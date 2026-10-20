import Foundation

/// Multiply by 10, 100, 1000 (the web app's g5-pow10): each zero moves every digit one place bigger.
/// Numbers: x (two decimal places at most, 1.01 to 99.99) and k (1 to 3); the problem is x × 10^k.
///
/// On the paper (design/grade5.md): a place chart, a column for each place the problem uses (from one past where the
/// answer's first digit lands down to x's last decimal), the point fixed on the strong line between the ones and the
/// tenths, and x's digits in their columns (the number written once). The child drags the digits left together, a
/// column at a time, the hops and the readout under the chart counting "× 10", "× 100", "× 1000"; letting go on k
/// columns answers the web's "how many zeros" step (its box is set from the columns moved). Then, only when x has fewer
/// decimals than 10^k has zeros, they tap each empty place between the digits and the point, and a 0 is written there.
/// Then the record, x × 10^k = [ ], typed: the web's "move the point" step, with its slips, worded for the chart (the
/// digits move; the point stays where it is).
///
/// Picture keys: "at", the stage: 0 the question, 1 drag the digits, 2 write the 0s, 3 write the record, 4 done. A hint
/// (after a miss, or asked for) lights: "target" (the hops the digits make, dashed, and what they make), "gaps" (each
/// empty place ringed), "read" (the new number outlined on the chart).
public enum PowersOfTen {
    public static func numbers(x: Double, k: Int) -> Numbers { ["x": (x * 100).rounded() / 100, "k": Double(k)] }

