import Foundation

/// What 1st grade's chapter 1, Add and take away to 20, shares (design/grade1.md chapter 1, the preview
/// design/prototype/grade1-ch1.html): one counter is 3 × 3 squares, a row of ten 30 squares; the number line 0 to 20 is
/// 3 squares a step; the second amount is striped; every number is tapped on the number row (0–20), never typed. Every
/// line here is also spoken (App's Voice). The preview's grey second line is folded into the instruction.
public enum G1 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// The number row's numbers.
    public static let row = 0...20
    /// The first wrong-answer line that fits (the web's slips, in order: never the answer, on the row only), else `other`.
    static func slip(_ v: Int, _ ans: Int, _ list: [(Int, String)], _ other: String) -> String {
        list.first { $0.0 == v && $0.0 != ans && row.contains($0.0) }?.1 ?? other
    }
    /// The slips a step names for the number row: the ones that can be tapped, each once.
    static func known(_ ans: Int, _ list: [(Int, String)]) -> [(Int, String)] {
        var seen: Set<Int> = []
        return list.filter { $0.0 != ans && row.contains($0.0) && seen.insert($0.0).inserted }
    }
    /// A number tapped on the row into `box`: right when it's `want`, else its slip.
    static func write(_ box: String, _ want: Int, _ list: [(Int, String)], other: @escaping @Sendable (Int) -> String, hint: String, explain: String) -> AnswerTask {
        CountK.write(box, want, known: known(want, list), other: { slip($0, want, list, other($0)) }, hint: hint, explain: explain)
    }
    /// The write step's words (the preview's).
    public static let tap = "Tap the number that goes in the box."
    public static let taps = "Tap the numbers that go in the boxes."
}

// MARK: - Add within 20

