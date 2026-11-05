import SwiftUI

/// Elapsed time on the paper, as in the preview (design/prototype/grade3-ch6.html, dElapsed, dEnds): one square is 5 minutes,
/// so an hour is 12 squares. A timeline from the o'clock before the start to the o'clock after the end, a tick a square
/// (longer each half hour and hour), the o'clocks named under it (a.m. or p.m. on the first and at noon), the start and end
/// points named with their times. Hop to the next o'clock (one hop stretching a square at a time, "20 min" over it), hop the
/// whole hours (hops of 12 squares, "1 h"), hop the minutes left; write `20 min + 1 h + 15 min = [1] h [35] min`. When the two
/// minute hops make 60 or more they slide down under the line, end to end, and 60 of them close into "1 h". When does it end:
/// the story on the top rows; hop to the o'clock ("15 min · 35 to go"), hop the rest, write `[4]:[35] p.m.`.
///
/// Hand: "grab", "n" the hop being made (squares, or hours), kept as the hop's own after a miss.
@MainActor
struct Elapsed3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    func told(_ s: PaperState) -> String? { let P = Elapsed3.Parts(s.numbers); return P.ends ? P.story : nil }

    @MainActor struct Geo {
        let P: Elapsed3.Parts, rows: Int, LY: Double
        /// Squares to 5 minutes: the biggest of 3, 2, 1 that keeps the line within 70 squares (so it shows at 75%).
        let s: Double
        init(_ n: Numbers) {
            P = Elapsed3.Parts(n)
            s = P.W * 3 <= 70 ? 3 : P.W * 2 <= 70 ? 2 : 1
            rows = P.ends ? A2.storyRows([P.story], width: max(44, Double(P.W) * s + 4)).count : 0
            LY = P.ends ? 2 * Double(rows) + 6 : 6
        }
        var width: Double { max(44, Double(P.W) * s + 4) }
        var BY: Double { LY + 5 }
        var RY: Double { LY + (P.trade && !P.ends ? 11 : 7) }
        func x(_ t: Int) -> Double { Double(P.X(t)) * s }
        /// The hop of each stage: where it starts, its squares a hop, how many it may make, what its box holds a hop.
        func hop(_ st: Int) -> (x0: Double, step: Double, max: Int, per: Int)? {
            let W = P.W
            if P.ends {
                switch st {
                case 0: return (x(P.start), s, W - P.X(P.start), 5)
                case 1: return (x(P.H1 * 60), s, W - P.X(P.H1 * 60), 5)
                default: return nil
                }
            }
            switch st {
            case 0: return (x(P.start), s, W - P.X(P.start), 5)
            case 1: return (x(P.H1 * 60), 12 * s, (W - P.X(P.H1 * 60)) / 12, 1)
            case 2: return (x(P.H2 * 60), s, W - P.X(P.H2 * 60), 5)
            default: return nil
            }
        }
        var box: [String] { P.ends ? ["a", "c"] : ["a", "b", "c"] }
        /// The right hops of each stage.
        func want(_ st: Int) -> Int { P.ends ? [P.m1 / 5, P.rest / 5][st] : [P.m1 / 5, P.h, P.m3 / 5][st] }
    }

    /// An arc from x1 to x2 over the line, its length named over it.
    private func stretch(_ pen: inout GridPen, _ id: String, _ x1: Double, _ x2: Double, _ y: Double, _ name: String?) {
        guard x2 > x1 else { return }
        let ph = max(1, min(3.5, (x2 - x1) * 0.3))
        pen.hop(id + "a", from: x1, to: x2, row: y, height: ph)
        if let name { pen.word(id + "t", name, at: (x1 + x2) / 2, y - ph - 1.3, KK.lit) }
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let g = Geo(s.numbers), st = at(s)
        guard (g.P.ends && st >= 2) || (!g.P.ends && st >= 3) else { return nil }
        return CGPoint(x: EG2.ceil5(M7.width(recToks(g, right: false)) + 1), y: g.RY - 1)
    }
    private func recToks(_ g: Geo, right: Bool) -> [M7.Tok] {
        let P = g.P, c: Sketch.Colour = .chapter
        if P.ends {
            let tail: [M7.Tok] = [.w(Ms3.ampm(P.end))]
            return (right ? [.t("\(P.EH):\(Ms3.two(P.EM))", c)] : [.box("x", cells: 2), .op(":"), .box("y", cells: 2)]) + tail
        }
        let head: [M7.Tok] = [.n(P.m1), .w("min"), .op("+"), .n(P.h), .w("h"), .op("+"), .n(P.m3), .w("min"), .op("=")]
        return head + (right ? [.n(P.th, c), .w("h", c), .n(P.tm, c), .w("min", c)] : [.box("h", cells: 1), .w("h"), .box("m", cells: 2), .w("min")])
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = Geo(s.numbers), P = g.P, st = at(s), LY = g.LY, W = Double(P.W) * g.s, sc = g.s
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if P.ends { A2.tell(&pic, [P.story], width: g.width) }
        // the timeline: a tick a square, longer each half hour and hour; the o'clocks named under it
        pic.rule("tl", from: 0, to: W, row: LY)
        var tk: [(CGPoint, CGPoint)] = []
        for j in 0...P.W { tk.append((pic.P(Double(j) * sc, LY), pic.P(Double(j) * sc, LY - (j % 12 == 0 ? 1.6 : j % 6 == 0 ? 1 : 0.6)))) }
        pic.sketch.segments("tlt", tk, .ink, width: Sketch.stroke)
        var t = P.T0
        while t <= P.T3 {
            let name = t == P.T0 || t == 720 ? "\(Ms3.clk(t)) \(Ms3.ampm(t))" : Ms3.clk(t)
            pic.word("on\(t)", name, at: g.x(t), LY + 1.2, Self.small)
            t += 60
        }
        pic.dot("ps", at: g.x(P.start), LY, radius: 0.45, .ink)
        pic.word("pst", Ms3.clk(P.start), at: g.x(P.start), LY + 3, Self.small)
        if !P.ends || st >= 2 {
            pic.dot("pe", at: g.x(P.end), LY, radius: 0.45, P.ends ? .chapter : .ink)
            if !P.ends { pic.word("pet", Ms3.clk(P.end), at: g.x(P.end), LY + 3, Self.small) }
        }
        // the hops made, each named over its arc; the one being made follows the finger
        let n = Int((s.h("n") ?? 0).rounded())
        func made(_ k: Int) -> Int { st == k ? n : st > k ? g.want(k) : 0 }
        let hops = g.box.count
        for k in 0..<hops {
            guard let h = g.hop(k), st >= k else { continue }
            let m = made(k), held = st == k && s.grabbed
            var pen = held ? live : pic
            if P.ends || k != 1 {
                stretch(&pen, "h\(k)", h.x0, h.x0 + Double(m) * h.step, LY, m > 0 ? "\(5 * m) min" : nil)
            } else {
                for i in 0..<m { stretch(&pen, "h\(k).\(i)", h.x0 + Double(i) * h.step, h.x0 + Double(i + 1) * h.step, LY, "1 h") }
            }
            if st == k {
                pen.dot("hh", at: h.x0 + Double(m) * h.step, LY, radius: held ? 0.7 : 0.55, .ink, over: true)
                if held { pen.reads(P.ends ? (k == 0 ? "\(5 * m) min · \(P.len - 5 * m) to go" : "\(5 * m) min") : k == 1 ? "\(m) h" : "\(5 * m) min") }
            }
            if held { live = pen } else { pic = pen }
        }
        // (See) the two minute hops slide down under the line, end to end; 60 minutes close into an hour
        if !P.ends && P.trade && st >= 3 {
            let a = Double(P.m1) / 5 * sc, b = Double(P.m3) / 5 * sc, BY = g.BY
            func rect(_ x: Double, _ y: Double, _ w: Double) -> [CGPoint] { [pic.P(x, y), pic.P(x + w, y), pic.P(x + w, y + 1), pic.P(x, y + 1)] }
            for (id, x0, x1, w) in [("ma", g.x(P.start), 0.0, a), ("mb", g.x(P.H2 * 60), a, b)] {
                let r0 = rect(x0, LY - 0.5, w)
                pic.sketch.from[id + "f"] = .fill(r0)
                pic.sketch.from[id + "o"] = .line(r0 + [r0[0]], width: Sketch.stroke, dashed: false)
                pic.fill(id + "f", col: x1, row: BY, w: w, h: 1, .tint(0.2))
                pic.sketch.box(id + "o", pic.R(x1, BY, w, 1), .ink, width: Sketch.stroke)
            }
            pic.sketch.delay = 0.7
            pic.line("mcut", [(12 * sc, BY - 0.6), (12 * sc, BY + 1.6)], .chapter)
            pic.word("m60", "1 h", at: 6 * sc, BY + 2.2, KK.lit)
            if P.m1 + P.m3 > 60 { pic.word("mre", "\(P.m1 + P.m3 - 60) min", at: (12 + Double(P.m1 + P.m3 - 60) / 10) * sc, BY + 2.2, KK.lit) }
            pic.sketch.delay = 0
        }
        // the record under the line
        let writing = P.ends ? st == 2 : st == 3, done = P.ends ? st >= 3 : st >= 4
        if writing { M7.row(&rec, "rec", recToks(g, right: false), x: 0, line: g.RY) }
        if done { M7.row(&pic, "rec", recToks(g, right: true), x: 0, line: g.RY) }
        // hints: a first miss rings the stretch to hop, a second the place to land
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if let h = g.hop(st) {
            let target = h.x0 + Double(g.want(st)) * h.step
            let to = P.ends ? (st == 0 ? g.x(P.H1 * 60) : W) : st == 0 ? g.x(P.H1 * 60) : st == 1 ? g.x(P.H2 * 60) : W
            if ring { KK.hintBox(&pic, "hr", x: h.x0, y: LY - 4, w: max(2, (st == 1 && !P.ends ? W - h.x0 : to - h.x0)), h: 5) }
            if spot { pic.circle("spot", at: target, LY, radius: 1.1, .chapter, dashed: true) }
        }
        if writing {
            if ring { KK.hintBox(&pic, "hr", x: 0, y: LY - 5, w: W, h: 5.5) }
            if spot { A1.note(&pic, "spot", P.ends ? Ms3.clk(P.end) : "\(P.m1) + \(P.m3) = \(P.m1 + P.m3) min", x: 0, y: g.RY - 2.6) }
        }
        let bottom = g.RY + 1
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, max(W, M7.width(recToks(g, right: false)) + 12), bottom))
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = Geo(s.numbers), st = at(s), LY = g.LY
        guard let h = g.hop(st) else { return nil }
        let n0 = Int((s.h("n") ?? 0).rounded()), box = g.box[st], want = g.want(st)
        return Hands(
            grab: { q in
                let end = h.x0 + Double(n0) * h.step
                guard abs(q.x - end) <= max(2, h.step / 2 + 0.5), abs(q.y - LY) <= 3 else { return nil }
                return ["grab": 1, "n": Double(n0)]
            },
            drag: { q, hh in var hh = hh; hh["n"] = Double(max(0, min(h.max, Int(((q.x - h.x0) / h.step).rounded())))); return hh },
            release: { hh in
                let n = Int((hh["n"] ?? 0).rounded())
                guard n > 0 else { return HandMove(hand: ["n": 0]) }
                _ = want
                return HandMove(hand: ["n": Double(n)], missHand: nil, set: [(box, Double(n * h.per))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = Geo(s.numbers), st = at(s)
        guard let h = g.hop(st) else { return [] }
        let n0 = Double(Int((s.h("n") ?? 0).rounded()))
        return [.drag(from: CGPoint(x: h.x0 + n0 * h.step, y: g.LY), to: CGPoint(x: h.x0 + Double(g.want(st)) * h.step, y: g.LY))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let g = Geo(s.numbers), st = at(s)
        guard let h = g.hop(st) else { return nil }
        let w = g.want(st), n = w > 1 && st != 1 ? w - 1 : w + 1
        return HandMove(hand: ["n": Double(n)], missHand: nil, set: [(g.box[st], Double(n * h.per))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Elapsed3.Parts(s.numbers), st = at(s)
        if P.ends { return st == 2 ? ["x": Double(Ms3.h12(P.start / 60)), "y": Double(P.EM)] : nil }
        return st == 3 ? ["h": Double(P.h), "m": Double(P.trade ? P.m1 + P.m3 : abs(P.m3 - P.m1))] : nil
    }
}
