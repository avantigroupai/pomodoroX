import XCTest
@testable import PomodoroXCore

final class AmbientAudioEngineTests: XCTestCase {
    func testAmbientAudioEngineSingleton() {
        let engine = AmbientAudioEngine.shared
        XCTAssertNotNil(engine)
    }

    func testAudioEngineStateTransitions() {
        let engine = AmbientAudioEngine.shared

        engine.setVolume(0.7)
        engine.playAmbient(type: .vibeCoding, volume: 0.5, fadeDuration: 0.1)
        engine.playAmbient(type: .oceanWaves, volume: 0.4, fadeDuration: 0.1)
        engine.playAmbient(type: .deepFocus, volume: 0.4, fadeDuration: 0.1)
        engine.playAmbient(type: .brownNoise, volume: 0.4, fadeDuration: 0.1)
        engine.playAmbient(type: .softStream, volume: 0.4, fadeDuration: 0.1)
        engine.stopAmbient(fadeDuration: 0.1)
        engine.playCompletionBell()
    }
}
