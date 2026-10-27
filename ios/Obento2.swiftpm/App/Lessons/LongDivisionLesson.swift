import SwiftUI

/// Long division on the paper (design/grade5.md): Multiply's rectangle run backwards. One square is one thing (a marble,
/// in the story), every ten bold: a rectangle dv squares tall, named down its left side, whose width is found. Its right
/// edge has a handle; dragged (or tapped to a place) it snaps ten columns at a time, the strip lit as it grows, its width
/// written over it, the squares it uses written in it and what's left at its right end ("840", "24 left"). Check takes
/// the tens; then the edge goes on a column at a time until nothing is left. The record is the division as school writes
/// it, the problem in its bracket: each strip's squares taken away under it as it's found, its width beside them (the
/// partial quotients, written for the child), and the answer typed over the bracket. The last words say why.
@MainActor
struct LongDivisionLesson: PaperLesson {
    var liveKeys: Set<String> { ["edge", "grab"] }
    /// A size being tried (Q.k lays the problem out at each size it tries); nil: the problem's own.
    var trying: Double? = nil
    private func q(_ run: LessonRun) -> Q { Q(run.numbers, story: run.story, k: trying) }

    private static let name = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    private static let readout = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let product = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .chapter)
    private static let sign = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let minor = Sketch.Colour.tint(0.45), ten = Sketch.Colour.tint(0.85)
    private static func fill(_ lit: Bool) -> Sketch.Colour { .tint(lit ? 0.3 : 0.1) }

    /// A problem's numbers and where its parts go, in its squares.
    @MainActor struct Q {
        let dv, qt, n: Int
        /// The answer's tens and ones, the squares the tens use, and what's left after them.
        let T, O, rest: Int
        /// Words, blocks and the record drawn k times as big when the rectangle is big (the camera steps far back for it).
        let k: Double
        init(_ nums: Numbers, story: Bool = false, k fixed: Double? = nil) {
            dv = max(1, Int((nums["dv"] ?? 12).rounded())); qt = max(1, Int((nums["qt"] ?? 72).rounded())); n = dv * qt
            T = qt - qt % 10; O = qt % 10; rest = n - dv * T
            k = fixed ?? Self.k(dv: dv, qt: qt, story: story)
        }
        /// Words never show smaller than this many points (as Multiply's).
        static let readable = 22.0
        /// Bigger by whole steps while its words would show smaller than `readable`: the problem laid out at each size
        /// just as it will be shown (ProblemGrid's plan), worked out once per problem, told plainly or as its story.
        static func k(dv: Int, qt: Int, story: Bool) -> Double {
            let key = "\(dv)÷\(qt)\(story ? " story" : "")"
            if let k = scales[key] { return k }
            let run = LessonRun(LongDivision.spec, numbers: LongDivision.numbers(dv: dv, qt: qt), story: story)
            var k = 1.0
            while k < 6, ProblemGrid.stackPlan(LongDivisionLesson(trying: k), run, auto: false).zoom * Sketch.wordSize * k < readable { k += 1 }
            scales[key] = k
            return k
        }
        private static var scales: [String: Double] = [:]
        /// The rectangle's top row (its widths are written in the rows over it) and its middle row (the handle's).
        var top: Double { 2 * k }
        var mid: Double { top + Double(dv) / 2 }
        /// The furthest the edge goes: a ten past where the tens end (so "more than 864" can be seen).
        var far: Int { T + 10 }
        func width(_ text: String, _ w: Sketch.Words) -> Double { PaperText.width(text, PaperText.font(w.size * k, w.weight, digits: true)) / Paper.cell }
        /// The room at the right end for what's left, written half a square past the handle.
        var readoutRoom: Double { 0.6 * k + 0.5 + max(width("\(n) left", LongDivisionLesson.readout), width("\(dv * 10) too many", LongDivisionLesson.readout)) }
        /// The ones strip's squares don't fit in it: written under it.
        var onesUnder: Bool { width("\(dv * O)", LongDivisionLesson.product) + 0.5 > Double(O) }
    }

    /// The stage (LongDivision's "at"): 0 the question, 1 the tens, 2 the ones, 3 the answer to write, 4 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Where the edge being dragged starts from, how far one snap moves it, on this stage.
    private func from(_ q: Q, _ at: Int) -> (base: Int, step: Int) { at == 1 ? (0, 10) : (q.T, 1) }

    func scale(_ run: LessonRun) -> Double { q(run).k }
    func recordBeside(_ run: LessonRun) -> Double? { q(run).top }
    func messageRows(_ run: LessonRun) -> Int { missRows(q(run)) }
    func scale(_ n: Numbers) -> Double { Q(n, k: trying).k }
    func recordBeside(_ n: Numbers) -> Double? { Q(n, k: trying).top }
    func messageRows(_ n: Numbers) -> Int { missRows(Q(n, k: trying)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = self.q(s.run), at = stage(s), k = q.k
        let H = Double(q.dv), top = q.top, T = Double(q.T), O = Double(q.O)
        var pic = GridPen(k: k), live = GridPen(k: k, stableIds: true), rec = GridPen(k: k)

        // its name: its height down its left side (the problem's other numbers are in the record's bracket), clear of the
        // handle while the edge starts there
        pic.label("side", "\(q.dv)", Self.name, .left, edge: at == 1 ? -0.6 * k : 0, along: q.mid)

        /// Squares written in a strip, or under it when it's too narrow to hold them (`clear`: room kept at each end, as
        /// the handle's dot needs at the strip's right end, so the number never runs into it).
        func inStrip(_ pen: inout GridPen, _ id: String, _ text: String, x: Double, w: Double, _ words: Sketch.Words, clear: Double = 0) {
            if q.width(text, words) + 0.5 + 2 * clear <= w { pen.word(id, text, at: x + w / 2, q.mid, words) }
            else { pen.label(id, text, words, .below, edge: top + H, along: x + w / 2) }
        }

        // MARK: the strips found: the tens (from the ones on), the ones (once found); their widths over them, their
        // squares in them; both lit while the answer is written
        if at >= 2 {
            strip(&pic, "S1", x: 0, cols: q.T, rows: q.dv, top: top, lit: at == 3, left: true, right: at < 3)
            pic.label("w1", "\(q.T)", Self.name, .above, edge: top, along: T / 2)
            inStrip(&pic, "p1", "\(q.dv * q.T)", x: 0, w: T, Self.product)
        }
        if at >= 3 {
            strip(&pic, "S2", x: T, cols: q.O, rows: q.dv, top: top, lit: at == 3, left: false, right: true)
            pic.label("w2", "\(q.O)", Self.name, .above, edge: top, along: T + O / 2)
            inStrip(&pic, "p2", "\(q.dv * q.O)", x: T, w: O, Self.product)
        }
        // done: the whole width under it, in the chapter's colour
        if at >= 4 {
            let row = top + H + (q.onesUnder ? 3 * k : 1)
            pic.line("all", [(0, row - 0.5), (0, row), (Double(q.qt), row), (Double(q.qt), row - 0.5)], .chapter)
            pic.label("allw", "\(q.qt)", Self.product, .below, edge: row, along: Double(q.qt) / 2)
        }

        // MARK: the edge, live as the hand moves it: the strip being found grows from where the last one ends, lit,
        // every square drawn; its width over it, its squares in it, and what's left at its right end
        var actions: [String] = []
        if at == 1 || at == 2 {
            actions = ["Check"]
            let (base, _) = from(q, at), b = Double(base)
            let c = s.h("edge") ?? b, cols = Int(c.rounded()) - base, used = q.dv * cols, left = (at == 1 ? q.n : q.rest) - used
            if cols > 0 {
                strip(&live, "L", x: b, cols: cols, rows: q.dv, top: top, lit: true, left: at == 1, right: true)
                live.label("lw", "\(cols)", Self.readout, .above, edge: top, along: b + Double(cols) / 2)
                inStrip(&live, "lu", "\(used)", x: b, w: Double(cols), Self.readout, clear: (s.grabbed ? 0.75 : 0.6) * k)
            } else if at == 1 {
                live.line("L0", [(0, top), (0, top + H)], .chapter)
            }
            live.dot("handle", at: c, q.mid, radius: (s.grabbed ? 0.75 : 0.6) * k, .chapter, over: true)
            let say = left >= 0 ? "\(left) left" : "\(-left) too many"
            live.label("left", say, Self.readout, .right, edge: c + 0.6 * k, along: q.mid)
            live.reads(say)
        }

        // MARK: the record: the division as school writes it, two squares to a digit: the divisor, the bracket and the
        // number under it; each strip's squares taken away as it's found and its width beside them; the answer typed
        // over the bracket, then in the chapter's colour
        let per = 2 * k, dvd = Double(String(q.dv).count), nd = Double(String(q.n).count)
        let S = (dvd + 1) * per, R = S + nd * per, Qr = R + 3 * per, bx = S - 0.25 * per
        func row(_ r: Double) -> Double { (r + 0.5) * per }
        // a story's "Pick what to do": the bracket would give the division away, so it's written once it's picked
        if !s.picking {
            rec.digits("dv", "\(q.dv)", right: S - per, row: row(1), per: per)
            // the bracket: a curve down the number's left, then over it
            let curve = (0...12).map { i -> CGPoint in let t = Double(i) / 12; return rec.P(bx - 0.3 * per + 0.3 * per * sin(.pi * t), 2 * per - t * per) }
            rec.sketch.line("bracket", curve + [rec.P(R, per)], .ink, width: Sketch.stroke)
            rec.digits("n", "\(q.n)", right: R, row: row(1), per: per)
        }
        func takeAway(_ id: String, _ product: Int, _ part: Int, _ r: Double, _ under: String) {
            let len = Double(String(product).count)
            rec.word(id + "m", "−", at: R - (len + 0.5) * per, row(r), Self.sign)
            rec.digits(id + "p", "\(product)", right: R, row: row(r), per: per)
            rec.rule(id + "u", from: R - len * per, to: R, row: (r + 1) * per)
            rec.digits(id + "q", "\(part)", right: Qr, row: row(r), per: per, .chapter)
            rec.digits(id + "r", under, right: R, row: row(r + 1), per: per)
        }
        if at >= 2 { takeAway("t", q.dv * q.T, q.T, 2, "\(q.rest)") }
        if at >= 3 { takeAway("o", q.dv * q.O, q.O, 4, "0") }
        if at == 3 { rec.answerBox("x", right: R, mid: row(0), per: per, cells: String(q.qt).count) }
        if at >= 4 { rec.digits("ans", "\(q.qt)", right: R, row: row(0), per: per, .chapter) }

        // the room the edge needs: as far as it goes, what's left written past it, the whole width's bracket under it
        let extent = pic.R(-0.5, 0, Double(q.far) + q.readoutRoom + 0.5, top + H + (q.onesUnder ? 3 * k : 1) + 2.5 * k)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: actions, extent: extent)
    }

    /// `cols` columns of the rectangle from column x: its edges, every square, every ten of the rectangle bold (counted
    /// from its left side), and its fill. Where it joins the strip before it its edge is left off (that one's bold edge
    /// is the line between them).
    private func strip(_ pen: inout GridPen, _ id: String, x: Double, cols: Int, rows: Int, top: Double, lit: Bool, left: Bool, right: Bool) {
        let w = Double(cols), h = Double(rows), c0 = Int(x.rounded())
        pen.line("\(id)top", [(x, top), (x + w, top)], .chapter)
        pen.line("\(id)bot", [(x, top + h), (x + w, top + h)], .chapter)
        if left { pen.line("\(id)l", [(x, top), (x, top + h)], .chapter) }
        if right { pen.line("\(id)r", [(x + w, top), (x + w, top + h)], .chapter) }
        var fine: [(CGPoint, CGPoint)] = [], bold: [(CGPoint, CGPoint)] = []
        for c in 1..<max(1, cols) {
            let seg = (pen.P(x + Double(c), top), pen.P(x + Double(c), top + h))
            if (c0 + c) % 10 == 0 { bold.append(seg) } else { fine.append(seg) }
        }
        for r in 1..<max(1, rows) {
            let seg = (pen.P(x, top + Double(r)), pen.P(x + w, top + Double(r)))
            if r % 10 == 0 { bold.append(seg) } else { fine.append(seg) }
        }
        pen.sketch.segments("\(id)c", fine, Self.minor, width: 1)
        pen.sketch.segments("\(id)t", bold, Self.ten, width: Sketch.stroke)
        pen.fill("\(id)f\(lit)", col: x, row: top, w: w, h: h, Self.fill(lit))
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = self.q(s.run), at = stage(s), k = q.k
        guard at == 1 || at == 2 else { return nil }
        let (base, step) = from(q, at), b = Double(base), far = Double(q.far), H = Double(q.dv)
        let c = s.h("edge") ?? b
        /// The edge for the finger here: ten columns at a time for the tens, one at a time for the ones, never back past
        /// where this strip starts nor more than a ten past where the tens end.
        func snap(_ x: Double) -> Double { min(far, max(b, b + ((x - b) / Double(step)).rounded() * Double(step))) }
        return Hands(
            // a tap in the rectangle's rows, out to as far as the edge goes, puts the edge there
            tap: { p in p.y > q.top - 0.5 && p.y < q.top + H + 0.5 && p.x > b - 0.5 && p.x < far + 0.5 ? HandMove(hand: ["edge": snap(p.x)], missHand: nil) : nil },
            // the handle, or the edge it's on, a finger's width either side
            grab: { p in abs(p.x - c) < 2 * k && p.y > q.top - 1.5 * k && p.y < q.top + H + 1.5 * k ? ["grab": 1, "edge": c] : nil },
            drag: { p, _ in ["grab": 1, "edge": snap(p.x)] },
            release: { h in HandMove(hand: ["edge": h["edge"] ?? c], missHand: nil) },
            // Check: how many columns the strip is goes in the step's box, checked
            actions: ["Check": { HandMove(hand: nil, missHand: nil, set: [("x", c - b)], check: true) }])
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = self.q(s.run), at = stage(s)
        guard at == 1 || at == 2 else { return [] }
        let b = Double(from(q, at).base), c = s.h("edge") ?? b, to = at == 1 ? Double(q.T) : Double(q.qt)
        return (c == to ? [] : [.drag(from: CGPoint(x: c, y: q.mid), to: CGPoint(x: to, y: q.mid))]) + [.tap(.action("Check"))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = self.q(s.run), at = stage(s)
        guard at == 1 || at == 2 else { return nil }
        // a ten too many, or a column too many: more squares than there are
        let x = at == 1 ? q.T + 10 : q.O + 1, edge = at == 1 ? x : q.T + x
        return HandMove(hand: ["edge": Double(edge)], missHand: nil, set: [("x", Double(x))], check: true)
    }

    /// What a miss says can run to two rows on a narrow problem ("That uses 2000, and 475 are left: ten more columns fit.").
    private func missRows(_ q: Q) -> Int {
        let longest = "That uses \(q.dv * max(10, q.T - 10)), and \(q.n - q.dv * max(10, q.T - 10)) are left: ten more columns fit."
        let w = PaperText.width(longest, PaperText.font(Sketch.small * q.k, .medium)) / Paper.cell
        return w > max(30, Double(q.far) + q.readoutRoom) ? 2 : 1
    }
}
