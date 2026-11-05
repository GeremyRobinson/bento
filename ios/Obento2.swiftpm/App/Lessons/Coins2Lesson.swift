import SwiftUI

/// Name the coin on the paper, as in the preview (design/prototype/grade2-ch6.html, dCoins): the coins true to each other's
/// size (a dime 15 squares across, a penny 16, a nickel 18, a quarter 20), the coin big and centred on a block corner, four name
/// blocks under it. Tap its name: its edge traces in the chapter colour. Then `A dime is [10]¢` where the blocks were, and its
/// cents draw beside it, five to a row. The pair: two coins side by side, both names (written under each), then tap the one
/// worth more; each one's name and worth under it, its cents under that.
///
/// Kept: "wn" a name tapped and wrong, "wo" a coin tapped and wrong.
@MainActor
struct Coins2Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let cy = 10.0, nb = 21.0, rr = 23.0
    private static func cx(_ P: Coins2.Parts, _ j: Int) -> Double { P.pair ? [10.0, 35.0][j] : 20 }
    private static func names(_ P: Coins2.Parts) -> [CGRect] {
        let x0 = P.pair ? 5.0 : 0
        var out: [CGRect] = []
        for i in 0..<4 { out.append(CGRect(x: x0 + 10 * Double(i), y: P.pair ? nb + 2 : nb, width: 8, height: 4)) }
        return out
    }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    private func lead(_ P: Coins2.Parts) -> M7.Tok { .w("A \(P.a.name) is") }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Coins2.Parts(s.numbers), st = at(s)
        if P.pair { return st == 4 ? CGPoint(x: 55, y: Self.nb + 2) : nil }
        guard st >= 3 else { return nil }
        let toks: [M7.Tok] = [lead(P), .box("x", cells: 2), .t("¢")]
        return CGPoint(x: EG2.ceil5(M7.width(toks) + 1), y: Self.rr - 1)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Coins2.Parts(s.numbers), st = at(s)
        var pic = GridPen(), rec = GridPen()
        let wo = st == 2 ? s.run.kept["wo"].map { Int($0) } : nil
        for (j, c) in P.shown.enumerated() {
            let r = Double(TM2.coins[c].across) / 2, x = Self.cx(P, j), bad = wo == j
            TMK.coin(&pic, "c\(j)", c, cx: x, cy: Self.cy, r: r, side: P.side, rim: bad ? KK.red : .ink)
            // named: its edge traces in the chapter colour
            let named = P.pair ? st > j : st >= 3
            if named { pic.line("edge\(j)\(bad)", TMK.ring(x, Self.cy, r), bad ? KK.red : .chapter) }
            if P.pair && named {
                let w = st == 4 ? "\(TM2.coins[c].name), \(TM2.coins[c].value)¢" : TM2.coins[c].name
                pic.word("nm\(j)\(w)", w, at: x, Self.cy + 11, KK.words)
            }
        }
        // the four name blocks, until the naming is done
        let naming = P.pair ? st < 2 : st == 0
        let wn = s.run.kept["wn"].map { Int($0) }
        if naming {
            for (i, r) in Self.names(P).enumerated() { E1.block(&pic, "nb\(i)", x: r.minX, y: r.minY, w: r.width, TM2.coins[i].name, wrong: wn == i) }
        }
        // its cents, five to a row: beside the one coin, or under both
        func cents(_ id: String, _ v: Int, x: Double, y: Double, per: Int = 5) {
            for n in 0..<v { TMK.cent(&pic, "\(id)\(n)", x: x + 3 * Double(n % per), y: y + 3 * Double(n / per)) }
        }
        if !P.pair && st == 4 {
            let v = P.a.value, rows = (v + 4) / 5
            cents("ce", v, x: 35, y: Self.cy - (1.5 * Double(rows)).rounded())
        }
        if P.pair && st == 4 {
            // under both: a quarter's 25 in rows of 10, so the pair still shows at 75%; the right one's start clear of the left's
            var end = -2.0
            for (j, c) in P.shown.enumerated() {
                let v = TM2.coins[c].value, per = v == 25 ? 10 : 5, w = 3 * Double(min(v, per))
                let x = max(end + 2, max(0, Self.cx(P, j) - w / 2))
                cents("ce\(j):", v, x: x, y: Self.nb + 2, per: per)
                end = x + w
            }
        }
        // the record: A dime is [10]¢
        if !P.pair && st >= 3 {
            let toks: [M7.Tok] = st == 3 ? [lead(P), .box("x", cells: 2), .t("¢")] : [lead(P), .t("\(P.a.value)¢", .chapter)]
            if st == 3 { M7.row(&rec, "rec", toks, x: 0, line: Self.rr) } else { M7.row(&pic, "rec", toks, x: 0, line: Self.rr) }
        }
        // hints: a first miss rings the coin (or both), a second the name block or the coin worth more (or the worth by the box)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        let j = P.pair && st == 1 ? 1 : 0, r0 = Double(TM2.coins[P.shown[j]].across) / 2
        if naming {
            if ring { KK.hint(&pic, "hr", Self.cx(P, j), Self.cy, radius: r0 + 1) }
            if spot { let r = Self.names(P)[P.shown[j]]; KK.hintBox(&pic, "spot", x: r.minX, y: r.minY, w: r.width, h: r.height) }
        }
        if st == 2 {
            if ring { for (k, c) in P.shown.enumerated() { KK.hint(&pic, "hr\(k)", Self.cx(P, k), Self.cy, radius: Double(TM2.coins[c].across) / 2 + 1) } }
            if spot { KK.hint(&pic, "spot", Self.cx(P, P.right), Self.cy, radius: Double(TM2.coins[P.shown[P.right]].across) / 2 + 1) }
        }
        if st == 3 {
            if ring { KK.hint(&pic, "hr", Self.cx(P, 0), Self.cy, radius: r0 + 1) }
            if spot { A1.note(&pic, "spot", "\(P.a.value)", x: M7.width([lead(P)]), y: Self.rr - 2.6) }
        }
        let right = P.pair ? (st == 4 ? 65.0 : 45) : 50
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, right, Self.nb + (P.pair ? 6 : 4)))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Coins2.Parts(s.numbers), st = at(s)
        if (P.pair && st < 2) || (!P.pair && st == 0) {
            let box = st == 1 ? "d" : "c", want = P.shown[st == 1 ? 1 : 0]
            return Hands(tap: { q in
                guard let i = Self.names(P).firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [(box, Double(i))], keep: ["wn": i == want ? -1 : Double(i)], check: true)
            })
        }
        guard P.pair && st == 2 else { return nil }
        return Hands(tap: { q in
            guard let j = P.shown.indices.first(where: { hypot(q.x - Self.cx(P, $0), q.y - Self.cy) <= Double(TM2.coins[P.shown[$0]].across) / 2 + 0.5 }) else { return nil }
            return HandMove(hand: nil, missHand: nil, set: [("w", Double(j))], keep: ["wo": j == P.right ? -1 : Double(j)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Coins2.Parts(s.numbers), st = at(s)
        if (P.pair && st < 2) || (!P.pair && st == 0) {
            let r = Self.names(P)[P.shown[st == 1 ? 1 : 0]]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        }
        if P.pair && st == 2 { return [.tap(.picture(CGPoint(x: Self.cx(P, P.right), y: Self.cy)))] }
        return []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Coins2.Parts(s.numbers), st = at(s)
        if (P.pair && st < 2) || (!P.pair && st == 0) {
            let c = P.shown[st == 1 ? 1 : 0], i = c == TM2.dime ? TM2.nickel : (c + 1) % 4
            return HandMove(hand: nil, missHand: nil, set: [(st == 1 ? "d" : "c", Double(i))], keep: ["wn": Double(i)], check: true)
        }
        guard P.pair && st == 2 else { return nil }
        return HandMove(hand: nil, missHand: nil, set: [("w", Double(1 - P.right))], keep: ["wo": Double(1 - P.right)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Coins2.Parts(s.numbers)
        guard at(s) == 3 else { return nil }
        return ["x": Double(P.slips.first?.0 ?? 1)]
    }
}
