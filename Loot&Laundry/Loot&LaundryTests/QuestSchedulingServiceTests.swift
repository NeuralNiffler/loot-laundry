import Testing
import Foundation
import SwiftData
@testable import Loot_Laundry

// MARK: - Mock ModelContext

class MockModelContext: ModelContext {
    var insertedObjects: [any PersistentModel] = []
    var deletedObjects: [any PersistentModel] = []
    var fetchedTemplates: [QuestTemplate] = []

    init() {
        let container = try! ModelContainer(
            for: QuestTemplate.self, QuestInstance.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        super.init(container)
    }

    override func insert<T>(_ model: T) where T : PersistentModel {
        insertedObjects.append(model)
        super.insert(model)
    }

    override func delete<T>(_ model: T) where T : PersistentModel {
        deletedObjects.append(model)
        super.delete(model)
    }

    func setFetchedTemplates(_ templates: [QuestTemplate]) {
        fetchedTemplates = templates
    }
}

// MARK: - QuestSchedulingService Tests

@Suite("QuestSchedulingService Tests")
struct QuestSchedulingServiceTests {

    // MARK: - spawnInstance Tests

    @Test("spawnInstance erzeugt neue Instanz aus Template")
    func spawnInstanceCreatesInstance() {
        let context = MockModelContext()
        let template = QuestTemplate(
            title: "Test Quest",
            difficulty: .medium,
            isRecurring: false,
            isPredefined: false
        )
        context.insert(template)

        let instance = QuestSchedulingService.spawnInstance(from: template, context: context)

        #expect(instance.template === template)
        #expect(!instance.isCompleted)
        #expect(instance.dueDate == nil)
    }