    static let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    static func places(_ k: Int) -> String { "\(k) place\(k == 1 ? "" : "s")" }
    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }

    /// The digits as written without the point, and how many sit left of it: 3.47 → ("347", 1).
    public static func digits(_ x: Double) -> (digits: String, whole: Int) {
        let s = fmt(x), parts = s.split(separator: ".", omittingEmptySubsequences: false)
        return (parts.joined(), parts[0].count)
    }

    /// A place's name, by its power of ten (4 the ten thousands … 0 the ones, −1 the tenths, −2 the hundredths).
    public static func placeName(_ p: Int) -> String {
        ["hundredths", "tenths", "ones", "tens", "hundreds", "thousands", "ten thousands"][min(6, max(0, p + 2))]
    }

    /// A wrong tap on the step that writes the 0s is set as 10 + the place tapped (8 to 14; the right answer, how many
    /// 0s there are, is 1 to 3), so the check can say what's in that place.
    public static func tapCode(_ place: Int) -> Double { Double(10 + place) }

    /// The worked parts of a problem, all from x and k.
    public struct Parts: Sendable {
        public let x: Double, k: Int
        /// x's digits as written, without the point, and how many are whole.
        public let digits: [Character], whole: Int
        public init(_ n: Numbers) {
            x = n["x"] ?? 1; k = Int((n["k"] ?? 1).rounded())
            let d = PowersOfTen.digits(x)
            digits = Array(d.digits); whole = d.whole
        }
        public var m: Double { pow(10, Double(k)) }
        public var M: String { fmt(m) }
        public var answer: Double { r6(x * m) }
        public var decimals: Int { digits.count - whole }
        /// The place of digit `i` of x, moved `by` places (0 the ones, 1 the tens, −1 the tenths).
        public func place(_ i: Int, by: Int = 0) -> Int { whole - 1 - i + by }
        /// The digit in place `p` once the digits have moved `by` places, if one is there.
        public func digit(at p: Int, by: Int = 0) -> Character? {
            let i = whole - 1 + by - p
            return digits.indices.contains(i) ? digits[i] : nil
        }
        /// The first digit's place, before the move (k places bigger after it).
        public var lead: Int { whole - 1 }
        /// The places left empty between the digits and the point once they've moved: a 0 is written in each (none
        /// when x has as many decimals as 10^k has zeros).
        public var gaps: [Int] { (0..<max(0, k - decimals)).reversed().map { $0 } }
        /// The chart's places, left to right: from one past where the first digit lands (room for one place too far,
        /// the ten thousands at most) down to x's last decimal (the tenths at least, so the point has a place each side).
        public var hi: Int { min(4, lead + k + 1) }
        public var lo: Int { min(-1, -decimals) }
        public var columns: [Int] { Array((lo...hi).reversed()) }
        /// The furthest the digits can go: the first one to the chart's first place.
        public var most: Int { hi - lead }
        /// What `d` places make: "× 100".
        public static func times(_ d: Int) -> String { "× " + fmt(pow(10, Double(d))) }
        /// What a move of `d` places says when it isn't k.
        public func moved(_ d: Int) -> String { "That’s \(Self.times(d)). × \(M) moves every digit \(PowersOfTen.places(k))." }
        /// The rule, written under the record once it's done.
        public var rule: String { "\(k) zero\(k == 1 ? "" : "s"): \(PowersOfTen.places(k)) bigger" }
        /// What a tap that isn't on an empty place between the digits and the point says.
        public func tapped(_ p: Int) -> String {
            if let d = digit(at: p, by: k) { return "That place has a \(d) in it." }
            if p < 0 { return "No 0 is needed after the point." }
            return "No 0 is needed in front of the \(digits.first.map(String.init) ?? "number")."
        }
    }

    public static let spec = LessonSpec(id: "g5-pow10", title: "Multiply by 10, 100, 1000", master: "shift", generate: { rng, index in
        // the web lesson's order: first a one-digit whole part with tenths, times 100, so the digits run past the point
        // and a 0 is written in (the tricky part); the next two times 10; then anything
        if index == 0 {
            var n = Int.random(in: 11...99, using: &rng); if n % 10 == 0 { n += 1 }
            return numbers(x: Double(n) / 10, k: 2)
        }
        if index < 3 { return numbers(x: Double(Int.random(in: 101...999, using: &rng)) / 100, k: 1) }
        return numbers(x: Double(Int.random(in: 101...9999, using: &rng)) / 100, k: Int.random(in: 1...3, using: &rng))
    }, display: { n in [.num(n["x"] ?? 0), .op("×"), .num(pow(10, n["k"] ?? 1))] },
    idea: { n in
        let k = Int(n["k"] ?? 1)
        return "Times \(fmt(pow(10, Double(k)))) makes each digit worth \(["ten", "a hundred", "a thousand"][k - 1]) times more, so every digit moves \(words[k]) \(k > 1 ? "places" : "place") left."
    },
    depends: ["g4-dec", "g4-placevalue"],
    check: [CheckItem(3, when: { $0["k"] == 1 }), CheckItem(3, when: { $0["k"] == 2 }),
            CheckItem(3, when: { n in n["k"] == 3 && (fmt(n["x"] ?? 0).split(separator: ".").dropFirst().first?.count ?? 0) < 3 }), CheckItem(3)]) { n in
        let s = Parts(n), x = s.x, k = s.k, m = s.m, ans = s.answer, M = s.M, A = fmt(ans)
        let first = s.digits.first.map(String.init) ?? ""

        // the number is written once, as the chart's digits (G 20 Oct): the words only say what it's multiplied by
        let ask = LessonStep(StepWords(say: "Multiply by \(M).", hint: "Each zero moves every digit one place.", action: "Let’s find out"),
                             picture: ["at": 0])

        // drag the digits left: the places they move are the zeros counted (the web's first step, answered by the move)
        let drag = LessonStep(StepWords(say: "Multiply by \(M). Drag the digits left.", hint: "Each zero moves every digit one place.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(k)],
                               // the web's slip: the 1 counted as a zero, one place too far
                               known: [(["x": Double(k + 1)], s.moved(k + 1))],
                               hint: "\(M) has \(k) zero\(k == 1 ? "" : "s"): every digit moves \(places(k)).",
                               explain: "× \(M) moves every digit \(places(k)): the \(first) goes from the \(placeName(s.lead)) to the \(placeName(s.lead + k)).",
                               check: { v in
                                   guard let d = v["x"], d > 0 else { return .soft("They didn’t move. Drag them left.") }
                                   return Int(d.rounded()) == k ? .right : .wrong(s.moved(Int(d.rounded())))
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["target": 1])

        // the places left empty between the digits and the point: tap each, and a 0 is written there (wrong taps are
        // notices, not misses: a 0 after the point or in front changes nothing)
        let gaps = s.gaps, names = gaps.map { placeName($0) }
        let zeros = LessonStep(StepWords(say: "Tap each gap to write a 0.", hint: "Every place between the digits and the point needs a digit.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(gaps.count)],
                               hint: "Write a 0 in each empty place between the digits and the point.",
                               explain: "The \(names.dropLast().joined(separator: ", ") + (names.count > 1 ? " and " : "") + (names.last ?? "")) \(gaps.count == 1 ? "place is" : "places are") empty: a 0 goes in \(gaps.count == 1 ? "it" : "each").",
                               check: { v in
                                   guard let z = v["x"] else { return .soft("Tap each gap.") }
                                   let t = Int(z.rounded())
                                   if t == gaps.count { return .right }
                                   return (8...14).contains(t) ? .soft(s.tapped(t - 10)) : .soft("Tap each gap.")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["gaps": 1])

        // the record, as school writes it: x × 10^k = [ ], typed; the web's slips, said of the digits (they moved, the
        // point didn't)
        let write = LessonStep(StepWords(say: "Write the new number.", hint: "Write the number the chart shows.", action: "Check"),
            answer: AnswerTask(prompt: [.num(x), .op("×"), .num(m), .op("="), .box("x")], expected: ["x": ans],
                               known: [(["x": r6(ans / 10)], "Move every digit one place for each zero."),
                                       (["x": r6(ans * 10)], "Move every digit one place for each zero, no more."),
                                       (["x": r6(x / m)], "Multiplying by \(M) makes the number bigger, so the digits move left.")],
                               hint: "Write the number the chart shows.", explain: "The chart shows \(A).",
                               check: { v in
                                   guard let t = v["x"] else { return .soft("Fill in every box.") }
                                   return abs(t - ans) < 1e-9 ? .right : .wrong("That’s not the number on the chart.")
                               }),
            picture: ["at": 3], onMiss: ["read": 1])

        // the answer is in the record, the rule under it; the last words say why
        let done = LessonStep(StepWords(say: "Each zero moves every digit one place bigger.",
                                        hint: "Each zero moves every digit one place bigger.", action: "Next problem"),
                              picture: ["at": 4])
        return [ask, drag] + (gaps.isEmpty ? [] : [zeros]) + [write, done]
    }
}
