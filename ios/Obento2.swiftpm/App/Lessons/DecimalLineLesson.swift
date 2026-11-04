import SwiftUI

/// Decimals on a number line, as in the preview (design/prototype/grade4-ch6.html): Rounding decimals' two lines. Line 1
/// runs from a whole number to the next, ten blocks of 5 squares (a block is a tenth), the decimal waiting over its left
/// end. Tap the block it's in: it lights and opens below, a dashed funnel, into line 2, ten blocks of a hundredth; drag
/// the point along line 2 (it snaps to hundredths, the readout saying where it is). A tenths decimal is placed straight
/// on line 1's tick. Then the decimal goes into the record and the fraction is written, top and bottom.
@MainActor
struct DecimalLineLesson: PaperLesson {
    /// The decimal's row, line 1's, line 2's; a block; a line's length.
    static let nameRow = 1.0, y1 = 7.0, y2 = 19.0, B = 5.0, L = 50.0
    var liveKeys: Set<String> { ["at"] }
    private static let label = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The line the point is dragged along.
    private func lineY(_ P: DecimalLine.Parts) -> Double { P.tenOnly ? Self.y1 : Self.y2 }
    /// Where the point is meant to go, in steps of its line.
    private func goal(_ P: DecimalLine.Parts) -> Int { P.tenOnly ? P.t : P.u }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = DecimalLine.Parts(s.numbers), at = stage(s), y1 = Self.y1, y2 = Self.y2, B = Self.B, L = Self.L
        let open = !P.tenOnly && at >= 2, writing = at >= 3, done = at >= 4, t = Double(P.t)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ink = Self.label.colour(.ink2)

        // line 1: ten blocks of a tenth, named at its ends; the block tapped red when the number isn't in it; lit once
        // it's found
        if open { pic.fill("lit", col: t * B, row: y1 - 2, w: B, h: 2, .tint(0.42)) }
        if at == 1, let w = s.h("wrong") { pic.fill("wrong\(w)", col: w * B, row: y1 - 2, w: B, h: 2, RoundingLesson.wrongFill) }
        pic.numberLine("l1", col: 0, row: y1, steps: 10, per: B, long: 5)
        pic.label("l1lo", "\(P.w)\(P.unit)", ink, .below, edge: y1, along: 0)
        pic.label("l1hi", "\(P.w + 1)\(P.unit)", ink, .below, edge: y1, along: L)
        if at == 1 && s.on("spot") { D6.ring(&pic, "ring", x: t * B, y: y1 - 2, w: B, h: 2) }
        else if at == 1 && s.on("ring") { D6.ring(&pic, "ringl", x: 0, y: y1 - 2, w: L, h: 2) }

        // the point: on line 1 for a tenths decimal, else on line 2 once it's open
        let now = s.h("at") ?? 0
        if P.tenOnly {
            if done || writing { pic.dot("p1", at: t * B, y1, radius: 0.5, .chapter, over: true) }
            else if at == 2 { live.dot("p1", at: now * B, y1, radius: s.grabbed ? 0.7 : 0.5, .chapter, over: true) }
        } else if done { pic.dot("p1", at: Double(P.h) / 100 * L, y1, radius: 0.5, .chapter, over: true) }
        if open {
            pic.line("mgL", [(t * B, y1 + 3), (0, y2 - 4)], .chapter, dashed: true)
            pic.line("mgR", [(t * B + B, y1 + 3), (L, y2 - 4)], .chapter, dashed: true)
            pic.numberLine("l2", col: 0, row: y2, steps: 10, per: B, long: 5)
            pic.label("l2lo", Dec4.text(P.lo2) + P.unit, ink, .below, edge: y2, along: 0)
            pic.label("l2hi", Dec4.text(P.lo2 + 10) + P.unit, ink, .below, edge: y2, along: L)
            if writing { pic.dot("p2", at: Double(P.u) * B, y2, radius: 0.5, .chapter, over: true) }
            else { live.dot("p2", at: now * B, y2, radius: s.grabbed ? 0.7 : 0.5, .chapter, over: true) }
        }
        let Y = lineY(P)
        if at == 2 && !s.grabbed && now == 0 && s.on("ring") == false {
            pic.word("arrow", "→", at: 2.5, Y - 3, Bars.maths.colour(.chapter))
        }
        if at == 2 && s.on("spot") { pic.circle("ring2", at: Double(goal(P)) * B, Y, radius: 1.3, .chapter, dashed: true) }
        else if at == 2 && s.on("ring") { D6.ring(&pic, "ringl2", x: 0, y: Y - 2, w: L, h: 2) }
        if at == 2 && s.grabbed { live.reads(P.at(Int(now.rounded()))) }

