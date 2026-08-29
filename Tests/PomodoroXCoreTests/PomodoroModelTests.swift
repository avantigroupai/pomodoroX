import XCTest
@testable import PomodoroXCore

final class PomodoroModelTests: XCTestCase {
    // MARK: - PomodoroPhase Tests
    func testPomodoroPhaseDefaults() {
        XCTAssertEqual(PomodoroPhase.focus.defaultDuration, 25 * 60)
        XCTAssertEqual(PomodoroPhase.shortBreak.defaultDuration, 5 * 60)
        XCTAssertEqual(PomodoroPhase.longBreak.defaultDuration, 15 * 60)

        XCTAssertEqual(PomodoroPhase.focus.iconName, "flame.fill")
        XCTAssertEqual(PomodoroPhase.shortBreak.iconName, "cup.and.saucer.fill")
        XCTAssertEqual(PomodoroPhase.longBreak.iconName, "sparkles")

        XCTAssertEqual(PomodoroPhase.focus.subtitle, "Stay in the flow")
        XCTAssertEqual(PomodoroPhase.shortBreak.subtitle, "Quick recharge")
        XCTAssertEqual(PomodoroPhase.longBreak.subtitle, "Deep rest & reset")

        XCTAssertEqual(PomodoroPhase.focus.id, "Focus")
        XCTAssertEqual(PomodoroPhase.shortBreak.id, "Short Break")
        XCTAssertEqual(PomodoroPhase.longBreak.id, "Long Break")
    }

    func testPomodoroPhaseCodable() throws {
        for phase in PomodoroPhase.allCases {
            let data = try JSONEncoder().encode(phase)
            let decoded = try JSONDecoder().decode(PomodoroPhase.self, from: data)
            XCTAssertEqual(decoded, phase)
        }
    }

    // MARK: - TimerState Tests
    func testTimerStateIsActive() {
        XCTAssertFalse(TimerState.idle.isActive)
        XCTAssertTrue(TimerState.running.isActive)
        XCTAssertTrue(TimerState.paused.isActive)
        XCTAssertFalse(TimerState.completed.isActive)
    }

    func testTimerStateCodable() throws {
        let states: [TimerState] = [.idle, .running, .paused, .completed]
        for state in states {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(TimerState.self, from: data)
            XCTAssertEqual(decoded, state)
        }
    }

    // MARK: - TaskCategory Tests
    func testTaskCategoryIconsAndIds() {
        XCTAssertEqual(TaskCategory.work.iconName, "briefcase.fill")
        XCTAssertEqual(TaskCategory.coding.iconName, "curlybraces")
        XCTAssertEqual(TaskCategory.study.iconName, "book.closed.fill")
        XCTAssertEqual(TaskCategory.writing.iconName, "pencil.line")
        XCTAssertEqual(TaskCategory.design.iconName, "paintpalette.fill")
        XCTAssertEqual(TaskCategory.general.iconName, "checklist")

        for cat in TaskCategory.allCases {
            XCTAssertEqual(cat.id, cat.rawValue)
        }
    }

    func testTaskCategoryCodable() throws {
        for cat in TaskCategory.allCases {
            let data = try JSONEncoder().encode(cat)
            let decoded = try JSONDecoder().decode(TaskCategory.self, from: data)
            XCTAssertEqual(decoded, cat)
        }
    }

