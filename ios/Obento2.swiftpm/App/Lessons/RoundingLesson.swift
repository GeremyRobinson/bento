import SwiftUI

/// Rounding decimals on the paper, as on the test page G approved (design/grade5.md). Line 1 is the place one bigger
/// (the tenth for hundredths, the whole for tenths): 50 squares, ten blocks of the place, the number's point on it with
/// its number over it (the problem, written once). Tap the block it's in: it lights and opens below, a dashed funnel,
/// into line 2, ten big steps of the next place. Drag the point to the end it's closer to, a bracket counting the steps
/// as it goes ("That end is 6 steps away. The other end is 4."). Then the record, 3.476 ≈ [ ], typed; done, the place's
/// digit is underlined, the next ringed, "6 is 5 or more: round up" written under it, and the last words say why.
@MainActor
struct RoundingLesson: PaperLesson {
    /// The picture's rows and sizes, in its squares: line 1, line 2 a dozen squares under it, a block of 5.
    static let line1 = 4.0, line2 = 16.0, block = 5.0, length = 50.0

    var liveKeys: Set<String> { ["at"] }

    private static let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    /// A block tapped that the point isn't in: lightly red (red means wrong).
    private static let wrongFill = Sketch.Colour.hex(Ink.mix(0xF3F2EF, 0xC8372D, 0.2), Ink.mix(0x121211, 0xFF6B5E, 0.24))

    /// The stage: 0 the question, 1 tap the block, 2 drag the point, 3 write it, 4 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = RoundDecimals.Parts(s.numbers), p = P.p, at = stage(s), found = at >= 2
        let y1 = Self.line1, y2 = Self.line2, B = Self.block, L = Self.length, label = Self.label
        let k = Double(P.digit), x1 = (P.value - P.lo1) / P.place * B, sx = P.step * B
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // line 1: the place one bigger, in ten blocks of the place; its ends to one place fewer (3.4 and 3.5, 5 and 6),
        // the block's own ends taking their place once it's found
        pic.numberLine("l1", col: 0, row: y1, steps: 10, per: B, long: 5)
        if !(found && P.digit == 0) { pic.label("l1lo", RoundDecimals.written(P.lo1, p - 1), label, .below, edge: y1, along: 0) }
        if !(found && P.digit == 9) { pic.label("l1hi", RoundDecimals.written(P.lo1 + 10 * P.place, p - 1), label, .below, edge: y1, along: L) }
        if at == 1 {
            // the block tapped: lit while it's checked, red when the point isn't in it
            if let w = s.h("wrong") { pic.fill("wrong\(w)", col: w * B, row: y1 - 2, w: B, h: 2, Self.wrongFill) }
            if let t = s.h("tapped") { pic.fill("tapped\(t)", col: t * B, row: y1 - 2, w: B, h: 2, .tint(0.42)) }
        }
        // the number's point, its number over it until the block it's in is found
        pic.dot("p1", at: x1, y1, radius: 0.35, found ? .ink3 : .chapter, over: true)
        if !found { pic.label("p1w", fmt(P.value), label.colour(.ink), .above, edge: y1 - 2, along: x1) }
        // a hint (after a miss or asked for): the point ringed
        if at == 1, s.on("ring") { pic.circle("ring", at: x1, y1, radius: 1.3, .chapter, dashed: true) }

        if found {
            // the block it's in, lit, its ends named, opened out below into line 2's ten big steps (the funnel stops
            // two squares over line 2's end ticks, clear of the number's own label wherever the point is)
            pic.fill("blk", col: k * B, row: y1 - 2, w: B, h: 2, .tint(0.42))
            pic.label("blklo", RoundDecimals.written(P.T, p), label.colour(.chapter), .below, edge: y1, along: k * B)
            pic.label("blkhi", RoundDecimals.written(P.up, p), label.colour(.chapter), .below, edge: y1, along: k * B + B)
            pic.line("zoomL", [(k * B, y1 + 3), (0, y2 - 4)], .chapter, dashed: true)
            pic.line("zoomR", [(k * B + B, y1 + 3), (L, y2 - 4)], .chapter, dashed: true)
            pic.numberLine("l2", col: 0, row: y2, steps: 10, per: B, long: 5)
            let done = at >= 4
            pic.label("l2lo", RoundDecimals.written(P.T, p), label.colour(done && P.stays ? .chapter : .ink2), .below, edge: y2, along: 0)
            // halfway, small, under the middle tick; not when the point is there (its own number says it, and its ring
            // would cross it)
            if !(at >= 2 && P.halfway) { pic.label("l2mid", RoundDecimals.written(P.half, p + 1), Self.small.colour(.ink3), .below, edge: y2, along: L / 2) }
            pic.label("l2hi", RoundDecimals.written(P.up, p), label.colour(done && P.roundsUp ? .chapter : .ink2), .below, edge: y2, along: L)

            if at == 2 {
                // the point to drag: where the hand has it, the number's label where it started (not while it's held)
                let now = s.h("at") ?? P.step
                live.dot("p2", at: now * B, y2, radius: s.grabbed ? 0.7 : 0.55, .chapter, over: true)
                if !s.grabbed {
                    pic.label("p2w", fmt(P.value), label.colour(.ink), .above, edge: y2 - 2, along: sx)
                    live.circle("p2ring", at: now * B, y2, radius: 1.3, .chapter, dashed: true)
                }
                // the steps counted while it moves: a bracket under the line from where it was to where it is, its
                // count under it (under the line, where the hint counts too, so it never crosses the dashed funnel)
                if s.grabbed, abs(now - P.step) > 0.01 {
                    let a = min(now, P.step) * B, b = max(now, P.step) * B, n = Int(abs(now - P.step).rounded())
                    live.line("count", [(a, y2 + 3), (a, y2 + 4), (b, y2 + 4), (b, y2 + 3)], .chapter)
                    live.label("countw", RoundDecimals.steps(n), label.colour(.chapter), .below, edge: y2 + 4, along: (a + b) / 2)
                }
                // a hint: the steps to each end, counted under the line (the live count takes its place while held)
                if s.on("counts"), !s.grabbed {
                    let low = P.step, high = 10 - P.step
                    pic.line("toLo", [(0, y2 + 3), (0, y2 + 4), (sx, y2 + 4), (sx, y2 + 3)], .ink2)
                    pic.label("toLow", low == 1 ? "1 step" : "\(fmt(low)) steps", Self.small, .below, edge: y2 + 4, along: sx / 2)
                    pic.line("toHi", [(sx, y2 + 3), (sx, y2 + 4), (L, y2 + 4), (L, y2 + 3)], .ink2)
                    pic.label("toHigh", high == 1 ? "1 step" : "\(fmt(high)) steps", Self.small, .below, edge: y2 + 4, along: (sx + L) / 2)
                }
            } else if at >= 3 {
                // the point where the number is, and its hop to the closer end; the steps it took counted under the
                // line, as they were while it was dragged
                let end = P.roundsUp ? L : 0, span = abs(end - sx), height = min(2.5, max(1.2, span / 6))
                pic.dot("p2", at: sx, y2, radius: 0.55, .chapter, over: true)
                pic.label("p2w", fmt(P.value), label.colour(.ink), .above, edge: y2 - 2, along: sx)
                pic.hop("hop", from: sx, to: end, row: y2, height: height)
                pic.dot("end", at: end, y2, radius: 0.4, .chapter, over: true)
                let a = min(sx, end), b = max(sx, end)
                pic.line("hopc", [(a, y2 + 3), (a, y2 + 4), (b, y2 + 4), (b, y2 + 3)], .chapter)
                pic.label("hopw", RoundDecimals.steps(P.near), label.colour(.chapter), .below, edge: y2 + 4, along: (a + b) / 2)
            }
        }

