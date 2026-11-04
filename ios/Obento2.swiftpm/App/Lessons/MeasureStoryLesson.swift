import SwiftUI

/// Measurement story problems on the paper, as in the preview (design/prototype/grade4-ch7.html): the measuring line, 48
/// or 50 squares, a square what the story sets (5 minutes, 25¢, 100 mL, 100 m, 100 g), the big unit a long tick named
/// under it (3:00, $4, 2 L), the start ringed. Drag a hop out from where you are: it snaps a square at a time, arcs over
/// the line with its amount over it, and the readout says it and where it lands ("1 h 20 min → 5:05"); one hop for each
/// part the story gives, or, for a "How long?" story, hops from the ring up to the end. Then the record: any change of
/// unit first (2 L = 2,000 mL), then the line with the answer typed (a time in two boxes, [h]:[min]).
@MainActor
struct MeasureStoryLesson: PaperLesson {
    /// The line's row.
    static let LY = 6.0
    var liveKeys: Set<String> { ["len"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The hops made so far (their ends, in squares), from the hand while the step lasts, then from what it kept.
    private func ends(_ s: PaperState, _ p: MeasureStory.Parts) -> [Int] {
        let src = stage(s) == 1 ? s.hand : s.run.kept
        let k = Int((src["k"] ?? 0).rounded())
        if stage(s) >= 2 && k == 0 {
            if p.counts { return [p.tx] }
            var at = p.sx; return p.hops.map { at += $0 / p.per; return at }
        }
        return (0..<k).map { Int((src["e\($0)"] ?? 0).rounded()) }
    }
    private func pos(_ s: PaperState, _ p: MeasureStory.Parts) -> Int { ends(s, p).last ?? p.sx }

    static func durToks(_ t: Int, _ c: Sketch.Colour = .ink) -> [M7.Tok] {
        (t >= 60 ? [.n(t / 60, c), .w("h", c)] : []) + (t % 60 != 0 || t < 60 ? [.n(t % 60, c), .w("min", c)] : [])
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let p = MeasureStory.Parts(s.numbers), at = stage(s), LY = Self.LY, LW = p.LW
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

        // the measuring line: a tick a square, longer at the big unit (and at half hours), named under it
        pic.rule("ml", from: 0, to: Double(LW), row: LY)
        let bigEvery = p.time ? 12 : p.money ? 4 : 10
        var minor: [(CGPoint, CGPoint)] = [], major: [(CGPoint, CGPoint)] = []
        for x in 0...LW {
            let big = x % bigEvery == 0, mid = p.time && x % 6 == 0, t = big ? 0.8 : mid ? 0.6 : 0.3
            let seg = (pic.P(Double(x), LY - t), pic.P(Double(x), LY + t))
            if big { major.append(seg) } else { minor.append(seg) }
            if big {
                let name = p.time ? Meas4.clock(p.L0 + x * p.per) : p.money ? Meas4.usd(x * p.per) : x == 0 ? "0" : "\(x / 10) \(p.unit!.b)"
                pic.label("mn\(x)", name, small, .below, edge: LY + 0.8, along: Double(x))
            }
        }
        pic.sketch.segments("mtm", minor, .ink3, width: Sketch.stroke)
        pic.sketch.segments("mtb", major, .ink, width: Sketch.stroke)
        pic.circle("st", at: Double(p.sx), LY, radius: 0.7, .ink)
        if p.counts { pic.circle("end", at: Double(p.tx), LY, radius: 0.7, .ink, dashed: true) }

        // the hops made, each named over its arc; the one being dragged, live
        func hop(_ pen: inout GridPen, _ id: String, _ a: Int, _ b: Int) {
            let h = min(3, 1 + Double(abs(b - a)) / 6)
            pen.hop(id + "a", from: Double(a), to: Double(b), row: LY, height: h)
            let name = p.amount(abs(b - a))
            if PaperText.width(name, PaperText.font(Sketch.small, .semibold, digits: true)) / Paper.cell <= Double(abs(b - a)) - 0.3 {
                pen.label(id + "n", name, Bars.small, .above, edge: LY - h, along: Double(a + b) / 2)
            }
        }
        var from = p.sx
        for (i, e) in ends(s, p).enumerated() {
            hop(&pic, "h\(i)_\(from)_\(e)", from, e)
            pic.dot("hd\(i)_\(e)", at: Double(e), LY, radius: 0.3, .chapter, over: true)
            from = e
        }
        if at == 1 {
            let len = Int((s.h("len") ?? 0).rounded()), x = pos(s, p)
            if s.grabbed && len != 0 {
                hop(&live, "hl", x, x + len)
                live.reads("\(p.amount(abs(len))) → \(p.place(x + len))")
            }
            live.dot("handle", at: Double(x + (s.grabbed ? len : 0)), LY, radius: s.grabbed ? 0.75 : 0.55, .ink, over: true)
            if s.on("spot") {
                let target = p.counts ? p.tx : x + (p.hops.indices.contains(ends(s, p).count) ? p.hops[ends(s, p).count] / p.per : 0)
                pic.circle("ring", at: Double(target), LY, radius: 1.3, .chapter, dashed: true)
            }
        }

        // the record: any change of unit first, then the line written, its answer typed
        if at >= 2 {
            var line = 2.0
            if let U = p.unit {
                for (i, r) in p.unitRows.enumerated() {
                    let big: [M7.Tok]
                    if p.half && r.small == 500 && i == p.unitRows.count - 1 && (p.sub == .two || p.sub == .take2) {
                        big = U.b == "km" ? [.t("0.5"), .w(U.b)] : [.f(1, 2), .w(U.b)]
                    } else if r.small % 1000 == 0 { big = [.n(r.small / 1000), .w(U.b)] }
                    else { big = [.n(r.small / 1000), .w(U.b), .n(r.small % 1000), .w(U.s)] }
                    let frac = big.contains { if case .f = $0 { true } else { false } }
                    if frac { line += 1 }
                    M7.row(&rec, "u\(i)", big + [.op("="), .n(r.small), .w(U.s)], x: 0, line: line)
                    line += 3
                }
            }
            M7.row(&rec, "wr", lead(p) + [.op("=")] + (at >= 3 ? answer(p) : boxes(p)), x: 0, line: line)
        }
        let extent = pic.R(0, 0, Double(LW) + 1, LY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    private func lead(_ p: MeasureStory.Parts) -> [M7.Tok] {
        let a1 = abs(p.hops.first ?? 0), a2 = p.hops.count > 1 ? abs(p.hops[1]) : 0
        switch p.kind {
        case 0:
            if p.sub == .len { return [.t(Meas4.clock(p.t)), .op("−"), .t(Meas4.clock(p.s))] }
            return [.t(Meas4.clock(p.s))] + p.hops.flatMap { [M7.Tok.op("+")] + Self.durToks($0) }
        case 1: return p.sub == .change ? [.t(Meas4.usd(p.t)), .op("−"), .t(Meas4.usd(p.s))] : [.t(Meas4.usd(a1)), .op("+"), .t(Meas4.usd(a2))]
        default:
            let U = p.unit!
            switch p.sub {
            case .one: return [.n(p.s), .op(p.take ? "−" : "+"), .n(a1)]
            case .rep: return [.n(p.B), .w(U.b), .op("−"), .n(p.hops.count), .op("×"), .n(a1), .w(U.s)]
            case .two: return [.n(a1), .op("+"), .n(a2)]
            default: return [.n(p.s), .op("−"), .n(a1), .op("−"), .n(a2)]
            }
        }
    }
    private func boxes(_ p: MeasureStory.Parts) -> [M7.Tok] {
        if p.time {
            if p.sub == .len { return (p.D >= 60 ? [.box("H", cells: 1), .w("h")] : []) + [.box("M", cells: 2), .w("min")] }
            return [.box("H", cells: 2), .op(":"), .box("M", cells: 2)]
        }
        if p.money { return [.t("$"), .box("R", cells: 3)] }
        return [.box("R", cells: String(p.end).count), .w(p.unit!.s)]
    }
    private func answer(_ p: MeasureStory.Parts) -> [M7.Tok] {
        if p.time { return p.sub == .len ? Self.durToks(p.D, .chapter) : [.t(Meas4.clock(p.end), .chapter)] }
        if p.money { return [.t(Meas4.usd(p.sub == .change ? p.t - p.s : p.end), .chapter)] }
        return [.n(p.end, .chapter), .w(p.unit!.s, .chapter)]
    }

    func recordRow(_ n: Numbers) -> Double? { Self.LY + 3 }
    func messageRows(_ n: Numbers) -> Int { 2 }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let p = MeasureStory.Parts(s.numbers), done = ends(s, p), x = pos(s, p), LY = Self.LY, LW = p.LW, base = s.hand
        func after(_ e: [Int]) -> Numbers {
            var h: Numbers = ["k": Double(e.count)]
            for (i, v) in e.enumerated() { h["e\(i)"] = Double(v) }
            return h
        }
        return Hands(
            grab: { q in
                guard abs(q.x - Double(x)) < 2 && abs(q.y - LY) < 2.5 else { return nil }
                var h = base; h["grab"] = 1; h["len"] = 0; return h
            },
            drag: { q, h in var n = h; n["len"] = Double(min(LW - x, max(-x, Int((q.x - Double(x)).rounded())))); return n },
            release: { h in
                let len = Int((h["len"] ?? 0).rounded())
                let still = after(done)
                guard len != 0 else { return HandMove(hand: still, missHand: nil) }
                let wrong = HandMove(hand: still, missHand: nil, set: [("x", Double(x)), ("h", Double(len))], check: true)
                let next = after(done + [x + len])
                if p.counts {
                    if len < 0 || x + len > p.tx { return wrong }
                    if x + len == p.tx { return HandMove(hand: next, missHand: nil, set: [("x", Double(x)), ("h", Double(len))], keep: next, check: true) }
                    return HandMove(hand: next, missHand: nil)
                }
                let j = done.count
                guard p.hops.indices.contains(j), len == p.hops[j] / p.per else { return wrong }
                if j == p.hops.count - 1 { return HandMove(hand: next, missHand: nil, set: [("x", Double(x)), ("h", Double(len))], keep: next, check: true) }
                return HandMove(hand: next, missHand: nil)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let p = MeasureStory.Parts(s.numbers), LY = Self.LY
        if p.counts { return [.drag(from: CGPoint(x: Double(pos(s, p)), y: LY), to: CGPoint(x: Double(p.tx), y: LY))] }
        var at = pos(s, p), out: [GhostMove] = []
        for h in p.hops.dropFirst(ends(s, p).count) {
            out.append(.drag(from: CGPoint(x: Double(at), y: LY), to: CGPoint(x: Double(at + h / p.per), y: LY)))
            at += h / p.per
        }
        return out
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let p = MeasureStory.Parts(s.numbers), x = pos(s, p)
        // a hop too long: past the end, or one more square than the story's part
        let len = p.counts ? p.tx - x + 2 : (p.hops.first ?? p.per) / p.per + ((p.hops.first ?? 1) > 0 ? 4 : -4)
        return HandMove(hand: [:], missHand: nil, set: [("x", Double(x)), ("h", Double(len))], check: true)
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = MeasureStory.Parts(s.numbers)
        guard stage(s) == 2 else { return nil }
        if p.time { return p.sub == .len ? (p.D >= 60 ? ["H": Double(p.D / 60), "M": Double(p.D % 60 + 60 >= 100 ? 5 : p.D % 60 + 60)] : ["M": Double(p.D + 10)])
                                          : ["H": Double(p.eh), "M": Double(p.em + 60 > 99 ? 75 : p.em + 60)] }
        if p.money { return ["R": Double(p.sub == .change ? p.t - p.s : p.end)] }
        return ["R": Double(p.take ? p.s + p.hops.reduce(0) { $0 + abs($1) } : p.end / 1000 == 0 ? p.end + 100 : p.end - 100)]
    }
}
