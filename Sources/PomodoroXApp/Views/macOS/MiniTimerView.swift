import SwiftUI
import PomodoroXCore

public struct MiniTimerView: View {
    @Bindable var viewModel: PomodoroViewModel

    public init(viewModel: PomodoroViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color.pxBackground.ignoresSafeArea()

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 8, height: 8)

                    Text(viewModel.currentPhase.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(phaseColor)

                    Spacer()

                    Button {
                        viewModel.togglePlayPause()
                    } label: {
                        Image(systemName: viewModel.timerState == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text(viewModel.formattedTime)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                // Mini progress line
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule().fill(LinearGradient.phaseGradient(for: viewModel.currentPhase))
                            .frame(width: max(0, geo.size.width * viewModel.progress))
                    }
                }
                .frame(height: 4)
            }
            .padding(12)
        }
        .frame(width: 170, height: 95)
    }

    private var phaseColor: Color {
        switch viewModel.currentPhase {
        case .focus: return .pxFocusPrimary
        case .shortBreak: return .pxShortBreakPrimary
        case .longBreak: return .pxLongBreakPrimary
        }
    }
}
