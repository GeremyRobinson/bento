import Foundation

/// What 6th grade's Ratios and percents chapter shares (design/grade6.md chapter 1, the preview
/// design/prototype/grade6-ch1.html): rows carry the multiplying (one row is one copy of a ratio, or one item and its
/// price), and the percents use the fractions family's bar, 100% in 40 squares (so 10% is 4 squares and 25% is 10).
public enum Ratio6 {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? abs(a) : gcd(b, a % b) }
    static func lcm(_ a: Int, _ b: Int) -> Int { a / gcd(a, b) * b }
    /// A number as school writes it: 1 1/2, 2/3, 4.
    public static func mixed(_ num: Int, _ den: Int) -> String {
        let g = max(1, gcd(num, den)), n = num / g, d = den / g, w = n / d, r = n - w * d
        return r == 0 ? "\(w)" : w > 0 ? "\(w) \(r)/\(d)" : "\(r)/\(d)"
    }
    /// A number of halves as school writes it (4.5 → "4 1/2").
    public static func half(_ x: Double) -> String { mixed(Int((x * 2).rounded()), 2) }
    /// A point's pair: (4 1/2, 3).
    public static func pair(_ u: Double, _ v: Double) -> String { "(\(half(u)), \(half(v)))" }
}

// MARK: - Equivalent ratios

/// Equivalent ratios (the web app's g6-ratio, 6.RP.1, 6.RP.3a): a : b = ? : b·k. One thing is a 3 × 3 cell: two
/// rectangles a cells and b cells wide grow together a row at a time, each row one more a : b. Drag the bottom edge down
/// until the right side is b·k (the rows count the times), then write a × k.
///
/// Every step's picture has "at": 0 the question, 1 drag the rows, 2 write the left side, 3 done.
public enum EquivRatio {
    public static func numbers(a: Int, b: Int, k: Int) -> Numbers { ["a": Double(a), "b": Double(b), "k": Double(k)] }

    public struct Parts: Sendable {
        public let a: Int, b: Int, k: Int
        public init(_ n: Numbers) {
            a = Int((n["a"] ?? 2).rounded()); b = Int((n["b"] ?? 3).rounded()); k = Int((n["k"] ?? 2).rounded())
        }
        /// The right side's total, and the left side's.
        public var total: Int { b * k }
        public var left: Int { a * k }
        /// The most rows the edge can be dragged to.
        public var maxRows: Int { k + 2 }
        /// What the edge let go at `r` rows says (nil: right).
        public func moved(_ r: Int) -> String? {
            if r == k { return nil }
            if r < k { return "\(r * b) so far. \(k - r == 1 ? "Another row." : "More rows.")" }
            return "That’s \(r * b), past \(total)."
        }
        public var drag: String { "Drag down until the right side is \(total)." }
        public var why: String { "\(k) rows of \(a) : \(b) make \(left) : \(total). Both sides grew \(k) times." }
    }

    /// The web's generator: a 1–9 and b 2–9, different, no shared factor, k 2–9; the first three a and b 5 or less, k 2–3.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let top = index < 3 ? 5 : 9
        var a = 1, b = 2
        repeat { a = Int.random(in: 1...top, using: &rng); b = Int.random(in: 2...top, using: &rng) } while Ratio6.gcd(a, b) != 1 || a == b
        return numbers(a: a, b: b, k: index < 3 ? Int.random(in: 2...3, using: &rng) : Int.random(in: 2...9, using: &rng))
    }

    public static let spec = LessonSpec(id: "g6-ratio", title: "Equivalent ratios", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.num(Double(s.a)), .text(":"), .num(Double(s.b)), .op("="), .text("?"), .text(":"), .num(Double(s.total))] },
        idea: { _ in "A ratio compares two amounts, so both parts have to grow by the same factor." },
        depends: ["g4-equiv", "g3-divfacts"],
        check: [CheckItem(3), CheckItem(3, when: { Parts($0).k >= 5 }), CheckItem(3, when: { Parts($0).a > Parts($0).b }), CheckItem(3)]) { n in
        let s = Parts(n)
        let ask = LessonStep(StepWords(say: s.drag, hint: "Each row is one more \(s.a) : \(s.b).", action: "Let’s find out"), picture: ["at": 0])
        let hint = "Each row is one more \(s.a) : \(s.b)."
        let drag = LessonStep(StepWords(say: s.drag, hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.k)], hint: hint, explain: "\(s.k) rows of \(s.b) make \(s.total).",
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.drag) }
                                   return s.moved(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        // write the left side, with the web's adding slip measured on the paper
        let rows = "\(s.k) rows of \(s.a) on the left."
        let write = LessonStep(StepWords(say: "Write the left side.", hint: rows, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s.a)), .text(":"), .num(Double(s.b)), .op("="), .num(Double(s.a)), .op("×"), .num(Double(s.k)), .text(":"),
                                        .num(Double(s.b)), .op("×"), .num(Double(s.k)), .op("="), .box("x"), .text(":"), .num(Double(s.total))],
                               expected: ["x": Double(s.left)],
                               known: BigNumbers.slips(Double(s.left), [(Double(s.a + s.total - s.b), "Multiply both numbers by the same number. \(rows)")]),
                               hint: rows, explain: s.why,
                               check: { v in Int((v["x"] ?? -1).rounded()) == s.left ? .right : .wrong(rows) },
                               incomplete: "Write the number in the box."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Both parts grow by the same factor.", action: "Next problem"), picture: ["at": 3])
        return [ask, drag, write, done]
    }
}