    // MARK: - PomodoroTask Tests
    func testPomodoroTaskDefaultsAndConstraints() {
        let task = PomodoroTask(
            title: "Write Swift Tests",
            notes: "Unit and integration tests",
            estimatedPomodoros: 0, // Should clamp to at least 1
            completedPomodoros: -1, // Should clamp to at least 0
            category: .coding
        )

        XCTAssertEqual(task.title, "Write Swift Tests")
        XCTAssertEqual(task.notes, "Unit and integration tests")
        XCTAssertEqual(task.estimatedPomodoros, 1)
        XCTAssertEqual(task.completedPomodoros, 0)
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.category, .coding)
        XCTAssertNil(task.completedAt)
    }

    func testPomodoroTaskProgressAndCodable() throws {
        var task = PomodoroTask(
            title: "Feature Development",
            estimatedPomodoros: 4,
            completedPomodoros: 2,
            category: .work
        )

        XCTAssertEqual(task.estimatedPomodoros, 4)
        XCTAssertEqual(task.completedPomodoros, 2)

        task.completedPomodoros += 2
        task.isCompleted = true
        task.completedAt = Date()

        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(PomodoroTask.self, from: data)

        XCTAssertEqual(decoded.id, task.id)
        XCTAssertEqual(decoded.title, "Feature Development")
        XCTAssertEqual(decoded.estimatedPomodoros, 4)
        XCTAssertEqual(decoded.completedPomodoros, 4)
        XCTAssertTrue(decoded.isCompleted)
        XCTAssertNotNil(decoded.completedAt)
    }

    // MARK: - SessionRecord Tests
    func testSessionRecordCodable() throws {
        let taskId = UUID()
        let record = SessionRecord(
            phase: .focus,
            duration: 1500,
            completedAt: Date(),
            taskId: taskId,
            taskTitle: "Design System"
        )

        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(SessionRecord.self, from: data)

        XCTAssertEqual(decoded.id, record.id)
        XCTAssertEqual(decoded.phase, .focus)
        XCTAssertEqual(decoded.duration, 1500)
        XCTAssertEqual(decoded.taskId, taskId)
        XCTAssertEqual(decoded.taskTitle, "Design System")
    }

    // MARK: - TimerPresets Tests
    func testTimerPresets() {
        XCTAssertEqual(TimerPreset.classic.focusMinutes, 25)
        XCTAssertEqual(TimerPreset.classic.shortBreakMinutes, 5)
        XCTAssertEqual(TimerPreset.classic.longBreakMinutes, 15)

        XCTAssertEqual(TimerPreset.deepFlow.focusMinutes, 50)
        XCTAssertEqual(TimerPreset.deepFlow.shortBreakMinutes, 10)
        XCTAssertEqual(TimerPreset.deepFlow.longBreakMinutes, 30)

        XCTAssertEqual(TimerPreset.ultradian.focusMinutes, 90)
        XCTAssertEqual(TimerPreset.ultradian.shortBreakMinutes, 20)
        XCTAssertEqual(TimerPreset.ultradian.longBreakMinutes, 30)

        XCTAssertEqual(TimerPreset.quickSprint.focusMinutes, 15)
        XCTAssertEqual(TimerPreset.quickSprint.shortBreakMinutes, 3)
        XCTAssertEqual(TimerPreset.quickSprint.longBreakMinutes, 10)

        XCTAssertEqual(TimerPreset.custom.focusMinutes, 25)
        XCTAssertEqual(TimerPreset.custom.shortBreakMinutes, 5)
        XCTAssertEqual(TimerPreset.custom.longBreakMinutes, 15)

        for preset in TimerPreset.allCases {
            XCTAssertEqual(preset.id, preset.rawValue)
        }
    }

    // MARK: - PomodoroSettings Tests
    func testSettingsDefaultsAndCodable() throws {
        let settings = PomodoroSettings.default
        XCTAssertEqual(settings.focusDuration, 25 * 60)
        XCTAssertEqual(settings.shortBreakDuration, 5 * 60)
        XCTAssertEqual(settings.longBreakDuration, 15 * 60)
        XCTAssertEqual(settings.sessionsBeforeLongBreak, 4)
        XCTAssertFalse(settings.autoStartBreaks)
        XCTAssertFalse(settings.autoStartFocus)
        XCTAssertTrue(settings.soundEnabled)
        XCTAssertFalse(settings.tickingSoundEnabled)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertTrue(settings.keepScreenAwake)
        XCTAssertTrue(settings.showInMenuBar)
        XCTAssertEqual(settings.activePreset, .classic)
        XCTAssertEqual(settings.ambientSound, .none)
        XCTAssertEqual(settings.ambientVolume, 0.5)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(PomodoroSettings.self, from: data)
        XCTAssertEqual(decoded, settings)
    }

    // MARK: - AmbientSoundType Tests
    func testAmbientSoundTypes() throws {
        XCTAssertEqual(AmbientSoundType.none.rawValue, "Off")
        XCTAssertEqual(AmbientSoundType.vibeCoding.rawValue, "Vibe Coding")
        XCTAssertEqual(AmbientSoundType.oceanWaves.rawValue, "Ocean Waves")
        XCTAssertEqual(AmbientSoundType.deepFocus.rawValue, "Deep Pink Noise")
        XCTAssertEqual(AmbientSoundType.brownNoise.rawValue, "Brown Noise")
        XCTAssertEqual(AmbientSoundType.softStream.rawValue, "Forest Stream")

        XCTAssertEqual(AmbientSoundType.vibeCoding.iconName, "terminal.fill")
        XCTAssertEqual(AmbientSoundType.oceanWaves.iconName, "water.waves")
        XCTAssertEqual(AmbientSoundType.none.iconName, "speaker.slash.fill")
        XCTAssertEqual(AmbientSoundType.deepFocus.iconName, "waveform.path")
        XCTAssertEqual(AmbientSoundType.brownNoise.iconName, "wind")
        XCTAssertEqual(AmbientSoundType.softStream.iconName, "leaf.fill")

        for sound in AmbientSoundType.allCases {
            XCTAssertEqual(sound.id, sound.rawValue)
            let encoded = try JSONEncoder().encode(sound)
            let decoded = try JSONDecoder().decode(AmbientSoundType.self, from: encoded)
            XCTAssertEqual(decoded, sound)
        }
    }
}
