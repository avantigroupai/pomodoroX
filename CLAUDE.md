# PomodoroX Development & Release Guidelines

## Overview
PomodoroX is a high-performance Pomodoro Timer for macOS (14.0+) and iOS (17.0+) built with Swift 6 and SwiftUI.

## Architecture
- **`Sources/PomodoroXCore`**: Business logic, `TimerService`, `StorageService`, `AmbientAudioEngine` (procedural DSP audio synthesis), and `@Observable` ViewModels (`PomodoroViewModel`, `TasksViewModel`, `StatsViewModel`).
- **`Sources/PomodoroXApp`**: SwiftUI user interface, liquid glass styling, MenuBarExtra support, and views.
- **`Tests/PomodoroXCoreTests`**: 46 unit and component tests.
- **`website/`**: Landing page hosted on GitHub Pages with downloadable notarized DMG artifacts in `website/downloads/`.

## Commands

### Running Tests
```bash
# SPM Tests
swift test

# Xcode Project Tests
xcodebuild -scheme PomodoroXTests -destination 'platform=macOS,arch=arm64' test
```

### Release Build & Notarization
When asked for **"release build"**, **"build and publish"**, **"create release"**, or **"publish latest dmg"**:
1. Run test suite: `swift test`
2. Update version and build number in `version.env`, `Info-macOS.plist`, `Info-iOS.plist`, `CHANGELOG.md`, and `website/index.html`.
3. Run notarization release script:
   ```bash
   ./Scripts/notarize_release.sh
   ```
   *This builds the Release app, signs with Apple Developer ID, notarizes with Apple Notary Service, staples tickets, generates signed & notarized DMG, and copies it to `website/downloads/PomodoroX.dmg` and `website/downloads/PomodoroX-<version>.dmg`.*
4. Commit and push to main:
   ```bash
   git add -A
   git commit -m "chore(release): bump version to <version> (build <build>) and publish notarized DMG"
   git push origin main
   ```
   *(GitHub Actions automatically deploys the website and latest DMG to GitHub Pages).*
