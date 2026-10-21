import Foundation

/// Dividing by a unit fraction (the web app's g5-unitdiv): W ÷ 1/d asks how many pieces of 1/d fit in W wholes.
/// Count the pieces in one whole (d), then in all of them (W × d).
/// Numbers: W (2 to 10 wholes; 2 to 4 for the first three problems of a run) and d (2 to 8; 2 to 4 at first), the web's
/// ranges and easy-first order.
///
/// On the paper (design/grade5.md, the fractions family): W whole bars, all shaded, each named 1, their column braced
/// and named W; and the 1/d piece drawn alone above them, the size it really is, named 1/d: the problem, written once as
/// the picture's own names. A whole is the family's length (48 squares; 40 for fifths, 42 for sevenths), so a piece is a
/// whole number of squares. The child drags the ruler to the end of the piece and cuts the first whole: the cut's box
/// is how many of the ruler's pieces make a whole (the web's "one" step, set by the move), and a cut that isn't the
/// piece's size is measured against the piece ("A third is longer than the 1/4 piece."). The other wholes are then cut
/// the same way and every piece is counted on (See); then the record W ÷ 1/d = W × d = [ ], the product typed. The web's
/// "one" slip (the cut lines counted, d − 1) can't be made with the ruler, which counts the pieces itself; counting cut
/// lines happens writing the record now, over every whole (W × (d − 1)), so it's the record's slip. Its "all" slip
/// (divided the wrong way, W/d) stays the record's.
///
/// Picture keys, by step (cumulative): "ruler" (the cut: the ruler's handle over the piece); "cut" (every whole cut into
/// d pieces, every piece numbered on, the record written); "done" (the answer written). A hint (after a miss, or asked
/// for) lights: "oldCuts" (the dot under the piece's end ringed: a new cut must land on it) and "last" (the last piece
/// counted, ringed).
public enum DivideByUnitFraction {
    public static func numbers(W: Int, d: Int) -> Numbers { ["W": Double(W), "d": Double(d)] }

    /// "1 whole", "3 wholes" (the web's count()).
    static func count(_ k: Int, _ one: String) -> String { "\(k) \(k == 1 ? one : one + "s")" }

    /// Name of a piece size, as the ruler's readout spells it: halves, thirds, ..., twenty-fourths.
    static func pieceName(_ d: Int, _ plural: Bool = true) -> String { UnlikeFractions.pieceName(d, plural) }

    /// What a cut at the ruler's length says, measured against the 1/d piece: `x` is how many of the ruler's pieces
    /// make a whole. Right at d; longer pieces; pieces that make the piece in twos or threes; or pieces that miss its end
    /// (one too short, the next too long).
    static func cutVerdict(_ x: Double?, d: Int) -> Verdict {
        guard let x, x > 0 else { return .soft("Drag the ruler first.") }
        if UnlikeFractions.same(x, d) { return .right }
        let piece = "the 1/\(d) piece"
        // a whole number of pieces to a whole (the ruler only makes those); anything else is named plainly
        guard x == x.rounded(), x >= 2 else { return .wrong("Those pieces aren’t the size of \(piece).") }
        let k = Int(x), one = pieceName(k, false), many = pieceName(k)
        if k < d { return .wrong("\(startsWithVowel(one) ? "An" : "A") \(one) is longer than \(piece).") }
        if k % d == 0 { return .wrong("\(k / d) \(many) make \(piece).") }
        // smaller, but their cuts step over the piece's end: m of them fall short of it, m + 1 go past
        let m = k / d
        let short = m == 1 ? "\(startsWithVowel(one) ? "An" : "A") \(one) is" : "\(m) \(many) are"
        return .wrong("\(short) shorter than \(piece). \(m + 1) \(many) are longer.")
    }

    /// A piece's name takes "an" (an eighth, an eleventh).
    static func startsWithVowel(_ word: String) -> Bool { word.first.map { "aeio".contains($0) } ?? false }

