import SwiftUI

/// Area and perimeter on the paper, as in the preview (design/prototype/grade4-ch7.html): a square meter is one block (5 ×
/// 5 squares, its sides the paper's strong lines), the rectangle's top-left corner on a strong line, its sides named
/// (`5 m` over the top, `3 m` down the left). Drag the corner out: it snaps to meters, the blocks inside counting, live
/// "5 by 3: 15 square meters"; type the area. Trace one long side and one short side (they light as the finger runs
/// along them, live "5 m + 3 m = 8 m"); type it; the other two sides light on round the edge, and the perimeter is typed.
/// A rectangle too big to show at 75% takes 2 squares to a meter (the picture says so). From index 6, the area or the
/// perimeter may be given with one side: drag the free side, or trace half the way round, and type the missing side.
@MainActor
struct AreaPerimLesson: PaperLesson {
    /// The rectangle's top, on a strong line; the given area or perimeter's row.
    static let Y0 = 5.0, givenRow = 1.0
    var liveKeys: Set<String> { ["t"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct Q {
        let p: AreaPerim.Parts
        var U: Double { Double(p.U) }
        /// How far the corner may go (one meter past the rectangle), and the side the trace may run down.
        var maxA: Int { min(15, p.l + 1) }
        var maxB: Int { min(10, p.w + 1) }
        var sideB: Int { p.fold == 2 ? maxB : p.w }
        var maxT: Int { p.fold == 2 ? p.l + maxB : 2 * p.l + p.w }
        /// Where the traced edge's tip is, t meters round from the top-left corner.
        func tip(_ t: Int) -> CGPoint {
            let a = p.l, b = sideB, U = self.U, Y0 = AreaPerimLesson.Y0
            if t <= a { return CGPoint(x: U * Double(t), y: Y0) }
            if t <= a + b { return CGPoint(x: U * Double(a), y: Y0 + U * Double(t - a)) }
            return CGPoint(x: U * Double(a - (t - a - b)), y: Y0 + U * Double(b))
        }
        /// The edge lit from the corner round to t.
        func path(_ t: Int) -> [CGPoint] {
            var pts = [tip(0)]
            for c in [p.l, p.l + sideB, 2 * p.l + sideB] where t > c { pts.append(tip(c)) }
            pts.append(tip(t))
            return pts
        }
        /// The other half, round from the bottom-right corner to the top-left.
        var rest: [CGPoint] {
            let U = self.U, Y0 = AreaPerimLesson.Y0, X = U * Double(p.l), Y = Y0 + U * Double(p.w)
            return [CGPoint(x: X, y: Y), CGPoint(x: 0, y: Y), CGPoint(x: 0, y: Y0)]
        }
    }

    /// The rectangle's sides now, in meters (nil: not drawn yet).
    private func size(_ s: PaperState, _ q: Q) -> (Int, Int)? {
        let p = q.p, at = stage(s)
        switch p.fold {
        case 1: return at >= 6 ? (p.l, p.w) : (Int((s.h("a") ?? 1).rounded()), p.w)
        case 2: return at >= 6 ? (p.l, p.w) : nil
        default: return at >= 2 ? (p.l, p.w) : (Int((s.h("a") ?? 1).rounded()), Int((s.h("b") ?? 1).rounded()))
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(p: AreaPerim.Parts(s.numbers)), p = q.p, at = stage(s), U = q.U, Y0 = Self.Y0, l = Double(p.l), w = Double(p.w)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let words = Record.words, done = at >= 7
        let held = s.grabbed

        // the rectangle (live while the hand makes it), its blocks counted while it's made
        if let (a, b) = size(s, q) {
            var pen = held ? live : pic
            let A = Double(a), B = Double(b)
            pen.fill("in", col: 0, row: Y0, w: U * A, h: U * B, .tint(0.2))
            if U == 2 {
                var segs: [(CGPoint, CGPoint)] = []
                for i in 1..<max(1, a) { segs.append((pen.P(U * Double(i), Y0), pen.P(U * Double(i), Y0 + U * B))) }
                for j in 1..<max(1, b) { segs.append((pen.P(0, Y0 + U * Double(j)), pen.P(U * A, Y0 + U * Double(j)))) }
                pen.sketch.segments("m\(a)_\(b)", segs, .tint(0.45), width: 1)
            }
            let counting = p.U == 5 && (p.fold == 1 ? at <= 1 || at == 6 : p.fold == 0 && at <= 2)
            if counting {
                for r in 0..<b { for c in 0..<a { pen.word("bn\(r)_\(c)", "\(r * a + c + 1)", at: U * (Double(c) + 0.5), Y0 + U * (Double(r) + 0.5), Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)) } }
            }
            pen.sketch.box("ro", pen.R(0, Y0, U * A, U * B), .ink, width: Sketch.stroke)
            if held { live = pen } else { pic = pen }
        } else {
            pic.rule("top", from: 0, to: U * l, row: Y0)
        }

        // the traced edge, lit; then the other two sides light on round the edge
        let band = Sketch.Colour.tint(0.7), bandW = 12.0
        if at == 3 {
            let t = Int((s.h("t") ?? 0).rounded())
            if t > 0 { live.sketch.line("lit", q.path(t).map { live.P($0.x, $0.y) }, band, width: bandW) }
            live.dot("ht", at: q.tip(t).x, q.tip(t).y, radius: held ? 0.75 : 0.55, .ink, over: true)
            if held && t > 0 { live.reads(p.traced(t)) }
            if s.on("spot") { pic.circle("ring", at: q.tip(p.l + p.w).x, q.tip(p.l + p.w).y, radius: 1.3, .chapter, dashed: true) }
        }
        let traced = (p.fold == 0 && at >= 4) || (p.fold == 2 && at >= 6)
        if traced {
            pic.sketch.line("half", q.path(p.l + p.w).map { pic.P($0.x, $0.y) }, band, width: bandW)
            if at >= 5 { pic.sketch.line("rest", q.rest.map { pic.P($0.x, $0.y) }, band, width: bandW) }
        }

        // the hands' handles: the corner, or the free side
        if at == 1, let (a, b) = size(s, q) {
            if p.fold == 1 { live.dot("he", at: U * Double(a), Y0 + U * w / 2, radius: held ? 0.75 : 0.55, .ink, over: true) }
            else { live.dot("hc", at: U * Double(a), Y0 + U * Double(b), radius: held ? 0.75 : 0.55, .ink, over: true) }
            if held { live.reads(p.fold == 1 ? "\(p.w) × \(a) = \(p.w * a)" : "\(a) by \(b): \(a * b) square \(a * b == 1 ? "meter" : "meters")") }
            if s.on("spot") {
                if p.fold == 1 { pic.circle("ring", at: U * l, Y0 + U * w / 2, radius: 1.3, .chapter, dashed: true) }
                else { pic.circle("ring", at: U * l, Y0 + U * w, radius: 1.3, .chapter, dashed: true) }
            }
        }

        // the problem, as the picture's names; the side found named in the chapter's colour at the end
        if p.fold != 1 || done { pic.label("lt", "\(p.l) m", words.colour(p.fold == 1 ? .chapter : .ink), .above, edge: Y0, along: U * l / 2) }
        if p.fold != 2 || done { pic.label("ll", "\(p.w) m", words.colour(p.fold == 2 ? .chapter : .ink), .left, edge: 0, along: Y0 + U * w / 2) }
        if p.fold == 1 { M7.row(&pic, "given", [.w("Area"), .op("="), .n(p.A), .w("m²")], x: 0, line: Self.givenRow) }
        if p.fold == 2 { M7.row(&pic, "given", [.w("Perimeter"), .op("="), .n(p.Pm), .w("m")], x: 0, line: Self.givenRow) }
        // a smaller picture says what a square is
        if p.U < 5 {
            let bottom = Y0 + U * Double(max(p.w, at == 1 ? size(s, q)?.1 ?? p.w : p.w))
            pic.word("unit", p.unitLine, at: 0, bottom + 1.5, Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), anchor: UnitPoint(x: 0, y: 0.5))
        }

        // the record
        var rows: [[M7.Tok]] = []
        func box(_ id: String, _ v: Int) -> M7.Tok { .box(id, cells: max(2, String(v).count)) }
        let c: Sketch.Colour = done ? .chapter : .ink
        switch p.fold {
        case 1:
            if at == 6 { rows.append([.n(p.w), .op("×"), box("R", p.l), .op("="), .n(p.A)]) }
            if done { rows.append([.w("Area"), .op("="), .n(p.w), .op("×"), .n(p.l, .chapter), .op("="), .n(p.A), .w("m²")]) }
        case 2:
            if at == 6 { rows.append([.n(p.l), .op("+"), box("R", p.w), .op("="), .n(p.Pm / 2)]) }
            if done { rows.append([.w("Perimeter"), .op("="), .n(2), .op("×"), .op("("), .n(p.l), .op("+"), .n(p.w, .chapter), .op(")"), .op("="), .n(p.Pm), .w("m")]) }
        default:
            if at >= 2 { rows.append([.w("Area"), .op("="), .n(p.l), .op("×"), .n(p.w), .op("=")] + (at == 2 ? [box("A", p.A)] : [.n(p.A, c)]) + [.w("m²", c)]) }
            if at == 4 { rows.append([.n(p.l), .op("+"), .n(p.w), .op("="), box("H", p.l + p.w)]) }
            if at == 5 { rows.append([.n(2), .op("×"), .n(p.l + p.w), .op("="), box("Q", p.Pm), .w("m")]) }
            if done { rows.append([.w("Perimeter"), .op("="), .n(2), .op("×"), .op("("), .n(p.l), .op("+"), .n(p.w), .op(")"), .op("="), .n(p.Pm, .chapter), .w("m", .chapter)]) }
        }
        for (i, r) in rows.enumerated() { M7.row(&rec, "r\(i)", r, x: 0, line: 2 + 3 * Double(i)) }

        // room for the rectangle to grow, so the camera frames it before the hand gets there
        let reach = pic.R(0, 0, U * Double(p.fold == 2 ? p.l : q.maxA) + 1, Y0 + U * Double(max(p.w, p.fold == 0 ? q.maxB : p.fold == 2 ? q.maxB : p.w)) + 1)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: reach)
    }

