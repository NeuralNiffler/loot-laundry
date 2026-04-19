// SETUP: Um diese Tests auszuführen muss in Xcode ein Unit-Test-Target angelegt werden:
// File > New > Target > Unit Testing Bundle > Name: "Loot&LaundryTests"
// Danach diese Datei dem neuen Target zuweisen.

import Testing
@testable import Loot_Laundry

@Suite("ProgressionService Tests")
struct ProgressionServiceTests {

    let sut = ProgressionService()

    // MARK: - EXP Vergabe

    @Test("Leichte Aufgabe gibt 5 EXP")
    func expRewardEasy() {
        #expect(sut.expReward(for: .easy) == 5)
    }

    @Test("Mittlere Aufgabe gibt 10 EXP")
    func expRewardMedium() {
        #expect(sut.expReward(for: .medium) == 10)
    }

    @Test("Schwere Aufgabe gibt 20 EXP")
    func expRewardHard() {
        #expect(sut.expReward(for: .hard) == 20)
    }

    // MARK: - Evolution Berechnung

    @Test("0 EXP = Novize")
    func evolutionAtZero() {
        #expect(sut.evolution(for: 0) == .novize)
    }

    @Test("99 EXP = Novize (Grenzwert knapp darunter)")
    func evolutionBeforeGelehrte() {
        #expect(sut.evolution(for: 99) == .novize)
    }

    @Test("100 EXP = Gelehrte (Schwellenwert exakt)")
    func evolutionAtGelehrte() {
        #expect(sut.evolution(for: 100) == .gelehrte)
    }

    @Test("299 EXP = Gelehrte")
    func evolutionBeforeMagier() {
        #expect(sut.evolution(for: 299) == .gelehrte)
    }

    @Test("300 EXP = Magier")
    func evolutionAtMagier() {
        #expect(sut.evolution(for: 300) == .magier)
    }

    @Test("600 EXP = Arkanist")
    func evolutionAtArkanist() {
        #expect(sut.evolution(for: 600) == .arkanist)
    }

    @Test("1000 EXP = Meister")
    func evolutionAtMeister() {
        #expect(sut.evolution(for: 1000) == .meister)
    }

    @Test("Weit über Maximum bleibt Meister")
    func evolutionAboveMaximum() {
        #expect(sut.evolution(for: 9999) == .meister)
    }

    // MARK: - Stufenaufstieg Erkennung

    @Test("willEvolve ist false wenn keine neue Stufe erreicht")
    func willNotEvolve() {
        #expect(sut.willEvolve(currentEXP: 50, earnedEXP: 10) == false)
    }

    @Test("willEvolve ist true wenn Schwellenwert überschritten wird")
    func willEvolveAtThreshold() {
        #expect(sut.willEvolve(currentEXP: 95, earnedEXP: 10) == true)
    }

    @Test("willEvolve ist true genau am Schwellenwert")
    func willEvolveExactlyAtThreshold() {
        #expect(sut.willEvolve(currentEXP: 90, earnedEXP: 10) == true)
    }

    @Test("newEvolution gibt korrekte neue Stufe zurück")
    func newEvolutionReturnsCorrectStage() {
        let result = sut.newEvolution(currentEXP: 95, earnedEXP: 10)
        #expect(result == .gelehrte)
    }

    @Test("newEvolution gibt nil zurück wenn kein Aufstieg")
    func newEvolutionNilWhenNoLevelUp() {
        #expect(sut.newEvolution(currentEXP: 50, earnedEXP: 5) == nil)
    }

    // MARK: - Fortschritt Berechnung

    @Test("Fortschritt ist 0.0 am Anfang einer Stufe")
    func progressAtLevelStart() {
        let progress = sut.progressToNextLevel(currentEXP: 0)
        #expect(progress == 0.0)
    }

    @Test("Fortschritt ist 0.5 in der Mitte einer Stufe")
    func progressAtMidLevel() {
        // Novize: 0-100 EXP → 50 EXP = 50%
        let progress = sut.progressToNextLevel(currentEXP: 50)
        #expect(progress == 0.5)
    }

    @Test("Fortschritt ist 1.0 auf Max-Stufe")
    func progressAtMaxLevel() {
        let progress = sut.progressToNextLevel(currentEXP: 1000)
        #expect(progress == 1.0)
    }

    @Test("EXP in aktueller Stufe korrekt berechnet")
    func expInCurrentLevel() {
        // Bei 350 EXP: Magier-Schwelle = 300 → 50 EXP in dieser Stufe
        #expect(sut.expInCurrentLevel(currentEXP: 350) == 50)
    }

    @Test("EXP bis zur nächsten Stufe korrekt berechnet")
    func expRequiredForNextLevel() {
        // Novize (0) → Gelehrte (100): 100 EXP gesamt nötig
        #expect(sut.expRequiredForNextLevel(currentEXP: 0) == 100)
    }

    @Test("EXP bis zur nächsten Stufe ist nil auf Max-Stufe")
    func expRequiredIsNilAtMaxLevel() {
        #expect(sut.expRequiredForNextLevel(currentEXP: 1000) == nil)
    }
}

// MARK: - CharacterEvolution Tests

@Suite("CharacterEvolution Tests")
struct CharacterEvolutionTests {

    @Test("Alle Stufen haben eindeutige Schwellenwerte")
    func uniqueThresholds() {
        let thresholds = CharacterEvolution.allCases.map { $0.expThreshold }
        #expect(Set(thresholds).count == thresholds.count)
    }

    @Test("Schwellenwerte sind aufsteigend sortiert")
    func ascendingThresholds() {
        let thresholds = CharacterEvolution.allCases.map { $0.expThreshold }
        let sorted = thresholds.sorted()
        #expect(thresholds == sorted)
    }

    @Test("nextEvolution ist nil für Meister")
    func noNextEvolutionAtMax() {
        #expect(CharacterEvolution.meister.nextEvolution == nil)
    }

    @Test("Asset-Namen existieren für alle Stufen")
    func assetNamesNotEmpty() {
        for evo in CharacterEvolution.allCases {
            #expect(!evo.assetName.isEmpty)
        }
    }
}
