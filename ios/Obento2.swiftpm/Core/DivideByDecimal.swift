import Foundation

/// Dividing by a decimal (the web app's g5-divdec): multiply both numbers by 10, then divide whole numbers.
/// Numbers: d (2 to 9) and qt (2 to 12); the problem is (d × qt)/10 ÷ d/10 (4.8 ÷ 0.6), so the answer is the whole number qt.
///
/// On the paper (design/grade5.md): a number line where one square is a tenth (a block of five is 0.5, a whole is ten
/// squares; a line of one or two wholes is drawn 3 or 2 squares a tenth, squaresPerTenth), from 0 on past the dividend to the next whole, the dividend marked and named on it.
/// The child hops the divisor along it from 0 (a tap lays one more hop, a drag lays them as it goes, each snapping to
/// the divisor's d squares and numbered), the readout counting the hops and where they reach. Then the same squares
/// are read in tenths under the line (0, 6, 12, … 48), so 4.8 ÷ 0.6 is 48 ÷ 6, and the record is written:
/// `4.8 ÷ 0.6 = 48 ÷ 6 = [ ]`. Picture key "at", the stage: 0 the question, 1 hop, 2 write, 3 done. Hints: "ring"
/// (the end ringed, after a miss on the hops).
public enum DivideByDecimal {
    public static func numbers(d: Int, qt: Int) -> Numbers { ["d": Double(d), "qt": Double(qt)] }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }

    /// The two numbers: x ÷ y, and n = 10x.
    public struct Parts: Sendable {
        public let d: Int, qt: Int
        public var x: Double { r6(Double(d * qt) / 10) }
        public var y: Double { r6(Double(d) / 10) }
        public var n: Int { d * qt }
        /// Where `k` hops of y reach.
        public func reach(_ k: Int) -> Double { r6(Double(d * k) / 10) }
        public init(_ v: Numbers) { d = Int((v["d"] ?? 2).rounded()); qt = Int((v["qt"] ?? 2).rounded()) }
    }

    static func hops(_ k: Int) -> String { k == 1 ? "1 hop" : "\(k) hops" }

    /// Squares to a tenth on the paper: one, but a short line (one whole, or two) is drawn three or two times as big, so
    /// the smallest problems aren't a sliver of the screen; every half is still on a strong line.
    public static func squaresPerTenth(_ n: Int) -> Int { n < 10 ? 3 : n < 20 ? 2 : 1 }

    /// The hops laid, `h` of them: right when they reach the end, else where they reach, measured.
    public static func hopVerdict(_ h: Double?, _ s: Parts) -> Verdict {
        guard let h, h > 0 else { return .soft("Tap the line to hop \(fmt(s.y)) from 0.") }
        let k = Int(h.rounded()), reach = "\(hops(k)) of \(fmt(s.y)) \(k == 1 ? "reaches" : "reach") \(fmt(s.reach(k)))."
        if k == s.qt { return .right }
        if k > s.qt { return .wrong("\(reach) That’s past \(fmt(s.x)).") }
        return .wrong("\(reach) Hop on to \(fmt(s.x)).")
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

        // the problem is written once, as the line's end and the hop's size (G 20 Oct): the first words say what a square is
        let u = squaresPerTenth(n)
        let ask = LessonStep(StepWords(say: u == 1 ? "Each square on the line is a tenth." : "Every \(u) squares on the line make a tenth.", hint: "How many hops of \(Y) reach \(X)?", action: "Let’s find out"),
                             picture: ["at": 0])

        // the hops: tapped or dragged along from 0, each d squares; how many are laid goes in the box
        let hop = LessonStep(StepWords(say: "Hop along the line from 0 to the end. Tap, or drag.", hint: u == 1 ? "Each hop is \(d) squares." : "Each hop is \(d) tenths.", action: "Check"),
            answer: AnswerTask(prompt: [.num(x), .op("÷"), .num(y), .op("="), .box("h")], expected: ["h": Double(qt)],
                               hint: "Hop \(Y) at a time until you reach \(X).",
                               explain: "\(hops(qt)) of \(Y) reach \(X).",
                               check: { v in DivideByDecimal.hopVerdict(v["h"], s) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1])

        // the same squares in tenths: the one number school writes is the answer; the web's divide step, its slips kept
        let divide = LessonStep(StepWords(say: "Read the hops in tenths, under the line. Write the answer.", hint: "Now it’s whole numbers: divide.", action: "Check"),
            answer: AnswerTask(prompt: [.num(x), .op("÷"), .num(y), .op("="), .num(Double(n)), .op("÷"), .num(Double(d)), .op("="), .box("x")],
                               expected: ["x": Double(qt)],
                               known: [(["x": r6(Double(qt) / 10)], "Both numbers got 10 times bigger, so the answer is the same. Don’t move the point back."),
                                       (["x": Double(n * d)], "How many \(d)s fit in \(n)? That’s dividing.")],
                               hint: "How many \(d)s make \(n)?"),
            picture: ["at": 2])

        // the answer is in the record; the last words say why
        let done = LessonStep(StepWords(say: "The same hops in tenths: \(n) ÷ \(d).",
                                        hint: "Making both numbers ten times bigger doesn’t change how many times one fits in the other.",
                                        action: "Next problem"),
                              picture: ["at": 3])
        return [ask, hop, divide, done]
    }
}
