import SwiftUI

/// Angles and degrees on the paper, as in the preview (design/prototype/grade4-ch8.html): a circle of radius 16 squares
/// round a corner on a grid point, a tick every 10°, longer every 90°; a fixed arm along the grid line to the right and a
/// second on it to turn. Drag the arm round: it snaps every 5°, the angle between the arms shading, and when it's a part
/// with a 4th grade bottom the circle's dashed cuts show it (the bar says "1/4 turn: 90°" while the finger is down).
/// Then the degrees are typed: 1/4 of 360° = [90]°. The clock: the circle as a clock face, the minute hand snapping to
/// the numbers (the bar: "4 × 30° = 120°").
///
/// The picture's squares: the circle's centre at (16, 16); the record beside it or under it.
@MainActor
struct TurnsLesson: PaperLesson {
    typealias Pt = Geo4.Pt
    static let O = Pt(16, 16), R = 16.0
    var liveKeys: Set<String> { ["raw", "v", "last"] }

    private func armAt(_ p: Turns4.Parts, _ v: Double) -> Double { p.clock ? 90 - v : v }

    func draw(_ s: PaperState) -> PaperDrawing {
        let p = Turns4.Parts(s.numbers), at = G8.stage(s), O = Self.O, R = Self.R, done = at >= 3
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed
        let v = at >= 2 ? Double(p.ans) : s.h("v") ?? 0, a1 = armAt(p, v)
        var pen = held ? live : pic
        G8.wedge(&pen, "wd\(Int(v))", O, R, p.clock ? a1 : 0, p.clock ? 90 : v)
        if held { live = pen } else { pic = pen }
        G8.arc(&pic, "circ", O, R, 0, 360, .ink)
        if p.clock {
            for h in 1...12 {
                let a = 90 - 30 * Double(h)
                G8.seg(&pic, "ck\(h)", Geo4.pol(O, R, a), Geo4.pol(O, R - 1.2, a), .ink2)
                let q = Geo4.pol(O, R - 3, a)
                pic.word("cn\(h)", "\(h)", at: q.x, q.y, G8.say)
            }
            G8.seg(&pic, "arm0", O, Geo4.pol(O, 11, 90), .ink3)
            var pen = held ? live : pic
            G8.seg(&pen, "arm1\(Int(v))", O, Geo4.pol(O, 11, a1), done ? .chapter : .ink)
            if held { live = pen } else { pic = pen }
            if at == 1 { let h = Geo4.pol(O, 11, a1); live.dot("hh", at: h.x, h.y, radius: held ? 0.75 : 0.55, .ink, over: true) }
            if held && v > 0 { live.reads("\(Int(v) / 30) × 30° = \(Int(v))°") }
        } else {
            var t1: [(CGPoint, CGPoint)] = [], t9: [(CGPoint, CGPoint)] = []
            for d in stride(from: 0, to: 360, by: 10) {
                let a = Double(d), s = (G8.cg(pic, Geo4.pol(O, R, a)), G8.cg(pic, Geo4.pol(O, R - (d % 90 == 0 ? 1.6 : 0.8), a)))
                if d % 90 == 0 { t9.append(s) } else { t1.append(s) }
            }
            pic.sketch.segments("tk", t1, .ink3, width: Sketch.stroke)
            pic.sketch.segments("tk9", t9, .ink2, width: Sketch.stroke)
            var pen = held ? live : pic
            if let part = Turns4.part(Int(v)) {
                for j in 1..<part.1 { G8.seg(&pen, "cut\(part.1)_\(j)", O, Geo4.pol(O, R, 360 * Double(j) / Double(part.1)), .ink3, dashed: true) }
            }
            G8.seg(&pen, "arm1\(Int(v))", O, Geo4.pol(O, R, a1), done ? .chapter : .ink)
            if v > 0 { G8.arc(&pen, "ar\(Int(v))", O, 4, 0, v) }
            if held { live = pen } else { pic = pen }
            G8.seg(&pic, "arm0", O, Geo4.pol(O, R, 0))
            if at == 1 { let h = Geo4.pol(O, R, a1); live.dot("hh", at: h.x, h.y, radius: held ? 0.75 : 0.55, .ink, over: true) }
            if held && v > 0 { live.reads(Turns4.part(Int(v)).map { "\($0.0)/\($0.1) turn: \(Int(v))°" } ?? "\(Int(v))°") }
        }
        pic.dot("O", at: O.x, O.y, radius: 0.35, .ink, over: true)
        // a hint after a second miss: where the arm stops
        if at == 1 && s.on("spot") {
            let g = Geo4.pol(O, p.clock ? 11 : R, armAt(p, Double(p.ans)))
            pic.circle("spot", at: g.x, g.y, radius: 1.6, .chapter, dashed: true)
        }

        // the record
        let box: [M7.Tok] = [.box("R", cells: 3), .op("°")]
        let lead: [M7.Tok] = [.f(p.n, p.d), .w("of"), .t("360°"), .op("=")]
        if at == 2 { M7.row(&rec, "rec", p.clock ? box : lead + box, x: 0, line: 2) }
        if done {
            let sum: [M7.Tok] = p.clock ? [.n(p.h), .op("×"), .t("30°")]
                : lead + (p.n == 1 ? [.t("360°"), .op("÷"), .n(p.d)] : [.n(p.n), .op("×"), .t("\(360 / p.d)°")])
            M7.row(&rec, "rec", sum + [.op("="), .t("\(p.ans)°", .chapter)], x: 0, line: 2)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, 2 * R, 2 * R))
    }

    func recordBeside(_ n: Numbers) -> Double? { 6 }

    func hands(_ s: PaperState) -> Hands? {
        guard G8.stage(s) == 1 else { return nil }
        let p = Turns4.Parts(s.numbers), O = Self.O, v = s.h("v") ?? 0
        return Hands(grab: { c in
            let tip = Geo4.pol(O, p.clock ? 11 : Self.R, armAt(p, v))
            guard hypot(c.x - tip.x, c.y - tip.y) <= 2.4 else { return nil }
            return ["grab": 1, "raw": v, "v": v, "v0": v, "last": Geo4.angOf(O, G8.pt(c))]
        }, drag: { c, h in
            let a = Geo4.angOf(O, G8.pt(c)), dA = Geo4.adiff(a, h["last"] ?? a)
            var h = h
            let raw = min(360, max(0, (h["raw"] ?? 0) + (p.clock ? -dA : dA))), step = p.clock ? 30.0 : 5
            h["raw"] = raw; h["last"] = a; h["v"] = (raw / step).rounded() * step
            return h
        }, release: { h in
            let v2 = h["v"] ?? 0
            if v2 == 0 || v2 == h["v0"] { return HandMove(hand: ["v": v2]) }
            return HandMove(hand: ["v": v2], missHand: ["v": v2], set: [("t", v2)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard G8.stage(s) == 1 else { return [] }
        let p = Turns4.Parts(s.numbers), O = Self.O, r = p.clock ? 11 : Self.R, v = s.h("v") ?? 0
        // round the circle, 10° at a time, so the arm turns the way the finger goes
        let to = Double(p.ans), n = max(1, Int((abs(to - v) / 10).rounded(.up)))
        let pts = (0...n).map { k -> CGPoint in let q = Geo4.pol(O, r, armAt(p, v + (to - v) * Double(k) / Double(n))); return CGPoint(x: q.x, y: q.y) }
        return [.path(pts)]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard G8.stage(s) == 1 else { return nil }
        let p = Turns4.Parts(s.numbers)
        let v = Double(p.clock ? (p.h == 11 ? 300 : p.ans + 30) : (p.ans == 120 ? 90 : 120))
        return HandMove(hand: ["v": v], missHand: ["v": v], set: [("t", v)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = Turns4.Parts(s.numbers)
        return G8.stage(s) == 2 ? ["R": Double(360 - p.ans)] : nil
    }
}
