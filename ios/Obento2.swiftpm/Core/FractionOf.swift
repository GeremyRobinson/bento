import Foundation

/// Fraction of a number (the web app's g5-fracof): n/d of W. Split W into d equal groups, take n of them.
/// Numbers: n (top, in lowest terms with d), d (bottom, 2 to 9) and W (a whole number of d's, 2 to 12 groups).
///
/// Picture (master "tape", the web's `fractionOfNumberPicture`): one bar labelled W.
/// - beat 0: the whole bar, uncut, labelled W.
/// - beat 1: the bar cut into d equal groups, each labelled W/d (the bar is lit from here on).
/// - beat 2: n groups shaded, a bracket "n/d" below them, and the total "n × W/d = answer" beside the bar.
/// Keys, as the web's practice screen places the picture (`pictureAt`):
/// - "at": the beat shown with its results (everything up to and including it).
/// - "ask": the beat being asked about now, lit without its answer (absent when nothing is asked).
public enum FractionOf {
    public static func numbers(n: Int, d: Int, W: Int) -> Numbers { ["n": Double(n), "d": Double(d), "W": Double(W)] }

    /// "1 group", "3 groups".
    static func count(_ k: Int, _ one: String) -> String { "\(k) \(k == 1 ? one : one + "s")" }

    /// A top below d that shares no factor with it (the web's coprimeTop).
    static func coprimeTop(_ d: Int, using rng: inout SeededRandom) -> Int {
        var n: Int
        repeat { n = Int.random(in: 1...(d - 1), using: &rng) } while gcd(n, d) != 1
        return n
    }

    public static let spec = LessonSpec(id: "g5-fracof", title: "Fraction of a number", master: "tape", generate: { rng, index in
        // the first three: one group (a unit fraction) of a small number
        if index < 3 {
            let d = Int.random(in: 2...5, using: &rng)
            return numbers(n: 1, d: d, W: d * Int.random(in: 2...6, using: &rng))
        }
        let d = Int.random(in: 2...9, using: &rng), n = coprimeTop(d, using: &rng)
        return numbers(n: n, d: d, W: d * Int.random(in: 2...12, using: &rng))
    }, display: { p in [.frac(.num(p["n"] ?? 1), .num(p["d"] ?? 2)), .text("of"), .num(p["W"] ?? 0)] },
    idea: { _ in "The bottom says how many equal groups to make, and the top says how many to take." },
    story: { p in "There are \(fmt(p["W"] ?? 0)) marbles in a bag. \(fmt(p["n"] ?? 1))/\(fmt(p["d"] ?? 2)) of them are blue. How many marbles are blue?" },
    storyOp: { _ in "×" },
    depends: ["g3-divfacts", "g4-fracwhole"],
    check: [CheckItem(3, when: { ($0["n"] ?? 0) > 1 }), CheckItem(3, when: { ($0["n"] ?? 0) > 1 }), CheckItem(3), CheckItem(3, story: true)]) { p in
        let n = Int(p["n"] ?? 1), d = Int(p["d"] ?? 2), W = Int(p["W"] ?? 0), g = W / d, R = g * n
        let F = "\(n)/\(d)"
        let ask = LessonStep(StepWords(say: "What is \(F) of \(W)?", hint: "Look at the bar of \(W). How can we split it?", action: "Let’s find out"),
                             picture: ["at": 0])
        // hints are the spec's narration (specs/k12/grade5.md §3); the tasks keep the web lesson's hints and slips
        let groupsHint = "The bottom number tells how many equal groups: \(d)."
        let groups = LessonStep(StepWords(say: "Split into equal groups.", hint: "The bottom says \(d) equal groups.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(W)), .op("÷"), .num(Double(d)), .op("="), .box("x")], expected: ["x": Double(g)],
                               known: [(["x": Double(W * d)], "Split \(W) into \(d) equal groups: divide.")],
                               hint: groupsHint, explain: "\(groupsHint) That makes \(g)."),
            picture: ["at": 0, "ask": 1])
        let takeHint = "The top number tells how many groups to take: \(n)."
        let take = LessonStep(StepWords(say: "Take that many groups.", hint: "The top says take \(n) of them.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(g)), .op("×"), .num(Double(n)), .op("="), .box("x")], expected: ["x": Double(R)],
                               known: [(["x": Double(g + n)], "Take \(count(n, "group")) of \(g): that’s multiplying."),
                                       (["x": Double(W - R)], "That’s the groups left over. The top says to take \(count(n, "group")).")],
                               hint: takeHint, explain: "\(takeHint) That makes \(R)."),
            picture: ["at": 1, "ask": 2])
        let done = LessonStep(StepWords(say: "\(F) of \(W) is \(R).",
                                        hint: "The bottom says how many equal groups to make, and the top says how many to take.",
                                        action: "Next problem"),
                              picture: ["at": 2])
        return [ask, groups, take, done]
    }
}
