import Foundation

/// 1st grade's chapter 5, Length, time and graphs (design/grade1.md chapter 5, the preview design/prototype/grade1-ch5.html).
/// One cube of length is one block (Unit cubes), so a thing n cubes long is n blocks and the strong lines count it; on the
/// clock one square is one minute (the hour strip is 60 squares); on a graph one picture is one block and a tally mark is
/// 2 squares. Every number is written with the drawn digit pad and Check; every line is spoken (App's Voice); the
/// preview's grey second line is folded into the instruction.
public enum Len1 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G1.int(v, k, d) }
    public static let things = ["pencil", "crayon", "ribbon", "straw", "spoon", "leaf", "brush", "key"]
    public static let stuck = things + ["rug", "desk"]
    public static func pl(_ n: Int, _ one: String, _ many: String) -> String { Num1.pl(n, one, many) }
    /// "1, 2, 3" or "1, 2 … 8".
    public static func run(_ ns: [Int]) -> String { Num1.run(ns) }
    public static let writeBox = Num1.writeBox

    /// The data lessons' themes (the web's), each row with its own small picture.
    public struct Theme: Sendable {
        public let title: String, names: [String], nouns: [String], one: [String], icons: [String]
    }
    public static let themes = [
        Theme(title: "Favorite fruit", names: ["Apples", "Bananas", "Grapes"], nouns: ["apples", "bananas", "grapes"], one: ["apple", "banana", "grape"], icons: ["apple", "banana", "grapes"]),
        Theme(title: "Our pets", names: ["Dogs", "Cats", "Fish"], nouns: ["dogs", "cats", "fish"], one: ["dog", "cat", "fish"], icons: ["dog", "cat", "fish"]),
        Theme(title: "Weather this month", names: ["Sunny", "Rainy", "Cloudy"], nouns: ["sunny days", "rainy days", "cloudy days"], one: ["sunny day", "rainy day", "cloudy day"], icons: ["sun", "rain", "cloud"]),
        Theme(title: "Favorite snacks", names: ["Crackers", "Popcorn", "Pretzels"], nouns: ["crackers", "bags of popcorn", "pretzels"], one: ["cracker", "bag of popcorn", "pretzel"], icons: ["cracker", "popcorn", "pretzel"]),
    ]
    /// A pile's order: 0..<n mixed up, the same every time for one seed.
    public static func pile(_ n: Int, seed: Int) -> [Int] {
        var rng = SeededRandom(seed: UInt64(max(0, seed)) &* 7919 &+ 17)
        return MeasureK.shuffled(Array(0..<n), &rng)
    }
    static func three(_ rng: inout SeededRandom, _ hi: Int) -> [Int] { Array(MeasureK.shuffled(Array(1...hi), &rng).prefix(3)) }
}

// MARK: - Longest to shortest

