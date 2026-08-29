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
    private var omPhase: Float = 0
    private var breathPhase: Float = 0
    private var dropletDecay: Float = 0
    private var dropletFreq: Float = 3200

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

        if fadeDuration > 0 {
            rampVolume(from: currentVolume, to: 0.0, duration: fadeDuration) { [weak self] in
                engine.stop()
                self?.noiseSourceNode = nil
                self?.audioEngine = nil
                self?.isPlayingAmbient = false
            }
        } else {
            engine.stop()
            noiseSourceNode = nil
            audioEngine = nil
            isPlayingAmbient = false
        }
    }

    private func rampVolume(from start: Float, to end: Float, duration: TimeInterval, onComplete: (@Sendable () -> Void)? = nil) {
        fadeTimer?.invalidate()
        let steps = 20
        let stepInterval = duration / Double(steps)
        var step = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            step += 1
            let progress = Float(step) / Float(steps)
            let vol = start + (end - start) * progress
            self.currentVolume = vol
            self.audioEngine?.mainMixerNode.outputVolume = vol

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

        case .rain:
            // 🌧 REAL RAIN: Layered diffuse rain bed + randomized Poisson raindrop impacts + soft wind gust
            // Layer 1: Diffuse background rainfall (low-pass filtered pink noise)
            b0 = 0.96 * b0 + white * 0.04
            b1 = 0.92 * b1 + b0 * 0.08
            let rainBed = (b1 * 1.8) * 0.65

            // Layer 2: Individual raindrop splatter & patter
            if Float.random(in: 0...1000) > 994.0 {
                dropletDecay = Float.random(in: 0.4...0.85)
                dropletFreq = Float.random(in: 2200...4800)
            } else {
                dropletDecay *= 0.992
            }
            let droplet = dropletDecay > 0.001 ? sin(dropletFreq * dropletDecay) * dropletDecay * 0.45 : 0.0

            return rainBed + droplet

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

        case .omChant:
            // 🕉 AUTHENTIC OM CHANTING: Sacred 136.1 Hz fundamental + harmonic throat resonance + meditative 9s breath cycle
            breathPhase += (2.0 * Float.pi) / (sampleRate * 9.0)
            if breathPhase > 2.0 * Float.pi { breathPhase -= 2.0 * Float.pi }

            // Meditative breathing envelope (smooth inhale, sustained resonant vocal tone, transcendent decay)
            let breathEnv = max(0.05, pow((sin(breathPhase) + 1.0) * 0.5, 1.2))

            // Sacred Earth Frequency 136.1 Hz (C#3) with subtle 5.2 Hz vocal vibrato
            let vibrato = sin(breathPhase * 9.0 * 5.2) * 0.8
            let f0: Float = 136.1 + vibrato
            omPhase += (2.0 * Float.pi * f0) / sampleRate
            if omPhase > 2.0 * Float.pi { omPhase -= 2.0 * Float.pi }

            // Harmonic throat overtone series: fundamental, octave, fifth, double octave, third
            let h0 = sin(omPhase) * 0.55
            let h1 = sin(omPhase * 2.0) * 0.25
            let h2 = sin(omPhase * 3.0) * 0.14
            let h3 = sin(omPhase * 4.0) * 0.08
            let h4 = sin(omPhase * 5.0) * 0.04

            // Sub-bass Tibetan singing bowl grounding undertone (68.05 Hz)
            let subBass = sin(omPhase * 0.5) * 0.20

            // Vocal Formant Filtering for deep "Ooooommmmm" resonance
            let rawVocal = (h0 + h1 + h2 + h3 + h4 + subBass) * breathEnv
            b0 = 0.88 * b0 + rawVocal * 0.12
            b1 = 0.84 * b1 + b0 * 0.16

            return b1 * 1.5

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

    // MARK: - Completion Sound Synthesis (528 Hz Chime & Om Vibration)
    public func playCompletionBell() {
        playCompletionOm()
    }

    public func playCompletionOm() {
        let engine = AVAudioEngine()
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let durationSeconds: Double = 4.0
        let totalFrames = AVAudioFrameCount(sampleRate * durationSeconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return }
        buffer.frameLength = totalFrames

        let leftChannel = buffer.floatChannelData?[0]
        let rightChannel = buffer.floatChannelData?[1]

        let f0 = 136.1 // Sacred Earth Om frequency (C#3)

        for i in 0..<Int(totalFrames) {
            let t = Double(i) / sampleRate
            let decay = exp(-t * 0.75)

            // Vocal vibrato & Formant shaping
            let vibrato = sin(2.0 * .pi * 5.2 * t) * 0.6
            let freq = f0 + vibrato

            let s0 = sin(2.0 * .pi * freq * t) * decay * 0.55
            let s1 = sin(2.0 * .pi * (freq * 2.0) * t) * (decay * 0.85) * 0.25
            let s2 = sin(2.0 * .pi * (freq * 3.0) * t) * (decay * 0.70) * 0.15
            let s3 = sin(2.0 * .pi * (freq * 4.0) * t) * (decay * 0.55) * 0.08
            let sub = sin(2.0 * .pi * (freq * 0.5) * t) * decay * 0.20

            let sample = Float((s0 + s1 + s2 + s3 + sub) * 0.75)
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
