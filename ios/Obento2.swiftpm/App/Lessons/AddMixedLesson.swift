import SwiftUI

/// Adding mixed numbers on the paper, as in the preview (design/prototype/grade4-ch5.html): w1 whole bars and an n1 bar
/// on the left; w2 and n2, striped, on the right, each number named under its column. Slide the striped wholes under the
/// left's (the left's part bar steps down to make room); slide the striped pieces into the left's part bar, where they
/// land after its shaded pieces, the count running on, spilling into a new bar past its end; tap the full bar and it
/// closes into a whole, the spill bar stepping up to be the part bar. The record grows under the names as the hands
/// find it (2 + 1 = 3, 3/5 + 4/5 = 7/5 = 1 2/5); then the names go into the problem, written with the answer's boxes.
@MainActor
struct AddMixedLesson: PaperLesson {
    var liveKeys: Set<String> { GroupSlide.liveKeys }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The picture's places, for a stage.
    private struct Lay {
        let P: AddMixed.Parts, at: Int
        var W: Double { Double(P.W) }
        var pw: Double { Double(P.pw) }
        var XR: Double { W + 4 }
        var movedW: Bool { at >= 2 }
        var dropped: Bool { at >= 3 }
        var traded: Bool { P.trade && at >= 4 }
        var partY: Double { M5.step * Double(P.w1 + (movedW ? P.w2 : 0)) + (traded ? M5.step : 0) }
        var spillY: Double { partY + 5 }
        var rpY: Double { M5.step * Double(P.w2) }
        /// The bottom of each column: its name goes 3 rows under it.
        var bottom: Double { (traded ? partY : P.trade && dropped ? spillY : partY) + F4.h }
        var rightBottom: Double { rpY + F4.h }
        /// Where striped piece i lands: its slot after the shaded pieces, in the part bar or the spill bar.
        func slot(_ i: Int) -> (x: Double, y: Double, label: Int)? {
            let k = P.n1 + i
            if traded && k < P.d { return nil }
            return (Double(k % P.d) * pw, k < P.d || traded ? partY : spillY, traded ? k - P.d + 1 : k + 1)
        }
    }
    func draw(_ s: PaperState) -> PaperDrawing {
        let P = AddMixed.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at), d = P.d, W = L.W, pw = L.pw, XR = L.XR
        let held = s.grabbed, writing = at >= 4, done = at >= 5
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let off = GroupSlide.offset(s)

        // the left's wholes, then the right's once slid over, then the traded one
        for j in 0..<P.w1 { M5.whole(&pic, "L\(j)", x: 0, y: M5.step * Double(j), W: W) }
        for j in 0..<P.w2 {
            if L.movedW {
                M5.whole(&pic, "R\(j)", x: 0, y: M5.step * Double(P.w1 + j), W: W, striped: true)
                M5.gone(&pic, "Rd\(j)", x: XR, y: M5.step * Double(j), W: W)
            } else if at == 1 && held {
                M5.whole(&live, "R\(j)", x: XR + off.x, y: M5.step * Double(j) + off.y, W: W, striped: true)
            } else {
                M5.whole(&pic, "R\(j)", x: XR, y: M5.step * Double(j), W: W, striped: true)
            }
        }
        if L.traded { M5.whole(&pic, "T", x: 0, y: M5.step * Double(P.Wt), W: W) }
        // the left's part bar (the spill bar becomes it once the full one is traded)
        if !L.traded {
            M5.frame(&pic, "lpb", x: 0, y: L.partY, W: P.W, d: d)
            for q in 0..<P.n1 {
                F4.piece(&pic, "lp\(q)", x: Double(q) * pw, y: L.partY, pw: pw)
                pic.word("lpn\(q)", "\(q + 1)", at: (Double(q) + 0.5) * pw, L.partY + F4.h / 2, Bars.count)
            }
        }
        if P.trade && L.dropped { M5.frame(&pic, "spb", x: 0, y: L.traded ? L.partY : L.spillY, W: P.W, d: d) }
        // the right's part bar and its striped pieces: held, they follow the finger; dropped, each in its slot
        M5.frame(&pic, "rpb", x: XR, y: L.rpY, W: P.W, d: d, dash: L.dropped)
        for i in 0..<P.n2 {
            if L.dropped {
                guard let p = L.slot(i) else { continue }
                F4.piece(&pic, "sp\(i)", x: p.x, y: p.y, pw: pw, striped: true)
                pic.word("spn\(i)", "\(p.label)", at: p.x + pw / 2, p.y + F4.h / 2, Bars.count)
            } else if at == 2 && held {
                F4.piece(&live, "sp\(i)", x: XR + Double(i) * pw + off.x, y: L.rpY + off.y, pw: pw, striped: true)
            } else {
                F4.piece(&pic, "sp\(i)", x: XR + Double(i) * pw, y: L.rpY, pw: pw, striped: true)
                pic.word("spn\(i)", "\(i + 1)", at: XR + (Double(i) + 0.5) * pw, L.rpY + F4.h / 2, Bars.count)
            }
        }
        if at == 2 && !held { pic.word("arrow", "←", at: XR - 2, L.rpY + F4.h / 2, Bars.maths.colour(.chapter)) }
        // the live readout
        if held && at == 1 { live.reads(s.h("in") == 1 ? Mixed4.wholes(P.Wt) : Mixed4.wholes(P.w2)) }
        if held && at == 2 { live.reads(s.h("in") == 1 ? Fractions4.pieces(P.S, d) : "\(P.n2)/\(d)") }
        // hints: where they go (dashed), the full bar (ringed)
        if at == 1 && !held && s.on("target") {
            for j in 0..<P.w2 { M5.target(&pic, "tg\(j)", x: 0, y: M5.step * Double(P.w1 + j), w: W, h: M5.wh + 1) }
        }
        if at == 2 && !held && s.on("target") {
            for i in 0..<P.n2 {
                let k = P.n1 + i
                M5.target(&pic, "tg\(i)", x: Double(k % d) * pw, y: k < d ? L.partY : L.spillY, w: pw, h: F4.h)
            }
        }
        if at == 3 && s.on("ring") { M5.ring(&pic, "ring", x: 0, y: L.partY, w: W, h: F4.h) }

