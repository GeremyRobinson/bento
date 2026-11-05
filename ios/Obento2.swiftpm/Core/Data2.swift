import Foundation

/// What 2nd grade's chapter 5, Data, shares (design/grade2.md chapter 5, the preview design/prototype/grade2-ch5.html): a
/// vote is a block along its bar, so a graph's scale lines are the strong lines; on a line plot an inch is a block, as on
/// the ruler. Every number the child writes is typed with the iPad's keys and Check, as the preview types; the hands do the
/// rest (tap to add pictures, drag a bar's end, drop a line, hop, place an X, tap a stack).
public enum Data2 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G2.int(v, k, d) }
    /// A list read in order, with its rest left out past 4: 8, 9, 10 … 11.
    public static func landings(_ l: [Int]) -> String { Len2.landings(l) }
    static func shuffled(_ a: [Int], _ rng: inout SeededRandom) -> [Int] {
        var b = a
        if b.count > 1 { for i in stride(from: b.count - 1, to: 0, by: -1) { let j = Int.random(in: 0...i, using: &rng); b.swapAt(i, j) } }
        return b
    }
}

// MARK: - Make a graph

/// Make a graph (g2-makegraph, new; 2.MD.D.10: draw; put together, take apart). The tally chart beside the graph (each row's
/// little picture, its name and its marks at its left), the title over, four rows 4 squares tall a square apart, a vote a
/// block along its row. A picture graph: tap a row and each tap puts the next picture in its next block. A bar graph: drag
/// each bar's end a block at a time over the scale 0–8. Any order; a finished row ticks its tally. Then `7 + 4 + 6 + 3 =
/// [20] in all`. The missing row: one tally is a ?, the other three bars are drawn; "20 children voted." Drag that bar (the
/// readout counts the whole graph), then `20 − 17 = [3]`.
///
/// "kind" 0 picture graph, 1 bar graph, 2 the missing row; "theme" 0–4; "c0"…"c3" the counts; "mx" the missing row. "at": 0
/// the rows, 1 write, 2 done. Boxes: "r" the rows (100 all made; a miss 10 × row + count shown; the missing row: its
/// length), "x" written.
public enum MakeGraph2 {
    public struct Theme: Sendable {
        public let title: String, names: [String], nouns: [String], icons: [String], one: String, who: String
    }
    public static let themes: [Theme] = [
        Theme(title: "Our favorite fruit", names: ["apples", "bananas", "grapes", "pears"], nouns: ["apples", "bananas", "grapes", "pears"],
              icons: ["apple", "banana", "grapes", "pear"], one: "vote", who: "children voted."),
        Theme(title: "Pets in our class", names: ["dogs", "cats", "fish", "birds"], nouns: ["dogs", "cats", "fish", "birds"],
              icons: ["dog", "cat", "fish", "bird"], one: "pet", who: "pets"),
        Theme(title: "Weather this month", names: ["sunny", "rainy", "cloudy", "windy"], nouns: ["sunny days", "rainy days", "cloudy days", "windy days"],
              icons: ["sun", "rain", "cloud", "wind"], one: "day", who: "days"),
        Theme(title: "Our favorite snacks", names: ["crackers", "popcorn", "pretzels", "cookies"], nouns: ["crackers", "popcorn", "pretzels", "cookies"],
              icons: ["cracker", "popcorn", "pretzel", "cookie"], one: "vote", who: "children voted."),
        Theme(title: "Our favorite colors", names: ["red", "blue", "green", "yellow"], nouns: ["votes for red", "votes for blue", "votes for green", "votes for yellow"],
              icons: ["paint", "paint", "paint", "paint"], one: "vote", who: "children voted."),
    ]
    static let singular: Set<String> = ["popcorn", "sunny", "rainy", "cloudy", "windy", "red", "blue", "green", "yellow"]
    public enum Kind: Int, Sendable { case pictures, bars, missing }
    public static let allMade = 100
    public static func code(row: Int, shown: Int) -> Int { 10 * row + shown }

