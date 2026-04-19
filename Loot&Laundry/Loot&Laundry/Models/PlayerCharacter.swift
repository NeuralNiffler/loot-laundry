import Foundation
import SwiftData

@Model
final class PlayerCharacter {
    var id: UUID = UUID()
    var name: String = "Held"
    var totalEXP: Int = 0
    var createdAt: Date = Date()

    init(name: String = "Held") {
        self.name = name
    }

    var currentEvolution: CharacterEvolution {
        CharacterEvolution.evolution(for: totalEXP)
    }

    /// EXP innerhalb der aktuellen Stufe (seit dem letzten Stufenaufstieg)
    var expInCurrentLevel: Int {
        totalEXP - currentEvolution.expThreshold
    }

    /// EXP die für den nächsten Stufenaufstieg insgesamt nötig sind (nil auf Max-Stufe)
    var expRequiredForNextLevel: Int? {
        guard let next = currentEvolution.nextEvolution else { return nil }
        return next.expThreshold - currentEvolution.expThreshold
    }

    /// Fortschritt 0.0 ... 1.0 zur nächsten Stufe (1.0 = Max-Stufe)
    var progressToNextLevel: Double {
        guard let required = expRequiredForNextLevel, required > 0 else { return 1.0 }
        return min(1.0, Double(expInCurrentLevel) / Double(required))
    }
}
