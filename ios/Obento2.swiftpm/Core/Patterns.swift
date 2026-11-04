import Foundation

/// Number and shape patterns (g4-patterns, 4.OA.5; new; design/grade4.md chapter 3, the preview
/// design/prototype/grade4-ch3.html). Two kinds of rule.
///
/// A number rule ("Start at 1. Add 3."): a number line one square a one, 0 to 60. Hop each step out from the last
/// number (it snaps a square at a time), five hops; tap the odd numbers (each is ringed); then say whether a far number
/// (the 10th to the 30th) is odd or even. Start 0–9, add 2–9, six numbers ending at 60 or less.
///
/// A shape rule (shapes 1–3 side by side, each with d more squares than the last, the new ones tinted): towers, L's
/// and steps, the first shape 1–5 squares, adding 1–4 (an L adds to both arms: 2 or 4, from 1, 3 or 5; a tower stays 11
/// tall by shape 4). Tap squares to build shape 4; drag out copies of the new squares in a row after shape 1's to reach
/// shape q (6–12); write its squares.
///
/// Index < 3: an odd add, a shape, an even add; then shape, odd, shape, even. Every step's picture has "at": numbers 0
/// the question, 1 hop, 2 tap the odd ones, 3 odd or even, 4 done; shapes 0 the question, 1 build, 2 copies, 3 write,
/// 4 done.
public enum Patterns {
    /// A number rule: kind 0 (an odd add) or 2 (an even add), start s, add d, ask about the k-th number.
    public static func number(s: Int, d: Int, k: Int) -> Numbers { ["kind": d % 2 == 1 ? 0 : 2, "s": Double(s), "d": Double(d), "k": Double(k)] }
    /// A shape rule: sk 0 a tower, 1 an L, 2 steps; the first shape f squares, adding d, ask about shape q.
    public static func shape(sk: Int, f: Int, d: Int, q: Int) -> Numbers { ["kind": 1, "sk": Double(sk), "f": Double(f), "d": Double(d), "q": Double(q)] }

    /// "1st", "2nd", "20th".
    public static func ord(_ k: Int) -> String {
        if (11...13).contains(k % 100) { return "\(k)th" }
        return "\(k)" + ([1: "st", 2: "nd", 3: "rd"][k % 10] ?? "th")
    }

    public struct Parts: Sendable {
        public let kind: Int, s: Int, d: Int, k: Int, sk: Int, f: Int, q: Int
        public init(_ x: Numbers) {
            func i(_ key: String, _ v: Int) -> Int { Int((x[key] ?? Double(v)).rounded()) }
            kind = i("kind", 0); s = i("s", 1); d = i("d", 3); k = i("k", 20); sk = i("sk", 0); f = i("f", 3); q = i("q", 10)
        }
        public var isShape: Bool { kind == 1 }

        // MARK: a number rule
        /// The six numbers: s, s + d, … s + 5d.
        public var vals: [Int] { (0..<6).map { s + $0 * d } }
        /// Which ones are tapped: the odd ones (the even ones when every number is even).
        public var target: Int { vals.contains { $0 % 2 == 1 } ? 1 : 0 }
        public var targetWord: String { target == 1 ? "odd" : "even" }
        public var want: [Int] { vals.filter { $0 % 2 == target } }
        /// The k-th number's oddness: 0 odd, 1 even (the choices' order).
        public var answer: Int { (s + (k - 1) * d) % 2 == 1 ? 0 : 1 }
        public var answerWord: String { answer == 0 ? "odd" : "even" }
        var sp: String { s % 2 == 1 ? "odd" : "even" }
        var other: String { s % 2 == 1 ? "even" : "odd" }
        /// What a hop let go at `len` says (nil: the rule's).
        public func hopped(_ len: Int) -> String? { len == d ? nil : "That hop is \(len). The rule adds \(d)." }
        /// What tapping v says when it isn't one to ring.
        public func tapped(_ v: Int) -> String {
            if target == 1 { return v == 0 ? "0 is even." : "\(v) is even: it’s \(v / 2) \(v == 2 ? "two" : "twos")." }
            return "\(v) is odd."
        }
        /// What a wrong odd or even says.
        public var notQuite: String {
            let A = sp.prefix(1).uppercased() + sp.dropFirst()
            return d % 2 == 1 ? "\(A), \(other), \(sp), \(other): it repeats every 2, so the \(ord(k)) is like the \(k % 2 == 1 ? "1st" : "2nd")."
                : "\(A), \(sp), \(sp): adding \(d) keeps \(sp) numbers \(sp)."
        }
        public var numberWhy: String { d % 2 == 1 ? "Adding \(d) turns odd into even and back." : "Adding \(d) keeps \(sp) numbers \(sp)." }