// MARK: - Ratio tables

/// Ratio tables (new, 6.RP.3a, 6.RP.2): "2 laps take 3 minutes" as a table and as points on the first-quadrant plane,
/// two squares a unit, across 0–24 for the minutes and up 0–12 for the other amount. Put a point for each of the first
/// two columns; the ruler line through 0 lays itself; slide along it to fill the gaps (one up, then from the 4th problem
/// one across too); write the column past the paper; slide to 1 lap (a grid point when a is 1 or 2) and write the unit
/// rate. From the 7th problem two tables compare: a point for each table's first column, drag up the line at X minutes,
/// then pick whose is more.
///
/// "at": 0 the question, 1 the points, 2 the gap up, 3 the gap across, 4 the column past the paper, 5 slide to 1,
/// 6 write 1, 7 done; the compare kind: 1 the points, 8 drag up, 9 pick, 10 done.
public enum RatioTable {
    public struct Story: Sendable { public let up: String, one: String, does: String }
    public static let stories = [Story(up: "laps", one: "lap", does: "runs"), Story(up: "pages", one: "page", does: "reads"), Story(up: "lengths", one: "length", does: "swims")]
    public static let names = ["Ana", "Ben", "Kai", "Mia", "Sam", "Zoe", "Leo", "Ivy"]
    /// Every a : b with a 1–3, b 2–6, a < b, no shared factor (so at least four columns fit the paper).
    public static let pairs: [(Int, Int)] = (1...3).flatMap { a in (2...6).compactMap { b in a < b && Ratio6.gcd(a, b) == 1 ? (a, b) : nil } }
    /// The plane: across 0–24, up 0–12.
    public static let across = 24, up = 12

    public static func numbers(a: Int, b: Int, tL: Int, tM: Int = 0, tP: Int, story: Int = 0) -> Numbers {
        ["kind": tM > 0 ? 1 : 0, "a": Double(a), "b": Double(b), "tL": Double(tL), "tM": Double(tM), "tP": Double(tP), "story": Double(story)]
    }
    public static func compare(X: Int, a1: Int, b1: Int, a2: Int, b2: Int, n1: Int = 0, n2: Int = 1, story: Int = 0) -> Numbers {
        ["kind": 2, "X": Double(X), "a1": Double(a1), "b1": Double(b1), "a2": Double(a2), "b2": Double(b2), "n1": Double(n1), "n2": Double(n2), "story": Double(story)]
    }

    /// One table of a compare: its name and its a : b.
    public struct Table: Sendable, Equatable { public let name: String, a: Int, b: Int }

    public struct Parts: Sendable {
        /// 0 one gap, 1 a gap each way, 2 compare two tables.
        public let kind: Int, a: Int, b: Int, tL: Int, tM: Int, tP: Int
        public let S: Story
        public let X: Int, A: Table, B: Table
        public init(_ n: Numbers) {
            func i(_ k: String, _ d: Int = 0) -> Int { Int((n[k] ?? Double(d)).rounded()) }
            kind = i("kind"); a = i("a", 2); b = i("b", 3); tL = i("tL", 3); tM = i("tM"); tP = i("tP", 7)
            S = RatioTable.stories[min(2, max(0, i("story")))]
            X = i("X", 6)
            let nm = RatioTable.names
            A = Table(name: nm[min(nm.count - 1, max(0, i("n1")))], a: i("a1", 1), b: i("b1", 2))
            B = Table(name: nm[min(nm.count - 1, max(0, i("n2", 1)))], a: i("a2", 1), b: i("b2", 3))
        }
        public var compares: Bool { kind == 2 }
        /// The columns, left to right: 1, 2, the gaps, the one past the paper.
        public var cols: [Int] { ([1, 2, tL] + (tM > 0 ? [tM] : []) + [tP]).sorted() }
        /// The furthest along the line a point can slide (in half units, j: the point is (j·b/2, j·a/2)).
        public var jmax: Int { min(2 * RatioTable.across / b, 2 * RatioTable.up / a) }
        /// The unit rate's point is a grid point (a is 1 or 2), so it's slid to.
        public var slidesToOne: Bool { a <= 2 }
        public func nm(_ n: Double) -> String { n == 1 ? S.one : S.up }
        public func take(_ n: Double) -> String { n == 1 ? "takes" : "take" }
        /// The compare: how many each does in X minutes, who does more.
        public func at(_ t: Table) -> Int { t.a * X / t.b }
        public var winner: Table { at(A) > at(B) ? A : B }
        public var loser: Table { winner == A ? B : A }
        public var top: Int { max(at(A), at(B)) }

