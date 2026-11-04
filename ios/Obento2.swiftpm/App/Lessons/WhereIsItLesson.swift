import SwiftUI

/// Where is it? on the paper, as in the preview (design/prototype/gradeK-ch2.html, lPosition), with the shared 3D
/// (PaperStand.swift). A floor of 10 × 6 floor squares (three squares each) outlined on the paper; on it 2–4 solids (a
/// cube, a sphere, a cone, a cylinder), each on 2 × 2, and from the 7th problem a table (a slab 4 × 2 on legs 2 high). The
/// words are read on the flat paper, then it tilts by itself: in front of and behind are depth.
///
/// Put it: drag the thing across the floor; it moves block by block, up onto a flat top (a cube's, a standing cylinder's,
/// the table's: a sphere's or cone's won't hold it, it slides off), or under the table. While it's held the bar says
/// where it is from the other one, in the instruction's words ("behind the cube"). Let go where the words asked: right;
/// elsewhere it slides back home. Find it: tap the one the words name. Done, the record says it under the floor.
///
/// Kept: "mx", "my", "mon" the thing's place once put; "back" when one slid back and "bx", "by", "bon" where it was let go;
/// "wrongTap" the one tapped wrong. Hand: "grab", "dx", "dy" (where it's held), "x", "y", "on" (its place now).
@MainActor
struct WhereIsItLesson: PaperLesson {
    typealias Thing = WhereIsIt.Thing
    var solid: Bool { true }
    var liveKeys: Set<String> { ["x", "y", "on", "dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Squares a floor square: three (the design's block, five, stood the floor up at 44%), so every corner is still on the grid.
    static let U = 3.0, S = 2 * U, legs = 2 * U, tableTop = 2 * U + 1.2, slide = 0.45

    @MainActor struct Scene {
        let P: WhereIsIt.Parts
        var pivot = CGPoint.zero
        static var cache: [String: CGPoint] = [:]
        init(_ n: Numbers) {
            P = WhereIsIt.Parts(n)
            let key = n.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()
            if let p = Scene.cache[key] { pivot = p; return }
            let all = reach, c = SK.bounds(all.map { CGPoint(x: $0.x, y: $0.y) })
            pivot = Standing.pivot(showing: all, at: CGPoint(x: 0, y: 0), from: CGPoint(x: c.midX, y: c.midY))
            Scene.cache[key] = pivot
        }
        /// What a thing sits on is this high.
        func height(_ id: Int) -> Double { id == WhereIsIt.table ? WhereIsItLesson.tableTop : id >= 0 ? WhereIsItLesson.S : 0 }
        /// A solid's shape where it stands (its back-left block, what it's on).
        func shape(_ kind: Int, x: Double, y: Double, z: Double) -> SK.Shape {
            let S = WhereIsItLesson.S, U = WhereIsItLesson.U, c = Vec3(x * U + S / 2, y * U + S / 2, z)
            switch kind {
            case 0: return SK.box(S, S, S).posed(SK.I, c)
            case 1: return SK.sphere(S / 2).posed(SK.I, c + Vec3(0, 0, S / 2))
            case 2: return SK.cone(S / 2, S).posed(SK.I, c)
            default: return SK.cylinder(S / 2, S).posed(SK.I, c)
            }
        }
        /// The table: its slab and four legs.
        func table(_ t: Thing) -> [SK.Shape] {
            let U = WhereIsItLesson.U, L = WhereIsItLesson.legs, x0 = Double(t.bx) * U, y0 = Double(t.by) * U
            var out = [SK.box(4 * U, 2 * U, WhereIsItLesson.tableTop - L).posed(SK.I, Vec3(x0 + 2 * U, y0 + U, L))]
            for (lx, ly) in [(0.3, 0.3), (4 * U - 1.2, 0.3), (0.3, 2 * U - 1.2), (4 * U - 1.2, 2 * U - 1.2)] { out.append(SK.box(0.9, 0.9, L).posed(SK.I, Vec3(x0 + lx + 0.45, y0 + ly + 0.45, 0))) }
            return out
        }
        /// Everything that can be seen: the floor and every thing (one put up on a top may rise past it a moment).
        var reach: [Vec3] {
            let W = 10 * WhereIsItLesson.U, D = 6 * WhereIsItLesson.U
            var pts = [Vec3(0, 0, 0), Vec3(W, 0, 0), Vec3(0, D, 0), Vec3(W, D, 0)]
            for t in P.things { pts += shape(t.kind, x: Double(t.bx), y: Double(t.by), z: height(t.on)).points }
            if let t = P.table { pts += table(t).flatMap(\.points) }
            return pts
        }
    }

    func stands(_ s: PaperState) -> CGPoint? { Scene(s.numbers).pivot }
    func standDelay(_ s: PaperState) -> Double { 0.9 }

    /// The thing to move, where it is now (held, put, or as it started).
    private func moverAt(_ s: PaperState, _ P: WhereIsIt.Parts) -> Thing {
        var m = P.things[P.who]
        if s.grabbed, let x = s.h("x"), let y = s.h("y") { m.bx = Int(x); m.by = Int(y); m.on = Int(s.h("on") ?? -1); return m }
        if let x = s.run.kept["mx"], let y = s.run.kept["my"] { m.bx = Int(x); m.by = Int(y); m.on = Int(s.run.kept["mon"] ?? -1) }
        return m
    }
    private func things(_ s: PaperState, _ P: WhereIsIt.Parts) -> [Thing] {
        var t = P.things
        if P.put { t[P.who] = moverAt(s, P) }
        return t
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let Sc = Scene(s.numbers), P = Sc.P, st = at(s), St = s.standing(Sc.pivot)
        var pic = GridPen(), live = GridPen(stableIds: true), so = Solids()
        let W = 10 * Self.U, D = 6 * Self.U
        so.lines.append(Solids.Line(id: "floor", pts: [Vec3(0, 0, 0.02), Vec3(W, 0, 0.02), Vec3(W, D, 0.02), Vec3(0, D, 0.02), Vec3(0, 0, 0.02)], colour: .ink))
        if let t = P.table { for (k, part) in Sc.table(t).enumerated() { so.bodies.append(part.body("tab\(k)")) } }
        let all = things(s, P), who = P.put ? P.who : (st == 1 ? P.who : -1)
        let wrong = st == 0 ? Int(s.run.kept["wrongTap"] ?? -1) : -1
        for (j, t) in all.enumerated() {
            let tone: Solids.Tone = j == wrong ? .red : (st == 1 && j == who) ? .lit : .auto
            so.bodies.append(Sc.shape(t.kind, x: Double(t.bx), y: Double(t.by), z: Sc.height(t.on)).body("t\(j)", tone: tone))
        }
        // one let go in the wrong place slides back home
        if st == 0, P.put, !s.grabbed, let t0 = s.run.kept["back"], PaperClock.now - t0 < Self.slide + 0.2 {
            let from = Vec3(s.run.kept["bx"] ?? 0, s.run.kept["by"] ?? 0, Sc.height(Int(s.run.kept["bon"] ?? -1))), home = moverAt(s, P)
            let to = Vec3(Double(home.bx), Double(home.by), Sc.height(home.on)), base = so, j = P.who, kind = P.things[P.who].kind
            so.play = Solids.Play(start: t0, length: Self.slide) { t in
                let u = ease(min(1, (t - t0) / WhereIsItLesson.slide)), p = from + (to - from) * u
                var o = base
                if let i = o.bodies.firstIndex(where: { $0.id == "t\(j)" }) { o.bodies[i] = Sc.shape(kind, x: p.x, y: p.y, z: p.z).body("t\(j)") }
                return o
            }
        }
        if st == 0 && P.put && s.grabbed, let r = P.relation(of: moverAt(s, P)) { live.reads("\(WhereIsIt.say(r, asked: P.word)) the \(P.refName)") }
        // hints: the one it goes by ringed; a second miss, the place (or the one to tap)
        func box(_ t: Thing) -> CGRect { SK.bounds((t.isTable ? Sc.table(t).flatMap(\.points) : Sc.shape(t.kind, x: Double(t.bx), y: Double(t.by), z: Sc.height(t.on)).points).map { St.up($0) }) }
        if st == 0 {
            if s.on("ring"), !s.on("spot") { let b = box(P.refThing); KK.hintBox(&pic, "hr", x: b.minX, y: b.minY, w: b.width, h: b.height) }
            if s.on("spot") {
                if P.put, let g = P.target {
                    let z = Sc.height(g.on) + 0.05, x0 = Double(g.bx) * Self.U, y0 = Double(g.by) * Self.U, e = Self.S
                    // on the board, so what stands in front of the place never hides it
                    KS.outline(&pic, "spot", [Vec3(x0, y0, z), Vec3(x0 + e, y0, z), Vec3(x0 + e, y0 + e, z), Vec3(x0, y0 + e, z)].map { let p = St.up($0); return (Double(p.x), Double(p.y)) }, .chapter, dashed: true)
                } else { let b = box(P.things[P.who]); KK.hintBox(&pic, "spot", x: b.minX, y: b.minY, w: b.width, h: b.height) }
            }
        }
        let floor = SK.bounds(Sc.reach.map { St.up($0) })
        if st == 1 {
            let name = P.things[P.who].name
            let r = recordAt(floor)
            KS.line(&pic, "rec", [.w("The \(name) is"), .w(P.word, .chapter), .w("the \(P.refName).")], x: r.x, line: r.y + 1)
        }
        // the record beside the floor (there's room across, not down)
        let w = M7.width([.w("The \(P.things[P.who].name) is"), .w(P.word), .w("the \(P.refName).")])
        let room = (st == 1 ? floor.union(CGRect(x: recordAt(floor).x, y: recordAt(floor).y, width: w, height: 6)) : floor).insetBy(dx: -1, dy: -1)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(room.minX, room.minY, room.width, room.height), solids: so, standing: St)
    }
    /// The record's corner: right of the floor, a third of the way down it, on the grid's block lines.
    private func recordAt(_ floor: CGRect) -> CGPoint { CGPoint(x: ((floor.maxX + 3) / 5).rounded(.up) * 5, y: ((floor.minY + floor.height / 3) / 5).rounded() * 5) }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        guard at(s) == 1 else { return nil }
        let Sc = Scene(s.numbers), St = s.standing(Sc.pivot), r = recordAt(SK.bounds(Sc.reach.map { St.up($0) }))
        return CGPoint(x: r.x, y: r.y + 4)
    }

