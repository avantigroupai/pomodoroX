import Foundation

public enum TimerPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case classic = "Classic (25/5)"
    case deepFlow = "Deep Flow (50/10)"
    case ultradian = "Ultradian (90/20)"
    case quickSprint = "Sprint (15/3)"
    case custom = "Custom"

    public var id: String { rawValue }

    public var focusMinutes: Double {
        switch self {
        case .classic: return 25
        case .deepFlow: return 50
        case .ultradian: return 90
        case .quickSprint: return 15
        case .custom: return 25
        }
    }

    public var shortBreakMinutes: Double {
        switch self {
        case .classic: return 5
        case .deepFlow: return 10
        case .ultradian: return 20
        case .quickSprint: return 3
        case .custom: return 5
        }
    }

    public var longBreakMinutes: Double {
        switch self {
        case .classic: return 15
        case .deepFlow: return 30
        case .ultradian: return 30
        case .quickSprint: return 10
        case .custom: return 15
        }
    }
}

public enum AmbientSoundType: String, Codable, CaseIterable, Identifiable, Sendable {
    case none = "Off"
    case vibeCoding = "Vibe Coding"
    case oceanWaves = "Ocean Waves"
    case deepFocus = "Deep Pink Noise"
    case brownNoise = "Brown Noise"
    case softStream = "Forest Stream"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .vibeCoding: return "terminal.fill"
        case .oceanWaves: return "water.waves"
        case .deepFocus: return "waveform.path"
        case .brownNoise: return "wind"
        case .softStream: return "leaf.fill"
        }
    }
}

public struct PomodoroSettings: Codable, Sendable, Equatable {
    public var activePreset: TimerPreset
    public var focusDuration: TimeInterval
    public var shortBreakDuration: TimeInterval
    public var longBreakDuration: TimeInterval
    public var sessionsBeforeLongBreak: Int

    public var autoStartBreaks: Bool
    public var autoStartFocus: Bool

    public var soundEnabled: Bool
    public var tickingSoundEnabled: Bool
    public var ambientSound: AmbientSoundType
    public var ambientVolume: Float // 0.0 ... 1.0

    public var notificationsEnabled: Bool
    public var keepScreenAwake: Bool
    public var showInMenuBar: Bool

    public init(
        activePreset: TimerPreset = .classic,
        focusDuration: TimeInterval = 25 * 60,
        shortBreakDuration: TimeInterval = 5 * 60,
        longBreakDuration: TimeInterval = 15 * 60,
        sessionsBeforeLongBreak: Int = 4,
        autoStartBreaks: Bool = false,
        autoStartFocus: Bool = false,
        soundEnabled: Bool = true,
        tickingSoundEnabled: Bool = false,
        ambientSound: AmbientSoundType = .none,
        ambientVolume: Float = 0.5,
        notificationsEnabled: Bool = true,
        keepScreenAwake: Bool = true,
        showInMenuBar: Bool = true
    ) {
        self.activePreset = activePreset
        self.focusDuration = focusDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.sessionsBeforeLongBreak = sessionsBeforeLongBreak
        self.autoStartBreaks = autoStartBreaks
        self.autoStartFocus = autoStartFocus
        self.soundEnabled = soundEnabled
        self.tickingSoundEnabled = tickingSoundEnabled
        self.ambientSound = ambientSound
        self.ambientVolume = ambientVolume
        self.notificationsEnabled = notificationsEnabled
        self.keepScreenAwake = keepScreenAwake
        self.showInMenuBar = showInMenuBar
    }

    public static let `default` = PomodoroSettings()
}
