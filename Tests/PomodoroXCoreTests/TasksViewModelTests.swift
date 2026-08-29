import XCTest
@testable import PomodoroXCore

@MainActor
final class TasksViewModelTests: XCTestCase {
    func testTasksViewModelInitialization() {
        let viewModel = TasksViewModel()
        XCTAssertNotNil(viewModel.tasks)
        XCTAssertNotNil(viewModel.pendingTasks)
        XCTAssertNotNil(viewModel.completedTasks)
    }

    func testAddTaskValidationAndTrimming() {
        let viewModel = TasksViewModel()
        let initialCount = viewModel.tasks.count

        // Empty title should not be added
        viewModel.addTask(title: "   ", estimatedPomodoros: 2, category: .general, notes: "")
        XCTAssertEqual(viewModel.tasks.count, initialCount)

        // Valid title with surrounding whitespace should be trimmed
        viewModel.addTask(title: "  Fix Memory Leak  ", estimatedPomodoros: 3, category: .coding, notes: "Profiling")
        XCTAssertEqual(viewModel.tasks.count, initialCount + 1)

        let addedTask = viewModel.tasks.first
        XCTAssertEqual(addedTask?.title, "Fix Memory Leak")
        XCTAssertEqual(addedTask?.estimatedPomodoros, 3)
        XCTAssertEqual(addedTask?.category, .coding)
        XCTAssertEqual(addedTask?.notes, "Profiling")
        XCTAssertEqual(viewModel.selectedTaskId, addedTask?.id)
        XCTAssertEqual(viewModel.activeTask?.id, addedTask?.id)
    }

    func testToggleTaskCompletion() {
        let viewModel = TasksViewModel()
        viewModel.addTask(title: "Write documentation", estimatedPomodoros: 2, category: .writing)
        guard let task = viewModel.tasks.first else {
            XCTFail("Task not created")
            return
        }

        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)

        viewModel.toggleTaskCompletion(task)

        guard let updated = viewModel.tasks.first(where: { $0.id == task.id }) else {
            XCTFail("Task not found")
            return
        }
        XCTAssertTrue(updated.isCompleted)
        XCTAssertNotNil(updated.completedAt)

        // Toggle back to pending
        viewModel.toggleTaskCompletion(updated)
        guard let reverted = viewModel.tasks.first(where: { $0.id == task.id }) else {
            XCTFail("Task not found")
            return
        }
        XCTAssertFalse(reverted.isCompleted)
        XCTAssertNil(reverted.completedAt)
    }

    func testIncrementCompletedPomodoro() {
        let viewModel = TasksViewModel()
        viewModel.addTask(title: "Implement Dark Mode", estimatedPomodoros: 4, category: .design)
        guard let task = viewModel.tasks.first else {
            XCTFail("Task not created")
            return
        }

        XCTAssertEqual(task.completedPomodoros, 0)
        viewModel.incrementCompletedPomodoro(for: task.id)

        let updated = viewModel.tasks.first(where: { $0.id == task.id })
        XCTAssertEqual(updated?.completedPomodoros, 1)
    }

    func testSelectTask() {
        let viewModel = TasksViewModel()
        viewModel.addTask(title: "Task 1", estimatedPomodoros: 1)
        viewModel.addTask(title: "Task 2", estimatedPomodoros: 2)

        let task1 = viewModel.tasks.last!
        let task2 = viewModel.tasks.first!

        viewModel.selectTask(task1)
        XCTAssertEqual(viewModel.selectedTaskId, task1.id)
        XCTAssertEqual(viewModel.activeTask?.id, task1.id)

        viewModel.selectTask(task2)
        XCTAssertEqual(viewModel.selectedTaskId, task2.id)
        XCTAssertEqual(viewModel.activeTask?.id, task2.id)
    }

    func testDeleteTask() {
        let viewModel = TasksViewModel()
        viewModel.addTask(title: "Task to delete", estimatedPomodoros: 1)
        guard let taskToDelete = viewModel.tasks.first else {
            XCTFail("Task not found")
            return
        }

        let countBefore = viewModel.tasks.count
        viewModel.deleteTask(taskToDelete)
        XCTAssertEqual(viewModel.tasks.count, countBefore - 1)
        XCTAssertFalse(viewModel.tasks.contains(where: { $0.id == taskToDelete.id }))
    }

    func testPendingAndCompletedFilters() {
        let viewModel = TasksViewModel()
        viewModel.addTask(title: "Pending Item", estimatedPomodoros: 1)
        viewModel.addTask(title: "Done Item", estimatedPomodoros: 1)

        let doneTask = viewModel.tasks.first!
        viewModel.toggleTaskCompletion(doneTask)

        XCTAssertTrue(viewModel.pendingTasks.allSatisfy { !$0.isCompleted })
        XCTAssertTrue(viewModel.completedTasks.allSatisfy { $0.isCompleted })
    }
}
