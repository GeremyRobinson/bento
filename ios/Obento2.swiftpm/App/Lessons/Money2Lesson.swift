import SwiftUI

/// Kinds slid in one at a time, biggest first, and the running total written after each (the preview's slideCount: Counting
/// money's coins, Dollars and cents' bills). The rows wait at the left, the biggest on top; grab one and it follows the finger;
/// let go over the target and its value pours in (each piece glides from where the row was let go into its place, one after
/// another), or it glides home (the wrong kind is a miss: "Start with the quarters."). The readout counts the kind, never the
/// money. The totals are written down the target's right side under the readout, `50¢`, `60¢`, `[  ]¢`, Check under the box
/// being written (along one row under the square the problem showed at 70%).
///
/// "at": 2k slide kind k, 2k + 1 write after it. Hand: "grab", "i" the row held, "gx", "gy", "dx", "dy". Kept: "lx", "ly",
/// "li" where the last row was let go.
@MainActor
struct SlideIn {
    let groups: [TM2.Group]
    /// Each kind's row at home (its rect, in squares).
    let rows: [CGRect]
    let target: CGRect
    /// Where the readout and the totals' column start.
    let colX: Double
    let readout: (TM2.Group) -> String
    let money: (Int) -> String
    /// The record's tokens for the box being written.
    let box: (String) -> [M7.Tok]
    let drawRow: (inout GridPen, String, Int, Double, Double) -> Void
    /// The n-th piece of value poured in: its cell (top-left) and how it's drawn there.
    let piece: (inout GridPen, String, Int, CGPoint, Bool) -> Void
    let pieceAt: (Int) -> CGPoint

