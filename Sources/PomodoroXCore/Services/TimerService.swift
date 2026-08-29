import Foundation
import Combine

public final class TimerService: @unchecked Sendable {
    public private(set) var state: TimerState = .idle
    public private(set) var currentPhase: PomodoroPhase = .focus
    public private(set) var timeRemaining: TimeInterval = 25 * 60
    public private(set) var totalDuration: TimeInterval = 25 * 60
    public private(set) var completedFocusCount: Int = 0

    private var targetEndDate: Date?
    private var pausedRemainingTime: TimeInterval?
    private var timer: Timer?

    public var onTick: ((TimeInterval, Double) -> Void)?
    public var onStateChange: ((TimerState) -> Void)?
    public var onPhaseChange: ((PomodoroPhase) -> Void)?
    public var onSessionComplete: ((PomodoroPhase, TimeInterval) -> Void)?

    public init() {}

    public var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - timeRemaining
        return min(1.0, max(0.0, elapsed / totalDuration))
    }

    public func configure(phase: PomodoroPhase, duration: TimeInterval) {
        stopTimer()
        self.currentPhase = phase
        self.totalDuration = max(1, duration)
        self.timeRemaining = max(1, duration)
        self.state = .idle
        self.targetEndDate = nil
        self.pausedRemainingTime = nil

        onPhaseChange?(phase)
        onStateChange?(state)
        onTick?(timeRemaining, progress)
    }

    public func start() {
        guard state != .running else { return }

        let remaining = pausedRemainingTime ?? timeRemaining
        self.totalDuration = (self.totalDuration > 0) ? self.totalDuration : remaining
        self.targetEndDate = Date().addingTimeInterval(remaining)
        self.pausedRemainingTime = nil
        self.state = .running

        onStateChange?(.running)
        startTimerLoop()
    }

    public func pause() {
        guard state == .running else { return }

        stopTimer()
        if let target = targetEndDate {
            self.pausedRemainingTime = max(0, target.timeIntervalSinceNow)
            self.timeRemaining = self.pausedRemainingTime ?? 0
        }
        self.targetEndDate = nil
        self.state = .paused

        onStateChange?(.paused)
        onTick?(timeRemaining, progress)
    }

    public func resume() {
        if state == .paused {
            start()
        }
    }

    public func reset(to duration: TimeInterval? = nil) {
        stopTimer()
        let dur = duration ?? currentPhase.defaultDuration
        self.totalDuration = dur
        self.timeRemaining = dur
        self.pausedRemainingTime = nil
        self.targetEndDate = nil
        self.state = .idle

        onStateChange?(.idle)
        onTick?(timeRemaining, 0)
    }

    public func skip(nextPhase: PomodoroPhase, nextDuration: TimeInterval) {
        stopTimer()
        configure(phase: nextPhase, duration: nextDuration)
    }

    public func adjustTime(by deltaSeconds: TimeInterval) {
        let newRemaining = max(60, min(7200, timeRemaining + deltaSeconds))
        let newTotal = max(newRemaining, totalDuration + deltaSeconds)
        self.timeRemaining = newRemaining
        self.totalDuration = newTotal

        if state == .running {
            self.targetEndDate = Date().addingTimeInterval(newRemaining)
        } else if state == .paused {
            self.pausedRemainingTime = newRemaining
        }
        onTick?(timeRemaining, progress)
    }

    // MARK: - App Lifecycle Wake / Resume Hook
    public func synchronizeWithSystemClock() {
        guard state == .running, let target = targetEndDate else { return }
        let remaining = target.timeIntervalSinceNow
        if remaining <= 0.05 {
            tick()
        } else {
            self.timeRemaining = remaining
            onTick?(remaining, progress)
        }
    }

    // MARK: - Private Timer Loop
    private func startTimerLoop() {
        stopTimer()
        let t = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .running, let target = targetEndDate else { return }

        let remaining = target.timeIntervalSinceNow
        if remaining <= 0.05 {
            let completedPhase = currentPhase
            let completedDuration = totalDuration

            self.timeRemaining = 0
            self.state = .completed
            stopTimer()

            if completedPhase == .focus {
                completedFocusCount += 1
            }

            onTick?(0, 1.0)
            onStateChange?(.completed)
            onSessionComplete?(completedPhase, completedDuration)
        } else {
            self.timeRemaining = remaining
            onTick?(remaining, progress)
        }
    }
}
