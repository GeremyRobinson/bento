import SwiftUI

/// Find the missing number on the paper, as in the preview (design/prototype/grade3-ch1.html, dUnknown): the array's own
/// names are the equation. Rows down the left, how many in each over the top, the total in a bracket on the right; the one
/// missing is an empty box where its name goes. Drag the open side until the array holds the total (the edge snaps a row or
/// column at a time, "8 rows of 5 · 40"); for a missing total, drag down to make the rows and they count by b. Then write
/// the box in the equation (`8 × [ ] = 48`); once it's right the matching fact is written under it.
///
/// Hand: "grab", "n" the edge (columns in form 0, rows otherwise).
@MainActor
struct Unknown3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let X0 = 10.0, Y0 = M3.Y0
    func recordBeside(_ n: Numbers) -> Double? { Self.Y0 }
    func recordRow(_ n: Numbers) -> Double? { let P = Unknown3.Parts(n); return Self.Y0 + Double(P.a * P.c) + 3 }

    private static func eq(_ P: Unknown3.Parts, _ bx: M7.Tok) -> [M7.Tok] {
        let a = M7.Tok.n(P.a), b = M7.Tok.n(P.b), T = M7.Tok.n(P.T), x = M7.Tok.op("×"), d = M7.Tok.op("÷"), e = M7.Tok.op("=")
        switch P.form {
        case 0: return P.flip ? [T, e, a, x, bx] : [a, x, bx, e, T]
        case 1: return P.flip ? [T, e, bx, x, b] : [bx, x, b, e, T]
        case 2: return P.flip ? [b, e, T, d, bx] : [T, d, bx, e, b]
        default: return P.flip ? [b, e, bx, d, a] : [bx, d, a, e, b]
        }
    }
    private static func fact(_ P: Unknown3.Parts) -> [M7.Tok] {
        switch P.form {
        case 0: return [.n(P.T), .op("÷"), .n(P.a), .op("="), .n(P.b)]
        case 1: return [.n(P.T), .op("÷"), .n(P.b), .op("="), .n(P.a)]
        default: return [.n(P.a), .op("×"), .n(P.b), .op("="), .n(P.T)]
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Unknown3.Parts(s.numbers), st = at(s), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0, ch = Sketch.Colour.chapter
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let n = Int((s.h("n") ?? 1).rounded())
        let (r, k) = st == 0 ? P.rc(n) : (P.a, P.b), w = Double(k) * c, h = Double(r) * c
        let named = st == 2, form = P.form, gapR: Double = form == 3 ? 4 : 1
        M3.array(&pic, "ar", x: X0, y: Y0, rows: r, cols: k, c: c, over: form == 3 && st > 0)
        // over the top: how many in each row
        if form == 0 && !named { M3.nameBox(&pic, "tb", cx: X0 + w / 2, cy: Y0 - 1.5) }
        else { pic.label("top\(k)", "\(P.b)", M3.maths.colour(form == 0 ? ch : .ink), .above, edge: Y0, along: X0 + w / 2) }
        // down the left: the rows
        let rowsH = form == 3 ? Double(P.a) * c : h
        let leftName: String? = (form == 1 || form == 2) && !named ? nil : "\(P.a)"
        M3.bracket(&pic, "bl\(r)", x: X0 - 1, y1: Y0, y2: Y0 + rowsH, open: form == 3 && st == 0, name: leftName, form == 1 || form == 2 ? ch : .ink)
        if leftName == nil { M3.nameBox(&pic, "lb", cx: X0 - 4, cy: Y0 + rowsH / 2) }
        // on the right: the total, in a bracket that closes when the array holds it
        let bx = X0 + w + gapR
        if form != 3 || st > 0 {
            let totalName: String? = form == 3 && !named ? nil : "\(P.T)"
            M3.bracket(&pic, "br\(r).\(k)", x: bx, y1: Y0, y2: Y0 + h, open: st == 0, left: false, name: totalName, form == 3 ? ch : .ink)
            if totalName == nil { M3.nameBox(&pic, "rb", cx: bx + 2.5, cy: Y0 + h / 2) }
        }
        if form == 3 && st > 0 { M3.countRows(&pic, "cr", x: X0, y: Y0, rows: P.a, cols: P.b, c: c, by: P.b, last: named) }
        var extent: CGRect?
        if st == 0 {
            M3.edge(&live, rows: !P.cols, x: X0, y: Y0, at: (P.cols ? X0 : Y0) + Double(n) * c, span: P.cols ? h : w, held: s.grabbed)
            if s.grabbed { live.reads(form == 3 ? "\(G3.count(r, "row")) of \(P.b)" : "\(G3.count(r, "row")) of \(k) · \(r * k)") }
            let reach = min(Double(P.cap) * c, 30)
            extent = P.cols ? pic.R(X0 - 1, Y0, max(reach, Double(P.b) * c) + gapR + 6, h) : pic.R(X0 - 1, Y0, w + gapR + 6, max(reach, Double(P.a) * c))
            // hints: a miss rings the name to reach; a second dashes where the edge goes
            if s.on("ring") || s.on("spot") {
                if form == 3 { KK.hintBox(&pic, "hr", x: X0 - 4, y: Y0, w: 3.5, h: rowsH) } else { KK.hintBox(&pic, "hr", x: bx + 0.5, y: Y0 + h / 2 - 1.5, w: 4, h: 3) }
            }
            if s.on("spot") {
                let e = Double(P.want) * c
                if P.cols { pic.line("sp", [(X0 + e, Y0 - 0.5), (X0 + e, Y0 + h + 0.5)], ch, dashed: true) }
                else { pic.line("sp", [(X0 - 0.5, Y0 + e), (X0 + w + 0.5, Y0 + e)], ch, dashed: true) }
            }
        } else {
            M7.row(&rec, "l1", Self.eq(P, M3.box("u", P.ans, cells: M3.cells(P.ans), right: named)), x: 0, line: 1)
            if named { M7.row(&rec, "l2", Self.fact(P), x: 0, line: 4) }
            if st == 1 && (s.on("ring") || s.on("spot")) {
                switch form {
                case 0: KK.hintBox(&pic, "hw", x: X0, y: Y0, w: w, h: c)
                case 3: KK.hintBox(&pic, "hw", x: X0, y: Y0, w: w, h: h)
                default: KK.hintBox(&pic, "hw", x: X0, y: Y0, w: c, h: h)
                }
            }
            if st == 1 && s.on("spot") {
                switch form {
                case 0: for j in 0..<P.b { KK.hint(&pic, "sn\(j)", X0 + (Double(j) + 0.5) * c, Y0 + c / 2, radius: c * 0.4) }
                case 3: pic.word("sn", "\(P.T)", at: X0 + w + 0.5, Y0 + h - c / 2, M3.lit, anchor: UnitPoint(x: 0, y: 0.5))
                default: for i in 0..<P.a { KK.hint(&pic, "sn\(i)", X0 + c / 2, Y0 + (Double(i) + 0.5) * c, radius: c * 0.4) }
                }
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Unknown3.Parts(s.numbers), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0
        guard at(s) == 0 else { return nil }
        let n = Int((s.h("n") ?? 1).rounded()), (r, k) = P.rc(n)
        let span = P.cols ? Double(r) * c : Double(k) * c, base = P.cols ? X0 : Y0
        return Hands(
            grab: { q in M3.onEdge(q, rows: !P.cols, x: X0, y: Y0, at: base + Double(n) * c, span: span) ? ["grab": 1, "n": Double(n)] : nil },
            drag: { q, h in var h = h; h["n"] = Double(max(1, min(P.cap, Int((((P.cols ? q.x : q.y) - base) / c).rounded())))); return h },
            release: { h in
                let m = Int((h["n"] ?? 1).rounded())
                guard m != 1 else { return HandMove(hand: ["n": 1]) }
                return HandMove(hand: ["n": Double(m)], missHand: ["n": 1], set: [("e", Double(m))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Unknown3.Parts(s.numbers), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0
        guard at(s) == 0 else { return [] }
        let n = Double(Int((s.h("n") ?? 1).rounded())), want = Double(P.want)
        if P.cols { let y = Y0 + Double(P.a) * c / 2; return [.drag(from: CGPoint(x: X0 + n * c, y: y), to: CGPoint(x: X0 + want * c, y: y))] }
        let x = X0 + Double(P.b) * c / 2
        return [.drag(from: CGPoint(x: x, y: Y0 + n * c), to: CGPoint(x: x, y: Y0 + want * c))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Unknown3.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        let m = P.want + 1 <= P.cap ? P.want + 1 : P.want - 1
        return HandMove(hand: ["n": Double(m)], missHand: ["n": 1], set: [("e", Double(m))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Unknown3.Parts(s.numbers)
        return at(s) == 1 ? ["u": Double(P.form == 3 ? P.a + P.b : P.T)] : nil
    }
}
