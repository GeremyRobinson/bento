import Foundation

/// Tens, hundreds, thousands (g4-tentimes, 4.NBT.1; design/grade4.md, the preview design/prototype/grade4-ch1.html).
/// A count c of a place p (10, 100 or 1,000). Two kinds take turns: A asks how many p's make c × p (340 is how many
/// tens?), B what number c p's make (52 hundreds is what number?).
///
/// On the paper: the place chart with the columns the problem needs, a disk one of its column's place. A: tap each disk
/// of the next place up: it opens into a full frame of ten in its column, and the count runs on; then write the count.
/// B: tap each full frame of ten: it closes into one disk of the next place up and slides left; then write the number.
///
/// Every step's picture has "at": 0 the question, 1 the move (open or close), 2 write it, 3 done.
public enum TensHundreds {
    public static func numbers(kind: Int, p: Int, c: Int) -> Numbers { ["kind": Double(kind), "p": Double(p), "c": Double(c)] }

    public struct Parts: Sendable {
        /// 0: A (how many p's), 1: B (what number).
        public let kind: Int, p: Int, c: Int
        public var a: Bool { kind == 0 }
        /// The place p counts in (1 tens, 2 hundreds, 3 thousands).
        public var q: Int { BigNumbers.log10(p) }
        public var N: Int { c * p }
        /// The full tens of the count and what's left: 34 tens are 3 hundreds and 4 tens.
        public var h: Int { c / 10 }
        public var r: Int { c % 10 }
        /// The number written in the box.
        public var answer: Int { a ? c : N }
        /// The chart's columns: the place, the one up, and every one under them.
        public var columns: Int { q + 2 }
        /// "ten", or "10" for the thousands (ten thousands making a ten thousand would read as the place).
        public var ten: String { q == 3 ? "10" : "ten" }
        public var name: String { BigNumbers.places[q] }
        public var up: String { BigNumbers.places[q + 1] }
        public var up1: String { BigNumbers.place1[q + 1] }
        public init(_ n: Numbers) {
            kind = Int((n["kind"] ?? 0).rounded()); p = Int((n["p"] ?? 10).rounded()); c = Int((n["c"] ?? 11).rounded())
        }
        /// The question.
        public var question: String { a ? "How many \(name) make \(BigNumbers.commas(N))?" : "What number is \(c) \(name)?" }
        /// The last words: why.
        public var why: String { a ? "A \(up1) is \(ten) \(name)." : "\(BigNumbers.cap(ten)) \(name) make a \(up1)." }
    }

