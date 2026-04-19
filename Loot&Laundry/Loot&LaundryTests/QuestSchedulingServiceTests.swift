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
        let container = try! ModelContainer(for: QuestTemplate.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
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
}
