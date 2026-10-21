import SwiftUI

/// The fractions family's kit (design/grade5.md, "Fractions family"), built once and used by every fractions lesson on
/// the paper (Adding fractions and its family, Mixed numbers to fractions, Dividing by a unit fraction): bars a whole
/// long, the ruler that cuts them, and pieces slid from one bar into another. A lesson places its own bars and says what
/// they hold; the kit draws them and plays the hands, everything in the picture's squares (GridPen).
@MainActor
enum Bars {
    /// A bar is 4 squares tall, and bars sit 2 squares apart.
    nonisolated static let height = 4.0, gap = 2.0

    static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    /// A piece's number, as it's counted.
    static let count = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)
    /// The ruler's readout: the piece's name.
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    /// Green and red mean only right and wrong: an old cut a new cut lands on, or one none does.
    static let green = Sketch.Colour.hex(0x178A57, 0x3CCF8E), red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)
    /// Shaded pieces, in the chapter's colour.
    static let shade = Sketch.Colour.tint(0.4)

    /// A bar a whole long (`W` squares): its outline and its cuts in the chapter's colour. `h`: its height, when a
    /// lesson has more bars than 4-square ones fit (Dividing by a unit fraction's many wholes are 2 tall).
    static func bar(_ pen: inout GridPen, _ id: String, row: Double, parts: Int, W: Int, h: Double = height) {
        let per = Double(W) / Double(max(1, parts))
        pen.sketch.box("\(id)o", pen.R(0, row, Double(W), h), .chapter, width: Sketch.stroke)
        if parts > 1 {
            pen.sketch.segments("\(id)c\(parts)", (1..<parts).map { i in (pen.P(Double(i) * per, row), pen.P(Double(i) * per, row + h)) }, .chapter, width: Sketch.stroke)
        }
    }

    /// `n` pieces striped from piece `from` (the second amount), crossed out when they take away the shaded pieces
    /// under them.
    static func stripes(_ pen: inout GridPen, _ id: String, row: Double, from: Int, n: Int, per: Double, crossed: Bool) {
        guard n > 0 else { return }
        pen.stripes(id, col: Double(from) * per, row: row, w: Double(n) * per, h: height)
        // the pieces' own cuts over the stripes
        for i in 1..<max(1, n) { pen.line("\(id)c\(i)", [(Double(from + i) * per, row), (Double(from + i) * per, row + height)], .chapter) }
        if crossed {
            for i in 0..<n {
                let x0 = Double(from + i) * per
                pen.line("\(id)x\(i)a", [(x0 + 0.5, row + 0.5), (x0 + per - 0.5, row + height - 0.5)], .ink2)
                pen.line("\(id)x\(i)b", [(x0 + per - 0.5, row + 0.5), (x0 + 0.5, row + height - 0.5)], .ink2)
            }
        }
    }

    /// Pieces counted: the numbers in `counted` (each one less than it's written, 0 for "1"), the first in piece
    /// `from` of a bar `per` squares a piece, each centred in its piece.
    static func numbers(_ pen: inout GridPen, _ id: String, _ counted: Range<Int>, row: Double, from: Int = 0, per: Double, h: Double = height) {
        for i in counted { pen.word("\(id)\(i)", "\(i + 1)", at: (Double(from + i - counted.lowerBound) + 0.5) * per, row + h / 2, count) }
    }

    /// A bar's name: a fraction in a column 4 squares wide, its top centred down row r + 1, its bar on r + 2, its bottom
    /// down r + 3, where r is the bar's top row (nil leaves a part empty, for a box).
    static func fraction(_ pen: inout GridPen, _ id: String, _ top: Int?, _ bottom: Int?, col: Double, row r: Double, _ colour: Sketch.Colour = .ink) {
        if let top { pen.word(id + "t", "\(top)", at: col + 2, r + 1, maths.colour(colour)) }
        pen.rule(id + "bar", from: col, to: col + 4, row: r + 2, colour)
        if let bottom { pen.word(id + "b", "\(bottom)", at: col + 2, r + 3, maths.colour(colour)) }
    }

    /// A whole number as a bar's name (a whole bar is named 1): in the same column, level with a fraction's bar (the
    /// bar's middle, `h` its height).
    static func whole(_ pen: inout GridPen, _ id: String, _ n: Int, col: Double, row r: Double, h: Double = height, _ colour: Sketch.Colour = .ink) {
        pen.word(id + "w", "\(n)", at: col + 2, r + h / 2, maths.colour(colour))
    }

    /// A brace down the right of a column of names, from row `top` to row `bottom` (they're one number): its ends on
    /// column `col`, its stem a square right on the next grid line, its point two squares right, halfway down.
    static func brace(_ pen: inout GridPen, _ id: String, col x: Double, from top: Double, to bottom: Double, _ colour: Sketch.Colour = .ink) {
        let r = 1.0, mid = (top + bottom) / 2
        func arc(_ cx: Double, _ cy: Double, _ a0: Double, _ a1: Double) -> [(Double, Double)] {
            (0...8).map { i in let a = a0 + (a1 - a0) * Double(i) / 8; return (cx + r * cos(a), cy + r * sin(a)) }
        }
        let pts = arc(x, top + r, -.pi / 2, 0) + arc(x + 2 * r, mid - r, .pi, .pi / 2)
            + arc(x + 2 * r, mid + r, -.pi / 2, -.pi) + arc(x, bottom - r, 0, .pi / 2)
        pen.line(id, pts, colour)
    }
}

