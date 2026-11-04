import Foundation

/// What 2nd grade's chapter 4, Length, shares (design/grade2.md chapter 4, the preview design/prototype/grade2-ch4.html):
/// an inch is a block and a centimeter 2 squares, so an inch is 2½ cm on the paper, as in life; feet and meters are drawn
/// smaller (a foot a block, a meter 2 blocks). A hop along a ruler or a line is set as one code, where it started and where
/// it ended (`code`), so its miss can say both. Every number the child writes is typed with the iPad's keys and Check, as
/// the preview types; the hands do the rest.
public enum Len2 {
    public struct Unit: Sendable { public let u: String, per: Double, one: String, many: String }
    public static let units: [String: Unit] = [
        "in": Unit(u: "in", per: 5, one: "inch", many: "inches"), "cm": Unit(u: "cm", per: 2, one: "centimeter", many: "centimeters"),
        "ft": Unit(u: "ft", per: 5, one: "foot", many: "feet"), "m": Unit(u: "m", per: 10, one: "meter", many: "meters"),
    ]
    public static func unit(_ u: String) -> Unit { units[u] ?? units["in"]! }
    /// A hop from one mark to another, as one number: from × 1000 + to.
    public static func code(_ from: Int, _ to: Int) -> Int { from * 1000 + to }
    public static func decode(_ k: Int) -> (from: Int, to: Int) { (max(0, k) / 1000, max(0, k) % 1000) }
    public static let spaces = "Count the spaces between the marks, not the marks themselves."
    public static let names: [(String, String)] = [("Mia", "she"), ("Leo", "he"), ("Ana", "she"), ("Sam", "he"), ("Zoe", "she"), ("Ben", "he")]
    /// The hops from a to b: whole hops of `big` first, then ones (or the rest in one hop).
    public static func hops(_ a: Int, _ b: Int, big: Int = 1, restInOne: Bool = false) -> [(Int, Int)] {
        let s = b >= a ? 1 : -1
        var out: [(Int, Int)] = [], p = a
        while abs(b - p) >= big { out.append((p, p + s * big)); p += s * big }
        if p != b {
            if restInOne { out.append((p, b)) } else { while p != b { out.append((p, p + s)); p += s } }
        }
        return out
    }
    /// A list of landings, short: 1, 2, 3 … 7.
    public static func landings(_ l: [Int]) -> String {
        guard l.count > 4 else { return l.map(String.init).joined(separator: ", ") }
        return "\(l[0]), \(l[1]), \(l[2]) … \(l[l.count - 1])"
    }
    /// A hop's miss on a ruler: started somewhere else, or stopped short or past the end.
    static func hopMiss(_ k: Int, from: Int, to: Int, name: String, startName: String) -> String {
        let c = decode(k)
        if c.from != from { return "Start at the \(startName)'s end." }
        return "That's \(abs(c.to - c.from)). The \(name) goes on to \(to)."
    }
}

// MARK: - Inches and centimeters

