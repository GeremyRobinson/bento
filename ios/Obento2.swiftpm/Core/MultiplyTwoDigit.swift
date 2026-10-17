import Foundation

/// Multiply two-digit numbers (the web app's g5-mult2): split the second factor into tens and ones,
/// multiply the first factor by each part, then add the parts back together.
/// Numbers: a (the first factor, down the side) and b (the second factor, across the top, the one that is split).
///
/// Picture master: "area-model" (web `explanations/diagrams/area-model`). A rectangle a tall and b wide,
/// cut across the top into one strip per place-value part of b (biggest first), each strip a tall and part wide.
/// Picture keys:
/// - `split`: 1 = the top side is cut into its parts (30 | 6), each strip labelled with its part; 0 = one whole rectangle.
/// - `strip`: the strip being worked on this step, lit up, counted from 1 (1 = the tens strip); 0 = none lit.
/// - `found`: how many strips, from the left, already have their product written inside them.
/// - `sum`: 1 = every strip shows its product and the total is shown with the rectangle (all strips together).
/// - `look` (onMiss only): 1 = after a miss with no named slip, point at the lit strip(s) again, with the step's `look` words.
/// Per step: ask {split 1, strip 0, found 0} · partial i {split 1, strip i+1, found i} · sum {split 1, found parts, sum 1}
/// · done {split 1, found parts, sum 1}.
public enum MultiplyTwoDigit {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }

    private static let placeNames = ["ones", "tens", "hundreds", "thousands", "ten thousands", "hundred thousands"]
    private static let countWords = ["", "one", "two", "three", "four"]

    /// 36 → [30, 6]; 305 → [300, 5]. Biggest place first, zero places left out.
    public static func parts(_ n: Int) -> [Int] {
        let digits = String(n).compactMap { $0.wholeNumberValue }
        return digits.enumerated().map { i, d in d * Int(pow(10, Double(digits.count - 1 - i))) }.filter { $0 != 0 }
    }
    /// 30 → "tens", 6 → "ones".
    public static func placeName(_ part: Int) -> String {
        let zeros = String(part).count - 1
        return zeros < placeNames.count ? placeNames[zeros] : "10^\(zeros)"
    }
    private static func leadingDigit(_ part: Int) -> Int { String(part).first?.wholeNumberValue ?? 0 }
    private static func plusChain(_ values: [Int]) -> MathLine {
        values.enumerated().flatMap { i, v in i == 0 ? [Math.num(Double(v))] : [.op("+"), .num(Double(v))] }
    }
    private static func countWord(_ n: Int) -> String { n < countWords.count ? countWords[n] : String(n) }

    public static let spec = LessonSpec(id: "g5-mult2", title: "Multiply two-digit numbers", master: "area-model", generate: { rng, index in
        // the web generator: both factors 12–98, the second never a multiple of ten; the first three friendlier (12–39 × 12–29)
        let early = index < 3
        var second: Int
        repeat { second = Int.random(in: 12...(early ? 29 : 98), using: &rng) } while second % 10 == 0
        return numbers(a: Int.random(in: 12...(early ? 39 : 98), using: &rng), b: second)
    }, display: { n in [.num(n["a"] ?? 0), .op("×"), .num(n["b"] ?? 0)] },
    idea: { _ in "Splitting one number into tens and ones turns one hard multiplication into two easy ones, added back together." },
    story: { n in "A theater has \(fmt(n["a"] ?? 0)) rows. Each row has \(fmt(n["b"] ?? 0)) seats. How many seats are there?" },
    storyOp: { _ in "×" },
    depends: ["g4-mult2x2", "g3-mult10"],
    check: [CheckItem(3), CheckItem(3), CheckItem(3, when: { Int($0["b"] ?? 0) % 10 >= 6 }), CheckItem(3, story: true)]) { n in
        let a = Int(n["a"] ?? 0), b = Int(n["b"] ?? 0)
        let ps = parts(b), products = ps.map { a * $0 }, product = products.reduce(0, +), many = ps.count > 1
        let A = fmt(Double(a)), B = fmt(Double(b))

        // the split is not an answer step on the web; its narration invites the child to look at the cut picture
        let ask = LessonStep(StepWords(say: "What is \(A) × \(B)?",
                                       hint: many ? "Split \(B) into tens and ones." : "\(B) has only one part, so there's nothing to split.",
                                       action: "Let’s find out"),
                             picture: ["split": 1, "strip": 0, "found": 0])

        let partials: [LessonStep] = ps.enumerated().map { i, part in
            let expected = products[i], zeros = String(part).count - 1, digit = leadingDigit(part)
            let P = fmt(Double(part)), Z = zeros == 1 ? "a zero" : "\(zeros) zeros"
            let hint = zeros == 0 ? "\(A) × \(P)." : "Do \(A) × \(fmt(Double(digit))), then add \(Z)."
            // a ones part of 1 has no adding slip to name (a + 1 is also the off-by-one try)
            let known: [(values: [String: Double], message: String)] = zeros == 0
                ? (part == 1 ? [] : [(["x": Double(a + part)], "This part is \(A) times \(P), not plus.")])
                : [(["x": Double(a * digit)], "That's \(A) × \(fmt(Double(digit))). The \(placeName(part)) digit stands for \(P), so add \(Z).")]
            return LessonStep(StepWords(say: "Multiply by the \(placeName(part))", hint: "The \(placeName(part)) strip is \(A) tall and \(P) wide.", action: "Check"),
                              answer: AnswerTask(prompt: [.num(Double(a)), .op("×"), .num(Double(part)), .op("="), .box("x")], expected: ["x": Double(expected)],
                                                 known: known, hint: hint, explain: "\(hint) That makes \(fmt(Double(expected)))."),
                              picture: ["split": 1, "strip": Double(i + 1), "found": Double(i)], onMiss: ["look": 1],
                              look: "Look again at the lit-up strip: it's \(P) wide and \(A) tall.")
        }

        var steps = [ask] + partials
        if many {
            let hint = ps.count == 2 ? "Add the two partial products." : "Add the partial products."
            // the commonest slip: a part left out; not where the place-value or off-by-one tries land, and no repeats
            var seen: Set<Int> = []
            let known: [(values: [String: Double], message: String)] = products.compactMap { x in
                let v = product - x
                guard v != product + 1, !ps.contains(where: { v == a * leadingDigit($0) }), seen.insert(v).inserted else { return nil }
                return (["x": Double(v)], "Add every part: \(products.map { fmt(Double($0)) }.joined(separator: " + ")).")
            }
            steps.append(LessonStep(StepWords(say: "Add the parts", hint: "Add the strips to fill the whole rectangle.", action: "Check"),
                                    answer: AnswerTask(prompt: plusChain(products) + [.op("="), .box("x")], expected: ["x": Double(product)],
                                                       known: known, hint: hint, explain: "\(hint) That makes \(fmt(Double(product)))."),
                                    picture: ["split": 1, "strip": 0, "found": Double(ps.count), "sum": 1], onMiss: ["look": 1],
                                    look: "Look again: add \(ps.count == 2 ? "both strips" : "every strip") in the picture."))
        }
        steps.append(LessonStep(StepWords(say: many ? "The \(countWord(ps.count)) strips make \(fmt(Double(product)))." : "\(A) × \(B) = \(fmt(Double(product))).",
                                          hint: many ? "Add the strips to fill the whole rectangle." : "The \(placeName(b)) strip is \(A) tall and \(B) wide.",
                                          action: "Next problem"),
                                picture: ["split": 1, "strip": 0, "found": Double(ps.count), "sum": 1]))
        return steps
    }
}
