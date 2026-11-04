import SwiftUI

/// Points in four quadrants on the paper, as in the preview (design/prototype/grade6-ch4.html, dQuad): the plane, two
/// squares a unit, −12 to 12 across and −7 to 7 up, the quadrants' numbers small in their corners. Drag the point from 0
/// to the pair (dotted lines drop to both axes as it moves, its pair beside it); later problems fold the half with it
/// over an axis (or both, one at a time): the half turns over the axis, prints the point's mirror, and lies back; then
/// `([−3], [−5])` is written beside the plane. The last kind picks the quadrant from the signs.
@MainActor
struct QuadrantsLesson: PaperLesson {
    static let Pl = N6.Plane(ox: 25, oy: Double(Neg6.Y) * 2 + 2)
    var liveKeys: Set<String> { ["u", "v", "th", "fx", "fy"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The fold over an axis ("x": the x-axis, a line across) lifting the half a point (u, v) is on.
    static func fold(_ axis: Int, _ u: Double, _ v: Double) -> N6.Fold {
        let P = Pl
        return axis == 1 ? N6.Fold(vertical: false, at: P.oy, mid: P.ox, side: v > 0 ? -1 : 1) : N6.Fold(vertical: true, at: P.ox, mid: P.oy, side: u < 0 ? -1 : 1)
    }
    static func sheet(_ f: N6.Fold) -> CGRect {
        let P = Pl, ex = P.width + 0.5, ey = P.height + 0.5
        return f.vertical ? CGRect(x: min(P.ox, P.ox + f.side * ex), y: P.oy - ey, width: ex, height: 2 * ey)
            : CGRect(x: P.ox - ex, y: min(P.oy, P.oy + f.side * ey), width: 2 * ex, height: ey)
    }
    static func mirror(_ axis: Int, _ m: (Double, Double)) -> (Double, Double) { axis == 1 ? (m.0, -m.1) : (-m.0, m.1) }
    /// The axes folded so far, in order (1 the x-axis, 2 the y-axis).
    static func axes(_ P: Quadrants6.Parts, _ kept: Numbers, upTo at: Int) -> [Int] {
        var out: [Int] = []
        guard !P.want.isEmpty else { return out }
        if at >= 3, P.kind != 3 || kept["ax1"] != nil { out.append(P.kind == 3 ? Int(kept["ax1"] ?? 1) : P.want[0] == "x" ? 1 : 2) }
        if at >= 4, P.kind == 3 { out.append(3 - (out.first ?? 1)) }
        return out
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Quadrants6.Parts(s.numbers), at = stage(s), Pl = Self.Pl, kept = s.run.kept
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let placing = at <= 1, done = at >= 6
        // the folds landed: each the half the point was on then, and how far it had turned when let go
        let axes = Self.axes(P, kept, upTo: at)
        var landed: [(f: N6.Fold, th: Double)] = [], cur = (P.x, P.y), prints: [(Double, Double)] = []
        for (i, a) in axes.enumerated() {
            landed.append((Self.fold(a, cur.0, cur.1), kept["th\(i + 1)"] ?? .pi * 0.75))
            cur = Self.mirror(a, cur); prints.append(cur)
        }
        let foldNow = (at == 2 || at == 3), held = foldNow && s.grabbed && s.h("ax") != nil
        let heldFold = held ? Self.fold(Int(s.h("ax") ?? 1), cur.0, cur.1).with(side: s.h("sd") ?? 1) : nil
        let back = foldNow && !s.grabbed ? s.h("back").map { th in (Self.fold(Int(s.h("ax") ?? 1), cur.0, cur.1).with(side: s.h("sd") ?? 1), th) } : nil
        let lifting = landed.map(\.f) + [heldFold, back?.0].compactMap { $0 }
        func base(_ p: CGPoint) -> Bool { !lifting.contains { $0.lifted(p) } }
        let bad = foldNow ? s.h("bad").map { Self.mirror(Int($0), cur) } : nil
        let avoid = ((placing ? [] : [(P.x, P.y)]) + prints + (bad.map { [$0] } ?? [])).map { Pl.at($0.0, $0.1) }

        func content(_ pen: inout GridPen, _ keep: (CGPoint) -> Bool) {
            Pl.draw(&pen, "pl", keep: keep, avoid: avoid)
            if !placing {
                let p = Pl.at(P.x, P.y)
                if keep(p) {
                    if axes.isEmpty { Pl.drops(&pen, "d0", P.x, P.y) }
                    N6.point(&pen, "pt", p)
                    Pl.pair(&pen, "pr", P.x, P.y)
                }
            }
            for (j, m) in prints.enumerated() {
                let q = Pl.at(m.0, m.1)
                guard keep(q) else { continue }
                N6.point(&pen, "pp\(j)", q, shade: 1)
                let lit = at == 4 && s.on("spot") && j == prints.count - 1
                Pl.pair(&pen, "ppr\(j)\(lit)", m.0, m.1, lit ? N6.lit : N6.quiet)
            }
        }
        content(&pic, base)
        for (j, l) in landed.enumerated() {
            N6.flap(&pic, "fl\(j)", l.f, rect: Self.sheet(l.f), th: 0, from: l.th, gridTop: s.gridTop) { content(&$0) { l.f.lifted($0) } }
        }
        if let (f, th) = back { N6.flap(&pic, "fb", f, rect: Self.sheet(f), th: 0, from: th, gridTop: s.gridTop) { content(&$0) { f.lifted($0) } } }
        if let f = heldFold {
            N6.flap(&live, "fh", f, rect: Self.sheet(f), th: s.h("th") ?? 0, gridTop: s.gridTop) { content(&$0) { f.lifted($0) } }
            let m = Self.mirror(Int(s.h("ax") ?? 1), cur)
            live.reads(Neg6.pair(m.0, m.1))
        }
        // a fold over the wrong axis: where it printed, in red
        if let b = bad { N6.point(&pic, "bp\(b.0)_\(b.1)", Pl.at(b.0, b.1), shade: 1, R6.red) }
        // the point being placed: from 0, dotted lines dropping to both axes as it moves, its pair beside it
        if placing {
            let u = s.h("u") ?? 0, v = s.h("v") ?? 0, p = Pl.at(u, v), shown = s.grabbed || s.h("u") != nil
            if shown { Pl.drops(&live, "d0", u, v) }
            N6.point(&live, "pt", p, held: s.grabbed)
            if shown { live.word("pr", Neg6.pair(u, v), at: p.x + (u < 0 ? -0.4 : 0.4), p.y + (v > 0 ? -1.3 : 1.4), N6.lit, anchor: UnitPoint(x: u < 0 ? 1 : 0, y: 0.5)) }
            if s.grabbed { live.reads(Neg6.pair(u, v)) }
        }
        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let o = Pl.at(0, 0)
        if at == 1 {
            if s.on("ring") {
                // the quadrant it's in
                let x0 = P.x < 0 ? Pl.ox - Pl.width + 1 : Pl.ox + 1.5, y0 = P.y > 0 ? Pl.oy - Pl.height + 1 : Pl.oy + 2.5
                R6.ring(&pic, "ring", x: x0, y: y0, w: Pl.width - 4, h: Pl.height - 4)
            }
            if s.on("spot") { let p = Pl.at(P.x, P.y); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        }
        if foldNow {
            let want = at == 3 ? 3 - (axes.first ?? 1) : P.kind == 3 ? 1 : (P.want[0] == "x" ? 1 : 2)
            if s.on("ring") && !held {
                // the axis to fold over
                if want == 1 { R6.ring(&pic, "ring", x: Pl.ox - Pl.width + 1, y: Pl.oy - 0.5, w: 2 * Pl.width - 2, h: 1) }
                else { R6.ring(&pic, "ring", x: Pl.ox - 0.5, y: Pl.oy - Pl.height, w: 1, h: 2 * Pl.height) }
            }
            if s.on("spot") { let m = Self.mirror(want, cur), p = Pl.at(m.0, m.1); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        }
        if at == 4 && s.on("ring"), let m = prints.last { let p = Pl.at(m.0, m.1); pic.circle("ring", at: p.x, p.y, radius: 2.6, .chapter, dashed: true) }
        if at == 5 && s.on("ring") { R6.ring(&pic, "ring", x: o.x - 1, y: o.y - 1, w: 2, h: 2) }
        if at == 5 && s.on("spot") {
            let x = Pl.ox + (P.x > 0 ? 1 : -1) * (Pl.width - 3), y = Pl.oy - (P.y > 0 ? 1 : -1) * (Pl.height - 2.5)
            pic.circle("spot", at: x, y, radius: 1.5, .chapter, dashed: true)
        }
        // the record beside the plane: ([−3], [−5])
        if !P.want.isEmpty && at >= 4 {
            let a = P.ans
            let bx: (String, Double) -> M7.Tok = { id, v in done ? .t(Neg6.fm(v), .chapter) : .box(id, cells: max(2, Neg6.fm(v).count)) }
            M7.row(&rec, "rec", [.op("("), bx("x", a.x), .op(","), bx("y", a.y), .op(")")], x: 0, line: 1)
        }
        if P.kind == 5 && done { M7.row(&rec, "q", [.w("quadrant", .chapter), .w(Quadrants6.quads[Quadrants6.quadrant(P.x, P.y)], .chapter)], x: 0, line: 1) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, Pl.oy - Pl.height - 0.5, Pl.ox + Pl.width + 2.5, 2 * Pl.height + 1))
    }

    /// Keys up for the pair: the point and where the folds printed it stay in the frame with the line being typed.
    func keysFocus(_ s: PaperState) -> CGRect? {
        let P = Quadrants6.Parts(s.numbers)
        var pts = [(P.x, P.y)], cur = (P.x, P.y)
        for a in Self.axes(P, s.run.kept, upTo: stage(s)) { cur = Self.mirror(a, cur); pts.append(cur) }
        let q = pts.map { Self.Pl.at($0.0, $0.1) }
        let x0 = q.map(\.x).min()! - 6, x1 = q.map(\.x).max()! + 6, y0 = q.map(\.y).min()! - 2, y1 = q.map(\.y).max()! + 2
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    /// The record beside the plane, level with the x-axis.
    func recordBeside(_ n: Numbers) -> Double? { Self.Pl.oy - 1 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        stage(s) == 5 ? CGPoint(x: 55, y: Self.Pl.oy - 9) : nil
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Quadrants6.Parts(s.numbers), at = stage(s), Pl = Self.Pl, kept = s.run.kept
        switch at {
        case 1:
            let u0 = s.h("u") ?? 0, v0 = s.h("v") ?? 0
            return Hands(grab: { q in
                let p = Pl.at(u0, v0)
                return hypot(q.x - p.x, q.y - p.y) <= 2.5 ? ["grab": 1, "u": u0, "v": v0, "fu": u0, "fv": v0] : nil
            }, drag: { q, h in
                let sn = Pl.snap(q); var h = h; h["u"] = sn.u; h["v"] = sn.v; return h
            }, release: { h in
                let u = h["u"] ?? 0, v = h["v"] ?? 0
                if u == h["fu"] && v == h["fv"] { return HandMove(hand: ["u": u, "v": v], missHand: nil) }
                return HandMove(hand: ["u": u, "v": v], missHand: nil, set: [("x", u), ("y", v)], check: true)
            })
        case 2, 3:
            let axes = Self.axes(P, kept, upTo: at)
            var cur = (P.x, P.y)
            for a in axes { cur = Self.mirror(a, cur) }
            let first = axes.first, second = at == 3
            return Hands(grab: { q in Pl.holds(q) ? ["grab": 1, "fx": q.x, "fy": q.y] : nil },
                         drag: { q, h in
                var h = h
                if h["ax"] == nil, let fx = h["fx"], let fy = h["fy"] {
                    let dx = q.x - fx, dy = q.y - fy
                    guard hypot(dx, dy) >= 1 else { return h }
                    // dragged up or down: a fold over the x-axis; across: over the y-axis; the half where it started
                    let ax = abs(dy) > abs(dx) ? 1 : 2, at = ax == 1 ? Pl.oy : Pl.ox, from = ax == 1 ? fy : fx
                    var d = from - at
                    if abs(d) < 0.5 { d = (ax == 1 ? q.y : q.x) - at }
                    guard abs(d) >= 0.5 else { return h }
                    h["ax"] = Double(ax); h["sd"] = d > 0 ? 1 : -1; h["g"] = abs(d)
                }
                if let ax = h["ax"] { h["th"] = Self.fold(Int(ax), 0, 0).with(side: h["sd"] ?? 1).angle(q, grab: h["g"] ?? 1) }
                return h
            }, release: { h in
                guard let ax = h["ax"].map({ Int($0) }) else { return HandMove(hand: [:]) }
                let th = h["th"] ?? 0, sd = h["sd"] ?? 1
                if th < 0.05 { return HandMove(hand: [:]) }
                let backs: Numbers = ["back": th, "sd": sd, "ax": Double(ax)]
                guard th > 1.75 else { return HandMove(hand: backs) }
                let f = Self.fold(ax, cur.0, cur.1)
                // the half without the point
                if f.side != sd { return HandMove(hand: backs, missHand: backs, set: [("f", 0)], check: true) }
                let code: Double
                if second { code = ax == first ? (ax == 1 ? 3 : 4) : 1 } else { code = Double(ax) }
                let right = second ? code == 1 : (P.kind == 3 || (P.want[0] == "x") == (ax == 1))
                if right {
                    let keep: Numbers = second ? ["th2": th] : ["th1": th, "ax1": Double(ax)]
                    return HandMove(hand: [:], missHand: [:], set: [("f", code)], keep: keep, check: true)
                }
                var miss = backs; miss["bad"] = Double(ax)
                return HandMove(hand: miss, missHand: miss, set: [("f", code)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Quadrants6.Parts(s.numbers), Pl = Self.Pl, at = stage(s)
        switch at {
        case 1: return [.drag(from: Pl.at(s.h("u") ?? 0, s.h("v") ?? 0), to: Pl.at(P.x, P.y))]
        case 2, 3:
            let axes = Self.axes(P, s.run.kept, upTo: at)
            var cur = (P.x, P.y)
            for a in axes { cur = Self.mirror(a, cur) }
            let ax = at == 3 ? 3 - (axes.first ?? 1) : P.kind == 3 ? 1 : (P.want[0] == "x" ? 1 : 2)
            let p = Pl.at(cur.0, cur.1), m = Self.mirror(ax, cur), q = Pl.at(m.0, m.1)
            return [.drag(from: p, to: q)]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Quadrants6.Parts(s.numbers)
        switch stage(s) {
        case 1: return HandMove(hand: ["u": P.y, "v": P.x], missHand: nil, set: [("x", P.y), ("y", P.x)], check: true)
        case 2:
            if P.kind == 3 { return HandMove(hand: [:], missHand: [:], set: [("f", 0)], check: true) }
            let ax = P.want[0] == "x" ? 2 : 1, f = Self.fold(ax, P.x, P.y)
            let miss: Numbers = ["back": 2.4, "sd": f.side, "ax": Double(ax), "bad": Double(ax)]
            return HandMove(hand: miss, missHand: miss, set: [("f", Double(ax))], check: true)
        case 3:
            let ax = Int(s.run.kept["ax1"] ?? 1)
            let miss: Numbers = ["back": 2.4, "sd": 1, "ax": Double(ax)]
            return HandMove(hand: miss, missHand: miss, set: [("f", ax == 1 ? 3 : 4)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Quadrants6.Parts(s.numbers)
        return stage(s) == 4 ? ["x": P.ans.x, "y": -P.ans.y] : nil
    }
}

extension N6.Fold {
    func with(side s: Double) -> N6.Fold { var f = self; f.side = s; return f }
}
