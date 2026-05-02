import Testing
import Foundation
import SwiftData
@testable import Loot_Laundry

@Suite("QuestListFilter Tests")
struct QuestListFilterTests {

    private func makeOpenInstance(
        title: String,
        difficulty: TaskDifficulty = .medium,
        isRecurring: Bool = false,
        dueDate: Date? = nil,
        context: ModelContext
    ) -> QuestInstance {
        let template = QuestTemplate(
            title: title,
            difficulty: difficulty,
            isRecurring: isRecurring,
            isPredefined: false
        )
        let instance = QuestInstance(template: template)
        instance.dueDate = dueDate
        context.insert(template)
        context.insert(instance)
        return instance
    }

    @Test("matchesTemplate erlaubt leere Suche")
    func templateEmptySearch() {
        let context = TestSupport.makeModelContext()
        let template = QuestTemplate(title: "Wäsche", difficulty: .easy, isPredefined: false)
        context.insert(template)
        #expect(QuestListFilter.matchesTemplate(template, searchText: ""))
        #expect(QuestListFilter.matchesTemplate(template, searchText: "   "))
    }

    @Test("matchesTemplate filtert nach Titel-Teilstring")
    func templateSubstring() {
        let context = TestSupport.makeModelContext()
        let template = QuestTemplate(title: "Große Wäsche", difficulty: .easy, isPredefined: false)
        context.insert(template)
        #expect(QuestListFilter.matchesTemplate(template, searchText: "wäs"))
        #expect(QuestListFilter.matchesTemplate(template, searchText: "gar-nicht-da") == false)
        #expect(QuestListFilter.matchesTemplate(template, searchText: "groß"))
    }

    @Test("matchesCompletedInstance nutzt nur Textsuche")
    func completedUsesSearchOnly() {
        let context = TestSupport.makeModelContext()
        let instance = makeOpenInstance(title: "Quest A", difficulty: .hard, isRecurring: true, context: context)
        instance.completedAt = Date()
        #expect(QuestListFilter.matchesCompletedInstance(instance, searchText: "Quest"))
        #expect(QuestListFilter.matchesCompletedInstance(instance, searchText: "nix") == false)
    }

    @Test("matchesOpenInstance lehnt erledigte Instanzen ab")
    func openRejectsCompleted() {
        let context = TestSupport.makeModelContext()
        let instance = makeOpenInstance(title: "X", context: context)
        instance.completedAt = Date()
        #expect(
            QuestListFilter.matchesOpenInstance(
                instance,
                searchText: "",
                difficulty: .all,
                recurrence: .all,
                due: .all
            ) == false
        )
    }

    @Test("matchesOpenInstance Schwierigkeit")
    func openDifficulty() {
        let context = TestSupport.makeModelContext()
        let easy = makeOpenInstance(title: "E", difficulty: .easy, context: context)
        #expect(
            QuestListFilter.matchesOpenInstance(easy, searchText: "", difficulty: .easy, recurrence: .all, due: .all)
        )
        #expect(
            QuestListFilter.matchesOpenInstance(easy, searchText: "", difficulty: .medium, recurrence: .all, due: .all)
                == false
        )
    }

    @Test("matchesOpenInstance Wiederholung")
    func openRecurrence() {
        let context = TestSupport.makeModelContext()
        let once = makeOpenInstance(title: "O", isRecurring: false, context: context)
        let recur = makeOpenInstance(title: "R", isRecurring: true, context: context)
        #expect(
            QuestListFilter.matchesOpenInstance(once, searchText: "", difficulty: .all, recurrence: .oneTimeOnly, due: .all)
        )
        #expect(
            QuestListFilter.matchesOpenInstance(recur, searchText: "", difficulty: .all, recurrence: .oneTimeOnly, due: .all)
                == false
        )
        #expect(
            QuestListFilter.matchesOpenInstance(recur, searchText: "", difficulty: .all, recurrence: .recurringOnly, due: .all)
        )
    }

    @Test("matchesOpenInstance ohne Fälligkeit")
    func openNoDueDate() {
        let context = TestSupport.makeModelContext()
        let noDue = makeOpenInstance(title: "N", dueDate: nil, context: context)
        let cal = Calendar.current
        let withDue = makeOpenInstance(title: "W", dueDate: cal.startOfDay(for: Date()), context: context)
        #expect(
            QuestListFilter.matchesOpenInstance(noDue, searchText: "", difficulty: .all, recurrence: .all, due: .noDueDate)
        )
        #expect(
            QuestListFilter.matchesOpenInstance(withDue, searchText: "", difficulty: .all, recurrence: .all, due: .noDueDate)
                == false
        )
    }

    @Test("matchesOpenInstance heute fällig")
    func openDueToday() {
        let context = TestSupport.makeModelContext()
        let cal = Calendar.current
        let today = makeOpenInstance(title: "T", dueDate: cal.startOfDay(for: Date()), context: context)
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let overdue = makeOpenInstance(title: "O", dueDate: cal.startOfDay(for: yesterday), context: context)
        #expect(
            QuestListFilter.matchesOpenInstance(today, searchText: "", difficulty: .all, recurrence: .all, due: .dueToday)
        )
        #expect(
            QuestListFilter.matchesOpenInstance(overdue, searchText: "", difficulty: .all, recurrence: .all, due: .dueToday)
                == false
        )
    }

    @Test("matchesOpenInstance überfällig")
    func openOverdue() {
        let context = TestSupport.makeModelContext()
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let overdue = makeOpenInstance(title: "O", dueDate: cal.startOfDay(for: yesterday), context: context)
        let today = makeOpenInstance(title: "T", dueDate: cal.startOfDay(for: Date()), context: context)
        #expect(
            QuestListFilter.matchesOpenInstance(overdue, searchText: "", difficulty: .all, recurrence: .all, due: .overdue)
        )
        #expect(
            QuestListFilter.matchesOpenInstance(today, searchText: "", difficulty: .all, recurrence: .all, due: .overdue)
                == false
        )
    }

    @Test("openInstancesFiltersActive")
    func filtersActiveFlag() {
        #expect(QuestListFilter.openInstancesFiltersActive(difficulty: .all, recurrence: .all, due: .all) == false)
        #expect(QuestListFilter.openInstancesFiltersActive(difficulty: .easy, recurrence: .all, due: .all))
        #expect(QuestListFilter.openInstancesFiltersActive(difficulty: .all, recurrence: .recurringOnly, due: .all))
        #expect(QuestListFilter.openInstancesFiltersActive(difficulty: .all, recurrence: .all, due: .overdue))
    }
}
