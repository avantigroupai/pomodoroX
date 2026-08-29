import Foundation
import SwiftUI
import Observation

public struct DailyFocusStat: Identifiable, Sendable {
    public let id = UUID()
    public let dayLabel: String
    public let date: Date
    public let focusMinutes: Double
    public let sessionsCount: Int

    public init(dayLabel: String, date: Date, focusMinutes: Double, sessionsCount: Int) {
        self.dayLabel = dayLabel
        self.date = date
        self.focusMinutes = focusMinutes
        self.sessionsCount = sessionsCount
    }
}

public struct CategoryStat: Identifiable, Sendable {
    public let id = UUID()
    public let category: TaskCategory
    public let pomodoroCount: Int
    public let percentage: Double

    public init(category: TaskCategory, pomodoroCount: Int, percentage: Double) {
        self.category = category
        self.pomodoroCount = pomodoroCount
        self.percentage = percentage
    }
}

@Observable
public final class StatsViewModel {
    public var sessions: [SessionRecord] = []

    private let storage = StorageService.shared
    private let calendar = Calendar.current

    public init() {
        refresh()
    }

    public func refresh() {
        self.sessions = storage.loadSessions()
    }

    // MARK: - Summary Metrics
    public var totalFocusMinutesToday: Double {
        let today = calendar.startOfDay(for: Date())
        let todaySessions = sessions.filter {
            $0.phase == .focus && calendar.isDate($0.completedAt, inSameDayAs: today)
        }
        return todaySessions.reduce(0) { $0 + ($1.duration / 60.0) }
    }

    public var totalFocusSessionsCount: Int {
        sessions.filter { $0.phase == .focus }.count
    }

    public var totalFocusHoursAllTime: Double {
        let totalSecs = sessions.filter { $0.phase == .focus }.reduce(0) { $0 + $1.duration }
        return totalSecs / 3600.0
    }

    public var currentDayStreak: Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        let activeDays: Set<Date> = Set(
            sessions.filter { $0.phase == .focus }.map { calendar.startOfDay(for: $0.completedAt) }
        )

        // If today has sessions, count today
        if activeDays.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        } else {
            // Check yesterday
            let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            if activeDays.contains(yesterday) {
                checkDate = yesterday
            } else {
                return 0
            }
        }

        while true {
            if activeDays.contains(checkDate) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Last 7 Days Chart Data
    public var weeklyFocusStats: [DailyFocusStat] {
        var results: [DailyFocusStat] = []
        let today = calendar.startOfDay(for: Date())

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let daySessions = sessions.filter {
                $0.phase == .focus && calendar.isDate($0.completedAt, inSameDayAs: date)
            }
            let mins = daySessions.reduce(0.0) { $0 + ($1.duration / 60.0) }
            let label = offset == 0 ? "Today" : formatter.string(from: date)
            results.append(DailyFocusStat(dayLabel: label, date: date, focusMinutes: mins, sessionsCount: daySessions.count))
        }

        return results
    }

    // MARK: - Sample Seed Data if Empty
    public func seedSampleDataIfEmpty() {
        guard sessions.isEmpty else { return }

        var sample: [SessionRecord] = []
        let now = Date()

        // Add sessions across past 5 days
        for dayOffset in 0...4 {
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let sessionsForDay = (dayOffset == 0) ? 3 : (5 - dayOffset)

            for i in 0..<sessionsForDay {
                let sessionTime = calendar.date(byAdding: .hour, value: -(i * 2), to: dayDate) ?? dayDate
                sample.append(
                    SessionRecord(
                        phase: .focus,
                        duration: 25 * 60,
                        completedAt: sessionTime,
                        taskTitle: (i % 2 == 0) ? "Core System Architecture" : "Design Review"
                    )
                )
            }
        }

        storage.saveSessions(sample)
        self.sessions = sample
    }
}
