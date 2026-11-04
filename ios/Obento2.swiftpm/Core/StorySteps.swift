import Foundation

/// Story problems in steps (g4-multistep, 4.OA.3; new; design/grade4.md chapter 2, the preview grade4-ch2.html): 3rd
/// grade's two-step stories with 4th grade numbers, a letter for the unknown and a rounded estimate. Three kinds: groups
/// then take away (a × b − c), groups then more (a × b + c), take away then share ((a − c) ÷ b).
///
/// On the paper: one square is ten. The story's bar model, each bar dragged to the nearest ten, so the picture is the
/// estimate: groups with a part taken off the end (the dashed rest is n), groups with a part joined on (n the whole), or
/// a part taken off and the rest cut into b equal parts (n one part). Then the two written steps.
///
/// Every step's picture has "at": 0 the question, 1 round the bars, 2 the first step, 3 the second, 4 done.
public enum StorySteps {
    /// kind 0 take away, 1 more, 2 share; `theme` picks the story's things.
    public static func numbers(kind: Int, a: Int, b: Int, c: Int, theme: Int = 0) -> Numbers {
        ["kind": Double(kind), "a": Double(a), "b": Double(b), "c": Double(c), "theme": Double(theme)]
    }
    /// To the nearest ten, halfway up.
    public static func round10(_ x: Int) -> Int { (x + 5) / 10 * 10 }

    public struct Parts: Sendable {
        public let kind: Int, a: Int, b: Int, c: Int, theme: Int
        public init(_ x: Numbers) {
            kind = Int((x["kind"] ?? 0).rounded()); a = Int((x["a"] ?? 3).rounded()); b = Int((x["b"] ?? 12).rounded())
            c = Int((x["c"] ?? 15).rounded()); theme = Int((x["theme"] ?? 0).rounded())
        }
        public var share: Bool { kind == 2 }
        /// The first step's answer, and n.
        public var s1: Int { share ? a - c : a * b }
        public var n: Int { kind == 0 ? a * b - c : kind == 1 ? a * b + c : (a - c) / b }
        /// The amount whose bar is rounded first: a group (b), or the whole when sharing (a).
        public var first: Int { share ? a : b }
        /// The estimate the rounded bars make.
        public var est: Int {
            let R = StorySteps.round10
            if share { return Int((Double(R(a) - R(c)) / Double(b) / 10).rounded()) * 10 }
            return kind == 0 ? a * R(b) - R(c) : a * R(b) + R(c)
        }
        public var story: String {
            switch (kind, theme) {
            case (0, 0): "A store has \(a) crates of \(b) apples. It sells \(c). How many apples are left?"
            case (0, _): "A hall has \(a) rows of \(b) seats. \(c) are full. How many are empty?"
            case (1, 0): "Mia has \(a) packs of \(b) stickers and \(c) more. How many stickers in all?"
            case (1, _): "A shop has \(a) boxes of \(b) cookies and \(c) more. How many cookies in all?"
            case (_, 0): "A baker has \(a) cookies. \(c) are sold. The rest fill \(b) boxes equally. How many in a box?"
            default: "There are \(a) stickers. \(c) are used. The rest go in \(b) equal packs. How many in a pack?"
            }
        }
        /// What a bar let go at `got` (rounded to tens) says, for amount `amt`: nil when it's the nearest ten.
        public func rounded(_ amt: Int, _ got: Int) -> String? {
            let want = StorySteps.round10(amt)
            if got == want { return nil }
            return amt % 10 == 5 && got == want - 10 ? "\(amt) is halfway: halfway rounds up to \(want)." : "\(amt) is nearer \(want) than \(got)."
        }
    }

