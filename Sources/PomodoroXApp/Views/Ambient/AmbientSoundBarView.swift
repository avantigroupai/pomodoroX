import SwiftUI
import PomodoroXCore

public struct AmbientSoundBarView: View {
    public var selectedSound: AmbientSoundType
    public var isPlaying: Bool
    public var volume: Float
    public var onSelectSound: (AmbientSoundType) -> Void
    public var onVolumeChange: (Float) -> Void

    @State private var showingSoundPicker = false

    public init(
        selectedSound: AmbientSoundType,
        isPlaying: Bool,
        volume: Float,
        onSelectSound: @escaping (AmbientSoundType) -> Void,
        onVolumeChange: @escaping (Float) -> Void
    ) {
        self.selectedSound = selectedSound
        self.isPlaying = isPlaying
        self.volume = volume
        self.onSelectSound = onSelectSound
        self.onVolumeChange = onVolumeChange
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Live Waveform / Sound Icon
            Menu {
                ForEach(AmbientSoundType.allCases) { sound in
                    Button {
                        onSelectSound(sound)
                    } label: {
                        HStack {
                            Label(sound.rawValue, systemImage: sound.iconName)
                            if selectedSound == sound {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isPlaying && selectedSound != .none {
                        AudioWaveformView()
                    } else {
                        Image(systemName: selectedSound.iconName)
                            .font(.system(size: 14))
                    }

                    Text(selectedSound == .none ? "Ambient: Off" : selectedSound.rawValue)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.pxTextSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Volume Control (if active sound)
            if selectedSound != .none {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.1.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.pxTextSecondary)

                    Slider(
                        value: Binding(
                            get: { Double(volume) },
                            set: { onVolumeChange(Float($0)) }
                        ),
                        in: 0.0...1.0
                    )
                    .frame(width: 80)
                    .tint(.white.opacity(0.8))

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.pxTextSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedSound)
    }
}

public struct AudioWaveformView: View {
    @State private var animating = false

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.pxShortBreakPrimary)
                    .frame(width: 2.5, height: animating ? CGFloat([14, 8, 16, 10][index]) : 4)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}
