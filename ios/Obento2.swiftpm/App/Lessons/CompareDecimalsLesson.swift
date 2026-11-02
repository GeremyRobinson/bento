import SwiftUI

/// Comparing decimals on the paper, as in the preview G approved on 1 Nov 2026 (design/prototype/new5-lessons.html,
/// dCompare): Rounding decimals' zoom lines. Line 1 is the whole both numbers are in, 50 squares, ten blocks of a tenth.
/// Tap the block they're both in: it lights and opens below, a dashed funnel, into ten blocks of the next place, until
/// the two fall in different blocks; then tap the block each one is in (one shaded, one striped, each named over it).
/// Beside the line the two numbers are written once, stacked, their points on one grid line; the place being looked at
/// is ringed (dashed after a miss, solid once they differ), and the record a ? b is written under them with < and >
/// to tap. The last words say why.
@MainActor
struct CompareDecimalsLesson: PaperLesson {
    /// The picture's squares: line j's row, a block's width, a line's length; the stacked numbers' point column and rows;
    /// the record's row and its < > blocks' row.
    nonisolated static func line(_ j: Int) -> Double { 4 + 12 * Double(j) }
    nonisolated static let block = 5.0, length = 50.0
    nonisolated static let point = 60.0, rowA = 3.0, rowB = 7.0
    nonisolated static let record = 13.0, left = 54.0, signs = 17.0
    /// The < and > blocks: their left columns (4 squares wide, 2 tall).
    nonisolated static let lt = 54.0, gt = 59.0

