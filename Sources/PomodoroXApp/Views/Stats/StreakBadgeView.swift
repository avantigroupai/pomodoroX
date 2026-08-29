import SwiftUI
import PomodoroXCore

public struct StreakBadgeView: View {
    public var streakDays: Int
    public var todayMinutes: Double
    public var totalSessions: Int

    public init(streakDays: Int, todayMinutes: Double, totalSessions: Int) {
        self.streakDays = streakDays
        self.todayMinutes = todayMinutes
        self.totalSessions = totalSessions
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Streak Card
            statCard(
                title: "DAY STREAK",
                value: "\(streakDays)",
                unit: "days",
                icon: "flame.fill",
                color: .pxFocusPrimary
            )

            // Today Focus Time
            statCard(
                title: "TODAY FOCUS",
                value: formatMinutes(todayMinutes),
                unit: todayMinutes >= 60 ? "hrs" : "mins",
                icon: "clock.fill",
                color: .pxShortBreakPrimary
            )

            // Total Sessions
            statCard(
                title: "COMPLETED",
                value: "\(totalSessions)",
                unit: "sessions",
                icon: "checkmark.seal.fill",
                color: .pxLongBreakPrimary
            )
        }
    }

    private func statCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(Color.pxTextSecondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.pxTextSecondary)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func formatMinutes(_ minutes: Double) -> String {
        if minutes >= 60 {
            return String(format: "%.1f", minutes / 60.0)
        } else {
            return "\(Int(minutes))"
        }
    }
}
