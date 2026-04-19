import Foundation
import SwiftData

struct QuestSchedulingService {

    // MARK: - Auto-Spawn beim App-Start

    /// Stellt sicher, dass für jedes wiederkehrende Template min. eine offene
    /// Instanz im aktuellen Intervall (Tag / Woche) existiert.
    static func ensureRecurringInstances(context: ModelContext) {
        let descriptor = FetchDescriptor<QuestTemplate>(
            predicate: #Predicate { $0.isRecurring == true }
        )
        guard let templates = try? context.fetch(descriptor) else { return }

        for template in templates {
            guard let rule = template.recurrenceRule else { continue }
            let hasCurrentInstance = template.instances.contains { instance in
                guard !instance.isCompleted else { return false }
                return isInstanceInCurrentInterval(instance, rule: rule)
            }
            if !hasCurrentInstance {
                let instance = QuestInstance(template: template)
                context.insert(instance)
            }
        }
    }

    // MARK: - Manueller Spawn

    /// Erzeugt eine neue Instanz aus einem Template – beliebig oft aufrufbar.
    @discardableResult
    static func spawnInstance(from template: QuestTemplate, context: ModelContext) -> QuestInstance {
        let instance = QuestInstance(template: template)
        context.insert(instance)
        return instance
    }

    // MARK: - Hilfsmethoden

    private static func isInstanceInCurrentInterval(_ instance: QuestInstance, rule: RecurrenceRule) -> Bool {
        let now = Date()
        switch rule {
        case .daily:
            return Calendar.current.isDateInToday(instance.createdAt)
        case .weekly:
            return Calendar.current.isDate(instance.createdAt, equalTo: now, toGranularity: .weekOfYear)
        }
    }
}
