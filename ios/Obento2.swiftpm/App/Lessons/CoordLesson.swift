import SwiftUI

/// Points on a grid on the paper, as in the preview G approved on 1 Nov 2026 (design/prototype/new5-lessons.html, dCoord;
/// design/grade5.md). One step is one block (5 squares): the paper's own strong lines are the coordinate grid, 10 across
/// and 7 up; only the two edges are drawn, with their numbers and arrows ("x", "y").
///
/// **Plot** `A (a, b)`, the pair written in the record beside the grid: drag the dot from 0 along the bottom (a chapter
/// line follows it, the number under it lights, "4 across" over it), let go on a; then drag it up from there ("2 up"),
/// let go on b; the point is named, and the record labels each number "across", "up".
/// **Read** a point A: drag A straight down (a dashed line follows the finger to the bottom numbers; a lights), then
/// across to the side (b lights), then write `A ( [a] , [b] )` in the record.
///
/// The picture's squares: the grid's corner (0, 0) at column 5, row 37 (the "y" arrow at row 0). Picture keys: "at"
/// (PointsOnGrid), "ring" (a hint: the number to reach ringed, or the point). Hand keys: "u" (across) and "v" (up) for
/// the plotted dot, "dv" and "du" for the finger reading A (all live), "lit" (the number lit while dragging), "grab".
@MainActor
struct CoordLesson: PaperLesson {
    /// The grid's corner, one step's squares, and how far it goes.
    static let ox = 5.0, oy = 37.0, step = 5.0
    static let across = Double(PointsOnGrid.across), up = Double(PointsOnGrid.up)
    /// Where a point (u across, v up) is, in the picture's squares.
    static func P(_ u: Double, _ v: Double) -> CGPoint { CGPoint(x: ox + u * step, y: oy - v * step) }