        // MARK: a shape rule
        /// Shape j's squares (j from 1).
        public func count(_ j: Int) -> Int { f + (j - 1) * d }
        public var n4: Int { count(4) }
        public var ans: Int { count(q) }
        /// What letting the copies go at shape `j` says (nil: shape q).
        public func copied(_ j: Int) -> String? {
            if j == q { return nil }
            let m = abs(q - j)
            return j < q ? "That’s shape \(j). \(m == 1 ? "One more copy." : "\(m) more copies.")" : "That’s shape \(j). \(m == 1 ? "One copy too many." : "\(m) copies too many.")"
        }
        public var shapeWhy: String { "\(q - 1) more shapes add \(q - 1) × \(d) to the first one." }

        /// Shape j's squares, (x, y) from its bottom-left going up, each with the shape that added it (0: shape 1's own).
        public func cells(_ j: Int) -> [(x: Int, y: Int, g: Int)] {
            var out: [(x: Int, y: Int, g: Int)] = []
            switch sk {
            case 0:
                for i in 0..<count(j) { out.append((0, i, i < f ? 0 : 1 + (i - f) / d)) }
            case 1:
                let m0 = (f - 1) / 2, A = m0 + (j - 1) * d / 2
                func g(_ i: Int) -> Int { i <= m0 ? 0 : 1 + (i - m0 - 1) / (d / 2) }
                out.append((0, 0, 0))
                if A > 0 { for i in 1...A { out.append((0, i, g(i))); out.append((i, 0, g(i))) } }
            default:
                for i in 0..<f { out.append((i, 0, 0)) }
                var end = f - 1
                if j > 1 { for r in 1..<j { for i in 0..<d { out.append((end + i, r, r)) }; end += d - 1 } }
            }
            return out
        }
        /// A shape's width and height in squares.
        public func size(_ j: Int) -> (w: Int, h: Int) {
            let c = cells(j)
            return ((c.map(\.x).max() ?? 0) + 1, (c.map(\.y).max() ?? 0) + 1)
        }
    }