    func recordRow(_ n: Numbers) -> Double? {
        let q = Q(p: AreaPerim.Parts(n)), p = q.p
        // under the rectangle as it ends up (the room the corner had to grow is gone by then)
        return Self.Y0 + q.U * Double(p.w) + (p.U < 5 ? 3 : 2)
    }
    func recordBeside(_ n: Numbers) -> Double? { Self.Y0 - 1 }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(p: AreaPerim.Parts(s.numbers)), p = q.p, U = q.U, Y0 = Self.Y0, at = stage(s)
        func near(_ c: CGPoint, _ x: Double, _ y: Double) -> Bool { abs(c.x - x) <= 2.5 && abs(c.y - y) <= 2.5 }
        if at == 1 && p.fold == 0 {
            let a = s.h("a") ?? 1, b = s.h("b") ?? 1
            return Hands(grab: { c in near(c, U * a, Y0 + U * b) ? ["grab": 1, "a": a, "b": b, "a0": a, "b0": b] : nil },
                         drag: { c, h in ["grab": 1, "a": Double(min(q.maxA, max(1, Int((c.x / U).rounded())))), "b": Double(min(q.maxB, max(1, Int(((c.y - Y0) / U).rounded())))),
                                          "a0": h["a0"] ?? a, "b0": h["b0"] ?? b] },
                         release: { h in
                             let a2 = h["a"] ?? a, b2 = h["b"] ?? b
                             // let go where it was picked up: nothing to check
                             if a2 == h["a0"] && b2 == h["b0"] { return HandMove(hand: ["a": a2, "b": b2], missHand: nil) }
                             return HandMove(hand: ["a": a2, "b": b2], missHand: nil, set: [("a", a2), ("b", b2)], check: true)
                         })
        }
        if at == 1 && p.fold == 1 {
            let a = s.h("a") ?? 1, w = Double(p.w)
            return Hands(grab: { c in near(c, U * a, Y0 + U * w / 2) ? ["grab": 1, "a": a, "a0": a] : nil },
                         drag: { c, h in ["grab": 1, "a": Double(min(q.maxA, max(1, Int((c.x / U).rounded())))), "a0": h["a0"] ?? a] },
                         release: { h in
                             let a2 = h["a"] ?? a
                             if a2 == h["a0"] { return HandMove(hand: ["a": a2], missHand: nil) }
                             return HandMove(hand: ["a": a2], missHand: nil, set: [("a", a2)], check: true)
                         })
        }
        if at == 3 {
            let t = Int((s.h("t") ?? 0).rounded())
            return Hands(grab: { c in let tp = q.tip(t); return near(c, tp.x, tp.y) ? ["grab": 1, "t": Double(t), "from": Double(t)] : nil },
                         drag: { c, h in
                             // the edge lights up to the corner-to-corner point nearest the finger
                             var best = Int((h["t"] ?? 0).rounded()), bd = Double.infinity
                             for k in 0...q.maxT {
                                 let tp = q.tip(k), d = hypot(tp.x - c.x, tp.y - c.y)
                                 if d < bd { bd = d; best = k }
                             }
                             return ["grab": 1, "t": Double(best), "from": h["from"] ?? 0]
                         },
                         release: { h in
                             let t2 = h["t"] ?? 0
                             if t2 == 0 || t2 == h["from"] { return HandMove(hand: ["t": t2], missHand: nil) }
                             return HandMove(hand: ["t": t2], missHand: nil, set: [("t", t2)], check: true)
                         })
        }
        return nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(p: AreaPerim.Parts(s.numbers)), p = q.p, U = q.U, Y0 = Self.Y0, l = Double(p.l), w = Double(p.w)
        switch (stage(s), p.fold) {
        case (1, 0): return [.drag(from: CGPoint(x: U * (s.h("a") ?? 1), y: Y0 + U * (s.h("b") ?? 1)), to: CGPoint(x: U * l, y: Y0 + U * w))]
        case (1, 1): return [.drag(from: CGPoint(x: U * (s.h("a") ?? 1), y: Y0 + U * w / 2), to: CGPoint(x: U * l, y: Y0 + U * w / 2))]
        case (3, _): return [.drag(from: q.tip(Int((s.h("t") ?? 0).rounded())), to: q.tip(p.l + p.w))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = AreaPerim.Parts(s.numbers), a = Double(p.l > 1 ? p.l - 1 : p.l + 1)
        switch (stage(s), p.fold) {
        case (1, 0): return HandMove(hand: ["a": a, "b": Double(p.w)], missHand: nil, set: [("a", a), ("b", Double(p.w))], check: true)
        case (1, 1): return HandMove(hand: ["a": a], missHand: nil, set: [("a", a)], check: true)
        case (3, _): return HandMove(hand: ["t": Double(p.l)], missHand: nil, set: [("t", Double(p.l))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = AreaPerim.Parts(s.numbers)
        switch stage(s) {
        case 2: return ["A": Double(p.Pm != p.A ? p.Pm : p.l + p.w)]
        case 4: return ["H": Double(p.A)]
        case 5: return ["Q": Double(p.A != p.Pm ? p.A : p.Pm - 2)]
        case 6: return ["R": Double(p.fold == 1 ? p.l - 1 : p.Pm / 2)]
        default: return nil
        }
    }
}
