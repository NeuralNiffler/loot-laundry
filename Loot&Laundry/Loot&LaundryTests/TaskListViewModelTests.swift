import Testing
import Foundation
import SwiftData
@testable import Loot_Laundry

// MARK: - Mock ModelContext für ViewModel Tests

class ViewModelMockModelContext: ModelContext {
    var insertedObjects: [any PersistentModel] = []
    var deletedObjects: [any PersistentModel] = []

    init() {
        let container = try! ModelContainer(
            for: QuestTemplate.self, QuestInstance.self, PlayerCharacter.self,
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
}

// MARK: - TaskListViewModel Tests

@Suite("TaskListViewModel Tests")
struct TaskListViewModelTests {

    let viewModel = TaskListViewModel()

    // MARK: - completeInstance Tests

    @Test("completeInstance setzt completedAt")
    func completeInstanceSetsCompletedAt() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        
        context.insert(template)
        context.insert(instance)

        let character = PlayerCharacter(name: "Held")
        context.insert(character)

        #expect(instance.completedAt == nil)
        
        viewModel.completeInstance(instance, character: character, context: context)

        #expect(instance.completedAt != nil)
    }

    @Test("completeInstance setzt expEarned korrekt")
    func completeInstanceSetsExpEarned() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .medium,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        
        context.insert(template)
        context.insert(instance)

        let character = PlayerCharacter(name: "Held")
        context.insert(character)

        viewModel.completeInstance(instance, character: character, context: context)

        // Medium = 10 EXP
        #expect(instance.expEarned == 10)
    }

    @Test("completeInstance vergibt EXP an Character")
    func completeInstanceGrantsCharacterEXP() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .hard,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        
        context.insert(template)
        context.insert(instance)

        let character = PlayerCharacter(name: "Held")
        #expect(character.totalEXP == 0)
        context.insert(character)

        viewModel.completeInstance(instance, character: character, context: context)

