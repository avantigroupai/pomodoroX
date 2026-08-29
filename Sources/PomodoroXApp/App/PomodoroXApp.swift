import SwiftUI
import PomodoroXCore

@main
struct PomodoroXApp: App {
    @State private var environment = AppEnvironment.shared
    @State private var selectedTab: Int = 0
    @State private var showingSettings: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MainContentView(
                environment: environment,
                selectedTab: $selectedTab,
                showingSettings: $showingSettings
            )
            .frame(minWidth: 440, maxWidth: 640, minHeight: 680, maxHeight: 900)
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    environment.pomodoroViewModel.synchronizeClock()
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 460, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Timer") {
                Button(environment.pomodoroViewModel.timerState == .running ? "Pause" : "Start") {
                    environment.pomodoroViewModel.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Reset") {
                    environment.pomodoroViewModel.reset()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Skip Phase") {
                    environment.pomodoroViewModel.skipPhase()
                }
                .keyboardShortcut("k", modifiers: .command)

                Divider()

                Button("Add 5 Minutes") {
                    environment.pomodoroViewModel.adjustTime(by: 5)
                }
                .keyboardShortcut("=", modifiers: .command)

                Button("Subtract 5 Minutes") {
                    environment.pomodoroViewModel.adjustTime(by: -5)
                }
                .keyboardShortcut("-", modifiers: .command)

                Divider()

                Button("Focus Phase") {
                    environment.pomodoroViewModel.selectPhase(.focus)
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])

                Button("Short Break") {
                    environment.pomodoroViewModel.selectPhase(.shortBreak)
                }
                .keyboardShortcut("2", modifiers: [.command, .shift])

                Button("Long Break") {
                    environment.pomodoroViewModel.selectPhase(.longBreak)
                }
                .keyboardShortcut("3", modifiers: [.command, .shift])
            }

            CommandMenu("Navigation") {
                Button("Timer") {
                    selectedTab = 0
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Tasks") {
                    selectedTab = 1
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Insights") {
                    selectedTab = 2
                }
                .keyboardShortcut("3", modifiers: .command)
            }
        }

        MenuBarExtra {
            MenuBarView(viewModel: environment.pomodoroViewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: environment.pomodoroViewModel.currentPhase.iconName)
                Text(environment.pomodoroViewModel.formattedTime)
            }
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            MainContentView(
                environment: environment,
                selectedTab: $selectedTab,
                showingSettings: $showingSettings
            )
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    environment.pomodoroViewModel.synchronizeClock()
                }
            }
        }
        #endif
    }
}

public struct MainContentView: View {
    var environment: AppEnvironment
    @Binding var selectedTab: Int
    @Binding var showingSettings: Bool

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.pxBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar with macOS traffic lights spacing
                topHeaderBar

                // Active Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        TimerMainView(
                            viewModel: environment.pomodoroViewModel,
                            tasksViewModel: environment.tasksViewModel,
                            selectedTab: $selectedTab
                        )
                    case 1:
                        TaskListView(tasksViewModel: environment.tasksViewModel)
                    case 2:
                        StatsView(statsViewModel: environment.statsViewModel)
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Custom Bottom Tab Bar
                bottomTabBar
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheetView(viewModel: environment.pomodoroViewModel)
        }
    }

    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            #if os(macOS)
            // Offset for native traffic light buttons
            Spacer().frame(width: 58)
            #endif

            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.pxFocusPrimary)
                Text("PomodoroX")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pxTextSecondary)
                    .padding(7)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Preferences (⌘,)")
            .accessibilityLabel("Open preferences")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Bottom Tab Bar
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "Timer", icon: "clock.fill", index: 0)
            tabButton(title: "Tasks", icon: "checklist", index: 1)
            tabButton(title: "Insights", icon: "chart.bar.xaxis", index: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color.pxSurface
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundStyle(isSelected ? Color.pxFocusPrimary : Color.pxTextSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) tab")
    }
}
