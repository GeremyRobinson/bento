import SwiftUI

/// Multiplying fractions on the paper (design/grade5.md, the fractions family): a/b × c/d. One whole is a square whose
/// side is the smallest multiple of lcm(b, d) at least 24 squares, so every row and column is whole squares and every
/// piece can be counted. The problem is written once as the square's own names: a/b at its right, level with the rows it
/// shades, c/d under it, under the columns it shades. A ruler down the left side cuts it into rows (its readout counts
/// them, "3 rows", the cuts dashed across while it's dragged); Cut cuts. The child taps a rows (they shade as they're
/// tapped, counted over the square); Shade shades them. Then a ruler along the top cuts it into columns, and c columns are
/// tapped and striped. The pieces shaded twice are numbered, and the record a/b × c/d = (a × c)/(b × d) = [N]/[D] is
/// written beside or under the picture, then simplified when it can be. A big square (72 squares a side) is drawn with
/// its words a whole step bigger, so they still read with the camera far back.
@MainActor
struct MultiplyFractionsLesson: PaperLesson {
    /// (The taps redraw the still picture: what's tapped lies under the square's lines and over the other fraction's
    /// shading, as the shading it becomes does.)
    var liveKeys: Set<String> { ["ruler", "grab"] }
    /// A size being tried (Q.k lays the problem out at each size it tries); nil: the problem's own.
    var trying: Double? = nil

    private static let maths = Bars.maths, count = Bars.count, small = Bars.small
    /// A piece shaded twice: a shaded row's colour with the column's stripes over it, so it reads darker.
    private static let twice = Bars.shade

    /// A problem's numbers and where its parts go, in its squares.
    @MainActor struct Q {
        let a, b, c, d, N, D, S: Int
        let F: (whole: Int, num: Int, den: Int)
        let k: Double
        init(_ v: Numbers, story: Bool = false, k fixed: Double? = nil) {
            func i(_ key: String, _ dflt: Int) -> Int { Int((v[key] ?? Double(dflt)).rounded()) }
            b = min(max(2, i("b", 2)), 9); d = min(max(2, i("d", 2)), 9)
            a = min(max(1, i("a", 1)), b - 1); c = min(max(1, i("c", 1)), d - 1)
            N = a * c; D = b * d; S = MultiplyFractions.side(b: b, d: d)
            let g = gcd(N, D); F = (0, N / g, D / g)
            k = fixed ?? Self.k(v, story: story)
        }
        var simplifies: Bool { F.den != D }
        /// The columns' ruler row and the square's top; the rows' ruler column and the square's left; its bottom and right.
        var rulerRow: Double { 2 * k }
        var top: Double { 4 * k }
        var rulerCol: Double { 5 * k }
        var left: Double { 7 * k }
        var bottom: Double { top + Double(S) }
        var right: Double { left + Double(S) }
        /// A row's height and a column's width, in squares.
        var rh: Double { Double(S / b) }
        var cw: Double { Double(S / d) }
        /// The names: a/b's column right of the square (a bracket a square out first), c/d's row under it.
        var rowName: Double { right + 2 + k }
        var colName: Double { bottom + 2 + k }
        var recordRow: Double { colName + 4 * k + 3 }

        /// The rulers: each length that cuts the side into whole squares; where they start (the biggest that isn't
        /// the answer, so the hand has something to find), and the answer.
        var lengths: [Int] { Ruler.lengths(S) }
        func start(_ parts: Int) -> Int { lengths.last { $0 != S / parts } ?? S / parts }

        /// Words never show smaller than this many points; 18, not 22 (25 Oct): a square 30 or 40 squares a side (every
        /// problem with bottoms up to 5, the first ones) with its long record beside it showed its words at 19 to 21 points
        /// and was drawn with everything else twice as big, which took the camera so far back the square shrank by a third.
        static let readable = 18.0
        @MainActor static func k(_ v: Numbers, story: Bool) -> Double {
            let s = Q(v, k: 1), key = "\(s.a) \(s.b) \(s.c) \(s.d)\(story ? " story" : "")"
            if let k = scales[key] { return k }
            let run = LessonRun(MultiplyFractions.spec, numbers: v, story: story)
            var k = 1.0
            while k < 4, ProblemGrid.stackPlan(MultiplyFractionsLesson(trying: k), run, auto: false).zoom * Sketch.wordSize * k < readable { k += 1 }
            scales[key] = k
            return k
        }
        @MainActor private static var scales: [String: Double] = [:]
    }

