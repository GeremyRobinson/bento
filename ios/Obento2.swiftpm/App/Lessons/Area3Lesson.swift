import SwiftUI

/// Area by counting squares on the paper, as in the preview (design/prototype/grade3-ch4.html, dArea), with one square of
/// the grid as one square unit (the call of 4 Nov): the rectangle's outline l across and w down, its inner squares faint,
/// its sides named. Drag across the top row: the tiles tint in one by one ("5 tiles"); let go short, they stay and the
/// row says how many it has. Drag the row down: rows of l tint down a square at a time and count by l at the right end
/// ("3 rows of 7"). Write `4 × 7 = [28] square units`; the last count joins once it's written.
///
/// Hand: "grab", "n" the tiles laid (the row step), the rows (the rows step).
@MainActor
struct Area3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let X0 = 5.0, Y0 = 3.0
    func messageRows(_ n: Numbers) -> Int { 2 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Area3.Parts(s.numbers), st = at(s), X0 = Self.X0, Y0 = Self.Y0, L = Double(P.l), H = Double(P.w)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        // the tiles laid so far
        let laid = st == 0 ? Int((s.h("n") ?? 0).rounded()) : P.l
        let rows = st == 0 ? 0 : st == 1 ? Int((s.h("n") ?? 1).rounded()) : P.w
        if st == 0 { S3P.lay(&live, "t0_", x: X0, y: Y0, n: laid) } else { S3P.lay(&pic, "t0_", x: X0, y: Y0, n: P.l) }
        for i in 1..<max(1, rows) {
            if st == 1 { live.fill("tr\(i)", col: X0, row: Y0 + Double(i), w: L, h: 1, S3P.tint) }
            else { pic.fill("tr\(i)", col: X0, row: Y0 + Double(i), w: L, h: 1, S3P.tint) }
        }
        S3P.tiles(&pic, "g", x: X0, y: Y0, rows: P.w, cols: P.l)
        pic.label("lt", P.nm(P.l), S3P.small, .above, edge: Y0, along: X0 + L / 2)
        pic.label("ll", P.nm(P.w), S3P.small, .left, edge: X0, along: Y0 + H / 2)
        // the rows count by l at the right end (the last once it's written)
        let shown = st == 2 ? P.w - 1 : rows
        for i in 0..<max(0, shown) {
            if st == 1 { S3P.count(&live, "cnt\(i)", "\(P.l * (i + 1))", x: X0 + L, y: Y0 + Double(i) + 0.5) }
            else { S3P.count(&pic, "cnt\(i)", "\(P.l * (i + 1))", x: X0 + L, y: Y0 + Double(i) + 0.5) }
        }
        switch st {
        case 0:
            live.dot("rh", at: X0 + Double(laid), Y0 + 0.5, radius: s.grabbed ? 0.7 : 0.55)
            if s.grabbed { live.reads(S3.count(laid, "tile", "tiles")) }
            if ring { KK.hintBox(&pic, "hr", x: X0, y: Y0, w: L, h: 1) }
            if spot { pic.circle("sp", at: X0 + L, Y0 + 0.5, radius: 0.9, .chapter, dashed: true) }
        case 1:
            M3.edge(&live, rows: true, x: X0, y: Y0, at: Y0 + Double(rows), span: L, held: s.grabbed)
            if s.grabbed { live.reads("\(S3.count(rows, "row", "rows")) of \(P.l)") }
            if ring { KK.hintBox(&pic, "hr", x: X0 - 3, y: Y0, w: 2, h: H) }
            if spot { pic.circle("sp", at: X0 + L / 2, Y0 + H, radius: 1, .chapter, dashed: true) }
        case 2:
            if ring { KK.hintBox(&pic, "hc", x: X0 + L, y: Y0, w: 3, h: H) }
            if spot { S3P.count(&pic, "sp", "\(P.A)", x: X0 + L, y: Y0 + H - 0.5) }
        default: break
        }
        if st >= 2 {
            M7.row(&rec, "rec", [.n(P.w), .op("×"), .n(P.l), .op("="), M3.box("A", P.A, cells: M3.cells(P.A), right: st == 3), .w(P.uw)], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, Y0 - 2, X0 + L + 4, H + 2))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Area3.Parts(s.numbers), X0 = Self.X0, Y0 = Self.Y0, L = Double(P.l)
        switch at(s) {
        case 0:
            let n0 = Int((s.h("n") ?? 0).rounded())
            func laid(_ q: CGPoint, _ n: Int) -> Int { max(n, min(P.l, Int((q.x - X0).rounded(.up)))) }
            return Hands(
                grab: { q in
                    guard q.y >= Y0 - 1.5, q.y <= Y0 + 2.5, q.x >= X0 - 1.5, q.x <= X0 + L + 1.5 else { return nil }
                    return ["grab": 1, "n": Double(laid(q, n0))]
                },
                drag: { q, h in var h = h; h["n"] = Double(laid(q, Int((h["n"] ?? 0).rounded()))); return h },
                release: { h in
                    let n = Int((h["n"] ?? 0).rounded())
                    guard n > 0 else { return HandMove(hand: ["n": 0]) }
                    return HandMove(hand: ["n": Double(n)], missHand: ["n": Double(n)], set: [("n", Double(n))], check: true)
                })
        case 1:
            let n = Int((s.h("n") ?? 1).rounded())
            return Hands(
                grab: { q in M3.onEdge(q, rows: true, x: X0, y: Y0, at: Y0 + Double(n), span: L) ? ["grab": 1, "n": Double(n)] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(1, min(P.w, Int((q.y - Y0).rounded())))); return h },
                release: { h in
                    let k = Int((h["n"] ?? 1).rounded())
                    guard k != 1 else { return HandMove(hand: ["n": 1]) }
                    return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("r", Double(k))], check: true)
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Area3.Parts(s.numbers), X0 = Self.X0, Y0 = Self.Y0, L = Double(P.l)
        switch at(s) {
        case 0:
            let n = (s.h("n") ?? 0).rounded()
            return [.drag(from: CGPoint(x: X0 + max(0.5, n - 0.5), y: Y0 + 0.5), to: CGPoint(x: X0 + L - 0.5, y: Y0 + 0.5))]
        case 1:
            let n = (s.h("n") ?? 1).rounded()
            return [.drag(from: CGPoint(x: X0 + L / 2, y: Y0 + n), to: CGPoint(x: X0 + L / 2, y: Y0 + Double(P.w)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Area3.Parts(s.numbers)
        switch at(s) {
        case 0: let n = Double(max(1, P.l - 2)); return HandMove(hand: ["n": n], missHand: ["n": n], set: [("n", n)], check: true)
        case 1: let k = Double(P.w > 2 ? P.w - 1 : 2 == P.w ? 1 : P.w); return HandMove(hand: ["n": k], missHand: ["n": 1], set: [("r", k)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Area3.Parts(s.numbers)
        return at(s) == 2 ? ["A": Double(2 * (P.l + P.w))] : nil
    }
}
