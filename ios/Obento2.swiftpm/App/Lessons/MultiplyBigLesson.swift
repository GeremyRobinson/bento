import SwiftUI

/// Multiply big numbers on the paper, as in the preview (design/prototype/grade4-ch2.html): the place chart with the
/// number's columns (2-square cells for three digits, 1-square for four), its disks in one plain row across the top, named
/// at its right (a row is one copy). Drag the handle under the row down: the row copies a row at a time, so each column
/// becomes an array of its place; let go at m and the copies are braced "× m" at the left. Then each place lights, its
/// count written under it ("7 × 3 = 21 hundreds"), and its part is written in the record with its multiplication beside
/// it, biggest first; then the parts are added under a rule.
@MainActor
struct MultiplyBigLesson: PaperLesson {
    /// The chart's names on rows 0–3, the rows of disks from row 3.
    static let top = 0.0, y0 = 3.0, x0 = 5.0
    private static let count = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let countSmall = Sketch.Words(size: Sketch.small, weight: .medium, colour: .chapter)
    private static let dim = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static func chart(_ P: MultiplyBig.Parts) -> PlaceChart { PlaceChart(n: P.D, c: P.D == 3 ? 2 : 1, pr: 2, x0: x0, y0: y0) }
    private func rows(_ s: PaperState, _ P: MultiplyBig.Parts) -> Int { stage(s) >= 2 ? P.m : Int((s.h("rows") ?? 1).rounded()) }
    private func handleY(_ ch: PlaceChart, _ rows: Int) -> Double { Self.y0 + Double(rows) * ch.c + 1 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = MultiplyBig.Parts(s.numbers), ch = Self.chart(P), at = stage(s), c = ch.c, m = P.m
        let n = rows(s, P), cur: Int? = at == 2 ? Int((s.picture["p"] ?? 0).rounded()) : nil
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let bottom = Self.y0 + Double(max(n, at >= 1 ? 1 : 1)) * c + 1
        if let cur { pic.fill("lit\(cur)", col: ch.colX(cur), row: Self.y0, w: ch.cw, h: Double(m) * c, .tint(0.16)) }
        ch.draw(&pic, "ch", bands: [], top: Self.top, bottom: bottom, lit: cur)
        // the rows: one copy each, every place's disks in a plain row
        for k in 0..<n {
            for p in 0..<P.D {
                for j in 0..<P.digit(p) {
                    ch.disk(&pic, "\(k)_\(p)_\(j)", at: CGPoint(x: ch.colX(p) + (Double(j) + 0.5) * c, y: Self.y0 + (Double(k) + 0.5) * c))
                }
            }
        }
        // its name at the first row's right end
        pic.word("name", BigNumbers.commas(P.n), at: ch.right + 0.5, Self.y0 + c / 2, Record.maths, anchor: UnitPoint(x: 0, y: 0.5))
        if at <= 1 {
            let hy = handleY(ch, n), mid = (ch.x0 + ch.right) / 2
            if at == 1 {
                live.dot("hd", at: mid, hy, radius: s.grabbed ? 0.75 : 0.55, .ink, over: true)
                if s.grabbed { live.reads("× \(n)") }
                // a hint: where the rows end, dashed
                if s.on("ring") { pic.line("ring", [(ch.x0 - 1, Self.y0 + Double(m) * c), (ch.right + 1, Self.y0 + Double(m) * c)], .chapter, dashed: true) }
            }
        } else {
            // the copies braced at the left
            let yb = Self.y0 + Double(m) * c
            pic.line("brace", [(ch.x0 - 0.5, Self.y0), (ch.x0 - 1, Self.y0), (ch.x0 - 1, yb), (ch.x0 - 0.5, yb)], .ink)
            pic.word("bracew", "× \(m)", at: ch.x0 - 1.5, Self.y0 + Double(m) * c / 2, Record.maths, anchor: UnitPoint(x: 1, y: 0.5))
        }
        // each place's count under its column, once it's lit
        let order = P.order
        let shown = at >= 3 ? order : at == 2 ? Array(order.prefix(through: order.firstIndex(of: cur ?? 0) ?? 0)) : []
        for p in shown {
            let d = P.digit(p), txt = d == 0 ? "0 \(BigNumbers.places[p])" : c == 2 ? "\(m) × \(d) = \(m * d) \(BigNumbers.place(p, m * d))" : "\(m * d) \(BigNumbers.place(p, m * d))"
            pic.label("cnt\(p)", txt, p == cur ? (c == 2 ? Self.count : Self.countSmall) : Self.dim, .below, edge: bottom, along: ch.mid(p))
        }

        // the record: each part, its multiplication beside it; a rule; the sum
        var boxes: [WorkBox] = []
        if at >= 2 {
            let xr = 3 + 2 * Double(String(P.total).count)
            for (i, p) in shown.enumerated() {
                let row = 2 + 2 * Double(i), part = P.part(p)
                if p == cur { rec.answerBox("x", right: xr, mid: row, per: 2, cells: String(part).count, commas: true) }
                else { Record.number(&rec, "pt\(p)", part, right: xr, row: row) }
                Record.line(&rec, "eq\(p)", [.n(P.digit(p) * BigNumbers.pow10(p)), .op("×"), .n(m)], x: xr + 2, row: row)
            }
            if at >= 3 {
                let last = 2 + 2 * Double(P.D - 1)
                rec.word("plus", "+", at: 1.5, last, Record.maths)
                rec.rule("rule", from: 0, to: xr, row: last + 2)
                if at == 3 { rec.answerBox("x", right: xr, mid: last + 4, per: 2, cells: String(P.total).count, commas: true) }
                else { Record.number(&rec, "tot", P.total, right: xr, row: last + 4, .chapter) }
            }
            boxes = rec.boxes
        }
        let most = Self.y0 + 9 * c + 2
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes,
                            extent: at == 1 ? pic.R(ch.x0 - 4, 0, ch.right - ch.x0 + 8, most) : nil)
    }

    /// The record goes under the copies as they end up (m rows), not under the room the handle had.
    func recordRow(_ n: Numbers) -> Double? {
        let P = MultiplyBig.Parts(n), ch = Self.chart(P)
        return Self.y0 + Double(P.m) * ch.c + 1 + (ch.c == 2 ? 4 : 3)
    }
    func messageRows(_ n: Numbers) -> Int { 2 }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let P = MultiplyBig.Parts(s.numbers), ch = Self.chart(P), n = rows(s, P), hy = handleY(ch, n)
        return Hands(
            grab: { q in abs(q.y - hy) <= 2 && q.x >= ch.x0 - 1 && q.x <= ch.right + 1 ? ["grab": 1, "rows": Double(n)] : nil },
            drag: { q, _ in ["grab": 1, "rows": Double(max(1, min(9, Int(((q.y - 1 - Self.y0) / ch.c).rounded()))))] },
            release: { h in
                let r = Int((h["rows"] ?? 1).rounded())
                guard r > 1 else { return HandMove(hand: ["rows": 1], missHand: nil) }
                return HandMove(hand: ["rows": Double(r)], missHand: nil, set: [("x", Double(r))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let P = MultiplyBig.Parts(s.numbers), ch = Self.chart(P), mid = (ch.x0 + ch.right) / 2
        return [.drag(from: CGPoint(x: mid, y: handleY(ch, rows(s, P))), to: CGPoint(x: mid, y: handleY(ch, P.m)))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = MultiplyBig.Parts(s.numbers), r = P.m > 2 ? P.m - 1 : P.m + 1
        return HandMove(hand: ["rows": Double(r)], missHand: nil, set: [("x", Double(r))], check: true)
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        // the commonest slip: the digit times m, the place's zeros lost
        guard stage(s) == 2 else { return nil }
        let P = MultiplyBig.Parts(s.numbers), p = Int((s.picture["p"] ?? 0).rounded())
        return P.digit(p) > 0 && p > 0 ? ["x": Double(P.digit(p) * P.m)] : nil
    }
}
