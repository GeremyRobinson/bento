import AVFoundation
import SwiftUI

/// The voice of Kindergarten and 1st grade (most of these children can't read yet): every instruction, every miss line
/// and every Say line is spoken as it appears, calmly, in an American English voice a little slower than talking pace,
/// and the drawn speaker mark beside the instruction says it all again. A grown-up can turn it off (Settings, Read
/// aloud; on by itself for these grades). Numbers and signs are said as a person says them (Core's Spoken).
@MainActor
final class Voice: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Voice()
    private var synth = AVSpeechSynthesizer()
    override init() { super.init(); synth.delegate = self }

    /// A calm voice for children: a premium or enhanced American English voice when the iPad has one (Ava, Samantha,
    /// Zoe), else the system's own en-US voice.
    static let voice: AVSpeechSynthesisVoice? = {
        let us = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "en-US" }
        for name in ["Ava", "Samantha", "Zoe", "Allison", "Susan"] {
            for q in [AVSpeechSynthesisVoiceQuality.premium, .enhanced, .default] {
                if let v = us.first(where: { $0.name.hasPrefix(name) && $0.quality == q }) { return v }
            }
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }()
    /// A little slower than talking pace, and a touch brighter.
    static let rate = AVSpeechUtteranceDefaultSpeechRate * 0.86, pitch: Float = 1.08

    /// Says `text` now, over anything still being said. In a screenshot it's only written to the log, unless the moment
    /// asks to hear it (-voice).
    func say(_ text: String) {
        let t = Spoken.text(text)
        guard !t.isEmpty else { return }
        Self.log("say: \(t) [\(Self.voice?.name ?? "none") \(Self.voice?.quality.rawValue ?? 0)]")
        guard !Shots.active || ProcessInfo.processInfo.arguments.contains("-voice") else { return }
        // cut off what's being said; a synthesizer stopped mid-word can drop what's given it next, so a fresh one says it
        if synth.isSpeaking || synth.isPaused {
            synth.stopSpeaking(at: .immediate)
            synth = AVSpeechSynthesizer(); synth.delegate = self
        }
        let u = AVSpeechUtterance(string: t)
        u.voice = Self.voice; u.rate = Self.rate; u.pitchMultiplier = Self.pitch; u.preUtteranceDelay = 0.1
        synth.speak(u)
    }
    func stop() { synth.stopSpeaking(at: .immediate) }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        let t = u.speechString
        Task { @MainActor in Self.log("spoken: \(t)") }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) {
        let t = u.speechString
        Task { @MainActor in Self.log("cut off: \(t)") }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) {
        let t = u.speechString
        Task { @MainActor in Self.log("speaking: \(t)") }
    }

    /// Debug builds: what was said, a line each, in the app's Documents/voice.log (to check it on the simulator).
    static func log(_ line: String) {
        #if DEBUG
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("voice.log")
        let stamp = String(format: "%.2f", Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100_000))
        let data = Data("\(stamp) \(line)\n".utf8)
        if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(data); try? h.close() }
        else { try? data.write(to: url) }
        #endif
    }

    /// What the problem says now: what to do, and what a miss said, if anything (the speaker mark says both).
    static func words(_ m: WorkProblem) -> String {
        [m.sayText, m.message?.text ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

/// The drawn speaker mark (G's rules: drawn on the grid, no iOS look): a small speaker and two sound arcs in thin ink,
/// 2 × 2 squares, left of the instruction's first row.
extension Sketch {
    mutating func speaker(_ id: String, in r: CGRect, _ colour: Colour = .ink2) {
        let c = Paper.cell, x = r.minX, y = r.minY
        func P(_ u: Double, _ v: Double) -> CGPoint { CGPoint(x: x + u * c, y: y + v * c) }
        line(id + "b", [P(0.1, 0.7), P(0.55, 0.7), P(1.1, 0.25), P(1.1, 1.75), P(0.55, 1.3), P(0.1, 1.3), P(0.1, 0.7)], colour, width: Sketch.stroke)
        func arc(_ r: Double, _ k: String) {
            line(id + k, (0...10).map { i in let a = -Double.pi / 3 + Double(i) / 10 * 2 * Double.pi / 3; return P(1.15 + r * cos(a), 1 + r * sin(a)) }, colour, width: Sketch.stroke)
        }
        arc(0.4, "a1"); arc(0.75, "a2")
    }
}
