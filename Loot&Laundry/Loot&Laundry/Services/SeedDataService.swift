import Foundation
import SwiftData

/// Befüllt die Datenbank beim ersten Start mit vordefinierten Quest-Vorlagen und einem Spieler-Charakter.
struct SeedDataService {

    // MARK: - Vordefinierte Vorlagen

    private static let predefinedTemplateData: [(String, TaskDifficulty, Bool, RecurrenceRule?)] = [
        ("Geschirrspüler ausräumen",    .medium, true,  nil),
        ("Geschirrspüler einräumen",    .easy,   true,  nil),
        ("Bett machen",                 .easy,   true,  .daily),
        ("Küche wischen",               .medium, true,  .weekly),
        ("Müll rausbringen",            .easy,   true,  .weekly),
        ("Wäsche waschen",              .medium, true,  .weekly),
        ("Wäsche wegräumen",            .medium, false, nil),
        ("Staubsaugen",                 .hard,   true,  .weekly),
        ("Bad putzen",                  .hard,   true,  .weekly),
        ("Einkaufen",                   .medium, true,  nil),
    ]

    /// Legt vordefinierte Vorlagen an – aber nur beim allerersten Start (idempotent).
    static func seedTemplatesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<QuestTemplate>(
            predicate: #Predicate { $0.isPredefined == true }
        )
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (title, difficulty, recurring, rule) in predefinedTemplateData {
            let template = QuestTemplate(
                title: title,
                difficulty: difficulty,
                isRecurring: recurring,
                recurrenceRule: rule,
                isPredefined: true
            )
            context.insert(template)
        }
    }

    /// Legt einen Spieler-Charakter an – aber nur beim allerersten Start (idempotent).
    static func seedPlayerIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<PlayerCharacter>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        context.insert(PlayerCharacter(name: "Held"))
    }
}
