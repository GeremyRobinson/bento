import Foundation

/// Fractions as division (5.NF.3, design/grade5.md "Added 1 Nov 2026"; the preview G approved on 1 Nov 2026 is
/// design/prototype/new5-lessons.html, dFracDiv). a things shared equally by b friends: each gets a/b of one.
///
/// Numbers: a (2 to 4 things), b (2, 3, 4, 5, 6 or 8 friends, never a; more things than friends one time in three) and
/// t, which thing (sandwiches, ribbons, granola bars, subs).
///
/// On the paper (the fractions family): each thing is a bar a whole long (48 squares, 40 for fifths). 1. The ruler cuts
/// every bar so each friend gets a piece ("6 pieces" while it's dragged); Cut sets the cut's box to how many pieces a
/// bar makes. 2. The child taps one friend's share (one piece from every bar); Check sets the share's box to how many
/// are shaded. 3. The share slides together into one bar under a rule ("one share"; a second bar when it's more than
/// a whole), and the record a ÷ b = [ ]/[ ] is written, both typed. The last words say why.
///
/// Picture keys, by step (cumulative): "ruler" (the cut: the ruler over the bars); "cut" (every bar cut into b pieces);
/// "share" (pieces are tapped to shade them); "slid" (the share slid together, the record's boxes); "done" (the answer
/// written). A miss on the share lights "ring" (a piece of every bar ringed: one from each).
public enum FractionsAsDivision {
    public static func numbers(a: Int, b: Int, t: Int) -> Numbers { ["a": Double(a), "b": Double(b), "t": Double(t)] }

    /// The things shared, one and many.
    public static let things: [(one: String, many: String)] = [("sandwich", "sandwiches"), ("ribbon", "ribbons"), ("granola bar", "granola bars"), ("sub", "subs")]
    /// The friends a problem can have.
    public static let friends = [2, 3, 4, 5, 6, 8]

