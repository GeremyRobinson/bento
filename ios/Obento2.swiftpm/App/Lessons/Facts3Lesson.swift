import SwiftUI

/// Multiplication facts on the paper, as in the preview (design/prototype/grade3-ch1.html, dFacts): a rows of b dots, a dot
/// in a cell of 5, 4 or 3 squares, the array a block in. b over the first row, the only row drawn, and a down the left in an
/// open bracket for the rows still to make. Drag the bottom edge down: it snaps a row at a time ("3 rows of 6"); let go on a
/// rows it closes the bracket. The rows light one by one with their counts, the last typed (`6, 12, 18, [ ]`); `4 × 6 = 24`.
/// Turn it by its corner: the same dots swing round the middle, snap at a quarter turn and slide home (b rows of a);
/// `6 × 4 = [ ]`. A square has no turn. The record goes beside the array or under it, whichever shows bigger.
///
/// Hand: "grab", "n" the rows (the rows step); "grab", "a0", "th" the turn (degrees), "back" a turn let go short (it swings
/// back). Kept: "th" the turn let go at, "to" the quarter it snapped to.
@MainActor
struct Facts3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private static let X0 = M3.X0, Y0 = M3.Y0
    func recordBeside(_ n: Numbers) -> Double? { Self.Y0 }
    func recordRow(_ n: Numbers) -> Double? { let P = Facts3.Parts(n); return Self.Y0 + Double(max(P.a, P.b) * P.c) + 3 }

    /// The array's middle, in squares, and the turn about it (degrees) as a map of paper points.
    private static func centre(_ P: Facts3.Parts) -> CGPoint {
        let c = Double(P.c)
        return CGPoint(x: X0 + Double(P.b) * c / 2, y: Y0 + Double(P.a) * c / 2)
    }
    private static func turn(_ P: Facts3.Parts, _ deg: Double, home: Bool = false) -> (CGPoint) -> CGPoint {
        let C = centre(P), q = Paper.cell, t = deg * .pi / 180, c = Double(P.c)
        // turned a quarter, the array is b rows of a about the same middle; home slides its top-left back to (X0, Y0)
        let dx = home ? X0 - (C.x - Double(P.a) * c / 2) : 0, dy = home ? Y0 - (C.y - Double(P.b) * c / 2) : 0
        return { p in
            let x = p.x / q - C.x, y = p.y / q - C.y
            return CGPoint(x: (C.x + x * cos(t) - y * sin(t) + dx) * q, y: (C.y + x * sin(t) + y * cos(t) + dy) * q)
        }
    }
    private static func arrayPen(_ P: Facts3.Parts) -> Sketch {
        var g = GridPen()
        M3.array(&g, "ar", x: X0, y: Y0, rows: P.a, cols: P.b, c: Double(P.c))
        return g.sketch
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Facts3.Parts(s.numbers), st = at(s), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let W = Double(P.b) * c, H = Double(P.a) * c
        var extent: CGRect?
        if st == 0 {
            // the rows made so far, b over the top, a in the open bracket; the bottom edge to drag
            let n = Int((s.h("n") ?? 1).rounded())
            M3.array(&pic, "ar", x: X0, y: Y0, rows: n, cols: P.b, c: c)
            pic.label("top", "\(P.b)", M3.maths, .above, edge: Y0, along: X0 + W / 2)
            M3.bracket(&pic, "bl", x: X0 - 1, y1: Y0, y2: Y0 + H, open: true, name: "\(P.a)")
            M3.edge(&live, rows: true, x: X0, y: Y0, at: Y0 + Double(n) * c, span: W, held: s.grabbed)
            if s.grabbed { live.reads("\(G3.count(n, "row")) of \(P.b)") }
            if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hr", x: X0 - 4, y: Y0, w: 3.5, h: H) }
            if s.on("spot") { pic.line("sp", [(X0 - 0.5, Y0 + H), (X0 + W + 0.5, Y0 + H)], .chapter, dashed: true) }
            extent = pic.R(X0 - 1, Y0, W + 1, H + 1)
        } else if st == 1 || (P.square && st == 4) {
            M3.array(&pic, "ar", x: X0, y: Y0, rows: P.a, cols: P.b, c: c, over: true)
            pic.label("top", "\(P.b)", M3.maths, .above, edge: Y0, along: X0 + W / 2)
            M3.bracket(&pic, "bl", x: X0 - 1, y1: Y0, y2: Y0 + H, open: false, name: "\(P.a)")
            M3.countRows(&pic, "cr", x: X0, y: Y0, rows: P.a, cols: P.b, c: c, by: P.b, last: st == 4)
            if st == 1 && (s.on("ring") || s.on("spot")) { KK.hintBox(&pic, "hc", x: X0, y: Y0 + H - c, w: W, h: c) }
            if st == 1 && s.on("spot") { A1.note(&pic, "sp", "\(P.P)", x: X0 + W + 0.5, y: Y0 + H - c / 2) }
        } else if st == 2 {
            // the turn: held, the array follows the finger round its middle; let go short, it swings back
            if s.grabbed {
                live.sketch.append(Self.arrayPen(P).lifted(Self.turn(P, s.h("th") ?? 0), tag: "L"))
                let q = abs(Int(((s.h("th") ?? 0) / 90).rounded())) % 2 == 1
                live.reads(q ? "\(P.b) rows of \(P.a)" : "\(P.a) rows of \(P.b)")
            } else if let back = s.h("back") {
                pic.sketch.append(Self.arrayPen(P).lifted(Self.turn(P, 0), from: Self.turn(P, back), tag: "B"))
            } else {
                M3.array(&pic, "ar", x: X0, y: Y0, rows: P.a, cols: P.b, c: c)
            }
            if !s.grabbed { handle(&pic, P) }
            if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hh", x: X0 + W - 3, y: Y0 + H - 3, w: 3, h: 3) }
            if s.on("spot") { pic.sketch.box("sp", pic.R(X0, Y0, H, W), .chapter, width: Sketch.stroke, dashed: true) }
            extent = pic.R(X0 - 1, Y0, max(W, H) + 4, max(W, H) + 1)
        } else {
            // turned: the same dots, b rows of a, slid home on the paper's spring
            let th = s.run.kept["th"] ?? 90, to = s.run.kept["to"] ?? 90
            pic.sketch.append(Self.arrayPen(P).lifted(Self.turn(P, to, home: true), from: Self.turn(P, th), via: Self.turn(P, to), tag: "T"))
            pic.label("ttop", "\(P.a)", M3.maths, .above, edge: Y0, along: X0 + H / 2)
            M3.bracket(&pic, "tbl", x: X0 - 1, y1: Y0, y2: Y0 + W, open: false, name: "\(P.b)")
            if st == 3 && (s.on("ring") || s.on("spot")) { KK.hintBox(&pic, "ht", x: X0, y: Y0, w: H, h: W) }
        }

        // the record: the count, the fact, the fact turned round
        if st >= 1 {
            let cl = M3.cells(P.P), counted = st >= 2
            var toks: [M7.Tok] = []
            for v in P.shown { toks.append(.t(v.map { "\($0)," } ?? "…,")) }
            toks.append(M3.box("n", P.P, cells: cl, right: counted))
            M7.row(&rec, "l1", toks, x: 0, line: 1)
            if counted { M7.row(&rec, "l2", [.n(P.a), .op("×"), .n(P.b), .op("="), .n(P.P, .chapter)], x: 0, line: 4) }
            if st >= 3 && !P.square { M7.row(&rec, "l3", [.n(P.b), .op("×"), .n(P.a), .op("="), M3.box("t", P.P, cells: cl, right: st == 4)], x: 0, line: 7) }
            if st == 3 && s.on("spot") { KK.hintBox(&rec, "hs", x: 0, y: 3, w: M7.width([.n(P.a), .op("×"), .n(P.b), .op("="), .n(P.P)]), h: 2) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    /// The turn's handle: a dot on the bottom-right corner and a curved arrow round it.
    private func handle(_ pen: inout GridPen, _ P: Facts3.Parts) {
        let c = Double(P.c), cx = Self.X0 + Double(P.b) * c, cy = Self.Y0 + Double(P.a) * c, r = 2.4
        var arc: [(Double, Double)] = []
        for i in 0...12 { let a = (-110 + 120 * Double(i) / 12) * .pi / 180; arc.append((cx + r * cos(a), cy + r * sin(a))) }
        pen.line("tnarc", arc, .chapter)
        let e = arc[arc.count - 1]
        pen.line("tnhead", [(e.0 - 0.6, e.1 - 0.55), (e.0, e.1), (e.0 + 0.55, e.1 - 0.6)], .chapter)
        pen.dot("tnh", at: cx, cy, radius: 0.55)
    }

    private static func angle(_ q: CGPoint, _ C: CGPoint) -> Double { atan2(q.y - C.y, q.x - C.x) * 180 / .pi }

    func hands(_ s: PaperState) -> Hands? {
        let P = Facts3.Parts(s.numbers), st = at(s), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0
        let W = Double(P.b) * c, H = Double(P.a) * c
        if st == 0 {
            let n = Int((s.h("n") ?? 1).rounded())
            return Hands(
                grab: { q in M3.onEdge(q, rows: true, x: X0, y: Y0, at: Y0 + Double(n) * c, span: W) ? ["grab": 1, "n": Double(n)] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(1, min(P.cap, Int(((q.y - Y0) / c).rounded())))); return h },
                release: { h in
                    let k = Int((h["n"] ?? 1).rounded())
                    guard k != 1 else { return HandMove(hand: ["n": 1]) }
                    return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("r", Double(k))], check: true)
                })
        }
        guard st == 2 else { return nil }
        let C = Self.centre(P), corners = [CGPoint(x: X0, y: Y0), CGPoint(x: X0 + W, y: Y0), CGPoint(x: X0 + W, y: Y0 + H), CGPoint(x: X0, y: Y0 + H)]
        return Hands(
            grab: { q in corners.contains { hypot(q.x - $0.x, q.y - $0.y) < 3 } ? ["grab": 1, "a0": Self.angle(q, C), "th": 0] : nil },
            drag: { q, h in
                var h = h, d = Self.angle(q, C) - (h["a0"] ?? 0)
                while d > 180 { d -= 360 }
                while d < -180 { d += 360 }
                h["th"] = d; return h
            },
            release: { h in
                let th = h["th"] ?? 0, k = Int((th / 90).rounded())
                // a half turn is a miss (still a rows of b); short of a quarter it swings back
                if abs(k) == 2 { return HandMove(hand: ["back": th], missHand: ["back": th], set: [("q", 2)], check: true) }
                guard abs(k) % 2 == 1 else { return HandMove(hand: abs(th) > 2 ? ["back": th] : [:]) }
                return HandMove(hand: [:], set: [("q", 1)], keep: ["th": th, "to": Double(k) * 90], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Facts3.Parts(s.numbers), st = at(s), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0, W = Double(P.b) * c, H = Double(P.a) * c
        if st == 0 {
            let n = Double(Int((s.h("n") ?? 1).rounded()))
            return [.drag(from: CGPoint(x: X0 + W / 2, y: Y0 + n * c), to: CGPoint(x: X0 + W / 2, y: Y0 + H))]
        }
        guard st == 2 else { return [] }
        // the bottom-right corner swung a quarter turn round the middle
        let C = Self.centre(P), r = hypot(W / 2, H / 2), a = atan2(H / 2, W / 2)
        var pts: [CGPoint] = []
        for i in 0...8 { let t = a + Double(i) / 8 * .pi / 2; pts.append(CGPoint(x: C.x + r * cos(t), y: C.y + r * sin(t))) }
        return [.path(pts)]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Facts3.Parts(s.numbers)
        if at(s) == 2 { return HandMove(hand: ["back": 180], missHand: ["back": 180], set: [("q", 2)], check: true) }
        guard at(s) == 0 else { return nil }
        let k = min(P.cap, P.a + 1)
        return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("r", Double(k))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Facts3.Parts(s.numbers)
        switch at(s) { case 1: return ["n": Double((P.a - 1) * P.b)]; case 3: return ["t": Double(P.a + P.b)]; default: return nil }
    }
}
