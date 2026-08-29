import SwiftUI
import Charts
import PomodoroXCore

public struct StatsView: View {
    @Bindable var statsViewModel: StatsViewModel
    @State private var selectedDayStat: DailyFocusStat? = nil

    public init(statsViewModel: StatsViewModel) {
        self.statsViewModel = statsViewModel
    }

    private var averageDailyMinutes: Double {
        let stats = statsViewModel.weeklyFocusStats
        guard !stats.isEmpty else { return 0 }
        let total = stats.reduce(0.0) { $0 + $1.focusMinutes }
        return total / Double(stats.count)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Productivity Insights")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Track your focus rhythm and momentum")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.pxTextSecondary)
                    }
                    Spacer()

                    if statsViewModel.sessions.isEmpty {
                        Button {
                            withAnimation {
                                statsViewModel.seedSampleDataIfEmpty()
                            }
                        } label: {
                            Text("Load Sample Data")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.pxShortBreakPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.pxShortBreakPrimary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("Pre-populate history with demo data")
                    }
                }
                .padding(.top, 14)

                // High level KPI Cards
                StreakBadgeView(
                    streakDays: statsViewModel.currentDayStreak,
                    todayMinutes: statsViewModel.totalFocusMinutesToday,
                    totalSessions: statsViewModel.totalFocusSessionsCount
                )

                // Weekly Focus Chart Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LAST 7 DAYS FOCUS")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(Color.pxTextSecondary)

                            if let selected = selectedDayStat {
                                Text("\(selected.dayLabel): \(Int(selected.focusMinutes))m (\(selected.sessionsCount) sessions)")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.pxFocusPrimary)
                            } else {
                                Text("Avg \(Int(averageDailyMinutes))m / day")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        Spacer()

                        if selectedDayStat != nil {
                            Button("Reset") {
                                selectedDayStat = nil
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(Color.pxTextSecondary)
                        }
                    }

                    // Swift Chart with interactive selection
                    Chart {
                        ForEach(statsViewModel.weeklyFocusStats) { stat in
                            let isHighlighted = (selectedDayStat?.id == stat.id)
                            BarMark(
                                x: .value("Day", stat.dayLabel),
                                y: .value("Minutes", stat.focusMinutes)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: isHighlighted ?
                                        [Color.pxShortBreakPrimary, Color.pxShortBreakSecondary] :
                                        [Color.pxFocusPrimary, Color.pxFocusSecondary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(6)
                            .opacity((selectedDayStat == nil || isHighlighted) ? 1.0 : 0.45)

                            // Goal reference line (100 mins / 4 pomodoros)
                            RuleMark(y: .value("Daily Goal", 100))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(Color.white.opacity(0.25))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Goal: 100m")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.08))
                            AxisValueLabel {
                                if let intVal = value.as(Int.self) {
                                    Text("\(intVal)m")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.pxTextSecondary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let stringVal = value.as(String.self) {
                                    Text(stringVal)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    guard let (day, _) = proxy.value(at: location, as: (String, Double).self) else { return }
                                    if let found = statsViewModel.weeklyFocusStats.first(where: { $0.dayLabel == day }) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDayStat = found
                                        }
                                    }
                                }
                        }
                    }
                    .frame(height: 180)
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )

                // Recent Session Logs
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT SESSIONS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(Color.pxTextSecondary)
                        .padding(.leading, 4)

                    if statsViewModel.sessions.isEmpty {
                        Text("No completed sessions yet. Start the timer to record sessions!")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.pxTextSecondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(statsViewModel.sessions.prefix(8)) { session in
                            sessionRow(session)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.pxBackground)
        .onAppear {
            statsViewModel.refresh()
        }
    }

    private func sessionRow(_ session: SessionRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: session.phase.iconName)
                .font(.system(size: 13))
                .foregroundStyle(sessionColor(for: session.phase))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.taskTitle ?? session.phase.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)

                Text(formatDate(session.completedAt))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.pxTextSecondary)
            }

            Spacer()

            Text("\(Int(session.duration / 60)) min")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func sessionColor(for phase: PomodoroPhase) -> Color {
        switch phase {
        case .focus: return .pxFocusPrimary
        case .shortBreak: return .pxShortBreakPrimary
        case .longBreak: return .pxLongBreakPrimary
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
