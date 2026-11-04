import SwiftUI

/// Build with solids on the paper, as in the preview (design/prototype/grade1-ch6.html, dBuild), with the shared 3D
/// (PaperStand.swift). Unit cubes as they are: one cube is one block (5 squares). Flat first: the new solid's footprint dashed on
/// the paper, its pieces beside it (left of it: turned +28°, the left of the paper rises, so they stand beside it), each named.
/// The paper tilts by itself and the new solid stands over its outline as a dashed ghost. Drag a piece: it moves block by block
/// over the paper and up onto what's placed ("1 of 3 in"); tap one to turn it (a box along, across, standing; a cylinder standing
/// or lying). Let go inside the ghost: it stays; else it slides back home, said ("That sticks out past the shape.", "Nothing
/// stands on a point.", "It rolls off. Put a flat face down.", "The cone goes on the cylinder."). Built, a box's pieces become
/// one box and the record writes itself; a two-stage problem keeps the box made as a piece of a bigger one. The paper goes flat
/// again before the next problem.
///
/// Kept (stage s, piece n, key "s_n"): "i…", "j…", "k…" its place (blocks; the tray is left of the footprint, so negative), "p…"
/// its pose, "in…" placed; "back" when one slid back, "bg", "bi", "bj", "bk" which and from where. Hand: "grab", "g", "dx", "dy",
/// "i", "j", "k", "fi", "fj".
@MainActor
struct Build1Lesson: PaperLesson {
    typealias Vox = Build1.Vox
    var solid: Bool { true }
    var liveKeys: Set<String> { ["i", "j", "k", "dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let B = 5.0, slide = 0.45

    struct Item { var kind: String; var h: Int; var pose: Int; var i: Int; var j: Int; var k: Int; var placed: Bool; var ti: Int; var tj: Int
        var piece: Build1.Piece { Build1.Piece(kind: kind, h: h) }
        var d: [Int] { Build1.dims(piece, pose: pose) }
    }

    @MainActor struct Scene {
        let P: Build1.Parts
        let trayW: Int
        var pivot = CGPoint.zero
        static var cache: [String: (Int, CGPoint)] = [:]
        var FX: Double { Build1Lesson.B * Double(trayW + 1) }
        /// The tray's places (blocks from its left), at most 5 blocks wide (7 showed 4 cubes at 69%), rows a block apart past the deepest piece in a row.
        static func tray(_ P: Build1.Parts, _ s: Int) -> (at: [(Int, Int)?], w: Int) {
            var ci = 0, cj = 0, deep = 1, w = 0, out: [(Int, Int)?] = []
            for (n, p) in P.stages[s].pieces.enumerated() {
                if p.kind == "made" { out.append(nil); continue }
                let pw = p.kind == "cube" || p.kind == "cone" ? 1 : 2
                if ci > 0 && ci + pw > 5 { ci = 0; cj += deep + 1; deep = 1 }
                out.append((ci, cj)); w = max(w, ci + pw); ci += pw + 1
                deep = max(deep, Build1.dims(p, pose: P.poses[s][n])[1])
            }
            return (out, w)
        }
        init(_ n: Numbers) {
            P = Build1.Parts(n)
            let key = n.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()
            if let c = Scene.cache[key] { trayW = c.0; pivot = c.1; return }
            let parts = P
            trayW = parts.stages.indices.map { Scene.tray(parts, $0).w }.max() ?? 2
            let all = reach, c = SK.bounds(all.map { CGPoint(x: $0.x, y: $0.y) })
            pivot = Standing.pivot(showing: all, at: CGPoint(x: 0, y: 0), from: CGPoint(x: c.midX, y: c.midY))
            Scene.cache[key] = (trayW, pivot)
        }
        func items(_ kept: Numbers, _ s: Int) -> [Item] {
            let tr = Scene.tray(P, s).at
            return P.stages[s].pieces.enumerated().map { n, p in
                if p.kind == "made" { return Item(kind: "made", h: 1, pose: 0, i: 0, j: 0, k: 0, placed: true, ti: 0, tj: 0) }
                let key = "\(s)_\(n)", ti = (tr[n]?.0 ?? 0) - trayW - 1, tj = tr[n]?.1 ?? 0
                func v(_ k: String, _ d: Int) -> Int { Int((kept[k + key] ?? Double(d)).rounded()) }
                return Item(kind: p.kind, h: p.h, pose: v("p", P.poses[s][n]), i: v("i", ti), j: v("j", tj), k: v("k", 0), placed: v("in", 0) == 1, ti: ti, tj: tj)
            }
        }
        /// Everything that can be seen: every stage's new solid and its tray.
        var reach: [Vec3] {
            let B = Build1Lesson.B
            var pts: [Vec3] = []
            func add(_ i: Double, _ j: Double, _ d: [Double]) {
                for a in [0, d[0]] { for b in [0, d[1]] { for c in [0, d[2]] { pts.append(Vec3(FX + B * (i + a), B * (j + b), B * c)) } } }
            }
            for s in P.stages.indices {
                add(0, 0, P.size(s).map(Double.init))
                for it in items([:], s) where !it.placed { add(Double(it.ti), Double(it.tj), [2, Double(max(1, it.d[1])), Double(it.d.max() ?? 1)]) }
            }
            return pts
        }
        /// A piece's body standing at (x, y, z) blocks.
        func body(_ it: Item, _ x: Double, _ y: Double, _ z: Double, id: String, tone: Solids.Tone = .auto) -> Solids.Body {
            let B = Build1Lesson.B, d = it.d.map(Double.init), cx = FX + B * (x + d[0] / 2), cy = B * (y + d[1] / 2), cz = B * z
            switch it.kind {
            case "cone": return SK.cone(B / 2, B).posed(SK.I, Vec3(cx, cy, cz)).body(id, tone: tone)
            case "cylinder":
                if it.pose == 1 { return SK.cylinder(B / 2, B * Double(it.h)).posed(SK.ry(.pi / 2), Vec3(FX + B * x, cy, cz + B / 2)).body(id, tone: tone) }
                return SK.cylinder(B / 2, B * Double(it.h)).posed(SK.I, Vec3(cx, cy, cz)).body(id, tone: tone)
            default: return SK.box(B * d[0], B * d[1], B * d[2]).posed(SK.I, Vec3(cx, cy, cz)).body(id, tone: tone)
            }
        }
        /// The level a piece stands at over blocks (i, j): the top of what's placed there, and what that is.
        func under(_ items: [Item], _ x: Int, _ p: Item, _ i: Int, _ j: Int) -> (k: Int, top: Item?) {
            var k = 0, top: Item? = nil
            for (n, q) in items.enumerated() where n != x && q.placed {
                for v in P.vox(q.piece, pose: q.pose, at: q.i, q.j, q.k) where v.i >= i && v.i < i + p.d[0] && v.j >= j && v.j < j + p.d[1] && v.k + 1 > k { k = v.k + 1; top = q }
            }
            return (k, top)
        }
        /// A piece let go at (i, j): 0 not over the outline (it just goes home), 1 it fits, or the miss's code.
        func check(_ s: Int, _ items: [Item], _ x: Int, _ p: Item, _ i: Int, _ j: Int) -> Int {
            let gh = P.ghost(s), u = under(items, x, p, i, j), vs = P.vox(p.piece, pose: p.pose, at: i, j, u.k)
            guard vs.contains(where: { v in gh.keys.contains { $0.i == v.i && $0.j == v.j } }) else { return 0 }
            if u.top?.kind == "cone" { return -2 }
            if p.kind == "cylinder" && p.pose == 1 { return -3 }
            let taken = Set(items.enumerated().filter { $0.offset != x && $0.element.placed }.flatMap { P.vox($0.element.piece, pose: $0.element.pose, at: $0.element.i, $0.element.j, $0.element.k) })
            if vs.contains(where: { gh[$0] == nil || taken.contains($0) }) { return -1 }
            if vs.contains(where: { gh[$0] != Build1.label(p.kind) }) { return -(10 + (Build1.kinds.firstIndex(of: p.kind) ?? 0)) }
            return 1
        }
        /// Where piece x can go (Show me, a second miss): the taps to turn it, and the place.
        func target(_ s: Int, _ items: [Item], _ x: Int) -> (taps: Int, pose: Int, i: Int, j: Int, k: Int)? {
            let it = items[x], size = P.size(s)
            let poses = it.kind == "box" ? (0..<3).map { (it.pose + $0) % 3 } : it.kind == "cylinder" ? [it.pose, 1 - it.pose] : [it.pose]
            for (t, pose) in poses.enumerated() {
                var p = it; p.pose = pose
                for i in 0..<size[0] { for j in 0..<size[1] where check(s, items, x, p, i, j) == 1 { return (t, pose, i, j, under(items, x, p, i, j).k) } }
            }
            return nil
        }
    }

    func stands(_ s: PaperState) -> CGPoint? { Scene(s.numbers).pivot }
    func standDelay(_ s: PaperState) -> Double { 0.9 }

    static func boxEdges(_ x0: Vec3, _ d: Vec3) -> [[Vec3]] {
        func v(_ a: Double, _ b: Double, _ c: Double) -> Vec3 { Vec3(x0.x + a * d.x, x0.y + b * d.y, x0.z + c * d.z) }
        return [[v(0, 0, 0), v(1, 0, 0), v(1, 1, 0), v(0, 1, 0), v(0, 0, 0)], [v(0, 0, 1), v(1, 0, 1), v(1, 1, 1), v(0, 1, 1), v(0, 0, 1)],
                [v(0, 0, 0), v(0, 0, 1)], [v(1, 0, 0), v(1, 0, 1)], [v(1, 1, 0), v(1, 1, 1)], [v(0, 1, 0), v(0, 1, 1)]]
    }
    /// A ghost part's dashed lines: a box's edges; a cylinder's rims and sides, a cone's rim and sides, as seen from the eye.
    private func ghostLines(_ Sc: Scene, _ g: Build1.Ghost, id: String, colour: Sketch.Colour) -> [Solids.Line] {
        let B = Self.B, o = Vec3(Sc.FX + B * Double(g.at[0]), B * Double(g.at[1]), B * Double(g.at[2]))
        if g.kind == "box" { return Self.boxEdges(o, Vec3(B * Double(g.d[0]), B * Double(g.d[1]), B * Double(g.d[2]))).enumerated().map { Solids.Line(id: "\(id)e\($0.offset)", pts: $0.element, colour: colour, dashed: true) } }
        let c = o + Vec3(B / 2, B / 2, 0), r = B / 2, h = B * Double(g.d[2]), e = SK.eye, l = max(1e-6, hypot(e.x, e.y)), side = Vec3(-e.y / l * r, e.x / l * r, 0)
        let rim = { (z: Double) in SK.ring(r, z, 40, closed: true).map { $0 + c } }
        var out = [Solids.Line(id: "\(id)r0", pts: rim(0), colour: colour, dashed: true)]
        if g.kind == "cone" {
            out += [Solids.Line(id: "\(id)s0", pts: [c + side, c + Vec3(0, 0, B)], colour: colour, dashed: true), Solids.Line(id: "\(id)s1", pts: [c - side, c + Vec3(0, 0, B)], colour: colour, dashed: true)]
        } else {
            out += [Solids.Line(id: "\(id)r1", pts: rim(h), colour: colour, dashed: true), Solids.Line(id: "\(id)s0", pts: [c + side, c + side + Vec3(0, 0, h)], colour: colour, dashed: true),
                    Solids.Line(id: "\(id)s1", pts: [c - side, c - side + Vec3(0, 0, h)], colour: colour, dashed: true)]
        }
        return out
    }
    /// The record's corner: beside what stands, on the grid's block lines, a third of the way down it (under it the problem
    /// showed at 68%).
    private func recAt(_ Sc: Scene, _ St: Standing) -> CGPoint {
        let b = St.bounds(Sc.reach) ?? CGRect(x: 0, y: 0, width: 40, height: 30)
        let wr = Sc.P.stages.map { M7.width(Compose1Lesson.toks($0.words)) }.max() ?? 30, x = ((b.maxX + 3) / 5).rounded(.up) * 5
        // beside when that's no wider than the screen shows at 75%; else under
        if x + wr <= 69 { return CGPoint(x: x, y: ((b.minY + b.height / 3) / 5).rounded() * 5) }
        return CGPoint(x: 0, y: (b.maxY + 2).rounded(.up))
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let Sc = Scene(s.numbers), n = Sc.P.stages.count
        guard at(s) == n else { return nil }
        let r = recAt(Sc, s.standing(Sc.pivot)), wr = Sc.P.stages.map { M7.width(Compose1Lesson.toks($0.words)) }.max() ?? 30
        // under the record beside; beside the record's last line under
        return r.x > 0 ? CGPoint(x: r.x, y: r.y + 3 * Double(n) + 1) : CGPoint(x: ((wr + 2) / 5).rounded(.up) * 5, y: r.y + 3 * Double(n - 1))
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let Sc = Scene(s.numbers), P = Sc.P, st = at(s), n = P.stages.count, St = s.standing(Sc.pivot), B = Self.B
        var pic = GridPen(), live = GridPen(stableIds: true), so = Solids()
        let stage = min(st, n - 1), its = Sc.items(s.run.kept, stage), size = P.size(stage)
        // on the paper: the new solid's footprint, dashed
        so.lines.append(Solids.Line(id: "foot\(stage)", pts: [Vec3(Sc.FX, 0, 0.02), Vec3(Sc.FX + B * Double(size[0]), 0, 0.02), Vec3(Sc.FX + B * Double(size[0]), B * Double(size[1]), 0.02),
                                                         Vec3(Sc.FX, B * Double(size[1]), 0.02), Vec3(Sc.FX, 0, 0.02)], colour: .ink3, dashed: true))
        let held = st < n && s.grabbed ? Int(s.h("g") ?? -1) : -1
        let merged = st == n && P.stages[stage].ghost.count == 1 && P.stages[stage].ghost[0].kind == "box"
        var spotAt: (Int, (taps: Int, pose: Int, i: Int, j: Int, k: Int))? = nil
        if st < n {
            if s.on("spot"), let x = its.indices.first(where: { !its[$0].placed }), let t = Sc.target(stage, its, x) { spotAt = (x, t) }
            for (k, g) in P.stages[stage].ghost.enumerated() { so.lines += ghostLines(Sc, g, id: "gh\(stage)_\(k)", colour: spotAt == nil ? .ink3 : .chapter) }
            if let (x, t) = spotAt {
                var p = its[x]; p.pose = t.pose
                let d = p.d.map { B * Double($0) }
                so.lines += Self.boxEdges(Vec3(Sc.FX + B * Double(t.i), B * Double(t.j), B * Double(t.k)), Vec3(d[0], d[1], d[2])).enumerated().map { Solids.Line(id: "sp\($0.offset)", pts: $0.element, colour: .chapter, dashed: false) }
            }
        }
        if merged {
            let d = size.map { B * Double($0) }
            so.bodies.append(SK.box(d[0], d[1], d[2]).posed(SK.I, Vec3(Sc.FX + d[0] / 2, d[1] / 2, 0)).body("mg\(stage)"))
        } else {
            for (x, it) in its.enumerated() {
                var p = it
                if x == held, let i = s.h("i"), let j = s.h("j") { p.i = Int(i); p.j = Int(j); p.k = Int(s.h("k") ?? 0) }
                so.bodies.append(Sc.body(p, Double(p.i), Double(p.j), Double(p.k), id: "pc\(stage)_\(x)", tone: spotAt?.0 == x ? .lit : .auto))
            }
        }
        if st < n {
            // each piece in the tray named under it; the count in front of the footprint
            for (x, it) in its.enumerated() where !it.placed && x != held {
                let d = it.d.map(Double.init)
                so.labels.append(Solids.Label(id: "nm\(stage)_\(x)", text: Build1.name(it.kind), at: Vec3(Sc.FX + B * (Double(it.ti) + d[0] / 2), B * (Double(it.tj) + d[1]) + 1.6, 0), words: Sketch.Words.note))
            }
            let nIn = its.filter(\.placed).count
            so.labels.append(Solids.Label(id: "in\(stage)_\(nIn)", text: "\(nIn) of \(its.count) in", at: Vec3(Sc.FX + B * Double(size[0]) / 2, B * Double(size[1]) + 2.2, 0), words: KK.lit))
            if held >= 0 {
                var p = its[held]; p.i = Int(s.h("i") ?? 0); p.j = Int(s.h("j") ?? 0)
                live.reads("\(nIn + (Sc.check(stage, its, held, p, p.i, p.j) == 1 ? 1 : 0)) of \(its.count) in")
            }
            if s.on("ring") && !s.on("spot"), let b = St.bounds(P.stages[stage].ghost.flatMap { g in ghostLines(Sc, g, id: "", colour: .ink3).flatMap(\.pts) }) {
                KK.hintBox(&pic, "hr", x: b.minX - 1, y: b.minY - 1, w: b.width + 2, h: b.height + 2)
            }
        }
        // one let go in the wrong place slides back home
        if st < n, !s.grabbed, let t0 = s.run.kept["back"], PaperClock.now - t0 < Self.slide + 0.2, let gi = s.run.kept["bg"].map({ Int($0) }), its.indices.contains(gi) {
            let from = Vec3(s.run.kept["bi"] ?? 0, s.run.kept["bj"] ?? 0, s.run.kept["bk"] ?? 0), it = its[gi], to = Vec3(Double(it.i), Double(it.j), Double(it.k)), base = so
            so.play = Solids.Play(start: t0, length: Self.slide) { @MainActor t in
                let u = ease(min(1, (t - t0) / Build1Lesson.slide)), p = from + (to - from) * u
                var o = base
                if let b = o.bodies.firstIndex(where: { $0.id == "pc\(stage)_\(gi)" }) { o.bodies[b] = Sc.body(it, p.x, p.y, p.z, id: "pc\(stage)_\(gi)") }
                return o
            }
        }
        // the record: a line for each solid built, under what stands
        let r = recAt(Sc, St)
        for k in 0..<min(st, n) { KS.line(&pic, "rec\(k)", Compose1Lesson.toks(P.stages[k].words), x: r.x, line: r.y + 1 + 3 * Double(k)) }
        let wr = P.stages.map { M7.width(Compose1Lesson.toks($0.words)) }.max() ?? 0
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(r.x, r.y, wr + 1, 3 * Double(n) + 1), solids: so, standing: St)
    }

    private func hit(_ Sc: Scene, _ St: Standing, _ its: [Item], _ q: CGPoint) -> Int? {
        let f = St.up(q.x, q.y, 0), eye = SK.eye
        let hits = its.indices.filter { x in !its[x].placed && KS.inside((f.x, f.y), SK.hull(Sc.body(its[x], Double(its[x].i), Double(its[x].j), Double(its[x].k), id: "").facets.flatMap { $0 }.map { St.up($0) })) }
        var depth: [Int: Double] = [:]
        for x in hits { let p = Sc.body(its[x], Double(its[x].i), Double(its[x].j), Double(its[x].k), id: "").facets.flatMap { $0 }; depth[x] = (p.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(max(1, p.count)))).dot(eye) }
        return hits.max { (depth[$0] ?? 0) < (depth[$1] ?? 0) }
    }
    private func turn(_ s: PaperState, _ stage: Int, _ it: Item, _ x: Int) -> HandMove {
        let pose = it.kind == "box" ? (it.pose + 1) % 3 : it.kind == "cylinder" ? 1 - it.pose : it.pose
        return HandMove(hand: [:], keep: ["p\(stage)_\(x)": Double(pose)])
    }