        // Hard = 20 EXP
        #expect(character.totalEXP == 20)
    }

    @Test("completeInstance triggert Evolution bei Levelup")
    func completeInstanceTriggersEvolutionOnLevelUp() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .hard,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        
        context.insert(template)
        context.insert(instance)

        let character = PlayerCharacter(name: "Held")
        character.totalEXP = 95  // Knapp vor Gelehrte (100)
        context.insert(character)

        #expect(viewModel.triggeredEvolution == nil)
        
        viewModel.completeInstance(instance, character: character, context: context)

        // Hard Quest (20 EXP) → 95 + 20 = 115 EXP → sollte Evolution triggern
        #expect(viewModel.triggeredEvolution == .gelehrte)
    }

    @Test("completeInstance erzeugt bei wiederkehrend eine Folgeinstanz mit neuem dueDate")
    func completeRecurringSpawnsNextInstance() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Täglich",
            difficulty: .easy,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        instance.dueDate = QuestSchedulingService.startOfToday()

        context.insert(template)
        context.insert(instance)

        let character = PlayerCharacter(name: "Held")
        context.insert(character)

        viewModel.completeInstance(instance, character: character, context: context)

        let open = template.instances.filter { !$0.isCompleted }
        #expect(open.count == 1)
        let tomorrow = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: QuestSchedulingService.startOfToday()
        )!
        #expect(Calendar.current.isDate(open[0].dueDate ?? .distantPast, inSameDayAs: tomorrow))
    }

    @Test("completeInstance ignoriert bereits abgehakte Instanzen")
    func completeInstanceIgnoresCompletedInstance() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        instance.completedAt = Date()
        
        context.insert(template)
        context.insert(instance)

        let character = PlayerCharacter(name: "Held")
        context.insert(character)

        let initialEXP = character.totalEXP

        viewModel.completeInstance(instance, character: character, context: context)

        // EXP sollte unverändert bleiben
        #expect(character.totalEXP == initialEXP)
    }

    // MARK: - spawnInstance Tests

    @Test("spawnInstance ruft QuestSchedulingService auf")
    func spawnInstanceCallsSchedulingService() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        context.insert(template)

        let initialCount = context.insertedObjects.count

        viewModel.spawnInstance(from: template, context: context)

        // Eine neue Instanz sollte eingefügt sein
        #expect(context.insertedObjects.count > initialCount)
    }

    // MARK: - addTemplate Tests

    @Test("addTemplate erstellt neues Template")
    func addTemplateCreatesTemplate() {
        let context = ViewModelMockModelContext()
        let initialCount = context.insertedObjects.count

        viewModel.addTemplate(
            title: "Neue Quest",
            difficulty: .medium,
            isRecurring: false,
            recurrenceRule: nil,
            context: context
        )

        #expect(context.insertedObjects.count == initialCount + 1)
    }

    @Test("addTemplate erstellt Template OHNE sofortige Instanz")
    func addTemplateDoesNotSpawnInstance() {
        let context = ViewModelMockModelContext()
        let initialCount = context.insertedObjects.count

        viewModel.addTemplate(
            title: "Neue Quest",
            difficulty: .easy,
            isRecurring: false,
            recurrenceRule: nil,
            context: context
        )

        // Nur Template, keine Instanz
        #expect(context.insertedObjects.count == initialCount + 1)

        // Prüfe dass inserted object ein Template ist
        let lastInserted = context.insertedObjects.last
        #expect(lastInserted is QuestTemplate)
    }

    @Test("addTemplate setzt Eigenschaften korrekt")
    func addTemplateSetProperties() {
        let context = ViewModelMockModelContext()

        viewModel.addTemplate(
            title: "Geschirrspüler ausräumen",
            difficulty: .hard,
            isRecurring: true,
            recurrenceRule: .daily,
            context: context
        )

        guard let template = context.insertedObjects.last as? QuestTemplate else {
            Issue.record("Template nicht gefunden")
            return
        }

        #expect(template.title == "Geschirrspüler ausräumen")
        #expect(template.difficulty == .hard)
        #expect(template.isRecurring == true)
        #expect(template.recurrenceRule == .daily)
        #expect(template.isPredefined == false)
    }

    @Test("addTemplate setzt recurrenceRule auf nil wenn isRecurring false")
    func addTemplateNullsRecurrenceRuleWhenNotRecurring() {
        let context = ViewModelMockModelContext()

        viewModel.addTemplate(
            title: "Test",
            difficulty: .easy,
            isRecurring: false,
            recurrenceRule: .daily,  // Wird ignoriert
            context: context
        )

        guard let template = context.insertedObjects.last as? QuestTemplate else {
            Issue.record("Template nicht gefunden")
            return
        }

        #expect(template.recurrenceRule == nil)
    }

    // MARK: - updateTemplate Tests

    @Test("updateTemplate aktualisiert Titel")
    func updateTemplateTitle() {
        let template = QuestTemplate(
            title: "Alt",
            difficulty: .easy,
            isPredefined: false
        )

        viewModel.updateTemplate(
            template,
            title: "Neu",
            difficulty: .easy,
            isRecurring: false,
            recurrenceRule: nil
        )

        #expect(template.title == "Neu")
    }

    @Test("updateTemplate aktualisiert Schwierigkeit")
    func updateTemplateDifficulty() {
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )

        viewModel.updateTemplate(
            template,
            title: "Test",
            difficulty: .hard,
            isRecurring: false,
            recurrenceRule: nil
        )

        #expect(template.difficulty == .hard)
    }

    @Test("updateTemplate setzt recurrenceRule auf nil wenn isRecurring false")
    func updateTemplateRemovesRecurrence() {
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isRecurring: true,
            recurrenceRule: .daily,
            isPredefined: false
        )

        viewModel.updateTemplate(
            template,
            title: "Test",
            difficulty: .easy,
            isRecurring: false,
            recurrenceRule: nil
        )

        #expect(template.isRecurring == false)
        #expect(template.recurrenceRule == nil)
    }

    // MARK: - deleteTemplate Tests

    @Test("deleteTemplate löscht Template aus Context")
    func deleteTemplateRemovesFromContext() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        context.insert(template)

        let initialCount = context.deletedObjects.count

        viewModel.deleteTemplate(template, context: context)

        #expect(context.deletedObjects.count == initialCount + 1)
    }

    // MARK: - deleteInstance Tests

    @Test("deleteInstance löscht Instanz aus Context")
    func deleteInstanceRemovesFromContext() {
        let context = ViewModelMockModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        
        context.insert(template)
        context.insert(instance)

        let initialCount = context.deletedObjects.count

        viewModel.deleteInstance(instance, context: context)

        #expect(context.deletedObjects.count == initialCount + 1)
    }

    // MARK: - clearTriggeredEvolution Tests

    @Test("clearTriggeredEvolution setzt triggeredEvolution auf nil")
    func clearTriggeredEvolution() {
        viewModel.triggeredEvolution = .gelehrte

        viewModel.clearTriggeredEvolution()

        #expect(viewModel.triggeredEvolution == nil)
    }
}