        var boxes: [WorkBox] = []
        if at >= 3 {
            // the record, as school writes it: the number, ≈, the closer end; two squares to a digit, the point on a line
            let V = fmt(P.value), ds = Array(V.filter { $0 != "." }), whole = V.split(separator: ".").first?.count ?? 1
            let right = 2 * Double(ds.count), row = 1.0, R = RoundDecimals.written(P.R, p)
            rec.digits("num", V, right: right, row: row, per: 2)
            rec.word("approx", "≈", at: right + 2, row, Self.maths)
            if at == 3 {
                // as on the test page: a box as many cells as the answer has characters, what's typed written in its
                // middle as one number (the point on its line, not in a cell of its own)
                rec.answerBox("x", right: right + 4 + 2 * Double(R.count), mid: row, per: 2, cells: R.count, centred: true)
            } else {
                rec.digits("R", R, right: right + 4 + 2 * Double(R.filter { $0 != "." }.count), row: row, per: 2, .chapter)
                // the rule as the record has it: the place's digit underlined, the next one ringed, why written under them
                func mid(_ i: Int) -> Double { right - 2 * Double(ds.count - 1 - i) - 1 }
                let placeI = whole + p - 1, nextI = placeI + 1
                if placeI < ds.count { rec.rule("under", from: mid(placeI) - 1, to: mid(placeI) + 1, row: row + 1, .chapter) }
                if nextI < ds.count { rec.ring("next", col: mid(nextI) - 1, row: row - 1, w: 2, h: 2) }
                rec.word("rule", P.rule, at: 0, row + 3, Self.small, anchor: UnitPoint(x: 0, y: 0.5))
            }
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = RoundDecimals.Parts(s.numbers), B = Self.block
        switch stage(s) {
        case 1:
            // tap a block of line 1 (anywhere on it, its ticks or its labels): the block's number is the digit
            return Hands(tap: { q in
                guard q.y > -0.5, q.y < Self.line1 + 3.5, q.x > -0.5, q.x < Self.length + 0.5 else { return nil }
                let b = Double(min(9, max(0, Int((q.x / B).rounded(.down)))))
                return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
            })
        case 2:
            // the point on line 2: it snaps to the steps; let go on an end, or it goes back
            let now = s.h("at") ?? P.step
            return Hands(grab: { q in abs(q.x - now * B) < 2.5 && abs(q.y - Self.line2) < 3 ? ["grab": 1, "at": now] : nil },
                         drag: { q, _ in ["grab": 1, "at": min(10, max(0, (q.x / B).rounded()))] },
                         release: { h in
                             let end = h["at"] ?? P.step
                             return HandMove(hand: ["at": end], missHand: [:], set: [("x", end)], check: true)
                         })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = RoundDecimals.Parts(s.numbers), B = Self.block
        switch stage(s) {
        case 1: return [.tap(.picture(CGPoint(x: (Double(P.digit) + 0.5) * B, y: Self.line1 - 1)))]
        case 2: return [.drag(from: CGPoint(x: (s.h("at") ?? P.step) * B, y: Self.line2), to: CGPoint(x: P.roundsUp ? Self.length : 0, y: Self.line2))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = RoundDecimals.Parts(s.numbers)
        switch stage(s) {
        case 1:
            let b = Double((P.digit + 3) % 10)
            return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
        case 2:
            let end: Double = P.roundsUp ? 0 : 10
            return HandMove(hand: ["at": end], missHand: [:], set: [("x", end)], check: true)
        default: return nil
        }
    }
}
