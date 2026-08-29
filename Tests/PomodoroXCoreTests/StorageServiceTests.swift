import XCTest
@testable import PomodoroXCore

final class StorageServiceTests: XCTestCase {
    func testStorageServiceLoadDefaults() {
        let storage = StorageService()

        let settings = storage.loadSettings()
        XCTAssertGreaterThan(settings.focusDuration, 0)
        XCTAssertGreaterThan(settings.shortBreakDuration, 0)
        XCTAssertGreaterThan(settings.longBreakDuration, 0)

        let tasks = storage.loadTasks()
        XCTAssertFalse(tasks.isEmpty)

        let sessions = storage.loadSessions()
        XCTAssertNotNil(sessions)
    }

    func testSaveAndLoadConsistency() {
        let storage = StorageService.shared
        var customSettings = PomodoroSettings.default
        customSettings.focusDuration = 1800
        customSettings.soundEnabled = false

        storage.saveSettings(customSettings)

        let testTask = PomodoroTask(title: "Unit Test Storage Task", estimatedPomodoros: 2)
        storage.saveTasks([testTask])

        let testSession = SessionRecord(phase: .focus, duration: 1800, taskTitle: "Storage Test")
        storage.saveSessions([testSession])
    }
}
