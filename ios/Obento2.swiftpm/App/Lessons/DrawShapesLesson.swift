import SwiftUI

/// Draw shapes on the paper, as in the preview (design/prototype/gradeK-ch2.html, lDraw): the drawing place is 10 × 6
/// blocks of the paper's own grid, a faint frame round it, its block crossings dotted faintly. Tap a crossing for each
/// corner (a dot, the clay ball); from the second on a side draws from the last one (the stick); tap the first again to
/// close it (it's ringed once there are three). Tap the last corner again to take it back; drag a corner to move it;
/// Start over (beside the place) clears it. The paper refuses a side that would cross another or three corners in a line. Closed, it's
/// checked; the drawing stays to fix (a square that isn't has its sides' blocks numbered, or its longer sides marked).
/// A circle: drag out from the centre dot; its size snaps to whole blocks (1–3 out). Then its sides are numbered, its
/// corners counted; a square's stick fits every side.
///
/// Kept: the drawing (DrawShape.keep: `n`, `x<i>`, `y<i>`, `closed`), a circle's `r`. Hand: `grab`, `g` (the corner held,
/// −1 the circle), `cx`, `cy` (where it is now), `r`.
@MainActor
struct DrawShapesLesson: PaperLesson {
    typealias C = (Int, Int)
    var liveKeys: Set<String> { ["cx", "cy", "r", "grab", "g"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let across = 10, down = 6, over = CGRect(x: 55, y: 0, width: 15, height: 4)
    static let centre = CGPoint(x: 25, y: 15)
    private func corners(_ s: PaperState) -> [C] { DrawShape.corners(s.run.kept) }
    private func closed(_ s: PaperState) -> Bool { (s.run.kept["closed"] ?? 0) != 0 }
    private func sq(_ c: C) -> KS.Pt { (Double(c.0) * 5, Double(c.1) * 5) }
    /// A shape to show (Show me, a second miss's dashed outline).
    static func example(_ kind: String) -> [C] {
        switch kind {
        case "square": [(3, 1), (7, 1), (7, 5), (3, 5)]
        case "rectangle": [(2, 1), (8, 1), (8, 4), (2, 4)]
        case "hexagon": [(3, 1), (6, 1), (8, 3), (6, 5), (3, 5), (1, 3)]
        default: [(3, 5), (7, 5), (5, 1)]
        }
    }
    /// The crossing a finger is on (within half a block's reach), or nil.
    private func snap(_ q: CGPoint) -> C? {
        let c = (Int((q.x / 5).rounded()), Int((q.y / 5).rounded()))
        guard c.0 >= 0, c.0 <= Self.across, c.1 >= 0, c.1 <= Self.down, hypot(q.x - Double(c.0) * 5, q.y - Double(c.1) * 5) <= 2.6 else { return nil }
        return c
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = DrawShape.Parts(s.numbers), st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        // the drawing place: a faint frame, its block crossings dotted faintly
        pic.sketch.box("place", pic.R(0, 0, 50, 30), .ink3, width: Sketch.stroke)
        for x in 0...Self.across { for y in 0...Self.down { pic.dot("x\(x)_\(y)", at: Double(x) * 5, Double(y) * 5, radius: 0.3, .ink3) } }
        let recY = 0.0
        if P.circle {
            let c = Self.centre, held = s.grabbed && st == 0
            let r = held ? Int(s.h("r") ?? 0) : Int(s.run.kept["r"] ?? 0)
            pic.dot("cc", at: c.x, c.y, radius: 0.6, .chapter, over: true)
            if r > 0 {
                let pts = KS.circlePts((c.x, c.y), Double(r) * 5)
                if held {
                    KS.poly(&live, "cr", pts, KS.fill); KS.outline(&live, "cro", pts, .chapter)
                    live.line("crl", [(c.x, c.y), (c.x + Double(r) * 5, c.y)], .chapter, dashed: true)
                    live.reads(CountK.plural(r, "block", "blocks") + " out")
                } else { KS.poly(&pic, "cr\(r)", pts, KS.fill); KS.outline(&pic, "cro\(r)", pts, .chapter) }
            }
            if st == 0 && s.on("ring") { pic.circle("hr", at: c.x, c.y, radius: 2.6, .chapter, dashed: true) }
            if st == 0 && s.on("spot") { KS.outline(&pic, "spot", KS.circlePts((c.x, c.y), 10), .chapter, dashed: true) }
            if st == 1 {
                pic.sketch.startAt = PaperClock.now + 0.4
                KS.line(&pic, "rec", [.n(0, .chapter), .w("sides")], x: 55, line: recY + 1)
                KS.line(&pic, "rec2", [.n(0, .chapter), .w("corners")], x: 55, line: recY + 4)
                pic.sketch.startAt = nil
            }
            return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(-1, 0, 52, 31))
        }
        var Cs = corners(s)
        // the finished drawing (the layout measures the last step before anything's drawn: a shape that would do)
        if st == 1 && Cs.count < 3 { Cs = Self.example(P.kind) }
        let isClosed = closed(s) || st == 1
        // a corner being dragged: where it is now
        let g = s.grabbed && st == 0 ? Int(s.h("g") ?? -1) : -1
        if g >= 0, Cs.indices.contains(g), let x = s.h("cx"), let y = s.h("cy") { Cs[g] = (Int(x), Int(y)) }
        let n = Cs.count, pts = Cs.map(sq), pen = g >= 0 ? 1 : 0
        func draw(_ into: inout GridPen) {
            if isClosed && n >= 3 { KS.poly(&into, "fill\(Cs.map { "\($0.0)\($0.1)" }.joined())", pts, KS.fill) }
            let sides = isClosed ? n : n - 1
            for i in 0..<max(0, sides) {
                let a = pts[i], b = pts[(i + 1) % n]
                into.line("s\(Cs[i].0),\(Cs[i].1)-\(Cs[(i + 1) % n].0),\(Cs[(i + 1) % n].1)", [a, b], .ink)
            }
            for (i, p) in pts.enumerated() { into.dot("c\(Cs[i].0),\(Cs[i].1)", at: p.0, p.1, radius: 0.75, .chapter, over: true) }
            if !isClosed && n >= 3 { into.circle("first", at: pts[0].0, pts[0].1, radius: 1.5, .chapter) }
        }
        if pen == 1 { draw(&live) } else { draw(&pic) }
        // checked and not right: what the paper shows of it
        if st == 0, isClosed, g < 0, let m = DrawShape.check(P.kind, Cs) {
            for i in 0..<n {
                let a = pts[i], b = pts[(i + 1) % n]
                if m.longer?[i] == true { KS.poly(&pic, "lg\(i)", KS.edge(pts, i), .hex(0xE9B7B2, 0x6B2E2A)) }
                if m.blocks {
                    let o = KS.sideOut(pts, i), k = Int((hypot(b.0 - a.0, b.1 - a.1) / 5).rounded())
                    for j in 0..<k {
                        let u = (Double(j) + 0.5) / Double(k)
                        pic.word("bn\(i)_\(j)", "\(j + 1)", at: a.0 + (b.0 - a.0) * u + o.0 * 1.5, a.1 + (b.1 - a.1) * u + o.1 * 1.5, Sketch.Words.note)
                    }
                }
            }
        }
        if st == 0 {
            if n > 0 { KS.blocks(&pic, "over", ["Start over"], [Self.over]) }
            // a hint: where to close it (or the place to draw in); a second miss, a shape that would do, dashed
            if s.on("ring") {
                if n >= 3 && !isClosed { KK.hint(&pic, "hr", pts[0].0, pts[0].1, radius: 2.6) } else if n < 3 { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 50, h: 30) }
            }
            if s.on("spot") { KS.outline(&pic, "spot", Self.example(P.kind).map(sq), .chapter, dashed: true) }
        } else {
            // the See: its sides numbered, its corners counted; a square's stick fits every side
            for i in 0..<n {
                let m = KS.sideLabel(pts, i, out: 2.4), c = KS.cornerLabel(pts, i)
                pic.word("sn\(i)", "\(i + 1)", at: m.0, m.1, KK.count.colour(.chapter))
                pic.word("cn\(i)", "\(i + 1)", at: c.0, c.1, Sketch.Words.note)
            }
            var wait = 0.4
            if P.kind == "square" { wait = KS.stick(&pic, "stk", pts, start: PaperClock.now + 0.3) + 0.5 }
            pic.sketch.startAt = PaperClock.now + wait
            // the record beside the place, a line each (there's room across, not down)
            KS.line(&pic, "rec", [.n(n, .chapter), .w("sides")], x: 55, line: recY + 1)
            KS.line(&pic, "rec2", [.n(n, .chapter), .w("corners")], x: 55, line: recY + 4)
            pic.sketch.startAt = nil
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(-1, -1, 52, 32))
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let P = DrawShape.Parts(s.numbers)
        if P.circle {
            let c = Self.centre
            func r(_ q: CGPoint) -> Int { let d = hypot(q.x - c.x, q.y - c.y); return d < 2.5 ? 0 : max(1, min(3, Int((d / 5).rounded()))) }
            return Hands(grab: { q in hypot(q.x - c.x, q.y - c.y) <= 4 ? ["grab": 1, "g": -1, "r": 0] : nil },
                         drag: { q, h in var h = h; h["r"] = Double(r(q)); return h },
                         release: { h in
                             let r = Int(h["r"] ?? 0)
                             return r > 0 ? HandMove(hand: [:], missHand: [:], set: [("d", Double(r))], keep: ["r": Double(r)], check: true) : HandMove(hand: [:])
                         })
        }
        let Cs = corners(s), isClosed = closed(s), n = Cs.count
        /// A tap on a crossing: a new corner, the first again to close, the last again to take it back.
        func place(_ c: C) -> HandMove? {
            if isClosed { return nil }
            if let l = Cs.last, l == c { return HandMove(hand: nil, missHand: nil, keep: DrawShape.keep(Array(Cs.dropLast()), closed: false)) }
            if n >= 3, Cs[0] == c {
                if let why = DrawShape.refuse(Cs, closed: true) { return HandMove(hand: nil, missHand: nil, set: [("d", DrawShape.code(why))], check: true) }
                return HandMove(hand: nil, missHand: nil, set: [("d", 1)], keep: DrawShape.keep(Cs, closed: true), check: true)
            }
            if let why = DrawShape.refuse(Cs + [c], closed: false) { return HandMove(hand: nil, missHand: nil, set: [("d", DrawShape.code(why))], check: true) }
            return HandMove(hand: nil, missHand: nil, keep: DrawShape.keep(Cs + [c], closed: false))
        }
        return Hands(
            tap: { q in
                if n > 0, Self.over.contains(q) { return HandMove(hand: [:], keep: DrawShape.keep([], closed: false)) }
                return snap(q).flatMap(place)
            },
            grab: { q in
                guard let i = Cs.firstIndex(where: { hypot(q.x - Double($0.0) * 5, q.y - Double($0.1) * 5) < 2.6 }) else { return nil }
                return ["grab": 1, "g": Double(i), "cx": Double(Cs[i].0), "cy": Double(Cs[i].1)]
            },
            drag: { q, h in
                var h = h
                if let c = snap(q) { h["cx"] = Double(c.0); h["cy"] = Double(c.1) }
                return h
            },
            release: { h in
                let i = Int(h["g"] ?? -1), c = (Int(h["cx"] ?? 0), Int(h["cy"] ?? 0))
                guard Cs.indices.contains(i) else { return HandMove(hand: [:]) }
                if c == Cs[i] { return place(c).map { var m = $0; m.hand = [:]; return m } ?? HandMove(hand: [:]) }
                var moved = Cs; moved[i] = c
                if let why = DrawShape.refuse(moved, closed: isClosed) { return HandMove(hand: [:], missHand: [:], set: [("d", DrawShape.code(why))], check: true) }
                return HandMove(hand: [:], missHand: [:], set: isClosed ? [("d", 1)] : [], keep: DrawShape.keep(moved, closed: isClosed), check: isClosed)
            })
    }

