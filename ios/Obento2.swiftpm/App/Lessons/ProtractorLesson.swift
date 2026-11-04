import SwiftUI

/// Measuring angles on the paper, as in the preview (design/prototype/grade4-ch8.html): the corner on a grid point, the
/// first arm along a grid line pointing right or left, arms 18 squares; the protractor (radius 15) resting beside it.
/// Measure: drag the protractor on; it snaps only with its centre on the corner (its edge along the first arm), the
/// scale whose 0 is on that arm lit and its 0 ringed; then read where the other arm crosses and type it. Draw: the
/// protractor already on, turn the free arm (it snaps to whole degrees; the bar reads "65°" on the first arm's scale).
///
/// The picture's squares: the corner at (18, 18); the protractor rests 2 squares past the arms; the record under them.
@MainActor
struct ProtractorLesson: PaperLesson {
    typealias Pt = Geo4.Pt
    static let ARM = 18.0, PR = 15.0
    static let C = Pt(18, 18), rest = Pt(18 + 18 + 2 + 15, 18)
    var liveKeys: Set<String> { ["px", "py", "v"] }

    private func scr(_ p: Protractor4.Parts, _ v: Double) -> Double { p.left ? 180 - v : v }

    func draw(_ s: PaperState) -> PaperDrawing {
        let p = Protractor4.Parts(s.numbers), at = G8.stage(s), C = Self.C, ARM = Self.ARM, done = at >= 3
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed, a0 = p.left ? 180.0 : 0, use = p.left ? "L" : "R"
        let laid = p.draw || at >= 2
        if laid { G8.protractor(&pic, "pr", C, Self.PR, use: use) }
        G8.seg(&pic, "arm1", C, Geo4.pol(C, ARM, a0))
        if p.draw {
            let v = done ? Double(p.deg) : s.h("v") ?? 0, a2 = scr(p, v)
            var pen = held ? live : pic
            G8.wedge(&pen, "wd\(Int(v))", C, 5, min(a0, a2), max(a0, a2))
            G8.seg(&pen, "arm2\(Int(v))", C, Geo4.pol(C, ARM, a2), done ? .chapter : .ink)
            if held { live = pen } else { pic = pen }
            if at == 1 {
                let h = Geo4.pol(C, ARM, a2)
                live.dot("ha", at: h.x, h.y, radius: held ? 0.75 : 0.55, .ink, over: true)
                if held && v > 0 { live.reads("\(Int(v))°") }
                // a hint after a second miss: where the free arm stops
                if s.on("spot") { let g = Geo4.pol(C, ARM, scr(p, Double(p.deg))); pic.circle("spot", at: g.x, g.y, radius: 1.5, .chapter, dashed: true) }
            }
        } else {
            let a2 = scr(p, Double(p.deg))
            G8.arc(&pic, "ang", C, 3, min(a0, a2), max(a0, a2), .ink2)
            G8.seg(&pic, "arm2", C, Geo4.pol(C, ARM, a2))
        }
        pic.dot("C", at: C.x, C.y, radius: 0.35, .ink, over: true)
        if !laid {
            let c = Pt(s.h("px") ?? Self.rest.x, s.h("py") ?? Self.rest.y)
            if held { G8.protractor(&live, "prr", c, Self.PR, use: nil) } else { G8.protractor(&pic, "prr", c, Self.PR, use: nil) }
            if at == 1 && s.on("spot") { pic.circle("spot", at: C.x, C.y, radius: 1.5, .chapter, dashed: true) }
        }
        // a hint on the reading: after a miss, the lit scale's 0 is ringed already; after a second, where the arm crosses
        if at == 2 && s.on("spot") { let g = Geo4.pol(C, Self.PR - (p.left ? 4.1 : 2.3), scr(p, Double(p.deg))); pic.circle("spot", at: g.x, g.y, radius: 1.5, .chapter, dashed: true) }

        if at == 2 { M7.row(&rec, "rec", [.w("angle"), .op("="), .box("R", cells: 3), .op("°")], x: 0, line: 2) }
        if done { M7.row(&rec, "rec", [.w("angle"), .op("="), .t("\(p.deg)°", .chapter)], x: 0, line: 2) }
        let right = p.draw ? C.x + ARM : Self.rest.x + Self.PR
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, right, C.y))
    }

    func recordRow(_ n: Numbers) -> Double? { Self.C.y + 1 }

    func hands(_ s: PaperState) -> Hands? {
        let p = Protractor4.Parts(s.numbers), C = Self.C, at = G8.stage(s)
        if at == 1 && !p.draw {
            let c = Pt(s.h("px") ?? Self.rest.x, s.h("py") ?? Self.rest.y)
            return Hands(grab: { q in
                G8.onProtractor(G8.pt(q), c, Self.PR) ? ["grab": 1, "ox": q.x - c.x, "oy": q.y - c.y, "px": c.x, "py": c.y, "fx": c.x, "fy": c.y] : nil
            }, drag: { q, h in
                var h = h; h["px"] = q.x - (h["ox"] ?? 0); h["py"] = q.y - (h["oy"] ?? 0); return h
            }, release: { h in
                let to = Pt(h["px"] ?? c.x, h["py"] ?? c.y)
                if Geo4.dist(to, Pt(h["fx"] ?? c.x, h["fy"] ?? c.y)) < 0.5 { return HandMove(hand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [("p", Geo4.dist(to, C) <= 2.5 ? 1 : 0)], check: true)
            })
        }
        if at == 1 && p.draw {
            let v = s.h("v") ?? 0
            return Hands(grab: { q in
                let h = Geo4.pol(C, Self.ARM, scr(p, v))
                return hypot(q.x - h.x, q.y - h.y) <= 2.2 ? ["grab": 1, "v": v, "v0": v] : nil
            }, drag: { q, h in
                var a = Geo4.angOf(C, G8.pt(q))
                if a > 180 { a = a > 270 ? 0 : 180 }
                var h = h; h["v"] = min(180, max(0, (p.left ? 180 - a : a).rounded())); return h
            }, release: { h in
                let v2 = h["v"] ?? 0
                if v2 == 0 || v2 == h["v0"] { return HandMove(hand: ["v": v2]) }
                return HandMove(hand: ["v": v2], missHand: ["v": v2], set: [("a", v2)], check: true)
            })
        }
        return nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let p = Protractor4.Parts(s.numbers), C = Self.C
        guard G8.stage(s) == 1 else { return [] }
        if p.draw {
            let v = s.h("v") ?? 0, a = Geo4.pol(C, Self.ARM, scr(p, v)), b = Geo4.pol(C, Self.ARM, scr(p, Double(p.deg)))
            return [.drag(from: CGPoint(x: a.x, y: a.y), to: CGPoint(x: b.x, y: b.y))]
        }
        let c = Pt(s.h("px") ?? Self.rest.x, s.h("py") ?? Self.rest.y)
        return [.drag(from: CGPoint(x: c.x, y: c.y - 3), to: CGPoint(x: C.x, y: C.y - 3))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = Protractor4.Parts(s.numbers)
        guard G8.stage(s) == 1 else { return nil }
        if p.draw { let v = Double(180 - p.deg); return HandMove(hand: ["v": v], missHand: ["v": v], set: [("a", v)], check: true) }
        return HandMove(hand: [:], missHand: [:], set: [("p", 0)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        G8.stage(s) == 2 ? ["R": Double(180 - Protractor4.Parts(s.numbers).deg)] : nil
    }
}
