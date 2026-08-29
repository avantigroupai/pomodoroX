import XCTest
@testable import PomodoroXCore

@MainActor
final class PomodoroViewModelTests: XCTestCase {
    func testInitializationDefaults() {
        let vm = PomodoroViewModel()
        XCTAssertEqual(vm.currentPhase, .focus)
        XCTAssertEqual(vm.timerState, .idle)
        XCTAssertEqual(vm.progress, 0.0)
        XCTAssertEqual(vm.totalDuration, vm.settings.focusDuration)
        XCTAssertEqual(vm.timeRemaining, vm.settings.focusDuration)
    }

    func testFormattedTimeAndAccessibility() {
        let vm = PomodoroViewModel()
        vm.timeRemaining = 1500 // 25:00
        XCTAssertEqual(vm.formattedTime, "25:00")

        vm.timeRemaining = 325 // 05:25
        XCTAssertEqual(vm.formattedTime, "05:25")

        vm.timeRemaining = 9 // 00:09
        XCTAssertEqual(vm.formattedTime, "00:09")

        XCTAssertTrue(vm.accessibilityTimeDescription.contains("minutes"))
        XCTAssertTrue(vm.accessibilityTimeDescription.contains("Focus"))
    }

    func testPhaseProgressTitle() {
        let vm = PomodoroViewModel()
        vm.currentPhase = .focus
        vm.completedCyclesCount = 0
        vm.settings.sessionsBeforeLongBreak = 4
        XCTAssertEqual(vm.phaseProgressTitle, "Focus #1/4")

        vm.completedCyclesCount = 2
        XCTAssertEqual(vm.phaseProgressTitle, "Focus #3/4")

        vm.currentPhase = .shortBreak
        XCTAssertEqual(vm.phaseProgressTitle, "Short Break")

        vm.currentPhase = .longBreak
        XCTAssertEqual(vm.phaseProgressTitle, "Long Break")
    }

    func testSelectPhase() {
        let vm = PomodoroViewModel()

        vm.selectPhase(.shortBreak)
        XCTAssertEqual(vm.currentPhase, .shortBreak)
        XCTAssertEqual(vm.timeRemaining, vm.settings.shortBreakDuration)
        XCTAssertEqual(vm.totalDuration, vm.settings.shortBreakDuration)
        XCTAssertEqual(vm.timerState, .idle)

        vm.selectPhase(.longBreak)
        XCTAssertEqual(vm.currentPhase, .longBreak)
        XCTAssertEqual(vm.timeRemaining, vm.settings.longBreakDuration)
        XCTAssertEqual(vm.totalDuration, vm.settings.longBreakDuration)
        XCTAssertEqual(vm.timerState, .idle)

        vm.selectPhase(.focus)
        XCTAssertEqual(vm.currentPhase, .focus)
        XCTAssertEqual(vm.timeRemaining, vm.settings.focusDuration)
    }

    func testSkipPhase() {
        let vm = PomodoroViewModel()
        vm.currentPhase = .focus
        vm.completedCyclesCount = 0

        vm.skipPhase()
        XCTAssertEqual(vm.currentPhase, .shortBreak)

        vm.skipPhase()
        XCTAssertEqual(vm.currentPhase, .focus)
    }

    func testApplyPreset() {
        let vm = PomodoroViewModel()
        vm.applyPreset(.ultradian)

        XCTAssertEqual(vm.settings.activePreset, .ultradian)
        XCTAssertEqual(vm.settings.focusDuration, 90 * 60)
        XCTAssertEqual(vm.settings.shortBreakDuration, 20 * 60)
        XCTAssertEqual(vm.settings.longBreakDuration, 30 * 60)
        XCTAssertEqual(vm.timeRemaining, 90 * 60)
        XCTAssertEqual(vm.totalDuration, 90 * 60)
    }

    func testAdjustTime() {
        let vm = PomodoroViewModel()
        let initialTime = vm.timeRemaining

        vm.adjustTime(by: 5)
        XCTAssertEqual(vm.timeRemaining, initialTime + 300)

        vm.adjustTime(by: -10)
        XCTAssertEqual(vm.timeRemaining, initialTime - 300)
    }

    func testAmbientSoundAndVolumeSettings() {
        let vm = PomodoroViewModel()

        vm.setAmbientSound(.vibeCoding)
        XCTAssertEqual(vm.selectedAmbientSound, .vibeCoding)
        XCTAssertEqual(vm.settings.ambientSound, .vibeCoding)

        vm.setAmbientVolume(0.8)
        XCTAssertEqual(vm.ambientVolume, 0.8)
        XCTAssertEqual(vm.settings.ambientVolume, 0.8)
    }

    func testUpdateSettings() {
        let vm = PomodoroViewModel()
        var newSettings = PomodoroSettings.default
        newSettings.focusDuration = 20 * 60
        newSettings.sessionsBeforeLongBreak = 6

        vm.updateSettings(newSettings)
        XCTAssertEqual(vm.settings.focusDuration, 20 * 60)
        XCTAssertEqual(vm.settings.sessionsBeforeLongBreak, 6)
        XCTAssertEqual(vm.timeRemaining, 20 * 60)
    }
}
