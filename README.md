# 🍅 PomodoroX

A modern, high-performance Pomodoro Timer for **macOS & iOS** crafted in SwiftUI and Swift 6 with ambient audio generators, macOS MenuBarExtra, Swift Charts analytics, and task management.

---

## ✨ Features

- **Glow & Glassmorphism Design**: Dynamic color themes for Focus, Short Break, and Long Break with ambient breathing animations.
- **Built-in Ambient Soundscapes**: Real-time DSP procedural sound generator for *Rain Shower, Deep Pink Noise, Brown Noise, Ocean Waves, and Forest Stream* + 528Hz harmonic Singing Bowl chime on completion.
- **macOS Menu Bar Extra**: Native menu bar timer countdown and quick controls popover.
- **Productivity Dashboard**: Swift Charts 7-day focus analytics, streak tracker, and session history.
- **Integrated Tasks**: Task manager with pomodoro estimations (`🍅 🍅 ⚪️`) and active focus binding.
- **Multiplatform**: Native support for macOS 14+ and iOS 17+.

---

## 🚀 Getting Started

### Open in Xcode
Generate the project and open with Xcode:
```bash
xcodegen generate
open PomodoroX.xcodeproj
```

### Build & Test from Terminal
```bash
# Run unit tests
swift test

# Build release binary
swift build -c release

# Or run helper script
./Scripts/build_macos.sh
```

### Keyboard Shortcuts (macOS)
- `Space`: Start / Pause
- `⌘R`: Reset Timer
- `⌘K`: Skip Phase
- `⌘⇧1`, `⌘⇧2`, `⌘⇧3`: Select Focus / Short Break / Long Break
- `⌘,`: Open Preferences