    public static func numbers(kind: Int, theme: Int, counts c: [Int], mx: Int = 0) -> Numbers {
        var out: Numbers = ["kind": Double(kind), "theme": Double(theme), "mx": Double(mx)]
        for j in 0..<4 { out["c\(j)"] = Double(j < c.count ? c[j] : 1) }
        return out
    }
    public struct Parts: Sendable {
        public let kind: Kind, theme: Int, c: [Int], mx: Int
        public init(_ x: Numbers) {
            kind = Kind(rawValue: Data2.int(x, "kind")) ?? .pictures
            theme = max(0, min(4, Data2.int(x, "theme")))
            var cs: [Int] = []
            for j in 0..<4 { cs.append(max(1, min(8, Data2.int(x, "c\(j)", j + 2)))) }
            c = cs
            mx = max(0, min(3, Data2.int(x, "mx")))
        }
        public var th: Theme { MakeGraph2.themes[theme] }
        public var pics: Bool { kind == .pictures }
        public var missing: Bool { kind == .missing }
        public var total: Int { c.reduce(0, +) }
        /// The other rows: what the graph shows without the missing one.
        public var base: Int { total - c[mx] }
        public var name: String { th.names[mx] }
        /// "20 children voted.", "The class has 20 pets.", "We counted 20 days."
        public var story: String {
            switch th.who {
            case "pets": return "The class has \(total) pets."
            case "days": return "We counted \(total) days."
            default: return "\(total) \(th.who)"
            }
        }
        func told(_ s: String) -> String { missing ? "\(story) \(s)" : s }
        public var sayRows: String { told(missing ? "Drag the \(name) bar." : pics ? "Tap to add the pictures." : "Drag each bar to its tally.") }
        public var sayWrite: String { told(missing ? "Write how many \(th.nouns[mx])." : "Write how many in all.") }
        public var why: String {
            if missing { return told("The rows make \(total), so \(name) \(MakeGraph2.singular.contains(name) ? "gets" : "get") what's left.") }
            return "One \(pics ? "picture" : "block") for each \(th.one), so each row is as long as its tally."
        }
        /// A row made one off (or another row left before its tally): what it shows and what its tally says.
        public func rowMiss(_ k: Int) -> String {
            if missing { return "That's \(base + max(0, k)) in all. \(story)" }
            let j = max(0, min(3, k / 10)), v = k % 10
            return "That's \(v). The tally says \(c[j])."
        }
        public var answer: Int { missing ? c[mx] : total }
        public var slips: [(Int, String)] {
            if missing {
                return [(total, "That's everyone. Write how many \(th.nouns[mx])."), (base, "That's the other rows. Take them from \(total).")]
            }
            var out: [(Int, String)] = []
            for j in 0..<4 { out.append((total - c[j], "That leaves out the \(th.names[j]) row. Add all four.")) }
            return out
        }
        public var plain: String { missing ? "Count the blocks in the \(name) bar." : "Add the four rows again." }
        public var rowsHint: String { missing ? "The rows make \(total) in all." : pics ? "One picture for each tally mark." : "One block for each tally mark." }
    }