/// Inches and centimeters (the web's g2-measure; 2.MD.A.1, fold 2.MD.A.4). The ruler, a strip 3 squares tall (inches 0–10,
/// 50 squares; centimeters 0–15, 30), the thing just above it, its ends on marks, dashed lines dropping from them. Hop from
/// end to end a space at a time, then write `9 − 2 = [7] cm` (from 0, `[7] cm`). The fold (problems 4, 8, 12 …): two things
/// from 0 on one ruler; hop the part sticking out.
///
/// "unit" 0 inches, 1 centimeters; "th" the thing (and "th2", the fold's shorter one); "start", "end" (the fold: "short",
/// "long", "fold" 1). "at": 0 hop, 1 write, 2 done. Boxes: "h" the hop (Len2.code), "x" the length.
public enum Measure2 {
    public static let things = ["pencil", "crayon", "ribbon", "straw"]
    static let range: [(u: String, max: Int, min: Int, hi: Int)] = [("in", 10, 2, 7), ("cm", 15, 3, 11)]
    public static func numbers(unit: Int, th: Int, start: Int, end: Int) -> Numbers {
        ["unit": Double(unit), "th": Double(th), "start": Double(start), "end": Double(end)]
    }
    public static func fold(unit: Int, th: Int, th2: Int, long: Int, short: Int) -> Numbers {
        ["unit": Double(unit), "th": Double(th), "th2": Double(th2), "long": Double(long), "short": Double(short), "fold": 1]
    }
    public struct Parts: Sendable {
        public let fold: Bool, unit: Int, th: Int, th2: Int, from: Int, to: Int
        public init(_ x: Numbers) {
            fold = G2.int(x, "fold") != 0
            unit = max(0, min(1, G2.int(x, "unit")))
            th = max(0, min(3, G2.int(x, "th"))); th2 = max(0, min(3, G2.int(x, "th2", (G2.int(x, "th") + 1) % 4)))
            let m = Measure2.range[unit].max
            if fold {
                let lo = max(1, G2.int(x, "short", 3)), hi = max(lo + 1, G2.int(x, "long", 6))
                from = min(lo, m - 1); to = min(hi, m)
            } else {
                let s = max(0, G2.int(x, "start")), e = max(s + 1, G2.int(x, "end", 5))
                from = min(s, m - 1); to = min(e, m)
            }
        }
        public var u: String { Measure2.range[unit].u }
        public var top: Int { Measure2.range[unit].max }
        public var per: Double { Len2.unit(u).per }
        public var name: String { Measure2.things[th] }
        public var name2: String { Measure2.things[th2] }
        public var L: Int { to - from }
        public var sayHop: String { fold ? "Hop the part sticking out." : "Hop from end to end." }
        public var why: String { fold ? "Lined up at 0, the part sticking out is how much longer." : "Each hop is one space, and the spaces are the length." }
        public func hopMiss(_ k: Int) -> String { Len2.hopMiss(k, from: from, to: to, name: name, startName: fold ? name2 : name) }
        /// The record's left side: `9 − 2 =` (nothing when it starts at 0).
        public var minus: Bool { fold || from > 0 }
        public var slips: [(Int, String)] {
            if fold {
                return [(to, "That's the whole \(name). Write the part sticking out."), (L + 1, Len2.spaces), (from, "That's the \(name2). Write the part sticking out.")]
            }
            var out: [(Int, String)] = []
            if from > 0 { out.append((to, "The \(name) starts at \(from), not 0. Count the spaces from \(from) to \(to).")) }
            out.append((L + 1, Len2.spaces))
            if from > 0 { out.append((to + from, "Take away the start: the ruler before \(from) is not part of the \(name).")) }
            return out
        }
        public var plain: String { minus ? "Count the hops from \(from) to \(to)." : "It starts at 0, so the end is the length." }
    }

