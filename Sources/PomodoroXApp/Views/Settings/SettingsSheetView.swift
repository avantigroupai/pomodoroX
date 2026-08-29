import SwiftUI
import PomodoroXCore

public struct SettingsSheetView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPreset: TimerPreset
    @State private var focusMinutes: Double
    @State private var shortBreakMinutes: Double
    @State private var longBreakMinutes: Double
    @State private var sessionsBeforeLongBreak: Int
    @State private var autoStartBreaks: Bool
    @State private var autoStartFocus: Bool
    @State private var soundEnabled: Bool
    @State private var notificationsEnabled: Bool

    public init(viewModel: PomodoroViewModel) {
        self.viewModel = viewModel
        _selectedPreset = State(initialValue: viewModel.settings.activePreset)
        _focusMinutes = State(initialValue: viewModel.settings.focusDuration / 60.0)
        _shortBreakMinutes = State(initialValue: viewModel.settings.shortBreakDuration / 60.0)
        _longBreakMinutes = State(initialValue: viewModel.settings.longBreakDuration / 60.0)
        _sessionsBeforeLongBreak = State(initialValue: viewModel.settings.sessionsBeforeLongBreak)
        _autoStartBreaks = State(initialValue: viewModel.settings.autoStartBreaks)
        _autoStartFocus = State(initialValue: viewModel.settings.autoStartFocus)
        _soundEnabled = State(initialValue: viewModel.settings.soundEnabled)
        _notificationsEnabled = State(initialValue: viewModel.settings.notificationsEnabled)
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Presets Section
                Section {
                    Picker("Preset Pattern", selection: $selectedPreset) {
                        ForEach(TimerPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPreset) { _, newPreset in
                        if newPreset != .custom {
                            focusMinutes = newPreset.focusMinutes
                            shortBreakMinutes = newPreset.shortBreakMinutes
                            longBreakMinutes = newPreset.longBreakMinutes
                        }
                    }
                } header: {
                    Text("FOCUS PRESETS")
                } footer: {
                    Text("Choose standard rhythm models or customize your own intervals below.")
                }

                // Timer Durations Section
                Section {
                    durationStepper(title: "Focus Duration", minutes: $focusMinutes, step: 5, range: 5...120, icon: "flame.fill", color: .pxFocusPrimary)
                    durationStepper(title: "Short Break", minutes: $shortBreakMinutes, step: 1, range: 1...30, icon: "cup.and.saucer.fill", color: .pxShortBreakPrimary)
                    durationStepper(title: "Long Break", minutes: $longBreakMinutes, step: 5, range: 5...60, icon: "sparkles", color: .pxLongBreakPrimary)

                    Stepper {
                        HStack {
                            Text("Sessions before Long Break")
                                .font(.system(size: 14))
                            Spacer()
                            Text("\(sessionsBeforeLongBreak)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.pxFocusPrimary)
                        }
                    } onIncrement: {
                        if sessionsBeforeLongBreak < 10 { sessionsBeforeLongBreak += 1 }
                    } onDecrement: {
                        if sessionsBeforeLongBreak > 2 { sessionsBeforeLongBreak -= 1 }
                    }
                } header: {
                    Text("INTERVAL DURATIONS")
                }

                // Automation Flow
                Section {
                    Toggle("Auto-start Breaks", isOn: $autoStartBreaks)
                    Toggle("Auto-start Focus Sessions", isOn: $autoStartFocus)
                } header: {
                    Text("FLOW & AUTOMATION")
                }

                // Audio & Alerts
                Section {
                    Toggle("Completion Bell & Chimes", isOn: $soundEnabled)
                    Toggle("Notifications", isOn: $notificationsEnabled)
                } header: {
                    Text("AUDIO & ALERTS")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0 (Universal)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Crafted for")
                        Spacer()
                        Text("macOS & iOS")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("ABOUT POMODOROX")
                }
            }
            .navigationTitle("Preferences")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 480)
    }

    private func durationStepper(
        title: String,
        minutes: Binding<Double>,
        step: Double,
        range: ClosedRange<Double>,
        icon: String,
        color: Color
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14))

            Spacer()

            Stepper {
                Text("\(Int(minutes.wrappedValue)) min")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } onIncrement: {
                if minutes.wrappedValue + step <= range.upperBound {
                    minutes.wrappedValue += step
                    selectedPreset = .custom
                }
            } onDecrement: {
                if minutes.wrappedValue - step >= range.lowerBound {
                    minutes.wrappedValue -= step
                    selectedPreset = .custom
                }
            }
        }
    }

    private func saveChanges() {
        var updated = viewModel.settings
        updated.activePreset = selectedPreset
        updated.focusDuration = focusMinutes * 60.0
        updated.shortBreakDuration = shortBreakMinutes * 60.0
        updated.longBreakDuration = longBreakMinutes * 60.0
        updated.sessionsBeforeLongBreak = sessionsBeforeLongBreak
        updated.autoStartBreaks = autoStartBreaks
        updated.autoStartFocus = autoStartFocus
        updated.soundEnabled = soundEnabled
        updated.notificationsEnabled = notificationsEnabled

        viewModel.updateSettings(updated)
    }
}
