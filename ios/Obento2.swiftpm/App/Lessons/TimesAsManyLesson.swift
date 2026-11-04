import SwiftUI

/// Times as many on the paper, as in the preview (design/prototype/grade4-ch2.html): one square a centimeter of ribbon.
/// Red, then Blue under it, both 4 squares tall and starting on the same strong line, named at their left. Find the big
/// one: drag out copies of Red along Blue's row, each outlined and numbered. Find the small one: drag the ruler under
/// Blue; it cuts Blue into equal parts (snapping to sizes that divide it), and the first part slides up into Red. How
/// many times: hop Red along Blue. Longer or times: drag Blue's end a square at a time. Then the record's line is
/// written; the last words say why.
@MainActor
struct TimesAsManyLesson: PaperLesson {
    /// Red's row, Blue's, a bar's height, where both start (the names in the block before).
    static let yR = 0.0, yB = 6.0, H = 4.0, x0 = 5.0
    var liveKeys: Set<String> { ["c", "s", "h", "len", "grab"] }
    private static let name = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    private static let named = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    private static let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The furthest a move can reach: a few copies past Blue, a hop past its end, Blue's end a little past.
    private func cmax(_ P: TimesAsMany.Parts) -> Int { min(60 / P.r, P.m + 3) }
    private func lmax(_ P: TimesAsMany.Parts) -> Int { min(60, max(P.B + 2 * P.r, P.B + 6)) }

