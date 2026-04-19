import Foundation

enum TaskDifficulty: String, CaseIterable, Codable {
    case easy   = "Leicht"
    case medium = "Mittel"
    case hard   = "Schwer"

    var expReward: Int {
        switch self {
        case .easy:   return 5
        case .medium: return 10
        case .hard:   return 20
        }
    }

    var symbolName: String {
        switch self {
        case .easy:   return "bolt"
        case .medium: return "bolt.fill"
        case .hard:   return "bolt.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .easy:   return "Leicht  +\(expReward) EXP"
        case .medium: return "Mittel  +\(expReward) EXP"
        case .hard:   return "Schwer  +\(expReward) EXP"
        }
    }
}

enum RecurrenceRule: String, CaseIterable, Codable {
    case daily   = "Täglich"
    case weekly  = "Wöchentlich"
}
