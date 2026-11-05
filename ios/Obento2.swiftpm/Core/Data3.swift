import Foundation

// 3rd grade's chapter 7, Data (design/grade3.md chapter 7, the preview design/prototype/grade3-ch7.html): scaled picture
// and bar graphs read by the hands (tap the key or the scale, drag along a row or drop a line from a bar's end to the
// scale), a bar graph drawn from its numbers (drag each bar out, tap pictures in), and line plots in halves and fourths
// (a crayon measured on a fourths ruler, X's placed on a plot and its stacks read). Every number the child writes is typed
// with the iPad's keys and Check, as the preview types; misses and slips are the preview's words.

/// What the chapter shares: the four graphs (the web's g3-graphs themes with the questions Draw a bar graph adds), the
/// scales 2, 5 and 10, what a row or bar can show, and the words for pictures and lines.
public enum Data3 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func r(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { a >= b ? a : Int.random(in: a...b, using: &rng) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func shuffled(_ a: [Int], _ rng: inout SeededRandom) -> [Int] {
        var b = a
        if b.count > 1 { for i in stride(from: b.count - 1, to: 0, by: -1) { let j = Int.random(in: 0...i, using: &rng); b.swapAt(i, j) } }
        return b
    }
    public static func plural(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }

    /// A graph's theme: its title, four names, picture, what it counts, and its questions.
    public struct Theme: Sendable {
        public let title: String, names: [String], icon: String, things: String
        static let days = ["Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday", "Thu": "Thursday"]
        func day(_ n: String) -> String { Theme.days[n] ?? n }
        /// "How many books did Ana read?"
        public func ask(_ n: String) -> String {
            switch things {
            case "books": return "How many books did \(n) read?"
            case "votes": return "How many votes for \(n)?"
            case "pets": return "How many \(n.lowercased())?"
            default: return "How many cookies on \(day(n))?"
            }
        }
        public func more(_ a: String, _ b: String) -> String {
            switch things {
            case "books": return "How many more books did \(a) read than \(b)?"
            case "votes": return "How many more votes for \(a) than \(b)?"
            case "pets": return "How many more \(a.lowercased()) than \(b.lowercased())?"
            default: return "How many more cookies on \(day(a)) than on \(day(b))?"
            }
        }
        public func fewer(_ a: String, _ b: String) -> String {
            switch things {
            case "books": return "How many fewer books did \(b) read than \(a)?"
            case "votes": return "How many fewer votes for \(b) than \(a)?"
            case "pets": return "How many fewer \(b.lowercased()) than \(a.lowercased())?"
            default: return "How many fewer cookies on \(day(b)) than on \(day(a))?"
            }
        }
        public func two(_ a: String, _ b: String, _ c: String) -> String {
            switch things {
            case "books": return "How many fewer books did \(c) read than \(a) and \(b) together?"
            case "votes": return "How many fewer votes for \(c) than for \(a) and \(b) together?"
            case "pets": return "How many fewer \(c.lowercased()) than \(a.lowercased()) and \(b.lowercased()) together?"
            default: return "How many fewer cookies on \(day(c)) than on \(day(a)) and \(day(b)) together?"
            }
        }
        /// What row j counts, one or many: "35 dogs", "1 book" ("fish" stays).
        public func unit(_ j: Int, _ n: Int) -> String {
            let m = things == "pets" ? names[j].lowercased() : things
            if n == 1 && m != "fish" && m.hasSuffix("s") { return String(m.dropLast()) }
            return m
        }
    }
    public static let themes: [Theme] = [
        Theme(title: "Books read this month", names: ["Ana", "Ben", "Cleo", "Dev"], icon: "star", things: "books"),
        Theme(title: "Favorite fruit", names: ["Apples", "Pears", "Plums", "Kiwis"], icon: "apple", things: "votes"),
        Theme(title: "Pets at our school", names: ["Dogs", "Cats", "Fish", "Birds"], icon: "paw", things: "pets"),
        Theme(title: "Cookies sold", names: ["Mon", "Tue", "Wed", "Thu"], icon: "cookie", things: "cookies"),
    ]
    public static let scales = [2, 5, 10]
    /// (The web's) the smallest amount a row or bar can show: a half picture for a key of 2, half a line for 2 and 10.
    public static func grain(_ type: Int, _ s: Int) -> Int { type == 0 ? (s == 2 ? 1 : s) : (s == 5 ? 5 : s / 2) }
    /// The most: 9 pictures, or 8 lines.
    public static func most(_ type: Int, _ s: Int) -> Int { type == 0 ? 9 * s : 8 * s }
    /// n2 half pictures as words: "4 pictures and a half", "half a picture".
    public static func picWords(_ n2: Int) -> String {
        let w = n2 / 2, h = n2 % 2
        if w == 0 && h == 1 { return "half a picture" }
        return plural(w, "picture", "pictures") + (h == 1 ? " and a half" : "")
    }
    /// l half lines as words: "3 lines", "3 and a half lines".
    public static func lineWords(halves l: Int) -> String { l % 2 == 0 ? plural(l / 2, "line", "lines") : "\(l / 2) and a half lines" }

    /// A step answered by a code its hand move puts in the box: right when it's `want`, else what `said` says.
    static func hand(_ box: String, _ want: Int, hint: String, explain: String, said: @escaping @Sendable (Int) -> String) -> AnswerTask {
        G2.hand(box, want, hint: hint, explain: explain, said: said)
    }
    /// A typed number: right, a known slip (the preview's words), or "Not quite." and the hint. Slips that aren't whole
    /// numbers (half a count), are below 0 or repeat are left out, as the web's slips() does.
    static func typed(_ box: String, _ want: Int, _ slips: [(Double, String)], hint: String, explain: String) -> AnswerTask {
        var list: [(Int, String)] = []
        for s in slips where s.0 == s.0.rounded() && s.0 >= 0 { list.append((Int(s.0), s.1)) }
        return G2.typed(box, want, list, plain: "Not quite. \(hint)", hint: hint, explain: explain)
    }
    static func numbers(type: Int, scale: Int, theme: Int, counts: [Int], ask: Int, x: Int, y: Int) -> Numbers {
        var out: Numbers = ["type": Double(type), "scale": Double(scale), "theme": Double(theme), "ask": Double(ask), "x": Double(x), "y": Double(y)]
        for j in 0..<4 { out["c\(j)"] = Double(j < counts.count ? counts[j] : 1) }
        return out
    }
    /// Four counts a graph of this type and scale can show, all different, in a random order.
    static func counts(_ type: Int, _ scale: Int, _ rng: inout SeededRandom) -> [Int] {
        let g = grain(type, scale), hi = most(type, scale) / g
        var all: [Int] = []
        for k in 0..<hi { all.append((k + 1) * g) }
        return Array(shuffled(all, &rng).prefix(4))
    }
}

// MARK: - Scaled picture and bar graphs

/// Scaled picture and bar graphs (the web's g3-graphs; 3.MD.B.3: read; how many more, together). A picture graph: tap the
/// key (every picture says what it's worth), drag along a row (a half picture at a time, "4 pictures and a half"), write
/// `4 × 2 + 1 = [9]`. A bar graph: tap the scale (its numbers light), drag a line from a bar's end down to the scale (it
/// snaps to half lines; the readout names the lines either side, "40 | 50"), write `Dogs: [45]`. How many more or
/// together: the second row the same way, then `35 − 20 = [15]` (the shorter one's end drops a dashed line across the
/// longer one and the extra is bracketed) or `35 + 20 = [55]`.
///
/// "type" 0 picture graph, 1 bar graph; "scale" 2, 5 or 10; "theme" 0–3; "c0"…"c3"; "ask" 0 read one, 1 how many more, 2
/// together; "x", "y" the rows. "at": 0 the key or scale, 1 drag x, 2 write x, 3 drag y, 4 write y, 5 the sum or
/// difference, 9 done. Boxes: "k" the tap (1 the key or scale, 0 the graph); "dx", "dy" the drags (100 × row + half pictures
/// or half lines; `notDown` a line let go short of the scale); "x", "y", "op" written.
public enum Graphs3 {
    public static func numbers(type: Int, scale: Int, theme: Int, counts: [Int], ask: Int, x: Int, y: Int) -> Numbers {
        Data3.numbers(type: type, scale: scale, theme: theme, counts: counts, ask: ask, x: x, y: y)
    }
    public static func code(row: Int, _ n: Int) -> Int { 100 * row + n }
    public static let notDown = 9000

    public struct Parts: Sendable {
        public let type: Int, s: Int, theme: Int, c: [Int], ask: Int, x: Int, y: Int
        public init(_ n: Numbers) {
            type = Data3.int(n, "type") == 1 ? 1 : 0
            let sc = Data3.int(n, "scale", 2); s = Data3.scales.contains(sc) ? sc : 2
            theme = max(0, min(3, Data3.int(n, "theme")))
            let g = Data3.grain(type, s), top = Data3.most(type, s)
            var cs: [Int] = []
            for j in 0..<4 { cs.append(max(g, min(top, Data3.int(n, "c\(j)", (j + 1) * g)))) }
            c = cs
            ask = max(0, min(2, Data3.int(n, "ask")))
            x = max(0, min(3, Data3.int(n, "x")))
            let yy = max(0, min(3, Data3.int(n, "y", 1))); y = yy == x ? (x + 1) % 4 : yy
        }
        public var th: Data3.Theme { Data3.themes[theme] }
        public var pic: Bool { type == 0 }
        public var a: Int { c[x] }
        public var b: Int { c[y] }
        /// Half steps a bar's line snaps to: whole lines for a scale of 5 (its bars never end between lines).
        public var hs: Int { s == 5 ? 2 : 1 }
        /// Row j's count in half pictures (a picture graph) or half lines (a bar graph).
        public func halves(_ j: Int) -> Int { 2 * c[j] / s }
        public func whole(_ j: Int) -> Int { c[j] / s }
        public func half(_ j: Int) -> Bool { c[j] % s != 0 }
        public func sayDrag(_ j: Int) -> String {
            pic ? "Drag along the \(th.names[j]) row." : "Drag the line from the end of the \(th.names[j]) bar to the scale."
        }
        public var sayOp: String {
            ask == 1 ? "How many more for \(th.names[x]) than \(th.names[y])?" : "How many for \(th.names[x]) and \(th.names[y]) together?"
        }
        public var why: String {
            if ask == 1 { return "How many more means subtract." }
            if ask == 2 { return "Together means add." }
            let cx = c[x]
            if pic {
                let an = "aeiou".contains(th.icon.prefix(1)) ? "an" : "a"
                let halfSaid = half(x) ? ", half \(an) \(th.icon) is \(s / 2)" : ""
                return "Each \(th.icon) is \(s)\(halfSaid): \(cx) \(th.unit(x, cx))."
            }
            let below = whole(x) * s
            return half(x) ? "Halfway between \(below) and \(below + s) is \(cx)." : "Each line is \(s): the bar ends at \(cx)."
        }
        public var tapMiss: String {
            pic ? "A picture can stand for more than 1. Tap the key to see how many." : "Tap the numbers along the bottom to see what each line is."
        }
        /// A drag let go: another row, past the end, short of it, or a line short of the scale.
        public func dragMiss(_ k: Int, want j: Int) -> String {
            let name = th.names[j], cnt = c[j]
            if k == Graphs3.notDown { return "Drag the line all the way down to the scale." }
            let row = max(0, min(3, k / 100)), n = k % 100
            if row != j { return pic ? "That's the \(th.names[row]) row." : "That's the \(th.names[row]) bar." }
            if pic {
                let T = halves(j)
                if n == T + 1 && half(j) { return "The last picture is only half. Count the whole ones." }
                if n > T { return "That's past the end of the \(name) row." }
                return "That's \(Data3.picWords(n)). The \(name) row goes on."
            }
            let v = n * s / 2
            return v > cnt ? "That's \(v). The \(name) bar stops before \(v)." : "That's \(v). The \(name) bar goes past \(v)."
        }
        /// The count typed: the web's slips.
        public func slips(_ j: Int) -> [(Double, String)] {
            let cnt = c[j], w = whole(j), below = w * s
            var out: [(Double, String)] = []
            if pic {
                out.append((Double(w), "Each picture is \(s), so \(Data3.plural(w, "picture", "pictures")) is \(w) × \(s)."))
                if half(j) { out.append((Double(below), "Don't forget the half picture: half of \(s) is \(s / 2).")) }
                return out
            }
            out.append((Double(cnt) / Double(s), "Each line is \(s), so count by \(s)s."))
            if below != cnt { out.append((Double(below), "The bar ends halfway between \(below) and \(below + s). Halfway is \(below + s / 2).")) }
            for (k, v) in c.enumerated() where k != j { out.append((Double(v), "That's the \(th.names[k]) bar.")) }
            return out
        }
        public func countHint(_ j: Int) -> String { pic ? "Each picture is \(s)." : "Follow the end of the \(th.names[j]) bar down to the scale." }
        public var answer: Int { ask == 1 ? a - b : a + b }
        public var opSlips: [(Double, String)] {
            ask == 1 ? [(Double(a + b), "How many more means the difference. Subtract.")] : [(Double(abs(a - b)), "Together means add.")]
        }
        public var opHint: String { ask == 1 ? "Subtract the smaller from the bigger." : "Add the two." }
    }

    /// The web's: problems 0–2 picture graphs by 2 or 5, one row; then type = i % 2, ask = i % 3, a bar graph's scale
    /// scales[(i >> 1) % 3] (so two in a row never share one), a picture graph's any.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3, type = early ? 0 : i % 2
        let scale = early ? Data3.pick([2, 5], &rng) : (type == 1 ? Data3.scales[(i >> 1) % 3] : Data3.pick(Data3.scales, &rng))
        let ask = early ? 0 : i % 3
        while true {
            let counts = Data3.counts(type, scale, &rng), x = Data3.r(0, 3, &rng)
            var others: [Int] = []
            for k in 0..<4 where k != x { others.append(k) }
            let y = Data3.pick(others, &rng)
            if ask == 1 && counts[x] <= counts[y] { continue }
            return numbers(type: type, scale: scale, theme: Data3.r(0, 3, &rng), counts: counts, ask: ask, x: x, y: y)
        }
    }

    public static let spec = LessonSpec(id: "g3-graphs", title: "Scaled picture and bar graphs", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { n in let P = Parts(n); return [.text(P.ask == 0 ? P.th.ask(P.th.names[P.x]) : P.sayOp)] },
        idea: { _ in "In a scaled graph, one picture, or one line along the bottom, can stand for more than 1." },
        depends: ["g2-bargraph", "g2-skip"],
        check: [CheckItem(4), CheckItem(5), CheckItem(7, when: { let P = Parts($0); return P.half(P.x) || P.half(P.y) }),
                CheckItem(8, when: { let P = Parts($0); return P.s == 2 && P.half(P.x) })]) { n in
        let P = Parts(n), th = P.th
        let tapHint = P.pic ? "The key under the graph says what one picture is worth." : "The numbers along the bottom say what each line is."
        let tap = LessonStep(StepWords(say: P.pic ? "Tap the key." : "Tap the scale.", hint: tapHint, action: "Check"),
            answer: Data3.hand("k", 1, hint: tapHint, explain: P.pic ? "The key says each picture is \(P.s) \(th.things)." : "The lines go up by \(P.s).",
                               said: { _ in P.tapMiss }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        func drag(_ j: Int, _ box: String, _ at: Int) -> LessonStep {
            let hint = P.pic ? "Run your finger along the \(th.names[j]) row to its last picture." : "Start at the end of the \(th.names[j]) bar and drag straight down."
            let explain = P.pic ? "\(Data3.picWords(P.halves(j))) for \(th.names[j])." : "The \(th.names[j]) bar reaches \(P.c[j])."
            return LessonStep(StepWords(say: P.sayDrag(j), hint: hint, action: "Check"),
                answer: Data3.hand(box, code(row: j, P.halves(j)), hint: hint, explain: explain, said: { k in P.dragMiss(k, want: j) }),
                picture: ["at": Double(at)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        func write(_ j: Int, _ box: String, _ at: Int) -> LessonStep {
            let hint = P.countHint(j), cnt = P.c[j], w = P.whole(j)
            let explain = P.pic ? "\(w) × \(P.s)\(P.half(j) ? " + \(P.s / 2)" : "") = \(cnt)." : "The \(th.names[j]) bar reaches \(cnt)."
            return LessonStep(StepWords(say: th.ask(th.names[j]), hint: hint, action: "Check"),
                answer: Data3.typed(box, cnt, P.slips(j), hint: hint, explain: explain),
                picture: ["at": Double(at)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        var out = [tap, drag(P.x, "dx", 1), write(P.x, "x", 2)]
        if P.ask > 0 {
            out.append(drag(P.y, "dy", 3)); out.append(write(P.y, "y", 4))
            out.append(LessonStep(StepWords(say: P.sayOp, hint: P.opHint, action: "Check"),
                answer: Data3.typed("op", P.answer, P.opSlips, hint: P.opHint, explain: "\(P.a) \(P.ask == 1 ? "−" : "+") \(P.b) = \(P.answer)."),
                picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        out.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 9]))
        return out
    }
}

// MARK: - Draw a bar graph

/// Draw a bar graph (g3-drawgraph, new; 3.MD.B.3: draw; one- and two-step how many more and fewer). The empty graph with its
/// scale (or key); each row starts with its name and count ("Dogs 35"). A bar is dragged out from the axis (half lines for
/// scales of 2 and 10, whole lines for 5; "35 dogs"); a picture row is tapped a picture at a time (tap the last again: a
/// half, for a key of 2; then gone; "4 pictures and a half · 9"). A row done turns solid and is ticked. Then (from problem
/// 4) how many more or fewer, `35 − 20 = [15]`, and (from problem 7) two steps, `35 + 20 = [55]`, `55 − 15 = [40]`.
///
/// "type", "scale", "theme", "c0"…"c3", "x", "y", "z" (two steps), "fewer"; "ask" 0 draw only, 1 how many more or fewer, 2
/// two steps. "at": 0 draw, 1 the difference (or the sum), 2 the two-step difference, 9 done. Boxes: "r" the rows (100 all
/// made; a miss: a bar let go wrong, 1000 × row + what it shows; a row tapped past its count, 10000 more); "op", "sum", "diff".
public enum DrawGraph3 {
    public static let allMade = 100
    public static func dragCode(_ row: Int, _ v: Int) -> Int { 1000 * row + v }
    public static func tapCode(_ row: Int, _ v: Int) -> Int { 10000 + 1000 * row + v }
    public static func numbers(type: Int, scale: Int, theme: Int, counts: [Int], ask: Int, x: Int, y: Int, z: Int = 0, fewer: Bool = false) -> Numbers {
        var out = Data3.numbers(type: type, scale: scale, theme: theme, counts: counts, ask: ask, x: x, y: y)
        out["z"] = Double(z); out["fewer"] = fewer ? 1 : 0
        return out
    }

    public struct Parts: Sendable {
        public let type: Int, s: Int, theme: Int, c: [Int], ask: Int, x: Int, y: Int, z: Int, fewer: Bool
        public init(_ n: Numbers) {
            let G = Graphs3.Parts(n)
            let gx = G.x, gy = G.y
            type = G.type; s = G.s; theme = G.theme; c = G.c; ask = G.ask; x = gx; y = gy
            var zz = max(0, min(3, Data3.int(n, "z")))
            if zz == gx || zz == gy { zz = (0..<4).first { $0 != gx && $0 != gy } ?? 0 }
            z = zz
            fewer = Data3.int(n, "fewer") == 1
        }
        public var th: Data3.Theme { Data3.themes[theme] }
        public var pic: Bool { type == 0 }
        public var a: Int { c[x] }
        public var b: Int { c[y] }
        public var cz: Int { c[z] }
        public var sum: Int { a + b }
        public var diff: Int { sum - cz }
        /// A bar's unit: squares a drag snaps by (6 a whole line for 5, else 3 a half line); a picture row 2 (a half picture).
        public var unit: Int { pic ? 2 : (s == 5 ? 6 : 3) }
        /// Row j's count in units.
        public func units(_ j: Int) -> Int { pic ? 2 * c[j] / s : c[j] * 6 / (s * unit) }
        /// What n units show.
        public func value(_ n: Int) -> Int { pic ? n * s / 2 : n * unit * s / 6 }
        public func halves(_ j: Int) -> Int { 2 * c[j] / s }
        public var question: String {
            if ask == 1 { return fewer ? th.fewer(th.names[x], th.names[y]) : th.more(th.names[x], th.names[y]) }
            if ask == 2 { return th.two(th.names[x], th.names[y], th.names[z]) }
            return ""
        }
        public var sayDraw: String { pic ? "Tap to add pictures." : "Drag each bar to its number." }
        /// The Say: one row's count as lines or pictures (a row with a half when there is one).
        public var why: String {
            if ask == 1 { return fewer ? "How many fewer means subtract." : "How many more means subtract." }
            if ask == 2 { return "Add the two, then subtract." }
            let sj = c.firstIndex { $0 % s != 0 } ?? 0, sc = c[sj]
            if pic { return "Each picture is \(s), so \(sc) is \(Data3.picWords(2 * sc / s))." }
            if sc % s != 0 { return "Each line is \(s), so \(sc) ends half a line past \(sc / s * s)." }
            return "Each line is \(s), so \(sc) is \(Data3.lineWords(halves: 2 * sc / s))."
        }
        /// The readout while a bar is dragged or a row tapped: "35 dogs", "4 pictures and a half · 9".
        public func readout(_ j: Int, _ n: Int) -> String {
            let v = value(n)
            return pic ? "\(Data3.picWords(n)) · \(v)" : "\(v) \(th.unit(j, v))"
        }
        /// A row let go or tapped wrong: what it shows and what it should.
        public func rowMiss(_ k: Int) -> String {
            let tapped = k >= 10000, rest = tapped ? k - 10000 : k
            let j = max(0, min(3, rest / 1000)), v = rest % 1000, cnt = c[j], name = th.names[j]
            if tapped {
                let lastHalf = s == 2 && v % 2 == 1
                let fix: String
                if lastHalf { fix = "Tap the last one to take it away." }
                else if s == 2 && v - cnt == 1 { fix = "Tap the last one to make it a half." }
                else if s == 2 { fix = "Tap the last one twice to take it away." }
                else { fix = "Tap the last one to take it away." }
                return "That's \(v). \(name) is \(cnt). \(fix)"
            }
            if v == cnt * s { return "That's \(v). Each line is \(s), so \(cnt) is \(Data3.lineWords(halves: 2 * cnt / s))." }
            let dl2 = 2 * (v - cnt) / s
            let fix: String
            switch dl2 {
            case 1: fix = "Back half a line."
            case -1: fix = "On half a line."
            case 2: fix = "Back a line."
            case -2: fix = "On a line."
            default: fix = "Each line is \(s)."
            }
            return "That's \(v). \(name) is \(cnt). \(fix)"
        }
        public var opSlips: [(Double, String)] { [(Double(a + b), "How many \(fewer ? "fewer" : "more") means the difference. Subtract.")] }
        public var sumSlips: [(Double, String)] { [(Double(abs(a - b)), "Together means add.")] }
        public var diffSlips: [(Double, String)] {
            [(Double(sum + cz), "How many fewer means the difference. Subtract."), (Double(abs(cz - a)), "First put \(th.names[x]) and \(th.names[y]) together.")]
        }
    }

    /// The preview's: problems 0–2 bar graphs by 5 or 10, whole lines, draw only; problem 3 a bar graph by 2 with a half
    /// line; then a picture graph one in three (problems 4, 7, 10 …); the question from problem 3 by [more or fewer, draw
    /// only, more or fewer, two steps], so two steps first at problem 6.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let type = i >= 3 && (i - 4) % 3 == 0 ? 0 : 1
        let scale: Int
        if type == 0 { scale = Data3.pick(Data3.scales, &rng) }
        else if i < 3 { scale = Data3.pick([5, 10], &rng) }
        else if i == 3 { scale = 2 }
        else { scale = Data3.scales[(i >> 1) % 3] }
        let ask = i < 3 ? 0 : [1, 0, 1, 2][(i - 3) % 4]
        while true {
            var counts: [Int]
            if i < 3 {
                var all: [Int] = []
                for k in 0..<8 { all.append((k + 1) * scale) }
                counts = Array(Data3.shuffled(all, &rng).prefix(4))
            } else { counts = Data3.counts(type, scale, &rng) }
            if i == 3 && counts.allSatisfy({ $0 % scale == 0 }) { continue }
            let order = Data3.shuffled([0, 1, 2, 3], &rng), x = order[0], y = order[1], z = order[2]
            if ask >= 1 && counts[x] <= counts[y] { continue }
            if ask == 2 && counts[z] >= counts[x] + counts[y] { continue }
            return numbers(type: type, scale: scale, theme: Data3.r(0, 3, &rng), counts: counts, ask: ask, x: x, y: y, z: ask == 2 ? z : 0,
                           fewer: ask == 1 && Data3.r(0, 1, &rng) == 1)
        }
    }

    public static let spec = LessonSpec(id: "g3-drawgraph", title: "Draw a bar graph", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { n in let P = Parts(n); return [.text(P.ask == 0 ? P.th.title : P.question)] },
        idea: { _ in "Each line of the scale stands for more than 1, so a bar ends where its number says." },
        depends: ["g3-graphs", "g2-makegraph"],
        check: [CheckItem(3), CheckItem(4), CheckItem(5), CheckItem(6)]) { n in
        let P = Parts(n)
        let drawHint = P.pic ? "Each tap adds a picture worth \(P.s)." : "Each line is \(P.s). Let go where the bar reaches its number."
        let draw = LessonStep(StepWords(say: P.sayDraw, hint: drawHint, action: "Check"),
            answer: Data3.hand("r", allMade, hint: drawHint, explain: "Each row ends at its number.", said: { P.rowMiss($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        var out = [draw]
        if P.ask == 1 {
            let hint = "Subtract the smaller from the bigger."
            out.append(LessonStep(StepWords(say: P.question, hint: hint, action: "Check"),
                answer: Data3.typed("op", P.a - P.b, P.opSlips, hint: hint, explain: "\(P.a) − \(P.b) = \(P.a - P.b)."),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        if P.ask == 2 {
            let sumHint = "Add the two.", diffHint = "Subtract \(P.cz) from \(P.sum)."
            out.append(LessonStep(StepWords(say: P.question, hint: sumHint, action: "Check"),
                answer: Data3.typed("sum", P.sum, P.sumSlips, hint: sumHint, explain: "\(P.a) + \(P.b) = \(P.sum)."),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
            out.append(LessonStep(StepWords(say: P.question, hint: diffHint, action: "Check"),
                answer: Data3.typed("diff", P.diff, P.diffSlips, hint: diffHint, explain: "\(P.sum) − \(P.cz) = \(P.diff)."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        out.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 9]))
        return out
    }
}

// MARK: - Line plots with halves and fourths

/// Line plots with halves and fourths (the web's g3-lineplot; 3.MD.B.4). Measure: a crayon lies on an inch ruler from 0
/// (an inch is 8 squares, a fourth 2). Tap the last whole inch it passes; hop the fourths (or halves) from there to its end
/// ("3 hops"); write `[2] [3]/[4] inches`. Make and read the plot (an inch 12 squares, a fourth 3): the ruler, and under it
/// the plot over two inches. Each thing comes onto the ruler; tap where its X goes (above the mark under its end); after
/// three the rest drop in by themselves. Then tap the stack the question asks about (its X's number) and write how many,
/// or tap the tallest stack, and the record writes its length.
///
/// "kind" 0 measure, 1 the plot. Measure: "whole" 1–5, "quarters" 1–3, "to" 2 (halves) or 4. The plot: "thing" 0–3, "lo" 4
/// or 8 (fourths), "n" and "d0"… the lengths in fourths (lo to lo + 8), "ask" 0 how many in a stack, 1 which came up most,
/// "v". "at": measure 0 the whole inch, 1 the hops, 2 write, 9 done; the plot 0 place, 1 the stack, 2 write, 3 the tallest,
/// 9 done. Boxes: "i" the inch tapped; "h" the hops; "w", "n", "d" the mixed number; "p" placed (999 all; a miss 100 × X +
/// the mark tapped); "t" the stack tapped; "c" written; "m" the tallest tapped.
public enum LinePlot3 {
    public struct Thing: Sendable { public let many: String, one: String }
    public static let things = [Thing(many: "shells", one: "shell"), Thing(many: "leaves", one: "leaf"), Thing(many: "crayons", one: "crayon"), Thing(many: "bugs", one: "bug")]
    public static let allPlaced = 999
    /// How many of the first three X's are placed by hand.
    public static let byHand = 3
    static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
    /// v fourths as the web says it: "2 1/4", "2 1/2", "3".
    public static func said(_ v: Int) -> String {
        let w = v / 4, r = v % 4
        guard r != 0 else { return "\(w)" }
        let g = gcd(r, 4)
        return (w > 0 ? "\(w) " : "") + "\(r / g)/\(4 / g)"
    }
    /// A length's top and bottom, in lowest terms (3 → (0, 1): a whole).
    public static func fraction(_ v: Int) -> (whole: Int, top: Int, bottom: Int) {
        let w = v / 4, r = v % 4
        guard r != 0 else { return (w, 0, 1) }
        let g = gcd(r, 4)
        return (w, r / g, 4 / g)
    }
    public static func inchWord(_ v: Int) -> String { v == 4 ? "inch" : "inches" }
    public static func howMany(_ d: [Int], _ v: Int) -> Int { d.filter { $0 == v }.count }
    public static func modes(_ d: [Int]) -> [Int] {
        let vs = Array(Set(d)).sorted()
        let top = vs.map { howMany(d, $0) }.max() ?? 0
        return vs.filter { howMany(d, $0) == top }
    }
    public static func measure(whole: Int, quarters: Int, to: Int) -> Numbers {
        ["kind": 0, "whole": Double(whole), "quarters": Double(quarters), "to": Double(to)]
    }
    public static func plot(thing: Int, lo: Int, data: [Int], ask: Int, v: Int) -> Numbers {
        var out: Numbers = ["kind": 1, "thing": Double(thing), "lo": Double(lo), "n": Double(data.count), "ask": Double(ask), "v": Double(v)]
        for (i, d) in data.enumerated() { out["d\(i)"] = Double(d) }
        return out
    }

    public struct Parts: Sendable {
        public let kind: Int, whole: Int, quarters: Int, to: Int, thing: Int, lo: Int, data: [Int], ask: Int, v: Int
        public init(_ x: Numbers) {
            kind = Data3.int(x, "kind") == 1 ? 1 : 0
            whole = max(1, min(5, Data3.int(x, "whole", 2)))
            to = Data3.int(x, "to", 4) == 2 ? 2 : 4
            let q = Data3.int(x, "quarters", to == 2 ? 2 : 3)
            quarters = to == 2 ? 2 : (q == 1 ? 1 : 3)
            thing = max(0, min(3, Data3.int(x, "thing")))
            lo = Data3.int(x, "lo", 4) == 8 ? 8 : 4
            let n = max(1, min(12, Data3.int(x, "n", 8)))
            var d: [Int] = []
            for i in 0..<n { d.append(max(lo, min(lo + 8, Data3.int(x, "d\(i)", lo + 2)))) }
            data = d
            ask = Data3.int(x, "ask") == 1 ? 1 : 0
            v = max(lo, min(lo + 8, Data3.int(x, "v", lo + 2)))
        }
        public var th: Thing { LinePlot3.things[thing] }
        public var measure: Bool { kind == 0 }
        // measure
        /// The crayon's length in fourths.
        public var fourths: Int { 4 * whole + quarters }
        /// The ruler's inches: one more than the whole inches, at least 4.
        public var inches: Int { Swift.max(4, whole + 1) }
        /// Hops past the whole inch: 1 half, or the fourths.
        public var extra: Int { to == 2 ? 1 : quarters }
        public var pieceName: String { to == 2 ? "halves" : "fourths" }
        public var pieceOne: String { to == 2 ? "half" : "fourth" }
        /// How many hops the ruler has room for past the whole inch.
        public var hopRoom: Int { (inches - whole) * to }
        public func inchMiss(_ t: Int) -> String { t > whole ? "It hasn't reached \(t) yet." : "It passes \(t), and \(t + 1) too." }
        public func hopMiss(_ k: Int) -> String { k > extra ? "That's past the end." : "Hop all the way to its end." }
        public var measureWhy: String { "\(whole) whole \(whole == 1 ? "inch" : "inches") and \(extra) \(extra == 1 ? pieceOne : pieceName) more." }
        // the plot
        public var mode: Int { LinePlot3.modes(data).first ?? lo }
        /// How many X's stand over v.
        public var n: Int { LinePlot3.howMany(data, v) }
        public var stackMax: Int { data.map { LinePlot3.howMany(data, $0) }.max() ?? 1 }
        public var toPlace: Int { Swift.min(LinePlot3.byHand, data.count) }
        public var sayStack: String { "How many \(th.many) are \(LinePlot3.said(v)) \(LinePlot3.inchWord(v))? Tap the stack." }
        public var sayWrite: String { "Write how many \(th.many)." }
        public static let sayMode = "Which length came up most? Tap its stack."
        public var plotWhy: String { ask == 0 ? "Each X is one \(th.one)." : "Each X is one \(th.one): the tallest stack came up most." }
        public func placeMiss(_ k: Int) -> String {
            let i = Swift.max(0, Swift.min(data.count - 1, k / 100)), u = k % 100
            return "That's \(LinePlot3.said(u)). Its end is at \(LinePlot3.said(data[i]))."
        }
        public func stackMiss(_ u: Int) -> String {
            let here = LinePlot3.howMany(data, u)
            return here > 0 ? "That's the stack at \(LinePlot3.said(u)). Find \(LinePlot3.said(v)) on the line." : "There's no X at \(LinePlot3.said(u)). Find \(LinePlot3.said(v)) on the line."
        }
        public func modeMiss(_ u: Int) -> String { "That stack has \(Data3.plural(LinePlot3.howMany(data, u), "X", "X's")). Find the tallest stack." }
        public var stackSlips: [(Double, String)] {
            var out: [(Double, String)] = []
            for dv in [-1, 1] {
                out.append((Double(LinePlot3.howMany(data, v + dv)), "That's the stack at \(LinePlot3.said(v + dv)). Each space is one fourth: count the marks from \(v / 4)."))
            }
            out.append((Double(data.count), "That's all the X's on the plot. Count only the stack above \(LinePlot3.said(v))."))
            out.append((Double(n + 1), "One too many. Touch each X above \(LinePlot3.said(v)) once."))
            out.append((Double(n - 1), "One short. Count every X above \(LinePlot3.said(v)), up to the top one."))
            return out
        }
        public var stackHint: String { "Find \(LinePlot3.said(v)) on the line, then count the X's above it." }
    }

    /// The web's: problems 0–1 halves on a ruler; an even index from 2 a ruler (fourths 2 times in 3); an odd index from
    /// 3 a plot of 8–12 lengths over 2 inches with one tallest stack, the question by (i >> 1) % 2.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 2 { return measure(whole: Data3.r(1, 5, &rng), quarters: 2, to: 2) }
        if i % 2 == 0 {
            if Data3.r(0, 2, &rng) != 0 { return measure(whole: Data3.r(1, 5, &rng), quarters: Data3.pick([1, 3], &rng), to: 4) }
            return measure(whole: Data3.r(1, 5, &rng), quarters: 2, to: 2)
        }
        while true {
            let lo = Data3.pick([4, 8], &rng), n = Data3.r(8, 12, &rng)
            var data: [Int] = []
            for _ in 0..<n { data.append(lo + Swift.min(8, (Data3.r(0, 8, &rng) + Data3.r(0, 8, &rng)) / 2)) }
            if modes(data).count != 1 { continue }
            let ask = (i >> 1) % 2, vs = Array(Set(data)).sorted()
            return plot(thing: Data3.r(0, 3, &rng), lo: lo, data: data, ask: ask, v: Data3.pick(vs, &rng))
        }
    }

    public static let spec = LessonSpec(id: "g3-lineplot", title: "Line plots with halves and fourths", master: "number-line",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.text(P.measure ? "How long is the crayon?" : P.ask == 0 ? P.sayStack : Parts.sayMode)] },
        idea: { _ in "A ruler marks halves and fourths of an inch, so a length can land between whole inches." },
        depends: ["g3-fracline", "g2-lineplot"],
        check: [CheckItem(0), CheckItem(2, when: { Parts($0).to == 4 }), CheckItem(3), CheckItem(5)]) { x in
        let P = Parts(x)
        if P.measure {
            let iHint = "Long marks are whole inches. Find the last one it passes."
            let inch = LessonStep(StepWords(say: "Tap the last whole inch it passes.", hint: iHint, action: "Check"),
                answer: Data3.hand("i", P.whole, hint: iHint, explain: "It passes \(P.whole), but not \(P.whole + 1).", said: { P.inchMiss($0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let hHint = "\(P.to == 4 ? "Middle marks are halves, short ones fourths." : "The middle mark is the half.") Count the spaces past \(P.whole)."
            let hops = LessonStep(StepWords(say: "Hop the \(P.pieceName) to its end.", hint: hHint, action: "Check"),
                answer: Data3.hand("h", P.extra, hint: hHint, explain: "\(P.extra) \(P.extra == 1 ? P.pieceOne : P.pieceName) past \(P.whole).", said: { P.hopMiss($0) }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            let wHint = "Whole inches go in front. Bottom: pieces in one inch. Top: pieces past the whole inches."
            let whole = P.whole, extra = P.extra, to = P.to, pieces = P.pieceName
            let task = AnswerTask(prompt: [.box("w"), .frac(.box("n"), .box("d")), .text("inches")],
                                  expected: ["w": Double(whole), "n": Double(extra), "d": Double(to)],
                                  known: [(["w": Double(whole), "n": Double(extra), "d": Double(to == 2 ? 4 : 2)], "The pieces are \(pieces), so the bottom number is \(to).")],
                                  hint: wHint, explain: P.measureWhy,
                                  check: { v in
                                      guard let a = v["w"], let b = v["n"], let c = v["d"] else { return .soft("Write the whole inches, the top and the bottom.") }
                                      let w = Int(a.rounded()), n = Int(b.rounded()), d = Int(c.rounded())
                                      if w == whole && n == extra && d == to { return .right }
                                      if w == whole && n == extra && d == (to == 2 ? 4 : 2) { return .wrong("The pieces are \(pieces), so the bottom number is \(to).") }
                                      return .wrong("Not quite. \(wHint)")
                                  }, incomplete: "Write the whole inches, the top and the bottom.")
            let write = LessonStep(StepWords(say: "Write how long it is.", hint: wHint, action: "Check"), answer: task,
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [inch, hops, write, LessonStep(StepWords(say: P.measureWhy, hint: "", action: "Next problem"), picture: ["at": 9])]
        }
        let pHint = "Find the mark under its end, then tap above it."
        let place = LessonStep(StepWords(say: "Tap where its X goes.", hint: pHint, action: "Check"),
            answer: Data3.hand("p", allPlaced, hint: pHint, explain: "Each X goes above its length.", said: { P.placeMiss($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        var out = [place]
        if P.ask == 0 {
            let tHint = "Find \(said(P.v)) on the line, then tap the X's above it."
            out.append(LessonStep(StepWords(say: P.sayStack, hint: tHint, action: "Check"),
                answer: Data3.hand("t", P.v, hint: tHint, explain: "The stack above \(said(P.v)).", said: { P.stackMiss($0) }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
            out.append(LessonStep(StepWords(say: P.sayWrite, hint: P.stackHint, action: "Check"),
                answer: Data3.typed("c", P.n, P.stackSlips, hint: P.stackHint, explain: "\(P.n == 1 ? "1 X" : "\(P.n) X's") above \(said(P.v))."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        } else {
            let mHint = "Look for the stack with the most X's."
            out.append(LessonStep(StepWords(say: Parts.sayMode, hint: mHint, action: "Check"),
                answer: Data3.hand("m", P.mode, hint: mHint, explain: "The tallest stack is at \(said(P.mode)) inches.", said: { P.modeMiss($0) }),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        out.append(LessonStep(StepWords(say: P.plotWhy, hint: "", action: "Next problem"), picture: ["at": 9]))
        return out
    }
}
