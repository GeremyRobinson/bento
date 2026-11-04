import SwiftUI

/// Shapes on the plane, as in the preview (design/prototype/grade6-ch4.html, dShape): the plane as Points in four
/// quadrants'; two corners of a rectangle drawn with their pairs. Drag a point from 0 to each of the other two corners
/// (the sides draw in as each lands); drag along the top from corner to corner (crossing the y-axis splits the count,
/// "4 + 5"); then the record beside the plane: the other side `|3| + |−2| = [5]`, and the area or the perimeter, each
/// line short enough to sit beside the plane so the problem shows at 75%.
@MainActor
struct PlaneShapesLesson: PaperLesson {
    static let Pl = QuadrantsLesson.Pl
    var liveKeys: Set<String> { ["u", "v", "br"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The top's count sits over it, or inside the shape when the top is near the x-axis's numbers or the plane's top.
    static func level(_ P: Shapes6.Parts) -> (top: Double, lev: Double, dn: Double) {
        let topY = Pl.at(0, Double(P.y2)).y, dn: Double = (P.y2 < 0 && topY - Pl.oy < 5) || P.y2 >= Neg6.Y - 1 ? -1 : 1
        // half a unit off the top when the y-axis has a number a unit away, so the bracket passes between its numbers
        let near = (P.y2 + Int(dn)) % 2 == 0
        return (topY, topY - (near ? 1 : 1.6) * dn, dn)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Shapes6.Parts(s.numbers), at = stage(s), Pl = Self.Pl, done = at >= 5
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let cs = P.corners.map { Pl.at(Double($0.u), Double($0.v)) }
        Pl.draw(&pic, "pl", avoid: cs)
        // the corners there, and the sides between them as they come
        let placed = at >= 2 ? [2, 3] : [2, 3].filter { s.h("c\($0)") != nil }
        let known = [0, 1] + placed
        for (a, b) in [(0, 1), (1, 2), (2, 3), (3, 0)] where known.contains(a) && known.contains(b) {
            pic.line("sd\(a)\(b)", [(cs[a].x, cs[a].y), (cs[b].x, cs[b].y)], .chapter)
        }
        for j in known {
            // beside the corner on the outside, or on the inside near the plane's left and right ends (so the plane and
            // the record beside it show at 75%)
            let c = P.corners[j], p = cs[j], below = c.v == P.y1, right = abs(c.u) >= 10 ? c.u < 0 : c.u == P.x2
            pic.dot("c\(j)", at: p.x, p.y, radius: 0.45, .chapter, over: true)
            pic.word("cl\(j)", Neg6.pair(Double(c.u), Double(c.v)), at: p.x + (right ? 0.8 : -0.8), p.y + (below ? 1.5 : -1.3), N6.small,
                     anchor: UnitPoint(x: right ? 0 : 1, y: 0.5))
        }
        // the corner being placed: from 0, its dotted lines and pair while it moves
        if at <= 1 {
            let u = s.h("u") ?? 0, v = s.h("v") ?? 0, p = Pl.at(u, v), shown = s.grabbed || s.h("u") != nil
            if shown && (u != 0 || v != 0) { Pl.drops(&live, "d0", u, v) }
            N6.point(&live, "pt", p, held: s.grabbed)
            if shown { live.word("pr", Neg6.pair(u, v), at: p.x + (u < 0 ? -0.4 : 0.4), p.y + (v > 0 ? -1.3 : 1.4), N6.lit, anchor: UnitPoint(x: u < 0 ? 1 : 0, y: 0.5)) }
            if s.grabbed { live.reads(Neg6.pair(u, v)) }
        }
        // the count along the top: split at the y-axis when it crosses it
        let (topY, lev, dn) = Self.level(P)
        func piece(_ pen: inout GridPen, _ id: String, _ a: Int, _ b: Int, _ label: String?) {
            let p = Pl.at(Double(a), Double(P.y2)), q = Pl.at(Double(b), Double(P.y2))
            pen.line(id, [(p.x, topY - 0.6 * dn), (p.x, lev), (q.x, lev), (q.x, topY - 0.6 * dn)], .chapter)
            guard a != b, let label else { return }
            var mx = (p.x + q.x) / 2
            let half = R6.width(label, N6.lit) / 2 + 1
            if abs(mx - Pl.ox) < half + 2.5 { mx = Pl.ox + half + 0.5 }
            pen.word(id + "w", label, at: mx, lev - 0.8 * dn, N6.lit)
        }
        if at == 2, s.grabbed, let br = s.h("br").map({ Int($0) }), let from = s.h("from").map({ Int($0) }) {
            if from * br < 0 { piece(&live, "ma", from, 0, "\(abs(from))"); piece(&live, "mb", 0, br, "\(abs(br))"); live.reads("\(abs(from)) + \(abs(br))") }
            else { piece(&live, "ma", from, br, "\(abs(br - from))"); live.reads("\(abs(br - from))") }
        }
        if at >= 3 { piece(&pic, "tp", P.x1, P.x2, P.topCount) }
        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        if at == 1 {
            let y = Pl.at(0, Double(P.y1)).y
            if s.on("ring") { R6.ring(&pic, "ring", x: Pl.ox - Pl.width + 1, y: y - 1, w: 2 * Pl.width - 2, h: 2) }
            if s.on("spot") { for j in [2, 3] where !placed.contains(j) { pic.circle("spot\(j)", at: cs[j].x, cs[j].y, radius: 1.3, .chapter, dashed: true) } }
        }
        if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: cs[0].x, y: cs[0].y - 1, w: cs[1].x - cs[0].x, h: 2) }
        if at == 2 && s.on("spot") { for j in [0, 1] { pic.circle("spot\(j)", at: cs[j].x, cs[j].y, radius: 1.3, .chapter, dashed: true) } }
        if at == 3 && s.on("ring") { R6.ring(&pic, "ring", x: cs[0].x - 1, y: cs[0].y, w: 2, h: cs[3].y - cs[0].y) }
        if at == 3 && s.on("spot") {
            for (k, j) in [(0, 0), (1, 3)] { let y = cs[j].y; pic.circle("spot\(k)", at: Pl.ox - 1.8, y, radius: 1.4, .chapter, dashed: true) }
        }
        if at == 4 && s.on("ring") { R6.ring(&pic, "ring", x: cs[0].x, y: cs[0].y, w: cs[1].x - cs[0].x, h: cs[3].y - cs[0].y) }

        // the record beside the plane, each line short: the side, then the area or the perimeter
        if at >= 3 {
            let (fa, fb) = P.sideTerms
            let side: M7.Tok = at == 3 ? .box("h", cells: 2) : .n(P.h, .chapter)
            M7.row(&rec, "rs", [.t("|\(fmt(Double(fa)))|"), .op(P.crossY ? "+" : "−"), .t("|\(fmt(Double(fb)))|"), .op("="), side], x: 0, line: 1)
        }
        if at >= 4 {
            let total: M7.Tok = done ? .n(P.total, .chapter) : .box("A", cells: max(3, String(P.total).count))
            if P.perim {
                M7.row(&rec, "rp", [.w("Perimeter"), .op("=")], x: 0, line: 4)
                M7.row(&rec, "rq", [.n(P.w), .op("+"), .n(P.h), .op("+"), .n(P.w), .op("+"), .n(P.h)], x: 0, line: 7)
                M7.row(&rec, "rr", [.op("="), total], x: 0, line: 10)
            } else {
                M7.row(&rec, "ra", [.w("Area"), .op("="), .n(P.w), .op("×"), .n(P.h)], x: 0, line: 4)
                M7.row(&rec, "rb", [.op("="), total], x: 0, line: 7)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, Pl.oy - Pl.height - 0.5, Pl.ox + Pl.width + 2.5, 2 * Pl.height + 1))
    }