    /// The preview's generator: A and B take turns; the first three count tens (11 to 39), then hundreds or thousands
    /// (11 to 99); one time in five the count is a whole ten (300 is 30 tens).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let kind = index % 2, whole = Int.random(in: 0...4, using: &rng) == 0
        if index < 3 { return numbers(kind: kind, p: 10, c: whole ? 10 * Int.random(in: 2...3, using: &rng) : Int.random(in: 11...39, using: &rng)) }
        let p = Bool.random(using: &rng) ? 100 : 1000
        return numbers(kind: kind, p: p, c: whole ? 10 * Int.random(in: 2...9, using: &rng) : Int.random(in: 11...99, using: &rng))
    }

    public static let spec = LessonSpec(id: "g4-tentimes", title: "Tens, hundreds, thousands", master: "place-chart",
        generate: { rng, index in make(&rng, index) },
        display: { n in
            let s = Parts(n)
            return s.a ? [.text(BigNumbers.commas(s.N)), .op("="), .text("?"), .text(s.name)] : [.text("\(s.c)"), .text(s.name), .op("="), .text("?")]
        },
        idea: { _ in "Ten of a place make one of the next place up." },
        depends: ["g3-mult10", "g3-addsub"],
        check: [CheckItem(0), CheckItem(1), CheckItem(4, when: { Parts($0).p == 100 }), CheckItem(5, when: { Parts($0).p == 1000 })]) { n in
        let s = Parts(n), h = s.h
        let ask = LessonStep(StepWords(say: s.question, hint: s.a ? "Each \(s.up1) opens into \(s.ten) \(s.name)." : "\(BigNumbers.cap(s.ten)) \(s.name) make a \(s.up1).",
                                       action: "Let’s find out"), picture: ["at": 0])

        // A: open each disk of the place up (its count is the box); B: close each full frame (how many closed)
        let move: LessonStep
        if s.a {
            move = LessonStep(StepWords(say: "\(s.question) Tap each \(s.up1).", hint: "Each \(s.up1) opens into \(s.ten) \(s.name).", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(h)], hint: "Each \(s.up1) opens into \(s.ten) \(s.name).",
                                   explain: "\(h) \(BigNumbers.place(s.q + 1, h)) open into \(h * 10) \(s.name).",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft("Tap each \(s.up1).") }
                                       if Int(x.rounded()) == h { return .right }
                                       if x < 0 { return .wrong("Count \(s.name): open the \(s.up).") }
                                       return .soft("Tap each \(s.up1).")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        } else {
            move = LessonStep(StepWords(say: "\(s.question) Tap each full ten.", hint: "\(BigNumbers.cap(s.ten)) \(s.name) make a \(s.up1).", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(h)], hint: "\(BigNumbers.cap(s.ten)) \(s.name) make a \(s.up1).",
                                   explain: "\(h) full ten\(h == 1 ? "" : "s") close into \(h) \(BigNumbers.place(s.q + 1, h)).",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft("Tap each full ten.") }
                                       if Int(x.rounded()) == h { return .right }
                                       if x < 0 { return .wrong("That frame has \(Int(-x)). Only a full ten closes.") }
                                       return .soft("Tap each full ten.")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        }

        // write it: the count (A) or the number (B), with the web's slips
        let ans = Double(s.answer)
        let known: [(values: [String: Double], message: String)]
        let generic: String
        if s.a {
            known = BigNumbers.slips(ans, [
                (Double(s.r), "The \(h) \(BigNumbers.place(s.q + 1, h)) \(h == 1 ? "is" : "are") \(h * 10) \(s.name) more."),
                (Double(h), "That’s the \(s.up)."),
                (Double(s.N), "That’s ones."),
            ])
            generic = "Count the \(s.name): each full frame is ten."
        } else {
            known = BigNumbers.slips(ans, [(Double(s.c), "That’s how many \(s.name). Write the number.")]
                + (s.q > 1 ? [(Double(s.N / 10), "That’s \(s.c) \(BigNumbers.places[s.q - 1]).")] : [])
                + [(Double(s.N * 10), "That’s \(s.c) \(s.up).")])
            generic = "Read the chart: a digit for every place, a 0 where it’s empty."
        }
        let write = LessonStep(StepWords(say: s.a ? "Write how many \(s.name)." : "Write the number.",
                                         hint: s.a ? "Each full frame is ten." : "An empty place gets a 0.", action: "Check"),
            answer: AnswerTask(prompt: s.a ? [.text(BigNumbers.commas(s.N)), .op("="), .box("x"), .text(s.name)] : [.text("\(s.c)"), .text(s.name), .op("="), .box("x")],
                               expected: ["x": ans], known: known, hint: s.a ? "Each full frame is ten." : "An empty place gets a 0.",
                               explain: s.a ? "\(BigNumbers.commas(s.N)) is \(s.c) \(s.name)." : "\(s.c) \(s.name) is \(BigNumbers.commas(s.N)).",
                               check: { v in Int((v["x"] ?? -1).rounded()) == s.answer ? .right : .wrong(generic) }),
            picture: ["at": 2])

        let done = LessonStep(StepWords(say: s.why, hint: "Ten of a place make one of the next place up.", action: "Next problem"), picture: ["at": 3])
        return [ask, move, write, done]
    }
}
