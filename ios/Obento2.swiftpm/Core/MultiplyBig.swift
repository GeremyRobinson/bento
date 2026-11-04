import Foundation

/// Multiply big numbers (the web app's g4-partial, 4.NBT.5; design/grade4.md chapter 2, the preview grade4-ch2.html):
/// n × m, n of three digits (or four, the fold) and m of one. The web's maths: its generator (the first three friendlier,
/// never a whole number of hundreds), its partial products and its slips, and its story (crayons in boxes).
///
/// On the paper: the place chart with the number's columns, its disks in one plain row across the top (a row is one
/// copy). Drag the handle down: the row copies a row at a time, so each column becomes an array of its place. Then each
/// place lights and its part is written (its multiplication beside it, as school writes partial products), biggest
/// first; then the parts are added.
///
/// Every step's picture has "at": 0 the question, 1 copy, 2 a place's part ("p" the place), 3 the sum, 4 done.
public enum MultiplyBig {
    public static func numbers(n: Int, m: Int) -> Numbers { ["n": Double(n), "m": Double(m)] }
    public static let zeros = ["", "a zero", "two zeros", "three zeros"]

    public struct Parts: Sendable {
        public let n: Int, m: Int
        public init(_ x: Numbers) { n = Int((x["n"] ?? 112).rounded()); m = Int((x["m"] ?? 2).rounded()) }
        /// Its digits (3 or 4).
        public var D: Int { BigNumbers.length(n) }
        public func digit(_ p: Int) -> Int { BigNumbers.digit(n, p) }
        /// Place p's part: its digit's worth times m.
        public func part(_ p: Int) -> Int { digit(p) * BigNumbers.pow10(p) * m }
        public var total: Int { n * m }
        /// The places from the biggest down.
        public var order: [Int] { Array((0..<D).reversed()) }
        public var story: String { "A box holds \(BigNumbers.commas(n)) crayons. How many crayons are in \(m) boxes?" }
        /// What the copies let go at `rows` say (nil: right).
        public func copied(_ rows: Int) -> String? { rows == m ? nil : "That’s \(rows) rows. \(BigNumbers.commas(n)) × \(m) needs \(m)." }
        /// "7 rows of 3 hundreds", or "There are no tens, so this part is 0."
        public func rowsOf(_ p: Int) -> String {
            let d = digit(p)
            return d == 0 ? "There are no \(BigNumbers.places[p]), so this part is 0." : "\(m) rows of \(d) \(BigNumbers.place(p, d))."
        }
    }

