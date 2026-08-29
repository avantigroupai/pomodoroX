import Foundation

public final class StorageService: @unchecked Sendable {
    public static let shared = StorageService()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.pomodorox.storage", qos: .utility)

    private var storageDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("PomodoroX", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var settingsURL: URL { storageDirectory.appendingPathComponent("settings.json") }
    private var tasksURL: URL { storageDirectory.appendingPathComponent("tasks.json") }
    private var sessionsURL: URL { storageDirectory.appendingPathComponent("sessions.json") }

    public init() {}

    // MARK: - Settings
    public func loadSettings() -> PomodoroSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(PomodoroSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    public func saveSettings(_ settings: PomodoroSettings) {
        queue.async {
            guard let data = try? JSONEncoder().encode(settings) else { return }
            try? data.write(to: self.settingsURL, options: .atomic)
        }
    }

    // MARK: - Tasks
    public func loadTasks() -> [PomodoroTask] {
        guard let data = try? Data(contentsOf: tasksURL),
              let tasks = try? JSONDecoder().decode([PomodoroTask].self, from: data) else {
            return [
                PomodoroTask(title: "Complete initial prototype", estimatedPomodoros: 2, category: .coding),
                PomodoroTask(title: "Review daily goals", estimatedPomodoros: 1, category: .work),
                PomodoroTask(title: "Read research paper", estimatedPomodoros: 3, category: .study)
            ]
        }
        return tasks
    }

    public func saveTasks(_ tasks: [PomodoroTask]) {
        queue.async {
            guard let data = try? JSONEncoder().encode(tasks) else { return }
            try? data.write(to: self.tasksURL, options: .atomic)
        }
    }

    // MARK: - Session Records
    public func loadSessions() -> [SessionRecord] {
        guard let data = try? Data(contentsOf: sessionsURL),
              let sessions = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
            return []
        }
        return sessions
    }

    public func saveSessions(_ sessions: [SessionRecord]) {
        queue.async {
            guard let data = try? JSONEncoder().encode(sessions) else { return }
            try? data.write(to: self.sessionsURL, options: .atomic)
        }
    }
}
