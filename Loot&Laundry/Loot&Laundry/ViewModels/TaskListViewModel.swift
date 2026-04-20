import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskListViewModel {

    private let progressionService = ProgressionService()

    /// Wird gesetzt wenn ein Stufenaufstieg stattgefunden hat – triggert die Animations-Overlay
    var triggeredEvolution: CharacterEvolution? = nil

    // MARK: - Instanz erledigen

    func completeInstance(_ instance: QuestInstance, character: PlayerCharacter, context: ModelContext) {
        guard !instance.isCompleted else { return }

        let earnedEXP = progressionService.expReward(for: instance.difficulty)
        let newEvo    = progressionService.newEvolution(currentEXP: character.totalEXP, earnedEXP: earnedEXP)

        instance.completedAt = Date()
        instance.expEarned   = earnedEXP
        character.totalEXP  += earnedEXP

        if instance.isRecurring {
            QuestSchedulingService.spawnNextRecurringInstance(after: instance, context: context)
        }

        if let evo = newEvo {
            triggeredEvolution = evo
        }
    }

    // MARK: - Instanz löschen (Swipe)

    func deleteInstance(_ instance: QuestInstance, context: ModelContext) {
        context.delete(instance)
    }

    // MARK: - Instanz manuell spawnen

    func spawnInstance(from template: QuestTemplate, context: ModelContext) {
        QuestSchedulingService.spawnInstance(from: template, context: context)
    }

    // MARK: - Template verwalten

    func addTemplate(
        title: String,
        difficulty: TaskDifficulty,
        isRecurring: Bool,
        recurrenceRule: RecurrenceRule?,
        context: ModelContext
    ) {
        let template = QuestTemplate(
            title: title,
            difficulty: difficulty,
            isRecurring: isRecurring,
            recurrenceRule: recurrenceRule,
            isPredefined: false
        )
        context.insert(template)
    }

    func updateTemplate(
        _ template: QuestTemplate,
        title: String,
        difficulty: TaskDifficulty,
        isRecurring: Bool,
        recurrenceRule: RecurrenceRule?
    ) {
        template.title          = title
        template.difficulty     = difficulty
        template.isRecurring    = isRecurring
        template.recurrenceRule = isRecurring ? recurrenceRule : nil
    }

    func deleteTemplate(_ template: QuestTemplate, context: ModelContext) {
        context.delete(template)
    }

    func clearTriggeredEvolution() {
        triggeredEvolution = nil
    }
}