    /// The web's generator, with the preview's fold: index < 3 n 112–399 and m 2–5, then n 112–989 and m 3–9, never a whole
    /// number of hundreds; from index 6, one time in three a four-digit n (never whole hundreds) with m 3–9.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        if index >= 6 && Int.random(in: 0...2, using: &rng) == 0 {
            var n = 0
            repeat { n = Int.random(in: 1012...9989, using: &rng) } while n % 100 == 0
            return numbers(n: n, m: Int.random(in: 3...9, using: &rng))
        }
        let (lo, hi) = index < 3 ? (112, 399) : (112, 989)
        let m = index < 3 ? Int.random(in: 2...5, using: &rng) : Int.random(in: 3...9, using: &rng)
        var n = 0
        repeat { n = Int.random(in: lo...hi, using: &rng) } while n % 100 == 0
        return numbers(n: n, m: m)
    }

    public static let spec = LessonSpec(id: "g4-partial", title: "Multiply big numbers", master: "place-chart",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text(BigNumbers.commas(s.n)), .op("×"), .num(Double(s.m))] },
        idea: { _ in "A big number is its hundreds, tens and ones, so each part can be multiplied on its own." },
        story: { x in Parts(x).story },
        storyOp: { _ in "×" },
        depends: ["g3-split", "g3-mult10"],
        check: [CheckItem(6, when: { Parts($0).n >= 1000 }), CheckItem(3, when: { Parts($0).digit(1) == 0 }),
                CheckItem(3, when: { Parts($0).m >= 6 }), CheckItem(3, story: true)]) { x in
        let s = Parts(x), m = s.m, N = BigNumbers.commas(s.n)
        var steps = [LessonStep(StepWords(say: "Make \(m) rows of \(N).", hint: "Each row is one copy.", action: "Let’s find out"), picture: ["at": 0])]
        // copy the row down: the box is how many rows it was let go at
        steps.append(LessonStep(StepWords(say: "Make \(m) rows. Drag the handle down. Each row is one copy.", hint: "A row for each time.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(m)], hint: "A row for each time.", explain: "\(m) rows of \(N).",
                               check: { v in
                                   guard let r = v["x"] else { return .soft("Drag the handle down.") }
                                   return s.copied(Int(r.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1]))
        // each place's part, biggest first, with the web's slips
        for p in s.order {
            let d = s.digit(p), want = s.part(p), worth = d * BigNumbers.pow10(p)
            var slips: [(Double, String)] = []
            if p > 0 && d > 0 { slips.append((Double(d * m), "That’s \(d) × \(m). The \(d) stands for \(BigNumbers.commas(worth)), so put \(MultiplyBig.zeros[p]) on the end.")) }
            if p == 0 { slips.append((Double(d + m), "This one is times, not plus.")) }
            let generic = d == 0 ? "There are no \(BigNumbers.places[p]), so this part is 0." : "\(m * d) \(BigNumbers.place(p, m * d)) is written \(BigNumbers.commas(want))."
            let hint = d == 0 ? "There are no \(BigNumbers.places[p]), so this part is 0."
                : p == 0 ? "\(d) group\(d == 1 ? "" : "s") of \(m)." : "Do \(d) × \(m), then add \(MultiplyBig.zeros[p])."
            steps.append(LessonStep(StepWords(say: "Write the \(BigNumbers.places[p]). \(s.rowsOf(p))", hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.num(Double(worth)), .op("×"), .num(Double(m)), .op("="), .box("x")], expected: ["x": Double(want)],
                                   known: BigNumbers.slips(Double(want), slips), hint: hint,
                                   explain: "\(BigNumbers.commas(worth)) × \(m) = \(BigNumbers.commas(want)).",
                                   check: { v in Int((v["x"] ?? -1).rounded()) == want ? .right : .wrong(generic) },
                                   incomplete: "Type the number in the box."),
                picture: ["at": 2, "p": Double(p)]))
        }
        // the parts added
        let parts = s.order.map { s.part($0) }
        let two = s.part(s.D - 1) + s.part(s.D - 2)
        let sumSlips: [(Double, String)] = s.digit(0) != 0 ? [(Double(two), "Add all \(s.D == 3 ? "three" : "four") parts.")] : []
        steps.append(LessonStep(StepWords(say: "Add every place’s part.", hint: "Line them up by place and add.", action: "Check"),
            answer: AnswerTask(prompt: parts.enumerated().flatMap { i, v in (i > 0 ? [Math.op("+")] : []) + [.num(Double(v))] } + [.op("="), .box("x")],
                               expected: ["x": Double(s.total)], known: BigNumbers.slips(Double(s.total), sumSlips), hint: "Line them up by place and add.",
                               explain: parts.map { BigNumbers.commas($0) }.joined(separator: " + ") + " = \(BigNumbers.commas(s.total)).",
                               check: { v in Int((v["x"] ?? -1).rounded()) == s.total ? .right : .wrong("Line them up by place and add.") },
                               incomplete: "Type the number in the box."),
            picture: ["at": 3]))
        steps.append(LessonStep(StepWords(say: "\(m) rows of every place make \(BigNumbers.commas(s.total)).",
                                          hint: "A big number is its hundreds, tens and ones, so each part can be multiplied on its own.", action: "Next problem"),
                                picture: ["at": 4]))
        return steps
    }
}
