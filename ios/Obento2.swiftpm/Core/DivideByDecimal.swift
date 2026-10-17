import Foundation

/// Dividing by a decimal (the web app's g5-divdec): multiply both numbers by 10, then divide whole numbers.
/// Numbers: d (2 to 9) and qt (2 to 12); the problem is (d × qt)/10 ÷ d/10 (4.8 ÷ 0.6), so the answer is the whole number qt.
///
/// Picture master "double-line" (the web's double number line, in its early-g4 diagram folder; not the decimal shift):
/// two lines tick for tick, the top counting by d/10 up to (d × qt)/10, the bottom by d up to d × qt, with "× 10"
/// between them. Keys, by step:
/// - "lines": 1, both lines with qt + 1 ticks, the top ones labelled 0, d/10, 2d/10 … (always on).
/// - "lit": what is lit for the child to look at: 0 = the divisor's tick on the top line (0.6) and its whole-number
///   twin (the divisor step), 1 = the two ends, 4.8 and 48 (the other-number step). Absent: nothing lit.
/// - "one": 1, one step matched: 0 to the first tick drawn bold on both lines, the bottom tick labelled d, and the line
///   "0.6 × 10 = 6" under the picture (once the child has made the divisor whole).
/// - "all": 1, every tick matched: the lines bold to the end, wires joining each tick pair, every bottom label, both
///   ends marked with a dot and labelled in the picture's colour, and the line "4.8 × 10 = 48" (once the other number
///   is done). It replaces "one"'s bold stretch and line.
/// - "hops": 1, hops tick to tick along both lines, counted 1 to qt, and the line "48 ÷ 6 = 8, and 4.8 ÷ 0.6 = 8"
///   (the last step).
public enum DivideByDecimal {
    public static func numbers(d: Int, qt: Int) -> Numbers { ["d": Double(d), "qt": Double(qt)] }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }

    /// The two numbers: x ÷ y, and n = 10x.
    public struct Parts: Sendable {
        public let d: Int, qt: Int
        public var x: Double { r6(Double(d * qt) / 10) }
        public var y: Double { r6(Double(d) / 10) }
        public var n: Int { d * qt }
        public init(_ v: Numbers) { d = Int((v["d"] ?? 2).rounded()); qt = Int((v["qt"] ?? 2).rounded()) }
    }

    public static let spec = LessonSpec(id: "g5-divdec", title: "Dividing by a decimal", master: "double-line", generate: { rng, _ in
        let d = Int.random(in: 2...9, using: &rng), qt = Int.random(in: 2...12, using: &rng)
        return numbers(d: d, qt: qt)
    }, display: { v in let s = Parts(v); return [.num(s.x), .op("÷"), .num(s.y)] },
    idea: { _ in "Making both numbers ten times bigger doesn’t change how many times one fits in the other." },
    story: { v in let s = Parts(v); return "You have \(fmt(s.x)) liters of juice. Each cup holds \(fmt(s.y)) liters. How many cups can you fill?" },
    storyOp: { _ in "÷" },
    depends: ["g5-pow10", "g3-divfacts"],
    check: [CheckItem(0, when: { Parts($0).qt >= 7 }), CheckItem(0, when: { Parts($0).qt >= 10 }), CheckItem(0), CheckItem(0, story: true)]) { v in
        let s = Parts(v), d = s.d, qt = s.qt, x = s.x, y = s.y, n = s.n
        let X = fmt(x), Y = fmt(y)

        let ask = LessonStep(StepWords(say: "What is \(X) ÷ \(Y)?", hint: "Look at \(Y). Can it be a whole number?", action: "Let’s find out"),
                             picture: ["lines": 1])

        // hints are the spec's narration (specs/k12/grade5.md §3), the task's hint the web step's own
        let divisor = LessonStep(StepWords(say: "Make the divisor whole.", hint: "Make the divisor a whole number.", action: "Check"),
            answer: AnswerTask(prompt: [.num(y), .op("×"), .num(10), .op("="), .box("x")], expected: ["x": Double(d)],
                               known: [(["x": Double(d * 10)], "Times 10 moves the point one place."),
                                       (["x": r6(y / 10)], "Times 10 makes it bigger: the point moves right.")],
                               hint: "Move its decimal point one place right."),
            picture: ["lines": 1, "lit": 0])

        let other = LessonStep(StepWords(say: "Do the same to the other number.", hint: "Do the same to \(X), so the answer doesn’t change.", action: "Check"),
            answer: AnswerTask(prompt: [.num(x), .op("×"), .num(10), .op("="), .box("x")], expected: ["x": Double(n)],
                               known: [(["x": x], "Multiply both numbers by 10.")],
                               hint: "Multiply it by 10 too, so the answer doesn’t change."),
            picture: ["lines": 1, "one": 1, "lit": 1])

        let divide = LessonStep(StepWords(say: "Divide.", hint: "Now it’s whole numbers: divide.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(n)), .op("÷"), .num(Double(d)), .op("="), .box("x")], expected: ["x": Double(qt)],
                               known: [(["x": r6(Double(qt) / 10)], "Both numbers got 10 times bigger, so the answer is the same. Don’t move the point back."),
                                       (["x": Double(n * d)], "How many \(d)s fit in \(n)? That’s dividing.")],
                               hint: "How many \(d)s make \(n)?"),
            picture: ["lines": 1, "all": 1])

        let done = LessonStep(StepWords(say: "\(X) ÷ \(Y) = \(qt).",
                                        hint: "Making both numbers ten times bigger doesn’t change how many times one fits in the other.",
                                        action: "Next problem"),
                              picture: ["lines": 1, "all": 1, "hops": 1])
        return [ask, divisor, other, divide, done]
    }
}
