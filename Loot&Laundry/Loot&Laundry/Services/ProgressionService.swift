import Foundation

/// Reine Geschäftslogik für EXP-Vergabe und Charakter-Evolution.
/// Keine Abhängigkeit zu SwiftData – dadurch vollständig testbar.
struct ProgressionService {

    // MARK: - EXP Berechnung

    func expReward(for difficulty: TaskDifficulty) -> Int {
        difficulty.expReward
    }

    // MARK: - Evolution

    func evolution(for totalEXP: Int) -> CharacterEvolution {
        CharacterEvolution.evolution(for: totalEXP)
    }

    /// Gibt an ob das Hinzufügen von `earnedEXP` eine Stufenaufstieg auslöst.
    func willEvolve(currentEXP: Int, earnedEXP: Int) -> Bool {
        let before = CharacterEvolution.evolution(for: currentEXP)
        let after  = CharacterEvolution.evolution(for: currentEXP + earnedEXP)
        return after != before
    }

    /// Gibt die neue Evolution nach EXP-Gewinn zurück – nur wenn ein Aufstieg stattfand.
    func newEvolution(currentEXP: Int, earnedEXP: Int) -> CharacterEvolution? {
        guard willEvolve(currentEXP: currentEXP, earnedEXP: earnedEXP) else { return nil }
        return CharacterEvolution.evolution(for: currentEXP + earnedEXP)
    }

    // MARK: - Fortschritt

    /// Fortschritt 0.0 ... 1.0 zur nächsten Stufe
    func progressToNextLevel(currentEXP: Int) -> Double {
        let evo = CharacterEvolution.evolution(for: currentEXP)
        guard let next = evo.nextEvolution else { return 1.0 }
        let expInLevel    = currentEXP - evo.expThreshold
        let expForLevel   = next.expThreshold - evo.expThreshold
        guard expForLevel > 0 else { return 1.0 }
        return min(1.0, Double(expInLevel) / Double(expForLevel))
    }

    /// EXP innerhalb der aktuellen Stufe
    func expInCurrentLevel(currentEXP: Int) -> Int {
        let evo = CharacterEvolution.evolution(for: currentEXP)
        return currentEXP - evo.expThreshold
    }

    /// EXP die für den Abschluss der aktuellen Stufe noch fehlen (nil = Max-Stufe)
    func expRequiredForNextLevel(currentEXP: Int) -> Int? {
        let evo = CharacterEvolution.evolution(for: currentEXP)
        guard let next = evo.nextEvolution else { return nil }
        return next.expThreshold - evo.expThreshold
    }
}
