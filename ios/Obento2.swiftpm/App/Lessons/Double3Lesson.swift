import SwiftUI

/// Double a fact on the paper, as in the preview (design/prototype/grade3-ch2.html, dDouble): 2h rows of n dots (a cell of 4
/// squares, 5 for a small fact), n over the top and 2h down the left. The ruler's handle sticks out of the right edge at
/// the bottom; dragged up it snaps between rows, a dashed cut runs across ("14 | 14"). Let go at the middle: the halves
/// part a square, each named `2 × 7` at its right. Write one half (`= [14] + 14`), then the double (`= [28]`); tap Even or
/// Odd beside it; then the fact's row of the times table writes itself under the record in the chapter colour.
///
/// The record always goes beside the picture (its blocks are tapped where it is): it starts on the block line two squares
/// past the picture's room, level with the array's top.
///
/// Hand: "grab", "k" the rows above the cut (2h: resting at the bottom). Kept: "pick" an odd tap (1), cleared when right.
@MainActor
struct Double3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private static let X0 = M3.X0, Y0 = M3.Y0
    var liveKeys: Set<String> { ["k"] }
    func recordBeside(_ n: Numbers) -> Double? { Self.Y0 }
    /// Under the picture never shows it bigger than beside (and the blocks must know where the record is).
    func recordRow(_ n: Numbers) -> Double? { 500 }
    private static func ruler(_ P: Double3.Parts) -> T3.Ruler { T3.Ruler(down: false, x: X0, y: Y0, c: Double(P.c), n: P.rows, span: P.n) }
    /// The picture's room on every step ends here; the record starts on the block line two squares past it.
    private static func right(_ P: Double3.Parts) -> Double { X0 + Double(P.n * P.c) + 10 }
    private static func RL(_ P: Double3.Parts) -> Double { ((right(P) + 2) / 5 - 1e-6).rounded(.up) * 5 }
    private static func x6(_ P: Double3.Parts) -> Double { M7.width([.n(P.rows), .op("×"), .n(P.n)]) }
    /// Even and Odd, beside the double, in the picture's squares.
    private static func picks(_ P: Double3.Parts) -> [CGRect] {
        let x = RL(P) + x6(P) + M7.width([.op("="), .n(P.P)]) + 2, y = Y0 + 6
        return [CGRect(x: x, y: y, width: 4, height: 2), CGRect(x: x + 5, y: y, width: 4, height: 2)]
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Double3.Parts(s.numbers), st = at(s), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0, ch = Sketch.Colour.chapter
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let W = Double(P.n) * c, cut = st > 0, gap: Double = cut ? 1 : 0, H = Double(P.rows) * c + gap
        let parts = T3.split(&pic, "ar", x: X0, y: Y0, rows: P.rows, cols: P.n, c: c, byCols: false, at: P.h, gap: gap, cut: cut,
                             tint: (cut, cut && st != 1))
        pic.label("top", "\(P.n)", M3.maths, .above, edge: Y0, along: X0 + W / 2)
        M3.bracket(&pic, "bl", x: X0 - 1, y1: Y0, y2: Y0 + H, open: false, name: "\(P.rows)")
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        let extent = pic.R(X0 - 1, Y0, Self.right(P) - X0 + 1, H + 1)
        if st == 0 {
            let k = Int((s.h("k") ?? Double(P.rows)).rounded())
            Self.ruler(P).draw(&live, k, held: s.grabbed)
            if s.grabbed { live.reads("\(k * P.n) | \((P.rows - k) * P.n)") }
            // a miss rings the side the ruler slides down; a second dashes the middle
            if ring { KK.hintBox(&pic, "hr", x: X0 + W + 0.5, y: Y0, w: 3.5, h: H) }
            if spot { pic.line("sp", [(X0 - 0.5, Y0 + Double(P.h) * c), (X0 + W + 0.5, Y0 + Double(P.h) * c)], ch, dashed: true) }
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
        }
        // each half's name at its right (a second miss on the half writes what it makes)
        for (i, p) in parts.enumerated() {
            let name = "\(P.h) × \(P.n)" + (i == 0 && st == 1 && spot ? " = \(P.half)" : "")
            pic.word("n\(i)", name, at: X0 + W + 0.5, p.midY, M3.maths, anchor: UnitPoint(x: 0, y: 0.5))
        }
        if st == 1 && ring { KK.hintBox(&pic, "hh", x: X0, y: Y0, w: W, h: parts[0].height) }
        if st == 2 && ring { KK.hintBox(&pic, "hd", x: X0, y: Y0, w: W, h: H) }
        if st == 2 && spot { A1.note(&pic, "sd", "\(P.P)", x: X0 + W + 0.5, y: parts[0].maxY + 0.5) }
        if st == 3 && ring { KK.hintBox(&pic, "he", x: X0, y: Y0, w: W, h: H) }

        // the record: 4 × 7 = 2 × 7 + 2 × 7, = [14] + 14, = [28]
        let lit: Sketch.Colour = st == 1 ? ch : .ink
        M7.row(&rec, "l1", [.n(P.rows), .op("×"), .n(P.n), .op("="), .n(P.h, lit), .op("×", lit), .n(P.n, lit), .op("+"), .n(P.h), .op("×"), .n(P.n)], x: 0, line: 1)
        let x6 = Self.x6(P)
        var l2: [M7.Tok] = [.op("="), M3.box("h", P.half, cells: 2, right: st >= 2)]
        if st >= 2 { l2 += [.op("+"), .n(P.half, ch)] }
        M7.row(&rec, "l2", l2, x: x6, line: 4)
        if st >= 2 { M7.row(&rec, "l3", [.op("="), M3.box("d", P.P, cells: 2, right: st >= 3)], x: x6, line: 7) }
        if st >= 3 {
            // drawn with the record (where they show), tapped in the picture's squares (Self.picks)
            let r = Self.picks(P).map { $0.offsetBy(dx: -Self.RL(P), dy: -Y0) }, odd = s.run.kept["pick"] == 1
            T3.block(&rec, "ev", x: r[0].minX, y: r[0].minY, w: 4, "Even", right: st == 4)
            if st == 3 { T3.block(&rec, "od", x: r[1].minX, y: r[1].minY, w: 4, "Odd", wrong: odd) }
            if st == 3 && spot { KK.hintBox(&rec, "hk", x: r[0].minX, y: r[0].minY, w: 4, h: 2) }
        }
        if st == 4 {
            // the fact's row of the times table, every one even
            let t = P.table
            var a: [M7.Tok] = [], b: [M7.Tok] = []
            for (i, v) in t.enumerated() {
                if i < 5 { a.append(.t("\(v),", ch)) } else { b.append(.t(i < 9 ? "\(v)," : "\(v)", ch)) }
            }
            M7.row(&rec, "t1", a, x: 0, line: 10)
            M7.row(&rec, "t2", b, x: 0, line: 13)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Double3.Parts(s.numbers), st = at(s)
        if st == 3 {
            let r = Self.picks(P)
            return Hands(tap: { q in
                guard let i = r.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["pick": i == 1 ? 1 : -1], check: true)
            })
        }
        guard st == 0 else { return nil }
        let R = Self.ruler(P), k = Int((s.h("k") ?? Double(P.rows)).rounded())
        return Hands(
            grab: { q in R.holds(q, k) ? ["grab": 1, "k": Double(k)] : nil },
            drag: { q, h in var h = h; h["k"] = Double(R.snap(q)); return h },
            release: { h in
                let k = Int((h["k"] ?? Double(P.rows)).rounded())
                guard k < P.rows else { return HandMove(hand: ["k": Double(P.rows)]) }
                return HandMove(hand: ["k": Double(k)], missHand: ["k": Double(P.rows)], set: [("k", Double(k))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Double3.Parts(s.numbers)
        switch at(s) {
        case 0: let R = Self.ruler(P); return [.drag(from: R.at(P.rows), to: R.at(P.h))]
        case 3: let r = Self.picks(P)[0]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Double3.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: ["k": Double(P.rows)], missHand: ["k": Double(P.rows)], set: [("k", Double(P.h + 1))], check: true)
        case 3: return HandMove(hand: nil, missHand: nil, set: [("c", 1)], keep: ["pick": 1], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Double3.Parts(s.numbers)
        switch at(s) { case 1: return ["h": Double(P.h + P.n)]; case 2: return ["d": Double(P.half)]; default: return nil }
    }
}
