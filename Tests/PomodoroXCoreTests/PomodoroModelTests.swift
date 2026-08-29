import XCTest
@testable import PomodoroXCore

final class PomodoroModelTests: XCTestCase {
    func testPomodoroPhaseDefaults() {
        XCTAssertEqual(PomodoroPhase.focus.defaultDuration, 25 * 60)
        XCTAssertEqual(PomodoroPhase.shortBreak.defaultDuration, 5 * 60)
        XCTAssertEqual(PomodoroPhase.longBreak.defaultDuration, 15 * 60)
    }

    func testTimerPresets() {
        XCTAssertEqual(TimerPreset.classic.focusMinutes, 25)
        XCTAssertEqual(TimerPreset.classic.shortBreakMinutes, 5)
        XCTAssertEqual(TimerPreset.deepFlow.focusMinutes, 50)
        XCTAssertEqual(TimerPreset.deepFlow.shortBreakMinutes, 10)
        XCTAssertEqual(TimerPreset.ultradian.focusMinutes, 90)
        XCTAssertEqual(TimerPreset.quickSprint.focusMinutes, 15)
    }

    func testSessionRecordCodable() throws {
        let original = SessionRecord(
            phase: .focus,
            duration: 1500,
            completedAt: Date(),
            taskTitle: "Swift Refactor"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SessionRecord.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.phase, decoded.phase)
        XCTAssertEqual(original.duration, decoded.duration)
        XCTAssertEqual(original.taskTitle, decoded.taskTitle)
    }

    func testPomodoroTaskProgress() {
        var task = PomodoroTask(title: "Design UX", estimatedPomodoros: 4, category: .design)
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.completedPomodoros, 0)

        task.completedPomodoros += 2
        XCTAssertEqual(task.completedPomodoros, 2)

        task.isCompleted = true
        XCTAssertTrue(task.isCompleted)
    }

    func testSettingsDefaults() {
        let settings = PomodoroSettings.default
        XCTAssertEqual(settings.focusDuration, 25 * 60)
        XCTAssertEqual(settings.shortBreakDuration, 5 * 60)
        XCTAssertEqual(settings.longBreakDuration, 15 * 60)
        XCTAssertEqual(settings.sessionsBeforeLongBreak, 4)
        XCTAssertEqual(settings.activePreset, .classic)
        XCTAssertTrue(settings.soundEnabled)
    }
}