    public static let spec = LessonSpec(id: "g5-unitdiv", title: "Dividing by a unit fraction", master: "tape", generate: { rng, index in
        // the first three: a few wholes cut into halves, thirds or fourths
        if index < 3 {
            let W = Int.random(in: 2...4, using: &rng)
            return numbers(W: W, d: Int.random(in: 2...4, using: &rng))
        }
        let W = Int.random(in: 2...10, using: &rng)
        return numbers(W: W, d: Int.random(in: 2...8, using: &rng))
    }, display: { p in [.num(p["W"] ?? 0), .op("÷"), .frac(.num(1), .num(p["d"] ?? 2))] },
    idea: { _ in "Dividing by a unit fraction asks how many of those pieces fit." },
    story: { p in "You have \(fmt(p["W"] ?? 0)) cups of flour. Each batch of cookies uses 1/\(fmt(p["d"] ?? 2)) cup. How many batches can you make?" },
    storyOp: { _ in "÷" },
    depends: ["g3-unitfrac", "g3-facts"],
    check: [CheckItem(3), CheckItem(3), CheckItem(3), CheckItem(3, story: true)]) { p in
        let W = max(1, Int(p["W"] ?? 1)), d = max(2, Int(p["d"] ?? 2)), all = W * d, piece = pieceName(d)

        // the problem is written once, as the picture's own names (G 20 Oct): the first words point at the piece
        let ask = LessonStep(StepWords(say: "Look at the piece. How many fit in all the wholes?", hint: "Look at the wholes. How many pieces fit?", action: "Let’s find out"))

        // the cut: the ruler set to the piece's length cuts the first whole. Its box is how many of the ruler's pieces
        // make a whole (the web's "one": d); a cut that isn't the piece's size is measured against the piece. The hint is
        // the spec's narration (specs/k12/grade5.md §3)
        let cut = LessonStep(
            StepWords(say: "How many fit in one whole? Drag the ruler to the end of the piece, then cut.",
                      hint: "Cut one whole into \(piece).", action: "Cut"),
            answer: AnswerTask(
                prompt: [.num(1), .op("="), .box("x"), .op("×"), .frac(.num(1), .num(Double(d)))],
                expected: ["x": Double(d)],
                hint: "A new cut has to land on the end of the 1/\(d) piece.",
                explain: "\(d) pieces the size of 1/\(d) make one whole.",
                check: { v in cutVerdict(v["x"], d: d) }, byHand: true),
            picture: ["ruler": 1], onMiss: ["oldCuts": 1])

        // the record, as school writes it: W ÷ 1/d = W × d = [W·d], the product typed. Its slips are the web's: divided
        // the wrong way ("all"), and the cut lines counted instead of the pieces ("one"), now over every whole
        let allHint = "\(count(W, "whole")), \(count(d, "piece")) in each."
        let wrongWay = (Double(W) / Double(d) * 1_000_000).rounded() / 1_000_000
        let write = LessonStep(
            StepWords(say: "How many \(piece) in all? Write it.", hint: "Every whole holds \(d), so count them all.", action: "Check"),
            answer: AnswerTask(
                prompt: [.num(Double(W)), .op("÷"), .frac(.num(1), .num(Double(d))), .op("="), .num(Double(W)), .op("×"), .num(Double(d)), .op("="), .box("n")],
                expected: ["n": Double(all)],
                known: [(["n": wrongWay], "The pieces are small, so lots of them fit. The answer is bigger than \(W)."),
                        (["n": Double(W * (d - 1))], "Count the pieces, not the cut lines between them.")],
                hint: allHint, explain: "\(allHint) That makes \(all)."),
            picture: ["cut": 1], onMiss: ["last": 1])

        // the answer is in the record; the last words say why it's W × d
        let done = LessonStep(StepWords(say: "\(d) pieces in every whole.",
                                        hint: "Dividing by a unit fraction asks how many of those pieces fit.",
                                        action: "Next problem"),
                              picture: ["cut": 1, "done": 1])
        return [ask, cut, write, done]
    }
}
