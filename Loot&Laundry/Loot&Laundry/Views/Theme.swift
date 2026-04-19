import SwiftUI

/// Zentrales Design-System für den RPG-Look der App.
/// Alle Views greifen ausschließlich auf diese Werte zurück.
enum Theme {

    // MARK: - Hintergrundfarben

    /// Tiefdunkler Hintergrund – erzeugt die düstere RPG-Atmosphäre
    static let background     = Color(red: 0.07, green: 0.07, blue: 0.11)

    /// Etwas hellere Karte / NavigationBar
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.18)

    // MARK: - Akzentfarben

    /// Gold – primäre RPG-Akzentfarbe für Stufenaufstiege, wichtige Elemente
    static let gold           = Color(red: 1.0, green: 0.78, blue: 0.24)

    /// Magisches Lila – EXP-Balken und Fortschrittsanzeigen
    static let expColor       = Color(red: 0.55, green: 0.25, blue: 0.95)

    /// Grün – Erfolg / erledigte Quests
    static let success        = Color(red: 0.25, green: 0.85, blue: 0.45)

    // MARK: - Textfarben

    static let textPrimary    = Color.white
    static let textSecondary  = Color(white: 0.55)
}
