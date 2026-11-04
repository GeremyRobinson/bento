import SwiftUI

/// Adding and subtracting decimals on the paper, as in the preview (design/prototype/grade6-ch3.html, dAddSub): five
/// place columns (tens to thousandths), each 2 blocks wide, their names over them, the point on the strong line between
/// the ones and the tenths. a's digits with its discs under them (a disc, a 2 × 2 cell, is one of its column's place), b
/// the same under it, the line, the answer under it. Tap each empty place to write a 0 ("12.4 is 12.400"); slide b's
/// discs up into a's (they pour in a column at a time); adding: tap ten and they close into one disc of the next place;
/// taking away: the covered discs are crossed out, and a short column waits while one of the place to its left is
/// broken into ten. The school's marks come with the hands: a broken digit crossed out and written again small over
/// it, a carry written small over its place. Then the answer is typed under the line, each digit in its column.
///
/// Everything (the record too) is in the picture's squares (recordRow 0). Hand keys: "fa"/"fb" (0s written), "ox"/"oy"
/// (b's discs held), "nc" with "c0"… (columns closed), "nb" (breaks made).
@MainActor
struct DecAddSubLesson: PaperLesson {
    static let names = 0.6, YA = 4.0, BA = 5.0, YB = 15.0, BB = 16.0, YL = 21.0, YR = 23.0
    static func col(_ e: Int) -> Double { Double(1 - e) * 10 }
    var liveKeys: Set<String> { ["ox", "oy", "x0", "y0"] }

