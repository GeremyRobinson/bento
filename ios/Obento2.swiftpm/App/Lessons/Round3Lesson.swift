import SwiftUI

/// Rounding to 10 and 100 on the paper, as in the preview (design/prototype/grade3-ch3.html, dRound): Rounding decimals'
/// two lines with whole numbers. Line 1 is 50 squares, ten blocks of the place (the hundred the number is in, a block a
/// ten; or 0 to 1000, a block a hundred), the number's point on it. Tap the block it's in: it lights and opens below, a
/// dashed funnel, into line 2, ten blocks again (340 to 350, halfway its tall middle tick). Drag the point to the end it's
/// closer to: while it's held, brackets say how far it is to each end ("7 to 340", "3 to 350"). Then the hop to that end,
/// how far written over it, and the record `347 ≈ [350]`, typed; done, the place's digit underlined, the next ringed, "7 is
/// 5 or more: round up" beside it.
@MainActor
struct Round3Lesson: PaperLesson {
    static let line1 = 4.0, line2 = 14.0, block = 5.0, length = 50.0

    var liveKeys: Set<String> { ["at"] }
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { Self.line2 + 6 }

    /// A line of ten blocks: ticks every block, a block's tick a square tall, every 5th two (line 2's middle three).
    private static func numberLine(_ pen: inout GridPen, _ id: String, row y: Double, middle: Bool) {
        pen.line(id, [(0, y), (length, y)])
        for i in 0...10 {
            let h: Double = middle && i == 5 ? 3 : i % 5 == 0 ? 2 : 1
            pen.line("\(id)t\(i)", [(Double(i) * block, y - h), (Double(i) * block, y)])
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Round3.Parts(s.numbers), at = stage(s), open = at >= 1
        let y1 = Self.line1, y2 = Self.line2, B = Self.block, L = Self.length, small = Self.small
        let x1 = Double(P.n - P.lo1) / Double(10 * P.to) * L, x2 = Double(P.rest) / Double(P.to) * L, k = Double(P.block)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // line 1: ten blocks of the place, its ends named, the number's point on it
        if open { pic.fill("lit", col: k * B, row: y1 - 2, w: B, h: 2, .tint(0.42)) }
        if at == 0 {
            if let w = s.h("wrong") { pic.fill("wrong\(w)", col: w * B, row: y1 - 2, w: B, h: 2, RoundingLesson.wrongFill) }
            if let t = s.h("tapped") { pic.fill("tapped\(t)", col: t * B, row: y1 - 2, w: B, h: 2, .tint(0.42)) }
        }
        Self.numberLine(&pic, "l1", row: y1, middle: false)
        pic.label("l1lo", "\(P.lo1)", small, .below, edge: y1, along: 0)
        pic.label("l1hi", "\(P.lo1 + 10 * P.to)", small, .below, edge: y1, along: L)
        pic.dot("p1", at: x1, y1, radius: 0.5, .chapter, over: true)
        // a hint: the point ringed (a first miss), then the block it's in (a second)
        if at == 0, s.on("ring") { pic.circle("ring", at: x1, y1, radius: 1.3, .chapter, dashed: true) }
        if at == 0, s.on("spot") { KK.hintBox(&pic, "spot", x: k * B, y: y1 - 2, w: B, h: 2) }

        if open {
            // the block opens below into line 2: ten blocks again, halfway its tall middle tick
            pic.line("fanL", [(k * B, y1 + 2.4), (0, y2 - 3.6)], .chapter, dashed: true)
            pic.line("fanR", [(k * B + B, y1 + 2.4), (L, y2 - 3.6)], .chapter, dashed: true)
            Self.numberLine(&pic, "l2", row: y2, middle: true)
            let done = at >= 3
            pic.label("l2lo", "\(P.T)", small.colour(done && !P.up ? .chapter : .ink2), .below, edge: y2, along: 0)
            pic.label("l2hi", "\(P.hi)", small.colour(done && P.up ? .chapter : .ink2), .below, edge: y2, along: L)
            if !(at == 1 && s.grabbed) && !(at >= 2 && P.half) { pic.label("l2mid", "\(P.mid)", small.colour(.ink3), .below, edge: y2, along: L / 2) }
            if at == 1 {
                let now = s.h("at") ?? x2
                live.dot("p2", at: now, y2, radius: s.grabbed ? 0.7 : 0.5, .chapter, over: true)
                // while it's held, how far the number is to each end, in brackets under the line, and the end it's heading for
                if s.grabbed || s.on("ring") {
                    var p = s.grabbed ? live : pic
                    Self.brackets(&p, P, x2)
                    if s.grabbed {
                        p.reads("\(P.rest) to \(P.T) · \(P.to - P.rest) to \(P.hi)")
                        if now != L / 2 { p.dot("head", at: now > L / 2 ? L : 0, y2, radius: 0.6, .tint(0.42)) }
                        live = p
                    } else { pic = p }
                }
                // a second miss: the closer end ringed
                if s.on("spot"), !s.grabbed { pic.circle("spot", at: P.up ? L : 0, y2 - 1, radius: 1.3, .chapter, dashed: true) }
            } else if at >= 2 {
                // where the number was, and its hop to the closer end, how far written over it
                let end = P.up ? L : 0
                pic.dot("p2was", at: x2, y2, radius: 0.35, .ink3, over: true)
                pic.hop("hop", from: x2, to: end, row: y2, height: 2.5)
                pic.label("hopw", "\(abs(P.R - P.n))", small.colour(.chapter), .above, edge: y2 - 2.6, along: (x2 + end) / 2)
                pic.dot("p2", at: end, y2, radius: 0.4, .chapter, over: true)
            }
        }

        var boxes: [WorkBox] = []
        if at >= 2 {
            // the record: 347 ≈ [350], the numbers written tight (call of 3 Nov)
            let right = Record.width(.n(P.n)), row = 1.0, ow = Record.opWidth("≈")
            Record.tight(&rec, "num", P.n, right: right, row: row)
            rec.word("approx", "≈", at: right + ow / 2, row, Record.maths)
            if at == 2 {
                let bw = Record.boxWidth(cells: 3, commas: true)
                rec.answerBox("R", right: right + ow + bw, mid: row, per: 2, cells: 1, commas: true, word: bw)
                boxes = rec.boxes
            } else {
                let end = right + ow + Record.width(.n(P.R))
                Record.tight(&rec, "R", P.R, right: end, row: row, .chapter)
                // the place's digit underlined and the next ringed where they stand in the tight number; the rule beside
                let text = Array(String(P.n)), font = PaperText.font(Sketch.maths, .medium, digits: true)
                func w(_ s: String) -> Double { PaperText.width(s, font) / Paper.cell }
                let inkRight = right - Record.width(.n(P.n)) / 2 + w(String(text)) / 2
                func mid(_ place: Int) -> Double {
                    let i = text.count - 1 - place
                    return inkRight - w(String(text[(i + 1)...])) - w(String(text[i])) / 2 + 0.08
                }
                let kp = P.to == 10 ? 1 : 2
                rec.rule("under", from: mid(kp) - 0.5, to: mid(kp) + 0.5, row: row + 1, .chapter)
                rec.ring("next", col: mid(kp - 1) - 0.7, row: row - 1.2, w: 1.4, h: 2.4)
                rec.word("rule", P.rule, at: end + 2, row, Self.small, anchor: UnitPoint(x: 0, y: 0.5))
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes)
    }

    /// Brackets under line 2 from each end to where the number is, how far written under each, kept clear of each other.
    private static func brackets(_ p: inout GridPen, _ P: Round3.Parts, _ x2: Double) {
        let by = line2 + 3, L = length, f = PaperText.font(Sketch.small, .medium, digits: true)
        let sL = "\(P.rest) to \(P.T)", sR = "\(P.to - P.rest) to \(P.hi)"
        let wL = PaperText.width(sL, f) / Paper.cell / 2 + 0.3, wR = PaperText.width(sR, f) / Paper.cell / 2 + 0.3
        p.line("brL", [(0, by - 0.6), (0, by), (x2, by), (x2, by - 0.6)], .chapter)
        p.line("brR", [(x2, by - 0.6), (x2, by), (L, by), (L, by - 0.6)], .chapter)
        var cL = max(wL - 0.5, x2 / 2), cR = min(L - wR + 0.5, (x2 + L) / 2)
        if cR - wR < cL + wL + 0.6 { let m = (cL + wL + cR - wR) / 2; cL = m - wL - 0.3; cR = m + wR + 0.3 }
        p.label("brLw", sL, small.colour(.chapter), .below, edge: by, along: cL)
        p.label("brRw", sR, small.colour(.chapter), .below, edge: by, along: cR)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Round3.Parts(s.numbers), B = Self.block, L = Self.length, x2 = Double(P.rest) / Double(P.to) * L
        switch stage(s) {
        case 0:
            return Hands(tap: { q in
                guard q.y > Self.line1 - 3.5, q.y < Self.line1 + 2, q.x > -0.5, q.x < L + 0.5 else { return nil }
                let b = Double(min(9, max(0, Int((q.x / B).rounded(.down)))))
                return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
            })
        case 1:
            // the point on line 2, a square at a time; let go on (or near) an end, or past halfway, and it goes there
            let now = s.h("at") ?? x2
            return Hands(grab: { q in abs(q.x - now) < 2.5 && abs(q.y - Self.line2) < 3 ? ["grab": 1, "at": now] : nil },
                         drag: { q, _ in ["grab": 1, "at": min(L, max(0, q.x.rounded()))] },
                         release: { h in
                             let a = h["at"] ?? x2
                             if a > 1, a < L - 1, abs(a - x2) < 1.5 { return HandMove(hand: [:], missHand: [:], set: [], check: false) }
                             let end: Double = a <= 1 ? 0 : a >= L - 1 ? 10 : a > L / 2 ? 10 : a < L / 2 ? 0 : (a > x2 ? 10 : 0)
                             return HandMove(hand: ["at": end * B], missHand: [:], set: [("x", end)], check: true)
                         })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Round3.Parts(s.numbers), B = Self.block, L = Self.length
        switch stage(s) {
        case 0: return [.tap(.picture(CGPoint(x: (Double(P.block) + 0.5) * B, y: Self.line1 - 1)))]
        case 1: return [.drag(from: CGPoint(x: s.h("at") ?? Double(P.rest) / Double(P.to) * L, y: Self.line2), to: CGPoint(x: P.up ? L : 0, y: Self.line2))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Round3.Parts(s.numbers)
        switch stage(s) {
        case 0:
            let b = Double((P.block + 3) % 10)
            return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
        case 1:
            let end: Double = P.up ? 0 : 10
            return HandMove(hand: ["at": end * Self.block], missHand: [:], set: [("x", end)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? { stage(s) == 2 ? ["R": Double(Round3.Parts(s.numbers).other)] : nil }
}
