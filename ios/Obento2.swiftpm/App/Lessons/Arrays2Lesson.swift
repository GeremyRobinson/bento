import SwiftUI

/// Arrays on the paper, as in the preview (design/prototype/grade2-ch3.html, dArrays): a dot sits in the middle of its own
/// block (Kindergarten's dot), so the strong lines run between the rows and the columns; the array starts a block in, so
/// the rows' numbers have room at its left. The story kind's lines take the top rows, and the muffin box is drawn round it.
/// Tap each row (or sweep along it): it lights and takes its number at the left, "3 rows" beside it. Count one row: its
/// dots number as they're tapped (or a finger drags along them), "4 in a row". Then the record 3 rows under, `4 + 4 + 4 =
/// [ ]`, Check beside it; once it's right the running totals write in at the rows' right ends.
///
/// Kept: "l0"… the rows lit (EG2), "cr" the row counted, "n0"… its dots counted in order. Hand: a sweep (EG2), or "grab",
/// "t0"… the dots a drag along the row has met.
@MainActor
struct Arrays2Lesson: PaperLesson {
    static let AX = 5.0
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private static func lines(_ P: Arrays2.Parts) -> Int { P.story ? A2.storyRows(P.lines, width: 44).count : 0 }
    static func AY(_ P: Arrays2.Parts) -> Double { P.story ? EG2.ceil5(2 * Double(lines(P)) + 1) : 0 }
    private static func grid(_ P: Arrays2.Parts) -> EG2.Grid { EG2.Grid(x: AX, y: AY(P), rows: P.R, cols: P.C) }
    /// The record 3 rows under the array; 2 under a story's 5 rows, so it shows at 75%.
    private static func RY(_ P: Arrays2.Parts) -> Double { AY(P) + 5 * Double(P.R) + (P.story && P.R == 5 ? 1 : 2) }
    func recordRow(_ n: Numbers) -> Double? { Self.RY(Arrays2.Parts(n)) }
    func told(_ s: PaperState) -> String? { let P = Arrays2.Parts(s.numbers); return P.story ? P.lines.joined(separator: " ") : nil }
    /// Check and Next problem beside the record's line (the preview's).
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Arrays2.Parts(s.numbers)
        guard at(s) >= 2 else { return nil }
        return CGPoint(x: EG2.ceil5(Self.AX + EG2.recordWidth(rows: P.R, cols: P.C, cells: 2) + 1), y: Self.RY(P) - 1)
    }

    private func counted(_ s: PaperState) -> (row: Int?, cols: [Int]) {
        var out: [Int] = []
        while let c = s.run.kept["n\(out.count)"] { out.append(Int(c.rounded())) }
        var t = 0
        while let c = s.hand["t\(t)"] { if !out.contains(Int(c)) { out.append(Int(c)) }; t += 1 }
        let r = s.run.kept["cr"].map { Int($0.rounded()) } ?? s.hand["r"].map { Int($0) }
        return (r, out)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Arrays2.Parts(s.numbers), st = at(s), G = Self.grid(P), AX = Self.AX, AY = G.y
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if P.story { A2.tell(&pic, P.lines, width: 44) }
        EG2.drawRows(&pic, &live, s, G, tapping: st == 0, past: st > 0)
        // the dots, each in the middle of its block; the counted row's dots take their numbers
        let C = counted(s), held = s.grabbed && st == 1
        for r in 0..<P.R {
            for c in 0..<P.C {
                let k = r == C.row ? C.cols.firstIndex(of: c) : nil
                let cx = AX + 5 * Double(c) + 2.5, cy = G.mid(r)
                if held, k != nil, s.run.kept["n\(k!)"] == nil { KK.counter(&live, "dt\(r).\(c)", cx, cy, num: k! + 1) }
                // over the lit rows' bands while they're tapped (a plate, so the two fills never fight)
                else if st == 0 { pic.dot("dt\(r).\(c)d", at: cx, cy, radius: 1.5, .chapter, over: true) }
                else { KK.counter(&pic, "dt\(r).\(c)", cx, cy, num: k.map { $0 + 1 }) }
            }
        }
        if P.story { pic.sketch.box("muffins", pic.R(AX, AY, G.w, G.h), .ink, width: Sketch.stroke) }
        // the readout beside the picture
        let rx = AX + G.w + 1.5
        if st == 0 {
            let n = EG2.lit(s, rows: P.R, past: false).count
            if n > 0 { EG2.readout(&pic, G2.count(n, "row"), x: rx, y: G.mid(0)) }
            if s.grabbed { live.reads(G2.count(n + 1, "row")) }
        }
        if st == 1 {
            // on the paper (the still drawing follows what's kept); while a finger drags along, live
            if let r = C.row, !C.cols.isEmpty {
                if held { EG2.readout(&live, "\(C.cols.count) in a row", x: rx, y: G.mid(r)) } else { EG2.readout(&pic, "\(C.cols.count) in a row", x: rx, y: G.mid(r)) }
            }
            if held { live.reads("\(C.cols.count) in a row") }
            // hints: a miss rings one row; a second rings the next dot to count
            let r = C.row ?? 0
            if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hc", x: AX, y: AY + 5 * Double(r), w: G.w, h: 5) }
            if s.on("spot"), let c = (0..<P.C).first(where: { !C.cols.contains($0) }) { KK.hint(&pic, "sc", AX + 5 * Double(c) + 2.5, G.mid(r), radius: 2.2) }
        }
        // the record; once it's right, the running totals at the rows' right ends
        if st >= 2 {
            EG2.record(&rec, rows: P.R, cols: P.C, x: AX, box: "x", cells: 2, done: st == 3 ? P.T : nil)
            if st == 3 { EG2.totals(&pic, G, per: P.C, x: AX + G.w + 1) }
            if st == 2 && s.on("ring") { KK.hintBox(&pic, "ht", x: AX - 2, y: AY, w: 2, h: G.h) }
            if st == 2 && s.on("spot") { for r in 0..<P.R { A1.note(&pic, "sp\(r)", "\(P.C * (r + 1))", x: AX + G.w + 1, y: G.mid(r)) } }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Arrays2.Parts(s.numbers), st = at(s), G = Self.grid(P)
        if st == 0 { return EG2.rowHands(s, G, box: "r") }
        guard st == 1 else { return nil }
        let C = counted(s)
        func dot(_ q: CGPoint) -> (Int, Int)? {
            guard let r = G.row(q) else { return nil }
            let c = Int((q.x - G.x) / 5)
            guard c >= 0, c < P.C, abs(q.x - (G.x + 5 * Double(c) + 2.5)) <= 2.2, abs(q.y - G.mid(r)) <= 2.2 else { return nil }
            return (r, c)
        }
        // the dots counted now: kept, and the move's
        func count(_ r: Int, _ cols: [Int]) -> HandMove {
            var keep: Numbers = ["cr": Double(r)]
            for (i, c) in cols.enumerated() { keep["n\(i)"] = Double(c) }
            let all = cols.count == P.C
            return HandMove(hand: [:], missHand: [:], set: all ? [("c", Double(P.C))] : [], keep: keep, check: all)
        }
        let other = HandMove(hand: [:], missHand: [:], set: [("c", -1)], check: true)
        return Hands(
            tap: { q in
                guard let (r, c) = dot(q) else { return nil }
                if let cr = C.row, cr != r { return other }
                return C.cols.contains(c) ? HandMove(hand: [:]) : count(r, C.cols + [c])
            },
            grab: { q in
                guard let (r, c) = dot(q) else { return nil }
                if let cr = C.row, cr != r { return nil }
                return ["grab": 1, "r": Double(r), "t0": Double(c)]
            },
            drag: { q, h in
                var h = h
                guard let (r, c) = dot(q), r == Int(h["r"] ?? -1) else { return h }
                var t = 0, seen: [Int] = []
                while let x = h["t\(t)"] { seen.append(Int(x)); t += 1 }
                if !seen.contains(c) && !C.cols.contains(c) { h["t\(t)"] = Double(c) }
                return h
            },
            release: { h in
                let r = Int(h["r"] ?? 0)
                var cols = C.cols, t = 0
                while let x = h["t\(t)"] { if !cols.contains(Int(x)) { cols.append(Int(x)) }; t += 1 }
                return count(r, cols)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Arrays2.Parts(s.numbers), st = at(s), G = Self.grid(P)
        if st == 0 {
            let L = EG2.lit(s, rows: P.R, past: false)
            return (0..<P.R).filter { !L.contains($0) }.map { .tap(.picture(CGPoint(x: G.x + G.w / 2, y: G.mid($0)))) }
        }
        guard st == 1 else { return [] }
        let C = counted(s), r = C.row ?? 0
        return (0..<P.C).filter { !C.cols.contains($0) }.map { .tap(.picture(CGPoint(x: G.x + 5 * Double($0) + 2.5, y: G.mid(r)))) }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("r", -1)], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("c", -1)], keep: ["cr": 0, "n0": 0], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Arrays2.Parts(s.numbers)
        return at(s) == 2 ? ["x": Double(P.R + P.C)] : nil
    }
}
