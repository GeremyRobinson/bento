import Foundation

/// Mixed numbers to fractions (the web app's g5-improper): w n/d as one fraction, (w·d + n)/d.
/// Count the pieces in the wholes, add the extra pieces, and the bottom stays the same.
///
/// Numbers: w (wholes, 1–6), n (the extra pieces, 1 to d − 1, in lowest terms with d), d (the bottom, 2–9).
///
/// Picture (master "tape", the web's fraction bars, web/src/explanations/diagrams/tape): w bars one whole long, each
/// cut into d pieces and labelled "1", and under them a bar of d pieces labelled n/d, all waiting to be counted.
/// Keys (cumulative: once shown, they stay):
/// - wholes: how many whole bars are filled and counted so far (0...w). Whole j fills piece by piece, its pieces
///   numbered on from the whole before (j·d + 1 ... (j + 1)·d), with the running count (j + 1)·d beside it; the last
///   whole's count is amber. One whole per web beat, so a master can count them in one after another.
/// - extra: 1 when the n extra pieces of the last bar are filled (orange, "two") and counted on from w·d to S = w·d + n,
///   with S beside it in amber (web beat w + 1).
/// - fraction: 1 when S/d is written beside the last bar, in amber, and every bar is lit (web beat w + 2).
/// - focus: the bars this step asks about: 1 the whole bars, 2 the bar with the extra pieces, 3 all of them.
///   Absent: nothing is singled out.
public enum MixedToImproper {
    public static func numbers(w: Int, n: Int, d: Int) -> Numbers { ["w": Double(w), "n": Double(n), "d": Double(d)] }

    /// "1 whole", "3 pieces" (the web's count()).
    static func count(_ k: Int, _ one: String) -> String { "\(k) \(k == 1 ? one : one + "s")" }

    static func pieceName(_ d: Int, _ plural: Bool = true) -> String { UnlikeFractions.pieceName(d, plural) }

    public static let spec = LessonSpec(id: "g5-improper", title: "Mixed numbers to fractions", master: "tape", generate: { rng, index in
        // the web's generateMixedToImproper: the first three are 1 or 2 wholes cut into halves to fifths;
        // then a bottom of 2–9 and 1–6 wholes; the top is always in lowest terms
        let early = index < 3, d = Int.random(in: 2...(early ? 5 : 9), using: &rng)
        var n: Int
        repeat { n = Int.random(in: 1...(d - 1), using: &rng) } while gcd(n, d) != 1
        return numbers(w: Int.random(in: 1...(early ? 2 : 6), using: &rng), n: n, d: d)
    }, display: { n in [.num(n["w"] ?? 1), .frac(.num(n["n"] ?? 1), .num(n["d"] ?? 2))] },
    idea: { _ in "Cut every whole into the same pieces, then count all the pieces." },
    depends: ["g4-mixed"],
    check: [CheckItem(3), CheckItem(3, when: { ($0["d"] ?? 0) >= 6 }), CheckItem(3, when: { ($0["w"] ?? 0) >= 4 }), CheckItem(3)]) { p in
        let w = Int(p["w"] ?? 1), n = Int(p["n"] ?? 1), d = Int(p["d"] ?? 2), S = w * d + n
        let mixed = "\(w) \(n)/\(d)"
        let pieces = { (k: Int) in "\(k) \(pieceName(d, k != 1))" }

        // the web's displayNote ("Write it as one fraction.") folded into the opening question
        let ask = LessonStep(StepWords(say: "What is \(mixed) as one fraction?", hint: "Look at the bars. How many pieces are there in all?", action: "Let’s find out"))

        // hints are the spec's narration (specs/k12/grade5.md §3); the task hints and slips are the web's
        let wholes = LessonStep(StepWords(say: "Wholes into pieces", hint: "Each whole is \(pieces(d)).", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(w)), .op("×"), .num(Double(d)), .op("="), .box("x")], expected: ["x": Double(w * d)],
                               known: [(["x": Double(w + d)], "\(count(w, "whole")) with \(count(d, "piece")) each: multiply.")],
                               hint: "How many pieces are in one whole? Then in all \(w == 1 ? "of it" : "\(w) wholes")?"),
            picture: ["focus": 1])

        let extra = LessonStep(StepWords(say: "Add the extra pieces", hint: "Add the \(n) extra \(n == 1 ? "piece" : "pieces").", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(w * d)), .op("+"), .num(Double(n)), .op("="), .box("x")], expected: ["x": Double(S)],
                               known: [(["x": Double(w + n)], "Use the \(w * d) pieces the wholes make, not the \(w).")],
                               hint: "Add the \(count(n, "extra piece"))."),
            picture: ["wholes": Double(w), "focus": 2])

        // the web's ms() check is the engine's own: every box filled, the answer, then the slips, else "Not quite. <hint>"
        let fraction = LessonStep(StepWords(say: "Write the fraction", hint: "The pieces are still \(pieceName(d)), so the bottom stays \(d).", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(w)), .frac(.num(Double(n)), .num(Double(d))), .op("="), .frac(.box("n"), .box("d"))],
                               expected: ["n": Double(S), "d": Double(d)],
                               known: [(["n": Double(S), "d": Double(w * d)], "The piece size doesn’t change: the bottom stays \(d).")],
                               hint: "The top counts every piece. The bottom says how big each piece is.",
                               explain: "\(count(S, "piece")), each a \(d == 2 ? "half" : "1/\(d)"): \(S)/\(d)."),
            picture: ["wholes": Double(w), "extra": 1, "focus": 3])

        let done = LessonStep(StepWords(say: "\(mixed) = \(S)/\(d).", hint: "Cut every whole into the same pieces, then count all the pieces.", action: "Next problem"),
                              picture: ["wholes": Double(w), "extra": 1, "fraction": 1])
        return [ask, wholes, extra, fraction, done]
    }
}
