import Foundation

/// Comparing decimals (5.NBT.3, design/grade5.md "Added 1 Nov 2026"; the preview G approved on 1 Nov 2026 is
/// design/prototype/new5-lessons.html, dCompare). Which is bigger, 0.45 or 0.452?
///
/// Numbers: a and b, the two numbers in thousandths (the whole part included: 3.45 is 3450), and la and lb, how many
/// decimals each is written with (1 to 3, the last never 0). They share their whole part and first differ in place d
/// (1 tenths, 2 hundredths, 3 thousandths). The shorter number is often the bigger one (0.5 and 0.49), the trap school
/// sets.
///
/// On the paper: Rounding decimals' zoom lines. Line 1 is the whole they're in, in ten blocks of a tenth. 1. The child
/// taps the block both numbers are in (its number is their shared digit); it opens below into ten blocks of the next
/// place, until they fall in different blocks; then taps the block each one is in (one shaded, one striped, named over
/// it). 2. The record stacks them with their points lined up, the place where they differ ringed, and the child taps
/// < or >. The last words say why.
///
/// Picture keys: "st", the stage (0 the question, 1 tap the block they share, 2 tap each one's block, 3 tap < or >, 4
/// done), and "lv", the line being tapped (0 the tenths' line). After a miss, "ring" (the place being looked at ringed
/// in the stacked numbers).
public enum CompareDecimals {
    public static func numbers(a: Int, la: Int, b: Int, lb: Int) -> Numbers {
        ["a": Double(a), "la": Double(la), "b": Double(b), "lb": Double(lb)]
    }

    /// The places, by line: line 0's blocks are tenths.
    public static let names = ["tenth", "hundredth", "thousandth"]
    /// "1 tenth", "4 tenths".
    static func count(_ k: Int, _ j: Int) -> String { "\(k) \(names[j])\(k == 1 ? "" : "s")" }

