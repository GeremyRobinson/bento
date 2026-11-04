import SwiftUI

/// What Kindergarten's Add and take away chapter shares on the paper (the preview design/prototype/gradeK-ch4.html): a
/// cube filling its block (tinted, or striped: the second amount; a number on it as it's counted, a line across it once
/// it's taken away), a counter (a thing in a story: a dot 3 squares across, striped when it's the second amount), the
/// dashed strip a taken cube drops into, the hop over a cube counted on, and a record line with its box anywhere in it.
/// Chapter 1's kit (KK) gives the ten track, the number row and the hints.
@MainActor
enum KA {
    /// A cube filling the block at (x, y): its fill (striped, or lit), the chapter's outline, its number, a line across it
    /// (taken away), a ring (the last one counted), or a red outline (tapped and wrong).
    static func cube(_ pen: inout GridPen, _ id: String, x: Double, y: Double, striped: Bool = false, lit: Bool = false, num: Int? = nil,
                     cross: Bool = false, ring: Bool = false, red: Bool = false) {
        pen.fill(id + "f\(striped ? "s" : lit ? "L" : "")", col: x, row: y, w: 5, h: 5, lit ? KK.litCube : KK.cube)
        if striped { pen.stripeLines(id + "s", col: x, row: y, w: 5, h: 5) }
        pen.sketch.box(id + "o\(red ? "x" : "")", pen.R(x, y, 5, 5), red ? KK.red : .chapter, width: Sketch.stroke)
        if let num { pen.word(id + "n", "\(num)", at: x + 2.5, y + 2.5, KK.count) }
        if cross { pen.line(id + "x", [(x + 0.8, y + 4.2), (x + 4.2, y + 0.8)]) }
        if ring { pen.circle(id + "r", at: x + 2.5, y + 2.5, radius: 2.05, .chapter) }
    }

    /// A counter: a dot 3 squares across centred at (cx, cy). Striped (the second amount): lightly filled, outlined, the
    /// stripes the cubes have (corner to corner of each square) cut to the dot. `num`: written on it once counted.
    /// `cross`: taken away.
    static func dot(_ pen: inout GridPen, _ id: String, _ cx: Double, _ cy: Double, striped: Bool = false, num: Int? = nil, cross: Bool = false, red: Bool = false) {
        let r = 1.5
        if striped || num != nil {
            let pts = (0..<32).map { i in let a = Double(i) / 32 * 2 * .pi; return pen.P(cx + r * cos(a), cy + r * sin(a)) }
            pen.sketch.polygon(id + "f", pts, num != nil && !striped ? .tint(0.42) : .tint(0.2))
            if striped {
                // the lines x − y = k (whole squares) that cross the dot, each cut to its chord
                var segs: [(CGPoint, CGPoint)] = []
                let lo = Int((cx - cy - r * 2.0.squareRoot()).rounded(.up)), hi = Int((cx - cy + r * 2.0.squareRoot()).rounded(.down))
                for k in lo...max(lo, hi) {
                    let d = (Double(k) - (cx - cy)) / 2.0.squareRoot()
                    guard abs(d) < r - 0.05 else { continue }
                    let half = (r * r - d * d).squareRoot() / 2.0.squareRoot()
                    let mx = cx + d / 2.0.squareRoot(), my = cy - d / 2.0.squareRoot()
                    segs.append((pen.P(mx - half, my - half), pen.P(mx + half, my + half)))
                }
                pen.sketch.segments(id + "s", segs, .tint(0.6), width: Sketch.stroke)
            }
            pen.circle(id + "o\(red ? "x" : "")", at: cx, cy, radius: r, red ? KK.red : .chapter)
        } else {
            pen.dot(id + "d\(red ? "x" : "")", at: cx, cy, radius: r, red ? KK.red : .chapter)
        }
        if let num { pen.word(id + "n", "\(num)", at: cx, cy, KK.count) }
        if cross { pen.line(id + "x", [(cx - 1.6, cy + 1.6), (cx + 1.6, cy - 1.6)]) }
    }

    /// The strip taken things drop into: dashed blocks from column x, `n` of them.
    static func strip(_ pen: inout GridPen, _ id: String, x: Double = 0, y: Double, _ n: Int) {
        for c in 0..<max(0, n) { pen.sketch.box("\(id)\(c)", pen.R(x + Double(c) * 5, y, 5, 5), .ink3, width: Sketch.stroke, dashed: true) }
    }

    /// A hop over the track: an arc from block j − 1's middle to block j's, rising 2 squares above the track's top `y`.
    static func hop(_ pen: inout GridPen, _ id: String, _ j: Int, y: Double) {
        pen.hop(id, from: Double(j) * 5 - 2.5, to: Double(j) * 5 + 2.5, row: y, height: 2)
    }

