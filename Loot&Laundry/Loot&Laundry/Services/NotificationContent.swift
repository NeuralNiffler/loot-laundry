import Foundation

/// Zentrale Copy für lokale Benachrichtigungen (MVP, deutsch, RPG-Ton).
enum NotificationContent {

    // MARK: - Overdue

    static func overdueTitle() -> String {
        "Dein Held wartet…"
    }

    static func overdueBody(singleQuestTitle: String) -> String {
        "„\(singleQuestTitle)“ ruft. Ein winziger Schritt genügt – vielleicht gleich heute am Abend?"
    }

    static func overdueBodyMultiple(count: Int) -> String {
        "\(count) Quests harren deiner. Kein Druck – dein Stapel wird nur sichtbar, wenn du nachsiehst."
    }

    // MARK: - Inactivity

    static func inactivityTitle() -> String {
        "Die Tavernen-Tür knarrt…"
    }

    static func inactivityBody() -> String {
        "Hier riecht’s noch nach Abenteuern. Ein kurzer Blick in dein Quest-Log reicht, um weitermachen zu wollen."
    }

    // MARK: - Level-Teaser

    static func levelTeaserTitle() -> String {
        "Fast am nächsten Aufstieg"
    }

    static func levelTeaserBody(remainingExp: Int, nextEvolutionName: String) -> String {
        "Nur noch \(remainingExp) EXP bis „\(nextEvolutionName)“. Ein Quick-Quest genügt vielleicht schon."
    }
}
