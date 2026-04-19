import Foundation
import SwiftData

@Model
final class QuestTemplate {
    var id: UUID = UUID()
    var title: String = ""
    var difficulty: TaskDifficulty = TaskDifficulty.medium
    var isRecurring: Bool = false
    var recurrenceRule: RecurrenceRule? = nil
    var isPredefined: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \QuestInstance.template)
    var instances: [QuestInstance] = []

    init(
        title: String,
        difficulty: TaskDifficulty,
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        isPredefined: Bool = false
    ) {
        self.title = title
        self.difficulty = difficulty
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.isPredefined = isPredefined
    }

    /// Ob aktuell mind. eine offene Instanz dieses Templates existiert.
    var hasOpenInstance: Bool {
        instances.contains { !$0.isCompleted }
    }

    /// Anzahl offener Instanzen.
    var openInstanceCount: Int {
        instances.filter { !$0.isCompleted }.count
    }
}
