import SwiftUI

/// Compare three-digit numbers on the paper, as in the preview (design/prototype/grade2-ch2.html, dCompare): 5th grade's
/// Comparing decimals for whole numbers. Line 1 runs 0 to 1000 in ten blocks of a hundred (5 squares each); tap the block
/// both numbers are in and it lights and opens below (dashed lines to the next line's ends) into ten blocks of ten, then
/// ten blocks of one. Where they part, tap each one's block (the first shaded, the second striped, each named over it).
/// The record at the right, `427 □ 461`, rings the place where they first differ; tap <, = or > under it.
///
/// Kept: "wr" a block tapped wrong (10 × line + block), "la" "lb" each one's block on the line where they part, "pick" the
/// sign tapped wrong.
@MainActor
struct Compare2Lesson: PaperLesson {
    static let PX = 55.0, RY = 5.0
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? { CGPoint(x: Self.PX, y: Self.RY + 3) }
    private static func Y(_ j: Int) -> Double { 4 + 10 * Double(j) }
    /// The line being tapped: a same block's, or where they part; −1 none.
    private func level(_ P: Compare2.Parts, _ st: Int) -> Int { st <= 2 ? st : st == 3 ? P.d : -1 }
    private static func signRects() -> [CGRect] { (0..<3).map { CGRect(x: PX + 4 * Double($0), y: RY + 3, width: 3, height: 4) } }
    private func kept(_ s: PaperState, _ k: String) -> Int? { s.run.kept[k].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil } }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Compare2.Parts(s.numbers), st = at(s), da = P.da, db = P.db, d = P.d
        var pic = GridPen()
        let passed = st <= 2 ? st : P.stages, open = 1 + min(passed, 2), lv = level(P, st)
        let wr = kept(s, "wr")
        let la = st >= 4 ? da[min(d, 2)] : kept(s, "la"), lb = st >= 4 ? db[min(d, 2)] : kept(s, "lb")
        for k in 0..<open {
            let y = Self.Y(k), base = P.lo(k), size = Compare2.Parts.size(k)
            if k < passed { pic.fill("lit\(k)", col: Double(da[k]) * 5, row: y - 2, w: 5, h: 2, .tint(0.4)) }
            if k == d && d < 3 {
                if let a = la { pic.fill("litA", col: Double(a) * 5, row: y - 2, w: 5, h: 2, .tint(0.4)); pic.label("labA", "\(P.a)", KK.lit, .above, edge: y - 2, along: Double(a) * 5 + 2.5) }
                if let b = lb { pic.stripes("litB", col: Double(b) * 5, row: y - 2, w: 5, h: 2); pic.label("labB", "\(P.b)", KK.lit, .above, edge: y - 2, along: Double(b) * 5 + 2.5) }
            }
            if let w = wr, w / 10 == k, lv == k { pic.fill("wr\(w)", col: Double(w % 10) * 5, row: y - 2, w: 5, h: 2, .tint(0.15)); pic.sketch.box("wro\(w)", pic.R(Double(w % 10) * 5, y - 2, 5, 2), KK.red, width: Sketch.stroke) }
            N2.line(&pic, "lv\(k)", y: y, w: 50, step: 5, tall: 5)
            pic.label("lo\(k)", "\(base)", N2.small, .below, edge: y, along: 0)
            pic.label("hi\(k)", "\(base + 10 * size)", N2.small, .below, edge: y, along: 50)
            // the block both are in opens into the next line
            if k < passed && k + 1 < open {
                let x = Double(da[k]) * 5, y2 = Self.Y(k + 1)
                pic.line("mgL\(k)", [(x, y + 2), (0, y2 - 4)], .chapter, dashed: true)
                pic.line("mgR\(k)", [(x + 5, y + 2), (50, y2 - 4)], .chapter, dashed: true)
            }
        }
        // hints: a first miss rings the digits to look at, a second the block (or the sign)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        var rec = GridPen()
        let wA = Record.width(.n(P.a)), sx = Self.PX + wA + 1, bx = sx + 3
        N2.number(&rec, "rA", P.a, x: Self.PX, row: Self.RY)
        N2.number(&rec, "rB", P.b, x: bx, row: Self.RY)
        if st == 5 { rec.word("sg", Compare2.Parts.signs[P.sign], at: sx + 1, Self.RY, KK.maths.colour(.chapter)) }
        else { rec.sketch.box("sgbox\(st == 4 && kept(s, "pick") != nil)", rec.R(sx, Self.RY - 1, 2, 2), st == 4 && kept(s, "pick") != nil ? KK.red : .ink3, width: Sketch.stroke) }
        if st >= 4 && d < 3 { N2.ringDigit(&rec, "rgA", P.a, d, x: Self.PX, row: Self.RY); N2.ringDigit(&rec, "rgB", P.b, d, x: bx, row: Self.RY) }
        if lv >= 0 {
            if ring {
                N2.ringDigit(&rec, "hA", P.a, lv, x: Self.PX, row: Self.RY, dashed: true)
                N2.ringDigit(&rec, "hB", P.b, lv, x: bx, row: Self.RY, dashed: true)
            }
            if spot {
                let y = Self.Y(lv)
                for (i, bl) in (st == 3 ? [da[lv], db[lv]] : [da[lv]]).enumerated() where (i == 0 ? la : lb) == nil || st != 3 {
                    pic.sketch.box("sp\(i)", pic.R(Double(bl) * 5, y - 2, 5, 2), .chapter, width: Sketch.stroke, dashed: true)
                }
            }
        }
        if st == 4 {
            let r = Self.signRects(), pick = kept(s, "pick")
            for (i, g) in Compare2.Parts.signs.enumerated() { E1.block(&rec, "sb\(i)", x: r[i].minX, y: r[i].minY, w: r[i].width, g, wrong: pick == i) }
            if ring { KK.hintBox(&rec, "hs", x: N2.digitX(P.a, min(d, 2), x: Self.PX) - 1, y: Self.RY - 1, w: bx + Record.width(.n(P.b)) - N2.digitX(P.a, min(d, 2), x: Self.PX) + 1, h: 2) }
            if spot { KK.hintBox(&rec, "ss", x: r[P.sign].minX, y: r[P.sign].minY, w: r[P.sign].width, h: r[P.sign].height) }
        }
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Compare2.Parts(s.numbers), st = at(s), da = P.da, db = P.db, lv = level(P, st)
        if st == 4 {
            let r = Self.signRects()
            return Hands(tap: { q in
                guard let i = r.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("g", Double(i))], keep: ["pick": i == P.sign ? -1 : Double(i)], check: true)
            })
        }
        guard lv >= 0 else { return nil }
        let y = Self.Y(lv), la = kept(s, "la"), lb = kept(s, "lb")
        return Hands(tap: { q in
            guard q.y >= y - 3.5, q.y <= y + 1.5, q.x >= 0, q.x <= 50 else { return nil }
            let bl = min(9, Int(q.x / 5))
            if st <= 2 {
                return HandMove(hand: nil, missHand: nil, set: [("s\(st)", Double(bl))], keep: ["wr": bl == da[lv] ? -1 : Double(10 * lv + bl)], check: true)
            }
            if bl == da[lv] || bl == db[lv] {
                let a = bl == da[lv] ? bl : la, b = bl == db[lv] ? bl : lb
                var keep: Numbers = ["wr": -1]
                if let a { keep["la"] = Double(a) }
                if let b { keep["lb"] = Double(b) }
                let both = a != nil && b != nil
                return HandMove(hand: nil, missHand: nil, set: both ? [("p", 1)] : [], keep: keep, check: both)
            }
            return HandMove(hand: nil, missHand: nil, set: [("p", Double(-1 - bl))], keep: ["wr": Double(10 * lv + bl)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Compare2.Parts(s.numbers), st = at(s), lv = level(P, st)
        if st == 4 { let r = Self.signRects()[P.sign]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))] }
        guard lv >= 0 else { return [] }
        let y = Self.Y(lv) - 1
        let blocks = st <= 2 ? [P.da[lv]] : [P.da[lv], P.db[lv]].filter { _ in true }
        var out: [GhostMove] = []
        for (i, bl) in blocks.enumerated() where st <= 2 || (i == 0 ? kept(s, "la") : kept(s, "lb")) == nil { out.append(.tap(.picture(CGPoint(x: Double(bl) * 5 + 2.5, y: y)))) }
        return out
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Compare2.Parts(s.numbers), st = at(s), lv = level(P, st)
        if st == 4 { let i = (P.sign + 2) % 3; return HandMove(hand: nil, missHand: nil, set: [("g", Double(i))], keep: ["pick": Double(i)], check: true) }
        guard lv >= 0 else { return nil }
        if st <= 2 { let bl = (P.da[lv] + 1) % 10; return HandMove(hand: nil, missHand: nil, set: [("s\(st)", Double(bl))], keep: ["wr": Double(10 * lv + bl)], check: true) }
        guard let bl = (0...9).first(where: { $0 != P.da[lv] && $0 != P.db[lv] }) else { return nil }
        return HandMove(hand: nil, missHand: nil, set: [("p", Double(-1 - bl))], keep: ["wr": Double(10 * lv + bl)], check: true)
    }
}