    private func q(_ run: LessonRun) -> Q { Q(run.numbers, story: run.story, k: trying) }
    func scale(_ run: LessonRun) -> Double { q(run).k }
    func scale(_ n: Numbers) -> Double { Q(n, k: trying).k }
    func recordRow(_ n: Numbers) -> Double? { Q(n, k: trying).recordRow }
    /// Beside the square, level with its top, when that shows it bigger (a square is as tall as it's wide).
    func recordBeside(_ run: LessonRun) -> Double? { q(run).top }
    func recordBeside(_ n: Numbers) -> Double? { Q(n, k: trying).top }
    /// The web's slips run long.
    func messageRows(_ n: Numbers) -> Int { 2 }

    private func rowsRuler(_ q: Q) -> Ruler {
        let S = q.S
        return Ruler(W: S, row: q.rulerCol, from: q.left - 1, to: q.right + 1, old: [], start: q.start(q.b),
                     readout: { MultiplyFractions.count(S / max(1, $0), "row") }, vertical: true, at: q.top)
    }
    private func colsRuler(_ q: Q) -> Ruler {
        let S = q.S
        return Ruler(W: S, row: q.rulerRow, from: q.top - 1, to: q.bottom + 1, old: [], start: q.start(q.d),
                     readout: { MultiplyFractions.count(S / max(1, $0), "column") }, at: q.left)
    }

    /// The rows (or columns) tapped, as bits of the hand's "taps".
    private func taps(_ s: PaperState) -> Set<Int> { Self.bits(s.h("taps") ?? 0) }
    static func bits(_ v: Double) -> Set<Int> { let b = Int(v); return Set((0..<12).filter { b & (1 << $0) != 0 }) }

    /// The rows shaded and the columns striped once their step is done: the ones the child tapped (kept by Shade), or
    /// the first ones when there was nothing to tap (a top of 1 is shaded with the cut) or what's kept doesn't fit.
    private func shaded(_ s: PaperState, _ key: String, want: Int, of n: Int) -> [Int] {
        let kept = s.run.kept[key].map(Self.bits) ?? []
        return kept.count == want && kept.allSatisfy({ $0 < n }) ? kept.sorted() : Array(0..<want)
    }

    /// Runs of neighbouring indices (rows 0, 1 and 3: 0–1 and 3–3), each bracketed on its own.
    static func runs(_ xs: [Int]) -> [(Int, Int)] {
        var out: [(Int, Int)] = []
        for x in xs.sorted() { if let l = out.last, l.1 + 1 == x { out[out.count - 1].1 = x } else { out.append((x, x)) } }
        return out
    }

