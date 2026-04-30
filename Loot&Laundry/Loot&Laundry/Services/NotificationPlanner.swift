import Foundation

/// Eine geplante lokale Benachrichtigung (rein datenbasiert, kein UserNotifications-Import).
struct PlannedNotification: Equatable, Sendable {
    let identifier: String
    let fireDate: Date
    let title: String
    let body: String
}

/// Minimale Quest-Daten für die Planung (unabhängig von SwiftData im View).
struct OpenQuestInput: Equatable, Sendable {
    let id: UUID
    let title: String
    let dueDate: Date?
}

/// Berechnet **idempotent** die nächsten geplanten Notifications.
struct NotificationPlanner {

    var calendar: Calendar
    private let progression: ProgressionService

    init(calendar: Calendar = .current, progression: ProgressionService = ProgressionService()) {
        self.calendar = calendar
        self.progression = progression
    }

    func plannedNotifications(
        now: Date,
        lastActiveAt: Date,
        openQuests: [OpenQuestInput],
        characterTotalExp: Int
    ) -> [PlannedNotification] {
        var out: [PlannedNotification] = []
        if let o = planOverdue(now: now, openQuests: openQuests) {
            out.append(o)
        }
        if let i = planInactivity(now: now, lastActiveAt: lastActiveAt) {
            out.append(i)
        }
        if let l = planLevelTeaser(now: now, totalExp: characterTotalExp) {
            out.append(l)
        }
        return out
    }

    // MARK: - Overdue

    private func planOverdue(now: Date, openQuests: [OpenQuestInput]) -> PlannedNotification? {
        let startToday = calendar.startOfDay(for: now)
        let openOverdue = openQuests.filter { q in
            guard let d = q.dueDate else { return false }
            return calendar.startOfDay(for: d) < startToday
        }
        guard !openOverdue.isEmpty else { return nil }

        let dueDays = openOverdue.map { calendar.startOfDay(for: $0.dueDate!) }
        guard let earliestDueDay = dueDays.min() else { return nil }

        // Folgetag des frühesten Fälligkeits-Tages, 18:00
        let firstNudgeDay = calendar.date(byAdding: .day, value: 1, to: earliestDueDay) ?? earliestDueDay
        guard var at18 = dateSettingHour(18, minute: 0, on: firstNudgeDay) else { return nil }
        at18 = rollForwardIfNeeded(dateAtFixedClock: at18, hour: 18, minute: 0, now: now)

        let title = NotificationContent.overdueTitle()
        let body: String
        if openOverdue.count == 1, let one = openOverdue.first {
            body = NotificationContent.overdueBody(singleQuestTitle: one.title)
        } else {
            body = NotificationContent.overdueBodyMultiple(count: openOverdue.count)
        }

        return PlannedNotification(
            identifier: NotificationIdentifiers.overdue,
            fireDate: at18,
            title: title,
            body: body
        )
    }

    // MARK: - Inactivity

    private func planInactivity(now: Date, lastActiveAt: Date) -> PlannedNotification? {
        let baseDay = calendar.startOfDay(for: lastActiveAt)
        guard let thirdDay = calendar.date(byAdding: .day, value: 3, to: baseDay) else { return nil }
        guard var at19 = dateSettingHour(19, minute: 0, on: thirdDay) else { return nil }
        at19 = rollForwardIfNeeded(dateAtFixedClock: at19, hour: 19, minute: 0, now: now)

        return PlannedNotification(
            identifier: NotificationIdentifiers.inactivity,
            fireDate: at19,
            title: NotificationContent.inactivityTitle(),
            body: NotificationContent.inactivityBody()
        )
    }

    // MARK: - Level-Teaser

    private func planLevelTeaser(now: Date, totalExp: Int) -> PlannedNotification? {
        let evo = progression.evolution(for: totalExp)
        guard let next = evo.nextEvolution else { return nil }
        let progress = progression.progressToNextLevel(currentEXP: totalExp)
        if progress < 0.7 { return nil }
        let remaining = max(0, next.expThreshold - totalExp)
        if remaining == 0 { return nil }

        guard var day = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return nil }
        guard var at10 = dateSettingHour(10, minute: 0, on: day) else { return nil }
        at10 = rollForwardIfNeeded(dateAtFixedClock: at10, hour: 10, minute: 0, now: now)

        return PlannedNotification(
            identifier: NotificationIdentifiers.levelClose,
            fireDate: at10,
            title: NotificationContent.levelTeaserTitle(),
            body: NotificationContent.levelTeaserBody(remainingExp: remaining, nextEvolutionName: next.displayName)
        )
    }

    // MARK: - Datum & Rollen

    private func dateSettingHour(_ hour: Int, minute: Int, on day: Date) -> Date? {
        var c = calendar.dateComponents([.year, .month, .day], from: day)
        c.hour = hour
        c.minute = minute
        c.second = 0
        return calendar.date(from: c)
    }

    /// Wiederhole denselben Uhrzeit-Steckplatz tagesweise, bis `> now` (für fällige, verpasste Slots).
    private func rollForwardIfNeeded(
        dateAtFixedClock: Date,
        hour: Int,
        minute: Int,
        now: Date
    ) -> Date {
        var t = dateAtFixedClock
        var guardCount = 0
        while t <= now && guardCount < 10_000 {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: t),
                  let withClock = dateSettingHour(hour, minute: minute, on: nextDay) else { break }
            t = withClock
            guardCount += 1
        }
        return t
    }
}

// MARK: - Identifiers (Prefix ll.)

enum NotificationIdentifiers {
    static let overdue = "ll.overdue"
    static let inactivity = "ll.inactivity"
    static let levelClose = "ll.levelclose"

    static let all: [String] = [overdue, inactivity, levelClose]
}
