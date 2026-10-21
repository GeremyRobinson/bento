import Foundation

/// Multiply two-digit numbers (the web app's g5-mult2): split the second factor into tens and ones,
/// multiply the first factor by each part, then add the parts back together.
/// Numbers: a (the first factor, down the side) and b (the second factor, across the top, the one that is split).
///
/// On the paper (design/grade5.md, approved 19 Oct, now with a hand move): the rectangle a squares tall and b wide,
/// one square for each one (a seat, in the story), every ten bold, named by its sides. The child drags a cut along its
/// top to where the tens end and presses Cut (that answers the split, 36 = 30 + 6: its box is set from the cut); the
/// strips part a square. Then each strip lights and its squares are written in the record, the column working as
/// school writes it (47 × 36, each strip's product, the total), each typed where it goes.
///
/// Picture keys: "at", the stage: 0 the question (the whole rectangle, its sides named), 1 the cut (a handle on its
/// top edge), 2 the tens strip lit (its row of the record to write), 3 the ones strip, 4 both strips (the total to
/// write), 5 done. A hint (after a miss, or asked for) lights "tens" (the cut: every ten across the top counted) or
/// "look" (a strip: its multiplication written on it; the total: the whole rectangle outlined).
/// A second factor with one part (none is generated) has no cut: its one strip is the whole rectangle.
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

    /// The cut the child makes across the top, at column `x` of a rectangle `b` wide, measured on the grid: right where
    /// the tens end; a part that isn't all tens, or tens left over on the right (counted, as its bold lines show them),
    /// said in plain words.
    static func cut(_ x: Double?, b: Int) -> Verdict {
        guard let x, x > 0, x < Double(b) else { return .soft("Drag the cut to where the tens end first.") }
        let c = Int(x.rounded()), T = b - b % 10
        if c == T { return .right }
        if c % 10 != 0 { return .wrong("\(c) has \(c % 10) one\(c % 10 == 1 ? "" : "s") in it. Cut on a bold line.") }
        // on a bold line short of where the tens end (none is past it): the part on the right still has tens in it
        let left = (T - c) / 10
        return .wrong("\(b - c) still has \(left == 1 ? "a ten" : "\(left) tens") in it. Cut where the tens end.")
    }

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
        // tens and ones (every problem the generator makes): the cut splits them on the paper
        let cuts = ps.count == 2

        // the problem is written once, as the rectangle's own names (its side and its top, G 20 Oct): the first words
        // ask about the picture, not the sum again
        let ask = LessonStep(StepWords(say: "How many squares in the rectangle?",
                                       hint: many ? "Split \(B) into tens and ones." : "\(B) has only one part, so there's nothing to split.",
                                       action: "Let’s find out"),
                             picture: ["at": 0])

        // the cut: dragged along the top, snapping to the squares, the two widths written over it as it moves; Cut puts
        // where it is in the box (the split, 36 = 30 + 6), and what a cut in the wrong place makes is said
        var cutting: [LessonStep] = []
        if cuts {
            let T = ps[0], O = ps[1]
            cutting = [LessonStep(StepWords(say: "Drag the cut to where the tens end.", hint: "The bold lines are the tens. Cut at the last one.", action: "Cut"),
                              answer: AnswerTask(prompt: [.num(Double(b)), .op("="), .box("x"), .op("+"), .num(Double(O))], expected: ["x": Double(T)],
                                                 hint: "Cut at the last bold line: \(B) is \(T / 10) ten\(T == 10 ? "" : "s") and \(O).",
                                                 explain: "\(B) is \(T) and \(O): the tens end at \(T).",
                                                 check: { v in MultiplyTwoDigit.cut(v["x"], b: b) }, byHand: true),
                              picture: ["at": 1], onMiss: ["tens": 1])]
        }

        // each strip lights, and its squares are written in its row of the record (the web's steps, its slips and its
        // words for them)
        let partials: [LessonStep] = ps.enumerated().map { i, part in
            let expected = products[i], zeros = String(part).count - 1, digit = leadingDigit(part)
            let P = fmt(Double(part)), Z = zeros == 1 ? "a zero" : "\(zeros) zeros", name = placeName(part)
            let hint = zeros == 0 ? "\(A) × \(P)." : "Do \(A) × \(fmt(Double(digit))), then add \(Z)."
            // a ones part of 1 has no adding slip to name (a + 1 is also the off-by-one try)
            let known: [(values: [String: Double], message: String)] = zeros == 0
                ? (part == 1 ? [] : [(["x": Double(a + part)], "This part is \(A) times \(P), not plus.")])
                : [(["x": Double(a * digit)], "That's \(A) × \(fmt(Double(digit))). The \(placeName(part)) digit stands for \(P), so add \(Z).")]
            return LessonStep(StepWords(say: many ? "How many squares in the \(name) strip? Write it." : "How many squares in all? Write it.",
                                        hint: "The \(name) strip is \(A) tall and \(P) wide.", action: "Check"),
                              answer: AnswerTask(prompt: [.num(Double(a)), .op("×"), .num(Double(part)), .op("="), .box("x")], expected: ["x": Double(expected)],
                                                 known: known, hint: hint, explain: "\(hint) That makes \(fmt(Double(expected)))."),
                              picture: ["at": Double(cuts ? 2 + i : 2)], onMiss: ["look": 1],
                              look: "Look again at the lit-up strip: it's \(P) wide and \(A) tall.")
        }

        var steps = [ask] + cutting + partials
        if many {
            let hint = ps.count == 2 ? "Add the two partial products." : "Add the partial products."
            // the commonest slip: a part left out; not where the place-value or off-by-one tries land, and no repeats
            var seen: Set<Int> = []
            let known: [(values: [String: Double], message: String)] = products.compactMap { x in
                let v = product - x
                guard v != product + 1, !ps.contains(where: { v == a * leadingDigit($0) }), seen.insert(v).inserted else { return nil }
                return (["x": Double(v)], "Add every part: \(products.map { fmt(Double($0)) }.joined(separator: " + ")).")
            }
            steps.append(LessonStep(StepWords(say: "How many squares in all? Write it.", hint: "Add the strips to fill the whole rectangle.", action: "Check"),
                                    answer: AnswerTask(prompt: plusChain(products) + [.op("="), .box("x")], expected: ["x": Double(product)],
                                                       known: known, hint: hint, explain: "\(hint) That makes \(fmt(Double(product)))."),
                                    picture: ["at": 4], onMiss: ["look": 1],
                                    look: "Look again: add \(ps.count == 2 ? "both strips" : "every strip") in the picture."))
        }
        // the answer is in the record, in the chapter's colour; the last words say why the strips add up to it
        let why = many ? "The \(countWord(ps.count)) strips make the whole rectangle." : "\(A) × \(B) = \(fmt(Double(product)))."
        steps.append(LessonStep(StepWords(say: why, hint: many ? "Add the strips to fill the whole rectangle." : "The \(placeName(b)) strip is \(A) tall and \(B) wide.",
                                          action: "Next problem"),
                                picture: ["at": 5]))
        return steps
    }
}
