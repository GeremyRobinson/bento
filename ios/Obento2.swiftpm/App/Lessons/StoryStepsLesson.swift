import SwiftUI

/// Story problems in steps on the paper, as in the preview (design/prototype/grade4-ch2.html): one square is ten. The
/// story's bar model, 3 squares tall, each amount drawn at its true length and named: groups (a copies of b) with a part
/// taken off the end (the dashed rest is n), groups with a part joined on (n the whole), or a whole with a part taken off
/// and the rest shared into b equal parts (n one part). Drag each bar's end to the nearest ten (a group's copies follow
/// it), so the picture becomes the estimate; then the record writes the story as an equation with a letter and the
/// estimate, and the two steps are written; the answer is marked on n's bar, near the end of its estimate.
@MainActor
struct StoryStepsLesson: PaperLesson {
    static let y1 = 2.0, y2 = 7.0, H = 3.0
    var liveKeys: Set<String> { ["grab"] }
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    private static let named = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let mark = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The bars' lengths now (in squares, tens): the hand's while they're rounded, the rounded ones after.
    private func lengths(_ s: PaperState, _ P: StorySteps.Parts) -> (f: Double, c: Double, fd: Bool, cd: Bool) {
        if stage(s) >= 2 { return (Double(StorySteps.round10(P.first)) / 10, Double(StorySteps.round10(P.c)) / 10, true, true) }
        return (s.h("f") ?? Self.start(P.first), s.h("c") ?? Self.start(P.c), (s.h("fd") ?? 0) != 0, (s.h("cd") ?? 0) != 0)
    }
    /// A bar's length before it's rounded: its whole tens (G 3 Nov: every bar starts on the grid; its name keeps its own
    /// value), so 186 starts 18 squares long and is dragged to 19; 184 is let go where it is, at 18.
    static func start(_ amount: Int) -> Double { Double(max(1, amount / 10)) }
    /// Where things sit for these lengths: the groups' end (or the whole), where the part starts and ends, the rest.
    private func geo(_ P: StorySteps.Parts, _ f: Double, _ c: Double) -> (g: Double, cStart: Double, cEnd: Double, rest: Double) {
        if P.share { return (f, f - c, f, f - c) }
        let g = Double(P.a) * f
        return P.kind == 0 ? (g, g - c, g, g - c) : (g, g, g + c, g + c)
    }
    private func handles(_ P: StorySteps.Parts, _ L: (f: Double, c: Double, fd: Bool, cd: Bool)) -> [(id: Int, at: CGPoint)] {
        let G = geo(P, L.f, L.c)
        var out: [(Int, CGPoint)] = []
        if !L.fd { out.append((1, CGPoint(x: P.share ? G.g : L.f, y: Self.y1 + Self.H / 2))) }
        if !L.cd { out.append((2, CGPoint(x: P.kind == 1 ? G.cEnd : G.cStart, y: (P.kind == 1 ? Self.y1 : Self.y2) + Self.H / 2))) }
        return out
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = StorySteps.Parts(s.numbers), at = stage(s), L = lengths(s, P), G = geo(P, L.f, L.c)
        let y1 = Self.y1, y2 = Self.y2, H = Self.H
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        func piece(_ id: String, _ x: Double, _ y: Double, _ w: Double, strong: Bool = false) {
            pic.fill(id + "f", col: x, row: y, w: w, h: H, .tint(strong ? 0.4 : 0.2))
            pic.sketch.box(id + "o", pic.R(x, y, w, H), .chapter, width: Sketch.stroke)
        }
        func dashed(_ id: String, _ x: Double, _ y: Double, _ w: Double, _ c: Sketch.Colour = .ink) {
            pic.sketch.box(id, pic.R(x, y, max(0, w), H), c, width: Sketch.stroke, dashed: true)
        }
        if !P.share {
            // row 1: the groups, each named with its amount; joined on, the part after them
            for j in 0..<P.a {
                piece("g\(j)", Double(j) * L.f, y1, L.f)
                pic.label("gl\(j)", "\(P.b)", Self.small, .above, edge: y1, along: (Double(j) + 0.5) * L.f)
            }
            if P.kind == 1 {
                piece("cj", G.cStart, y1, L.c, strong: true)
                pic.label("cjl", "\(P.c)", Self.small, .above, edge: y1, along: G.cStart + L.c / 2)
                dashed("nb", 0, y2, G.cEnd)
                pic.label("nl", "n", Self.named, .below, edge: y2 + H, along: G.cEnd / 2)
            } else {
                piece("ct", G.cStart, y2, L.c, strong: true)
                pic.label("ctl", "\(P.c)", Self.small, .below, edge: y2 + H, along: G.cStart + L.c / 2)
                dashed("nb", 0, y2, G.rest)
                pic.label("nl", "n", Self.named, .below, edge: y2 + H, along: G.rest / 2)
            }
        } else {
            piece("wh", 0, y1, G.g)
            pic.label("whl", "\(P.a)", Self.small, .above, edge: y1, along: G.g / 2)
            piece("ct", G.cStart, y2, L.c, strong: true)
            pic.label("ctl", "\(P.c)", Self.small, .below, edge: y2 + H, along: G.cStart + L.c / 2)
            if at <= 1 {
                dashed("nb", 0, y2, G.rest)
                pic.label("nl", "?", Self.named.colour(.ink), .below, edge: y2 + H, along: G.rest / 2)
            } else {
                // the rest cut by the ruler into b equal parts; n is one (the preview's parts of the estimate's whole
                // squares ran past the rest when it doesn't share evenly: 500 into 9 parts of 6 squares is 54)
                // each part whole squares (what the parts leave of the rest stays blank, before the part taken off)
                let pw = max(1, (G.rest / Double(P.b)).rounded(.down))
                for j in 0..<P.b { dashed("sp\(j)", Double(j) * pw, y2, pw, j == 0 ? .ink : .ink3) }
                pic.label("nl", "n", Self.named, .below, edge: y2 + H, along: pw / 2)
            }
        }
        // the handles; while one is held, what it rounds to
        if at == 1 {
            let held = Int((s.h("held") ?? 0).rounded())
            for h in handles(P, L) { live.dot("h\(h.id)", at: h.at.x, h.at.y, radius: s.grabbed && held == h.id ? 0.75 : 0.55, .ink, over: true) }
            if s.grabbed, held > 0 {
                let amt = held == 1 ? P.first : P.c, len = held == 1 ? L.f : L.c
                live.reads("\(amt) → \(Int(len.rounded()) * 10)")
            }
            // a hint: where each end belongs, dashed
            if s.on("ring") {
                let R = { (x: Int) in Double(StorySteps.round10(x)) / 10 }
                if !L.fd { let x = P.share ? R(P.a) : R(P.b); pic.line("ringf", [(x, y1 - 1), (x, y1 + H + 1)], .chapter, dashed: true) }
                if !L.cd {
                    let fR = L.fd ? L.f : P.share ? R(P.a) : R(P.b), gR = P.share ? fR : Double(P.a) * fR
                    let x = P.kind == 1 ? gR + R(P.c) : gR - R(P.c), y = P.kind == 1 ? y1 : y2
                    pic.line("ringc", [(x, y - 1), (x, y + H + 1)], .chapter, dashed: true)
                }
            }
        }
        // the answer, marked on n's bar near the end of its estimate
        if at >= 4 {
            // on the grid: the square line nearest the answer (its number says it exactly)
            if P.share {
                // sharing: the parts are whole squares, so n is written over the first part, its own value
                let pw = max(1, (G.rest / Double(P.b)).rounded(.down))
                pic.label("markw", "\(P.n)", Self.mark, .above, edge: y2, along: pw / 2)
            } else {
                let x = (Double(P.n) / 10).rounded()
                pic.line("mark", [(x, y2 - 0.5), (x, y2 + H + 0.5)], .chapter)
                pic.word("markw", "\(P.n)", at: x, y2 - 1.2, Self.mark)
            }
        }

        // the record: the story as an equation with a letter, the estimate, the two steps, n
        var boxes: [WorkBox] = []
        if at >= 2 {
            let R = StorySteps.round10, sign = P.kind == 0 ? "−" : "+"
            let eq: [Record.Token] = P.share ? [.op("("), .n(P.a), .op("−"), .n(P.c), .op(")"), .op("÷"), .n(P.b), .op("="), .w("n")]
                : [.n(P.a), .op("×"), .n(P.b), .op(sign), .n(P.c), .op("="), .w("n")]
            let about: [Record.Token] = P.share ? [.w("about"), .op("("), .n(R(P.a)), .op("−"), .n(R(P.c)), .op(")"), .op("÷"), .n(P.b), .op("="), .n(P.est)]
                : [.w("about"), .n(P.a * R(P.b)), .op(sign), .n(R(P.c)), .op("="), .n(P.est)]
            let w1: [Record.Token] = P.share ? [.n(P.a), .op("−"), .n(P.c), .op("=")] : [.n(P.a), .op("×"), .n(P.b), .op("=")]
            let w2: [Record.Token] = P.share ? [.n(P.s1), .op("÷"), .n(P.b), .op("=")] : [.n(P.s1), .op(sign), .n(P.c), .op("=")]
            var lines = [eq, about, w1 + [at == 2 ? .box("x", cells: String(P.s1).count) : .n(P.s1)]]
            if at >= 3 { lines.append(w2 + [at == 3 ? .box("x", cells: String(P.n).count) : .n(P.n)]) }
            if at >= 4 { lines.append([.w("n"), .op("="), .n(P.n)]) }
            for (i, l) in lines.enumerated() {
                Record.line(&rec, "r\(i)", l, x: 0, row: 1 + 3 * Double(i), colours: at >= 4 && i == 4 ? [2: .chapter] : [:])
            }
            boxes = rec.boxes
        }
        let most = P.share ? 62.0 : Double(P.a) * Double(StorySteps.round10(P.b) / 10 + 1) + (P.kind == 1 ? Double(StorySteps.round10(P.c) / 10 + 1) : 0)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes,
                            extent: at == 1 ? pic.R(0, 0, min(64, most + 2), y2 + H + 2) : nil)
    }

    /// Every slip fits one row over the bars.
    func messageRows(_ n: Numbers) -> Int { 1 }
    /// The record may go beside the bars (when that shows it bigger: a short take-away's narrow bars left its story
    /// wrapped onto many rows, seen at 73%).
    func recordBeside(_ n: Numbers) -> Double? {
        let P = StorySteps.Parts(n)
        let most = P.share ? 62.0 : Double(P.a) * Double(StorySteps.round10(P.b) / 10 + 1) + (P.kind == 1 ? Double(StorySteps.round10(P.c) / 10 + 1) : 0)
        return most + 2 <= 34 ? 0 : nil
    }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let P = StorySteps.Parts(s.numbers), L = lengths(s, P), hs = handles(P, L), base = s.hand
        return Hands(
            grab: { q in
                guard let h = hs.first(where: { abs(q.x - $0.at.x) < 1.5 && abs(q.y - $0.at.y) < 2 }) else { return nil }
                var out = base; out["grab"] = 1; out["held"] = Double(h.id); out["gx"] = q.x
                return out
            },
            drag: { q, h in
                var h = h
                let G = self.geo(P, L.f, L.c)
                if h["held"] == 1 { h["f"] = Double(max(1, min(P.share ? 62 : 62 / P.a, Int(q.x.rounded())))) }
                else if P.kind == 1 { h["c"] = Double(max(1, min(30, Int((q.x - G.cStart).rounded())))) }
                else { h["c"] = Double(max(1, min(Int(G.cEnd) - 1, Int((G.cEnd - q.x).rounded())))) }
                return h
            },
            release: { h in
                var out = h; out["grab"] = nil; out["held"] = nil; out["gx"] = nil
                let which = Int((h["held"] ?? 0).rounded())
                let key = which == 1 ? "f" : "c", amt = which == 1 ? P.first : P.c
                // a tap: nothing moved
                // a tap, nothing moved: right when it already ends at the nearest ten (184 at 18), else nothing
                let len = h[key] ?? base[key] ?? Self.start(amt), got = Int(len.rounded())
                if len == (base[key] ?? Self.start(amt)) && got * 10 != StorySteps.round10(amt) { out[key] = base[key]; return HandMove(hand: out, missHand: nil) }
                if got * 10 == StorySteps.round10(amt) {
                    out[which == 1 ? "fd" : "cd"] = 1
                    let both = (out["fd"] ?? 0) != 0 && (out["cd"] ?? 0) != 0
                    return HandMove(hand: out, missHand: nil, set: both ? [("x", 1)] : [], check: both)
                }
                // let go at the wrong ten: it springs back to its true length
                var back = out; back[key] = nil
                return HandMove(hand: out, missHand: back, set: [("x", Double(1000 * which + got))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let P = StorySteps.Parts(s.numbers), L = lengths(s, P), R = { (x: Int) in Double(StorySteps.round10(x)) / 10 }
        var moves: [GhostMove] = []
        let fR = P.share ? R(P.a) : R(P.b)
        if !L.fd { moves.append(.drag(from: CGPoint(x: P.share ? L.f : L.f, y: Self.y1 + Self.H / 2), to: CGPoint(x: fR, y: Self.y1 + Self.H / 2))) }
        // (a bar already at its nearest ten is a drag that ends where it starts: pressed and let go)
        if !L.cd {
            // after the first: the groups at their rounded length
            let g = P.share ? fR : Double(P.a) * fR, c = Self.start(P.c)
            if P.kind == 1 { moves.append(.drag(from: CGPoint(x: g + c, y: Self.y1 + Self.H / 2), to: CGPoint(x: g + R(P.c), y: Self.y1 + Self.H / 2))) }
            else { moves.append(.drag(from: CGPoint(x: g - c, y: Self.y2 + Self.H / 2), to: CGPoint(x: g - R(P.c), y: Self.y2 + Self.H / 2))) }
        }
        return moves
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = StorySteps.Parts(s.numbers), got = StorySteps.round10(P.first) / 10 - 1
        return HandMove(hand: s.hand, missHand: s.hand, set: [("x", Double(1000 + got))], check: true)
    }
}
