import SwiftUI

/// Comparing fractions on the paper, as in the preview (design/prototype/grade4-ch4.html): two bars of one whole, a/b
/// shaded on top and c/d striped under it, named at their right ends with ? between. The ruler under them cuts both into
/// pieces of one size (a dot under each old cut, green when a new cut lands on it, red when none does); Cut. The pieces
/// count, a dashed line from each shaded end shows which reaches further, the names become A/L and C/L; the record writes
/// each one renamed, then tap <, = or >, and the sign goes between the names.
@MainActor
struct CompareFractionsLesson: PaperLesson {
    /// The bars 3 squares apart (not the kit's 2), so the ? and then the sign stand clear between their names.
    static let y1 = 0.0, y2 = 7.0, rulerRow = 14.0
    var liveKeys: Set<String> { ["ruler"] }
    static let signs = CompareFractions.signs

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private func ruler(_ P: CompareFractions.Parts) -> Ruler {
        var r = Ruler(W: P.W, row: Self.rulerRow, from: Self.y1 - 1, to: Self.y2 + F4.h + 1,
                      old: [Ruler.Old(tag: 1, row: Self.y1 + F4.h + 1, at: (1..<P.b).map { Double($0 * P.p1) }),
                            Ruler.Old(tag: 2, row: Self.y2 + F4.h + 1, at: (1..<P.d).map { Double($0 * P.p2) })],
                      start: max(P.p1, P.p2))
        r.snaps = P.sizes; r.under = true
        r.readout = { Fractions4.piece(P.W / max(1, $0)) }
        r.reads = { Fractions4.cap(Fractions4.piece(P.W / max(1, $0))) }
        return r
    }
    /// The record's lines: each fraction renamed when its bottom changes.
    private func renamed(_ P: CompareFractions.Parts) -> Int { (P.L != P.b ? 1 : 0) + (P.L != P.d ? 1 : 0) }
    /// The choices' top, in the record's rows.
    private func choicesTop(_ P: CompareFractions.Parts) -> Double { 5 * Double(renamed(P)) + (renamed(P) > 0 ? 0 : 1) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = CompareFractions.Parts(s.numbers), at = stage(s), cut = at >= 2, done = at >= 3
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let W = Double(P.W)
        var actions: [String] = []
        if !cut {
            F4.bar(&pic, "t", y: Self.y1, W: P.W, d: P.b, on: P.a)
            F4.bar(&pic, "l", y: Self.y2, W: P.W, d: P.d, on: P.c, striped: true)
            if at == 1 { actions = ["Cut"]; ruler(P).draw(s, live: &live, still: &pic) }
        } else {
            F4.bar(&pic, "t", y: Self.y1, W: P.W, d: P.L, on: P.A)
            F4.bar(&pic, "l", y: Self.y2, W: P.W, d: P.L, on: P.C, striped: true)
            F4.counts(&pic, "tc", y: Self.y1, pw: Double(P.pL), P.A)
            F4.counts(&pic, "lc", y: Self.y2, pw: Double(P.pL), P.C)
            pic.line("g1", [(Double(P.A * P.pL), Self.y1 - 1), (Double(P.A * P.pL), Self.y2 + F4.h + 1)], .ink2, dashed: true)
            if P.C != P.A { pic.line("g2", [(Double(P.C * P.pL), Self.y1 - 1), (Double(P.C * P.pL), Self.y2 + F4.h + 1)], .ink2, dashed: true) }
            if at == 2 && s.on("ring") {
                // a hint: the shaded pieces of each bar, outlined
                pic.sketch.box("ring1", pic.R(-0.5, Self.y1 - 0.5, Double(P.A * P.pL) + 1, F4.h + 1), .chapter, width: Sketch.stroke, dashed: true)
                pic.sketch.box("ring2", pic.R(-0.5, Self.y2 - 0.5, Double(P.C * P.pL) + 1, F4.h + 1), .chapter, width: Sketch.stroke, dashed: true)
            }
        }
        // the names, and ? (then the sign) between them
        F4.frac(&pic, "n1", "\(cut ? P.A : P.a)", "\(cut ? P.L : P.b)", col: W + 1, line: Self.y1 + 2)
        F4.frac(&pic, "n2", "\(cut ? P.C : P.c)", "\(cut ? P.L : P.d)", col: W + 1, line: Self.y2 + 2)
        pic.word("sg\(done)", done ? Self.signs[P.k] : "?", at: W + 3, (Self.y1 + F4.h + Self.y2) / 2, Bars.maths.colour(done ? .chapter : .ink))

        // the record: each renamed fraction, the choices, then the answer
        if cut {
            var line = 2.0
            if P.L != P.b { F4.row(&rec, "r1", [.f("\(P.a)", "\(P.b)"), .op("="), .f("\(P.A)", "\(P.L)")], x: 0, line: line); line += 5 }
            if P.L != P.d { F4.row(&rec, "r2", [.f("\(P.c)", "\(P.d)"), .op("="), .f("\(P.C)", "\(P.L)")], x: 0, line: line); line += 5 }
            if at == 2 {
                Squares.choices(&rec, "ch", Self.signs, x: 0, y: choicesTop(P), bad: s.h("bad").map { Int($0.rounded()) })
            } else {
                F4.row(&rec, "r3", [.f("\(P.a)", "\(P.b)"), .op(Self.signs[P.k], .chapter), .f("\(P.c)", "\(P.d)")], x: 0, line: line)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, actions: actions,
                            extent: pic.R(0, 0, W + 5, at == 1 ? Self.rulerRow + 2 : Self.y2 + F4.h + 1))
    }

    /// The record comes once the ruler is put away: 3 rows under the bars.
    func recordRow(_ n: Numbers) -> Double? { Self.y2 + F4.h + 3 }

    func hands(_ s: PaperState) -> Hands? {
        let P = CompareFractions.Parts(s.numbers)
        switch stage(s) {
        case 1: return ruler(P).hands(s)
        case 2:
            let top = (recordRow(s.numbers) ?? 0) + choicesTop(P)
            return Hands(tap: { q in
                guard let i = Squares.choice(at: CGPoint(x: q.x, y: q.y - top), Self.signs, x: 0, y: 0) else { return nil }
                return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = CompareFractions.Parts(s.numbers)
        switch stage(s) {
        case 1: return ruler(P).demo(s, to: P.pL)
        case 2:
            let r = Squares.choiceRects(Self.signs, x: 0, y: (recordRow(s.numbers) ?? 0) + choicesTop(P))[P.k]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func messageRows(_ n: Numbers) -> Int { 1 }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = CompareFractions.Parts(s.numbers)
        switch stage(s) {
        case 1: return ruler(P).wrongMove(else: P.sizes.first { $0 < P.pL && P.W % $0 == 0 } ?? 1)
        case 2:
            // the sign the tops alone would give, when it's wrong; else the next one round
            let tops = CompareFractions.cmp(P.a, P.c), i = tops != P.k ? tops : (P.k + 1) % 3
            return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
        default: return nil
        }
    }
}
