import SwiftUI

/// Converting measurements on the paper, as in the preview (design/prototype/grade4-ch7.html): 5th grade's Converting
/// units, big to small. A bar for each big unit, 48 squares long (40 when it's 100 or 1,000 small units), the amount over
/// them ("3 ft 5 in"), the extra small units a striped bar under them, true to size. The ruler runs along the top of the
/// first bar from its left end: dragged, it snaps a piece at a time (a small unit, or tens or hundreds of them), its cuts
/// dashed down the bar and its readout the small units it has gone ("7 inches"). Let go all the way along, every bar is
/// cut and counted on, a row of the table beside them each (ft | in: 1 | 12, 2 | 24 …); n × 12 is typed; then the extra
/// small units count on and are added.
@MainActor
struct ConvertLesson: PaperLesson {
    /// The amount's row; the ruler's and the first bar's top (with more than 6 bars the ruler runs along the first bar's
    /// top edge, so the problem still shows at 75%).
    static let nameRow = 1.0
    var liveKeys: Set<String> { ["len"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct Q {
        let p: Convert4.Parts
        /// Bars: how many (the extra's too), their height and their pitch.
        let count: Int, bh: Double, pitch: Double, Y0: Double, RY: Double
        init(_ n: Numbers) {
            p = Convert4.Parts(n)
            count = p.n + (p.m > 0 ? 1 : 0)
            (bh, pitch) = count <= 4 ? (4, 5) : count <= 6 ? (2, 3) : (2, 2)
            (Y0, RY) = count <= 6 ? (4, 3) : (3, 3)
        }
        func y(_ j: Int) -> Double { Y0 + Double(j) * pitch }
        var bottom: Double { y(count - 1) + bh }
        var W: Double { Double(p.u.W) }
        /// The table's left edge (on a block line, two squares past the bars at least), its first column's width, and
        /// the right edge of its numbers.
        var tx: Double { ((W + 2) / 5).rounded(.up) * 5 }
        var c2: Double { max(Record.width(p.u.s), Record.width(.n(p.all))) + 2 }
        var numRight: Double { tx + 4 + c2 - 1 }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), p = q.p, u = p.u, at = stage(s), W = q.W, pS = Double(p.pS), sqU = W / Double(u.per)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let cut = at >= 2, ink = Bars.count

        // the amount over the bars: the problem, once, as the picture's own name
        let amount: [M7.Tok] = [.n(p.n), .w(u.b)] + (p.m > 0 ? [.n(p.m), .w(u.s)] : [])
        if at < 4 { M7.row(&pic, "amt", amount, x: 0, line: Self.nameRow) }

        // the table's head, beside the bars
        let tx = q.tx
        pic.word("th1", u.b, at: tx + 2, q.Y0 - 1, Record.words)
        pic.word("th2", u.s, at: tx + 4 + q.c2 / 2, q.Y0 - 1, Record.words)
        pic.rule("thr", from: tx, to: tx + 4 + q.c2, row: q.Y0)
        pic.line("tvr", [(tx + 4, q.Y0 - 2), (tx + 4, q.y(p.n - 1) + q.bh)])

        // the bars: cut once the ruler has gone all along the first, then every one, each counted on and written in the
        // table as it is (they draw in in this order: the count-on)
        for j in 0..<p.n {
            let y = q.y(j)
            pic.fill("bf\(j)", col: 0, row: y, w: W, h: q.bh, .tint(0.2))
            pic.sketch.box("bo\(j)", pic.R(0, y, W, q.bh), .chapter, width: Sketch.stroke)
            pic.word("t1\(j)", "\(j + 1)", at: tx + 2, y + q.bh / 2, Bars.maths)
            guard cut else { continue }
            pic.sketch.segments("bc\(j)", (1..<p.np).map { i in (pic.P(Double(i) * pS, y), pic.P(Double(i) * pS, y + q.bh)) }, .chapter, width: Sketch.stroke)
            for i in 0..<p.np where u.pv == 1 || pS > 4 || i == 0 || (i + 1) % 5 == 0 {
                let label = u.pv == 1 ? "\(j * u.per + i + 1)" : "\(Meas4.n(u.pv)) \(u.s)"
                pic.word("bl\(j)_\(i)", label, at: (Double(i) + 0.5) * pS, y + q.bh / 2, ink)
            }
            Record.tight(&pic, "t2\(j)", (j + 1) * u.per, right: q.numRight, row: y + q.bh / 2)
        }

        // the extra small units, striped, true to size; counted on a piece at a time once the bars are
        if p.m > 0 {
            let y = q.y(p.n), xS = Double(p.xS)
            pic.stripes("xf", col: 0, row: y, w: Double(p.xW), h: q.bh)
            if at >= 3 {
                if p.nx > 1 { pic.sketch.segments("xc", (1..<p.nx).map { i in (pic.P(Double(i) * xS, y), pic.P(Double(i) * xS, y + q.bh)) }, .chapter, width: Sketch.stroke) }
                let widest = PaperText.width(Meas4.n(p.tot), PaperText.font(Sketch.small, .semibold, digits: true)) / Paper.cell
                if widest <= xS - 0.3 {
                    for i in 0..<p.nx { pic.word("xl\(i)", Meas4.n(p.all + (i + 1) * u.by), at: (Double(i) + 0.5) * xS, y + q.bh / 2, ink) }
                }
            }
            pic.sketch.box("xo", pic.R(0, y, Double(p.xW), q.bh), .chapter, width: Sketch.stroke)
            _ = sqU
        }

        // the ruler along the top of the first bar, its handle at its end, its cuts dashed down the bar; live
        if at == 1 {
            let len = s.h("len") ?? 0, RY = q.RY, e = RY == q.Y0 ? -0.6 : 0.6
            live.line("ruler", [(0, RY + e), (0, RY), (len, RY), (len, RY + e)], .chapter)
            live.dot("handle", at: len, RY, radius: s.grabbed ? 0.75 : 0.6, .chapter, over: true)
            var x = pS
            while x <= len && x < W { live.line("dc\(Int(x))", [(x, q.Y0 - 0.5), (x, q.Y0 + q.bh + 0.5)], .ink2, dashed: true); x += pS }
            if s.grabbed, len > 0 { let c = Int((len / pS).rounded()) * u.pv; live.reads("\(Meas4.n(c)) \(p.smallsOf(c))") }
            if s.on("spot") { pic.circle("ring", at: W, RY, radius: 1.3, .chapter, dashed: true) }
            else if s.on("ring") { M7.ring(&pic, "ringb", x: 0, y: q.Y0, w: W, h: q.bh) }
        }
        if at == 2 && s.on("spot") { let w = Record.width(.n(p.all)); M7.ring(&pic, "ring", x: q.numRight - w, y: q.y(p.n - 1) + q.bh / 2 - 1, w: w, h: 2) }
        else if at == 2 && s.on("ring") { M7.ring(&pic, "ringt", x: tx, y: q.Y0 - 2, w: q.numRight + 1 - tx, h: q.y(p.n - 1) + q.bh - q.Y0 + 2) }
        if at == 3 && s.on("ring") { M7.ring(&pic, "ring", x: 0, y: q.y(p.n), w: Double(p.xW), h: q.bh) }

        // the record, a row at a time; the amount goes into it at the end
        var toks: [M7.Tok] = []
        switch at {
        case 2: toks = [.n(p.n), .op("×"), .n(u.per), .op("="), .box("R", cells: String(p.all).count)]
        case 3: toks = [.n(p.all), .op("+"), .n(p.m), .op("="), .box("R", cells: String(p.tot).count)]
        case 4: toks = amount + [.op("=")] + (p.m > 0 ? [.n(p.all), .op("+"), .n(p.m)] : [.n(p.n), .op("×"), .n(u.per)])
                + [.op("="), .n(p.tot, .chapter), .w(u.s, .chapter)]
        default: break
        }
        if !toks.isEmpty { M7.row(&rec, "rec", toks, x: 0, line: 2) }
        // room for the table's numbers to come
        let extent = pic.R(0, 0, q.numRight + 1, q.bottom)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    func recordRow(_ n: Numbers) -> Double? { Q(n).bottom + 1 }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let q = Q(s.numbers), pS = Double(q.p.pS), W = q.W, pv = Double(q.p.u.pv)
        let now = s.h("len") ?? 0
        return Hands(grab: { p in abs(p.x - now) < 2.5 && abs(p.y - q.RY) < 2.5 ? ["grab": 1, "len": now, "from": now] : nil },
                     drag: { p, h in ["grab": 1, "len": min(W, max(0, (p.x / pS).rounded() * pS)), "from": h["from"] ?? now] },
                     release: { h in
                         let len = h["len"] ?? 0
                         if len == h["from"] || len == 0 { return HandMove(hand: ["len": len], missHand: nil) }
                         return HandMove(hand: ["len": len], missHand: nil, set: [("c", (len / pS).rounded() * pv)], check: true)
                     })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let q = Q(s.numbers)
        return [.drag(from: CGPoint(x: s.h("len") ?? 0, y: q.RY), to: CGPoint(x: q.W, y: q.RY))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let q = Q(s.numbers), u = q.p.u
        // a slip the web names (a foot cut at 10 inches), else half way
        let c = u.slips.first?.0 ?? u.per / 2, len = Double(c / u.pv * q.p.pS)
        return HandMove(hand: ["len": len], missHand: nil, set: [("c", Double(c))], check: true)
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = Convert4.Parts(s.numbers)
        switch stage(s) {
        case 2: return ["R": Double(p.n * 10)]
        case 3: return ["R": Double(p.all)]
        default: return nil
        }
    }
}
