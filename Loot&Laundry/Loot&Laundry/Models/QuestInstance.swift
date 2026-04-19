import Foundation
import SwiftData

@Model
final class QuestInstance {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var completedAt: Date? = nil
    var expEarned: Int = 0
    var template: QuestTemplate?

    init(template: QuestTemplate) {
        self.template = template
    }

    var isCompleted: Bool { completedAt != nil }

    var isCompletedToday: Bool {
        guard let date = completedAt else { return false }
        return Calendar.current.isDateInToday(date)
    }

    /// Bequemer Zugriff auf Template-Eigenschaften (mit Fallbacks)
    var title: String      { template?.title ?? "Unbekannte Quest" }
    var difficulty: TaskDifficulty { template?.difficulty ?? .medium }
    var isRecurring: Bool  { template?.isRecurring ?? false }
    var recurrenceRule: RecurrenceRule? { template?.recurrenceRule }
}
