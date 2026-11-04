import SwiftUI

/// Tenths and hundredths on the paper, as in the preview (design/prototype/grade4-ch6.html): two wholes 4 squares apart,
/// a/10 as shaded tenths (columns, no hundredths' lines in them) and b/100 as striped hundredths, named under them with +
/// between. Tap a shaded tenth: every shaded tenth opens into ten hundredths (the lines draw down them). Slide the
/// striped hundredths into the first whole: they pour in after the shaded ones, a column after another (past a full
/// whole, on into the second). The names go into the record, which grows a step at a time
/// (3/10 + 25/100 = 30/100 + 25/100 = 55/100 =); then the decimal is typed.
@MainActor
struct TenthsHundredthsLesson: PaperLesson {
    var liveKeys: Set<String> { GroupSlide.liveKeys }
    /// The names' (and the record's) fraction line, 3 rows under the wholes.
    static let nameLine = D6.side + 3

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TenthsHundredths.Parts(s.numbers), at = stage(s), a = P.a, b = P.b, G = D6.side, X2 = D6.second
        let held = at == 2 && s.grabbed, poured = at >= 3
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let off = GroupSlide.offset(s)

        // the tenths, shaded; the striped hundredths: held, they follow the finger; poured, each in its place after the
        // shaded ones (past a full whole, on into the second), drawn in one after another
        pic.fill("ten", col: 0, row: 0, w: Double(a) * D6.col, h: G, Bars.shade)
        for i in 0..<b {
            if poured {
                let k = P.A + i, c = k < 100 ? D6.cell(k, x0: 0, y0: 0) : D6.cell(k - 100, x0: X2, y0: 0)
                pic.stripes("sp\(i)", col: c.x, row: c.y, w: D6.col, h: D6.col)
            } else {
                let c = D6.cell(i, x0: X2, y0: 0)
                if held { live.stripes("sp\(i)", col: c.x + off.x, row: c.y + off.y, w: D6.col, h: D6.col) }
                else { pic.stripes("sp\(i)", col: c.x, row: c.y, w: D6.col, h: D6.col) }
            }
        }
        D6.whole(&pic, "w1", x: 0, y: 0, bare: at >= 2 ? 0 : a)
        D6.whole(&pic, "w2", x: X2, y: 0)
        if at == 2 && !held { pic.word("arrow", "←", at: X2 - 2, G / 2, Bars.maths.colour(.chapter)) }
        if held { live.reads(s.h("in") == 1 ? Dec4.hund(P.S) : Dec4.hund(b)) }
        // hints: the shaded tenths (ringed), where the hundredths go (dashed)
        if at == 1 && s.on("ring") { D6.ring(&pic, "ring", x: 0, y: 0, w: Double(a) * D6.col, h: G) }
        if at == 2 && !held && s.on("target") { M5.target(&pic, "tg", x: Double(a) * D6.col, y: 0, w: G - Double(a) * D6.col, h: G) }

        // the names under the wholes, + between; from the slide on they go into the record, which grows a step at a time
        let nA: [F4.Tok] = [.f("\(a)", "10")], nB: [F4.Tok] = [.f("\(b)", "100")]
        if at < 2 {
            F4.row(&pic, "nA", nA, x: G / 2 - 2, line: Self.nameLine)
            F4.row(&pic, "nP", [.op("+")], x: G + 1, line: Self.nameLine)
            F4.row(&pic, "nB", nB, x: X2 + G / 2 - 2, line: Self.nameLine)
        } else {
            var x = F4.row(&rec, "nA", nA, x: 0, line: 2)
            x = F4.row(&rec, "nP", [.op("+")], x: x, line: 2)
            x = F4.row(&rec, "nB", nB, x: x, line: 2)
            var t: [F4.Tok] = [.op("="), .f("\(P.A)", "100"), .op("+"), .f("\(b)", "100")]
            if at >= 3 { t += [.op("="), .f("\(P.S)", "100"), .op("=")] }
            if at == 3 { t.append(.box("x", cells: 4)) }
            if at >= 4 { t.append(.d(P.text, .chapter)) }
            F4.row(&rec, "rec", t, x: x, line: 2)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// The record takes the names' row under the wholes.
    func recordRow(_ n: Numbers) -> Double? { Self.nameLine - 2 }
    func messageRows(_ n: Numbers) -> Int { TenthsHundredths.Parts(n).S >= 100 ? 2 : 1 }

    func hands(_ s: PaperState) -> Hands? {
        let P = TenthsHundredths.Parts(s.numbers), G = D6.side, X2 = D6.second
        switch stage(s) {
        case 1:
            // a tap on the first whole: a shaded tenth (1) or its empty part (−1); on the second whole (−2)
            return Hands(tap: { q in
                guard q.y >= -0.5, q.y <= G + 0.5 else { return nil }
                let v: Double
                if q.x >= -0.5 && q.x < Double(P.a) * D6.col { v = 1 }
                else if q.x >= Double(P.a) * D6.col && q.x <= G + 0.5 { v = -1 }
                else if q.x >= X2 - 0.5 && q.x <= X2 + G + 0.5 { v = -2 }
                else { return nil }
                return HandMove(hand: [:], missHand: [:], set: [("t", v)], check: true)
            })
        case 2:
            let cols = Double((P.b + 9) / 10)
            return GroupSlide(from: CGRect(x: X2 - 0.5, y: -0.5, width: cols * D6.col + 1, height: G + 1),
                              over: { p in p.x >= -1 && p.x <= G + 1 && p.y >= -1 && p.y <= G + 1 }).hands()
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = TenthsHundredths.Parts(s.numbers), G = D6.side
        switch stage(s) {
        case 1: return [.tap(.picture(CGPoint(x: Double(P.a) * D6.col / 2, y: G / 2)))]
        case 2: return [.drag(from: CGPoint(x: D6.second + 1, y: G / 2), to: CGPoint(x: G / 2, y: G / 2))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        switch stage(s) {
        case 1: return HandMove(hand: [:], missHand: [:], set: [("t", -1)], check: true)
        case 2: return GroupSlide(from: .zero, over: { _ in false }).wrongMove
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = TenthsHundredths.Parts(s.numbers)
        // the tenths used as they were
        return stage(s) == 3 ? ["x": Double(P.a + P.b) / 100] : nil
    }
}
