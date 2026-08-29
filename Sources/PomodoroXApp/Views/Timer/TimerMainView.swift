import SwiftUI
import PomodoroXCore

public struct TimerMainView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Bindable var tasksViewModel: TasksViewModel
    @Binding var selectedTab: Int

    public init(
        viewModel: PomodoroViewModel,
        tasksViewModel: TasksViewModel,
        selectedTab: Binding<Int>
    ) {
        self.viewModel = viewModel
        self.tasksViewModel = tasksViewModel
        self._selectedTab = selectedTab
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Active Task Header Banner
            activeTaskBanner

            Spacer(minLength: 4)

            // Phase Selector
            PhaseSelectorView(
                selectedPhase: viewModel.currentPhase,
                onSelect: { phase in
                    viewModel.selectPhase(phase)
                }
            )

            Spacer(minLength: 4)

            // Circular Glowing Progress Timer
            CircularProgressRing(
                progress: viewModel.progress,
                timeFormatted: viewModel.formattedTime,
                phase: viewModel.currentPhase,
                isRunning: viewModel.timerState == .running,
                onAdjustTime: { delta in
                    viewModel.adjustTime(by: delta)
                }
            )

            // Session subtitle
            Text(viewModel.phaseProgressTitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.pxTextSecondary)

            Spacer(minLength: 4)

            // Control Buttons
            ControlButtonsView(
                timerState: viewModel.timerState,
                phase: viewModel.currentPhase,
                onTogglePlayPause: {
                    viewModel.togglePlayPause()
                },
                onReset: {
                    viewModel.reset()
                },
                onSkip: {
                    viewModel.skipPhase()
                }
            )

            Spacer(minLength: 4)

            // Ambient Soundbar
            AmbientSoundBarView(
                selectedSound: viewModel.selectedAmbientSound,
                isPlaying: viewModel.isAmbientPlaying,
                volume: viewModel.ambientVolume,
                onSelectSound: { sound in
                    viewModel.setAmbientSound(sound)
                },
                onVolumeChange: { vol in
                    viewModel.setAmbientVolume(vol)
                }
            )
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pxBackground)
        .onChange(of: tasksViewModel.selectedTaskId) { _, newId in
            viewModel.activeTask = tasksViewModel.activeTask
        }
        .onAppear {
            viewModel.activeTask = tasksViewModel.activeTask
        }
    }

    // MARK: - Active Task Banner
    private var activeTaskBanner: some View {
        HStack(spacing: 12) {
            if let task = tasksViewModel.activeTask {
                HStack(spacing: 8) {
                    Image(systemName: task.category.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.pxFocusPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text("Pomodoros: \(task.completedPomodoros)/\(task.estimatedPomodoros)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.pxTextSecondary)
                        }
                    }
                }

                Spacer()

                Button {
                    selectedTab = 1 // Switch to Tasks tab
                } label: {
                    Text("Change")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(Color.pxShortBreakPrimary)
                    Text("No task selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.pxTextSecondary)
                }

                Spacer()

                Button {
                    selectedTab = 1
                } label: {
                    Label("Choose Task", systemImage: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
