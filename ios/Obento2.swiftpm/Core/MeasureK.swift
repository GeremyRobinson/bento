import Foundation

/// What Kindergarten's Measure and sort chapter shares (design/gradeK.md chapter 3, the preview
/// design/prototype/gradeK-ch3.html): one block is one cube of length (a thing is drawn as long as it is, its cubes faint
/// across it), weight has no unit (it's compared on a pan balance), and one block is one thing when sorting. Every
/// number is tapped on the number row; every line is spoken (App's Voice).
public enum MeasureK {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func shuffled(_ a: [Int], _ rng: inout SeededRandom) -> [Int] {
        var a = a
        if a.count > 1 { for i in stride(from: a.count - 1, to: 0, by: -1) { a.swapAt(i, Int.random(in: 0...i, using: &rng)) } }
        return a
    }
    /// "1 cube", "4 cubes".
    public static func cubes(_ n: Int) -> String { n == 1 ? "1 cube" : "\(n) cubes" }
    public static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
}

// MARK: - Longer and shorter

/// Longer and shorter (the web's k-length, K.MD.A.2, K.MD.A.1; taller folded in). Two things on two block rows, a start
/// line through both; the top one touches it, the bottom one starts out of line. Slide the bottom one's end onto the line,
/// tap the longer one (or Same), see what sticks out (ringed, its cubes counted), write how many on the number row.
/// Taller (from index 6, every third problem): two things stand on a floor; slide the raised one down onto it.
///
/// "at": 0 slide, 1 pick, 2 write, 3 done.
public enum LengthK {
    public static let long = ["pencil", "crayon", "ribbon", "spoon", "snake", "straw"]
    public static let standing = ["tower", "plant", "bottle", "lamp", "candle", "cup"]
    /// `mover`: the one that starts out of line (0 top or left, 1 bottom or right); `shift`: how far, in blocks (lying:
    /// right of the line when more than 0, left when less; standing: up off the floor).
    public static func numbers(top: Int, bottom: Int, a: Int, b: Int, tall: Bool = false, mover: Int = 1, shift: Int = 2) -> Numbers {
        ["top": Double(top), "bottom": Double(bottom), "a": Double(a), "b": Double(b), "tall": tall ? 1 : 0, "mover": Double(mover), "shift": Double(shift)]
    }

    public struct Parts: Sendable {
        public let top: Int, bottom: Int, a: Int, b: Int, tall: Bool, mover: Int, shift: Int
        public init(_ x: Numbers) {
            tall = MeasureK.int(x, "tall") == 1
            top = max(0, min(5, MeasureK.int(x, "top"))); bottom = max(0, min(5, MeasureK.int(x, "bottom", 1)))
            a = max(1, min(10, MeasureK.int(x, "a", 2))); b = max(1, min(10, MeasureK.int(x, "b", 3)))
            mover = MeasureK.int(x, "mover", 1) == 0 ? 0 : 1; shift = MeasureK.int(x, "shift", 2)
        }
        public var names: [String] { let l = tall ? LengthK.standing : LengthK.long; return [l[top], l[bottom]] }
        public var len: [Int] { [a, b] }
        /// 0 the first is longer, 1 the second, 2 the same.
        public var right: Int { a > b ? 0 : a < b ? 1 : 2 }
        public var same: Bool { a == b }
        public var extra: Int { abs(a - b) }
        public var lo: Int { min(a, b) }
        public var hi: Int { max(a, b) }
        public var longer: Int { right == 1 ? 1 : 0 }
        public var shorter: Int { 1 - longer }
        public var word: String { tall ? "taller" : "longer" }
        var past: String { tall ? "above" : "past" }
        /// Standing: how many blocks tall the room is (the mover raised).
        public var height: Int { max(a + (mover == 0 ? shift : 0), b + (mover == 1 ? shift : 0)) }