    /// The move's value now: what the hand holds on the move, the answer after it.
    private func value(_ s: PaperState, _ P: TimesAsMany.Parts) -> Int {
        let at = stage(s)
        switch P.kind {
        case 0: return at >= 2 ? P.m : Int((s.h("c") ?? 0).rounded())
        case 1: return at >= 2 ? P.r : Int((s.h("s") ?? Double(P.B)).rounded())
        case 2: return at >= 2 ? P.m : Int((s.h("h") ?? 0).rounded())
        default: return at >= 2 ? P.B : Int((s.h("len") ?? Double(P.r)).rounded())
        }
    }
    private func handle(_ P: TimesAsMany.Parts, _ v: Int) -> CGPoint {
        let x0 = Self.x0, yB = Self.yB, H = Self.H
        switch P.kind {
        case 0: return CGPoint(x: x0 + Double(v * P.r), y: yB + H / 2)
        case 1: return CGPoint(x: x0 + Double(v), y: yB + H + 2)
        case 2: return CGPoint(x: x0 + Double(v * P.r), y: yB + H)
        default: return CGPoint(x: x0 + Double(v), y: yB + H / 2)
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TimesAsMany.Parts(s.numbers), at = stage(s), done = at >= 3, moving = at <= 1
        let x0 = Self.x0, yR = Self.yR, yB = Self.yB, H = Self.H, r = Double(P.r), B = Double(P.B)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let v = value(s, P)
        func bar(_ pen: inout GridPen, _ id: String, _ x: Double, _ y: Double, _ w: Double) {
            pen.fill(id + "f", col: x, row: y, w: w, h: H, .tint(0.22))
            pen.sketch.box(id + "o", pen.R(x, y, w, H), .chapter, width: Sketch.stroke)
        }
        pic.label("nR", "Red", Self.name, .left, edge: x0, along: yR + H / 2)
        pic.label("nB", "Blue", Self.name, .left, edge: x0, along: yB + H / 2)

        // Red: a length, or (the small one) a dashed edge and "?" until the first part slides up into it
        if P.kind != 1 {
            bar(&pic, "red", x0, yR, r)
            pic.label("rl", "\(P.r) cm", Self.name, .right, edge: x0 + r, along: yR + H / 2)
        } else if at < 2 {
            pic.line("redq", [(x0, yR), (x0, yR + H)], .ink3, dashed: true)
            pic.label("redqm", "?", Self.name, .right, edge: x0, along: yR + H / 2)
        }

        // what follows the hand is drawn live while it moves, on the picture after
        func pen(_ body: (inout GridPen) -> Void) { if moving { body(&live) } else { body(&pic) } }
        // Blue
        switch P.kind {
        case 0:
            // copies of Red, each outlined and numbered
            pen { p in
                for j in 0..<v {
                    bar(&p, "cp\(j)", x0 + Double(j) * r, yB, r)
                    p.word("cpn\(j)", "\(j + 1)", at: x0 + (Double(j) + 0.5) * r, yB + H / 2, Self.small)
                }
                if v == 0 { p.line("blueq", [(x0, yB), (x0, yB + H)], .ink3, dashed: true) }
                p.label("bl", done ? "\(P.B) cm" : "?", Self.name, .right, edge: x0 + Double(v) * r + (moving ? 1 : 0), along: yB + H / 2)
            }
            if moving { live.reads("\(v) × \(P.r) = \(v * P.r)") }
        case 3:
            let len = Double(v)
            pen { p in
                bar(&p, "blue", x0, yB, len)
                p.line("bcopy", [(x0 + r, yB), (x0 + r, yB + H)], .chapter)
                if v % P.r == 0 { for j in stride(from: 2, to: v / P.r, by: 1) { p.line("bc\(j)", [(x0 + Double(j) * r, yB), (x0 + Double(j) * r, yB + H)], .chapter) } }
                p.label("bl", done ? "\(P.B) cm" : "?", Self.name, .right, edge: x0 + len + (moving ? 1 : 0), along: yB + H / 2)
            }
            if moving { live.reads("Red + \(v - P.r) = \(v)" + (v % P.r == 0 && v > P.r ? " · \(v / P.r) × Red" : "")) }
        default:
            bar(&pic, "blue", x0, yB, B)
            pic.label("bl", "\(P.B) cm", Self.name, .right, edge: x0 + B, along: yB + H / 2)
        }

        // the small one: the ruler's cuts, dashed while it's moved, solid once found; the first part slides up into Red
        if P.kind == 1 {
            let sz = Double(v), found = at >= 2
            if sz < B {
                let cuts = (1..<max(2, Int(B / sz))).map { j in [(x0 + Double(j) * sz, yB), (x0 + Double(j) * sz, yB + H)] }
                for (j, c) in cuts.enumerated() {
                    if found { pic.line("cut\(j)", c, .ink) } else { live.line("cut\(j)", c, .chapter, dashed: true) }
                }
            }
            if found {
                bar(&pic, "part", x0, yR, r)
                pic.label("rlF", done ? "\(P.r) cm" : "r", done ? Self.name : Self.named, .right, edge: x0 + r, along: yR + H / 2)
            }
            if moving {
                let hd = handle(P, v)
                live.line("stem", [(hd.x, yB + H), (hd.x, hd.y)], .ink)
                live.reads(v == P.B ? "1 part" : "\(P.B / max(1, v)) parts of \(v)")
            }
        }
        // how many times: hops under Blue, counted; past its end, red
        if P.kind == 2 {
            pen { p in
                for j in 0..<v {
                    let a = x0 + Double(j) * r, past = a + r > x0 + B
                    let pts = (0...16).map { i -> (Double, Double) in let t = Double(i) / 16; return (a + r * t, yB + H + sin(.pi * t) * 3) }
                    p.line("hop\(j)", pts, past ? Self.red : .chapter)
                    p.word("hopn\(j)", "\(j + 1)", at: a + r / 2, yB + H + 1.6, Sketch.Words(size: Sketch.small, weight: .semibold, colour: past ? Self.red : .chapter))
                }
            }
            if moving { live.reads("\(v) hop\(v == 1 ? "" : "s"): \(v * P.r)") }
        }
        // the handle the hand drags
        if moving {
            let hd = handle(P, v)
            live.dot("hd", at: hd.x, hd.y, radius: s.grabbed ? 0.75 : 0.55, .ink, over: true)
        }
        // a hint: where the move should end, a dashed mark across Blue a square past it either side
        if moving, s.on("ring") {
            let end = x0 + (P.kind == 1 ? r : B)
            pic.line("ring", [(end, yB - 1), (end, yB + H + 1)], .chapter, dashed: true)
        }

        // the record: the kind's line, written once the hands have found it
        var boxes: [WorkBox] = []
        if at >= 2 {
            let ans: Record.Token = done ? .n(P.answer) : .box("x", cells: String(P.answer).count)
            var lines: [[Record.Token]]
            if P.timesLike { lines = [[.w("Blue"), .op("="), .n(P.m), .op("×"), .n(P.r), .op("="), ans]] }
            else if P.kind == 1 { lines = [[.n(P.B), .op("="), .n(P.m), .op("×"), .w("r")], [.w("r"), .op("="), .n(P.B), .op("÷"), .n(P.m), .op("="), ans]] }
            else if P.kind == 2 { lines = [[.n(P.B), .op("="), ans, .op("×"), .n(P.r)]] }
            else { lines = [[.w("Blue"), .op("="), .n(P.r), .op("+"), .n(P.k), .op("="), ans]] }
            // the answer's place: the last line's last token, or (how many times) its third
            let ai = P.kind == 2 ? 2 : lines[lines.count - 1].count - 1
            for (i, l) in lines.enumerated() {
                Record.line(&rec, "rec\(i)", l, x: 0, row: 1 + 3 * Double(i), colours: done && i == lines.count - 1 ? [ai: .chapter] : [:])
            }
            if done && P.timesLike {
                rec.word("asmany", "\(P.B) is \(P.m) times as many as \(P.r).", at: 0.5, 1 + 3 * Double(lines.count), Record.words, anchor: UnitPoint(x: 0, y: 0.5))
            }
            boxes = rec.boxes
        }
        let reach = P.kind == 0 ? Double(cmax(P)) * r : P.kind == 2 ? Double(P.m + 1) * r : P.kind == 3 ? Double(lmax(P)) : B
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes,
                            extent: moving ? pic.R(0, yR, x0 + reach + 4, yB + H + (P.kind == 1 || P.kind == 2 ? 3 : 0)) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let P = TimesAsMany.Parts(s.numbers), v = value(s, P), hd = handle(P, v), x0 = Self.x0
        let key = ["c", "s", "h", "len"][P.kind]
        func snap(_ q: CGPoint) -> Int {
            let dx = q.x - x0
            switch P.kind {
            case 0: return max(0, min(cmax(P), Int((dx / Double(P.r)).rounded())))
            case 1: return (P.divisors + [P.B]).min { abs(Double($0) - dx) < abs(Double($1) - dx) } ?? P.B
            case 2: return max(0, min(P.m + 1, Int((dx / Double(P.r)).rounded())))
            default: return max(P.r, min(lmax(P), Int(dx.rounded())))
            }
        }
        let rest = P.kind == 1 ? P.B : P.kind == 3 ? P.r : 0
        return Hands(
            grab: { q in abs(q.x - hd.x) <= 2 && abs(q.y - hd.y) <= 2.5 ? ["grab": 1, key: Double(v)] : nil },
            drag: { q, _ in ["grab": 1, key: Double(snap(q))] },
            release: { h in
                let x = Int((h[key] ?? 0).rounded())
                // let go where it started: nothing to check
                guard x != rest else { return HandMove(hand: [key: Double(x)], missHand: nil) }
                let set = P.kind == 1 ? P.B / max(1, x) : x
                return HandMove(hand: [key: Double(x)], missHand: nil, set: [("x", Double(set))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let P = TimesAsMany.Parts(s.numbers), from = handle(P, value(s, P))
        let to = handle(P, P.kind == 0 || P.kind == 2 ? P.m : P.kind == 1 ? P.r : P.B)
        return [.drag(from: from, to: to)]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = TimesAsMany.Parts(s.numbers)
        switch P.kind {
        case 0: return HandMove(hand: ["c": Double(P.m - 1)], missHand: nil, set: [("x", Double(P.m - 1))], check: true)
        case 1:
            let sz = P.divisors.first { P.B / $0 != P.m } ?? 1
            return HandMove(hand: ["s": Double(sz)], missHand: nil, set: [("x", Double(P.B / sz))], check: true)
        case 2:
            let h = P.m > 1 ? P.m - 1 : P.m + 1
            return HandMove(hand: ["h": Double(h)], missHand: nil, set: [("x", Double(h))], check: true)
        default:
            let len = P.lg ? (2 * P.r != P.B ? 2 * P.r : P.B - 1) : P.B - 1
            return HandMove(hand: ["len": Double(len)], missHand: nil, set: [("x", Double(len))], check: true)
        }
    }

    func messageRows(_ n: Numbers) -> Int { 2 }
}
