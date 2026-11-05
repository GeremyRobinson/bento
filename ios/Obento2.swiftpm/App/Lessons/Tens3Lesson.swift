import SwiftUI

/// Multiply by multiples of 10 on the paper, as in the preview (design/prototype/grade3-ch2.html, dMult10): a square is
/// one, a ten is a ten-frame (2 rows of 5 squares, a block wide, tinted). `4 × 30` is rows of 3 tens a square apart, `3
/// tens` over the first row and 4 down the left in an open bracket. Drag the bottom edge down to make the rows ("4 rows ·
/// 12 tens"); write `4 × 3 = [12]`. With ten tens or more, ten of them glide together into a hundred (hundreds in rows of
/// four a block apart, the tens left over in a column beside them, "1 hundred and 2 tens"), and `4 × 30 = 12 tens = [120]`.
///
/// Hand: "grab", "n" the rows made (1 at first).
@MainActor
struct Tens3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private static let X0 = M3.X0, Y0 = M3.Y0
    func recordBeside(_ n: Numbers) -> Double? { Self.Y0 }
    func recordRow(_ n: Numbers) -> Double? { let P = Tens3.Parts(n); return (max(Self.Y0 + Double(3 * P.a - 1), Self.foldBottom(P) + 2.5) + 3).rounded(.up) }

    /// The fold's places: hundreds (and then the tens left over, as a hundred still filling) in rows of four a square
    /// apart, each ten-frame where it lies in its hundred: 2 across, 5 down.
    private static func slot(_ i: Int) -> (Double, Double) { (X0 + Double(i % 4) * 11, Y0 + Double(i / 4) * 11) }
    private static func foldBottom(_ P: Tens3.Parts) -> Double {
        guard P.hundreds > 0 else { return 0 }
        let full = slot(P.hundreds - 1).1 + 10
        return P.left > 0 ? max(full, slot(P.hundreds).1 + Double((P.left + 1) / 2 * 2)) : full
    }
    /// How wide the fold is.
    private static func foldWidth(_ P: Tens3.Parts) -> Double { Double(min(4, P.hundreds + (P.left > 0 ? 1 : 0))) * 11 - 1 }
    /// Where ten-frame j sits: in its row, or folded into a hundred (or the hundred the tens left over start).
    private static func frame(_ P: Tens3.Parts, _ j: Int, folded: Bool) -> (Double, Double) {
        guard folded, P.hundreds > 0 else { return (X0 + Double(j % P.m) * 5, Y0 + Double(j / P.m) * 3) }
        let (x, y) = slot(j / 10), k = j % 10
        return (x + Double(k % 2) * 5, y + Double(k / 2) * 2)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Tens3.Parts(s.numbers), st = at(s), X0 = Self.X0, Y0 = Self.Y0, ch = Sketch.Colour.chapter
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let n = st == 0 ? Int((s.h("n") ?? 1).rounded()) : P.a, folded = st >= 2 && P.hundreds > 0, W = Double(5 * P.m)
        for j in 0..<(n * P.m) {
            let (x, y) = Self.frame(P, j, folded: folded)
            pic.fill("fr\(j)f", col: x, row: y, w: 5, h: 2, .tint(0.2))
            pic.sketch.box("fr\(j)o", pic.R(x, y, 5, 2), .ink, width: Sketch.stroke)
        }
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), rowsH = Double(3 * P.a - 1)
        if folded {
            // ten tens make a hundred: its outline drawn round the ten frames that glided together
            for i in 0..<P.hundreds { pic.sketch.box("hu\(i)", pic.R(Self.slot(i).0, Self.slot(i).1, 10, 10), .ink, width: Sketch.stroke) }
            pic.word("fw", P.folded, at: X0, Self.foldBottom(P) + 1.6, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: ch), anchor: UnitPoint(x: 0, y: 0.5))
        } else {
            pic.label("top", G3.count(P.m, "ten"), Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink), .above, edge: Y0, along: X0 + W / 2)
            M3.bracket(&pic, "bl", x: X0 - 1, y1: Y0, y2: Y0 + rowsH, open: st == 0, name: "\(P.a)")
        }
        var extent: CGRect?
        if st == 0 {
            M3.edge(&live, rows: true, x: X0, y: Y0, at: Y0 + Double(3 * n - 1), span: W, held: s.grabbed)
            if s.grabbed { live.reads("\(G3.count(n, "row")) · \(n * P.m) tens") }
            if ring { KK.hintBox(&pic, "hr", x: X0 - 4, y: Y0, w: 3.5, h: rowsH) }
            if spot { pic.line("sp", [(X0 - 0.5, Y0 + rowsH), (X0 + W + 0.5, Y0 + rowsH)], ch, dashed: true) }
            extent = pic.R(X0 - 1, Y0, W + 1, rowsH + 1)
        }
        if st == 1 && ring { KK.hintBox(&pic, "hf", x: X0, y: Y0, w: W, h: rowsH) }
        if st == 1 && spot { A1.note(&pic, "sf", "\(P.f) tens", x: X0, y: Y0 + rowsH + 1.5) }
        if st == 2 && ring { KK.hintBox(&pic, "ht", x: X0, y: Y0, w: folded ? Self.foldWidth(P) : W, h: folded ? Self.foldBottom(P) - Y0 : rowsH) }
        if st == 2 && spot { A1.note(&pic, "st", "\(P.P)", x: X0, y: (folded ? Self.foldBottom(P) + 1.6 : Y0 + rowsH) + 2, centred: false) }

        // the record: 4 × 3 = [12], 4 × 30 = 12 tens = [120]
        if st >= 1 {
            M7.row(&rec, "l1", [.n(P.a), .op("×"), .n(P.m), .op("="), M3.box("f", P.f, cells: 2, right: st >= 2)], x: 0, line: 1)
            // 4 × 30 = 12 tens, then = [120] under its = (one line made the biggest, 9 × 90, too wide to show at 75%)
            if st >= 2 {
                M7.row(&rec, "l2", [.n(P.a), .op("×"), .n(P.t), .op("="), .n(P.f), .w("tens")], x: 0, line: 4)
                M7.row(&rec, "l3", [.op("="), M3.box("x", P.P, cells: M3.cells(P.P), right: st == 3)], x: M7.width([.n(P.a), .op("×"), .n(P.t)]), line: 7)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let P = Tens3.Parts(s.numbers), X0 = Self.X0, Y0 = Self.Y0, n = Int((s.h("n") ?? 1).rounded()), W = Double(5 * P.m)
        return Hands(
            grab: { q in M3.onEdge(q, rows: true, x: X0, y: Y0, at: Y0 + Double(3 * n - 1), span: W) ? ["grab": 1, "n": Double(n)] : nil },
            drag: { q, h in var h = h; h["n"] = Double(max(1, min(P.cap, Int(((q.y - Y0 + 1) / 3).rounded())))); return h },
            release: { h in
                let k = Int((h["n"] ?? 1).rounded())
                guard k != 1 else { return HandMove(hand: ["n": 1]) }
                return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("r", Double(k))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0 else { return [] }
        let P = Tens3.Parts(s.numbers), n = Double(Int((s.h("n") ?? 1).rounded())), x = Self.X0 + 2.5 * Double(P.m)
        return [.drag(from: CGPoint(x: x, y: Self.Y0 + 3 * n - 1), to: CGPoint(x: x, y: Self.Y0 + Double(3 * P.a - 1)))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard at(s) == 0 else { return nil }
        let P = Tens3.Parts(s.numbers), k = min(P.cap, P.a + 1)
        return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("r", Double(k))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Tens3.Parts(s.numbers)
        switch at(s) { case 1: return ["f": Double(P.a + P.m)]; case 2: return ["x": Double(P.f)]; default: return nil }
    }
}
