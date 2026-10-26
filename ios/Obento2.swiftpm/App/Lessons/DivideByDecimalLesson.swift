import SwiftUI

/// Dividing by a decimal on the paper (design/grade5.md). A number line where one square is a tenth, in every problem: a
/// short tick every five squares (0.5), a long one every ten (a whole), the wholes numbered under it. It runs from 0 on
/// past the dividend to the next whole, and the problem is written once as its two names: the dividend marked on the
/// line and named under it, the divisor as a dashed hop from 0 with its size over it. The child hops along from 0 (a tap
/// lays one more hop, a drag lays them as it goes), each hop snapping to the divisor's squares and numbered over its
/// arc, the readout counting them ("5 hops of 0.6 = 3"); hops past the dividend are red, and letting go there is
/// answered in words and put back. Once the hops reach the end, the same squares are read in tenths under the line
/// (0, 6, 12, … 48), the record is written as school writes it (4.8 ÷ 0.6 = 48 ÷ 6 = [ ]), and the last words say why.
@MainActor
struct DivideByDecimalLesson: PaperLesson {
    var liveKeys: Set<String> { ["k", "grab", "from"] }
    /// A size being tried (Q.k lays the problem out at each size it tries); nil: the problem's own.
    var trying: Double? = nil

    private static let name = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let readout = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    private static let count = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    /// Hops past the end: red (red means wrong).
    private static let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)

    /// A problem's numbers and where its parts go, in its squares.
    @MainActor struct Q {
        let d, qt, n: Int
        let x, y: Double
        let X, Y: String
        let k: Double
        /// Squares to a tenth: 1, or 3 or 2 on a line of one or two wholes (DivideByDecimal.squaresPerTenth).
        let u: Double
        init(_ v: Numbers, story: Bool = false, k fixed: Double? = nil) {
            let s = DivideByDecimal.Parts(v)
            d = s.d; qt = s.qt; n = s.n; x = s.x; y = s.y; X = fmt(x); Y = fmt(y)
            u = Double(DivideByDecimal.squaresPerTenth(s.n))
            k = fixed ?? Self.k(v, story: story)
        }
        /// The line's length: on past the dividend to the next whole, so a hop past it lands on the line.
        var wholes: Int { n / 10 + 1 }
        var W: Double { Double(10 * wholes) * u }
        /// The dividend's place on the line.
        var end: Double { Double(n) * u }
        /// One hop's squares, and how many hops the line has room for (one past its end at most).
        var D: Double { Double(d) * u }
        var most: Int { 10 * wholes / d + 1 }
        /// The line's row (the readout and the hops' numbers over it), the hops' height, the tenths' row under it.
        var line: Double { 4 + 3 * k }
        var arc: Double { min(2.5, max(1, D / 2)) }
        var tenths: Double { line + 2.5 * k }
        var bottom: Double { tenths + 1.5 * k }

        // MARK: the record, two squares a digit: X ÷ Y = n ÷ d = [qt]
        var per: Double { 2 * k }
        var recordRow: Double { bottom + 3 }
        func cells(_ s: String) -> Double { Double(s.filter { $0 != "." }.count) * per }
        /// The record's parts, left to right: a number (its digits' right edge) or a sign (its middle).
        var parts: [(text: String, at: Double, sign: Bool)] {
            var out: [(String, Double, Bool)] = [], c = 0.0
            for (t, sign) in [(X, false), ("÷", true), (Y, false), ("=", true), ("\(n)", false), ("÷", true), ("\(d)", false), ("=", true)] {
                if sign { out.append((t, c + per / 2, true)); c += per } else { c += cells(t); out.append((t, c, false)) }
            }
            return out
        }
        var answerRight: Double { (parts.last?.at ?? 0) + per / 2 + cells("\(qt)") }

        static let readable = 22.0
        static func k(_ v: Numbers, story: Bool) -> Double {
            let s = DivideByDecimal.Parts(v), key = "\(s.d) \(s.qt)\(story ? " story" : "")"
            if let k = scales[key] { return k }
            let run = LessonRun(DivideByDecimal.spec, numbers: v, story: story)
            var k = 1.0
            while k < 6, ProblemGrid.stackPlan(DivideByDecimalLesson(trying: k), run, auto: false).zoom * Sketch.wordSize * k < readable { k += 1 }
            scales[key] = k
            return k
        }
        private static var scales: [String: Double] = [:]
    }

    private func q(_ run: LessonRun) -> Q { Q(run.numbers, story: run.story, k: trying) }
    /// The stage: 0 the question, 1 hop, 2 write, 3 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func scale(_ run: LessonRun) -> Double { q(run).k }
    func scale(_ n: Numbers) -> Double { Q(n, k: trying).k }
    func recordRow(_ n: Numbers) -> Double? { Q(n, k: trying).recordRow }
    func messageRows(_ run: LessonRun) -> Int { missRows(q(run)) }
    func messageRows(_ n: Numbers) -> Int { missRows(Q(n, k: trying)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = self.q(s.run), at = stage(s), k = q.k
        var pic = GridPen(k: k), live = GridPen(k: k, stableIds: true), rec = GridPen(k: k)
        let L = q.line, W = q.W, end = q.end, D = q.D, u = q.u

        // MARK: the line: a short tick every half, a long one every whole, the wholes numbered under it (not where the
        // dividend's own name is); drawn bigger than a square a tenth, a small tick every tenth too, so they still count
        pic.line("line", [(0, L), (W, L)], .ink)
        pic.sketch.segments("ticks", stride(from: 0, through: 10 * q.wholes, by: u > 1 ? 1 : 5).map { c in
            (pic.P(Double(c) * u, L - (c % 10 == 0 ? 2 : c % 5 == 0 ? 1 : 0.5)), pic.P(Double(c) * u, L))
        }, .ink, width: Sketch.stroke)
        for j in 0...q.wholes where abs(Double(10 * j) * u - end) >= 2.5 * k {
            pic.label("w\(j)", "\(j)", Self.small, .below, edge: L, along: Double(10 * j) * u)
        }
        // the dividend: a post on the line in the chapter's colour, its name under it
        pic.line("post", [(end, L - 2), (end, L)], .chapter)
        pic.dot("end", at: end, L, radius: 0.4, .chapter, over: true)
        pic.label("nx", q.X, Self.name, .below, edge: L, along: end)
        if at == 1, s.on("ring") { pic.circle("ring", at: end, L, radius: 1.3 * k, .chapter, dashed: true) }

        // MARK: the hops, numbered over their arcs: live while they're laid, then still
        func hops(_ pen: inout GridPen, _ count: Int, lit: Bool) {
            for j in 0..<count {
                let a = Double(j) * D, b = a + D, past = b > end + 0.01
                let colour: Sketch.Colour = past ? Self.red : .chapter
                pen.hop("hop\(j)", from: a, to: b, row: L, height: q.arc, colour)
                pen.label("hn\(j)", "\(j + 1)", Self.count.colour(past ? Self.red : .chapter), .above, edge: L - q.arc, along: (a + b) / 2)
            }
            if count > 0 {
                pen.dot("front", at: Double(count) * D, L, radius: 0.35 * k, count * q.d > q.n ? Self.red : .chapter, over: true)
                let text = "\(count == 1 ? "1 hop" : "\(count) hops") of \(q.Y) = \(fmt(DivideByDecimal.Parts(s.numbers).reach(count)))"
                let w = PaperText.width(text, PaperText.font(Sketch.wordSize * k, .medium)) / Paper.cell
                let along = max(w / 2, min(W - w / 2, Double(count) * D / 2))
                pen.label("readout", text, Self.readout.colour(lit ? .chapter : .ink), .above, edge: 2 * k, along: along)
                pen.reads(text)
            }
        }
        /// The divisor's size, written once: a dashed hop from 0 with its name over it, until the first hop is laid.
        func sample(_ pen: inout GridPen) {
            let pts = (0...16).map { i -> CGPoint in let t = Double(i) / 16; return pen.P(D * t, L - sin(.pi * t) * q.arc) }
            pen.sketch.segments("sample", GridPen.dashes(pts), .ink2, width: Sketch.stroke)
            pen.label("ny", q.Y, Self.name, .above, edge: L - q.arc, along: D / 2)
        }
        let laid = Int((s.h("k") ?? 0).rounded())
        if at == 0 { sample(&pic) }
        else if at == 1 {
            if laid == 0 { sample(&live) }
            hops(&live, laid, lit: false)
        } else {
            hops(&pic, q.qt, lit: at >= 3)
        }

        // MARK: the same squares in tenths, under the line at each hop's end
        if at >= 2 {
            for j in 0...q.qt {
                pic.label("t\(j)", "\(j * q.d)", Self.count, .below, edge: q.tenths, along: Double(j) * D)
            }
            pic.label("tw", "tenths", Self.small.colour(.chapter), .right, edge: W + 1, along: q.tenths + 0.5 * k + 0.4 * k)
        }

        // MARK: the record: X ÷ Y = n ÷ d = [qt]
        var boxes: [WorkBox] = []
        if at >= 2, !s.picking {
            let row = q.per / 2
            for (i, p) in q.parts.enumerated() {
                if p.sign { rec.word("r\(i)", p.text, at: p.at, row, Self.maths) }
                else { rec.digits("r\(i)", p.text, right: p.at, row: row, per: q.per) }
            }
            if at == 2 { rec.answerBox("x", right: q.answerRight, mid: row, per: q.per, cells: "\(q.qt)".count) }
            else { rec.digits("ans", "\(q.qt)", right: q.answerRight, row: row, per: q.per, .chapter) }
            boxes = rec.boxes
        }
        let extent = pic.R(-2 * k, 0, W + D + 2 * k + 8 * k, q.bottom)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, extent: extent)
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = self.q(s.run), k = q.k
        guard stage(s) == 1 else { return nil }
        let now = Int((s.h("k") ?? 0).rounded()), L = q.line
        func onLine(_ p: CGPoint) -> Bool { p.x > -1.5 && p.x < q.W + q.D + 1 && p.y > L - q.arc - 2.5 * k && p.y < L + 3 * k }
        /// `count` hops laid: checked once they reach the end (or go past it); a miss puts back the hops there were.
        func move(_ count: Int, from: Int) -> HandMove {
            HandMove(hand: ["k": Double(count)], missHand: ["k": Double(from)], set: [("h", Double(count))], check: count >= q.qt)
        }
        return Hands(
            // a tap anywhere on the line lays one more hop
            tap: { p in onLine(p) ? move(min(q.most, now + 1), from: now) : nil },
            grab: { p in onLine(p) ? ["grab": 1, "k": Double(now), "from": Double(now)] : nil },
            // dragged along, the hops follow the finger, a whole hop at a time
            drag: { p, h in ["grab": 1, "from": h["from"] ?? Double(now), "k": Double(min(q.most, max(0, Int((p.x / q.D).rounded()))))] },
            release: { h in move(Int((h["k"] ?? 0).rounded()), from: Int((h["from"] ?? 0).rounded())) })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = self.q(s.run)
        guard stage(s) == 1 else { return [] }
        let now = Double(Int((s.h("k") ?? 0).rounded()))
        return [.drag(from: CGPoint(x: now * q.D, y: q.line), to: CGPoint(x: q.end, y: q.line))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = self.q(s.run)
        guard stage(s) == 1 else { return nil }
        // one hop past the end
        return HandMove(hand: ["k": Double(q.qt + 1)], missHand: ["k": 0], set: [("h", Double(q.qt + 1))], check: true)
    }

    /// What a miss says can run to two rows on a short line.
    private func missRows(_ q: Q) -> Int {
        let longest = "\(q.most) hops of \(q.Y) reach \(fmt(Double(q.most * q.d) / 10)). That’s past \(q.X)."
        let w = PaperText.width(longest, PaperText.font(Sketch.small * q.k, .medium)) / Paper.cell
        return w > max(30, q.W + q.D) ? 2 : 1
    }
}
