import Foundation

// MARK: - Filter-Kriterien (offene Instanzen)

enum QuestDifficultyFilter: CaseIterable, Hashable {
    case all
    case easy
    case medium
    case hard

    var menuTitle: String {
        switch self {
        case .all: return "Alle"
        case .easy: return TaskDifficulty.easy.rawValue
        case .medium: return TaskDifficulty.medium.rawValue
        case .hard: return TaskDifficulty.hard.rawValue
        }
    }
}

enum QuestRecurrenceFilter: CaseIterable, Hashable {
    case all
    case recurringOnly
    case oneTimeOnly

    var menuTitle: String {
        switch self {
        case .all: return "Alle"
        case .recurringOnly: return "Nur wiederkehrend"
        case .oneTimeOnly: return "Nur einmalig"
        }
    }
}

enum QuestDueFilter: CaseIterable, Hashable {
    case all
    case overdue
    case dueToday
    case noDueDate

    var menuTitle: String {
        switch self {
        case .all: return "Alle"
        case .overdue: return "Überfällig"
        case .dueToday: return "Heute fällig"
        case .noDueDate: return "Ohne Datum"
        }
    }
}

// MARK: - Matching

enum QuestListFilter {

    static func trimmedSearch(_ searchText: String) -> String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func matchesTitleSearch(title: String, searchText: String) -> Bool {
        let q = trimmedSearch(searchText)
        if q.isEmpty { return true }
        return title.localizedStandardContains(q)
    }

    static func matchesTemplate(_ template: QuestTemplate, searchText: String) -> Bool {
        matchesTitleSearch(title: template.title, searchText: searchText)
    }

    static func matchesCompletedInstance(_ instance: QuestInstance, searchText: String) -> Bool {
        matchesTitleSearch(title: instance.title, searchText: searchText)
    }

    /// Nur für nicht erledigte Instanzen gedacht (wird bei erfüllten Filtern ignoriert).
    static func matchesOpenInstance(
        _ instance: QuestInstance,
        searchText: String,
        difficulty: QuestDifficultyFilter,
        recurrence: QuestRecurrenceFilter,
        due: QuestDueFilter
    ) -> Bool {
        guard !instance.isCompleted else { return false }
        guard matchesTitleSearch(title: instance.title, searchText: searchText) else { return false }

        switch difficulty {
        case .all: break
        case .easy: guard instance.difficulty == .easy else { return false }
        case .medium: guard instance.difficulty == .medium else { return false }
        case .hard: guard instance.difficulty == .hard else { return false }
        }

        switch recurrence {
        case .all: break
        case .recurringOnly: guard instance.isRecurring else { return false }
        case .oneTimeOnly: guard !instance.isRecurring else { return false }
        }

        switch due {
        case .all: break
        case .overdue: guard instance.isOverdue else { return false }
        case .dueToday: guard instance.isDueToday else { return false }
        case .noDueDate: guard instance.dueDate == nil else { return false }
        }

        return true
    }

    static func openInstancesFiltersActive(
        difficulty: QuestDifficultyFilter,
        recurrence: QuestRecurrenceFilter,
        due: QuestDueFilter
    ) -> Bool {
        difficulty != .all || recurrence != .all || due != .all
    }
}
