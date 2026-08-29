import SwiftUI
import PomodoroXCore

public struct ControlButtonsView: View {
    public var timerState: TimerState
    public var phase: PomodoroPhase
    public var onTogglePlayPause: () -> Void
    public var onReset: () -> Void
    public var onSkip: () -> Void

    public init(
        timerState: TimerState,
        phase: PomodoroPhase,
        onTogglePlayPause: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.timerState = timerState
        self.phase = phase
        self.onTogglePlayPause = onTogglePlayPause
        self.onReset = onReset
        self.onSkip = onSkip
    }

    public var body: some View {
        HStack(spacing: 32) {
            // Reset Button
            Button(action: onReset) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 50, height: 50)
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
            .buttonStyle(SpringScaleButtonStyle())
            .help("Reset Timer (⌘R)")
            .accessibilityLabel("Reset timer")
            .accessibilityHint("Resets current session to full duration")

            // Main Play / Pause Button
            Button(action: onTogglePlayPause) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.phaseGradient(for: phase))
                        .frame(width: 74, height: 74)
                        .shadow(color: phaseColor.opacity(timerState == .running ? 0.65 : 0.35), radius: timerState == .running ? 16 : 8, x: 0, y: 6)

                    Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: timerState == .running ? 0 : 2)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(SpringScaleButtonStyle())
            .help("Start / Pause (Space)")
            .accessibilityLabel(timerState == .running ? "Pause timer" : "Start timer")
            .accessibilityHint("Toggles timer countdown")

            // Skip Button
            Button(action: onSkip) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 50, height: 50)
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
            .buttonStyle(SpringScaleButtonStyle())
            .help("Skip to next phase (⌘K)")
            .accessibilityLabel("Skip phase")
            .accessibilityHint("Advances to next session phase")
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .focus: return .pxFocusPrimary
        case .shortBreak: return .pxShortBreakPrimary
        case .longBreak: return .pxLongBreakPrimary
        }
    }
}

public struct SpringScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