    var liveKeys: Set<String> { ["u", "v", "dv", "du"] }

    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
    private static let say = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .ink)
    private static let maths = Sketch.Words(size: Sketch.maths, weight: .semibold, colour: .ink)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The record beside the grid, level with the grid's top block (the preview's row 9).
    func recordBeside(_ n: Numbers) -> Double? { 3 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let p = PointsOnGrid.Parts(s.numbers), a = Double(p.a), b = Double(p.b), at = stage(s)
        let ox = Self.ox, oy = Self.oy, S = Self.step
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // the two edges, their arrows and names; the paper's own strong lines are the grid
        let xEnd = ox + Self.across * S + 2, yEnd = oy - Self.up * S - 2
        pic.line("ax", [(ox, oy), (xEnd, oy)])
        pic.line("axa", [(xEnd - 0.8, oy - 0.8), (xEnd, oy), (xEnd - 0.8, oy + 0.8)])
        pic.line("ay", [(ox, oy), (ox, yEnd)])
        pic.line("aya", [(ox - 0.8, yEnd + 0.8), (ox, yEnd), (ox + 0.8, yEnd + 0.8)])
        pic.label("axn", "x", Self.small, .right, edge: xEnd, along: oy)
        pic.label("ayn", "y", Self.small, .above, edge: yEnd, along: ox)

        // which number lights: the one the dot is over while it's dragged, then the one it was let go on
        let held = s.grabbed ? s.h("lit").map { Int($0) } : nil
        let litX: Int? = p.read ? (at >= 2 ? p.a : nil) : (at == 1 ? held : at >= 2 ? p.a : nil)
        let litY: Int? = p.read ? (at >= 3 ? p.b : nil) : (at == 2 ? held : at >= 3 ? p.b : nil)
        pic.sketch.segments("xt", (0...PointsOnGrid.across).map { i in (pic.P(ox + Double(i) * S, oy), pic.P(ox + Double(i) * S, oy + 0.5)) }, .ink, width: Sketch.stroke)
        pic.sketch.segments("yt", (1...PointsOnGrid.up).map { j in (pic.P(ox - 0.5, oy - Double(j) * S), pic.P(ox, oy - Double(j) * S)) }, .ink, width: Sketch.stroke)
        for i in 0...PointsOnGrid.across {
            let lit = litX == i && i > 0
            pic.label("xl\(i)\(lit)", "\(i)", lit ? Self.small.colour(.chapter) : Self.small, .below, edge: oy + 0.5, along: ox + Double(i) * S)
        }
        for j in 1...PointsOnGrid.up {
            let lit = litY == j
            pic.label("yl\(j)\(lit)", "\(j)", lit ? Self.small.colour(.chapter) : Self.small, .left, edge: ox - 0.5, along: oy - Double(j) * S)
        }

        var boxes: [WorkBox] = []
        if !p.read {
            // the path walked: along the bottom, then up (live while it's being dragged)
            let u = at == 1 ? (s.h("u") ?? 0) : at == 0 ? 0 : a
            let v = at == 2 ? (s.h("v") ?? 0) : at >= 3 ? b : 0
            if u > 0.05 {
                if at == 1 { live.line("walkx", [(ox, oy), (ox + u * S, oy)], .chapter) } else { pic.line("walkx", [(ox, oy), (ox + u * S, oy)], .chapter) }
            }
            if at >= 2, v > 0.05 {
                if at == 2 { live.line("walky", [(ox + a * S, oy), (ox + a * S, oy - v * S)], .chapter) } else { pic.line("walky", [(ox + a * S, oy), (ox + a * S, oy - v * S)], .chapter) }
            }
            let dot = Self.P(u, v)
            live.dot("pt", at: dot.x, dot.y, radius: s.grabbed ? 0.7 : 0.55, .chapter, over: true)
            if s.grabbed, at == 1 || at == 2 {
                let n = Int(((at == 1 ? u : v)).rounded()), text = at == 1 ? "\(n) across" : "\(n) up"
                live.label("read", text, Self.small.colour(.chapter), .above, edge: dot.y - 1, along: dot.x)
                live.reads(text)
            }
            if at >= 3 { pic.label("ptn", p.name, Self.say.colour(.chapter), .right, edge: dot.x + 0.6, along: dot.y - 1.2) }
            // a hint: the number to reach, ringed
            if s.on("ring"), at == 1 { pic.circle("ring", at: ox + a * S, oy + 1.35, radius: 1.2, .chapter, dashed: true) }
            if s.on("ring"), at == 2 { pic.circle("ring", at: ox - 1.3, oy - b * S, radius: 1.2, .chapter, dashed: true) }

            // the record: the pair, each number labelled once its move is made
            rec.word("rn", p.name, at: 1, 1, Self.maths)
            rec.word("ro", "(", at: 3.5, 1, Self.maths)
            rec.word("ra\(at >= 2)", "\(p.a)", at: 5, 1, at >= 2 ? Self.maths.colour(.chapter) : Self.maths)
            rec.word("rc", ",", at: 6.5, 1, Self.maths)
            rec.word("rb\(at >= 3)", "\(p.b)", at: 8, 1, at >= 3 ? Self.maths.colour(.chapter) : Self.maths)
            rec.word("rcl", ")", at: 9.5, 1, Self.maths)
            if at >= 2 { rec.label("rau", "across", Self.small, .below, edge: 2, along: 5) }
            if at >= 3 { rec.label("rbu", "up", Self.small, .below, edge: 2, along: 8) }
        } else {
            let pt = Self.P(a, b)
            // the dashed lines A is dragged along: following the finger, then staying
            if at == 1, s.grabbed {
                let dv = s.h("dv") ?? b
                live.line("dd", [(pt.x, pt.y), (pt.x, oy - dv * S)], .chapter, dashed: true)
                live.dot("fing", at: pt.x, oy - dv * S, radius: 0.35, .chapter, over: true)
            }
            if at >= 2 { pic.line("ddown", [(pt.x, pt.y), (pt.x, oy)], .chapter, dashed: true) }
            if at == 2, s.grabbed {
                let du = s.h("du") ?? a
                live.line("ds", [(pt.x, pt.y), (ox + du * S, pt.y)], .chapter, dashed: true)
                live.dot("fing", at: ox + du * S, pt.y, radius: 0.35, .chapter, over: true)
            }
            if at >= 3 { pic.line("dside", [(pt.x, pt.y), (ox, pt.y)], .chapter, dashed: true) }
            pic.dot("pt\(s.grabbed)", at: pt.x, pt.y, radius: s.grabbed ? 0.7 : 0.55, .chapter, over: true)
            pic.label("ptn", p.name, Self.say, .right, edge: pt.x + 0.6, along: pt.y - 1.2)
            // a hint: the point ringed while it's dragged; the two numbers ringed while it's written
            if s.on("ring"), at == 1 || at == 2 { pic.circle("ring", at: pt.x, pt.y, radius: 1.3, .chapter, dashed: true) }
            if s.on("ring"), at == 3 {
                pic.circle("ringx", at: ox + a * S, oy + 1.35, radius: 1.2, .chapter, dashed: true)
                pic.circle("ringy", at: ox - 1.3, oy - b * S, radius: 1.2, .chapter, dashed: true)
            }

            // the record, once it's found: A ( [a] , [b] ), each number labelled
            if at >= 3 {
                rec.word("rn", p.name, at: 1, 1, Self.maths)
                rec.word("ro", "(", at: 3.5, 1, Self.maths)
                rec.word("rc", ",", at: 7.5, 1, Self.maths)
                rec.word("rcl", ")", at: 11.5, 1, Self.maths)
            }
            if at == 3 {
                rec.answerBox("x", right: 6.5, mid: 1, per: 2, cells: 1, centred: true)
                rec.answerBox("y", right: 10.5, mid: 1, per: 2, cells: 1, centred: true)
                boxes = rec.boxes
            } else if at >= 4 {
                rec.word("rx", "\(p.a)", at: 5.5, 1, Self.maths.colour(.chapter))
                rec.word("ry", "\(p.b)", at: 9.5, 1, Self.maths.colour(.chapter))
                rec.label("rau", "across", Self.small, .below, edge: 2, along: 5.5)
                rec.label("rbu", "up", Self.small, .below, edge: 2, along: 9.5)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes)
    }

    // MARK: the hands

    /// A snapped place along a line: to the square, in steps.
    private static func snap(_ squares: Double) -> Double { squares.rounded() / step }

    func hands(_ s: PaperState) -> Hands? {
        let p = PointsOnGrid.Parts(s.numbers), a = Double(p.a), b = Double(p.b), at = stage(s)
        let ox = Self.ox, oy = Self.oy
        func near(_ q: CGPoint, _ c: CGPoint) -> Bool { hypot(q.x - c.x, q.y - c.y) <= 2.5 }
        if !p.read {
            switch at {
            case 1:
                // the dot along the bottom, from where it is
                let u = s.h("u") ?? 0
                return Hands(grab: { q in near(q, Self.P(u, 0)) ? ["grab": 1, "u": u, "lit": u.rounded()] : nil },
                             drag: { q, _ in let u = min(Self.across, max(0, Self.snap(q.x - ox))); return ["grab": 1, "u": u, "lit": u.rounded()] },
                             release: { h in
                                 let n = (h["u"] ?? 0).rounded()
                                 // let go at 0: nothing happened
                                 guard n > 0 else { return HandMove(hand: [:]) }
                                 return HandMove(hand: ["u": n], missHand: [:], set: [("x", n)], check: true)
                             })
            case 2:
                // then up, from a on the bottom
                let v = s.h("v") ?? 0
                return Hands(grab: { q in near(q, Self.P(a, v)) ? ["grab": 1, "v": v, "lit": v.rounded()] : nil },
                             drag: { q, _ in let v = min(Self.up, max(0, Self.snap(oy - q.y))); return ["grab": 1, "v": v, "lit": v.rounded()] },
                             release: { h in
                                 let n = (h["v"] ?? 0).rounded()
                                 guard n > 0 else { return HandMove(hand: [:]) }
                                 return HandMove(hand: ["v": n], missHand: [:], set: [("y", n)], check: true)
                             })
            default: return nil
            }
        }
        let pt = Self.P(a, b)
        switch at {
        case 1:
            // A straight down to the bottom numbers: let go there, or it goes back
            return Hands(grab: { q in near(q, pt) ? ["grab": 1, "dv": b] : nil },
                         drag: { q, _ in ["grab": 1, "dv": min(b, max(0, Self.snap(oy - q.y)))] },
                         release: { h in HandMove(hand: [:], missHand: [:], set: [("x", h["dv"] ?? b)], check: true) })
        case 2:
            // then across to the side
            return Hands(grab: { q in near(q, pt) ? ["grab": 1, "du": a] : nil },
                         drag: { q, _ in ["grab": 1, "du": min(a, max(0, Self.snap(q.x - ox)))] },
                         release: { h in HandMove(hand: [:], missHand: [:], set: [("x", h["du"] ?? a)], check: true) })
        default: return nil
        }
    }

    /// The ghost finger drags the dot (or A) the way the step goes.
    func demo(_ s: PaperState) -> [GhostMove] {
        let p = PointsOnGrid.Parts(s.numbers), a = Double(p.a), b = Double(p.b), at = stage(s)
        if !p.read {
            switch at {
            case 1: return [.drag(from: Self.P(s.h("u") ?? 0, 0), to: Self.P(a, 0))]
            case 2: return [.drag(from: Self.P(a, s.h("v") ?? 0), to: Self.P(a, b))]
            default: return []
            }
        }
        switch at {
        case 1: return [.drag(from: Self.P(a, b), to: Self.P(a, 0))]
        case 2: return [.drag(from: Self.P(a, b), to: Self.P(0, b))]
        default: return []
        }
    }

    /// Screenshots only: the slips the lesson names. Plot: the other number counted (the swap); read: let go short.
    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = PointsOnGrid.Parts(s.numbers), at = stage(s)
        if !p.read {
            switch at {
            case 1: return HandMove(hand: ["u": Double(p.b)], missHand: [:], set: [("x", Double(p.b))], check: true)
            case 2:
                let v = p.a <= PointsOnGrid.up ? p.a : (p.b == 1 ? 2 : p.b - 1)
                return HandMove(hand: ["v": Double(v)], missHand: [:], set: [("y", Double(v))], check: true)
            default: return nil
            }
        }
        switch at {
        case 1: return HandMove(hand: [:], missHand: [:], set: [("x", 1)], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("x", 1)], check: true)
        default: return nil
        }
    }

    /// Screenshots only: the pair written the wrong way round.
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = PointsOnGrid.Parts(s.numbers)
        guard p.read, stage(s) == 3 else { return nil }
        return ["x": Double(p.b), "y": Double(p.a)]
    }
}
