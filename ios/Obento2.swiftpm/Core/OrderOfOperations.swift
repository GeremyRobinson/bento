import Foundation

/// Order of operations (the web app's g5-order), in three shapes that take turns:
/// t = 0: a + b × (c − d),  t = 1: (a + b) × c − d,  t = 2: a × b − c ÷ d.
/// Numbers: t (the shape), a, b, c, d.
///
/// Picture master: "order" (web `explanations/diagrams/order`): the expression as one row of tiles, every number in its
/// own tile, the signs between them, the parentheses drawn round what they hold. Three groups are worked out in order
/// (t0: c − d, then b × (c − d), then the whole row; t1: (a + b), then (a + b) × c, then the whole row;
/// t2: a × b, then c ÷ d, then the whole row). A worked group becomes one tile holding its value, as wide as what it
/// replaced, so nothing already drawn moves.
/// Picture keys:
/// - `beat`: 0 = the row as written, nothing lit. 1, 2, 3 = the groups before group (beat − 1) are value tiles and
///   group (beat − 1) is lit (its tiles filled, a ring round it). 4 = the whole row is one tile: the answer.
/// Per step: ask {beat 0} · first ("What goes first?") {beat 0, so the picture doesn't give the answer away} ·
/// s0 {beat 1} · s1 {beat 2} · s2 {beat 3} · done {beat 4}.
public enum OrderOfOperations {
    public static func numbers(t: Int, a: Int, b: Int, c: Int, d: Int) -> Numbers {
        ["t": Double(t), "a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d)]
    }

    private static let leftToRightWords = "Parentheses go first, then × and ÷, then + and −. Left to right is only for signs of the same kind."

    /// The expression as written.
    public static func expression(t: Int, a: Int, b: Int, c: Int, d: Int) -> MathLine {
        func v(_ x: Int) -> Math { .num(Double(x)) }
        switch t {
        case 1: return [.text("("), v(a), .op("+"), v(b), .text(")"), .op("×"), v(c), .op("−"), v(d)]
        case 2: return [v(a), .op("×"), v(b), .op("−"), v(c), .op("÷"), v(d)]
        default: return [v(a), .op("+"), v(b), .op("×"), .text("("), v(c), .op("−"), v(d), .text(")")]
        }
    }
    private static func plain(t: Int, a: Int, b: Int, c: Int, d: Int) -> String {
        t == 1 ? "(\(a) + \(b)) × \(c) − \(d)" : t == 2 ? "\(a) × \(b) − \(c) ÷ \(d)" : "\(a) + \(b) × (\(c) − \(d))"
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
        func v(_ x: Int) -> Math { .num(Double(x)) }
        let r2 = value(t: t, a: a, b: b, c: c, d: d)

        let ask = LessonStep(StepWords(say: "What is \(plain(t: t, a: a, b: b, c: c, d: d))?", hint: "Look at the signs and the parentheses.", action: "Let’s find out"),
                             picture: ["beat": 0])

        // "What goes first?": a pick-one step, as on the web: the child taps the part that goes first; the slips are the web's, by part
        let (choices, ans, wrong): ([String], Int, [Int: String]) = t == 1
            ? (["\(a) + \(b)", "\(c) − \(d)"], 0, [1: "The parentheses go first: \(a) + \(b). Then × comes before −."])
            : t == 2
            ? (["\(a) × \(b)", "\(b) − \(c)"], 0, [1: "× and ÷ come before −, so the − waits."])
            : (["\(a) + \(b)", "\(b) × \(c)", "\(c) − \(d)"], 2, [0: leftToRightWords, 1: "The parentheses make \(c) − \(d) one number, so it comes even before ×."])
        let firstHint = t == 2 ? "There are no parentheses here. Which comes first, × or −?" : "Look for parentheses: they say \"do me first\"."
        let firstExplain = t == 2 ? "× comes before −, so \(a) × \(b) goes first." : "The parentheses go first: \(choices[ans])."
        let first = LessonStep(StepWords(say: "Which part do you do first?",
                                         hint: t == 2 ? "No parentheses, and × comes before −." : "Find the parentheses: they go first.", action: "Check"),
            answer: AnswerTask(prompt: [.text("First:")], expected: ["c": Double(ans)],
                               known: wrong.keys.sorted().map { (["c": Double($0)], wrong[$0]!) },
                               hint: firstHint, explain: firstExplain, choices: choices),
            picture: ["beat": 0])

        // the slip the web's card warns about, worked out for this problem
        let leftToRight: Double? = t == 1 ? nil : t == 2 ? Double(a * b - c) / Double(d) : Double((a + b) * (c - d))
        let wrongWay = leftToRight.map { $0 == $0.rounded() && Int($0) != r2 ? " Left to right would give \(fmt($0)), which is wrong." : "" } ?? ""

        typealias Box = (label: String, words: String, prompt: MathLine, ans: Int, hint: String, explain: String?, slip: Int, message: String)
        let boxes: [Box] = t == 1 ? [
            ("Parentheses first", "Work out the inside of the parentheses.", [v(a), .op("+"), v(b)], a + b,
             "The parentheses make \(a) + \(b) one number. What is it?", "Inside the parentheses: \(a) + \(b) = \(a + b).", a * b, "Inside the parentheses it's +: \(a) + \(b)."),
            ("Multiply next", "Multiply before subtracting.", [v(a + b), .op("×"), v(c)], (a + b) * c,
             "Multiplication comes before subtraction.", nil, (a + b) * (c - d), "Multiply before you subtract: \(a + b) × \(c)."),
            ("Subtract last", "Subtract last.", [v((a + b) * c), .op("−"), v(d)], (a + b) * c - d,
             "The multiplying is done, so take \(d) away.", "\((a + b) * c) − \(d) = \((a + b) * c - d).", (a + b) * c + d, "The sign is −, so take \(d) away."),
        ] : t == 2 ? [
            ("Multiply", "Multiply first.", [v(a), .op("×"), v(b)], a * b,
             "× and ÷ come before −.", nil, a + b, "That's \(a) + \(b). The sign is ×."),
            ("Divide", "Divide next, still before subtracting.", [v(c), .op("÷"), v(d)], c / d,
             "× and ÷ come before −, so divide before you subtract.", nil, c * d, "The sign is ÷: how many \(d)s make \(c)?"),
            ("Subtract last", "Subtract last.\(wrongWay)", [v(a * b), .op("−"), v(c / d)], a * b - c / d,
             "The × and ÷ are done, so take \(c / d) away from \(a * b).", "\(a * b) − \(c / d) = \(a * b - c / d).", -1, "Divide \(c) ÷ \(d) first, then subtract it from \(a * b)."),
        ] : [
            ("Parentheses first", "Work out the inside of the parentheses.", [v(c), .op("−"), v(d)], c - d,
             "The parentheses make \(c) − \(d) one number. What is it?", "Inside the parentheses: \(c) − \(d) = \(c - d).", c + d, "Inside the parentheses it's −: \(c) − \(d)."),
            ("Multiply next", "Multiply next, before adding.", [v(b), .op("×"), v(c - d)], b * (c - d),
             "Multiplication comes before addition.", nil, (a + b) * (c - d), "Multiply before you add. Do only \(b) × \(c - d) here."),
            ("Add last", "Add last.\(wrongWay)", [v(a), .op("+"), v(b * (c - d))], a + b * (c - d),
             "\(b) × \(c - d) is done, so all that's left is adding \(a).", "\(a) + \(b * (c - d)) = \(a + b * (c - d)).", a * b * (c - d), "The sign is +: add \(a)."),
        ]
        let worked: [LessonStep] = boxes.enumerated().map { i, s in
            // t2's last slip, (a × b − c) ÷ d, need not be whole: kept as the web's exact number
            let slip: Double = t == 2 && i == 2 ? Double(a * b - c) / Double(d) : Double(s.slip)
            return LessonStep(StepWords(say: s.label, hint: s.words, action: "Check"),
                              answer: AnswerTask(prompt: s.prompt + [.op("="), .box("x")], expected: ["x": Double(s.ans)],
                                                 known: [(["x": slip], s.message)], hint: s.hint, explain: s.explain),
                              picture: ["beat": Double(i + 1)])
        }
        let solved = "\(t == 2 ? "× and ÷ first, then −," : "Parentheses, then ×, then \(t == 1 ? "−" : "+"),") makes \(r2)."
        let done = LessonStep(StepWords(say: solved, hint: "Everyone uses the same order, so a problem has only one answer.", action: "Next problem"),
                              picture: ["beat": 4])
        return [ask, first] + worked + [done]
    }
}
