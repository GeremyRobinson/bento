import Foundation

/// Place value and rounding (the web app's g4-placevalue, 4.NBT.3; design/grade4.md, the preview grade4-ch1.html):
/// a number n rounded to the nearest r (10, 100, 1,000, 10,000 or 100,000). Rounding decimals' two lines with bigger
/// numbers. The web's maths: its generator, its parts and its slips.
///
/// On the paper: line 1 is ten blocks of the place, from the round number of the next place up to the one after
/// (40,000 to 50,000), the number's point on it. Tap the block the point is in (it lights and opens below into line 2,
/// ten blocks of a tenth of the place, 47,000 to 48,000); drag the point to the end it's closer to (a bracket says how far
/// to each end); write the closer end in the record.
///
/// Every step's picture has "at": 0 the question, 1 tap the block, 2 drag the point, 3 write it, 4 done.
public enum PlaceValueRound {
    public static func numbers(n: Int, r: Int) -> Numbers { ["n": Double(n), "r": Double(r)] }
    /// "thousand": the round number a place counts in.
    public static let one: [Int: String] = [1: "one", 10: "ten", 100: "hundred", 1000: "thousand", 10_000: "ten thousand", 100_000: "hundred thousand"]

    public struct Parts: Sendable {
        public let n: Int, r: Int
        public var k: Int { BigNumbers.log10(r) }
        /// Line 1's start: the round number of the next place up at or under n.
        public var lo1: Int { n / (10 * r) * (10 * r) }
        /// Rounded down and up to the place; how far n is past the lower one.
        public var T: Int { n / r * r }
        public var hi: Int { T + r }
        public var rest: Int { n - T }
        public var up: Bool { 2 * rest >= r }
        public var half: Bool { 2 * rest == r }
        /// The rounded number.
        public var R: Int { up ? hi : T }
        /// The block of line 1 the point is in (its digit in the place).
        public var block: Int { (n - lo1) / r }
        /// The digit in the place, and the one after it that decides.
        public var digit: Int { BigNumbers.digit(n, k) }
        public var next: Int { BigNumbers.digit(n, k - 1) }
        public var name: String { one[r] ?? "" }
        public init(_ v: Numbers) { n = Int((v["n"] ?? 1234).rounded()); r = Int((v["r"] ?? 10).rounded()) }
        /// The last words: how far to each end, and which is closer.
        public var why: String {
            let c = BigNumbers.commas
            let head = "\(c(rest)) to \(c(T)), \(c(r - rest)) to \(c(hi))."
            return half ? "\(head) Exactly halfway rounds up." : "\(head) \(c(R)) is closer."
        }
        /// The rule, written under the record once it's rounded.
        public var rule: String { "\(next) is " + (next >= 5 ? "5 or more: round up" : "less than 5: round down") }
    }

    /// The web's generator: the first three are four digits rounded to the tens or hundreds; then five digits to the
    /// hundreds, thousands or ten thousands; then six digits to the thousands, ten thousands or hundred thousands. A
    /// next digit of 0 is mostly avoided.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let (d, places) = index < 3 ? (4, [10, 100]) : index < 6 ? (5, [100, 1000, 10_000]) : (6, [1000, 10_000, 100_000])
        let r = places[Int.random(in: 0..<places.count, using: &rng)]
        var n: Int
        repeat { n = Int.random(in: BigNumbers.pow10(d - 1)...(BigNumbers.pow10(d) - 1), using: &rng) }
        while n % r == 0 || ((n / (r / 10)) % 10 == 0 && Double.random(in: 0..<1, using: &rng) < 0.7)
        return numbers(n: n, r: r)
    }

    public static let spec = LessonSpec(id: "g4-placevalue", title: "Place value and rounding", master: "number-line",
        generate: { rng, index in make(&rng, index) },
        display: { v in let s = Parts(v); return [.text(BigNumbers.commas(s.n)), .op("≈"), .text("?"), .text("(nearest \(s.name))")] },
        idea: { _ in "Rounding finds the closest round number, and the next digit shows which side of halfway it’s on." },
        depends: ["g3-round"],
        check: [CheckItem(3, when: { !Parts($0).up }), CheckItem(3, when: { Parts($0).up }), CheckItem(6, when: { Parts($0).next == 5 }), CheckItem(6)]) { v in
        let s = Parts(v), c = BigNumbers.commas, N = c(s.n), name = s.name
        let ask = LessonStep(StepWords(say: "Round to the nearest \(name).", hint: "Which round \(name) is it closer to?", action: "Let’s find out"),
                             picture: ["at": 0])

        // tap the block the point is in
        let tap = LessonStep(StepWords(say: "Round to the nearest \(name). Tap the \(name) the point is in.", hint: "Find the point. Tap the block it sits in.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.block)], hint: "Find the point. Tap the block it sits in.",
                               explain: "\(N) is between \(c(s.T)) and \(c(s.hi)).",
                               check: { x in
                                   guard let b = x["x"], b >= 0, b <= 9 else { return .soft("Tap the block the point is in.") }
                                   let bl = Int(b.rounded())
                                   return bl == s.block ? .right : .wrong("\(N) is between \(c(s.T)) and \(c(s.hi)).")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])

        // drag the point to the end it's closer to (0 the lower end, 10 the upper)
        let end = s.up ? 10.0 : 0
        let drag = LessonStep(StepWords(say: "Drag the point to the closer end.", hint: "Count how far it is to each end.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": end], hint: "Count how far it is to each end.", explain: s.why,
                               check: { x in
                                   guard let e = x["x"], e == 0 || e == 10 else { return .soft("Drag it all the way to one end.") }
                                   if e == end { return .right }
                                   if s.half { return .wrong("Exactly halfway rounds up.") }
                                   let far = e == 10 ? s.r - s.rest : s.rest
                                   return .wrong("That end is \(c(far)) away. The other end is \(c(s.r - far)).")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["counts": 1], hint2: ["spot": 1])

        // write the closer end, with the web's slips
        let small = s.r / 10, finer = (s.n + small / 2) / small * small
        let known = BigNumbers.slips(Double(s.R), [
            (Double(s.up ? s.T : s.hi), s.up ? "The next digit is \(s.next). 5 or more rounds up, to \(c(s.hi))." : "The next digit is \(s.next). Less than 5 rounds down, to \(c(s.T))."),
            (Double(s.R + s.n % s.r), "A rounded number ends in zeros. Every digit after the \(name)s place becomes 0."),
        ] + (s.r >= 100 ? [(Double(finer), "That’s \(N) to the nearest \(PlaceValueRound.one[small] ?? ""). Round to the nearest \(name) instead.")] : [])
          + [(Double(s.R / s.r), "Keep the zeros: \(s.R / s.r) \(name)s is written \(c(s.R)).")])
        let write = LessonStep(StepWords(say: "Write the closer end.", hint: "The end you dragged to, after ≈.", action: "Check"),
            answer: AnswerTask(prompt: [.text(N), .op("≈"), .box("x")], expected: ["x": Double(s.R)], known: known,
                               hint: "The end you dragged to, after ≈.", explain: "The point went to \(c(s.R)), the closer end.",
                               check: { x in Int((x["x"] ?? -1).rounded()) == s.R ? .right : .wrong("Write the end you dragged to.") }),
            picture: ["at": 3])

        let done = LessonStep(StepWords(say: s.why, hint: "Rounding finds the closest round number.", action: "Next problem"), picture: ["at": 4])
        return [ask, tap, drag, write, done]
    }
}