    /// The preview's generator. Index < 3: take away, then more, then take away (a 3–5, b 12–95, c 15–95); then all three
    /// in turn: b 105–195 with a 2–4 (a × b up to 600), c up to a × b − 100 taken away, a × b + c at most 600 joined on;
    /// sharing: a 200–600, b 3–9, a − c a multiple of b with 12 or more in a part, and the rounded rest (in squares, a
    /// square a ten) a multiple of b, so its parts are whole squares. No amount is a whole ten.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let kind = index < 3 ? index % 2 : index % 3, theme = Int.random(in: 0...1, using: &rng)
        func nt(_ lo: Int, _ hi: Int) -> Int { while true { let v = Int.random(in: lo...max(lo, hi), using: &rng); if v % 10 != 0 { return v } } }
        while true {
            if kind == 2 {
                let b = Int.random(in: 3...9, using: &rng), a = nt(200, 600), c = nt(15, a - 100)
                // the rounded rest shares into whole squares (G 3 Nov: no blank stretch is left)
                if (a - c) % b != 0 || (a - c) / b < 12 || ((round10(a) - round10(c)) / 10) % b != 0 { continue }
                return numbers(kind: 2, a: a, b: b, c: c, theme: theme)
            }
            let a: Int, b: Int, c: Int
            if index < 3 { a = Int.random(in: 3...5, using: &rng); b = nt(12, 95); c = nt(15, 95) }
            else {
                a = Int.random(in: 2...4, using: &rng); b = nt(105, 195)
                if a * b > 600 { continue }
                let room = kind == 0 ? a * b - 100 : 600 - a * b
                if room < 15 { continue }
                c = nt(15, room)
            }
            let n = kind == 0 ? a * b - c : a * b + c
            if kind == 0 && n < 20 { continue }
            if kind == 1 && n > 600 { continue }
            return numbers(kind: kind, a: a, b: b, c: c, theme: theme)
        }
    }

    public static let spec = LessonSpec(id: "g4-multistep", title: "Story problems in steps", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in
            let s = Parts(x)
            if s.share { return [.text("("), .num(Double(s.a)), .op("−"), .num(Double(s.c)), .text(")"), .op("÷"), .num(Double(s.b))] }
            return [.num(Double(s.a)), .op("×"), .num(Double(s.b)), .op(s.kind == 0 ? "−" : "+"), .num(Double(s.c))]
        },
        idea: { _ in "Round every amount first: the estimate tells you if the answer makes sense." },
        depends: ["g3-twostep", "g3-estimate", "g4-partial", "g4-divide", "g4-placevalue"],
        check: [CheckItem(0), CheckItem(1), CheckItem(5), CheckItem(3, when: { Parts($0).b >= 100 })]) { x in
        let s = Parts(x), a = s.a, b = s.b, c = s.c, n = s.n, s1 = s.s1, est = s.est, R = StorySteps.round10
        var steps = [LessonStep(StepWords(say: s.story, hint: "Round each amount to the nearest ten.", action: "Let’s find out"), picture: ["at": 0])]
        // round both bars: the box is 1 once both are; a bar let go at the wrong ten sets 1000 × which (1 the first, 2 c)
        // plus where it was let go, in squares (tens)
        steps.append(LessonStep(StepWords(say: "\(s.story) Drag each bar’s end to the nearest ten.", hint: "Round each amount to the nearest ten.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: "Round each amount to the nearest ten.",
                               explain: "\(s.first) → \(R(s.first)), \(c) → \(R(c)).",
                               check: { v in
                                   let x = Int((v["x"] ?? 0).rounded())
                                   if x == 1 { return .right }
                                   guard x >= 1000 else { return .soft("Drag each bar’s end to the nearest ten.") }
                                   let amt = x / 1000 == 1 ? s.first : c
                                   return .wrong(s.rounded(amt, (x % 1000) * 10) ?? "Drag each bar’s end to the nearest ten.")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1]))
        // the two written steps, with g3-twostep's slips
        let check1 = s.share ? R(a) - R(c) : a * R(b)
        let slips1: [(Double, String)] = s.share ? [(Double(a + c), "\(c) are taken off first. Subtract.")] : [(Double(a + b), "That’s \(a) + \(b). \(a) groups of \(b): multiply.")]
        steps.append(LessonStep(StepWords(say: "Write the first step. " + (s.share ? "The ruler cut the rest into \(b) parts of about \(est)." : "The picture is the estimate."),
                                          hint: "About \(check1).", action: "Check"),
            answer: AnswerTask(prompt: s.share ? [.num(Double(a)), .op("−"), .num(Double(c)), .op("="), .box("x")] : [.num(Double(a)), .op("×"), .num(Double(b)), .op("="), .box("x")],
                               expected: ["x": Double(s1)], known: BigNumbers.slips(Double(s1), slips1), hint: "About \(check1).", explain: "\(s1)",
                               check: { v in Int((v["x"] ?? -1).rounded()) == s1 ? .right : .wrong("Check it: about \(check1).") },
                               incomplete: "Type the number in the box."),
            picture: ["at": 2]))
        let slips2: [(Double, String)] = s.kind == 0 ? [(Double(s1 + c), "The \(c) are taken away. Subtract.")] + (b > c ? [(Double(a * (b - c)), "Take \(c) away once, from all \(s1).")] : [])
            : s.kind == 1 ? [(Double(s1 - c), "The \(c) are joined on. Add.")]
            : [(Double(s1 - b), "Share it into \(b) equal parts: divide."), (Double(s1 * b), "That’s \(b) times as many. Share it: divide.")]
        steps.append(LessonStep(StepWords(say: "Write the second step.", hint: "About \(est).", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s1)), .op(s.kind == 0 ? "−" : s.kind == 1 ? "+" : "÷"), .num(Double(s.share ? b : c)), .op("="), .box("x")],
                               expected: ["x": Double(n)], known: BigNumbers.slips(Double(n), slips2), hint: "About \(est).", explain: "n = \(n)",
                               check: { v in Int((v["x"] ?? -1).rounded()) == n ? .right : .wrong("Check it against the estimate, about \(est).") },
                               incomplete: "Type the number in the box."),
            picture: ["at": 3]))
        steps.append(LessonStep(StepWords(say: "\(n) is close to \(est), so it makes sense.", hint: "Round every amount first: the estimate tells you if the answer makes sense.",
                                          action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}
