import SwiftUI

/// Place value and rounding on the paper, as in the preview (design/prototype/grade4-ch1.html): Rounding decimals' two
/// lines (RoundingLesson) with bigger numbers. Line 1 is 50 squares, ten blocks of the place, from the round number of
/// the next place up to the one after (40,000 to 50,000), the number's point on it with its number over it. Tap the block
/// it's in: it lights and opens below, a dashed funnel, into line 2, ten blocks of a tenth of the place (47,000 to 48,000,
/// halfway named). Drag the point to the end it's closer to: while it's held, brackets say how far it is to each end
/// ("382 to 47,000", "618 to 48,000"). Then the record, 47,382 ≈ [ ], typed; done, the place's digit underlined, the next
/// ringed, "3 is less than 5: round down" under it, and the last words say why.
@MainActor
struct PlaceValueLesson: PaperLesson {
    static let line1 = 4.0, line2 = 16.0, block = 5.0, length = 50.0

    var liveKeys: Set<String> { ["at"] }
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    private static let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PlaceValueRound.Parts(s.numbers), at = stage(s), found = at >= 2, c = BigNumbers.commas
        let y1 = Self.line1, y2 = Self.line2, B = Self.block, L = Self.length, small = Self.small
        // the point's place on each line, in squares
        let x1 = Double(P.n - P.lo1) / Double(10 * P.r) * L, x2 = Double(P.rest) / Double(P.r) * L, k = Double(P.block)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // line 1: ten blocks of the place; its ends named, the block's own ends taking their place once it's found
        _ = pic.numberLine("l1", col: 0, row: y1, steps: 10, per: B, long: 5)
        if !(found && P.block == 0) { pic.label("l1lo", c(P.lo1), small, .below, edge: y1, along: 0) }
        if !(found && P.block == 9) { pic.label("l1hi", c(P.lo1 + 10 * P.r), small, .below, edge: y1, along: L) }
        if at == 1 {
            if let w = s.h("wrong") { pic.fill("wrong\(w)", col: w * B, row: y1 - 2, w: B, h: 2, RoundingLesson.wrongFill) }
            if let t = s.h("tapped") { pic.fill("tapped\(t)", col: t * B, row: y1 - 2, w: B, h: 2, .tint(0.42)) }
        }
        pic.dot("p1", at: x1, y1, radius: 0.35, found ? .ink3 : .chapter, over: true)
        if !found { pic.label("p1w", c(P.n), Self.label, .above, edge: y1 - 2, along: x1) }
        if at == 1, s.on("ring") { pic.circle("ring", at: x1, y1, radius: 1.3, .chapter, dashed: true) }

        if found {
            pic.fill("blk", col: k * B, row: y1 - 2, w: B, h: 2, .tint(0.42))
            pic.label("blklo", c(P.T), small.colour(.chapter), .below, edge: y1, along: k * B)
            pic.label("blkhi", c(P.hi), small.colour(.chapter), .below, edge: y1, along: k * B + B)
            pic.line("zoomL", [(k * B, y1 + 3), (0, y2 - 4)], .chapter, dashed: true)
            pic.line("zoomR", [(k * B + B, y1 + 3), (L, y2 - 4)], .chapter, dashed: true)
            _ = pic.numberLine("l2", col: 0, row: y2, steps: 10, per: B, long: 5)
            let done = at >= 4
            pic.label("l2lo", c(P.T), small.colour(done && !P.up ? .chapter : .ink2), .below, edge: y2, along: 0)
            if !(at >= 2 && P.half) { pic.label("l2mid", c(P.T + P.r / 2), small.colour(.ink3), .below, edge: y2, along: L / 2) }
            pic.label("l2hi", c(P.hi), small.colour(done && P.up ? .chapter : .ink2), .below, edge: y2, along: L)

            if at == 2 {
                // the point to drag (it keeps every digit, so it can sit between ticks); while it's held, how far it is to
                // each end, in brackets under the line
                let now = s.h("at") ?? x2
                live.dot("p2", at: now, y2, radius: s.grabbed ? 0.7 : 0.55, .chapter, over: true)
                if !s.grabbed {
                    pic.label("p2w", c(P.n), Self.label, .above, edge: y2 - 2, along: x2)
                    live.circle("p2ring", at: now, y2, radius: 1.3, .chapter, dashed: true)
                }
                if s.grabbed || s.on("counts") {
                    let pen = s.grabbed ? live : pic, by = y2 + 3
                    var p = pen
                    p.line("brL", [(0, by - 1), (0, by), (x2, by), (x2, by - 1)], .chapter)
                    p.line("brR", [(x2, by - 1), (x2, by), (L, by), (L, by - 1)], .chapter)
                    p.label("brLw", "\(c(P.rest)) to \(c(P.T))", small.colour(.chapter), .below, edge: by, along: min(max(6, x2 / 2), L / 2 - 6))
                    p.label("brRw", "\(c(P.r - P.rest)) to \(c(P.hi))", small.colour(.chapter), .below, edge: by, along: max(min(L - 6, (x2 + L) / 2), L / 2 + 6))
                    if s.grabbed {
                        p.reads("\(c(P.rest)) to \(c(P.T)) · \(c(P.r - P.rest)) to \(c(P.hi))")
                        // the end it's heading for
                        if now != L / 2 { p.dot("head", at: now > L / 2 ? L : 0, y2, radius: 0.6, .tint(0.42)) }
                        live = p
                    } else { pic = p }
                }
            } else if at >= 3 {
                // the point where the number is, and its hop to the closer end, how far written over it
                let end = P.up ? L : 0, span = abs(end - x2), height = min(3, max(1.2, span / 6))
                pic.dot("p2", at: x2, y2, radius: 0.55, .chapter, over: true)
                pic.label("p2w", c(P.n), Self.label, .above, edge: y2 - 2, along: x2)
                pic.hop("hop", from: x2, to: end, row: y2, height: height)
                pic.dot("end", at: end, y2, radius: 0.4, .chapter, over: true)
                let a = min(x2, end), b = max(x2, end)
                pic.line("hopc", [(a, y2 + 3), (a, y2 + 4), (b, y2 + 4), (b, y2 + 3)], .chapter)
                pic.label("hopw", c(P.up ? P.r - P.rest : P.rest), small.colour(.chapter), .below, edge: y2 + 4, along: (a + b) / 2)
            }
        }

