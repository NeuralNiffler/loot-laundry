import Foundation
import SwiftData
import UserNotifications

/// Fassade: SwiftData fetchen, planen, `UNUserNotificationCenter` füttern.
@MainActor
final class NotificationSyncService {
    static let shared = NotificationSyncService()

    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults
    private var planner: NotificationPlanner

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard,
        planner: NotificationPlanner = NotificationPlanner()
    ) {
        self.center = center
        self.defaults = defaults
        self.planner = planner
    }

    // MARK: - Szenen-Lifecycle

    /// Aufruf bei `scenePhase == .active` — aktualisiert letzte Aktivität und synchronisiert geplante Reminder.
    func onSceneBecameActive(context: ModelContext) async {
        await resync(context: context)
    }

    // MARK: - Permission (nach erster Quest)

    /// Einmalig nach dem ersten abgeschlossenen Quest-Instanz-Abhaken (siehe Plan).
    func requestAuthorizationIfNeededOnFirstCompletion() async {
        if defaults.bool(forKey: UserDefaultsKey.askedAfterFirstQuest) { return }
        defaults.set(true, forKey: UserDefaultsKey.askedAfterFirstQuest)
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Resync

    func resync(context: ModelContext) async {
        setLastActiveNow()

        let status = (await center.notificationSettings()).authorizationStatus
        if status == .notDetermined {
            center.removePendingNotificationRequests(withIdentifiers: NotificationIdentifiers.all)
            return
        }
        // Ausstehende ll.* entfernen, falls Berechtigung dauerhaft entzogen
        if status == .denied {
            center.removePendingNotificationRequests(withIdentifiers: NotificationIdentifiers.all)
            return
        }

        let lastActive = (defaults.object(forKey: UserDefaultsKey.lastActiveAt) as? Date) ?? Date()
        let open = fetchOpenQuestInputs(context: context)
        let exp = fetchTotalExp(context: context)
        let now = Date()
        let plans = planner.plannedNotifications(
            now: now,
            lastActiveAt: lastActive,
            openQuests: open,
            characterTotalExp: exp
        )

        center.removePendingNotificationRequests(withIdentifiers: NotificationIdentifiers.all)
        for p in plans {
            await addRequest(from: p)
        }
    }

    // MARK: - Intern

    private func setLastActiveNow() {
        defaults.set(Date(), forKey: UserDefaultsKey.lastActiveAt)
    }

    private func fetchOpenQuestInputs(context: ModelContext) -> [OpenQuestInput] {
        let descriptor = FetchDescriptor<QuestInstance>(predicate: #Predicate<QuestInstance> { $0.completedAt == nil })
        guard let rows = try? context.fetch(descriptor) else { return [] }
        return rows.map { OpenQuestInput(id: $0.id, title: $0.title, dueDate: $0.dueDate) }
    }

    private func fetchTotalExp(context: ModelContext) -> Int {
        let d = FetchDescriptor<PlayerCharacter>()
        let chars = (try? context.fetch(d)) ?? []
        return chars.first?.totalEXP ?? 0
    }

    private func addRequest(from planned: PlannedNotification) async {
        let content = UNMutableNotificationContent()
        content.title = planned.title
        content.body = planned.body
        content.sound = .default

        let interval = max(1, planned.fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let req = UNNotificationRequest(identifier: planned.identifier, content: content, trigger: trigger)
        _ = try? await center.add(req)
    }
}

// MARK: - UserDefaults

private enum UserDefaultsKey {
    static let lastActiveAt = "ll.notif.lastActiveAt"
    static let askedAfterFirstQuest = "ll.notif.askedAfterFirstQuest"
}
