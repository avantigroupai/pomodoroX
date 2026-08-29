import SwiftUI
import PomodoroXCore

public struct CircularProgressRing: View {
    public var progress: Double
    public var timeFormatted: String
    public var phase: PomodoroPhase
    public var isRunning: Bool
    public var onAdjustTime: (Int) -> Void

    @State private var pulseGlow: Bool = false

    public init(
        progress: Double,
        timeFormatted: String,
        phase: PomodoroPhase,
        isRunning: Bool,
        onAdjustTime: @escaping (Int) -> Void
    ) {
        self.progress = progress
        self.timeFormatted = timeFormatted
        self.phase = phase
        self.isRunning = isRunning
        self.onAdjustTime = onAdjustTime
    }

    public var body: some View {
        ZStack {
            // Ambient Backdrop Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            phaseColor.opacity(isRunning ? 0.28 : 0.10),
                            phaseColor.opacity(isRunning ? 0.08 : 0.02),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 155
                    )
                )
                .scaleEffect(isRunning ? (pulseGlow ? 1.12 : 0.96) : 1.0)
                .animation(
                    isRunning ? .easeInOut(duration: 2.8).repeatForever(autoreverses: true) : .easeInOut(duration: 0.3),
                    value: pulseGlow
                )
                .onAppear {
                    pulseGlow = true
                }

            // Outer decorative track
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 32)

            // Circumference Tick Marks (60-minute dial ticks)
            ForEach(0..<60) { tick in
                Rectangle()
                    .fill(tick % 5 == 0 ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: tick % 5 == 0 ? 2 : 1, height: tick % 5 == 0 ? 8 : 4)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(tick) * 6))
            }

            // Background Track
            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )

            // Dynamic Progress Stroke
            Circle()
                .trim(from: 0.0, to: CGFloat(min(1.0, max(0.001, progress))))
                .stroke(
                    LinearGradient.phaseGradient(for: phase),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
                .shadow(color: phaseColor.opacity(0.65), radius: isRunning ? 14 : 6, x: 0, y: 0)

            // Glowing Arc Beacon Head (Leading edge dot)
            if progress > 0.01 && progress < 0.99 {
                let angle = (progress * 360.0) - 90.0
                let radius: CGFloat = 130.0
                let rad = angle * .pi / 180.0
                let x = radius * cos(rad)
                let y = radius * sin(rad)

                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(color: phaseColor, radius: 8, x: 0, y: 0)
                    .offset(x: x, y: y)
                    .animation(.linear(duration: 0.2), value: progress)
            }

            // Center Content & Micro-Interactions
            VStack(spacing: 8) {
                // Phase Icon & Badge
                HStack(spacing: 6) {
                    Image(systemName: phase.iconName)
                        .font(.system(size: 13, weight: .bold))
                    Text(phase.rawValue.uppercased())
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                }
                .foregroundStyle(phaseColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(phaseColor.opacity(0.16))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(phaseColor.opacity(0.3), lineWidth: 1)
                )

                // Main Time Display
                Text(timeFormatted)
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)

                // Quick ± Adjusters
                HStack(spacing: 16) {
                    Button(action: { onAdjustTime(-5) }) {
                        Text("-5m")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.pxTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Subtract 5 minutes")
                    .accessibilityLabel("Subtract 5 minutes")

                    Button(action: { onAdjustTime(5) }) {
                        Text("+5m")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.pxTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Add 5 minutes")
                    .accessibilityLabel("Add 5 minutes")
                }
                .opacity(isRunning ? 0.35 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRunning)
            }
        }
        .frame(width: 290, height: 290)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.rawValue) timer, \(timeFormatted) remaining")
        .accessibilityValue("\(Int(progress * 100)) percent completed")
    }

    private var phaseColor: Color {
        switch phase {
        case .focus: return .pxFocusPrimary
        case .shortBreak: return .pxShortBreakPrimary
        case .longBreak: return .pxLongBreakPrimary
        }
    }
}
