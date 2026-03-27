import SwiftUI

enum DarknetTheme {
    static let background = Color(hex: 0x0A0A0A)
    static let cardBackground = Color(hex: 0x141414)
    static let accent = Color(hex: 0x00FF88)
    static let danger = Color(hex: 0xFF0033)
    static let textPrimary = Color(hex: 0xE0E0E0)
    static let textSecondary = Color(hex: 0x888888)
    static let borderColor = Color(hex: 0x00FF88).opacity(0.3)

    static let monoFont: Font = .system(.body, design: .monospaced)

    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

struct DarknetCardStyle: ViewModifier {
    var glowColor: Color = DarknetTheme.accent

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(DarknetTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DarknetTheme.borderColor, lineWidth: 1)
            )
            .shadow(color: glowColor.opacity(0.15), radius: 8, x: 0, y: 0)
    }
}

extension View {
    func darknetCard(glow: Color = DarknetTheme.accent) -> some View {
        modifier(DarknetCardStyle(glowColor: glow))
    }
}

struct GlowingBorder: ViewModifier {
    var color: Color = DarknetTheme.accent
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}
