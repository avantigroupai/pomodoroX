import Foundation
import SwiftUI
import Observation

@Observable
public final class TasksViewModel {
    public var tasks: [PomodoroTask] = []
    public var selectedTaskId: UUID?

    private let storage = StorageService.shared

    public init() {
        self.tasks = storage.loadTasks()
        if let first = tasks.first(where: { !$0.isCompleted }) {
            self.selectedTaskId = first.id
        }
    }

    public var activeTask: PomodoroTask? {
        tasks.first(where: { $0.id == selectedTaskId })
    }

    public var pendingTasks: [PomodoroTask] {
        tasks.filter { !$0.isCompleted }
    }

    public var completedTasks: [PomodoroTask] {
        tasks.filter { $0.isCompleted }
    }

    public func addTask(title: String, estimatedPomodoros: Int = 2, category: TaskCategory = .general, notes: String = "") {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newTask = PomodoroTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes,
            estimatedPomodoros: estimatedPomodoros,
            category: category
        )
        tasks.insert(newTask, at: 0)
        selectedTaskId = newTask.id
        storage.saveTasks(tasks)
    }

    public func toggleTaskCompletion(_ task: PomodoroTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            tasks[idx].completedAt = tasks[idx].isCompleted ? Date() : nil
            storage.saveTasks(tasks)
        }
    }

    public func selectTask(_ task: PomodoroTask) {
        selectedTaskId = task.id
    }

    public func incrementCompletedPomodoro(for taskId: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[idx].completedPomodoros += 1
            storage.saveTasks(tasks)
        }
    }

    public func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        storage.saveTasks(tasks)
    }

    public func deleteTask(_ task: PomodoroTask) {
        tasks.removeAll(where: { $0.id == task.id })
        if selectedTaskId == task.id {
            selectedTaskId = tasks.first(where: { !$0.isCompleted })?.id
        }
        storage.saveTasks(tasks)
    }
}
