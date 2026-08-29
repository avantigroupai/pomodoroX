import Foundation
import SwiftUI
import Observation

@Observable
public final class PomodoroViewModel {
    public var currentPhase: PomodoroPhase = .focus
    public var timerState: TimerState = .idle
    public var timeRemaining: TimeInterval = 25 * 60
    public var totalDuration: TimeInterval = 25 * 60
    public var progress: Double = 0.0

    public var settings: PomodoroSettings
    public var activeTask: PomodoroTask?
    public var completedCyclesCount: Int = 0

    public var isAmbientPlaying: Bool = false
    public var ambientVolume: Float = 0.5
    public var selectedAmbientSound: AmbientSoundType = .none

    public var recentSessions: [SessionRecord] = []

    private let timerService = TimerService()
    private let storage = StorageService.shared
    private let audioEngine = AmbientAudioEngine.shared
    private let haptics = HapticsManager.shared
    private let notifications = NotificationManager.shared

    public init() {
        let loadedSettings = storage.loadSettings()
        self.settings = loadedSettings
        self.selectedAmbientSound = loadedSettings.ambientSound
        self.ambientVolume = loadedSettings.ambientVolume
        self.recentSessions = storage.loadSessions()

        self.totalDuration = loadedSettings.focusDuration
        self.timeRemaining = loadedSettings.focusDuration

        setupTimerCallbacks()
        notifications.requestAuthorization()
    }

