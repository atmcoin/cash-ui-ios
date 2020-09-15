
import Foundation
import UIKit

class Theme {
    
    enum ColorHex: String {
        case primaryBackground = "#1E1E1E"
        case secondaryBackground = "#292929"
        case tertiaryBackground = "292929" // enums dont accept duplicate values, so cheating them by having one with the hash (#) and the other one without
        
        case text = "#FFFFFF"
        
        case accent = "#5B6DEE"
        case accentHighlighted = "#5667E0"
        case success = "#5BE081"
        case error = "#EA6654"
    }
    
    //
    // Colors
    //
    
    static var primaryBackground: UIColor {
        return color(.primaryBackground)
    }
    
    static var secondaryBackground: UIColor {
        return color(.secondaryBackground)
    }
    
    static var tertiaryBackground: UIColor {
        return color(.tertiaryBackground)
    }
    
    // returns a color with the given enum
    public static func color(_ hex: ColorHex) -> UIColor {
        return UIColor.fromHex(hex.rawValue)
    }
}