        var boxes: [WorkBox] = []
        if at >= 3 {
            // the record: 47,382 ≈ [ ], the numbers written tight (G 3 Nov), the place's digit underlined and the next
            // ringed where they stand in it
            let right = Record.width(.n(P.n)), row = 1.0
            Record.tight(&rec, "num", P.n, right: right, row: row)
            let ow = Record.opWidth("≈")
            rec.word("approx", "≈", at: right + ow / 2, row, Record.maths)
            let cells = String(P.R).count
            if at == 3 {
                let bw = Record.boxWidth(cells: cells, commas: true)
                rec.answerBox("x", right: right + ow + bw, mid: row, per: 2, cells: 1, commas: true, word: bw)
            } else {
                Record.tight(&rec, "R", P.R, right: right + ow + Record.width(.n(P.R)), row: row, .chapter)
                // a digit's middle in the tight number (centred in its squares): what's written after it measured back
                // from its right edge
                let text = Array(BigNumbers.commas(P.n)), font = PaperText.font(Sketch.maths, .medium, digits: true)
                func w(_ s: String) -> Double { PaperText.width(s, font) / Paper.cell }
                let inkRight = right - Record.width(.n(P.n)) / 2 + w(String(text)) / 2
                func mid(_ place: Int) -> Double {
                    var seen = -1, i = text.count
                    while i > 0 { i -= 1; if text[i].isNumber { seen += 1; if seen == place { break } } }
                    // (the glyphs' own side bearing puts the ink a little right of the measured middle)
                    return inkRight - w(String(text[(i + 1)...])) - w(String(text[i])) / 2 + 0.08
                }
                rec.rule("under", from: mid(P.k) - 0.5, to: mid(P.k) + 0.5, row: row + 1, .chapter)
                rec.ring("next", col: mid(P.k - 1) - 0.7, row: row - 1.2, w: 1.4, h: 2.4)
                rec.word("rule", P.rule, at: 0, row + 3, Self.small, anchor: UnitPoint(x: 0, y: 0.5))
            }
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes)
    }

    func messageRows(_ n: Numbers) -> Int { 1 }

    func hands(_ s: PaperState) -> Hands? {
        let P = PlaceValueRound.Parts(s.numbers), B = Self.block, L = Self.length
        let x2 = Double(P.rest) / Double(P.r) * L
        switch stage(s) {
        case 1:
            return Hands(tap: { q in
                guard q.y > -0.5, q.y < Self.line1 + 3.5, q.x > -0.5, q.x < L + 0.5 else { return nil }
                let b = Double(min(9, max(0, Int((q.x / B).rounded(.down)))))
                return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
            })
        case 2:
            // the point on line 2, a square at a time; let go on (or near) an end, or past halfway, and it goes there
            let now = s.h("at") ?? x2
            return Hands(grab: { q in abs(q.x - now) < 2.5 && abs(q.y - Self.line2) < 3 ? ["grab": 1, "at": now] : nil },
                         drag: { q, _ in ["grab": 1, "at": min(L, max(0, q.x.rounded()))] },
                         release: { h in
                             let a = h["at"] ?? x2
                             // let go where it was: nothing happened
                             if a > 1, a < L - 1, abs(a - x2) < 1.5 { return HandMove(hand: [:], missHand: [:], set: [], check: false) }
                             let end: Double = a <= 1 ? 0 : a >= L - 1 ? 10 : a > L / 2 ? 10 : a < L / 2 ? 0 : (a > x2 ? 10 : 0)
                             return HandMove(hand: ["at": end * B], missHand: [:], set: [("x", end)], check: true)
                         })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = PlaceValueRound.Parts(s.numbers), B = Self.block, L = Self.length
        switch stage(s) {
        case 1: return [.tap(.picture(CGPoint(x: (Double(P.block) + 0.5) * B, y: Self.line1 - 1)))]
        case 2: return [.drag(from: CGPoint(x: s.h("at") ?? Double(P.rest) / Double(P.r) * L, y: Self.line2), to: CGPoint(x: P.up ? L : 0, y: Self.line2))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = PlaceValueRound.Parts(s.numbers)
        switch stage(s) {
        case 1:
            let b = Double((P.block + 3) % 10)
            return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
        case 2:
            let end: Double = P.up ? 0 : 10
            return HandMove(hand: ["at": end * Self.block], missHand: [:], set: [("x", end)], check: true)
        default: return nil
        }
    }
}
