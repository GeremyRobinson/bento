import Foundation

/// Rounding decimals (the web app's g5-round): find the place, look one place to the right, round.
/// Numbers: N (1001 to 99999) and p (1 or 2); the problem is N / 1000 rounded to p places (1: tenths, 2: hundredths).
/// Rounding to hundredths uses three decimals, rounding to tenths two (G 20 Oct, the paper design): one place past the
/// place being rounded to, so the number sits on a step of the second line. A rounded number isn't equal to the one it
/// came from, so the record uses ≈.
///
/// On the paper (design/grade5.md, the test page G approved): line 1 is the place one bigger (the tenth for hundredths,
/// the whole for tenths) in ten blocks of the place, the number's point on it. The child taps the block the point is
/// in (that answers which digit is in the place: the block's number is the digit); it opens into line 2, ten steps of
/// the next place, and the child drags the point to the end it's closer to (the steps counted from the lower end are
/// the next digit); then writes the closer end in the record.
///
/// Every step's picture carries the line's numbers: "lo", "hi" (the number rounded down and rounded up to the place),
/// "tick" (a step of line 2), "value", "half" and "rounded". And "at", the stage: 0 the question, 1 tap the block,
/// 2 drag the point, 3 write it, 4 done. After a miss, "ring" (the point ringed on line 1) on the tap and "counts" (the
/// steps to each end) on the drag.
public enum RoundDecimals {
    public static func numbers(N: Int, p: Int) -> Numbers { ["N": Double(N), "p": Double(p)] }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
    private static func pow10(_ k: Int) -> Int { [1, 10, 100, 1000, 10000, 100000][k] }
    private static func digits(_ p: Int) -> String { "\(p) digit\(p > 1 ? "s" : "")" }
    /// A number written to `d` places (5.0, not 5): the ends of a line are written to their place.
    public static func written(_ v: Double, _ d: Int) -> String { String(format: "%.\(max(0, d))f", v) }
    static func steps(_ k: Int) -> String { k == 1 ? "1 step" : "\(k) steps" }

    /// The worked parts of a problem, all from N and p.
    public struct Parts: Sendable {
        public let N: Int, p: Int
        /// The place, in thousandths (100 for tenths, 10 for hundredths).
        public var unit: Int { pow10(3 - p) }
        /// "tenths" or "hundredths"
        public var name: String { p == 1 ? "tenths" : "hundredths" }
        public var placeName: String { p == 1 ? "tenth" : "hundredth" }
        public var value: Double { Double(N) / 1000 }
        /// The digit in the place, and the one right after it.
        public var digit: Int { (N / unit) % 10 }
        public var next: Int { (N / (unit / 10)) % 10 }
        /// Rounded down (cut off) and rounded.
        public var T: Double { r6(Double(N / unit) / Double(pow10(p))) }
        public var R: Double { r6(Double((N + unit / 2) / unit) / Double(pow10(p))) }
        public var place: Double { 1 / Double(pow10(p)) }
        public var up: Double { r6(T + place) }
        public var half: Double { r6(T + place / 2) }
        public var halfway: Bool { abs(value - half) < 1e-9 }
        public var stays: Bool { abs(R - T) < 1e-9 }
        public var roundsUp: Bool { !stays }
        /// The digit at a place: 0 ones, 1 tenths, 2 hundredths, 3 thousandths.
        public func at(_ place: Int) -> Int { (N / pow10(3 - place)) % 10 }
        /// Line 1's start: the place one bigger, at or under the number (3.4 for 3.476 to hundredths, 5 for 5.28 to
        /// tenths). Its ten blocks are the place's, and the block the number is in is its digit.
        public var lo1: Double { r6(Double(N / (10 * unit) * (10 * unit)) / 1000) }
        /// Where the number sits on line 2, in its steps from the lower end (the next digit, when the number has just one
        /// more decimal than the place).
        public var step: Double { Double(N % unit) / Double(unit / 10) }
        /// The steps from the number to the end it rounds to, and to the other end.
        public var near: Int { roundsUp ? 10 - next : next }
        public var far: Int { 10 - near }
        /// The rule, written under the record once it's rounded.
        public var rule: String { "\(next) is " + (next >= 5 ? "5 or more: round up" : "4 or less: it stays") }
        /// The last words: why that end (the steps counted on the line).
        public var why: String {
            let t = written(T, p), u = written(up, p), r = written(R, p)
            if roundsUp { return "\(RoundDecimals.steps(next)) from \(t), \(10 - next) to \(u). " + (halfway ? "Halfway rounds up." : "\(r) is closer.") }
            return "\(RoundDecimals.steps(next)) to \(t), \(10 - next) to \(u). \(r) is closer."
        }
        public init(_ n: Numbers) { N = Int((n["N"] ?? 1001).rounded()); p = Int((n["p"] ?? 1).rounded()) }
    }

    /// A number to round to tenths: two decimals, the second not 0 (something to round), the whole from `wholes`.
    static func tenths(_ rng: inout SeededRandom, wholes: ClosedRange<Int>) -> Int {
        Int.random(in: wholes, using: &rng) * 1000 + Int.random(in: 0...9, using: &rng) * 100 + Int.random(in: 1...9, using: &rng) * 10
    }

