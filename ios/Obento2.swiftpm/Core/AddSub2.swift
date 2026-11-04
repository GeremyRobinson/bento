import Foundation

/// What 2nd grade's chapter 1, Adding and subtracting to 100, shares (design/grade2.md chapter 1, the preview
/// design/prototype/grade2-ch1.html): the problems' numbers, their slips and lines word for word. Every number the child
/// writes is typed with the iPad's keys and Check, as the preview types; the hands do the rest on the picture.
public enum G2 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// "1 ten", "8 tens".
    public static func count(_ n: Int, _ one: String, _ many: String? = nil) -> String { "\(n) \(n == 1 ? one : many ?? one + "s")" }
    public static func tens(_ n: Int) -> Int { n / 10 }
    public static func ones(_ n: Int) -> Int { n % 10 }
    public static let write = "Write the answer."
    public static let names: [(String, String)] = [("Maya", "she"), ("Leo", "he"), ("Ana", "she"), ("Sam", "he")]
    public static let things = ["stickers", "books", "shells", "marbles", "cards"]
    static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// A number typed into box `box`: right when it's `want`, else the first slip that matches, or the plain line.
    static func typed(_ box: String, _ want: Int, _ slips: [(Int, String)], plain: String, hint: String, explain: String) -> AnswerTask {
        var seen: Set<Int> = []
        let list = slips.filter { $0.0 != want && $0.0 >= 0 && seen.insert($0.0).inserted }
        return AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], known: list.map { ([box: Double($0.0)], $0.1) },
                          hint: hint, explain: explain,
                          check: { v in
                              guard let x = v[box] else { return .soft("Write the number.") }
                              let k = Int(x.rounded())
                              return k == want ? .right : .wrong(list.first { $0.0 == k }?.1 ?? plain)
                          }, incomplete: "Write the number.")
    }
    /// A step answered by a code its hand move puts in the box: right when it's `want`, else what `said` says.
    static func hand(_ box: String, _ want: Int, hint: String, explain: String, said: @escaping @Sendable (Int) -> String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], hint: hint, explain: explain,
                   check: { v in let x = Int((v[box] ?? -99).rounded()); return x == want ? .right : .wrong(said(x)) }, byHand: true)
    }
    /// A story's pick: + Add or − Take away (2nd grade's only two).
    static func pick(_ say: String, add: Bool, wrong: String) -> LessonStep {
        LessonStep(StepWords(say: say, hint: wrong, action: "Check"),
                   answer: AnswerTask(prompt: [.box("c")], expected: ["c": add ? 0 : 1], hint: wrong, explain: add ? "Put them together: add." : "Take them away.",
                                      check: { v in v["c"] == (add ? 0 : 1) ? .right : .wrong(wrong) }, choices: ["+ Add", "− Take away"]),
                   picture: ["at": -1])
    }
}

// MARK: - Facts to 20

/// Facts to 20 (g2-facts, new; 2.OA.B.2). The two rows of ten places (1st grade's), the fact's counters in them; the record
/// `8 + 7 = [ ]` live from the start. The line names the way that suits the fact: make a ten (slide counters up into the top
/// row's empty places), pair them up (slide the bottom row under the top), or back to 10 (slide counters off the end), "or just
/// write it". Once the hands have found it the record writes the way (`8 + 7 = 10 + 5 = [ ]`); a right answer written straight
/// away plays its way on the picture (See).
///
/// "kind" 0 make a ten, 1 pair them up, 2 back to 10; "a", "b" the fact's numbers (back: a − b). "at": 0 write, 1 done.
public enum Facts2 {
    public enum Kind: Int, Sendable { case ten, pairs, back }
    public static func numbers(a: Int, b: Int, back: Bool = false) -> Numbers {
        ["a": Double(a), "b": Double(b), "kind": Double(back ? 2 : abs(a - b) <= 1 ? 1 : 0)]
    }
    public struct Parts: Sendable {
        public let kind: Kind, a: Int, b: Int
        public init(_ x: Numbers) {
            kind = Kind(rawValue: G2.int(x, "kind")) ?? .ten
            if kind == .back { a = max(11, min(18, G2.int(x, "a", 15))); b = max(a - 9, min(9, G2.int(x, "b", 8))) }
            else { a = max(2, min(9, G2.int(x, "a", 8))); b = max(2, min(9, G2.int(x, "b", 7))) }
        }
        public var ans: Int { kind == .back ? a - b : a + b }
        public var big: Int { max(a, b) }
        public var small: Int { min(a, b) }
        /// Back to 10: the ones over ten (what's taken first).
        public var ro: Int { a - 10 }
        public var double: Bool { kind == .pairs && a == b }
        public var sign: String { kind == .back ? "−" : "+" }
        /// The record's middle once the hands have found it: 10 + 5, 6 + 6 + 1, 10 − 3 (a double has none).
        public var way: [String] {
            switch kind {
            case .ten: return ["10", "+", "\(small - (10 - big))"]
            case .pairs: return a == b ? [] : ["\(small)", "+", "\(small)", "+", "1"]
            case .back: return ["10", "−", "\(b - ro)"]
            }
        }
        public var say: String {
            switch kind {
            case .ten: return "Make a ten, or just write it."
            case .pairs: return "Pair them up, or just write it."
            case .back: return "Take \(b) away, or just write it."
            }
        }
        public var why: String {
            switch kind {
            case .ten: return "Make a ten, and the rest is easy."
            case .back: return "Back to 10 first, then the rest."
            case .pairs: return a == b ? "The same number twice." : "A double and one more."
            }
        }
        public var plain: String {
            switch kind {
            case .ten: return "Make a ten first: \(big) and \(10 - big)."
            case .pairs: return a == b ? "Double \(a) is \(a) and \(a) more." : "Pair them up: double \(small), then 1 more."
            case .back: return "Back to 10 takes \(ro). Then \(b - ro) more."
            }
        }
        public var slips: [(Int, String)] {
            switch kind {
            case .ten:
                let l = "\(big) and \(10 - big) make 10, then \(ans - 10) more."
                return [(ans - 1, l), (ans + 1, l), (big - small, "That's taking away.")]
            case .pairs where a != b:
                return [(2 * small, "That's double \(small). \(big) is one more."), (2 * big, "That's double \(big). \(small) is one less."), (1, "That's taking away.")]
            case .pairs:
                let l = "A double is the same number twice: \(a) and \(a) more."
                return [(ans - 1, l), (ans + 1, l), (a, "That's one \(a). Double \(a) is \(a) and \(a)."), (0, "That's taking away.")]
            case .back:
                return [(a + b, "That's adding."), (b, "\(b) is what you take. What's left?"), (ans - 1, plain), (ans + 1, plain)]
            }
        }
        /// What the hands' move finds, as the readout leaves it (10 + 5, 6 + 6 + 1).
        public var found: String { kind == .pairs && a == b ? "\(a) + \(a)" : way.joined(separator: " ") }
    }

