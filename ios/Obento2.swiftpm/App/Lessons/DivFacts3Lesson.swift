import SwiftUI

/// Division facts on the paper, as in the preview (design/prototype/grade3-ch1.html, dDiv): a dot in a 3-square cell. The
/// pile of a in rows of 10 on the left, a over it; b empty rows a block right of it, b down their left in a bracket. Drag
/// their right edge across: each column takes one dot for every row from the end of the pile, gliding across ("3 in each ·
/// 12 left"). Let go short: "Keep going"; past: "That's more than 24" and it goes back. Shared, the pile is empty, a moves
/// over the rows and each row's end says q. The record is written where the pile was: `4 × 6 = 24`, `24 ÷ 4 = [ ]`.
///
/// Hand: "grab", "k" the columns now, "k0" when grabbed.
@MainActor
struct DivFacts3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let c = 3.0, X0 = 0.0, SX = 35.0, Y0 = M3.Y0
    /// The record where the pile was (the hands emptied it), its blocks under it.
    func recordRow(_ n: Numbers) -> Double? { Self.Y0 }
    func blocksLeft(_ n: Numbers) -> Double? { 0 }

    /// Where pile dot i is: in the pile, or (once k columns are shared) in its row.
    static func spot(_ i: Int, a: Int, b: Int, k: Int, sx: Double = SX, y: Double = Y0) -> CGPoint {
        let e = a - 1 - i, j = e / b, r = e % b
        if j < k { return CGPoint(x: sx + (Double(j) + 0.5) * c, y: y + (Double(r) + 0.5) * c) }
        return CGPoint(x: X0 + (Double(i % 10) + 0.5) * c, y: y + (Double(i / 10) + 0.5) * c)
    }

    /// The rows being filled (shared by Two-step's sharing too): faint lines across while sharing, the filled part outlined
    /// row by row, the left side; b down the left in a bracket; the edge to drag; once done, each row's end says q.
    static func rows(_ pic: inout GridPen, _ live: inout GridPen, sx: Double, y: Double, rows b: Int, k: Int, done: Bool, held: Bool) {
        let c = Self.c
        if !done {
            var segs: [(CGPoint, CGPoint)] = []
            for r in 0...b { segs.append((pic.P(sx, y + Double(r) * c), pic.P(sx + 10 * c, y + Double(r) * c))) }
            pic.sketch.segments("shg", segs, .ink3, width: 1)
        }
        if k > 0 {
            M3.array(&pic, "shr", x: sx, y: y, rows: b, cols: k, c: c, dots: false)
        }
        pic.line("shl", [(sx, y), (sx, y + Double(b) * c)])
        M3.bracket(&pic, "shb", x: sx - 1, y1: y, y2: y + Double(b) * c, open: false, name: "\(b)")
        if !done { M3.edge(&live, rows: false, x: sx, y: y, at: sx + Double(k) * c, span: Double(b) * c, held: held) }
        if done { for r in 0..<b { pic.word("end\(r)", "\(k)", at: sx + Double(k) * c + 0.5, y + (Double(r) + 0.5) * c, M3.lit, anchor: UnitPoint(x: 0, y: 0.5)) } }
    }
    static func readout(_ k: Int, rows b: Int, of a: Int) -> String {
        let left = a - k * b
        return left >= 0 ? "\(k) in each · \(left) left" : "\(k) in each · \(-left) missing"
    }
    /// Drag the rows' edge across, a column at a time; let go on q, or short (keep going), or past (back to before).
    static func shareHands(_ s: PaperState, sx: Double, y: Double, rows b: Int, q: Int, box: String) -> Hands {
        let k = Int((s.h("k") ?? 0).rounded())
        return Hands(
            grab: { p in M3.onEdge(p, rows: false, x: sx, y: y, at: sx + Double(k) * c, span: Double(b) * c) ? ["grab": 1, "k": Double(k), "k0": Double(k)] : nil },
            drag: { p, h in var h = h; h["k"] = Double(max(0, min(10, Int(((p.x - sx) / c).rounded())))); return h },
            release: { h in
                let n = Int((h["k"] ?? 0).rounded()), k0 = Int((h["k0"] ?? 0).rounded())
                guard n > 0 else { return HandMove(hand: ["k": 0]) }
                let back = n > q ? Double(min(k0, q - 1)) : Double(n)
                return HandMove(hand: ["k": Double(n)], missHand: ["k": back], set: [(box, Double(n))], check: true)
            })
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = DivFacts3.Parts(s.numbers), st = at(s), c = Self.c, X0 = Self.X0, SX = Self.SX, Y0 = Self.Y0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let k = st == 0 ? Int((s.h("k") ?? 0).rounded()) : P.q, pileRows = (P.a + 9) / 10
        // a over the pile; once it's shared, over the rows that hold it
        if st == 0 { pic.label("pn\(st)", "\(P.a)", M3.maths, .above, edge: Y0, along: X0 + Double(min(P.a, 10)) * c / 2) }
        else { pic.label("pn\(st)", "\(P.a)", M3.maths, .above, edge: Y0, along: SX + Double(P.q) * c / 2) }
        for i in 0..<P.a {
            let p = Self.spot(i, a: P.a, b: P.b, k: k)
            pic.dot("d\(i)", at: p.x, p.y, radius: M3.dotR(c))
        }
        Self.rows(&pic, &live, sx: SX, y: Y0, rows: P.b, k: k, done: st > 0, held: s.grabbed)
        if st == 0 {
            if s.grabbed { live.reads(Self.readout(k, rows: P.b, of: P.a)) }
            if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hp", x: X0, y: Y0, w: Double(min(P.a, 10)) * c, h: Double(pileRows) * c) }
            if s.on("spot") { pic.line("sp", [(SX + Double(P.q) * c, Y0 - 0.5), (SX + Double(P.q) * c, Y0 + Double(P.b) * c + 0.5)], .chapter, dashed: true) }
        } else {
            M7.row(&rec, "l1", [.n(P.b), .op("×"), .n(P.q), .op("="), .n(P.a)], x: 0, line: 1)
            M7.row(&rec, "l2", [.n(P.a), .op("÷"), .n(P.b), .op("="), M3.box("d", P.q, cells: 2, right: st == 2)], x: 0, line: 4)
            if st == 1 && (s.on("ring") || s.on("spot")) { KK.hintBox(&pic, "hr", x: SX, y: Y0, w: Double(P.q) * c + 2.5, h: c) }
            if st == 1 && s.on("spot") { KK.hintBox(&rec, "hs", x: 0, y: 0, w: M7.width([.n(P.b), .op("×"), .n(P.q), .op("="), .n(P.a)]), h: 2) }
        }
        let tall = Double(max(pileRows, P.b)) * c
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: st == 0 ? pic.R(X0, Y0, SX + 10 * c + 1 - X0, tall) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = DivFacts3.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        return Self.shareHands(s, sx: Self.SX, y: Self.Y0, rows: P.b, q: P.q, box: "k")
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = DivFacts3.Parts(s.numbers)
        guard at(s) == 0 else { return [] }
        let k = Double(Int((s.h("k") ?? 0).rounded())), y = Self.Y0 + Double(P.b) * Self.c / 2
        return [.drag(from: CGPoint(x: Self.SX + k * Self.c, y: y), to: CGPoint(x: Self.SX + Double(P.q) * Self.c, y: y))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = DivFacts3.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        let n = min(10, P.q + 1)
        return HandMove(hand: ["k": Double(n)], missHand: ["k": 0], set: [("k", Double(n == P.q ? P.q - 1 : n))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? { at(s) == 1 ? ["d": Double(DivFacts3.Parts(s.numbers).b)] : nil }
}
