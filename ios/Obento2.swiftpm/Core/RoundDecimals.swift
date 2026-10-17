import Foundation

/// Rounding decimals (the web app's g5-round): find the place, look one place to the right, round.
/// Numbers: N (1001 to 99999) and p (1 or 2); the problem is N / 1000 (three decimal places) rounded to p places
/// (1: tenths, 2: hundredths). A rounded number isn't equal to the one it came from, so the solved line uses ≈.
///
/// Picture master "number-line" (the web's number-line family). Every step's picture carries:
/// - "lo", "hi": the ends of the line, the number rounded down and rounded up to the place (3.47 and 3.48).
/// - "tick": the gap between ticks, a tenth of the place (0.001 for hundredths); every tenth tick is long.
/// - "value": the number being rounded, marked with its label; it stays to the end.
/// - "half": the halfway point between the ends; "rounded": the answer.
/// - "line": 1, the line from lo to hi with its ticks, lo, hi and value labelled.
/// And by step:
/// - "lit": what is lit for the child to look at: 0 = the two ends and the number (the digit step), 1 = the halfway mark
///   (the next-digit step). Absent: nothing lit.
/// - "halfway": 1, the halfway mark is drawn as a dot with its label (from the next-digit step on).
/// - "hop": 1, a hop from value to rounded, labelled "closer", or "halfway: up" when "halfwayUp" is 1 (the value sits
///   exactly halfway). Drawn on the last step, once the child has rounded.
public enum RoundDecimals {
    public static func numbers(N: Int, p: Int) -> Numbers { ["N": Double(N), "p": Double(p)] }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
    private static func pow10(_ k: Int) -> Int { [1, 10, 100, 1000, 10000, 100000][k] }
    private static func digits(_ p: Int) -> String { "\(p) digit\(p > 1 ? "s" : "")" }

    /// The worked parts of a problem, all from N and p.
    public struct Parts: Sendable {
        public let N: Int, p: Int
        public var unit: Int { pow10(3 - p) }
        /// "tenths" or "hundredths"
        public var name: String { p == 1 ? "tenths" : "hundredths" }
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
        /// The digit at a place: 0 ones, 1 tenths, 2 hundredths, 3 thousandths.
        public func at(_ place: Int) -> Int { (N / pow10(3 - place)) % 10 }
        public init(_ n: Numbers) { N = Int((n["N"] ?? 1001).rounded()); p = Int((n["p"] ?? 1).rounded()) }
    }

