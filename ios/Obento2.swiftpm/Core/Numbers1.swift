import Foundation

/// 1st grade's chapter 3, Numbers to 120 (design/grade1.md chapter 3, the preview design/prototype/grade1-ch3.html): a ten
/// is a row, on the 120 chart (K's hundred chart grown to 12 rows, one block a number) and in counters 3 × 3 squares. Every
/// number past 20 is written with the drawn digit pad and Check, never typed. Every line here is spoken (App's Voice); the
/// preview's grey second line is folded into the instruction.
public enum Num1 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G1.int(v, k, d) }
    /// The chart's row of v (1–10 is row 0).
    public static func row(_ v: Int) -> Int { (v - 1) / 10 }
    public static func tens(_ n: Int) -> Int { n / 10 }
    public static func ones(_ n: Int) -> Int { n % 10 }
    /// "1 ten", "3 tens".
    public static func pl(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }
    /// "6, 7, 8" or "6, 7 … 12": a count's readout.
    public static func run(_ ns: [Int]) -> String {
        ns.count > 4 ? "\(ns[0]), \(ns[1]) … \(ns[ns.count - 1])" : ns.map(String.init).joined(separator: ", ")
    }
    /// The digit pad writes up to 5 digits, so a slip may be bigger than 120 (1001 for 101).
    static let hi = 99_999
    /// A number written with the digit pad into `box`: right when it's `want`, else its slip, else `other`.
    static func write(_ box: String, _ want: Int, _ list: [(Int, String)], other: String, hint: String, explain: String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], known: TeensK.known(want, list, hi: hi).map { ([box: Double($0.0)], $0.1) },
                   hint: hint, explain: explain,
                   check: { v in let k = Int((v[box] ?? -1).rounded()); return k == want ? .right : .wrong(TeensK.slip(k, want, list, other, hi: hi)) },
                   incomplete: "Tap a number.", byHand: true)
    }
    public static let skip = "You skipped one. Touch each place."
    public static let writeBox = "Write the number that goes in the box."
    public static let afterNine = "After 9 ones comes a new ten."
    public static let hundred = "Ten tens is 100, and counting goes on."
}

// MARK: - Count to 120

