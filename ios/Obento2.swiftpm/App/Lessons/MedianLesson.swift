import SwiftUI

/// Find the median on the paper, as in the preview (design/prototype/grade6-ch8.html, dMed): the numbers as bars, one
/// square a one, up to 30 tall with room over them for the tallest to grow, each number tight under its bar; the record
/// beside them. Sort: drag a bar to its place (it follows the finger; the others make room, gliding, as it passes them;
/// "to spot 3"); in order, they number themselves 1 to n in their bottom squares. Cross them off a pair at a time from
/// both ends (tap the shortest and the tallest left): each goes faint with a stroke through it, and the middle bar (or
/// two, with their halfway dashed across) is left. Write `7 bars:`, `(7 + 1) ÷ 2 = [4]`, `median = [13]` (or
/// `(12 + 15) ÷ 2`, `= [13.5]`). Then drag the tallest's top up: "mean 14.2 → 15, median 13".
///
/// Hand keys: "o<p>" (the bar in spot p), "grab", "i" (the bar held), "dx", "x" (the finger), "t" (the spot it's over);
/// "lo", "hi" (the shortest and tallest left), "pend" (1 or 2: one of a pair crossed), "cx" (crossed spots, bits);
/// "g" (how much the tallest has grown).
@MainActor
struct MedianLesson: PaperLesson {
    var liveKeys: Set<String> { ["grab", "x"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct G {
        let P: Median6.Parts
        init(_ n: Numbers) { P = Median6.Parts(n) }
        var BY: Double { 1 + Double(P.tallest + Median6.room) }
        var PW: Double { 6 * Double(P.n) - 2 }
        var RX: Double { ((PW + 3) / 5).rounded(.up) * 5 }
        func slot(_ q: CGPoint) -> Int? { (0..<P.n).first { q.x >= D8.barX($0) - 0.5 && q.x <= D8.barX($0) + 4.5 } }
    }

    func recordRow(_ n: Numbers) -> Double? { 4 }
    func blocksLeft(_ n: Numbers) -> Double? { G(n).RX }

    /// The bars in their spots: as the hand has them while sorting, kept after (ties stay as the child left them).
    private func order(_ s: PaperState, _ P: Median6.Parts) -> [Int] {
        let at = stage(s)
        let given = (0..<P.n).map { p in (s.h("o\(p)") ?? s.run.kept["o\(p)"]).map { Int($0.rounded()) } }
        if given.allSatisfy({ $0 != nil }) { return given.map { $0! } }
        return at >= 2 ? P.v.indices.sorted { (P.v[$0], $0) < (P.v[$1], $1) } : Array(P.v.indices)
    }
    /// The order while a bar is held over spot t: the others make room.
    private func arranged(_ base: [Int], held: Int?, t: Int?) -> [Int] {
        guard let i = held, let t else { return base }
        var rest = base.filter { $0 != i }
        rest.insert(i, at: min(rest.count, max(0, t)))
        return rest
    }
    private func crossed(_ s: PaperState, _ n: Int) -> Int {
        switch stage(s) {
        case 2: return Int((s.h("cx") ?? 0).rounded())
        case let a where a > 2:
            let keep: Set<Int> = n % 2 == 1 ? [n / 2] : [n / 2 - 1, n / 2]
            return (0..<n).filter { !keep.contains($0) }.reduce(0) { $0 | 1 << $1 }
        default: return 0
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = G(s.numbers), P = g.P, at = stage(s), BY = g.BY, n = P.n
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = at == 1 && s.grabbed ? s.h("i").map { Int($0) } : nil
        let ord = arranged(order(s, P), held: held, t: s.h("t").map { Int($0) })
        let cx = crossed(s, n), grown = at >= 5 ? Int((s.h("g") ?? (at > 5 ? Double(Median6.grows) : 0)).rounded()) : 0
        let sorted = at >= 2
        pic.rule("base", from: -1, to: g.PW + 1, row: BY)
        for (p, j) in ord.enumerated() {
            let h = P.v[j] + (sorted && p == n - 1 ? grown : 0), isH = held == j
            let x = isH ? ((s.h("x") ?? 0) - (s.h("dx") ?? 0)).rounded() : D8.barX(p)
            let cr = cx & (1 << p) != 0, left = sorted && !cr && at >= 3
            var pen = isH ? live : pic
            let id = isH ? "held" : "mb\(j)"
            D8.square(&pen, id, x: x, y: BY - Double(h), w: 4, h: Double(h), cr ? .paper : left ? D8.strong : D8.fill, edge: cr ? .ink3 : .chapter)
            if cr { pen.line("mx\(j)", [(x + 0.3, BY - 0.3), (x + 3.7, BY - Double(h) + 0.3)], .ink3) }
            D8.under(&pen, isH ? "heldn" : "mn\(j)_", "\(h)", x: x, base: BY, cr ? .ink3 : .ink)
            // in order, the bars number themselves in their bottom squares
            if sorted { pen.word("mc\(p)\(cr)", "\(p + 1)", at: x + 2, BY - 0.5, D8.small.colour(cr ? .ink3 : .ink)) }
            if isH { live = pen } else { pic = pen }
        }
        // two left: their halfway, dashed across both
        if !P.odd && at >= 3 { let y = BY - P.median; pic.line("hw", [(D8.barX(n / 2 - 1), y), (D8.barX(n / 2) + 4, y)], .chapter, dashed: true) }
        if at == 5 {
            R6.handle(&live, "gh", D8.barX(n - 1) + 2, BY - Double(P.tallest + grown), held: s.grabbed)
        }
        // the readout beside the bars
        if let i = held { D8.readout(&live, "to spot \(ord.firstIndex(of: i).map { $0 + 1 } ?? 1)", x: g.RX, y: 2, held: true) }
        if at == 2 && cx == 0 { pic.word("rdo", "in order", at: g.RX, 2, D8.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        if at >= 5 {
            let rd = "mean \(Data6.dec1(Double(P.total) / Double(n))) → \(Data6.dec1(Double(P.total + grown) / Double(n))), median \(fmt(P.median))"
            if s.grabbed { D8.readout(&live, rd, x: g.RX, y: 2, held: true) } else { pic.word("rd\(rd)", rd, at: g.RX, 2, D8.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let lo = Int(s.h("lo") ?? 0), hi = Int(s.h("hi") ?? Double(n - 1))
        let mids = P.odd ? [n / 2] : [n / 2 - 1, n / 2]
        switch at {
        case 2:
            if s.on("ring") { R6.ring(&pic, "ring", x: D8.barX(lo), y: BY - Double(P.tallest), w: D8.barX(hi) + 4 - D8.barX(lo), h: Double(P.tallest)) }
            if s.on("spot") { for p in [lo, hi] { pic.circle("spot\(p)", at: D8.barX(p) + 2, BY + 1.3, radius: 1.5, .chapter, dashed: true) } }
        case 3, 4:
            if s.on("ring") { for p in mids { R6.ring(&pic, "ring\(p)", x: D8.barX(p), y: BY - Double(P.v[ord[p]]), w: 4, h: Double(P.v[ord[p]])) } }
            if s.on("spot") {
                if at == 3 { pic.circle("spot", at: D8.barX(n / 2) + 2, BY - 0.5, radius: 1.2, .chapter, dashed: true) }
                else { for p in mids { pic.circle("spot\(p)", at: D8.barX(p) + 2, BY + 1.3, radius: 1.5, .chapter, dashed: true) } }
            }
        default: break
        }

        // the record beside the bars
        if at >= 3 {
            let R = 1.0, done = at > 4
            if P.odd {
                M7.row(&rec, "w0", [.n(n), .w("bars:")], x: g.RX, line: R)
                let sv: M7.Tok = at == 3 ? .box("s", cells: 2) : .n(P.spot, .chapter)
                M7.row(&rec, "w1", [.t("(\(n)"), .op("+"), .t("1)"), .op("÷"), .n(2), .op("="), sv], x: g.RX, line: R + 3)
                let mv: M7.Tok = at == 4 ? .box("m", cells: max(1, fmt(P.median).count)) : done ? .t(fmt(P.median), .chapter) : .gap(Record.boxWidth(cells: 2, commas: true))
                let toks: [M7.Tok] = [.w("median"), .op("="), mv]
                M7.row(&rec, "w2", toks, x: g.RX, line: R + 6)
                if at == 3 { D8.waiting(&rec, "mw", toks, 2, x: g.RX, line: R + 6) }
            } else {
                let (a, b) = P.pair
                M7.row(&rec, "w1", [.t("(\(a)"), .op("+"), .t("\(b))"), .op("÷"), .n(2)], x: g.RX, line: R)
                let mv: M7.Tok = at == 4 ? .box("m", cells: max(2, fmt(P.median).count)) : .t(fmt(P.median), .chapter)
                M7.row(&rec, "w2", [.op("="), mv], x: g.RX, line: R + 3)
            }
        }
        let ext = pic.R(-1, 0, g.RX + 20, BY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = G(s.numbers), P = g.P, at = stage(s), BY = g.BY, n = P.n
        switch at {
        case 1:
            let base = order(s, P), keep = Dictionary(uniqueKeysWithValues: base.enumerated().map { ("o\($0.offset)", Double($0.element)) })
            return Hands(grab: { q in
                guard let p = g.slot(q), q.y > 0, q.y < BY + 3 else { return nil }
                return keep.merging(["grab": 1, "i": Double(base[p]), "dx": q.x - D8.barX(p), "x": q.x, "t": Double(p)]) { $1 }
            }, drag: { q, h in
                var h = h
                h["x"] = q.x
                h["t"] = Double(min(n - 1, max(0, Int(((q.x - (h["dx"] ?? 0)) / 6).rounded()))))
                return h
            }, release: { h in
                let now = arranged(base, held: h["i"].map { Int($0) }, t: h["t"].map { Int($0) })
                let o = Dictionary(uniqueKeysWithValues: now.enumerated().map { ("o\($0.offset)", Double($0.element)) })
                let inOrder = zip(now, now.dropFirst()).allSatisfy { P.v[$0] <= P.v[$1] }
                return HandMove(hand: o, missHand: o, set: inOrder ? [("s", 1)] : [], keep: o, check: inOrder)
            })
        case 2:
            let lo = Int(s.h("lo") ?? 0), hi = Int(s.h("hi") ?? Double(n - 1)), pend = Int(s.h("pend") ?? 0), cx = Int(s.h("cx") ?? 0)
            let now: Numbers = ["lo": Double(lo), "hi": Double(hi), "pend": Double(pend), "cx": Double(cx)]
            return Hands(tap: { q in
                guard let p = g.slot(q), q.y > 0, q.y < BY + 3, cx & (1 << p) == 0 else { return nil }
                let ok = (p == lo && pend != 1) || (p == hi && pend != 2)
                if !ok { return HandMove(hand: now, missHand: now, set: [("x", -1)], check: true) }
                var h = now
                h["cx"] = Double(cx | 1 << p)
                if p == lo { h["lo"] = Double(lo + 1); h["pend"] = pend == 0 ? 1 : 0 } else { h["hi"] = Double(hi - 1); h["pend"] = pend == 0 ? 2 : 0 }
                let l2 = Int(h["lo"]!), h2 = Int(h["hi"]!)
                let done = h["pend"] == 0 && h2 - l2 == (P.odd ? 0 : 1)
                return HandMove(hand: h, missHand: h, set: done ? [("x", 1)] : [], check: done)
            })
        case 5:
            let gr = Double(Int((s.h("g") ?? 0).rounded())), top = Double(P.tallest)
            return Hands(grab: { q in
                q.x >= D8.barX(n - 1) - 0.5 && q.x <= D8.barX(n - 1) + 4.5 && abs(q.y - (BY - top - gr)) < 1.8 ? ["grab": 1, "g": gr] : nil
            }, drag: { q, h in ["grab": 1, "g": Double(min(Median6.room, max(0, Int((BY - q.y).rounded()) - P.tallest)))] },
            release: { h in
                let g2 = h["g"] ?? 0
                if g2 == 0 { return HandMove(hand: ["g": 0], missHand: ["g": 0]) }
                return HandMove(hand: ["g": g2], missHand: ["g": g2], set: [("g", g2)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = G(s.numbers), P = g.P, BY = g.BY, n = P.n
        switch stage(s) {
        case 1:
            // the shortest left to the front, then the next, until they're in order (a selection sort, as a hand does it)
            var o = order(s, P), out: [GhostMove] = []
            for p in 0..<n {
                guard let q = (p..<n).min(by: { (P.v[o[$0]], $0) < (P.v[o[$1]], $1) }), P.v[o[q]] < P.v[o[p]] else { continue }
                out.append(.drag(from: CGPoint(x: D8.barX(q) + 2, y: BY - 1), to: CGPoint(x: D8.barX(p) + 2, y: BY - 1)))
                let b = o.remove(at: q); o.insert(b, at: p)
            }
            return out
        case 2:
            let lo = Int(s.h("lo") ?? 0), hi = Int(s.h("hi") ?? Double(n - 1)), pend = Int(s.h("pend") ?? 0)
            var out: [GhostMove] = [], l = lo, h = hi
            if pend == 1 { out.append(.tap(.picture(CGPoint(x: D8.barX(h) + 2, y: BY - 1)))); h -= 1 }
            if pend == 2 { out.append(.tap(.picture(CGPoint(x: D8.barX(l) + 2, y: BY - 1)))); l += 1 }
            while h - l > (P.odd ? 0 : 1) {
                out.append(.tap(.picture(CGPoint(x: D8.barX(l) + 2, y: BY - 1)))); out.append(.tap(.picture(CGPoint(x: D8.barX(h) + 2, y: BY - 1))))
                l += 1; h -= 1
            }
            return out
        case 5:
            let x = D8.barX(n - 1) + 2, y = BY - Double(P.tallest)
            return [.drag(from: CGPoint(x: x, y: y), to: CGPoint(x: x, y: y - Double(Median6.room)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let n = Median6.Parts(s.numbers).n
        switch stage(s) {
        case 2:
            let now: Numbers = ["lo": s.h("lo") ?? 0, "hi": s.h("hi") ?? Double(n - 1), "pend": s.h("pend") ?? 0, "cx": s.h("cx") ?? 0]
            return HandMove(hand: now, missHand: now, set: [("x", -1)], check: true)
        case 5: return HandMove(hand: ["g": 1], missHand: ["g": 1], set: [("g", 1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Median6.Parts(s.numbers)
        switch stage(s) {
        case 3: return ["s": Double(P.n) / 2]
        case 4: return ["m": P.odd ? P.median + 1 : Double(P.pair.0 + P.pair.1)]
        default: return nil
        }
    }
}
