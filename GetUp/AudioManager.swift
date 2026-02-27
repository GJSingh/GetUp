// AudioManager.swift
// Programmatic background music using AVAudioEngine — no external audio files needed.
// Generates looping rhythmic tones tuned to each exercise category.

import AVFoundation
import SwiftUI

// MARK: - Music Style

enum WorkoutMusicStyle {
    case strength   // 130 BPM, punchy kick-snare pattern, motivational
    case yoga       // 60 BPM, soft ambient drone with gentle chimes
    case dance      // 128 BPM, four-on-the-floor groove with synth hits

    var bpm: Double {
        switch self {
        case .strength: return 130
        case .yoga:     return 60
        case .dance:    return 128
        }
    }

    var displayName: String {
        switch self {
        case .strength: return "Power Beats"
        case .yoga:     return "Calm Flow"
        case .dance:    return "Dance Groove"
        }
    }

    var emoji: String {
        switch self {
        case .strength: return "🥁"
        case .yoga:     return "🎵"
        case .dance:    return "🎧"
        }
    }
}

// MARK: - AudioManager

@MainActor
final class AudioManager: ObservableObject {

    static let shared = AudioManager()

    @Published var isPlaying: Bool = false
    @Published var volume: Float = 0.7
    @Published var currentStyle: WorkoutMusicStyle = .strength

    // Engine graph
    private let engine    = AVAudioEngine()
    private let mixer     = AVAudioMixerNode()
    private var players:  [AVAudioPlayerNode] = []
    private var buffers:  [AVAudioPCMBuffer] = []

    // Per-style source nodes
    private var kickNode:  AVAudioPlayerNode?
    private var snareNode: AVAudioPlayerNode?
    private var bassNode:  AVAudioPlayerNode?
    private var hihatNode: AVAudioPlayerNode?
    private var padNode:   AVAudioPlayerNode?

    private let sampleRate: Double = 44100
    private var isEngineBuilt = false

    private init() {}

    // MARK: - Public API

    func play(style: WorkoutMusicStyle) {
        currentStyle = style
        stopInternal()
        buildEngine(for: style)
        startEngine()
        isPlaying = true
    }

    func stop() {
        stopInternal()
        isPlaying = false
    }

    func setVolume(_ v: Float) {
        volume = v
        mixer.outputVolume = v
    }

    func toggle(style: WorkoutMusicStyle) {
        if isPlaying && currentStyle == style {
            stop()
        } else {
            play(style: style)
        }
    }

    // MARK: - Engine Lifecycle

    private func stopInternal() {
        for p in players { p.stop() }
        players.removeAll()
        buffers.removeAll()
        if engine.isRunning { engine.stop() }
        // Detach all non-main nodes
        for node in [kickNode, snareNode, bassNode, hihatNode, padNode].compactMap({ $0 }) {
            if engine.attachedNodes.contains(node) {
                engine.detach(node)
            }
        }
        kickNode = nil; snareNode = nil; bassNode = nil; hihatNode = nil; padNode = nil
        isEngineBuilt = false
    }

    private func buildEngine(for style: WorkoutMusicStyle) {
        guard !isEngineBuilt else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        mixer.outputVolume = volume

        switch style {
        case .strength: buildStrengthPattern(format: format)
        case .yoga:     buildYogaPattern(format: format)
        case .dance:    buildDancePattern(format: format)
        }

        isEngineBuilt = true
    }

