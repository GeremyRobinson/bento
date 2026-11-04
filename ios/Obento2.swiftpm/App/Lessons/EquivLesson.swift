import SwiftUI

/// Equivalent fractions on the paper, as in the preview (design/prototype/grade4-ch4.html): two bars of one whole, a/b on
/// top, the same bar under it named ?/N. The ruler under them snaps only to sizes that cut every piece evenly, its cuts
/// dashed across the lower bar, its readout "Eighths: each half into 4"; Cut. The cuts turn solid, the shaded part hasn't
/// moved (a dashed line down both bars at its end), its pieces count; the names come down into the record:
/// a/b = [A]/N, then a/b = (a × k)/(b × k) = A/N.
@MainActor
struct EquivLesson: PaperLesson {
    static let y1 = 0.0, y2 = 6.0, rulerRow = 13.0
    var liveKeys: Set<String> { ["ruler"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private func ruler(_ P: EquivFractions.Parts) -> Ruler {
        var r = Ruler(W: P.W, row: Self.rulerRow, from: Self.y2 - 1, to: Self.y2 + F4.h + 1, old: [], start: P.pb)
        r.snaps = P.sizes; r.under = true
        r.readout = { Fractions4.piece(P.W / max(1, $0)) }
        r.reads = { P.reads($0) }
        return r
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = EquivFractions.Parts(s.numbers), at = stage(s), cut = at >= 2, done = at >= 3
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let W = Double(P.W)
        F4.bar(&pic, "t", y: Self.y1, W: P.W, d: P.b, on: P.a)
        var actions: [String] = []
        if !cut {
            F4.bar(&pic, "l", y: Self.y2, W: P.W, d: P.b, on: P.a)
            // the names at the bars' right ends
            F4.frac(&pic, "n1", "\(P.a)", "\(P.b)", col: W + 1, line: Self.y1 + 2)
            F4.frac(&pic, "n2", "?", "\(P.N)", col: W + 1, line: Self.y2 + 2)
            if at == 1 {
                actions = ["Cut"]
                ruler(P).draw(s, live: &live, still: &pic)
                // a hint: where the right cuts go, dashed over the lower bar
                if s.on("ring") {
                    for x in stride(from: P.pN, to: P.W, by: P.pN) where x % P.pb != 0 {
                        pic.line("hint\(x)", [(Double(x), Self.y2), (Double(x), Self.y2 + F4.h)], .chapter, dashed: true)
                    }
                }
            }
        } else {
            F4.bar(&pic, "l", y: Self.y2, W: P.W, d: P.N, on: P.A)
            F4.counts(&pic, "lc", y: Self.y2, pw: Double(P.pN), P.A)
            pic.line("guide", [(Double(P.a * P.pb), Self.y1 - 1), (Double(P.a * P.pb), Self.y2 + F4.h + 1)], .ink2, dashed: true)
            if at == 2 && s.on("ring") { pic.sketch.box("ring", pic.R(-0.5, Self.y2 - 0.5, Double(P.a * P.pb) + 1, F4.h + 1), .chapter, width: Sketch.stroke, dashed: true) }
        }
        // the record: a/b = [A]/N, then a/b = (a × k)/(b × k) = A/N
        if at == 2 { F4.row(&rec, "rec", [.f("\(P.a)", "\(P.b)"), .op("="), .fb(top: .box("x"), bottom: .v(P.N))], x: 0, line: 2) }
        if done {
            F4.row(&rec, "rec", [.f("\(P.a)", "\(P.b)"), .op("="), .f("\(P.a) × \(P.k)", "\(P.b) × \(P.k)", w: 8), .op("="), .f("\(P.A)", "\(P.N)", .chapter)], x: 0, line: 2)
        }
        // the ruler (and its name under it) is live: its room is kept, so Cut goes under it
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: actions,
                            extent: at == 1 ? pic.R(0, 0, W + 5, Self.rulerRow + 2) : nil)
    }

    /// The record comes once the ruler is put away: 3 rows under the bars.
    func recordRow(_ n: Numbers) -> Double? { Self.y2 + F4.h + 3 }

    func hands(_ s: PaperState) -> Hands? {
        stage(s) == 1 ? ruler(EquivFractions.Parts(s.numbers)).hands(s) : nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = EquivFractions.Parts(s.numbers)
        return stage(s) == 1 ? ruler(P).demo(s, to: P.pN) : []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = EquivFractions.Parts(s.numbers)
        guard stage(s) == 1 else { return nil }
        // pieces of another size: the first that isn't the one asked for, nor the uncut one
        let w = P.sizes.reversed().first { $0 != P.pN && $0 != P.pb } ?? P.pb
        return HandMove(hand: ["ruler": Double(w)], missHand: nil, set: [("x", Double(P.W / w))], check: true)
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        stage(s) == 2 ? ["x": Double(EquivFractions.Parts(s.numbers).a)] : nil
    }
}
