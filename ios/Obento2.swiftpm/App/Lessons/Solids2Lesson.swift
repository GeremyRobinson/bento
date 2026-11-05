import SwiftUI

/// Faces, edges and corners on the paper, as in the preview (design/prototype/grade2-ch7.html, dSolids), with the shared 3D
/// (PaperStand.swift): Unit cubes' scale, a block (5 squares) a cube's side. Flat first: the solid's base on the paper (a box 3 × 2
/// blocks, a cube 2 × 2, a square pyramid 2 × 2, a triangular prism 3 × 2), an arrow up beside it. Drag the paper up: it tilts
/// with the finger (on up on the spring past a third, else back) and the solid rises from its base, 2 blocks tall, in true 3D
/// through the long lens. Turn it with one finger (across: round; up and down: over, a quarter turn at most, so its bottom
/// shows: turned further it showed at 70%), snapping every 15°;
/// it rocks to stay on the paper. Tap every face (it lights and takes its number), Check; the same for the edges (each drawn in
/// the chapter colour) and the corners (a dot). Hidden edges are dashed. Then tap its name. The record under it writes
/// `6 faces · 12 edges · 8 corners` as they're found, then the name.
///
/// Kept: "yaw", "pitch" the turn it's left at; "fo<i>" face i counted (its number), "e<i>", "v<i>"; "wn" a name tapped wrong;
/// "upAt" when it rose. Hand: "grab", "up" (the tilt held), "y0"; turning: "x0", "y0", "yaw", "pitch", "turn".
@MainActor
struct Solids2Lesson: PaperLesson {
    var solid: Bool { true }
    var liveKeys: Set<String> { ["up", "y0"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let rise = 0.9
    /// Its name slips run to two rows.
    func messageRows(_ n: Numbers) -> Int { 2 }

    @MainActor struct Scene {
        let P: Solids2.Parts
        let G: Solids2.Geo
        /// The middle of its base on the paper (a turn along the grid has its base on block lines).
        let C: Vec3
        var pivot = CGPoint.zero
        static var cache: [String: CGPoint] = [:]
        init(_ n: Numbers) {
            P = Solids2.Parts(n); G = P.geo
            let base = Self.base(P, G), xs = base.map(\.x), ys = base.map(\.y)
            let hx = ((xs.max() ?? 0) - (xs.min() ?? 0)) / 2, hy = ((ys.max() ?? 0) - (ys.min() ?? 0)) / 2
            C = P.turn == 2 ? Vec3((15 + hx).rounded(), (5 + hy).rounded(), 0) : Vec3(15 + hx, 5 + hy, 0)
            let key = "\(P.solid),\(P.turn)"
            if let p = Scene.cache[key] { pivot = p; return }
            let all = reach
            let b = SK.bounds(all.map { CGPoint(x: $0.x, y: $0.y) })
            pivot = Standing.pivot(showing: all, at: CGPoint(x: 0, y: 0), from: CGPoint(x: b.midX, y: b.midY))
            Scene.cache[key] = pivot
        }
        static func base(_ P: Solids2.Parts, _ G: Solids2.Geo) -> [Vec3] {
            let R = SK.rz(P.yaw0 * .pi / 180), f = G.N.firstIndex { $0.z < -0.9 } ?? 0
            return G.F[f].map { SK.mv(R, G.V[$0]) }
        }
        /// The turn: round the up axis by yaw, then over about the screen's across (the paper is seen turned +28°).
        static func R(_ yaw: Double, _ pitch: Double) -> SK.M3 {
            let a = PaperView3D.tilted.azimuth * .pi / 180
            return SK.mm(axis(Vec3(cos(a), -sin(a), 0), pitch * .pi / 180), SK.rz(yaw * .pi / 180))
        }
        static func axis(_ u: Vec3, _ t: Double) -> SK.M3 {
            let c = cos(t), s = sin(t), k = 1 - c, x = u.x, y = u.y, z = u.z
            let r0: [Double] = [c + x * x * k, x * y * k - z * s, x * z * k + y * s]
            let r1: [Double] = [y * x * k + z * s, c + y * y * k, y * z * k - x * s]
            let r2: [Double] = [z * x * k - y * s, z * y * k + x * s, c + z * z * k]
            return r0 + r1 + r2
        }
        /// Its corners at a turn, standing on the paper (its lowest point on it), `up` 0 (flat on its base) to 1 (risen).
        func pts(_ yaw: Double, _ pitch: Double, up: Double = 1) -> [Vec3] {
            let M = Self.R(yaw, pitch)
            let w = G.V.map { SK.mv(M, $0 - Vec3(0, 0, 5)) }, lift = -(w.map(\.z).min() ?? 0)
            return w.map { Vec3(C.x + $0.x, C.y + $0.y, ($0.z + lift) * up) }
        }
        /// Every turn a finger can reach, to frame it once for all of them.
        static var reaches: [String: [Vec3]] = [:]
        static var frames: [String: CGRect] = [:]
        var reach: [Vec3] {
            let key = "\(P.solid),\(P.turn)"
            if let r = Self.reaches[key] { return r }
            var out: [Vec3] = []
            for y in stride(from: 0.0, to: 360, by: 30) { for p in stride(from: -90.0, through: 90, by: 30) { out += pts(y + P.yaw0, p) } }
            // only its outline matters (what's seen of it standing): the points on the edge of it as the tilted view sees it
            let v = Standing(pivot: CGPoint(x: C.x, y: C.y)), seen = out.map { v.up($0) }
            let hull = SK.hull(seen)
            var keep: [Vec3] = []
            for (i, q) in seen.enumerated() where hull.contains(where: { abs($0.0 - q.x) < 1e-9 && abs($0.1 - q.y) < 1e-9 }) { keep.append(out[i]) }
            out = keep
            Self.reaches[key] = out
            return out
        }
        var stand: Standing { Standing(pivot: pivot) }
    }

    /// The turn now: the finger's while it turns it, else where it was left.
    private func turn(_ s: PaperState, _ S: Scene) -> (Double, Double) {
        if s.grabbed, (s.h("turn") ?? 0) != 0 { return (s.h("yaw") ?? 0, s.h("pitch") ?? 0) }
        return (s.run.kept["yaw"] ?? S.P.yaw0, s.run.kept["pitch"] ?? 0)
    }
    /// What faces the child at this turn: faces, edges (either face seen), corners (any face seen).
    private func seen(_ S: Scene, _ p: [Vec3]) -> (f: [Bool], e: [Bool], v: [Bool]) {
        var c = Vec3(0, 0, 0)
        for q in p { c = c + q * (1 / Double(p.count)) }
        let f = S.G.F.map { SK.seen($0.map { p[$0] }, centre: c) }
        let e = S.G.E.map { $0.f.contains { f[$0] } }
        let v = S.G.VF.map { $0.contains { f[$0] } }
        return (f, e, v)
    }
    private static let what = ["faces", "edges", "corners"], keyOf = ["fo", "e", "v"], box = ["f", "e", "v"]
    private func got(_ s: PaperState, _ k: Int, _ i: Int) -> Bool { (s.run.kept["\(Self.keyOf[k])\(i)"] ?? 0) != 0 }
    private func count(_ s: PaperState, _ S: Scene, _ k: Int) -> Int {
        let n = [S.P.faces, S.P.edges, S.P.corners][k]
        return (0..<n).filter { got(s, k, $0) }.count
    }
    static let blockW = [9.0, 14, 9, 14]
    /// The names two by two beside what stands (under it the problem showed at 70%).
    /// Check, on the board beside what stands (the layout's own blocks don't show on it).
    private func checkRect(_ F: (B: CGRect, rec: Double, blocks: Double, side: Double)) -> CGRect { CGRect(x: F.side, y: F.blocks, width: 9, height: 4) }
    private func names(_ F: (B: CGRect, rec: Double, blocks: Double, side: Double)) -> [CGRect] { KS.rects(4, x: F.side, y: F.blocks, w: 15, .grid) }
    /// Where everything it can be turned to shows standing (the board's squares), the record's row and the blocks' row.
    private func frame(_ S: Scene, _ St: Standing) -> (B: CGRect, rec: Double, blocks: Double, side: Double) {
        let key = "\(S.P.solid),\(S.P.turn),\(St.pivot.x),\(St.pivot.y),\(St.eye.map { "\($0.x),\($0.y)" } ?? "")"
        let B = Scene.frames[key] ?? SK.bounds(S.reach.map { St.up($0) })
        Scene.frames[key] = B
        let rec = (B.maxY + 1.5).rounded(.up)
        // beside it: the readout, then Check or the names under it; the record under it
        return (B, rec, (max(0, B.minY) + 3).rounded(.up), EG2.ceil5(B.maxX + 2))
    }
    private func record(_ s: PaperState, _ S: Scene) -> [M7.Tok] {
        let P = S.P, st = at(s), found = max(0, min(3, st - 1))
        let n = [P.faces, P.edges, P.corners], ws = ["faces", "edges", "corners"]
        var out: [M7.Tok] = []
        for k in 0..<found {
            out.append(.n(n[k], .chapter))
            out.append(.w(k + 1 < found ? "\(ws[k]) ·" : st >= 5 && k == 2 ? "\(ws[k]): \(P.S.name)" : ws[k]))
        }
        return out
    }

    func stands(_ s: PaperState) -> CGPoint? { at(s) >= 1 ? Scene(s.numbers).pivot : nil }
    func standHeld(_ s: PaperState) -> (pivot: CGPoint, up: Double)? {
        guard at(s) == 0, s.grabbed else { return nil }
        return (Scene(s.numbers).pivot, s.h("up") ?? 0)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let st = at(s)
        guard st == 5 else { return nil }
        let S = Scene(s.numbers), F = frame(S, s.standing(S.pivot))
        if st == 5 { return CGPoint(x: EG2.ceil5(M7.width(record(s, S)) + 1), y: F.rec - 1) }
        return CGPoint(x: F.side, y: F.blocks)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Scene(s.numbers), P = S.P, st = at(s), St = s.standing(S.pivot)
        var pic = GridPen(), so = Solids()
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st == 0 {
            // flat: the base on the paper; the hand's way, an arrow up beside it
            let base = Scene.base(P, S.G).map { Vec3($0.x + S.C.x, $0.y + S.C.y, 0) }
            so.faces.append(Solids.Face(id: "base", pts: base, look: .top))
            let xs = base.map(\.x), ys = base.map(\.y), ax = (xs.max() ?? 0) + 3, ay = ys.max() ?? 0
            let c: Sketch.Colour = spot ? .chapter : .ink2
            pic.line("tiltA\(spot)", [(ax, ay), (ax, ay - 6)], c)
            pic.line("tiltH\(spot)", [(ax - 0.8, ay - 5.2), (ax, ay - 6), (ax + 0.8, ay - 5.2)], c)
            if ring { KK.hintBox(&pic, "hr", x: (xs.min() ?? 0) - 1, y: (ys.min() ?? 0) - 1, w: (xs.max() ?? 0) - (xs.min() ?? 0) + 2, h: (ys.max() ?? 0) - (ys.min() ?? 0) + 2) }
            let room = CGRect(x: (xs.min() ?? 0) - 1, y: (ys.min() ?? 0) - 1, width: ax - (xs.min() ?? 0) + 3, height: (ys.max() ?? 0) - (ys.min() ?? 0) + 2)
            return PaperDrawing(picture: pic.sketch, extent: pic.R(room.minX, room.minY, room.width, room.height), solids: so)
        }
        let (yaw, pitch) = turn(s, S), p = S.pts(yaw, pitch), vis = seen(S, p), F = frame(S, St)
        func faces(_ q: [Vec3]) -> [Solids.Face] {
            S.G.F.enumerated().map { i, f in Solids.Face(id: "f\(i)", pts: f.map { q[$0] }, look: got(s, 0, i) ? .lit : .auto) }
        }
        so.faces = faces(p)
        // risen: it rises from its base as the paper stands
        if let t0 = s.run.kept["upAt"], PaperClock.now - t0 < Self.rise + 0.3 {
            let base = so
            so.play = Solids.Play(start: t0, length: Self.rise) { t in
                var o = base; o.faces = faces(S.pts(yaw, pitch, up: max(0.02, ease(min(1, (t - t0) / Self.rise))))); return o
            }
        }
        let q = p.map { St.up($0) }
        // hidden edges dashed, over what's in front (as the web draws them)
        for (i, e) in S.G.E.enumerated() where !vis.e[i] {
            let lit = st >= 2 && got(s, 1, i)
            pic.line("he\(i)\(lit)", [(q[e.a].x, q[e.a].y), (q[e.b].x, q[e.b].y)], lit ? .chapter : .ink3, dashed: true)
        }
        if st >= 2 { for (i, e) in S.G.E.enumerated() where vis.e[i] && got(s, 1, i) { pic.line("ve\(i)", [(q[e.a].x, q[e.a].y), (q[e.b].x, q[e.b].y)], .chapter) } }
        // the faces' numbers while they're counted; the corners' dots
        if st == 1 {
            for i in S.G.F.indices where vis.f[i] && got(s, 0, i) {
                var c = CGPoint.zero
                for k in S.G.F[i] { c.x += q[k].x / Double(S.G.F[i].count); c.y += q[k].y / Double(S.G.F[i].count) }
                pic.word("fn\(i)", "\(Int(s.run.kept["fo\(i)"] ?? 0))", at: c.x, c.y, KK.words)
            }
        }
        if st >= 3 { for i in S.G.V.indices where got(s, 2, i) { pic.dot("cn\(i)\(vis.v[i])", at: q[i].x, q[i].y, radius: 0.5, vis.v[i] ? .chapter : .tint(0.35), over: true) } }
        // the readout beside it: what's counted in this step
        if (1...3).contains(st) {
            let k = st - 1, n = count(s, S, k)
            if n > 0 { TMK.readout(&pic, G2.count(n, String(Self.what[k].dropLast())), x: F.side, y: max(0, F.B.minY) + 1); KS.blocks(&pic, "ck", ["Check"], [checkRect(F)]) }
            if ring { let b = SK.bounds(q); KK.hintBox(&pic, "hr", x: b.minX - 1, y: b.minY - 1, w: b.width + 2, h: b.height + 2) }
            if spot, let pt = next(s, S, k, p, vis) { KK.hint(&pic, "spot", pt.x, pt.y, radius: 1.6) }
        }
        if st == 4 {
            let w = s.run.kept["wn"].map { Int($0) }.flatMap { $0 >= 0 ? $0 : nil }
            KS.blocks(&pic, "nm", Solids2.names, names(F), wrong: w, spot: spot ? P.solid : nil, ring: ring)
        }
        if st >= 2 { KS.line(&pic, "rec\(st)", record(s, S), x: 0, line: F.rec) }
        let right = max(F.side + 31, EG2.ceil5(M7.width(record(s, S)) + 1) + 10)
        let bottom = max(F.rec + 1.5, F.blocks + 9)
        return PaperDrawing(picture: pic.sketch, extent: pic.R(F.B.minX - 1, F.B.minY - 0.5, right - F.B.minX + 2, bottom - F.B.minY + 1), solids: so, standing: St)
    }
    private func ease(_ u: Double) -> Double { u < 0.5 ? 2 * u * u : 1 - pow(-2 * u + 2, 2) / 2 }

    /// The next one to count that shows (a second miss rings it), on the board.
    private func next(_ s: PaperState, _ S: Scene, _ k: Int, _ p: [Vec3], _ vis: (f: [Bool], e: [Bool], v: [Bool])) -> CGPoint? {
        let St = s.standing(S.pivot)
        switch k {
        case 0:
            guard let i = S.G.F.indices.first(where: { vis.f[$0] && !got(s, 0, $0) }) else { return nil }
            var c = Vec3(0, 0, 0)
            for j in S.G.F[i] { c = c + p[j] * (1 / Double(S.G.F[i].count)) }
            return St.up(c)
        case 1:
            guard let i = S.G.E.indices.first(where: { vis.e[$0] && !got(s, 1, $0) }) else { return nil }
            return St.up((p[S.G.E[i].a] + p[S.G.E[i].b]) * 0.5)
        default:
            guard let i = S.G.V.indices.first(where: { vis.v[$0] && !got(s, 2, $0) }) else { return nil }
            return St.up(p[i])
        }
    }
    /// What a tap at board point f hits on step k: the index, or nil.
    private func hit(_ S: Scene, _ St: Standing, _ k: Int, _ p: [Vec3], _ vis: (f: [Bool], e: [Bool], v: [Bool]), _ f: CGPoint) -> Int? {
        let q = p.map { St.up($0) }
        switch k {
        case 0: return S.G.F.indices.last { vis.f[$0] && KS.inside((f.x, f.y), S.G.F[$0].map { (q[$0].x, q[$0].y) }) }
        case 1:
            var best: (Int, Double)?
            for (i, e) in S.G.E.enumerated() where vis.e[i] {
                let d = KS.segDist((f.x, f.y), (q[e.a].x, q[e.a].y), (q[e.b].x, q[e.b].y))
                if d < 0.9 && d < (best?.1 ?? 9) { best = (i, d) }
            }
            return best?.0
        default:
            var best: (Int, Double)?
            for i in S.G.V.indices where vis.v[i] { let d = hypot(q[i].x - f.x, q[i].y - f.y); if d < 1.4 && d < (best?.1 ?? 9) { best = (i, d) } }
            return best?.0
        }
    }
    /// A Check's code (Solids2.Parts.countMiss), or the count when every one is counted.
    private func checkCode(_ s: PaperState, _ S: Scene, _ k: Int, _ vis: (f: [Bool], e: [Bool], v: [Bool]), pitch: Double, also: Set<Int> = []) -> Int {
        let all = [S.P.faces, S.P.edges, S.P.corners][k]
        func has(_ i: Int) -> Bool { also.contains(i) || got(s, k, i) }
        let n = (0..<all).filter(has).count
        if n == all { return n }
        let v = [vis.f, vis.e, vis.v][k], seenN = v.filter { $0 }.count
        let missSeen = v.indices.filter { v[$0] && !has($0) }.count
        if missSeen > 0 { return -(100 + missSeen) }
        if k == 0 { return n == seenN && pitch == 0 ? -(200 + seenN) : -(300 + all - n) }
        if k == 1 { return -4 }
        return all - n == 1 ? -5 : -4
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Scene(s.numbers), P = S.P, St = s.standing(S.pivot), st = at(s)
        func board(_ q: CGPoint) -> CGPoint { St.up(q.x, q.y, 0) }
        switch st {
        case 0:
            return Hands(grab: { q in ["grab": 1, "y0": q.y, "up": 0] },
                         drag: { q, h in var h = h; h["up"] = max(0, min(1, ((h["y0"] ?? q.y) - q.y) / 12)); return h },
                         release: { h in
                             (h["up"] ?? 0) >= 0.35 ? HandMove(hand: [:], set: [("t", 1)], keep: ["upAt": PaperClock.now], check: true)
                                 : HandMove(hand: [:], missHand: [:], set: [("t", 0)], check: true)
                         })
        case 1, 2, 3:
            let k = st - 1, (yaw, pitch) = turn(s, S), p = S.pts(yaw, pitch), vis = seen(S, p)
            let code = checkCode(s, S, k, vis, pitch: pitch)
            return Hands(
                tap: { q in
                    if KS.hit(board(q), [checkRect(frame(S, St))]) != nil, count(s, S, k) > 0 { return HandMove(hand: nil, missHand: nil, set: [(Self.box[k], Double(code))], check: true) }
                    guard let i = hit(S, St, k, p, vis, board(q)) else { return nil }
                    if got(s, k, i) { return HandMove(hand: nil, missHand: nil, set: [(Self.box[k], -6)], check: true) }
                    return HandMove(hand: nil, missHand: nil, keep: ["\(Self.keyOf[k])\(i)": k == 0 ? Double(count(s, S, 0) + 1) : 1])
                },
                grab: { q in let b = board(q); return ["grab": 1, "turn": 1, "x0": b.x, "y0": b.y, "yaw": yaw, "pitch": pitch] },
                drag: { q, h in
                    var h = h
                    let b = board(q)
                    h["yaw"] = yaw - (b.x - (h["x0"] ?? b.x)) * 7
                    h["pitch"] = max(-90, min(90, pitch - (b.y - (h["y0"] ?? b.y)) * 7))
                    return h
                },
                release: { h in
                    let y = ((h["yaw"] ?? yaw) / 15).rounded() * 15, pt = ((h["pitch"] ?? pitch) / 15).rounded() * 15
                    return HandMove(hand: [:], keep: ["yaw": y, "pitch": pt])
                })
        case 4:
            let r = names(frame(S, St))
            return Hands(tap: { q in
                guard let j = KS.hit(board(q), r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wn": j == P.solid ? -1 : Double(j)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Scene(s.numbers), P = S.P, St = s.standing(S.pivot), st = at(s)
        func paper(_ b: CGPoint) -> CGPoint { St.down(b) }
        switch st {
        case 0:
            return [.drag(from: CGPoint(x: S.C.x, y: S.C.y), to: CGPoint(x: S.C.x, y: S.C.y - 10))]
        case 1, 2, 3:
            // tap what shows; then turn it (one drag) to where most of the rest shows, and tap those; then Check
            let k = st - 1, all = [P.faces, P.edges, P.corners][k], F = frame(S, St), c = CGPoint(x: F.B.midX, y: F.B.midY)
            var (yaw, pitch) = turn(s, S), done = Set((0..<all).filter { got(s, k, $0) }), moves: [GhostMove] = []
            func showing(_ y: Double, _ p: Double) -> [Int] { let v = seen(S, S.pts(y, p)); return (0..<all).filter { [v.f, v.e, v.v][k][$0] } }
            func spot(_ i: Int, _ y: Double, _ pt: Double) -> CGPoint {
                let p = S.pts(y, pt), q = p.map { St.up($0) }
                switch k {
                case 0: var m = CGPoint.zero; for j in S.G.F[i] { m.x += q[j].x / Double(S.G.F[i].count); m.y += q[j].y / Double(S.G.F[i].count) }; return m
                case 1: let e = S.G.E[i]; return CGPoint(x: (q[e.a].x + q[e.b].x) / 2, y: (q[e.a].y + q[e.b].y) / 2)
                default: return q[i]
                }
            }
            for round in 0..<8 {
                if round > 0 {
                    let turns: [(Double, Double)] = [(0, 90), (0, -90), (180, 0), (90, 0), (-90, 0), (45, 0), (0, 45), (0, -45), (45, 45), (0, 180), (0, -180)]
                    var best: (Double, Double, Int)?
                    for t in turns {
                        let np = max(-90, min(90, pitch + t.1)), n = showing(yaw + t.0, np).filter { !done.contains($0) }.count
                        if n > (best?.2 ?? 0) { best = (t.0, np - pitch, n) }
                    }
                    guard let b = best else { break }
                    moves.append(.drag(from: paper(c), to: paper(CGPoint(x: c.x - b.0 / 7, y: c.y - b.1 / 7))))
                    yaw += b.0; pitch += b.1
                }
                // only a tap that lands on that one (an edge seen end on, say, waits for another turn)
                let p = S.pts(yaw, pitch), v = seen(S, p)
                for i in showing(yaw, pitch) where !done.contains(i) {
                    let at = spot(i, yaw, pitch)
                    if hit(S, St, k, p, v, at) == i { moves.append(.tap(.picture(paper(at)))); done.insert(i) }
                }
                if done.count == all { break }
            }
            let ck = checkRect(F)
            moves.append(.tap(.picture(paper(CGPoint(x: ck.midX, y: ck.midY)))))
            return moves
        case 4:
            let r = names(frame(S, St))[P.solid]
            return [.tap(.picture(paper(CGPoint(x: r.midX, y: r.midY))))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let S = Scene(s.numbers), P = S.P, st = at(s)
        switch st {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("t", 0)], check: true)
        case 1, 2, 3:
            let k = st - 1, (yaw, pitch) = turn(s, S), p = S.pts(yaw, pitch), vis = seen(S, p)
            let v = [vis.f, vis.e, vis.v][k]
            var keep: Numbers = [:], m = 0, also: Set<Int> = []
            for i in v.indices where v[i] { m += 1; keep["\(Self.keyOf[k])\(i)"] = k == 0 ? Double(m) : 1; also.insert(i) }
            return HandMove(hand: nil, missHand: nil, set: [(Self.box[k], Double(checkCode(s, S, k, vis, pitch: pitch, also: also)))], keep: keep, check: true)
        case 4:
            let j = [1, 0, 3, 2][P.solid]
            return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wn": Double(j)], check: true)
        default: return nil
        }
    }
}