        /// A point let go at (u, v) units with `mask` the columns placed before it (bit 0 the first, bit 1 the second; in
        /// a compare, bit 0 the first table, bit 1 the second): what it says (nil: both are placed, right).
        public func placed(_ u: Double, _ v: Double, mask: Int) -> Verdict {
            if compares {
                let tables = [A, B]
                if let who = tables.firstIndex(where: { p in [1, 2].contains { t in u == Double(p.b * t) && v == Double(p.a * t) } }) {
                    return mask | (1 << who) == 3 ? .right : .soft("Put a point for the other table.")
                }
                if tables.contains(where: { p in [1, 2].contains { t in u == Double(p.a * t) && v == Double(p.b * t) } }) {
                    return .wrong("That’s \(Ratio6.pair(u, v)). Minutes go across.")
                }
                let p = mask & 1 != 0 ? B : A
                return .wrong("\(p.name): \(p.a) \(nm(Double(p.a))) \(take(Double(p.a))) \(p.b) minutes.")
            }
            if let t = [1, 2].first(where: { u == Double(b * $0) && v == Double(a * $0) }) {
                return mask | (1 << (t - 1)) == 3 ? .right : .soft("Put a point for the other column.")
            }
            if [1, 2].contains(where: { u == Double(a * $0) && v == Double(b * $0) }) { return .wrong("That’s \(Ratio6.pair(u, v)). Minutes go across.") }
            let t = mask & 1 == 0 ? 1 : 2
            return .wrong("\(a * t) \(nm(Double(a * t))) \(take(Double(a * t))) \(b * t) minutes.")
        }
        /// The point slid along the line to j (half units): what the gap up, the gap across or the slide to 1 says.
        public func slid(_ j: Int, stage: Int) -> String? {
            let up = Double(j * a) / 2, ac = Double(j * b) / 2
            switch stage {
            case 2: return up == Double(a * tL) ? nil : "That’s \(Ratio6.half(up)) \(nm(up)). This column has \(a * tL)."
            case 3: return ac == Double(b * tM) ? nil : "That’s \(Ratio6.half(ac)) minutes. This column has \(b * tM)."
            default: return up == 1 ? nil : "That’s \(Ratio6.half(up)) \(nm(up)). Slide to 1 \(S.one)."
            }
        }
        /// Where each slide starts (half units): the second column's point, then where the last slide was let go.
        public func start(_ stage: Int) -> Int {
            switch stage {
            case 2: return 4
            case 3: return 2 * tL
            default: return 2 * (tM > 0 ? tM : tL)
            }
        }
        /// The written lines' words.
        public var past: String { "\(a * tP) \(nm(Double(a * tP))) take" }
        public var oneTakes: String { "1 \(S.one) takes" }
        public var unitRate: String { Ratio6.mixed(b, a) }
        public var why: String { "Equal ratios sit on one straight line through 0." }
        public var pickSay: String { "Who \(S.does) more \(S.up) in \(X) minutes? Tap a name." }
        public var compared: String { "\(winner.name) \(S.does) more: \(at(winner)) \(nm(Double(at(winner)))) to \(at(loser)). \(why)" }
    }