    @Test("spawnInstance kann mehrfach für gleiches Template aufgerufen werden")
    func spawnInstanceMultipleTimes() {
        let context = MockModelContext()
        let template = QuestTemplate(
            title: "Geschirrspüler ausräumen",
            difficulty: .medium,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        context.insert(template)

        let instance1 = QuestSchedulingService.spawnInstance(from: template, context: context)
        let instance2 = QuestSchedulingService.spawnInstance(from: template, context: context)

        #expect(instance1.id != instance2.id)
        #expect(instance1.template === template)
        #expect(instance2.template === template)
        #expect(instance1.dueDate != nil)
        #expect(instance2.dueDate != nil)
    }

    @Test("spawnInstance fügt Instanz in Context ein")
    func spawnInstanceInsertsIntoContext() {
        let context = MockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        context.insert(template)

        let initialCount = context.insertedObjects.count
        _ = QuestSchedulingService.spawnInstance(from: template, context: context)

        #expect(context.insertedObjects.count == initialCount + 1)
    }

    // MARK: - ensureRecurringInstances Tests

    @Test("ensureRecurringInstances erstellt Instanz wenn keine existiert")
    func ensureRecurringInstancesCreatesWhenMissing() {
        let context = MockModelContext()
        
        // Template ohne Instanzen
        let template = QuestTemplate(
            title: "Bett machen",
            difficulty: .easy,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        context.insert(template)
        context.setFetchedTemplates([template])

        let initialCount = context.insertedObjects.count
        QuestSchedulingService.ensureRecurringInstances(context: context)

        // Mindestens eine Instanz sollte hinzugefügt werden
        #expect(context.insertedObjects.count > initialCount)
        let newInstance = template.instances.first { !$0.isCompleted }
        #expect(newInstance?.dueDate != nil)
        let today = QuestSchedulingService.startOfToday()
        #expect(Calendar.current.isDate(newInstance?.dueDate ?? .distantPast, inSameDayAs: today))
    }

    @Test("ensureRecurringInstances erstellt NICHT wenn offene Instanz existiert")
    func ensureRecurringInstancesSkipsIfExists() {
        let context = MockModelContext()
        
        let template = QuestTemplate(
            title: "Täglich",
            difficulty: .medium,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        
        // Füge heute eine offene Instanz hinzu
        let existingInstance = QuestInstance(template: template)
        existingInstance.createdAt = Date()
        template.instances.append(existingInstance)
        
        context.insert(template)
        context.setFetchedTemplates([template])

        let initialCount = context.insertedObjects.count
        QuestSchedulingService.ensureRecurringInstances(context: context)

        // Keine neue Instanz sollte hinzugefügt werden
        #expect(context.insertedObjects.count == initialCount)
    }

    @Test("ensureRecurringInstances erstellt NICHT wenn abgehakte Instanz existiert")
    func ensureRecurringInstancesIgnoresCompletedInstances() {
        let context = MockModelContext()
        
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        
        // Füge heute eine ABGEHAKTE Instanz hinzu
        let completedInstance = QuestInstance(template: template)
        completedInstance.createdAt = Date()
        completedInstance.completedAt = Date()
        template.instances.append(completedInstance)
        
        context.insert(template)
        context.setFetchedTemplates([template])

        let initialCount = context.insertedObjects.count
        QuestSchedulingService.ensureRecurringInstances(context: context)

        // Eine NEUE offene Instanz sollte erzeugt werden
        #expect(context.insertedObjects.count > initialCount)
        let open = template.instances.filter { !$0.isCompleted }
        #expect(open.count == 1)
        #expect(Calendar.current.isDate(open.first?.dueDate ?? .distantPast, inSameDayAs: QuestSchedulingService.startOfToday()))
    }

    @Test("ensureRecurringInstances berücksichtigt nur wiederkehrende Templates")
    func ensureRecurringInstancesIgnoresNonRecurring() {
        let context = MockModelContext()
        
        let nonRecurringTemplate = QuestTemplate(
            title: "Einmalig",
            difficulty: .hard,
            isRecurring: false,
            isPredefined: false
        )
        
        context.insert(nonRecurringTemplate)
        context.setFetchedTemplates([])  // Non-recurring nicht in Fetch-Result

        let initialCount = context.insertedObjects.count
        QuestSchedulingService.ensureRecurringInstances(context: context)

        // Keine neue Instanz sollte erzeugt werden
        #expect(context.insertedObjects.count == initialCount)
    }

    @Test("ensureRecurringInstances verarbeitet mehrere Templates")
    func ensureRecurringInstancesMultipleTemplates() {
        let context = MockModelContext()
        
        let template1 = QuestTemplate(
            title: "Täglich 1",
            difficulty: .easy,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        
        let template2 = QuestTemplate(
            title: "Täglich 2",
            difficulty: .medium,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        
        context.insert(template1)
        context.insert(template2)
        context.setFetchedTemplates([template1, template2])

        let initialCount = context.insertedObjects.count
        QuestSchedulingService.ensureRecurringInstances(context: context)

        // Mindestens 2 neue Instanzen sollten hinzugefügt werden (eine pro Template)
        #expect(context.insertedObjects.count >= initialCount + 2)
    }

    // MARK: - backfillDueDatesIfNeeded

    @Test("backfillDueDatesIfNeeded setzt dueDate auf heute für offene wiederkehrende ohne Datum")
    func backfillSetsDueDateForOpenRecurring() {
        let context = MockModelContext()
        let template = QuestTemplate(
            title: "Alt",
            difficulty: .easy,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        instance.dueDate = nil
        context.insert(template)
        context.insert(instance)

        QuestSchedulingService.backfillDueDatesIfNeeded(context: context)

        #expect(instance.dueDate != nil)
        let today = QuestSchedulingService.startOfToday()
        #expect(Calendar.current.isDate(instance.dueDate!, inSameDayAs: today))
    }

    // MARK: - nextDueDate

    @Test("nextDueDate täglich addiert einen Kalendertag ab Tagesbeginn")
    func nextDueDateDailyAddsOneDay() {
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 15, minute: 30))!
        let next = QuestSchedulingService.nextDueDate(after: base, rule: .daily, calendar: cal)
        let expectedDay = cal.date(from: DateComponents(year: 2026, month: 6, day: 11))!
        #expect(cal.isDate(next, inSameDayAs: expectedDay))
    }

    @Test("nextDueDate wöchentlich addiert eine Woche ab Tagesbeginn")
    func nextDueDateWeeklyAddsOneWeek() {
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2026, month: 6, day: 10))!
        let next = QuestSchedulingService.nextDueDate(after: base, rule: .weekly, calendar: cal)
        let expectedDay = cal.date(from: DateComponents(year: 2026, month: 6, day: 17))!
        #expect(cal.isDate(next, inSameDayAs: expectedDay))
    }

    // MARK: - spawnNextRecurringInstance

    @Test("spawnNextRecurringInstance rechtzeitig täglich -> Fälligkeit morgen")
    func spawnNextOnTimeDaily() {
        let context = MockModelContext()
        let cal = Calendar.current
        let today = QuestSchedulingService.startOfToday(calendar: cal)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        let template = QuestTemplate(
            title: "Täglich",
            difficulty: .medium,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        context.insert(template)

        let completed = QuestInstance(template: template)
        completed.dueDate = today
        completed.completedAt = cal.date(byAdding: .hour, value: 10, to: today)
        context.insert(completed)

        _ = QuestSchedulingService.spawnNextRecurringInstance(after: completed, context: context)

        let open = template.instances.filter { !$0.isCompleted }
        #expect(open.count == 1)
        #expect(cal.isDate(open[0].dueDate!, inSameDayAs: tomorrow))
    }

    @Test("spawnNextRecurringInstance früh erledigt -> Rhythmus am Due-Date")
    func spawnNextEarlyCompletionAnchorsOnDue() {
        let context = MockModelContext()
        let cal = Calendar.current
        let today = QuestSchedulingService.startOfToday(calendar: cal)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let dayAfter = cal.date(byAdding: .day, value: 2, to: today)!

        let template = QuestTemplate(
            title: "Täglich",
            difficulty: .easy,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        context.insert(template)

        let completed = QuestInstance(template: template)
        completed.dueDate = tomorrow
        completed.completedAt = cal.date(byAdding: .hour, value: 9, to: today)
        context.insert(completed)

        _ = QuestSchedulingService.spawnNextRecurringInstance(after: completed, context: context)

        let open = template.instances.filter { !$0.isCompleted }
        #expect(open.count == 1)
        #expect(cal.isDate(open[0].dueDate!, inSameDayAs: dayAfter))
    }

    @Test("spawnNextRecurringInstance überfällig -> ab Erledigung +1 Tag")
    func spawnNextOverdueDaily() {
        let context = MockModelContext()
        let cal = Calendar.current
        let today = QuestSchedulingService.startOfToday(calendar: cal)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: today)!

        let template = QuestTemplate(
            title: "Täglich",
            difficulty: .hard,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        context.insert(template)

        let completed = QuestInstance(template: template)
        completed.dueDate = threeDaysAgo
        completed.completedAt = cal.date(byAdding: .hour, value: 16, to: today)
        context.insert(completed)

        _ = QuestSchedulingService.spawnNextRecurringInstance(after: completed, context: context)

        let open = template.instances.filter { !$0.isCompleted }
        #expect(open.count == 1)
        #expect(cal.isDate(open[0].dueDate!, inSameDayAs: tomorrow))
    }

    @Test("spawnNextRecurringInstance wöchentlich rechtzeitig -> +1 Woche")
    func spawnNextOnTimeWeekly() {
        let context = MockModelContext()
        let cal = Calendar.current
        let today = QuestSchedulingService.startOfToday(calendar: cal)
        let nextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: today)!

        let template = QuestTemplate(
            title: "Wöchentlich",
            difficulty: .medium,
            isRecurring: true,
            recurrenceRule: .weekly,
            isPredefined: false
        )
        context.insert(template)

        let completed = QuestInstance(template: template)
        completed.dueDate = today
        completed.completedAt = cal.date(byAdding: .hour, value: 11, to: today)
        context.insert(completed)

        _ = QuestSchedulingService.spawnNextRecurringInstance(after: completed, context: context)

        let open = template.instances.filter { !$0.isCompleted }
        #expect(open.count == 1)
        #expect(cal.isDate(open[0].dueDate!, inSameDayAs: nextWeek))
    }
}
