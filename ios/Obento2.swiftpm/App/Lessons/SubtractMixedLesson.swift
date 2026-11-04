import SwiftUI

/// Subtracting mixed numbers on the paper, as in the preview (design/prototype/grade4-ch5.html): the first number's bars
/// on the left, the second's, striped, on the right, each named under its column. Slide the striped pieces onto the
/// shaded ones: they land from the right and cross them out, what's left counting down. Too few, the slide stops; tap a
/// whole and it grows into a bar of its pieces (the part bar steps down), the left renamed (3 2/5 = 2 7/5, into the
/// record); slide again. Then the striped wholes slide onto the left's wholes and cross them out, and what's left is
/// written.
@MainActor
struct SubtractMixedLesson: PaperLesson {
    var liveKeys: Set<String> { GroupSlide.liveKeys }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private struct Lay {
        let P: SubtractMixed.Parts, at: Int
        var W: Double { Double(P.W) }
        var pw: Double { Double(P.pw) }
        var XR: Double { W + 4 }
        var opened: Bool { P.need && at >= 3 }
        var takenP: Bool { at >= 4 }
        var takenW: Bool { at >= 5 }
        /// The last whole's row (opened, it's a bar of its pieces), and the part bar's.
        var oY: Double { M5.step * Double(P.w1 - 1) }
        var partY: Double { opened ? oY + 5 : M5.step * Double(P.w1) }
        var rpY: Double { M5.step * Double(P.w2) }
        /// The shaded pieces in order: the opened whole's, then the part bar's.
        var slots: [(x: Double, y: Double)] {
            (opened ? (0..<P.d).map { (Double($0) * pw, oY) } : []) + (0..<P.n1).map { (Double($0) * pw, partY) }
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = SubtractMixed.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at), d = P.d, W = L.W, pw = L.pw, XR = L.XR
        let held = s.grabbed, writing = at >= 5, done = at >= 6, slots = L.slots, T = slots.count
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let off = GroupSlide.offset(s)
        // the pieces being taken: on the step that slides them (onto the shaded pieces once over them), or after
        let sliding = (at == 1 || at == 3) && held, over = sliding && s.h("in") == 1 && (L.opened || !P.need)

        // the left's wholes; the last one, opened, is a bar of its pieces
        for j in 0..<P.w1 {
            let y = M5.step * Double(j)
            if L.opened && j == P.w1 - 1 {
                M5.frame(&pic, "op", x: 0, y: y, W: P.W, d: d)
                for q in 0..<d { F4.piece(&pic, "o\(q)", x: Double(q) * pw, y: y, pw: pw) }
            } else { M5.whole(&pic, "L\(j)", x: 0, y: y, W: W) }
        }
        // the part bar
        M5.frame(&pic, "lpb", x: 0, y: L.partY, W: P.W, d: d)
        for q in 0..<P.n1 { F4.piece(&pic, "lp\(q)", x: Double(q) * pw, y: L.partY, pw: pw) }
        // the shaded pieces counted; the ones covered lose their number
        let covered = L.takenP || over ? Set((T - P.n2)..<T) : []
        for (q, p) in slots.enumerated() where !covered.contains(q) {
            pic.word("sn\(q)", "\(q + 1)", at: p.x + pw / 2, p.y + F4.h / 2, Bars.count)
        }
        // the right: striped wholes, taken onto the left's and crossed out
        for j in 0..<P.w2 {
            let y = M5.step * Double(j)
            if L.takenW {
                M5.whole(&pic, "R\(j)", x: 0, y: y, W: W, striped: true, crossed: true)
                M5.gone(&pic, "Rd\(j)", x: XR, y: y, W: W)
            } else if at == 4 && held {
                M5.whole(&live, "R\(j)", x: XR + off.x, y: y + off.y, W: W, striped: true)
            } else { M5.whole(&pic, "R\(j)", x: XR, y: y, W: W, striped: true) }
        }
        // the right's part bar and its striped pieces
        M5.frame(&pic, "rpb", x: XR, y: L.rpY, W: P.W, d: d, dash: L.takenP)
        for i in 0..<P.n2 {
            if L.takenP {
                let p = slots[T - P.n2 + i]
                F4.piece(&pic, "sp\(i)", x: p.x, y: p.y, pw: pw, striped: true, crossed: true)
            } else if over {
                let p = slots[T - P.n2 + i]
                F4.piece(&live, "sp\(i)", x: p.x, y: p.y, pw: pw, striped: true, crossed: true)
            } else if sliding {
                F4.piece(&live, "sp\(i)", x: XR + Double(i) * pw + off.x, y: L.rpY + off.y, pw: pw, striped: true)
            } else {
                F4.piece(&pic, "sp\(i)", x: XR + Double(i) * pw, y: L.rpY, pw: pw, striped: true)
                pic.word("spn\(i)", "\(i + 1)", at: XR + (Double(i) + 0.5) * pw, L.rpY + F4.h / 2, Bars.count)
            }
        }
        if (at == 1 || at == 3) && !held { pic.word("arrow", "←", at: XR - 2, L.rpY + F4.h / 2, Bars.maths.colour(.chapter)) }
        // the live readout
        if sliding { live.reads(s.h("in") != 1 ? "\(P.n2)/\(d)" : P.need && !L.opened ? Fractions4.pieces(P.n1, d) : "\(Fractions4.pieces(P.R, d)) left") }
        if held && at == 4 { live.reads(s.h("in") == 1 ? "\(Mixed4.wholes(P.w1 - P.w2 - (P.need ? 1 : 0))) left" : Mixed4.wholes(P.w2)) }
        // hints: where they go (dashed); the whole to open (ringed)
        if (at == 1 || at == 3) && !held && s.on("target") && (L.opened || !P.need) {
            for i in 0..<P.n2 { let p = slots[T - P.n2 + i]; M5.target(&pic, "tg\(i)", x: p.x, y: p.y, w: pw, h: F4.h) }
        }
        if at == 2 && s.on("ring") { M5.ring(&pic, "ring", x: 0, y: L.oY, w: W, h: M5.wh) }
        if at == 4 && !held && s.on("target") {
            for j in 0..<P.w2 { M5.target(&pic, "tg\(j)", x: 0, y: M5.step * Double(j), w: W, h: M5.wh + 1) }
        }

        // the names, each under its column; opening a whole renames the left (into the record); then the problem. The
        // record is in the right column, under its name (so the problem shows at 75% or more)
        let Br = L.rpY + F4.h
        let A = L.opened ? M5.mixed(P.w1 - 1, P.n1 + d, d) : M5.mixed(P.w1, P.n1, d)
        if !writing {
            M5.name(&pic, "nmA", A, col: 0, W: W, line: L.partY + F4.h + 3)
            M5.name(&pic, "nmB", M5.mixed(P.w2, P.n2, d), col: XR, W: W, line: Br + 3)
        }
        if L.opened {
            F4.row(&pic, "r1", M5.mixed(P.w1, P.n1, d) + [.op("=")] + M5.mixed(P.w1 - 1, P.n1 + d, d), x: XR, line: writing ? Br + 3 : Br + 8)
        }
        if writing {
            let ans: [F4.Tok] = done ? M5.mixed(P.Wa, P.R, d, .chapter)
                : (P.Wa > 0 ? [.box("W", cells: 1)] : []) + [.fb(top: .box("N"), bottom: .v(d))]
            F4.row(&rec, "r2", A + [.op("−")] + M5.mixed(P.w2, P.n2, d) + [.op("=")] + ans, x: XR, line: 2)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// In the right column where its name was (B + 3, B its bottom), or with a whole opened under the renaming line (the
    /// problem at B + 8).
    func recordRow(_ n: Numbers) -> Double? {
        let P = SubtractMixed.Parts(n), B = Lay(P: P, at: 6).rpY + F4.h
        return P.need ? B + 6 : B + 1
    }
    func blocksLeft(_ n: Numbers) -> Double? { Double(SubtractMixed.Parts(n).W) + 4 }

    func hands(_ s: PaperState) -> Hands? {
        let P = SubtractMixed.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at), W = L.W
        let pieces = CGRect(x: L.XR - 0.5, y: L.rpY - 0.5, width: Double(P.n2) * L.pw + 1, height: F4.h + 1)
        let top = (L.opened ? L.oY : L.partY) - 2
        // a whole bar tapped (on the first slide: it opens one when there are too few, a miss when there are enough)
        func onWhole(_ p: CGPoint) -> Bool {
            p.x >= 0 && p.x <= W && (0..<P.w1).contains { j in p.y >= M5.step * Double(j) - 0.5 && p.y <= M5.step * Double(j) + M5.wh + 0.5 }
        }
        switch at {
        case 1:
            return GroupSlide(from: pieces, over: { p in p.x >= -1 && p.x <= W + 1 && p.y >= top }, value: P.need ? 2 : 1).hands(tap: { p in
                guard onWhole(p) else { return nil }
                return P.need ? HandMove(hand: [:], missHand: nil, set: [("s", 3)], keep: ["opened": 1], check: true)
                              : HandMove(hand: [:], missHand: [:], set: [("s", -1)], check: true)
            })
        case 2:
            return Hands(tap: { p in onWhole(p) ? HandMove(hand: [:], missHand: nil, set: [("o", 1)], keep: ["opened": 1], check: true) : nil })
        case 3:
            return GroupSlide(from: pieces, over: { p in p.x >= -1 && p.x <= W + 1 && p.y >= top }).hands()
        case 4:
            return GroupSlide(from: CGRect(x: L.XR - 0.5, y: -0.5, width: W + 1, height: M5.step * Double(P.w2)),
                              over: { p in p.x >= -1 && p.x <= W + 1 }).hands()
        default: return nil
        }
    }

    /// A whole opened on the first slide (tapped before sliding): the step that opens one is passed.
    func autoAnswer(_ s: PaperState) -> [String: Double]? {
        stage(s) == 2 && (s.run.kept["opened"] ?? 0) == 1 ? ["o": 1] : nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = SubtractMixed.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at), W = L.W
        let from = CGPoint(x: L.XR + Double(P.n2) * L.pw / 2, y: L.rpY + 2)
        switch at {
        case 1, 3: return [.drag(from: from, to: CGPoint(x: W / 2, y: L.partY + 2))]
        case 2: return [.tap(.picture(CGPoint(x: W / 2, y: L.oY + 1)))]
        case 4: return [.drag(from: CGPoint(x: L.XR + W / 2, y: 1), to: CGPoint(x: W / 2, y: 1))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = SubtractMixed.Parts(s.numbers)
        switch stage(s) {
        // with enough pieces, a whole tapped first; else let go off the bars
        case 1: return P.need ? HandMove(hand: [:], missHand: [:], set: [("s", 0)], check: true) : HandMove(hand: [:], missHand: [:], set: [("s", -1)], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("o", 0)], check: true)
        case 3, 4: return HandMove(hand: [:], missHand: [:], set: [("s", 0)], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = SubtractMixed.Parts(s.numbers)
        guard stage(s) == 5 else { return nil }
        // the opened whole forgotten (or, with enough pieces, one piece out)
        let w = P.need ? P.w1 - P.w2 : P.Wa
        return P.need ? (P.Wa > 0 ? ["W": Double(w), "N": Double(P.R)] : ["N": Double(P.n2 - P.n1)]) : ["W": Double(w), "N": Double(P.R + 1)]
    }
}
