import SwiftUI

/// Area of a triangle on the paper, as in the preview (design/prototype/grade6-ch7.html, dTri): the triangle from the
/// picture's top, its base on a grid line, its top over one end, over the base or past its end (`p`), its base and height
/// named (the height dashed with its square corner where it stands inside or past the base); a copy turned half a turn
/// waits beside it, dashed, in its stronger shade. Drag the copy against the slanted side: it snaps when it fits, and the
/// two make a b by h rectangle at once, or a parallelogram whose end is cut straight down and slid back (the
/// parallelogram's own move, played). The record beside: `6 × 4 = [24]`, then `24 ÷ 2 = [12] square units`.
///
/// Two squares a unit when the triangle and its copy fit that way. Hand keys: "grab", "g0x", "g0y", "ox", "oy".
@MainActor
struct TriLesson: PaperLesson {
    var liveKeys: Set<String> { ["grab", "ox", "oy"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }

    struct Shape {
        let P: Tri6.Parts
        init(_ n: Numbers) { P = Tri6.Parts(n) }
        var b: Double { Double(P.b) }
        var h: Double { Double(P.h) }
        var p: Double { Double(P.p) }
        var W: Double { max(b, p) }
        /// Two squares a unit when the triangle, its copy waiting and the record beside show that way at 75%, else one.
        var U: Double { max((2 * W + 2) * 2 + 4.5, rx(2) + 28.5) <= 71 && h <= 12 ? 2 : 1 }
        func rx(_ u: Double) -> Double { (((P.p < P.b ? b + p : p) * u + 2) / 5).rounded(.up) * 5 }
        /// Where the copy's turning point waits, and where it fits.
        var wait: CGPoint { CGPoint(x: 2 * W + (U == 1 ? 1 : 2), y: h) }
        var target: CGPoint { CGPoint(x: P.p < P.b ? b + p : p, y: h) }
        /// How far the end past the base is cut off (0: a rectangle at once).
        var sig: Double { P.p < P.b ? p : p - b }
        func X(_ x: Double) -> Double { x * U }
        func sq(_ pts: [(Double, Double)]) -> [CGPoint] { pts.map { CGPoint(x: $0.0 * U, y: $0.1 * U) } }
        var tri: [(Double, Double)] { [(0, h), (b, h), (p, 0)] }
        func copy(_ O: CGPoint) -> [(Double, Double)] { tri.map { (O.x - $0.0, O.y - $0.1) } }
        /// The record's column: on a block line past the rectangle (or the copy, while it waits).
        var rx: Double { rx(U) }
        func line(_ i: Int) -> Double { 1 + 3 * Double(i) }
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers), at = stage(s)
        return at == 2 || at == 3 ? CGPoint(x: S.rx, y: S.line(at - 2) + 2) : at >= 4 ? CGPoint(x: S.rx, y: S.line(1) + 2) : nil
    }
    func keysFocus(_ s: PaperState) -> CGRect? { let S = Shape(s.numbers); return CGRect(x: 0, y: 0, width: S.X(S.b), height: S.X(S.h)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), U = S.U, b = S.b, h = S.h, p = S.p
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if at <= 1 {
            let t = S.sq(S.tri)
            A7.shape(&pic, "tri", t); A7.faint(&pic, "trif", t, U: U)
            // the copy: waiting, or following the hand a unit at a time
            let O = CGPoint(x: S.wait.x + (s.h("ox") ?? 0), y: S.wait.y + (s.h("oy") ?? 0))
            if s.grabbed { A7.shape(&live, "copy", S.sq(S.copy(O)), fill: A7.strong, dashed: true) }
            else { A7.shape(&pic, "copy", S.sq(S.copy(S.wait)), fill: A7.strong, dashed: true) }
            pic.label("bl", "\(P.b)", A7.words, .below, edge: S.X(h), along: S.X(b / 2))
            if P.p > 0 && P.p < P.b {
                A7.height(&pic, "hh", x: S.X(p), from: 0, to: S.X(h), toward: 1)
                pic.label("hl", "\(P.h)", A7.words, .right, edge: S.X(p) + 0.2, along: S.X(h / 2))
            } else if P.p > P.b {
                A7.height(&pic, "hh", x: S.X(p), from: 0, to: S.X(h), toward: -1)
                pic.line("hb", [(S.X(b), S.X(h)), (S.X(p), S.X(h))], .ink2, dashed: true)
                pic.label("hl", "\(P.h)", A7.words, .right, edge: S.X(p), along: S.X(h / 2))
            } else { pic.label("hl", "\(P.h)", A7.words, P.p == 0 ? .left : .right, edge: S.X(p), along: S.X(h / 2)) }
            if at == 1 && s.on("ring") { A7.ring(&pic, "ring", x: S.X(S.wait.x - S.W), y: 0, w: S.X(S.W), h: S.X(h)) }
            if at == 1 && s.on("spot") { A7.shape(&pic, "spot", S.sq(S.copy(S.target)), fill: nil, dashed: true) }
        } else {
            // the two as one shape: the part left of the base's end stays; a parallelogram's end is cut straight down
            // there and slides back a base's length (played as Area of a parallelogram's move)
            let sig = S.sig
            let stay: [(Double, Double)] = sig > 0 ? [(0, h), (b, h), (b, 0), (sig, 0)] : [(0, h), (b, h), (b, 0), (0, 0)]
            A7.shape(&pic, "stay", S.sq(stay)); A7.faint(&pic, "stayf", S.sq(stay), U: U)
            if sig > 0 {
                let from = S.sq([(b, h), (b + sig, 0), (b, 0)]), to = S.sq([(0, h), (sig, 0), (0, 0)])
                pic.sketch.delay = 0.7
                for (id, k) in [("mvf", Sketch.Kind.fill(from.map { pic.P($0.x, $0.y) })), ("mvo", .line((from + [from[0]]).map { pic.P($0.x, $0.y) }, width: Sketch.stroke, dashed: false))] { pic.sketch.from[id] = k }
                pic.sketch.polygon("mvf", to.map { pic.P($0.x, $0.y) }, A7.fill)
                pic.sketch.line("mvo", (to + [to[0]]).map { pic.P($0.x, $0.y) }, .chapter, width: Sketch.stroke)
                pic.sketch.from = [:]; pic.sketch.delay = 0
                A7.faint(&pic, "mvfaint", to, U: U)
            }
            // where the copy met the triangle, dashed
            if P.p < P.b || sig == 0 {
                let s0: (Double, Double) = P.p < P.b ? (b, h) : (0, h)
                pic.line("seam", [(S.X(s0.0), S.X(s0.1)), (S.X(p), 0)], .chapter, dashed: true)
            } else {
                let yb = h * (1 - b / p)
                pic.line("seamA", [(0, S.X(h)), (S.X(b), S.X(yb))], .chapter, dashed: true)
                pic.line("seamB", [(S.X(0), S.X(yb)), (S.X(p - b), 0)], .chapter, dashed: true)
            }
            pic.label("bl", "\(P.b)", A7.words, .below, edge: S.X(h), along: S.X(b / 2))
            pic.label("hl2", "\(P.h)", A7.words, .left, edge: -0.2, along: S.X(h / 2))
            if at == 2 && s.on("ring") { A7.ring(&pic, "ring", x: 0, y: 0, w: S.X(b), h: S.X(h)) }
            if at == 2 && s.on("spot") { pic.word("spot", "\(P.h) rows of \(P.b)", at: S.X(b / 2), S.X(h / 2), A7.lit) }
            if at == 3 && s.on("ring") { R6.ring(&rec, "ring", x: S.rx, y: S.line(0) - 1, w: 12, h: 2) }
        }
        // the record beside
        func val(_ v: Int, _ step: Int) -> M7.Tok { at == step ? .box("x", cells: max(2, "\(v)".count)) : .n(v, .chapter) }
        if at >= 2 { M7.row(&rec, "r1", [.n(P.b), .op("×"), .n(P.h), .op("="), val(P.R, 2)], x: S.rx, line: S.line(0)) }
        if at >= 3 { M7.row(&rec, "r2", [.n(P.R), .op("÷"), .n(2), .op("="), val(P.A, 3), .w("square units")], x: S.rx, line: S.line(1)) }
        let room = pic.R(-2.5, 0, max(S.X(S.wait.x) + 2, S.rx + 26) + 2.5, S.X(h) + 2)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: room)
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), U = S.U
        guard stage(s) == 1 else { return nil }
        let waiting = S.sq(S.copy(S.wait))
        return Hands(grab: { q in
            A7.inside(waiting, q) ? ["grab": 1, "g0x": q.x, "g0y": q.y, "ox": 0, "oy": 0] : nil
        }, drag: { q, hd in
            var hd = hd
            hd["ox"] = ((q.x - (hd["g0x"] ?? q.x)) / U).rounded(); hd["oy"] = ((q.y - (hd["g0y"] ?? q.y)) / U).rounded()
            return hd
        }, release: { hd in
            let O = CGPoint(x: S.wait.x + (hd["ox"] ?? 0), y: S.wait.y + (hd["oy"] ?? 0))
            if abs(O.x - S.target.x) <= 1 && abs(O.y - S.target.y) <= 1 { return HandMove(hand: [:], set: [("f", 1)], check: true) }
            return (hd["ox"] ?? 0) == 0 && (hd["oy"] ?? 0) == 0 ? HandMove(hand: [:]) : HandMove(hand: [:], set: [("f", 0)], check: true)
        })
    }
    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers)
        guard stage(s) == 1 else { return [] }
        let m = A7.centroid(S.sq(S.copy(S.wait)))
        return [.drag(from: m, to: CGPoint(x: m.x + S.X(S.target.x - S.wait.x), y: m.y))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? { stage(s) == 1 ? HandMove(hand: [:], set: [("f", 0)], check: true) : nil }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Tri6.Parts(s.numbers)
        switch stage(s) { case 2: return ["x": Double(P.b + P.h)]; case 3: return ["x": Double(P.R)]; default: return nil }
    }
}