    private func setupTimerCallbacks() {
        timerService.onTick = { [weak self] remaining, prog in
            Task { @MainActor in
                self?.timeRemaining = remaining
                self?.progress = prog
            }
        }

        timerService.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.timerState = state
            }
        }

        timerService.onPhaseChange = { [weak self] phase in
            Task { @MainActor in
                self?.currentPhase = phase
            }
        }

        timerService.onSessionComplete = { [weak self] phase, duration in
            Task { @MainActor in
                self?.handleSessionCompletion(phase: phase, duration: duration)
            }
        }

        timerService.configure(phase: currentPhase, duration: settings.focusDuration)
    }

    // MARK: - Formatted Output & A11y
    public var formattedTime: String {
        let totalSeconds = Int(ceil(timeRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    public var accessibilityTimeDescription: String {
        let totalSeconds = Int(ceil(timeRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes) minutes and \(seconds) seconds remaining in \(currentPhase.rawValue) mode"
    }

    public var phaseProgressTitle: String {
        switch currentPhase {
        case .focus:
            let cycle = (completedCyclesCount % settings.sessionsBeforeLongBreak) + 1
            return "Focus #\(cycle)/\(settings.sessionsBeforeLongBreak)"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    // MARK: - Controls
    public func togglePlayPause() {
        switch timerState {
        case .idle, .paused:
            start()
        case .running:
            pause()
        case .completed:
            reset()
            start()
        }
    }

    public func start() {
        timerService.start()
        haptics.playStartFeedback()

        if settings.notificationsEnabled {
            notifications.scheduleSessionCompletionNotification(phase: currentPhase, in: timeRemaining)
        }

        if settings.ambientSound != .none && !isAmbientPlaying {
            audioEngine.playAmbient(type: settings.ambientSound, volume: ambientVolume, fadeDuration: 0.8)
            isAmbientPlaying = true
        }
    }

    public func pause() {
        timerService.pause()
        haptics.playPauseFeedback()
        notifications.cancelPendingNotifications()

        if isAmbientPlaying {
            audioEngine.stopAmbient(fadeDuration: 0.4)
            isAmbientPlaying = false
        }
    }

    public func reset() {
        let duration = duration(for: currentPhase)
        timerService.reset(to: duration)
        timeRemaining = duration
        progress = 0
        timerState = .idle
        notifications.cancelPendingNotifications()

        if isAmbientPlaying {
            audioEngine.stopAmbient(fadeDuration: 0.3)
            isAmbientPlaying = false
        }
    }

    public func selectPhase(_ phase: PomodoroPhase) {
        currentPhase = phase
        let dur = duration(for: phase)
        timerService.configure(phase: phase, duration: dur)
        timeRemaining = dur
        totalDuration = dur
        progress = 0
        timerState = .idle
        haptics.playSelectionFeedback()
        notifications.cancelPendingNotifications()
    }

    public func skipPhase() {
        let next = determineNextPhase()
        selectPhase(next)
    }

    public func adjustTime(by deltaMinutes: Int) {
        let deltaSeconds = TimeInterval(deltaMinutes * 60)
        timerService.adjustTime(by: deltaSeconds)
        haptics.playSelectionFeedback()
    }

    public func applyPreset(_ preset: TimerPreset) {
        settings.activePreset = preset
        settings.focusDuration = preset.focusMinutes * 60.0
        settings.shortBreakDuration = preset.shortBreakMinutes * 60.0
        settings.longBreakDuration = preset.longBreakMinutes * 60.0
        storage.saveSettings(settings)

        if timerState == .idle {
            let dur = duration(for: currentPhase)
            timerService.configure(phase: currentPhase, duration: dur)
            self.totalDuration = dur
            self.timeRemaining = dur
        }
    }

    // MARK: - Ambient Controls
    public func setAmbientSound(_ type: AmbientSoundType) {
        selectedAmbientSound = type
        settings.ambientSound = type
        storage.saveSettings(settings)

        if timerState == .running {
            if type == .none {
                audioEngine.stopAmbient(fadeDuration: 0.4)
                isAmbientPlaying = false
            } else {
                audioEngine.playAmbient(type: type, volume: ambientVolume, fadeDuration: 0.6)
                isAmbientPlaying = true
            }
        }
    }

    public func setAmbientVolume(_ vol: Float) {
        ambientVolume = vol
        settings.ambientVolume = vol
        storage.saveSettings(settings)
        audioEngine.setVolume(vol)
    }

    // MARK: - Settings Update
    public func updateSettings(_ newSettings: PomodoroSettings) {
        self.settings = newSettings
        storage.saveSettings(newSettings)
        if timerState == .idle {
            let dur = duration(for: currentPhase)
            timerService.configure(phase: currentPhase, duration: dur)
            self.totalDuration = dur
            self.timeRemaining = dur
        }
    }

    public func synchronizeClock() {
        timerService.synchronizeWithSystemClock()
    }

    // MARK: - Completion Handler
    private func handleSessionCompletion(phase: PomodoroPhase, duration: TimeInterval) {
        haptics.playCompletionFeedback()

        if settings.soundEnabled {
            audioEngine.playCompletionBell()
        }

        if isAmbientPlaying {
            audioEngine.stopAmbient(fadeDuration: 0.5)
            isAmbientPlaying = false
        }

        // Record session
        let record = SessionRecord(
            phase: phase,
            duration: duration,
            completedAt: Date(),
            taskId: activeTask?.id,
            taskTitle: activeTask?.title
        )
        recentSessions.insert(record, at: 0)
        storage.saveSessions(recentSessions)

        if phase == .focus {
            completedCyclesCount += 1
            if let task = activeTask {
                var updatedTask = task
                updatedTask.completedPomodoros += 1
                self.activeTask = updatedTask
            }
        }

        // Next Phase Transition
        let nextPhase = determineNextPhase()
        let nextDuration = self.duration(for: nextPhase)
        timerService.configure(phase: nextPhase, duration: nextDuration)
        self.currentPhase = nextPhase
        self.totalDuration = nextDuration
        self.timeRemaining = nextDuration
        self.progress = 0

        // Auto start if enabled
        let shouldAutoStart = (nextPhase == .focus && settings.autoStartFocus) ||
                              (nextPhase != .focus && settings.autoStartBreaks)
        if shouldAutoStart {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.start()
            }
        }
    }

    private func determineNextPhase() -> PomodoroPhase {
        switch currentPhase {
        case .focus:
            if completedCyclesCount > 0 && (completedCyclesCount % settings.sessionsBeforeLongBreak == 0) {
                return .longBreak
            } else {
                return .shortBreak
            }
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    public func duration(for phase: PomodoroPhase) -> TimeInterval {
        switch phase {
        case .focus: return settings.focusDuration
        case .shortBreak: return settings.shortBreakDuration
        case .longBreak: return settings.longBreakDuration
        }
    }
}