    /// The preview's: an 8 or 9 with 3–6; a near double (5–8 and one more); a double 6–9; from 3 any two of 2–9 that cross
    /// ten, and from 5 every third a take-away.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        switch i {
        case 0: return numbers(a: Int.random(in: 8...9, using: &rng), b: Int.random(in: 3...6, using: &rng))
        case 1:
            let lo = Int.random(in: 5...8, using: &rng)
            return Bool.random(using: &rng) ? numbers(a: lo, b: lo + 1) : numbers(a: lo + 1, b: lo)
        case 2: let d = Int.random(in: 6...9, using: &rng); return numbers(a: d, b: d)
        default:
            var a = 0, b = 0
            repeat { a = Int.random(in: 2...9, using: &rng); b = Int.random(in: 2...9, using: &rng) } while a + b < 11
            if i >= 5 && (i - 5) % 3 == 0 { return numbers(a: a + b, b: b, back: true) }
            return numbers(a: a, b: b)
        }
    }

    public static let spec = LessonSpec(id: "g2-facts", title: "Facts to 20", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op(P.sign), .num(Double(P.b)), .op("="), .box("x")] },
        idea: { _ in "Make a ten, and the rest is easy." },
        depends: ["g1-ten", "g1-doubles", "g1-sub20", "g1-related"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).kind != .back && Parts($0).ans >= 15 }), CheckItem(5),
                CheckItem(6, when: { Parts($0).kind == .pairs && Parts($0).a != Parts($0).b })]) { x in
        let P = Parts(x)
        let write = LessonStep(StepWords(say: P.say, hint: P.plain, action: "Check"),
            answer: G2.typed("x", P.ans, P.slips, plain: P.plain, hint: P.plain, explain: "\(P.a) \(P.sign) \(P.b) = \(P.ans)."),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [write, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 1])]
    }
}

// MARK: - Tens and ones: adding and subtracting with regrouping, and up to four numbers

