import Foundation

/// Dividing by a unit fraction (the web app's g5-unitdiv): W ÷ 1/d asks how many pieces of 1/d fit in W wholes.
/// Count the pieces in one whole (d), then in all of them (W × d).
/// Numbers: W (2 to 10 wholes; 2 to 4 for the first three problems of a run) and d (2 to 8; 2 to 4 at first).
///
/// Picture (master "tape", the web's `unitDivisionPicture`): W bars, one per whole, each shaded and labelled 1.
/// Whole j (0 = the top one) is cut into d pieces labelled "1/d", with its running count (j + 1) × d beside it,
/// on beat min(j + 1, 3):
/// - beat 1: the first whole is cut; count d.
/// - beat 2: the second whole is cut; count 2d.
/// - beat 3: every other whole, one after another (half a second apart), each count landing in turn; the last count is the answer.
/// The whole being cut and its running count are lit on the beat they're counted. The last beat is min(W, 3).
/// Keys, as the web's practice screen places the picture (`pictureAt`):
/// - "at": the beat shown with its results (everything up to and including it).
/// - "ask": the beat being asked about now, lit without its answer (absent when nothing is asked).
public enum DivideByUnitFraction {
    public static func numbers(W: Int, d: Int) -> Numbers { ["W": Double(W), "d": Double(d)] }

    /// The beat whole j is cut and counted on (the web's wholeBeat).
    public static func wholeBeat(_ j: Int) -> Int { min(j + 1, 3) }

    /// "1 whole", "3 wholes".
    static func count(_ k: Int, _ one: String) -> String { "\(k) \(k == 1 ? one : one + "s")" }

    /// Name of a piece size: halves, thirds, fourths… (the web's pieceName).
    static func pieceName(_ d: Int, plural: Bool = true) -> String {
        let names: [Int: (String, String)] = [
            2: ("half", "halves"), 3: ("third", "thirds"), 4: ("fourth", "fourths"), 5: ("fifth", "fifths"), 6: ("sixth", "sixths"),
            7: ("seventh", "sevenths"), 8: ("eighth", "eighths"), 9: ("ninth", "ninths"), 10: ("tenth", "tenths"), 11: ("eleventh", "elevenths"),
            12: ("twelfth", "twelfths"), 13: ("thirteenth", "thirteenths"), 14: ("fourteenth", "fourteenths"), 15: ("fifteenth", "fifteenths"),
            16: ("sixteenth", "sixteenths"), 17: ("seventeenth", "seventeenths"), 18: ("eighteenth", "eighteenths"), 19: ("nineteenth", "nineteenths"),
            20: ("twentieth", "twentieths"), 100: ("hundredth", "hundredths"),
        ]
        if let n = names[d] { return plural ? n.1 : n.0 }
        let last = d % 10, teen = (11...13).contains(d % 100)
        let suffix = teen ? "th" : last == 1 ? "st" : last == 2 ? "nd" : last == 3 ? "rd" : "th"
        return "\(d)\(suffix)\(plural ? "s" : "")"
    }

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
        let W = Int(p["W"] ?? 0), d = Int(p["d"] ?? 2), all = W * d, last = wholeBeat(W - 1)
        let ask = LessonStep(StepWords(say: "What is \(W) ÷ 1/\(d)?", hint: "Look at the wholes. How many pieces fit?", action: "Let’s find out"),
                             picture: ["at": 0])
        // hints are the spec's narration (specs/k12/grade5.md §3); the tasks keep the web lesson's hints and slips
        let oneHint = "Look at one whole bar and count the pieces in it."
        let one = LessonStep(StepWords(say: "How many 1/\(count(d, "piece")) make 1 whole?", hint: "Cut one whole into \(pieceName(d)).", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(d)],
                               known: [(["x": Double(d - 1)], "Count the pieces, not the cut lines between them.")],
                               hint: oneHint, explain: "\(oneHint) That makes \(d)."),
            picture: ["at": 0, "ask": 1])
        let allHint = "\(count(W, "whole")), \(count(d, "piece")) in each."
        let wrongWay = (Double(W) / Double(d) * 1_000_000).rounded() / 1_000_000
        let every = LessonStep(StepWords(say: "Pieces in all.", hint: "Every whole holds \(d), so count them all.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(W)), .op("×"), .num(Double(d)), .op("="), .box("x")], expected: ["x": Double(all)],
                               known: [(["x": wrongWay], "The pieces are small, so lots of them fit. The answer is bigger than \(W).")],
                               hint: allHint, explain: "\(allHint) That makes \(all)."),
            picture: ["at": 1, "ask": Double(last)])
        let done = LessonStep(StepWords(say: "\(W) ÷ 1/\(d) = \(all).",
                                        hint: "Dividing by a unit fraction asks how many of those pieces fit.",
                                        action: "Next problem"),
                              picture: ["at": Double(last)])
        return [ask, one, every, done]
    }
}
