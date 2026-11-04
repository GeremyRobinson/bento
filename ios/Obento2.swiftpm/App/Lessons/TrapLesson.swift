import SwiftUI

/// Area of a trapezoid on the paper, as in the preview (design/prototype/grade6-ch7.html, dTrap): the web's right
/// trapezoid from the picture's top (bottom a, top b, its left side upright with a square corner), its sides named, and
/// its copy beside it, dashed, in the stronger shade. Picked up, the copy swings half a turn on the spring (the web's
/// motion; it turns in 3D about its middle, PaperStand.swift); slid against the slanted side it snaps, and the two make
/// a rectangle a + b long, its second names in. The record beside: `4 + 8 = [12]`, `12 × 5 = [60]`, `60 ÷ 2 = [30] square
/// units`.
///
/// Hand keys: "grab", "g0x", "g0y", "dx", "dy" (the copy moved, in units), "turned".
@MainActor
struct TrapLesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy", "grab"] }
    var solid: Bool { true }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }

    struct Shape {
        let P: Trap6.Parts
        init(_ n: Numbers) { P = Trap6.Parts(n) }
        var a: Double { Double(P.a) }
        var b: Double { Double(P.b) }
        var h: Double { Double(P.h) }
        var W: Double { max(a, b) }
        var U: Double { P.S <= 20 && P.h <= 12 ? 2 : 1 }
        func X(_ x: Double) -> Double { x * U }
        func sq(_ pts: [(Double, Double)]) -> [CGPoint] { pts.map { CGPoint(x: $0.0 * U, y: $0.1 * U) } }
        var trap: [(Double, Double)] { [(0, h), (a, h), (b, 0), (0, 0)] }
        /// The copy waiting beside it (unturned), moved by (dx, dy) units.
        func waiting(_ dx: Double, _ dy: Double) -> [(Double, Double)] { trap.map { ($0.0 + W + 2 + dx, $0.1 + dy) } }
        /// Turned half a turn about its middle.
        func turned(_ dx: Double, _ dy: Double) -> [(Double, Double)] { trap.map { (2 * W + 2 - $0.0 + dx, h - $0.1 + dy) } }
        /// Where the turned copy fits: its offset.
        var fit: (Double, Double) { (a + b - (2 * W + 2), 0) }
        var rx: Double { ((X(a + b) + 3) / 5).rounded(.up) * 5 }
        func line(_ i: Int) -> Double { 1 + 3 * Double(i) }
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers), at = stage(s)
        return at >= 2 ? CGPoint(x: S.rx, y: S.line(min(at - 2, 2)) + 2) : nil
    }
    func keysFocus(_ s: PaperState) -> CGRect? { let S = Shape(s.numbers); return CGRect(x: 0, y: 0, width: S.X(S.a + S.b), height: S.X(S.h)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), U = S.U, a = S.a, b = S.b, h = S.h
        var pic = GridPen(), rec = GridPen(), solids = Solids()
        let t = S.sq(S.trap)
        A7.shape(&pic, "trap", t); A7.faint(&pic, "trapf", t, U: U)
        // the square corner on its upright side
        pic.line("rc", [(0.6, S.X(h)), (0.6, S.X(h) - 0.6), (0, S.X(h) - 0.6)], .ink2)
        pic.label("ba", "\(P.a)", A7.words, .below, edge: S.X(h), along: S.X(a / 2))
        pic.label("bb", "\(P.b)", A7.words, .above, edge: 0, along: S.X(b / 2))
        pic.label("hh", "\(P.h)", A7.words, .left, edge: 0, along: S.X(h / 2))
        if at <= 1 {
            // the copy: a flat face on the paper, turning about its middle as it's picked up, moved a unit at a time
            let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0, on = (s.h("turned") ?? 0) != 0
            let pts = S.waiting(dx, dy).map { Vec3($0.0 * U, $0.1 * U, 0) }
            let c = Vec3((S.W + 2 + S.W / 2 + dx) * U, (h / 2 + dy) * U, 0)
            solids.faces.append(Solids.Face(id: "copy", pts: pts, look: .paint(A7.strong), edges: true, hinge: (c, c + Vec3(0, 0, 1)), angle: on ? 180 : 0, dashed: true))
            if at == 1 && s.on("ring") { A7.ring(&pic, "ring", x: S.X(S.W + 2), y: 0, w: S.X(S.W), h: S.X(h)) }
            if at == 1 && s.on("spot") { A7.shape(&pic, "spot", S.sq(S.turned(S.fit.0, S.fit.1)), fill: nil, dashed: true) }
        } else {
            let cp = S.sq(S.turned(S.fit.0, S.fit.1))
            A7.shape(&pic, "copy2", cp); A7.faint(&pic, "copy2f", cp, U: U)
            pic.line("seam", [(S.X(a), S.X(h)), (S.X(b), 0)], .chapter, dashed: true)
            pic.label("ba2", "\(P.b)", A7.words, .below, edge: S.X(h), along: S.X(a + b / 2))
            pic.label("bb2", "\(P.a)", A7.words, .above, edge: 0, along: S.X(b + a / 2))
            if at == 2 && s.on("ring") { A7.ring(&pic, "ring", x: 0, y: S.X(h) - 1, w: S.X(a + b), h: 3) }
            if at == 3 && s.on("ring") { A7.ring(&pic, "ring", x: 0, y: 0, w: S.X(a + b), h: S.X(h)) }
            if at == 4 && s.on("ring") { R6.ring(&rec, "ring", x: S.rx, y: S.line(1) - 1, w: 12, h: 2) }
        }
        func val(_ v: Int, _ step: Int) -> M7.Tok { at == step ? .box("x", cells: max(2, "\(v)".count)) : .n(v, .chapter) }
        if at >= 2 { M7.row(&rec, "r1", [.n(P.a), .op("+"), .n(P.b), .op("="), val(P.S, 2)], x: S.rx, line: S.line(0)) }
        if at >= 3 { M7.row(&rec, "r2", [.n(P.S), .op("×"), .n(P.h), .op("="), val(P.P, 3)], x: S.rx, line: S.line(1)) }
        if at >= 4 { M7.row(&rec, "r3", [.n(P.P), .op("÷"), .n(2), .op("="), val(P.A, 4), .w("square units")], x: S.rx, line: S.line(2)) }
        let room = pic.R(-2.5, -2, max(S.X(2 * S.W + 2) + 2, S.rx + 27) + 2.5, S.X(h) + 4)
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes, extent: room, solids: solids)
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), U = S.U
        guard stage(s) == 1 else { return nil }
        let on = (s.h("turned") ?? 0) != 0, now = S.sq(on ? S.turned(0, 0) : S.waiting(0, 0))
        return Hands(grab: { q in
            A7.inside(now, q) ? ["grab": 1, "turned": 1, "g0x": q.x, "g0y": q.y, "dx": 0, "dy": 0] : nil
        }, drag: { q, hd in
            var hd = hd
            hd["dx"] = ((q.x - (hd["g0x"] ?? q.x)) / U).rounded(); hd["dy"] = ((q.y - (hd["g0y"] ?? q.y)) / U).rounded()
            return hd
        }, release: { hd in
            let dx = hd["dx"] ?? 0, dy = hd["dy"] ?? 0
            if abs(dx - S.fit.0) <= 1 && abs(dy - S.fit.1) <= 1 { return HandMove(hand: [:], set: [("f", 1)], check: true) }
            return dx == 0 && dy == 0 ? HandMove(hand: ["turned": 1]) : HandMove(hand: ["turned": 1], missHand: ["turned": 1], set: [("f", 0)], check: true)
        })
    }
    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers)
        guard stage(s) == 1 else { return [] }
        let m = A7.centroid(S.sq(S.waiting(0, 0)))
        return [.drag(from: m, to: CGPoint(x: m.x + S.X(S.fit.0), y: m.y))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? { stage(s) == 1 ? HandMove(hand: ["turned": 1], missHand: ["turned": 1], set: [("f", 0)], check: true) : nil }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Trap6.Parts(s.numbers)
        switch stage(s) { case 2: return ["x": Double(P.a * P.b)]; case 3: return ["x": Double(P.S + P.h)]; case 4: return ["x": Double(P.P)]; default: return nil }
    }
}
