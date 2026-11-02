import SwiftUI

/// Sorting shapes on the paper, as in the preview G approved on 1 Nov 2026 (design/prototype/new5-lessons.html, dShapes;
/// design/grade5.md). A four-sided shape drawn by its corners on grid points, each side's length in squares beside it
/// where it's whole. 1. Tap two sides that are parallel: a pair found gets matching arrowheads (one on the first pair,
/// two on the second); a wrong pair goes red and is measured on the grid; No more when every pair is found. 2. Tap each
/// square corner: it gets the little square mark; a corner that isn't square gets a red dot. 3. The family picture
/// draws in beside it, boxes inside boxes; tap the smallest box it fits in (a wrong box goes red); then every box around
/// it lights in the chapter's colour, its own box tinted, and the last words name them all.
///
/// The picture's squares: the shape from column 2, centred down rows 3–25; the family picture from column 29, row 0 to
/// 37. Hand keys: "pick" (a side tapped, + 1), "p02" and "p13" (the order a pair was found in), "w1", "w2" (a wrong
/// pair's sides, + 1), "c0"…"c3" (square corners marked), "wc" (a corner that isn't square, + 1), "wb" (a wrong box,
/// + 1). What steps 1 and 2 found is kept for the steps after (LessonRun.kept).
@MainActor
struct ShapesLesson: PaperLesson {
    typealias Box = SortingShapes.Box

    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
    private static let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)
    private static let wrongFill = Sketch.Colour.hex(Ink.mix(0xF3F2EF, 0xC8372D, 0.15), Ink.mix(0x121211, 0xFF6B5E, 0.18))

    /// The family picture's boxes, in the picture's squares (the preview's, six rows up): where each is, and where its
    /// name sits (from its start, its end, or its middle).
    struct Family { let x: Double, y: Double, w: Double, h: Double, lx: Double, ly: Double, anchor: UnitPoint }
    static let family: [Box: Family] = [
        .quadrilaterals: Family(x: 29, y: 0, w: 38, h: 37, lx: 30, ly: 1.5, anchor: UnitPoint(x: 0, y: 0.5)),
        .trapezoids: Family(x: 31, y: 5, w: 34, h: 30, lx: 32, ly: 6.5, anchor: UnitPoint(x: 0, y: 0.5)),
        .parallelograms: Family(x: 33, y: 10, w: 30, h: 23, lx: 34, ly: 11.5, anchor: UnitPoint(x: 0, y: 0.5)),
        .rectangles: Family(x: 35, y: 15, w: 16, h: 16, lx: 35.5, ly: 16.5, anchor: UnitPoint(x: 0, y: 0.5)),
        .rhombuses: Family(x: 45, y: 15, w: 16, h: 16, lx: 60.5, ly: 16.5, anchor: UnitPoint(x: 1, y: 0.5)),
        .squares: Family(x: 45, y: 15, w: 6, h: 16, lx: 48, ly: 24, anchor: .center),
    ]
    /// The box a tap is in: the smallest first (Squares is where Rectangles and Rhombuses overlap).
    static func box(at q: CGPoint) -> Box? {
        Box.allCases.first { b in let f = family[b]!; return q.x >= f.x && q.x <= f.x + f.w && q.y >= f.y && q.y <= f.y + f.h }
    }
    /// A place inside each box and in no smaller one: where the ghost finger taps.
    static let inside: [Box: CGPoint] = [.squares: CGPoint(x: 48, y: 27), .rectangles: CGPoint(x: 40, y: 27), .rhombuses: CGPoint(x: 56, y: 27),
                                          .parallelograms: CGPoint(x: 48, y: 13), .trapezoids: CGPoint(x: 48, y: 8), .quadrilaterals: CGPoint(x: 48, y: 3)]

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The shape's corners in the picture's squares: from column 2, centred down rows 3 to 25.
    static func corners(_ p: SortingShapes.Parts) -> [CGPoint] {
        let oy = 3 + ((22 - Double(p.height)) / 2).rounded(.down)
        return p.corners.map { CGPoint(x: 2 + Double($0.x), y: oy + Double($0.y)) }
    }

    /// The pairs found, in the order they were found (step 1's hand, or what it kept; every pair once it's done).
    private func found(_ s: PaperState, _ p: SortingShapes.Parts) -> [[Int]] {
        let src = stage(s) == 1 ? s.hand : s.run.kept
        var pairs = p.pairs.filter { (src[$0 == [0, 2] ? "p02" : "p13"] ?? 0) > 0 }
        if stage(s) >= 2 { for q in p.pairs where !pairs.contains(q) { pairs.append(q) } }
        return pairs.sorted { (src[$0 == [0, 2] ? "p02" : "p13"] ?? 9) < (src[$1 == [0, 2] ? "p02" : "p13"] ?? 9) }
    }
    /// The square corners marked (step 2's hand; every one once it's done).
    private func marked(_ s: PaperState, _ p: SortingShapes.Parts) -> [Int] {
        if stage(s) >= 3 { return p.rights }
        guard stage(s) == 2 else { return [] }
        return (0..<4).filter { (s.hand["c\($0)"] ?? 0) > 0 }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let p = SortingShapes.Parts(s.numbers), V = Self.corners(p), at = stage(s)
        var pic = GridPen()
        let pick = s.h("pick").map { Int($0) - 1 }
        let pairs = found(s, p)
        let bad: [Int] = at == 1 ? [s.h("w1"), s.h("w2")].compactMap { $0.map { Int($0) - 1 } } : []
        let cx = V.map(\.x).reduce(0, +) / 4, cy = V.map(\.y).reduce(0, +) / 4

        // the sides: lit when tapped or found, red when a wrong pair; each whole length beside it, outside the shape
        for i in 0..<4 {
            let a = V[i], b = V[(i + 1) % 4]
            let lit = pick == i || pairs.contains { $0.contains(i) }, wrong = bad.contains(i)
            pic.line("side\(i)\(lit)\(wrong)", [(a.x, a.y), (b.x, b.y)], wrong ? Self.red : lit ? .chapter : .ink)
            if let l = p.wholeLength(i) {
                let dx = b.x - a.x, dy = b.y - a.y, len = hypot(dx, dy), n = CGPoint(x: dy / len, y: -dx / len)
                let mx = a.x + dx / 2, my = a.y + dy / 2
                let out: Double = pow(mx + n.x - cx, 2) + pow(my + n.y - cy, 2) > pow(mx - cx, 2) + pow(my - cy, 2) ? 1 : -1
                pic.word("len\(i)", "\(l)", at: mx + out * n.x * 1.6, my + out * n.y * 1.6, Self.small)
            }
        }
        // parallel marks: one arrowhead on each side of the first pair found, two on the second
        for (k, pr) in pairs.enumerated() {
            for i in pr {
                let a = V[i], b = V[(i + 1) % 4], dx = b.x - a.x, dy = b.y - a.y, len = hypot(dx, dy)
                // both sides of a pair point the same way (right, or up when straight up and down): going round the
                // shape, opposite sides run opposite ways
                let flip: Double = dx < -1e-9 || (abs(dx) < 1e-9 && dy > 0) ? -1 : 1
                let u = CGPoint(x: flip * dx / len, y: flip * dy / len), nn = CGPoint(x: -u.y, y: u.x)
                for m in 0...k {
                    let px = a.x + dx / 2 + u.x * 0.7 * Double(m), py = a.y + dy / 2 + u.y * 0.7 * Double(m)
                    pic.line("par\(i)_\(m)", [(px - u.x * 0.6 + nn.x * 0.6, py - u.y * 0.6 + nn.y * 0.6), (px, py),
                                             (px - u.x * 0.6 - nn.x * 0.6, py - u.y * 0.6 - nn.y * 0.6)], .chapter)
                }
            }
        }
        // square-corner marks
        for i in marked(s, p) {
            let (u, v) = p.cornerSides(i), lu = hypot(Double(u.dx), Double(u.dy)), lv = hypot(Double(v.dx), Double(v.dy)), k = 1.5
            let a1 = CGPoint(x: V[i].x + Double(u.dx) / lu * k, y: V[i].y + Double(u.dy) / lu * k)
            let a2 = CGPoint(x: V[i].x + Double(v.dx) / lv * k, y: V[i].y + Double(v.dy) / lv * k)
            pic.line("rc\(i)", [(a1.x, a1.y), (a1.x + Double(v.dx) / lv * k, a1.y + Double(v.dy) / lv * k), (a2.x, a2.y)], .chapter)
        }
        if at == 2, let w = s.h("wc").map({ Int($0) - 1 }), V.indices.contains(w) { pic.dot("wc\(w)", at: V[w].x, V[w].y, radius: 0.6, Self.red, over: true) }
        for i in 0..<4 { pic.dot("v\(i)", at: V[i].x, V[i].y, radius: 0.3, .ink, over: true) }

        // a hint: one side of a pair not found yet, or a square corner not marked yet, ringed
        if s.on("ring"), at == 1, let pr = p.pairs.first(where: { !pairs.contains($0) }) {
            let i = pr[0], a = V[i], b = V[(i + 1) % 4]
            pic.circle("ring", at: (a.x + b.x) / 2, (a.y + b.y) / 2, radius: 1.3, .chapter, dashed: true)
        }
        if s.on("ring"), at == 2, let i = p.rights.first(where: { !marked(s, p).contains($0) }) {
            pic.circle("ring", at: V[i].x, V[i].y, radius: 1.3, .chapter, dashed: true)
        }

        // the family picture: boxes inside boxes
        if at >= 3 {
            let done = at >= 4, chain = p.chain, wrongBox: Box? = at == 3 ? s.h("wb").flatMap { Box(rawValue: Int($0) - 1) } : nil
            for b in [Box.quadrilaterals, .trapezoids, .parallelograms, .rectangles, .rhombuses] {
                let f = Self.family[b]!, on = done && chain.contains(b), wrong = wrongBox == b
                if done && chain[0] == b { pic.fill("fill\(b)", col: f.x, row: f.y, w: f.w, h: f.h, .tint(0.2)) }
                pic.sketch.box("box\(b)\(on)\(wrong)", pic.R(f.x, f.y, f.w, f.h), wrong ? Self.red : on ? .chapter : .ink, width: Sketch.stroke)
            }
            let sq = Self.family[.squares]!
            if done && chain[0] == .squares { pic.fill("fillS", col: sq.x, row: sq.y, w: sq.w, h: sq.h, .tint(0.4)) }
            if wrongBox == .squares { pic.fill("badS", col: sq.x, row: sq.y, w: sq.w, h: sq.h, Self.wrongFill) }
            for b in Box.allCases {
                let f = Self.family[b]!, on = done && chain.contains(b)
                pic.word("nm\(b)\(on)", b.name, at: f.lx, f.ly, on ? Self.small.colour(.chapter) : Self.small, anchor: f.anchor)
            }
        }
        return PaperDrawing(picture: pic.sketch, actions: at == 1 || at == 2 ? ["No more"] : [])
    }

    // MARK: the hands: tap a side, a corner, or a box; No more

    /// The side nearest a place, within a square and a half.
    private static func side(at q: CGPoint, _ V: [CGPoint]) -> Int? {
        var best: Int?, bd = 1.5
        for i in 0..<4 {
            let a = V[i], b = V[(i + 1) % 4], dx = b.x - a.x, dy = b.y - a.y
            let t = max(0, min(1, ((q.x - a.x) * dx + (q.y - a.y) * dy) / (dx * dx + dy * dy)))
            let d = hypot(q.x - (a.x + t * dx), q.y - (a.y + t * dy))
            if d < bd { bd = d; best = i }
        }
        return best
    }

    func hands(_ s: PaperState) -> Hands? {
        let p = SortingShapes.Parts(s.numbers), V = Self.corners(p)
        switch stage(s) {
        case 1:
            // what's found stays; a wrong pair's red goes as soon as anything else is tapped
            var base = s.hand
            base["w1"] = nil; base["w2"] = nil
            let count = Double(p.pairs.filter { (base[$0 == [0, 2] ? "p02" : "p13"] ?? 0) > 0 }.count)
            let keep: Numbers = ["p02": base["p02"] ?? 0, "p13": base["p13"] ?? 0]
            return Hands(tap: { q in
                guard let i = Self.side(at: q, V) else { return nil }
                var h = base
                guard let j = base["pick"].map({ Int($0) - 1 }) else { h["pick"] = Double(i + 1); return HandMove(hand: h) }
                h["pick"] = nil
                if i == j { return HandMove(hand: h) }
                let pr = [min(i, j), max(i, j)]
                if p.parallel(i, j) {
                    let key = pr == [0, 2] ? "p02" : "p13"
                    if h[key] == nil { h[key] = count + 1 }
                    return HandMove(hand: h)
                }
                var miss = h
                miss["w1"] = Double(pr[0] + 1); miss["w2"] = Double(pr[1] + 1)
                return HandMove(hand: h, missHand: miss, set: [("x", Double(100 + 10 * pr[0] + pr[1]))], check: true)
            }, actions: ["No more": {
                var h = base; h["pick"] = nil
                return HandMove(hand: h, missHand: h, set: [("x", count)], keep: keep, check: true)
            }])
        case 2:
            var base = s.hand
            base["wc"] = nil
            let marks = (0..<4).filter { (base["c\($0)"] ?? 0) > 0 }
            return Hands(tap: { q in
                guard let i = (0..<4).min(by: { hypot(q.x - V[$0].x, q.y - V[$0].y) < hypot(q.x - V[$1].x, q.y - V[$1].y) }),
                      hypot(q.x - V[i].x, q.y - V[i].y) < 2.5 else { return nil }
                var h = base
                if p.opening(i) == 0 { h["c\(i)"] = 1; return HandMove(hand: h) }
                var miss = h; miss["wc"] = Double(i + 1)
                return HandMove(hand: h, missHand: miss, set: [("x", Double(100 + i))], check: true)
            }, actions: ["No more": {
                HandMove(hand: base, missHand: base, set: [("x", Double(marks.count))], check: true)
            }])
        case 3:
            return Hands(tap: { q in
                guard let b = Self.box(at: q) else { return nil }
                return HandMove(hand: [:], missHand: ["wb": Double(b.rawValue + 1)], set: [("x", Double(b.rawValue))], check: true)
            })
        default: return nil
        }
    }

    /// The ghost finger: each pair not found yet, side by side, then No more; each square corner, then No more; the box.
    func demo(_ s: PaperState) -> [GhostMove] {
        let p = SortingShapes.Parts(s.numbers), V = Self.corners(p)
        func mid(_ i: Int) -> GhostMove { let a = V[i], b = V[(i + 1) % 4]; return .tap(.picture(CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2))) }
        switch stage(s) {
        case 1:
            var moves: [GhostMove] = []
            if let j = s.h("pick").map({ Int($0) - 1 }) { moves.append(mid(j)) }
            for pr in p.pairs where (s.hand[pr == [0, 2] ? "p02" : "p13"] ?? 0) == 0 { moves += [mid(pr[0]), mid(pr[1])] }
            return moves + [.tap(.action("No more"))]
        case 2:
            return p.rights.filter { (s.hand["c\($0)"] ?? 0) == 0 }.map { .tap(.picture(V[$0])) } + [.tap(.action("No more"))]
        case 3:
            return [.tap(.picture(Self.inside[p.smallest]!))]
        default: return []
        }
    }

    /// Screenshots only: two sides next to each other (never parallel); a corner that isn't square (or No more too soon);
    /// a box it fits in that's too big (or one it doesn't fit).
    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = SortingShapes.Parts(s.numbers)
        switch stage(s) {
        case 1: return HandMove(hand: [:], missHand: ["w1": 1, "w2": 2], set: [("x", 101)], check: true)
        case 2:
            if let i = (0..<4).first(where: { p.opening($0) != 0 }) { return HandMove(hand: [:], missHand: ["wc": Double(i + 1)], set: [("x", Double(100 + i))], check: true) }
            return HandMove(hand: [:], missHand: [:], set: [("x", 0)], check: true)
        case 3:
            let b = p.chain.count > 1 ? p.chain[1] : Box.rectangles
            return HandMove(hand: [:], missHand: ["wb": Double(b.rawValue + 1)], set: [("x", Double(b.rawValue))], check: true)
        default: return nil
        }
    }
}