/// Count to 120 (g1-count120, new; 1.NBT.1). Count on: the rows of the 120 chart the count passes and one above and below;
/// the start ringed, the next places empty, two of them boxed (the one a new ten starts on, and 101 when the count gets
/// past 100). Drag along the empty places: each lights and says its number. Then write the boxed ones with the digit pad.
/// How many?: the chart from 1, its first n places shaded, four rows showing at a time. Tap each full row (it counts by
/// tens), drag along the rest, then write how many.
///
/// "kind" 0 count on ("s", "m"), 1 how many ("n"). Count on "at": 0 count, 1 the first box, 2 the second, 3 done; the count's
/// box "k": m once every place is counted, −1 a place skipped. How many "at": 0 tens, 1 ones, 2 write, 3 done; the tens'
/// box "r": the full rows once all are tapped, −1 out of order, −2 the short row; the ones' box "k" as count on's.
public enum Count120 {
    public static func numbers(on s: Int, more m: Int) -> Numbers { ["kind": 0, "s": Double(s), "m": Double(m)] }
    public static func numbers(many n: Int) -> Numbers { ["kind": 1, "n": Double(n)] }
    public struct Parts: Sendable {
        public let many: Bool, s: Int, m: Int, n: Int
        public init(_ x: Numbers) {
            many = Num1.int(x, "kind") == 1
            m = max(1, min(8, Num1.int(x, "m", 5)))
            s = max(1, min(120 - m, Num1.int(x, "s", 97)))
            n = max(11, min(120, Num1.int(x, "n", 113)))
        }
        // count on
        public var last: Int { s + m }
        public var places: [Int] { Array((s + 1)...last) }
        /// The boxed places: the first a new ten starts on (else the middle one), and 101 or the last.
        public var boxed: [Int] {
            let p = places
            let b1 = p.first { $0 % 10 == 0 } ?? p[m / 2]
            let b2 = p.contains(101) && b1 != 101 ? 101 : last != b1 ? last : last - 1
            return [b1, b2].sorted()
        }
        /// The rows shown: one above the start's and one below the last's (kept on the chart).
        public var r0: Int { max(0, Num1.row(s) - 1) }
        public var rows: Int { min(11, Num1.row(last) + 1) - r0 + 1 }
        public func slips(_ v: Int) -> [(Int, String)] {
            let t = Num1.tens(v), o = Num1.ones(v)
            var list: [(Int, String)] = []
            if v >= 20 && v < 100 && o == 0 { list.append((Int("\(t - 1)10") ?? -1, "After \(v - 1) comes a new ten: \(v).")) }
            if v == 100 { list += [(1000, "100 is 10 tens: 1, 0, 0."), (910, "After 99 comes a new ten: 100.")] }
            if v > 100 && v < 110 { list.append((Int("100\(o)") ?? -1, "\(v) is 100 and \(o) more: 1, 0, \(o).")) }
            if v >= 110 { list.append((Int("100\(v - 100)") ?? -1, "\(v) is 100 and \(v - 100): \(String(v).map(String.init).joined(separator: ", ")).")) }
            list += [(v - 1, "Touch each place once."), (v + 1, "Touch each place once.")]
            return list
        }
        public var countOther: String { "Count on from \(s) to the box." }
        // how many
        public var T: Int { Num1.tens(n) }
        public var o: Int { Num1.ones(n) }
        public var manySlips: [(Int, String)] {
            var list: [(Int, String)] = []
            if o > 0 { list.append((Int("\(10 * T)\(o)") ?? -1, "\(n) is \(T) tens and \(o): \(String(n).map(String.init).joined(separator: ", ")).")) }
            list += [(n - 1, "Touch each place once."), (n + 1, "Touch each place once.")]
            if o > 0 { list.append((10 * T, "That's only the full rows. Count on the rest too.")) }
            return list
        }
        public static let manyOther = "Count the full rows by tens, then the rest by ones."
        public func tapped(_ code: Int) -> String { code == -2 ? "That row has only \(o). Tap the full rows first." : "Count the rows in order, from the top." }
        public var why: String {
            if many { return n >= 100 ? Num1.hundred : Num1.afterNine }
            return last > 100 && s < 101 ? Num1.hundred : Num1.afterNine
        }
        /// The window of four rows shown while `f` full rows are counted (it turns on by three rows as the count goes down).
        public static func window(_ f: Int) -> Int { f < 4 ? 0 : min(8, 3 + 3 * ((f - 4) / 3)) }
    }
    /// New (grade1.md): the first three start 25–89 (ones 5–9) and count 5, passing one ten; the next three start 94–99 and
    /// pass 100; then any start, counting 5–8, never past 120; from the 7th, every third is a how-many of 21–120.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 6 && (i - 6) % 3 == 0 { return numbers(many: Int.random(in: 21...120, using: &rng)) }
        if i < 3 { return numbers(on: Int.random(in: 2...8, using: &rng) * 10 + Int.random(in: 5...9, using: &rng), more: 5) }
        if i < 6 { let s = Int.random(in: 94...99, using: &rng); return numbers(on: s, more: Int.random(in: max(5, 101 - s)...8, using: &rng)) }
        let m = Int.random(in: 5...8, using: &rng)
        return numbers(on: Int.random(in: 1...(120 - m), using: &rng), more: m)
    }

    public static let spec = LessonSpec(id: "g1-count120", title: "Count to 120", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return P.many ? [.text("How many?")] : [.text("Count to"), .num(Double(P.last))] },
        idea: { _ in Num1.afterNine },
        depends: ["gk-count100", "k-tens"],
        check: [CheckItem(3, when: { let P = Parts($0); return !P.many && P.s < 100 && P.last > 100 }),
                CheckItem(7, when: { let P = Parts($0); return !P.many && P.places.contains { $0 % 10 == 0 && $0 < 100 } }),
                CheckItem(6, when: { let P = Parts($0); return P.many && P.n > 100 }), CheckItem(4)]) { x in
        let P = Parts(x)
        if P.many {
            let tensHint = "Tap the top row first."
            let tens = LessonStep(StepWords(say: "Tap each full row to count by tens.", hint: tensHint, action: "Check"),
                answer: TeensK.hand("r", P.T, hint: tensHint, explain: "\(P.T) full rows: \(10 * P.T).", said: P.tapped),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let onesHint = "Start right after \(10 * P.T)."
            let ones = LessonStep(StepWords(say: "Now drag along the rest to count on.", hint: onesHint, action: "Check"),
                answer: TeensK.hand("k", P.o, hint: onesHint, explain: "\(10 * P.T + 1) to \(P.n).", said: { _ in Num1.skip }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            let writeHint = "The last number you counted."
            let write = LessonStep(StepWords(say: "Write how many are shaded.", hint: writeHint, action: "Check"),
                answer: Num1.write("x", P.n, P.manySlips, other: Parts.manyOther, hint: writeHint, explain: "\(P.n) are shaded."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
            return P.o > 0 ? [tens, ones, write, done] : [tens, write, done]
        }
        let countHint = "Start at the place right after \(P.s)."
        let count = LessonStep(StepWords(say: "Drag along the empty places to count on.", hint: countHint, action: "Check"),
            answer: TeensK.hand("k", P.m, hint: countHint, explain: "\(P.s + 1) to \(P.last).", said: { _ in Num1.skip }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writes = P.boxed.enumerated().map { i, v in
            LessonStep(StepWords(say: Num1.writeBox, hint: P.countOther, action: "Check"),
                answer: Num1.write("x\(i)", v, P.slips(v), other: P.countOther, hint: P.countOther, explain: "The box is \(v)."),
                picture: ["at": Double(i + 1)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [count] + writes + [done]
    }
}

// MARK: - Tens and ones

/// Tens and ones (the web's g1-tensones; 1.NBT.2a, b, c). Counters 3 × 3 arrive loose in rows of ten, each in its own
/// outlined place, rows a square apart, the last row short. Tap a full row: it closes into one ten. Then count the ones
/// (tap or drag along them); then write the number: 3 tens and 4 ones is [34].
///
/// "at": 0 group, 1 count, 2 write, 3 done (no ones: 0, 2, 3). The group's box "g": t once every full row is a ten, −1 the
/// short row tapped. The count's box "c": o once every one is counted, −1 a ten tapped.
public enum TensOnes1 {
    public static func numbers(n: Int) -> Numbers { ["n": Double(n)] }
    public struct Parts: Sendable {
        public let n: Int
        public init(_ x: Numbers) { n = max(11, min(99, Num1.int(x, "n", 34))) }
        public var t: Int { Num1.tens(n) }
        public var o: Int { Num1.ones(n) }
        public var slips: [(Int, String)] {
            [(t + o, "Each ten is worth 10, not 1. \(Num1.pl(t, "ten", "tens")) is \(10 * t)."), (o * 10 + t, "The tens come first. Write \(t), then \(o)."),
             (10 * t, "That's only the tens. Add the \(Num1.pl(o, "one", "ones")) too.")]
        }
        public static let other = "Count the tens by 10s, then count on the ones."
        public func grouped(_ code: Int) -> String { "That's only \(o). A ten needs 10." }
        public static let why = "The first digit counts tens; the second counts ones."
    }
    /// The web's generator: 11–39 for the first three, then 11–99.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers { numbers(n: Int.random(in: 11...(i < 3 ? 39 : 99), using: &rng)) }

    public static let spec = LessonSpec(id: "g1-tensones", title: "Tens and ones", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How many?")] },
        idea: { _ in Parts.why },
        depends: ["k-teens", "k-tens"],
        check: [CheckItem(3, when: { Parts($0).t >= 4 }), CheckItem(3, when: { Parts($0).o == 0 }), CheckItem(3, when: { Parts($0).o > Parts($0).t }), CheckItem(3)]) { x in
        let P = Parts(x)
        let groupHint = "Tap a row of 10."
        let group = LessonStep(StepWords(say: "Tap each full row to make a ten.", hint: groupHint, action: "Check"),
            answer: TeensK.hand("g", P.t, hint: groupHint, explain: "\(Num1.pl(P.t, "ten", "tens")).", said: P.grouped),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let countHint = "Count the ones in the short row."
        let count = LessonStep(StepWords(say: "Now count the ones.", hint: countHint, action: "Check"),
            answer: TeensK.hand("c", P.o, hint: countHint, explain: "\(Num1.pl(P.o, "one", "ones")).", said: { _ in "That's a ten. Count the ones on their own." }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "\(Num1.pl(P.t, "ten", "tens")) is \(10 * P.t). Count on the ones."
        let write = LessonStep(StepWords(say: P.o > 0 ? Num1.writeBox : "No ones on their own. " + Num1.writeBox, hint: writeHint, action: "Check"),
            answer: Num1.write("x", P.n, P.slips, other: Parts.other, hint: writeHint, explain: "\(Num1.pl(P.t, "ten", "tens")) and \(Num1.pl(P.o, "one", "ones")) is \(P.n)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return P.o > 0 ? [group, count, write, done] : [group, write, done]
    }
}

// MARK: - Compare two-digit numbers

/// Compare two-digit numbers (the web's g1-compare; 1.NBT.3). Both numbers as tens (closed rows) and ones, side by side, a
/// block between; each number written over its stack. Tap the number with more tens (same tens: look at the ones); then
/// tap the sign (<, = and > in the gap): it's written between them.
///
/// "at": 0 tens, 1 ones (same tens only), 2 sign, 3 done. The picks' box "p": 0 the left number, 1 the right. The sign's
/// box "g": 0 <, 1 =, 2 >.
public enum Compare1 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public static let signs = ["<", "=", ">"]
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) { a = max(10, min(99, Num1.int(x, "a", 43))); b = max(10, min(99, Num1.int(x, "b", 47))) }
        public var ta: Int { Num1.tens(a) }
        public var tb: Int { Num1.tens(b) }
        public var ao: Int { Num1.ones(a) }
        public var bo: Int { Num1.ones(b) }
        public var same: Bool { ta == tb }
        /// The bigger one's side (0 left, 1 right; the left when equal).
        public var big: Int { a >= b ? 0 : 1 }
        public var sign: Int { a < b ? 0 : a == b ? 1 : 2 }
        public var bn: Int { max(a, b) }
        public var sn: Int { min(a, b) }
        public var tensMiss: String {
            let t = Num1.tens(bn)
            return "\(bn) has \(Num1.pl(t, "ten", "tens")) and \(sn) has \(Num1.tens(sn)). \(Num1.pl(t, "ten", "tens")) is more."
        }
        public var onesMiss: String {
            let o = Num1.ones(bn)
            return "\(bn) has \(Num1.pl(o, "one", "ones")) and \(sn) has \(Num1.ones(sn)). \(Num1.pl(o, "one", "ones")) is more."
        }
        public func signed(_ g: Int) -> String {
            if a == b { return "Same tens and same ones, so the numbers are equal." }
            return g == 1 ? "\(a) and \(b) are not the same number." : "The open side faces the bigger number, \(bn)."
        }
        public var onesSay: String { "Same tens: \(ta) and \(tb). Look at the ones. Tap the number with more ones." }
        public var signSay: String { (a == b ? "Same tens, same ones. " : "") + "Tap the sign that goes between them." }
        public static let why = "More tens is bigger; with the same tens, more ones is bigger."
    }
    /// The web's: different tens for the first three; then same tens 4 in 10, equal 1 in 10.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind = i < 3 ? 0 : Int.random(in: 0...9, using: &rng)
        if kind == 9 { let n = Int.random(in: 10...99, using: &rng); return numbers(a: n, b: n) }
        if kind >= 5 {
            let t = Int.random(in: 1...9, using: &rng), x = Int.random(in: 0...9, using: &rng)
            var y = Int.random(in: 0...8, using: &rng); if y >= x { y += 1 }
            return numbers(a: t * 10 + x, b: t * 10 + y)
        }
        let ta = Int.random(in: 1...9, using: &rng)
        var tb = Int.random(in: 1...8, using: &rng); if tb >= ta { tb += 1 }
        return numbers(a: ta * 10 + Int.random(in: 0...9, using: &rng), b: tb * 10 + Int.random(in: 0...9, using: &rng))
    }

    static func pick(_ want: Int, any: Bool, hint: String, explain: String, wrong: String) -> AnswerTask {
        AnswerTask(prompt: [.box("p")], expected: ["p": Double(want)], hint: hint, explain: explain,
                   check: { v in let p = Int((v["p"] ?? -1).rounded()); return any || p == want ? .right : .wrong(wrong) }, byHand: true)
    }

    public static let spec = LessonSpec(id: "g1-compare", title: "Compare two-digit numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("?"), .num(Double(P.b))] },
        idea: { _ in Parts.why },
        depends: ["g1-tensones", "k-compare"],
        check: [CheckItem(3, when: { let P = Parts($0); return !P.same && Num1.ones(P.sn) > Num1.ones(P.bn) }), CheckItem(3, when: { !Parts($0).same }),
                CheckItem(3, when: { let P = Parts($0); return P.same && P.a > P.b }), CheckItem(3, when: { let P = Parts($0); return P.same && P.a < P.b })]) { x in
        let P = Parts(x)
        let tensHint = "Count the rows of ten in each."
        let tens = LessonStep(StepWords(say: "Tap the number with more tens.", hint: tensHint, action: "Check"),
            answer: pick(P.big, any: P.same, hint: tensHint, explain: "\(P.bn) has more tens.", wrong: P.tensMiss),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let onesHint = "Count the ones under each."
        let ones = LessonStep(StepWords(say: P.onesSay, hint: onesHint, action: "Check"),
            answer: pick(P.big, any: P.ao == P.bo, hint: onesHint, explain: "\(P.bn) has more ones.", wrong: P.onesMiss),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let signHint = "The open side faces the bigger number."
        let sign = LessonStep(StepWords(say: P.signSay, hint: signHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("g")], expected: ["g": Double(P.sign)], hint: signHint, explain: "\(P.a) \(Compare1.signs[P.sign]) \(P.b)",
                               check: { v in let g = Int((v["g"] ?? -1).rounded()); return g == P.sign ? .right : .wrong(P.signed(g)) }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return P.same ? [tens, ones, sign, done] : [tens, sign, done]
    }
}

// MARK: - 10 more, 10 less

/// 10 more, 10 less (the web's g1-tenmore; 1.NBT.5). Three rows of the 120 chart: n's row, the row above and the row below,
/// n ringed. Drag the ring down (10 more) or up (10 less): it snaps a place at a time; the readout says how far. Then both
/// numbers' tens digits light and their ones digits are underlined: the ones stay. Write the record: 34 + 10 = [44].
///
/// "at": 0 drag, 1 write, 2 done. The drag's box "d": where the ring landed, less n (+10 or −10 right).
public enum TenMore1 {
    public static func numbers(n: Int, more: Bool) -> Numbers { ["n": Double(n), "more": more ? 1 : 0] }
    public struct Parts: Sendable {
        public let n: Int, more: Bool
        public init(_ x: Numbers) {
            more = Num1.int(x, "more", 1) == 1
            n = max(more ? 11 : 20, min(89, Num1.int(x, "n", 34)))
        }
        public var w: String { more ? "more" : "less" }
        public var dir: String { more ? "down" : "up" }
        public var res: Int { more ? n + 10 : n - 10 }
        public var o: Int { Num1.ones(n) }
        public var newT: Int { Num1.tens(res) }
        public var op: String { more ? "+" : "−" }
        public func landed(_ d: Int) -> String {
            if d == -(res - n) { return "That's 10 \(more ? "less" : "more"). Go \(dir) for 10 \(w)." }
            return "That's \(abs(d)) \(d > 0 ? "more" : "less"). 10 \(w) is one row \(dir)."
        }
        public var slips: [(Int, String)] {
            [(n + (more ? 1 : -1), "That's 1 \(w). For 10 \(w), change the tens and keep \(o > 0 ? "the \(Num1.pl(o, "one", "ones"))" : "the ones the same")."),
             (more ? n - 10 : n + 10, "That's 10 \(more ? "less" : "more"). You want 10 \(w)."),
             (newT, "That's only the tens. \(o > 0 ? "Put the \(Num1.pl(o, "one", "ones")) back on the end." : "Put the 0 back in the ones place.")")]
        }
        public var other: String { "\(Num1.pl(newT, "ten", "tens")) and \(Num1.pl(o, "one", "ones"))." }
        public var why: String { more ? "One row down is one more ten; the ones stay." : "One row up is one ten less; the ones stay." }
    }
    /// The web's: 10 more for the first two; n 11–49 for the first three, then 11–89; 10 less keeps the answer two digits;
    /// the first four keep some ones.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let more = i < 2 ? true : Bool.random(using: &rng)
        var n = i < 3 ? Int.random(in: 11...49, using: &rng) : Int.random(in: 11...89, using: &rng)
        if !more && n < 20 { n += 10 }
        if n % 10 == 0 && i < 4 { n += Int.random(in: 1...9, using: &rng) }
        return numbers(n: n, more: more)
    }

    public static let spec = LessonSpec(id: "g1-tenmore", title: "10 more, 10 less", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.n)), .op(P.op), .num(10), .op("="), .box("q")] },
        idea: { _ in "One row down is one more ten; the ones stay." },
        depends: ["g1-tensones", "k-tens"],
        check: [CheckItem(3, when: { Parts($0).more }), CheckItem(3, when: { !Parts($0).more }), CheckItem(4, when: { Parts($0).n % 10 == 0 }),
                CheckItem(3, when: { !Parts($0).more && Parts($0).n >= 50 })]) { x in
        let P = Parts(x)
        let dragHint = "10 \(P.w) is one row \(P.dir)."
        let drag = LessonStep(StepWords(say: "Drag the ring to 10 \(P.w).", hint: dragHint, action: "Check"),
            answer: TeensK.hand("d", P.res - P.n, hint: dragHint, explain: "10 \(P.w) than \(P.n) is \(P.res).", said: P.landed),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: Num1.writeBox, hint: P.other, action: "Check"),
            answer: Num1.write("x", P.res, P.slips, other: P.other, hint: P.other, explain: "\(P.n) \(P.op) 10 = \(P.res)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [drag, write, done]
    }
}