    /// The preview's generator: from the 7th problem two tables (their lines meet a whole number at X minutes, X a
    /// multiple of both minutes, every point on the plane); from the 4th a gap each way; else one gap up. The column past
    /// the paper is 1–4 past the last that fits.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let story = Int.random(in: 0..<stories.count, using: &rng)
        if index >= 6 {
            while true {
                let (a1, b1) = Ratio6.pick(pairs, &rng), (a2, b2) = Ratio6.pick(pairs, &rng)
                if a1 == a2 && b1 == b2 { continue }
                let l = Ratio6.lcm(b1, b2)
                let Xs = stride(from: l, through: across, by: l).filter { a1 * $0 / b1 <= up && a2 * $0 / b2 <= up }
                if Xs.isEmpty { continue }
                let n1 = Int.random(in: 0..<names.count, using: &rng)
                var n2 = n1
                while n2 == n1 { n2 = Int.random(in: 0..<names.count, using: &rng) }
                return compare(X: Ratio6.pick(Xs, &rng), a1: a1, b1: b1, a2: a2, b2: b2, n1: n1, n2: n2, story: story)
            }
        }
        let (a, b) = Ratio6.pick(pairs, &rng), tmax = min(across / b, up / a)
        let inner = Array(3...tmax), tL = Ratio6.pick(inner, &rng)
        var tM = 0
        if index >= 3 { repeat { tM = Ratio6.pick(inner, &rng) } while tM == tL }
        return numbers(a: a, b: b, tL: tL, tM: tM, tP: Int.random(in: (tmax + 1)...(tmax + 4), using: &rng), story: story)
    }

    public static let spec = LessonSpec(id: "g6-ratiotable", title: "Ratio tables", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return s.compares ? [] : [.num(Double(s.a)), .text(":"), .num(Double(s.b))] },
        idea: { _ in "Equal ratios sit on one straight line through 0." },
        depends: ["g6-ratio", "g5-coord"],
        check: [CheckItem(0), CheckItem(3), CheckItem(3, when: { Parts($0).a == 3 }), CheckItem(6)]) { n in
        let s = Parts(n), a = s.a, b = s.b
        func by(_ say: String, _ hint: String, _ boxes: [String], at: Int, _ check: @escaping @Sendable ([String: Double]) -> Verdict) -> LessonStep {
            LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                       answer: AnswerTask(prompt: boxes.map { .box($0) }, expected: Dictionary(uniqueKeysWithValues: boxes.map { ($0, 0) }), hint: hint, explain: hint,
                                          check: check, byHand: true),
                       picture: ["at": Double(at)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        // a point: x is its place in squares (across × 100 + up), m the columns placed before it
        let points = { (say: String, hint: String) in
            by(say, hint, ["x", "m"], at: 1) { v in
                let x = Ratio6.int(v, "x"), m = Ratio6.int(v, "m", 0)
                return s.placed(Double(x / 100) / 2, Double(x % 100) / 2, mask: m)
            }
        }
        if s.compares {
            let A = s.A, B = s.B
            let say = "Put a point for each table’s first column."
            let ask = LessonStep(StepWords(say: say, hint: "Minutes go across.", action: "Let’s find out"), picture: ["at": 0])
            let pts = points(say, "\(A.name): \(A.a) \(s.nm(Double(A.a))) \(s.take(Double(A.a))) \(A.b) minutes.")
            let upSay = "Drag up the line at \(s.X) minutes."
            let up = by(upSay, "Keep going up to both lines.", ["x"], at: 8) { v in
                Double(Ratio6.int(v, "x")) / 2 >= Double(s.top) ? .right : .wrong("Keep going up to both lines.")
            }
            let win = s.winner == A ? 0 : 1
            let pick = LessonStep(StepWords(say: s.pickSay, hint: "Look where each line crosses \(s.X) minutes.", action: "Check"),
                answer: AnswerTask(prompt: [], expected: ["c": Double(win)], hint: "Look where each line crosses \(s.X) minutes.", explain: s.compared,
                                   check: { v in
                                       let c = Ratio6.int(v, "c")
                                       if c == win { return .right }
                                       let p = c == 0 ? A : B, o = c == 0 ? B : A
                                       return .wrong("\(p.name) \(s.S.does) \(s.at(p)) \(s.nm(Double(s.at(p)))). \(o.name) \(s.S.does) \(s.at(o)).")
                                   }, choices: [A.name, B.name]),
                picture: ["at": 9], onMiss: ["ring": 1], hint2: ["spot": 1])
            let done = LessonStep(StepWords(say: s.compared, hint: s.why, action: "Next problem"), picture: ["at": 10])
            return [ask, pts, up, pick, done]
        }
        let say = "Put a point for each of the first two columns."
        let ask = LessonStep(StepWords(say: say, hint: "Minutes go across.", action: "Let’s find out"), picture: ["at": 0])
        var steps = [ask, points(say, "\(a) \(s.nm(Double(a))) \(s.take(Double(a))) \(b) minutes.")]
        let upL = a * s.tL
        steps.append(by("Slide along the line to \(upL) \(s.nm(Double(upL))).", "This column has \(upL) \(s.nm(Double(upL))).", ["x"], at: 2) { v in
            s.slid(Ratio6.int(v, "x"), stage: 2).map { .wrong($0) } ?? .right
        })
        if s.tM > 0 {
            steps.append(by("Slide along the line to \(b * s.tM) minutes.", "This column has \(b * s.tM) minutes.", ["x"], at: 3) { v in
                s.slid(Ratio6.int(v, "x"), stage: 3).map { .wrong($0) } ?? .right
            })
        }
        // the column past the paper, with the preview's slips: the adding pattern, another column's minutes
        let L0 = a * s.tP, want = b * s.tP, times = "\(L0) \(s.nm(Double(L0))) is \(s.tP) × \(a) \(s.nm(Double(a)))."
        let known = s.cols.filter { $0 != s.tP }
        steps.append(LessonStep(StepWords(say: "Write the column past the paper.", hint: times, action: "Check"),
            answer: AnswerTask(prompt: [.text(s.past), .box("x"), .text("minutes")], expected: ["x": Double(want)], hint: times, explain: s.why,
                               check: { v in
                                   let x = Ratio6.int(v, "x")
                                   if x == want { return .right }
                                   if let t = known.first(where: { x == b * $0 + (L0 - a * $0) }) {
                                       return .wrong("Adding \(L0 - a * t) to both isn’t the same ratio. \(times)")
                                   }
                                   if let t = known.first(where: { x == b * $0 }) { return .wrong("That’s the minutes for \(a * t) \(s.nm(Double(a * t))).") }
                                   return .wrong(times)
                               }, incomplete: "Write the number in the box."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        if s.slidesToOne {
            steps.append(by("Slide to 1 \(s.S.one).", "1 \(s.S.one) is one step up.", ["x"], at: 5) { v in
                s.slid(Ratio6.int(v, "x"), stage: 5).map { .wrong($0) } ?? .right
            })
        }
        // 1 lap takes b ÷ a minutes: a whole number when a is 1, else a mixed number (any way it's written)
        let unitSay = "Write how long 1 \(s.S.one) takes."
        let unitMiss = a == 1 ? "Look at the first column." : "\(a) \(s.S.up) take \(b) minutes, so 1 \(s.S.one) takes \(b) ÷ \(a) minutes."
        let boxes: MathLine = a == 1 ? [.box("w")] : [.box("w"), .box("n"), .text("/"), .box("d")]
        let w = b / a, r = b % a
        steps.append(LessonStep(StepWords(say: unitSay, hint: unitMiss, action: "Check"),
            answer: AnswerTask(prompt: [.text(s.oneTakes)] + boxes + [.text("minutes")], expected: a == 1 ? ["w": Double(b)] : ["w": Double(w), "n": Double(r), "d": Double(a)],
                               hint: unitMiss, explain: s.why,
                               check: { v in
                                   let w = Ratio6.int(v, "w"), nn = a == 1 ? 0 : Ratio6.int(v, "n"), d = a == 1 ? 1 : Ratio6.int(v, "d")
                                   return d > 0 && (w * d + nn) * a == b * d ? .right : .wrong(unitMiss)
                               }, incomplete: a == 1 ? "Write the number in the box." : "Fill in every box."),
            picture: ["at": 6], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: s.why, hint: "Equal ratios grow together.", action: "Next problem"), picture: ["at": 7]))
        return steps
    }
}

// MARK: - Unit rates

/// Unit rates (the web app's g6-rate, 6.RP.2, 6.RP.3b, 6.RP.3d): n items cost $u·n; how much do m cost? $1 is a cell
/// (2 × 2 squares, or 1 square for the biggest problems), one row is one item. Share the total over n rows by dragging
/// the right edge (each column puts $1 in every row), copy the row down to m items, then write m × the cost of one. The
/// same numbers are told as speed (a mile a cell, an hour a row) and as units (3 feet are 36 inches).
///
/// "at": 0 the question, 1 share, 2 make m, 3 write, 4 done.
public enum UnitRate {
    public static let items = ["notebooks", "apples", "pencils", "stickers", "tickets"]
    /// u: one, many, the smaller unit (many, one), its short name, the big unit's short name.
    public static let units: [Int: [String]] = [12: ["foot", "feet", "inches", "inch", "in", "ft"], 3: ["yard", "yards", "feet", "foot", "ft", "yd"],
        4: ["gallon", "gallons", "quarts", "quart", "qt", "gal"], 7: ["week", "weeks", "days", "day", "days", "wk"],
        10: ["centimeter", "centimeters", "millimeters", "millimeter", "mm", "cm"]]
    public enum Kind: Int, Sendable { case cost, speed, units }

    public static func numbers(u: Int, n: Int, m: Int, item: Int = 1, kind: Kind = .cost) -> Numbers {
        ["u": Double(u), "n": Double(n), "m": Double(m), "item": Double(item), "kind": Double(kind.rawValue)]
    }

    public struct Parts: Sendable {
        public let u: Int, n: Int, m: Int, item: String, kind: Kind
        public init(_ nn: Numbers) {
            u = Int((nn["u"] ?? 3).rounded()); n = Int((nn["n"] ?? 4).rounded()); m = Int((nn["m"] ?? 7).rounded())
            item = UnitRate.items[min(4, max(0, Int((nn["item"] ?? 1).rounded())))]
            kind = Kind(rawValue: Int((nn["kind"] ?? 0).rounded())) ?? .cost
        }
        public var total: Int { u * n }
        var one: String { String(item.dropLast()) }
        var unit: [String] { UnitRate.units[u] ?? ["foot", "feet", "inches", "inch", "in", "ft"] }
        func mi(_ x: Int) -> String { "\(x) mile\(x == 1 ? "" : "s")" }
        func sub(_ x: Int) -> String { "\(x) \(x == 1 ? unit[3] : unit[2])" }
        /// A row count: "4 apples", "1 hour", "3 feet".
        public func rows(_ r: Int) -> String {
            switch kind {
            case .cost: "\(r) \(r == 1 ? one : item)"
            case .speed: "\(r) hour\(r == 1 ? "" : "s")"
            case .units: "\(r) \(r == 1 ? unit[0] : unit[1])"
            }
        }
        /// What one row holds, beside it: "$3", "12 mi", "12 in".
        public var perRow: String { kind == .cost ? "$\(u)" : kind == .speed ? "\(u) mi" : "\(u) \(unit[4])" }
        /// The total, as the left rectangle's name.
        public var totalName: String { kind == .cost ? "$\(total)" : kind == .speed ? mi(total) : sub(total) }
        /// The readout while sharing: what's used and what's left.
        public func used(_ x: Int, _ y: Int) -> String {
            let used = kind == .cost ? "$\(x) used" : kind == .speed ? "\(mi(x)) used" : "\(sub(x)) used"
            return y < 0 ? used : used + (kind == .cost ? ", $\(y) left" : ", \(y) left")
        }
        public func still(_ y: Int) -> String {
            kind == .cost ? "$\(y) is still left." : kind == .speed ? "\(mi(y)) \(y == 1 ? "is" : "are") still left." : "\(sub(y)) \(y == 1 ? "is" : "are") still left."
        }
        public func past(_ x: Int) -> String {
            kind == .cost ? "That’s $\(x). There’s only $\(total)." : kind == .speed ? "That’s \(mi(x)). There are only \(total)." : "That’s \(sub(x)). There are only \(total)."
        }
        public var share: String {
            kind == .cost ? "Share $\(total) over the \(n) \(item)." : kind == .speed ? "Share \(total) miles over the \(n) hours." : "Share \(total) \(unit[2]) over the \(n) \(unit[1])."
        }
        public var make: String { kind == .cost ? "Make \(m) \(item)." : kind == .speed ? "Make \(m) hours." : "Make \(m) \(unit[1])." }
        public var why: String {
            switch kind {
            case .cost: "Every \(one) costs $\(u), so \(m) cost \(m) × $\(u)."
            case .speed: "Every hour goes \(mi(u)), so \(m) hours go \(m) × \(u)."
            case .units: "Every \(unit[0]) is \(sub(u)), so \(m) \(unit[1]) are \(m) × \(u)."
            }
        }
        public var all: String {
            kind == .cost ? "Use the cost of one, $\(u), not $\(total)." : kind == .speed ? "Use one hour’s \(u) miles, not \(total)." : "Use one \(unit[0])’s \(u) \(unit[2]), not \(total)."
        }
        public var added: String {
            kind == .cost ? "\(m) of them, $\(u) each: that’s \(m) groups of $\(u)." : kind == .speed ? "\(m) hours, \(u) miles each: that’s \(m) groups of \(u)."
                : "\(m) \(unit[1]), \(u) \(unit[2]) each: that’s \(m) groups of \(u)."
        }
        /// The records' units: the small unit's short name and the big one's ("mi", "h"; "in", "ft").
        public var smallUnit: String { kind == .speed ? "mi" : unit[4] }
        public var bigUnit: String { kind == .speed ? "h" : unit[5] }
        /// What the edge let go at w columns says (nil: right).
        public func shared(_ w: Int) -> String? { w == u ? nil : w < u ? still((u - w) * n) : past(w * n) }
        public func made(_ r: Int) -> String? { r == m ? nil : "That’s \(rows(r)). Make \(m)." }
    }

    /// The web's generator ($2–15 each, 2–9 bought, 2–12 asked about; the first three $2–5, 2–4 and 2–6), told as cost,
    /// speed or units (picked after the numbers; a units story redraws u from its list).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        var u = index < 3 ? Int.random(in: 2...5, using: &rng) : Int.random(in: 2...15, using: &rng)
        let n = index < 3 ? Int.random(in: 2...4, using: &rng) : Int.random(in: 2...9, using: &rng)
        let m = index < 3 ? Int.random(in: 2...6, using: &rng) : Int.random(in: 2...12, using: &rng)
        let item = Int.random(in: 0..<items.count, using: &rng)
        let kind = Kind(rawValue: Int.random(in: 0...2, using: &rng)) ?? .cost
        if kind == .units { u = Ratio6.pick(index < 3 ? [3, 4] : [12, 3, 4, 7, 10], &rng) }
        return numbers(u: u, n: n, m: m, item: item, kind: kind)
    }

    public static let spec = LessonSpec(id: "g6-rate", title: "Unit rates", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.num(Double(s.n)), .text(s.item), .text("cost"), .text("$"), .num(Double(s.total))] },
        idea: { _ in "Every one costs the same, so the cost of one gets you to any number of them." },
        depends: ["g4-divide", "g4-partial"],
        check: [CheckItem(3), CheckItem(3, when: { Parts($0).n >= 5 }), CheckItem(3, when: { Parts($0).m < Parts($0).n }), CheckItem(3, when: { Parts($0).u >= 10 })]) { nn in
        let s = Parts(nn)
        let ask = LessonStep(StepWords(say: s.share, hint: "Each column puts 1 in every row.", action: "Let’s find out"), picture: ["at": 0])
        let share = LessonStep(StepWords(say: s.share, hint: "Each column puts 1 in every row.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.u)], hint: "Each column puts 1 in every row.", explain: s.why,
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.share) }
                                   return s.shared(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let make = LessonStep(StepWords(say: s.make, hint: "Each row is one more \(s.perRow).", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.m)], hint: "Each row is one more \(s.perRow).", explain: s.why,
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.make) }
                                   return s.made(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let count = "Count the squares: \(s.m) rows of \(s.u)."
        let write = LessonStep(StepWords(say: "Write how much in all.", hint: count, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s.m)), .op("×"), .num(Double(s.u)), .op("="), .box("x")], expected: ["x": Double(s.u * s.m)],
                               known: BigNumbers.slips(Double(s.u * s.m), [(Double(s.total * s.m), s.all), (Double(s.m + s.u), s.added)]),
                               hint: count, explain: s.why,
                               check: { v in Int((v["x"] ?? -1).rounded()) == s.u * s.m ? .right : .wrong(count) },
                               incomplete: "Write the number in the box."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Find one first.", action: "Next problem"), picture: ["at": 4])
        return [ask, share, make, write, done]
    }
}