    func hands(_ s: PaperState) -> Hands? {
        let Sc = Scene(s.numbers), P = Sc.P, st = at(s), St = s.standing(Sc.pivot), B = Self.B
        guard st < P.stages.count else { return nil }
        let its = Sc.items(s.run.kept, st), box = st == 0 ? "p" : "q"
        return Hands(
            tap: { q in hit(Sc, St, its, q).map { turn(s, st, its[$0], $0) } },
            grab: { q in
                guard let x = hit(Sc, St, its, q) else { return nil }
                let it = its[x]
                return ["grab": 1, "g": Double(x), "dx": Sc.FX + B * Double(it.i) - q.x, "dy": B * Double(it.j) - q.y, "i": Double(it.i), "j": Double(it.j), "k": Double(it.k), "fi": Double(it.i), "fj": Double(it.j)]
            },
            drag: { q, h in
                var h = h
                let x = Int(h["g"] ?? 0)
                let i = max(-12, min(8, Int(((q.x + (h["dx"] ?? 0) - Sc.FX) / B).rounded()))), j = max(-1, min(6, Int(((q.y + (h["dy"] ?? 0)) / B).rounded())))
                h["i"] = Double(i); h["j"] = Double(j); h["k"] = Double(Sc.under(its, x, its[x], i, j).k)
                return h
            },
            release: { h in
                let x = Int(h["g"] ?? 0), i = Int(h["i"] ?? 0), j = Int(h["j"] ?? 0), k = Int(h["k"] ?? 0), it = its[x], key = "\(st)_\(x)"
                if i == Int(h["fi"] ?? 0) && j == Int(h["fj"] ?? 0) { return turn(s, st, it, x) }
                let code = Sc.check(st, its, x, it, i, j)
                let home: Numbers = ["i" + key: Double(it.ti), "j" + key: Double(it.tj), "k" + key: 0, "in" + key: 0, "back": PaperClock.now, "bg": Double(x), "bi": Double(i), "bj": Double(j), "bk": Double(k)]
                if code == 0 { return HandMove(hand: [:], keep: home) }
                if code < 0 { return HandMove(hand: [:], missHand: [:], set: [(box, Double(code))], keep: home, check: true) }
                let full = its.enumerated().allSatisfy { $0.offset == x || $0.element.placed }
                return HandMove(hand: [:], missHand: [:], set: full ? [(box, 1)] : [], keep: ["i" + key: Double(i), "j" + key: Double(j), "k" + key: Double(k), "in" + key: 1], check: full)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let Sc = Scene(s.numbers), P = Sc.P, st = at(s), St = s.standing(Sc.pivot), B = Self.B
        guard st < P.stages.count else { return [] }
        var its = Sc.items(s.run.kept, st), moves: [GhostMove] = []
        func centre(_ it: Item) -> CGPoint {
            let b = SK.bounds(Sc.body(it, Double(it.i), Double(it.j), Double(it.k), id: "").facets.flatMap { $0 }.map { St.up($0) })
            return St.down(CGPoint(x: b.midX, y: b.midY))
        }
        for x in its.indices where !its[x].placed {
            guard let t = Sc.target(st, its, x) else { continue }
            for _ in 0..<t.taps { moves.append(.tap(.picture(centre(its[x])))) }
            its[x].pose = t.pose
            let from = centre(its[x])
            moves.append(.drag(from: from, to: CGPoint(x: from.x + Double(t.i - its[x].i) * B, y: from.y + Double(t.j - its[x].j) * B)))
            its[x].i = t.i; its[x].j = t.j; its[x].k = t.k; its[x].placed = true
        }
        return moves
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let Sc = Scene(s.numbers), P = Sc.P, st = at(s)
        guard st < P.stages.count else { return nil }
        let its = Sc.items(s.run.kept, st)
        guard let x = its.indices.first(where: { !its[$0].placed }) else { return nil }
        // let go hanging off the footprint's right edge
        let size = P.size(st), it = its[x], i = size[0] - it.d[0] + 1, key = "\(st)_\(x)"
        let code = Sc.check(st, its, x, it, i, 0)
        return HandMove(hand: [:], missHand: [:], set: [(st == 0 ? "p" : "q", Double(code == 1 || code == 0 ? -1 : code))],
                        keep: ["i" + key: Double(it.ti), "j" + key: Double(it.tj), "k" + key: 0, "back": PaperClock.now, "bg": Double(x), "bi": Double(i), "bj": 0, "bk": 0], check: true)
    }
}