    /// A fraction in a column `w` squares wide (k: the words' size), its top centred down row r + k, its bar on r + 2k,
    /// its bottom down r + 3k (nil leaves a part empty, for a box).
    private func fraction(_ pen: inout GridPen, _ id: String, _ top: String?, _ bottom: String?, col: Double, row r: Double, w: Double, _ colour: Sketch.Colour = .ink) {
        let k = pen.k, m = Self.maths.colour(colour)
        if let top { pen.word(id + "t", top, at: col + w / 2, r + k, m) }
        pen.rule(id + "bar", from: col, to: col + w, row: r + 2 * k, colour, width: Sketch.stroke * k)
        if let bottom { pen.word(id + "b", bottom, at: col + w / 2, r + 3 * k, m) }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = self.q(s.run), k = q.k
        let L = q.left, T = q.top, R = q.right, B = q.bottom, S = Double(q.S), rh = q.rh, cw = q.cw
        let rows = s.on("rows"), shR = s.on("shR"), cols = s.on("cols"), shC = s.on("shC"), done = s.on("done")
        var pic = GridPen(k: k), live = GridPen(k: k, stableIds: true), rec = GridPen(k: k)

        // a big square is seen from far back, so its lines are drawn as much firmer as its words are bigger
        let wide = Sketch.stroke * k
        // MARK: the square: the a rows shaded, the c columns striped over them, so the pieces shaded twice are darker.
        // They're the rows and columns the child tapped, where they were tapped
        let sr = shaded(s, "rowsR", want: q.a, of: q.b), sc = shaded(s, "colsC", want: q.c, of: q.d)
        // the taps: rows shade, columns stripe, as they're tapped (over the rows already shaded)
        let tapping = s.on("tapR") || s.on("tapC"), byRow = s.on("tapR"), on = taps(s)
        let rowsOn = Set(shR ? sr : byRow ? on.sorted() : []), colsOn = Set(shC ? sc : s.on("tapC") ? on.sorted() : [])
        // drawn as pieces that never overlap (two fills over each other on the paper flicker as to which is on top): a
        // shaded row's pieces, a striped column's pieces, and the pieces both cover, darker, the stripes' lines over them
        for r in rowsOn.sorted() {
            for run in Self.runs((0..<q.d).filter { !colsOn.contains($0) }) {
                pic.fill("r\(r)_\(run.0)_\(run.1)", col: L + Double(run.0) * cw, row: T + Double(r) * rh, w: Double(run.1 - run.0 + 1) * cw, h: rh, Bars.shade)
            }
        }
        for c in colsOn.sorted() {
            for run in Self.runs((0..<q.b).filter { !rowsOn.contains($0) }) {
                pic.fill("c\(c)_\(run.0)_\(run.1)", col: L + Double(c) * cw, row: T + Double(run.0) * rh, w: cw, h: Double(run.1 - run.0 + 1) * rh, .tint(0.2))
            }
            for r in rowsOn.sorted() { pic.fill("o\(r)_\(c)", col: L + Double(c) * cw, row: T + Double(r) * rh, w: cw, h: rh, Self.twice) }
            pic.stripeLines("c\(c)s", col: L + Double(c) * cw, row: T, w: cw, h: S)
        }
        if rows { pic.sketch.segments("rc\(q.b)", (1..<q.b).map { i in (pic.P(L, T + Double(i) * rh), pic.P(R, T + Double(i) * rh)) }, .chapter, width: wide) }
        if cols { pic.sketch.segments("cc\(q.d)", (1..<q.d).map { i in (pic.P(L + Double(i) * cw, T), pic.P(L + Double(i) * cw, B)) }, .chapter, width: wide) }
        pic.sketch.box("sq", pic.R(L, T, S, S), .chapter, width: wide)

        // MARK: the names, the problem written once: a/b right of its rows, c/d under its columns, each bracketed once
        // shaded (a bracket for each run of rows or columns side by side; the name level with the middle of them all)
        // until its rows are shaded a name is centred on the whole square (there's nothing smaller for it to name yet);
        // then it glides to the middle of what it names
        let r0 = Double(sr.first ?? 0) * rh, r1 = Double((sr.last ?? 0) + 1) * rh, mid = (T + (shR ? (r0 + r1) / 2 : S / 2)).rounded()
        if shR {
            for (j, run) in Self.runs(sr).enumerated() {
                let y0 = T + Double(run.0) * rh, y1 = T + Double(run.1 + 1) * rh
                pic.sketch.line("rbr\(j)", [pic.P(R + 1, y0), pic.P(R + 2, y0), pic.P(R + 2, y1), pic.P(R + 1, y1)], .chapter, width: wide)
            }
        }
        fraction(&pic, "na", "\(q.a)", "\(q.b)", col: q.rowName, row: mid - 2 * k, w: 4 * k)
        let c0 = Double(sc.first ?? 0) * cw, c1 = Double((sc.last ?? 0) + 1) * cw, cx = L + (shC ? (c0 + c1) / 2 : S / 2).rounded()
        if shC {
            for (j, run) in Self.runs(sc).enumerated() {
                let x0 = L + Double(run.0) * cw, x1 = L + Double(run.1 + 1) * cw
                pic.sketch.line("cbr\(j)", [pic.P(x0, B + 1), pic.P(x0, B + 2), pic.P(x1, B + 2), pic.P(x1, B + 1)], .chapter, width: wide)
            }
        }
        fraction(&pic, "nc", "\(q.c)", "\(q.d)", col: min(max(L, cx - 2 * k), R - 4 * k), row: q.colName, w: 4 * k)

        // MARK: the pieces shaded twice, numbered row by row
        if shC {
            var i = 0
            for r in sr { for c in sc {
                i += 1
                pic.word("p\(i)", "\(i)", at: L + (Double(c) + 0.5) * cw, T + (Double(r) + 0.5) * rh, Self.count)
            } }
        }

        // MARK: the rulers, and what they'd cut, live as they're dragged
        var actions: [String] = []
        if s.on("rulerR") { actions = ["Cut"]; rowsRuler(q).draw(s, live: &live, still: &pic) }
        if s.on("rulerC") { actions = ["Cut"]; colsRuler(q).draw(s, live: &live, still: &pic) }

        // MARK: the taps' readout, counting them
        if tapping {
            actions = ["Shade"]
            let text = byRow ? "\(on.count) of \(MultiplyFractions.count(q.b, "row"))" : "\(on.count) of \(MultiplyFractions.count(q.d, "column"))"
            live.label("tapw", text, Self.small, .above, edge: T - 0.5, along: L + S / 2)
        }

        // MARK: the record, as school writes it: a/b × c/d = (a × c)/(b × d) = [N]/[D], then = [n]/[d] when it simplifies
        var boxes: [WorkBox] = []
        if shC {
            let written = s.on("simp") || done, w4 = 4 * k
            var x = 0.0
            func sign(_ id: String, _ t: String, _ colour: Sketch.Colour = .ink) { rec.word(id, t, at: x + k, 2 * k, Self.maths.colour(colour)); x += 2 * k }
            fraction(&rec, "ra", "\(q.a)", "\(q.b)", col: x, row: 0, w: w4); x += w4 + k
            sign("rx", "×"); x += k
            fraction(&rec, "rc", "\(q.c)", "\(q.d)", col: x, row: 0, w: w4); x += w4 + k
            sign("re1", "="); x += k
            fraction(&rec, "rp", "\(q.a) × \(q.c)", "\(q.b) × \(q.d)", col: x, row: 0, w: 6 * k); x += 6 * k + k
            sign("re2", "="); x += k
            // N/D: typed, then written (the answer's colour when it's already simplest)
            let ndColour: Sketch.Colour = done && !q.simplifies ? .chapter : .ink
            if written { fraction(&rec, "rnd", "\(q.N)", "\(q.D)", col: x, row: 0, w: w4, ndColour) }
            else {
                fraction(&rec, "rnd", nil, nil, col: x, row: 0, w: w4)
                rec.answerBox("n", right: x + w4, mid: k, per: 2 * k, cells: 2, centred: true)
                rec.answerBox("d", right: x + w4, mid: 3 * k, per: 2 * k, cells: 2, centred: true)
            }
            x += w4 + k
            if q.simplifies && written {
                sign("re3", "=", done ? .chapter : .ink); x += k
                if done { fraction(&rec, "rs", "\(q.F.num)", "\(q.F.den)", col: x, row: 0, w: w4, .chapter) }
                else {
                    fraction(&rec, "rs", nil, nil, col: x, row: 0, w: w4)
                    rec.answerBox("n", right: x + w4, mid: k, per: 2 * k, cells: 2, centred: true)
                    rec.answerBox("d", right: x + w4, mid: 3 * k, per: 2 * k, cells: 2, centred: true)
                }
            }
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions)
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = self.q(s.run)
        if s.on("rulerR") { return rowsRuler(q).hands(s) }
        if s.on("rulerC") { return colsRuler(q).hands(s) }
        let byRow = s.on("tapR")
        guard byRow || s.on("tapC") else { return nil }
        // a tap in a row (or column) of the square shades it, or takes its shading off; Shade checks how many
        let bits = Int(s.h("taps") ?? 0), count = taps(s).count
        let L = q.left, T = q.top, S = Double(q.S), rh = q.rh, cw = q.cw, n = byRow ? q.b : q.d
        return Hands(
            tap: { p in
                guard p.x >= L, p.x < L + S, p.y >= T, p.y < T + S else { return nil }
                let i = min(n - 1, Int(byRow ? (p.y - T) / rh : (p.x - L) / cw)), now = bits ^ (1 << i)
                return HandMove(hand: ["taps": Double(now)], missHand: nil, set: [("t", Double(now.nonzeroBitCount))])
            },
            // Shade keeps which ones were tapped, so they stay the ones shaded
            actions: ["Shade": { HandMove(hand: nil, missHand: nil, set: [("t", Double(count))], keep: [byRow ? "rowsR" : "colsC": Double(bits)], check: true) }])
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = self.q(s.run)
        if s.on("rulerR") { return rowsRuler(q).demo(s, to: q.S / q.b) }
        if s.on("rulerC") { return colsRuler(q).demo(s, to: q.S / q.d) }
        let byRow = s.on("tapR")
        guard byRow || s.on("tapC") else { return [] }
        // the first a rows (or c columns) tapped, those already shaded left as they are, then Shade
        let on = taps(s), want = byRow ? q.a : q.c, n = byRow ? q.b : q.d
        let flips = (0..<n).filter { ($0 < want) != on.contains($0) }
        let mid = Double(q.S) / 2
        return flips.map { i in
            let p = byRow ? CGPoint(x: q.left + mid, y: q.top + (Double(i) + 0.5) * q.rh) : CGPoint(x: q.left + (Double(i) + 0.5) * q.cw, y: q.top + mid)
            return .tap(.picture(p))
        } + [.tap(.action("Shade"))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = self.q(s.run)
        // a cut into the wrong number of rows (or columns)
        if s.on("rulerR") { let w = q.start(q.b); return HandMove(hand: ["ruler": Double(w)], missHand: nil, set: [("x", Double(q.S / w))], check: true) }
        if s.on("rulerC") { let w = q.start(q.d); return HandMove(hand: ["ruler": Double(w)], missHand: nil, set: [("x", Double(q.S / w))], check: true) }
        // one row (or column) too many shaded
        let byRow = s.on("tapR")
        guard byRow || s.on("tapC") else { return nil }
        let t = (byRow ? q.a : q.c) + 1
        return HandMove(hand: ["taps": Double((1 << t) - 1)], missHand: nil, set: [("t", Double(t))], check: true)
    }
}
