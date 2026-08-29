import XCTest
@testable import PomodoroXCore

final class TimerServiceTests: XCTestCase {
    func testTimerServiceConfiguration() {
        let service = TimerService()
        service.configure(phase: .focus, duration: 1500)

        XCTAssertEqual(service.currentPhase, .focus)
        XCTAssertEqual(service.totalDuration, 1500)
        XCTAssertEqual(service.timeRemaining, 1500)
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.progress, 0.0)
    }

    func testTimerStartAndPauseAndResume() {
        let service = TimerService()
        service.configure(phase: .shortBreak, duration: 300)

        var lastState: TimerState?
        service.onStateChange = { state in
            lastState = state
        }

        service.start()
        XCTAssertEqual(service.state, .running)
        XCTAssertEqual(lastState, .running)

        service.pause()
        XCTAssertEqual(service.state, .paused)
        XCTAssertEqual(lastState, .paused)

        service.resume()
        XCTAssertEqual(service.state, .running)
        XCTAssertEqual(lastState, .running)

        service.reset()
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.timeRemaining, 300)
        XCTAssertEqual(lastState, .idle)
    }

    func testTimerResetWithExplicitDuration() {
        let service = TimerService()
        service.configure(phase: .focus, duration: 1500)
        service.start()

        service.reset(to: 1200)
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.totalDuration, 1200)
        XCTAssertEqual(service.timeRemaining, 1200)
        XCTAssertEqual(service.progress, 0.0)
    }

    func testTimerAdjustTime() {
        let service = TimerService()
        service.configure(phase: .focus, duration: 1500)

        // Increase time
        service.adjustTime(by: 300) // +5 mins
        XCTAssertEqual(service.timeRemaining, 1800)
        XCTAssertEqual(service.totalDuration, 1800)

        // Decrease time
        service.adjustTime(by: -600) // -10 mins
        XCTAssertEqual(service.timeRemaining, 1200)

        // Ensure clamping to >= 60s (1 min) and <= 7200s (2h)
        service.adjustTime(by: -2000)
        XCTAssertEqual(service.timeRemaining, 60)

        service.adjustTime(by: 10000)
        XCTAssertEqual(service.timeRemaining, 7200)
    }

    func testClockSynchronization() {
        let service = TimerService()
        service.configure(phase: .focus, duration: 1500)
        service.start()

        // Trigger clock sync while running
        service.synchronizeWithSystemClock()
        XCTAssertEqual(service.state, .running)
        XCTAssertLessThanOrEqual(service.timeRemaining, 1500)

        // Clock sync when idle does not crash or corrupt time
        service.reset()
        service.synchronizeWithSystemClock()
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.timeRemaining, 1500)
    }

    func testPhaseChangeCallback() {
        let service = TimerService()
        var reportedPhase: PomodoroPhase?

        service.onPhaseChange = { phase in
            reportedPhase = phase
        }

        service.configure(phase: .longBreak, duration: 900)
        XCTAssertEqual(service.currentPhase, .longBreak)
        XCTAssertEqual(reportedPhase, .longBreak)
    }

    func testCallbacksOnConfiguration() {
        let service = TimerService()
        var tickRemaining: TimeInterval?
        var tickProgress: Double?

        service.onTick = { remaining, progress in
            tickRemaining = remaining
            tickProgress = progress
        }

        service.configure(phase: .focus, duration: 1500)
        service.start()
        service.adjustTime(by: 60)

        XCTAssertNotNil(tickRemaining)
        XCTAssertNotNil(tickProgress)
    }
}