    /// The record beside the plane, from near its top.
    func recordBeside(_ n: Numbers) -> Double? { Self.Pl.oy - Self.Pl.height + 1 }

    func hands(_ s: PaperState) -> Hands? {
        let P = Shapes6.Parts(s.numbers), at = stage(s), Pl = Self.Pl
        switch at {
        case 1:
            let u0 = s.h("u") ?? 0, v0 = s.h("v") ?? 0
            var base = s.hand
            for k in ["grab", "u", "v", "fu", "fv"] { base[k] = nil }
            return Hands(grab: { q in
                let p = Pl.at(u0, v0)
                guard hypot(q.x - p.x, q.y - p.y) <= 2.5 else { return nil }
                var h = base; h["grab"] = 1; h["u"] = u0; h["v"] = v0; h["fu"] = u0; h["fv"] = v0; return h
            }, drag: { q, h in
                let sn = Pl.snap(q); var h = h; h["u"] = sn.u.rounded(); h["v"] = sn.v.rounded(); return h
            }, release: { h in
                let u = h["u"] ?? 0, v = h["v"] ?? 0
                var b = base
                if u == h["fu"] && v == h["fv"] { b["u"] = u; b["v"] = v; return HandMove(hand: b, missHand: nil) }
                if let j = [2, 3].first(where: { Double(P.corners[$0].u) == u && Double(P.corners[$0].v) == v && b["c\($0)"] == nil }) {
                    b["c\(j)"] = 1
                    let n = [2, 3].filter { b["c\($0)"] != nil }.count
                    return n == 2 ? HandMove(hand: b, missHand: b, set: [("x", 2)], check: true) : HandMove(hand: b)
                }
                b["u"] = u; b["v"] = v
                return HandMove(hand: b, missHand: b, set: [("x", Neg6.corner(Int(u), Int(v)))], check: true)
            })
        case 2:
            return Hands(grab: { q in
                guard let k = [0, 1].first(where: { let c = Pl.at(Double(P.corners[$0].u), Double(P.corners[$0].v)); return hypot(q.x - c.x, q.y - c.y) < 2.2 }) else { return nil }
                let from = Double(P.corners[k].u)
                return ["grab": 1, "from": from, "br": from]
            }, drag: { q, h in
                var h = h; h["br"] = min(Double(P.x2), max(Double(P.x1), ((q.x - Pl.ox) / Pl.U).rounded())); return h
            }, release: { h in
                let from = h["from"] ?? 0, to = h["br"] ?? from
                if to == from { return HandMove(hand: [:]) }
                let other = from == Double(P.x1) ? Double(P.x2) : Double(P.x1)
                return HandMove(hand: [:], missHand: [:], set: [("x", to == other ? Double(P.w) : -1)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Shapes6.Parts(s.numbers), Pl = Self.Pl
        switch stage(s) {
        case 1:
            var from = Pl.at(s.h("u") ?? 0, s.h("v") ?? 0)
            var out: [GhostMove] = []
            for j in [2, 3] where s.h("c\(j)") == nil {
                let to = Pl.at(Double(P.corners[j].u), Double(P.corners[j].v))
                out.append(.drag(from: from, to: to)); from = Pl.at(0, 0)
            }
            return out
        case 2: return [.drag(from: Pl.at(Double(P.x1), Double(P.y2)), to: Pl.at(Double(P.x2), Double(P.y2)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Shapes6.Parts(s.numbers)
        switch stage(s) {
        case 1:
            let u = P.x2, v = P.y1 + 1 == 0 ? P.y1 + 2 : P.y1 + 1
            return HandMove(hand: ["u": Double(u), "v": Double(v)], missHand: ["u": Double(u), "v": Double(v)], set: [("x", Neg6.corner(u, v))], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("x", -1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Shapes6.Parts(s.numbers)
        switch stage(s) {
        case 3: return ["h": Double(P.crossY ? abs(abs(P.y2) - abs(P.y1)) : abs(P.y1) + abs(P.y2))]
        case 4: return ["A": Double(P.perim ? P.w * P.h : 2 * (P.w + P.h))]
        default: return nil
        }
    }
}
