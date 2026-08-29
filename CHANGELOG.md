# Changelog

All notable changes to **PomodoroX** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.3] - 2026-08-29

### Added
- **"Vibe Coding" Focus Sound**: Procedural DSP audio generator designed specifically for software engineers and vibe-coding sessions.
  - **40 Hz Gamma Wave Entrainment**: Isochronic pulse modulation to stimulate working memory, high-level cognition, and flow state.
  - **Warm Cyberpunk Synth Pad Drone**: Multi-oscillator harmonic chord drone (A2, E3, B3, and 55 Hz sub-bass foundation) with gentle analog oscillator pitch drift.
  - **Dynamic Lowpass Filter**: 16-second breathing LFO cutoff sweep simulating an analog synth pad.
  - **Lo-Fi Tape Noise & Micro-Crackle**: Warm vintage tape floor with subtle dust micro-pops to mask ambient room distractions.
- **Comprehensive Unit & Integration Test Suite**: 46 unit and component tests covering models, ViewModels (`PomodoroViewModel`, `TasksViewModel`, `StatsViewModel`), `TimerService`, `StorageService`, `AmbientAudioEngine`, multi-day streak algorithms, presets, and serialization.
- **Apple Developer ID Notarized Release**: Automated signed and notarized DMG distribution with stapled tickets.

---

## [1.0.2] - 2026-08-28

### Added
- Real comparison matrix and technical specifications table on the landing website.
- Google Analytics 4 (GA4) tracking and Google Search Console (GSC) verification.
- Apple Developer ID notarized and stapled DMG packaging for macOS distribution.

### Changed
- Refined glassmorphism styling in `MenuBarView` and app interface.
- Updated landing page typography and eliminated link/logo underlines with inline CSS fallbacks.

### Fixed
- Fixed layout stacking and alignment issues across glassmorphic cards on the website.

---

## [1.0.1] - 2026-08-27

### Added
- Interactive web soundboard with live audio equalizer animations and sound toggles.
- High-resolution Apple app icon assets (1024x1024, @2x, @3x, and .icns for macOS).
- GitHub Pages automated deployment workflow.

### Changed
- Improved MenuBarExtra responsive layout for macOS menu bar popovers.

---

## [1.0.0] - 2026-08-26

### Added
- Initial release of **PomodoroX** for macOS 14+ and iOS 17+.
- **Timer Presets**: Classic (25/5), Deep Flow (50/10), Ultradian (90/20), Sprint (15/3), and Custom durations.
- **Procedural Ambient Sound Engine**: Built-in real-time DSP audio generation for *Ocean Waves, Deep Pink Noise, Brown Noise, and Forest Stream*.
- **Harmonic Singing Bowl**: 528 Hz Solfeggio clarity bell chime on session completion.
- **macOS Menu Bar Extra**: Native menu bar timer countdown and quick controls popover.
- **Productivity Dashboard**: Swift Charts 7-day focus analytics, streak badge tracking, and session history persistence.
- **Task Management**: Integrated task list with Pomodoro estimations (`🍅 🍅 ⚪️`) and active task binding.
- **Glassmorphism & Glow UI**: Dynamic themes for Focus (tomato glow), Short Break (cyan), and Long Break (lavender).
