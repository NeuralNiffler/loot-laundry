import Foundation

enum CharacterEvolution: Int, CaseIterable, Codable, Equatable {
    case novize = 1
    case gelehrte = 2
    case magier = 3
    case arkanist = 4
    case meister = 5

    var displayName: String {
        switch self {
        case .novize:   return "Der Novize"
        case .gelehrte: return "Der Gelehrte"
        case .magier:   return "Der Magier"
        case .arkanist: return "Der Arkanist"
        case .meister:  return "Der Meister"
        }
    }

    var assetName: String {
        switch self {
        case .novize:   return "1_der_novize"
        case .gelehrte: return "2_der_gelehrte"
        case .magier:   return "3_der_magier"
        case .arkanist: return "4_der_arkanist"
        case .meister:  return "5_der_meister"
        }
    }

    /// Mindest-EXP um diese Stufe zu erreichen
    var expThreshold: Int {
        switch self {
        case .novize:   return 0
        case .gelehrte: return 100
        case .magier:   return 300
        case .arkanist: return 600
        case .meister:  return 1000
        }
    }

    var nextEvolution: CharacterEvolution? {
        CharacterEvolution(rawValue: rawValue + 1)
    }

    /// Ermittelt die korrekte Evolution anhand der gesamten EXP.
    /// Gibt die höchste Stufe zurück, deren Schwelle erreicht oder überschritten wurde.
    static func evolution(for totalEXP: Int) -> CharacterEvolution {
        allCases.reversed().first { totalEXP >= $0.expThreshold } ?? .novize
    }
}
