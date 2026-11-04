import SwiftUI

/// Put shapes together on the paper, as in the preview (design/prototype/gradeK-ch2.html, lCompose): the big shape's
/// outline dashed on the left, its pieces (whole blocks, some turned) waiting a block past it. Slide a piece: it follows
/// the finger block by block ("1 of 2 in"); tap one: it turns a quarter where it is. One that hangs out ("That one sticks
/// out.") or lies over another ("Pieces can’t stack.") slides back. Full, the outline turns solid and the sides that
/// touch go dashed: one shape. Tap its name in the row under it; the record: `2 triangles make a square.`
///
/// Kept: each piece's place `px<j>`, `py<j>` and the quarter turns it's been given `pt<j>`. Hand: `grab`, `g`, `ox`, `oy`
/// (where it's held, in blocks), `x`, `y` (its place now), `fx`, `fy` (where it was taken from); `bk`, `bx`, `by` the
/// piece just let go and where (it glides from there).
@MainActor
struct PutShapesLesson: PaperLesson {
    typealias Pt = KS.Pt
    var liveKeys: Set<String> { ["x", "y", "grab", "g", "ox", "oy", "fx", "fy"] }
    static let B = 5.0
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Piece j now: its shape (blocks, from 0, 0) and its place.
    private func piece(_ s: PaperState, _ P: PutShapes.Parts, _ j: Int) -> (shape: [Pt], x: Double, y: Double) {
        let t = Int(s.run.kept["pt\(j)"] ?? 0), tray = P.tray[j]
        return (PutShapes.turned(P.start(j), t), s.run.kept["px\(j)"] ?? tray.0, s.run.kept["py\(j)"] ?? tray.1)
    }
    private func placed(_ shape: [Pt], _ x: Double, _ y: Double) -> [Pt] { shape.map { ($0.0 + x, $0.1 + y) } }
    private func sq(_ p: [Pt]) -> [Pt] { p.map { ($0.0 * Self.B, $0.1 * Self.B) } }
    private func namesY(_ P: PutShapes.Parts) -> Double { P.size.h * Self.B + 3 }
    private func names(_ P: PutShapes.Parts) -> [CGRect] { KS.rects(P.choices.count, x: 0, y: namesY(P), w: 13, .row) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PutShapes.Parts(s.numbers), st = at(s), outline = sq(P.S.outline)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let held = st == 0 && s.grabbed ? Int(s.h("g") ?? -1) : -1
        if st == 0 { KS.outline(&pic, "out", outline, .ink, dashed: true) }
        let all = (0..<P.n).map { piece(s, P, $0) }
        var inner = Set<String>()
        for j in 0..<P.n {
            let p = all[j]
            if j == held {
                let q = sq(placed(p.shape, s.h("x") ?? p.x, s.h("y") ?? p.y))
                KS.poly(&live, "pc\(j)f", q, .tint(0.42)); KS.outline(&live, "pc\(j)o", q, .chapter)
                let inNow = (0..<P.n).filter { k in P.fit(k == j ? placed(p.shape, s.h("x") ?? p.x, s.h("y") ?? p.y) : placed(all[k].shape, all[k].x, all[k].y)).all }.count
                live.reads("\(inNow) of \(P.n) in")
                continue
            }
            let q = sq(placed(p.shape, p.x, p.y)), id = "pc\(j)\(p.shape.map { "\($0.0)\($0.1)" }.joined())"
            // just let go: it glides from where the finger left it
            if Int(s.h("bk") ?? -1) == j, let bx = s.h("bx"), let by = s.h("by") {
                pic.sketch.from[id + "f"] = KS.kind(sq(placed(p.shape, bx, by)), pic)
            }
            KS.poly(&pic, id + "f", q, st == 0 ? .tint(0.42) : KS.fill)
            pic.sketch.from = [:]
            if st == 0 { KS.outline(&pic, id + "o", q, .chapter) }
            else if st == 1 {
                // the sides that touch, dashed, each once (they go once it's named)
                for i in q.indices {
                    let a = q[i], b = q[(i + 1) % q.count], m = ((a.0 + b.0) / 2, (a.1 + b.1) / 2)
                    let outer = outline.indices.contains { k in KS.segDist(m, outline[k], outline[(k + 1) % outline.count]) < 0.01 }
                    let key = [a, b].sorted { ($0.0, $0.1) < ($1.0, $1.1) }.map { "\(Int($0.0)),\(Int($0.1))" }.joined(separator: "-")
                    if !outer && !inner.contains(key) { inner.insert(key); pic.line("in" + key, [a, b], .chapter, dashed: true) }
                }
            }
        }
        if st >= 1 { KS.outline(&pic, "outs", outline, .chapter) }
        if st == 0 {
            // a hint: the outline ringed; a second miss, where each piece goes, dashed
            if s.on("ring") { KK.hintBox(&pic, "hr", x: -0.5, y: -0.5, w: P.size.w * Self.B + 1, h: P.size.h * Self.B + 1) }
            if s.on("spot") {
                for j in 0..<P.n { let sol = PutShapes.solution(P.which, j); KS.outline(&pic, "spot\(j)", sq(placed(sol.shape, sol.at.0, sol.at.1)), .chapter, dashed: true) }
            }
        }
        if st == 1 {
            let wrong = s.run.kept["wrong"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil }
            KS.blocks(&pic, "nm", P.choices.map(ShapesK.cap), names(P), wrong: wrong, spot: s.on("spot") ? P.right : nil, ring: s.on("ring") && !s.on("spot"))
        }
        if st == 2 { KS.line(&pic, "rec", [.n(P.S.n, .chapter), .w("\(P.S.piece) make \(ShapesK.an(P.S.make)).")], x: 0, line: namesY(P) + 1) }
        // room for the tray and what's under the outline, so the camera holds still
        let right = (0..<P.n).map { j in P.tray[j].0 + (P.start(j).map(\.0).max() ?? 2) }.max() ?? 10
        let low = (0..<P.n).map { j in P.tray[j].1 + (P.start(j).map(\.1).max() ?? 2) }.max() ?? 2
        let room = st == 0 ? pic.R(0, 0, right * Self.B, max(low, P.size.h) * Self.B) : pic.R(0, 0, max(P.size.w * Self.B, 4 * 14), namesY(P) + 4)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: room)
    }

    /// A piece let go at (x, y), turned `t` quarters more: where it ends up and the move.
    private func letGo(_ s: PaperState, _ P: PutShapes.Parts, _ j: Int, x: Double, y: Double, turn: Int) -> HandMove {
        let p = piece(s, P, j), t = Int(s.run.kept["pt\(j)"] ?? 0) + turn
        let shape = PutShapes.turned(P.start(j), t)
        var nx = x, ny = y
        if turn != 0 {
            // a turn keeps its middle where it was
            let b0 = (p.shape.map(\.0).max() ?? 0, p.shape.map(\.1).max() ?? 0), b1 = (shape.map(\.0).max() ?? 0, shape.map(\.1).max() ?? 0)
            nx += ((b0.0 - b1.0) / 2).rounded(); ny += ((b0.1 - b1.1) / 2).rounded()
        }
        let here = placed(shape, nx, ny), fit = P.fit(here)
        let others = (0..<P.n).filter { $0 != j }.map { k -> [Pt] in let o = piece(s, P, k); return placed(o.shape, o.x, o.y) }
        let back: Numbers = ["bk": Double(j), "bx": nx, "by": ny]
        let tray = P.tray[j]
        if fit.some && !fit.all { return HandMove(hand: back, missHand: back, set: [("f", -1)], keep: ["px\(j)": tray.0, "py\(j)": tray.1, "pt\(j)": Double(t)], check: true) }
        if others.contains(where: { P.overlap(here, $0) }) { return HandMove(hand: back, missHand: back, set: [("f", -2)], keep: ["px\(j)": tray.0, "py\(j)": tray.1, "pt\(j)": Double(t)], check: true) }
        let full = fit.all && (0..<P.n).filter { $0 != j }.allSatisfy { k in let o = piece(s, P, k); return P.fit(placed(o.shape, o.x, o.y)).all }
        return HandMove(hand: back, missHand: back, set: full ? [("f", 1)] : [], keep: ["px\(j)": nx, "py\(j)": ny, "pt\(j)": Double(t)], check: full)
    }
    private func pieceAt(_ s: PaperState, _ P: PutShapes.Parts, _ q: CGPoint) -> Int? {
        let b = (q.x / Self.B, q.y / Self.B)
        return (0..<P.n).reversed().first { j in let p = piece(s, P, j); return KS.inside(b, placed(p.shape, p.x, p.y)) }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = PutShapes.Parts(s.numbers)
        switch at(s) {
        case 0:
            return Hands(
                tap: { q in pieceAt(s, P, q).map { j in let p = piece(s, P, j); return letGo(s, P, j, x: p.x, y: p.y, turn: 1) } },
                grab: { q in
                    guard let j = pieceAt(s, P, q) else { return nil }
                    let p = piece(s, P, j)
                    return ["grab": 1, "g": Double(j), "ox": p.x - q.x / Self.B, "oy": p.y - q.y / Self.B, "x": p.x, "y": p.y, "fx": p.x, "fy": p.y]
                },
                drag: { q, h in
                    var h = h
                    h["x"] = (q.x / Self.B + (h["ox"] ?? 0)).rounded(); h["y"] = (q.y / Self.B + (h["oy"] ?? 0)).rounded()
                    return h
                },
                release: { h in
                    let j = Int(h["g"] ?? 0), x = h["x"] ?? 0, y = h["y"] ?? 0
                    // not moved: a tap, a quarter turn where it is
                    let moved = x != h["fx"] || y != h["fy"]
                    return letGo(s, P, j, x: x, y: y, turn: moved ? 0 : 1)
                })
        case 1:
            let r = names(P)
            return Hands(tap: { q in
                guard let j = KS.hit(q, r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wrong": j == P.right ? -1 : Double(j)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = PutShapes.Parts(s.numbers)
        switch at(s) {
        case 0:
            func key(_ p: [Pt]) -> String { PutShapes.norm(p).map { "\($0.0),\($0.1)" }.sorted().joined(separator: " ") }
            var moves: [GhostMove] = []
            for j in 0..<P.n {
                var p = piece(s, P, j)
                let sol = PutShapes.solution(P.which, j)
                if P.fit(placed(p.shape, p.x, p.y)).all { continue }
                // turned until it's the shape its place wants (a tap each), then slid in
                for _ in 0..<3 where key(p.shape) != key(sol.shape) {
                    let c = KS.centroid(sq(placed(p.shape, p.x, p.y)))
                    moves.append(.tap(.picture(CGPoint(x: c.0, y: c.1))))
                    let t = PutShapes.turned(p.shape, 1)
                    let b0 = (p.shape.map(\.0).max() ?? 0, p.shape.map(\.1).max() ?? 0), b1 = (t.map(\.0).max() ?? 0, t.map(\.1).max() ?? 0)
                    p = (t, p.x + ((b0.0 - b1.0) / 2).rounded(), p.y + ((b0.1 - b1.1) / 2).rounded())
                }
                let c = KS.centroid(sq(placed(p.shape, p.x, p.y)))
                moves.append(.drag(from: CGPoint(x: c.0, y: c.1), to: CGPoint(x: c.0 + (sol.at.0 - p.x) * Self.B, y: c.1 + (sol.at.1 - p.y) * Self.B)))
            }
            return moves
        case 1: let r = names(P)[P.right]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    /// Done: Next problem beside the record.
    func blocksAt(_ s: PaperState) -> CGPoint? { at(s) == 2 ? CGPoint(x: 40, y: namesY(PutShapes.Parts(s.numbers))) : nil }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = PutShapes.Parts(s.numbers)
        switch at(s) {
        case 0: return letGo(s, P, 0, x: P.size.w - 1, y: 0, turn: 0)
        case 1:
            let j = (P.right + 1) % P.choices.count
            return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wrong": Double(j)], check: true)
        default: return nil
        }
    }
}
