import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public final class SystemDesign {
    private init() {}
    
    private enum FontName: String {
        case italic = "Italic"
        case medium = "Medium"
        case mediumItalic = "Medium_Italic"
        case regular = "Regular"
        case semibold = "Semibold"
        case semiboldItalic = "Semibold_Italic"
    }
    
    public enum Typography {
        case sectionTitle
        case cardTitle
        case cardDescription
        case cardContentType
        case location
        case caption
        case primaryButton
        case secondaryButton
        case dateMonth
        case dateDay
        
        fileprivate var pointSize: CGFloat {
            switch self {
            case .sectionTitle: return 18
            case .cardTitle, .cardDescription: return 14
            case .cardContentType:return 10
            case .location, .caption, .primaryButton, .secondaryButton, .dateMonth: return 12
            case .dateDay: return 20
            }
        }

        fileprivate var fontName: String {
            switch self {
            case .sectionTitle, .cardContentType, .location, .caption, .cardDescription:
                return SystemDesign.FontName.regular.rawValue
            case .cardTitle, .primaryButton, .secondaryButton, .dateMonth, .dateDay:
                return SystemDesign.FontName.semibold.rawValue
            }
        }
        
        fileprivate var lineHeight: CGFloat {
            switch self {
            case .sectionTitle, .dateDay:
                return 23
            case .cardTitle, .location, .caption, .primaryButton, .secondaryButton, .dateMonth:
                return 19
            case .cardContentType:
                return 16
            case .cardDescription:
                return 21
            }
        }
        
        fileprivate var lineSpacing: CGFloat {
            return (self.lineHeight - self.pointSize) / 2
        }
        
        var foregroundColor: Color {
            switch self {
            case .sectionTitle: return .clear
            case .cardTitle: return .init(red: 21/255, green: 23/255, blue: 29/255)
            case .cardContentType, .location, .caption: return .init(red: 90/255, green: 91/255, blue: 102/255)
            case .primaryButton: return .init(red: 0/255, green: 122/255, blue: 80/255)
            case .secondaryButton: return .init(red: 0/255, green: 106/255, blue: 199/255)
            case .dateMonth, .dateDay: return .white
            case .cardDescription: return .init(red: 50/255, green: 52/255, blue: 64/255)
            }
        }
    }

    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 10
        public static let lg: CGFloat = 12
        public static let xl: CGFloat = 16
    }

    public enum CornerRadius {
        public static let card: CGFloat = 12
        public static let pill: CGFloat = 999
    }

    public enum Border {
        public static let thin: CGFloat = 1
    }

    public enum Palette {
        case surface
        case border
        case mutedText
        case imagePlaceholder
        case statusBackground

        fileprivate var color: Color {
            switch self {
            case .surface:
                return .white
            case .border:
                return Color.black.opacity(0.08)
            case .mutedText:
                return Color(red: 0.353, green: 0.357, blue: 0.4)
            case .imagePlaceholder:
                return Color.black.opacity(0.06)
            case .statusBackground:
                return Color.black.opacity(0.05)
            }
        }
    }

    public enum CardMetrics {
        public static let compactHeightWidth: CGFloat = 220
        public static let compactHeightMinHeight: CGFloat = 86

        public static let compactWidthWidth: CGFloat = 164
        public static let compactWidthMinHeight: CGFloat = 96

        public static let topThumbnailMinHeight: CGFloat = 150
        public static let insightMinHeight: CGFloat = 118

        public static let fallbackMinHeight: CGFloat = 96
    }

    public static func font(_ token: Typography) -> Font {
        #if canImport(UIKit)
        if UIFont(name: token.fontName, size: token.pointSize) != nil {
            return .custom(token.fontName, size: token.pointSize)
        }
        #endif
        return .system(size: token.pointSize)
    }
    
    public static func lineSpacing(_ token: Typography) -> CGFloat {
        token.lineSpacing
    }

    public static func color(_ token: Typography) -> Color {
        token.foregroundColor
    }

    public static func color(_ token: Palette) -> Color {
        token.color
    }
    
    public static var buttonForegroundColor: Color {
        return Color(red: 0, green: 106/255, blue: 199/255)
    }
    
    public static var buttonSize: CGSize {
        return .init(width: 44, height: 44)
    }
    
    public static var registeredButtonColor: Color {
        return Color(red: 0, green: 122/255, blue: 80/255)
    }

    public static func accent(for contentType: ContentType) -> Color {
        switch contentType {
        case .document:
            return Color(red: 0.18, green: 0.41, blue: 0.69)
        case .onDemandWebinar, .upcomingWebinar:
            return Color(red: 0.69, green: 0.2, blue: 0.27)
        case .video:
            return Color(red: 0.52, green: 0.21, blue: 0.67)
        case .podcast:
            return Color(red: 0.0, green: 0.49, blue: 0.43)
        case .inquiry:
            return Color(red: 0.79, green: 0.47, blue: 0.11)
        case .conference:
            return Color(red: 0.77, green: 0.36, blue: 0.12)
        default:
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        }
    }
}
