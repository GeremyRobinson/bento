import SwiftUI

/// Evaluate expressions on the paper, as in the preview (design/prototype/grade6-ch5.html, dEval): `3x + 2y` as rows, a
/// cell two squares: 3 rows of an x strip and, a block away, 2 rows of a y strip (striped), every strip the same length
/// and its end dashed while it isn't known; the values written as the picture's names ("x = 4", "y = 5"). Drag the end of
/// an x strip: every x row stretches with it a cell at a time ("x = 4"); let go at 4 and the letter gives way to 4 in
/// every strip. Write `3 × 4 = [12]`; the same for y; then the sum. The record sits under the rows (beside them when
/// there are more than 5).
///
/// Everything is in the picture's squares (recordRow 0). Hand keys: "lx", "ly" (the strips' lengths in cells).
@MainActor
struct EvalExprLesson: PaperLesson {
    var liveKeys: Set<String> { ["lx", "ly", "grab"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    struct Shape {
        let P: Eval6.Parts
        init(_ n: Numbers) { P = Eval6.Parts(n) }
        static func up5(_ v: Double) -> Double { (v / 5).rounded(.up) * 5 }
        var cap: Double { Double(P.cap) }
        var XA: Double { 0 }
        /// More than 5 rows: the record (and the names over it) sits between the x rows and the y rows, so each line shows
        /// beside the rows it's counted from, keys up; else the names right of the rows and the record under them.
        var tall: Bool { max(P.a, P.b) > 5 }
        var XB: Double { tall ? 45 : Shape.up5(2 * cap + 5) }
        var NX: Double { tall ? RX : Shape.up5(XB + 2 * cap + 3) }
        var rowsH: Double { 2 * Double(max(P.a, P.b)) }
        var RX: Double { tall ? Shape.up5(2 * cap + 3) : 0 }
        var RY: Double { tall ? 8 : rowsH + 4 }
        var right: Double { tall ? XB + 2 * cap : NX + 8 }
        func line(_ i: Int) -> Double { RY + 3 * Double(i) }
        /// Where a strip starts before it's dragged (never at its answer).
        static func start(_ v: Int) -> Double { v == 3 ? 4 : 3 }
    }

    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers), at = stage(s)
        switch at {
        case 2: return CGPoint(x: S.RX, y: S.line(1) + 2)
        case 4: return CGPoint(x: S.RX, y: S.line(2) + 2)
        case 5, 6: return CGPoint(x: S.RX, y: S.line(3) + 2)
        default: return nil
        }
    }
    func keysFocus(_ s: PaperState) -> CGRect? {
        let S = Shape(s.numbers), P = S.P
        switch stage(s) {
        case 2: return CGRect(x: S.XA, y: 0, width: 2 * Double(P.x), height: 2 * Double(P.a))
        case 4: return CGRect(x: S.XB, y: 0, width: 2 * Double(P.y), height: 2 * Double(P.b))
        default: return nil
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let xk = at >= 2, yk = at >= 4, hx = at == 1 && s.grabbed, hy = at == 3 && s.grabbed
        let lx = xk ? Double(P.x) : s.h("lx") ?? Shape.start(P.x), ly = yk ? Double(P.y) : s.h("ly") ?? Shape.start(P.y)
        // the rows: each strip 2 squares tall, its cells (2 squares) drawn once its length is known or while it's held
        func rows(_ pen: inout GridPen, _ id: String, x0: Double, count: Int, len: Double, known: Bool, held: Bool, letter: String, value: Int, striped: Bool) {
            for r in 0..<count {
                X6.strip(&pen, "\(id)\(r)", x: x0, y: 2 * Double(r), len: 2 * len, h: 2, known: known, cell: known || held ? 2 : nil,
                         label: known ? "\(value)" : letter, striped: striped, held: held)
            }
        }
        if hx { rows(&live, "xs", x0: S.XA, count: P.a, len: lx, known: false, held: true, letter: "x", value: P.x, striped: false) }
        else { rows(&pic, "xs", x0: S.XA, count: P.a, len: lx, known: xk, held: false, letter: "x", value: P.x, striped: false) }
        if hy { rows(&live, "ys", x0: S.XB, count: P.b, len: ly, known: false, held: true, letter: "y", value: P.y, striped: true) }
        else { rows(&pic, "ys", x0: S.XB, count: P.b, len: ly, known: yk, held: false, letter: "y", value: P.y, striped: true) }
        // the handle on the strip being made, and its readout
        func handle(_ pen: inout GridPen, _ id: String, x: Double, rows n: Int, len: Double, letter: String, held: Bool) {
            R6.handle(&pen, id, x + 2 * len, 2 * Double(n), held: held)
            if held { pen.word(id + "r", "\(letter) = \(Int(len))", at: x + 2 * len + 1, 2 * Double(n) + 1.2, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)); pen.reads("\(letter) = \(Int(len))") }
        }
        if at == 1 { handle(&live, "hx", x: S.XA, rows: P.a, len: lx, letter: "x", held: hx) }
        if at == 3 { handle(&live, "hy", x: S.XB, rows: P.b, len: ly, letter: "y", held: hy) }
        // the values, as the picture's names
        pic.word("nx", "x = \(P.x)", at: S.NX, 1, X6.words, anchor: UnitPoint(x: 0, y: 0.5))
        pic.word("ny", "y = \(P.y)", at: S.NX, 4, X6.words, anchor: UnitPoint(x: 0, y: 0.5))

        // hints: a first miss rings the rows, a second marks the length (or counts the cells)
        func hint(_ x0: Double, _ n: Int, _ v: Int, count: Bool) {
            if s.on("ring") { X6.ring(&pic, "ring", x: x0, y: 0, w: 2 * S.cap, h: 2 * Double(n)) }
            guard s.on("spot") else { return }
            if count { for r in 0..<n { pic.word("run\(r)", "\(v * (r + 1))", at: x0 + 2 * Double(v) + 0.6, 2 * Double(r) + 1, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)) } }
            else { pic.line("spot", [(x0 + 2 * Double(v), -0.8), (x0 + 2 * Double(v), 2 * Double(n) + 0.8)], .chapter, dashed: true) }
        }
        switch at {
        case 1: hint(S.XA, P.a, P.x, count: false)
        case 2: hint(S.XA, P.a, P.x, count: true)
        case 3: hint(S.XB, P.b, P.y, count: false)
        case 4: hint(S.XB, P.b, P.y, count: true)
        default: break
        }

