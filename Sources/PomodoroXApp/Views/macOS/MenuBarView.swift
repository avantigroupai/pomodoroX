import SwiftUI
import PomodoroXCore

public struct MenuBarView: View {
    @Bindable var viewModel: PomodoroViewModel

    public init(viewModel: PomodoroViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.currentPhase.iconName)
                        .foregroundStyle(phaseColor)
                    Text(viewModel.currentPhase.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Text(viewModel.formattedTime)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }

            // Mini Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient.phaseGradient(for: viewModel.currentPhase))
                        .frame(width: max(0, geo.size.width * viewModel.progress))
                }
            }
            .frame(height: 6)

            // Active Task
            if let task = viewModel.activeTask {
                HStack(spacing: 6) {
                    Image(systemName: task.category.iconName)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.pxFocusPrimary)
                    Text(task.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            // Quick Actions
            HStack(spacing: 8) {
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Label(
                        viewModel.timerState == .running ? "Pause" : "Start",
                        systemImage: viewModel.timerState == .running ? "pause.fill" : "play.fill"
                    )
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(LinearGradient.phaseGradient(for: viewModel.currentPhase))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .padding(8)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Reset Timer")

                Button {
                    viewModel.skipPhase()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .padding(8)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Skip to next phase")
            }

            Divider()

            // Phase Quick Switcher
            HStack(spacing: 4) {
                ForEach(PomodoroPhase.allCases) { phase in
                    let isSelected = viewModel.currentPhase == phase
                    let color = phaseColor(for: phase)
                    Button {
                        viewModel.selectPhase(phase)
                    } label: {
                        Text(phase == .focus ? "Focus" : (phase == .shortBreak ? "Short" : "Long"))
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? color : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(isSelected ? color.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 250)
    }

    private var phaseColor: Color {
        phaseColor(for: viewModel.currentPhase)
    }

    private func phaseColor(for phase: PomodoroPhase) -> Color {
        switch phase {
        case .focus: return .pxFocusPrimary
        case .shortBreak: return .pxShortBreakPrimary
        case .longBreak: return .pxLongBreakPrimary
        }
    }
}