/// The ruler (design/grade5.md, shared by the fractions family): its handle, above the first bar, sets one piece's
/// length, snapping only to lengths that divide the whole. While it's dragged the piece is named over it, the cuts it
/// would make show dashed across the bars, and under each old cut a dot is green when a new cut lands on it, red when
/// none does (all live, following the hand). Cut fills the step's box with how many pieces of that length make a whole,
/// and checks it, so the lesson's Core check says what a miss means.
@MainActor
struct Ruler {
    /// The whole, in squares.
    let W: Int
    /// The ruler's row (its handle on it), and the rows its dashed cuts run between (a square past the bars it cuts).
    var row = 2.0
    var from: Double, to: Double
    /// One bar's old cuts: where they are and the row of their dots (a square under the bar). `tag` names the dots
    /// ("d1_…") and the rings a hint draws round them ("r1_…").
    struct Old { let tag: Int; let row: Double; let at: [Double] }
    var old: [Old]
    /// Its length before the hand moves it.
    var start: Int
    /// The step's box Cut fills.
    var box = "x"
    /// The lengths it snaps to, when a lesson's pieces aren't every length that divides the whole (Fraction of a number's
    /// groups are whole numbers of things, 2 squares a thing when there are few).
    var snaps: [Int]? = nil
    /// Its readout for a length, when it says more than the piece's name ("fourths, 5 in each").
    var readout: ((Int) -> String)? = nil
    /// Down the left of what it cuts instead of along the top (Multiplying fractions' rows): `row` is then its column,
    /// `from` and `to` the columns its cuts run between, and its readout sits left of it.
    var vertical = false
    /// Where its length starts along the way it measures (the left end of what it cuts, or its top when vertical).
    var at = 0.0

    /// A place `a` squares along the ruler's way and `b` across it, in the picture's squares.
    private func pt(_ a: Double, _ b: Double) -> (Double, Double) { vertical ? (b, at + a) : (at + a, b) }
    private func cg(_ a: Double, _ b: Double) -> CGPoint { let p = pt(a, b); return CGPoint(x: p.0, y: p.1) }

    /// The lengths it snaps to: every whole number of squares that divides the whole, 2 at least (so a piece holds its
    /// number), up to half the whole.
    nonisolated static func lengths(_ W: Int) -> [Int] { (2...max(2, W / 2)).filter { W % $0 == 0 } }
    var lengths: [Int] { snaps ?? Self.lengths(W) }

    /// Its length now: where the hand left it, or where it starts.
    func length(_ s: PaperState) -> Int { s.h("ruler").map { Int($0.rounded()) } ?? start }

    /// The ruler with its handle and readout, the cuts it would make, and the old cuts' dots, live; a hint (`oldCuts`)
    /// rings every old cut's dot on the still picture (each needs a new cut on it).
    func draw(_ s: PaperState, live: inout GridPen, still pic: inout GridPen) {
        let w = Double(length(s)), R = row, small = Bars.small
        live.line("ruler", [pt(0, R + 1), pt(0, R), pt(w, R), pt(w, R + 1)], .chapter)
        let hp = pt(w, R)
        live.dot("handle", at: hp.0, hp.1, radius: s.grabbed ? 0.75 : 0.6, .chapter, over: true)
        // the piece's name over the ruler, centred on it, but never past the bars' left end (a short ruler's long name,
        // "twenty-fourths", starts where the bars do)
        let name = readout?(Int(w)) ?? UnlikeFractions.pieceName(W / Int(w))
        let half = PaperText.width(name, PaperText.font(small.size, small.weight, digits: true)) / 2 / Paper.cell
        // (its ink half a square over the handle, which a short ruler's name would otherwise touch); a ruler down the
        // side has it on its left, level with its middle
        if vertical { live.label("rulerw", name, small, .left, edge: R - 0.75, along: at + w / 2) }
        else { live.label("rulerw", name, small, .above, edge: R - 0.75, along: at + max(w / 2, half)) }
        // the cuts it would make, dashed across the bars
        for k in 1..<max(1, Int((Double(W) / w).rounded())) {
            let x = Double(k) * w
            live.line("cut\(k)", [pt(x, from), pt(x, to)], .ink2, dashed: true)
        }
        // a dot under each old cut: green when a new cut lands on it, red when none does
        for o in old {
            for (i, x) in o.at.enumerated() { let p = pt(x, o.row); live.dot("d\(o.tag)_\(i + 1)", at: p.0, p.1, radius: 0.35, x.truncatingRemainder(dividingBy: w) == 0 ? Bars.green : Bars.red, over: true) }
        }
        if s.on("oldCuts") {
            for o in old { for (i, x) in o.at.enumerated() { let p = pt(x, o.row); pic.circle("r\(o.tag)_\(i + 1)", at: p.0, p.1, radius: 0.9, .chapter, dashed: true) } }
        }
    }

