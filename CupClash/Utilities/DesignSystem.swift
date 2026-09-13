import SwiftUI

enum AppCredits {
    static let createdBy = "Created by Ronell Bradley"
    static let owner = "Property of Bradley Virtual Solutions, LLC"
    static let fullLine = "Created by Ronell Bradley, Property of Bradley Virtual Solutions, LLC"
}

enum CupClashTheme {
    static let navy = Color(red: 0.031, green: 0.043, blue: 0.118)
    static let navyDeep = Color(red: 0.016, green: 0.020, blue: 0.070)
    static let navyPanel = Color(red: 0.070, green: 0.086, blue: 0.176)
    static let cyan = Color(red: 0.00, green: 0.91, blue: 0.98)
    static let violet = Color(red: 0.62, green: 0.28, blue: 0.98)
    static let neonGreen = Color(red: 0.22, green: 0.98, blue: 0.45)
    static let warning = Color(red: 1.00, green: 0.58, blue: 0.18)
    static let gold = Color(red: 1.00, green: 0.80, blue: 0.24)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.78, green: 0.82, blue: 0.90)
    static let textMuted = Color(red: 0.58, green: 0.64, blue: 0.74)

    static let spacingXS: CGFloat = 6
    static let spacingS: CGFloat = 10
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    static let radiusS: CGFloat = 12
    static let radiusM: CGFloat = 18
    static let radiusL: CGFloat = 26

    static let buttonHeight: CGFloat = 56
    static let minTouch: CGFloat = 44

    static let titleFont = Font.system(size: 40, weight: .heavy, design: .rounded)
    static let subtitleFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineFont = Font.system(.title3, design: .rounded).weight(.bold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded).weight(.semibold)

    static let spring = Animation.spring(duration: 0.42, bounce: 0.18)
    static let quick = Animation.easeOut(duration: 0.22)
    static let splashDuration: Double = 1.7

    static func background(highContrast: Bool) -> LinearGradient {
        LinearGradient(
            colors: highContrast
                ? [Color.black, navyDeep]
                : [navyDeep, navy, Color(red: 0.08, green: 0.05, blue: 0.20)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func neonGradient() -> LinearGradient {
        LinearGradient(
            colors: [cyan, violet],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func goldGradient() -> LinearGradient {
        LinearGradient(
            colors: [gold, Color(red: 1.0, green: 0.62, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ScreenBackground: View {
    var highContrast = false

    var body: some View {
        CupClashTheme.background(highContrast: highContrast)
            .ignoresSafeArea()
            .overlay {
                if !highContrast {
                    RadialGradient(
                        colors: [CupClashTheme.violet.opacity(0.18), .clear],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 420
                    )
                    .ignoresSafeArea()
                }
            }
    }
}
