import SwiftUI
import AudioToolbox

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
/// for a step right, one low note for a miss, three up when a problem is done. They're played as system sounds, by the
/// iPad's own sound server, so nothing heavy runs in the app (an audio engine started on a busy moment can stall it)
/// and the iPad's volume and silent mode come first. Never in a screenshot.
@MainActor
final class Sounds {
    static let shared = Sounds()
    enum Cue: String, CaseIterable { case right, wrong, done }
    private var ids: [Cue: SystemSoundID] = [:]
    private var failed: Set<Cue> = []

    func play(_ cue: Cue) {
        guard AppSettings.sound, !Shots.active, let id = ids[cue] ?? make(cue) else { return }
        AudioServicesPlaySystemSound(id)
    }

    /// A cue made once: its notes written as a small sound file in the caches, and handed to the sound server.
    private func make(_ cue: Cue) -> SystemSoundID? {
        guard !failed.contains(cue), let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let url = dir.appendingPathComponent("sound-\(cue.rawValue).wav")
        var id: SystemSoundID = 0
        guard (try? Self.wav(cue).write(to: url, options: .atomic)) != nil, AudioServicesCreateSystemSoundID(url as CFURL, &id) == noErr else {
            failed.insert(cue); return nil
        }
        ids[cue] = id
        return id
    }

    /// A cue's notes as a sound file (16-bit, one channel): each note a sine with a little brightness, starting quickly
    /// and falling away softly.
    static func wav(_ cue: Cue) -> Data {
        let rate = 44_100.0
        // (frequency, start, length, loudness)
        let notes: [(Double, Double, Double, Double)]
        switch cue {
        case .right: notes = [(1046.5, 0, 0.22, 0.30), (1568.0, 0.07, 0.32, 0.26)]
        case .wrong: notes = [(233.1, 0, 0.28, 0.40)]
        case .done: notes = [(1046.5, 0, 0.3, 0.26), (1318.5, 0.08, 0.3, 0.24), (1568.0, 0.16, 0.5, 0.24)]
        }
        let n = Int(((notes.map { $0.1 + $0.2 }.max() ?? 0.3) + 0.02) * rate)
        var samples = [Double](repeating: 0, count: n)
        for (f, start, len, amp) in notes {
            let s0 = Int(start * rate)
            for j in 0..<Int(len * rate) where s0 + j < n {
                let t = Double(j) / rate, env = min(1, t / 0.006) * exp(-t / (len * 0.3))
                samples[s0 + j] += amp * env * (sin(2 * .pi * f * t) + 0.18 * sin(4 * .pi * f * t))
            }
        }
        var d = Data()
        func put32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func put16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        d.append(contentsOf: Array("RIFF".utf8)); put32(UInt32(36 + 2 * n)); d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8)); put32(16); put16(1); put16(1); put32(UInt32(rate)); put32(UInt32(rate) * 2); put16(2); put16(16)
        d.append(contentsOf: Array("data".utf8)); put32(UInt32(2 * n))
        for v in samples { put16(UInt16(bitPattern: Int16(max(-1, min(1, v)) * 32_000))) }
        return d
    }
}

/// Listens to the problem being worked, with nothing to show: plays its sounds (a step right, a miss, the problem
/// done), and reads each step's words aloud when the grown-ups asked for that (never in a test, as ⋯'s Read it aloud
/// isn't). It only watches what the paper does, so no lesson needs to know about it.
struct Listener: View {
    let model: PaperModel

    /// What the sounds hear of the problem being worked.
    struct Heard: Equatable {
        var id: UUID; var index: Int; var misses: Int; var solved: Bool; var right: Bool; var last: Int
        /// The step on had a miss in a test (one try): it shows its answer and moves on by itself, which is no right.
        var shownAnswer: Bool
    }

    var body: some View {
        let page = model.bars
        let worked = page?.mode == .work ? page?.current : nil
        let heard = worked.flatMap { p -> Heard? in
            guard !p.auto else { return nil }
            let l = p.lesson
            return Heard(id: p.id, index: l.index, misses: l.misses + l.missedSteps.count, solved: p.solved,
                         right: (p as? WorkProblem)?.verdict?.right == true, last: l.steps.count - 1, shownAnswer: l.oneTry && l.missedSteps.contains(l.index))
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
        // a step answered by the hands moves on as it's right; one that had a miss moves on with its answer shown
        if new.index > old.index && !old.right && !old.shownAnswer { Sounds.shared.play(new.solved ? .done : .right) }
    }
}
