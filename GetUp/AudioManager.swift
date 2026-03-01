// AudioManager.swift
// Programmatic workout music via AVAudioEngine — no external files needed.
// 9 selectable styles (3 per workout category). Auto-stops on app background.

import AVFoundation
import SwiftUI
import Combine

// MARK: - Music Genre

enum MusicGenre: String, CaseIterable, Identifiable {
    // Strength
    case powerBeats    = "Power Beats"
    case hipHop        = "Hip-Hop"
    case rockDrive     = "Rock Drive"
    // Yoga
    case calmFlow      = "Calm Flow"
    case tibetanBowls  = "Tibetan Bowls"
    case natureDrone   = "Nature Drone"
    // Dance
    case danceGroove   = "Dance Groove"
    case latinBeat     = "Latin Beat"
    case edmPulse      = "EDM Pulse"

    var id: String { rawValue }

    var workoutCategory: WorkoutMusicCategory {
        switch self {
        case .powerBeats, .hipHop, .rockDrive:       return .strength
        case .calmFlow, .tibetanBowls, .natureDrone: return .yoga
        case .danceGroove, .latinBeat, .edmPulse:    return .dance
        }
    }

    var emoji: String {
        switch self {
        case .powerBeats: return "🥁"; case .hipHop: return "🎤"; case .rockDrive: return "🎸"
        case .calmFlow: return "🎵"; case .tibetanBowls: return "🔔"; case .natureDrone: return "🌿"
        case .danceGroove: return "🎧"; case .latinBeat: return "💃"; case .edmPulse: return "⚡"
        }
    }

    var bpm: Double {
        switch self {
        case .powerBeats: return 130; case .hipHop: return 90; case .rockDrive: return 120
        case .calmFlow: return 60; case .tibetanBowls: return 50; case .natureDrone: return 55
        case .danceGroove: return 128; case .latinBeat: return 120; case .edmPulse: return 138
        }
    }
}

enum WorkoutMusicCategory { case strength, yoga, dance }

// MARK: - AudioManager

@MainActor
final class AudioManager: ObservableObject {

    static let shared = AudioManager()

    @Published var isPlaying: Bool         = false
    @Published var volume: Float           = 0.70
    @Published var currentGenre: MusicGenre = .powerBeats

    // var not let — we create a fresh engine + mixer on every play() to avoid
    // AVAudioEngine crashes caused by re-attaching/re-using detached nodes.
    private var engine   = AVAudioEngine()
    private var mixer    = AVAudioMixerNode()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [AVAudioPCMBuffer]  = []
    private let sampleRate: Double = 44100
    private var cancelBag = Set<AnyCancellable>()