        // the decimal over line 1's left end, then into the record, and the fraction written
        let nm: [F4.Tok] = [.d(P.X)]
        if !writing { F4.row(&pic, "nm", nm, x: 0, line: Self.nameRow) }
        else {
            let x = F4.row(&rec, "nm", nm, x: 0, line: 2)
            var toks: [F4.Tok] = [.op("=")]
            if !done { toks.append(.fr(top: .box("T"), bottom: .box("B"), w: 6, cells: 3)) }
            else {
                let ans: F4.Tok = .f("\(P.H)", "100", .chapter, w: 5)
                switch P.kind {
                case .plain: toks += [.f("\(P.t)", "10"), .op("+"), .f("\(P.u)", "100", w: 5), .op("="), ans]
                case .whole: toks += [.n(P.w), .op("+"), .f("\(P.t)", "10"), .op("+"), .f("\(P.u)", "100", w: 5), .op("="), ans]
                case .under: toks.append(ans)
                case .tenths: toks += [.f("\(P.t)", "10", .chapter), .op("="), .f("\(P.h)", "100", .chapter, w: 5)]
                }
            }
            F4.row(&rec, "rec", toks, x: x, line: 2)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// The record 4 rows under the line the point was placed on.
    func recordRow(_ n: Numbers) -> Double? { lineY(DecimalLine.Parts(n)) + 4 }

    func hands(_ s: PaperState) -> Hands? {
        let P = DecimalLine.Parts(s.numbers), B = Self.B, Y = lineY(P)
        switch stage(s) {
        case 1:
            return Hands(tap: { q in
                guard q.y > Self.y1 - 3.5, q.y < Self.y1 + 2, q.x > -0.5, q.x < Self.L + 0.5 else { return nil }
                let b = Double(min(9, max(0, Int((q.x / B).rounded(.down)))))
                return HandMove(hand: [:], missHand: ["wrong": b], set: [("b", b)], check: true)
            })
        case 2:
            let now = s.h("at") ?? 0
            return Hands(grab: { q in abs(q.x - now * B) < 2.5 && abs(q.y - Y) < 2.5 ? ["grab": 1, "at": now, "from": now] : nil },
                         drag: { q, h in ["grab": 1, "at": min(10, max(0, (q.x / B).rounded())), "from": h["from"] ?? now] },
                         release: { h in
                             let at = h["at"] ?? 0
                             // let go where it was picked up: nothing to check
                             if at == h["from"] { return HandMove(hand: ["at": at], missHand: nil) }
                             return HandMove(hand: ["at": at], missHand: nil, set: [("p", at)], check: true)
                         })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = DecimalLine.Parts(s.numbers), B = Self.B
        switch stage(s) {
        case 1: return [.tap(.picture(CGPoint(x: (Double(P.t) + 0.5) * B, y: Self.y1 - 1)))]
        case 2: return [.drag(from: CGPoint(x: (s.h("at") ?? 0) * B, y: lineY(P)), to: CGPoint(x: Double(goal(P)) * B, y: lineY(P)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = DecimalLine.Parts(s.numbers)
        switch stage(s) {
        case 1:
            let b = Double((P.t + 3) % 10)
            return HandMove(hand: [:], missHand: ["wrong": b], set: [("b", b)], check: true)
        case 2:
            let p = Double(goal(P) == 10 ? 8 : goal(P) + 2)
            return HandMove(hand: ["at": p], missHand: nil, set: [("p", p)], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = DecimalLine.Parts(s.numbers)
        guard stage(s) == 3 else { return nil }
        switch P.kind {
        case .tenths: return ["T": Double(P.t), "B": 100]
        case .under: return ["T": Double(P.u), "B": 10]
        default: return ["T": Double(10 * P.w + P.t), "B": 10]
        }
    }
}
