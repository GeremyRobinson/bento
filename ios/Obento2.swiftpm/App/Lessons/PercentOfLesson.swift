import SwiftUI

/// Percent of a number on the paper, as in the preview (design/prototype/grade6-ch1.html, dPctOf): one square is 2.5%, so
/// the bar is 40 squares long and 4 tall, W at its right end, a small 0%–100% scale over it. Cut with the ruler under it
/// (it snaps to tenths, 4 squares, and quarters, 10; the cuts dashed across the bar, "tenths: 10 blocks"), Cut commits;
/// write one block (`10% of 80 = [ ]`), every block then shows it; tap blocks to shade p% ("30%" under the bar), Check;
/// write `30% of 80 = 3 × 8 = [ ]`.
@MainActor
struct PercentOfLesson: PaperLesson {
    static let x0 = 0.0, y0 = 3.0, bh = 4.0, bw = Double(PercentOf.bar)
    static var ry: Double { y0 + bh + 1.5 }
    var liveKeys: Set<String> { ["cw", "grab"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func cw(_ s: PaperState, _ P: PercentOf.Parts) -> Double { stage(s) >= 2 ? Double(P.width) : (s.h("cw") ?? Self.bw) }
    /// The blocks shaded: as they're tapped, then kept.
    private func shaded(_ s: PaperState) -> Set<Int> {
        let bits = stage(s) == 3 ? Int(s.h("taps") ?? 0) : Int(s.run.kept["shaded"] ?? 0)
        return Set((0..<10).filter { bits & (1 << $0) != 0 })
    }
    func recordRow(_ n: Numbers) -> Double? { Self.y0 + Self.bh + 3 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PercentOf.Parts(s.numbers), at = stage(s), cut = at >= 2, done = at >= 5
        let x0 = Self.x0, y0 = Self.y0, bh = Self.bh, bw = Self.bw, w = cw(s, P), blocks = Int(bw / w)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // the 0%–100% scale over the bar
        pic.sketch.segments("sc", (0...10).map { t in (pic.P(x0 + 4 * Double(t), y0 - (t % 5 == 0 ? 1 : 0.5)), pic.P(x0 + 4 * Double(t), y0)) }, .ink, width: Sketch.stroke)
        pic.label("s0", "0%", R6.small, .above, edge: y0 - 1, along: x0)
        pic.label("s100", "100%", R6.small, .above, edge: y0 - 1, along: x0 + bw)
        let on = shaded(s)
        for k in on.sorted() where cut { pic.fill("sh\(k)", col: x0 + Double(k) * w, row: y0, w: w, h: bh, Bars.shade) }
        pic.sketch.box("bar", pic.R(x0, y0, bw, bh), .chapter, width: Sketch.stroke)
        pic.label("barn", "\(P.W)", R6.maths, .right, edge: x0 + bw, along: y0 + bh / 2)
        var actions: [String] = []
        if !cut {
            // the ruler under the bar: its handle sets one block's length; the cuts it would make, dashed
            let y = Self.ry
            live.line("ruler", [(x0, y - 0.6), (x0, y), (x0 + w, y), (x0 + w, y - 0.6)], .chapter)
            R6.handle(&live, "rh", x0 + w, y, held: s.grabbed)
            if w < bw {
                for k in 1..<blocks { live.line("dc\(k)", [(x0 + Double(k) * w, y0 - 0.6), (x0 + Double(k) * w, y0 + bh + 0.6)], .ink2, dashed: true) }
                let ro = "\(w == 4 ? "tenths" : "quarters"): \(blocks) blocks"
                live.word("rro", ro, at: x0, y + 1.6, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { live.reads(ro) }
            }
            // a hint: the scale ringed; a second miss, where one block of the right size ends
            if at == 1, s.on("ring") { R6.ring(&pic, "ring", x: x0 - 1.8, y: y0 - 2.4, w: bw + 2 + R6.width("\(P.W)", R6.maths) + 1.5, h: bh + 2.4) }
            if at == 1, s.on("spot") { pic.line("spot", [(x0 + Double(P.width), y0 - 1.5), (x0 + Double(P.width), y0 + bh + 1.5)], .chapter, dashed: true) }
            if at == 1 { actions = ["Cut"] }
        } else {
            pic.sketch.segments("cuts\(P.width)", (1..<blocks).map { k in (pic.P(x0 + Double(k) * w, y0), pic.P(x0 + Double(k) * w, y0 + bh)) }, .chapter, width: Sketch.stroke)
            if at >= 3 { for k in 0..<blocks { pic.word("bv\(k)", "\(P.part)", at: x0 + (Double(k) + 0.5) * w, y0 + bh / 2, R6.maths.colour(.chapter)) } }
            if at == 3 {
                pic.word("pro\(on.count)", "\(on.count * P.base)%", at: x0, y0 + bh + 1.4, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
                actions = ["Check"]
                if s.on("ring") { R6.ring(&pic, "ring", x: x0 - 1.8, y: y0 - 2.4, w: bw + 2 + R6.width("\(P.W)", R6.maths) + 1.5, h: bh + 2.4) }
                if s.on("spot") { let x = x0 + Double(P.p) * bw / 100; pic.line("spot", [(x, y0 - 1.5), (x, y0 + bh + 1.5)], .chapter, dashed: true) }
            }
            if at >= 4 { pic.label("bshade", "\(P.p)%", R6.lit, .below, edge: y0 + bh, along: x0 + Double(P.p) * bw / 200) }
            if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: x0, y: y0, w: w, h: bh) }
            if at == 2 && s.on("spot") { pic.label("spot", "\(P.W) ÷ \(blocks)", R6.lit, .below, edge: y0 + bh, along: x0 + w / 2) }
            if at == 4 && s.on("ring") { R6.ring(&pic, "ring", x: x0, y: y0, w: Double(P.blocks) * w, h: bh) }
            if at == 4 && s.on("spot") { for k in 0..<P.blocks { pic.label("cnt\(k)", "\(k + 1)", R6.lit, .above, edge: y0, along: x0 + (Double(k) + 0.5) * w) } }
            // the record
            let one: M7.Tok = at == 2 ? .box("x", cells: String(P.part).count) : .n(P.part, .chapter)
            M7.row(&rec, "r1", [.t("\(P.base)%"), .w("of"), .n(P.W), .op("="), one], x: 0, line: 1)
            if at >= 4 {
                let ans: M7.Tok = done ? .n(P.R, .chapter) : .box("x", cells: String(P.R).count)
                M7.row(&rec, "r2", [.t("\(P.p)%"), .w("of"), .n(P.W), .op("="), .n(P.blocks), .op("×"), .n(P.part), .op("="), ans], x: 0, line: 4)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: actions,
                            extent: at <= 1 ? pic.R(0, 0, bw + 4, Self.ry + 2.5) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = PercentOf.Parts(s.numbers), at = stage(s), x0 = Self.x0, y0 = Self.y0, bh = Self.bh, bw = Self.bw
        switch at {
        case 1:
            let w = cw(s, P)
            func snap(_ x: Double) -> Double { [4.0, 10, bw].min { abs($0 - x) < abs($1 - x) } ?? bw }
            return Hands(
                grab: { q in q.y >= y0 - 1 && q.y <= Self.ry + 2 && q.x >= x0 && q.x <= x0 + bw + 2 ? ["grab": 1, "cw": snap(max(1, min(bw, q.x - x0)))] : nil },
                drag: { q, _ in ["grab": 1, "cw": snap(max(1, min(bw, q.x - x0)))] },
                release: { h in HandMove(hand: ["cw": h["cw"] ?? w], missHand: nil) },
                actions: ["Cut": { HandMove(hand: nil, missHand: nil, set: [("x", w)], check: true) }])
        case 3:
            let bits = Int(s.h("taps") ?? 0), w = Double(P.width), n = Int(bw / w)
            return Hands(
                tap: { q in
                    guard q.y >= y0, q.y <= y0 + bh, q.x >= x0, q.x < x0 + bw else { return nil }
                    let k = min(n - 1, Int((q.x - x0) / w))
                    return HandMove(hand: ["taps": Double(bits ^ (1 << k))], missHand: nil)
                },
                actions: ["Check": { HandMove(hand: nil, missHand: nil, set: [("x", Double(bits.nonzeroBitCount))], keep: ["shaded": Double(bits)], check: true) }])
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = PercentOf.Parts(s.numbers), at = stage(s), y0 = Self.y0, bh = Self.bh, w = Double(P.width)
        switch at {
        case 1:
            let now = cw(s, P)
            return (now == w ? [] : [.drag(from: CGPoint(x: Self.x0 + now, y: Self.ry), to: CGPoint(x: Self.x0 + w, y: Self.ry))]) + [.tap(.action("Cut"))]
        case 3:
            let on = shaded(s)
            let flips = (0..<Int(Self.bw / w)).filter { ($0 < P.blocks) != on.contains($0) }
            return flips.map { .tap(.picture(CGPoint(x: Self.x0 + (Double($0) + 0.5) * w, y: y0 + bh / 2))) } + [.tap(.action("Check"))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = PercentOf.Parts(s.numbers)
        switch stage(s) {
        case 1:
            // the other block: quarters for a tenths percent (50% excepted: quarters fit it), tenths for a quarters one
            let w = P.base == 25 ? 4.0 : P.p == 50 ? Self.bw : 10
            return HandMove(hand: ["cw": w], missHand: nil, set: [("x", w)], check: true)
        case 3:
            // one block too many
            let bits = (1 << (P.blocks + 1)) - 1
            return HandMove(hand: ["taps": Double(bits)], missHand: nil, set: [("x", Double(P.blocks + 1))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = PercentOf.Parts(s.numbers)
        switch stage(s) {
        case 2: return ["x": Double(P.W * P.base)]
        case 4: return ["x": Double(P.W - P.R)]
        default: return nil
        }
    }

    func messageRows(_ n: Numbers) -> Int { 1 }
}