    /// Where the thing goes for a finger at paper point q (its board point f), held `dx`, `dy` from its corner: the floor
    /// block its footprint is over now; right over a thing, up on its top; over the table, on it when the finger is on its
    /// top, else under it. Half over something else: nowhere (it stays where it was).
    private func place(_ s: PaperState, _ Sc: Scene, _ St: Standing, q: CGPoint, dx: Double, dy: Double, mover: Thing) -> Thing? {
        let P = Sc.P, all = things(s, P), f = St.up(q.x, q.y, 0)
        let bx = max(0, min(8, Int(((q.x + dx) / Self.U).rounded()))), by = max(0, min(4, Int(((q.y + dy) / Self.U).rounded())))
        func over(_ a: (x: Int, y: Int, w: Int, h: Int), _ b: (x: Int, y: Int, w: Int, h: Int)) -> Bool { a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h }
        let spot = (x: bx, y: by, w: 2, h: 2)
        func busy(_ id: Int, _ x: Int) -> Bool { all.indices.contains { $0 != P.who && all[$0].on == id && (id != WhereIsIt.table || all[$0].bx == x) } }
        var m = mover
        for (j, o) in all.enumerated() where j != P.who && o.on < 0 && over(spot, o.foot) {
            guard o.bx == bx && o.by == by && !busy(j, bx) else { return nil }
            m.bx = bx; m.by = by; m.on = j; return m
        }
        if let t = P.table, over(spot, t.foot) {
            let x = max(t.bx, min(t.bx + 2, bx)), x0 = Double(x) * Self.U, y0 = Double(t.by) * Self.U, e = Self.S
            let top = [(x0, y0), (x0 + e, y0), (x0 + e, y0 + e), (x0, y0 + e)].map { St.up($0.0, $0.1, Self.tableTop) }.map { (Double($0.x), Double($0.y)) }
            if KS.inside((f.x, f.y), top) || (mover.on == WhereIsIt.table && q.y < y0 + e) {
                if busy(WhereIsIt.table, x) { return nil }
                m.bx = x; m.by = t.by; m.on = WhereIsIt.table; return m
            }
        }
        m.bx = bx; m.by = by; m.on = -1
        return m
    }