        // the record
        func val(_ v: Int, _ step: Int) -> M7.Tok { at == step ? .box("x", cells: max(2, "\(v)".count)) : .n(v, .chapter) }
        M7.row(&rec, "r0", [.t("\(P.a)x"), .op("+"), .t("\(P.b)y")], x: S.RX, line: S.line(0))
        if at >= 2 { M7.row(&rec, "r1", [.n(P.a), .op("×"), .n(P.x), .op("="), val(P.AX, 2)], x: S.RX, line: S.line(1)) }
        if at >= 4 { M7.row(&rec, "r2", [.n(P.b), .op("×"), .n(P.y), .op("="), val(P.BY, 4)], x: S.RX, line: S.line(2)) }
        if at >= 5 { M7.row(&rec, "r3", [.n(P.AX), .op("+"), .n(P.BY), .op("="), val(P.S, 5)], x: S.RX, line: S.line(3)) }
        if at == 5 && s.on("ring") { X6.ring(&rec, "ring", x: S.RX, y: S.line(1) - 1, w: 12, h: S.line(2) - S.line(1) + 2) }
        let ext = pic.R(-1, -1, S.right + 2, S.rowsH + 2.5)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), P = S.P, at = stage(s)
        guard at == 1 || at == 3 else { return nil }
        let isX = at == 1, x0 = isX ? S.XA : S.XB, n = isX ? P.a : P.b, key = isX ? "lx" : "ly"
        let now = s.h(key) ?? Shape.start(isX ? P.x : P.y)
        return Hands(grab: { q in
            abs(q.x - (x0 + 2 * now)) <= 1.8 && q.y >= -1.5 && q.y <= 2 * Double(n) + 1.5 ? ["grab": 1, key: now] : nil
        }, drag: { q, _ in
            ["grab": 1, key: max(1, min(S.cap, ((q.x - x0) / 2).rounded()))]
        }, release: { h in
            let v = h[key] ?? now
            return HandMove(hand: [key: v], missHand: [key: v], set: [("x", v)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), P = S.P, at = stage(s)
        guard at == 1 || at == 3 else { return [] }
        let isX = at == 1, x0 = isX ? S.XA : S.XB, n = isX ? P.a : P.b, want = Double(isX ? P.x : P.y)
        let now = s.h(isX ? "lx" : "ly") ?? Shape.start(isX ? P.x : P.y), y = 2 * Double(n) - 1
        return [.drag(from: CGPoint(x: x0 + 2 * now, y: y), to: CGPoint(x: x0 + 2 * want, y: y))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let S = Shape(s.numbers), P = S.P, at = stage(s)
        guard at == 1 || at == 3 else { return nil }
        let want = isWant(P, at), v = want < Int(S.cap) ? Double(want + 1) : Double(want - 1), key = at == 1 ? "lx" : "ly"
        return HandMove(hand: [key: v], missHand: [key: v], set: [("x", v)], check: true)
    }
    private func isWant(_ P: Eval6.Parts, _ at: Int) -> Int { at == 1 ? P.x : P.y }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Eval6.Parts(s.numbers)
        switch stage(s) {
        case 2: return ["x": Double(Int("\(P.a)\(P.x)") ?? 0)]
        case 4: return ["x": Double(Int("\(P.b)\(P.y)") ?? 0)]
        case 5: return ["x": Double(P.AX * P.BY)]
        default: return nil
        }
    }
}
