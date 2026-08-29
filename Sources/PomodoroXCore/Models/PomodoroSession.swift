import Foundation

public enum PomodoroPhase: String, Codable, CaseIterable, Identifiable, Sendable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .focus: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "sparkles"
        }
    }

    public var subtitle: String {
        switch self {
        case .focus: return "Stay in the flow"
        case .shortBreak: return "Quick recharge"
        case .longBreak: return "Deep rest & reset"
        }
    }

    public var defaultDuration: TimeInterval {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
}

public enum TimerState: String, Codable, Sendable {
    case idle
    case running
    case paused
    case completed

    public var isActive: Bool {
        self == .running || self == .paused
    }
}

public struct SessionRecord: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let phase: PomodoroPhase
    public let duration: TimeInterval
    public let completedAt: Date
    public let taskId: UUID?
    public let taskTitle: String?

    public init(
        id: UUID = UUID(),
        phase: PomodoroPhase,
        duration: TimeInterval,
        completedAt: Date = Date(),
        taskId: UUID? = nil,
        taskTitle: String? = nil
    ) {
        self.id = id
        self.phase = phase
        self.duration = duration
        self.completedAt = completedAt
        self.taskId = taskId
        self.taskTitle = taskTitle
    }
}
