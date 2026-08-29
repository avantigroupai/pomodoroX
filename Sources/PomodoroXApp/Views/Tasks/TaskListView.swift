import SwiftUI
import PomodoroXCore

public struct TaskListView: View {
    @Bindable var tasksViewModel: TasksViewModel
    @State private var newTaskTitle: String = ""
    @State private var selectedCategory: TaskCategory = .coding
    @State private var estimatedPomodoros: Int = 2
    @State private var isAddingTaskExpanded: Bool = false
    @State private var selectedCategoryFilter: TaskCategory? = nil

    public init(tasksViewModel: TasksViewModel) {
        self.tasksViewModel = tasksViewModel
    }

    private var filteredPendingTasks: [PomodoroTask] {
        if let filter = selectedCategoryFilter {
            return tasksViewModel.pendingTasks.filter { $0.category == filter }
        }
        return tasksViewModel.pendingTasks
    }

    private var filteredCompletedTasks: [PomodoroTask] {
        if let filter = selectedCategoryFilter {
            return tasksViewModel.completedTasks.filter { $0.category == filter }
        }
        return tasksViewModel.completedTasks
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tasks & Focus Goals")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(tasksViewModel.pendingTasks.count) pending • \(tasksViewModel.completedTasks.count) completed")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.pxTextSecondary)
                }
                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isAddingTaskExpanded.toggle()
                    }
                } label: {
                    Label(isAddingTaskExpanded ? "Cancel" : "Add Task", systemImage: isAddingTaskExpanded ? "xmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(LinearGradient.phaseGradient(for: .focus))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)
                .help("Add new task (⌘N)")
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterPill(title: "All", isSelected: selectedCategoryFilter == nil) {
                        selectedCategoryFilter = nil
                    }

                    ForEach(TaskCategory.allCases) { cat in
                        filterPill(
                            title: cat.rawValue,
                            icon: cat.iconName,
                            isSelected: selectedCategoryFilter == cat
                        ) {
                            selectedCategoryFilter = (selectedCategoryFilter == cat) ? nil : cat
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }

            // New Task Form
            if isAddingTaskExpanded {
                newTaskForm
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Task Lists
            ScrollView {
                LazyVStack(spacing: 16) {
                    if filteredPendingTasks.isEmpty && filteredCompletedTasks.isEmpty {
                        emptyStateView
                    } else {
                        if !filteredPendingTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("TO DO")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(Color.pxTextSecondary)
                                    .padding(.leading, 4)

                                ForEach(filteredPendingTasks) { task in
                                    TaskRowView(
                                        task: task,
                                        isSelected: tasksViewModel.selectedTaskId == task.id,
                                        onToggleCompletion: {
                                            withAnimation {
                                                tasksViewModel.toggleTaskCompletion(task)
                                            }
                                        },
                                        onSelect: {
                                            tasksViewModel.selectTask(task)
                                        },
                                        onDelete: {
                                            withAnimation {
                                                tasksViewModel.deleteTask(task)
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        if !filteredCompletedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("COMPLETED")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(Color.pxTextSecondary)
                                    .padding(.leading, 4)

                                ForEach(filteredCompletedTasks) { task in
                                    TaskRowView(
                                        task: task,
                                        isSelected: false,
                                        onToggleCompletion: {
                                            withAnimation {
                                                tasksViewModel.toggleTaskCompletion(task)
                                            }
                                        },
                                        onSelect: {},
                                        onDelete: {
                                            withAnimation {
                                                tasksViewModel.deleteTask(task)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color.pxBackground)
    }

    private func filterPill(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isSelected ? .white : Color.pxTextSecondary)
            .background(isSelected ? Color.pxFocusPrimary.opacity(0.3) : Color.white.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.pxFocusPrimary.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - New Task Form
    private var newTaskForm: some View {
        VStack(spacing: 12) {
            TextField("What are you working on?", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                .foregroundStyle(.white)
                .onSubmit {
                    submitTask()
                }

            HStack(spacing: 12) {
                // Category Picker Menu
                Menu {
                    ForEach(TaskCategory.allCases) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            Label(cat.rawValue, systemImage: cat.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedCategory.iconName)
                        Text(selectedCategory.rawValue)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Pomodoro Target Stepper
                HStack(spacing: 8) {
                    Text("Est:")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.pxTextSecondary)

                    Button {
                        if estimatedPomodoros > 1 { estimatedPomodoros -= 1 }
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Text("\(estimatedPomodoros) 🍅")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)

                    Button {
                        if estimatedPomodoros < 12 { estimatedPomodoros += 1 }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

                Spacer()

                Button {
                    submitTask()
                } label: {
                    Text("Save")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color.pxFocusPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func submitTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        tasksViewModel.addTask(
            title: newTaskTitle,
            estimatedPomodoros: estimatedPomodoros,
            category: selectedCategory
        )
        newTaskTitle = ""
        withAnimation {
            isAddingTaskExpanded = false
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 40))
                .foregroundStyle(Color.white.opacity(0.2))
                .padding(.top, 36)
            Text(selectedCategoryFilter != nil ? "No tasks in this category" : "No tasks yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            Text("Add tasks to track your pomodoro estimates and focus momentum.")
                .font(.system(size: 13))
                .foregroundStyle(Color.pxTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
        }
    }
}