        public var slideSay: String { tall ? "Stand them on the floor." : "Line them up." }
        public var pickSay: String { "Tap the \(word) one." }
        public var writeSay: String { tall ? "Count what sticks up. Write how many stick up." : "Count what sticks out. Write how many stick out." }
        public var doneSay: String {
            if same { return "They end at the same place. Same start and same end: the same \(tall ? "height" : "length")." }
            return tall ? "Same floor, so the one that sticks up is taller." : "Same start, so the one that sticks out is longer."
        }
        /// Let go `off` blocks from the line (or floor): nil when it's on it.
        public func slid(_ off: Int) -> String? { off == 0 ? nil : tall ? "Its foot goes on the floor." : "Its end goes on the line." }
        /// A thing tapped (0, 1) or Same (2): what to say, nil when it's right.
        public func picked(_ c: Int) -> String? {
            if c == right { return nil }
            if c == 2 { return "They are not the same." }
            if same { return "Look again: they end at the same place." }
            let j = max(0, min(1, c))
            return "The \(names[j]) is only \(MeasureK.cubes(len[j])). The \(names[1 - j]) is \(len[1 - j])."
        }
        /// A number tapped for what sticks out: the web's count slips, moved here (the first one wins).
        public func wrote(_ v: Int) -> String? {
            if v == extra { return nil }
            if v == hi { return "\(hi) is the whole \(names[longer]). Count only the cubes \(past) the dashed line." }
            if v == lo { return "\(lo) is the whole \(names[shorter]). Count only the cubes \(past) the dashed line." }
            if v == extra - 1 { return "One short. Count every cube \(past) the dashed line." }
            if v == extra + 1 { return "One too many. Count each cube \(past) the line once." }
            return "That’s \(v). Count only the cubes \(past) the dashed line."
        }
        /// The record's words before its box ("The pencil is longer by"), or the whole line when they're the same.
        public var recordWords: String {
            same ? "The \(names[0]) and the \(names[1]) are the same \(tall ? "height" : "length")." : "The \(names[longer]) is \(word) by"
        }
        public var unit: String { extra == 1 ? "cube." : "cubes." }
    }

