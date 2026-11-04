import SwiftUI

/// Put shapes together on the paper, as in the preview (design/prototype/grade1-ch6.html, dCompose): the new shape's outline
/// dashed on the left (blocks of 5 squares, circles 4 blocks across), its pieces two blocks past it in a tray. Slide a piece: it
/// follows the finger a square at a time and snaps in within 3 squares of a free place its shape fits ("1 of 2 in"); tap one: a
/// quarter turn about its middle. One that sticks out, lies over another, needs a turn or leaves a gap slides back, said. Full,
/// the sides that touch go and the record writes itself; a two-stage problem's shape then glides into the tray as a piece.
///
/// Kept (stage i, piece j): "x<i>_<j>", "y<i>_<j>" its place, "t<i>_<j>" the quarter turns it's been given, "s<i>_<j>" the place
/// it's in (1 + slot), "a<i>_<j>", "b<i>_<j>" its tray place once turned there. Hand: "grab", "g", "ox", "oy", "x", "y", "fx", "fy";
/// "bk", "bx", "by" the piece just let go (it glides back from there).
@MainActor
struct Compose1Lesson: PaperLesson {
    typealias Pt = KS.Pt
    var liveKeys: Set<String> { ["x", "y", "grab", "g", "ox", "oy", "fx", "fy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct Stage {
        let P: Compose1.Parts, i: Int
        let out: [Pt], OW: Double, OH: Double, TX: Double
        let start: [[Pt]], tray: [Pt], slots: [(key: String, x: Double, y: Double)]
        init(_ P: Compose1.Parts, _ i: Int) {
            self.P = P; self.i = i
            // the tray a block past the outline, in rows up to 45 squares long (two blocks past, wrapping at 35, was 69%)
            out = P.outline(i); let b = Shapes1.bbox(out); OW = b.x1; OH = b.y1; TX = OW + 5
            start = P.start(i); slots = P.slots(i)
            var t: [Pt] = [], cx = OW + 5, cy = 0.0, rowH = 0.0
            for s in start {
                let b = Shapes1.bbox(s)
                if cx > OW + 5 && cx + b.x1 > OW + 45 { cx = OW + 5; cy += rowH + 5; rowH = 0 }
                t.append((cx, cy)); cx += b.x1 + 5; rowH = max(rowH, b.y1)
            }
            tray = t
        }
        var n: Int { start.count }
        func slotShape(_ j: Int) -> [Pt] { let S = P.stages[i]; return Shapes1.scale(Shapes1.norm(S.pieces[j] ?? P.stages[max(0, i - 1)].outline), 5) }
        var trayRight: Double { (0..<n).map { tray[$0].0 + Shapes1.bbox(start[$0]).x1 }.max() ?? 0 }
        var trayBottom: Double { (0..<n).map { tray[$0].1 + Shapes1.bbox(start[$0]).y1 }.max() ?? 0 }
    }
    /// Piece j of stage i now: its shape and place, and the place it's in (or nil).
    private func piece(_ s: PaperState, _ S: Stage, _ j: Int) -> (shape: [Pt], x: Double, y: Double, slot: Int?) {
        let k = s.run.kept, i = S.i, t = Int(k["t\(i)_\(j)"] ?? 0)
        let tray = (k["a\(i)_\(j)"] ?? S.tray[j].0, k["b\(i)_\(j)"] ?? S.tray[j].1)
        let slot = Int(k["s\(i)_\(j)"] ?? 0)
        return (Compose1.turned(S.start[j], t), k["x\(i)_\(j)"] ?? tray.0, k["y\(i)_\(j)"] ?? tray.1, slot > 0 ? slot - 1 : nil)
    }
    private func trayAt(_ s: PaperState, _ S: Stage, _ j: Int) -> Pt { (s.run.kept["a\(S.i)_\(j)"] ?? S.tray[j].0, s.run.kept["b\(S.i)_\(j)"] ?? S.tray[j].1) }
    /// The record's first row: under the outline and the tray, whichever goes lower, for every stage.
    private func recY(_ P: Compose1.Parts) -> Double {
        let low = P.stages.indices.map { let S = Stage(P, $0); return max(S.OH, S.trayBottom) }.max() ?? 20
        return low + 3
    }
    /// Done: Next problem beside the last record line.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Compose1.Parts(s.numbers), n = P.stages.count
        guard at(s) == n else { return nil }
        let w = P.stages.map { M7.width(Self.toks($0.words)) }.max() ?? 30
        return CGPoint(x: ((w + 2) / 5).rounded(.up) * 5, y: recY(P) + 3 * Double(n - 1))
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Compose1.Parts(s.numbers), st = at(s), n = P.stages.count
        var pic = GridPen(), live = GridPen(stableIds: true)
        let ry = recY(P)
        if st < n {
            let S = Stage(P, st), held = s.grabbed ? Int(s.h("g") ?? -1) : -1
            if st > 0 { pic.sketch.startAt = PaperClock.now + 1.2 }
            KS.outline(&pic, "out\(st)", S.out, .ink, dashed: true)
            pic.sketch.startAt = nil
            var inNow = 0
            for j in 0..<S.n {
                let p = piece(s, S, j)
                if p.slot != nil { inNow += 1 }
                if j == held {
                    let q = Shapes1.shift(p.shape, s.h("x") ?? p.x, s.h("y") ?? p.y)
                    KS.poly(&live, "pc\(j)f", q, .tint(0.42)); KS.outline(&live, "pc\(j)o", q, .chapter)
                    continue
                }
                let q = Shapes1.shift(p.shape, p.x, p.y), id = "pc\(st)_\(j)" + Compose1.key(p.shape).prefix(40)
                if Int(s.h("bk") ?? -1) == j, let bx = s.h("bx"), let by = s.h("by") {
                    let was = KS.kind(Shapes1.shift(p.shape, bx, by), pic)
                    pic.sketch.from[id + "f"] = was; pic.sketch.from[id + "o"] = was
                }
                // the shape just made glides from where it was made into the tray
                let made = P.stages[st].pieces[j] == nil
                if made && s.run.kept["x\(st)_\(j)"] == nil && s.run.kept["t\(st)_\(j)"] == nil {
                    let was = KS.kind(p.shape, pic)
                    pic.sketch.from[id + "f"] = was; pic.sketch.from[id + "o"] = was; pic.sketch.delay = 1.2
                } else if st > 0 { pic.sketch.startAt = PaperClock.now + 1.2 }
                KS.poly(&pic, id + "f", q, p.slot != nil ? KS.fill : .tint(0.42))
                KS.outline(&pic, id + "o", q, .chapter)
                pic.sketch.from = [:]; pic.sketch.delay = 0; pic.sketch.startAt = nil
            }
            if held >= 0, let x = s.h("x"), let y = s.h("y") {
                let p = piece(s, S, held), here = Shapes1.shift(p.shape, x, y)
                let fits = S.slots.enumerated().contains { k, sl in sl.key == Compose1.key(p.shape) && abs(sl.x - x) <= 3 && abs(sl.y - y) <= 3 && !(0..<S.n).contains { piece(s, S, $0).slot == k } }
                _ = here
                live.reads("\(inNow + (fits && p.slot == nil ? 1 : 0)) of \(S.n) in")
            }
            if st > 0 { pic.sketch.startAt = PaperClock.now + 1.2 }
            A1.note(&pic, "in\(st)_\(inNow)", "\(inNow) of \(S.n) in", x: S.OW / 2, y: S.OH + 2, centred: true)
            pic.sketch.startAt = nil
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: -1, y: -1, w: S.OW + 2, h: S.OH + 2) }
            if s.on("spot") { for j in 0..<S.n { KS.outline(&pic, "spot\(j)", Shapes1.shift(S.slotShape(j), S.slots[j].x, S.slots[j].y), .chapter, dashed: true) } }
        } else {
            // the new shape whole: the sides that touched are gone, its outline in the chapter's colour
            let S = Stage(P, n - 1)
            for j in 0..<S.n { KS.poly(&pic, "wh\(j)", Shapes1.shift(S.slotShape(j), S.slots[j].x, S.slots[j].y), KS.fill) }
            KS.outline(&pic, "outs\(n - 1)", S.out, .chapter)
        }
        // the record: a line for each shape made
        for k in 0..<min(st, n) {
            KS.line(&pic, "rec\(k)", Self.toks(P.stages[k].words), x: 0, line: ry + 1 + 3 * Double(k))
        }
        let right = P.stages.indices.map { let S = Stage(P, $0); return max(S.OW, S.trayRight) }.max() ?? 40
        let wr = P.stages.map { M7.width(Self.toks($0.words)) }.max() ?? 0
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(-1, -1, max(right, wr) + 2, ry + 3 * Double(n) + 1))
    }
    /// "2 trapezoids make a hexagon." with its numbers in the chapter's colour.
    static func toks(_ s: String) -> [M7.Tok] {
        var out: [M7.Tok] = [], words: [String] = []
        for w in s.split(separator: " ").map(String.init) {
            if let v = Int(w) { if !words.isEmpty { out.append(.w(words.joined(separator: " "))); words = [] }; out.append(.n(v, .chapter)) } else { words.append(w) }
        }
        if !words.isEmpty { out.append(.w(words.joined(separator: " "))) }
        return out
    }

    /// Piece j let go at (x, y) turned `turn` quarters more (a tap): where it ends up and the move.
    private func letGo(_ s: PaperState, _ S: Stage, _ j: Int, x: Double, y: Double, turn: Int) -> HandMove {
        let i = S.i, box = i == 0 ? "f" : "g", p = piece(s, S, j), k = s.run.kept
        let back: Numbers = ["bk": Double(j), "bx": x, "by": y]
        if turn != 0 {
            let t = Int(k["t\(i)_\(j)"] ?? 0) + turn, sh = Compose1.turned(S.start[j], t)
            let b0 = Shapes1.bbox(p.shape), b1 = Shapes1.bbox(sh)
            let nx = x + ((b0.x1 - b1.x1) / 2).rounded(), ny = y + ((b0.y1 - b1.y1) / 2).rounded()
            var keep: Numbers = ["t\(i)_\(j)": Double(t), "x\(i)_\(j)": nx, "y\(i)_\(j)": ny, "s\(i)_\(j)": 0]
            let tr = trayAt(s, S, j)
            if x == tr.0 && y == tr.1 { keep["a\(i)_\(j)"] = nx; keep["b\(i)_\(j)"] = ny }
            return HandMove(hand: [:], keep: keep)
        }
        let key = Compose1.key(p.shape)
        let taken = Set((0..<S.n).filter { $0 != j }.compactMap { piece(s, S, $0).slot })
        let free = S.slots.indices.filter { !taken.contains($0) }
        if let near = free.filter({ S.slots[$0].key == key && abs(S.slots[$0].x - x) <= 3 && abs(S.slots[$0].y - y) <= 3 })
            .min(by: { hypot(S.slots[$0].x - x, S.slots[$0].y - y) < hypot(S.slots[$1].x - x, S.slots[$1].y - y) }) {
            let keep: Numbers = ["x\(i)_\(j)": S.slots[near].x, "y\(i)_\(j)": S.slots[near].y, "s\(i)_\(j)": Double(near + 1)]
            let full = taken.count + 1 == S.n
            return HandMove(hand: ["bk": Double(j), "bx": x, "by": y], set: full ? [(box, 1)] : [], keep: keep, check: full)
        }
        let tr = trayAt(s, S, j), home: Numbers = ["x\(i)_\(j)": tr.0, "y\(i)_\(j)": tr.1, "s\(i)_\(j)": 0]
        let here = Shapes1.shift(p.shape, x, y), sp = Shapes1.samples(here)
        guard sp.contains(where: { Shapes1.inside($0, S.out) }) else { return HandMove(hand: back, keep: home) }
        var code = -3
        let others = (0..<S.n).filter { $0 != j }.map { piece(s, S, $0) }.filter { $0.slot != nil }.map { Shapes1.shift($0.shape, $0.x, $0.y) }
        if others.contains(where: { o in sp.contains { Shapes1.inside($0, o) && Shapes1.polyDist($0, o) > 0.05 } }) { code = -1 }
        else if !sp.allSatisfy({ Shapes1.inside($0, S.out) || Shapes1.polyDist($0, S.out) < 0.05 }) {
            let d = here.filter { !Shapes1.inside($0, S.out) }.map { Shapes1.polyDist($0, S.out) }.max() ?? 1
            code = -(10 + max(1, Int(d.rounded())))
        } else if !free.contains(where: { S.slots[$0].key == key }) && free.contains(where: { f in (1...3).contains { Compose1.key(Compose1.turned(p.shape, $0)) == S.slots[f].key } }) { code = -2 }
        return HandMove(hand: back, missHand: back, set: [(box, Double(code))], keep: home, check: true)
    }
    private func pieceAt(_ s: PaperState, _ S: Stage, _ q: CGPoint) -> Int? {
        (0..<S.n).reversed().first { j in let p = piece(s, S, j); return p.slot == nil && Shapes1.inside((q.x, q.y), Shapes1.shift(p.shape, p.x, p.y)) }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Compose1.Parts(s.numbers), st = at(s)
        guard st < P.stages.count else { return nil }
        let S = Stage(P, st)
        return Hands(
            tap: { q in pieceAt(s, S, q).map { j in let p = piece(s, S, j); return letGo(s, S, j, x: p.x, y: p.y, turn: 1) } },
            grab: { q in
                guard let j = pieceAt(s, S, q) else { return nil }
                let p = piece(s, S, j)
                return ["grab": 1, "g": Double(j), "ox": p.x - q.x, "oy": p.y - q.y, "x": p.x, "y": p.y, "fx": p.x, "fy": p.y]
            },
            drag: { q, h in
                var h = h
                h["x"] = (q.x + (h["ox"] ?? 0)).rounded(); h["y"] = (q.y + (h["oy"] ?? 0)).rounded()
                return h
            },
            release: { h in
                let j = Int(h["g"] ?? 0), x = h["x"] ?? 0, y = h["y"] ?? 0
                let moved = x != h["fx"] || y != h["fy"]
                return letGo(s, S, j, x: x, y: y, turn: moved ? 0 : 1)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Compose1.Parts(s.numbers), st = at(s)
        guard st < P.stages.count else { return [] }
        let S = Stage(P, st)
        var moves: [GhostMove] = [], taken = Set((0..<S.n).compactMap { piece(s, S, $0).slot })
        for j in 0..<S.n {
            var p = piece(s, S, j)
            if p.slot != nil { continue }
            // turned until its shape fits a free place (a tap each), then slid in
            for _ in 0..<3 where !S.slots.indices.contains(where: { !taken.contains($0) && S.slots[$0].key == Compose1.key(p.shape) }) {
                let c = KS.centroid(Shapes1.shift(p.shape, p.x, p.y))
                moves.append(.tap(.picture(CGPoint(x: c.0, y: c.1))))
                let t = Compose1.turn(p.shape), b0 = Shapes1.bbox(p.shape), b1 = Shapes1.bbox(t)
                p = (t, p.x + ((b0.x1 - b1.x1) / 2).rounded(), p.y + ((b0.y1 - b1.y1) / 2).rounded(), nil)
            }
            guard let f = S.slots.indices.first(where: { !taken.contains($0) && S.slots[$0].key == Compose1.key(p.shape) }) else { continue }
            taken.insert(f)
            let c = KS.centroid(Shapes1.shift(p.shape, p.x, p.y))
            moves.append(.drag(from: CGPoint(x: c.0, y: c.1), to: CGPoint(x: c.0 + S.slots[f].x - p.x, y: c.1 + S.slots[f].y - p.y)))
        }
        return moves
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Compose1.Parts(s.numbers), st = at(s)
        guard st < P.stages.count else { return nil }
        let S = Stage(P, st)
        // the first piece in the tray, let go hanging off the outline's right edge
        guard let j = (0..<S.n).first(where: { piece(s, S, $0).slot == nil }) else { return nil }
        let p = piece(s, S, j), w = Shapes1.bbox(p.shape).x1
        return letGo(s, S, j, x: S.OW - w + 5, y: 0, turn: 0)
    }
}