/// Adding with regrouping (the web's g2-regroup; 2.NBT.B.5, 2.NBT.B.9). a at the left as ten rows and a ones row (tinted), b
/// at the right the same (striped), the column form beside them. Slide b's ones onto a's ("Slide the ones together."); tap the
/// full row: it closes into one ten and joins the tens, the small 1 over the tens; slide b's tens under them; write the sum.
/// The story kind (every fourth) picks + Add or − Take away first.
///
/// "at": −1 pick, 0 ones, 1 group, 2 tens, 3 write, 4 done. Boxes: "o" the ones (O; −1 dropped on the tens, −2 the tens
/// grabbed first), "g" the full row (1; −1 the short row), "t" the tens (bt; −1 dropped on the ones), "x" the sum.
public enum Regroup2 {
    public static func numbers(a: Int, b: Int, story: Bool = false) -> Numbers { ["a": Double(a), "b": Double(b), "story": story ? 1 : 0] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, story: Bool
        public init(_ x: Numbers) {
            a = max(11, min(89, G2.int(x, "a", 47))); b = max(1, min(99 - a, G2.int(x, "b", 38))); story = G2.int(x, "story") != 0
        }
        public var at: Int { G2.tens(a) }
        public var ao: Int { G2.ones(a) }
        public var bt: Int { G2.tens(b) }
        public var bo: Int { G2.ones(b) }
        public var O: Int { ao + bo }
        public var left: Int { O - 10 }
        public var T: Int { at + bt + 1 }
        public var sum: Int { a + b }
        public var lines: [String] { ["A class read \(a) books in May and \(b) books in June.", "How many books did they read in all?"] }
        public var slips: [(Int, String)] { [((at + bt) * 10 + left, "The new ten goes with the tens too: \(G2.count(T, "ten")), not \(at + bt).")] }
        public static let plain = "Count the tens, then the ones."
        public static let why = "10 ones make 1 ten, so it joins the tens."
        public func ones(_ code: Int) -> String { code == -2 ? "Start with the ones." : "Ones go with the ones." }
        public var short: String { "That's \(left). A ten needs 10." }
    }
    /// The web's: both 15–79, ones making 10 or more, the sum 99 or less; problems 0–2 both 11–49, the ones making 10–12 and
    /// the tens 6 or fewer. Every fourth is the story.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3
        var a = 0, b = 0
        repeat { a = Int.random(in: (early ? 11 : 15)...(early ? 49 : 79), using: &rng); b = Int.random(in: (early ? 11 : 15)...(early ? 49 : 79), using: &rng) }
        while !(a % 10 + b % 10 >= 10 && a + b <= 99 && (!early || (a % 10 + b % 10 <= 12 && a / 10 + b / 10 <= 6)))
        return numbers(a: a, b: b, story: i % 4 == 3)
    }

    public static let spec = LessonSpec(id: "g2-regroup", title: "Adding with regrouping", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("+"), .num(Double(P.b)), .op("="), .box("x")] },
        idea: { _ in Parts.why },
        depends: ["g1-addtens", "g1-add20"],
        check: [CheckItem(0), CheckItem(4, when: { Parts($0).left == 0 }), CheckItem(5), CheckItem(3)]) { x in
        let P = Parts(x)
        let onesHint = "Slide them after the ones."
        let ones = LessonStep(StepWords(say: "Slide the ones together.", hint: onesHint, action: "Check"),
            answer: G2.hand("o", P.O, hint: onesHint, explain: "\(P.ao) + \(P.bo) = \(P.O).", said: { P.ones($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let group = LessonStep(StepWords(say: "Make a ten: tap the full row.", hint: "Tap the row of 10.", action: "Check"),
            answer: G2.hand("g", 1, hint: "Tap the row of 10.", explain: "\(P.O) = 10 + \(P.left).", said: { _ in P.short }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let tensHint = "Slide them under the tens."
        let tens = LessonStep(StepWords(say: "Slide the tens together.", hint: tensHint, action: "Check"),
            answer: G2.hand("t", P.bt, hint: tensHint, explain: "\(P.at) + \(P.bt) + 1 = \(G2.count(P.T, "ten")).", said: { _ in "Tens go with the tens." }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: G2.write, hint: Parts.plain, action: "Check"),
            answer: G2.typed("x", P.sum, P.slips, plain: Parts.plain, hint: Parts.plain, explain: "\(P.a) + \(P.b) = \(P.sum)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return (P.story ? [G2.pick("Pick what to do.", add: true, wrong: "They read books in both months. Put them together.")] : []) + [ones, group, tens, write, done]
    }
}

/// Subtracting with regrouping (the web's g2-subregroup; 2.NBT.B.5, 2.NBT.B.9). a at the left as ten rows and a ones row;
/// b at the right drawn dashed, its ones row level with a's. As the problem draws, b's dashed ones slide over a's by
/// themselves, hang past the end and slide back: not enough ones. Tap a ten: it opens into a loose row of ten over the ones
/// (the 5 crossed with 4 over it, the 2 made 12); slide the dashed ones over the ones (each covered one crossed); slide the
/// dashed tens over ten rows; write what's left. The story kind (every fourth) picks + Add or − Take away first.
///
/// "at": −1 pick, 0 open, 1 ones, 2 tens, 3 write, 4 done. Boxes: "k" the ten opened (1; −1 the ones tapped), "o" the ones
/// (1; −1 dropped on the tens, −2 the tens grabbed first), "t" the tens (1; −1 dropped on the ones), "x" the answer.
public enum SubRegroup2 {
    public static func numbers(a: Int, b: Int, story: Bool = false) -> Numbers { ["a": Double(a), "b": Double(b), "story": story ? 1 : 0] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, story: Bool
        public init(_ x: Numbers) {
            a = max(30, min(98, G2.int(x, "a", 52))); story = G2.int(x, "story") != 0
            let bb = G2.int(x, "b", 27)
            b = max(11, min((G2.tens(a) - 1) * 10 + 9, bb))
        }
        public var at: Int { G2.tens(a) }
        public var ao: Int { G2.ones(a) }
        public var bt: Int { G2.tens(b) }
        public var bo: Int { G2.ones(b) }
        /// The ones once a ten is opened, what's left of them, and the tens left.
        public var O: Int { ao + 10 }
        public var onesLeft: Int { O - bo }
        public var tensLeft: Int { at - 1 - bt }
        public var diff: Int { a - b }
        public var lines: [String] { ["There were \(a) stickers on a sheet. Maya used \(b) of them.", "How many stickers are left?"] }
        public var open: String { ao > 0 ? "Not enough ones. Open a ten." : "No ones. Open a ten." }
        public var slips: [(Int, String)] {
            [((at - bt) * 10 + (bo - ao), "You did \(bo) − \(ao) in the ones. You can't take \(bo) from \(ao), so trade a ten first."),
             ((at - bt) * 10 + onesLeft, "You traded a ten, so there is one ten less: \(at - 1) − \(bt) = \(tensLeft)."),
             (tensLeft + onesLeft * 10, "Tens go on the left: \(G2.count(tensLeft, "ten")) and \(G2.count(onesLeft, "one")).")]
        }
        public static let plain = "Count the tens and the ones that are left."
        public static let why = "A ten is 10 ones, so now there are enough."
        public func ones(_ code: Int) -> String { code == -2 ? "Start with the ones." : "Ones go over ones." }
    }
    /// The web's: a's tens 3–9 and ones 0–8, fewer ones than b's; b's tens 1 to one less than a's (two less in problems 0–2,
    /// so a ten is left). Every fourth is the story.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let at = Int.random(in: 3...9, using: &rng), ao = Int.random(in: 0...8, using: &rng), bo = Int.random(in: (ao + 1)...9, using: &rng)
        let bt = Int.random(in: 1...(at - (i < 3 ? 2 : 1)), using: &rng)
        return numbers(a: at * 10 + ao, b: bt * 10 + bo, story: i % 4 == 3)
    }

    public static let spec = LessonSpec(id: "g2-subregroup", title: "Subtracting with regrouping", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("−"), .num(Double(P.b)), .op("="), .box("x")] },
        idea: { _ in Parts.why },
        depends: ["g2-regroup", "g1-sub20"],
        check: [CheckItem(4, when: { Parts($0).ao == 0 }), CheckItem(5, when: { Parts($0).diff < 10 }), CheckItem(6), CheckItem(3)]) { x in
        let P = Parts(x)
        let openHint = "Tap one of the ten rows."
        let open = LessonStep(StepWords(say: P.open, hint: openHint, action: "Check"),
            answer: G2.hand("k", 1, hint: openHint, explain: "10 + \(P.ao) = \(P.O) ones.", said: { _ in "Tap a ten to open it." }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let onesHint = "Slide them over the ones."
        let ones = LessonStep(StepWords(say: "Take \(P.bo) ones.", hint: onesHint, action: "Check"),
            answer: G2.hand("o", 1, hint: onesHint, explain: "\(P.O) − \(P.bo) = \(P.onesLeft).", said: { P.ones($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let tensHint = "Slide them over the ten rows."
        let tens = LessonStep(StepWords(say: "Take \(G2.count(P.bt, "ten")).", hint: tensHint, action: "Check"),
            answer: G2.hand("t", 1, hint: tensHint, explain: "\(P.at - 1) − \(P.bt) = \(G2.count(P.tensLeft, "ten")).", said: { _ in "Tens go over tens." }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: G2.write, hint: Parts.plain, action: "Check"),
            answer: G2.typed("x", P.diff, P.slips, plain: Parts.plain, hint: Parts.plain, explain: "\(P.a) − \(P.b) = \(P.diff)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return (P.story ? [G2.pick("Pick what to do.", add: false, wrong: "Maya used some. Take them away.")] : []) + [open, ones, tens, write, done]
    }
}

/// Add up to four numbers (g2-addfour, new; 2.NBT.B.6, 2.NBT.B.9). The first number at the left, where the total builds; the
/// others in a column at the right, each its ten rows and ones row. Slide every number's ones over, in any order (holding a
/// ones row lights another whose ones make 10 with it); tap each full row (it joins the tens, a small 1 or 2 over the tens);
/// slide the others' tens over; write the sum.
///
/// "n0"… "n3" the numbers ("n" how many). "at": 0 ones, 1 group, 2 tens, 3 write, 4 done. Boxes: "o" the ones (their total once
/// every row is over; −1 dropped on the tens, −2 tens grabbed first), "g" the full rows (G once all are tapped; −1 a short row),
/// "t" the tens (n − 1 once every number's are over; −1 dropped on the ones), "x" the sum. Kept: "s1"… which ones rows are
/// over, "u1"… which tens, "G" the new tens made.
public enum AddFour2 {
    public static func numbers(_ nums: [Int]) -> Numbers {
        var out: Numbers = ["n": Double(nums.count)]
        for (k, v) in nums.enumerated() { out["n\(k)"] = Double(v) }
        return out
    }
    public struct Parts: Sendable {
        public let nums: [Int]
        public init(_ x: Numbers) {
            let n = max(3, min(4, G2.int(x, "n", 3)))
            nums = (0..<n).map { max(11, min(39, G2.int(x, "n\($0)", [27, 34, 16, 12][$0]))) }
        }
        public var n: Int { nums.count }
        public var o: [Int] { nums.map(G2.ones) }
        public var t: [Int] { nums.map(G2.tens) }
        public var O: Int { o.reduce(0, +) }
        public var G: Int { O / 10 }
        public var sum: Int { nums.reduce(0, +) }
        /// The others with ones to slide over.
        public var withOnes: [Int] { (1..<n).filter { o[$0] > 0 } }
        public var slips: [(Int, String)] {
            (G == 2 ? [(sum - 10, "The ones made 2 tens."), (sum - 20, "The ones made 2 tens.")] : [(sum - 10, "The new ten goes with the tens.")])
                + nums.map { (sum - $0, "Add every number. There are \(n).") }
        }
        public static let plain = "Count the tens, then the ones."
        public static let why = "Ones with ones, tens with tens, in any order."
        public var groupSay: String { G > 1 ? "Tap each full row." : "Make a ten: tap the full row." }
        public func ones(_ code: Int) -> String { code == -2 ? "Start with the ones." : "Ones go with the ones." }
        public static func short(_ k: Int) -> String { "That's \(k). A ten needs 10." }
        public var record: String { nums.map(String.init).joined(separator: " + ") }
    }
    /// New (grade2.md): three numbers 11–39, or four 11–29; the sum 30–99, the ones 10 or more. Problems 0–2 three numbers, two
    /// of whose ones make 10, the ones 10–19 and the tens 6 or fewer; from 3 four on even problems, three on odd ones, the ones up
    /// to 29.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        while true {
            let n = i < 3 ? 3 : i % 2 == 0 ? 4 : 3, hi = n == 4 ? 29 : 39
            let nums = (0..<n).map { _ in Int.random(in: 11...hi, using: &rng) }
            let o = nums.map { $0 % 10 }, O = o.reduce(0, +), T = nums.map { $0 / 10 }.reduce(0, +), sum = nums.reduce(0, +)
            if O < 10 || sum < 30 || sum > 99 { continue }
            if i < 3 {
                let pair = o.indices.contains { j in o.indices.contains { k in k > j && o[j] + o[k] == 10 } }
                if !pair || O > 19 || T > 6 { continue }
            } else if O > 29 { continue }
            return numbers(nums)
        }
    }

    public static let spec = LessonSpec(id: "g2-addfour", title: "Add up to four numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in
            let P = Parts(x)
            return P.nums.enumerated().flatMap { k, v -> [Math] in k == 0 ? [.num(Double(v))] : [.op("+"), .num(Double(v))] } + [.op("="), .box("x")]
        },
        idea: { _ in Parts.why },
        depends: ["g2-regroup", "g1-three"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).O >= 20 }), CheckItem(4), CheckItem(5)]) { x in
        let P = Parts(x)
        let onesHint = "Slide each ones row after the ones."
        let ones = LessonStep(StepWords(say: "Slide all the ones over.", hint: onesHint, action: "Check"),
            answer: G2.hand("o", P.O, hint: onesHint, explain: "\(P.o.filter { $0 > 0 }.map(String.init).joined(separator: " + ")) = \(P.O).", said: { P.ones($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let group = LessonStep(StepWords(say: P.groupSay, hint: "Tap a row of 10.", action: "Check"),
            answer: G2.hand("g", P.G, hint: "Tap a row of 10.", explain: "\(P.O) = \(Array(repeating: "10", count: P.G).joined(separator: " + ")) + \(P.O % 10).",
                            said: { Parts.short(max(0, -$0 - 1)) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let tensHint = "Slide each number's tens under the tens."
        let tens = LessonStep(StepWords(say: "Slide the tens over.", hint: tensHint, action: "Check"),
            answer: G2.hand("t", P.n - 1, hint: tensHint, explain: "\((P.t + Array(repeating: 1, count: P.G)).map(String.init).joined(separator: " + ")) = \(P.t.reduce(0, +) + P.G) tens.",
                            said: { _ in "Tens go with the tens." }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: G2.write, hint: Parts.plain, action: "Check"),
            answer: G2.typed("x", P.sum, P.slips, plain: Parts.plain, hint: Parts.plain, explain: "\(P.record) = \(P.sum)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [ones, group, tens, write, LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: - Story problems

/// Bars to 100 (Story problems, Two-step story problems): one square is one thing up to 50; past 50 a square stands for 2
/// things (said on the page on its own row), so a story to 99 still fills the screen. Past 50 every number is even, so
/// every bar ends on a grid line (call 4 of 3 Nov: story numbers divide evenly into whole squares).
public enum Bars2 {
    /// Things per square for a picture whose longest bar is `most`.
    public static func per(_ most: Int) -> Int { most > 50 ? 2 : 1 }
    public static func scale(_ thing: String) -> String { "1 square is 2 \(thing)." }
}

/// Story problems to 100 (g2-story, new; 2.OA.A.1, 2.NBT.B.5). The story on the top rows, its numbers in the chapter colour;
/// its bars to scale, a bold line every ten things: joining, taking away and parts of a whole are one bar in two parts under a
/// bracket for the whole; comparing is two bars from one start line, the gap past the shorter one's end dashed. The part we
/// don't know is dashed, its true length, with no number. Slide the ? onto it; pick + or −; write the answer.
///
/// "kind" the story's kind (Kind), "more" 1 its words say more (0 fewer), "W" the whole, "p1" its first part (the second is
/// W − p1), "who" and "other" the names, "th" the things. "at": 0 place, 1 pick, 2 write, 3 done. Boxes: "u" the ? placed (1; −1
/// on the whole, −2 on the first part, −3 on the second), "c" the pick, "x" the answer.
public enum Story2 {
    public enum Kind: Int, CaseIterable, Sendable { case joinEnd, joinChange, joinStart, takeEnd, takeChange, takeStart, partWhole, partPart, cmpDiff, cmpBig, cmpSmall }
    public enum Piece: Int, Sendable { case whole, p1, p2 }
    public static func numbers(kind: Kind, W: Int, p1: Int, more: Bool = true, who: Int = 0, other: Int = 3, th: Int = 0) -> Numbers {
        ["kind": Double(kind.rawValue), "W": Double(W), "p1": Double(p1), "more": more ? 1 : 0, "who": Double(who), "other": Double(other), "th": Double(th)]
    }
    public struct Parts: Sendable {
        public let kind: Kind, W: Int, p1: Int, more: Bool, N: String, pr: String, M: String, th: String
        public init(_ x: Numbers) {
            kind = Kind(rawValue: G2.int(x, "kind")) ?? .joinEnd
            W = max(10, min(99, G2.int(x, "W", 59))); p1 = max(1, min(W - 1, G2.int(x, "p1", 34))); more = G2.int(x, "more", 1) != 0
            let w = G2.names[max(0, min(3, G2.int(x, "who")))], o = G2.names[max(0, min(3, G2.int(x, "other", 3)))]
            N = w.0; pr = w.1; M = o.0 == w.0 ? G2.names[(G2.names.firstIndex { $0.0 == w.0 }! + 1) % 4].0 : o.0
            th = G2.things[max(0, min(G2.things.count - 1, G2.int(x, "th")))]
        }
        public var p2: Int { W - p1 }
        public var cmp: Bool { [.cmpDiff, .cmpBig, .cmpSmall].contains(kind) }
        public var unknown: Piece {
            switch kind {
            case .joinEnd, .takeStart, .partWhole, .cmpBig: return .whole
            case .joinStart, .takeEnd, .cmpSmall: return .p1
            default: return .p2
            }
        }
        public var unkWhole: Bool { unknown == .whole }
        public func value(_ p: Piece) -> Int { p == .whole ? W : p == .p1 ? p1 : p2 }
        /// The part we know when a part is asked (nil: the whole is asked).
        public var known: Int? { unknown == .whole ? nil : unknown == .p1 ? p2 : p1 }
        public var ans: Int { known.map { W - $0 } ?? W }
        /// Things per square.
        public var U: Int { Bars2.per(W) }
        /// The story's equation, the ? where the story has it (nil is the ?).
        public var equation: [String?] {
            switch kind {
            case .joinEnd, .partWhole, .cmpBig: return ["\(p1)", "+", "\(p2)", "=", nil]
            case .joinChange, .partPart: return ["\(p1)", "+", nil, "=", "\(W)"]
            case .joinStart: return [nil, "+", "\(p2)", "=", "\(W)"]
            case .takeEnd: return ["\(W)", "−", "\(p2)", "=", nil]
            case .takeChange: return ["\(W)", "−", nil, "=", "\(p1)"]
            case .takeStart: return [nil, "−", "\(p2)", "=", "\(p1)"]
            case .cmpDiff: return ["\(W)", "−", "\(p1)", "=", nil]
            case .cmpSmall: return ["\(W)", "−", "\(p2)", "=", nil]
            }
        }
        /// The story's equation is already the sum to work: the box goes in it, written once.
        public var same: Bool { equation[4] == nil }
        /// The child's line: p1 + p2 = [ ], or W − known = [ ].
        public var line: (Int, String, Int) { known.map { (W, "−", $0) } ?? (p1, "+", p2) }
        public var lines: [String] {
            let Pr = G2.cap(pr)
            switch kind {
            case .joinEnd: return ["\(N) had \(p1) \(th).", "\(Pr) got \(p2) more.", "How many does \(pr) have now?"]
            case .joinChange: return ["\(N) had \(p1) \(th).", "\(Pr) got some more. Now \(pr) has \(W).", "How many did \(pr) get?"]
            case .joinStart: return ["\(N) had some \(th).", "\(Pr) got \(p2) more. Now \(pr) has \(W).", "How many did \(pr) have at first?"]
            case .takeEnd: return ["\(N) had \(W) \(th).", "\(Pr) gave \(p2) away.", "How many are left?"]
            case .takeChange: return ["\(N) had \(W) \(th).", "\(Pr) gave some away. Now \(pr) has \(p1).", "How many did \(pr) give away?"]
            case .takeStart: return ["\(N) had some \(th).", "\(Pr) gave \(p2) away. Now \(pr) has \(p1).", "How many did \(pr) have at first?"]
            case .partWhole: return ["\(N) has \(p1) red \(th) and \(p2) blue \(th).", "How many \(th) in all?"]
            case .partPart: return ["\(N) has \(W) \(th).", "\(p1) are red. The rest are blue.", "How many are blue?"]
            case .cmpDiff: return ["\(N) has \(W) \(th). \(M) has \(p1).", more ? "How many more does \(N) have?" : "How many fewer does \(M) have?"]
            case .cmpBig: return more ? ["\(M) has \(p1) \(th).", "\(N) has \(p2) more than \(M).", "How many does \(N) have?"]
                : ["\(M) has \(p2) fewer \(th) than \(N).", "\(M) has \(p1).", "How many does \(N) have?"]
            case .cmpSmall: return !more ? ["\(N) has \(W) \(th).", "\(M) has \(p2) fewer than \(N).", "How many does \(M) have?"]
                : ["\(N) has \(p2) more \(th) than \(M).", "\(N) has \(W).", "How many does \(M) have?"]
            }
        }
        /// Comparing in the mixed-up wording: "Sam has 25 fewer than Ana."
        public var mixedUp: Bool { (kind == .cmpBig && !more) || (kind == .cmpSmall && more) }
        public var startUnknown: Bool { kind == .joinStart || kind == .takeStart }
        public func placed(_ code: Int) -> String {
            let p = Piece(rawValue: -code - 1) ?? .whole
            return "We know that one: \(value(p))."
        }
        public var pickWrong: String { unkWhole ? "The ? is the whole. Put the parts together." : "The ? is a part. Take the other part away." }
        public var why: String { unkWhole ? "The ? is the whole, so put the parts together." : "The ? is a part, so take the known part away." }
        public var slips: [(Int, String)] {
            if let k = known {
                let wO = W % 10, kO = k % 10, tW = W / 10, tK = k / 10
                var s = [(W + k, "The ? is a part, so it's less than \(W).")]
                if wO < kO { s += [((tW - tK) * 10 + (kO - wO), "You can't take \(kO) from \(wO). Trade a ten first."), (ans + 10, "You traded a ten: \(tW - 1) tens, not \(tW).")] }
                return s
            }
            var s = [(abs(p1 - p2), "The ? is the whole, so it's more than \(max(p1, p2)).")]
            if p1 % 10 + p2 % 10 >= 10 { s.append((W - 10, "The ones made a new ten.")) }
            return s
        }
        public var plain: String { known.map { "Take \($0) from \(W): tens, then ones." } ?? "Put \(p1) and \(p2) together: tens, then ones." }
    }

    /// New (grade2.md): problems 0–2 the end unknown (joining, taking away, both parts known), wholes 20–50, no trade; 3 a change
    /// unknown, 4 a part unknown, 5 how many more; from 6 any kind, wholes 30–99, trades allowed. Past 50 every number is even.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind: Kind = i == 0 ? .joinEnd : i == 1 ? .takeEnd : i == 2 ? .partWhole : i == 3 ? (Bool.random(using: &rng) ? .joinChange : .takeChange)
            : i == 4 ? .partPart : i == 5 ? .cmpDiff : Kind.allCases.randomElement(using: &rng)!
        let more = kind == .cmpDiff && i == 5 ? true : Bool.random(using: &rng)
        let big = i >= 6
        var W = 0, p1 = 0
        repeat { W = Int.random(in: (big ? 30 : 20)...(big ? 99 : 50), using: &rng); p1 = Int.random(in: 5...(W - 5), using: &rng) }
        while (!big && p1 % 10 + (W - p1) % 10 >= 10) || (W > 50 && (W % 2 != 0 || p1 % 2 != 0))
        let who = Int.random(in: 0...3, using: &rng)
        var other = who
        while other == who { other = Int.random(in: 0...3, using: &rng) }
        return numbers(kind: kind, W: W, p1: p1, more: more, who: who, other: other, th: Int.random(in: 0..<G2.things.count, using: &rng))
    }

    public static let spec = LessonSpec(id: "g2-story", title: "Story problems to 100", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return P.equation.map { $0.map { s in Double(s).map { Math.num($0) } ?? .op(s) } ?? .box("x") } },
        idea: { _ in "The ? is a part, so take the known part away." },
        depends: ["g2-subregroup", "g1-story", "g1-more"],
        check: [CheckItem(3), CheckItem(4), CheckItem(6, when: { Parts($0).startUnknown }), CheckItem(6, when: { Parts($0).mixedUp })]) { x in
        let P = Parts(x)
        let placeHint = "Put it on the dashed piece."
        let place = LessonStep(StepWords(say: "Put the ? on what we don't know.", hint: placeHint, action: "Check"),
            answer: G2.hand("u", 1, hint: placeHint, explain: P.unkWhole ? "The ? is the whole." : "The ? is a part.", said: { P.placed($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pick = LessonStep(StepWords(say: "Pick what to do.", hint: P.pickWrong, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": P.unkWhole ? 0 : 1], hint: P.pickWrong, explain: P.why,
                               check: { v in v["c"] == (P.unkWhole ? 0 : 1) ? .right : .wrong(P.pickWrong) }, choices: ["+", "−"]),
            picture: ["at": 1])
        let (l0, op, l2) = P.line
        let write = LessonStep(StepWords(say: G2.write, hint: P.plain, action: "Check"),
            answer: G2.typed("x", P.ans, P.slips, plain: P.plain, hint: P.plain, explain: "\(l0) \(op) \(l2) = \(P.ans)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [place, pick, write, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])]
    }
}

/// Two-step story problems (g2-twostep, new; 2.OA.A.1). The story on the top rows; the start bar (tinted, its number at its
/// end) from the start line, the first change waiting under it as a loose striped bar. Slide it in: after the end it joins,
/// over the end it crosses out what it covers; write how many now. Then the second change the same way. More, then in all
/// (from problem 6, one in three): Sam's bar and Ana's, which starts as long as Sam's; drag Ana's end on, write how many Ana
/// has; slide Ana's bar onto the end of Sam's, write how many in all.
///
/// "kind" 0 two changes, 1 more then in all; "s" the start, "c1", "c2" the changes, "o1", "o2" their signs (0 +, 1 −); more:
/// "s" Sam's, "d" how many more Ana has. "who", "th" the story's name and things. "at": 0 move, 1 write, 2 move, 3 write,
/// 4 done. Boxes: "m1", "m2" the moves (1; −1 the wrong way; more's first: how many more it was dragged), "x1", "x2" the answers.
public enum TwoStep2 {
    public static func numbers(s: Int, c1: Int, plus1: Bool, c2: Int, plus2: Bool, who: Int = 1, th: Int = 0) -> Numbers {
        ["kind": 0, "s": Double(s), "c1": Double(c1), "o1": plus1 ? 0 : 1, "c2": Double(c2), "o2": plus2 ? 0 : 1, "who": Double(who), "th": Double(th)]
    }
    public static func more(s: Int, d: Int, th: Int = 0) -> Numbers { ["kind": 1, "s": Double(s), "d": Double(d), "th": Double(th)] }
    public struct Step: Sendable { public let a: Int, op: String, c: Int, ans: Int }
    public struct Parts: Sendable {
        public let more: Bool, s: Int, c: [Int], plus: [Bool], d: Int, N: String, pr: String, th: String
        public init(_ x: Numbers) {
            more = G2.int(x, "kind") == 1
            s = max(2, min(60, G2.int(x, "s", 45)))
            c = [max(1, min(50, G2.int(x, "c1", 18))), max(1, min(50, G2.int(x, "c2", 27)))]
            plus = [G2.int(x, "o1") == 0, G2.int(x, "o2", 1) == 0]
            d = max(1, min(50, G2.int(x, "d", 15)))
            let w = G2.names[max(0, min(3, G2.int(x, "who", 1)))]
            N = more ? "Ana" : w.0; pr = more ? "she" : w.1
            th = G2.things[max(0, min(G2.things.count - 1, G2.int(x, "th")))]
        }
        public var Pr: String { G2.cap(pr) }
        public var e1: Int { plus[0] ? s + c[0] : s - c[0] }
        public var e2: Int { plus[1] ? e1 + c[1] : e1 - c[1] }
        public var steps: [Step] {
            more ? [Step(a: s, op: "+", c: d, ans: s + d), Step(a: s, op: "+", c: s + d, ans: s + s + d)]
                : [Step(a: s, op: plus[0] ? "+" : "−", c: c[0], ans: e1), Step(a: e1, op: plus[1] ? "+" : "−", c: c[1], ans: e2)]
        }
        /// The longest a bar gets: what sets things per square.
        public var maxEnd: Int { more ? s + s + d : max(s, plus[0] ? s + c[0] : s, plus[1] ? e1 + c[1] : e1) }
        public var U: Int { Bars2.per(maxEnd) }
        func verb(_ k: Int) -> String { plus[k] ? "got \(c[k]) more" : "gave \(c[k]) away" }
        public var lines: [String] {
            more ? ["Sam has \(s) \(th). Ana has \(d) more than Sam.", "How many do they have in all?"]
                : ["\(N) had \(s) \(th). \(Pr) \(verb(0)).", "Then \(pr) \(verb(1)). How many does \(pr) have now?"]
        }
        public func say(_ at: Int) -> String {
            if more { return ["Ana has \(d) more.", "How many does Ana have?", "Put them together.", "Write how many in all.", Self.why][at] }
            return ["Slide the \(c[0]) in.", "Write how many now.", "Slide the \(c[1]) in.", "Write how many now.", Self.why][at]
        }
        public static let why = "The first answer is where the second step starts."
        /// The move the wrong way, said.
        public func wrongWay(_ k: Int) -> String {
            if more { return "Put them together: after the end." }
            return steps[k].op == "+" ? "\(Pr) got more. Put them after the end." : "\(Pr) gave some away. Slide them over the end."
        }
        public func dragged(_ m: Int) -> String { "That's \(m) more. Ana has \(d) more." }
        public func slips(_ k: Int) -> [(Int, String)] {
            let st = steps[k], other = st.op == "+" ? st.a - st.c : st.a + st.c
            var out: [(Int, String)] = []
            if k == 1 {
                out.append((steps[0].ans, "That's after one step. Now the \(st.c)."))
                if !more { out.append((st.op == "+" ? s + st.c : s - st.c, "Start from \(st.a), the first answer.")) }
            }
            out.append((other, more ? "Ana has more, so add." : st.op == "+" ? "\(Pr) got \(st.c) more, so add." : "\(Pr) gave \(st.c) away, so take away."))
            return out
        }
        public func plain(_ k: Int) -> String { let st = steps[k]; return st.op == "+" ? "Count on \(st.c) from \(st.a): tens, then ones." : "Count back \(st.c) from \(st.a): tens, then ones." }
        /// A step crosses a ten: its ones make 10 or more, or there aren't enough ones to take.
        public func trades(_ k: Int) -> Bool { let st = steps[k]; return st.op == "+" ? st.a % 10 + st.c % 10 >= 10 : st.a % 10 < st.c % 10 }
    }

    /// New (grade2.md): two changes (+ +, + −, − +, − −) on a start 10–60, each change 5–40, every answer 1–99; problems 0–2 + then
    /// −, no trades, all within 50; from 6, one in three is more-than then in all (each 10–45, the total 99 or less). Past 50 every
    /// number is even.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let th = Int.random(in: 0..<G2.things.count, using: &rng)
        if i >= 6 && i % 3 == 0 {
            while true {
                let s = Int.random(in: 10...45, using: &rng), d = Int.random(in: 10...45, using: &rng)
                if s + s + d > 99 || (s + s + d > 50 && (s % 2 != 0 || d % 2 != 0)) { continue }
                return more(s: s, d: d, th: th)
            }
        }
        let ops: [Bool] = i < 3 ? [true, false] : [[true, true], [true, false], [false, true], [false, false]].randomElement(using: &rng)!
        let who = Int.random(in: 0...3, using: &rng)
        while true {
            let s = Int.random(in: 10...60, using: &rng), c1 = Int.random(in: 5...40, using: &rng), c2 = Int.random(in: 5...40, using: &rng)
            let P = Parts(numbers(s: s, c1: c1, plus1: ops[0], c2: c2, plus2: ops[1], who: who, th: th))
            if P.e1 < 1 || P.e1 > 99 || P.e2 < 1 || P.e2 > 99 { continue }
            if i < 3 && (s > 50 || P.e1 > 50 || P.e2 > 50 || P.trades(0) || P.trades(1)) { continue }
            if P.U == 2 && (s % 2 != 0 || c1 % 2 != 0 || c2 % 2 != 0) { continue }
            return numbers(s: s, c1: c1, plus1: ops[0], c2: c2, plus2: ops[1], who: who, th: th)
        }
    }

    public static let spec = LessonSpec(id: "g2-twostep", title: "Two-step story problems", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let st = Parts(x).steps[0]; return [.num(Double(st.a)), .op(st.op), .num(Double(st.c)), .op("="), .box("x1")] },
        idea: { _ in Parts.why },
        depends: ["g2-story"],
        check: [CheckItem(0), CheckItem(3, when: { let P = Parts($0); return !P.more && !P.plus[0] && P.plus[1] }),
                CheckItem(3, when: { let P = Parts($0); return P.trades(0) || P.trades(1) }), CheckItem(6, when: { Parts($0).more })]) { x in
        let P = Parts(x)
        var out: [LessonStep] = []
        for k in 0..<2 {
            let st = P.steps[k], hint = P.more && k == 0 ? "Drag Ana's end on, \(P.d) more." : st.op == "+" ? "Put it after the end." : "Slide it over the end."
            let want = P.more && k == 0 ? P.d : 1
            out.append(LessonStep(StepWords(say: P.say(2 * k), hint: hint, action: "Check"),
                answer: G2.hand("m\(k + 1)", want, hint: hint, explain: "\(st.a) \(st.op) \(st.c).", said: { P.more && k == 0 ? P.dragged($0) : P.wrongWay(k) }),
                picture: ["at": Double(2 * k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            out.append(LessonStep(StepWords(say: P.say(2 * k + 1), hint: P.plain(k), action: "Check"),
                answer: G2.typed("x\(k + 1)", st.ans, P.slips(k), plain: P.plain(k), hint: P.plain(k), explain: "\(st.a) \(st.op) \(st.c) = \(st.ans)."),
                picture: ["at": Double(2 * k + 1)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        return out + [LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])]
    }
}
