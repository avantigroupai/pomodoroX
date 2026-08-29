#!/bin/bash
set -e

echo "🚀 Generating Xcode Project with XcodeGen..."
xcodegen generate

echo "📦 Building PomodoroX for macOS..."
swift build -c release

echo "✅ Build Complete!"