    private static let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)
    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["st"] ?? 0).rounded()) }
    private func level(_ s: PaperState) -> Int { Int((s.picture["lv"] ?? 0).rounded()) }

    /// The column where a place's digit sits in the stacked numbers (the point on `point`, two squares a digit).
    private static func column(_ j: Int) -> Double { point + 2 * Double(j) + 1 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let p = CompareDecimals.Parts(s.numbers), d = p.d, st = stage(s), lv = level(s)
        let B = Self.block, L = Self.length, label = Self.label
        var pic = GridPen()
        // the lines open so far: up to the one being tapped, every one once the two are told apart
        let open = st >= 3 ? d : lv + 1
        let dA = p.digitA(d - 1), dB = p.digitB(d - 1)

        for j in 0..<open {
            let y = Self.line(j)
            // the block they share, lit (every line above the one being tapped)
            let shared = j < lv || (st >= 3 && j < d - 1)
            if shared { pic.fill("lit\(j)", col: Double(p.digitA(j)) * B, row: y - 2, w: B, h: 2, .tint(0.42)) }
            // the line being tapped: the block just tapped lit while it's checked, red when it's wrong
            if j == lv && (st == 1 || st == 2) {
                if let w = s.h("wrong") { pic.fill("wrong\(w)", col: w * B, row: y - 2, w: B, h: 2, RoundingLesson.wrongFill) }
                if st == 1, let t = s.h("tapped") { pic.fill("tapped\(t)", col: t * B, row: y - 2, w: B, h: 2, .tint(0.42)) }
            }
            // each one's block on the line where they part: A shaded, B striped, each named over it
            if j == d - 1 {
                let litA = st >= 3 ? Double(dA) : (st == 2 ? s.h("litA") : nil)
                let litB = st >= 3 ? Double(dB) : (st == 2 ? s.h("litB") : nil)
                if let a = litA {
                    pic.fill("litA", col: a * B, row: y - 2, w: B, h: 2, .tint(0.42))
                    pic.label("labA", p.As, label.colour(.chapter), .above, edge: y - 2, along: a * B + B / 2)
                }
                if let b = litB {
                    pic.stripes("litB", col: b * B, row: y - 2, w: B, h: 2)
                    pic.label("labB", p.Bs, label.colour(.chapter), .above, edge: y - 2, along: b * B + B / 2)
                }
            }
            pic.numberLine("l\(j)", col: 0, row: y, steps: 10, per: B, long: 5)
            let (lo, hi) = p.lineEnds(j)
            pic.label("l\(j)lo", lo, label, .below, edge: y, along: 0)
            pic.label("l\(j)hi", hi, label, .below, edge: y, along: L)
            // the block they share opened out below into the next line's ten blocks (the magnifier's dashed lines)
            if shared && j + 1 < open {
                let k = Double(p.digitA(j)), y2 = Self.line(j + 1)
                pic.line("zoomL\(j)", [(k * B, y + 3), (0, y2 - 5)], .chapter, dashed: true)
                pic.line("zoomR\(j)", [(k * B + B, y + 3), (L, y2 - 5)], .chapter, dashed: true)
            }
        }

        // the two numbers, written once, stacked with their points on one grid line
        let la = Double(p.As.count - 1), lb = Double(p.Bs.count - 1)
        let decA = Double(p.la), decB = Double(p.lb)
        pic.digits("nA", p.As, right: Self.point + 2 * decA, row: Self.rowA, per: 2)
        pic.digits("nB", p.Bs, right: Self.point + 2 * decB, row: Self.rowB, per: 2)
        // the place being looked at: ringed dashed after a miss (a hint), solid once it decides
        if st >= 3 {
            let c = Self.column(d - 1)
            pic.ring("rA", col: c - 1, row: Self.rowA - 1, w: 2, h: 2)
            pic.ring("rB", col: c - 1, row: Self.rowB - 1, w: 2, h: 2)
        } else if (st == 1 || st == 2) && s.on("ring") {
            let c = Self.column(lv)
            pic.circle("hA\(lv)", at: c, Self.rowA, radius: 1.3, .chapter, dashed: true)
            pic.circle("hB\(lv)", at: c, Self.rowB, radius: 1.3, .chapter, dashed: true)
        }

        // the record: a, the sign (a box to fill, then the sign in the chapter's colour), b; < and > to tap under it
        if st >= 3 {
            let y = Self.record, x0 = Self.left, wA = 2 * la
            pic.digits("iA", p.As, right: x0 + wA, row: y, per: 2)
            let sx = x0 + wA + 1
            if st >= 4 { pic.word("sg", p.sign, at: sx + 1.5, y, Self.maths.colour(.chapter)) }
            else { pic.sketch.box("sgbox", pic.R(sx, y - 1, 3, 2), .ink3, width: Sketch.stroke) }
            pic.digits("iB", p.Bs, right: sx + 4 + 2 * lb, row: y, per: 2)
            if st == 3 {
                for (id, sign, x, v) in [("lt", "<", Self.lt, 0.0), ("gt", ">", Self.gt, 1.0)] {
                    let r = pic.R(x, Self.signs, 4, 2)
                    if s.h("wrongSign") == v { pic.sketch.fill("\(id)wrong", r, RoundingLesson.wrongFill) }
                    pic.sketch.block(id, r, .main, centred: sign, size: Sketch.maths)
                }
            }
        }
        return PaperDrawing(picture: pic.sketch)
    }

    func hands(_ s: PaperState) -> Hands? {
        let p = CompareDecimals.Parts(s.numbers), d = p.d, lv = level(s), B = Self.block, y = Self.line(lv)
        /// The block of line lv a tap is on (anywhere over it, on its ticks or its labels), or nil.
        func blockAt(_ q: CGPoint) -> Int? {
            guard q.y > y - 3.5, q.y < y + 1.5, q.x > -0.5, q.x < Self.length + 0.5 else { return nil }
            return min(9, max(0, Int((q.x / B).rounded(.down))))
        }
        switch stage(s) {
        case 1:
            // the block both are in: its number is the place's digit
            return Hands(tap: { q in
                guard let bl = blockAt(q) else { return nil }
                let b = Double(bl)
                return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
            })
        case 2:
            // each one's block: the first lights; with both lit it's checked. A block that holds neither is a miss
            let litA = s.h("litA"), litB = s.h("litB"), dA = p.digitA(d - 1), dB = p.digitB(d - 1)
            return Hands(tap: { q in
                guard let bl = blockAt(q) else { return nil }
                var h: Numbers = [:]
                h["litA"] = bl == dA ? Double(bl) : litA
                h["litB"] = bl == dB ? Double(bl) : litB
                guard bl == dA || bl == dB else {
                    var miss = h; miss["wrong"] = Double(bl)
                    return HandMove(hand: miss, missHand: miss, set: [("a", Double(bl)), ("b", Double(bl))], check: true)
                }
                let both = h["litA"] != nil && h["litB"] != nil
                return HandMove(hand: h, missHand: nil, set: [("a", h["litA"]), ("b", h["litB"])], check: both)
            })
        case 3:
            // < or >
            return Hands(tap: { q in
                guard q.y >= Self.signs - 0.5, q.y <= Self.signs + 2.5 else { return nil }
                let v: Double
                if q.x >= Self.lt - 0.5 && q.x <= Self.lt + 4.5 { v = 0 } else if q.x >= Self.gt - 0.5 && q.x <= Self.gt + 4.5 { v = 1 } else { return nil }
                return HandMove(hand: ["sign": v], missHand: ["wrongSign": v], set: [("s", v)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let p = CompareDecimals.Parts(s.numbers), d = p.d, lv = level(s), B = Self.block, y = Self.line(lv)
        func at(_ bl: Int) -> GhostMove { .tap(.picture(CGPoint(x: (Double(bl) + 0.5) * B, y: y - 1))) }
        switch stage(s) {
        case 1: return [at(p.digitA(lv))]
        case 2: return (s.h("litA") == nil ? [at(p.digitA(d - 1))] : []) + (s.h("litB") == nil ? [at(p.digitB(d - 1))] : [])
        case 3: return [.tap(.picture(CGPoint(x: (p.aBigger ? Self.gt : Self.lt) + 2, y: Self.signs + 1)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = CompareDecimals.Parts(s.numbers), d = p.d, lv = level(s)
        switch stage(s) {
        case 1:
            let b = Double((p.digitA(lv) + 3) % 10)
            return HandMove(hand: ["tapped": b], missHand: ["wrong": b], set: [("x", b)], check: true)
        case 2:
            let dA = p.digitA(d - 1), dB = p.digitB(d - 1)
            let bl = (0..<10).map { (dA + 3 + $0) % 10 }.first { $0 != dA && $0 != dB } ?? 0
            let miss: Numbers = ["wrong": Double(bl)]
            return HandMove(hand: miss, missHand: miss, set: [("a", Double(bl)), ("b", Double(bl))], check: true)
        case 3:
            let v: Double = p.aBigger ? 0 : 1
            return HandMove(hand: ["sign": v], missHand: ["wrongSign": v], set: [("s", v)], check: true)
        default: return nil
        }
    }
}