        // the names, each under its column; the record in the right column once its wholes have gone (so the problem
        // shows at 75% or more): the wholes, the pieces, the trade, under the right's name
        // (once the pieces are in, the record holds both numbers' parts, so the names go and it moves up where the
        // right's name was: the tall column of a trade still shows at 75% or more)
        let Br = L.rightBottom, named = at < 3
        if named {
            M5.name(&pic, "nmA", M5.mixed(P.w1, P.n1, d), col: 0, W: W, line: L.bottom + 3)
            M5.name(&pic, "nmB", M5.mixed(P.w2, P.n2, d), col: XR, W: W, line: Br + 3)
        }
        let r1 = named ? Br + 8 : Br + 3
        if at >= 2 {
            let end = F4.row(&pic, "r1w", [.n(P.w1), .op("+"), .n(P.w2), .op("="), .n(P.Wt)], x: XR, line: r1)
            if at >= 3 {
                var toks: [F4.Tok] = [.f("\(P.n1)", "\(d)"), .op("+"), .f("\(P.n2)", "\(d)"), .op("="), .f("\(P.S)", "\(d)")]
                if L.traded { toks += [.op("="), .n(1), .f("\(P.R)", "\(d)")] }
                F4.row(&pic, "r1p", toks, x: end + 3, line: r1)
            }
        }
        // then the problem, the answer's boxes in it
        if writing {
            let ans: [F4.Tok] = done ? M5.mixed(P.total, P.R, d, .chapter) : [.box("W", cells: 1), .fb(top: .box("N"), bottom: .v(d))]
            F4.row(&rec, "r2", M5.mixed(P.w1, P.n1, d) + [.op("+")] + M5.mixed(P.w2, P.n2, d) + [.op("=")] + ans, x: XR, line: 2)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// In the right column: the problem under the record's line (r1 at B + 3 once the names have gone, the problem's
    /// line at B + 8, B the right column's bottom).
    func recordRow(_ n: Numbers) -> Double? { Lay(P: AddMixed.Parts(n), at: 5).rightBottom + 6 }
    func blocksLeft(_ n: Numbers) -> Double? { Double(AddMixed.Parts(n).W) + 4 }

    func hands(_ s: PaperState) -> Hands? {
        let P = AddMixed.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at), W = L.W
        switch at {
        case 1:
            return GroupSlide(from: CGRect(x: L.XR - 0.5, y: -0.5, width: W + 1, height: M5.step * Double(P.w2)),
                              over: { p in p.x >= -1 && p.x <= W + 1 }).hands()
        case 2:
            let partY = L.partY
            return GroupSlide(from: CGRect(x: L.XR - 0.5, y: L.rpY - 0.5, width: Double(P.n2) * L.pw + 1, height: F4.h + 1),
                              over: { p in p.x >= -1 && p.x <= W + 1 && p.y >= partY - 2 }).hands()
        case 3:
            let partY = L.partY, spillY = L.spillY
            return Hands(tap: { p in
                guard p.x >= 0, p.x <= W else { return nil }
                if p.y >= partY - 0.5 && p.y <= partY + F4.h + 0.5 { return HandMove(hand: nil, missHand: nil, set: [("t", 1)], check: true) }
                if p.y >= spillY - 0.5 && p.y <= spillY + F4.h + 0.5 { return HandMove(hand: nil, missHand: nil, set: [("t", -1)], check: true) }
                if p.y >= -0.5 && p.y < partY - 0.5 { return HandMove(hand: nil, missHand: nil, set: [("t", -2)], check: true) }
                return nil
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = AddMixed.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at), W = L.W
        switch at {
        case 1: return [.drag(from: CGPoint(x: L.XR + W / 2, y: 1), to: CGPoint(x: W / 2, y: M5.step * Double(P.w1) + 1))]
        case 2: return [.drag(from: CGPoint(x: L.XR + Double(P.n2) * L.pw / 2, y: L.rpY + 2), to: CGPoint(x: W / 2, y: L.partY + 2))]
        case 3: return [.tap(.picture(CGPoint(x: W / 2, y: L.partY + 2)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        switch stage(s) {
        case 1, 2: return HandMove(hand: [:], missHand: [:], set: [("s", 0)], check: true)
        // the spill bar tapped: it isn't full
        case 3: return HandMove(hand: nil, missHand: nil, set: [("t", -1)], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = AddMixed.Parts(s.numbers)
        guard stage(s) == 4 else { return nil }
        // the new whole lost; or, with no trade, a whole too many
        return P.trade ? ["W": Double(P.Wt), "N": Double(P.R)] : ["W": Double(P.Wt + 1), "N": Double(P.R)]
    }
}