    public static let spec = LessonSpec(id: "g5-round", title: "Rounding decimals", master: "number-line", generate: { rng, index in
        // problem 6 always rolls a 9 over (4.96 → 5.0, 3.795 → 3.80), which hardly ever comes up by chance
        if index == 5 {
            let p = Int.random(in: 1...2, using: &rng), W = Int.random(in: 1...99, using: &rng)
            let dec: Int
            if p == 1 { let t = Int.random(in: 5...9, using: &rng); dec = 900 + 10 * t + Int.random(in: 0...9, using: &rng) }
            else { let h = Int.random(in: 0...9, using: &rng); dec = 100 * h + 90 + Int.random(in: 5...9, using: &rng) }
            return numbers(N: W * 1000 + dec, p: p)
        }
        // the first three: a one-digit whole part, rounded to tenths; a number with nothing past the place is already
        // rounded, so it gets a digit there
        let N = index < 3 ? Int.random(in: 1001...9999, using: &rng) : Int.random(in: 1001...99999, using: &rng)
        let p = index < 3 ? 1 : Int.random(in: 1...2, using: &rng), unit = pow10(3 - p)
        return numbers(N: N % unit != 0 ? N : N + Int.random(in: 1...(unit - 1), using: &rng), p: p)
    }, display: { n in
        let s = Parts(n)
        // the web's display note ("Round to the nearest hundredth.") has no place in a LessonSpec, so the line carries it
        return [.num(s.value), .op("≈"), .text("?"), .text("(nearest \(s.p == 1 ? "tenth" : "hundredth"))")]
    },
    idea: { _ in "Rounding picks the closer number, and the digit just to the right tells you which." },
    depends: ["g4-placevalue", "g4-dec"],
    check: [CheckItem(3, when: { n in let s = Parts(n); return s.p == 1 && s.next < 5 }),
            CheckItem(3, when: { n in let s = Parts(n); return s.p == 1 && s.next >= 5 }),
            CheckItem(3, when: { n in Parts(n).p == 2 }),
            CheckItem(5)]) { n in
        let s = Parts(n), p = s.p, name = s.name, digit = s.digit, next = s.next, T = s.T, R = s.R
        let V = fmt(s.value), other = p == 1 ? "hundredths" : "tenths"
        let base: Numbers = ["lo": T, "hi": s.up, "tick": s.place / 10, "value": s.value, "half": s.half, "rounded": R, "line": 1]
        let pic = { (extra: Numbers) in base.merging(extra) { $1 } }

        let ask = LessonStep(StepWords(say: "What is \(V) rounded to the nearest \(p == 1 ? "tenth" : "hundredth")?",
                                       hint: "Look at the line. Which end is it closer to?", action: "Let’s find out"),
                             picture: base)

        // predictable slips, minus any that equal the answer or repeat an earlier one (the web's slips())
        var digitSlips: [(values: [String: Double], message: String)] = []
        var seen: Set<Int> = [digit]
        for (v, m) in [(s.at(3 - p), "That’s the \(other) digit. The \(name) place is \(digits(p)) after the point."),
                       (s.at(p - 1), "Start right after the point and count \(digits(p)).")] where !seen.contains(v) {
            seen.insert(v); digitSlips.append((["x": Double(v)], m))
        }
        // hints are the spec's narration (specs/k12/grade5.md §3), the task's hint the web step's own
        let findDigit = LessonStep(StepWords(say: "Which digit is in the \(name) place?", hint: "\(V) sits between \(fmt(T)) and \(fmt(s.up)).", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(digit)], known: digitSlips,
                               hint: "The \(name) place is \(digits(p)) after the point."),
            picture: pic(["lit": 0]))

        let nextSlips: [(values: [String: Double], message: String)] = digit == next ? [] : [(["x": Double(digit)], "\(digit) is the \(name) digit. The digit after it decides.")]
        let nextDigit = LessonStep(StepWords(say: "Which digit comes right after it?", hint: "Halfway between them is \(fmt(s.half)).", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(next)], known: nextSlips, hint: "Look one place further right."),
            picture: pic(["halfway": 1, "lit": 1]))

        let wrongWay: (values: [String: Double], message: String) = s.stays
            ? (["x": r6(T + s.place)], "\(next) is 4 or less, so the digit stays the same.")
            : (["x": T], "\(next) is 5 or more, so round up.")
        // the commonest slip: rounding to the other place (51.647 to hundredths given as 51.6)
        let otherPlace = Double((s.N + pow10(p) / 2) / pow10(p)) / Double(pow10(3 - p))
        let narration = (s.stays ? "\(next) is 4 or less, so the digit stays." : "\(next) is 5 or more, so round up.") + (s.halfway ? " Halfway rounds up." : "")
        let round = LessonStep(StepWords(say: "5 or more rounds up. 4 or less stays the same.", hint: narration, action: "Check"),
            answer: AnswerTask(prompt: [.num(s.value), .op("≈"), .box("x")], expected: ["x": R],
                               known: [wrongWay, (["x": r6(otherPlace)], "Round to the \(name): that’s \(digits(p)) after the point.")],
                               hint: "The next digit is \(next)."),
            picture: pic(["halfway": 1]))

        let done = LessonStep(StepWords(say: "\(V) ≈ \(fmt(R)).",
                                        hint: "Rounding picks the closer number, and the digit just to the right tells you which.",
                                        action: "Next problem"),
                              picture: pic(["halfway": 1, "hop": 1, "halfwayUp": s.halfway ? 1 : 0]))
        return [ask, findDigit, nextDigit, round, done]
    }
}
