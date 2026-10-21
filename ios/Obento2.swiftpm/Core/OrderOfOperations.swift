import Foundation

/// Order of operations (the web app's g5-order), in three shapes that take turns:
/// t = 0: a + b × (c − d),  t = 1: (a + b) × c − d,  t = 2: a × b − c ÷ d.
/// Numbers: t (the shape), a, b, c, d.
///
/// On the paper (design/grade5.md): the expression written once, big, as the record's first line, rewritten line under
/// line as school does it (`= 3 + 4 × 4`, `= 3 + 16`, `= 19`). The child taps the part that goes first in the line (its
/// box is set from the tap: the part's sign, counted from the left), its squares build under the record (one square is
/// one: a number is a row of squares, × makes rows, − crosses out, ÷ deals into rows), and its value is typed in the
/// next line where school writes it. Then the part that goes next is tapped and written; the last part is the only one
/// left, so it isn't tapped, only written. The last words say why.
/// Picture key "at", the stage: 0 the question, 1 the first part to tap, 2 its value to write, 3 the next part to tap,
/// 4 its value to write, 5 the last value to write, 6 done.
public enum OrderOfOperations {
    public static func numbers(t: Int, a: Int, b: Int, c: Int, d: Int) -> Numbers {
        ["t": Double(t), "a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d)]
    }

    private static let leftToRightWords = "Parentheses go first, then × and ÷, then + and −. Left to right is only for signs of the same kind."

    /// A piece of a line as written: a number, a sign, or a parenthesis.
    public enum Token: Equatable, Sendable {
        case n(Int), op(String), open, close
        public var math: Math {
            switch self { case .n(let v): .num(Double(v)); case .op(let o): .op(o); case .open: .text("("); case .close: .text(")") }
        }
    }

    /// The working as school writes it: four lines (the expression, then each rewritten with one part worked out, then
    /// the answer), the part worked on each of the first three lines (its tokens; its value takes their place in the
    /// next line), the values, and which sign goes first and next (counted from the left in lines 0 and 1).
    public struct Working: Sendable {
        public let lines: [[Token]]
        public let worked: [Range<Int>]
        public let values: [Int]
        public let first: Int, next: Int
        /// The tokens a sign's part spans in a line: the numbers either side of it (a parenthesis's whole group).
        public static func span(_ line: [Token], sign j: Int) -> Range<Int> {
            var lo = j - 1, hi = j + 1
            if lo >= 0, line[lo] == .close { while lo > 0, line[lo] != .open { lo -= 1 } }
            if hi < line.count, line[hi] == .open { while hi < line.count - 1, line[hi] != .close { hi += 1 } }
            return max(0, lo)..<min(line.count, hi + 1)
        }
        /// The sign tokens of a line, left to right.
        public static func signs(_ line: [Token]) -> [Int] { line.indices.filter { if case .op = line[$0] { true } else { false } } }
    }

    public static func working(_ n: Numbers) -> Working {
        let (t, a, b, c, d) = ints(n)
        let N = Token.n
        switch t {
        case 1:
            let r0 = a + b, r1 = r0 * c, r2 = r1 - d
            return Working(lines: [[.open, N(a), .op("+"), N(b), .close, .op("×"), N(c), .op("−"), N(d)], [N(r0), .op("×"), N(c), .op("−"), N(d)], [N(r1), .op("−"), N(d)], [N(r2)]],
                           worked: [0..<5, 0..<3, 0..<3], values: [r0, r1, r2], first: 0, next: 0)
        case 2:
            let r0 = a * b, r1 = c / max(1, d), r2 = r0 - r1
            return Working(lines: [[N(a), .op("×"), N(b), .op("−"), N(c), .op("÷"), N(d)], [N(r0), .op("−"), N(c), .op("÷"), N(d)], [N(r0), .op("−"), N(r1)], [N(r2)]],
                           worked: [0..<3, 2..<5, 0..<3], values: [r0, r1, r2], first: 0, next: 1)
        default:
            let r0 = c - d, r1 = b * r0, r2 = a + r1
            return Working(lines: [[N(a), .op("+"), N(b), .op("×"), .open, N(c), .op("−"), N(d), .close], [N(a), .op("+"), N(b), .op("×"), N(r0)], [N(a), .op("+"), N(r1)], [N(r2)]],
                           worked: [4..<9, 2..<5, 0..<3], values: [r0, r1, r2], first: 2, next: 1)
        }
    }

    /// The expression as written.
    public static func expression(t: Int, a: Int, b: Int, c: Int, d: Int) -> MathLine {
        working(numbers(t: t, a: a, b: b, c: c, d: d)).lines[0].map(\.math)
    }
    /// The answer, worked in the right order.
    public static func value(t: Int, a: Int, b: Int, c: Int, d: Int) -> Int {
        t == 1 ? (a + b) * c - d : t == 2 ? a * b - c / d : a + b * (c - d)
    }
    private static func ints(_ n: Numbers) -> (t: Int, a: Int, b: Int, c: Int, d: Int) {
        (Int(n["t"] ?? 0), Int(n["a"] ?? 0), Int(n["b"] ?? 0), Int(n["c"] ?? 0), Int(n["d"] ?? 0))
    }

    public static let spec = LessonSpec(id: "g5-order", title: "Order of operations", master: "order", generate: { rng, i in
        if i < 3 {
            // a + b × (c − d) with small numbers first, so the order is what's hard, not the arithmetic
            while true {
                let c = Int.random(in: 5...9, using: &rng), d = Int.random(in: (c - 2)...(c - 1), using: &rng)
                let a = Int.random(in: 2...5, using: &rng), b = Int.random(in: 2...4, using: &rng)
                if a + b * (c - d) <= 9 { return numbers(t: 0, a: a, b: b, c: c, d: d) }
            }
        }
        let t = i % 3
        if t == 2 {
            let d = Int.random(in: 2...6, using: &rng), a = Int.random(in: 3...9, using: &rng), b = Int.random(in: 3...9, using: &rng)
            return numbers(t: t, a: a, b: b, c: d * Int.random(in: 1...min(9, (a * b) / d), using: &rng), d: d)
        }
        let c = Int.random(in: 5...12, using: &rng)
        let a = Int.random(in: 2...9, using: &rng), b = Int.random(in: 2...9, using: &rng)
        return numbers(t: t, a: a, b: b, c: c, d: Int.random(in: 1...(c - 1), using: &rng))
    }, display: { n in let p = ints(n); return expression(t: p.t, a: p.a, b: p.b, c: p.c, d: p.d) + [.op("="), .text("?")] },
    idea: { _ in "Everyone uses the same order, so a problem has only one answer." },
    depends: ["g3-facts", "g3-divfacts"],
    check: [CheckItem(3, when: { $0["t"] == 0 }), CheckItem(4, when: { $0["t"] == 1 }), CheckItem(5, when: { $0["t"] == 2 }), CheckItem(6, when: { $0["t"] == 0 })]) { n in
        let (t, a, b, c, d) = ints(n)
        let r2 = value(t: t, a: a, b: b, c: c, d: d)

        let w = working(n)
        // the line a value is written in: the line before it with its worked part replaced by the box
        func line(_ i: Int) -> MathLine {
            var m = w.lines[i - 1].map(\.math)
            m.replaceSubrange(w.worked[i - 1], with: [.box("x")])
            return [.op("=")] + m
        }

        // the expression is written once, in the record: the first words ask about it, never say it again
        let ask = LessonStep(StepWords(say: "What does it make?", hint: "Look at the signs and the parentheses.", action: "Let’s find out"),
                             picture: ["at": 0])

        // the part that goes first, tapped in the line: its box is the sign's place from the left (the web's slips by part;
        // a part the web didn't offer gets its own plain words)
        let (ans, wrong): (Int, [Int: String]) = t == 1
            ? (0, [1: "The parentheses go first: \(a) + \(b).", 2: "The parentheses go first: \(a) + \(b). Then × comes before −."])
            : t == 2
            ? (0, [1: "× and ÷ come before −, so the − waits.", 2: "× and ÷ are the same kind, so go left to right: × first."])
            : (2, [0: leftToRightWords, 1: "The parentheses make \(c) − \(d) one number, so it comes even before ×."])
        let firstHint = t == 2 ? "There are no parentheses here. Which comes first, × or −?" : "Look for parentheses: they say \"do me first\"."
        let firstPart = t == 1 ? "\(a) + \(b)" : t == 2 ? "\(a) × \(b)" : "\(c) − \(d)"
        let firstExplain = t == 2 ? "× comes before −, so \(a) × \(b) goes first." : "The parentheses go first: \(firstPart)."
        let first = LessonStep(StepWords(say: "Tap the part that goes first.",
                                         hint: t == 2 ? "No parentheses, and × comes before −." : "Find the parentheses: they go first.", action: "Check"),
            answer: AnswerTask(prompt: [.text("first:"), .box("c")], expected: ["c": Double(ans)],
                               known: wrong.keys.sorted().map { (["c": Double($0)], wrong[$0]!) },
                               hint: firstHint, explain: firstExplain, byHand: true),
            picture: ["at": 1])

        // the slip the web's card warns about, worked out for this problem
        let leftToRight: Double? = t == 1 ? nil : t == 2 ? Double(a * b - c) / Double(d) : Double((a + b) * (c - d))
        let wrongWay = leftToRight.map { $0 == $0.rounded() && Int($0) != r2 ? " Left to right would give \(fmt($0)), which is wrong." : "" } ?? ""

        /// A value written in the next line: what to do, the web's words for it, its hint, explanation and slip.
        typealias Box = (say: String, words: String, ans: Int, hint: String, explain: String?, slip: Double, message: String)
        let boxes: [Box] = t == 1 ? [
            ("Write what the parentheses make.", "Work out the inside of the parentheses.", a + b,
             "The parentheses make \(a) + \(b) one number. What is it?", "Inside the parentheses: \(a) + \(b) = \(a + b).", Double(a * b), "Inside the parentheses it's +: \(a) + \(b)."),
            ("Write what the × makes.", "Multiply before subtracting.", (a + b) * c,
             "Multiplication comes before subtraction.", nil, Double((a + b) * (c - d)), "Multiply before you subtract: \(a + b) × \(c)."),
            ("Subtract last, and write the answer.", "Subtract last.", (a + b) * c - d,
             "The multiplying is done, so take \(d) away.", "\((a + b) * c) − \(d) = \((a + b) * c - d).", Double((a + b) * c + d), "The sign is −, so take \(d) away."),
        ] : t == 2 ? [
            ("Write what the × makes.", "Multiply first.", a * b,
             "× and ÷ come before −.", nil, Double(a + b), "That's \(a) + \(b). The sign is ×."),
            ("Write what the ÷ makes.", "Divide next, still before subtracting.", c / d,
             "× and ÷ come before −, so divide before you subtract.", nil, Double(c * d), "The sign is ÷: how many \(d)s make \(c)?"),
            // its slip, (a × b − c) ÷ d, need not be whole: kept as the web's exact number
            ("Subtract last, and write the answer.", "Subtract last.\(wrongWay)", a * b - c / d,
             "The × and ÷ are done, so take \(c / d) away from \(a * b).", "\(a * b) − \(c / d) = \(a * b - c / d).", Double(a * b - c) / Double(d), "Divide \(c) ÷ \(d) first, then subtract it from \(a * b)."),
        ] : [
            ("Write what the parentheses make.", "Work out the inside of the parentheses.", c - d,
             "The parentheses make \(c) − \(d) one number. What is it?", "Inside the parentheses: \(c) − \(d) = \(c - d).", Double(c + d), "Inside the parentheses it's −: \(c) − \(d)."),
            ("Write what the × makes.", "Multiply next, before adding.", b * (c - d),
             "Multiplication comes before addition.", nil, Double((a + b) * (c - d)), "Multiply before you add. Do only \(b) × \(c - d) here."),
            ("Add last, and write the answer.", "Add last.\(wrongWay)", a + b * (c - d),
             "\(b) × \(c - d) is done, so all that's left is adding \(a).", "\(a) + \(b * (c - d)) = \(a + b * (c - d)).", Double(a * b * (c - d)), "The sign is +: add \(a)."),
        ]
        let written: [LessonStep] = boxes.enumerated().map { i, s in
            LessonStep(StepWords(say: s.say, hint: s.words, action: "Check"),
                       answer: AnswerTask(prompt: line(i + 1), expected: ["x": Double(s.ans)], known: [(["x": s.slip], s.message)], hint: s.hint, explain: s.explain),
                       picture: ["at": Double([2, 4, 5][i])])
        }

        // the part that goes next, tapped in the second line (the last part is the only one left, so it's only written)
        let (nextWrong, nextHint, nextName): (String, String, String) = t == 1
            ? ("× comes before −, so the − waits.", "× comes before −.", "\(w.values[0]) × \(c)")
            : t == 2
            ? ("÷ comes before −, so the − waits.", "÷ comes before −.", "\(c) ÷ \(d)")
            : ("× comes before +, so the + waits.", "× comes before +.", "\(b) × \(w.values[0])")
        let next = LessonStep(StepWords(say: "Tap the part that goes next.", hint: nextHint, action: "Check"),
            answer: AnswerTask(prompt: [.text("next:"), .box("c")], expected: ["c": Double(w.next)],
                               known: [(["c": Double(1 - w.next)], nextWrong)],
                               hint: nextHint, explain: "\(nextHint) \(nextName) goes next.", byHand: true),
            picture: ["at": 3])

        // the last words say why, never the answer again
        let done = LessonStep(StepWords(say: t == 2 ? "× and ÷ before + and −, so everyone gets one answer." : "Parentheses, then × and ÷, then + and −, so everyone gets one answer.",
                                        hint: "Everyone uses the same order, so a problem has only one answer.", action: "Next problem"),
                              picture: ["at": 6])
        return [ask, first, written[0], next, written[1], written[2], done]
    }
}
