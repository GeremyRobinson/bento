import SwiftUI

/// Halves, thirds and fourths on the paper, as in the preview (design/prototype/grade2-ch7.html, dShares): the whole big, a size
/// every cut lands on whole squares (a rectangle 48 × 24, a square 24 × 24, a circle 30 across centred on a block corner; the design's 36 showed at 65–71%). Cut with
/// the ruler: drag edge to edge (straight down or across, snapped to a square; the square corner to corner; the circle from the
/// middle out, or across through it, to 30°); the readout beside it gives each part's width as it's cut (`16 | 16 | 16`; `the
/// same` for a circle or corner to corner). Right: the parts number and each lands on the first in turn. Then the names (in a row
/// under the rectangle, a column beside the square and circle), shade by tapping parts (`2 thirds`), Check, and write `[3] thirds
/// make 1 whole`. Same size? (problems 3, 7, 11 …): two copies at half size, cut two ways, a part of each tinted; tap yes or no;
/// then the part of one lifts, cuts into pieces and slides onto the part of the other, covering it exactly.
///
/// Kept: the cuts "nc", "c<i>" (Shares2's numbers), "bad" 1 the cuts aren't equal (red; the next cut starts again); "wp" a block
/// tapped wrong; "s<j>" part j shaded. Hand: "grab", "ax", "ay", "bx", "by".
@MainActor
struct Shares2Lesson: PaperLesson {
    typealias Pt = KS.Pt
    var liveKeys: Set<String> { ["bx", "by"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }

    @MainActor struct Lay {
        let P: Shares2.Parts
        /// The square and circle have the readout, blocks and record beside them; the rectangle and the copies under.
        var side: Bool { !P.same && P.shape != 0 }
        var g: Shares2.Geom { P.same ? Shares2.geom(P.shape, half: true) : Shares2.geom(P.shape) }
        var g2: Shares2.Geom { Shares2.geom(P.shape, x0: 30, half: true) }
        var right: Double { P.same ? 54 : g.x0 + g.W }
        var bottom: Double { g.y0 + g.H }
        var SCX: Double { EG2.ceil5(right + 3) }
        var RO: CGPoint { side ? CGPoint(x: SCX, y: 2) : CGPoint(x: right + 2, y: g.y0 + g.H / 2) }
        var BX: Double { side ? SCX : 0 }
        var BY: Double { side ? 6 : bottom + 3 }
        init(_ n: Numbers) { P = Shares2.Parts(n) }
        func names() -> [CGRect] { KS.rects(3, x: BX, y: BY, w: 9, side ? .column : .row) }
        func yesNo() -> [CGRect] { KS.rects(2, x: BX, y: BY, w: 9, .row) }
        var asked: [Int] { Shares2.cutSet(g, P.parts, P.cut) }
    }

    private func cuts(_ s: PaperState, _ L: Lay) -> [Int] {
        if L.P.same || at(s) > 0 {
            let n = Int(s.run.kept["nc"] ?? 0)
            return n > 0 && !L.P.same ? (0..<n).map { Int(s.run.kept["c\($0)"] ?? 0) } : L.asked
        }
        let n = Int(s.run.kept["nc"] ?? 0)
        return (0..<n).map { Int(s.run.kept["c\($0)"] ?? 0) }
    }
    private func cutLine(_ pen: inout GridPen, _ id: String, _ g: Shares2.Geom, _ c: Int, _ colour: Sketch.Colour, dashed: Bool = false) {
        let (a, b) = Shares2.line(g, c)
        pen.line(id, [a, b], colour, dashed: dashed)
    }
    private func toks(_ P: Shares2.Parts, done: Bool) -> [M7.Tok] {
        [done ? .n(P.parts, .chapter) : .box("w", cells: 1), .w(P.recordWords)]
    }

    // MARK: Same size?: a part of one copy cut into pieces that cover a part of the other exactly
    struct Piece { var pts: [Pt]; var rot: Double; var dx: Double; var dy: Double }
    static func moved(_ p: Piece) -> [Pt] {
        let c = Shapes2.centroid(p.pts)
        return p.pts.map { q in let r = Shapes2.rot(q, c, p.rot); return (r.0 + p.dx, r.1 + p.dy) }
    }
    static func clip(_ pts: [Pt], _ f: (Pt) -> Double) -> [Pt] {
        var out: [Pt] = []
        for i in pts.indices {
            let p = pts[i], q = pts[(i + 1) % pts.count], fp = f(p), fq = f(q)
            if fp <= 0 { out.append(p) }
            if (fp < 0 && fq > 0) || (fp > 0 && fq < 0) { let u = fp / (fp - fq); out.append((p.0 + (q.0 - p.0) * u, p.1 + (q.1 - p.1) * u)) }
        }
        return out
    }
    static func box(_ p: [Pt]) -> (x0: Double, y0: Double, x1: Double, y1: Double) { Shapes1.bbox(p) }
    static func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> [Pt] { [(x, y), (x + w, y), (x + w, y + h), (x, y + h)] }
    /// The mover (a part of one copy), the target (a part of the other) and the pieces the mover is cut into, each with its move.
    static func dissect(_ L: Lay) -> (mover: [Pt], target: [Pt], pieces: [Piece]) {
        let P = L.P, gA = L.g, gB = L.g2
        let jA = Shares2.judge(gA, Shares2.cutSet(gA, P.parts, P.cut)), jB = Shares2.judge(gB, Shares2.cutSet(gB, P.parts, P.other))
        let swap = jB.tri && !jA.tri
        let gm = swap ? gB : gA, jm = swap ? jB : jA, gt = swap ? gA : gB, jt = swap ? jA : jB
        let off = (gt.x0 - gm.x0, gt.y0 - gm.y0), mover = jm.parts[0], target = jt.parts[0], e = 1e-9
        var pieces: [Piece] = []
        if !jm.tri {
            let bm = box(mover), bt = box(target), mw = bm.x1 - bm.x0, mh = bm.y1 - bm.y0, tW = bt.x1 - bt.x0, tH = bt.y1 - bt.y0
            if mw > tW + e {
                for j in 0..<Int((mw / tW).rounded()) {
                    let p = rect(bm.x0 + Double(j) * tW, bm.y0, tW, mh), c = Shapes2.centroid(p)
                    pieces.append(Piece(pts: p, rot: 0, dx: bt.x0 + tW / 2 - c.0, dy: bt.y0 + Double(j) * mh + mh / 2 - c.1))
                }
            } else if mh > tH + e {
                for j in 0..<Int((mh / tH).rounded()) {
                    let p = rect(bm.x0, bm.y0 + Double(j) * tH, mw, tH), c = Shapes2.centroid(p)
                    pieces.append(Piece(pts: p, rot: 0, dx: bt.x0 + Double(j) * mw + mw / 2 - c.0, dy: bt.y0 + tH / 2 - c.1))
                }
            } else { pieces.append(Piece(pts: mover, rot: 0, dx: off.0, dy: off.1)) }
            return (mover, target, pieces)
        }
        // a triangle onto a rectangle: the bit outside the rectangle turns about the square's middle into the gap
        let bt = box(target), R = (x0: bt.x0 - off.0, y0: bt.y0 - off.1, x1: bt.x1 - off.0, y1: bt.y1 - off.1)
        let cx = gm.x0 + gm.W / 2, cy = gm.y0 + gm.H / 2, O = (cx, cy), xs = mover.map(\.0)
        let crossX = (xs.min() ?? 0) < cx - e && (xs.max() ?? 0) > cx + e && (abs(R.x0 - cx) < e || abs(R.x1 - cx) < e)
        let f: (Pt) -> Double
        if crossX { f = abs(R.x1 - cx) < e ? { $0.0 - cx } : { cx - $0.0 } } else { f = abs(R.y1 - cy) < e ? { $0.1 - cy } : { cy - $0.1 } }
        let pin = clip(mover, f), pout = clip(mover, { -f($0) }), cOut = Shapes2.centroid(pout)
        let turn = [180.0, 90, -90].first { a in let c = Shapes2.rot(cOut, O, a); return c.0 > R.x0 && c.0 < R.x1 && c.1 > R.y0 && c.1 < R.y1 } ?? 180
        let land = Shapes2.rot(cOut, O, turn)
        pieces = [Piece(pts: pin, rot: 0, dx: off.0, dy: off.1), Piece(pts: pout, rot: turn, dx: land.0 + off.0 - cOut.0, dy: land.1 + off.1 - cOut.1)]
        return (mover, target, pieces)
    }
    /// How part j lands on part 0 (the match): rectangles slide; triangles and wedges turn about the middle.
    private func landed(_ g: Shares2.Geom, _ parts: [[Pt]], _ j: Int) -> [Pt] {
        let c0 = Shapes2.centroid(parts[0]), cj = Shapes2.centroid(parts[j])
        if g.kind != 2 && parts[0].count == 4 { return parts[j].map { ($0.0 + c0.0 - cj.0, $0.1 + c0.1 - cj.1) } }
        let O = (g.cx, g.cy)
        var best = (d: 1e9, a: 0.0)
        for k in -11...12 {
            let a = Double(k) * 30, p = Shapes2.rot(cj, O, a), d = hypot(p.0 - c0.0, p.1 - c0.1)
            if d < best.d - 1e-6 || (abs(d - best.d) < 1e-6 && abs(a) < abs(best.a)) { best = (d, a) }
        }
        return parts[j].map { Shapes2.rot($0, O, best.a) }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let L = Lay(s.numbers), P = L.P, st = at(s), g = L.g
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        let bad = st == 0 && (s.run.kept["bad"] ?? 0) != 0
        var cs = cuts(s, L)
        if bad && s.grabbed { cs = [] }
        let j = Shares2.judge(g, cs), parts = j.n > 1 ? j.parts : []
        let shaded = st == 4 ? Array(0..<P.shaded) : parts.indices.filter { (s.run.kept["s\($0)"] ?? 0) != 0 }
        var actions: [String] = []
        // the whole: its parts filled (the shaded ones stronger), its outline, its cuts
        for (k, p) in parts.enumerated() where st >= 2 && shaded.contains(k) { KS.poly(&pic, "sh\(cs.sorted())\(k)", p, KS.lit) }
        KS.outline(&pic, "ol", Shares2.outline(g), .ink)
        for c in cs { cutLine(&pic, "ct\(c)\(bad)", g, c, bad ? KS.red : .ink) }
        if P.same {
            KS.outline(&pic, "ol2", Shares2.outline(L.g2), .ink)
            for c in Shares2.cutSet(L.g2, P.parts, P.other) { cutLine(&pic, "cb\(c)", L.g2, c, .ink) }
            let D = Self.dissect(L)
            if st == 0 {
                KS.poly(&pic, "qa", D.mover, KS.fill); KS.poly(&pic, "qb", D.target, KS.fill)
                let w = s.run.kept["wp"].map { Int($0) }.flatMap { $0 >= 0 ? $0 : nil }
                KS.blocks(&pic, "yn", ["yes", "no"], L.yesNo(), wrong: w, spot: spot ? 0 : nil)
                if ring { KK.hintBox(&pic, "hr", x: -1, y: -1, w: L.right + 2, h: g.H + 2) }
            }
            if st == 1 {
                // the part lifts, cuts into pieces and slides onto the other's, covering it exactly
                KS.poly(&pic, "tg", D.target, KS.fill)
                pic.sketch.delay = 0.6
                for (k, pc) in D.pieces.enumerated() {
                    let id = "pc\(k)"
                    pic.sketch.from = Self.kinds { q in KS.poly(&q, id, pc.pts, KS.lit) }
                    KS.poly(&pic, id, Self.moved(pc), KS.lit)
                    pic.sketch.from = Self.kinds { q in KS.outline(&q, id + "o", pc.pts, .chapter) }
                    KS.outline(&pic, id + "o", Self.moved(pc), .chapter)
                }
                pic.sketch.from = [:]; pic.sketch.delay = 0
            }
        }
        // cutting: the cut under the finger dashed, the readout beside
        if st == 0 && !P.same {
            var show = cs
            if s.grabbed, let ax = s.h("ax"), let ay = s.h("ay"), let bx = s.h("bx"), let by = s.h("by"),
               let new = Shares2.snap(g, (ax, ay), (bx, by)), let c0 = new.first, c0 > 0 {
                for c in new where !cs.contains(c) { cutLine(&live, "lv\(c)", g, c, .chapter, dashed: true); show.append(c) }
            }
            if let r = Shares2.readout(g, Shares2.judge(g, show)) {
                if s.grabbed { TMK.readout(&live, r, x: L.RO.x, y: L.RO.y); live.reads(r) } else { TMK.readout(&pic, r, x: L.RO.x, y: L.RO.y) }
            }
            if ring { KK.hintBox(&pic, "hr", x: g.x0 - 1, y: g.y0 - 1, w: g.W + 2, h: g.H + 2) }
            if spot { for c in L.asked where !cs.contains(c) { cutLine(&pic, "spot\(c)", g, c, .chapter, dashed: true) } }
        }
        // right: the parts number, then each lands on the first in turn
        if st == 1 && !P.same {
            for (k, p) in parts.enumerated() { let c = Shapes2.centroid(p); A1.note(&pic, "pn\(k)", "\(k + 1)", x: c.0, y: c.1, centred: true) }
            for k in 1..<max(1, parts.count) {
                let id = "mv\(k)", to = landed(g, parts, k)
                pic.sketch.delay = 0.65 * Double(k - 1)
                pic.sketch.from = Self.kinds { q in KS.poly(&q, id, parts[k], KS.fill) }
                KS.poly(&pic, id, to, KS.fill)
                pic.sketch.from = Self.kinds { q in KS.outline(&q, id + "o", parts[k], .chapter) }
                KS.outline(&pic, id + "o", to, .chapter)
            }
            pic.sketch.from = [:]; pic.sketch.delay = 0
        }
        if st == 1 {
            let w = s.run.kept["wp"].map { Int($0) }.flatMap { $0 >= 0 ? $0 : nil }
            KS.blocks(&pic, "nm", Shares2.nameList, L.names(), wrong: w, spot: spot ? P.nameIndex : nil, ring: ring)
        }
        if st == 2 {
            let k = shaded.count
            if k > 0 { TMK.readout(&pic, "\(k) \(Shares2.pw(k, P.parts))", x: L.RO.x, y: L.RO.y); actions = ["Check"] }
            if ring { KK.hintBox(&pic, "hr", x: g.x0 - 1, y: g.y0 - 1, w: g.W + 2, h: g.H + 2) }
            if spot, k < P.shaded, let u = parts.indices.first(where: { !shaded.contains($0) }) { KS.poly(&pic, "spot\(u)", parts[u], KS.fill); KS.outline(&pic, "spoto\(u)", parts[u], .chapter, dashed: true) }
        }
        // the record: [3] thirds make 1 whole
        if st >= 3 {
            let t = toks(P, done: st == 4)
            if st == 3 {
                M7.row(&rec, "rec", t, x: L.BX, line: L.BY + 2)
                if ring { KK.hintBox(&pic, "hr", x: g.x0 - 1, y: g.y0 - 1, w: g.W + 2, h: g.H + 2) }
                if spot { A1.note(&pic, "spot", "\(P.parts)", x: L.BX + 1, y: L.BY - 0.6, centred: true) }
            } else { M7.row(&pic, "rec", t, x: L.BX, line: L.BY + 2) }
        }
        let roW = KK.width(L.side ? "12 | 12 · 18 | 18" : P.same ? "4 fourths" : "16 | 16 | 16 | 16", KK.words)
        let recW = M7.width(toks(P, done: true))
        var right = L.side ? L.SCX + max(roW, recW, 15) : max(L.right + 2 + roW, L.BX + 29, EG2.ceil5(L.BX + recW + 1) + 10)
        if L.side { right = max(right, L.SCX + 11) }
        let bottom = L.side ? max(L.bottom, L.BY + 15) : L.BY + 5
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: actions,
                            extent: pic.R(-1, -1, right + 2, bottom + 1))
    }
    static func kinds(_ draw: (inout GridPen) -> Void) -> [String: Sketch.Kind] { A2.kinds(draw) }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let L = Lay(s.numbers), st = at(s)
        switch st {
        case 2: return CGPoint(x: L.BX, y: L.BY)
        case 3, 4:
            if L.side { return CGPoint(x: L.BX, y: L.BY + 5) }
            return CGPoint(x: EG2.ceil5(L.BX + M7.width(toks(L.P, done: st == 4)) + 1), y: L.BY)
        default: return nil
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let L = Lay(s.numbers), P = L.P, st = at(s), g = L.g
        switch st {
        case 0 where P.same:
            let r = L.yesNo()
            return Hands(tap: { q in
                guard let j = KS.hit(q, r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("y", j == 0 ? 1 : 0)], keep: ["wp": j == 0 ? -1 : 1], check: true)
            })
        case 0:
            let bad = (s.run.kept["bad"] ?? 0) != 0, made = bad ? [] : cuts(s, L)
            return Hands(
                grab: { q in
                    guard q.x >= g.x0 - 3, q.y >= g.y0 - 3, q.x <= g.x0 + g.W + 3, q.y <= g.y0 + g.H + 3 else { return nil }
                    return ["grab": 1, "ax": q.x, "ay": q.y, "bx": q.x, "by": q.y]
                },
                drag: { q, h in var h = h; h["bx"] = q.x; h["by"] = q.y; return h },
                release: { h in
                    guard let new = Shares2.snap(g, (h["ax"] ?? 0, h["ay"] ?? 0), (h["bx"] ?? 0, h["by"] ?? 0)) else { return HandMove(hand: [:]) }
                    let r = Shares2.cutting(g, P.parts, made, new)
                    var keep: Numbers = ["nc": Double(r.cuts.count), "bad": 0]
                    for (i, c) in r.cuts.enumerated() { keep["c\(i)"] = Double(c) }
                    if r.code == 0 { return HandMove(hand: [:], keep: keep) }
                    if r.code == 1 { return HandMove(hand: [:], missHand: [:], set: [("k", 1)], keep: keep, check: true) }
                    // a cut that isn't a cut keeps what's made; cuts that make unequal parts show red until the next
                    if r.code > -4 && r.code < 0 && r.cuts == made { keep["bad"] = bad ? 1 : 0 } else { keep["bad"] = 1 }
                    return HandMove(hand: [:], missHand: [:], set: [("k", Double(r.code))], keep: keep, check: true)
                })
        case 1:
            let r = L.names()
            return Hands(tap: { q in
                guard let j = KS.hit(q, r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wp": j == P.nameIndex ? -1 : Double(j)], check: true)
            })
        case 2:
            let parts = Shares2.judge(g, cuts(s, L)).parts
            let k = parts.indices.filter { (s.run.kept["s\($0)"] ?? 0) != 0 }.count
            return Hands(tap: { q in
                guard let j = parts.firstIndex(where: { KS.inside((q.x, q.y), $0) }) else { return nil }
                return HandMove(hand: nil, missHand: nil, keep: ["s\(j)": (s.run.kept["s\(j)"] ?? 0) != 0 ? 0 : 1])
            }, actions: ["Check": { HandMove(hand: nil, missHand: nil, set: [("s", Double(k))], check: true) }])
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let L = Lay(s.numbers), P = L.P, st = at(s), g = L.g
        func mid(_ r: CGRect) -> GhostMove { .tap(.picture(CGPoint(x: r.midX, y: r.midY))) }
        switch st {
        case 0 where P.same: return [mid(L.yesNo()[0])]
        case 0:
            let made = (s.run.kept["bad"] ?? 0) != 0 ? [] : cuts(s, L)
            var moves: [GhostMove] = []
            var todo = L.asked.filter { !made.contains($0) }
            func pt(_ p: Pt, _ k: Double = 0.94) -> CGPoint { CGPoint(x: g.cx + (p.0 - g.cx) * k, y: g.cy + (p.1 - g.cy) * k) }
            while let c = todo.first {
                todo.removeFirst()
                let (a, b) = Shares2.line(g, c)
                if c >= 400 {
                    // a circle's diameter is one drag through the middle; a radius a drag from the middle out
                    if let k = todo.firstIndex(of: Shares2.radius(c - 400 + 180)) {
                        let (_, b2) = Shares2.line(g, todo[k]); todo.remove(at: k)
                        moves.append(.drag(from: pt(b2), to: pt(b)))
                    } else { moves.append(.drag(from: CGPoint(x: a.0, y: a.1), to: pt(b))) }
                    continue
                }
                let u = (b.0 - a.0, b.1 - a.1), l = max(1e-9, hypot(u.0, u.1)), e = (u.0 / l * 0.6, u.1 / l * 0.6)
                moves.append(.drag(from: CGPoint(x: a.0 + e.0, y: a.1 + e.1), to: CGPoint(x: b.0 - e.0, y: b.1 - e.1)))
            }
            return moves
        case 1: return [mid(L.names()[P.nameIndex])]
        case 2:
            let parts = Shares2.judge(g, cuts(s, L)).parts, on = parts.indices.filter { (s.run.kept["s\($0)"] ?? 0) != 0 }
            func tap(_ k: Int) -> GhostMove { let c = Shapes2.centroid(parts[k]); return .tap(.picture(CGPoint(x: c.0, y: c.1))) }
            var moves = on.dropFirst(min(on.count, P.shaded)).map(tap)
            moves += parts.indices.filter { !on.contains($0) }.prefix(max(0, P.shaded - on.count)).map(tap)
            moves.append(.tap(.action("Check")))
            return moves
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let L = Lay(s.numbers), P = L.P, st = at(s), g = L.g
        switch st {
        case 0 where P.same: return HandMove(hand: nil, missHand: nil, set: [("y", 0)], keep: ["wp": 1], check: true)
        case 0:
            var r = Shares2.cutting(g, P.parts, [], [Shares2.down(Int(g.W) / 2 - 4)])
            if r.code == 0 { r = Shares2.cutting(g, P.parts, r.cuts, [Shares2.across(Int(g.H) / 2 - 3)]) }
            if g.kind == 2 { r = ([Shares2.radius(270), Shares2.radius(0)], -4) }
            var keep: Numbers = ["nc": Double(r.cuts.count), "bad": 1]
            for (i, c) in r.cuts.enumerated() { keep["c\(i)"] = Double(c) }
            return HandMove(hand: [:], missHand: [:], set: [("k", Double(r.code))], keep: keep, check: true)
        case 1:
            let j = P.nameIndex == 0 ? 2 : 0
            return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wp": Double(j)], check: true)
        case 2:
            let k = P.shaded == 1 ? 2 : 1
            var keep: Numbers = ["s0": 1, "s1": 0]
            if k == 2 { keep["s1"] = 1 }
            return HandMove(hand: nil, missHand: nil, set: [("s", Double(k))], keep: keep, check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? { at(s) == 3 ? ["w": Double(Shares2.Parts(s.numbers).slips.first?.0 ?? 1)] : nil }
}