    private init() {
        // AUTO-STOP: stop music whenever the app goes to background or loses focus
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.stop() }
            .store(in: &cancelBag)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.stop() }
            .store(in: &cancelBag)
    }

    // MARK: - Public API

    func play(genre: MusicGenre) {
        teardown()
        currentGenre = genre
        build(genre: genre)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            scheduleLoops()
            isPlaying = true
        } catch {
            print("AudioManager: start failed – \(error)")
        }
    }

    func stop() {
        teardown()
        isPlaying = false
    }

    func toggle(genre: MusicGenre) {
        if isPlaying && currentGenre == genre { stop() } else { play(genre: genre) }
    }

    func setVolume(_ v: Float) {
        volume = v
        mixer.outputVolume = v
    }

    static func defaultGenre(for category: WorkoutMusicCategory) -> MusicGenre {
        switch category { case .strength: return .powerBeats; case .yoga: return .calmFlow; case .dance: return .danceGroove }
    }

    static func genres(for category: WorkoutMusicCategory) -> [MusicGenre] {
        MusicGenre.allCases.filter { $0.workoutCategory == category }
    }

    // MARK: - Engine lifecycle

    private func teardown() {
        // 1. Stop all player nodes
        players.forEach { $0.stop() }
        // 2. MUST explicitly detach each node from the engine before releasing it.
        //    Replacing `engine` without detaching leaves nodes dangling inside the
        //    old engine's graph — that's what causes the crash on genre switch.
        players.forEach { engine.detach($0) }
        players.removeAll()
        buffers.removeAll()
        // 3. Stop engine, then replace both engine and mixer with fresh instances
        if engine.isRunning { engine.stop() }
        engine = AVAudioEngine()
        mixer  = AVAudioMixerNode()
    }

    private func build(genre: MusicGenre) {
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        // Fresh engine: attach mixer first, connect to main output
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: fmt)
        mixer.outputVolume = volume
        switch genre {
        case .powerBeats:   buildPowerBeats(fmt)
        case .hipHop:       buildHipHop(fmt)
        case .rockDrive:    buildRockDrive(fmt)
        case .calmFlow:     buildCalmFlow(fmt)
        case .tibetanBowls: buildTibetanBowls(fmt)
        case .natureDrone:  buildNatureDrone(fmt)
        case .danceGroove:  buildDanceGroove(fmt)
        case .latinBeat:    buildLatinBeat(fmt)
        case .edmPulse:     buildEDMPulse(fmt)
        }
    }

    private func scheduleLoops() {
        for (p, b) in zip(players, buffers) {
            p.scheduleBuffer(b, at: nil, options: .loops); p.play()
        }
    }

    // MARK: - Buffer utilities

    private func barFrames(_ bpm: Double, beats: Int = 4) -> AVAudioFrameCount {
        AVAudioFrameCount((60.0 / bpm) * Double(beats) * sampleRate)
    }

    private func buf(_ n: AVAudioFrameCount, _ fmt: AVAudioFormat, _ fn: (Int, Double) -> Float) -> AVAudioPCMBuffer {
        let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: n)!
        b.frameLength = n
        let L = b.floatChannelData![0]; let R = b.floatChannelData![1]
        for i in 0..<Int(n) { let s = max(-1, min(1, fn(i, sampleRate))); L[i] = s; R[i] = s }
        return b
    }

    private func attach(_ bufs: [AVAudioPCMBuffer], _ fmt: AVAudioFormat) {
        for b in bufs {
            let n = AVAudioPlayerNode()
            engine.attach(n); engine.connect(n, to: mixer, format: fmt)
            players.append(n); buffers.append(b)
        }
    }

    // Returns time since nearest hit (or -1 if no hit has passed)
    private func nh(_ i: Int, _ hits: [Int], _ sr: Double) -> Double {
        var best = Int.max
        for h in hits { let d = i - h; if d >= 0 && d < best { best = d } }
        return best == Int.max ? -1 : Double(best) / sr
    }

    // MARK: - Strength

    private func buildPowerBeats(_ fmt: AVAudioFormat) {
        let spb = 60.0 / 130.0
        let n   = barFrames(130)
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [0, Int(spb*2*sr)], sr); guard t >= 0 else { return 0 }
            return self.kick(t) * 0.95
        }], fmt)
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [Int(spb*sr), Int(spb*3*sr)], sr); guard t >= 0 else { return 0 }
            return self.snare(t) * 0.65
        }], fmt)
        attach([buf(n, fmt) { i, sr in
            let step = Int(spb * 0.25 * sr)
            return self.closedHH(Double(i % step) / sr) * 0.18
        }], fmt)
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [0, Int(spb*2*sr)], sr); guard t >= 0 else { return 0 }
            return self.bassNote(t, 55) * 0.55
        }], fmt)
    }

    private func buildHipHop(_ fmt: AVAudioFormat) {
        let spb = 60.0 / 90.0
        let n   = barFrames(90)
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [0, Int(spb*0.75*sr), Int(spb*2*sr)], sr); guard t >= 0 else { return 0 }
            return self.kick808(t) * 1.0
        }], fmt)
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [Int(spb*sr), Int(spb*3*sr)], sr); guard t >= 0 else { return 0 }
            return self.clap(t) * 0.6
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // trap rolling hats
            let pos      = Double(i) / sr
            let gridPos  = fmod(pos, spb) / spb
            let vel: Double = (gridPos < 0.0625 || (gridPos > 0.5 && gridPos < 0.5625)) ? 0.4 : 0.1
            return self.closedHH(fmod(pos, spb * 0.0625)) * Float(vel)
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // 808 sub slide
            let t    = Double(i) / sr
            let beat = fmod(t, spb) / spb
            let freq = beat < 0.5 ? 55.0 : 49.0
            return Float(sin(2 * Double.pi * freq * t) * exp(-fmod(t, spb) * 3) * 0.7)
        }], fmt)
    }

    private func buildRockDrive(_ fmt: AVAudioFormat) {
        let spb = 60.0 / 120.0
        let n   = barFrames(120)
        attach([buf(n, fmt) { i, sr in  // double kick
            let hits = [0, Int(spb*0.5*sr), Int(spb*2*sr), Int(spb*2.5*sr)]
            let t = self.nh(i, hits, sr); guard t >= 0 else { return 0 }
            return self.kick(t) * 0.9
        }], fmt)
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [Int(spb*sr), Int(spb*3*sr)], sr); guard t >= 0 else { return 0 }
            return self.rimshot(t) * 0.55
        }], fmt)
        attach([buf(n, fmt) { i, sr in
            let hits = [Int(spb*0.5*sr), Int(spb*1.5*sr), Int(spb*2.5*sr), Int(spb*3.5*sr)]
            let t = self.nh(i, hits, sr); guard t >= 0 else { return 0 }
            return self.openHH(t) * 0.28
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // power chord
            let t = self.nh(i, [0, Int(spb*2*sr)], sr); guard t >= 0 else { return 0 }
            let env   = exp(-t * 6.0)
            let chord = tanh((sin(2*Double.pi*82.41*t) + sin(2*Double.pi*123.47*t)) * 3)
            return Float(chord * env * 0.4)
        }], fmt)
    }

    // MARK: - Yoga

    private func buildCalmFlow(_ fmt: AVAudioFormat) {
        let n = barFrames(60, beats: 8)
        attach([buf(n, fmt) { i, sr in  // A-major pad
            let t   = Double(i) / sr
            let env = 0.55 * (1 - exp(-t * 0.4)) * exp(-t * 0.08)
            let a3  = sin(2*Double.pi*220.0*t)
            let cs4 = sin(2*Double.pi*277.18*t) * 0.7
            let e4  = sin(2*Double.pi*329.63*t) * 0.5
            return Float((a3 + cs4 + e4) * env * 0.28)
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // bell on bar start
            let t = self.nh(i, [0], sr); guard t >= 0 else { return 0 }
            return Float(sin(2*Double.pi*659.25*t) * exp(-t*3) * 0.35)
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // breath noise
            let t   = Double(i) / sr
            let env = sin(Double.pi * fmod(t, 4.0) / 4.0) * 0.06
            return Float.random(in: -1...1) * Float(env)
        }], fmt)
    }

    private func buildTibetanBowls(_ fmt: AVAudioFormat) {
        let n = barFrames(50, beats: 16)
        attach([buf(n, fmt) { i, sr in  // low bowl C2 147Hz
            let t      = Double(i) / sr
            let period = 60.0 / 50.0 * 4
            let phase  = fmod(t, period)
            return Float(sin(2*Double.pi*147*t) * exp(-phase*0.6) * 0.45)
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // mid bowl G3 offset
            let t      = Double(i) / sr
            let period = 60.0 / 50.0 * 6
            let off    = 60.0 / 50.0 * 2
            let phase  = fmod(t + off, period)
            return Float(sin(2*Double.pi*196*t) * exp(-phase*0.5) * 0.35)
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // shimmer overtone
            let t = Double(i) / sr
            return Float(sin(2*Double.pi*392*t) * exp(-t*0.12) * 0.15)
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // sub drone
            let t = Double(i) / sr
            return Float(sin(2*Double.pi*73.4*t) * 0.10)
        }], fmt)
    }

    private func buildNatureDrone(_ fmt: AVAudioFormat) {
        let n = barFrames(55, beats: 16)
        var pink: Float = 0
        attach([buf(n, fmt) { i, sr in  // filtered wind noise
            let w = Float.random(in: -1...1)
            pink = pink * 0.99 + w * 0.01
            return pink * 0.3
        }], fmt)
        attach([buf(n, fmt) { i, sr in  // pentatonic melody
            let t     = Double(i) / sr
            let spb   = 60.0 / 55.0
            let notes: [(Double, Double)] = [(0, 261.63), (4, 293.66), (8, 329.63), (12, 392.0)]
            var out   = 0.0
            for (beat, freq) in notes {
                let onset = beat * spb
                guard t >= onset else { continue }
                out += sin(2*Double.pi*freq*t) * exp(-(t - onset)*0.8) * 0.18
            }
            return Float(out)
        }], fmt)
    }

    // MARK: - Dance

    private func buildDanceGroove(_ fmt: AVAudioFormat) {
        let spb = 60.0 / 128.0
        let n   = barFrames(128)
        // Kick every beat
        attach([buf(n, fmt) { i, sr in
            let step = Int(spb * sr)
            return self.kick(Double(i % step) / sr) * 0.95
        }], fmt)
        // Open hat offbeats
        attach([buf(n, fmt) { i, sr in
            let hits = [Int(spb*0.5*sr), Int(spb*1.5*sr), Int(spb*2.5*sr), Int(spb*3.5*sr)]
            let t = self.nh(i, hits, sr); guard t >= 0 else { return 0 }
            return self.openHH(t) * 0.35
        }], fmt)
        // Clap on 2 & 4
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [Int(spb*sr), Int(spb*3*sr)], sr); guard t >= 0 else { return 0 }
            return self.clap(t) * 0.5
        }], fmt)
        // Synth bass on 1 & 3
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [0, Int(spb*2*sr)], sr); guard t >= 0 else { return 0 }
            let saw = (2.0 * fmod(t * 73.42, 1.0)) - 1.0
            return Float(saw * exp(-t * 4) * 0.45)
        }], fmt)
    }

    private func buildLatinBeat(_ fmt: AVAudioFormat) {
        let spb = 60.0 / 120.0
        let n   = barFrames(120, beats: 2)
        // Son clave woodblock
        attach([buf(n, fmt) { i, sr in
            let hits = [0, Int(spb*1.5*sr), Int(spb*3*sr), Int(spb*4.5*sr), Int(spb*6.5*sr)]
            let t = self.nh(i, hits, sr); guard t >= 0 else { return 0 }
            return Float(sin(2 * Double.pi * 900 * t) * exp(-t * 60) * 0.55)
        }], fmt)
        // Conga slap
        attach([buf(n, fmt) { i, sr in
            let hits = [Int(spb*0.5*sr), Int(spb*2*sr), Int(spb*3.5*sr), Int(spb*5.5*sr)]
            let t = self.nh(i, hits, sr); guard t >= 0 else { return 0 }
            return self.conga(t) * 0.5
        }], fmt)
        // Bass on 1 & 3
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [0, Int(spb*4*sr)], sr); guard t >= 0 else { return 0 }
            return self.bassNote(t, 65.41) * 0.6
        }], fmt)
        // Cowbell accent
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [Int(spb*2.5*sr), Int(spb*6.5*sr)], sr); guard t >= 0 else { return 0 }
            let tone = sin(2*Double.pi*562*t) + sin(2*Double.pi*845*t) * 0.6
            return Float(tone * exp(-t * 12) * 0.3)
        }], fmt)
    }

    private func buildEDMPulse(_ fmt: AVAudioFormat) {
        let spb = 60.0 / 138.0
        let n   = barFrames(138, beats: 8)
        // Hard kick every beat
        attach([buf(n, fmt) { i, sr in
            let step = Int(spb * sr)
            return self.hardKick(Double(i % step) / sr) * 1.0
        }], fmt)
        // 16th closed hats
        attach([buf(n, fmt) { i, sr in
            let step = Int(spb * 0.25 * sr)
            return self.closedHH(Double(i % step) / sr) * 0.15
        }], fmt)
        // Synth lead stab
        attach([buf(n, fmt) { i, sr in
            let hits = [0, Int(spb*2*sr), Int(spb*4*sr), Int(spb*6*sr)]
            let t = self.nh(i, hits, sr); guard t >= 0 else { return 0 }
            let env = exp(-t * 5.0)
            let sq1 = sin(2 * Double.pi * 220.0 * t) > 0 ? 1.0 : -1.0
            let sq2 = sin(2 * Double.pi * 221.5 * t) > 0 ? 1.0 : -1.0
            return Float((sq1 + sq2) * 0.5 * env * 0.3)
        }], fmt)
        // Crash on bar start
        attach([buf(n, fmt) { i, sr in
            let t = self.nh(i, [0], sr); guard t >= 0 else { return 0 }
            let noise = Double.random(in: -1...1)
            return Float((noise + sin(2*Double.pi*800*t)*0.3) * exp(-t*4) * 0.4)
        }], fmt)
        // Sidechained bass
        attach([buf(n, fmt) { i, sr in
            let t = Double(i) / sr
            let sc  = 1.0 - exp(-fmod(t, spb) * 15)
            let saw = (2.0 * fmod(t * 55.0, 1.0)) - 1.0
            return Float(saw * sc * 0.5)
        }], fmt)
    }

    // MARK: - Synthesis Primitives

    private func kick(_ t: Double) -> Float {
        guard t >= 0 else { return 0 }
        return Float(sin(2*Double.pi*(80*exp(-t*25)+40)*t)*exp(-t*15))
    }
    private func hardKick(_ t: Double) -> Float {
        guard t >= 0 else { return 0 }
        let freq=100*exp(-t*40)+40; let click=Double.random(in: -1...1)*exp(-t*200)*0.3
        return Float(sin(2*Double.pi*freq*t)*exp(-t*12)+click)
    }
    private func kick808(_ t: Double) -> Float {
        guard t >= 0 else { return 0 }
        return Float(sin(2*Double.pi*(60*exp(-t*8)+40)*t)*exp(-t*4))
    }
    private func snare(_ t: Double) -> Float {
        guard t >= 0 else { return 0 }
        return Float((sin(2*Double.pi*200*t)*0.25+Double.random(in: -1...1)*0.75)*exp(-t*18))
    }
    private func rimshot(_ t: Double) -> Float {
        guard t >= 0 else { return 0 }
        return Float((sin(2*Double.pi*800*t)*0.4+sin(2*Double.pi*1200*t)*0.3+Double.random(in:-1...1)*0.3)*exp(-t*50))
    }
    private func clap(_ t: Double) -> Float {
        guard t >= 0 else { return 0 }
        let b1=Double.random(in:-1...1)*exp(-t*80)
        let b2=Double.random(in:-1...1)*exp(-(t-0.008)*60)*(t>0.008 ? 1:0)
        return Float((b1+b2+Double.random(in:-1...1)*exp(-t*20)*0.4)*0.9)
    }
    private func conga(_ t: Double) -> Float {
        guard t >= 0 else { return 0 }
        return Float(sin(2*Double.pi*(220+80*exp(-t*30))*t)*exp(-t*25)*0.8)
    }
    private func closedHH(_ t: Double) -> Float { Float(Double.random(in:-1...1)*exp(-t*90)) }
    private func openHH(_ t: Double)   -> Float { Float(Double.random(in:-1...1)*exp(-t*22)) }
    private func bassNote(_ t: Double, _ f: Double) -> Float {
        guard t >= 0 else { return 0 }
        return Float(sin(2*Double.pi*f*t)*exp(-t*7))
    }
}

