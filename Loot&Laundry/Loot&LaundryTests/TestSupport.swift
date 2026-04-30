import Foundation
import SwiftData
@testable import Loot_Laundry

/// Gemeinsame In-Memory-SwiftData-Hilfen für Unit-Tests (kein Subclassing von `ModelContext`).
enum TestSupport {

    static func makeModelContext() -> ModelContext {
        let container = try! ModelContainer(
            for: QuestTemplate.self,
            QuestInstance.self,
            PlayerCharacter.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    static func instanceCount(_ context: ModelContext) -> Int {
        (try? context.fetch(FetchDescriptor<QuestInstance>()))?.count ?? 0
    }

    static func templateCount(_ context: ModelContext) -> Int {
        (try? context.fetch(FetchDescriptor<QuestTemplate>()))?.count ?? 0
    }

    static func template(withTitle title: String, in context: ModelContext) -> QuestTemplate? {
        let all = (try? context.fetch(FetchDescriptor<QuestTemplate>())) ?? []
        return all.first { $0.title == title }
    }
}
