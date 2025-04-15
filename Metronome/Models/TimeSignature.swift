import Foundation

enum TimeSignature: String, CaseIterable, Hashable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case sixEight = "6/8"
    
    var beatsPerBar: Int {
        switch self {
        case .twoFour: return 2
        case .threeFour: return 3
        case .fourFour: return 4
        case .sixEight: return 6
        }
    }
    
    var subdivision: Int {
        switch self {
        case .sixEight: return 3  // 6/8 is typically counted as 2 beats with 3 subdivisions
        default: return 1
        }
    }
    
    var description: String {
        return rawValue
    }
} 