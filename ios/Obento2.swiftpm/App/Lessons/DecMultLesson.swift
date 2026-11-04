import SwiftUI

/// Multiplying decimals on the paper, as in the preview (design/prototype/grade6-ch3.html, dDecMult): Multiply by 10,
/// 100, 1000's place chart (a column a place, a block wide; the point fixed on the line between the ones and the
/// tenths), hundreds (or the product's biggest place) to thousandths; a digit is a tile in its column. Three rows a block
/// apart: a, b and the product; the school's column working to the chart's right. Drag a's digits left until it's whole
/// ("× 100"), then b's; write the wholes' product in columns (from problem 4 the partial products too); drag the
/// product's digits right to undo both ("÷ 1000"); tap 0s into the empty places between the point and the digits. Done,
/// the estimate is written under it.
///
/// Everything is in the picture's squares (recordRow 0). Hand keys: "k" (columns moved), "x0"/"k0" (the drag), "z"
/// (the 0s tapped, a bit each).
@MainActor
struct DecMultLesson: PaperLesson {
    static let YA = 3.0, YB = 8.0, YP = 14.0
    var liveKeys: Set<String> { ["k", "x0", "k0"] }
    private static let small = R6.small, lit = R6.lit, maths = Record.maths

    @MainActor struct Shape {
        let P: DecMult6.Parts
        init(_ n: Numbers) { P = DecMult6.Parts(n) }
        var topE: Int { P.topE }
        func colX(_ e: Int) -> Double { 5 + Double(topE - e) * 5 }
        var chartW: Double { colX(-3) + 5 }
        var PX: Double { colX(0) + 5 }
        var lenW: Int { "\(P.W)".count }
        var maxD: Int { max("\(P.A)".count, "\(P.B)".count + 1, lenW, P.two ? "\(P.p2)".count + 1 : 0) }
        /// The column working's right edge, and its total's row.
        var R: Double { chartW + 6 + 2 * Double(maxD) }
        var tY: Double { P.two ? 12 : 8 }
        func kmax(_ x: Dec6) -> Int { min(x.p + 1, topE - (x.intDigits - 1)) }
    }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers), at = stage(s)
        if at == 3 { return CGPoint(x: S.chartW + 5, y: S.tY + 2) }
        if at == 6 { return CGPoint(x: 0, y: 24) }
        return nil
    }

    // MARK: drawing

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), done = at == 6, K = P.K
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let k = Int((s.h("k") ?? 0).rounded()), held = s.grabbed

        // the chart: the places' names (neighbours that would touch staggered), the columns, the point's line
        Self.names(&pic, Array(stride(from: S.topE, through: -3, by: -1)), S.colX, y: 1.2)
        for e in stride(from: S.topE - 1, through: -3, by: -1) where e != -1 { pic.line("cl\(e)", [(S.colX(e), 1.9), (S.colX(e), Self.YP + 4.5)], .ink3) }
        pic.line("cpt", [(S.PX, 1.9), (S.PX, Self.YP + 4.5)], .ink2)

        // a and b where they are now; what the move made beside each row
        let ka = at == 1 ? k : at > 1 ? P.a.p : 0, kb = at == 2 ? k : at > 2 ? P.b.p : 0
        if at == 1 && held { tiles(&live, "ta", P.a.times10(ka).s, y: Self.YA, S) } else { tiles(&pic, "ta", P.a.times10(ka).s, y: Self.YA, S) }
        if at == 2 && held { tiles(&live, "tb", P.b.times10(kb).s, y: Self.YB, S) } else { tiles(&pic, "tb", P.b.times10(kb).s, y: Self.YB, S) }
        pic.word("tx", "×", at: 2.5, Self.YB + 2, Self.maths)
        pic.rule("tl", from: 0, to: S.chartW, row: Self.YP - 1)
        pic.dot("pa", at: S.PX, Self.YA + 3.3, radius: 0.25, .ink, over: true)
        pic.dot("pb", at: S.PX, Self.YB + 3.3, radius: 0.25, .ink, over: true)
        func readout(_ pen: inout GridPen, _ id: String, _ text: String, _ y: Double) {
            pen.word(id, text, at: S.chartW + 0.6, y + 2, Self.lit, anchor: UnitPoint(x: 0, y: 0.5))
        }
        if ka > 0 { if at == 1 && held { readout(&live, "roa", "× \(Dec6.pow10(ka))", Self.YA); live.reads("× \(Dec6.pow10(ka))") } else { readout(&pic, "roa\(ka)", "× \(Dec6.pow10(ka))", Self.YA) } }
        if kb > 0 { if at == 2 && held { readout(&live, "rob", "× \(Dec6.pow10(kb))", Self.YB); live.reads("× \(Dec6.pow10(kb))") } else { readout(&pic, "rob\(kb)", "× \(Dec6.pow10(kb))", Self.YB) } }
        // a hint: the row to move ringed; a second miss, where its last digit lands (the ones)
        if (at == 1 || at == 2) {
            let y = at == 1 ? Self.YA : Self.YB
            if s.on("ring") { R6.ring(&pic, "ring", x: 5, y: y, w: S.chartW - 6, h: 4) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(S.colX(0) + 0.5, y + 0.5, 4, 3), .chapter, width: Sketch.stroke, dashed: true) }
        }

        // the product, once it's written: its digits moved right by kp; 0s tapped into the empty places
        if at >= 4 {
            let kp = at == 4 ? k : K, str = Array("\(P.W)")
            let tz = done ? min(K, str.reversed().prefix { $0 == "0" }.count) : 0
            for (idx, ch) in str.enumerated() {
                let e = S.lenW - 1 - idx - kp, fade = done && idx >= str.count - tz
                let c: Sketch.Colour = done ? (fade ? .ink3 : .chapter) : .ink
                var pen = at == 4 && held ? live : pic
                tile(&pen, "tp\(str.count - 1 - idx)", e, ch, y: Self.YP, S, c)
                if at == 4 && held { live = pen } else { pic = pen }
            }
            let mask = Int(s.h("z") ?? 0)
            for (i, e) in P.zeros.enumerated() where done || at == 5 && mask & (1 << i) != 0 {
                tile(&pic, "tz\(e)", e, "0", y: Self.YP, S, done ? .chapter : .ink)
            }
            if at == 5 { for (i, e) in P.zeros.enumerated() where mask & (1 << i) == 0 { pic.sketch.box("zb\(e)", pic.R(S.colX(e) + 1, Self.YP + 1, 3, 2), .ink3, width: Sketch.stroke) } }
            pic.dot("pp", at: S.PX, Self.YP + 3.3, radius: 0.25, .ink, over: true)
            if kp > 0 { if at == 4 && held { readout(&live, "rop", "÷ \(Dec6.pow10(kp))", Self.YP); live.reads("÷ \(Dec6.pow10(kp))") } else { readout(&pic, "rop\(kp)", "÷ \(Dec6.pow10(kp))", Self.YP) } }
            if at == 4 && s.on("ring") { R6.ring(&pic, "ring", x: 5, y: Self.YP, w: S.chartW - 6, h: 4) }
            if at == 4 && s.on("spot") { pic.sketch.box("spot", pic.R(S.colX(-K) + 0.5, Self.YP + 0.5, 4, 3), .chapter, width: Sketch.stroke, dashed: true) }
            if at == 5 && s.on("ring") { R6.ring(&pic, "ring", x: S.colX(0), y: Self.YP, w: 5 * Double(P.zeros.count), h: 4) }
            if at == 5 && s.on("spot") { for (i, e) in P.zeros.enumerated() where mask & (1 << i) == 0 { pic.circle("sp\(e)", at: S.colX(e) + 2.5, Self.YP + 2, radius: 2.2, .chapter, dashed: true) } }
        }

        // the school's column working, right of the chart (once both are whole)
        if at >= 3 {
            let R = S.R
            rec.digits("wa", "\(P.A)", right: R, row: 4, per: 2)
            rec.digits("wb", "\(P.B)", right: R, row: 6, per: 2)
            rec.word("wx", "×", at: R - 2 * Double("\(P.B)".count) - 1, 6, Self.maths)
            rec.rule("wl1", from: R - 2 * Double(max("\(P.A)".count, "\(P.B)".count)) - 2, to: R, row: 7)
            func row(_ id: String, _ v: Int, _ y: Double, typed: Bool, _ c: Sketch.Colour = .ink) {
                if at == 3 && typed { rec.answerBox(id, right: R, mid: y, per: 2, cells: "\(v)".count) }
                else { rec.digits("w\(id)", "\(v)", right: R, row: y, per: 2, c) }
            }
            if P.two {
                row("p1", P.p1, 8, typed: P.partials)
                row("p2", P.p2, 10, typed: P.partials)
                rec.word("wplus", "+", at: R - 2 * Double(max("\(P.p2)".count, "\(P.p1)".count)) - 1, 10, Self.maths)
                rec.rule("wl2", from: R - 2 * Double(max("\(P.p2)".count, S.lenW)) - 2, to: R, row: 11)
            }
            row("t", P.W, S.tY, typed: true, at > 3 ? .chapter : .ink)
            if at == 3 && s.on("ring") { R6.ring(&rec, "ringw", x: R - 2 * Double(S.maxD) - 1, y: 3, w: 2 * Double(S.maxD) + 2, h: S.tY - 2) }
        }
        // See: the estimate
        if done { pic.word("est", P.estimate, at: 0, 21, R6.words, anchor: UnitPoint(x: 0, y: 0.5)) }
        let extent = pic.R(0, 0, S.R + 1, Self.YP + 5)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    /// The places' names over a chart's columns (5 squares each), small; a name that would touch the one before it is
    /// written a row higher.
    static func names(_ pen: inout GridPen, _ es: [Int], _ colX: (Int) -> Double, y: Double) {
        var prev: (w: Double, up: Bool)? = nil
        for e in es {
            let nm = Place6.name(e), w = R6.width(nm, R6.small)
            let up = prev.map { !$0.up && ($0.w + w) / 2 > 4.4 } ?? false
            pen.word("cn\(e)", nm, at: colX(e) + 2.5, up ? y - 1.2 : y, R6.small)
            prev = (w, up)
        }
    }

    /// One digit's tile in place e's column: a column wide, 4 tall, its digit in the middle. Its id is the digit's place
    /// in the number (counted from its last digit), so a moved digit glides to its new column.
    private func tile(_ pen: inout GridPen, _ id: String, _ e: Int, _ ch: Character, y: Double, _ S: Shape, _ c: Sketch.Colour = .ink) {
        pen.sketch.box(id + "o", pen.R(S.colX(e), y, 5, 4), c == .ink ? .ink2 : c, width: Sketch.stroke)
        pen.word(id + "d", String(ch), at: S.colX(e) + 2.5, y + 2, Self.maths.colour(c))
    }
    private func tiles(_ pen: inout GridPen, _ id: String, _ str: String, y: Double, _ S: Shape) {
        let parts = str.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let ip = parts[0], all = Array(ip + (parts.count > 1 ? parts[1] : ""))
        for (i, ch) in all.enumerated() { tile(&pen, "\(id)\(all.count - 1 - i)", ip.count - 1 - i, ch, y: y, S) }
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), P = S.P, at = stage(s), k = Int((s.h("k") ?? 0).rounded())
        func slide(row: Double, kmax: Int, right: Bool) -> Hands {
            Hands(
                grab: { q in q.y >= row - 1 && q.y <= row + 5 && q.x >= 4 && q.x <= S.chartW + 1 ? ["grab": 1, "x0": q.x, "k0": Double(k), "k": Double(k)] : nil },
                drag: { q, h in
                    var h = h
                    let dx = Int((((h["x0"] ?? q.x) - q.x) / 5).rounded()) * (right ? -1 : 1)
                    h["k"] = Double(max(0, min(kmax, Int(h["k0"] ?? 0) + dx)))
                    return h
                },
                release: { h in
                    let k = Int((h["k"] ?? 0).rounded())
                    return HandMove(hand: ["k": Double(k)], missHand: nil, set: [("x", Double(k))], check: true)
                })
        }
        switch at {
        case 1: return slide(row: Self.YA, kmax: S.kmax(P.a), right: false)
        case 2: return slide(row: Self.YB, kmax: S.kmax(P.b), right: false)
        case 4: return slide(row: Self.YP, kmax: min(3, P.K + 1), right: true)
        case 5:
            let mask = Int(s.h("z") ?? 0)
            return Hands(tap: { q in
                guard q.y >= Self.YP - 0.5, q.y <= Self.YP + 4.5, q.x >= 5, q.x < S.chartW else { return nil }
                let e = S.topE - Int(((q.x - 5) / 5).rounded(.down))
                guard let i = P.zeros.firstIndex(of: e) else { return HandMove(hand: ["z": Double(mask)], missHand: nil, set: [("x", 2)], check: true) }
                let now = mask | (1 << i)
                if now == (1 << P.zeros.count) - 1 { return HandMove(hand: ["z": Double(now)], missHand: nil, set: [("x", 1)], check: true) }
                return HandMove(hand: ["z": Double(now)], missHand: nil)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), P = S.P, at = stage(s), k = Double(Int((s.h("k") ?? 0).rounded()))
        func move(_ row: Double, from e: Double, by n: Double) -> [GhostMove] {
            [.drag(from: CGPoint(x: S.colX(Int(e)) + 2.5, y: row + 2), to: CGPoint(x: S.colX(Int(e)) + 2.5 - 5 * n, y: row + 2))]
        }
        switch at {
        case 1: return move(Self.YA, from: Double(-P.a.p + Int(k)), by: Double(P.a.p) - k)
        case 2: return move(Self.YB, from: Double(-P.b.p + Int(k)), by: Double(P.b.p) - k)
        case 4: return move(Self.YP, from: Double(-Int(k)), by: k - Double(P.K))
        case 5:
            let mask = Int(s.h("z") ?? 0)
            return P.zeros.enumerated().filter { mask & (1 << $0.offset) == 0 }.map { .tap(.picture(CGPoint(x: S.colX($0.element) + 2.5, y: Self.YP + 2))) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let S = Shape(s.numbers), P = S.P, at = stage(s)
        func wrong(_ k: Int) -> HandMove { HandMove(hand: ["k": Double(k)], missHand: nil, set: [("x", Double(k))], check: true) }
        switch at {
        case 1: return wrong(P.a.p > 1 ? P.a.p - 1 : min(S.kmax(P.a), P.a.p + 1))
        case 2: return wrong(min(S.kmax(P.b), P.b.p + 1))
        case 4: return wrong(P.K > 1 ? P.K - 1 : P.K + 1)
        case 5: return HandMove(hand: s.hand, missHand: nil, set: [("x", 2)], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = DecMult6.Parts(s.numbers)
        guard stage(s) == 3 else { return nil }
        if P.partials { return ["p1": Double(P.p1), "p2": Double(P.p2 / 10), "t": Double(P.p1 + P.p2 / 10)] }
        return ["t": Double(P.W + 10)]
    }
}