    /// The preview's: inches 2–7 on a 0–10 ruler or centimeters 3–11 on 0–15; problems 0–2 from 0, later never; the fold on
    /// problems 4, 8, 12 … (two lengths at least 1 apart).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let unit = r(0, 1), m = range[unit], th = r(0, 3)
        if i >= 4 && i % 4 == 0 {
            var a = 0, b = 0
            repeat { a = r(m.min, m.hi); b = r(m.min, m.hi) } while abs(a - b) < 1
            return fold(unit: unit, th: th, th2: (th + r(1, 3)) % 4, long: max(a, b), short: min(a, b))
        }
        let len = r(m.min, m.hi), start = i < 3 ? 0 : r(1, m.max - len)
        return numbers(unit: unit, th: th, start: start, end: start + len)
    }

    public static let spec = LessonSpec(id: "g2-measure", title: "Inches and centimeters", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.box("x"), .text(P.u)] },
        idea: { x in Parts(x).why },
        depends: ["g1-measure"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).unit == 0 }), CheckItem(3, when: { Parts($0).unit == 1 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let hopHint = P.fold ? "Start where the \(P.name2) ends." : "Start under the \(P.name)'s left end."
        let hop = LessonStep(StepWords(say: P.sayHop, hint: hopHint, action: "Check"),
            answer: G2.hand("h", Len2.code(P.from, P.to), hint: hopHint, explain: "\(P.L) \(P.u).", said: { P.hopMiss($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: "Write how long it is.", hint: P.plain, action: "Check"),
            answer: G2.typed("x", P.L, P.slips, plain: P.plain, hint: P.plain, explain: "\(P.L) \(P.u)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [hop, write, done]
    }
}

// MARK: - Measure with two units

/// Measure with two units (g2-twounits, new; 2.MD.A.2). The thing in the middle, an inch ruler over it (its marks hang
/// down to it) and a centimeter ruler under it, both from its left end; an even number of inches, so both read whole. Hop
/// the inch ruler, write `[6] in`; hop the centimeter ruler, write `[15] cm`; tap the bigger unit: one inch and one
/// centimeter lift out and lie side by side.
///
/// "inches" (2, 4 … 12). "at": 0 hop inches, 1 write, 2 hop centimeters, 3 write, 4 the bigger unit, 5 done. Boxes: "hi",
/// "hc" the hops (Len2.code), "in", "cm" written, "b" the unit tapped (1 an inch, 2 a centimeter).
public enum TwoUnits2 {
    public static let things: [Int: String] = [2: "key", 4: "crayon", 6: "spoon", 8: "pencil", 10: "book", 12: "ruler"]
    public static func numbers(inches: Int) -> Numbers { ["inches": Double(inches)] }
    public struct Parts: Sendable {
        public let n: Int
        public init(_ x: Numbers) { let v = max(2, min(12, G2.int(x, "inches", 6))); n = v % 2 == 0 ? v : v + 1 }
        public var cm: Int { n * 5 / 2 }
        public var name: String { TwoUnits2.things[n] ?? "pencil" }
        /// The rulers: two inches past the thing (12 at most), and as many centimeters.
        public var imax: Int { min(12, n + 2) }
        public var cmax: Int { imax * 5 / 2 }
        public func hopMiss(_ k: Int, cm inCm: Bool) -> String {
            let c = Len2.decode(k), want = inCm ? cm : n
            if c.from != 0 { return "Start at the \(name)'s end." }
            return "That's \(c.to). The \(name) goes on to \(want)."
        }
        public var smaller: String { "\(cm) is more, but each centimeter is smaller." }
        public static let why = "A centimeter is smaller, so more of them fit."
    }

    /// The design's: problems 0–2 2–6 inches, from 3 any of 2–12.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        numbers(inches: 2 * (i < 3 ? Int.random(in: 1...3, using: &rng) : Int.random(in: 1...6, using: &rng)))
    }

    public static let spec = LessonSpec(id: "g2-twounits", title: "Measure with two units", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.n)), .text("in"), .op("="), .box("cm"), .text("cm")] },
        idea: { _ in Parts.why },
        depends: ["g2-measure"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).n >= 8 }), CheckItem(3), CheckItem(3)]) { x in
        let P = Parts(x)
        let startHint = "Start at the \(P.name)'s left end."
        let hopIn = LessonStep(StepWords(say: "Measure in inches.", hint: startHint, action: "Check"),
            answer: G2.hand("hi", Len2.code(0, P.n), hint: startHint, explain: "\(P.n) in.", said: { P.hopMiss($0, cm: false) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let inSlips = [(P.n + 1, Len2.spaces), (P.cm, "That's the centimeters. Count the inches.")]
        let inPlain = "Count the hops on the inch ruler."
        let writeIn = LessonStep(StepWords(say: "Write how many inches.", hint: inPlain, action: "Check"),
            answer: G2.typed("in", P.n, inSlips, plain: inPlain, hint: inPlain, explain: "\(P.n) in."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let hopCm = LessonStep(StepWords(say: "Now in centimeters.", hint: startHint, action: "Check"),
            answer: G2.hand("hc", Len2.code(0, P.cm), hint: startHint, explain: "\(P.cm) cm.", said: { P.hopMiss($0, cm: true) }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let cmSlips = [(P.cm + 1, Len2.spaces), (P.n, "That's the inches. Count the centimeters.")]
        let cmPlain = "Count the hops on the centimeter ruler."
        let writeCm = LessonStep(StepWords(say: "Write how many centimeters.", hint: cmPlain, action: "Check"),
            answer: G2.typed("cm", P.cm, cmSlips, plain: cmPlain, hint: cmPlain, explain: "\(P.cm) cm."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let bigHint = "Look at one space on each ruler."
        let bigger = LessonStep(StepWords(say: "Tap the bigger unit.", hint: bigHint, action: "Check"),
            answer: G2.hand("b", 1, hint: bigHint, explain: "An inch is bigger.", said: { _ in P.smaller }),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 5])
        return [hopIn, writeIn, hopCm, writeCm, bigger, done]
    }
}

// MARK: - Estimate length

/// Estimate length (the web's g2-estimate; 2.MD.A.3, 2.MD.A.1, fold). The thing, its benchmark above its left end (a
/// paper clip, about an inch, a block long; a centimeter cube, 2 × 2). Tap a guess (three word blocks): right, the
/// benchmarks lay themselves end to end along it, counted; wrong, the guess draws dashed along it. The ruler slides in
/// under it: hop it, then write `[6] in` under `about 6 in`. The fold (problems 6, 9, 12 …): a long thing drawn smaller (a
/// foot a block, a meter 2 blocks), guessed by a foot ruler or a meter stick, then measured by hopping the ruler, the
/// stick or (6 feet or more) a yardstick along it (`3, 6, 7 ft`).
///
/// "fold"; "unit" 0 inches, 1 centimeters, or "u" 0 feet, 1 meters (the fold); "thing", "len", "start". "at": 0 guess,
/// 1 hop, 2 write, 3 done. Boxes: "g" the guess tapped, "h" the hop (Len2.code), "x" the length.
public enum Estimate2 {
    struct Thing { let name: String, lo: Int, hi: Int }
    static let small: [[Thing]] = [
        [Thing(name: "crayon", lo: 3, hi: 4), Thing(name: "marker", lo: 5, hi: 5), Thing(name: "pencil", lo: 6, hi: 7),
         Thing(name: "spoon", lo: 6, hi: 6), Thing(name: "shoe", lo: 9, hi: 10), Thing(name: "book", lo: 11, hi: 11)],
        [Thing(name: "paper clip", lo: 3, hi: 3), Thing(name: "crayon", lo: 9, hi: 9), Thing(name: "eraser", lo: 5, hi: 5),
         Thing(name: "marker", lo: 13, hi: 13), Thing(name: "spoon", lo: 15, hi: 15), Thing(name: "pencil", lo: 18, hi: 18)],
    ]
    static let long: [[Thing]] = [
        [Thing(name: "desk", lo: 3, hi: 4), Thing(name: "rug", lo: 5, hi: 5), Thing(name: "bed", lo: 6, hi: 7),
         Thing(name: "door", lo: 7, hi: 7), Thing(name: "board", lo: 8, hi: 8)],
        [Thing(name: "door", lo: 2, hi: 2), Thing(name: "board", lo: 3, hi: 3), Thing(name: "car", lo: 4, hi: 4), Thing(name: "log", lo: 5, hi: 5)],
    ]
    public static func numbers(unit: Int, thing: Int, len: Int, start: Int = 0) -> Numbers {
        ["unit": Double(unit), "thing": Double(thing), "len": Double(len), "start": Double(start)]
    }
    public static func fold(meters: Bool, thing: Int, len: Int) -> Numbers {
        ["fold": 1, "u": meters ? 1 : 0, "thing": Double(thing), "len": Double(len)]
    }
    public struct Parts: Sendable {
        public let fold: Bool, unit: Int, thing: Int, len: Int, start: Int
        public init(_ x: Numbers) {
            fold = G2.int(x, "fold") != 0
            unit = max(0, min(1, G2.int(x, fold ? "u" : "unit")))
            let list = fold ? Estimate2.long[unit] : Estimate2.small[unit]
            thing = max(0, min(list.count - 1, G2.int(x, "thing")))
            len = max(list[thing].lo, min(list[thing].hi, G2.int(x, "len", list[thing].lo)))
            let room = (unit == 0 ? 12 : 20) - len
            start = fold ? 0 : max(0, min(room, G2.int(x, "start")))
        }
        public var u: String { fold ? (unit == 0 ? "ft" : "m") : (unit == 0 ? "in" : "cm") }
        public var U: Len2.Unit { Len2.unit(u) }
        public var name: String { (fold ? Estimate2.long[unit] : Estimate2.small[unit])[thing].name }
        /// The benchmark: a paper clip, a cube, a foot ruler, a meter stick; the tool hopped in the fold.
        public var bench: String { fold ? (unit == 0 ? "foot" : "meter") : (unit == 0 ? "clip" : "cube") }
        public var benchName: String { fold ? (unit == 0 ? "foot ruler" : "meter stick") : (unit == 0 ? "paper clip" : "cube") }
        public var benches: String { unit == 0 && !fold ? "paper clips" : benchName + "s" }
        public var tool: String { fold ? (unit == 0 ? (len >= 6 ? "yard" : "foot") : "meter") : "ruler" }
        public var step: Int { tool == "yard" ? 3 : 1 }
        public var top: Int {
            if fold { return Swift.max(len + 1, (len + step - 1) / step * step) }
            return unit == 0 ? Swift.min(12, Swift.max(6, start + len + 2)) : Swift.max(10, start + len + 2)
        }
        /// The three guesses: its length; a quarter of it and four times it (a fifth and five times in centimeters or meters).
        public var smallGuess: Int { Swift.max(1, Int((Double(len) / Double(u == "cm" || u == "m" ? 5 : 4)).rounded())) }
        public var bigGuess: Int { len * (u == "cm" || u == "m" ? 5 : 4) }
        public var guesses: [Int] {
            let vals = [len, smallGuess, bigGuess], k = (thing + start + len) % 3
            return Array(vals[k...] + vals[..<k])
        }
        public func label(_ v: Int) -> String { G2.count(v, U.one, U.many) }
        public func guessMiss(_ v: Int) -> String {
            let n = label(v)
            if fold { return v == smallGuess ? "\(n) is \(G2.count(v, benchName)). The \(name) is much longer than that." : "\(n) is much longer than the \(name)." }
            if v == smallGuess { return "\(n) is about \(G2.count(v, benchName, benches)). The \(name) is much longer than that." }
            let far = unit == 0 ? 12 : 30
            return v > far ? "\(n) is longer than a whole ruler." : "\(n) is much longer than the \(name)."
        }
        public var why: String {
            if fold { return tool == "yard" ? "A yardstick is 3 feet, so count by 3s, then the rest." : "A \(benchName) is one \(U.one), and \(len) fit along the \(name)." }
            return "A \(benchName) is about \(unit == 0 ? "an inch" : "a centimeter"), and about \(len) fit."
        }
        public var end: Int { start + len }
        public func hopMiss(_ k: Int) -> String { Len2.hopMiss(k, from: start, to: end, name: name, startName: name) }
        public var slips: [(Int, String)] {
            if fold { return [(len + 1, "Count the hops, not the marks.")] }
            var out: [(Int, String)] = []
            if start > 0 { out.append((end, "The \(name) starts at \(start), not 0. Count the spaces from \(start) to \(end).")) }
            out.append((len + 1, "Count the spaces between the marks, not the marks."))
            return out
        }
        public var plain: String {
            if fold { return "Count the hops along the \(name)." }
            return start > 0 ? "It starts at \(start), so count the spaces from there." : "It starts at 0, so read the number at its end."
        }
        /// The hops the fold's tool makes: whole tools, then the rest.
        public var toolHops: [(Int, Int)] { Len2.hops(0, len, big: step, restInOne: true) }
    }

    /// The preview's: inches first (problems 0–2 from 0); then the units mixed and starts 0–2; a new thing each time; the
    /// fold on problems 6, 9, 12 ….
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if i >= 6 && i % 3 == 0 {
            let m = r(0, 1), list = long[m], t = r(0, list.count - 1)
            return fold(meters: m == 1, thing: t, len: r(list[t].lo, list[t].hi))
        }
        let early = i < 3, unit = early ? 0 : r(0, 1), list = small[unit], t = (i * 5 + 2) % list.count
        let len = r(list[t].lo, list[t].hi)
        return numbers(unit: unit, thing: t, len: len, start: early ? 0 : min(r(0, 2), (unit == 0 ? 12 : 20) - len))
    }

    public static let spec = LessonSpec(id: "g2-estimate", title: "Estimate length", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.text("about"), .box("x"), .text(P.u)] },
        idea: { x in Parts(x).why },
        depends: ["g2-measure"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).u == "cm" }), CheckItem(4, when: { Parts($0).u == "in" && Parts($0).start > 0 }), CheckItem(5)]) { x in
        let P = Parts(x)
        let guessHint = "Think how many \(P.benches) fit along it."
        let guess = LessonStep(StepWords(say: "Guess with the \(P.benchName).", hint: guessHint, action: "Check"),
            answer: G2.hand("g", P.len, hint: guessHint, explain: "About \(P.label(P.len)).", said: { P.guessMiss($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let hopHint = "Start at the \(P.name)'s end."
        let hop = LessonStep(StepWords(say: "Now measure it.", hint: hopHint, action: "Check"),
            answer: G2.hand("h", Len2.code(P.start, P.end), hint: hopHint, explain: "\(P.len) \(P.u).", said: { P.hopMiss($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: "Write how long it is.", hint: P.plain, action: "Check"),
            answer: G2.typed("x", P.len, P.slips, plain: P.plain, hint: P.plain, explain: "\(P.len) \(P.u)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [guess, hop, write, done]
    }
}

// MARK: - Lengths on a number line

/// Lengths on a number line (g2-numline, new; 2.MD.B.5, 2.MD.B.6, 2.MD.A.1). One square is one unit of the story, a tape
/// measure on a strong line: a mark every square, longer every 5, numbered every 10; to 50 the line is 0–50, past 50 a
/// square stands for 2 (0–100, still 50 squares) and the page says so (then every number in the story is even, so each
/// bar ends on a whole square). The story on the top rows; each length a bar 3 squares tall over the line from 0. Drag a
/// bar's end from 0; hop from its end, tens then ones; write the answer.
///
/// "kind" 0 joining, 1 cutting off, 2 comparing, 3 a part missing; "a", "b"; "th" the thing; "who", "other" the names.
/// "at": the drags (comparing: two), then the hop, the write, done. Boxes: "d0", "d1" the bars dragged, "h" the hop
/// (Len2.code), "x" the answer.
public enum Numline2 {
    public enum Kind: Int, Sendable { case join, cut, cmp, part }
    public static let units: [String: String] = ["ribbon": "cm", "rope": "ft", "string": "in", "path": "m", "fence": "m", "board": "in"]
    public static let things: [[String]] = [["ribbon", "rope", "string", "path", "fence", "board"], ["ribbon", "rope", "string", "board"],
                                            ["ribbon", "rope", "string", "path", "fence", "board"], ["ribbon", "rope", "string", "fence"]]
    public static func numbers(kind: Kind, a: Int, b: Int, th: Int = 0, who: Int = 0, other: Int = 1) -> Numbers {
        ["kind": Double(kind.rawValue), "a": Double(a), "b": Double(b), "th": Double(th), "who": Double(who), "other": Double(other)]
    }
    public struct Bar: Sendable { public let v: Int, whole: Bool, name: String?, lab: String? }
    public struct Parts: Sendable {
        public let kind: Kind, a: Int, b: Int, th: Int, who: Int, other: Int
        public init(_ x: Numbers) {
            kind = Kind(rawValue: G2.int(x, "kind")) ?? .join
            let a0 = max(10, min(90, G2.int(x, "a", 45))), b0 = max(1, min(60, G2.int(x, "b", 18)))
            if kind == .join { a = min(a0, 99); b = min(b0, 100 - a) } else { a = a0; b = min(b0, a0 - 1) }
            th = max(0, min(Numline2.things[kind.rawValue].count - 1, G2.int(x, "th")))
            who = max(0, min(5, G2.int(x, "who"))); let o = max(0, min(5, G2.int(x, "other", 1)))
            other = o == who ? (who + 1) % 6 : o
        }
        public var ans: Int { kind == .join ? a + b : a - b }
        public var hi: Int { kind == .join ? a + b : a }
        /// Things per square: 1 to 50, 2 past it.
        public var per: Int { hi > 50 ? 2 : 1 }
        public var thing: String { Numline2.things[kind.rawValue][th] }
        public var u: String { Numline2.units[thing] ?? "cm" }
        public var N: String { Len2.names[who].0 }
        public var pr: String { Len2.names[who].1 }
        public var Pr: String { G2.cap(pr) }
        public var M: String { Len2.names[other].0 }
        public var lines: [String] {
            switch kind {
            case .join: return ["\(N) has a \(thing) \(a) \(u) long.", "\(Pr) adds \(b) \(u) more.", "How long is it now?"]
            case .cut: return ["\(N) has a \(thing) \(a) \(u) long.", "\(Pr) cuts off \(b) \(u).", "How long is it now?"]
            case .cmp: return ["\(N)'s \(thing) is \(a) \(u) long.", "\(M)'s \(thing) is \(b) \(u) long.", "How much longer is \(N)'s?"]
            case .part: return ["\(N) needs \(a) \(u) of \(thing).", "\(Pr) has \(b) \(u).", "How much more does \(pr) need?"]
            }
        }
        public var scale: String { "A square is 2 \(u)." }
        /// The bars over the line, top first.
        public var bars: [Bar] {
            switch kind {
            case .cmp: return [Bar(v: a, whole: false, name: "\(N)'s \(thing)", lab: N), Bar(v: b, whole: false, name: "\(M)'s \(thing)", lab: M)]
            case .part: return [Bar(v: a, whole: true, name: nil, lab: nil), Bar(v: b, whole: false, name: nil, lab: nil)]
            default: return [Bar(v: a, whole: false, name: nil, lab: nil)]
            }
        }
        /// The bars the hands drag, in order.
        public var drags: [Int] { kind == .cmp ? [0, 1] : kind == .part ? [1] : [0] }
        public var hopFrom: Int { kind == .join || kind == .cut ? a : b }
        public var hopTo: Int { kind == .join ? a + b : kind == .cut ? a - b : a }
        public var hopRow: Int { kind == .join || kind == .cut ? 0 : 1 }
        public var hopSay: String { kind == .cut ? "Hop back \(b)." : kind == .join ? "Hop on \(b)." : "Hop from \(b) to \(a)." }
        public func dragSay(_ j: Int) -> String { "Drag from 0 to \(bars[j].v)." }
        public func dragMiss(_ j: Int, _ v: Int) -> String {
            let want = bars[j].v
            switch kind {
            case .cmp: return "That's \(v). \(G2.cap(bars[j].name ?? thing)) is \(want) \(u)."
            case .part: return "That's \(v). \(Pr) has \(want) \(u)."
            default: return "That's \(v). The \(thing) is \(want) \(u)."
            }
        }
        public func hopMiss(_ k: Int) -> String {
            let c = Len2.decode(k), n = abs(c.to - c.from)
            if c.from != hopFrom {
                return kind == .cmp ? "Start at the end of \(M)'s \(thing)." : kind == .part ? "Start at the end of the \(thing) \(pr) has." : "Start at the \(thing)'s end."
            }
            if (c.to > c.from) != (hopTo > hopFrom) { return kind == .cut ? "\(Pr) cut some off. Hop back." : kind == .join ? "\(Pr) added more. Hop on." : "Hop on to \(a)." }
            return kind == .cut ? "That's \(n) back. Hop \(b)." : kind == .join ? "That's \(n) on. Hop \(b)." : "That's \(c.to). Hop on to \(a)."
        }
        /// The hop's miss clears it (a start or a way that's wrong), or keeps it to go on from (short or past).
        public func clears(_ k: Int) -> Bool { let c = Len2.decode(k); return c.from != hopFrom || (c.to > c.from) != (hopTo > hopFrom) }
        public var why: String {
            switch kind {
            case .join: return "Every number is a length from 0, so hopping on adds length."
            case .cut: return "Every number is a length from 0, so hopping back takes length off."
            case .cmp: return "The gap between the ends is how much longer."
            case .part: return "The gap between the ends is how much more is needed."
            }
        }
        public var slips: [(Int, String)] {
            let other: (Int, String)
            switch kind {
            case .join: other = (abs(a - b), "It got longer, so add.")
            case .cut: other = (a + b, "Some was cut off, so it's shorter.")
            case .cmp: other = (a + b, "Take the shorter from the longer.")
            case .part: other = (a + b, "It's the part still needed, so it's less than \(a).")
            }
            return [other, (ans + 10, "Count the ten-hops again."), (ans - 10, "Count the ten-hops again."), (ans + 1, "Count the hops, not the marks.")]
        }
        public static let plain = "Count the hops: tens, then ones."
        /// The hops' readout: `45 − 10 = 35 … 27`.
        public static func readout(from: Int, to: Int) -> String {
            let hs = Len2.hops(from, to, big: 10)
            guard let f = hs.first else { return "" }
            let sign = f.1 > f.0 ? "+" : "−"
            return "\(from) \(sign) \(abs(f.1 - f.0)) = \(f.1)" + (hs.count > 1 ? " … \(to)" : "")
        }
    }

    /// The design's (and the preview's): joining, cutting off, comparing, a part missing; the first length 10–90, the
    /// second 5–60, every answer 1–100. Problems 0–2 join, cut, compare, within 50, the second a whole ten or under 10, no
    /// ten crossed; from 3 any kind, crossing a ten, to 100. Past 50 every number is even (a square stands for 2).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let kind: Kind = i == 0 ? .join : i == 1 ? .cut : i == 2 ? .cmp : Kind(rawValue: r(0, 3)) ?? .join
        var a = 0, b = 0
        while true {
            a = r(10, 90); b = r(5, 60)
            if i < 3 && !(b < 10 || b % 10 == 0) { continue }
            let ans = kind == .join ? a + b : a - b, hi = kind == .join ? a + b : a
            if ans < 1 || ans > 100 || (i < 3 && hi > 50) { continue }
            if hi > 50 && (a % 2 != 0 || b % 2 != 0) { continue }
            let cross = kind == .join ? a % 10 + b % 10 >= 10 : a % 10 < b % 10
            if i < 3 ? cross : !cross { continue }
            break
        }
        let who = r(0, 5)
        var other = r(0, 5)
        while other == who { other = r(0, 5) }
        return numbers(kind: kind, a: a, b: b, th: r(0, things[kind.rawValue].count - 1), who: who, other: other)
    }

    public static let spec = LessonSpec(id: "g2-numline", title: "Lengths on a number line", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in
            let P = Parts(x)
            return [.num(Double(P.a)), .op(P.kind == .join ? "+" : "−"), .num(Double(P.b)), .op("="), .box("x")]
        },
        idea: { x in Parts(x).why },
        depends: ["g2-measure", "g2-subregroup"],
        check: [CheckItem(3, when: { Parts($0).kind == .cut }), CheckItem(3, when: { Parts($0).kind == .cmp }),
                CheckItem(3, when: { Parts($0).kind == .part }), CheckItem(3)]) { x in
        let P = Parts(x)
        var steps: [LessonStep] = []
        for (k, j) in P.drags.enumerated() {
            let want = P.bars[j].v
            let hint = "Drag the bar's end along the line to \(want)."
            steps.append(LessonStep(StepWords(say: P.dragSay(j), hint: hint, action: "Check"),
                answer: G2.hand("d\(j)", want, hint: hint, explain: "\(want) \(P.u).", said: { P.dragMiss(j, $0) }),
                picture: ["at": Double(k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let n = P.drags.count
        let hopHint = "Hop the tens first, then the ones."
        steps.append(LessonStep(StepWords(say: P.hopSay, hint: hopHint, action: "Check"),
            answer: G2.hand("h", Len2.code(P.hopFrom, P.hopTo), hint: hopHint, explain: Parts.readout(from: P.hopFrom, to: P.hopTo), said: { P.hopMiss($0) }),
            picture: ["at": Double(n)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: G2.write, hint: Parts.plain, action: "Check"),
            answer: G2.typed("x", P.ans, P.slips, plain: Parts.plain, hint: Parts.plain, explain: "\(P.ans) \(P.u)."),
            picture: ["at": Double(n + 1)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": Double(n + 2)]))
        return steps
    }
}
