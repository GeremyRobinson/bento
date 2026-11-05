import SwiftUI

/// Two-step word problems on the paper, as in the preview (design/prototype/grade3-ch1.html, dTwoStep): the story on the
/// picture's top rows, its numbers in the chapter colour. Then fewer / then more: drag down to make the packs (each row
/// outlined as one pack, "3 packs · 18"), write how many; a block of c waits right of the packs: slide it over the last ones
/// (they're crossed out, "19 left") or in after the last one ("29 in all"), write how many now. Then share: the pile of a in
/// rows of 10; slide c away from its end, write how many are left; drag across to share them into b (Division facts' rows),
/// write how many in each. To show every problem at 75% a thing's cell is the biggest of 5, 4, 3 or 2 squares that fits,
/// and when the extras of "then more" would make the packs too tall they wait in a column of their own beside them.
///
/// Hand: "grab", "n" the packs; "grab", "px", "o0", "off" the block slid (cells right of where it lands); "grab", "k", "k0"
/// the share.
@MainActor
struct TwoStep3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let X0 = 5.0

    /// Where everything goes for these numbers.
    @MainActor struct Geo {
        let P: TwoStep3.Parts, R: Int, c: Double, beside: Bool
        /// The block's cells where it lands, in cells of the picture (column, row), and how far right it waits.
        let cells: [(Int, Int)], S: Int
        var Y0: Double { 2 * Double(R) + 3 }
        var X0: Double { P.kind == 2 ? 0 : TwoStep3Lesson.X0 }
        /// Share: the rows' left edge, a block right of the pile.
        var SX: Double { 10 * c + 5 }
        var rows: Int { P.kind == 2 ? (P.a + 9) / 10 : P.kind == 1 && !beside ? (P.P + P.cc + P.b - 1) / P.b : P.a }
        var wrap: Int { P.kind == 2 ? 10 : P.b }
        /// The cells right of the picture the block reaches as it waits.
        var right: Int { (cells.map(\.0).max() ?? 0) + S + 1 }
        /// What the block covers now, `off` cells right of where it lands.
        func covered(_ off: Int) -> Int {
            cells.filter { col, row in
                let x = col + off
                switch P.kind {
                case 0: return x < P.b && row * P.b + x < P.P
                case 1: return beside ? x >= P.b + 1 && x < 2 * P.b + 1 : x < P.b
                default: return x < 10 && row * 10 + x < P.a
                }
            }.count
        }
        func at(_ col: Int, _ row: Int) -> CGPoint { CGPoint(x: X0 + Double(col) * c, y: Y0 + Double(row) * c) }

        /// The story's width.
        let width: Double
        /// How many cells right the picture reaches (the block waiting included).
        static func reach(_ P: TwoStep3.Parts, _ beside: Bool) -> Int { P.kind == 1 && beside ? 3 * P.b + 3 : 2 * P.b + 2 }
        /// The cell (5, 4, 3 or 2 squares) and whether the extras wait beside the packs, for `room` squares under the story.
        static func size(_ P: TwoStep3.Parts, room: Double) -> (Double, Bool) {
            if P.kind == 2 { return (Double(max((P.a + 9) / 10, P.b)) * 3 <= room - 12 ? 3 : 2, false) }
            let appendRows = (P.P + P.cc + P.b - 1) / P.b
            let beside = P.kind == 1 && Double(appendRows) * 2 > room
            let rows = P.kind == 1 && !beside ? appendRows : P.a
            for k in [5.0, 4, 3, 2] where Double(rows) * k <= room && Double(reach(P, beside)) * k <= 48 { return (k, beside) }
            return (2, beside)
        }
        init(_ n: Numbers) {
            let P = TwoStep3.Parts(n)
            self.P = P
            // the story wraps to the picture's width (44 at least), so it takes the fewest rows that keep the frame narrow
            var rows = A2.storyRows(P.lines, width: 44).count, cell = 2.0, besideNow = false
            for _ in 0..<2 {
                (cell, besideNow) = Self.size(P, room: 29 - 2 * Double(rows))
                let wide = P.kind == 2 ? 10 * cell + 5 + 10 * cell : TwoStep3Lesson.X0 + Double(Self.reach(P, besideNow)) * cell
                rows = A2.storyRows(P.lines, width: max(44, wide)).count
            }
            R = rows; width = max(44, P.kind == 2 ? 10 * cell + 5 + 10 * cell : TwoStep3Lesson.X0 + Double(Self.reach(P, besideNow)) * cell)
            c = cell; beside = besideNow
            var cs: [(Int, Int)] = []
            for t in 0..<P.cc {
                switch P.kind {
                case 0: let i = P.P - P.cc + t; cs.append((i % P.b, i / P.b))
                case 1: if besideNow { cs.append((P.b + 1 + t % P.b, t / P.b)) } else { let i = P.P + t; cs.append((i % P.b, i / P.b)) }
                default: let i = P.a - P.cc + t; cs.append((i % 10, i / 10))
                }
            }
            cells = cs
            let minCol = cs.map(\.0).min() ?? 0
            S = (P.kind == 2 ? 12 : P.kind == 1 && besideNow ? 2 * P.b + 2 : P.b + 1) - minCol
        }
    }

    func recordBeside(_ n: Numbers) -> Double? { Geo(n).Y0 }
    func recordRow(_ n: Numbers) -> Double? { let g = Geo(n); return g.Y0 + Double(g.P.kind == 2 ? max(g.rows, g.P.b) : g.rows) * g.c + 3 }
    func told(_ s: PaperState) -> String? { TwoStep3.Parts(s.numbers).story }

    /// The step's stage: the packs (or the slide first, sharing), write, slide, write, done.
    private enum Stage { case packs, w1, slide, share, w2, done }
    private func stage(_ s: PaperState, _ P: TwoStep3.Parts) -> Stage {
        let st = at(s)
        if P.kind == 2 { return [Stage.slide, .w1, .share, .w2, .done][max(0, min(4, st))] }
        return [Stage.packs, .w1, .slide, .w2, .done][max(0, min(4, st))]
    }

    private func block(_ pen: inout GridPen, _ g: Geo, off: Int) {
        let c = g.c
        for (t, cell) in g.cells.enumerated() {
            let p = g.at(cell.0 + off, cell.1)
            pen.fill("bkf\(t)", col: p.x, row: p.y, w: c, h: c, .tint(0.2))
            pen.sketch.box("bko\(t)", pen.R(p.x, p.y, c, c), .ink, width: Sketch.stroke)
            pen.dot("bkd\(t)", at: p.x + c / 2, p.y + c / 2, radius: M3.dotR(c), over: true)
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = Geo(s.numbers), P = g.P, w = P.w, c = g.c, X0 = g.X0, Y0 = g.Y0, st = stage(s, P)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        A2.tell(&pic, P.lines, width: g.width)
        let off = Int((s.h("off") ?? Double(g.S)).rounded())
        var extent: CGRect?
        if P.kind < 2 {
            let made = st != .packs, n = made ? P.a : Int((s.h("n") ?? 1).rounded()), B = Double(P.b) * c
            let landed = st == .w2 || st == .done
            M3.array(&pic, "ar", x: X0, y: Y0, rows: n, cols: P.b, c: c, outline: false, dots: false)
            for i in 0..<n {
                pic.sketch.box("pk\(i)", pic.R(X0, Y0 + Double(i) * c, B, c), .ink, width: Sketch.stroke)
                for j in 0..<P.b {
                    let gone = P.kind == 0 && landed && i * P.b + j >= P.P - P.cc
                    let cx = X0 + (Double(j) + 0.5) * c, cy = Y0 + (Double(i) + 0.5) * c
                    pic.dot("ad\(i).\(j)\(gone)", at: cx, cy, radius: M3.dotR(c), gone ? .tint(0.4) : .chapter)
                    if gone { M3.cross(&pic, "cx\(i).\(j)", cx: cx, cy: cy, c: c) }
                }
            }
            pic.label("top", "\(P.b)", M3.maths, .above, edge: Y0, along: X0 + B / 2)
            M3.bracket(&pic, "bl", x: X0 - 1, y1: Y0, y2: Y0 + Double(P.a) * c, open: !made, name: "\(P.a)")
            if st == .packs {
                M3.edge(&live, rows: true, x: X0, y: Y0, at: Y0 + Double(n) * c, span: B, held: s.grabbed)
                if s.grabbed { live.reads("\(G3.count(n, w.group, w.groups)) · \(n * P.b)") }
                if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hr", x: X0 - 4, y: Y0, w: 3.5, h: Double(P.a) * c) }
                if s.on("spot") { pic.line("sp", [(X0 - 0.5, Y0 + Double(P.a) * c), (X0 + B + 0.5, Y0 + Double(P.a) * c)], .chapter, dashed: true) }
                extent = pic.R(X0 - 1, Y0, B + 1, Double(P.a) * c + 1)
            }
            // the c more, in after the last one (or beside the packs)
            if P.kind == 1 && landed {
                for (t, cell) in g.cells.enumerated() {
                    let p = g.at(cell.0, cell.1)
                    pic.sketch.box("bko\(t)", pic.R(p.x, p.y, c, c), .ink3, width: 1)
                    pic.dot("bkd\(t)", at: p.x + c / 2, p.y + c / 2, radius: M3.dotR(c))
                }
            }
        } else {
            // the pile of a in rows of 10, its last c slid away; the rest shared into b rows
            let sharing = st == .share || st == .w2 || st == .done, gone = st != .slide
            let k = st == .share ? Int((s.h("k") ?? 0).rounded()) : sharing ? P.q : 0
            pic.label("pn", "\(P.a)", M3.maths, .above, edge: Y0, along: X0 + Double(min(P.a, 10)) * c / 2)
            for i in 0..<P.a {
                var p = CGPoint(x: X0 + (Double(i % 10) + 0.5) * c, y: Y0 + (Double(i / 10) + 0.5) * c)
                if i >= P.P {
                    pic.dot("d\(i)\(gone)", at: p.x, p.y, radius: M3.dotR(c), gone ? .tint(0.4) : .chapter)
                    if gone { M3.cross(&pic, "cx\(i)", cx: p.x, cy: p.y, c: c) }
                    continue
                }
                let e = P.P - 1 - i, j = e / P.b, r = e % P.b
                if sharing && j < k { p = CGPoint(x: g.SX + (Double(j) + 0.5) * c, y: Y0 + (Double(r) + 0.5) * c) }
                pic.dot("d\(i)", at: p.x, p.y, radius: M3.dotR(c))
            }
            if sharing {
                DivFacts3Lesson.rows(&pic, &live, sx: g.SX, y: Y0, rows: P.b, k: k, done: st != .share, held: s.grabbed, c: c)
                if st == .share {
                    if s.grabbed { live.reads(DivFacts3Lesson.readout(k, rows: P.b, of: P.P)) }
                    if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hr", x: X0, y: Y0, w: 10 * c, h: Double(g.rows) * c) }
                    if s.on("spot") { pic.line("sp", [(g.SX + Double(P.q) * c, Y0 - 0.5), (g.SX + Double(P.q) * c, Y0 + Double(P.b) * c + 0.5)], .chapter, dashed: true) }
                    extent = pic.R(X0, Y0, g.SX + 10 * c + 1 - X0, Double(max(g.rows, P.b)) * c)
                }
            }
        }
        // the slide: the block waits right of the picture; held, it follows the finger a cell at a time
        if st == .slide {
            if s.grabbed { block(&live, g, off: off) } else { block(&pic, g, off: off) }
            if s.grabbed { live.reads(P.kind == 1 ? "\(P.P + g.covered(off)) in all" : "\((P.kind == 2 ? P.a : P.P) - g.covered(off)) left") }
            let x0 = g.cells.map(\.0).min() ?? 0, x1 = g.cells.map(\.0).max() ?? 0, y0 = g.cells.map(\.1).min() ?? 0, y1 = g.cells.map(\.1).max() ?? 0
            if s.on("ring") || s.on("spot") { let p = g.at(x0, y0); KK.hintBox(&pic, "hs", x: p.x, y: p.y, w: Double(x1 - x0 + 1) * c, h: Double(y1 - y0 + 1) * c) }
            if s.on("spot") { for (t, cell) in g.cells.enumerated() { let p = g.at(cell.0, cell.1); pic.sketch.box("sps\(t)", pic.R(p.x, p.y, c, c), .chapter, width: Sketch.stroke, dashed: true) } }
            let r = g.at(g.right, g.rows)
            extent = pic.R(X0 - 1, Y0, r.x - X0 + 2, r.y - Y0)
        }
        // the record: the first step's line, then the second's
        if st != .packs && !(P.kind == 2 && st == .slide) {
            let cl = M3.cells(max(P.P, P.ans2))
            let first: [M7.Tok] = P.kind == 2 ? [.n(P.a), .op("−"), .n(P.cc), .op("=")] : [.n(P.a), .op("×"), .n(P.b), .op("=")]
            M7.row(&rec, "l1", first + [M3.box("g", P.P, cells: cl, right: st != .w1)], x: 0, line: 1)
            if st == .w2 || st == .done {
                let second: [M7.Tok] = P.kind == 2 ? [.n(P.P), .op("÷"), .n(P.b), .op("=")] : [.n(P.P), .op(P.kind == 0 ? "−" : "+"), .n(P.cc), .op("=")]
                M7.row(&rec, "l2", second + [M3.box("h", P.ans2, cells: cl, right: st == .done)], x: 0, line: 4)
            }
            // hints on the written steps: a miss rings what to count; a second writes the counts at the rows' ends
            if st == .w1 && (s.on("ring") || s.on("spot")) {
                if P.kind == 2 { KK.hintBox(&pic, "hw", x: X0, y: Y0, w: 10 * c, h: Double(g.rows) * c) }
                else { KK.hintBox(&pic, "hw", x: X0, y: Y0, w: Double(P.b) * c, h: Double(P.a) * c) }
            }
            if st == .w1 && s.on("spot") {
                if P.kind == 2 { A1.note(&pic, "sp", "\(P.P) left", x: X0, y: Y0 + Double(g.rows) * c + 1.2) }
                else { for i in 0..<P.a { pic.word("spn\(i)", "\((i + 1) * P.b)", at: X0 + Double(P.b) * c + 0.5, Y0 + (Double(i) + 0.5) * c, M3.lit, anchor: UnitPoint(x: 0, y: 0.5)) } }
            }
            if st == .w2 && (s.on("ring") || s.on("spot")) {
                if P.kind == 2 { KK.hintBox(&pic, "hw2", x: g.SX, y: Y0, w: Double(P.q) * c + 2.5, h: c) }
                else {
                    let x0 = g.cells.map(\.0).min() ?? 0, x1 = g.cells.map(\.0).max() ?? 0, y0 = g.cells.map(\.1).min() ?? 0, y1 = g.cells.map(\.1).max() ?? 0
                    let p = g.at(x0, y0); KK.hintBox(&pic, "hw2", x: p.x, y: p.y, w: Double(x1 - x0 + 1) * c, h: Double(y1 - y0 + 1) * c)
                }
            }
            if st == .w2 && s.on("spot") && P.kind < 2 {
                KK.hintBox(&rec, "hs2", x: 0, y: 0, w: M7.width(first + [.n(P.P)]), h: 2)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = Geo(s.numbers), P = g.P, c = g.c, st = stage(s, P), X0 = g.X0, Y0 = g.Y0
        switch st {
        case .packs:
            let n = Int((s.h("n") ?? 1).rounded()), B = Double(P.b) * c, cap = G3.cap(P.a, Int(c))
            return Hands(
                grab: { q in M3.onEdge(q, rows: true, x: X0, y: Y0, at: Y0 + Double(n) * c, span: B) ? ["grab": 1, "n": Double(n)] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(1, min(cap, Int(((q.y - Y0) / c).rounded())))); return h },
                release: { h in
                    let k = Int((h["n"] ?? 1).rounded())
                    guard k != 1 else { return HandMove(hand: ["n": 1]) }
                    return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("p", Double(k))], check: true)
                })
        case .slide:
            let off = Int((s.h("off") ?? Double(g.S)).rounded())
            func on(_ q: CGPoint) -> Bool {
                g.cells.contains { cell in let p = g.at(cell.0 + off, cell.1); return q.x >= p.x - 0.5 && q.x <= p.x + c + 0.5 && q.y >= p.y - 0.5 && q.y <= p.y + c + 0.5 }
            }
            return Hands(
                grab: { q in on(q) ? ["grab": 1, "px": q.x, "o0": Double(off), "off": Double(off)] : nil },
                drag: { q, h in
                    var h = h
                    h["off"] = Double(max(0, min(g.S + 1, Int(h["o0"] ?? 0) + Int(((q.x - (h["px"] ?? 0)) / c).rounded()))))
                    return h
                },
                release: { h in
                    let o = Int((h["off"] ?? Double(g.S)).rounded()), cov = g.covered(o)
                    if o == 0 { return HandMove(hand: [:], set: [("s", 0)], check: true) }
                    if cov > 0 { return HandMove(hand: ["off": Double(o)], missHand: ["off": Double(g.S)], set: [("s", Double(cov))], check: true) }
                    return HandMove(hand: ["off": Double(g.S)])
                })
        case .share: return DivFacts3Lesson.shareHands(s, sx: g.SX, y: Y0, rows: P.b, q: P.q, box: "k", c: c)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = Geo(s.numbers), P = g.P, c = g.c, st = stage(s, P), Y0 = g.Y0
        switch st {
        case .packs:
            let n = Double(Int((s.h("n") ?? 1).rounded())), x = g.X0 + Double(P.b) * c / 2
            return [.drag(from: CGPoint(x: x, y: Y0 + n * c), to: CGPoint(x: x, y: Y0 + Double(P.a) * c))]
        case .slide:
            guard let first = g.cells.first else { return [] }
            let off = Int((s.h("off") ?? Double(g.S)).rounded()), a = g.at(first.0 + off, first.1), b = g.at(first.0, first.1)
            return [.drag(from: CGPoint(x: a.x + c / 2, y: a.y + c / 2), to: CGPoint(x: b.x + c / 2, y: b.y + c / 2))]
        case .share:
            let k = Double(Int((s.h("k") ?? 0).rounded())), y = Y0 + Double(P.b) * c / 2
            return [.drag(from: CGPoint(x: g.SX + k * c, y: y), to: CGPoint(x: g.SX + Double(P.q) * c, y: y))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let g = Geo(s.numbers), P = g.P
        switch stage(s, P) {
        case .packs:
            let k = P.a + 1
            return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("p", Double(k))], check: true)
        case .slide:
            // one cell short of where it lands
            let cov = max(1, g.covered(1))
            return HandMove(hand: ["off": 1], missHand: ["off": Double(g.S)], set: [("s", Double(cov))], check: true)
        case .share:
            let n = min(10, P.q + 1)
            return HandMove(hand: ["k": Double(n)], missHand: ["k": 0], set: [("k", Double(n))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = TwoStep3.Parts(s.numbers)
        switch stage(s, P) {
        case .w1: return ["g": Double(P.kind == 2 ? P.a + P.cc : P.a + P.b)]
        case .w2: return ["h": Double(P.kind == 0 ? P.P + P.cc : P.kind == 1 ? P.P - P.cc : P.b)]
        default: return nil
        }
    }
}
