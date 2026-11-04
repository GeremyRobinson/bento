import Foundation

/// 1st grade's chapter 4, Adding and taking away tens (design/grade1.md chapter 4, the preview
/// design/prototype/grade1-ch4.html): a number is its tens (closed rows of ten counters, touching) and its ones (a square
/// under them), counters 3 × 3 squares; the second number stands a block to the right, striped. The problem is written
/// once, as the picture's names (a, the sign, b), and the record goes on along that line. Every number is written with the
/// drawn digit pad and Check. Every line is spoken; the preview's grey second line is folded into the instruction.
public enum Tens1 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G1.int(v, k, d) }
    /// "1 ten, 2 tens, 3 tens": a count of tens' readout.
    public static func tensRun(_ k: Int) -> String {
        let s = (1...max(1, k)).map { Num1.pl($0, "ten", "tens") }
        return s.count > 4 ? "\(s[0]), \(s[1]) … \(s[s.count - 1])" : s.joined(separator: ", ")
    }
    public static let writeBox = Num1.writeBox
}

// MARK: - Add tens to a number, Add within 100

/// Add tens to a number (the web's g1-addtens; 1.NBT.4) and Add within 100 (g1-add100, new; 1.NBT.4). a as tens and ones;
/// b beside it, striped. Slide b's tens (as one) onto a's tens: they snap under them and the ones row moves down below.
/// Slide b's ones onto a's ones row (the one grabbed and every one left of it go together): they go in after its ones,
/// counting on; a full row closes into a new ten and joins the tens, and the rest start a new ones row. Then write the
/// record along the names line: 23 + 30 = [53], 36 + 7 = 40 + 3 = [43].
///
/// "at": 0 tens, 1 ones, 2 write, 3 done (a step b hasn't is left out). The tens' box "t": tb once they snap, −1 dropped on
/// the ones, −2 the ones grabbed first. The ones' box "o": bo once they're all in, −1 dropped on the tens.
public enum AddTens1 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, tensOnly: Bool
        public init(_ x: Numbers, tensOnly: Bool) {
            self.tensOnly = tensOnly
            a = max(11, min(89, Tens1.int(x, "a", tensOnly ? 23 : 36)))
            let bb = Tens1.int(x, "b", tensOnly ? 30 : 7)
            b = max(tensOnly ? 10 : 1, min(99 - a, tensOnly ? bb / 10 * 10 : bb))
        }
        public var ta: Int { Num1.tens(a) }
        public var ao: Int { Num1.ones(a) }
        public var tb: Int { Num1.tens(b) }
        public var bo: Int { Num1.ones(b) }
        public var sum: Int { a + b }
        public var T: Int { Num1.tens(sum) }
        public var O: Int { Num1.ones(sum) }
        public var newTen: Bool { ao + bo >= 10 }
        /// The ones that fill a's ones row to a ten, and what's left after.
        public var need: Int { 10 - ao }
        public var left: Int { bo - need }
        /// The number after b's tens have joined: where counting on the ones starts.
        public var base: Int { a + 10 * tb }
        /// The record's middle, 40 + 3 (none when it would only say the problem again, or there are no ones).
        public var split: Bool { !tensOnly && O != 0 && !(10 * T == a && O == b) }
        public var tensWords: String { "\(Num1.pl(ta, "ten", "tens")) and \(Num1.pl(tb, "ten", "tens")): \(ta + tb) tens" }
        public var summary: String {
            if tensOnly { return tensWords }
            if !newTen { return "\(Num1.pl(T, "ten", "tens")) and \(Num1.pl(O, "one", "ones"))" }
            return "\(a) + \(need) = \(10 * (ta + 1))" + (left > 0 ? ", then \(left) more" : ": a new ten")
        }
        public var slips: [(Int, String)] {
            if tensOnly {
                return [(a + tb, "You added \(Num1.pl(tb, "one", "ones")). \(b) is \(Num1.pl(tb, "ten", "tens")), so the tens go up by \(tb)."),
                        (10 * T, "Don't forget the \(Num1.pl(ao, "one", "ones")) from \(a)."),
                        (T + ao, "\(Num1.pl(T, "ten", "tens")) is \(10 * T). Then the \(Num1.pl(ao, "one", "ones")).")]
            }
            if tb > 0 {
                return [(10 * (ta + bo) + ao + tb, "Tens go with tens: \(Num1.pl(ta, "ten", "tens")) and \(Num1.pl(tb, "ten", "tens"))."),
                        (ta + tb + ao + bo, "Each ten is worth 10, not 1."), (sum - 1, "Count on again."), (sum + 1, "Count on again.")]
            }
            return (newTen ? [(sum - 10, "The \(ao) and \(bo) ones made a new ten.")] : [])
                + [(10 * (ta + bo) + ao, "\(bo) is ones. It goes with the \(ao > 0 ? Num1.pl(ao, "one", "ones") : "ones")."),
                   (ta + ao + bo, "Each ten is worth 10, not 1."), (sum - 1, "Count on again."), (sum + 1, "Count on again.")]
        }
        public var other: String { "\(Num1.pl(T, "ten", "tens")) and \(Num1.pl(O, "one", "ones"))." }
        public func tensMissed(_ code: Int) -> String { code == -2 ? "Tens first: slide the tens onto the tens." : "Tens go with the tens." }
        public static let onesMissed = "Ones go with the ones."
        public var tensSay: String { tensOnly ? "Slide the new tens onto the tens." : "Slide the tens onto the tens." }
        public static let onesSay = "Slide the ones onto the ones."
        public var why: String {
            if tensOnly { return "Tens join the tens, so the ones stay the same." }
            return newTen ? "Ones go with ones, and ten ones make a new ten." : "Ones go with ones, and tens go with tens."
        }
    }

    /// The web's: tens 1–4 and 2–3 new tens for the first three; then tens 1–8 and 1 to 9 − tens new tens; ones 1–9.
    static func makeTens(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let t = Int.random(in: 1...(i < 3 ? 4 : 8), using: &rng), n = t * 10 + Int.random(in: 1...9, using: &rng)
        let k = Int.random(in: (i < 3 ? 2 : 1)...min(i < 3 ? 3 : 9, 9 - t), using: &rng)
        return numbers(a: n, b: 10 * k)
    }
    /// New (grade1.md): the first three 21–79 and 2–9 with no new ten; the next three make a new ten; from the 7th, one in
    /// three is two two-digit numbers 11–69 whose ones make no new ten (sum 99 or less), the rest either one-digit kind.
    static func make100(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 6 && (i - 6) % 3 == 0 {
            var a = 0, b = 0
            repeat { a = Int.random(in: 11...69, using: &rng); b = Int.random(in: 11...69, using: &rng) } while a % 10 + b % 10 > 9 || a + b > 99
            return numbers(a: a, b: b)
        }
        let kind = i < 3 ? 0 : i < 6 ? 1 : Int.random(in: 0...1, using: &rng)
        var a = 0
        if kind == 0 {
            repeat { a = Int.random(in: 21...79, using: &rng) } while a % 10 > 7
            return numbers(a: a, b: Int.random(in: 2...(9 - a % 10), using: &rng))
        }
        repeat { a = Int.random(in: 21...79, using: &rng) } while a % 10 == 0
        return numbers(a: a, b: Int.random(in: max(2, 10 - a % 10)...9, using: &rng))
    }

    static func steps(_ P: Parts) -> [LessonStep] {
        let tensHint = "Slide them under the tens."
        let tens = LessonStep(StepWords(say: P.tensSay, hint: tensHint, action: "Check"),
            answer: TeensK.hand("t", P.tb, hint: tensHint, explain: P.tensWords + ".", said: P.tensMissed),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let onesHint = "Slide them after the ones."
        let ones = LessonStep(StepWords(say: Parts.onesSay, hint: onesHint, action: "Check"),
            answer: TeensK.hand("o", P.bo, hint: onesHint, explain: P.summary + ".", said: { _ in Parts.onesMissed }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: Tens1.writeBox, hint: P.other, action: "Check"),
            answer: Num1.write("x", P.sum, P.slips, other: P.other, hint: P.other, explain: "\(P.a) + \(P.b) = \(P.sum)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return (P.tb > 0 ? [tens] : []) + (P.bo > 0 ? [ones] : []) + [write, done]
    }

    public static let spec = LessonSpec(id: "g1-addtens", title: "Add tens to a number", master: "bars",
        generate: { rng, i in makeTens(&rng, i) },
        display: { x in let P = Parts(x, tensOnly: true); return [.num(Double(P.a)), .op("+"), .num(Double(P.b)), .op("="), .box("q")] },
        idea: { _ in "Tens join the tens, so the ones stay the same." },
        depends: ["g1-tensones", "g1-tenmore"],
        check: [CheckItem(0), CheckItem(3), CheckItem(4, when: { Parts($0, tensOnly: true).ta >= 5 }), CheckItem(5, when: { Parts($0, tensOnly: true).tb == 1 })]) { x in
        steps(Parts(x, tensOnly: true))
    }

    public static let spec100 = LessonSpec(id: "g1-add100", title: "Add within 100", master: "bars",
        generate: { rng, i in make100(&rng, i) },
        display: { x in let P = Parts(x, tensOnly: false); return [.num(Double(P.a)), .op("+"), .num(Double(P.b)), .op("="), .box("q")] },
        idea: { _ in "Ones go with ones, and ten ones make a new ten." },
        depends: ["g1-addtens", "g1-ten"],
        check: [CheckItem(0), CheckItem(3), CheckItem(3, when: { Parts($0, tensOnly: false).left == 0 }), CheckItem(6)]) { x in
        steps(Parts(x, tensOnly: false))
    }
}

// MARK: - Take away tens

/// Take away tens (g1-subtens, new; 1.NBT.6). a as tens rows (10–90), − b over the place they go. Slide tens away to the
/// right, one row at a time: each lands in the pile (a dashed place shows where) and is crossed out; the rows left close
/// up. Then tap the rows left to count them (sliding one more away: it slides back). Then write the record along the names
/// line: 70 − 30 = [40].
///
/// "at": 0 take, 1 count (none left: left out), 2 write, 3 done. The take's box "k": B once they're taken. The count's box
/// "c": the rows left once all are tapped, −1 one more slid away.
public enum SubTens1 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let A: Int, B: Int
        public init(_ x: Numbers) {
            A = max(1, min(9, Tens1.int(x, "a", 70) / 10))
            B = max(1, min(A, Tens1.int(x, "b", 30) / 10))
        }
        public var a: Int { 10 * A }
        public var b: Int { 10 * B }
        public var L: Int { A - B }
        public var res: Int { a - b }
        public var slips: [(Int, String)] {
            [(L, "That's \(Num1.pl(L, "ten", "tens")). \(Num1.pl(L, "ten", "tens")) is written \(res)."),
             (a - B, "\(b) is \(Num1.pl(B, "ten", "tens")), not \(Num1.pl(B, "one", "ones"))."), (a + b, "That's adding.")]
        }
        public static let other = "Count the tens that are left."
        public var tooMany: String { "That's \(Num1.pl(B + 1, "ten", "tens")). Take \(B)." }
        public static let takeSay = "Slide the tens away, one at a time."
        public static let countSay = "Tap the tens that are left."
        public var why: String { "It's \(A) − \(B), but in tens." }
    }
    /// New (grade1.md): the first three a 40–90 and b 10–30; then a 20–90 and b 10 to a (sometimes all of it: 0 left).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let A = i < 3 ? Int.random(in: 4...9, using: &rng) : Int.random(in: 2...9, using: &rng)
        let B = i < 3 ? Int.random(in: 1...3, using: &rng) : Int.random(in: 1...A, using: &rng)
        return numbers(a: 10 * A, b: 10 * B)
    }

    public static let spec = LessonSpec(id: "g1-subtens", title: "Take away tens", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("−"), .num(Double(P.b)), .op("="), .box("q")] },
        idea: { _ in "It's 7 − 3, but in tens." },
        depends: ["g1-addtens", "g1-tenmore"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).L == 0 }), CheckItem(3, when: { Parts($0).L == 1 }), CheckItem(4)]) { x in
        let P = Parts(x)
        let takeHint = "Slide a ten to the dashed place."
        let take = LessonStep(StepWords(say: Parts.takeSay, hint: takeHint, action: "Check"),
            answer: TeensK.hand("k", P.B, hint: takeHint, explain: "Take \(Num1.pl(P.B, "ten", "tens")).", said: { _ in Parts.takeSay }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let countHint = "Tap each row that's left."
        let count = LessonStep(StepWords(say: Parts.countSay, hint: countHint, action: "Check"),
            answer: TeensK.hand("c", P.L, hint: countHint, explain: "\(Num1.pl(P.L, "ten", "tens")) left.", said: { _ in P.tooMany }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: Tens1.writeBox, hint: Parts.other, action: "Check"),
            answer: Num1.write("x", P.res, P.slips, other: Parts.other, hint: Parts.other, explain: "\(P.a) − \(P.b) = \(P.res)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return P.L > 0 ? [take, count, write, done] : [take, write, done]
    }
}