/// Longest to shortest (g1-order3, new; 1.MD.1). Three things, 2–12 blocks long, each starting 1–3 blocks past a dashed start
/// line. Slide each one's end onto the line (elsewhere it slides back); then drag them into order, longest on top (drop one
/// on another's row and they swap; a swap that puts the shorter on top slides back, said); the record names them.
/// Use a go-between (from the 7th, every third): two stuck things, one lying, one standing, and a string: lay it along the
/// first (a mark where that thing stops), then along the second, then tap the longer one.
///
/// "at": 0 line, 1 order, 2 done; the line's box "l": 3 once all are lined, −1 let go off the line; the order's "o": 1 once in
/// order, 100 + 10 × the longer + the shorter for a swap the wrong way. Go-between "at": 0, 1, 2 tap, 3 done; "a", "b": 1 once the
/// string is laid, −1 let go elsewhere; "c" the thing tapped.
public enum Order1 {
    public static func numbers(_ n: [Int], _ l: [Int], shifts s: [Int] = [1, 2, 3]) -> Numbers {
        var x: Numbers = ["between": 0]
        for k in 0..<3 { x["n\(k)"] = Double(n[k]); x["l\(k)"] = Double(l[k]); x["s\(k)"] = Double(s[k]) }
        return x
    }
    public static func between(_ n: [Int], _ l: [Int]) -> Numbers { ["between": 1, "n0": Double(n[0]), "n1": Double(n[1]), "l0": Double(l[0]), "l1": Double(l[1])] }
    public struct Parts: Sendable {
        public let between: Bool, names: [String], lens: [Int], shifts: [Int]
        public init(_ x: Numbers) {
            between = Len1.int(x, "between") == 1
            let list = between ? Len1.stuck : Len1.things, k = between ? 2 : 3
            names = (0..<k).map { list[max(0, min(list.count - 1, Len1.int(x, "n\($0)", $0)))] }
            let lo = between ? 3 : 2, hi = between ? 6 : 12
            lens = (0..<k).map { max(lo, min(hi, Len1.int(x, "l\($0)", [7, 4, 9][$0]))) }
            shifts = (0..<k).map { max(1, min(3, Len1.int(x, "s\($0)", $0 + 1))) }
        }
        /// Longest first.
        public var order: [Int] { lens.indices.sorted { lens[$0] > lens[$1] } }
        public var record: String { order.map { names[$0] }.joined(separator: ", ") }
        public func swapped(_ code: Int) -> String {
            code < 100 ? "Put its end on the line." : "The \(names[max(0, min(2, (code - 100) / 10))]) goes past the \(names[max(0, min(2, code % 10))])'s end, so it's longer."
        }
        public static let lineSay = "Slide each one's end to the dashed line."
        public static let orderSay = "Now the far ends tell. Drag them into order, longest on top."
        public static let why = "Line up the ends; the one that goes farthest is longest."
        // go-between: A lies, B stands
        public var a: Int { lens[0] }
        public var b: Int { lens.count > 1 ? lens[1] : lens[0] }
        public var longer: Int { a > b ? 0 : 1 }
        public var gap: Int { abs(a - b) }
        public var string: Int { max(a, b) + 1 }
        public var stringSay: String { "These two are stuck. Lay the string along the \(names[0])." }
        public var secondSay: String { "Now lay it along the \(names[1])." }
        public static let tapSay = "Tap the longer one."
        public func laid(_ j: Int) -> String { "Put the string's end at the \(names[j])'s end." }
        public var tapMiss: String { a > b ? "The \(names[1]) stops before the mark, so the \(names[0]) is longer." : "The \(names[1]) goes past the mark, so it's longer." }
        public var betweenWhy: String { "The string was as long as the \(names[0]), and the \(names[1]) is \(b < a ? "shorter" : "longer")." }
        public var betweenRecord: String { "The \(names[longer]) is longer than the \(names[1 - longer])." }
    }
    /// New (grade1.md): three different things and lengths 2–12, the first three at least 2 apart, then 1 apart allowed; never
    /// already longest to shortest; each starts 1–3 blocks past the line (a different start each, all within 12 blocks: the preview's 13 showed at 73%).
    /// From the 7th, every third is a go-between (the things plus rug and desk, lengths 3–6, never equal).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 6 && (i - 6) % 3 == 0 {
            let n = MeasureK.shuffled(Array(0..<Len1.stuck.count), &rng), a = Int.random(in: 3...6, using: &rng)
            var b = a
            while b == a { b = Int.random(in: 3...6, using: &rng) }
            return between([n[0], n[1]], [a, b])
        }
        while true {
            let n = Array(MeasureK.shuffled(Array(0..<Len1.things.count), &rng).prefix(3))
            let l = (0..<3).map { _ in Int.random(in: 2...12, using: &rng) }
            let gap = min(abs(l[0] - l[1]), abs(l[0] - l[2]), abs(l[1] - l[2]))
            if gap < (i < 3 ? 2 : 1) || (l[0] > l[1] && l[1] > l[2]) { continue }
            let s = MeasureK.shuffled([1, 2, 3], &rng)
            if (0..<3).contains(where: { l[$0] + s[$0] > 12 }) { continue }
            return numbers(n, l, shifts: s)
        }
    }

    public static let spec = LessonSpec(id: "g1-order3", title: "Longest to shortest", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("Longest to shortest")] },
        idea: { _ in Parts.why },
        depends: ["k-length"],
        check: [CheckItem(0), CheckItem(4, when: { let l = Parts($0).lens; return !Parts($0).between && (abs(l[0] - l[1]) == 1 || abs(l[0] - l[2]) == 1 || abs(l[1] - l[2]) == 1) }),
                CheckItem(6), CheckItem(7)]) { x in
        let P = Parts(x)
        if P.between {
            let s1Hint = "Lay it from the \(P.names[0])'s left end.", s2Hint = "Stand it beside the \(P.names[1]), from the floor."
            let s1 = LessonStep(StepWords(say: P.stringSay, hint: s1Hint, action: "Check"),
                answer: TeensK.hand("a", 1, hint: s1Hint, explain: "The string's end is at the \(P.names[0])'s end.", said: { _ in P.laid(0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let s2 = LessonStep(StepWords(say: P.secondSay, hint: s2Hint, action: "Check"),
                answer: TeensK.hand("b", 1, hint: s2Hint, explain: "The mark is where the \(P.names[0]) stops.", said: { _ in P.laid(1) }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            let tapHint = "Look at the mark on the string."
            let tap = LessonStep(StepWords(say: Parts.tapSay, hint: tapHint, action: "Check"),
                answer: TeensK.hand("c", P.longer, hint: tapHint, explain: P.betweenRecord, said: { _ in P.tapMiss }),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            let done = LessonStep(StepWords(say: P.betweenWhy, hint: "", action: "Next problem"), picture: ["at": 3])
            return [s1, s2, tap, done]
        }
        let lineHint = "Slide it left until its end is on the dashed line."
        let line = LessonStep(StepWords(say: Parts.lineSay, hint: lineHint, action: "Check"),
            answer: TeensK.hand("l", 3, hint: lineHint, explain: "All three start at the line.", said: P.swapped),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let orderHint = "The one that goes farthest goes on top."
        let order = LessonStep(StepWords(say: Parts.orderSay, hint: orderHint, action: "Check"),
            answer: TeensK.hand("o", 1, hint: orderHint, explain: P.record + ".", said: P.swapped),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [line, order, done]
    }
}

// MARK: - Measure length

/// Measure length (the web's g1-measure; 1.MD.2). Two things as bars 2 squares tall from a dashed start line, a row of
/// cubes under each (one block a cube). Lay cubes under the first (tap at the line, or drag along: each lays the next cube
/// end to end, counted), then under the second; tap the cubes of the longer row that stick out past the shorter one's
/// end; write 7 − 4 = [3] cubes longer.
///
/// "at": 0 first, 1 second, 2 more, 3 write, 4 done. "f", "g": the cubes laid once the row is full, −1 a first cube away
/// from the line, −2 one past the end. "m": the cubes past the end once all are tapped, −1 one that isn't past.
public enum Cubes1 {
    public static func numbers(_ n0: Int, _ n1: Int, a: Int, b: Int) -> Numbers { ["n0": Double(n0), "n1": Double(n1), "a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let names: [String], a: Int, b: Int
        public init(_ x: Numbers) {
            names = (0..<2).map { Len1.things[max(0, min(7, Len1.int(x, "n\($0)", $0)))] }
            a = max(2, min(12, Len1.int(x, "a", 7))); b = max(2, min(12, Len1.int(x, "b", 4)))
        }
        public var len: [Int] { [a, b] }
        public var lg: Int { a > b ? 0 : 1 }
        public var sh: Int { 1 - lg }
        public var mx: Int { max(a, b) }
        public var mn: Int { min(a, b) }
        public var diff: Int { mx - mn }
        public func laid(_ r: Int) -> @Sendable (Int) -> String { let names = names; return { $0 == -2 ? "That's past the end of the \(names[r])." : "Start at the dashed line." } }
        public var firstSay: String { "Lay cubes under the \(names[0])." }
        public var secondSay: String { "Now lay cubes under the \(names[1])." }
        public var moreSay: String { "Tap the cubes that stick out past the \(names[sh])." }
        public var moreMiss: String { "Tap the cubes past the \(names[sh])'s end." }
        public var other: String { "Count the cubes past the \(names[sh])'s end." }
        public var slips: [(Int, String)] {
            [(a + b, "That's both together. Find the extra cubes the \(names[lg]) has."),
             (mx, "That's how long the \(names[lg]) is. How many cubes more than the \(names[sh])?")]
        }
        public static let why = "Cubes end to end, no gaps: the count is the length."
    }
    /// The web's: two different things; lengths 2–8 for the first three, then 2–12; never equal.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let n = MeasureK.shuffled(Array(0..<8), &rng), hi = i < 3 ? 8 : 12, a = Int.random(in: 2...hi, using: &rng)
        var b = Int.random(in: 2...(hi - 1), using: &rng)
        if b >= a { b += 1 }
        return numbers(n[0], n[1], a: a, b: b)
    }

    public static let spec = LessonSpec(id: "g1-measure", title: "Measure length", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How much longer?")] },
        idea: { _ in Parts.why },
        depends: ["g1-order3", "k-length"],
        check: [CheckItem(0), CheckItem(3), CheckItem(4, when: { Parts($0).diff == 1 }), CheckItem(6, when: { Parts($0).mx >= 9 })]) { x in
        let P = Parts(x)
        let layHint = "Start at the dashed line. Lay them end to end."
        let first = LessonStep(StepWords(say: P.firstSay, hint: layHint, action: "Check"),
            answer: TeensK.hand("f", P.a, hint: layHint, explain: "The \(P.names[0]) is \(Len1.pl(P.a, "cube", "cubes")) long.", said: P.laid(0)),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let second = LessonStep(StepWords(say: P.secondSay, hint: layHint, action: "Check"),
            answer: TeensK.hand("g", P.b, hint: layHint, explain: "The \(P.names[1]) is \(Len1.pl(P.b, "cube", "cubes")) long.", said: P.laid(1)),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let more = LessonStep(StepWords(say: P.moreSay, hint: P.moreMiss, action: "Check"),
            answer: TeensK.hand("m", P.diff, hint: P.moreMiss, explain: "\(P.diff) more.", said: { _ in P.moreMiss }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: Len1.writeBox, hint: P.other, action: "Check"),
            answer: Num1.write("x", P.diff, P.slips, other: P.other, hint: P.other, explain: "\(P.mx) − \(P.mn) = \(P.diff)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return [first, second, more, write, done]
    }
}

// MARK: - Time to the hour and half hour

/// Time to the hour and half hour (the web's g1-time; 1.MD.3). One square is one minute: a clock face 20 squares across on
/// the hour strip (60 squares, a block for each number on the face). Tap the number the short hand points at (or has just
/// passed); trace from 12 round to the long hand (the face shades, the strip fills a square a minute; on the hour, tap
/// where the long hand points); then write the time, [8] : [30], "half past 8" beside it.
///
/// "at": 0 hour, 1 trace, 2 write the hour, 3 write the minutes, 4 done. "h": the number tapped. "m": the minutes traced,
/// −1 started away from 12, −2 the wrong way, −3 past the long hand, −4 short of it.
public enum Time1 {
    public static func numbers(hour: Int, minute: Int) -> Numbers { ["hour": Double(hour), "minute": Double(minute)] }
    public struct Parts: Sendable {
        public let hour: Int, minute: Int
        public init(_ x: Numbers) {
            hour = max(1, min(12, Len1.int(x, "hour", 8))); minute = Len1.int(x, "minute", 30) >= 15 ? 30 : 0
        }
        public var half: Bool { minute == 30 }
        public var next: Int { hour % 12 + 1 }
        public var longAt: Int { half ? 6 : 12 }
        /// "half past 8", "8 o'clock".
        public var said: String { half ? "half past \(hour)" : "\(hour) o'clock" }
        /// "8:30", "8:00".
        public var time: String { "\(hour):\(half ? "30" : "00")" }
        public var hourSay: String { half ? "Tap the number the short hand just passed." : "Tap the number the short hand points at." }
        public var traceSay: String { half ? "Trace from 12 round to the long hand." : "Tap where the long hand points." }
        public static let writeSay = "Write the time."
        /// The minutes step's own line, so "Write the time." isn't said twice.
        public static let minutesSay = "Write the minutes."
        public func tapped(_ n: Int) -> String {
            if half && n == next { return "The short hand hasn't reached \(next) yet. It's still \(hour)." }
            if n == longAt { return "That's the long hand. The short hand tells the hour." }
            return half ? "Find the short hand. Which number did it just pass?" : "Find the short hand. Which number is it on?"
        }
        public func traced(_ code: Int) -> String {
            switch code {
            case -1: return "Start at 12."
            case -2: return "Clocks go this way."
            case -3: return "That's past the long hand."
            default: return "Keep going to the long hand."
            }
        }
        public var hourSlips: [(Int, String)] {
            [(longAt, "The short hand tells the hour. The long hand tells the minutes.")] + (half ? [(next, "The short hand hasn't reached \(next) yet. It's still \(hour).")] : [])
        }
        public static let hourOther = "Read the short hand: it tells the hour."
        public var minuteSlips: [(Int, String)] {
            [(longAt, "The long hand points at \(longAt), but that means \(Len1.pl(minute, "minute", "minutes")).")
             , (60, half ? "A whole hour is 60 minutes, but the long hand has only gone halfway around: 30 minutes." : "The long hand at the top means the hour is just starting: 0 minutes."),
             (hour, "That's the short hand. The long hand tells the minutes.")]
        }
        public static let minuteOther = "Count the strip: one square is one minute."
        public var why: String { half ? "Half way round is half the hour: 30 minutes." : "Long hand on 12: a new hour starts." }
    }
    /// The web's: hour 1–12; the second problem on the hour; then on the hour or half past.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        numbers(hour: Int.random(in: 1...12, using: &rng), minute: i == 1 ? 0 : Int.random(in: 0...1, using: &rng) * 30)
    }

    public static let spec = LessonSpec(id: "g1-time", title: "Time to the hour and half hour", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("What time is it?")] },
        idea: { _ in "Half way round is half the hour: 30 minutes." },
        depends: ["g1-count120"],
        check: [CheckItem(0, when: { Parts($0).half }), CheckItem(1), CheckItem(3, when: { Parts($0).half }), CheckItem(4, when: { !Parts($0).half })]) { x in
        let P = Parts(x)
        let hourHint = "The short hand is the short, thick one."
        let hour = LessonStep(StepWords(say: P.hourSay, hint: hourHint, action: "Check"),
            answer: TeensK.hand("h", P.hour, hint: hourHint, explain: "The short hand tells the hour: \(P.hour).", said: P.tapped),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let traceHint = P.half ? "Start at 12 and go round the way the numbers count." : "The long hand points at 12."
        let trace = LessonStep(StepWords(say: P.traceSay, hint: traceHint, action: "Check"),
            answer: TeensK.hand("m", P.minute, hint: traceHint, explain: Len1.pl(P.minute, "minute", "minutes") + ".", said: P.traced),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let wh = LessonStep(StepWords(say: Parts.writeSay, hint: Parts.hourOther, action: "Check"),
            answer: Num1.write("x", P.hour, P.hourSlips, other: Parts.hourOther, hint: Parts.hourOther, explain: "The hour is \(P.hour)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let wm = LessonStep(StepWords(say: Parts.minutesSay, hint: Parts.minuteOther, action: "Check"),
            answer: Num1.write("y", P.minute, P.minuteSlips, other: Parts.minuteOther, hint: Parts.minuteOther, explain: "\(P.time) is \(P.said)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return [hour, trace, wh, wm, done]
    }
}

// MARK: - Picture graphs

/// Picture graphs (the web's g1-picgraph; 1.MD.4, sorting folded in). One picture is one block; three rows of up to 9 from
/// one start line, each row's name in front, the title over it. The first three start with the pictures in a pile: tap
/// each and it goes to the next place in its row. Then the web's ask: read a row (tap to count, write, then Longer or
/// Shorter), the row with the most or fewest (tap it), how many more (tap the pictures past the shorter row's end, write),
/// together (slide one row onto the end of the other, write).
///
/// "at": 0 sort, 1 the ask's hands, 2 write, 3 longer or shorter, 4 done (a step the ask hasn't is left out). Boxes: "p" the
/// pile sorted; "k" counted (10 + r another row); "c" the row or block tapped; "m" past the end (10 + r another row, −1 not
/// past); "j" 1 once joined (−1 another row, −2 not at the end).
public enum PicGraph1 {
    public static func numbers(theme: Int, counts c: [Int], ask: Int, x: Int, y: Int, few: Bool = false, sort: Bool = false, seed: Int = 1) -> Numbers {
        ["theme": Double(theme), "c0": Double(c[0]), "c1": Double(c[1]), "c2": Double(c[2]), "ask": Double(ask), "x": Double(x), "y": Double(y),
         "few": few ? 1 : 0, "sort": sort ? 1 : 0, "seed": Double(seed)]
    }
    public struct Parts: Sendable {
        public let theme: Int, c: [Int], ask: Int, x: Int, y: Int, few: Bool, sort: Bool, seed: Int
        public init(_ v: Numbers) {
            theme = max(0, min(3, Len1.int(v, "theme"))); c = (0..<3).map { max(1, min(9, Len1.int(v, "c\($0)", [8, 3, 5][$0]))) }
            ask = max(0, min(3, Len1.int(v, "ask"))); x = max(0, min(2, Len1.int(v, "x")))
            let yy = max(0, min(2, Len1.int(v, "y", 1))); y = yy == x ? (x + 1) % 3 : yy
            few = Len1.int(v, "few") == 1; sort = Len1.int(v, "sort") == 1; seed = Len1.int(v, "seed", 1)
        }
        public var th: Len1.Theme { Len1.themes[theme] }
        public var X: String { th.names[x] }
        public var Y: String { th.names[y] }
        public var total: Int { c.reduce(0, +) }
        public var longer: Bool { c[x] > c[y] }
        public var word: String { few ? "fewest" : "most" }
        public var rightRow: Int { c.firstIndex(of: few ? c.min()! : c.max()!) ?? 0 }
        public var otherEnd: Int { c.firstIndex(of: few ? c.max()! : c.min()!) ?? 0 }
        public static let sortSay = "Tap each picture to put it in its row."
        public var askSay: String {
            switch ask {
            case 0: return "How many \(th.nouns[x])? Tap each picture to count it."
            case 1: return "Which row has the \(word)?"
            case 2: return "How many more \(th.nouns[x]) than \(th.nouns[y])? Tap the \(X) pictures past the \(Y) row's end."
            default: return "How many \(th.nouns[x]) and \(th.nouns[y]) together? Slide one row onto the end of the other."
            }
        }
        public var lrSay: String { "Longer or shorter than the \(Y) row?" }
        public func otherRow(_ r: Int) -> String { "That's the \(th.names[max(0, min(2, r))]) row. Find the \(X) row." }
        public var recount: String { "Touch each picture once and say its number. Each picture is one \(th.one[x])." }
        public func picked(_ r: Int) -> String {
            r == otherEnd ? "That row is the \(few ? "longest" : "shortest"). The \(word) is the \(few ? "shortest" : "longest") row."
                : "Look at where each row ends. The \(word) is the \(few ? "shortest" : "longest") row."
        }
        public var lrMiss: String { "The pictures line up. Look where each row ends: the \(X) row \(longer ? "goes past" : "stops before") the end of the \(Y) row." }
        public func moreMiss(_ code: Int) -> String { code >= 10 ? otherRow(code - 10) : "The \(Y) row has that one too. Tap past its end." }
        public func joinMiss(_ code: Int) -> String { code == -1 ? "Use the \(X) and \(Y) rows." : "Slide it to the end of the other row." }
        public var answer: Int { ask == 0 ? c[x] : ask == 2 ? c[x] - c[y] : c[x] + c[y] }
        public var slips: [(Int, String)] {
            switch ask {
            case 0: return [0, 1, 2].filter { $0 != x }.map { (c[$0], otherRow($0)) } + [(c[x] - 1, recount), (c[x] + 1, recount)]
            case 2: return [(c[x] + c[y], "How many more means the difference. Take away."), (c[x], "That's the whole \(X) row. How many more than \(Y)?")]
            default: return [(abs(c[x] - c[y]), "Together means add.")]
            }
        }
        public var other: String { ask == 0 ? recount : ask == 2 ? "Count the \(X) pictures past the \(Y) row's end." : "Count on along the row." }
        /// The second line of the record: read a row's, the most's.
        public var rec2: String? { ask == 0 ? "The \(X) row is \(longer ? "longer" : "shorter") than the \(Y) row." : ask == 1 ? "\(th.names[rightRow]) has the \(word)." : nil }
        public static let why = "One picture for each, so the longest row has the most."
        /// Together: past 10 joined, a picture is 3 squares (said on its own row) so the joined row fits (the preview's 11 showed
        /// at 71% on the 11-inch iPad).
        public var small: Bool { ask == 3 && c[x] + c[y] > 10 }
    }
    /// The web's: three different counts 1–9; asks 0 and 1 for the first three (which start with a pile to sort), then each
    /// in turn; how many more has x past y.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let ask = i < 3 ? i % 2 : i % 4
        while true {
            let c = Len1.three(&rng, 9), x = Int.random(in: 0...2, using: &rng)
            let ys = [0, 1, 2].filter { $0 != x }, y = ys[Int.random(in: 0...1, using: &rng)]
            if ask == 2 && c[x] <= c[y] { continue }
            return numbers(theme: Int.random(in: 0...3, using: &rng), counts: c, ask: ask, x: x, y: y, few: ask == 1 && Int.random(in: 0...2, using: &rng) == 0,
                           sort: i < 3, seed: Int.random(in: 1...9999, using: &rng))
        }
    }

    public static let spec = LessonSpec(id: "g1-picgraph", title: "Picture graphs", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).th.title)] },
        idea: { _ in Parts.why },
        depends: ["k-sort"],
        check: [CheckItem(0), CheckItem(5), CheckItem(6), CheckItem(7)]) { v in
        let P = Parts(v)
        var out: [LessonStep] = []
        if P.sort {
            let h = "Tap a picture in the pile."
            out.append(LessonStep(StepWords(say: Parts.sortSay, hint: h, action: "Check"),
                answer: TeensK.hand("p", P.total, hint: h, explain: "Each picture is in its row.", said: { _ in h }), picture: ["at": 0]))
        }
        let ending = "Look at where each row ends."
        switch P.ask {
        case 0:
            let h = "Count along the \(P.X) row."
            out.append(LessonStep(StepWords(say: P.askSay, hint: h, action: "Check"),
                answer: TeensK.hand("k", P.c[P.x], hint: h, explain: Len1.run(Array(1...P.c[P.x])) + ".", said: { P.otherRow($0 - 10) }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        case 1:
            out.append(LessonStep(StepWords(say: P.askSay, hint: ending, action: "Check"),
                answer: TeensK.hand("c", P.rightRow, hint: ending, explain: P.rec2 ?? "", said: P.picked),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        case 2:
            let h = "Tap the \(P.X) pictures past the \(P.Y) row's end."
            out.append(LessonStep(StepWords(say: P.askSay, hint: h, action: "Check"),
                answer: TeensK.hand("m", P.c[P.x] - P.c[P.y], hint: h, explain: "\(P.c[P.x] - P.c[P.y]) more.", said: P.moreMiss),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        default:
            let h = "Slide the \(P.Y) row onto the end of the \(P.X) row."
            out.append(LessonStep(StepWords(say: P.askSay, hint: h, action: "Check"),
                answer: TeensK.hand("j", 1, hint: h, explain: "\(P.c[P.x] + P.c[P.y]) together.", said: P.joinMiss),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        if P.ask != 1 {
            out.append(LessonStep(StepWords(say: Len1.writeBox, hint: P.other, action: "Check"),
                answer: Num1.write("x", P.answer, P.slips, other: P.other, hint: P.other, explain: "The box is \(P.answer)."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        if P.ask == 0 {
            out.append(LessonStep(StepWords(say: P.lrSay, hint: ending, action: "Check"),
                answer: TeensK.hand("c", P.longer ? 0 : 1, hint: ending, explain: P.rec2 ?? "", said: { _ in P.lrMiss }),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        out.append(LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4]))
        return out
    }
}

// MARK: - Tally charts

/// Tally charts (the web's g1-tally; 1.MD.4, making the marks folded in). A mark every 2 squares, 3 squares tall; four marks
/// and the fifth across them make a bundle two blocks wide. Three rows, names in front, the title over it. The first three
/// start by making the marks (tap each thing; its row gets a mark). Then the web's ask: read a row (tap each bundle, "5,
/// 10", then each single mark), how many more (tap the marks past the shorter row's end), in all (tap each row in turn, the
/// running total); then write.
///
/// "at": 0 make, 1 the ask's taps, 2 write, 3 done. Boxes: "mk" the marks made; "k" read (10 + r another row, −1 a single
/// mark before the bundles); "m" past the end (10 + r another row, −1 not past); "t" in all (−1 out of turn).
public enum Tally1 {
    public static func numbers(theme: Int, counts c: [Int], ask: Int, x: Int, y: Int, make: Bool = false, seed: Int = 1) -> Numbers {
        ["theme": Double(theme), "c0": Double(c[0]), "c1": Double(c[1]), "c2": Double(c[2]), "ask": Double(ask), "x": Double(x), "y": Double(y),
         "make": make ? 1 : 0, "seed": Double(seed)]
    }
    public struct Parts: Sendable {
        public let theme: Int, c: [Int], ask: Int, x: Int, y: Int, make: Bool, seed: Int
        public init(_ v: Numbers) {
            theme = max(0, min(3, Len1.int(v, "theme"))); c = (0..<3).map { max(1, min(14, Len1.int(v, "c\($0)", [12, 4, 9][$0]))) }
            ask = max(0, min(2, Len1.int(v, "ask"))); x = max(0, min(2, Len1.int(v, "x")))
            let yy = max(0, min(2, Len1.int(v, "y", 1))); y = yy == x ? (x + 1) % 3 : yy
            make = Len1.int(v, "make") == 1; seed = Len1.int(v, "seed", 1)
        }
        public var th: Len1.Theme { Len1.themes[theme] }
        public var X: String { th.names[x] }
        public var Y: String { th.names[y] }
        public var n: Int { c[x] }
        public var five: Int { n / 5 }
        public var rest: Int { n % 5 }
        public var sum: Int { c.reduce(0, +) }
        public static let makeSay = "Tap each one to make its mark."
        public var askSay: String {
            switch ask {
            case 0: return "How many \(th.nouns[x])? " + (five > 0 ? "Tap each bundle, then each mark." : "Tap each mark.")
            case 1: return "How many more \(th.nouns[x]) than \(th.nouns[y])? Tap the marks past the \(Y) row's end."
            default: return "How many in all? Tap each row, top to bottom."
            }
        }
        public func otherRow(_ r: Int) -> String { "That's the \(th.names[max(0, min(2, r))]) row. Find the \(X) row." }
        public func readMiss(_ code: Int) -> String { code >= 10 ? otherRow(code - 10) : "Count the bundles first, by 5s." }
        public func moreMiss(_ code: Int) -> String { code >= 10 ? otherRow(code - 10) : "The \(Y) row has that one too. Tap past its end." }
        public static let turnMiss = "Tap the rows in turn, top to bottom."
        public var fives: String { (1...max(1, five)).map { "\(5 * $0)" }.joined(separator: ", ") }
        public var recount: String { five > 0 ? "Count the bundles by 5s first: \(fives). Then count on the single marks." : "Touch each mark once and say its number." }
        public var answer: Int { ask == 0 ? n : ask == 1 ? c[x] - c[y] : sum }
        public var slips: [(Int, String)] {
            switch ask {
            case 0:
                return [0, 1, 2].filter { $0 != x }.map { (c[$0], otherRow($0)) }
                    + (five > 0 ? [(five + rest, "Each bundle is 5 marks, not 1. \(recount)"), (n + five, "The line across is the 5th mark of its bundle, not an extra one.")] : [])
                    + [(n - 1, recount), (n + 1, recount)]
            case 1: return [(c[x] + c[y], "How many more means the difference. Take away.")]
            default: return (0..<3).map { (sum - c[$0], "You left out the \(th.names[$0]) row. Add all three.") }
            }
        }
        public var other: String { ask == 0 ? recount : ask == 1 ? "Count the marks past the \(Y) row's end." : "Add all three rows." }
        public static let why = "Every fifth mark goes across, so count by 5s."
    }
    /// The web's: counts 1–9 for the first three (read a row with a bundle; they start by making the marks), then 1–14; asks
    /// in turn; how many more has x past y; in all is 20 at most.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3
        while true {
            let c = Len1.three(&rng, early ? 9 : 14), ask = early ? 0 : i % 3
            let x = early ? (c.firstIndex { $0 >= 5 } ?? -1) : Int.random(in: 0...2, using: &rng)
            if x < 0 { continue }
            if ask == 2 && c.reduce(0, +) > 20 { continue }
            var y = (x + 1) % 3
            if ask == 1 {
                let ys = [0, 1, 2].filter { $0 != x }; y = ys[Int.random(in: 0...1, using: &rng)]
                if c[x] <= c[y] { continue }
            }
            return numbers(theme: Int.random(in: 0...3, using: &rng), counts: c, ask: ask, x: x, y: y, make: early, seed: Int.random(in: 1...9999, using: &rng))
        }
    }

    public static let spec = LessonSpec(id: "g1-tally", title: "Tally charts", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).th.title)] },
        idea: { _ in Parts.why },
        depends: ["g1-picgraph"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).five >= 1 }), CheckItem(4), CheckItem(5)]) { v in
        let P = Parts(v)
        var out: [LessonStep] = []
        if P.make {
            let h = "Tap a picture under the chart."
            out.append(LessonStep(StepWords(say: Parts.makeSay, hint: h, action: "Check"),
                answer: TeensK.hand("mk", P.sum, hint: h, explain: "Every one has its mark.", said: { _ in h }), picture: ["at": 0]))
        }
        switch P.ask {
        case 0:
            let h = P.five > 0 ? "Tap the bundles first: \(P.fives)." : "Tap each mark in the \(P.X) row."
            out.append(LessonStep(StepWords(say: P.askSay, hint: h, action: "Check"),
                answer: TeensK.hand("k", P.n, hint: h, explain: "\(P.n).", said: P.readMiss), picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        case 1:
            let h = "Tap the \(P.X) marks past the \(P.Y) row's end."
            out.append(LessonStep(StepWords(say: P.askSay, hint: h, action: "Check"),
                answer: TeensK.hand("m", P.c[P.x] - P.c[P.y], hint: h, explain: "\(P.c[P.x] - P.c[P.y]) more.", said: P.moreMiss),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        default:
            let h = "Start with the top row."
            out.append(LessonStep(StepWords(say: P.askSay, hint: h, action: "Check"),
                answer: TeensK.hand("t", 3, hint: h, explain: "\(P.c[0]), \(P.c[0] + P.c[1]), \(P.sum).", said: { _ in Parts.turnMiss }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        out.append(LessonStep(StepWords(say: Len1.writeBox, hint: P.other, action: "Check"),
            answer: Num1.write("x", P.answer, P.slips, other: P.other, hint: P.other, explain: "The box is \(P.answer)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        out.append(LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3]))
        return out
    }
}