// MARK: - Music Genre Picker UI

struct MusicGenrePicker: View {
    let category: WorkoutMusicCategory
    @ObservedObject private var audio = AudioManager.shared
    var accentColor: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("MUSIC STYLE").font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "444460")).kerning(2)
                Spacer()
                if audio.isPlaying {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            EQBar(delay: Double(i)*0.15, color: accentColor)
                        }
                    }.frame(height: 14)
                }
            }
            HStack(spacing: 6) {
                ForEach(AudioManager.genres(for: category)) { genre in
                    let active = audio.isPlaying && audio.currentGenre == genre
                    Button(action: { AudioManager.shared.toggle(genre: genre) }) {
                        VStack(spacing: 3) {
                            Text(genre.emoji).font(.system(size: 22))
                            Text(genre.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(active ? .white : Color(hex: "666680"))
                                .multilineTextAlignment(.center).lineLimit(2)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 9).padding(.horizontal, 4)
                        .background(active ? accentColor.opacity(0.18) : Color(hex: "0E0E18"))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(active ? accentColor.opacity(0.5) : Color(hex: "252535"), lineWidth: 1))
                        .cornerRadius(10)
                    }
                }
            }
            if audio.isPlaying { MusicVolumeSlider() }
        }
        .padding(14)
        .background(Color(hex: "14141E"))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(audio.isPlaying ? accentColor.opacity(0.3) : Color(hex: "1E1E2E"), lineWidth: 1))
        .cornerRadius(14)
    }
}

private struct EQBar: View {
    let delay: Double; let color: Color
    @State private var h: CGFloat = 0.2
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5).fill(color).frame(width: 3, height: 14*h)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).repeatForever().delay(delay)) { h = 1.0 }
            }
    }
}

struct MusicVolumeSlider: View {
    @ObservedObject private var audio = AudioManager.shared
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill").font(.system(size: 10)).foregroundColor(Color(hex: "555570"))
            Slider(value: Binding(get: { Double(audio.volume) },
                                  set: { AudioManager.shared.setVolume(Float($0)) }), in: 0...1)
                .tint(Color(hex: "5BC8FF"))
            Image(systemName: "speaker.wave.3.fill").font(.system(size: 10)).foregroundColor(Color(hex: "555570"))
        }
    }
}