// MARK: - Percent of a number

/// Percent of a number (the web app's g6-pctof, 6.RP.3c): p% of W, found from 10% (or 25% for 25 and 75). One square is
/// 2.5%: the bar is 40 squares, so 10% is 4 squares and 25% is 10. Cut with the ruler (tenths or quarters), write one
/// block, shade p%, write p% as that many blocks.
///
/// "at": 0 the question, 1 cut, 2 write one block, 3 shade, 4 write p%, 5 done.
public enum PercentOf {
    public static let percents = [10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90]
    public static func numbers(p: Int, W: Int) -> Numbers { ["p": Double(p), "W": Double(W)] }
    /// The bar's squares, and a block's for tenths and quarters.
    public static let bar = 40

    public struct Parts: Sendable {
        public let p: Int, W: Int
        public init(_ n: Numbers) { p = Int((n["p"] ?? 30).rounded()); W = Int((n["W"] ?? 80).rounded()) }
        /// The block it's found from (10% or 25%), its value, how many blocks make p%, and p% of W.
        public var base: Int { p % 10 == 0 ? 10 : 25 }
        public var part: Int { W * base / 100 }
        public var blocks: Int { p / base }
        public var R: Int { W * p / 100 }
        /// The block's squares on the bar: 4 for tenths, 10 for quarters.
        public var width: Int { base == 10 ? 4 : 10 }
        /// The ruler let go at `cw` squares and Cut.
        public func cut(_ cw: Int) -> Verdict {
            if cw >= PercentOf.bar { return .soft("Drag the ruler to cut \(W).") }
            if base == 10 && cw == 10 { return p == 50 ? .soft("Those fit. Cut tenths: 50% is 5 blocks of 10%.") : .wrong("\(p)% isn’t a whole number of quarters.") }
            if base == 25 && cw == 4 { return .wrong("\(p)% isn’t a whole number of tenths.") }
            return .right
        }
        /// `c` blocks shaded and checked.
        public func shaded(_ c: Int) -> Verdict {
            if c == blocks { return .right }
            if c == 0 { return .soft("Tap blocks to shade them.") }
            return c * base == 100 - p ? .wrong("That’s the part not taken.") : .wrong("That’s \(c * base)%.")
        }
        public var why: String { blocks == 1 ? "Each \(base)% is \(part)." : "Each \(base)% is \(part), so \(p)% is \(blocks) of them." }
    }

