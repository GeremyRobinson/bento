import SwiftUI
import AVFoundation

/// The grown-ups' settings (G 20 Oct, GrownUpPage), kept on the device: sound, read aloud, and the paper's colours (as
/// the iPad is set, light or dark; the same `theme` the app and the bar's ⋯ read). Screenshots never save them: they
/// read the plain defaults, and what they set stays in memory.
@MainActor
enum AppSettings {
    /// Screenshots: nothing read from the device or saved to it.
    static var shots = false
    private static var memory: [String: Any] = [:]
    private static let d = UserDefaults.standard

    /// A soft sound for a step right, a miss, a problem done. On unless a grown-up turns it off.
    static var sound: Bool { memory["sound"] as? Bool ?? (shots ? nil : d.object(forKey: "sound") as? Bool) ?? true }
    /// Each step's words read out as they come. Off unless a grown-up turns it on (⋯ has Read it aloud either way).
    static var readAloud: Bool { memory["readAloud"] as? Bool ?? (shots ? nil : d.object(forKey: "readAloud") as? Bool) ?? false }
    /// "" as the iPad is set, or "light", or "dark".
    static var theme: String { memory["theme"] as? String ?? (shots ? nil : d.string(forKey: "theme")) ?? "" }

    static func set(sound on: Bool, saving: Bool) { put("sound", on, saving) }
    static func set(readAloud on: Bool, saving: Bool) { put("readAloud", on, saving) }
    static func set(theme t: String, saving: Bool) { put("theme", t, saving) }
    private static func put(_ key: String, _ value: Any, _ saving: Bool) {
        if saving && !shots { memory[key] = nil; d.set(value, forKey: key) } else { memory[key] = value }
    }
}

/// The app's few sounds (the grown-ups' Sound setting): soft and short, made here rather than recorded. Two notes up
/// for a step right, one low note for a miss, three up when a problem is done. Ambient, so the iPad's silent switch and
/// whatever else is playing come first. Never in a screenshot.
@MainActor
final class Sounds {
    static let shared = Sounds()
    enum Cue { case right, wrong, done }
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var buffers: [Cue: AVAudioPCMBuffer] = [:]
    private let rate = 44_100.0
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)

    func play(_ cue: Cue) {
        guard AppSettings.sound, !Shots.active else { return }
        if engine == nil { start() }
        guard let player, let engine, engine.isRunning, let b = buffer(cue) else { return }
        player.scheduleBuffer(b, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    private func start() {
        guard let format else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        let e = AVAudioEngine(), p = AVAudioPlayerNode()
        e.attach(p)
        e.connect(p, to: e.mainMixerNode, format: format)
        guard (try? e.start()) != nil else { return }
        engine = e; player = p
    }

    /// A cue's notes, made once: each a sine with a little brightness, starting quickly and falling away softly.
    private func buffer(_ cue: Cue) -> AVAudioPCMBuffer? {
        if let b = buffers[cue] { return b }
        // (frequency, start, length, loudness)
        let notes: [(Double, Double, Double, Double)]
        switch cue {
        case .right: notes = [(1046.5, 0, 0.22, 0.13), (1568.0, 0.07, 0.32, 0.11)]
        case .wrong: notes = [(233.1, 0, 0.28, 0.16)]
        case .done: notes = [(1046.5, 0, 0.3, 0.11), (1318.5, 0.08, 0.3, 0.10), (1568.0, 0.16, 0.5, 0.10)]
        }
        let length = (notes.map { $0.1 + $0.2 }.max() ?? 0.3) + 0.02, n = AVAudioFrameCount(length * rate)
        guard let format, let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n), let out = b.floatChannelData?[0] else { return nil }
        b.frameLength = n
        for i in 0..<Int(n) { out[i] = 0 }
        for (f, start, len, amp) in notes {
            let s0 = Int(start * rate)
            for j in 0..<Int(len * rate) where s0 + j < Int(n) {
                let t = Double(j) / rate, env = min(1, t / 0.006) * exp(-t / (len * 0.3))
                out[s0 + j] += Float(amp * env * (sin(2 * .pi * f * t) + 0.18 * sin(4 * .pi * f * t)))
            }
        }
        buffers[cue] = b
        return b
    }
}

/// Listens to the problem being worked, with nothing to show: plays its sounds (a step right, a miss, the problem
/// done), and reads each step's words aloud when the grown-ups asked for that (never in a test, as ⋯'s Read it aloud
/// isn't). It only watches what the paper does, so no lesson needs to know about it.
struct Listener: View {
    let model: PaperModel

    /// What the sounds hear of the problem being worked.
    struct Heard: Equatable { var id: UUID; var index: Int; var misses: Int; var solved: Bool; var right: Bool; var last: Int }

    var body: some View {
        let page = model.bars
        let worked = page?.mode == .work ? page?.current : nil
        let heard = worked.flatMap { p -> Heard? in
            guard !p.auto else { return nil }
            let l = p.lesson
            return Heard(id: p.id, index: l.index, misses: l.misses + l.missedSteps.count, solved: p.solved,
                         right: (p as? WorkProblem)?.verdict?.right == true, last: l.steps.count - 1)
        }
        // what to read: the open problem's step (or the How to's), as ⋯'s Read it aloud reads it
        let reading = page?.current
        let words = reading.map { $0.intro ?? ($0.lesson.story && $0.lesson.step.answer?.choices != nil ? $0.lesson.words.hint : $0.lesson.words.say) }
        let readKey = reading.map { "\($0.id) \($0.lesson.index) \(words ?? "")" } ?? ""
        Color.clear.frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onChange(of: heard) { old, new in Self.sounds(old, new) }
            .onChange(of: readKey) { _, key in
                guard !key.isEmpty, AppSettings.readAloud, !(page?.inTest ?? true), let words, !Shots.active else { return }
                Speech.shared.say(words)
            }
    }

    private static func sounds(_ old: Heard?, _ new: Heard?) {
        guard let old, let new, old.id == new.id else { return }
        if new.misses > old.misses { Sounds.shared.play(.wrong); return }
        // a number typed right goes green a moment before the step moves on: the sound is for the green
        if new.right && !old.right { Sounds.shared.play(new.index >= new.last - 1 ? .done : .right); return }
        if new.index > old.index && !old.right { Sounds.shared.play(new.solved ? .done : .right) }
    }
}