    /// A record line with its box among its tokens: `before`, the box (empty, a number tapped, red when wrong), `after`.
    /// Returns the box's left column.
    @discardableResult
    static func line(_ pen: inout GridPen, _ id: String, _ before: [M7.Tok], value: Int?, wrong: Bool, _ after: [M7.Tok] = [], x: Double = 0, line: Double = 1) -> Double {
        let end = before.isEmpty ? x : M7.row(&pen, id, before, x: x, line: line), bx = before.isEmpty ? x : (end + 0.5).rounded(.up)
        KK.box(&pen, id + "box", x: bx, line: line, value: value, wrong: wrong)
        if !after.isEmpty { M7.row(&pen, id + "a", after, x: bx + 4.5, line: line) }
        return bx
    }

    /// A kept number (nil when it isn't kept or is −1, "none").
    static func kept(_ s: PaperState, _ k: String) -> Int? { s.run.kept[k].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil } }
    /// The kept list o0, o1, … (what was counted, in order).
    static func list(_ s: PaperState, _ k: String) -> [Int] {
        var out: [Int] = []
        while let j = s.run.kept["\(k)\(out.count)"] { out.append(Int(j.rounded())) }
        return out
    }
}

/// Sliding the second train (or the second group's counters) on right after the first (k-add's and k-story's move): it
/// waits above the track at the right, follows the finger square by square, and snaps on right after the first; let go
/// anywhere else, it slides home again ("Put them right after the 3."). Hand: "grab", "gx", "gy", "x0", "y0", "x", "y";
/// kept: "lx", "ly" where it was let go (so it glides from there).
@MainActor
struct KSlide {
    let a: Int, b: Int
    /// The track's top while it waits for them.
    let track: Double
    var home: CGPoint { CGPoint(x: 50 - 5 * Double(b), y: track - 10) }

    /// Where the train is now: held, or let go and gliding home (drawn there), or home.
    func at(_ s: PaperState) -> CGPoint {
        if let x = s.h("x"), let y = s.h("y") { return CGPoint(x: x, y: y) }
        return home
    }
    /// Blocks from right after the first train (0 there), or nil off the track.
    func drop(_ p: CGPoint) -> Int? { abs(p.y - track) > 2.5 ? nil : Int((p.x / 5).rounded()) - a }
    func readout(_ p: CGPoint) -> String? {
        guard let r = drop(p) else { return nil }
        return r == 0 ? "Right after \(a)" : r > 0 ? "\(r) to go" : "On the \(a)"
    }
    /// Where it was let go, for it to glide from.
    func letGo(_ s: PaperState) -> CGPoint? {
        guard let x = s.run.kept["lx"], let y = s.run.kept["ly"] else { return nil }
        return CGPoint(x: x, y: y)
    }

    func hands(_ s: PaperState, box: String) -> Hands {
        let h = home
        return Hands(
            grab: { q in
                guard q.x >= h.x - 1, q.x <= h.x + 5 * Double(b) + 1, q.y >= h.y - 1, q.y <= h.y + 6 else { return nil }
                return ["grab": 1, "gx": q.x, "gy": q.y, "x0": h.x, "y0": h.y, "x": h.x, "y": h.y]
            },
            drag: { q, held in
                var held = held
                held["x"] = max(-10, min(55, ((held["x0"] ?? 0) + q.x - (held["gx"] ?? q.x)).rounded()))
                held["y"] = max(track - 15, min(track + 10, ((held["y0"] ?? 0) + q.y - (held["gy"] ?? q.y)).rounded()))
                return held
            },
            release: { held in
                let p = CGPoint(x: held["x"] ?? h.x, y: held["y"] ?? h.y)
                // not moved off home: nothing
                if abs(p.x - h.x) + abs(p.y - h.y) <= 1 { return HandMove(hand: [:]) }
                let r = drop(p)
                return HandMove(hand: [:], missHand: [:], set: [(box, Double(r ?? 99))], keep: ["lx": p.x, "ly": p.y, "lt": PaperClock.now], check: true)
            })
    }
    /// Show me: from its middle on the left to right after the first train.
    var demo: GhostMove { .drag(from: CGPoint(x: home.x + 2.5, y: home.y + 2.5), to: CGPoint(x: 5 * Double(a) + 2.5, y: track + 2.5)) }
    /// A slip: let go a block too far along.
    var wrong: HandMove { HandMove(hand: [:], missHand: [:], set: [("l", 1)], keep: ["lx": 5 * Double(a + 1), "ly": track], check: true) }
}
