import SwiftUI

/// Jobka brand colors — single source of truth.
/// Matches jobka.cz: primary #E41B61, secondary #981449, accent #FF5892.
enum JobkaTheme {
    // MARK: - Brand Colors
    static let primary = Color(hex: "#E41B61")
    static let secondary = Color(hex: "#981449")
    static let accent = Color(hex: "#FF5892")

    // MARK: - Semantic Colors
    static let headerBackground = primary
    static let loginGradientStart = primary
    static let loginGradientMiddle = accent
    static let loginGradientEnd = Color(hex: "#fdf2f8")

    // MARK: - Gradients
    static let brandGradient = LinearGradient(
        colors: [loginGradientStart, loginGradientMiddle, loginGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let headerGradient = LinearGradient(
        colors: [primary, Color(hex: "#C2164F")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Dark Mode Variants
    static let darkBrandGradient = LinearGradient(
        colors: [Color(hex: "#1a0a10"), Color(hex: "#111111")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
