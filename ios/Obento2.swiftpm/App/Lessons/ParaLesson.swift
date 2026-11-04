import SwiftUI

/// Area of a parallelogram on the paper, as in the preview (design/prototype/grade6-ch7.html, dPara): the parallelogram
/// from the picture's top, its base on a grid line, its unit squares faint inside it, its base named under it and its
/// height dashed outside its top corner. Cut straight down a grid line from the top side to the bottom side ("a cut 3
/// from the corner"), slide either piece to the other end (it snaps when its slanted side meets the other), and the b
/// by h rectangle fills row by row; `Area = 12 × 5 = [60] square units`.
///
/// Two squares a unit when it's 14 units or less each way, else one. Hand keys: "grab", "x0", "y0", "x1", "y1" (the cut
/// being drawn), "side", "g0", "d" (a piece slid). Kept: "c" (the cut's column), "side" (the piece slid).
@MainActor
struct ParaLesson: PaperLesson {
    var liveKeys: Set<String> { ["grab", "x1", "y1", "d"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    struct Shape {
        let P: Para6.Parts
        init(_ n: Numbers) { P = Para6.Parts(n) }
        var U: Double { P.b + P.s <= 14 && P.h <= 14 ? 2 : 1 }
        var b: Double { Double(P.b) }
        var h: Double { Double(P.h) }
        var s: Double { Double(P.s) }
        /// The bottom's and the top's left ends (units).
        var BL: Double { P.lean > 0 ? 0 : s }
        var TL: Double { P.lean > 0 ? s : 0 }
        func X(_ x: Double) -> Double { x * U }
        func Y(_ y: Double) -> Double { y * U }
        func sq(_ pts: [(Double, Double)]) -> [CGPoint] { pts.map { CGPoint(x: X($0.0), y: Y($0.1)) } }
        var whole: [(Double, Double)] { [(BL, h), (BL + b, h), (TL + b, 0), (TL, 0)] }
        func left(_ c: Double) -> [(Double, Double)] { P.lean > 0 ? [(0, h), (s, 0), (c, 0), (c, h)] : [(0, 0), (c, 0), (c, h), (s, h)] }
        func right(_ c: Double) -> [(Double, Double)] { P.lean > 0 ? [(c, 0), (s + b, 0), (b, h), (c, h)] : [(c, 0), (b, 0), (s + b, h), (c, h)] }
        /// The two pieces after a cut at c, one moved d units.
        func pieces(_ c: Double, side: Int, d: Double) -> [[CGPoint]] {
            [sq(left(c).map { ($0.0 + (side == 0 ? d : 0), $0.1) }), sq(right(c).map { ($0.0 + (side == 1 ? d : 0), $0.1) })]
        }
        /// Where the height is drawn (the top corner over the base's end), and the base's end it's measured from.
        var hx: Double { P.lean > 0 ? X(s + b) : 0 }
        var ex: Double { P.lean > 0 ? X(b) : X(s) }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), U = S.U, b = S.b, h = S.h
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let cut = s.run.kept["c"], side = Int(s.run.kept["side"] ?? s.h("side") ?? 0)
        let slid = at >= 3 ? (side == 0 ? b : -b) : 0.0
        // the shape, or its two pieces (the one held follows the hand)
        if let c = cut, at >= 2 {
            let held = at == 2 && s.grabbed, d = held ? (s.h("d") ?? 0) : 0
            for (k, pc) in S.pieces(c, side: side, d: at >= 3 ? slid : 0).enumerated() {
                if held && k == side {
                    let moved = S.pieces(c, side: side, d: d)[k]
                    A7.shape(&live, "held", moved, fill: A7.strong); A7.faint(&live, "heldf", moved, U: U)
                    continue
                }
                A7.shape(&pic, "pc\(k)\(c)\(at >= 3)", pc); A7.faint(&pic, "pcf\(k)\(c)\(at >= 3)", pc, U: U)
            }
        } else {
            let w = S.sq(S.whole)
            A7.shape(&pic, "whole", w); A7.faint(&pic, "wholef", w, U: U)
        }
        if at <= 2 {
            pic.label("bl", "\(P.b)", A7.words, .below, edge: S.Y(h), along: S.X(S.BL + b / 2))
            if !(at == 2 && s.grabbed) { A7.height(&pic, "hh", x: S.hx, from: 0, to: S.Y(h), toward: P.lean > 0 ? -1 : 1) }
            pic.line("hb", [(S.ex, S.Y(h)), (S.hx, S.Y(h))], .ink2, dashed: true)
            pic.label("hl", "\(P.h)", A7.words, P.lean > 0 ? .right : .left, edge: S.hx, along: S.Y(h / 2))
        } else {
            // See: the b by h rectangle fills row by row
            let lo = side == 0 ? (cut ?? 0) : (cut ?? 0) - b
            for r in 0..<P.h { pic.fill("row\(r)", col: S.X(lo), row: S.Y(Double(r)), w: S.X(b), h: U, .tint(0.3)) }
            pic.label("bl2", "\(P.b)", A7.words, .below, edge: S.Y(h), along: S.X(lo + b / 2))
            pic.label("hl2", "\(P.h)", A7.words, .left, edge: S.X(lo), along: S.Y(h / 2))
            if at == 3 && s.on("ring") { A7.ring(&pic, "ring", x: S.X(lo), y: 0, w: S.X(b), h: S.Y(h)) }
            if at == 3 && s.on("spot") { pic.word("spot", "\(P.h) rows of \(P.b)", at: S.X(lo + b) + 1, S.Y(h / 2), A7.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        }
        // the cut being drawn, down its column
        if at == 1, s.grabbed, let y0 = s.h("y0"), let y1 = s.h("y1"), let x1 = s.h("x1") {
            let c = (x1 / U).rounded(), ok = P.cuts(Int(c)), ya = min(y0, y1), yb = max(y0, y1)
            live.line("cutl", [(S.X(c), ya), (S.X(c), yb)], ok ? .chapter : .ink2, dashed: true)
            if ok {
                let from = abs(c - S.BL), words = from == 0 ? "a cut at the corner" : "a cut \(Int(from)) from the corner"
                live.word("rd", words, at: S.X(b + S.s) + 2, 1, A7.lit, anchor: UnitPoint(x: 0, y: 0.5))
                live.reads(words)
            }
        }
        if at == 1 && s.on("ring") { A7.ring(&pic, "ring", x: S.X(S.s), y: 0, w: max(1, S.X(b - S.s)), h: S.Y(h)) }
        if at == 1 && s.on("spot") { pic.line("spot", [(S.X(S.s), -1), (S.X(S.s), S.Y(h) + 1)], .chapter, dashed: true) }
        if at == 2, let c = cut {
            // a hint: where the piece goes, dashed
            let to = S.pieces(c, side: 0, d: b)[0]
            if s.on("ring") { let l = S.pieces(c, side: 0, d: 0)[0]; A7.ring(&pic, "ring", x: 0, y: 0, w: Double(l.map(\.x).max() ?? 1), h: S.Y(h)) }
            if s.on("spot") { A7.shape(&pic, "spot", to, fill: nil, dashed: true) }
        }
        // the record under the picture
        if at >= 3 {
            let x: M7.Tok = at >= 4 ? .n(P.A, .chapter) : .box("x", cells: max(2, "\(P.A)".count))
            M7.row(&rec, "r0", [.t("Area"), .op("="), .n(P.b), .op("×"), .n(P.h), .op("="), x, .w(P.unit)], x: 0, line: 1)
        }
        // room for either piece slid to the other end
        let x0 = S.X(min(0, (cut ?? S.s) - b)) - (P.lean > 0 ? 0 : 2.5), x1 = max(S.X(b + S.s) + (at == 1 ? 14 : 3), S.X(2 * b + 1))
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: at >= 1 && at <= 2 ? pic.R(x0, 0, x1 - x0, S.Y(h) + 2) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), P = S.P, at = stage(s), U = S.U
        switch at {
        case 1:
            return Hands(grab: { q in
                q.x > -2 && q.x < S.X(S.b + S.s) + 2 && q.y > -3 && q.y < S.Y(S.h) + 3 ? ["grab": 1, "x0": q.x, "y0": q.y, "x1": q.x, "y1": q.y] : nil
            }, drag: { q, hd in
                var hd = hd; hd["x1"] = q.x; hd["y1"] = q.y; return hd
            }, release: { hd in
                let y0 = hd["y0"] ?? 0, y1 = hd["y1"] ?? 0, c = ((hd["x1"] ?? 0) / U).rounded()
                guard abs(y1 - y0) >= 1 else { return HandMove(hand: [:]) }
                let spans = min(y0, y1) <= 0.75 && max(y0, y1) >= S.Y(S.h) - 0.75
                let ok = spans && P.cuts(Int(c))
                return HandMove(hand: [:], set: [("c", ok ? c : -1)], keep: ok ? ["c": c] : [:], check: true)
            })
        case 2:
            guard let c = s.run.kept["c"] else { return nil }
            let pcs = S.pieces(c, side: 0, d: 0)
            return Hands(grab: { q in
                for (k, pc) in pcs.enumerated() where A7.inside(pc, q) { return ["grab": 1, "side": Double(k), "g0": q.x, "d": 0] }
                return nil
            }, drag: { q, hd in
                var hd = hd
                hd["d"] = max(-S.b - 3, min(S.b + 3, ((q.x - (hd["g0"] ?? q.x)) / U).rounded())); return hd
            }, release: { hd in
                let side = Int(hd["side"] ?? 0), d = hd["d"] ?? 0, want = side == 0 ? S.b : -S.b
                if abs(d - want) <= 1 { return HandMove(hand: ["side": Double(side)], set: [("d", 1)], keep: ["side": Double(side)], check: true) }
                return d == 0 ? HandMove(hand: [:]) : HandMove(hand: [:], set: [("d", 0)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), at = stage(s)
        switch at {
        case 1: return [.drag(from: CGPoint(x: S.X(S.s), y: -0.5), to: CGPoint(x: S.X(S.s), y: S.Y(S.h) + 0.5))]
        case 2:
            guard let c = s.run.kept["c"] else { return [] }
            let m = A7.centroid(S.pieces(c, side: 0, d: 0)[0])
            return [.drag(from: m, to: CGPoint(x: m.x + S.X(S.b), y: m.y))]
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        switch stage(s) {
        case 1: return HandMove(hand: [:], set: [("c", -1)], check: true)
        case 2: return HandMove(hand: [:], set: [("d", 0)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Para6.Parts(s.numbers)
        return stage(s) == 3 ? ["x": Double(P.A % 2 == 0 ? P.A / 2 : P.b + P.h)] : nil
    }
}
