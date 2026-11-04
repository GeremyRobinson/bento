import SwiftUI

/// Ratio tables on the paper, as in the preview (design/prototype/grade6-ch1.html, dRatioTable): the first-quadrant plane,
/// two squares a unit, across 0–24 for the minutes and up 0–12 for the other amount; the table is the record under it
/// (two rows a column), the written lines beside the table. Put a point for each of the first two columns (it snaps to
/// every grid point, dotted lines drop to both axes, the readout is its pair); the ruler line lays itself from 0 through
/// both; slide a point along the line (it snaps only to the grid points on it) to fill each gap; write the column past
/// the paper; slide to 1 lap and write how long 1 lap takes. The compare kind: two tables, a point for each first column,
/// both lines on one plane, drag up the line at X minutes, then pick whose is more.
///
/// The picture's squares: the plane's corner at (5, 25), its arrow tips on row 0. The table and the lines are the record,
/// 3 rows under the plane (so the problem shows at 75% or more). Hand keys: "m" (the points placed), "cu"/"cv" (the
/// point held, in squares from the corner), "bu"/"bv" (a wrong one), "j" (a slid point, half units along the line), "sv"
/// (the compare's point up the line).
@MainActor
struct RatioTableLesson: PaperLesson {
    static let rowH = 2.0, cellW = 4.0, header = 6.0
    var liveKeys: Set<String> { ["cu", "cv", "j", "sv", "grab"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func plane(_ P: RatioTable.Parts) -> R6.Plane { var p = R6.Plane(); p.yName = P.S.up; return p }
    func recordRow(_ n: Numbers) -> Double? { R6.Plane().oy + 3 }

    // MARK: the written lines beside the table

    private func sx(_ P: RatioTable.Parts) -> Double { Self.header + Self.cellW * Double(P.cols.count) + 3 }
    private func pastLine(_ P: RatioTable.Parts, done: Bool) -> [M7.Tok] {
        [.w(P.past), done ? .n(P.b * P.tP, .chapter) : .box("x", cells: 2), .w("minutes")]
    }
    private func unitLine(_ P: RatioTable.Parts, done: Bool) -> [M7.Tok] {
        if done { return [.w(P.oneTakes), .t(P.unitRate, .chapter), .w("minutes")] }
        return [.w(P.oneTakes)] + (P.a == 1 ? [.box("w", cells: 1)] : [.box("w", cells: 1), .box("n", cells: 1), .op("/"), .box("d", cells: 1)]) + [.w("minutes")]
    }
    /// Check sits two squares past the longer line, on the row of the line being written.
    private func checkX(_ P: RatioTable.Parts) -> Double {
        (sx(P) + max(M7.width(pastLine(P, done: false)), M7.width(unitLine(P, done: false))) + 2).rounded(.up)
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = RatioTable.Parts(s.numbers), at = stage(s), top = recordRow(s.numbers) ?? 28
        switch at {
        case 4: return CGPoint(x: checkX(P), y: top)
        case 6, 7: return CGPoint(x: checkX(P), y: top + 3)
        case 9: return CGPoint(x: 61, y: 2)
        case 10: return CGPoint(x: 40, y: top)
        default: return nil
        }
    }

    // MARK: drawing

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = RatioTable.Parts(s.numbers), at = stage(s), pl = plane(P)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let a = Double(P.a), b = Double(P.b)
        // what's held: a point being placed, a point being slid, the compare's point going up
        let held: (u: Double, v: Double)? = {
            guard s.grabbed else { return nil }
            if at == 1, let cu = s.h("cu"), let cv = s.h("cv") { return (cu / 2, cv / 2) }
            if [2, 3, 5].contains(at), let j = s.h("j") { return (j * b / 2, j * a / 2) }
            if at == 8, let sv = s.h("sv") { return (Double(P.X), sv / 2) }
            return nil
        }()
        func whole(_ x: Double) -> Int? { x == x.rounded() ? Int(x) : nil }
        // the plane's numbers light under a held point (in the live pen, so they follow it)
        pl.draw(&pic)
        if let h = held {
            if let x = whole(h.u), x > 0 { live.label("litx", "\(x)", R6.lit, .below, edge: pl.oy + 0.4, along: pl.at(h.u, 0).x) }
            if let y = whole(h.v), y > 0 { live.label("lity", "\(y)", R6.lit, .left, edge: pl.ox - 0.4, along: pl.at(0, h.v).y) }
        }
        if P.compares { drawCompare(s, P, pl, at, held, &pic, &live, &rec) } else { drawTable(s, P, pl, at, held, &pic, &live, &rec) }
        let right = max(checkX(P) + 10, 70)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, right, 1))
    }

    private func drawTable(_ s: PaperState, _ P: RatioTable.Parts, _ pl: R6.Plane, _ at: Int, _ held: (u: Double, v: Double)?,
                           _ pic: inout GridPen, _ live: inout GridPen, _ rec: inout GridPen) {
        let a = Double(P.a), b = Double(P.b), mask = Int(s.h("m") ?? 0)
        // the points: the first two columns (as they're placed, then for good), the gaps once they're found
        let placed = at >= 2 ? [1, 2] : [1, 2].filter { mask & (1 << ($0 - 1)) != 0 }
        if at >= 2 { _ = pl.ray(&pic, "ray", a: P.a, b: P.b) }
        for t in placed { pl.mark(&pic, "pt\(t)", b * Double(t), a * Double(t)) }
        let filledL = at > 2, filledM = P.tM > 0 && at > 3, filledP = at > 4
        if filledL { pl.mark(&pic, "gl", b * Double(P.tL), a * Double(P.tL)) }
        if filledM { pl.mark(&pic, "gm", b * Double(P.tM), a * Double(P.tM)) }
        if at >= 6 && P.a == 2 { pl.mark(&pic, "one", b / a, 1, label: at >= 7) }
        // a wrong point, red, with its lines to the axes
        if at == 1, s.h("bad") == 1, let bu = s.h("bu"), let bv = s.h("bv") {
            pl.mark(&pic, "bad\(Int(bu))_\(Int(bv))", bu / 2, bv / 2, label: false, R6.red)
            pl.drops(&pic, "bd\(Int(bu))_\(Int(bv))", bu / 2, bv / 2, R6.red)
        }
        // the point held, or the one to slide
        if [2, 3, 5].contains(at) {
            let j = s.h("j") ?? Double(P.start(at)), p = pl.at(j * b / 2, j * a / 2)
            R6.handle(&live, "sl", p.x, p.y, held: s.grabbed)
        }
        if let h = held {
            let p = pl.at(h.u, h.v)
            if at == 1 { R6.handle(&live, "cur", p.x, p.y, held: true) }
            pl.drops(&live, "hd", h.u, h.v)
            live.word("hr", Ratio6.pair(h.u, h.v), at: p.x + 1, p.y + 1.3, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            live.reads(Ratio6.pair(h.u, h.v))
        }
        // the table: the record under the plane
        let cols = P.cols, n = Double(cols.count), right = Self.header + Self.cellW * n, H = Self.rowH
        rec.word("th1", P.S.up, at: 0.5, H / 2, R6.small, anchor: UnitPoint(x: 0, y: 0.5))
        rec.word("th2", "minutes", at: 0.5, H * 1.5, R6.small, anchor: UnitPoint(x: 0, y: 0.5))
        for y in [0, H, 2 * H] { rec.rule("tl\(y)", from: 0, to: right, row: y) }
        for c in 0...cols.count { rec.sketch.line("tv\(c)", [rec.P(Self.header + Self.cellW * Double(c), 0), rec.P(Self.header + Self.cellW * Double(c), 2 * H)], .ink, width: Sketch.stroke) }
        for (c, t) in cols.enumerated() {
            let cx = Self.header + Self.cellW * Double(c) + Self.cellW / 2
            let upKnown = t != P.tM || filledM, acKnown = t <= 2 || t == P.tM || (t == P.tL && filledL) || (t == P.tP && filledP)
            let upLit = t == P.tM && filledM, acLit = (t == P.tL && filledL) || (t == P.tP && filledP)
            rec.word("tu\(t)\(upKnown)", upKnown ? "\(P.a * t)" : "?", at: cx, H / 2, upKnown ? R6.maths.colour(upLit ? .chapter : .ink) : R6.maths.colour(.ink3))
            rec.word("ta\(t)\(acKnown)", acKnown ? "\(P.b * t)" : "?", at: cx, H * 1.5, acKnown ? R6.maths.colour(acLit ? .chapter : .ink) : R6.maths.colour(.ink3))
        }
        // a hint: the column to work on ringed; a second miss, its point on the plane (or what the box holds)
        let col: Int? = at == 1 ? (mask & 1 == 0 ? 1 : 2) : at == 2 ? P.tL : at == 3 ? P.tM : at == 4 ? P.tP : at == 5 || at == 6 ? 1 : nil
        if let t = col, let c = cols.firstIndex(of: t), s.on("ring") {
            R6.ring(&rec, "ring\(t)", x: Self.header + Self.cellW * Double(c), y: 0, w: Self.cellW, h: 2 * H)
        }
        if s.on("spot") {
            switch at {
            case 1, 2, 3:
                let t = Double(col ?? 1), p = pl.at(b * t, a * t)
                pic.circle("spot", at: p.x, p.y, radius: 1.2, .chapter, dashed: true)
            case 4:
                if let c = cols.firstIndex(of: P.tP) {
                    rec.label("spotp", "\(P.tP) × \(P.b)", R6.lit, .below, edge: 2 * H + 0.2, along: Self.header + Self.cellW * (Double(c) + 0.5))
                }
            case 5:
                let p = pl.at(b / a, 1)
                pic.circle("spot", at: p.x, p.y, radius: 1.2, .chapter, dashed: true)
            case 6:
                rec.label("spotu", "\(P.b) ÷ \(P.a)", R6.lit, .below, edge: 2 * H + 0.2, along: Self.header + Self.cellW / 2)
            default: break
            }
        }
        // the written lines: the column past the paper, then 1
        let x = sx(P)
        if at >= 4 { M7.row(&rec, "sp", pastLine(P, done: at > 4), x: x, line: 1) }
        if at >= 6 { M7.row(&rec, "su", unitLine(P, done: at > 6), x: x, line: 4) }
    }

    private func drawCompare(_ s: PaperState, _ P: RatioTable.Parts, _ pl: R6.Plane, _ at: Int, _ held: (u: Double, v: Double)?,
                             _ pic: inout GridPen, _ live: inout GridPen, _ rec: inout GridPen) {
        let mask = Int(s.h("m") ?? 0), tables = [P.A, P.B], X = Double(P.X)
        for (i, t) in tables.enumerated() where at >= 8 || mask & (1 << i) != 0 {
            pl.mark(&pic, "pp\(i)", Double(t.b), Double(t.a), label: at < 8)
            if at >= 8 {
                let e = pl.ray(&pic, "ray\(i)", a: t.a, b: t.b)
                pic.word("rn\(i)", t.name, at: e.x + 0.6, e.y - 0.8, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            }
        }
        if at == 1, s.h("bad") == 1, let bu = s.h("bu"), let bv = s.h("bv") {
            pl.mark(&pic, "bad\(Int(bu))_\(Int(bv))", bu / 2, bv / 2, label: false, R6.red)
            pl.drops(&pic, "bd\(Int(bu))_\(Int(bv))", bu / 2, bv / 2, R6.red)
        }
        if at == 1, let h = held {
            let p = pl.at(h.u, h.v)
            R6.handle(&live, "cur", p.x, p.y, held: true)
            pl.drops(&live, "hd", h.u, h.v)
            live.word("hr", Ratio6.pair(h.u, h.v), at: p.x + 1, p.y + 1.3, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            live.reads(Ratio6.pair(h.u, h.v))
        }
        if at >= 8 {
            let b0 = pl.at(X, 0), t0 = pl.at(X, Double(RatioTable.up))
            pic.line("vx", [(b0.x, b0.y), (t0.x, t0.y)], .ink3, dashed: true)
            let v = at == 8 ? (s.h("sv") ?? 0) / 2 : Double(P.top)
            let passed = tables.filter { v >= Double(P.at($0)) }
            for t in passed {
                let c = pl.at(X, Double(P.at(t)))
                if at == 8 { live.dot("cx\(t.name)", at: c.x, c.y, radius: 0.45, .chapter, over: true) } else { pic.dot("cx\(t.name)", at: c.x, c.y, radius: 0.45, .chapter, over: true) }
            }
            let ro = passed.isEmpty ? "\(Ratio6.half(v)) \(P.nm(v))"
                : passed.enumerated().map { $0.offset == 0 ? "\($0.element.name) \(P.at($0.element)) \(P.nm(Double(P.at($0.element))))" : "\($0.element.name) \(P.at($0.element))" }.joined(separator: ", ")
            let hv = pl.at(X, v), ry = min(hv.y, pl.at(X, Double(P.top)).y) + 1.3
            if at == 8 {
                R6.handle(&live, "vh", hv.x, hv.y, held: s.grabbed)
                if s.grabbed || v > 0 { live.word("vro", ro, at: hv.x + 1.2, ry, R6.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
                if s.grabbed { live.reads(ro) }
                if s.on("ring") { R6.ring(&pic, "ringv", x: t0.x - 1, y: t0.y, w: 2, h: b0.y - t0.y) }
                if s.on("spot") { let c = pl.at(X, Double(P.top)); pic.circle("spot", at: c.x, c.y, radius: 1.2, .chapter, dashed: true) }
            } else {
                pic.word("vro", ro, at: hv.x + 1.2, ry, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            }
            // a hint while picking: where each line crosses, ringed
            if at == 9, s.on("ring") { for t in tables { let c = pl.at(X, Double(P.at(t))); pic.circle("pr\(t.name)", at: c.x, c.y, radius: 1, .chapter, dashed: true) } }
        }
        // a hint while placing: the table whose point is missing ringed; a second miss, its point
        if at == 1 {
            let i = mask & 1 == 0 ? 0 : 1
            if s.on("ring") { R6.ring(&rec, "ringt\(i)", x: Double(i) * 20, y: 0, w: 16, h: 2 * Self.rowH) }
            if s.on("spot") { let t = tables[i], p = pl.at(Double(t.b), Double(t.a)); pic.circle("spot", at: p.x, p.y, radius: 1.2, .chapter, dashed: true) }
        }
        // the two tables: their first two columns
        let H = Self.rowH
        for (i, t) in tables.enumerated() {
            let x0 = Double(i) * 20, tx = x0 + 8, right = tx + 8
            rec.word("th1\(i)", "\(t.name): \(P.S.up)", at: x0 + 0.5, H / 2, R6.small, anchor: UnitPoint(x: 0, y: 0.5))
            rec.word("th2\(i)", "minutes", at: x0 + 0.5, H * 1.5, R6.small, anchor: UnitPoint(x: 0, y: 0.5))
            for y in [0, H, 2 * H] { rec.rule("tl\(i)_\(y)", from: x0, to: right, row: y) }
            for x in [tx, tx + 4, tx + 8] { rec.sketch.line("tv\(i)_\(x)", [rec.P(x, 0), rec.P(x, 2 * H)], .ink, width: Sketch.stroke) }
            for (c, k) in [1, 2].enumerated() {
                rec.word("tu\(i)\(k)", "\(t.a * k)", at: tx + 4 * Double(c) + 2, H / 2, R6.maths)
                rec.word("ta\(i)\(k)", "\(t.b * k)", at: tx + 4 * Double(c) + 2, H * 1.5, R6.maths)
            }
        }
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let P = RatioTable.Parts(s.numbers), at = stage(s), pl = plane(P)
        let mask = Int(s.h("m") ?? 0)
        switch at {
        case 1:
            return Hands(
                grab: { q in
                    guard pl.holds(q) else { return nil }
                    let p = pl.snap(q)
                    return ["grab": 1, "m": Double(mask), "cu": Double(p.su), "cv": Double(p.sv)]
                },
                drag: { q, _ in let p = pl.snap(q); return ["grab": 1, "m": Double(mask), "cu": Double(p.su), "cv": Double(p.sv)] },
                release: { h in
                    let su = Int(h["cu"] ?? 0), sv = Int(h["cv"] ?? 0)
                    guard su != 0 || sv != 0 else { return HandMove(hand: ["m": Double(mask)], missHand: nil) }
                    let u = Double(su) / 2, v = Double(sv) / 2
                    // a column's point (a table's, in a compare): placed; the last one checks
                    let bit: Int? = P.compares
                        ? [P.A, P.B].firstIndex { t in [1, 2].contains { k in u == Double(t.b * k) && v == Double(t.a * k) } }
                        : [1, 2].first { u == Double(P.b * $0) && v == Double(P.a * $0) }.map { $0 - 1 }
                    if let bit {
                        let now = mask | (1 << bit)
                        if now == 3 { return HandMove(hand: ["m": 3], missHand: nil, set: [("x", Double(su * 100 + sv)), ("m", Double(mask))], check: true) }
                        return HandMove(hand: ["m": Double(now)], missHand: nil)
                    }
                    return HandMove(hand: ["m": Double(mask), "bad": 1, "bu": Double(su), "bv": Double(sv)], missHand: nil,
                                    set: [("x", Double(su * 100 + sv)), ("m", Double(mask))], check: true)
                })
        case 2, 3, 5:
            let start = Double(P.start(at)), j = s.h("j") ?? start, p = pl.at(j * Double(P.b) / 2, j * Double(P.a) / 2)
            let a = Double(P.a), b = Double(P.b), jmax = P.jmax
            return Hands(
                grab: { q in hypot(q.x - p.x, q.y - p.y) <= 2.5 ? ["grab": 1, "j": j] : nil },
                drag: { q, _ in
                    let u = (q.x - pl.ox) / pl.U, v = (pl.oy - q.y) / pl.U, t = (u * b + v * a) / (b * b + a * a)
                    return ["grab": 1, "j": Double(max(0, min(jmax, Int((t * 2).rounded()))))]
                },
                release: { h in
                    let k = h["j"] ?? start
                    guard k != start else { return HandMove(hand: ["j": start], missHand: nil) }
                    return HandMove(hand: ["j": k], missHand: ["j": start], set: [("x", k)], check: true)
                })
        case 8:
            let sv = s.h("sv") ?? 0, p = pl.at(Double(P.X), sv / 2)
            return Hands(
                grab: { q in hypot(q.x - p.x, q.y - p.y) <= 2.5 ? ["grab": 1, "sv": sv] : nil },
                drag: { q, _ in ["grab": 1, "sv": Double(pl.snap(CGPoint(x: pl.ox, y: q.y)).sv)] },
                release: { h in
                    let v = h["sv"] ?? 0
                    guard v > 0 else { return HandMove(hand: ["sv": 0], missHand: nil) }
                    return HandMove(hand: ["sv": v], missHand: nil, set: [("x", v)], check: true)
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = RatioTable.Parts(s.numbers), at = stage(s), pl = plane(P), mask = Int(s.h("m") ?? 0)
        let a = Double(P.a), b = Double(P.b)
        switch at {
        case 1:
            // a tap-and-drag from the corner to each point still to place
            let targets: [CGPoint] = P.compares
                ? [P.A, P.B].enumerated().filter { mask & (1 << $0.offset) == 0 }.map { pl.at(Double($0.element.b), Double($0.element.a)) }
                : [1, 2].filter { mask & (1 << ($0 - 1)) == 0 }.map { pl.at(b * Double($0), a * Double($0)) }
            return targets.map { .drag(from: pl.at(0.5, 0.5), to: $0) }
        case 2, 3, 5:
            let j0 = Double(s.h("j") ?? Double(P.start(at)))
            let target: Double = at == 2 ? 2 * Double(P.tL) : at == 3 ? 2 * Double(P.tM) : 2 / a
            return [.drag(from: pl.at(j0 * b / 2, j0 * a / 2), to: pl.at(target * b / 2, target * a / 2))]
        case 8:
            return [.drag(from: pl.at(Double(P.X), (s.h("sv") ?? 0) / 2), to: pl.at(Double(P.X), Double(P.top)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = RatioTable.Parts(s.numbers), at = stage(s)
        switch at {
        case 1:
            // the pair swapped: minutes up, laps across
            let t = P.compares ? P.A : RatioTable.Table(name: "", a: P.a, b: P.b), su = 2 * t.a, sv = 2 * t.b
            return HandMove(hand: ["m": s.h("m") ?? 0, "bad": 1, "bu": Double(su), "bv": Double(sv)], missHand: nil,
                            set: [("x", Double(su * 100 + sv)), ("m", s.h("m") ?? 0)], check: true)
        case 2, 3, 5:
            let start = Double(P.start(at)), right: Double = at == 2 ? 2 * Double(P.tL) : at == 3 ? 2 * Double(P.tM) : 2 / Double(P.a)
            let k = right + 1 <= Double(P.jmax) && right + 1 != start ? right + 1 : right - 1
            return HandMove(hand: ["j": k], missHand: ["j": start], set: [("x", k)], check: true)
        case 8:
            return HandMove(hand: ["sv": 2], missHand: nil, set: [("x", 2)], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = RatioTable.Parts(s.numbers)
        switch stage(s) {
        // the adding pattern: as many more minutes as laps
        case 4: return ["x": Double(P.b * 2 + (P.a * P.tP - P.a * 2))]
        case 6: return P.a == 1 ? ["w": Double(P.b + 1)] : ["w": 1, "n": 1, "d": Double(P.b)]
        default: return nil
        }
    }

    func messageRows(_ n: Numbers) -> Int { 1 }
}
