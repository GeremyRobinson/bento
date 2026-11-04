import SwiftUI

/// Measure length on the paper, as in the preview (design/prototype/grade1-ch5.html, dMeasure): two things as bars 2 squares
/// tall from a dashed start line, a row of cubes (one block a cube) under each, the names at the bars' right ends. Lay cubes
/// under the first: a tap at the line lays the first cube, each tap after it the next, end to end (or drag along: they're
/// laid one at a time as the finger passes), counted at the row's end ("1, 2 … 7", then "7 cubes"). Then the second. Then
/// tap the cubes of the longer row past the shorter one's end (a dashed line drops from it), counted ("3 more"). Then the
/// record, 7 − 4 = [3] cubes longer, written with the digit pad under it.
///
/// Kept: "c0", "c1" the cubes laid in each row; "e<k>" the cubes past the end tapped, in order; "chk" what was last checked.
/// Hand while a row is dragged along: "grab", "r", "n" (the cubes now), "lx", "ly", "gx", "gy", "mv".
@MainActor
struct Cubes1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["lx", "ly", "gx", "gy", "mv"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let bar = [0.0, 10.0], cube = [2.0, 12.0], line = 23.0, padY = 26.0

    private func laid(_ s: PaperState, _ P: Cubes1.Parts, _ r: Int) -> Int {
        let st = at(s)
        if st >= 2 || (r == 0 && st == 1) { return P.len[r] }
        guard st == r else { return 0 }
        if s.grabbed, Int(s.h("r") ?? -1) == r { return Int(s.h("n") ?? 0) }
        return Int(s.run.kept["c\(r)"] ?? 0)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        switch at(s) {
        case 3: return DigitPad.checkAt(x: 0, y: Self.padY)
        case 4: return CGPoint(x: 0, y: Self.padY)
        default: return nil
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Cubes1.Parts(s.numbers), st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let extra = st == 2 ? KA.list(s, "e") : st >= 3 ? Array(P.mn..<P.mx) : []
        pic.line("start", [(0, -1), (0, 18)], .ink2, dashed: true)
        if st == 2 { pic.line("guide", [(5 * Double(P.mn), -1), (5 * Double(P.mn), 18)], .ink3, dashed: true) }
        for r in 0..<2 {
            let L = 5 * Double(P.len[r]), y = Self.bar[r]
            pic.fill("bar\(r)f", col: 0, row: y, w: L, h: 2, .tint(0.2))
            pic.sketch.box("bar\(r)o", pic.R(0, y, L, 2), .ink, width: Sketch.stroke)
            L5.label(&pic, "nm\(r)", P.names[r], x: L, mid: y + 1)
            let n = laid(s, P, r), cy = Self.cube[r]
            for j in 0..<n {
                let lit = r == P.lg && extra.contains(j)
                pic.fill("c\(r)-\(j)\(lit)", col: 5 * Double(j), row: cy, w: 5, h: 5, lit ? .tint(0.45) : .tint(0.2))
                pic.sketch.box("c\(r)-\(j)o", pic.R(5 * Double(j), cy, 5, 5), .chapter, width: Sketch.stroke)
            }
            if n > 0 {
                let ro = n == P.len[r] ? Len1.pl(n, "cube", "cubes") : Len1.run(Array(1...n))
                A1.note(&pic, "rd\(r)", ro, x: 5 * Double(n) + 1, y: cy + 2.5)
                if s.grabbed && Int(s.h("r") ?? -1) == r { live.reads(ro) }
            }
        }
        if !extra.isEmpty { A1.note(&pic, "ex", "\(extra.count) more", x: 2.5 * Double(P.mn + P.mx), y: Self.cube[P.lg] + 6.5, centred: true) }
        let unit = P.diff == 1 && st >= 4 ? "cube longer" : "cubes longer"
        switch st {
        case 0, 1:
            let r = st, n = laid(s, P, r)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.cube[r], w: 5 * Double(P.len[r]), h: 5) }
            if s.on("spot") && n < P.len[r] { pic.sketch.box("spot\(n)", pic.R(5 * Double(n), Self.cube[r], 5, 5), .chapter, width: Sketch.stroke, dashed: true) }
        case 2:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 5 * Double(P.mn), y: Self.cube[0], w: 5 * Double(P.diff), h: 15) }
            if s.on("spot"), let j = (P.mn..<P.mx).first(where: { !extra.contains($0) }) { KK.hintBox(&pic, "spot", x: 5 * Double(j), y: Self.cube[P.lg], w: 5, h: 5) }
        case 3:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.diff)
            let end = A1.record(&pic, "rec", [.n(P.mx), .op("−"), .n(P.mn), .op("="), .box(v, wrong: wrong)], x: 0, line: Self.line)
            M7.row(&pic, "recu", [.w(unit)], x: end.rounded(.up), line: Self.line)
            DigitPad.draw(&pic, "pad", x: 0, y: Self.padY)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 5 * Double(P.mn), y: Self.cube[P.lg], w: 5 * Double(P.diff), h: 5) }
            if s.on("spot") { A1.note(&pic, "spot", "\(P.diff)", x: DigitPad.width + 13.5, y: Self.padY + 2) }
        default:
            M7.row(&pic, "rec", [.n(P.mx), .op("−"), .n(P.mn), .op("="), .n(P.diff, .chapter), .w(unit)], x: 0, line: Self.line)
        }
        var right = 0.0
        for r in 0..<2 {
            let L = 5 * Double(P.len[r])
            right = max(right, L + 0.5 + L5.width(P.names[r]), L + 1 + L5.smallWidth(Len1.run(Array(1...P.len[r]))))
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 3 ? ["Check"] : [], extent: pic.R(0, -1, right, 19))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Cubes1.Parts(s.numbers), st = at(s)
        let box = ["f", "g"]
        func onRow(_ q: CGPoint, _ r: Int) -> Bool { q.y >= Self.cube[r] - 0.5 && q.y <= Self.cube[r] + 5.5 }
        switch st {
        case 0, 1:
            let r = st, n0 = Int(s.run.kept["c\(r)"] ?? 0), len = P.len[r]
            /// A cube laid at q (a tap), from n laid: the move it makes.
            func tapAt(_ q: CGPoint, _ n: Int) -> HandMove? {
                guard onRow(q, r), q.x >= -1 else { return nil }
                let j = Int((q.x / 5).rounded(.down))
                if j < n { return HandMove(hand: nil) }
                if j >= len { return HandMove(hand: [:], missHand: [:], set: [(box[r], -2)], check: true) }
                if n == 0 && j != 0 { return HandMove(hand: [:], missHand: [:], set: [(box[r], -1)], check: true) }
                let m = n + 1
                return HandMove(hand: [:], missHand: [:], set: m == len ? [(box[r], Double(len))] : [], keep: ["c\(r)": Double(m)], check: m == len)
            }
            return Hands(
                tap: { q in tapAt(q, n0) },
                grab: { q in
                    guard onRow(q, r), q.x >= -2, q.x <= 70 else { return nil }
                    return ["grab": 1, "r": Double(r), "n": Double(n0), "lx": q.x, "ly": q.y, "gx": q.x, "gy": q.y, "mv": 0]
                },
                drag: { q, h in
                    var h = h, n = Int(h["n"] ?? 0)
                    if hypot(q.x - (h["gx"] ?? q.x), q.y - (h["gy"] ?? q.y)) > 0.4 { h["mv"] = 1 }
                    if h["mv"] == 1 {
                        for p in N1.walk(CGPoint(x: h["lx"] ?? q.x, y: h["ly"] ?? q.y), q) where onRow(p, r) && p.x >= 0 {
                            if Int((p.x / 5).rounded(.down)) == n && n < len { n += 1 }
                        }
                    }
                    h["n"] = Double(n); h["lx"] = (q.x * 2).rounded() / 2; h["ly"] = (q.y * 2).rounded() / 2
                    return h
                },
                release: { h in
                    let n = Int(h["n"] ?? 0)
                    if h["mv"] != 1 { return tapAt(CGPoint(x: h["lx"] ?? 0, y: h["ly"] ?? 0), n0) ?? HandMove(hand: [:]) }
                    if n == 0 { return HandMove(hand: [:], missHand: [:], set: [(box[r], -1)], check: true) }
                    return HandMove(hand: [:], missHand: [:], set: n == len ? [(box[r], Double(len))] : [], keep: ["c\(r)": Double(n)], check: n == len)
                })
        case 2:
            let extra = KA.list(s, "e")
            return Hands(tap: { q in
                guard let r = (0..<2).first(where: { onRow(q, $0) }), q.x >= 0, q.x <= 5 * Double(P.len[r]) else { return nil }
                let j = Int((q.x / 5).rounded(.down))
                guard r == P.lg && j >= P.mn else { return HandMove(hand: nil, missHand: nil, set: [("m", -1)], check: true) }
                if extra.contains(j) { return HandMove(hand: nil) }
                let all = extra.count + 1 == P.diff
                return HandMove(hand: nil, missHand: nil, set: all ? [("m", Double(P.diff))] : [], keep: ["e\(extra.count)": Double(j)], check: all)
            })
        case 3: return DigitPad.hands(s, "x", want: P.diff, x: 0, y: Self.padY)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Cubes1.Parts(s.numbers), st = at(s)
        switch st {
        case 0, 1:
            let n = Int(s.run.kept["c\(st)"] ?? 0), y = Self.cube[st] + 2.5
            let pts = (n..<P.len[st]).map { CGPoint(x: 5 * Double($0) + 2.5, y: y) }
            return pts.count == 1 ? [.tap(.picture(pts[0]))] : [.path([CGPoint(x: 5 * Double(n) + 0.5, y: y)] + pts)]
        case 2:
            let extra = KA.list(s, "e")
            return (P.mn..<P.mx).filter { !extra.contains($0) }.map { .tap(.picture(CGPoint(x: 5 * Double($0) + 2.5, y: Self.cube[P.lg] + 2.5))) }
        case 3: return DigitPad.demo(P.diff, x: 0, y: Self.padY)
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Cubes1.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("f", -1)], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("g", -2)], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("m", -1)], check: true)
        case 3: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.a + P.b))], keep: ["chk": Double(P.a + P.b)], check: true)
        default: return nil
        }
    }
}
