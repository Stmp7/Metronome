import Foundation

enum TimeSignature: String, CaseIterable, Hashable {
    // Common time signatures
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case fiveFour = "5/4"
    case sixEight = "6/8"
    case sevenEight = "7/8"
    case nineEight = "9/8"
    case twelveEight = "12/8"
    
    // Custom time signatures can be added as needed
    
    var beatsPerBar: Int {
        switch self {
        case .twoFour: return 2
        case .threeFour: return 3
        case .fourFour: return 4
        case .fiveFour: return 5
        case .sixEight: return 6
        case .sevenEight: return 7
        case .nineEight: return 9
        case .twelveEight: return 12
        }
    }
    
    var subdivision: Int {
        switch self {
        case .sixEight, .nineEight, .twelveEight: return 3  // Compound meters have 3 subdivisions
        default: return 1
        }
    }
    
    var description: String {
        return rawValue
    }
    
    // Helper for UI display
    var numerator: Int {
        return beatsPerBar
    }
    
    // Helper for UI display
    var denominator: Int {
        switch self {
        case .sixEight, .sevenEight, .nineEight, .twelveEight:
            return 8
        default:
            return 4
        }
    }
} 