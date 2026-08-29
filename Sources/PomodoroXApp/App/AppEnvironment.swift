import SwiftUI
import PomodoroXCore

@MainActor
public final class AppEnvironment {
    public static let shared = AppEnvironment()

    public let pomodoroViewModel: PomodoroViewModel
    public let tasksViewModel: TasksViewModel
    public let statsViewModel: StatsViewModel

    public init() {
        self.pomodoroViewModel = PomodoroViewModel()
        self.tasksViewModel = TasksViewModel()
        self.statsViewModel = StatsViewModel()
    }
}
