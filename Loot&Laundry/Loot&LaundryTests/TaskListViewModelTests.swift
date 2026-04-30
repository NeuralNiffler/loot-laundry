import Testing
import Foundation
import SwiftData
@testable import Loot_Laundry

// MARK: - TaskListViewModel Tests

@Suite("TaskListViewModel Tests")
struct TaskListViewModelTests {

    let viewModel = TaskListViewModel()

    // MARK: - completeInstance Tests

    @Test("completeInstance setzt completedAt")
    func completeInstanceSetsCompletedAt() {
        let context = TestSupport.makeModelContext()
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
        let context = TestSupport.makeModelContext()
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
        let context = TestSupport.makeModelContext()
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
        let context = TestSupport.makeModelContext()
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
        let context = TestSupport.makeModelContext()
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
        let context = TestSupport.makeModelContext()
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
        let context = TestSupport.makeModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        context.insert(template)

        let initialInstances = TestSupport.instanceCount(context)

        viewModel.spawnInstance(from: template, context: context)

        // Eine neue Instanz sollte eingefügt sein
        #expect(TestSupport.instanceCount(context) > initialInstances)
    }

    // MARK: - addTemplate Tests

    @Test("addTemplate erstellt neues Template")
    func addTemplateCreatesTemplate() {
        let context = TestSupport.makeModelContext()
        let initialTemplates = TestSupport.templateCount(context)

        viewModel.addTemplate(
            title: "Neue Quest",
            difficulty: .medium,
            isRecurring: false,
            recurrenceRule: nil,
            context: context
        )

        #expect(TestSupport.templateCount(context) == initialTemplates + 1)
    }

    @Test("addTemplate erstellt Template OHNE sofortige Instanz")
    func addTemplateDoesNotSpawnInstance() {
        let context = TestSupport.makeModelContext()
        let initialTemplates = TestSupport.templateCount(context)
        let initialInstances = TestSupport.instanceCount(context)

        viewModel.addTemplate(
            title: "Neue Quest",
            difficulty: .easy,
            isRecurring: false,
            recurrenceRule: nil,
            context: context
        )

        // Nur Template, keine Instanz
        #expect(TestSupport.templateCount(context) == initialTemplates + 1)
        #expect(TestSupport.instanceCount(context) == initialInstances)

        #expect(TestSupport.template(withTitle: "Neue Quest", in: context) != nil)
    }

    @Test("addTemplate setzt Eigenschaften korrekt")
    func addTemplateSetProperties() {
        let context = TestSupport.makeModelContext()

        viewModel.addTemplate(
            title: "Geschirrspüler ausräumen",
            difficulty: .hard,
            isRecurring: true,
            recurrenceRule: .daily,
            context: context
        )

        guard let template = TestSupport.template(withTitle: "Geschirrspüler ausräumen", in: context) else {
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
        let context = TestSupport.makeModelContext()

        viewModel.addTemplate(
            title: "RecurrenceNullTest",
            difficulty: .easy,
            isRecurring: false,
            recurrenceRule: .daily,  // Wird ignoriert
            context: context
        )

        guard let template = TestSupport.template(withTitle: "RecurrenceNullTest", in: context) else {
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
        let context = TestSupport.makeModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        context.insert(template)

        #expect(TestSupport.templateCount(context) == 1)

        viewModel.deleteTemplate(template, context: context)

        #expect(TestSupport.templateCount(context) == 0)
    }

    // MARK: - deleteInstance Tests

    @Test("deleteInstance löscht Instanz aus Context")
    func deleteInstanceRemovesFromContext() {
        let context = TestSupport.makeModelContext()
        let template = QuestTemplate(
            title: "Test",
            difficulty: .easy,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        
        context.insert(template)
        context.insert(instance)

        #expect(TestSupport.instanceCount(context) == 1)

        viewModel.deleteInstance(instance, context: context)

        #expect(TestSupport.instanceCount(context) == 0)
    }

    // MARK: - clearTriggeredEvolution Tests

    @Test("clearTriggeredEvolution setzt triggeredEvolution auf nil")
    func clearTriggeredEvolution() {
        viewModel.triggeredEvolution = .gelehrte

        viewModel.clearTriggeredEvolution()

        #expect(viewModel.triggeredEvolution == nil)
    }
}