    /// The preview's: problems 0–2 counts 1–6, all different (a picture graph, a bar graph, a picture graph); from 3 in turn a
    /// picture graph, a bar graph and a missing row, counts 1–8 (a month's days stay at 31 or fewer).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kinds = i < 3 ? [0, 1, 0] : [0, 1, 2]
        let kind = i < 3 ? kinds[i] : kinds[(i - 3) % 3]
        let theme = Int.random(in: 0...4, using: &rng)
        var c: [Int] = []
        if i < 3 { c = Array(Data2.shuffled([1, 2, 3, 4, 5, 6], &rng).prefix(4)) }
        else {
            repeat {
                c = []
                for _ in 0..<4 { c.append(Int.random(in: 1...8, using: &rng)) }
            } while theme == 2 && c.reduce(0, +) > 31
        }
        return numbers(kind: kind, theme: theme, counts: c, mx: kind == 2 ? Int.random(in: 0...3, using: &rng) : 0)
    }

    public static let spec = LessonSpec(id: "g2-makegraph", title: "Make a graph", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).th.title)] },
        idea: { x in Parts(x).why },
        depends: ["g1-tally", "g1-picgraph"],
        check: [CheckItem(0), CheckItem(4), CheckItem(5), CheckItem(6)]) { x in
        let P = Parts(x)
        let want = P.missing ? P.c[P.mx] : allMade
        let rows = LessonStep(StepWords(say: P.sayRows, hint: P.rowsHint, action: "Check"),
            answer: G2.hand("r", want, hint: P.rowsHint, explain: P.missing ? "\(P.c[P.mx]) \(P.th.nouns[P.mx])." : "Each row is as long as its tally.",
                            said: { P.rowMiss($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: P.sayWrite, hint: P.plain, action: "Check"),
            answer: G2.typed("x", P.answer, P.slips, plain: P.plain, hint: P.plain, explain: "\(P.answer)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [rows, write, done]
    }
}

// MARK: - Bar graphs

/// Bar graphs (the web's g2-bargraph; 2.MD.D.10: read; compare, put together). Four bars across, 4 squares tall a square
/// apart, a vote a block, the names at their left, the scale 0–10 under them on the strong lines, the title over; the web's
/// question on the top rows. Drop a line from the end of each bar asked about (it lands on the scale, the number lights);
/// how many more: hop the part sticking out past the shorter bar's end; in all: count on along the second bar from the
/// first one's number. Then `7 − 4 = [3]` or `7 + 4 = [11]`.
///
/// "theme" 0–2; "v0"…"v3" the bars; "x", "y" the bars asked about; "kind" 0 how many more, 1 in all. "at": 0 read x, 1 read
/// y, 2 hop or count on, 3 write, 4 done. Boxes: "a", "b" the drops (100 × bar + where it landed), "h" the hop (Len2.code),
/// "k" counted on (50 + bar: another bar), "x" written.
public enum BarGraph2 {
    public struct Theme: Sendable { public let title: String, names: [String] }
    public static let themes: [Theme] = [
        Theme(title: "Our favorite fruit", names: ["apples", "bananas", "grapes", "pears"]),
        Theme(title: "Pets in our class", names: ["dogs", "cats", "fish", "birds"]),
        Theme(title: "Weather this month", names: ["sunny", "rainy", "cloudy", "windy"]),
    ]
    public static func numbers(theme: Int, values v: [Int], x: Int, y: Int, more: Bool) -> Numbers {
        var out: Numbers = ["theme": Double(theme), "x": Double(x), "y": Double(y), "kind": more ? 0 : 1]
        for j in 0..<4 { out["v\(j)"] = Double(j < v.count ? v[j] : 1) }
        return out
    }
    public static func drop(_ bar: Int, _ at: Int) -> Int { 100 * bar + at }
    public struct Parts: Sendable {
        public let theme: Int, v: [Int], x: Int, y: Int, more: Bool
        public init(_ n: Numbers) {
            theme = max(0, min(2, Data2.int(n, "theme")))
            var vs: [Int] = []
            for j in 0..<4 { vs.append(max(1, min(10, Data2.int(n, "v\(j)", j + 3)))) }
            v = vs
            x = max(0, min(3, Data2.int(n, "x")))
            let yy = max(0, min(3, Data2.int(n, "y", 1))); y = yy == x ? (x + 1) % 4 : yy
            more = Data2.int(n, "kind") == 0
        }
        public var th: Theme { BarGraph2.themes[theme] }
        public var X: String { th.names[x] }
        public var Y: String { th.names[y] }
        public var a: Int { v[x] }
        public var b: Int { v[y] }
        public var answer: Int { more ? a - b : a + b }
        public var question: String {
            switch (theme, more) {
            case (0, true): return "How many more children picked \(X) than \(Y)?"
            case (0, false): return "How many children picked \(X) or \(Y)?"
            case (1, true): return "How many more \(X) than \(Y) are there?"
            case (1, false): return "How many \(X) and \(Y) are there in all?"
            case (_, true): return "How many more \(X) days than \(Y) days were there?"
            default: return "How many \(X) and \(Y) days were there in all?"
            }
        }
        public var sayThird: String { more ? "Hop the part sticking out." : "Count on from \(a)." }
        public var why: String { more ? "The part sticking out is how many more." : "Counting on puts the two bars together." }
        /// A line dropped from a bar: another bar, or past or short of its end.
        public func dropMiss(_ k: Int, want j: Int) -> String {
            let bar = max(0, min(3, k / 100)), at = k % 100, name = th.names[j], n = v[j]
            if bar != j { return "That's the \(th.names[bar]) bar. Find \(name)." }
            return at > n ? "That's \(at). The \(name) bar stops before \(at)." : "That's \(at). The \(name) bar goes past \(at)."
        }
        public func hopMiss(_ k: Int) -> String {
            let c = Len2.decode(k)
            if c.from != b { return "Start where the \(Y) bar stops." }
            return "That's \(abs(c.to - c.from)). Hop to the end of the \(X) bar."
        }
        public func countMiss(_ k: Int) -> String { "That's the \(th.names[max(0, min(3, k - 50))]) bar. Count on along \(Y)." }
        public var slips: [(Int, String)] {
            if more { return [(a + b, "\"How many more\" means compare. Take \(b) away from \(a)."), (a, "\(a) is all of the \(X). How many more is that than \(b)?")] }
            return [(abs(a - b), "\"In all\" means put them together. Add \(a) and \(b)."), (max(a, b), "Count both bars together.")]
        }
        public var plain: String { more ? "Count the hops from \(b) to \(a)." : "Count on \(b) from \(a)." }
    }

    /// The web's: four values 1–10 (up to 8 and all different for problems 0–2); bars x and y; how many more has x longer.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let top = i < 3 ? 8 : 10
        while true {
            var v: [Int] = []
            for _ in 0..<4 { v.append(Int.random(in: 1...top, using: &rng)) }
            if i < 3 && Set(v).count < 4 { continue }
            let order = Data2.shuffled([0, 1, 2, 3], &rng), x = order[0], y = order[1]
            let more = Int.random(in: 0...1, using: &rng) == 0
            if more && v[x] <= v[y] { continue }
            return numbers(theme: Int.random(in: 0...2, using: &rng), values: v, x: x, y: y, more: more)
        }
    }

    public static let spec = LessonSpec(id: "g2-bargraph", title: "Bar graphs", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).question)] },
        idea: { x in Parts(x).why },
        depends: ["g1-picgraph"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).more }), CheckItem(3, when: { !Parts($0).more }), CheckItem(3, when: { Parts($0).more })]) { n in
        let P = Parts(n)
        func read(_ j: Int, _ box: String, _ at: Int) -> LessonStep {
            let hint = "Go along the \(P.th.names[j]) bar to its end."
            return LessonStep(StepWords(say: "Read the \(P.th.names[j]) bar.", hint: hint, action: "Check"),
                answer: G2.hand(box, drop(j, P.v[j]), hint: hint, explain: "\(P.th.names[j]): \(P.v[j]).", said: { P.dropMiss($0, want: j) }),
                picture: ["at": Double(at)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        var out = [read(P.x, "a", 0), read(P.y, "b", 1)]
        if P.more {
            let hint = "Start where the \(P.Y) bar stops."
            out.append(LessonStep(StepWords(say: P.sayThird, hint: hint, action: "Check"),
                answer: G2.hand("h", Len2.code(P.b, P.a), hint: hint, explain: "\(P.a - P.b) more.", said: { P.hopMiss($0) }),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        } else {
            let hint = "Tap each block of the \(P.Y) bar."
            out.append(LessonStep(StepWords(say: P.sayThird, hint: hint, action: "Check"),
                answer: G2.hand("k", P.b, hint: hint, explain: Data2.landings(Array((P.a + 1)...(P.a + P.b))) + ".", said: { P.countMiss($0) }),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        out.append(LessonStep(StepWords(say: G2.write, hint: P.plain, action: "Check"),
            answer: G2.typed("x", P.answer, P.slips, plain: P.plain, hint: P.plain, explain: "\(P.answer)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        out.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4]))
        return out
    }
}

// MARK: - Line plots

/// Line plots (the web's g2-lineplot; 2.MD.D.9, the fold measures first). An inch is a block, as on the ruler; each X a cell
/// a block wide and 3 squares tall (2 when a stack passes 6), stacked over its number. The web's question on the top rows.
/// Plot one more (ask 0): drag the new pencil's X above its length, then tap its stack to count it, `[4] pencils`; the
/// tallest stack (1): tap it, `[5] inches`; longer than (2): tap each X right of 6, `[2] pencils`; longest take away
/// shortest (3): hop from the X farthest left to the farthest right, `8 − 4 = [4] in`. The fold (problems 2, 9, 14, 19 …):
/// five things lie under an inch ruler from 0, each with its X at its end; put each X above its length on the ruler (a
/// thing a square past a mark is nearest that mark), then tap the tallest stack, `[5] inches`.
///
/// "thing" 0–3; "lo"; "n" and "d0"… the lengths; "ask" 0–3; "v" the length asked about; "fold" 1 with "p0"…"p4" (1: a
/// square past its mark). "at" the step's kind: 0 place, 1 count, 2 tallest, 3 hop, 4 write, 5 done. Boxes: "p" placed
/// (999 all; a miss 100 × X + the mark it went over), "k" counted (100 + a stack it shouldn't), "t" the stack tapped, "h"
/// the hop (Len2.code), "x" written.
public enum LinePlot2 {
    public struct Thing: Sendable { public let many: String, one: String, title: String }
    public static let things = [Thing(many: "pencils", one: "pencil", title: "Pencil lengths"), Thing(many: "leaves", one: "leaf", title: "Leaf lengths"),
                                Thing(many: "ribbons", one: "ribbon", title: "Ribbon lengths"), Thing(many: "worms", one: "worm", title: "Worm lengths")]
    public static let allPlaced = 999
    public static func isFold(_ i: Int) -> Bool { i == 2 || (i >= 9 && (i - 9) % 5 == 0) }
    public static func howMany(_ d: [Int], _ v: Int) -> Int { d.filter { $0 == v }.count }
    public static func modes(_ d: [Int]) -> [Int] {
        let vs = Array(Set(d)).sorted()
        let top = vs.map { howMany(d, $0) }.max() ?? 0
        return vs.filter { howMany(d, $0) == top }
    }

    public static func numbers(thing: Int, lo: Int, data: [Int], ask: Int, v: Int = 0) -> Numbers {
        var out: Numbers = ["thing": Double(thing), "lo": Double(lo), "n": Double(data.count), "ask": Double(ask), "v": Double(v)]
        for (i, d) in data.enumerated() { out["d\(i)"] = Double(d) }
        return out
    }
    public static func fold(thing: Int, lo: Int, data: [Int], past: [Bool]) -> Numbers {
        var out = numbers(thing: thing, lo: lo, data: data, ask: 1)
        out["fold"] = 1
        for (i, p) in past.enumerated() { out["p\(i)"] = p ? 1 : 0 }
        return out
    }

    public enum Kind: Int, Sendable { case place, count, tall, hop, write, done }
    public struct Parts: Sendable {
        public let thing: Int, lo: Int, data: [Int], ask: Int, v: Int, fold: Bool, past: [Bool]
        public init(_ x: Numbers) {
            thing = max(0, min(3, Data2.int(x, "thing")))
            fold = Data2.int(x, "fold") != 0
            let l = Data2.int(x, "lo", 4)
            lo = fold ? max(2, min(4, l)) : max(2, min(8, l))
            let n = max(1, min(12, Data2.int(x, "n", 8)))
            var d: [Int] = [], p: [Bool] = []
            for i in 0..<n { d.append(max(lo, min(lo + 5, Data2.int(x, "d\(i)", lo + 2)))) }
            if fold { for i in 0..<n { p.append(Data2.int(x, "p\(i)") != 0) } }
            data = d; past = p
            ask = fold ? 1 : max(0, min(3, Data2.int(x, "ask")))
            v = max(lo, min(lo + 5, Data2.int(x, "v", lo + 2)))
        }
        public var th: Thing { LinePlot2.things[thing] }
        public var hi: Int { data.max() ?? lo }
        public var lw: Int { data.min() ?? lo }
        public var mode: Int { LinePlot2.modes(data).first ?? lo }
        public var steps: [Kind] {
            if fold { return [.place, .tall, .write, .done] }
            switch ask {
            case 0: return [.place, .count, .write, .done]
            case 1: return [.tall, .write, .done]
            case 2: return [.count, .write, .done]
            default: return [.hop, .write, .done]
            }
        }
        /// The X's to place: the fold's five, or the new one.
        public var toPlace: Int { fold ? data.count : ask == 0 ? 1 : 0 }
        /// Where X number i belongs.
        public func home(_ i: Int) -> Int { fold ? data[max(0, min(data.count - 1, i))] : v }
        /// The stacks as drawn once everything is placed (the new X on top of its stack).
        public func stack(_ u: Int) -> Int { howMany(data, u) + (!fold && ask == 0 && u == v ? 1 : 0) }
        /// The tallest stack's height, with the new X.
        public var tallest: Int {
            var m = 0
            for u in lo...(lo + 5) { m = max(m, stack(u)) }
            return m
        }
        public var question: String? {
            if fold { return nil }
            switch ask {
            case 0: return "Add a \(th.one) that is \(v) inches long. Then how many \(th.many) are \(v) inches long?"
            case 1: return "Which length shows up the most?"
            case 2: return "How many \(th.many) are longer than \(v) inches?"
            default: return "How much longer is the longest than the shortest?"
            }
        }
        public func say(_ k: Kind) -> String {
            switch k {
            case .place: return fold ? "Put each X above its length." : "Put its X above its length."
            case .count: return ask == 0 ? "Count the X's over \(v)." : "Tap each X right of \(v)."
            case .tall: return "Tap the tallest stack."
            case .hop: return "Hop from the shortest to the longest."
            case .write: return G2.write
            case .done: return "Each X is one \(th.one), above its length."
            }
        }
        public func placeMiss(_ k: Int) -> String {
            let i = max(0, k / 100), u = k % 100, w = home(i)
            if !fold { return "That's above \(u). The new \(th.one) is \(v) inches." }
            if i < past.count && past[i] && u == w + 1 { return "It's nearest \(w)." }
            return "That's above \(u). The \(th.one) ends near \(w)."
        }
        public func countMiss(_ k: Int) -> String {
            let u = k - 100
            if ask == 0 { return "That's the stack over \(u). Count over \(v)." }
            return u == v ? "Longer than \(v) doesn't count \(v)." : "That one is shorter than \(v)."
        }
        public func tallMiss(_ u: Int) -> String { "That stack has \(stack(u)). Find a taller one." }
        public func hopMiss(_ k: Int) -> String {
            let c = Len2.decode(k)
            if c.from != lw { return "Start at the shortest, the X farthest left." }
            return "That's \(abs(c.to - c.from)) in. Hop to the X farthest right."
        }
        /// How many X's the count step counts.
        public var counted: Int { ask == 0 ? stack(v) : data.filter { $0 > v }.count }
        public var answer: Int {
            if fold || ask == 1 { return mode }
            if ask == 0 || ask == 2 { return counted }
            return hi - lw
        }
        public var slips: [(Int, String)] {
            if fold || ask == 1 {
                let near = "That number is next to the tallest stack. Read the number right under it."
                return [(howMany(data, mode), "That's how many X's. Write the length under the stack."), (mode - 1, near), (mode + 1, near)]
            }
            if ask == 0 {
                let n = counted
                return [(n - 1, "Count the new \(th.one) too: its X is on top of the stack."),
                        (howMany(data, v - 1), "That's the stack above \(v - 1). Find \(v) on the line first."),
                        (howMany(data, v + 1), "That's the stack above \(v + 1). Find \(v) on the line first."),
                        (data.count + 1, "That's every \(th.one). Count only the X's above \(v).")]
            }
            if ask == 2 { return [(data.filter { $0 >= v }.count, "Longer than \(v) doesn't count \(v).")] }
            return [(hi + lw, "How much longer means the difference. Subtract."), (hi - lw + 1, "Count the hops, not the marks.")]
        }
        public var plain: String {
            if fold || ask == 1 { return "Read the number under the tallest stack." }
            if ask == 0 { return "Count the X's above \(v), the new one too." }
            if ask == 2 { return "Count the X's to the right of \(v)." }
            return "Take \(lw) away from \(hi)."
        }
        /// The record's word after its box, and its left side (`8 − 4 =`, ask 3 only).
        public var unit: String { fold || ask == 1 ? "inches" : ask == 3 ? "in" : th.many }
    }

    /// The web's: 8 lengths for problems 0–2 (asks 0, 1), then 8–12 and the ask by index % 4, one tallest stack; the fold on
    /// 2, 9, 14, 19 …: five lengths lo to lo + 5 (lo 2–4, so a 0–10 ruler fits), one tallest stack of 3 at most.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if isFold(i) {
            while true {
                let lo = r(2, 4)
                var lens: [Int] = [], past: [Bool] = []
                for _ in 0..<5 { lens.append(lo + r(0, 5)); past.append(r(0, 1) == 1) }
                let m = modes(lens)
                if m.count != 1 || howMany(lens, m[0]) > 3 { continue }
                return fold(thing: r(0, 3), lo: lo, data: lens, past: past)
            }
        }
        let early = i < 3, ask = early ? i % 2 : i % 4, size = early ? 8 : r(8, 12)
        while true {
            let lo = r(2, 8)
            var data: [Int] = []
            for _ in 0..<size { data.append(lo + min(5, (r(0, 5) + r(0, 5)) / 2)) }
            if modes(data).count != 1 { continue }
            let vs = Array(Set(data)).sorted()
            let opts = ask == 2 ? vs.filter { u in data.contains { $0 > u } } : vs
            if opts.isEmpty { continue }
            return numbers(thing: r(0, 3), lo: lo, data: data, ask: ask, v: opts[r(0, opts.count - 1)])
        }
    }

    public static let spec = LessonSpec(id: "g2-lineplot", title: "Line plots", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.text(P.question ?? P.th.title)] },
        idea: { x in Parts(x).say(.done) },
        depends: ["g2-bargraph", "g2-measure"],
        check: [CheckItem(4), CheckItem(5), CheckItem(6), CheckItem(7)]) { x in
        let P = Parts(x)
        var out: [LessonStep] = []
        for k in P.steps {
            let at: Numbers = ["at": Double(k.rawValue)]
            switch k {
            case .place:
                let hint = P.fold ? "Each thing's end is on the ruler." : "Find \(P.v) on the line."
                out.append(LessonStep(StepWords(say: P.say(k), hint: hint, action: "Check"),
                    answer: G2.hand("p", allPlaced, hint: hint, explain: "Each X is above its length.", said: { P.placeMiss($0) }),
                    picture: at, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .count:
                let hint = P.ask == 0 ? "Tap the stack over \(P.v)." : "Tap the X's right of \(P.v)."
                out.append(LessonStep(StepWords(say: P.say(k), hint: hint, action: "Check"),
                    answer: G2.hand("k", P.counted, hint: hint, explain: "\(P.counted).", said: { P.countMiss($0) }),
                    picture: at, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .tall:
                let hint = "Look for the stack with the most X's."
                out.append(LessonStep(StepWords(say: P.say(k), hint: hint, action: "Check"),
                    answer: G2.hand("t", P.mode, hint: hint, explain: "\(P.mode) inches.", said: { P.tallMiss($0) }),
                    picture: at, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .hop:
                let hint = "Start at the X farthest left."
                out.append(LessonStep(StepWords(say: P.say(k), hint: hint, action: "Check"),
                    answer: G2.hand("h", Len2.code(P.lw, P.hi), hint: hint, explain: "\(P.hi - P.lw) in.", said: { P.hopMiss($0) }),
                    picture: at, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .write:
                out.append(LessonStep(StepWords(say: P.say(k), hint: P.plain, action: "Check"),
                    answer: G2.typed("x", P.answer, P.slips, plain: P.plain, hint: P.plain, explain: "\(P.answer) \(P.unit)."),
                    picture: at, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .done:
                out.append(LessonStep(StepWords(say: P.say(k), hint: "", action: "Next problem"), picture: at))
            }
        }
        return out
    }
}
