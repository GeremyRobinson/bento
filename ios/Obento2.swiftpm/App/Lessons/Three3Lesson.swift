import SwiftUI

/// Multiply three numbers on the paper, as in the preview (design/prototype/grade3-ch2.html, dThree): `3 × 5 × 2` written big
/// over the picture (the record's first line, so the record starts level with the picture's top); under it a rows of b
/// groups of c dots, each row outlined and its groups parted by ink lines (a cell a block, or 4 squares when a row holds
/// 12 or 15). Tap the two to do first: while pressed, the pair under the finger is bracketed under it ("5 × 2 first").
/// b × c: the lines between a row's groups go and each row's count is written at its end; a × b: the groups number 1 to
/// a × b. Write the pair, then the rest (`3 × (5 × 2) = 3 × [10] = [30]`); the other way is then written under it and the
/// picture regroups to show it. Check stands beside the line.
///
/// Hand: "press" the pair under the finger (1 b × c, 2 a × b). Kept: "pick", the pair tapped.
@MainActor
struct Three3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The equation's middle row and the array's top.
    private static let E = 1.0, Y0 = 7.0
    func recordRow(_ n: Numbers) -> Double? { 0 }
    private static func pick(_ s: PaperState) -> Bool { Three3.Parts.right(s.run.kept["pick"]) }

    private static func first(_ P: Three3.Parts) -> [M7.Tok] { [.n(P.a), .op("×"), .n(P.b), .op("×"), .n(P.c)] }
    /// The line for one way: b × c first (R) or a × b first, `lit` the pair, the pair's and the total's tokens.
    private static func way(_ P: Three3.Parts, R: Bool, lit: Bool, pair: M7.Tok, total: M7.Tok?) -> [M7.Tok] {
        let ch: Sketch.Colour = lit ? .chapter : .ink
        var t: [M7.Tok]
        // a bracket is written with the number it holds, tight: (5 × 2)
        if R { t = [.n(P.a), .op("×"), .t("(\(P.b)", ch), .op("×", ch), .t("\(P.c))", ch), .op("="), .n(P.a), .op("×"), pair] }
        else { t = [.t("(\(P.a)", ch), .op("×", ch), .t("\(P.b))", ch), .op("×"), .n(P.c), .op("="), pair, .op("×"), .n(P.c)] }
        if let total { t += [.op("="), total] }
        return t
    }
    /// Check's column: a block line two squares past the longest line.
    private static func BX(_ P: Three3.Parts) -> Double {
        var w = 0.0
        for R in [true, false] { w = max(w, M7.width(way(P, R: R, lit: false, pair: .n(P.pair(R)), total: .n(P.T)))) }
        return ((w + 2) / 5).rounded(.up) * 5
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Three3.Parts(s.numbers), st = at(s)
        guard st > 0 else { return nil }
        return CGPoint(x: Self.BX(P), y: st == 3 ? Self.E + 2 : Self.E - 1)
    }
    func say(_ s: PaperState) -> String? {
        let st = at(s)
        return st == 1 || st == 2 ? Three3.Parts(s.numbers).say(st, Self.pick(s)) : nil
    }

    /// Where the two pairs of the first line end: a × b is its first three tokens, b × c its last three.
    private static func spans(_ P: Three3.Parts) -> (l: (Double, Double), r: (Double, Double), mid: Double) {
        let w = M7.widths(first(P))
        let x2 = w[0] + w[1], x3 = x2 + w[2], end = w.reduce(0, +)
        return ((0, x3), (x2, end), x2 + w[2] / 2)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Three3.Parts(s.numbers), st = at(s), cs = Double(P.cell), E = Self.E, Y0 = Self.Y0, ch = Sketch.Colour.chapter
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let R = Self.pick(s), press = s.h("press").map { $0 == 1 }
        // which way the picture shows: the pair pressed, the pair picked, or once done the other way
        let view: Bool? = st == 0 ? (s.grabbed ? press : nil) : st == 3 ? !R : R
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        if st == 0 {
            M7.row(&rec, "e1", Self.first(P), x: 0, line: E)
            let sp = Self.spans(P)
            if s.grabbed, let r = press {
                let (x1, x2) = r ? sp.r : sp.l
                live.line("ub\(r)", [(x1 + 0.3, E + 1.1), (x1 + 0.3, E + 1.6), (x2 - 0.3, E + 1.6), (x2 - 0.3, E + 1.1)], ch)
                live.reads(r ? "\(P.b) × \(P.c) first" : "\(P.a) × \(P.b) first")
            }
            if ring { KK.hintBox(&pic, "ht", x: 0, y: E - 1, w: sp.r.1, h: 2) }
            if spot { pic.line("st", [(sp.r.0 + 0.3, E + 1.6), (sp.r.1 - 0.3, E + 1.6)], ch, dashed: true) }
        } else {
            let pair = M3.box("p", P.pair(R), cells: 2, right: st >= 2)
            let total: M7.Tok? = st >= 2 ? M3.box("t", P.T, cells: 2, right: st == 3) : nil
            M7.row(&rec, "e1", Self.way(P, R: R, lit: st == 1, pair: pair, total: total), x: 0, line: E)
            if st == 3 { M7.row(&rec, "e2", Self.way(P, R: !R, lit: false, pair: .n(P.pair(!R)), total: .n(P.T)), x: 0, line: E + 3) }
        }

        // the picture: a rows of b groups of c, each row outlined; b × c first, the lines between its groups go
        let W = Double(P.bc) * cs
        M3.array(&pic, "ar", x: 0, y: Y0, rows: P.a, cols: P.bc, c: cs, outline: false)
        for i in 0..<P.a {
            let y = Y0 + Double(i) * cs
            pic.sketch.box("row\(i)", pic.R(0, y, W, cs), .ink, width: Sketch.stroke)
            if view != true { for j in 1..<P.b { pic.line("dv\(i).\(j)", [(Double(j * P.c) * cs, y), (Double(j * P.c) * cs, y + cs)]) } }
            if view == true { pic.word("rn\(i)", "\(P.bc)", at: W + 0.5, y + cs / 2, KK.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        }
        // a × b first: the groups numbered 1 to a × b across the rows, each in its group's top-left corner
        if view == false {
            for i in 0..<P.a { for j in 0..<P.b {
                pic.word("gn\(i * P.b + j)", "\(i * P.b + j + 1)", at: Double(j * P.c) * cs + 0.35, Y0 + Double(i) * cs + 0.65, KK.lit, anchor: UnitPoint(x: 0, y: 0.5))
            } }
        }
        // hints: the pair, a row (or the groups), then the answer's place; the total, the whole array
        if st == 1 && ring { if R { KK.hintBox(&pic, "hp", x: 0, y: Y0, w: W, h: cs) } else { KK.hintBox(&pic, "hp", x: 0, y: Y0, w: W, h: Double(P.a) * cs) } }
        if st == 1 && spot { A1.note(&pic, "sp", "\(P.pair(R))", x: W + 3, y: Y0 + cs / 2) }
        if st == 2 && ring { KK.hintBox(&pic, "hq", x: 0, y: Y0, w: W, h: Double(P.a) * cs) }
        if st == 2 && spot { A1.note(&pic, "sq", "\(P.T)", x: W + 3, y: Y0 + Double(P.a) * cs / 2) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, 0, W + 3, Y0 + Double(P.a) * cs))
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let P = Three3.Parts(s.numbers), sp = Self.spans(P), E = Self.E
        let on = { (q: CGPoint) in q.x >= -0.8 && q.x <= sp.r.1 + 0.8 && q.y >= E - 1.6 && q.y <= E + 1.6 }
        func side(_ q: CGPoint) -> Double { q.x < sp.mid ? 2 : 1 }
        func picked(_ w: Double) -> HandMove { HandMove(hand: [:], missHand: [:], set: [("w", w)], keep: ["pick": w], check: true) }
        return Hands(
            tap: { q in on(q) ? picked(side(q)) : nil },
            grab: { q in on(q) ? ["grab": 1, "press": side(q)] : nil },
            drag: { q, h in var h = h; h["press"] = side(q); return h },
            release: { h in picked(h["press"] ?? 1) })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0 else { return [] }
        let sp = Self.spans(Three3.Parts(s.numbers))
        return [.tap(.picture(CGPoint(x: (sp.r.0 + sp.r.1) / 2 + 1, y: Self.E)))]
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Three3.Parts(s.numbers), R = Self.pick(s)
        switch at(s) { case 1: return ["p": Double(R ? P.b + P.c : P.a + P.b)]; case 2: return ["t": Double(P.a + P.b + P.c)]; default: return nil }
    }
}
