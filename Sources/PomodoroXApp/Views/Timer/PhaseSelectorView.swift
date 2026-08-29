import SwiftUI
import PomodoroXCore

public struct PhaseSelectorView: View {
    public var selectedPhase: PomodoroPhase
    public var onSelect: (PomodoroPhase) -> Void
    @Namespace private var phaseNamespace

    public init(selectedPhase: PomodoroPhase, onSelect: @escaping (PomodoroPhase) -> Void) {
        self.selectedPhase = selectedPhase
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(PomodoroPhase.allCases) { phase in
                phaseItemButton(for: phase)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func phaseItemButton(for phase: PomodoroPhase) -> some View {
        let isSelected = (selectedPhase == phase)
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                onSelect(phase)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: phase.iconName)
                    .font(.system(size: 13, weight: .semibold))
                Text(phase.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : Color.pxTextSecondary)
            .background {
                if isSelected {
                    Capsule()
                        .fill(LinearGradient.phaseGradient(for: phase))
                        .matchedGeometryEffect(id: "activePhase", in: phaseNamespace)
                        .shadow(color: phaseColor(for: phase).opacity(0.4), radius: 8, x: 0, y: 3)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func phaseColor(for phase: PomodoroPhase) -> Color {
        switch phase {
        case .focus: return .pxFocusPrimary
        case .shortBreak: return .pxShortBreakPrimary
        case .longBreak: return .pxLongBreakPrimary
        }
    }
}
