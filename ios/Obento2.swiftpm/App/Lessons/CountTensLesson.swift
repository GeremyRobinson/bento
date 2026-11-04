import SwiftUI

/// Count by tens to 100 on the paper, as in the preview (design/prototype/gradeK-ch5.html, lTens). One ten is a ten frame
/// tile: 2 × 1 blocks (10 × 5 squares), its ten dots 2 squares apart; tiles in rows of five (50 squares), two rows a block
/// apart. Tap each tile: its running total is written over it, 10, 20, 30, the last ringed (tapped again: "You counted that
/// ten."). Then the web's line, 10, 20, 30, [40], wrapping after five, its last number written with the digit pad and Check.
///
/// Kept: "o<k>" the tiles counted in order, "again" one tapped twice, "chk" the number last checked.
@MainActor
struct CountTensLesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// A tile's top-left: rows of five from row 4 (its total over it), the second row a block under the first.
    static func tile(_ t: Int) -> CGPoint { CGPoint(x: 10 * Double(t % 5), y: 4 + 10 * Double(t / 5)) }
    private func bottom(_ rows: Int) -> Double { rows > 5 ? 19 : 9 }
    func recordRow(_ n: Numbers) -> Double? { bottom(TensK.Parts(n).rows) + 3 }
    /// The digit pad: under the record's last line.
    private func padY(_ rows: Int) -> Double { bottom(rows) + 3 + (rows > 5 ? 8 : 5) }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        at(s) == 1 ? DigitPad.checkAt(x: 0, y: padY(TensK.Parts(s.numbers).rows)) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TensK.Parts(s.numbers), st = at(s), rows = P.rows
        var pic = GridPen(), rec = GridPen()
        let list = KA.list(s, "o"), counted = st == 0 ? list : (list.count == rows ? list : Array(0..<rows))
        for t in 0..<rows {
            let p = Self.tile(t), k = counted.firstIndex(of: t)
            pic.fill("tf\(t)\(k == nil ? "" : "L")", col: p.x, row: p.y, w: 10, h: 5, k == nil ? KK.cube : KK.litCube)
            pic.sketch.box("to\(t)", pic.R(p.x, p.y, 10, 5), .chapter, width: Sketch.stroke)
            for d in 0..<10 { pic.dot("td\(t)-\(d)", at: p.x + 1 + 2 * Double(d % 5), p.y + 1.5 + 2 * Double(d / 5), radius: 0.65, .chapter, over: true) }
            // its running total over it while counting (the record carries them after)
            if st == 0, let k {
                pic.word("tt\(t)-\(k)", "\(10 * (k + 1))", at: p.x + 5, p.y - 2, KK.maths)
                if counted.count == rows && k == rows - 1 { pic.circle("tr\(t)", at: p.x + 5, p.y - 2, radius: 2.05, .chapter) }
            }
        }
        switch st {
        case 0:
            if let a = KA.kept(s, "again") { let p = Self.tile(a); pic.sketch.box("again\(a)", pic.R(p.x - 0.5, p.y - 0.5, 11, 6), KK.red, width: Sketch.stroke) }
            let todo = (0..<rows).filter { !counted.contains($0) }
            if s.on("ring") && !s.on("spot") { for t in todo { let p = Self.tile(t); KK.hintBox(&pic, "hr\(t)", x: p.x, y: p.y, w: 10, h: 5) } }
            if s.on("spot"), let t = todo.first { let p = Self.tile(t); pic.sketch.box("spot", pic.R(p.x - 0.5, p.y - 0.5, 11, 6), .chapter, width: Sketch.stroke) }
            return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes)
        case 1:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.total)
            line(&rec, rows, value: v, wrong: wrong, done: false)
            DigitPad.draw(&pic, "pad", x: 0, y: padY(rows))
            // a hint: the tiles ringed; a second miss, the last one's total written over it
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 4, w: 50, h: bottom(rows) - 4) }
            if s.on("spot") {
                let p = Self.tile(rows - 1)
                pic.word("ts", "\(P.total)", at: p.x + 5, p.y - 2, KK.maths.colour(.chapter))
                pic.circle("tsr", at: p.x + 5, p.y - 2, radius: 2.05, .chapter)
            }
            return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes, actions: ["Check"])
        default:
            line(&rec, rows, value: P.total, wrong: false, done: true)
            return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes)
        }
    }

    /// The web's line, 10, 20, 30, [40]: five to a row, the last its box (or, done, the total in the chapter's colour).
    private func line(_ pen: inout GridPen, _ rows: Int, value: Int?, wrong: Bool, done: Bool) {
        let said: [M7.Tok] = (1..<rows).map { .t("\(10 * $0),") }
        let first = Array(said.prefix(5)), rest = Array(said.dropFirst(5))
        if done {
            let all = said + [.n(10 * rows, .chapter)]
            M7.row(&pen, "rec1", Array(all.prefix(5)), x: 0, line: 1)
            if all.count > 5 { M7.row(&pen, "rec2", Array(all.dropFirst(5)), x: 0, line: 4) }
        } else if rows > 5 {
            M7.row(&pen, "rec1", first, x: 0, line: 1)
            KA.line(&pen, "rec2", rest, value: value, wrong: wrong, line: 4)
        } else {
            KA.line(&pen, "rec1", first, value: value, wrong: wrong, line: 1)
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = TensK.Parts(s.numbers), rows = P.rows
        switch at(s) {
        case 0:
            let counted = KA.list(s, "o")
            return Hands(tap: { q in
                guard let t = (0..<rows).first(where: { let p = Self.tile($0); return q.x >= p.x && q.x <= p.x + 10 && q.y >= p.y && q.y <= p.y + 5 }) else { return nil }
                if counted.contains(t) { return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["again": Double(t)], check: true) }
                let done = counted.count + 1 == rows
                return HandMove(hand: nil, missHand: nil, set: done ? [("c", Double(rows))] : [], keep: ["o\(counted.count)": Double(t), "again": -1], check: done)
            })
        case 1: return DigitPad.hands(s, "x", want: P.total, x: 0, y: padY(rows))
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = TensK.Parts(s.numbers)
        switch at(s) {
        case 0:
            let counted = KA.list(s, "o")
            return (0..<P.rows).filter { !counted.contains($0) }.map { let p = Self.tile($0); return .tap(.picture(CGPoint(x: p.x + 5, y: p.y + 2.5))) }
        case 1: return DigitPad.demo(P.total, x: 0, y: padY(P.rows))
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = TensK.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["o0": 0, "again": 0], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.total - 10))], keep: ["chk": Double(P.total - 10)], check: true)
        default: return nil
        }
    }
}