    /// Done: Next problem beside the record.
    func blocksAt(_ s: PaperState) -> CGPoint? { at(s) == 1 ? CGPoint(x: 55, y: 7) : nil }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0 else { return [] }
        let P = DrawShape.Parts(s.numbers)
        if P.circle { return [.drag(from: Self.centre, to: CGPoint(x: Self.centre.x + 10, y: Self.centre.y))] }
        var moves: [GhostMove] = []
        // a drawing already there is started over first
        if !corners(s).isEmpty { moves.append(.tap(.picture(CGPoint(x: Self.over.midX, y: Self.over.midY)))) }
        let ex = Self.example(P.kind)
        for c in ex + [ex[0]] { moves.append(.tap(.picture(CGPoint(x: Double(c.0) * 5, y: Double(c.1) * 5)))) }
        return moves
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = DrawShape.Parts(s.numbers)
        guard at(s) == 0, !P.circle else { return nil }
        let bad: [C]
        switch P.kind {
        case "triangle": bad = [(2, 1), (6, 1), (6, 4), (2, 4)]
        case "square": bad = [(2, 1), (5, 1), (5, 3), (2, 3)]
        case "rectangle": bad = [(2, 1), (5, 1), (5, 4), (2, 4)]
        default: bad = [(2, 1), (6, 1), (8, 3), (6, 5), (2, 5)]
        }
        return HandMove(hand: nil, missHand: nil, set: [("d", 1)], keep: DrawShape.keep(bad, closed: true), check: true)
    }
}
