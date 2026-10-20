import Foundation

/// Mixed numbers to fractions (the web app's g5-improper): w n/d as one fraction, (w·d + n)/d.
/// Count the pieces in the wholes, add the extra pieces, and the bottom stays the same.
///
/// Numbers: w (wholes, 1–6), n (the extra pieces, 1 to d − 1, in lowest terms with d), d (the bottom, 2–9).
///
/// On the paper (design/grade5.md, the fractions family): w whole bars, all shaded, each named 1, and under them a bar of
/// d pieces with n shaded, named n/d; the column of names braced (w n/d, written once, as the bars' own names). The
/// child drags the ruler and cuts every whole into the extra bar's pieces (its box is how many pieces make a whole, d;
/// the extra bar's cuts are the old cuts a new cut must land on). The pieces then number on across all the bars and the
/// wholes are named d/d (See); then the record w n/d = (w × d + n)/d = [S]/d, the top typed, the bottom written for the
/// child. The web's counting steps (w × d, then + n) are what the cut and the count show, so they're left out; their
/// slips are the record's, since they're the slips made writing its top.
///
/// Picture keys, by step (cumulative): "ruler" (the cut: the ruler's handle over the first whole); "cut" (the wholes cut
/// into d pieces, every shaded piece numbered on, the record written); "done" (the answer written). A hint (after a
/// miss, or asked for) lights: "oldCuts" (the extra bar's cuts' dots ringed: each needs a new cut on it) and "last" (the
/// last piece counted, ringed).
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
        let piece = pieceName(d), extra = "\(n)/\(d)"

        // the problem is written once, as the bars' own names (G 20 Oct): the first words ask what the lesson finds
        let ask = LessonStep(StepWords(say: "Look at the bars. How many \(piece) in all?", hint: "Cut every whole into \(piece), then count them.", action: "Let’s find out"))

        // the cut: the ruler sets one piece's size, and Cut cuts every whole into it. Its box is how many of those pieces
        // make a whole; a cut that doesn't fit is measured on the extra bar, whose cuts are the old cuts
        let cut = LessonStep(
            StepWords(say: "Drag the ruler to cut each whole into \(piece).", hint: "Every cut in the \(extra) bar needs a new cut on it.", action: "Cut"),
            answer: AnswerTask(
                prompt: [.num(1), .op("="), .frac(.box("x"), .num(Double(d)))],
                expected: ["x": Double(d)],
                hint: "Make the new cuts land on the cuts in the \(extra) bar.",
                explain: "Each whole is \(d) \(piece), the size of the \(extra) bar’s pieces.",
                check: { v in
                    guard let x = v["x"], x > 0 else { return .soft("Drag the ruler first.") }
                    if UnlikeFractions.same(x, d) { return .right }
                    // smaller pieces: a new cut on every old one, but the extra bar's pieces fit too
                    if UnlikeFractions.divides(d, x) { return .wrong("Those fit. Bigger pieces fit too.") }
                    return .wrong("Some cuts in the \(extra) bar have no new cut on them.")
                }, byHand: true),
            picture: ["ruler": 1], onMiss: ["oldCuts": 1])

        // the record, as school writes it: w n/d = (w × d + n)/d = [S]/d, the bottom written for the child. The web's
        // slips are the ones made writing the top: adding the wholes and the bottom, or forgetting to cut the wholes
        let write = LessonStep(
            StepWords(say: "How many \(piece) in all? Write it.", hint: "Count the \(piece) in all the bars.", action: "Check"),
            answer: AnswerTask(
                prompt: [.num(Double(w)), .frac(.num(Double(n)), .num(Double(d))), .op("="),
                         .frac(.text("\(w) × \(d) + \(n)"), .num(Double(d))), .op("="), .frac(.box("n"), .num(Double(d)))],
                expected: ["n": Double(S)],
                known: [(["n": Double(w + d + n)], "\(count(w, "whole")) with \(count(d, "piece")) each: multiply."),
                        (["n": Double(w + n)], "Use the \(w * d) pieces the wholes make, not the \(w).")],
                hint: "The top counts every piece. The bottom says how big each piece is.",
                explain: "\(count(S, "piece")), each a \(d == 2 ? "half" : "1/\(d)"): \(S)/\(d)."),
            picture: ["cut": 1], onMiss: ["last": 1])

        // the answer is in the record; the last words say why it's w × d + n
        let done = LessonStep(StepWords(say: "Each whole is \(d) \(piece).", hint: "Cut every whole into the same pieces, then count all the pieces.", action: "Next problem"),
                              picture: ["cut": 1, "done": 1])
        return [ask, cut, write, done]
    }
}
