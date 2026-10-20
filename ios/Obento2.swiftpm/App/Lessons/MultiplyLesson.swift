import SwiftUI

/// Multiply two-digit numbers on the paper (design/grade5.md: approved 19 Oct, now with a hand move). The rectangle a
/// squares tall and b wide, one square for each one (a seat, in the story), every ten bold, named by its sides: a down
/// its left, b over its top (the problem, written once). The cut: a handle over its top edge, dragged along it (or
/// tapped to a place), snapping to the squares; a dashed cut runs down the rectangle under it and the two widths are
/// written over the two parts as it moves ("30 | 6"). Cut cuts where the tens end: the cut turns solid and the ones strip
/// parts a square, gliding off. Then each strip lights in turn and its squares are written in the record, the column
/// working as school writes it (beside the picture when that shows it bigger), and on the strip itself; then the total,
/// in the chapter's colour; the last words say why the two strips make it.
@MainActor
struct MultiplyLesson: PaperLesson {
    var liveKeys: Set<String> { ["cut", "grab"] }

    private static let name = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    private static let readout = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    /// A strip's squares written on it once found: the picture's word size, firm, in the chapter's colour.
    private static let product = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .chapter)
    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    private static let sign = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    /// The squares: every one fine, every ten bold (the rectangle's own grid, drawn over the paper's), and the fill, light
    /// or lit (the strip being written).
    private static let minor = Sketch.Colour.tint(0.45), ten = Sketch.Colour.tint(0.85)
    private static func fill(_ lit: Bool) -> Sketch.Colour { .tint(lit ? 0.3 : 0.1) }

    /// A problem's numbers and where its parts go, in its squares.
    @MainActor struct Q {
        let a, b: Int
        /// Where the tens end (the cut) and the ones after them. One part only (none is generated): no cut.
        let T, O: Int
        /// Words, blocks and the record drawn twice as big when the rectangle is (the camera steps far back for it).
        let k: Double
        init(_ n: Numbers) {
            a = max(1, Int((n["a"] ?? 12).rounded())); b = max(1, Int((n["b"] ?? 12).rounded()))
            T = b - b % 10; O = b % 10
            k = Self.k(a: a, b: b)
        }
        /// Twice as big (G 19 Oct: whole steps only) when at the paper's own size the words would show smaller than 22
        /// points on this screen (Rounding's and the fractions' read at about 30): the camera steps that far back to see
        /// the whole rectangle, with the words over it, the cut's rows and the record beside it (or under it, for a wide one).
        /// Worked out once for a problem's numbers, so its drawing always agrees with its plan.
        static func k(a: Int, b: Int) -> Double {
            if let k = scales["\(a)×\(b)"] { return k }
            let beside = ProblemGrid.zoom(squares: Double(b + 20), Double(a + 11))
            let under = ProblemGrid.zoom(squares: Double(max(b + 5, 30)), Double(a + 28))
            let k: Double = max(beside, under) * Sketch.wordSize < 22 ? 2 : 1
            scales["\(a)×\(b)"] = k
            return k
        }
        private static var scales: [String: Double] = [:]
        var cuts: Bool { T > 0 && O > 0 }
        /// The rectangle's top row, and the row the cut's handle runs along over it (the widths written between them).
        var top: Double { 3 * k }
        var handle: Double { top - 2 * k }
        /// Where the ones strip sits once the cut has parted it: a square past where the tens end.
        var onesX: Double { Double(T + 1) }
        var tensProduct: Int { a * T }
        var onesProduct: Int { a * O }
        var product: Int { a * b }
        /// Digits in the record's widest number (the product), and the column's cells: those and the sign's, one more
        /// when the ones strip's squares are as long as the total (25 × 17: + 175), so the + never touches them.
        var digits: Int { String(product).count }
        var columns: Int { max(digits, String(onesProduct).count + 1) + 1 }
    }

    /// The stage (MultiplyTwoDigit's "at"): 0 the question, 1 the cut, 2 the tens strip, 3 the ones strip, 4 the total,
    /// 5 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func scale(_ n: Numbers) -> Double { Q(n).k }
    /// The record's first row is level with the rectangle's top.
    func recordBeside(_ n: Numbers) -> Double? { Q(n).top }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), at = stage(s), k = q.k
        let a = Double(q.a), b = Double(q.b), T = Double(q.T), O = Double(q.O), top = q.top
        var pic = GridPen(k: k), live = GridPen(k: k, stableIds: true), rec = GridPen(k: k)
        let parted = q.cuts && at >= 2

        // MARK: the rectangle: two parts that join where the tens end (a bold line, as every ten is) until the cut
        // parts them; the strip being written lit, both for the total
        if q.cuts {
            part(&pic, "L", x: 0, c0: 0, c1: q.T, rows: q.a, top: top, lit: at == 2 || at >= 4, left: true, right: parted)
            part(&pic, "R", x: parted ? q.onesX : T, c0: q.T, c1: q.b, rows: q.a, top: top, lit: at >= 3, left: parted, right: true)
            if !parted { pic.line("seam", [(T, top), (T, top + a)], Self.ten) }
        } else {
            part(&pic, "L", x: 0, c0: 0, c1: q.b, rows: q.a, top: top, lit: at >= 2, left: true, right: true)
        }
        // its names: its height down its left side, its width over its top (over each strip once it's cut; while the cut
        // is being placed, the widths are the hand's readout)
        pic.label("side", "\(q.a)", Self.name, .left, edge: 0, along: top + a / 2)
        if at == 0 || (at >= 2 && !parted) { pic.label("width", "\(q.b)", Self.name, .above, edge: top, along: b / 2) }
        if parted {
            pic.label("wT", "\(q.T)", Self.name, .above, edge: top, along: T / 2)
            pic.label("wO", "\(q.O)", Self.name, .above, edge: top, along: q.onesX + O / 2)
        }

        // MARK: each strip's squares, written on it once found (under it when it's too narrow to hold them)
        let onesW = PaperText.width("\(q.onesProduct)", PaperText.font(Self.product.size * k, Self.product.weight, digits: true)) / Paper.cell
        let onesUnder = q.cuts && onesW + 0.5 > O
        func onStrip(_ id: String, _ text: String, x: Double, w: Double, _ words: Sketch.Words) {
            let tw = PaperText.width(text, PaperText.font(words.size * k, words.weight, digits: true)) / Paper.cell
            if tw + 0.5 <= w { pic.word(id, text, at: x + w / 2, top + a / 2, words) }
            else { pic.label(id, text, words, .below, edge: top + a, along: x + w / 2) }
        }
        if q.cuts {
            if at >= 3 { onStrip("pT", "\(q.tensProduct)", x: 0, w: T, Self.product) }
            if at >= 4 { onStrip("pO", "\(q.onesProduct)", x: q.onesX, w: O, Self.product) }
        } else if at >= 5 {
            onStrip("pT", "\(q.product)", x: 0, w: b, Self.product)
        }

        // MARK: hints: every ten across the top counted (the cut); the strip's multiplication written on it; both strips
        // together under a bracket (the total)
        if at == 1, s.on("tens") {
            for j in 0..<(q.T / 10) { pic.word("ten\(j)", "10", at: Double(10 * j) + 5, top + 1.5 * k, Self.small) }
        }
        if at == 2 || at == 3, s.on("look") {
            let tens = at == 2 || !q.cuts
            onStrip("look", "\(q.a) × \(tens ? (q.cuts ? q.T : q.b) : q.O)", x: tens ? 0 : q.onesX, w: tens ? (q.cuts ? T : b) : O, Self.readout)
        }
        if at == 4, s.on("look") {
            let row = top + a + (onesUnder ? 3 * k : 1)
            pic.line("sumB", [(0, row - 1), (0, row), (b + 1, row), (b + 1, row - 1)], .chapter)
            pic.label("sumBw", "\(q.tensProduct) + \(q.onesProduct)", Self.small, .below, edge: row, along: (b + 1) / 2)
        }

        // MARK: the cut, live as the hand moves it: the handle on its stem over the top edge, the cut dashed down the
        // rectangle, and the two widths it makes written over them; at either end, no cut, the whole width
        var actions: [String] = []
        if at == 1, q.cuts {
            actions = ["Cut"]
            let c = s.h("cut") ?? b, inside = c > 0 && c < b
            live.line("stem", [(c, q.handle), (c, top)], .chapter)
            live.dot("handle", at: c, q.handle, radius: (s.grabbed ? 0.75 : 0.6) * k, .chapter, over: true)
            if inside {
                live.line("cut", [(c, top), (c, top + a + 1)], .ink, dashed: true)
                live.label("wL", "\(Int(c))", Self.readout, .above, edge: top, along: c / 2)
                live.label("wR", "\(q.b - Int(c))", Self.readout, .above, edge: top, along: (c + b) / 2)
            } else {
                live.label("wL", "\(q.b)", Self.name, .above, edge: top, along: b / 2)
            }
        }

        // MARK: the record: the column working as school writes it, two squares to a digit (four, drawn big), each row
        // typed where it goes: a × b, each strip's squares, the total in the chapter's colour
        var boxes: [WorkBox] = []
        if at >= 2 {
            let per = 2 * k, R = Double(q.columns) * per, cells = q.digits
            func row(_ r: Double) -> Double { (r + 0.5) * per }
            rec.digits("ra", "\(q.a)", right: R, row: row(0), per: per)
            rec.word("rx", "×", at: per / 2, row(1), Self.sign)
            rec.digits("rb", "\(q.b)", right: R, row: row(1), per: per)
            rec.rule("rule1", from: 0, to: R, row: 2 * per)
            if q.cuts {
                if at == 2 { rec.answerBox("x", right: R, mid: row(2), per: per, cells: cells) }
                else { rec.digits("rT", "\(q.tensProduct)", right: R, row: row(2), per: per) }
                if at >= 3 {
                    rec.word("plus", "+", at: per / 2, row(3), Self.sign)
                    if at == 3 { rec.answerBox("x", right: R, mid: row(3), per: per, cells: cells) }
                    else { rec.digits("rO", "\(q.onesProduct)", right: R, row: row(3), per: per) }
                }
                if at >= 4 {
                    rec.rule("rule2", from: 0, to: R, row: 4 * per)
                    if at == 4 { rec.answerBox("x", right: R, mid: row(4), per: per, cells: cells) }
                    else { rec.digits("total", "\(q.product)", right: R, row: row(4), per: per, .chapter) }
                }
            } else {
                if at < 5 { rec.answerBox("x", right: R, mid: row(2), per: per, cells: cells) }
                else { rec.digits("total", "\(q.product)", right: R, row: row(2), per: per, .chapter) }
            }
            boxes = rec.boxes
        }
        // the room the cut and the parted strips need: the handle over the top, the dashed cut past the bottom
        let extent = pic.R(0, 0, b + 2, top + a + 1)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions, extent: extent)
    }

    /// Columns c0..<c1 of the rectangle, drawn from column x: its edges, every square, every ten of the rectangle bold,
    /// and its fill. Where it joins the other part its edge is left off (the bold line between them is drawn on its own)
    /// until the cut parts them. Its pieces keep their ids wherever it's drawn, so when the cut parts it the ones strip
    /// glides off, and lighting it only changes its fill.
    private func part(_ pen: inout GridPen, _ id: String, x: Double, c0: Int, c1: Int, rows: Int, top: Double, lit: Bool, left: Bool, right: Bool) {
        let w = Double(c1 - c0), h = Double(rows)
        pen.line("\(id)top", [(x, top), (x + w, top)], .chapter)
        pen.line("\(id)bot", [(x, top + h), (x + w, top + h)], .chapter)
        if left { pen.line("\(id)l", [(x, top), (x, top + h)], .chapter) }
        if right { pen.line("\(id)r", [(x + w, top), (x + w, top + h)], .chapter) }
        var fine: [(CGPoint, CGPoint)] = [], bold: [(CGPoint, CGPoint)] = []
        for c in (c0 + 1)..<max(c0 + 1, c1) {
            let seg = (pen.P(x + Double(c - c0), top), pen.P(x + Double(c - c0), top + h))
            if c % 10 == 0 { bold.append(seg) } else { fine.append(seg) }
        }
        for r in 1..<max(1, rows) {
            let seg = (pen.P(x, top + Double(r)), pen.P(x + w, top + Double(r)))
            if r % 10 == 0 { bold.append(seg) } else { fine.append(seg) }
        }
        pen.sketch.segments("\(id)c", fine, Self.minor, width: 1)
        pen.sketch.segments("\(id)t", bold, Self.ten, width: Sketch.stroke)
        pen.fill("\(id)f\(lit)", col: x, row: top, w: w, h: h, Self.fill(lit))
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers), k = q.k
        guard stage(s) == 1, q.cuts else { return nil }
        let b = Double(q.b), c = s.h("cut") ?? b, a = Double(q.a)
        /// The column under the finger. Drawn big, the camera far back, a square is a few points on the screen: a bold
        /// line within a square of the finger takes the cut, so a ten is easy to land on.
        func column(_ x: Double) -> Double {
            let ten = (x / 10).rounded() * 10
            let at = k > 1 && abs(x - ten) <= 1 ? ten : x.rounded()
            return min(b, max(0, at))
        }
        return Hands(
            // a tap along the top (over the rectangle, where the handle runs) puts the cut there
            tap: { p in p.y > q.handle - 1.5 * k && p.y < q.top + 0.5 && p.x > -0.5 && p.x < b + 0.5 ? HandMove(hand: ["cut": column(p.x)], missHand: nil) : nil },
            // the handle, or the cut under it, a finger's width either side
            grab: { p in abs(p.x - c) < 2 * k && p.y > q.handle - 2 * k && p.y < q.top + a ? ["grab": 1, "cut": c] : nil },
            drag: { p, _ in ["grab": 1, "cut": column(p.x)] },
            release: { h in HandMove(hand: ["cut": h["cut"] ?? c], missHand: nil) },
            // Cut: where it is goes in the step's box (the tens part), checked
            actions: ["Cut": { HandMove(hand: nil, missHand: nil, set: [("x", c)], check: true) }])
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers)
        guard stage(s) == 1, q.cuts else { return [] }
        let c = s.h("cut") ?? Double(q.b), T = Double(q.T)
        return (c == T ? [] : [.drag(from: CGPoint(x: c, y: q.handle), to: CGPoint(x: T, y: q.handle))]) + [.tap(.action("Cut"))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers)
        guard stage(s) == 1, q.cuts else { return nil }
        // a ten short (a ten left in the ones), or a square past where the tens end
        let x = Double(q.T >= 20 ? q.T - 10 : q.T + 1)
        return HandMove(hand: ["cut": x], missHand: nil, set: [("x", x)], check: true)
    }

    /// What a miss says can run to two rows on a narrow problem: the slips the web names ("That's 47 × 3. The tens digit
    /// stands for 30, so add a zero."), against the narrowest the problem can be laid out.
    func messageRows(_ n: Numbers) -> Int {
        let q = Q(n), k = q.k
        let longest = "That's \(q.a) × \(max(1, q.T / 10)). The tens digit stands for \(q.T), so add a zero."
        let w = PaperText.width(longest, PaperText.font(Sketch.small * k, .medium)) / Paper.cell
        let narrowest = max(30, Double(q.b + 2), Double(q.columns) * 2 * k + 1)
        return w > narrowest ? 2 : 1
    }
}
