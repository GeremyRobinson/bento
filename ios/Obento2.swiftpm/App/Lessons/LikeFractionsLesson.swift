import SwiftUI

/// Adding and Subtracting like fractions on the paper, as in the preview (design/prototype/grade4-ch4.html): the pieces
/// already match. a/d shaded on top (a whole bar named 1 when a = d), its pieces counted; c/d striped under it, counted,
/// an arrow over them; the names at the bars' right ends with the sign between. Slide the striped pieces up: over the top
/// bar they snap into place, the count running on (adding: after the shaded pieces, spilling into a second whole bar past
/// the end while the emptied bar steps down) or the pieces under them crossed out, what's left counting down (taking
/// away). Let go there and they stay; the emptied bar is left dashed. Then the names come down into the record:
/// a/d ± c/d = [T]/[B].
@MainActor
struct LikeFractionsLesson: PaperLesson {
    /// The bars 3 squares apart (not the kit's 2), so the sign stands clear between their names; the spill pushes the
    /// emptied bar down to y3, 2 squares under the spill bar.
    static let y1 = 0.0, y2 = 7.0, y3 = 13.0
    var liveKeys: Set<String> { ["dx", "dy"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func slide(_ P: LikeFractions.Parts) -> PieceSlide {
        PieceSlide(width: Double(P.c * P.pw), row: Self.y2, target: Self.y1, W: Double(P.W))
    }
    /// Where striped piece i lands: its slot after (or over) the shaded pieces, in the top bar or the spill bar.
    private func slot(_ P: LikeFractions.Parts, _ i: Int) -> (x: Double, y: Double) {
        let k = P.sub ? P.a - P.c + i : P.a + i
        return (Double((k % P.d) * P.pw), k >= P.d ? Self.y2 : Self.y1)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = LikeFractions.Parts(s.numbers), at = stage(s), d = P.d, pw = Double(P.pw), W = Double(P.W)
        let held = at == 1 && s.grabbed, over = held && s.h("in") == 1, slid = at >= 2, done = at >= 3
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // the striped pieces are in the top bar (slid), or over it in the hand (snapped there, live)
        let placed = slid
        let low = P.spill && (placed || over) ? Self.y3 : Self.y2

        // the top bar: its shaded pieces, counted (the ones crossed out lose their number)
        F4.bar(&pic, "b1", y: Self.y1, W: P.W, d: d, on: P.a)
        let left = P.sub && (placed || over) ? P.a - P.c : P.a
        F4.counts(&pic, "t1n", y: Self.y1, pw: pw, left)
        // past a whole: a second whole bar under it
        if P.spill && (placed || over) { F4.bar(&pic, "b3", y: Self.y2, W: P.W, d: d) }
        // the lower bar: its striped pieces wait to be slid; emptied, it's dashed (where they came from)
        F4.bar(&pic, "b2", y: low, W: P.W, d: d, dash: placed)
        for i in 0..<P.c {
            if placed {
                let p = slot(P, i)
                F4.piece(&pic, "sp\(i)", x: p.x, y: p.y, pw: pw, striped: true, crossed: P.sub)
                if !P.sub { pic.word("spn\(i)", "\(P.a + i + 1)", at: p.x + pw / 2, p.y + F4.h / 2, Bars.count) }
            } else if !held {
                F4.piece(&pic, "sp\(i)", x: Double(i) * pw, y: Self.y2, pw: pw, striped: true)
                pic.word("spn\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, Self.y2 + F4.h / 2, Bars.count)
            }
        }
        if at == 1 && !held { pic.word("up", "↑", at: Double(P.c) * pw / 2, (Self.y1 + F4.h + Self.y2) / 2, Bars.maths.colour(.chapter)) }

        // in the hand: following the finger, or snapped into place over the top bar (the count running on or down)
        if held {
            if over {
                for i in 0..<P.c {
                    let p = slot(P, i)
                    F4.piece(&live, "hp\(i)", x: p.x, y: p.y, pw: pw, striped: true, crossed: P.sub)
                    if !P.sub { live.word("hn\(i)", "\(P.a + i + 1)", at: p.x + pw / 2, p.y + F4.h / 2, Bars.count) }
                }
                live.reads(P.sub ? "\(Fractions4.pieces(P.R, d)) left" : Fractions4.pieces(P.R, d))
            } else {
                slide(P).drawHeld(s, &live, per: pw, pieces: P.c)
                live.reads("\(P.c)/\(d)")
            }
        }
        // hints: where the striped pieces go (dashed); the last piece to count (ringed)
        if at == 1 && !held && s.on("spot") {
            for i in 0..<P.c { let p = slot(P, i); pic.sketch.box("tg\(i)", pic.R(p.x + 0.5, p.y + 0.5, pw - 1, F4.h - 1), .chapter, width: Sketch.stroke, dashed: true) }
        } else if at == 1 && !held && s.on("target") {
            for y in Set((0..<P.c).map { slot(P, $0).y }).sorted() { M5.ring(&pic, "tgb\(y)", x: 0, y: y, w: Double(P.W), h: F4.h) }
        }
        if at == 2 && s.on("spot") {
            let k = P.R - 1, x = Double(k % d) * pw, y = k >= d ? Self.y2 : Self.y1
            pic.circle("last", at: x + pw / 2, y + F4.h / 2, radius: min(1.3, pw / 2 - 0.15), .chapter, dashed: true)
        } else if at == 2 && s.on("last") {
            for y in P.R > d ? [Self.y1, Self.y2] : [Self.y1] { M5.ring(&pic, "lastb\(y)", x: 0, y: y, w: Double(P.W), h: F4.h) }
        }

        // the names at the bars' right ends, the sign between (hidden until a story's sign is picked); then down into
        // the record: a/d ± c/d = [T]/[B]
        let whole = P.sub && P.a == d
        if !slid {
            if whole { Bars.whole(&pic, "n1", 1, col: W + 1, row: Self.y1) } else { F4.frac(&pic, "n1", "\(P.a)", "\(d)", col: W + 1, line: Self.y1 + 2) }
            if !s.picking { pic.word("sg", P.sign, at: W + 3, (Self.y1 + F4.h + low) / 2, Bars.maths) }
            F4.frac(&pic, "n2", "\(P.c)", "\(d)", col: W + 1, line: low + 2)
        }
        if slid {
            let first: F4.Tok = whole ? .n(1) : .f("\(P.a)", "\(d)")
            let ans: F4.Tok = done ? .f("\(P.R)", "\(d)", .chapter) : .fb(top: .box("T"), bottom: .box("B"))
            F4.row(&rec, "rec", [first, .op(P.sign), .f("\(P.c)", "\(d)"), .op("="), ans], x: 0, line: 2)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: P.spill ? pic.R(0, 0, W + 5, Self.y3 + F4.h) : pic.R(0, 0, W + 5, Self.y2 + F4.h))
    }

    /// Past a whole, the record comes 2 rows under the emptied bar (a story past a whole was seen at 73% with 3).
    func recordRow(_ n: Numbers) -> Double? { LikeFractions.Parts(n).spill ? Self.y3 + F4.h + 2 : nil }

    func hands(_ s: PaperState) -> Hands? {
        stage(s) == 1 ? slide(LikeFractions.Parts(s.numbers)).hands() : nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = LikeFractions.Parts(s.numbers)
        guard stage(s) == 1 else { return [] }
        let p = slot(P, 0)
        return slide(P).demo(to: p.x + Double(P.c * P.pw) / 2)
    }

    func messageRows(_ n: Numbers) -> Int { 1 }

    func wrongMove(_ s: PaperState) -> HandMove? { stage(s) == 1 ? slide(LikeFractions.Parts(s.numbers)).wrongMove : nil }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = LikeFractions.Parts(s.numbers)
        guard stage(s) == 2 else { return nil }
        // the bottoms added (or taken away)
        return P.sub ? ["T": Double(P.R), "B": 0] : ["T": Double(P.R), "B": Double(2 * P.d)]
    }
}
