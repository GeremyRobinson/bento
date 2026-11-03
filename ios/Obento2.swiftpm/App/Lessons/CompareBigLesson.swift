import SwiftUI

/// Comparing big numbers on the paper, as in the preview (design/prototype/grade4-ch1.html): the place chart with as many
/// columns as the longer number, 2-square disks, one frame to a column; the first number's disks and digits on top, the
/// second's (striped) under them. When the lengths differ the second starts written under the first's first digit, as
/// children write it: slide it a column at a time until ones are under ones (its disks then draw in). Tap the first
/// place that differs, from the left: its column lights. Tap <, = or > (three blocks at the chart's right, between the
/// two numbers); done, the sign is written there in the chapter's colour.
@MainActor
struct CompareBigLesson: PaperLesson {
    /// The names from row 0; the first number's frames from 3, its digits on 9; the second's frames from 11, its digits
    /// on 17; the columns' lines down to 19.
    static let top = 0.0, yA = 3.0, dA = 9.0, yB = 11.0, dB = 17.0, bottom = 19.0

    var liveKeys: Set<String> { ["at"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func chart(_ P: CompareBig.Parts) -> PlaceChart { PlaceChart(n: P.n, c: 2, pr: 1, y0: Self.yA) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = CompareBig.Parts(s.numbers), ch = chart(P), at = stage(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let placed = !P.slides || at >= 2, lit = at >= 3 ? P.first : nil
        if let lit { pic.fill("lit\(lit)", col: ch.colX(lit), row: Self.top, w: ch.cw, h: Self.bottom - Self.top, .tint(0.2)) }
        ch.draw(&pic, "ch", bands: [(Self.yA, { _ in 1 }), (Self.yB, { _ in 1 })], top: Self.top, bottom: Self.bottom, lit: lit)
        for pw in 0..<P.n {
            for j in 0..<BigNumbers.digit(P.A, pw) { ch.disk(&pic, "a\(pw).\(j)", at: ch.slot(pw, j, band: Self.yA)) }
            if placed { for j in 0..<BigNumbers.digit(P.B, pw) { ch.disk(&pic, "b\(pw).\(j)", at: ch.slot(pw, j, band: Self.yB), striped: true) } }
        }
        // the digits: one per column, centred; the comma on the line between the thousands and the hundreds
        let m = Record.maths
        for pw in 0..<P.lA { pic.word("da\(pw)", "\(BigNumbers.digit(P.A, pw))", at: ch.mid(pw), Self.dA, m.colour(lit == pw ? .chapter : .ink)) }
        if P.lA > 3 { pic.word("dac", ",", at: ch.colX(2), Self.dA, m) }
        // the second number, where it's been slid to (it follows the finger while held)
        let start = placed ? P.aligned : P.start, held = s.grabbed
        let col = held ? Int((s.h("at") ?? Double(start)).rounded()) : start
        func bx(_ j: Int) -> Double { ch.x0 + Double(col + j) * ch.cw + ch.cw / 2 }
        for j in 0..<P.lB {
            let pw = P.lB - 1 - j, colour: Sketch.Colour = lit == pw && placed ? .chapter : .ink
            if held { live.word("db\(j)", "\(BigNumbers.digit(P.B, pw))", at: bx(j), Self.dB, m.colour(colour)) }
            else { pic.word("db\(j)", "\(BigNumbers.digit(P.B, pw))", at: bx(j), Self.dB, m.colour(colour)) }
            if pw == 3 {
                if held { live.word("dbc", ",", at: bx(j) + ch.cw / 2, Self.dB, m) } else { pic.word("dbc", ",", at: bx(j) + ch.cw / 2, Self.dB, m) }
            }
        }
        if held {
            let k = P.n - 1 - (col + P.lB - 1), d = BigNumbers.digit(P.B, 0)
            live.reads(k >= 0 ? "\(d) under the \(BigNumbers.places[k])" : "\(d) past the ones")
        }
        // which way it has to go: an arrow beside it, pencil grey
        if at == 1, !held {
            let y = Self.dB
            if P.aligned > P.start { let x = bx(P.lB - 1) + 3; pic.line("arr", [(x, y), (x + 2, y)], .ink3); pic.line("arrh", [(x + 1.3, y - 0.7), (x + 2, y), (x + 1.3, y + 0.7)], .ink3) }
            else { let x = bx(0) - 3; pic.line("arr", [(x, y), (x - 2, y)], .ink3); pic.line("arrh", [(x - 1.3, y - 0.7), (x - 2, y), (x - 1.3, y + 0.7)], .ink3) }
            // a hint: where its ones go, ringed under the ones
            if s.on("ring") { pic.circle("ring", at: ch.mid(0), Self.dB, radius: 1.6, .chapter, dashed: true) }
        }
        // a hint on the place: the column to look at, from the left
        if at == 2, s.on("ring"), let fd = P.first {
            pic.sketch.box("ring", pic.R(ch.colX(fd) + 0.5, Self.top + 0.5, ch.cw - 1, Self.bottom - Self.top - 1), .chapter, width: Sketch.stroke, dashed: true)
        }
        // the sign: the three blocks at the chart's right between the two numbers, then the one that's right
        let sx = ch.right + 2
        if at == 3 {
            let bad = s.h("bad").map { Int($0.rounded()) }
            for (k, y) in [(0, Self.dA - 1), (1, (Self.dA + Self.dB) / 2 - 1), (2, Self.dB - 1)] {
                let r = pic.R(sx, y, 3, 2), wrong = bad == k
                pic.sketch.block("sg\(k)\(wrong)", r, wrong ? Sketch.Block(stroke: Bars.red, text: Bars.red) : .main, centred: CompareBig.Parts.signs[k], size: Sketch.maths)
            }
        } else if at >= 4 {
            pic.word("sign", P.signText, at: sx + 1.5, (Self.dA + Self.dB) / 2, m.colour(.chapter))
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch,
                            extent: CGRect(x: 0, y: 0, width: (sx + 3) * Paper.cell, height: Self.bottom * Paper.cell))
    }

    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }

    func hands(_ s: PaperState) -> Hands? {
        let P = CompareBig.Parts(s.numbers), ch = chart(P)
        switch stage(s) {
        case 1:
            // the second number, held anywhere along its digits: it moves a column at a time
            return Hands(
                grab: { q in
                    let x0 = ch.x0 + Double(P.start) * ch.cw, x1 = x0 + Double(P.lB) * ch.cw
                    guard abs(q.y - Self.dB) <= 2, q.x >= x0 - 2, q.x <= x1 + 2 else { return nil }
                    return ["grab": 1, "fx": q.x, "at": Double(P.start)]
                },
                drag: { q, h in
                    var h = h
                    h["at"] = Double(max(-1, min(P.n, P.start + Int(((q.x - (h["fx"] ?? 0)) / ch.cw).rounded()))))
                    return h
                },
                release: { h in
                    let at = h["at"] ?? Double(P.start)
                    // let go where it started: nothing happened
                    if Int(at.rounded()) == P.start { return HandMove(hand: [:], missHand: [:], set: [], check: false) }
                    return HandMove(hand: [:], missHand: [:], set: [("x", at)], check: true)
                })
        case 2:
            // a column tapped: the place it is
            return Hands(tap: { q in
                guard q.y >= Self.top - 0.5, q.y <= Self.bottom + 0.5, let pw = ch.place(at: q.x) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("x", Double(pw))], check: true)
            })
        case 3:
            let sx = ch.right + 2
            return Hands(tap: { q in
                guard q.x >= sx - 0.5, q.x <= sx + 3.5 else { return nil }
                for (k, y) in [(0, Self.dA - 1), (1, (Self.dA + Self.dB) / 2 - 1), (2, Self.dB - 1)] where q.y >= y - 0.3 && q.y <= y + 2.3 {
                    return HandMove(hand: ["pick": Double(k)], missHand: ["bad": Double(k)], set: [("s", Double(k))], check: true)
                }
                return nil
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = CompareBig.Parts(s.numbers), ch = chart(P)
        switch stage(s) {
        case 1:
            let from = CGPoint(x: ch.x0 + (Double(P.start) + 0.5) * ch.cw, y: Self.dB)
            return [.drag(from: from, to: CGPoint(x: from.x + Double(P.aligned - P.start) * ch.cw, y: Self.dB))]
        case 2: return P.first.map { [.tap(.picture(CGPoint(x: ch.mid($0), y: Self.dA)))] } ?? []
        case 3:
            let ys = [Self.dA, (Self.dA + Self.dB) / 2, Self.dB]
            return [.tap(.picture(CGPoint(x: ch.right + 3.5, y: ys[P.sign])))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = CompareBig.Parts(s.numbers)
        switch stage(s) {
        case 1: return HandMove(hand: [:], missHand: [:], set: [("x", Double(P.aligned + (P.aligned > P.start ? 1 : -1)))], check: true)
        case 2:
            // a place further right, where the digits are the same or differ later
            guard let fd = P.first else { return nil }
            return HandMove(hand: nil, missHand: nil, set: [("x", Double(fd > 0 ? fd - 1 : fd + 1))], check: true)
        case 3:
            // the first digits compared, or turned round
            let k = P.sign == 1 ? 2 : 2 - P.sign
            return HandMove(hand: ["pick": Double(k)], missHand: ["bad": Double(k)], set: [("s", Double(k))], check: true)
        default: return nil
        }
    }
}