    private static let small = R6.small, lit = R6.lit, maths = Record.maths, red = Bars.red
    private static let mark = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func phase(_ s: PaperState) -> Int { Int((s.picture["ph"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? { stage(s) >= 5 ? CGPoint(x: 0, y: Self.YR + 2) : nil }

    /// The columns as they are now: the phase's start with the hand's taps made on it.
    private func cols(_ s: PaperState, _ P: DecAddSub6.Parts) -> DecAddSub6.Cols {
        let at = stage(s), ph = P.phases
        if at <= 1 { return P.start }
        if at >= 5 { return ph.end }
        var c = ph.before[min(phase(s), ph.before.count - 1)]
        if at == 3 { for i in 0..<Int(s.h("nc") ?? 0) { c.close(Int((s.h("c\(i)") ?? 0).rounded())) } }
        if at == 4, let n = c.needy { for _ in 0..<Int(s.h("nb") ?? 0) { if let l = c.lender(n) { c.breakOne(l) } } }
        return c
    }

    // MARK: drawing

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = DecAddSub6.Parts(s.numbers), at = stage(s), C = cols(s, P), done = at == 6, add = P.add
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let places = DecAddSub6.places

        // the columns, their names, the point's line
        for e in places { pic.word("cn\(e)", Place6.name(e), at: Self.col(e) + 5, Self.names, Self.small) }
        for e in [0, -2, -3] { pic.line("cl\(e)", [(Self.col(e), 1.4), (Self.col(e), Self.YL)], .ink3) }
        pic.line("cpt", [(20, 1.4), (20, Self.YR + 1.5)], .ink2)

        // the numbers: their digits at the top of each band, the 0s written, the school's marks over a's digits
        let fa = at == 1 ? Int(s.h("fa") ?? 0) : at == 0 ? 0 : P.needA, fb = at == 1 ? Int(s.h("fb") ?? 0) : at == 0 ? 0 : P.needB
        var marks: [Int: Int] = [:]
        if !add { for e in places where (C.broke[e] ?? 0) != 0 { marks[e] = P.a.digit(e) + (C.broke[e] ?? 0) } }
        number(&rec, "ra", P.a, y: Self.YA, filled: fa, marks: marks)
        number(&rec, "rb", P.b, y: Self.YB, filled: fb, marks: [:])
        rec.word("op", add ? "+" : "−", at: 1, Self.YB, Self.maths)
        if add { for e in places where (C.carried[e] ?? 0) > 0 { rec.word("car\(e)", "\(C.carried[e] ?? 0)", at: Self.col(e) + 5, Self.YA - 1.75, Self.mark) } }
        // what the 0s make, beside the row being filled
        if at == 1 {
            if fa > 0 { pic.word("fra\(fa)", "\(P.a.s) is \(Self.filled(P.a, fa))", at: 51.5, Self.YA, Self.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
            if fb > 0 { pic.word("frb\(fb)", "\(P.b.s) is \(Self.filled(P.b, fb))", at: 51.5, Self.YB, Self.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
            // a hint: the number to fill ringed; a second miss, each empty place
            let row = P.needA > fa ? Self.YA : Self.YB, x = P.needA > fa ? P.a : P.b, f = P.needA > fa ? fa : fb, need = P.needA > fa ? P.needA : P.needB
            if s.on("ring") { R6.ring(&pic, "ring", x: 0, y: row - 1, w: 50, h: 2) }
            if s.on("spot") { for k in (f + 1)...max(f + 1, need) where k <= need { pic.circle("sp\(k)", at: Self.col(-x.p - k) + 5, row, radius: 1.3, .chapter, dashed: true) } }
        }

        // the discs: a's (and what slid in) on top, b's waiting under them (in the hand while they're held)
        let slidOn = at >= 3 || (at == 2 && phase(s) > 0) || done || at == 5
        for e in places {
            var seen: [Int: Int] = [:]
            let items = C.items[e] ?? [], lv = C.live(e)
            for (j, kind) in items.enumerated() {
                let o = seen[kind, default: 0]; seen[kind] = o + 1
                disc(&pic, "d\(kind)_\(e)_\(o)", at: Self.at(e, j, Self.BA), kind: kind, crossed: j >= lv)
            }
            let w = C.waiting[e] ?? 0, held = at == 2 && s.grabbed
            let off = CGPoint(x: s.h("ox") ?? 0, y: s.h("oy") ?? 0)
            for j in 0..<w {
                let p = Self.at(e, j, Self.BB), q = held ? CGPoint(x: p.x + off.x, y: p.y + off.y) : p
                // b's j-th disc keeps its id when it slides in (it's the j-th of b's there), so it glides up
                if held { disc(&live, "d1_\(e)_\((items.filter { $0 == 1 }.count) + j)", at: q, kind: 1, crossed: false) }
                else { disc(&pic, "d1_\(e)_\((items.filter { $0 == 1 }.count) + j)", at: q, kind: 1, crossed: false) }
            }
            // a column's count once the discs have slid: what's there (adding), what's left (taking away)
            if slidOn && (!items.isEmpty || (C.carried[e] ?? 0) > 0) {
                let rows = max(1, (items.count + 4) / 5)
                pic.word("cnt\(e)_\(lv)_\(items.count)", add ? "\(lv)" : "\(lv) left", at: Self.col(e) + 0.4, Self.BA + 2 * Double(rows) + 0.6, Self.lit, anchor: UnitPoint(x: 0, y: 0.5))
            }
        }
        // the column that needs breaking into: its waiting discs outlined; the ten to close outlined
        if at == 4, let n = C.needy {
            pic.sketch.box("need\(n)", pic.R(Self.col(n), Self.BB, 10, Double((C.waiting[n] ?? 0) + 4) / 5 * 2), .ink2, width: Sketch.stroke)
            if s.on("ring") { R6.ring(&pic, "ring", x: Self.col(n), y: Self.BA, w: 10, h: Self.BB - Self.BA + 4) }
            if s.on("spot"), let l = C.lender(n) { let p = Self.at(l, C.live(l) - 1, Self.BA); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        }
        if at == 3, let e = C.full {
            if s.on("ring") || s.on("spot") { R6.ring(&pic, "ring", x: Self.col(e), y: Self.BA, w: 10, h: 8) }
            if s.on("spot") { pic.sketch.box("ten\(e)", pic.R(Self.col(e), Self.BA, 10, 4), .chapter, width: Sketch.stroke, dashed: true) }
        }
        if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: 0, y: Self.BB, w: 50, h: 4) }
        if at == 2 && s.on("spot") { R6.ring(&pic, "spot", x: 0, y: Self.BA, w: 50, h: 4) }
        if at == 5 && s.on("ring") { R6.ring(&pic, "ring", x: 0, y: Self.BA, w: 50, h: Self.BB - Self.BA - 1) }

        // the line, the answer under it: typed into its columns, then written in the chapter's colour
        rec.rule("ans", from: 0, to: 50, row: Self.YL)
        let Rtop = P.R >= 10 * Dec6.pow10(P.P) ? 1 : 0, cells = Rtop + 1 + P.P
        if at == 5 {
            rec.answerBox("t", right: Self.col(-P.P) + 10, mid: Self.YR, per: 2, cells: cells, point: 20, step: 10)
        } else if done {
            let str = P.answer.s.contains(".") || P.P == 0 ? P.answer.s : P.answer.s
            let parts = str.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            let ip = Array(parts[0]), fp = Array(parts.count > 1 ? parts[1] : "")
            for (i, ch) in ip.enumerated() { rec.word("av\(i)", String(ch), at: Self.col(ip.count - 1 - i) + 5, Self.YR, Self.maths.colour(.chapter)) }
            for (i, ch) in fp.enumerated() { rec.word("aw\(i)", String(ch), at: Self.col(-1 - i) + 5, Self.YR, Self.maths.colour(.chapter)) }
            if !fp.isEmpty { rec.digits("apt", ".", right: 20, row: Self.YR, per: 2, .chapter) }
        }
        let extent = pic.R(0, 0, 51.5 + R6.width("\(P.a.s) is \(Self.filled(P.a, P.needA))", Self.lit) + 0.5, Self.YR + 1.5)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    static func filled(_ x: Dec6, _ f: Int) -> String { x.s + (x.p > 0 ? "" : ".") + String(repeating: "0", count: f) }
    /// Where a disc goes: column e, its j-th place in a band (5 across, 2 squares apart).
    static func at(_ e: Int, _ j: Int, _ band: Double) -> CGPoint { CGPoint(x: col(e) + 1 + 2 * Double(j % 5), y: band + 1 + 2 * Double(j / 5)) }

    /// A number's digits in their columns' middles, the 0s written after it, its point on the point's line; a broken
    /// digit crossed out with what it is now written small over it.
    private func number(_ pen: inout GridPen, _ id: String, _ x: Dec6, y: Double, filled: Int, marks: [Int: Int]) {
        let parts = x.s.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let ip = Array(parts[0]), fp = Array(parts.count > 1 ? parts[1] : "")
        var ds: [Int: String] = [:]
        for (i, ch) in ip.enumerated() { ds[ip.count - 1 - i] = String(ch) }
        for (i, ch) in fp.enumerated() { ds[-1 - i] = String(ch) }
        if filled > 0 { for f in 1...filled { ds[-x.p - f] = "0" } }
        for (e, ch) in ds {
            let cx = Self.col(e) + 5, m = marks[e]
            pen.word("\(id)\(e)\(m != nil)", ch, at: cx, y, Self.maths.colour(m != nil ? .ink2 : (e < -x.p ? .chapter : .ink)))
            if let m {
                pen.line("\(id)x\(e)", [(cx - 1, y + 0.8), (cx + 1, y - 0.8)])
                pen.word("\(id)m\(e)_\(m)", "\(m)", at: cx, y - 1.75, Self.mark)
            }
        }
        if x.p > 0 || filled > 0 { pen.digits("\(id)pt", ".", right: 20, row: y, per: 2) }
    }

    /// A disc: a's tinted, b's lighter, a new one (closed or broken into) darker; crossed out, an outline struck through.
    private func disc(_ pen: inout GridPen, _ id: String, at p: CGPoint, kind: Int, crossed: Bool) {
        if crossed {
            pen.circle(id + "x", at: p.x, p.y, radius: 0.75, .ink3)
            pen.line(id + "xs", [(p.x - 0.75, p.y + 0.75), (p.x + 0.75, p.y - 0.75)], .ink2)
            return
        }
        pen.dot(id + "f", at: p.x, p.y, radius: 0.75, kind == 1 ? .tint(0.18) : kind == 2 ? .tint(0.5) : .tint(0.32))
        pen.circle(id + "o", at: p.x, p.y, radius: 0.75, .chapter)
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let P = DecAddSub6.Parts(s.numbers), at = stage(s), C = cols(s, P)
        func column(_ q: CGPoint) -> Int? { DecAddSub6.places.first { q.x >= Self.col($0) && q.x < Self.col($0) + 10 } }
        switch at {
        case 1:
            let fa = Int(s.h("fa") ?? 0), fb = Int(s.h("fb") ?? 0)
            return Hands(tap: { q in
                guard let e = column(q) else { return nil }
                let rowA = abs(q.y - Self.YA) <= 1.5, rowB = abs(q.y - Self.YB) <= 1.5
                guard rowA || rowB else { return nil }
                let x = rowA ? P.a : P.b, need = rowA ? P.needA : P.needB, k = -e - x.p
                var h: Numbers = ["fa": Double(fa), "fb": Double(fb)]
                if k >= 1 && k <= need {
                    if rowA { h["fa"] = Double(max(fa, k)) } else { h["fb"] = Double(max(fb, k)) }
                    if Int(h["fa"] ?? 0) == P.needA && Int(h["fb"] ?? 0) == P.needB { return HandMove(hand: h, missHand: nil, set: [("x", 1)], check: true) }
                    return HandMove(hand: h, missHand: nil)
                }
                if e > DecAddSub6.Parts.top(x) { return HandMove(hand: h, missHand: nil, set: [("x", rowA ? 2 : 3)], check: true) }
                if k > need { return HandMove(hand: h, missHand: nil, set: [("x", 4)], check: true) }
                return nil
            })
        case 2:
            return Hands(
                grab: { q in q.x >= -1 && q.x <= 51 && q.y >= Self.YB - 1.5 && q.y <= Self.BB + 5 ? ["grab": 1, "x0": q.x, "y0": q.y, "ox": 0, "oy": 0] : nil },
                drag: { q, h in
                    var h = h
                    h["ox"] = (q.x - (h["x0"] ?? q.x)).rounded(); h["oy"] = min(0, q.y - (h["y0"] ?? q.y)).rounded()
                    return h
                },
                release: { h in
                    let up = (h["oy"] ?? 0) < -(Self.BB - Self.BA - 4)
                    return HandMove(hand: [:], missHand: [:], set: [("x", up ? 1 : 0)], check: true)
                })
        case 3:
            let nc = Int(s.h("nc") ?? 0)
            return Hands(tap: { q in
                guard let e = column(q), q.y >= Self.BA - 2, q.y <= Self.BA + 8.5 else { return nil }
                var h = s.hand
                let n = C.items[e]?.count ?? 0
                if n < 10 { return HandMove(hand: h, missHand: nil, set: [("x", Double(1000 + 100 * (e + 3) + n))], check: true) }
                var c = C; c.close(e)
                h["c\(nc)"] = Double(e); h["nc"] = Double(nc + 1)
                if c.full == nil { return HandMove(hand: h, missHand: nil, set: [("x", 1)], check: true) }
                return HandMove(hand: h, missHand: nil)
            })
        case 4:
            guard let n = C.needy else { return nil }
            let nb = Int(s.h("nb") ?? 0)
            return Hands(tap: { q in
                guard let e = column(q), q.y >= Self.BA - 2, q.y <= Self.BA + 8.5 else { return nil }
                let h = s.hand
                if e <= n { return HandMove(hand: h, missHand: nil, set: [("x", 2)], check: true) }
                guard let lend = C.lender(n) else { return nil }
                if e != lend { return HandMove(hand: h, missHand: nil, set: [("x", Double((C.live(e) == 0 ? 2000 : 3000) + 10 * (e + 3) + lend + 3))], check: true) }
                var c = C; c.breakOne(lend)
                let now: Numbers = ["nb": Double(nb + 1)]
                if c.live(n) >= (c.waiting[n] ?? 0) { return HandMove(hand: now, missHand: nil, set: [("x", 1)], check: true) }
                return HandMove(hand: now, missHand: nil)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = DecAddSub6.Parts(s.numbers), at = stage(s), C = cols(s, P)
        switch at {
        case 1:
            let fa = Int(s.h("fa") ?? 0), fb = Int(s.h("fb") ?? 0)
            var out: [GhostMove] = []
            if P.needA > fa { out.append(.tap(.picture(CGPoint(x: Self.col(-P.a.p - P.needA) + 5, y: Self.YA)))) }
            if P.needB > fb { out.append(.tap(.picture(CGPoint(x: Self.col(-P.b.p - P.needB) + 5, y: Self.YB)))) }
            return out
        case 2: return [.drag(from: CGPoint(x: 25, y: Self.BB + 1), to: CGPoint(x: 25, y: Self.BA + 1))]
        case 3:
            var c = C, out: [GhostMove] = []
            while let e = c.full { out.append(.tap(.picture(Self.at(e, 2, Self.BA)))); c.close(e) }
            return out
        case 4:
            guard let n = C.needy else { return [] }
            var c = C, out: [GhostMove] = []
            while c.live(n) < (c.waiting[n] ?? 0), let l = c.lender(n) { out.append(.tap(.picture(Self.at(l, max(0, c.live(l) - 1), Self.BA)))); c.breakOne(l) }
            return out
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = DecAddSub6.Parts(s.numbers), at = stage(s), C = cols(s, P)
        switch at {
        case 1: return HandMove(hand: s.hand, missHand: nil, set: [("x", P.needA > 0 ? 2 : 3)], check: true)
        case 3:
            let e = DecAddSub6.places.first { (C.items[$0]?.count ?? 0) < 10 && (C.items[$0]?.count ?? 0) > 0 } ?? 1
            return HandMove(hand: s.hand, missHand: nil, set: [("x", Double(1000 + 100 * (e + 3) + (C.items[e]?.count ?? 0)))], check: true)
        case 4:
            guard let n = C.needy else { return nil }
            return HandMove(hand: s.hand, missHand: nil, set: [("x", n > -3 ? 2 : 2)], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        guard stage(s) == 5 else { return nil }
        let P = DecAddSub6.Parts(s.numbers)
        let naive = DecAddSub6.places.reduce(0) { $0 + (P.add ? (P.a.digit($1) + P.b.digit($1)) % 10 : abs(P.a.digit($1) - P.b.digit($1))) * Dec6.pow10($1 + P.P) }
        return ["t": Dec6(naive == P.R ? P.R + 1 : naive, P.P).double]
    }
}
