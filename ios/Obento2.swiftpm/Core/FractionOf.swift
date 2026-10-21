import Foundation

/// Fraction of a number (the web app's g5-fracof): n/d of W. Split W into d equal groups, take n of them.
/// Numbers: n (top, in lowest terms with d), d (bottom, 2 to 9) and W (a whole number of d's, 2 to 12 groups); the first
/// three of a run are one group (a unit fraction) of a small number: the web's ranges and easy-first order.
///
/// On the paper (design/grade5.md, the fractions family): one square (2 × 2 when there are 30 or fewer) is one thing, so
/// the bar holds W things, named "n/d of W" at its right end: the problem, written once as the picture's own names.
/// 1. The ruler cuts the bar into equal groups, snapping only to group sizes that divide W ("fourths, 5 in each"); Cut
///    sets the cut's box to how many groups it makes (the web's "groups" step, set by the move), and a cut that isn't d
///    groups says how many it made. 2. The child taps n groups to take them; Take sets the take's box to how many are
///    tapped (dropped when n is 1: the one group is taken with the cut). 3. The record n/d of W = W ÷ d × n = [ ] is
///    written, the answer typed (× n left out when n is 1). The web's slips are kept on the record: multiplied instead of
///    divided (W × d, times n), added (g + n), and the groups left over (W − g·n). The last words say why.
///
/// Picture keys, by step (cumulative): "ruler" (the cut: the ruler over the bar); "cut" (the bar cut into d groups,
/// each group's count under it); "tap" (the take: groups tapped are taken); "taken" (the first n groups shaded and
/// bracketed n/d, the record written); "done" (the answer written). A hint after a miss lights "ring" (the taken groups'
/// counts ringed).
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

    /// The group sizes the ruler snaps to: every whole number of things that divides W, so the bar is cut into 2 or more
    /// equal groups.
    public static func groupSizes(_ W: Int) -> [Int] { W < 2 ? [] : (1...(W / 2)).filter { W % $0 == 0 } }

    /// The ruler's readout for groups of `each` things: the groups' name and what's in each ("fourths, 5 in each").
    public static func readout(W: Int, each: Int) -> String { "\(UnlikeFractions.pieceName(W / max(1, each))), \(each) in each" }

    /// What a cut into `x` equal groups says: right at d, otherwise how many it made.
    static func cutVerdict(_ x: Double?, d: Int) -> Verdict {
        guard let x, x > 0 else { return .soft("Drag the ruler first.") }
        if abs(x - Double(d)) < 1e-9 { return .right }
        guard x == x.rounded() else { return .wrong("Cut it into \(d) equal groups.") }
        return .wrong("That makes \(count(Int(x), "group")). The bottom says \(d).")
    }

    /// What taking `t` groups says: right at n, otherwise how many were taken.
    static func takeVerdict(_ t: Double?, n: Int) -> Verdict {
        guard let t, t > 0 else { return .soft("Tap a group to take it.") }
        if abs(t - Double(n)) < 1e-9 { return .right }
        return .wrong("That’s \(count(Int(t.rounded()), "group")). The top says take \(n).")
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
        let n = max(1, Int(p["n"] ?? 1)), d = max(2, Int(p["d"] ?? 2)), W = max(d, Int(p["W"] ?? 0)), g = W / d, R = g * n

        // the problem is written once, as the picture's own names (G 20 Oct): the first words point at the squares
        let ask = LessonStep(StepWords(say: "Each square is one thing. How many of them is that?",
                                       hint: "Look at the bar of \(W). How can we split it?", action: "Let’s find out"))

        // the cut: the ruler cuts the bar into equal groups; its box is how many groups (the web's "groups"). Hints are the
        // spec's narration (specs/k12/grade5.md §3), the task's the web lesson's
        let groupsHint = "The bottom number tells how many equal groups: \(d)."
        let cut = LessonStep(
            StepWords(say: "Drag the ruler to make \(d) equal groups, then cut.", hint: "The bottom says \(d) equal groups.", action: "Cut"),
            answer: AnswerTask(prompt: [.num(Double(W)), .op("÷"), .box("x"), .op("="), .num(Double(g))], expected: ["x": Double(d)],
                               hint: groupsHint, explain: "\(groupsHint) That makes \(g) in each.",
                               check: { v in cutVerdict(v["x"], d: d) }, byHand: true),
            picture: ["ruler": 1])

        // the take: n groups tapped, then Take (dropped when n is 1: the one group is the answer)
        let takeHint = "The top number tells how many groups to take: \(n)."
        let take = LessonStep(
            StepWords(say: "Tap \(n) groups to take them.", hint: "The top says take \(n) of them.", action: "Take"),
            answer: AnswerTask(prompt: [.frac(.box("t"), .num(Double(d)))], expected: ["t": Double(n)],
                               hint: takeHint, explain: takeHint,
                               check: { v in takeVerdict(v["t"], n: n) }, byHand: true),
            picture: ["cut": 1, "tap": 1])

        // the record, as school writes it: n/d of W = W ÷ d × n = [R], the answer typed. The web's slips, never the answer
        var known: [(values: [String: Double], message: String)] = []
        for (v, m) in [(W * d * n, "Split \(W) into \(d) equal groups: divide."),
                       (g + n, "Take \(count(n, "group")) of \(g): that’s multiplying."),
                       (W - R, "That’s the groups left over. The top says to take \(count(n, "group")).")]
        where v != R && !known.contains(where: { $0.values["x"] == Double(v) }) { known.append((["x": Double(v)], m)) }
        let allHint = n == 1 ? "One group of \(g)." : "\(n) groups of \(g)."
        let times: MathLine = n == 1 ? [] : [.op("×"), .num(Double(n))]
        let write = LessonStep(
            StepWords(say: n == 1 ? "How many in one group? Write it." : "How many are taken? Write it.",
                      hint: allHint, action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(n)), .num(Double(d))), .text("of"), .num(Double(W)), .op("="),
                                        .num(Double(W)), .op("÷"), .num(Double(d))] + times + [.op("="), .box("x")],
                               expected: ["x": Double(R)], known: known, hint: allHint, explain: "\(allHint) That makes \(R)."),
            picture: ["cut": 1, "taken": 1], onMiss: ["ring": 1])

        // the answer is in the record; the last words say why
        let done = LessonStep(StepWords(say: "The bottom made \(d) equal groups. The top took \(n).",
                                        hint: "The bottom says how many equal groups to make, and the top says how many to take.",
                                        action: "Next problem"),
                              picture: ["cut": 1, "taken": 1, "done": 1])
        return n == 1 ? [ask, cut, write, done] : [ask, cut, take, write, done]
    }
}
