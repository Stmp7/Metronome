import SwiftUI

// Enum to represent accent levels
enum AccentLevel: String, CaseIterable, Equatable {
    case forte = "f"
    case mezzoForte = "mf" 
    case piano = "p"
    case mute = "mute"
    
    var color: Color {
        switch self {
        case .forte:
            return Color(hex: "#FF3E9A") // Bright pink
        case .mezzoForte:
            return Color(hex: "#FF8AC4") // Light pink
        case .piano:
            return Color(hex: "#4D6A9A") // Gray-blue
        case .mute:
            return Color.gray.opacity(0.7) // Gray for outline
        }
    }
    
    var fillOpacity: Double {
        switch self {
        case .forte: return 1.0
        case .mezzoForte: return 0.8
        case .piano: return 0.6
        case .mute: return 0.0 // No fill for mute (hollow)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .forte, .mezzoForte, .piano:
            return color
        case .mute:
            return Color.gray.opacity(0.7) // Visible gray border
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .mute: 
            return 1.5 // Thicker border for mute to emphasize hollow state
        default:
            return 1.0
        }
    }
    
    func next() -> AccentLevel {
        switch self {
        case .forte: return .mezzoForte
        case .mezzoForte: return .piano
        case .piano: return .mute
        case .mute: return .forte
        }
    }
} 