/// Add within 20 (the web's g1-add20; 1.OA.3, 5, 6). The line 0 to 20, 3 squares a step; above it the two numbers as rows
/// of counters, a solid and b striped, each named at its right end. Drag the bigger row down onto the line (the smaller:
/// it slides back, "That works, but it's a long count."); hop on, a hop for each counter of the small row; write the sum.
/// When the bigger was second the record writes the turn-around, a + b = big + small.
///
/// "at": 0 start, 1 hop, 2 write, 3 done. The start step's box: 0 the bigger row on the line, 1 the smaller. The hop
/// step's box: small once every hop is made, −1 a hop back.
public enum Add20 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) {
            a = max(1, min(18, G1.int(x, "a", 9))); b = max(1, min(20 - a, G1.int(x, "b", 3)))
        }
        public var big: Int { max(a, b) }
        public var small: Int { min(a, b) }
        public var sum: Int { a + b }
        /// The bigger was second: the record writes the turn-around.
        public var swapped: Bool { b > a }
        /// The numbers said as the hops land.
        public var counted: [Int] { Array((big + 1)...sum) }
        public var long: String { "That works, but it's a long count. Start at \(big), then count on only \(small)." }
        public static let forward = "Hop forward to add."
        public var slips: [(Int, String)] {
            [(sum - 1, "One short. Don't count \(big) again: your first hop lands on \(big + 1)."),
             (sum + 1, "One too many. Make exactly \(small) hops: \(counted.map(String.init).joined(separator: ", "))."),
             (big - small, "That's taking away. Adding makes the number bigger.")]
        }
        public var other: String { "Not quite. Say \(big), then count \(small) more: one number for each." }
        public func wrote(_ v: Int) -> String { G1.slip(v, sum, slips, other) }
        public static let why = "Start big, so there are fewer hops."
    }
    /// The web's generator: small 2–3 for the first three, then 2–5; big from max(small + 1, 11 − small) to 20 − small;
    /// either order.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let small = Int.random(in: 2...(i < 3 ? 3 : 5), using: &rng)
        let big = Int.random(in: max(small + 1, 11 - small)...(20 - small), using: &rng)
        return Bool.random(using: &rng) ? numbers(a: small, b: big) : numbers(a: big, b: small)
    }

    public static let spec = LessonSpec(id: "g1-add20", title: "Add within 20", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("+"), .num(Double(P.b))] },
        idea: { _ in "Start at the bigger number, so you have fewer to count." },
        depends: ["k-add", "k-count20"],
        check: [CheckItem(3, when: { Parts($0).a < Parts($0).b }), CheckItem(3, when: { Parts($0).a < Parts($0).b }),
                CheckItem(3, when: { Parts($0).a > Parts($0).b }), CheckItem(3, when: { Parts($0).small >= 4 })]) { x in
        let P = Parts(x)
        let startHint = "Find the row with more counters."
        let start = LessonStep(StepWords(say: "Drag the bigger row down to the line.", hint: startHint, action: "Check"),
            answer: AddSubK.hand("r", 0, hint: startHint, explain: "Start at \(P.big).", said: { _ in P.long }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let hopHint = "Tap the line just past where you are."
        let hop = LessonStep(StepWords(say: "Hop on: one hop for each counter.", hint: hopHint, action: "Check"),
            answer: AddSubK.hand("h", P.small, hint: hopHint, explain: "Hop \(P.small) times: \(P.counted.map(String.init).joined(separator: ", ")).",
                                 said: { _ in Parts.forward }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Where did the last hop land?"
        let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
            answer: G1.write("x", P.sum, P.slips, other: { _ in P.other }, hint: writeHint, explain: "\(P.a) + \(P.b) = \(P.sum)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [start, hop, write, done]
    }
}

// MARK: - Make a ten to add

/// Make a ten to add (the web's g1-ten; 1.OA.6, 3). Two rows of ten dashed places, a square apart: a counters in the top
/// row from the left, b striped in the bottom. Slide counters up into the top row's empty places (one or several: the
/// ones from the left up to the one grabbed go together); the top row fills ("8 and 2 make 10"), what's left slides to
/// the start of the bottom row; write a + b = 10 + left.
///
/// "at": 0 fill, 1 write, 2 done. The fill step's box: need once the top row is full.
public enum MakeTen1 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) {
            a = max(1, min(9, G1.int(x, "a", 8))); b = max(10 - a + 1, min(9, G1.int(x, "b", 5)))
        }
        public var need: Int { 10 - a }
        public var left: Int { b - need }
        public var sum: Int { a + b }
        public static let full = "The top row is full. That's 10."
        public var slips: [(Int, String)] { [(left, "That's only the ones left over. The full row is 10 more.")] }
        public var other: String { "Not quite. 10 plus \(left) is ten and \(left) more." }
        public func wrote(_ v: Int) -> String { G1.slip(v, sum, slips, other) }
        public static let why = "A full ten makes the rest easy to add."
    }
    /// The web's generator: a 8–9 and b up to 6 for the first three, then a 6–9 and b 11 − a to 9 (always past 10).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let a = i < 3 ? Int.random(in: 8...9, using: &rng) : Int.random(in: 6...9, using: &rng)
        return numbers(a: a, b: Int.random(in: (11 - a)...(i < 3 ? 6 : 9), using: &rng))
    }

    public static let spec = LessonSpec(id: "g1-ten", title: "Make a ten to add", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("+"), .num(Double(P.b))] },
        idea: { _ in "Fill a ten first, because adding to 10 is easy." },
        depends: ["k-make10", "k-teens"],
        check: [CheckItem(3, when: { Parts($0).a == 9 }), CheckItem(3, when: { (6...7).contains(Parts($0).a) }),
                CheckItem(3, when: { Parts($0).b >= 7 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let fillHint = "Count the empty places in the top row."
        let fill = LessonStep(StepWords(say: "Slide counters up to fill the top row.", hint: fillHint, action: "Check"),
            answer: AddSubK.hand("f", P.need, hint: fillHint, explain: "Move \(P.need) of the \(P.b) into the top row.", said: { _ in Parts.full }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "The full row is 10. Count on what's left."
        let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
            answer: G1.write("x", P.sum, P.slips, other: { _ in P.other }, hint: writeHint, explain: "\(P.a) + \(P.b) = 10 + \(P.left) = \(P.sum)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [fill, write, done]
    }
}

// MARK: - Doubles and near doubles

/// Doubles and near doubles (g1-doubles, new; 1.OA.6, 3). Two rows of counters: a solid on top from the start line, b
/// striped a block lower and 2 blocks to the right. Slide the bottom row to the start line: a line joins each pair, an
/// extra one stands alone, ringed ("6 pairs and 1 more"). Write the double (school's 6 + 6 + 1 = 12 + 1).
///
/// "at": 0 slide, 1 write (the double's box, or a near double's first), 2 write (a near double's sum), 3 done. The slide
/// step's box: 0 once the row snaps at the start line.
public enum Doubles1 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) {
            a = max(1, min(10, G1.int(x, "a", 6)))
            b = max(max(1, a - 1), min(min(10, a + 1), G1.int(x, "b", a)))
        }
        public var dbl: Bool { a == b }
        public var d: Int { min(a, b) }
        public var sum: Int { a + b }
        public var dblLine: String { "A double is the same number twice: \(d) and \(d) more." }
        public var dSlips: [(Int, String)] { [(d, "That's one \(d). Double \(d) is \(d) and \(d)."), (2 * d - 1, dblLine), (2 * d + 1, dblLine)] }
        public var sSlips: [(Int, String)] {
            [(2 * d, "That's the double. Add the extra one."), (2 * d + 2, "\(2 * d + 2) is double \(d + 1). Double \(d) is \(2 * d), then 1 more.")]
        }
        public var sOther: String { "Not quite. Double \(d) is \(2 * d), then 1 more." }
        public var why: String { dbl ? "The same number twice." : "\(a) + \(b) is double \(d) and 1 more." }
        public var readout: String { dbl ? "\(d) pairs" : "\(d) pairs and 1 more" }
    }
    /// New: doubles d + d (d 1–5) for the first three, then near doubles d + (d + 1) (d 2–5) either order, then d 2–9, a
    /// double one time in three, else a near double, either order.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let d = i < 3 ? Int.random(in: 1...5, using: &rng) : i < 6 ? Int.random(in: 2...5, using: &rng) : Int.random(in: 2...9, using: &rng)
        let dbl = i < 3 ? true : i < 6 ? false : Int.random(in: 0...2, using: &rng) == 0
        if dbl { return numbers(a: d, b: d) }
        return Bool.random(using: &rng) ? numbers(a: d, b: d + 1) : numbers(a: d + 1, b: d)
    }

    public static let spec = LessonSpec(id: "g1-doubles", title: "Doubles and near doubles", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("+"), .num(Double(P.b))] },
        idea: { _ in "A double is the same number twice; a near double is a double and 1 more." },
        depends: ["g1-add20", "k-bonds"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6, when: { Parts($0).dbl && Parts($0).d >= 6 }),
                CheckItem(6, when: { !Parts($0).dbl && Parts($0).a > Parts($0).b })]) { x in
        let P = Parts(x)
        let slideHint = "Drag the striped row left to the line."
        let slide = LessonStep(StepWords(say: "Slide the bottom row to the start line.", hint: slideHint, action: "Check"),
            answer: AddSubK.hand("l", 0, hint: slideHint, explain: P.readout + ".", said: { _ in slideHint }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let dHint = "Count the pairs twice: \(P.d) and \(P.d) more."
        let first = LessonStep(StepWords(say: P.dbl ? G1.tap : G1.taps, hint: dHint, action: "Check"),
            answer: G1.write(P.dbl ? "x" : "d", 2 * P.d, P.dSlips, other: { _ in P.dblLine }, hint: dHint, explain: "\(P.d) + \(P.d) = \(2 * P.d)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        guard !P.dbl else { return [slide, first, done] }
        let sHint = "The double and the one extra."
        let second = LessonStep(StepWords(say: G1.taps, hint: sHint, action: "Check"),
            answer: G1.write("x", P.sum, P.sSlips, other: { _ in P.sOther }, hint: sHint, explain: "\(2 * P.d) + 1 = \(P.sum)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [slide, first, second, done]
    }
}

// MARK: - Add three numbers

/// Add three numbers (the web's g1-three; 1.OA.2, 3). Three groups of counters (solid, striped, dotted), each named at its
/// right end; a block under them the twenty, two rows of ten dashed places. Tap two that make 10 or a double (only when
/// exactly one pair does: the web's pick step; otherwise the pair is lit and named in the instruction); slide the two
/// into the top row (they fill it from the left, "7 and 3 make 10"); slide the last group in, the count running on; write.
/// A story item tells it as beads, its sentences first in the instruction.
///
/// "at": 0 pick, 1 slide, 2 last, 3 write, 4 done. Pairs are coded 10 + 3s + t (s < t, groups 0–2). The pick step's box:
/// the pair tapped. The slide step's box: the pair slid in (kept as "u"), or −1 a group that isn't one of the two first.
public enum Three1 {
    public static let names = ["Maya", "Leo", "Ana", "Sam", "Noor", "Eli"]
    public static func numbers(_ a: Int, _ b: Int, _ c: Int, story: Bool = false) -> Numbers {
        ["a": Double(a), "b": Double(b), "c": Double(c), "story": story ? 1 : 0]
    }
    public static func code(_ s: Int, _ t: Int) -> Int { 10 + 3 * min(s, t) + max(s, t) }
    public static func pair(_ code: Int) -> (Int, Int)? {
        let k = code - 10
        guard k >= 0 else { return nil }
        let s = k / 3, t = k % 3
        return s < t && t <= 2 ? (s, t) : nil
    }
    public enum Why: String, Sendable { case ten, double, order }
    public struct Parts: Sendable {
        public let v: [Int], story: Bool
        public init(_ x: Numbers) {
            v = ["a", "b", "c"].map { max(1, min(9, G1.int(x, $0, 3))) }
            story = G1.int(x, "story") == 1
        }
        public var sum: Int { v.reduce(0, +) }
        /// The two to add first: a pair that makes 10, else a double, else the first two (the web's pairOf).
        public var first: (pair: (Int, Int), why: Why) {
            let pairs = [(0, 2), (1, 2), (0, 1)]
            if let p = pairs.first(where: { v[$0.0] + v[$0.1] == 10 }) { return (p, .ten) }
            if let p = pairs.first(where: { v[$0.0] == v[$0.1] }) { return (p, .double) }
            return ((0, 1), .order)
        }
        public var why: Why { first.why }
        public var pairCode: Int { Three1.code(first.pair.0, first.pair.1) }
        /// The pick step comes when exactly one pair makes 10 or a double, and the three choices read differently.
        public var choose: Bool {
            let offer = [(0, 1), (0, 2), (1, 2)]
            let friendly = offer.filter { v[$0.0] + v[$0.1] == 10 || v[$0.0] == v[$0.1] }
            let labels = Set(offer.map { "\(v[$0.0]) and \(v[$0.1])" })
            return why != .order && friendly.count == 1 && labels.count == 3
        }
        /// The pairs that may go in first: the lit two, or the first two (the web accepts both).
        public var allowed: [Int] { Array(Set([pairCode, Three1.code(0, 1)])).sorted() }
        public var name: String { Three1.names[(v[0] + 2 * v[1] + 3 * v[2]) % Three1.names.count] }
        public var tale: String {
            "\(name) has \(v[0]) plain, \(v[1]) striped and \(v[2]) spotted bead\(v[2] == 1 ? "" : "s"). How many beads in all?"
        }
        func told(_ s: String) -> String { story ? tale + " " + s : s }
        public var pickSay: String { told(why == .ten ? "Tap two that make 10." : "Tap two that are the same.") }
        public func picked(_ code: Int) -> String {
            guard let (s, t) = Three1.pair(code) else { return "Tap two groups." }
            return "\(v[s]) and \(v[t]) make \(v[s] + v[t]). Look for two that \(why == .ten ? "make 10" : "are the same")."
        }
        public var narr: String {
            switch why {
            case .ten: "These two make 10, so add them first."
            case .double: "These two are a double, so add them first."
            case .order: "No ten and no double, so add the first two."
            }
        }
        public var slideSay: String { choose ? "Slide the two into the top row." : told(narr + " Slide these two into the top row.") }
        public var notFirst: String {
            pairCode != Three1.code(0, 1) ? "Slide in the two that \(why == .ten ? "make 10" : "are the same") first." : "Slide in the first two first."
        }
        public static let last = "Slide the last group in."
        /// The sum of the pair slid in first, and the number left.
        public func after(_ code: Int) -> (first: Int, z: Int) {
            let (s, t) = Three1.pair(code) ?? first.pair
            return (v[s] + v[t], v[3 - s - t])
        }
        public func slips(_ code: Int) -> [(Int, String)] {
            let (f, z) = after(code)
            let count = (f + 1...max(f + 1, sum)).map(String.init).joined(separator: ", ")
            return [(f, "That's only two of the numbers. Add the \(z) too."), (sum - 1, "Count on from \(f): \(count)."),
                    (sum + 1, "Count on from \(f): \(count)."), (sum + z, "You added the \(z) twice.")] + v.map { (sum + $0, "You added the \($0) twice.") }
        }
        public func other(_ code: Int) -> String { let (f, z) = after(code); return "Not quite. Start at \(f) and count on \(z)." }
        public func wrote(_ x: Int, pair code: Int) -> String { G1.slip(x, sum, slips(code), other(code)) }
        public var done: String {
            switch why {
            case .ten: "Any order works, so make 10 first."
            case .double: "Any order works, so add the double first."
            case .order: "Any order works, so add two first."
            }
        }
    }
    /// The web's generator: three numbers 1–9, the sum to 12 for the first three, then to 20: a ten pair, a double, or
    /// neither; every third a story.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3, most = early ? 12 : 20
        while true {
            let kind = Int.random(in: 0...2, using: &rng)
            var v: [Int]
            if kind < 2 {
                let x = Int.random(in: 1...9, using: &rng), z = Int.random(in: 1...min(9, most - 10), using: &rng)
                v = Bool.random(using: &rng) ? [x, z, 10 - x] : [z, x, 10 - x]
            } else if Bool.random(using: &rng) {
                let d = Int.random(in: 2...(early ? 5 : 8), using: &rng), z = Int.random(in: 1...9, using: &rng)
                v = [d, z, d]
            } else {
                v = (0..<3).map { _ in Int.random(in: 1...6, using: &rng) }
            }
            if v.contains(where: { $0 < 1 || $0 > 9 }) || v.reduce(0, +) > most { continue }
            let P = Parts(numbers(v[0], v[1], v[2]))
            if kind == 2 && P.why == .ten { continue }
            if kind < 2 && v[0] + v[1] == 10 { continue }
            return numbers(v[0], v[1], v[2], story: i % 3 == 2)
        }
    }

    public static let spec = LessonSpec(id: "g1-three", title: "Add three numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let v = Parts(x).v; return [.num(Double(v[0])), .op("+"), .num(Double(v[1])), .op("+"), .num(Double(v[2]))] },
        idea: { _ in "Any order works, so add two that make 10 or a double first." },
        depends: ["g1-ten", "g1-add20"],
        check: [CheckItem(3, when: { Parts($0).choose && Parts($0).why == .ten }), CheckItem(3, when: { Parts($0).choose && Parts($0).why == .double }),
                CheckItem(3, when: { Parts($0).choose }), CheckItem(5, when: { Parts($0).story })]) { x in
        let P = Parts(x)
        let pickHint = P.why == .ten ? "Which two numbers add to 10?" : "Which two numbers are the same?"
        let pick = LessonStep(StepWords(say: P.pickSay, hint: pickHint, action: "Check"),
            answer: AddSubK.hand("p", P.pairCode, hint: pickHint, explain: P.narr, said: { P.picked($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let slideHint = "Slide the lit groups down, one after the other."
        let ok = P.allowed
        let slide = LessonStep(StepWords(say: P.slideSay, hint: slideHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": Double(P.pairCode)], hint: slideHint, explain: P.narr,
                               check: { v in ok.contains(Int((v["s"] ?? -1).rounded())) ? .right : .wrong(P.notFirst) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let lastHint = "Drag the last group down to the twenty."
        let last = LessonStep(StepWords(say: Parts.last, hint: lastHint, action: "Check"),
            answer: AddSubK.hand("z", 1, hint: lastHint, explain: "Count on.", said: { _ in lastHint }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Count all the counters in the twenty."
        let sum = P.sum
        let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(sum)], hint: writeHint,
                               explain: "\(P.v[0]) + \(P.v[1]) + \(P.v[2]) = \(sum).",
                               check: { v in
                                   let x = Int((v["x"] ?? -1).rounded()), u = Int((v["kept.u"] ?? Double(P.pairCode)).rounded())
                                   return x == sum ? .right : .wrong(P.wrote(x, pair: u))
                               }, incomplete: "Tap a number.", byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.done, hint: "", action: "Next problem"), picture: ["at": 4])
        return (P.choose ? [pick] : []) + [slide, last, write, done]
    }
}

// MARK: - Subtract within 20

/// Subtract within 20 (the web's g1-sub20; 1.OA.6, 5). The line 0 to 20 with a counters over it from 0 (the tenth ends on
/// the strong line at 10). The number to take away is written once, in the record's first line, a − b. Hop back to 10
/// (drag left: it snaps a step at a time, crossing out the counters it passes, "−4"); hop back the rest ("6 taken");
/// write a − b = a − first − rest = 10 − rest.
///
/// "at": 0 to ten, 1 the rest, 2 write, 3 done. The first hop's box: where it landed (10 right). The second's: how many
/// are taken in all (b right).
public enum Sub20 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) {
            a = max(11, min(18, G1.int(x, "a", 14))); b = max(a - 9, min(9, G1.int(x, "b", 6)))
        }
        /// What the first hop takes (back to 10) and what's still to take.
        public var first: Int { a - 10 }
        public var rest: Int { b - first }
        public var left: Int { a - b }
        public func landed(_ n: Int) -> String { n > 10 ? "Hop all the way back to 10. \(a) is 10 and \(first) more." : "Stop at 10 first." }
        public func took(_ t: Int) -> String { "That takes \(t). Take \(b)." }
        public var slips: [(Int, String)] {
            [(10 + rest, "This is taking away, so the answer is less than 10. Count back \(rest) from 10."),
             (left + 1, "Count back one for each: start at 9, not 10."), (left - 1, "Count back exactly \(rest).")]
        }
        public var other: String { "Not quite. Count back \(rest) from 10." }
        public func wrote(_ v: Int) -> String { G1.slip(v, left, slips, other) }
        public static let why = "Back to 10 first, because taking from 10 is easy."
    }
    /// The web's generator: a 11–14 for the first three, then 11–18; b from a − 9 to 9 (so it goes past 10).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let a = Int.random(in: 11...(i < 3 ? 14 : 18), using: &rng)
        return numbers(a: a, b: Int.random(in: (a - 9)...9, using: &rng))
    }

    public static let spec = LessonSpec(id: "g1-sub20", title: "Subtract within 20", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("−"), .num(Double(P.b))] },
        idea: { _ in "Hop back to 10 first, then take away the rest." },
        depends: ["g1-ten", "k-sub"],
        check: [CheckItem(3), CheckItem(3, when: { Parts($0).a >= 15 }), CheckItem(3, when: { Parts($0).rest >= 4 }),
                CheckItem(3, when: { Parts($0).b == 9 })]) { x in
        let P = Parts(x)
        let tenHint = "\(P.a) is 10 and \(P.first) more."
        let toTen = LessonStep(StepWords(say: "Hop back to 10.", hint: tenHint, action: "Check"),
            answer: AddSubK.hand("t", 10, hint: tenHint, explain: "\(P.a) is 10 and \(P.first) more, so hop back to 10 first.", said: { P.landed($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let restHint = "\(P.first) taken. \(P.rest) more to take."
        let rest = LessonStep(StepWords(say: "Now hop back the rest.", hint: restHint, action: "Check"),
            answer: AddSubK.hand("r", P.b, hint: restHint, explain: "Hop back the rest from 10.", said: { P.took($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Where did the last hop land?"
        let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
            answer: G1.write("x", P.left, P.slips, other: { _ in P.other }, hint: writeHint,
                             explain: "\(P.a) − \(P.b) = 10 − \(P.rest) = \(P.left)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [toTen, rest, write, done]
    }
}
