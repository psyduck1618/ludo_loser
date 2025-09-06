import SwiftUI

enum Theme {
    // Palette
    static let boardDark = Color(red: 0.10, green: 0.10, blue: 0.10) // near black
    static let boardLight = Color(red: 0.92, green: 0.92, blue: 0.92) // near white
    static let boardWood = Color(red: 0.23, green: 0.16, blue: 0.10) // brown wood
    static let accent = Color(red: 0.96, green: 0.74, blue: 0.08) // subtle gold accent
    static let tokenBlack = Color.black
    static let tokenWhite = Color.white

    // Layout
    static let cornerRadius: CGFloat = 16
    static let boardPadding: CGFloat = 16
    static let tokenSize: CGFloat = 22
    static let diceSize: CGFloat = 80
}

extension ShapeStyle where Self == LinearGradient {
    static var glassHighlight: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.50), Color.white.opacity(0.05)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