    private func startEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            scheduleAllLoops()
        } catch {
            print("AudioManager: engine start failed – \(error)")
            isPlaying = false
        }
    }

    // MARK: - Pattern Builders

    /// Strength: punchy 130 BPM kick on 1&3, snare on 2&4, tight hihat 8ths
    private func buildStrengthPattern(format: AVAudioFormat) {
        let secPerBeat = 60.0 / 130.0
        let barLen = Int(secPerBeat * 4 * sampleRate)

        // Kick: deep thud on beats 1 and 3
        let kickBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            // Two kick hits per bar
            let beat1 = 0
            let beat3 = Int(secPerBeat * 2 * sr)
            let hit   = closestHit(i: i, hits: [beat1, beat3], sr: sr)
            return kick(t: hit) * 1.0
        }

        // Snare: crispy snap on beats 2 and 4
        let snareBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let beat2 = Int(secPerBeat * 1 * sr)
            let beat4 = Int(secPerBeat * 3 * sr)
            let hit   = closestHit(i: i, hits: [beat2, beat4], sr: sr)
            return snare(t: hit) * 0.6
        }

        // Hihat: closed 8ths
        let hiBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let step = Int(secPerBeat * 0.5 * sr)
            let hit  = i % step
            return hihat(t: Double(hit) / sr) * 0.25
        }

        // Low bass pulse on beats 1&3
        let bassBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let beat1 = 0
            let beat3 = Int(secPerBeat * 2 * sr)
            let hit   = closestHit(i: i, hits: [beat1, beat3], sr: sr)
            return bassNote(t: hit, freq: 55.0) * 0.5
        }

        attachAndKeep([kickBuf, snareBuf, hiBuf, bassBuf], format: format)
    }

    /// Yoga: slow 60 BPM ambient — soft drone + gentle bell chimes
    private func buildYogaPattern(format: AVAudioFormat) {
        let secPerBeat = 60.0 / 60.0
        let barLen = Int(secPerBeat * 4 * sampleRate)

        // Ambient pad: slow chord (A3-C#4-E4 = A major)
        let padBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let t = Double(i) / sr
            let env = 0.6 * (1.0 - exp(-t * 0.5)) * exp(-t * 0.15)
            let a3  = sin(2 * .pi * 220.0 * t) * env
            let cs4 = sin(2 * .pi * 277.18 * t) * env * 0.7
            let e4  = sin(2 * .pi * 329.63 * t) * env * 0.5
            return Float((a3 + cs4 + e4) * 0.35)
        }

        // Bell chime on beat 1 only
        let bellBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let t = Double(i) / sr
            let env = exp(-t * 3.0)
            return Float(sin(2 * .pi * 659.25 * t) * env * 0.3)
        }

        // Soft white-noise breath every 2 beats
        let breathBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let t = Double(i) / sr
            let cycle = fmod(t, secPerBeat * 2)
            let env = sin(.pi * cycle / (secPerBeat * 2)) * 0.1
            return Float.random(in: -1...1) * Float(env)
        }

        attachAndKeep([padBuf, bellBuf, breathBuf], format: format)
    }

    /// Dance: 128 BPM four-on-the-floor, synth bass, open hats on off-beats
    private func buildDancePattern(format: AVAudioFormat) {
        let secPerBeat = 60.0 / 128.0
        let barLen = Int(secPerBeat * 4 * sampleRate)

        // Kick every beat (4 on the floor)
        let kickBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let step = Int(secPerBeat * sr)
            let hit  = i % step
            return kick(t: Double(hit) / sr) * 0.95
        }

        // Open hihat on off-beats (between every beat)
        let openHiBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let step    = Int(secPerBeat * sr)
            let offbeat = step / 2
            let pos     = i % step
            let hit     = abs(pos - offbeat)
            let t       = Double(hit) / sr
            return openHihat(t: t) * 0.35
        }

        // Synth bass line: root on 1, fifth on 3
        let synBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let beat1 = 0
            let beat3 = Int(secPerBeat * 2 * sr)
            let freqs: [(Int, Double)] = [(beat1, 73.42), (beat3, 110.0)]
            var sig = 0.0
            for (start, freq) in freqs {
                if i >= start {
                    let t   = Double(i - start) / sr
                    let env = exp(-t * 4.0)
                    let saw = (2.0 * fmod(t * freq, 1.0)) - 1.0  // sawtooth
                    sig += saw * env * 0.4
                }
            }
            return Float(sig)
        }

        // Clap on beats 2 & 4
        let clapBuf = makeBuffer(frames: AVAudioFrameCount(barLen), format: format) { i, sr in
            let beat2 = Int(secPerBeat * 1 * sr)
            let beat4 = Int(secPerBeat * 3 * sr)
            let hit   = closestHit(i: i, hits: [beat2, beat4], sr: sr)
            return snare(t: hit) * 0.45
        }

        attachAndKeep([kickBuf, openHiBuf, synBuf, clapBuf], format: format)
    }

    // MARK: - Buffer Helpers

    private func makeBuffer(frames: AVAudioFrameCount,
                            format: AVAudioFormat,
                            signal: (Int, Double) -> Float) -> AVAudioPCMBuffer {
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buf.frameLength = frames
        let L = buf.floatChannelData![0]
        let R = buf.floatChannelData![1]
        for i in 0..<Int(frames) {
            let s = signal(i, sampleRate)
            L[i] = s
            R[i] = s
        }
        return buf
    }

    private func attachAndKeep(_ bufs: [AVAudioPCMBuffer], format: AVAudioFormat) {
        for buf in bufs {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: format)
            players.append(node)
            buffers.append(buf)
        }
    }

    private func scheduleAllLoops() {
        for (node, buf) in zip(players, buffers) {
            node.scheduleBuffer(buf, at: nil, options: .loops)
            node.play()
        }
    }

    // MARK: - Synthesis Primitives

    private func kick(t: Double) -> Float {
        guard t >= 0 else { return 0 }
        let freq = 60.0 * exp(-t * 30.0) + 40.0
        let env  = exp(-t * 18.0)
        return Float(sin(2 * .pi * freq * t) * env)
    }

    private func snare(t: Double) -> Float {
        guard t >= 0 else { return 0 }
        let env   = exp(-t * 20.0)
        let tone  = sin(2 * .pi * 200.0 * t) * 0.3
        let noise = Double.random(in: -1...1) * 0.7
        return Float((tone + noise) * env)
    }

    private func hihat(t: Double) -> Float {
        let env = exp(-t * 80.0)
        return Float(Double.random(in: -1...1) * env)
    }

    private func openHihat(t: Double) -> Float {
        let env = exp(-t * 20.0)
        return Float(Double.random(in: -1...1) * env)
    }

    private func bassNote(t: Double, freq: Double) -> Float {
        guard t >= 0 else { return 0 }
        let env = exp(-t * 8.0)
        return Float(sin(2 * .pi * freq * t) * env)
    }

    // Returns time-since-nearest-hit for a given sample position
    private func closestHit(i: Int, hits: [Int], sr: Double) -> Double {
        var best = Int.max
        for h in hits {
            let d = i - h
            if d >= 0 && d < best { best = d }
        }
        return best == Int.max ? -1.0 : Double(best) / sr
    }
}

