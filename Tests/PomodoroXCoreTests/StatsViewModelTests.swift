import XCTest
@testable import PomodoroXCore

@MainActor
final class StatsViewModelTests: XCTestCase {
    func testStatsViewModelMetricsWithNoSessions() {
        let statsVM = StatsViewModel()
        statsVM.sessions = []

        XCTAssertEqual(statsVM.totalFocusMinutesToday, 0)
        XCTAssertEqual(statsVM.totalFocusSessionsCount, 0)
        XCTAssertEqual(statsVM.totalFocusHoursAllTime, 0)
        XCTAssertEqual(statsVM.currentDayStreak, 0)
    }

    func testStatsViewModelMetricsCalculations() {
        let statsVM = StatsViewModel()
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        let session1 = SessionRecord(
            phase: .focus,
            duration: 1500, // 25 mins
            completedAt: now,
            taskTitle: "Task 1"
        )
        let session2 = SessionRecord(
            phase: .focus,
            duration: 1500, // 25 mins
            completedAt: calendar.date(byAdding: .hour, value: -1, to: now)!,
            taskTitle: "Task 2"
        )
        let breakSession = SessionRecord(
            phase: .shortBreak,
            duration: 300, // 5 mins
            completedAt: now
        )

        statsVM.sessions = [session1, session2, breakSession]

        XCTAssertEqual(statsVM.totalFocusMinutesToday, 50.0, accuracy: 0.1)
        XCTAssertEqual(statsVM.totalFocusSessionsCount, 2)
        XCTAssertEqual(statsVM.totalFocusHoursAllTime, 50.0 / 60.0, accuracy: 0.01)
        XCTAssertEqual(statsVM.currentDayStreak, 1)
    }

    func testMultiDayStreakCalculation() {
        let statsVM = StatsViewModel()
        let calendar = Calendar.current
        let now = Date()

        var sessions: [SessionRecord] = []

        // Consecutive sessions over 3 days (today, yesterday, 2 days ago)
        for offset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            sessions.append(
                SessionRecord(phase: .focus, duration: 1500, completedAt: date)
            )
        }

        statsVM.sessions = sessions
        XCTAssertEqual(statsVM.currentDayStreak, 3)

        // Add a gap of 2 days, then an older session
        guard let gapDate = calendar.date(byAdding: .day, value: -5, to: now) else { return }
        sessions.append(
            SessionRecord(phase: .focus, duration: 1500, completedAt: gapDate)
        )
        statsVM.sessions = sessions
        // Streak should still be 3 because of the gap
        XCTAssertEqual(statsVM.currentDayStreak, 3)
    }

    func testYesterdayStreakWhenTodayHasNoSessions() {
        let statsVM = StatsViewModel()
        let calendar = Calendar.current
        let now = Date()

        // Yesterday session only
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return }
        let session = SessionRecord(phase: .focus, duration: 1500, completedAt: yesterday)

        statsVM.sessions = [session]
        XCTAssertEqual(statsVM.currentDayStreak, 1)
    }

    func testWeeklyFocusStats() {
        let statsVM = StatsViewModel()
        statsVM.sessions = [
            SessionRecord(phase: .focus, duration: 1800, completedAt: Date())
        ]

        let weekly = statsVM.weeklyFocusStats
        XCTAssertEqual(weekly.count, 7)
        XCTAssertEqual(weekly.last?.dayLabel, "Today")
        XCTAssertEqual(weekly.last?.focusMinutes, 30.0)
        XCTAssertEqual(weekly.last?.sessionsCount, 1)
    }

    func testDailyFocusStatModel() {
        let stat = DailyFocusStat(dayLabel: "Mon", date: Date(), focusMinutes: 45.0, sessionsCount: 2)
        XCTAssertEqual(stat.dayLabel, "Mon")
        XCTAssertEqual(stat.focusMinutes, 45.0)
        XCTAssertEqual(stat.sessionsCount, 2)
    }

    func testCategoryStatModel() {
        let stat = CategoryStat(category: .coding, pomodoroCount: 8, percentage: 40.0)
        XCTAssertEqual(stat.category, .coding)
        XCTAssertEqual(stat.pomodoroCount, 8)
        XCTAssertEqual(stat.percentage, 40.0)
    }
}
