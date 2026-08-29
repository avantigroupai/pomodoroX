import SwiftUI
import PomodoroXCore

public struct TaskRowView: View {
    public var task: PomodoroTask
    public var isSelected: Bool
    public var onToggleCompletion: () -> Void
    public var onSelect: () -> Void
    public var onDelete: () -> Void

    public init(
        task: PomodoroTask,
        isSelected: Bool,
        onToggleCompletion: @escaping () -> Void,
        onSelect: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.isSelected = isSelected
        self.onToggleCompletion = onToggleCompletion
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    private var isGoalReached: Bool {
        task.completedPomodoros >= task.estimatedPomodoros && task.estimatedPomodoros > 0
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggleCompletion) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Color.pxShortBreakPrimary : Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if task.isCompleted {
                        Circle()
                            .fill(Color.pxShortBreakPrimary)
                            .frame(width: 14, height: 14)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.pxBackground)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark task incomplete" : "Mark task complete")

            // Category Icon
            Image(systemName: task.category.iconName)
                .font(.system(size: 13))
                .foregroundStyle(task.isCompleted ? Color.gray : Color.pxFocusPrimary)
                .frame(width: 24)

            // Title & Tomato Indicators
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(task.isCompleted ? Color.gray : Color.white)
                        .strikethrough(task.isCompleted, color: Color.gray)

                    if isGoalReached && !task.isCompleted {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                            .help("Estimated pomodoro target achieved!")
                    }
                }

                // Pomodoro counter dots
                HStack(spacing: 4) {
                    ForEach(0..<max(task.estimatedPomodoros, task.completedPomodoros), id: \.self) { index in
                        Circle()
                            .fill(index < task.completedPomodoros ? Color.pxFocusPrimary : Color.white.opacity(0.15))
                            .frame(width: 6, height: 6)
                    }

                    Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(isGoalReached ? Color.pxFocusSecondary : Color.pxTextSecondary)
                        .padding(.leading, 2)
                }
            }

            Spacer()

            if !task.isCompleted {
                // Focus / Active Badge
                Button(action: onSelect) {
                    HStack(spacing: 4) {
                        Image(systemName: isSelected ? "flame.fill" : "play.circle")
                            .font(.system(size: 12))
                        Text(isSelected ? "Active" : "Focus")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(isSelected ? Color.white : Color.pxFocusPrimary)
                    .background(
                        isSelected ?
                        LinearGradient.phaseGradient(for: .focus) :
                        LinearGradient(colors: [Color.pxFocusPrimary.opacity(0.15), Color.pxFocusPrimary.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSelected ? "Active task" : "Set as active focus task")
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            .buttonStyle(.plain)
            .help("Delete task")
            .accessibilityLabel("Delete task")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            isSelected && !task.isCompleted ?
            Color.pxFocusPrimary.opacity(0.08) :
            Color.white.opacity(0.03)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isSelected && !task.isCompleted ? Color.pxFocusPrimary.opacity(0.4) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
}