    public static let spec = LessonSpec(id: "g5-round", title: "Rounding decimals", master: "number-line", generate: { rng, index in
        // problem 6 always rolls a 9 over (4.96 → 5.0, 3.795 → 3.80), which hardly ever comes up by chance
        if index == 5 {
            let p = Int.random(in: 1...2, using: &rng), W = Int.random(in: 1...99, using: &rng)
            let dec: Int
            if p == 1 { dec = 900 + 10 * Int.random(in: 5...9, using: &rng) }
            else { let h = Int.random(in: 0...9, using: &rng); dec = 100 * h + 90 + Int.random(in: 5...9, using: &rng) }
            return numbers(N: W * 1000 + dec, p: p)
        }
        // the first three: a one-digit whole part, rounded to tenths
        if index < 3 { return numbers(N: tenths(&rng, wholes: 1...9), p: 1) }
        if Int.random(in: 1...2, using: &rng) == 1 { return numbers(N: tenths(&rng, wholes: 1...99), p: 1) }
        // hundredths: three decimals, the third not 0
        let N = Int.random(in: 1001...99999, using: &rng)
        return numbers(N: N % 10 != 0 ? N : N + Int.random(in: 1...9, using: &rng), p: 2)
    }, display: { n in
        let s = Parts(n)
        // the web's display note ("Round to the nearest hundredth.") has no place in a LessonSpec, so the line carries it
        return [.num(s.value), .op("≈"), .text("?"), .text("(nearest \(s.placeName))")]
    },
    idea: { _ in "Rounding picks the closer number, and the digit just to the right tells you which." },
    depends: ["g4-placevalue", "g4-dec"],
    check: [CheckItem(3, when: { n in let s = Parts(n); return s.p == 1 && s.next < 5 }),
            CheckItem(3, when: { n in let s = Parts(n); return s.p == 1 && s.next >= 5 }),
            CheckItem(3, when: { n in Parts(n).p == 2 }),
            CheckItem(5)]) { n in
        let s = Parts(n), p = s.p, name = s.name, digit = s.digit, next = s.next, T = s.T, R = s.R
        let V = fmt(s.value), Rs = written(R, p), place = s.placeName
        let base: Numbers = ["lo": T, "hi": s.up, "tick": s.place / 10, "value": s.value, "half": s.half, "rounded": R]
        let pic = { (extra: Numbers) in base.merging(extra) { $1 } }

        // the number is written once, as the point's own label (G 20 Oct): the words only say which place
        let ask = LessonStep(StepWords(say: "Round to the nearest \(place).",
                                       hint: "Look at the line. Which end is it closer to?", action: "Let’s find out"),
                             picture: pic(["at": 0]))

        // tap the block the point is in: the block's number is the place's digit
        let block: @Sendable (Int) -> (String, String) = { b in (written(s.lo1 + Double(b) * s.place, p), written(s.lo1 + Double(b + 1) * s.place, p)) }
        // the words name what to tap ("it" would have nothing to point at: the number is the point's own label)
        let tap = LessonStep(StepWords(say: "Round to the nearest \(place). Tap the block the point is in.",
                                       hint: "Find the point on the line. Tap the block it sits in.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(digit)],
                               hint: "The \(name) place is \(digits(p)) after the point.",
                               explain: "\(V) is between \(block(digit).0) and \(block(digit).1).",
                               check: { v in
                                   guard let x = v["x"], x >= 0, x <= 9 else { return .soft("Tap the block the point is in.") }
                                   if Int(x.rounded()) == digit { return .right }
                                   let (a, b) = block(Int(x.rounded()))
                                   return .wrong("\(V) isn’t between \(a) and \(b). Find the point.")
                               }, byHand: true),
            picture: pic(["at": 1]), onMiss: ["ring": 1])

        // drag the point to the end it's closer to: its steps from the lower end are the next digit
        let end = s.roundsUp ? 10.0 : 0
        let drag = LessonStep(StepWords(say: "Drag the point to the end it’s closer to.", hint: "Count the steps to each end.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": end],
                               hint: "The digit after the \(place) is \(next): \(next) steps from \(written(T, p)).",
                               explain: s.why,
                               check: { v in
                                   guard let x = v["x"], x == 0 || x == 10 else { return .soft("Drag it all the way to one end.") }
                                   if x == end { return .right }
                                   if s.halfway { return .wrong("Exactly halfway rounds up.") }
                                   return .wrong("That end is \(steps(s.far)) away. The other end is \(s.near).")
                               }, byHand: true),
            picture: pic(["at": 2]), onMiss: ["counts": 1])

        // write the closer end, as school writes it: the number ≈ the rounded number
        let wrongWay: (values: [String: Double], message: String) = s.stays
            ? (["x": r6(T + s.place)], "\(next) is 4 or less, so the digit stays the same.")
            : (["x": T], "\(next) is 5 or more, so round up.")
        // the commonest slip: rounding to the other place (51.647 to hundredths given as 51.6)
        let otherPlace = Double((s.N + pow10(p) / 2) / pow10(p)) / Double(pow10(3 - p))
        let write = LessonStep(StepWords(say: "Write the closer end.", hint: "Write the number at the end the point went to.", action: "Check"),
            answer: AnswerTask(prompt: [.num(s.value), .op("≈"), .box("x")], expected: ["x": R],
                               known: [wrongWay, (["x": r6(otherPlace)], "Round to the \(name): that’s \(digits(p)) after the point.")],
                               hint: "The point went to \(Rs).", explain: "The point went to \(Rs), the closer end.",
                               check: { v in
                                   guard let x = v["x"] else { return .soft("Fill in every box.") }
                                   return abs(x - R) < 1e-9 ? .right : .wrong("That’s not the end you dragged to. It was \(Rs).")
                               }),
            picture: pic(["at": 3]))

        // the answer is in the record, the rule under it; the last words say why
        let done = LessonStep(StepWords(say: s.why,
                                        hint: "Rounding picks the closer number, and the digit just to the right tells you which.",
                                        action: "Next problem"),
                              picture: pic(["at": 4]))
        return [ask, tap, drag, write, done]
    }
}