// MARK: - Music Control Button (drop-in UI component)

struct MusicControlButton: View {
    let style: WorkoutMusicStyle
    @ObservedObject private var audio = AudioManager.shared

    private var isActive: Bool { audio.isPlaying && audio.currentStyle == style }

    private var accentColor: Color {
        switch style {
        case .strength: return Color(hex: "00C896")
        case .yoga:     return Color(hex: "B57BFF")
        case .dance:    return Color(hex: "FF6B35")
        }
    }

    var body: some View {
        Button(action: { AudioManager.shared.toggle(style: style) }) {
            HStack(spacing: 8) {
                Image(systemName: isActive ? "pause.circle.fill" : "music.note")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isActive ? accentColor : Color(hex: "888899"))
                Text(isActive ? "Pause Music" : "\(style.emoji) \(style.displayName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isActive ? .white : Color(hex: "888899"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isActive
                    ? accentColor.opacity(0.15)
                    : Color(hex: "14141E")
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? accentColor.opacity(0.5) : Color(hex: "252535"), lineWidth: 1)
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Volume Slider

struct MusicVolumeSlider: View {
    @ObservedObject private var audio = AudioManager.shared

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "555570"))
            Slider(value: Binding(
                get: { Double(audio.volume) },
                set: { AudioManager.shared.setVolume(Float($0)) }
            ), in: 0...1)
            .tint(Color(hex: "5BC8FF"))
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "555570"))
        }
    }
}
