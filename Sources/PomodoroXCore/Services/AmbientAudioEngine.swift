import Foundation
import AVFoundation

public final class AmbientAudioEngine: @unchecked Sendable {
    public static let shared = AmbientAudioEngine()

    private var audioEngine: AVAudioEngine?
    private var noiseSourceNode: AVAudioSourceNode?
    private var isPlayingAmbient = false
    private var currentType: AmbientSoundType = .none
    private var targetVolume: Float = 0.5
    private var currentVolume: Float = 0.0

    // DSP State Variables
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
    private var brownLastOut: Float = 0
    private var wavePhase: Float = 0

    // Vibe Coding DSP State
    private var vibePhaseA: Float = 0
    private var vibePhaseB: Float = 0
    private var vibePhaseC: Float = 0
    private var vibePhaseSub: Float = 0
    private var vibeGammaPhase: Float = 0
    private var vibeLfoPhase: Float = 0
    private var vibeFilterOut: Float = 0
    private var vibeTapeOut: Float = 0

    // Volume Ramping Timer
    private var fadeTimer: Timer?

    public init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AmbientAudioEngine: AudioSession setup failed: \(error)")
        }
        #endif
    }

    public func setVolume(_ newVolume: Float) {
        self.targetVolume = max(0.0, min(1.0, newVolume))
        self.currentVolume = self.targetVolume
        audioEngine?.mainMixerNode.outputVolume = self.currentVolume
    }

    public func playAmbient(type: AmbientSoundType, volume: Float = 0.5, fadeDuration: TimeInterval = 0.8) {
        self.currentType = type
        self.targetVolume = max(0.0, min(1.0, volume))

        guard type != .none else {
            stopAmbient(fadeDuration: fadeDuration)
            return
        }

        stopAmbient(fadeDuration: 0.0)

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        let sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                let sample = self.generateSample(for: self.currentType)
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = sample * 0.22
                }
            }
            return noErr
        }

        self.noiseSourceNode = sourceNode
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        self.currentVolume = 0.0
        engine.mainMixerNode.outputVolume = 0.0

        do {
            try engine.start()
            isPlayingAmbient = true
            rampVolume(from: 0.0, to: self.targetVolume, duration: fadeDuration)
        } catch {
            print("AmbientAudioEngine: Failed to start engine: \(error)")
        }
    }

    public func stopAmbient(fadeDuration: TimeInterval = 0.5) {
        guard isPlayingAmbient, let engine = audioEngine else {
            audioEngine = nil
            noiseSourceNode = nil
            isPlayingAmbient = false
            return
        }

        if fadeDuration <= 0.0 {
            fadeTimer?.invalidate()
            fadeTimer = nil
            engine.stop()
            audioEngine = nil
            noiseSourceNode = nil
            isPlayingAmbient = false
            return
        }

        rampVolume(from: currentVolume, to: 0.0, duration: fadeDuration) { [weak self] in
            guard let self = self else { return }
            self.audioEngine?.stop()
            self.audioEngine = nil
            self.noiseSourceNode = nil
            self.isPlayingAmbient = false
        }
    }

    private func rampVolume(from start: Float, to end: Float, duration: TimeInterval, onComplete: (@Sendable () -> Void)? = nil) {
        fadeTimer?.invalidate()
        let steps = 20
        let timeStep = duration / Double(steps)
        var step = 0

        self.currentVolume = start
        audioEngine?.mainMixerNode.outputVolume = start

        fadeTimer = Timer.scheduledTimer(withTimeInterval: timeStep, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            step += 1
            let progress = Float(step) / Float(steps)
            let newVol = start + (end - start) * progress
            self.currentVolume = newVol
            self.audioEngine?.mainMixerNode.outputVolume = newVol

            if step >= steps {
                timer.invalidate()
                self.fadeTimer = nil
                self.currentVolume = end
                self.audioEngine?.mainMixerNode.outputVolume = end
                onComplete?()
            }
        }
    }

    // MARK: - Advanced DSP Procedural Audio Synthesis
    private func generateSample(for type: AmbientSoundType) -> Float {
        let white = Float.random(in: -1.0...1.0)
        let sampleRate: Float = 44100.0

        switch type {
        case .none:
            return 0

        case .vibeCoding:
            // 💻 VIBE CODING: 40Hz Gamma Isochronic Brainwave Entrainment + Warm Lo-Fi Synth Drone Pad + Vinyl Floor
            // 1. Slow 16s breathing LFO for subtle analog filter & detune motion
            vibeLfoPhase += (2.0 * Float.pi * 0.0625) / sampleRate
            if vibeLfoPhase > 2.0 * Float.pi { vibeLfoPhase -= 2.0 * Float.pi }
            let lfo = (sin(vibeLfoPhase) + 1.0) * 0.5

            // 2. 40Hz Gamma Focus Carrier Pulse (Isochronic brainwave entrainment)
            vibeGammaPhase += (2.0 * Float.pi * 40.0) / sampleRate
            if vibeGammaPhase > 2.0 * Float.pi { vibeGammaPhase -= 2.0 * Float.pi }
            let gammaPulse = 0.82 + (0.18 * sin(vibeGammaPhase))

            // 3. Multi-Oscillator Warm Synth Pad (A2 110Hz, E3 164.81Hz, B3 246.94Hz + Sub 55Hz)
            let detune = sin(vibeLfoPhase * 3.0) * 0.35
            let freqA: Float = 110.0 + detune
            let freqB: Float = 164.81 - detune * 0.5
            let freqC: Float = 246.94 + detune * 0.75
            let freqSub: Float = 55.0

            vibePhaseA += (2.0 * Float.pi * freqA) / sampleRate
            if vibePhaseA > 2.0 * Float.pi { vibePhaseA -= 2.0 * Float.pi }

            vibePhaseB += (2.0 * Float.pi * freqB) / sampleRate
            if vibePhaseB > 2.0 * Float.pi { vibePhaseB -= 2.0 * Float.pi }

            vibePhaseC += (2.0 * Float.pi * freqC) / sampleRate
            if vibePhaseC > 2.0 * Float.pi { vibePhaseC -= 2.0 * Float.pi }

            vibePhaseSub += (2.0 * Float.pi * freqSub) / sampleRate
            if vibePhaseSub > 2.0 * Float.pi { vibePhaseSub -= 2.0 * Float.pi }

            let oscA = (sin(vibePhaseA) * 0.45) + ((abs(vibePhaseA / Float.pi - 1.0) * 2.0 - 1.0) * 0.2)
            let oscB = sin(vibePhaseB) * 0.35
            let oscC = sin(vibePhaseC) * 0.22
            let oscSub = sin(vibePhaseSub) * 0.4

            let synthChord = (oscA + oscB + oscC + oscSub) * gammaPulse

            // 4. Warm Dynamic Lowpass Filter (One-pole smoothing)
            let filterAlpha = 0.07 + (0.06 * lfo)
            vibeFilterOut = vibeFilterOut + filterAlpha * (synthChord - vibeFilterOut)

            // 5. Lo-Fi Tape Noise & Micro-Texture
            vibeTapeOut = (vibeTapeOut + (0.015 * white)) / 1.015
            let tapeNoise = vibeTapeOut * 0.4

            // Subtle vinyl dust crackle
            let crackle = (abs(white) > 0.995) ? (white * 0.06) : 0.0

            return (vibeFilterOut * 0.8) + tapeNoise + crackle

        case .oceanWaves:
            // 🌊 REAL OCEAN WAVES: Asymmetric 11-second tidal swell + crashing crest surf + receding foam hiss
            wavePhase += (2.0 * Float.pi) / (sampleRate * 11.0)
            if wavePhase > 2.0 * Float.pi { wavePhase -= 2.0 * Float.pi }

            // Asymmetric wave swell envelope (steep crest rise, slow soothing trough recede)
            let rawSwell = (sin(wavePhase) + 1.0) * 0.5
            let swell = pow(rawSwell, 1.8)

            // Deep ocean body rumble (integrated brown noise)
            brownLastOut = (brownLastOut + (0.02 * white)) / 1.02
            let deepRumble = brownLastOut * 2.8 * (0.2 + swell * 1.6)

            // Crashing surf whitecap hiss at crest peak
            let crash = (swell > 0.6) ? (white * (swell - 0.6) * 1.8 * Float.random(in: 0.8...1.2)) : 0.0

            // Receding foam fizz
            let foam = (swell < 0.4) ? (white * (0.4 - swell) * 0.35) : 0.0

            return (deepRumble * 0.7) + (crash * 0.25) + (foam * 0.15)

        case .deepFocus:
            // Pink Noise (Paul Kellet's algorithm)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926
            return pink * 0.15

        case .brownNoise:
            // Brown / Red Noise (integrated white noise with low frequency floor)
            brownLastOut = (brownLastOut + (0.02 * white)) / 1.02
            return brownLastOut * 3.6

        case .softStream:
            // Forest Stream water trickle
            b0 = 0.82 * b0 + white * 0.18
            b1 = 0.88 * b1 + b0 * 0.12
            let ripple = sin(wavePhase * 4.0) * 0.04
            return (b1 * 1.3) + ripple + (white * 0.03)
        }
    }

    // MARK: - Completion Sound Synthesis (528 Hz Solfeggio Bell Chime)
    public func playCompletionBell() {
        let engine = AVAudioEngine()
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let durationSeconds: Double = 3.5
        let totalFrames = AVAudioFrameCount(sampleRate * durationSeconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return }
        buffer.frameLength = totalFrames

        let leftChannel = buffer.floatChannelData?[0]
        let rightChannel = buffer.floatChannelData?[1]

        let f0: Double = 528.0 // 528 Hz Transformation / Clarity bell chime
        let harmonics = [f0, f0 * 1.503, f0 * 2.001, f0 * 2.756, f0 * 3.42]
        let weights = [0.50, 0.25, 0.15, 0.09, 0.04]
        let decays = [1.2, 1.6, 2.2, 3.0, 3.8]

        for i in 0..<Int(totalFrames) {
            let t = Double(i) / sampleRate
            var sampleAcc: Double = 0.0

            for h in 0..<harmonics.count {
                let decay = exp(-t * decays[h])
                sampleAcc += sin(2.0 * .pi * harmonics[h] * t) * decay * weights[h]
            }

            let sample = Float(sampleAcc * 0.45)
            leftChannel?[i] = sample
            rightChannel?[i] = sample
        }

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.85

        do {
            try engine.start()
            playerNode.play()
            playerNode.scheduleBuffer(buffer, at: nil, options: []) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    engine.stop()
                }
            }
        } catch {
            print("AmbientAudioEngine: Failed to play completion sound: \(error)")
        }
    }
}