    /// The worked parts of a problem.
    public struct Parts: Sendable {
        public let a, b, t: Int
        public init(_ n: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((n[k] ?? Double(v)).rounded()) }
            a = min(4, max(1, i("a", 3))); b = min(12, max(2, i("b", 6))); t = min(things.count - 1, max(0, i("t", 0)))
        }
        public var one: String { things[t].one }
        /// "3 subs", "1 sub".
        public var named: String { "\(a) \(a == 1 ? things[t].one : things[t].many)" }
        /// A whole bar's length in squares: 48, or 40 for fifths.
        public var W: Int { b == 5 ? 40 : 48 }
        /// One piece's length in squares.
        public var pw: Int { W / b }
        /// The bars one share fills: 1, or 2 when it's more than a whole (4 ÷ 3).
        public var shareBars: Int { (a + b - 1) / b }
    }

    /// What a cut into `x` pieces a bar says: right at b, otherwise how many it made.
    static func cutVerdict(_ x: Double?, b: Int) -> Verdict {
        guard let x, x > 0 else { return .soft("Drag down across the bars to cut them.") }
        if abs(x - Double(b)) < 1e-9 { return .right }
        guard x == x.rounded() else { return .wrong("The pieces must fill the whole bar.") }
        return .wrong("That’s \(Int(x)) pieces in each. There are \(b) friends.")
    }

    /// What shading `n` pieces for one friend says: right at a, otherwise what that many for every friend would take.
    static func shareVerdict(_ n: Double?, a: Int, b: Int) -> Verdict {
        guard let n else { return .soft("Tap the pieces.") }
        let k = Int(n.rounded())
        if k == a { return .right }
        if k < a { return .wrong("If each friend gets \(k), \(b) friends take \(k * b). \(a * b - k * b) are left over.") }
        return .wrong("If each friend gets \(k), \(b) friends need \(k * b). There are only \(a * b).")
    }

    public static let spec = LessonSpec(id: "g5-fracdiv", title: "Fractions as division", master: "bars", generate: { rng, _ in
        let t = Int.random(in: 0..<things.count, using: &rng)
        var a = 2, b = 2
        // more things than friends only one time in three
        repeat { b = friends[Int.random(in: 0..<friends.count, using: &rng)]; a = Int.random(in: 2...4, using: &rng) }
        while a == b || (a > b && Int.random(in: 0...2, using: &rng) != 0)
        return numbers(a: a, b: b, t: t)
    }, display: { n in let p = Parts(n); return [.num(Double(p.a)), .op("÷"), .num(Double(p.b))] },
    idea: { n in let p = Parts(n); return "Sharing \(p.a) by \(p.b) is \(p.a) ÷ \(p.b), and each share is \(p.a)/\(p.b)." },
    depends: ["g3-unitfrac", "g3-divfacts"],
    check: [CheckItem(3, when: { let p = Parts($0); return p.a < p.b }), CheckItem(3, when: { let p = Parts($0); return p.a > p.b }),
            CheckItem(3), CheckItem(3)]) { n in
        let p = Parts(n), a = p.a, b = p.b, one = p.one
        let problem = "\(p.named), shared equally by \(b) friends."

        // the problem is written once, as the bars' own name and the record's a ÷ b
        let ask = LessonStep(StepWords(say: problem, hint: "Every friend gets the same.", action: "Let’s find out"))

        // the cut: the ruler cuts every bar into one piece per friend; its box is how many pieces a bar makes
        let cut = LessonStep(
            StepWords(say: "\(problem) Cut every one so each friend gets a piece. Drag the ruler, then cut.",
                      hint: "\(b) friends, so \(b) pieces in each.", action: "Cut"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(b)],
                               hint: "\(b) friends, so \(b) pieces in each.", explain: "\(b) friends, so \(b) pieces in each.",
                               check: { v in cutVerdict(v["x"], b: b) }, byHand: true),
            picture: ["ruler": 1])

        // the share: one friend's pieces tapped, then Check
        let share = LessonStep(
            StepWords(say: "Shade one friend’s share. Tap the pieces. Every friend gets the same.",
                      hint: "Every \(one) gives each friend one piece.", action: "Check"),
            answer: AnswerTask(prompt: [.box("n")], expected: ["n": Double(a)],
                               hint: "Every \(one) gives each friend one piece.", explain: "One piece from every \(one): \(a) pieces.",
                               check: { v in shareVerdict(v["n"], a: a, b: b) }, byHand: true),
            picture: ["cut": 1, "share": 1], onMiss: ["ring": 1])

        // the record: a ÷ b = [a]/[b], both typed
        let upside = "Upside down: the top is how many pieces, the bottom is what size."
        let write = LessonStep(
            StepWords(say: "How much is one share? Write it as a fraction of one \(one).", hint: "\(a) pieces, each 1/\(b) of a \(one).", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(a)), .op("÷"), .num(Double(b)), .op("="), .frac(.box("t"), .box("b"))],
                               expected: ["t": Double(a), "b": Double(b)],
                               known: a == b ? [] : [(["t": Double(b), "b": Double(a)], upside)],
                               hint: "\(a) pieces, each 1/\(b) of a \(one).", explain: "\(a) pieces, each 1/\(b): \(a)/\(b).",
                               check: { v in
                                   guard let t = v["t"], let d = v["b"] else { return .soft("Fill in both boxes.") }
                                   if t == Double(a) && d == Double(b) { return .right }
                                   if t == Double(b) && d == Double(a) { return .wrong(upside) }
                                   if d != 0, t * Double(b) == d * Double(a) { return .wrong("Same amount. Write it in \(UnlikeFractions.pieceName(b)), the pieces you cut.") }
                                   return .wrong("Count the pieces in one share. Each is 1/\(b).")
                               }),
            picture: ["cut": 1, "slid": 1])

        // the answer is in the record; the last words say why
        let done = LessonStep(StepWords(say: "Each friend gets \(a)/\(b) of a \(one). Every \(one) gives each friend 1/\(b), and there are \(a) of them.",
                                        hint: "Sharing \(a) by \(b) is \(a) ÷ \(b), and each share is \(a)/\(b).", action: "Next problem"),
                              picture: ["cut": 1, "slid": 1, "done": 1])
        return [ask, cut, share, write, done]
    }
}