    /// The preview's generator.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let kind = index < 3 ? [0, 1, 2][index] : [1, 0, 1, 2][(index - 3) % 4]
        if kind == 1 {
            while true {
                let sk = Int.random(in: 0...2, using: &rng)
                let (f, d) = sk == 1 ? ([1, 3, 5][Int.random(in: 0...2, using: &rng)], [2, 4][Int.random(in: 0...1, using: &rng)])
                    : (Int.random(in: 1...5, using: &rng), Int.random(in: 1...4, using: &rng))
                if sk == 0 && f + 3 * d > 11 { continue }
                return shape(sk: sk, f: f, d: d, q: Int.random(in: 6...12, using: &rng))
            }
        }
        while true {
            let s = Int.random(in: 0...9, using: &rng), d = kind == 0 ? [3, 5, 7, 9][Int.random(in: 0...3, using: &rng)] : [2, 4, 6, 8][Int.random(in: 0...3, using: &rng)]
            if s + 5 * d <= 60 { return number(s: s, d: d, k: Int.random(in: 10...30, using: &rng)) }
        }
    }

    public static let spec = LessonSpec(id: "g4-patterns", title: "Number and shape patterns", master: "squares",
        generate: { rng, index in make(&rng, index) },
        display: { x in
            let p = Parts(x)
            return p.isShape ? [.text("shape \(p.q)")] : [.text("start at \(p.s), add \(p.d)")]
        },
        idea: { x in Parts(x).isShape ? "Each shape adds the same squares, so the far shape is the first one and that many copies." : "A rule adds the same each time: watch what repeats." },
        depends: ["g3-facts"],
        check: [CheckItem(0), CheckItem(2), CheckItem(1), CheckItem(3)]) { x in
        let p = Parts(x)
        return p.isShape ? shapeSteps(p) : numberSteps(p)
    }

    static func numberSteps(_ p: Parts) -> [LessonStep] {
        let s = p.s, d = p.d, rule = "Start at \(s). Add \(d)."
        var steps = [LessonStep(StepWords(say: rule, hint: "Each hop adds \(d).", action: "Let’s find out"), picture: ["at": 0])]
        // five hops: the box is a hop's length, set when one is let go wrong or when the fifth lands
        steps.append(LessonStep(StepWords(say: "\(rule) Drag each hop out from the last number.", hint: "Each hop is \(d) squares.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(d)], hint: "Each hop is \(d) squares.",
                               explain: p.vals.map(String.init).joined(separator: ", "),
                               check: { v in
                                   guard let len = v["x"] else { return .soft("Drag each hop out from the last number.") }
                                   return p.hopped(Int(len.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        // tap the odd ones: the box is 1 once they're all ringed, or 1000 + a number tapped that isn't one
        let thint = p.target == 1 ? "Odd numbers end in 1, 3, 5, 7 or 9." : "Even numbers end in 0, 2, 4, 6 or 8."
        steps.append(LessonStep(StepWords(say: "Tap the \(p.targetWord) numbers.", hint: thint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: thint,
                               explain: p.want.map(String.init).joined(separator: ", "),
                               check: { v in
                                   let x = Int((v["x"] ?? 0).rounded())
                                   if x == 1 { return .right }
                                   return x >= 1000 ? .wrong(p.tapped(x - 1000)) : .soft("Tap the \(p.targetWord) numbers.")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        // odd or even, tapped: the box is the choice (0 Odd, 1 Even)
        let want = Double(p.answer), ask = "Will the \(ord(p.k)) number be odd or even?"
        let chint = d % 2 == 1 ? "Odd, even, odd, even: it repeats every 2." : "Adding \(d) keeps the start’s oddness."
        steps.append(LessonStep(StepWords(say: "\(ask) Tap one.", hint: chint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": want], hint: chint, explain: "The \(ord(p.k)) number is \(p.answerWord).",
                               check: { v in
                                   guard let c = v["c"] else { return .soft("Tap Odd or Even.") }
                                   return c == want ? .right : .wrong(p.notQuite)
                               }, byHand: true),
            picture: ["at": 3]))
        steps.append(LessonStep(StepWords(say: p.numberWhy, hint: "A rule adds the same each time: watch what repeats.", action: "Next problem"), picture: ["at": 4]))
        return steps
    }

    static func shapeSteps(_ p: Parts) -> [LessonStep] {
        let d = p.d, q = p.q, f = p.f, ans = p.ans
        let more = "Each shape has \(d) more than the last."
        var steps = [LessonStep(StepWords(say: "Build shape 4.", hint: more, action: "Let’s find out"), picture: ["at": 0])]
        // build shape 4: the box is how many squares it has when Check is pressed
        steps.append(LessonStep(StepWords(say: "Build shape 4. Tap squares to add them. \(more)", hint: more, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(p.n4)], hint: more, explain: "Shape 4 has \(p.n4) squares.",
                               check: { v in
                                   guard let c = v["x"] else { return .soft("Tap squares to add them.") }
                                   return Int(c.rounded()) == p.n4 ? .right : .wrong("Shape 4 has \(d) more than shape 3: \(p.n4).")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        // drag out copies: the box is the shape the row was let go at
        steps.append(LessonStep(StepWords(say: "How many squares will shape \(q) have? Drag out copies of the new squares.", hint: "Shape \(q) has \(q - 1) copies after shape 1.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(q)], hint: "Shape \(q) has \(q - 1) copies after shape 1.",
                               explain: "Shape \(q): \(f) + \(q - 1) × \(d) = \(ans).",
                               check: { v in
                                   guard let j = v["x"] else { return .soft("Drag out copies of the new squares.") }
                                   return p.copied(Int(j.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        // write it, with the preview's slips
        let slips = BigNumbers.slips(Double(ans), [(Double(q * d), "\(q) × \(d) forgets that shape 1 starts with \(f)."),
                                                   (Double(ans - d), "\(ans - d) is shape \(q - 1). Shape \(q) has one more copy."),
                                                   (Double(ans + d), "\(ans + d) is shape \(q + 1). Shape \(q) has one copy fewer.")])
        steps.append(LessonStep(StepWords(say: "Write how many squares shape \(q) has.", hint: "\(f), and \(q - 1) copies of \(d).", action: "Check"),
            answer: AnswerTask(prompt: [.text("shape"), .num(Double(q)), .op("="), .box("x"), .text("squares")], expected: ["x": Double(ans)], known: slips,
                               hint: "\(f), and \(q - 1) copies of \(d).", explain: "\(f) + \(q - 1) × \(d) = \(ans).",
                               check: { v in Int((v["x"] ?? -1).rounded()) == ans ? .right : .wrong("Count the row: \(f), and \(q - 1) copies of \(d).") },
                               incomplete: "Type the number in the box."),
            picture: ["at": 3]))
        steps.append(LessonStep(StepWords(say: p.shapeWhy, hint: "Each shape adds the same squares, so the far shape is the first one and that many copies.",
                                          action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}
