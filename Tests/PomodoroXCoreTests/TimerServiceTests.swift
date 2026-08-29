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

    func testTimerStartAndPause() {
        let service = TimerService()
        service.configure(phase: .shortBreak, duration: 300)

        service.start()
        XCTAssertEqual(service.state, .running)

        service.pause()
        XCTAssertEqual(service.state, .paused)

        service.resume()
        XCTAssertEqual(service.state, .running)

        service.reset()
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.timeRemaining, 300)
    }

    func testTimerAdjustTime() {
        let service = TimerService()
        service.configure(phase: .focus, duration: 1500)

        service.adjustTime(by: 300) // +5 mins
        XCTAssertEqual(service.timeRemaining, 1800)

        service.adjustTime(by: -600) // -10 mins
        XCTAssertEqual(service.timeRemaining, 1200)
    }

    func testClockSynchronization() {
        let service = TimerService()
        service.configure(phase: .focus, duration: 1500)
        service.start()

        // Trigger clock sync
        service.synchronizeWithSystemClock()
        XCTAssertEqual(service.state, .running)
        XCTAssertLessThanOrEqual(service.timeRemaining, 1500)
    }
}
