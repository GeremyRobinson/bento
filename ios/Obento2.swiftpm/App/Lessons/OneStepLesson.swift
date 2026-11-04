import SwiftUI

/// One-step equations on the paper, as in the preview (design/prototype/grade6-ch6.html, dOne): an equation is two
/// sides that balance. A cell is one (4 squares while the picture is small, else 2; a quarter or a half in the extra
/// type). x + 7 = 15: x and 7 cells over 15 cells; slide the 7 off the end, and the right side's last 7 cross off with it.
/// x − 7 = 8: x with 7 cells crossed off its end over 8 cells; slide a tray of 7 onto the bottom's end and the crossed
/// ones come back. 3x = 27: 3 rows of x beside a rectangle 3 rows tall; drag its right edge until all 27 are used: one
/// row is one x. x ÷ 3 = 4: x as 3 rows (one shaded) beside a row of 4; drag the bottom edge down to 3 rows. Then write
/// x, and check it in the record under the picture.
///
/// The picture's squares: the top bar (or the rows) from row 0. Hand keys: "h" (1 the piece, 2 the bottom bar, 3 the
/// tray, 4 an edge), "g" (where it was grabbed), "d" (cells slid), "w" (columns), "k" (rows).
@MainActor
struct OneStepLesson: PaperLesson {
    var liveKeys: Set<String> { ["grab", "h", "g", "d", "w", "k"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    struct Shape {
        let P: OneStep6.Parts
        init(_ n: Numbers) { P = OneStep6.Parts(n) }
        static func up5(_ v: Double) -> Double { (v / 5).rounded(.up) * 5 }
        /// The rows' width in cells (÷: the right side's).
        var W: Int { P.kind == 3 ? P.xc : P.X }
        /// Squares a cell: 4 while the picture stays small, else 2.
        /// (+ and −: 4 only while the cells slid off, or the tray waiting beside x, still fit 60 squares across, so the
        /// problem shows at 75%.)
        var C: Double {
            if !P.bars { return P.a <= 4 && W <= 6 ? 4 : 2 }
            let across = P.kind == 0 ? 4 * Double(P.Q + P.a + 1) : Shape.up5(4 * Double(P.X) + 3) + 4 * Double(P.a)
            return max(P.X, P.Q) <= 11 && across <= 60 ? 4 : 2
        }
        /// The bottom bar's top row; the right side's left column (× and ÷); the tray's (−).
        var BB: Double { C + 1 }
        var RX: Double { P.bars ? 0 : Shape.up5(C * Double(W) + 5) }
        var TX: Double { Shape.up5(C * Double(P.X) + 3) }
        /// The picture's bottom; the record's first row (a row lower when "a cell is 1/4" is written under the picture).
        var bottom: Double { P.bars ? BB + C : C * Double(P.kind == 3 ? max(P.a, 1) : P.a) }
        var recTop: Double { bottom + (P.cv != 1 ? 4 : 3) }
        /// The most columns (×) and rows (÷) an edge drags to.
        var wMax: Int { max(P.X + 3, (P.Q + 3 * P.a) / P.a) }
        var kMax: Int { P.a + 1 }
        /// How far right anything goes.
        var right: Double {
            switch P.kind {
            case 0: return C * Double(P.Q + P.a + 1)
            case 1: return TX + C * Double(P.a)
            case 2: return RX + C * Double(wMax)
            default: return RX + C * Double(W) + 8
            }
        }
        var tall: Double { P.kind == 3 ? C * Double(kMax) : bottom }
    }

    func recordRow(_ n: Numbers) -> Double? { Shape(n).recTop }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), C = S.C
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let undone = at >= 2, held = at == 1 && s.grabbed ? Int(s.h("h") ?? 0) : 0
        let X = Double(P.X), Q = Double(P.Q), a = Double(P.a)
        func xLabel(_ pen: inout GridPen, _ id: String, at x: Double, _ y: Double) { pen.word(id, "x", at: x, y, E6.words) }

        switch P.kind {
        case 0:
            // x and the a cells over Q cells; the a slides off the end, the right side's last a cross off with it
            X6.strip(&pic, "xs", x: 0, y: 0, len: C * X, h: C, label: nil)
            xLabel(&pic, "xl", at: C * X / 2, C / 2)
            let d = held == 1 ? s.h("d") ?? 0 : undone ? a + 1 : 0
            let crossN = held == 1 ? min(Int(d), P.a) : undone ? P.a : 0, bd = held == 2 ? s.h("d") ?? 0 : 0
            if held == 1 { E6.cells(&live, "pc", x: C * X + C * d, y: 0, n: P.a, c: C) }
            else { E6.cells(&pic, "pc\(undone)", x: C * X + C * d, y: 0, n: P.a, c: C, crossFrom: undone ? 0 : nil) }
            if held == 1 || held == 2 {
                E6.cells(&live, "bq", x: 0, y: S.BB, n: P.Q - (bd > 0 ? P.a : 0), c: C, crossFrom: crossN > 0 ? P.Q - crossN : nil)
                if bd > 0 { E6.cells(&live, "bm", x: C * (Q - a) + C * bd, y: S.BB, n: P.a, c: C) }
            } else {
                E6.cells(&pic, "bq\(undone)", x: 0, y: S.BB, n: P.Q, c: C, crossFrom: undone ? P.Q - P.a : nil)
            }
            if held == 1 && d > 0 {
                let r = "− \(P.pS) on both"
                live.word("rd", r, at: C * X + C * d + C * a + 1, C / 2, E6.lit, anchor: UnitPoint(x: 0, y: 0.5)); live.reads(r)
            }
        case 1:
            // x with a cells crossed off its end, over Q cells; a tray of a slides onto the bottom's end
            let d = held == 3 ? s.h("d") ?? 0 : undone ? (C * Q - S.TX) / C : 0
            let on = undone || (held == 3 && abs(S.TX + C * d - C * Q) <= C)
            X6.strip(&pic, "xs", x: 0, y: 0, len: C * X, h: C, label: nil)
            xLabel(&pic, "xl", at: C * Q / 2, C / 2)
            if !undone {
                if held == 3 { E6.cells(&live, "xc", x: C * Q, y: 0, n: P.a, c: C, crossFrom: on ? nil : 0) }
                else { E6.cells(&pic, "xc", x: C * Q, y: 0, n: P.a, c: C, crossFrom: 0) }
            }
            let bd = held == 2 ? s.h("d") ?? 0 : 0, moved = min(P.a, P.Q)
            if held == 2 {
                E6.cells(&live, "bq", x: 0, y: S.BB, n: P.Q - moved, c: C)
                E6.cells(&live, "bm", x: C * Double(P.Q - moved) + C * bd, y: S.BB, n: moved, c: C)
            } else { E6.cells(&pic, "bq", x: 0, y: S.BB, n: P.Q, c: C) }
            if held == 3 { E6.cells(&live, "tr", x: S.TX + C * d, y: S.BB, n: P.a, c: C, strong: true) }
            else { E6.cells(&pic, "tr\(undone)", x: S.TX + C * d, y: S.BB, n: P.a, c: C, strong: true) }
            if held == 3 && on {
                let r = "+ \(P.pS) on both"
                live.word("rd", r, at: S.TX + C * d + C * a + 1, S.BB + C / 2, E6.lit, anchor: UnitPoint(x: 0, y: 0.5)); live.reads(r)
            }
        case 2:
            // a rows of x beside a rectangle a rows tall whose width is found
            for r in 0..<P.a {
                X6.strip(&pic, "xs\(r)", x: 0, y: C * Double(r), len: C * X, h: C, label: "x")
            }
            pic.word("eq", "=", at: (C * X + S.RX) / 2, C * a / 2, E6.maths)
            let w = undone ? X : s.h("w") ?? 1
            var pen = held == 4 ? live : pic
            for r in 0..<P.a { E6.cells(&pen, "m\(r)", x: S.RX, y: C * Double(r), n: Int(w), c: C, strong: undone && r == 0) }
            if held == 4 { live = pen } else { pic = pen }
            if !undone { R6.handle(&live, "hd", S.RX + C * w, C * a / 2, held: held == 4) }
            if held == 4 {
                let used = P.a * Int(w), r = used <= P.Q ? "\(P.V(used)) used, \(P.V(P.Q - used)) left" : "\(P.V(used)): only \(P.V(P.Q))"
                live.word("rd", r, at: S.RX, C * a + 1.2, E6.lit, anchor: UnitPoint(x: 0, y: 0.5)); live.reads(r)
            }
        default:
            // x: a rows, one shaded, its end dashed (its length is the row of cells beside it)
            let xc = Double(P.xc)
            pic.fill("xr", col: 0, row: C, w: C * xc, h: C * (a - 1), .tint(0.22))
            pic.fill("xr0", col: 0, row: 0, w: C * xc, h: C, .tint(0.42))
            pic.line("xe", [(C * xc, 0), (0, 0), (0, C * a), (C * xc, C * a)], .chapter)
            pic.line("xd", [(C * xc, 0), (C * xc, C * a)], .chapter, dashed: true)
            pic.line("x1", [(0, C), (C * xc, C)], .chapter)
            xLabel(&pic, "xl", at: C * xc / 2, (C * a + C) / 2)
            pic.word("eq", "=", at: (C * xc + S.RX) / 2, C / 2, E6.maths)
            let k = undone ? a : s.h("k") ?? 1
            var pen = held == 4 ? live : pic
            for r in 0..<Int(k) { E6.cells(&pen, "d\(r)", x: S.RX, y: C * Double(r), n: P.xc, c: C, strong: r == 0) }
            if held == 4 { live = pen } else { pic = pen }
            if !undone { R6.handle(&live, "hd", S.RX + C * xc / 2, C * k, held: held == 4) }
            if held == 4 {
                let r = "\(Int(k)) row\(k == 1 ? "" : "s") · \(fmt(k * xc))"
                live.word("rd", r, at: S.RX + C * xc + 1, C * k - 1, E6.lit, anchor: UnitPoint(x: 0, y: 0.5)); live.reads(r)
            }
        }
        if P.cv != 1 { pic.word("cv", "a cell is \(P.cv == 0.25 ? "¼" : "½")", at: 0, S.bottom + 1.3, E6.small, anchor: UnitPoint(x: 0, y: 0.5)) }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        hints(s, S, at, &pic)

        // the record: the equation, x, the check
        // a line with a fraction in it is 4 rows tall: the lines go 5 apart then
        let gap = P.fr ? 5.0 : 3.0, b = P.fr ? 1.0 : 0.0, ys = (b, b + gap, b + 2 * gap)
        M7.row(&rec, "r0", equation(P), x: 0, line: 1 + ys.0)
        if at >= 2 {
            let toks: [M7.Tok]
            if at > 2 { toks = [.t("x"), .op("=")] + E6.value(P, P.X, .chapter) }
            else if P.fr { toks = [.t("x"), .op("=")] + (P.xParts.w != nil ? [.box("w", cells: 1)] : []) + [.fb("n", "d")] }
            else { toks = [.t("x"), .op("="), .box("x", cells: max(2, P.xS.count))] }
            M7.row(&rec, "r1", toks, x: 0, line: 1 + ys.1)
        }
        if at >= 3 {
            let xv = E6.value(P, P.X, then: true), pv = P.bars ? E6.value(P, P.a, then: true) : [M7.Tok.n(P.a)]
            let left: [M7.Tok] = [xv + [.op("+")] + pv, xv + [.op("−")] + pv, pv + [.op("×")] + xv, xv + [.op("÷")] + pv][P.kind]
            let ans: M7.Tok = at > 3 ? .t(P.qS, .chapter) : .box("q", cells: max(2, P.qS.count))
            M7.row(&rec, "r2", left + [.op("="), ans], x: 0, line: 1 + ys.2)
            if at == 3 && s.on("ring") { R6.ring(&rec, "ring", x: 0, y: ys.2, w: M7.width(left), h: 2) }
            if at == 3 && s.on("spot") { R6.ring(&rec, "spot", x: M7.width(equation(P)) - M7.width(rightSide(P)), y: ys.0, w: M7.width(rightSide(P)), h: 2) }
        }
        let ext = pic.R(-1, -1, S.right + 2, S.tall + 2)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    private func rightSide(_ P: OneStep6.Parts) -> [M7.Tok] { P.kind == 3 ? [.t(P.qS)] : E6.value(P, P.Q) }
    private func equation(_ P: OneStep6.Parts) -> [M7.Tok] {
        let pv = E6.value(P, P.a, then: true)
        let left: [M7.Tok] = [[.t("x"), .op("+")] + pv, [.t("x"), .op("−")] + pv, [.t("\(P.a)x")], [.t("x"), .op("÷"), .n(P.a)]][P.kind]
        return left + [.op("=")] + rightSide(P)
    }

    private func hints(_ s: PaperState, _ S: Shape, _ at: Int, _ pic: inout GridPen) {
        let P = S.P, C = S.C, X = Double(P.X), Q = Double(P.Q), a = Double(P.a)
        if at == 1 {
            if s.on("ring") {
                switch P.kind {
                case 0: R6.ring(&pic, "ring", x: C * X, y: 0, w: C * a, h: C)
                case 1: R6.ring(&pic, "ring", x: S.TX, y: S.BB, w: C * a, h: C)
                case 2: R6.ring(&pic, "ring", x: S.RX, y: 0, w: C * Double(S.wMax), h: C * a)
                default: R6.ring(&pic, "ring", x: S.RX, y: 0, w: C * Double(P.xc), h: C * Double(S.kMax))
                }
            }
            if s.on("spot") {
                switch P.kind {
                case 0: pic.sketch.box("spot", pic.R(C * (Q - a), S.BB, C * a, C), .chapter, width: Sketch.stroke, dashed: true)
                case 1: pic.sketch.box("spot", pic.R(C * Q, S.BB, C * a, C), .chapter, width: Sketch.stroke, dashed: true)
                case 2: pic.line("spot", [(S.RX + C * X, -0.8), (S.RX + C * X, C * a + 0.8)], .chapter, dashed: true)
                default: pic.line("spot", [(S.RX - 0.8, C * a), (S.RX + C * Double(P.xc) + 0.8, C * a)], .chapter, dashed: true)
                }
            }
        }
        if at == 2 {
            // the part that is x: ringed, then its value written under it
            let r: CGRect = {
                switch P.kind {
                case 0: return CGRect(x: 0, y: S.BB, width: C * X, height: C)
                case 1: return CGRect(x: 0, y: S.BB, width: C * X, height: C)
                case 2: return CGRect(x: S.RX, y: 0, width: C * X, height: C)
                default: return CGRect(x: S.RX, y: 0, width: C * Double(P.xc), height: C * a)
                }
            }()
            if s.on("ring") { R6.ring(&pic, "ring", x: r.minX, y: r.minY, w: r.width, h: r.height) }
            if s.on("spot") { pic.label("spot", "x = \(P.xS)", E6.lit, .below, edge: r.maxY + 0.6, along: r.midX) }
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), P = S.P, C = S.C, at = stage(s)
        guard at == 1 else { return nil }
        let X = Double(P.X), Q = Double(P.Q), a = Double(P.a)
        func inRow(_ q: CGPoint, _ y0: Double) -> Bool { q.y > y0 - 1 && q.y < y0 + C + 1 }
        switch P.kind {
        case 0, 1:
            return Hands(grab: { q in
                if P.kind == 0, inRow(q, 0), q.x > C * X - 0.5, q.x < C * Q + 0.5 { return ["grab": 1, "h": 1, "g": q.x, "d": 0] }
                if P.kind == 1, inRow(q, S.BB), q.x > S.TX - 0.5, q.x < S.TX + C * a + 0.5 { return ["grab": 1, "h": 3, "g": q.x, "d": 0] }
                let lo = P.kind == 0 ? C * (Q - a) : C * Q - 4
                if inRow(q, S.BB), q.x > lo, q.x < C * Q + 0.5 { return ["grab": 1, "h": 2, "g": q.x, "d": 0] }
                return nil
            }, drag: { q, h in
                var h = h, d = ((q.x - (h["g"] ?? 0)) / C).rounded()
                switch Int(h["h"] ?? 0) {
                case 3: d = min(0, max(((C * Q - S.TX) / C).rounded(.down) - 2, d))
                default: d = min(a + 3, max(0, d))
                }
                h["d"] = d; return h
            }, release: { h in
                let d = h["d"] ?? 0
                switch Int(h["h"] ?? 0) {
                case 1:
                    if d == 0 { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], set: [("u", d >= a ? a : d)], check: true)
                case 3:
                    if d == 0 { return HandMove(hand: [:]) }
                    let on = abs(S.TX + C * d - C * Q) <= C
                    return HandMove(hand: [:], set: [("u", on ? a : 0)], check: true)
                default:
                    if d == 0 { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], set: [("u", -1)], check: true)
                }
            })
        case 2:
            let now = s.h("w") ?? 1
            return Hands(grab: { q in
                abs(q.x - (S.RX + C * now)) < 1.8 && q.y > -1 && q.y < C * a + 1 ? ["grab": 1, "h": 4, "w": now] : nil
            }, drag: { q, h in
                var h = h; h["w"] = Double(min(S.wMax, max(1, Int(((q.x - S.RX) / C).rounded())))); return h
            }, release: { h in
                let w = h["w"] ?? now
                return HandMove(hand: ["w": w], missHand: ["w": w], set: [("u", w)], check: true)
            })
        default:
            let now = s.h("k") ?? 1, xc = Double(P.xc)
            return Hands(grab: { q in
                abs(q.y - C * now) < 1.8 && q.x > S.RX - 1 && q.x < S.RX + C * xc + 1 ? ["grab": 1, "h": 4, "k": now] : nil
            }, drag: { q, h in
                var h = h; h["k"] = Double(min(S.kMax, max(1, Int((q.y / C).rounded())))); return h
            }, release: { h in
                let k = h["k"] ?? now
                return HandMove(hand: ["k": k], missHand: ["k": k], set: [("u", k)], check: true)
            })
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), P = S.P, C = S.C
        guard stage(s) == 1 else { return [] }
        let X = Double(P.X), Q = Double(P.Q), a = Double(P.a)
        switch P.kind {
        case 0: let x0 = C * X + C * a / 2; return [.drag(from: CGPoint(x: x0, y: C / 2), to: CGPoint(x: x0 + C * (a + 1), y: C / 2))]
        case 1: return [.drag(from: CGPoint(x: S.TX + C * a / 2, y: S.BB + C / 2), to: CGPoint(x: C * Q + C * a / 2, y: S.BB + C / 2))]
        case 2: let w = s.h("w") ?? 1; return [.drag(from: CGPoint(x: S.RX + C * w, y: C * a / 2), to: CGPoint(x: S.RX + C * X, y: C * a / 2))]
        default:
            let k = s.h("k") ?? 1, x = S.RX + C * Double(P.xc) / 2
            return [.drag(from: CGPoint(x: x, y: C * k), to: CGPoint(x: x, y: C * a))]
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = OneStep6.Parts(s.numbers)
        guard stage(s) == 1 else { return nil }
        switch P.kind {
        case 0, 1: return HandMove(hand: [:], set: [("u", -1)], check: true)
        case 2: let w = Double(P.X > 1 ? P.X - 1 : 2); return HandMove(hand: ["w": w], missHand: ["w": w], set: [("u", w)], check: true)
        default: let k = Double(P.a - 1); return HandMove(hand: ["k": k], missHand: ["k": k], set: [("u", k)], check: true)
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = OneStep6.Parts(s.numbers)
        switch stage(s) {
        case 2 where !P.fr: return ["x": P.same]
        case 3: return ["q": P.xv]
        default: return nil
        }
    }

    /// Keys up, writing x: the part of the picture that is x stays in the frame with the line.
    func keysFocus(_ s: PaperState) -> CGRect? {
        let S = Shape(s.numbers), P = S.P, C = S.C
        guard stage(s) == 2 else { return nil }
        switch P.kind {
        case 0, 1: return CGRect(x: 0, y: 0, width: C * Double(P.X), height: S.BB + C)
        // the rows sit a block right of the line: keeping them would hold the line under 75% (the line shows alone)
        case 2: return nil
        default: return CGRect(x: 0, y: 0, width: C * Double(P.xc), height: C * Double(P.a))
        }
    }
}
