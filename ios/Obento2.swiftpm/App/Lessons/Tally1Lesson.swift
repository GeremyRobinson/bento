import SwiftUI

/// Tally charts on the paper, as in the preview (design/prototype/grade1-ch5.html, dTally): a mark every 2 squares, 3
/// squares tall; four marks and the fifth across them make a bundle two blocks wide, so bundles line up under bundles.
/// Three rows on block rows, names in front, the title over it. The first three start by making the marks: the things to
/// count sit under the chart; tap each one and its row gets a mark (it fades where it was). Then the web's ask: read a row
/// (tap each bundle, "5, 10", then each single mark, "11, 12"; a single before the bundles is said), how many more (tap the
/// marks past the shorter row's end, a dashed line dropping from it), in all (tap each row in turn, top to bottom: each
/// row's count at its end, the running total beside the chart); then write it with the digit pad.
///
/// Kept: "t<i>" the things tapped, in order; "b<i>" the bundles tapped; "sg" the single marks counted; "ex" the marks past
/// the end; "tr" the rows tapped in turn; "chk".
@MainActor
struct Tally1Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let tx = 10.0, bot = 17.0, rec = 21.0, padY = 24.0
    static func rowY(_ r: Int) -> Double { 2 + 5 * Double(r) }
    static func right(_ n: Int) -> Double { L5.markRight(n, x0: tx) }
    static func pileAt(_ k: Int) -> CGPoint { CGPoint(x: 3.5 + 4 * Double(k % 12), y: bot + 4 + 4 * Double(k / 12)) }
    static func rowAt(_ q: CGPoint) -> Int? { (0..<3).first { q.y >= rowY($0) + 0.3 && q.y <= rowY($0) + 4.7 && q.x >= tx - 10 && q.x <= tx + 32 } }

    private func thingRow(_ P: Tally1.Parts, _ id: Int) -> Int { id < P.c[0] ? 0 : id < P.c[0] + P.c[1] ? 1 : 2 }
    private func shown(_ s: PaperState, _ P: Tally1.Parts) -> [Int] {
        guard P.make && at(s) == 0 else { return P.c }
        let perm = Len1.pile(P.sum, seed: P.seed)
        var out = [0, 0, 0]
        for k in KA.list(s, "t") { out[thingRow(P, perm[k])] += 1 }
        return out
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        switch at(s) {
        case 2: return DigitPad.checkAt(x: 0, y: Self.padY)
        case 3: return CGPoint(x: 0, y: Self.padY)
        default: return nil
        }
    }

    private func toks(_ P: Tally1.Parts, _ last: A1.Tok) -> [A1.Tok] {
        P.ask == 1 ? [.n(P.c[P.x]), .op("−"), .n(P.c[P.y]), .op("="), last] : [.n(P.c[0]), .op("+"), .n(P.c[1]), .op("+"), .n(P.c[2]), .op("="), last]
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Tally1.Parts(s.numbers), st = at(s), th = P.th, tx = Self.tx, k = s.run.kept
        var pic = GridPen()
        let sh = shown(s, P)
        pic.word("title", th.title, at: tx + 15, 0.5, PicGraph1Lesson.small)
        pic.line("axis", [(tx, Self.rowY(0) + 0.5), (tx, Self.bot - 0.5)])
        let bundles = P.ask == 0 ? (st == 1 ? KA.list(s, "b") : st >= 2 ? Array(0..<P.five) : []) : []
        let singles = P.ask == 0 ? (st == 1 ? Int(k["sg"] ?? 0) : st >= 2 ? P.rest : 0) : 0
        let extra = P.ask == 1 ? (st == 1 ? Int(k["ex"] ?? 0) : st >= 2 ? P.c[P.x] - P.c[P.y] : 0) : 0
        let tapped = P.ask == 2 ? (st == 1 ? Int(k["tr"] ?? 0) : st >= 2 ? 3 : 0) : 0
        for r in 0..<3 {
            let y = Self.rowY(r)
            pic.word("nm\(r)", th.names[r], at: tx - 1, y + 2.5, PicGraph1Lesson.small, anchor: UnitPoint(x: 1, y: 0.5))
            if r < tapped { pic.fill("rt\(r)", col: tx - 0.5, row: y + 0.5, w: Self.right(P.c[r]) - tx + 1, h: 4, .tint(0.2)) }
            if r == P.x { for b in bundles { pic.fill("bt\(b)", col: tx + 10 * Double(b) - 0.5, row: y + 0.5, w: 9, h: 4, .tint(0.2)) } }
            for i in 0..<sh[r] {
                let lit = r == P.x && ((P.ask == 0 && i >= 5 * P.five && i < 5 * P.five + singles) || (P.ask == 1 && i >= P.c[P.y] && i < P.c[P.y] + extra))
                L5.mark(&pic, "m\(r)-\(i)\(lit ? "L" : "")", i, x0: tx, y: y, lit ? .chapter : .ink)
            }
            if st == 0 && P.make && sh[r] > 0 { A1.note(&pic, "sc\(r)", "\(sh[r])", x: Self.right(sh[r]) + 1, y: y + 2.5) }
            if r < tapped { A1.note(&pic, "rc\(r)", "\(P.c[r])", x: Self.right(P.c[r]) + 1, y: y + 2.5) }
        }
        if st == 0 && P.make {
            let perm = Len1.pile(P.sum, seed: P.seed), used = KA.list(s, "t")
            for kk in 0..<P.sum { let c = Self.pileAt(kk); L5.icon(&pic, "th\(kk)", th.icons[thingRow(P, perm[kk])], c.x, c.y, faint: used.contains(kk)) }
        }
        // readouts beside the chart: the count along the row; how many more; the running total
        if P.ask == 0 && (!bundles.isEmpty || singles > 0) {
            let run = (0..<bundles.count).map { 5 * ($0 + 1) } + (0..<singles).map { 5 * P.five + $0 + 1 }
            A1.note(&pic, "run", Len1.run(run), x: Self.right(P.n) + 1, y: Self.rowY(P.x) + 2.5)
        }
        if extra > 0 { A1.note(&pic, "ex", "\(extra) more", x: Self.right(P.c[P.x]) + 1, y: Self.rowY(P.x) + 2.5) }
        if tapped > 0 {
            let totals = (1...tapped).map { t in P.c.prefix(t).reduce(0, +) }.map(String.init).joined(separator: ", ")
            A1.note(&pic, "tot", totals, x: tx + 33, y: Self.rowY(1) + 2.5)
        }
        if st == 1 && P.ask == 1 {
            let gxl = Self.right(P.c[P.y])
            pic.line("guide", [(gxl, min(Self.rowY(P.x), Self.rowY(P.y)) + 0.5), (gxl, max(Self.rowY(P.x), Self.rowY(P.y)) + 4.5)], .ink3, dashed: true)
        }
        let yx = Self.rowY(P.x)
        switch st {
        case 1:
            switch P.ask {
            case 0:
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: tx, y: yx + 0.5, w: Self.right(P.n) - tx, h: 4) }
                if s.on("spot") {
                    if bundles.count < P.five, let b = (0..<P.five).first(where: { !bundles.contains($0) }) { KK.hintBox(&pic, "spot", x: tx + 10 * Double(b), y: yx + 0.5, w: 8, h: 4) }
                    else { KK.hint(&pic, "spot", tx + 10 * Double(P.five) + 1 + 2 * Double(singles), yx + 2.5, radius: 1.4) }
                }
            case 1:
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Self.right(P.c[P.y]), y: yx + 0.5, w: Self.right(P.c[P.x]) - Self.right(P.c[P.y]), h: 4) }
                if s.on("spot") { let i = P.c[P.y] + extra; KK.hint(&pic, "spot", tx + 10 * Double(i / 5) + (i % 5 == 4 ? 4 : 1 + 2 * Double(i % 5)), yx + 2.5, radius: 1.4) }
            default:
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: tx, y: Self.rowY(0) + 0.5, w: 30, h: 14) }
                if s.on("spot") && tapped < 3 { KK.hintBox(&pic, "spot", x: tx, y: Self.rowY(tapped) + 0.5, w: Self.right(P.c[tapped]) - tx, h: 4) }
            }
        case 2:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.answer)
            if P.ask == 0 { KK.line(&pic, "rec", [.w("\(P.X):")], value: v, wrong: wrong, x: 0, line: Self.rec) }
            else { A1.record(&pic, "rec", toks(P, .box(v, wrong: wrong)), x: 0, line: Self.rec) }
            DigitPad.draw(&pic, "pad", x: 0, y: Self.padY)
            if s.on("ring") && !s.on("spot") {
                if P.ask == 2 { KK.hintBox(&pic, "hr", x: tx, y: Self.rowY(0) + 0.5, w: 30, h: 14) } else { KK.hintBox(&pic, "hr", x: tx, y: yx + 0.5, w: Self.right(P.c[P.x]) - tx, h: 4) }
            }
            if s.on("spot") { A1.note(&pic, "spot", "\(P.answer)", x: DigitPad.width + 13.5, y: Self.padY + 2) }
        case 3:
            if P.ask == 0 { M7.row(&pic, "rec", [.w("\(P.X):"), .n(P.n, .chapter)], x: 0, line: Self.rec) }
            else { A1.record(&pic, "rec", toks(P, .n(P.answer, .chapter)), x: 0, line: Self.rec) }
        default: break
        }
        var right = tx + 30.0
        for r in 0..<3 { right = max(right, Self.right(P.c[r]) + 1 + L5.smallWidth(P.ask == 0 && r == P.x ? "5, 10 … 14" : "5 more")) }
        if P.ask == 2 { right = max(right, tx + 33 + L5.smallWidth("10, 13, 20")) }
        if st == 0 && P.make { right = max(right, 3.5 + 4 * 11 + 2) }
        let bottom = st == 0 && P.make ? Self.bot + 2 + 4 * Double((P.sum + 11) / 12) : Self.bot
        return PaperDrawing(picture: pic.sketch, actions: st == 2 ? ["Check"] : [], extent: pic.R(0, -0.5, right, bottom + 0.5))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Tally1.Parts(s.numbers), st = at(s), tx = Self.tx, k = s.run.kept
        switch st {
        case 0:
            let used = KA.list(s, "t")
            return Hands(tap: { q in
                guard let kk = (0..<P.sum).first(where: { let c = Self.pileAt($0); return !used.contains($0) && abs(q.x - c.x) <= 2 && abs(q.y - c.y) <= 2 }) else { return nil }
                let all = used.count + 1 == P.sum
                return HandMove(hand: nil, missHand: nil, set: all ? [("mk", Double(P.sum))] : [], keep: ["t\(used.count)": Double(kk)], check: all)
            })
        case 1:
            return Hands(tap: { q in
                guard let r = Self.rowAt(q) else { return nil }
                switch P.ask {
                case 0:
                    if r != P.x { return HandMove(hand: nil, missHand: nil, set: [("k", Double(10 + r))], check: true) }
                    let bundles = KA.list(s, "b"), sg = Int(k["sg"] ?? 0)
                    var keep: Numbers = [:], nb = bundles.count, ns = sg
                    if q.x >= tx - 0.5 && q.x < tx + 10 * Double(P.five) - 1 {
                        let b = max(0, min(P.five - 1, Int(((q.x - tx) / 10).rounded(.down))))
                        guard !bundles.contains(b) else { return HandMove(hand: nil) }
                        keep["b\(nb)"] = Double(b); nb += 1
                    } else if q.x >= tx + 10 * Double(P.five) - 1.5 && q.x <= Self.right(P.n) + 1.5 {
                        if nb < P.five { return HandMove(hand: nil, missHand: nil, set: [("k", -1)], check: true) }
                        guard ns < P.rest else { return HandMove(hand: nil) }
                        ns += 1; keep["sg"] = Double(ns)
                    } else { return HandMove(hand: nil) }
                    let all = nb == P.five && ns == P.rest
                    return HandMove(hand: nil, missHand: nil, set: all ? [("k", Double(P.n))] : [], keep: keep, check: all)
                case 1:
                    if r != P.x { return HandMove(hand: nil, missHand: nil, set: [("m", Double(10 + r))], check: true) }
                    if q.x <= Self.right(P.c[P.y]) + 0.2 { return HandMove(hand: nil, missHand: nil, set: [("m", -1)], check: true) }
                    let ex = Int(k["ex"] ?? 0), d = P.c[P.x] - P.c[P.y]
                    guard q.x <= Self.right(P.c[P.x]) + 1.5, ex < d else { return HandMove(hand: nil) }
                    return HandMove(hand: nil, missHand: nil, set: ex + 1 == d ? [("m", Double(d))] : [], keep: ["ex": Double(ex + 1)], check: ex + 1 == d)
                default:
                    let tr = Int(k["tr"] ?? 0)
                    if r < tr { return HandMove(hand: nil) }
                    if r != tr { return HandMove(hand: nil, missHand: nil, set: [("t", -1)], check: true) }
                    return HandMove(hand: nil, missHand: nil, set: tr + 1 == 3 ? [("t", 3)] : [], keep: ["tr": Double(tr + 1)], check: tr + 1 == 3)
                }
            })
        case 2: return DigitPad.hands(s, "x", want: P.answer, x: 0, y: Self.padY)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Tally1.Parts(s.numbers), tx = Self.tx, k = s.run.kept, yx = Self.rowY(P.x) + 2.5
        switch at(s) {
        case 0:
            let used = KA.list(s, "t")
            return (0..<P.sum).filter { !used.contains($0) }.map { .tap(.picture(Self.pileAt($0))) }
        case 1:
            switch P.ask {
            case 0:
                let bundles = KA.list(s, "b"), sg = Int(k["sg"] ?? 0)
                let b = (0..<P.five).filter { !bundles.contains($0) }.map { GhostMove.tap(.picture(CGPoint(x: tx + 10 * Double($0) + 4, y: yx))) }
                return b + (sg..<P.rest).map { .tap(.picture(CGPoint(x: tx + 10 * Double(P.five) + 1 + 2 * Double($0), y: yx))) }
            case 1:
                let ex = Int(k["ex"] ?? 0)
                return ((P.c[P.y] + ex)..<P.c[P.x]).map { i in .tap(.picture(CGPoint(x: Self.right(i + 1) - 0.5, y: yx))) }
            default:
                return (Int(k["tr"] ?? 0)..<3).map { .tap(.picture(CGPoint(x: tx + 3, y: Self.rowY($0) + 2.5))) }
            }
        case 2: return DigitPad.demo(P.answer, x: 0, y: Self.padY)
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Tally1.Parts(s.numbers)
        switch at(s) {
        case 1:
            switch P.ask {
            case 0: return HandMove(hand: nil, missHand: nil, set: [("k", P.five > 0 && Int(s.run.kept["sg"] ?? 0) == 0 && KA.list(s, "b").isEmpty && P.rest > 0 ? -1 : Double(10 + P.y))], check: true)
            case 1: return HandMove(hand: nil, missHand: nil, set: [("m", -1)], check: true)
            default: return HandMove(hand: nil, missHand: nil, set: [("t", -1)], check: true)
            }
        case 2:
            let slip = P.slips.first?.0 ?? P.answer + 1
            return HandMove(hand: nil, missHand: nil, set: [("x", Double(slip))], keep: ["chk": Double(slip)], check: true)
        default: return nil
        }
    }
}