    /// The web's generator: one of its percents, of 20–400 in steps of 20 (no easy start, as the web).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        numbers(p: Ratio6.pick(percents, &rng), W: 20 * Int.random(in: 1...20, using: &rng))
    }

    public static let spec = LessonSpec(id: "g6-pctof", title: "Percent of a number", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.num(Double(s.p)), .text("%"), .text("of"), .num(Double(s.W))] },
        idea: { _ in "Percent means out of 100, so 10% is one tenth and 25% is one quarter." },
        depends: ["g5-fracof", "g4-divide"],
        check: [CheckItem(0, when: { Parts($0).p == 75 }), CheckItem(0, when: { [20, 30, 40].contains(Parts($0).p) }),
                CheckItem(0, when: { [60, 70, 80, 90].contains(Parts($0).p) }), CheckItem(0, when: { ![10, 25].contains(Parts($0).p) })]) { n in
        let s = Parts(n)
        let cutSay = "Cut \(s.W) into blocks that make \(s.p)%."
        let ask = LessonStep(StepWords(say: cutSay, hint: "Tenths are 10% each, quarters 25%.", action: "Let’s find out"), picture: ["at": 0])
        let cutHint = s.base == 10 ? "\(s.p)% is a whole number of tenths." : "\(s.p)% is a whole number of quarters."
        let cut = LessonStep(StepWords(say: cutSay, hint: cutHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.width)], hint: cutHint, explain: cutHint,
                               check: { v in s.cut(Ratio6.int(v, "x", PercentOf.bar)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let oneHint = s.base == 10 ? "10% is one tenth: \(s.W) ÷ 10." : "25% is one quarter: \(s.W) ÷ 4."
        let base = LessonStep(StepWords(say: "Write one block.", hint: oneHint, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s.base)), .text("%"), .text("of"), .num(Double(s.W)), .op("="), .box("x")], expected: ["x": Double(s.part)],
                               known: BigNumbers.slips(Double(s.part), [(Double(s.W * s.base), "\(s.base)% is a part of \(s.W), so it’s smaller than \(s.W).")]),
                               hint: oneHint, explain: oneHint,
                               check: { v in Ratio6.int(v, "x") == s.part ? .right : .wrong(oneHint) }, incomplete: "Write the number in the box."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let shadeHint = "\(s.p)% is \(s.blocks) block\(s.blocks == 1 ? "" : "s") of \(s.base)%."
        let shade = LessonStep(StepWords(say: "Shade \(s.p)%.", hint: shadeHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.blocks)], hint: shadeHint, explain: shadeHint,
                               check: { v in s.shaded(Ratio6.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let blocks = "\(s.p)% is \(s.blocks) blocks of \(s.base)%."
        let scale = LessonStep(StepWords(say: "Write \(s.p)%.", hint: blocks, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s.p)), .text("%"), .text("of"), .num(Double(s.W)), .op("="), .num(Double(s.blocks)), .op("×"), .num(Double(s.part)), .op("="), .box("x")],
                               expected: ["x": Double(s.R)],
                               known: BigNumbers.slips(Double(s.R), (s.p > s.base ? [(Double(s.part * s.p), "\(s.p)% is \(s.blocks) blocks of \(s.base)%. Multiply \(s.part) by \(s.blocks), not \(s.p).")] : [])
                                        + [(Double(s.W - s.R), "That’s the part not taken. \(s.p)% is the shaded part.")]),
                               hint: blocks, explain: s.why,
                               check: { v in Ratio6.int(v, "x") == s.R ? .right : .wrong(blocks) }, incomplete: "Write the number in the box."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Percent means out of 100.", action: "Next problem"), picture: ["at": 5])
        return [ask, cut, base, shade, scale, done]
    }
}

// MARK: - Find the whole

/// Find the whole (the web app's g6-pctwhole, 6.RP.3c): P is p% of ?, with p dividing 100. The same bar, 2.5% a square:
/// the 100% bar is dashed and named ?; the known piece sits at its left end holding P. Lay copies of it end to end to
/// 100% (tap to lay one, or drag along), then write P × how many.
///
/// "at": 0 the question, 1 lay the blocks, 2 write the whole, 3 done.
public enum PercentWhole {
    public static func numbers(p: Int, P: Int) -> Numbers { ["p": Double(p), "P": Double(P)] }

    public struct Parts: Sendable {
        public let p: Int, P: Int
        public init(_ n: Numbers) { p = Int((n["p"] ?? 25).rounded()); P = Int((n["P"] ?? 15).rounded()) }
        /// How many blocks make 100%, a block's squares on the 40-square bar, the whole.
        public var k: Int { 100 / p }
        public var width: Int { PercentOf.bar * p / 100 }
        public var whole: Int { P * k }
        /// The most blocks the hand can lay: two past 100%, or as many as reach 50 squares (one past at least).
        public var most: Int { min(k + 2, max(k + 1, 50 / width)) }
        public func laid(_ c: Int) -> String? { c == k ? nil : c < k ? "That’s \(c * p)%." : "That’s past 100%." }
        public var why: String { "\(k) blocks of \(p)% make 100%, so the whole is \(k) × \(P)." }
    }

    /// The web's generator: 10, 20, 25 or 50 percent of a part 2–30; the first three 10 or 50 percent of 2–10.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        index < 3 ? numbers(p: Ratio6.pick([10, 50], &rng), P: Int.random(in: 2...10, using: &rng))
            : numbers(p: Ratio6.pick([10, 20, 25, 50], &rng), P: Int.random(in: 2...30, using: &rng))
    }

    public static let spec = LessonSpec(id: "g6-pctwhole", title: "Find the whole", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.num(Double(s.P)), .text("is"), .num(Double(s.p)), .text("%"), .text("of"), .text("?")] },
        idea: { _ in "Equal blocks of that percent fill 100%, so the whole is that many blocks." },
        depends: ["g6-pctof"],
        check: [CheckItem(3, when: { Parts($0).p == 10 }), CheckItem(3, when: { Parts($0).p == 20 }), CheckItem(3, when: { Parts($0).p == 25 }), CheckItem(3, when: { Parts($0).p == 50 })]) { n in
        let s = Parts(n)
        let say = "Lay \(s.p)% blocks to 100%."
        let ask = LessonStep(StepWords(say: say, hint: "Each block is \(s.p)%.", action: "Let’s find out"), picture: ["at": 0])
        let hint = "Each block is \(s.p)%. Lay them to the bar’s end."
        let lay = LessonStep(StepWords(say: say, hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.k)], hint: hint, explain: s.why,
                               check: { v in
                                   guard let x = v["x"] else { return .soft(say) }
                                   return s.laid(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let parts = "The whole is \(s.k) of those parts."
        let took = Double(s.P * s.p) / 100
        let write = LessonStep(StepWords(say: "Write the whole.", hint: parts, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s.P)), .op("×"), .num(Double(s.k)), .op("="), .box("x")], expected: ["x": Double(s.whole)],
                               known: BigNumbers.slips(Double(s.whole), [(took, "You want the whole, so it’s bigger than \(s.P).")]),
                               hint: parts, explain: s.why,
                               check: { v in
                                   let x = v["x"] ?? -1
                                   if abs(x - Double(s.whole)) < 1e-9 { return .right }
                                   return .wrong(abs(x - took) < 1e-6 ? "You want the whole, so it’s bigger than \(s.P)." : parts)
                               }, incomplete: "Write the number in the box."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Count up to 100%.", action: "Next problem"), picture: ["at": 3])
        return [ask, lay, write, done]
    }
}
