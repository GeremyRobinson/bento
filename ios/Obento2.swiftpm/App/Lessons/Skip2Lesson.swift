import SwiftUI

/// Skip counting on the paper, as in the preview (design/prototype/grade2-ch2.html, dSkip): one square is a tenth of a hop,
/// so a hop is always 10 squares, two blocks. A number line on a strong line, six marks 10 squares apart, small marks
/// inside each hop for its units (by 2 one in the middle, by 5 every 2 squares, by 10 or 100 every square). The first
/// three numbers under their marks, places for the other three. Drag the point from the first number to the second: it
/// snaps a unit at a time and the small hops count ("+5"); the jumps between the shown numbers draw in. Then hop on a whole
/// jump (the arc follows the finger) and write where you land in the box under the mark; the digits that changed light.
/// Back (a fold) runs right to left, the numbers falling.
///
/// The line, its hops and their labels are the record's (from the same corner), so a miss written over the box being
/// typed with the keys up clears them; the numbers stay the picture's, so the line being typed is the box and Check. Hand: "grab", "gx", "k" the small hops (the jump), "d" how far the point has gone (a hop).
@MainActor
struct Skip2Lesson: PaperLesson {
    static let LY = 7.0
    var liveKeys: Set<String> { ["k", "d"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    /// Keys up: the hop being written, from the number it starts on to the box, stays in the frame with the box.
    func keysFocus(_ s: PaperState) -> CGRect? {
        let P = Skip2.Parts(s.numbers), j = mark(at(s))
        guard j > 0 else { return nil }
        let a = min(X(P, j - 1), X(P, j)) - 3
        return CGRect(x: a, y: Self.LY - 4, width: 16, height: 7)
    }
    func blocksAt(_ s: PaperState) -> CGPoint? { CGPoint(x: Skip2.Parts(s.numbers).back ? 0 : 40, y: Self.LY + 6) }
    private func X(_ P: Skip2.Parts, _ j: Int) -> Double { P.back ? 50 - 10 * Double(j) : 10 * Double(j) }
    /// The mark being hopped to or written under (3–5), or 0.
    private func mark(_ st: Int) -> Int { st >= 1 && st <= 6 ? 3 + (st - 1) / 2 : 0 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Skip2.Parts(s.numbers), st = at(s), j = mark(st), LY = Self.LY, sg = Double(P.s)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed, hopping = st == 1 || st == 3 || st == 5
        // the line, its marks, the units inside each hop
        rec.line("ln", [(-2, LY), (52, LY)])
        var ticks: [(CGPoint, CGPoint)] = []
        for m in 0...5 {
            ticks.append((rec.P(X(P, m), LY - 1.5), rec.P(X(P, m), LY)))
            if m < 5 && P.units > 1 { for u in 1..<P.units { let x = X(P, m) + sg * Double(u) * P.ul; ticks.append((rec.P(x, LY - 0.7), rec.P(x, LY))) } }
        }
        rec.sketch.segments("tk", ticks, .ink, width: Sketch.stroke)
        // the first jump's small hops, counted; then the jumps between the numbers
        let k = st == 0 ? Int(s.h("k") ?? 0) : P.units
        if P.units > 1 {
            for u in 0..<k {
                let a = X(P, 0) + sg * Double(u) * P.ul, b = a + sg * P.ul
                if st == 0 { live.hop("ua\(u)", from: a, to: b, row: LY - 0.2, height: min(1.2, P.ul * 0.45)) } else { rec.hop("ua\(u)", from: a, to: b, row: LY - 0.2, height: min(1.2, P.ul * 0.45)) }
            }
        }
        let landed = st == 0 ? 0 : st == 7 ? 5 : hopping ? j - 1 : j
        if st > 0 {
            for m in 1...max(2, landed) {
                rec.hop("ja\(m)", from: X(P, m - 1), to: X(P, m), row: LY - 0.2, height: 2.6)
                rec.label("jl\(m)", "\(P.op)\(P.by)", KK.lit, .above, edge: LY - 3, along: (X(P, m - 1) + X(P, m)) / 2)
            }
        }
        // the point: dragged a unit at a time (the jump), or a whole hop, the arc following it
        var px = X(P, landed)
        if st == 0 { px = X(P, 0) + sg * Double(k) * P.ul }
        if hopping && held { let d = s.h("d") ?? 0; px = X(P, j - 1) + sg * d; if d > 0.3 { live.hop("live", from: X(P, j - 1), to: px, row: LY - 0.2, height: 2.6 * d / 10) } }
        if held { live.dot("pt", at: px, LY, radius: 0.75) } else { pic.dot("pt", at: px, LY, radius: 0.55, over: true) }
        if st == 0 && held { live.reads(k > 0 ? "\(P.op)\(k * P.uv)" : "") }
        // the numbers under their marks; boxes under the rest; a written number's changed digits lit
        for m in 0...5 {
            let v = P.v(m), str = Array("\(v)"), w = Record.width(.n(v)), x0 = X(P, m) - w / 2
            let written = m < 3 || st > 2 * (m - 3) + 2
            if written {
                if m < 3 { pic.word("n\(m)", "\(v)", at: X(P, m), LY + 2, KK.maths) }
                else {
                    let prev = Array(String("\(P.v(m - 1))".reversed()).padding(toLength: str.count, withPad: " ", startingAt: 0).reversed())
                    N2.number(&pic, "w\(m)", v, x: x0, row: LY + 2) { prev[$0] != str[$0] ? .chapter : .ink }
                }
            } else if st == 2 * (m - 3) + 2 {
                let bw = Record.boxWidth(cells: 3, commas: true), right = X(P, m) + (bw / 2).rounded(.up)
                rec.answerBox("b\(m)", right: right, mid: LY + 2, per: 2, cells: 1, commas: true, word: bw)
            } else {
                let bw = Record.boxWidth(cells: 3, commas: true), left = X(P, m) - (bw / 2).rounded(.down)
                pic.sketch.box("bx\(m)", pic.R(left, LY + 1, bw, 2), .ink3, width: Sketch.stroke, dashed: true)
            }
        }
        // hints: a first miss rings the hop, a second the mark it lands on (or the number)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st == 0 || (!hopping && st < 7) {
            let a = st == 0 ? 0 : j - 1, lo = min(X(P, a), X(P, a + 1)), x1 = st == 0 ? 1 : j
            if ring { KK.hintBox(&rec, "hr", x: lo, y: LY - 3.5, w: 10, h: 3.5) }
            if spot { if st == 0 { rec.circle("sp", at: X(P, x1), LY, radius: 1, .chapter, dashed: true) } else { A1.note(&rec, "sp", "\(P.v(j))", x: X(P, j), y: LY + 4.5, centred: true) } }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Skip2.Parts(s.numbers), st = at(s), j = mark(st), LY = Self.LY, sg = Double(P.s)
        if st == 0 {
            let x0 = X(P, 0)
            return Hands(
                grab: { q in abs(q.x - x0) <= 2.5 && abs(q.y - LY) <= 2.5 ? ["grab": 1, "gx": q.x, "k": 0] : nil },
                drag: { q, held in
                    var h = held
                    let d = max(0, min(10, sg * (q.x - (held["gx"] ?? q.x))))
                    h["k"] = Double(Int((d / P.ul).rounded())); return h
                },
                release: { held in
                    let k = Int(held["k"] ?? 0)
                    return k > 0 ? HandMove(hand: [:], missHand: [:], set: [("j", Double(k))], check: true) : HandMove(hand: [:])
                })
        }
        guard st == 1 || st == 3 || st == 5 else { return nil }
        let x0 = X(P, j - 1)
        return Hands(
            grab: { q in abs(q.x - x0) <= 2.5 && abs(q.y - LY) <= 2.5 ? ["grab": 1, "gx": q.x, "d": 0] : nil },
            drag: { q, held in var h = held; h["d"] = max(0, min(10, sg * (q.x - (held["gx"] ?? q.x)))); return h },
            release: { held in (held["d"] ?? 0) >= 5 ? HandMove(hand: [:], missHand: [:], set: [("p\(j)", 1)], check: true) : HandMove(hand: [:]) })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Skip2.Parts(s.numbers), st = at(s), LY = Self.LY
        if st == 0 { return [.drag(from: CGPoint(x: X(P, 0), y: LY), to: CGPoint(x: X(P, 1), y: LY))] }
        if st == 1 || st == 3 || st == 5 { let j = mark(st); return [.drag(from: CGPoint(x: X(P, j - 1), y: LY), to: CGPoint(x: X(P, j), y: LY))] }
        return []
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Skip2.Parts(s.numbers)
        guard at(s) == 0, P.units > 1 else { return nil }
        return HandMove(hand: [:], missHand: [:], set: [("j", Double(P.units - 1))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Skip2.Parts(s.numbers), st = at(s)
        guard st == 2 || st == 4 || st == 6 else { return nil }
        let j = mark(st)
        return ["b\(j)": Double(P.slips(j).first { $0.0 != P.v(j) }?.0 ?? P.v(j) + 1)]
    }
}