    /// The worked parts of a problem, all from its numbers.
    public struct Parts: Sendable {
        /// The two numbers in thousandths, and how many decimals each is written with.
        public let NA, NB, la, lb: Int
        public init(_ n: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((n[k] ?? Double(v)).rounded()) }
            NA = max(0, i("a", 500)); NB = max(0, i("b", 490))
            la = min(3, max(1, i("la", 1))); lb = min(3, max(1, i("lb", 2)))
        }
        /// Thousandths in a block of line j's place (line 0: a whole; its blocks are tenths).
        public static func size(_ j: Int) -> Int { [1000, 100, 10, 1][min(3, max(0, j))] }
        /// The whole part they share.
        public var whole: Int { NA / 1000 }
        /// Each one's digit in a place (0 tenths, 1 hundredths, 2 thousandths).
        public func digitA(_ i: Int) -> Int { (NA / Self.size(i + 1)) % 10 }
        public func digitB(_ i: Int) -> Int { (NB / Self.size(i + 1)) % 10 }
        /// The place where they first differ: 1 tenths, 2 hundredths, 3 thousandths.
        public var d: Int { ((0..<3).first { digitA($0) != digitB($0) } ?? 2) + 1 }
        /// The numbers as they're written ("0.45", "3.452").
        public var As: String { RoundDecimals.written(Double(NA) / 1000, la) }
        public var Bs: String { RoundDecimals.written(Double(NB) / 1000, lb) }
        public var aBigger: Bool { NA > NB }
        public var big: String { aBigger ? As : Bs }
        public var small: String { aBigger ? Bs : As }
        /// The sign between them, a then b.
        public var sign: String { aBigger ? ">" : "<" }
        /// The bigger one is written with fewer digits (0.5 > 0.49).
        public var fewer: Bool { big.count < small.count }
        /// Line j's start: the whole (line 0), the tenth (line 1), the hundredth (line 2) they're both in.
        public func lo(_ j: Int) -> Int { NA / Self.size(j) * Self.size(j) }
        /// Line j's ends, as they're written under it ("0" and "1", "0.4" and "0.5").
        public func lineEnds(_ j: Int) -> (String, String) {
            (fmt(Double(lo(j)) / 1000), fmt(Double(lo(j) + Self.size(j)) / 1000))
        }
        /// Block `bl` of line j: its ends ("0.4" and "0.41").
        public func ends(_ j: Int, _ bl: Int) -> (String, String) {
            let s = Self.size(j + 1)
            return (fmt(Double(lo(j) + bl * s) / 1000), fmt(Double(lo(j) + (bl + 1) * s) / 1000))
        }
        /// The last words: what they share, the place that decides, and the trap when it's there.
        public var why: String {
            var shared: [String] = []
            if whole > 0 { shared.append("\(whole) whole\(whole > 1 ? "s" : "")") }
            for j in 0..<(d - 1) { shared.append(CompareDecimals.count(digitA(j), j)) }
            let dB = max(digitA(d - 1), digitB(d - 1)), dS = min(digitA(d - 1), digitB(d - 1)), pl = names[d - 1]
            let head = shared.isEmpty ? "" : "Both have " + shared.joined(separator: " and ") + ". "
            return head + "\(dB) \(pl)\(dB == 1 ? " is" : "s are") more than \(dS)." + (fewer ? " Fewer digits, still bigger." : "")
        }
    }

    /// Two numbers as the preview makes them: the whole part 0 three times in four (else 1 to 9), the place they first
    /// differ in tenths, hundredths or thousandths, and two times in three the shorter one is the bigger (0.5 and 0.49).
    static func make(_ rng: inout SeededRandom) -> Numbers {
        while true {
            let w = Int.random(in: 0...3, using: &rng) == 0 ? Int.random(in: 1...9, using: &rng) : 0
            let d = Int.random(in: 1...3, using: &rng)
            let A = (0..<3).map { _ in Int.random(in: 0...9, using: &rng) }
            var B = A
            repeat { B[d - 1] = Int.random(in: 0...9, using: &rng) } while B[d - 1] == A[d - 1]
            for j in d..<3 { B[j] = Int.random(in: 0...9, using: &rng) }
            // the trap school sets: the shorter number is often the bigger one
            let bigA = A[d - 1] > B[d - 1]
            let la = d < 3 && Int.random(in: 0...2, using: &rng) != 0 ? (bigA ? d : Int.random(in: (d + 1)...3, using: &rng)) : Int.random(in: d...3, using: &rng)
            let lb = d < 3 && Int.random(in: 0...2, using: &rng) != 0 ? (bigA ? Int.random(in: (d + 1)...3, using: &rng) : d) : Int.random(in: d...3, using: &rng)
            // a number never ends in 0 (0.40 is written 0.4)
            if A[la - 1] == 0 || B[lb - 1] == 0 { continue }
            func value(_ D: [Int], _ l: Int) -> Int { w * 1000 + (0..<l).reduce(0) { $0 + D[$1] * [100, 10, 1][$1] } }
            let NA = value(A, la), NB = value(B, lb)
            if NA != NB { return numbers(a: NA, la: la, b: NB, lb: lb) }
        }
    }

    public static let spec = LessonSpec(id: "g5-compare", title: "Comparing decimals", master: "number-line", generate: { rng, _ in make(&rng) },
    display: { n in let p = Parts(n); return [.num(Double(p.NA) / 1000), .text("or"), .num(Double(p.NB) / 1000)] },
    idea: { _ in "Look place by place from the left. The first place that’s different decides." },
    depends: ["g4-dec", "g4-placevalue"],
    check: [CheckItem(3, when: { Parts($0).d == 1 }), CheckItem(3, when: { Parts($0).d == 2 }),
            CheckItem(3, when: { Parts($0).d == 3 }), CheckItem(3, when: { Parts($0).fewer })]) { n in
        let p = Parts(n), d = p.d, As = p.As, Bs = p.Bs, pl = names[d - 1]
        let dA = p.digitA(d - 1), dB = p.digitB(d - 1)
        let question = "Which is bigger, \(As) or \(Bs)?"

        // the two numbers are written once, stacked beside the line: the words only ask
        let ask = LessonStep(StepWords(say: question, hint: "Look place by place from the left.", action: "Let’s find out"),
                             picture: ["st": 0, "lv": 0])

        // tap the block both numbers are in: it opens below into ten blocks of the next place
        let same: [LessonStep] = (0..<(d - 1)).map { j in
            let digit = p.digitA(j), (lo, hi) = p.ends(j, digit)
            return LessonStep(StepWords(say: "\(question) Tap the \(names[j]) they’re both in.",
                                        hint: "Both have \(digit) in the \(names[j])s place.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(digit)],
                                   hint: "Both have \(digit) in the \(names[j])s place.",
                                   explain: "Both are between \(lo) and \(hi).",
                                   check: { v in
                                       guard let x = v["x"], x >= 0, x <= 9 else { return .soft("Tap the \(names[j]) they’re both in.") }
                                       let bl = Int(x.rounded())
                                       if bl == digit { return .right }
                                       let (a, b) = p.ends(j, bl)
                                       return .wrong("They aren’t between \(a) and \(b).")
                                   }, byHand: true),
                picture: ["st": 1, "lv": Double(j)], onMiss: ["ring": 1])
        }

        // tap the block each one is in: one shaded, one striped, each named over its block
        let (aLo, aHi) = p.ends(d - 1, dA), (bLo, bHi) = p.ends(d - 1, dB)
        let split = LessonStep(StepWords(say: d == 1 ? "\(question) Tap the tenth each one is in." : "Tap the \(pl) each one is in. Their \(names[d - 2])s match, so look closer.",
                                         hint: "\(As) has \(count(dA, d - 1)). \(Bs) has \(count(dB, d - 1)).", action: "Check"),
            answer: AnswerTask(prompt: [.box("a"), .box("b")], expected: ["a": Double(dA), "b": Double(dB)],
                               hint: "\(As) has \(count(dA, d - 1)). \(Bs) has \(count(dB, d - 1)).",
                               explain: "\(As) is between \(aLo) and \(aHi). \(Bs) is between \(bLo) and \(bHi).",
                               check: { v in
                                   guard let a = v["a"], let b = v["b"] else { return .soft("Tap the \(pl) each one is in.") }
                                   let ia = Int(a.rounded()), ib = Int(b.rounded())
                                   if ia == dA && ib == dB { return .right }
                                   // a block that holds neither: the tap sets both boxes to it
                                   let bl = ia != dA ? ia : ib
                                   let (lo, hi) = p.ends(d - 1, min(9, max(0, bl)))
                                   return .wrong("Neither number is between \(lo) and \(hi).")
                               }, byHand: true),
            picture: ["st": 2, "lv": Double(d - 1)], onMiss: ["ring": 1])

        // tap < or >: the open mouth faces the bigger one
        let want: Double = p.aBigger ? 1 : 0
        let sign = LessonStep(StepWords(say: "Which is bigger? Tap < or >.", hint: "The open mouth faces the bigger one.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(p.NA) / 1000), .box("s"), .num(Double(p.NB) / 1000)], expected: ["s": want],
                               hint: "The open mouth faces the bigger one.", explain: "\(As) \(p.sign) \(Bs). \(p.big) is bigger.",
                               check: { v in
                                   guard let s = v["s"], s == 0 || s == 1 else { return .soft("Tap < or >.") }
                                   if s == want { return .right }
                                   return .wrong("Look at the \(pl)s: \(dA) and \(dB). The open mouth faces the bigger one.")
                               }, byHand: true),
            picture: ["st": 3, "lv": Double(d - 1)])

        // the sign is written; the last words say why
        let done = LessonStep(StepWords(say: "\(p.big) is bigger. \(p.why)",
                                        hint: "Look place by place from the left. The first place that’s different decides.",
                                        action: "Next problem"),
                              picture: ["st": 4, "lv": Double(d - 1)])
        return [ask] + same + [split, sign, done]
    }
}
