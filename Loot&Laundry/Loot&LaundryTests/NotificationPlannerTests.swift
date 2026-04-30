import Foundation
import Testing
@testable import Loot_Laundry

@Suite("NotificationPlanner Tests")
struct NotificationPlannerTests {

    private func gmtCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    // MARK: - Overdue

    @Test("Kein Overdue, wenn Fälligkeit heute")
    func testNoOverdue_whenDueIsToday() {
        let cal = gmtCalendar()
        let now = cal.date(from: DateComponents(year: 2020, month: 1, day: 10, hour: 10))!
        let todayStart = cal.startOfDay(for: now)
        let p = NotificationPlanner(calendar: cal)
        let result = p.plannedNotifications(
            now: now,
            lastActiveAt: now,
            openQuests: [OpenQuestInput(id: UUID(), title: "A", dueDate: todayStart)],
            characterTotalExp: 0
        )
        let overdues = result.filter { $0.identifier == NotificationIdentifiers.overdue }
        #expect(overdues.isEmpty)
    }

    @Test("Ein Overdue: Slot Folgetag 18:00, wenn heute noch platz")
    func testSingleOverdue_schedulesNudgeAt1800() {
        let cal = gmtCalendar()
        let now = cal.date(from: DateComponents(year: 2020, month: 1, day: 10, hour: 10, minute: 0))!
        // Fällig am 9.1. → Folgetag 10.1. 18:00
        let due = cal.date(from: DateComponents(year: 2020, month: 1, day: 9, hour: 8))!
        let p = NotificationPlanner(calendar: cal)
        let result = p.plannedNotifications(
            now: now,
            lastActiveAt: now,
            openQuests: [OpenQuestInput(id: UUID(), title: "Wäsche wegrollen", dueDate: due)],
            characterTotalExp: 0
        )
        let o = result.first { $0.identifier == NotificationIdentifiers.overdue }
        #expect(o != nil)
        #expect(o?.title == NotificationContent.overdueTitle())
        #expect(o?.body == NotificationContent.overdueBody(singleQuestTitle: "Wäsche wegrollen"))
        let expected = cal.date(from: DateComponents(timeZone: cal.timeZone, year: 2020, month: 1, day: 10, hour: 18, minute: 0))!
        #expect(o?.fireDate == expected)
    }

    @Test("Mehrfach-Overdues: Sammel-Body")
    func testMultipleOverdues_grouped() {
        let cal = gmtCalendar()
        let now = cal.date(from: DateComponents(year: 2020, month: 1, day: 10, hour: 10))!
        let d1 = cal.date(from: DateComponents(year: 2020, month: 1, day: 7))!
        let d2 = cal.date(from: DateComponents(year: 2020, month: 1, day: 8))!
        let p = NotificationPlanner(calendar: cal)
        let result = p.plannedNotifications(
            now: now,
            lastActiveAt: now,
            openQuests: [
                OpenQuestInput(id: UUID(), title: "A", dueDate: d1),
                OpenQuestInput(id: UUID(), title: "B", dueDate: d2),
            ],
            characterTotalExp: 0
        )
        let o = result.first { $0.identifier == NotificationIdentifiers.overdue }
        #expect(o != nil)
        #expect(o?.body == NotificationContent.overdueBodyMultiple(count: 2))
    }

    @Test("Offene, nicht überfällige Liste erzeugt keinen Overdue-Eintrag")
    func testCompletedOrNonOverdue_filterOutsidePlanner() {
        let cal = gmtCalendar()
        let now = cal.date(from: DateComponents(year: 2020, month: 1, day: 10, hour: 10))!
        let p = NotificationPlanner(calendar: cal)
        let result = p.plannedNotifications(
            now: now,
            lastActiveAt: now,
            openQuests: [],
            characterTotalExp: 0
        )
        #expect(result.contains { $0.identifier == NotificationIdentifiers.overdue } == false)
    }

    // MARK: - Inactivity

    @Test("Inaktivität: +3 Tage ab Tagesanfang, 19:00, rollt vorwärts")
    func testInactivity_schedulesAfter3Days() {
        let cal = gmtCalendar()
        let now = cal.date(from: DateComponents(year: 2020, month: 1, day: 10, hour: 10, minute: 0))!
        let last = cal.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 20))!
        let p = NotificationPlanner(calendar: cal)
        let result = p.plannedNotifications(
            now: now,
            lastActiveAt: last,
            openQuests: [],
            characterTotalExp: 0
        )
        let i = result.first { $0.identifier == NotificationIdentifiers.inactivity }
        #expect(i != nil)
        // Start 1.1. +3 Tage = 4.1. 19:00, liegt vor 10.1. 10:00 → rolle, bis 10.1. 19:00
        let expected = cal.date(from: DateComponents(timeZone: cal.timeZone, year: 2020, month: 1, day: 10, hour: 19, minute: 0))!
        #expect(i?.fireDate == expected)
    }

    // MARK: - Level-Teaser

    @Test("Level-Teaser ab 70% Fortschritt, morgen 10:00")
    func testLevelClose_whenProgressAtLeast70() {
        let cal = gmtCalendar()
        let now = cal.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 8, minute: 0))!
        let p = NotificationPlanner(calendar: cal)
        // 70 EXP im Novice → 0.7, nächste Stufe Gelehrte, noch 30 EXP
        let result = p.plannedNotifications(
            now: now,
            lastActiveAt: now,
            openQuests: [],
            characterTotalExp: 70
        )
        let l = result.first { $0.identifier == NotificationIdentifiers.levelClose }
        #expect(l != nil)
        #expect(l?.body.contains("30") == true)
        #expect(l?.body.contains("Gelehrte") == true)
        let expected = cal.date(from: DateComponents(timeZone: cal.timeZone, year: 2020, month: 1, day: 2, hour: 10, minute: 0))!
        #expect(l?.fireDate == expected)
    }

    @Test("Level-Teaser: auf Meister/Max kein nextEvolution")
    func testLevelClose_skippedOnMaxEvolution() {
        let cal = gmtCalendar()
        let now = cal.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 8))!
        let p = NotificationPlanner(calendar: cal)
        let result = p.plannedNotifications(
            now: now,
            lastActiveAt: now,
            openQuests: [],
            characterTotalExp: 2000
        )
        #expect(result.contains { $0.identifier == NotificationIdentifiers.levelClose } == false)
    }
}