    /// The handle (or the ruler's end) is grabbed a finger's width around it and dragged, snapping to the lengths; let go,
    /// it stays where it is. Cut: how many pieces of that length make a whole, checked.
    func hands(_ s: PaperState) -> Hands {
        let w = Double(length(s)), lengths = self.lengths, R = row, W = Double(self.W), start = self.start, box = self.box
        // the finger's place along the ruler's way and across it
        let vertical = self.vertical, at = self.at
        func along(_ p: CGPoint) -> Double { (vertical ? p.y : p.x) - at }
        func across(_ p: CGPoint) -> Double { vertical ? p.x : p.y }
        return Hands(
            grab: { p in abs(along(p) - w) < 2.5 && across(p) > R - 2.5 && across(p) < R + 3 ? ["grab": 1, "ruler": w] : nil },
            drag: { p, _ in
                let x = along(p)
                let best = lengths.min { abs(Double($0) - x) < abs(Double($1) - x) } ?? start
                return ["grab": 1, "ruler": Double(best)]
            },
            release: { h in HandMove(hand: ["ruler": h["ruler"] ?? w], missHand: nil) },
            actions: ["Cut": { HandMove(hand: nil, missHand: nil, set: [(box, W / w)], check: true) }])
    }

    /// Show me and the How to: the handle dragged to `target` (unless it's there already), then Cut.
    func demo(_ s: PaperState, to target: Int) -> [GhostMove] {
        let w = Double(length(s)), R = row
        return (w == Double(target) ? [] : [.drag(from: cg(w, R), to: cg(Double(target), R))]) + [.tap(.action("Cut"))]
    }

    /// Screenshots only (-wrong): Cut at the first length that leaves an old cut with no new cut on it (else `fallback`).
    func wrongMove(else fallback: Int) -> HandMove {
        let w = lengths.first { l in old.contains { $0.at.contains { x in x.truncatingRemainder(dividingBy: Double(l)) != 0 } } } ?? fallback
        return HandMove(hand: ["ruler": Double(w)], missHand: nil, set: [(box, Double(W / w))], check: true)
    }
}

/// Pieces slid from one bar into another (design/grade5.md): the group is grabbed on its bar, follows the finger a square
/// at a time, and over the target bar it snaps in. Let go there, the move is made (its box 1); anywhere else they go back
/// (0), which the lesson's Core check says as a notice.
@MainActor
struct PieceSlide {
    /// The group, from its bar's left end, `width` squares long; its bar's row, and the target bar's.
    let width: Double, row: Double, target: Double
    /// The whole: over the target bar means some of it over the bar's length.
    let W: Double
    var box = "s"

    func hands() -> Hands {
        let gw = width, row = self.row, target = self.target, W = self.W, box = self.box
        return Hands(
            grab: { p in p.x > -0.5 && p.x < gw + 0.5 && p.y > row - 0.5 && p.y < row + Bars.height + 0.5 ? ["grab": 1, "fx": p.x, "fy": p.y, "dx": 0, "dy": 0] : nil },
            drag: { p, h in
                let fx = h["fx"] ?? 0, fy = h["fy"] ?? 0
                let dx = (p.x - fx).rounded(), dy = (p.y - fy).rounded()
                // over the target bar: it snaps in
                let top = row + dy, into = abs(top - target) <= 3 && dx + gw > 0 && dx < W
                return ["grab": 1, "fx": fx, "fy": fy, "dx": dx, "dy": dy, "in": into ? 1 : 0]
            },
            release: { h in
                h["in"] == 1 ? HandMove(hand: ["in": 1], missHand: [:], set: [(box, 1)], check: true)
                             : HandMove(hand: [:], missHand: [:], set: [(box, 0)], check: true)
            })
    }

    /// The group in the hand, following the finger (striped, its pieces' cuts, outlined), `per` squares a piece.
    func drawHeld(_ s: PaperState, _ live: inout GridPen, per: Double, pieces: Int) {
        let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0, h = Bars.height
        live.stripes("group", col: dx, row: row + dy, w: width, h: h)
        for i in 1..<max(1, pieces) { live.line("gc\(i)", [(dx + Double(i) * per, row + dy), (dx + Double(i) * per, row + dy + h)], .chapter) }
        live.sketch.box("go", live.R(dx, row + dy, width, h), .chapter, width: Sketch.stroke)
    }

    /// Show me and the How to: the group dragged from its middle to `x` on the target bar.
    func demo(to x: Double) -> [GhostMove] {
        [.drag(from: CGPoint(x: width / 2, y: row + Bars.height / 2), to: CGPoint(x: x, y: target + Bars.height / 2))]
    }

    /// Screenshots only (-wrong): dropped off the target bar.
    var wrongMove: HandMove { HandMove(hand: [:], missHand: [:], set: [(box, 0)], check: true) }
}