    func hands(_ s: PaperState) -> Hands? {
        let Sc = Scene(s.numbers), P = Sc.P, St = s.standing(Sc.pivot)
        guard at(s) == 0 else { return nil }
        func hull(_ t: Thing) -> [KS.Pt] { SK.hull(Sc.shape(t.kind, x: Double(t.bx), y: Double(t.by), z: Sc.height(t.on)).points.map { St.up($0) }) }
        if P.put {
            let home = moverAt(s, P)
            return Hands(
                grab: { q in
                    let f = St.up(q.x, q.y, 0)
                    guard KS.inside((f.x, f.y), hull(home)) else { return nil }
                    return ["grab": 1, "dx": Double(home.bx) * Self.U - q.x, "dy": Double(home.by) * Self.U - q.y, "x": Double(home.bx), "y": Double(home.by), "on": Double(home.on)]
                },
                drag: { q, h in
                    var h = h, m = home
                    m.bx = Int(h["x"] ?? 0); m.by = Int(h["y"] ?? 0); m.on = Int(h["on"] ?? -1)
                    if let p = place(s, Sc, St, q: q, dx: h["dx"] ?? 0, dy: h["dy"] ?? 0, mover: m) { h["x"] = Double(p.bx); h["y"] = Double(p.by); h["on"] = Double(p.on) }
                    return h
                },
                release: { h in
                    var m = home
                    m.bx = Int(h["x"] ?? 0); m.by = Int(h["y"] ?? 0); m.on = Int(h["on"] ?? -1)
                    let back: Numbers = ["back": PaperClock.now, "bx": Double(m.bx), "by": Double(m.by), "bon": Double(m.on)]
                    if m.on >= 0, m.on != WhereIsIt.table, !P.things[m.on].flatTop { return HandMove(hand: [:], missHand: [:], set: [("p", 8)], keep: back, check: true) }
                    let r = P.relation(of: m)
                    if WhereIsIt.same(r, P.word) {
                        return HandMove(hand: [:], missHand: [:], set: [("p", Double(WhereIsIt.code(r)))], keep: ["mx": Double(m.bx), "my": Double(m.by), "mon": Double(m.on)], check: true)
                    }
                    if m == home { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], missHand: [:], set: [("p", Double(WhereIsIt.code(r)))], keep: back, check: true)
                })
        }
        return Hands(tap: { q in
            let f = St.up(q.x, q.y, 0), eye = SK.eye
            // the nearest one under the finger
            let hits = P.things.indices.filter { KS.inside((f.x, f.y), hull(P.things[$0])) }
            guard let j = hits.max(by: { a, b in
                let ca = Sc.shape(P.things[a].kind, x: Double(P.things[a].bx), y: Double(P.things[a].by), z: Sc.height(P.things[a].on)).points
                let cb = Sc.shape(P.things[b].kind, x: Double(P.things[b].bx), y: Double(P.things[b].by), z: Sc.height(P.things[b].on)).points
                return (ca.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(ca.count))).dot(eye) < (cb.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(cb.count))).dot(eye)
            }) else { return nil }
            return HandMove(hand: nil, missHand: nil, set: [("f", Double(j))], keep: ["wrongTap": j == P.who ? -1 : Double(j)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let Sc = Scene(s.numbers), P = Sc.P, St = s.standing(Sc.pivot)
        guard at(s) == 0 else { return [] }
        func centre(_ t: Thing) -> CGPoint {
            let b = SK.bounds(Sc.shape(t.kind, x: Double(t.bx), y: Double(t.by), z: Sc.height(t.on)).points.map { St.up($0) })
            return St.down(CGPoint(x: b.midX, y: b.midY))
        }
        if P.put, let g = P.target {
            let home = moverAt(s, P), from = centre(home)
            // the finger keeps its hold on the thing: it ends as far from the place's corner as it started from the thing's
            let to = CGPoint(x: from.x + Double(g.bx - home.bx) * Self.U, y: from.y + Double(g.by - home.by) * Self.U)
            return [.drag(from: from, to: to)]
        }
        return [.tap(.picture(centre(P.things[P.who])))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let Sc = Scene(s.numbers), P = Sc.P
        guard at(s) == 0 else { return nil }
        if P.put {
            // let go beside instead of behind (or behind instead of beside)
            let r = P.refThing, wrongWord = P.word == "behind" || P.word == "in front of" || P.word == "above" || P.word == "below" ? "beside" : "in front of"
            let code = Double(WhereIsIt.code(wrongWord))
            return HandMove(hand: [:], missHand: [:], set: [("p", code)], keep: ["back": PaperClock.now, "bx": Double(max(0, min(8, r.bx + 2))), "by": Double(r.by), "bon": -1], check: true)
        }
        let j = P.things.indices.first { $0 != P.who && $0 != P.ref } ?? P.ref
        return HandMove(hand: nil, missHand: nil, set: [("f", Double(j))], keep: ["wrongTap": Double(j)], check: true)
    }
}
