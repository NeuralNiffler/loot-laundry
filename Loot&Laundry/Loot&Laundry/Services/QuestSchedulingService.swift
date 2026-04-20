import Foundation
import SwiftData

struct QuestSchedulingService {

    // MARK: - Migration / Bootstrap

    /// Setzt fehlende `dueDate` bei offenen wiederkehrenden Instanzen (ältere Daten).
    static func backfillDueDatesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<QuestTemplate>(
            predicate: #Predicate { $0.isRecurring == true }
        )
        guard let templates = try? context.fetch(descriptor) else { return }
        let today = startOfToday()
        for template in templates {
            for instance in template.instances where !instance.isCompleted && instance.dueDate == nil {
                instance.dueDate = today
            }
        }
    }

    /// Stellt sicher, dass jedes wiederkehrende Template höchstens eine offene Instanz hat
    /// und diese ein `dueDate` trägt (neu: Fälligkeit = heute).
    static func ensureRecurringInstances(context: ModelContext) {
        let descriptor = FetchDescriptor<QuestTemplate>(
            predicate: #Predicate { $0.isRecurring == true }
        )
        guard let templates = try? context.fetch(descriptor) else { return }

        let today = startOfToday()
        for template in templates {
            guard template.recurrenceRule != nil else { continue }
            let hasOpen = template.instances.contains { !$0.isCompleted }
            if !hasOpen {
                let instance = QuestInstance(template: template)
                instance.dueDate = today
                context.insert(instance)
            }
        }
    }

    // MARK: - Nach Erledigung (Hybrid-Rhythmus)

    /// Legt die nächste offene Instanz mit neuem Fälligkeitsdatum an (nur wiederkehrend).
    @discardableResult
    static func spawnNextRecurringInstance(after completed: QuestInstance, context: ModelContext) -> QuestInstance? {
        guard completed.isRecurring,
              let rule = completed.recurrenceRule,
              let completedAt = completed.completedAt,
              let template = completed.template
        else { return nil }

        let calendar = Calendar.current
        let completionDay = calendar.startOfDay(for: completedAt)
        let base: Date
        if let due = completed.dueDate {
            let dueDay = calendar.startOfDay(for: due)
            if completionDay <= dueDay {
                base = due
            } else {
                base = completedAt
            }
        } else {
            base = completedAt
        }

        let newDue = nextDueDate(after: base, rule: rule, calendar: calendar)
        let next = QuestInstance(template: template)
        next.dueDate = newDue
        context.insert(next)
        return next
    }

    // MARK: - Manueller Spawn

    /// Erzeugt eine neue Instanz aus einem Template – beliebig oft aufrufbar.
    @discardableResult
    static func spawnInstance(from template: QuestTemplate, context: ModelContext) -> QuestInstance {
        let instance = QuestInstance(template: template)
        if template.isRecurring, template.recurrenceRule != nil {
            instance.dueDate = startOfToday(calendar: Calendar.current)
        }
        context.insert(instance)
        return instance
    }

    // MARK: - Datums-Helfer

    static func startOfToday(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: Date())
    }

    /// Nächster Fälligkeitstag ab `base` (Tagesbeginn von `base` + 1 Tag bzw. + 1 Woche).
    static func nextDueDate(after base: Date, rule: RecurrenceRule, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: base)
        switch rule {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start.addingTimeInterval(86_400 * 7)
        }
    }
}
