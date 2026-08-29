import SwiftUI
import PomodoroXCore

public extension Color {
    static let pxBackground = Color(red: 0.07, green: 0.08, blue: 0.11)
    static let pxSurface = Color(red: 0.11, green: 0.13, blue: 0.18)
    static let pxSurfaceLight = Color(red: 0.16, green: 0.19, blue: 0.26)

    // Phase Accents
    static let pxFocusPrimary = Color(red: 1.00, green: 0.35, blue: 0.28) // Vibrant coral ember
    static let pxFocusSecondary = Color(red: 1.00, green: 0.58, blue: 0.18) // Warm amber

    static let pxShortBreakPrimary = Color(red: 0.18, green: 0.84, blue: 0.72) // Mint cyan
    static let pxShortBreakSecondary = Color(red: 0.22, green: 0.65, blue: 0.95) // Sky azure

    static let pxLongBreakPrimary = Color(red: 0.68, green: 0.38, blue: 0.98) // Royal purple
    static let pxLongBreakSecondary = Color(red: 0.92, green: 0.35, blue: 0.82) // Orchid magenta

    static let pxCardBorder = Color.white.opacity(0.12)
    static let pxTextSecondary = Color(red: 0.62, green: 0.66, blue: 0.75)
}

public extension LinearGradient {
    static func phaseGradient(for phase: PomodoroPhase) -> LinearGradient {
        switch phase {
        case .focus:
            return LinearGradient(
                colors: [.pxFocusPrimary, .pxFocusSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .shortBreak:
            return LinearGradient(
                colors: [.pxShortBreakPrimary, .pxShortBreakSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .longBreak:
            return LinearGradient(
                colors: [.pxLongBreakPrimary, .pxLongBreakSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static var darkCardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