    /// The web's generator as it is (the first three 8 at most and 3 or more apart; after that 1 in 6 the same). New:
    /// taller from index 6 every third (things that stand, 2–6 cubes and 6 high at most with the raised one lifted: the
    /// design's 7 showed at 69% with the record and the number row beside them) and where the moving one starts.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let tall = index >= 6 && index % 3 == 0
        while true {
            let order = MeasureK.shuffled(Array(0..<6), &rng), top = order[0], bottom = order[1]
            let easy = index < 3, hi = tall ? 6 : easy ? 8 : 10, a = Int.random(in: 2...hi, using: &rng)
            let b = !easy && Int.random(in: 0...5, using: &rng) == 0 ? a : MeasureK.pick((2...hi).filter { abs($0 - a) >= (easy ? 3 : 1) }, &rng)
            if !tall {
                let shift = Int.random(in: 0...2, using: &rng) == 0 ? -Int.random(in: 1...2, using: &rng) : Int.random(in: 1...min(3, 11 - b), using: &rng)
                return numbers(top: top, bottom: bottom, a: a, b: b, mover: 1, shift: shift)
            }
            let can = [0, 1].filter { ($0 == 1 ? b : a) <= 5 }
            guard !can.isEmpty else { continue }
            let mover = MeasureK.pick(can, &rng), h = mover == 1 ? b : a
            return numbers(top: top, bottom: bottom, a: a, b: b, tall: true, mover: mover, shift: Int.random(in: 1...min(3, 6 - h), using: &rng))
        }
    }

    public static let spec = LessonSpec(id: "k-length", title: "Longer and shorter", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { _ in [.text("Which is longer?")] },
        idea: { _ in "When both start at the same line, the one that sticks out farther is longer." },
        depends: ["k-compare"],
        check: [CheckItem(3, when: { Parts($0).a > Parts($0).b }), CheckItem(3, when: { Parts($0).a < Parts($0).b }),
                CheckItem(3, when: { Parts($0).same }), CheckItem(6, when: { Parts($0).tall && Parts($0).extra == 1 })]) { x in
        let P = Parts(x)
        let slideHint = P.tall ? "Slide it down until its foot is on the floor." : "Slide it until its end is on the line."
        let slide = LessonStep(StepWords(say: P.slideSay, hint: slideHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("l")], expected: ["l": 0], hint: slideHint, explain: P.tall ? "Both stand on the floor." : "Both start at the line.",
                               check: { v in P.slid(Int((v["l"] ?? 9).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let lookHint = P.tall ? "Look at the tops. Which one sticks up?" : "Look at the ends. Which one sticks out?"
        let pick = LessonStep(StepWords(say: P.pickSay, hint: lookHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(P.right)], hint: lookHint, explain: P.doneSay,
                               check: { v in P.picked(Int((v["c"] ?? -1).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.doneSay, hint: "", action: "Next problem"), picture: ["at": 3])
        if P.same { return [slide, pick, done] }
        let countHint = "Count only the cubes \(P.past) the dashed line."
        let write = LessonStep(StepWords(say: P.writeSay, hint: countHint, action: "Check"),
            answer: CountK.write("x", P.extra, known: [P.hi, P.lo, P.extra - 1, P.extra + 1].filter { $0 != P.extra && $0 >= 0 }.map { ($0, P.wrote($0) ?? "") },
                                 other: { P.wrote($0) ?? "" }, hint: countHint, explain: "\(MeasureK.cubes(P.extra)) stick \(P.tall ? "up" : "out")."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [slide, pick, write, done]
    }
}

// MARK: - Heavier and lighter

/// Heavier and lighter (gk-heavier, new; K.MD.A.1, K.MD.A.2). Weight has no unit in K: two things are put on a pan
/// balance in blocks and the beam tips on a spring, the heavier side down (the same weight stays level). Each thing is
/// drawn as long as it is (one block one cube of length), so a pillow is longer and lighter than a rock. Slide each onto
/// a pan, tap the heavier (or lighter) one or Same; both ways (from index 3, every other problem): the balance draws out,
/// the two lie on a start line, tap the longer one. The record is written by the taps.
///
/// "at": 0 put, 1 pick, 2 longer, 3 done.
public enum Heavier {
    public struct Thing: Sendable { public let name: String, many: String, len: Int, weight: Int }
    /// Each thing's length (1–4 blocks) and weight (a rank 1–9, never shown).
    public static let things: [Thing] = [
        Thing(name: "rock", many: "rocks", len: 1, weight: 8), Thing(name: "feather", many: "feathers", len: 2, weight: 1),
        Thing(name: "brick", many: "bricks", len: 2, weight: 9), Thing(name: "pillow", many: "pillows", len: 4, weight: 3),
        Thing(name: "ball", many: "balls", len: 2, weight: 5), Thing(name: "book", many: "books", len: 2, weight: 7),
        Thing(name: "apple", many: "apples", len: 1, weight: 4), Thing(name: "balloon", many: "balloons", len: 3, weight: 2),
        Thing(name: "shoe", many: "shoes", len: 3, weight: 6), Thing(name: "leaf", many: "leaves", len: 1, weight: 1),
    ]
    public static func numbers(x: Int, y: Int, lighter: Bool = false, both: Bool = false) -> Numbers {
        ["x": Double(x), "y": Double(y), "ask": lighter ? 1 : 0, "both": both ? 1 : 0]
    }

    public struct Parts: Sendable {
        public let x: Int, y: Int, lighter: Bool, both: Bool
        public init(_ v: Numbers) {
            x = max(0, min(9, MeasureK.int(v, "x"))); y = max(0, min(9, MeasureK.int(v, "y", 1)))
            lighter = MeasureK.int(v, "ask") == 1; both = MeasureK.int(v, "both") == 1 && x != y
        }
        /// The two things: 0 is x's, 1 is y's.
        public var T: [Thing] { [Heavier.things[x], Heavier.things[y]] }
        public var level: Bool { x == y || T[0].weight == T[1].weight }
        /// The heavier one (0 or 1), nil when they weigh the same.
        public var heavy: Int? { level ? nil : T[0].weight > T[1].weight ? 0 : 1 }
        public var ask: String { lighter ? "lighter" : "heavier" }
        /// What to tap: the thing asked for (0 or 1), or 2 (Same) when it stays level.
        public var want: Int { guard let h = heavy else { return 2 }; return lighter ? 1 - h : h }
        /// The longer one.
        public var longer: Int { T[0].len >= T[1].len ? 0 : 1 }

        public var pickSay: String { "Watch the balance. Tap the \(ask) one." }
        public var doneSay: String { both ? "Longer isn’t always heavier." : level ? "The same weight: the balance stays level." : "The heavier side goes down." }
        /// What the put step's box holds: 1 both on; −1 let go off the pans; −2 onto a pan that's full.
        public func put(_ code: Int) -> String? { code == 1 ? nil : code == -2 ? "One thing on each pan." : "Put it on a pan." }
        /// A thing tapped (0, 1) or Same (2): what to say, nil when it's right.
        public func picked(_ c: Int) -> String? {
            if c == want { return nil }
            if c == 2 { return "One side went down." }
            if level { return "Look again: it stayed level." }
            let j = max(0, min(1, c))
            return T[j].weight > T[1 - j].weight ? "That side went down. It’s heavier." : "That side went up. It’s lighter."
        }
        /// A thing tapped on the start line: what to say, nil when it's the longer one.
        public func longPicked(_ c: Int) -> String? {
            if c == longer { return nil }
            let j = max(0, min(1, c))
            return "The \(T[j].name) is only \(MeasureK.cubes(T[j].len)). The \(T[1 - j].name) is \(T[1 - j].len)."
        }
        public var heavyLine: String { level ? "The \(T[0].many) weigh the same." : "The \(T[want].name) is \(ask)." }
        public var longLine: String { "The \(T[longer].name) is longer." }
    }

    /// Easy first: index 0–2 weights 5 or more apart, ask heavier; 3–5 a longer but lighter pair 1 in 2, both ways every
    /// other (odd); 6+ two of the same thing now and then (level), ask lighter 1 in 3.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let both = i >= 3 && i % 2 == 1, lighter = i >= 6 && Int.random(in: 1...3, using: &rng) == 1
        let longLight = i >= 3 && i < 6 && Int.random(in: 0...1, using: &rng) == 1
        if i >= 6 && !both && Int.random(in: 1...6, using: &rng) == 1 { let x = Int.random(in: 0...9, using: &rng); return numbers(x: x, y: x, lighter: lighter) }
        while true {
            let x = Int.random(in: 0...9, using: &rng), y = Int.random(in: 0...9, using: &rng), A = things[x], B = things[y]
            if x == y || A.weight == B.weight { continue }
            if i < 3 && abs(A.weight - B.weight) < 5 { continue }
            if (both || longLight) && A.len == B.len { continue }
            if longLight && (A.len > B.len) != (A.weight < B.weight) { continue }
            return numbers(x: x, y: y, lighter: lighter, both: both)
        }
    }

    public static let spec = LessonSpec(id: "gk-heavier", title: "Heavier and lighter", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text("Which is \(Parts(x).ask)?")] },
        idea: { _ in "On a balance, the heavier side goes down." },
        depends: ["k-length"],
        check: [CheckItem(6, when: { Parts($0).lighter }),
                CheckItem(3, when: { let P = Parts($0); return !P.level && P.T[P.longer].weight < P.T[1 - P.longer].weight && P.T[0].len != P.T[1].len }),
                CheckItem(3, when: { Parts($0).both }), CheckItem(3)]) { v in
        let P = Parts(v)
        let put = LessonStep(StepWords(say: "Put them on.", hint: "Slide each thing onto a pan.", action: "Check"),
            answer: AnswerTask(prompt: [.box("p")], expected: ["p": 1], hint: "Slide each thing onto a pan.", explain: "One thing on each pan.",
                               check: { x in P.put(Int((x["p"] ?? 0).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pickHint = P.lighter ? "The lighter side goes up." : "The heavier side goes down."
        let pick = LessonStep(StepWords(say: P.pickSay, hint: pickHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(P.want)], hint: pickHint, explain: P.heavyLine,
                               check: { x in P.picked(Int((x["c"] ?? -1).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.doneSay, hint: "", action: "Next problem"), picture: ["at": 3])
        guard P.both else { return [put, pick, done] }
        let longHint = "Look at the ends. Which one sticks out?"
        let long = LessonStep(StepWords(say: "Tap the longer one.", hint: longHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("g")], expected: ["g": Double(P.longer)], hint: longHint, explain: P.longLine,
                               check: { x in P.longPicked(Int((x["g"] ?? -1).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [put, pick, long, done]
    }
}

// MARK: - Sort and count

/// Sort and count (the web's k-sort, K.MD.B.3; the rows put in order folded in). One block is one thing. A mixed-up pile
/// on a field of 9 × 2 blocks; under it one empty row per kind, each row's first block holding its kind's key, the rows
/// starting on one line. Tap each thing of a kind (the circled one's kind first): it flies into its row and takes the
/// next number. Then the field draws out, the rows rise; tap the row with the most (or the fewest); the rows slide into
/// order, most at the top. The record: `The buttons have the most.`
///
/// "at": 0 sort (step j sorts `order[j]`, "kind"), 1 pick, 2 done.
public enum SortK {
    public struct Kind: Sendable { public let glyph: String, one: String, many: String, looks: String }
    public static let kinds: [[Kind]] = [
        [Kind(glyph: "button", one: "button", many: "buttons", looks: "It is round with 4 little holes"),
         Kind(glyph: "leaf", one: "leaf", many: "leaves", looks: "It has a pointed tip and a line down the middle"),
         Kind(glyph: "block", one: "block", many: "blocks", looks: "It has 4 corners and a little square in the middle")],
        [Kind(glyph: "circle", one: "circle", many: "circles", looks: "It is round all the way, with no corners"),
         Kind(glyph: "square", one: "square", many: "squares", looks: "It has 4 corners and 4 straight sides"),
         Kind(glyph: "triangle", one: "triangle", many: "triangles", looks: "It has 3 corners and 3 straight sides")],
    ]
    /// The field's blocks across and down: 9 × 2 (the preview's 7 × 3 put three rows of things under it at 69%; 18
    /// places still hold the 15 things a problem has at most).
    public static let across = 9, down = 2
    /// `cells`: each thing's block in the field (0–17, across then down), kind by kind.
    public static func numbers(by: Int, counts: [Int], theme: Int, ask: Int, cells: [Int]) -> Numbers {
        var x: Numbers = ["by": Double(by), "theme": Double(theme), "ask": Double(ask), "K": Double(counts.count)]
        for (i, c) in counts.enumerated() { x["n\(i)"] = Double(c) }
        for (i, c) in cells.enumerated() { x["c\(i)"] = Double(c) }
        return x
    }
    /// The things in the field in order, each block given (the first ones, as many as there are).
    public static func numbers(by: Int, counts: [Int], theme: Int = 0, ask: Int = 0) -> Numbers {
        numbers(by: by, counts: counts, theme: theme, ask: ask, cells: Array(0..<counts.reduce(0, +)))
    }

    public struct Parts: Sendable {
        public let by: Int, counts: [Int], theme: Int, ask: Int, cells: [Int]
        public init(_ x: Numbers) {
            by = MeasureK.int(x, "by") == 1 ? 1 : 0
            let K = max(2, min(3, MeasureK.int(x, "K", 2)))
            counts = (0..<K).map { max(1, min(8, MeasureK.int(x, "n\($0)", 1))) }
            theme = max(0, min(2, MeasureK.int(x, "theme"))); ask = MeasureK.int(x, "ask") == 1 ? 1 : 0
            let total = counts.reduce(0, +)
            cells = (0..<total).map { max(0, min(SortK.across * SortK.down - 1, MeasureK.int(x, "c\($0)", $0))) }
        }
        public var K: Int { counts.count }
        public var total: Int { counts.reduce(0, +) }
        /// Row i's kind.
        public var kinds: [Kind] { (0..<K).map { SortK.kinds[by][($0 + theme) % 3] } }
        /// Each thing's row (kind), in the order the cells list them.
        public var kindOf: [Int] { counts.enumerated().flatMap { i, n in Array(repeating: i, count: n) } }
        /// The circled one's kind: sorted first (the web's pickOf).
        public var first: Int { (theme + counts[0]) % K }
        /// The kinds in the order they're sorted.
        public var order: [Int] { [first] + (0..<K).filter { $0 != first } }
        /// The circled thing: the first of the first kind.
        public var circled: Int { kindOf.firstIndex(of: first) ?? 0 }
        public var word: String { ask == 1 ? "fewest" : "most" }
        public var pickN: Int { ask == 1 ? counts.min()! : counts.max()! }
        public var other: Int { ask == 1 ? counts.max()! : counts.min()! }
        /// The row to tap.
        public var right: Int { counts.firstIndex(of: pickN) ?? 0 }
        /// The rows in order, most at the top.
        public var rank: [Int] { (0..<K).sorted { counts[$0] > counts[$1] } }
        public func sortSay(_ j: Int) -> String { "Tap each \(kinds[order[j]].one)." }
        public var pickSay: String { "Tap the row with the \(word)." }
        public var why: String { ask == 1 ? "Rows from one line: the shortest row has the fewest." : "Rows from one line: the longest row has the most." }
        public var doneSay: String { "In order: most at the top. \(why)" }
        public var record: String { "The \(kinds[right].many) have the \(word)." }
        /// What sort step j's box holds: the row's count once all are in, or −(k + 1) for a thing of kind k tapped.
        public func sorted(_ j: Int, _ code: Int) -> String? {
            let want = counts[order[j]]
            if code == want { return nil }
            if code < 0 { let k = kinds[max(0, min(K - 1, -code - 1))]; return "That’s a \(k.one). \(k.looks)." }
            return "Tap each \(kinds[order[j]].one)."
        }
        /// A row tapped: the web's words, nil when it's right.
        public func picked(_ i: Int) -> String? {
            if i == right { return nil }
            let c = counts[max(0, min(K - 1, i))]
            return c == other ? "That group has the \(ask == 1 ? "most" : "fewest"). Which group has the \(word)?"
                : "That group is in the middle. The \(word) is the \(ask == 1 ? "shortest" : "longest") row."
        }
    }

    /// The web's generator as it is (the first three 2 kinds, 1–6 each, 8 in all at most; then 3 kinds, 1–8, 15 at most;
    /// counts all different; the fewest every fourth), and where each thing lies in the field.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3, K = early ? 2 : 3, top = early ? 6 : 8, most = early ? 8 : 15
        while true {
            let counts = Array(MeasureK.shuffled(Array(1...top), &rng).prefix(K))
            guard counts.reduce(0, +) <= most else { continue }
            let by = Int.random(in: 0...1, using: &rng), theme = Int.random(in: 0...2, using: &rng)
            let cells = Array(MeasureK.shuffled(Array(0..<(across * down)), &rng).prefix(counts.reduce(0, +)))
            return numbers(by: by, counts: counts, theme: theme, ask: i % 4 == 3 ? 1 : 0, cells: cells)
        }
    }

    public static let spec = LessonSpec(id: "k-sort", title: "Sort and count", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text("Which group has the \(Parts(x).word)?")] },
        idea: { _ in "Putting matching things together makes each group easy to count." },
        depends: ["k-compare", "k-shapes"],
        check: [CheckItem(3), CheckItem(4), CheckItem(5, when: { Parts($0).by == 1 }), CheckItem(7)]) { x in
        let P = Parts(x)
        var steps: [LessonStep] = P.order.indices.map { j in
            let k = P.kinds[P.order[j]], box = "s\(j)", hint = "Find every \(k.one). Tap each one."
            return LessonStep(StepWords(say: P.sortSay(j), hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box(box)], expected: [box: Double(P.counts[P.order[j]])], hint: hint,
                                   explain: "There \(P.counts[P.order[j]] == 1 ? "is" : "are") \(P.counts[P.order[j]]) \(P.counts[P.order[j]] == 1 ? k.one : k.many).",
                                   check: { v in P.sorted(j, Int((v[box] ?? 0).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
                picture: ["at": 0, "kind": Double(j)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let pickHint = P.ask == 1 ? "The shortest row has the fewest." : "The longest row has the most."
        steps.append(LessonStep(StepWords(say: P.pickSay, hint: pickHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(P.right)], hint: pickHint, explain: P.record,
                               check: { v in P.picked(Int((v["c"] ?? -1).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: P.doneSay, hint: "", action: "Next problem"), picture: ["at": 2]))
        return steps
    }
}
