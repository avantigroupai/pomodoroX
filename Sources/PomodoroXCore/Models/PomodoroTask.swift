import Foundation

public enum TaskCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case work = "Work"
    case coding = "Coding"
    case study = "Study"
    case writing = "Writing"
    case design = "Design"
    case general = "General"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .work: return "briefcase.fill"
        case .coding: return "curlybraces"
        case .study: return "book.closed.fill"
        case .writing: return "pencil.line"
        case .design: return "paintpalette.fill"
        case .general: return "checklist"
        }
    }
}

public struct PomodoroTask: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var estimatedPomodoros: Int
    public var completedPomodoros: Int
    public var isCompleted: Bool
    public var category: TaskCategory
    public var createdAt: Date
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        estimatedPomodoros: Int = 1,
        completedPomodoros: Int = 0,
        isCompleted: Bool = false,
        category: TaskCategory = .general,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.estimatedPomodoros = max(1, estimatedPomodoros)
        self.completedPomodoros = max(0, completedPomodoros)
        self.isCompleted = isCompleted
        self.category = category
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
