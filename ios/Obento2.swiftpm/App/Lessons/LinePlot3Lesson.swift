import SwiftUI

/// Line plots with halves and fourths on the paper, as in the preview (design/prototype/grade3-ch7.html, dMeasure and
/// dPlot). Measure: an inch is 8 squares (a fourth 2, a half 4); the crayon lies on the ruler from 0. Tap the last whole
/// inch it passes (it lights); hop the fourths (or halves) from there to its end, the hops snapping a mark at a time and
/// counting ("3 hops" beside the crayon); write `[2] [3]/[4] inches`. The plot: an inch is 12 squares (a fourth 3); the
/// ruler, and under it, lined up, the plot over 2 inches with every fourth named. Each thing comes onto the ruler from 0;
/// tap where its X goes (it stacks above the mark under its end); after three the rest drop in one after another. Then
/// tap the stack the question asks about (its X's number) and write `[3] crayons`, or tap the tallest stack and the record
/// writes `2 1/4 inches`.
///
/// Kept: "pl" how many X's are placed. Hand while hops are dragged: "grab", "n".
@MainActor
struct LinePlot3Lesson: PaperLesson {
    var liveKeys: Set<String> { ["n"] }
    func messageRows(_ n: Numbers) -> Int { 2 }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The measure's squares: the crayon's row, the ruler's top, the record's row.
    struct Measure {
        let P: LinePlot3.Parts
        static let per = 8.0, CY = 4.0, RT = 6.0, RY = 14.0
        var W: Double { Self.per * Double(P.inches) }
        var x0: Double { Double(P.whole) * Self.per }
        var step: Double { Self.per / Double(P.to) }
        var end: Double { Double(P.fourths) * Self.per / 4 }
        var hopY: Double { Self.CY - 0.3 }
    }
    /// The plot's squares: a fourth is 3; the thing's row, the ruler's top, the plot's line, the record's row.
    struct Plot {
        let P: LinePlot3.Parts
        static let f = 3.0, TY = 1.0, RT = 3.0
        var inches: Int { P.lo / 4 + 2 }
        var W: Double { 12 * Double(inches) }
        var LY: Double { Self.RT + 5 + 2 * Double(P.stackMax) }
        var RY: Double { P.ask == 0 ? LY + 6 : LY + 7 }
        func X(_ u: Int) -> Double { Double(u) * Self.f }
        var x0: Double { X(P.lo) }
        var x1: Double { X(P.lo + 8) }
        /// The mark under a point in the plot's columns, or nil.
        func col(_ q: CGPoint) -> Int? {
            guard q.y >= Self.RT + 3.5, q.y <= LY + 2.5 else { return nil }
            let u = Int((q.x / Self.f).rounded())
            guard u >= P.lo, u <= P.lo + 8, abs(q.x - X(u)) <= 1.5 else { return nil }
            return u
        }
    }
    private func placed(_ s: PaperState, _ P: LinePlot3.Parts) -> Int { at(s) >= 1 ? P.data.count : min(P.toPlace, Int(s.run.kept["pl"] ?? 0)) }
    func recordRow(_ n: Numbers) -> Double? {
        let P = LinePlot3.Parts(n)
        return (P.measure ? Measure.RY : Plot(P: P).RY) - 1
    }
    private func plotLine(_ P: LinePlot3.Parts, right: Bool) -> [M7.Tok] {
        if P.ask == 0 { return [right ? .n(P.n, .chapter) : .box("c", cells: 2), .w(P.th.many, right ? .chapter : .ink)] }
        let f = LinePlot3.fraction(P.mode)
        var out: [M7.Tok] = []
        if f.whole > 0 || f.top == 0 { out.append(.n(f.whole, .chapter)) }
        if f.top > 0 { out.append(.f(f.top, f.bottom, .chapter)); out.append(.gap(0.6)) }
        out.append(.w(LinePlot3.inchWord(P.mode), .chapter))
        return out
    }
    private func measureLine(_ P: LinePlot3.Parts, right: Bool) -> [M7.Tok] {
        let w: M7.Tok = right ? .n(P.whole, .chapter) : .box("w", cells: 1)
        let f: M7.Tok = right ? .f(P.extra, P.to, .chapter) : .fb("n", "d")
        return [w, f, .gap(0.6), .w("inches", right ? .chapter : .ink)]
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = LinePlot3.Parts(s.numbers), st = at(s)
        if P.measure {
            guard st >= 2 else { return nil }
            return CGPoint(x: DK3.after(M7.width(measureLine(P, right: st == 9))), y: Measure.RY - 1)
        }
        let G = Plot(P: P)
        guard (P.ask == 0 && st >= 2) || (P.ask == 1 && st == 9) else { return nil }
        return CGPoint(x: DK3.after(M7.width(plotLine(P, right: st == 9))), y: G.RY - 1)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = LinePlot3.Parts(s.numbers), st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if P.measure {
            let G = Measure(P: P), CY = Measure.CY, RT = Measure.RT, n = Int((s.h("n") ?? 0).rounded())
            DK3.thing(&pic, "cr", "crayon", x0: 0, x1: G.end, y: CY)
            DK3.ruler(&pic, "ru", x0: 0, y: RT, per: Measure.per, max: P.inches, to: 4, lit: st >= 1 ? P.whole : nil)
            // the hops: held in the live pen, then kept
            let hops = st == 1 ? n : (st >= 2 ? P.extra : 0)
            if hops > 0 {
                let H = min(6, G.step * 0.8)
                for i in 1...hops {
                    let a = G.x0 + Double(i - 1) * G.step, b = G.x0 + Double(i) * G.step
                    if st == 1 {
                        live.hop("ha\(i)", from: a, to: b, row: G.hopY, height: H)
                        live.word("hn\(i)", "\(i)", at: (a + b) / 2, G.hopY - H - 0.9, DK3.smallLit)
                    } else {
                        pic.hop("ha\(i)", from: a, to: b, row: G.hopY, height: H)
                        pic.word("hn\(i)", "\(i)", at: (a + b) / 2, G.hopY - H - 0.9, DK3.smallLit)
                    }
                }
            }
            if st == 1 {
                live.dot("hh", at: G.x0 + Double(n) * G.step, G.hopY, radius: s.grabbed ? 0.7 : 0.55, .ink, over: true)
                if n > 0 || s.grabbed {
                    let ro = Data3.plural(n, "hop", "hops")
                    DK3.readout(&live, ro, x: G.W + 2.5, y: CY + 1); if s.grabbed { live.reads(ro) }
                }
            }
            switch st {
            case 0:
                if ring { KK.hintBox(&pic, "hr", x: max(0, G.end - 12), y: RT, w: min(G.end + 12, G.W) - max(0, G.end - 12), h: 3) }
                if spot { pic.circle("hs", at: G.x0, RT + 2.35, radius: 1.2, .chapter, dashed: true) }
            case 1:
                if ring { KK.hintBox(&pic, "hr", x: G.x0, y: CY - 3, w: G.end - G.x0, h: 3) }
                if spot { pic.circle("hs", at: G.end, G.hopY, radius: 1, .chapter, dashed: true) }
            case 2:
                if ring { KK.hintBox(&pic, "hr", x: 0, y: CY - 3, w: G.end, h: 5) }
            default: break
            }
            if st >= 2 {
                let e = M7.row(&rec, "rec", measureLine(P, right: st == 9), x: 0, line: 1)
                if st == 2 && spot { A1.note(&rec, "spot", "\(P.whole) \(P.extra)/\(P.to)", x: e + 0.5, y: 1) }
            }
            let ext = pic.R(0, CY - 3.5, G.W + (st == 1 ? 9 : 1), RT + 3 - (CY - 3.5))
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
        }
        let G = Plot(P: P), LY = G.LY, RT = Plot.RT, th = P.th, shown = placed(s, P)
        // the thing to place, on the ruler from 0 (gone once the rest have dropped in)
        if st == 0 && shown < P.data.count { DK3.thing(&pic, "th\(shown)", th.one, x0: 0, x1: G.X(P.data[shown]), y: Plot.TY) }
        DK3.ruler(&pic, "ru", x0: 0, y: RT, per: 12, max: G.inches, to: 4)
        // the plot: a line from lo to lo + 2 inches, a mark every fourth with its length under it
        let tapped: Int? = (P.ask == 0 && st >= 2) ? P.v : (P.ask == 1 && st == 9 ? P.mode : nil)
        pic.line("pl", [(G.x0 - 1.5, LY), (G.x1 + 1.5, LY)])
        var marks: [(CGPoint, CGPoint)] = []
        for u in P.lo...(P.lo + 8) { marks.append((pic.P(G.X(u), LY), pic.P(G.X(u), LY + 0.8))) }
        pic.sketch.segments("pk", marks, .ink, width: Sketch.stroke)
        for u in P.lo...(P.lo + 8) {
            let lit = tapped == u
            pic.label("pn\(u)\(lit)", LinePlot3.said(u), lit ? DK3.smallLit : DK3.small, .below, edge: LY + 0.8, along: G.X(u))
        }
        pic.word("pu", "inches", at: G.x1 + 2.5, LY + 1.65, DK3.small, anchor: UnitPoint(x: 0, y: 0.5))
        // the X's: by hand first, then the rest one after another
        var count: [Int: Int] = [:]
        for i in 0..<shown {
            let u = P.data[i], kk = (count[u] ?? 0) + 1, on = tapped == u
            count[u] = kk
            if i >= LinePlot3.byHand && tapped == nil { pic.sketch.delay = 0.15 + Double(i - LinePlot3.byHand) * 0.22 }
            DK3.xMark(&pic, "x\(i)\(on)", cx: G.X(u), top: LY - 2 * Double(kk), on ? .chapter : .ink)
            pic.sketch.delay = 0
            if on && P.ask == 0 { pic.word("xn\(i)", "\(kk)", at: G.X(u) + 0.9, LY - 2 * Double(kk) + 1, DK3.smallLit, anchor: UnitPoint(x: 0, y: 0.5)) }
        }
        // hints
        let plotTop = LY - 2 * Double(P.stackMax)
        func stackBox(_ id: String, _ u: Int) {
            let h = max(1, LinePlot3.howMany(P.data, u))
            KK.hintBox(&pic, id, x: G.X(u) - 1.5, y: LY - 2 * Double(h), w: 3, h: 2 * Double(h))
        }
        switch st {
        case 0:
            if ring { KK.hintBox(&pic, "hr", x: G.x0 - 1.5, y: LY, w: G.x1 - G.x0 + 3, h: 3) }
            if spot, shown < P.data.count { pic.circle("hs", at: G.X(P.data[shown]), LY + 2.3, radius: 1.3, .chapter, dashed: true) }
        case 1, 3:
            if ring { KK.hintBox(&pic, "hr", x: G.x0 - 1.5, y: plotTop, w: G.x1 - G.x0 + 3, h: LY - plotTop) }
            if spot { stackBox("hs", st == 1 ? P.v : P.mode) }
        case 2:
            if ring { stackBox("hr", P.v) }
        default: break
        }
        if (P.ask == 0 && st >= 2) || (P.ask == 1 && st == 9) {
            let e = M7.row(&rec, "rec", plotLine(P, right: st == 9), x: 0, line: 1)
            if st == 2 && spot { A1.note(&rec, "spot", "\(P.n)", x: e + 0.5, y: 1) }
        }
        let ext = pic.R(0, 0, G.W + 1, LY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = LinePlot3.Parts(s.numbers), st = at(s)
        if P.measure {
            let G = Measure(P: P)
            if st == 0 {
                return Hands(tap: { q in
                    guard q.y >= Measure.RT - 0.5, q.y <= Measure.RT + 3.3 else { return nil }
                    let v = Int((q.x / Measure.per).rounded())
                    guard v >= 0, v <= P.inches, abs(q.x - Double(v) * Measure.per) <= 1.5 else { return nil }
                    return HandMove(hand: [:], missHand: [:], set: [("i", Double(v))], check: true)
                })
            }
            guard st == 1 else { return nil }
            let n0 = Int((s.h("n") ?? 0).rounded()), room = P.hopRoom, want = P.extra
            return Hands(
                grab: { q in abs(q.x - (G.x0 + Double(n0) * G.step)) <= 2.5 && abs(q.y - G.hopY) <= 3 ? ["grab": 1, "n": Double(n0)] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(0, min(room, Int(((q.x - G.x0) / G.step).rounded())))); return h },
                release: { h in
                    let n = Int((h["n"] ?? 0).rounded())
                    guard n != n0, n > 0 else { return HandMove(hand: ["n": Double(n)]) }
                    return HandMove(hand: ["n": Double(n)], missHand: ["n": Double(n > want ? n0 : n)], set: [("h", Double(n))], check: true)
                })
        }
        let G = Plot(P: P), shown = placed(s, P)
        guard st == 0 || st == 1 || st == 3 else { return nil }
        return Hands(tap: { q in
            guard let u = G.col(q) else { return nil }
            if st == 1 { return HandMove(hand: [:], missHand: [:], set: [("t", Double(u))], check: true) }
            if st == 3 { return HandMove(hand: [:], missHand: [:], set: [("m", Double(u))], check: true) }
            guard shown < P.toPlace else { return nil }
            if u != P.data[shown] { return HandMove(hand: [:], missHand: [:], set: [("p", Double(100 * shown + u))], check: true) }
            let all = shown + 1 == P.toPlace
            return HandMove(hand: [:], missHand: [:], set: all ? [("p", Double(LinePlot3.allPlaced))] : [], keep: ["pl": Double(shown + 1)], check: all)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = LinePlot3.Parts(s.numbers), st = at(s)
        if P.measure {
            let G = Measure(P: P)
            if st == 0 { return [.tap(.picture(CGPoint(x: G.x0, y: Measure.RT + 2)))] }
            guard st == 1 else { return [] }
            let n0 = (s.h("n") ?? 0).rounded()
            return [.drag(from: CGPoint(x: G.x0 + n0 * G.step, y: G.hopY), to: CGPoint(x: G.x0 + Double(P.extra) * G.step, y: G.hopY))]
        }
        let G = Plot(P: P), y = G.LY - 1
        switch st {
        case 0:
            var out: [GhostMove] = []
            for i in placed(s, P)..<P.toPlace { out.append(.tap(.picture(CGPoint(x: G.X(P.data[i]), y: y)))) }
            return out
        case 1: return [.tap(.picture(CGPoint(x: G.X(P.v), y: y)))]
        case 3: return [.tap(.picture(CGPoint(x: G.X(P.mode), y: y)))]
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = LinePlot3.Parts(s.numbers), st = at(s)
        if P.measure {
            if st == 0 { return HandMove(hand: [:], missHand: [:], set: [("i", Double(P.whole + 1 <= P.inches ? P.whole + 1 : P.whole - 1))], check: true) }
            guard st == 1 else { return nil }
            let n = P.extra + 1 <= P.hopRoom ? P.extra + 1 : P.extra - 1
            return HandMove(hand: ["n": Double(n)], missHand: ["n": Double(n > P.extra ? 0 : n)], set: [("h", Double(n))], check: true)
        }
        switch st {
        case 0:
            let i = placed(s, P), w = P.data[min(i, P.data.count - 1)], u = w > P.lo ? w - 1 : w + 1
            return HandMove(hand: [:], missHand: [:], set: [("p", Double(100 * i + u))], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("t", Double(P.v > P.lo ? P.v - 1 : P.v + 1))], check: true)
        case 3: return HandMove(hand: [:], missHand: [:], set: [("m", Double(P.data.first { $0 != P.mode } ?? P.mode))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = LinePlot3.Parts(s.numbers)
        guard at(s) == 2 else { return nil }
        if P.measure { return ["w": Double(P.whole), "n": Double(P.extra), "d": Double(P.to == 2 ? 4 : 2)] }
        return ["c": Double(P.n + 1)]
    }
}