    static func line(_ i: Int) -> Double { 5 + 4 * Double(i) }
    func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    var n: Int { groups.count }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let st = at(s), k = st / 2
        if st >= 2 * n { return CGPoint(x: colX, y: Self.line(n - 1) + 2) }
        return st % 2 == 1 ? CGPoint(x: colX, y: Self.line(k) + 2) : nil
    }
    /// The rect a held row covers now.
    private func held(_ s: PaperState) -> (i: Int, dx: Double, dy: Double)? {
        guard s.grabbed, let i = s.h("i") else { return nil }
        return (Int(i), s.h("dx") ?? 0, s.h("dy") ?? 0)
    }

    func draw(_ s: PaperState, _ pic: inout GridPen, _ live: inout GridPen, _ rec: inout GridPen) {
        let st = at(s), k = st / 2, writing = st % 2 == 1 && k < n, done = st >= 2 * n
        let poured = done ? n : writing ? k + 1 : k
        // what has poured in so far, the kind being counted lit; the last kind in glides from where it was let go
        let li = s.run.kept["li"].map { Int($0) }
        for g in 0..<poured {
            let G = groups[g], lit = writing && g == k
            if g == li, !done || g == n - 1 {
                let lx = s.run.kept["lx"] ?? 0, ly = s.run.kept["ly"] ?? 0, r = rows[g]
                let c = CGPoint(x: r.midX + lx - 1.5, y: r.midY + ly - 1.5)
                pic.sketch.from = A2.kinds { q in for m in G.before..<G.after { piece(&q, "p\(m)", m, c, lit) } }
            }
            for m in G.before..<G.after { pic.sketch.delay = g == li ? 0.025 * Double(m - G.before) : 0; piece(&pic, "p\(m)", m, pieceAt(m), lit) }
            pic.sketch.from = [:]; pic.sketch.delay = 0
        }
        // the rows not in yet: the one held follows the finger; one let go elsewhere glides home
        let h = held(s)
        for i in poured..<n {
            if let h, h.i == i { drawRow(&live, "r\(i):", i, h.dx, h.dy); continue }
            if !s.grabbed, li == i, let lx = s.run.kept["lx"], let ly = s.run.kept["ly"] {
                pic.sketch.from = A2.kinds { q in drawRow(&q, "r\(i):", i, lx, ly) }
            }
            drawRow(&pic, "r\(i):", i, 0, 0)
            pic.sketch.from = [:]
        }
        // the readout beside the target counts what slid in, never the money
        if let h { let ro = readout(groups[h.i]); TMK.readout(&live, ro, x: colX, y: 1); live.reads(ro) }
        else if writing { TMK.readout(&pic, readout(groups[k]), x: colX, y: 1) }
        // the totals, each once it's right, then the one being written
        for i in 0..<n {
            if i < k || done { M7.row(&pic, "rd\(i)", [.t(money(groups[i].after))], x: colX, line: Self.line(i)) }
            else if i == k && writing { M7.row(&rec, "rw\(i)", box("a\(i)"), x: colX, line: Self.line(i)) }
        }
        // hints: sliding, a first miss rings the kind to slide and a second the target; writing, the kind's pieces, then the total
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if !writing && !done {
            if ring { let r = rows[k]; KK.hintBox(&pic, "hr", x: r.minX, y: r.minY, w: r.width, h: r.height) }
            if spot { KK.hintBox(&pic, "spot", x: target.minX, y: target.minY, w: target.width, h: target.height) }
        }
        if writing {
            if ring {
                var x0 = 99.0, y0 = 99.0, x1 = -99.0, y1 = -99.0
                for m in groups[k].before..<groups[k].after { let p = pieceAt(m); x0 = min(x0, p.x); y0 = min(y0, p.y); x1 = max(x1, p.x + 3); y1 = max(y1, p.y + 3) }
                KK.hintBox(&pic, "hr", x: x0, y: y0, w: x1 - x0, h: y1 - y0)
            }
            if spot { A1.note(&pic, "spot", "\(groups[k].after)", x: colX + 8, y: Self.line(k)) }
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let st = at(s), k = st / 2
        guard st % 2 == 0 && k < n else { return nil }
        return Hands(
            grab: { q in
                for i in k..<n where rows[i].insetBy(dx: -0.6, dy: -0.6).contains(q) { return ["grab": 1, "i": Double(i), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] }
                return nil
            },
            drag: { q, h in var h = h; h["dx"] = q.x - (h["gx"] ?? q.x); h["dy"] = q.y - (h["gy"] ?? q.y); return h },
            release: { h in
                let i = Int(h["i"] ?? 0), dx = h["dx"] ?? 0, dy = h["dy"] ?? 0
                let q = CGPoint(x: (h["gx"] ?? 0) + dx, y: (h["gy"] ?? 0) + dy)
                let keep: Numbers = ["lx": dx, "ly": dy, "li": Double(i)]
                guard target.insetBy(dx: -1, dy: -1).contains(q) else { return HandMove(hand: [:], keep: keep) }
                return HandMove(hand: [:], missHand: [:], set: [("s\(k)", Double(i))], keep: keep, check: true)
            })
    }
    func demo(_ s: PaperState) -> [GhostMove] {
        let st = at(s), k = st / 2
        guard st % 2 == 0 && k < n else { return [] }
        let r = rows[k]
        return [.drag(from: CGPoint(x: r.midX, y: r.midY), to: CGPoint(x: target.midX, y: target.midY))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let st = at(s), k = st / 2
        guard st % 2 == 0 && k + 1 < n else { return nil }
        return HandMove(hand: [:], missHand: [:], set: [("s\(k)", Double(k + 1))], keep: ["lx": target.midX - rows[k + 1].midX, "ly": target.midY - rows[k + 1].midY, "li": Double(k + 1)], check: true)
    }
}

/// Counting money on the paper, as in the preview (design/prototype/grade2-ch6.html, dMoney): a cent is a 3 × 3 counter, so a
/// dollar is the dollar square (30 × 30, four quarter blocks). The coins at the left in rows by kind, the biggest on top, each
/// row fanned (a coin 3 squares on from the last; a quarter 8 squares across, a nickel 7, a penny and a dime 6); the empty
/// square from the next block. Slide in each kind, biggest first: its cents pour in block by block, row by row, the kind's lit
/// while it's counted; write the running total (SlideIn).
@MainActor
struct Money2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy"] }
    static let SX = 20.0
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func kit(_ n: Numbers) -> SlideIn {
        let P = Money2.Parts(n), G = P.G
        var rows: [CGRect] = [], y = 0.0
        for g in G {
            let md = Double(TM2.coins[g.kind].small)
            rows.append(CGRect(x: 0, y: y, width: 3 * Double(g.count - 1) + md, height: md)); y += md + 1
        }
        let side = P.side
        return SlideIn(groups: G, rows: rows, target: CGRect(x: Self.SX, y: 0, width: 30, height: 30), colX: Self.SX + 32,
            readout: { g in "\(g.count) \(Money2.Parts.name(g))" }, money: { "\($0)¢" },
            box: { [.box($0, cells: 2), .t("¢")] },
            drawRow: { pen, id, i, dx, dy in
                let g = G[i], md = Double(TM2.coins[g.kind].small), r = rows[i]
                for j in 0..<g.count {
                    let x = r.minX + dx + md / 2 + 3 * Double(j), y = r.minY + dy + md / 2
                    TMK.coin(&pen, "\(id)\(j)", g.kind, cx: x, cy: y, r: md / 2, side: side, under: j + 1 < g.count ? (x + 3, y, md / 2) : nil)
                }
            },
            piece: { pen, id, _, p, lit in TMK.cent(&pen, id, x: p.x, y: p.y, lit: lit) },
            pieceAt: { TMK.centAt($0, x: Self.SX, y: 0) })
    }
    func blocksAt(_ s: PaperState) -> CGPoint? { kit(s.numbers).blocksAt(s) }

    func draw(_ s: PaperState) -> PaperDrawing {
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        TMK.dollarSquare(&pic, x: Self.SX, y: 0)
        kit(s.numbers).draw(s, &pic, &live, &rec)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, Self.SX + 41, 30))
    }
    func hands(_ s: PaperState) -> Hands? { kit(s.numbers).hands(s) }
    func demo(_ s: PaperState) -> [GhostMove] { kit(s.numbers).demo(s) }
    func wrongMove(_ s: PaperState) -> HandMove? { kit(s.numbers).wrongMove(s) }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let K = kit(s.numbers), st = K.at(s), k = st / 2
        guard st % 2 == 1, k < K.n else { return nil }
        return ["a\(k)": Double(Money2.Parts.slips(K.groups[k]).first?.0 ?? 1)]
    }
}
