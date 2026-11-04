import SwiftUI

/// Nets and surface area on the paper, as in the preview (design/prototype/grade6-ch7.html, dNets), with the shared 3D
/// (PaperStand.swift): the net flat from the picture's top, its faces in the cubes' colours, its outer sides named, a
/// triangle's height dashed. Drag a face toward the middle and the paper stands up (Unit cubes' view, the long lens) as
/// the face turns up about its fold line in true 3D, following the finger ("5 of 6 faces"); let go past halfway it folds
/// on up on the spring, short of it it falls back. The last face closes it; it stays closed a moment, then opens as the
/// paper lies flat. Tap each face: it fills and its area is written in it (faces the same size light together after the
/// first), the running total under the net; then `SA = 2 × 20 + 2 × 15 + 2 × 12 = [94] square units` (a cube's 6 × 4²).
///
/// Units are `U` squares (the biggest, 5 down to 2, that shows the flat net and its record, and the folded solid, at 75%).
/// Hand keys: "u<i>" (face i folded), "grab", "g" (the face held), "x0", "y0", "dx", "dy" (where it was taken and the way
/// to its fold line, in the board's squares), "a" (how far it's turned, 0–1); "l<i>" a face lit, "o<k>" the areas in the
/// order they lit (kept for the record).
@MainActor
struct NetsLesson: PaperLesson {
    var liveKeys: Set<String> { ["a", "grab"] }
    var solid: Bool { true }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct Shape {
        let N: Nets6.Net
        let U: Double
        /// Worked out once a net: its unit, and the pivot that shows it standing.
        static var cache: [String: (U: Double, pivot: CGPoint)] = [:]
        init(_ n: Numbers) {
            let N = Nets6.net(n), key = n.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()
            self.N = N
            if let c = Shape.cache[key] { U = c.U; pivot = c.pivot; return }
            var pick = 2.0
            let recW = M7.width(Shape.recordToks(N, nil)) + 1
            for u in [5.0, 4, 3, 2] {
                let corner = Shape.corner(N, u), beside = Shape(N: N, U: u, pivot: .zero).beside
                let w = Shape.splits(N, u) ? { let (a, b) = Shape.split(N, nil); return max(M7.width(a), M7.width(b) + 8) + 1 }() : recW
                let flat = beside ? ProblemGrid.zoom(squares: max((corner ?? ((N.width * u + 3) / 5).rounded(.up) * 5) + w, N.width * u, 44), 6 + max(N.height * u + 3, 9))
                    : ProblemGrid.zoom(squares: max(N.width * u, 44), 6 + N.height * u + 3 + 2 + 4)
                let b = Shape.standingBounds(N, u)
                let up = ProblemGrid.zoom(squares: max(b.width + 14, 44), 6 + b.height + 6)
                if min(flat, up) >= 0.79 { pick = u; break }
            }
            U = pick
            pivot = Shape(N: N, U: pick, pivot: .zero).pivotNow
            Shape.cache[key] = (U, pivot)
        }
        let pivot: CGPoint
        var nF: Int { N.faces.count }
        func face(_ i: Int) -> Nets6.Face { N.faces[i] }
        func index(_ id: String?) -> Int? { id.flatMap { p in N.faces.firstIndex { $0.id == p } } }
        func sq(_ f: Nets6.Face) -> [CGPoint] { f.pts.map { CGPoint(x: $0.0 * U, y: $0.1 * U) } }
        /// The faces as solids, each turned to `angle(i)` degrees.
        func solids(_ angle: (Int) -> Double, look: (Int) -> Solids.Look = { _ in .auto }, live: Int? = nil, delay: Double = 0) -> Solids {
            var so = Solids()
            for (i, f) in N.faces.enumerated() {
                let h = f.hinge
                so.faces.append(Solids.Face(id: f.id, pts: f.pts.map { Vec3($0.0 * U, $0.1 * U, 0) }, look: look(i), parent: f.parent,
                                            hinge: f.parent == nil ? nil : (Vec3(h.0.0 * U, h.0.1 * U, 0), Vec3(h.1.0 * U, h.1.1 * U, 0)),
                                            angle: angle(i), live: live == i, delay: delay))
            }
            return so
        }
        static func standingBounds(_ N: Nets6.Net, _ U: Double) -> CGRect {
            let s = Shape(N: N, U: U, pivot: .zero), p = s.pivotNow
            return Standing(pivot: p).bounds(s.allPoints) ?? .zero
        }
        private init(N: Nets6.Net, U: Double, pivot: CGPoint) { self.N = N; self.U = U; self.pivot = pivot }
        /// Every corner the faces reach as they fold: flat, all folded, the sides folded with what hangs on them still flat.
        var allPoints: [Vec3] {
            let flat = solids { _ in 0 }.points, up = solids { face($0).turn }.points
            let half = solids { i in face(i).parent == "base" ? face(i).turn : 0 }.points
            return flat + up + half
        }
        var stand: Standing { Standing(pivot: pivot) }
        /// The paper turns about the point that shows all of it under the words.
        var pivotNow: CGPoint {
            let base = N.faces[0].pts, c = CGPoint(x: base.map(\.0).reduce(0, +) / Double(base.count) * U, y: base.map(\.1).reduce(0, +) / Double(base.count) * U)
            return Standing.pivot(showing: allPoints, at: CGPoint(x: 0, y: 0), from: c)
        }
        /// The record beside the net when that shows it at 75% (a tall net), else under it.
        var beside: Bool {
            if Shape.corner(N, U) != nil { return true }
            let w = M7.width(Shape.recordToks(N, nil)) + 1, x = ((N.width * U + 3) / 5).rounded(.up) * 5
            // beside the net only when that shows it bigger than under it
            let side = ProblemGrid.zoom(squares: x + w + 2, 6 + max(N.height * U + 3, 9))
            let under = ProblemGrid.zoom(squares: max(N.width * U, w) + 2, 6 + N.height * U + 3 + 2 + 4)
            return side > under
        }
        var record: Double { beside ? 0 : N.height * U + 3 }
        var rx: Double { Shape.corner(N, U) ?? (beside ? ((N.width * U + 3) / 5).rounded(.up) * 5 : 0) }
        /// The record's column when it fits in the corner right of the net's top face, over the rest of the net (the
        /// net's shape leaves that room): nil when it doesn't.
        static func corner(_ N: Nets6.Net, _ U: Double) -> Double? {
            guard let top = N.faces.first(where: { f in f.pts.contains { $0.1 == 0 } }) else { return nil }
            let right = top.pts.map(\.0).max() ?? 0, below = N.faces.filter { $0.id != top.id }.flatMap(\.pts).filter { $0.0 > right + 1e-6 }.map(\.1).min() ?? N.height
            let x = ((right * U + 2) / 5).rounded(.up) * 5
            let w = M7.width(recordToks(N, nil)) + 1
            if below * U >= 5.5 && x + w <= 71 { return x }
            // on two lines there: SA = … then = [ ] square units, Check beside the second
            let (a, b) = split(N, nil)
            return below * U >= 6.5 && x + max(M7.width(a), M7.width(b) + 8) + 1 <= 71 ? x : nil
        }
        /// Whether the corner's record goes on two lines.
        static func splits(_ N: Nets6.Net, _ U: Double) -> Bool {
            guard let x = corner(N, U) else { return false }
            return x + M7.width(recordToks(N, nil)) + 1 > 71
        }
        static func split(_ N: Nets6.Net, _ x: M7.Tok?) -> ([M7.Tok], [M7.Tok]) {
            let all = recordToks(N, x)
            return (Array(all.dropLast(3)), Array(all.suffix(3)))
        }
        /// SA = 2 × 20 + 2 × 15 + 2 × 12 = [ ] square units (a box while it's typed, else the answer).
        static func recordToks(_ N: Nets6.Net, _ x: M7.Tok?) -> [M7.Tok] {
            var toks: [M7.Tok] = [.t("SA"), .op("=")]
            for m in N.terms {
                switch m { case .num(let v): toks.append(.n(Int(v))); case .op(let o): toks.append(.op(o)); case .text(let t): toks.append(.t(t)); default: break }
            }
            return toks + [.op("="), x ?? .box("x", cells: max(2, "\(N.SA)".count)), .w("square units")]
        }
    }

    func recordRow(_ n: Numbers) -> Double? { Shape(n).record }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers)
        guard S.beside, stage(s) >= 3 else { return nil }
        return Shape.splits(S.N, S.U) ? CGPoint(x: S.rx + M7.width(Shape.split(S.N, nil).1) + 1, y: 3) : CGPoint(x: S.rx, y: 3)
    }

    /// The fold step stands once a face has been taken hold of.
    func stands(_ s: PaperState) -> CGPoint? {
        guard stage(s) == 1 else { return nil }
        let S = Shape(s.numbers)
        let any = s.grabbed || (0..<S.nF).contains { (s.h("u\($0)") ?? 0) != 0 }
        return any ? S.stand.pivot : nil
    }
    /// Closed, the box stays up a moment before it opens and the paper lies flat.
    func lingers(_ s: PaperState) -> Double { stage(s) == 2 ? 1.2 : 0 }

    private func folded(_ s: PaperState, _ i: Int) -> Bool { (s.h("u\(i)") ?? 0) != 0 }
    private func lit(_ s: PaperState, _ i: Int) -> Bool { (s.h("l\(i)") ?? s.run.kept["l\(i)"] ?? 0) != 0 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), N = S.N, at = stage(s), U = S.U
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        var solids = Solids(), standing: Standing?
        if at <= 1 {
            let held = s.grabbed ? s.h("g").map { Int($0) } : nil, a = s.h("a") ?? 0
            solids = S.solids({ i in held == i ? S.face(i).turn * a : folded(s, i) ? S.face(i).turn : 0 }, live: held)
            if stands(s) != nil {
                let St = s.standing(S.pivot)
                standing = St
                // how many faces are up, beside what stands
                let n = 1 + (0..<S.nF).filter { folded(s, $0) }.count
                if s.grabbed || n > 1, let b = St.bounds(solids.points) {
                    live.word("rd", "\(n) of \(S.nF) faces", at: b.maxX + 1.5, b.midY, A7.lit, anchor: UnitPoint(x: 0, y: 0.5))
                    if s.grabbed { live.reads("\(n) of \(S.nF) faces") }
                }
                if at == 1 && s.on("ring"), let b = St.bounds(solids.points) { A7.ring(&pic, "ring", x: b.minX, y: b.minY, w: b.width, h: b.height) }
            } else {
                labels(&pic, S, lit: [])
                if at == 1 && s.on("ring") { A7.ring(&pic, "ring", x: 0, y: 0, w: N.width * U, h: N.height * U) }
            }
            if at == 1 && s.on("spot") {
                // the next face to fold: its fold line, dashed
                if let i = (1..<S.nF).first(where: { !folded(s, $0) && (S.face($0).parent == "base" || S.index(S.face($0).parent).map { folded(s, $0) } == true) }) {
                    let h = S.face(i).hinge, dx = h.1.0 - h.0.0, dy = h.1.1 - h.0.1
                    let len = S.face(i).n.0 != 0 ? Double(S.face(i).h) : Double(S.face(i).w)
                    let a0 = CGPoint(x: h.0.0 * U, y: h.0.1 * U), b0 = CGPoint(x: (h.0.0 + dx * len) * U, y: (h.0.1 + dy * len) * U)
                    let p0 = standing.map { $0.up(a0.x, a0.y, 0) } ?? a0, p1 = standing.map { $0.up(b0.x, b0.y, 0) } ?? b0
                    pic.line("spot", [(p0.x, p0.y), (p1.x, p1.y)], .chapter, dashed: true)
                }
            }
        } else {
            // flat again: the box opens (after it's stood closed a moment), the faces lit as they're tapped
            let litNow = (0..<S.nF).filter { lit(s, $0) }
            solids = S.solids({ _ in 0 }, look: { litNow.contains($0) ? .paint(A7.strong) : .auto }, delay: at == 2 ? 1.2 : 0)
            labels(&pic, S, lit: Set(litNow))
            // the running total under the net
            let order = (0..<Int(s.h("no") ?? s.run.kept["no"] ?? 0)).map { Int(s.h("o\($0)") ?? s.run.kept["o\($0)"] ?? 0) }
            if !order.isEmpty && at == 2 {
                pic.word("tot\(order.count)", "\(order.map(String.init).joined(separator: " + ")) = \(order.reduce(0, +))", at: 0, N.height * U + 1.4, A7.lit, anchor: UnitPoint(x: 0, y: 0.5))
            }
            if at == 2 && s.on("ring") { A7.ring(&pic, "ring", x: 0, y: 0, w: N.width * U, h: N.height * U) }
            if at == 2 && s.on("spot"), let i = (0..<S.nF).first(where: { !litNow.contains($0) }) {
                let c = A7.centroid(S.sq(S.face(i))); pic.circle("spot", at: c.x, c.y, radius: 1.4, .chapter, dashed: true)
            }
        }
        if at >= 3 {
            let x: M7.Tok = at == 3 ? .box("x", cells: max(2, "\(N.SA)".count)) : .n(N.SA, .chapter)
            if Shape.splits(N, U) {
                let (a, b) = Shape.split(N, x)
                M7.row(&rec, "r", a, x: S.rx, line: 1); M7.row(&rec, "r2", b, x: S.rx, line: 4)
            } else { M7.row(&rec, "r", Shape.recordToks(N, x), x: S.rx, line: 1) }
        }
        // room for the net flat and for it standing (folded, or partway)
        var room = pic.R(-1, -1, N.width * U + 14, N.height * U + 3)
        if at <= 1 { let b = S.stand.bounds(S.allPoints) ?? .zero; room = room.union(pic.R(b.minX, b.minY, b.width + 12, b.height + 1)) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: room, solids: solids, standing: standing)
    }

    /// The flat net's names: its outer sides (tops no other face shares, and its left end), a triangle's height dashed, and
    /// the areas written in the lit faces.
    private func labels(_ pen: inout GridPen, _ S: Shape, lit: Set<Int>) {
        let U = S.U, faces = S.N.faces
        let edges = faces.enumerated().flatMap { j, f in f.pts.indices.map { (j, f.pts[$0], f.pts[($0 + 1) % f.pts.count]) } }
        func same(_ a: (Double, Double), _ b: (Double, Double)) -> Bool { abs(a.0 - b.0) < 1e-4 && abs(a.1 - b.1) < 1e-4 }
        func shared(_ e: (Int, (Double, Double), (Double, Double))) -> Bool {
            edges.contains { o in o.0 != e.0 && ((same(o.1, e.1) && same(o.2, e.2)) || (same(o.1, e.2) && same(o.2, e.1))) }
        }
        var k = 0
        for e in edges where !shared(e) {
            let f = faces[e.0], pts = S.sq(f), (a, b) = (e.1, e.2)
            if a.1 == b.1 && a.0 != b.0, !A7.inside(pts, CGPoint(x: (a.0 + b.0) / 2 * U, y: a.1 * U - 0.05)) {
                pen.label("nl\(k)", fmt(abs(b.0 - a.0)), A7.words, .above, edge: a.1 * U, along: (a.0 + b.0) / 2 * U); k += 1
            }
            if a.0 == b.0 && a.0 == 0 && a.1 != b.1 {
                pen.label("nl\(k)", fmt(abs(b.1 - a.1)), A7.words, .left, edge: 0, along: (a.1 + b.1) / 2 * U); k += 1
            }
        }
        if S.N.kind == .pyramid && !lit.contains(0) {
            let b = faces[0].pts
            pen.label("bs", "\(faces[0].w)", A7.small, .below, edge: b[2].1 * U, along: (b[0].0 + b[1].0) / 2 * U)
        }
        for (j, f) in faces.enumerated() where f.tri && !lit.contains(j) {
            // a triangle's height, dashed from its tip to its base (unless it's a side already)
            let ap = f.pts[2], dd = (ap.0 - f.P.0) * f.n.0 + (ap.1 - f.P.1) * f.n.1, ft = (ap.0 - dd * f.n.0, ap.1 - dd * f.n.1)
            if same(ft, f.pts[0]) || same(ft, f.pts[1]) { continue }
            pen.line("th\(f.id)", [(ap.0 * U, ap.1 * U), (ft.0 * U, ft.1 * U)], .ink2, dashed: true)
            let m = ((ap.0 + ft.0) / 2 * U, (ap.1 + ft.1) / 2 * U)
            if f.n.0 != 0 { pen.label("thl\(f.id)", "\(f.h)", A7.small, .above, edge: m.1 - 0.1, along: m.0) }
            else { pen.label("thl\(f.id)", "\(f.h)", A7.small, .right, edge: m.0 + 0.1, along: m.1) }
        }
        for j in lit.sorted() {
            let f = faces[j], c = A7.centroid(S.sq(f))
            let one = "\(f.w) × \(f.h)\(f.tri ? " ÷ 2" : "") = \(f.A)", room = (f.tri ? Double(f.n.0 != 0 ? f.h : f.w) * 0.6 : Double(f.w)) * U - 0.8
            if R6.width(one, A7.small.colour(.ink)) <= room { pen.word("ar\(f.id)", one, at: c.x, c.y, A7.small.colour(.ink)) }
            else {
                pen.word("ar\(f.id)a", "\(f.w) × \(f.h)\(f.tri ? " ÷ 2" : "")", at: c.x, c.y - 0.6, A7.small.colour(.ink))
                pen.word("ar\(f.id)b", "= \(f.A)", at: c.x, c.y + 0.6, A7.small.colour(.ink))
            }
        }
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), at = stage(s)
        switch at {
        case 1:
            let up = stands(s) != nil, St = s.standing(S.pivot)
            let angles = { (i: Int) -> Double in folded(s, i) ? S.face(i).turn : 0 }
            let now = S.solids(angles)
            /// A face's corners where they show (the board's squares).
            func shown(_ i: Int) -> [CGPoint] {
                let p = now.placed(now.faces[i]) { f in angles(S.index(f.id) ?? 0) }
                return p.map { up ? St.up($0) : CGPoint(x: $0.x, y: $0.y) }
            }
            let base = s.hand.filter { $0.key.hasPrefix("u") }
            return Hands(grab: { q in
                let f = up ? St.up(q.x, q.y, 0) : q
                guard let i = (1..<S.nF).first(where: { !folded(s, $0) && A7.inside(shown($0), f) }) else { return nil }
                // the way to its fold line, as it shows (carried with its parents)
                let fc = S.face(i), h = fc.hinge, len = fc.n.0 != 0 ? Double(fc.h) : Double(fc.w)
                let pts = now.placed(now.faces[i]) { g in angles(S.index(g.id) ?? 0) }
                let c3 = pts.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(pts.count))
                var carry = now.faces[i]
                carry.pts = [Vec3((h.0.0 + (h.1.0 - h.0.0) * len / 2) * S.U, (h.0.1 + (h.1.1 - h.0.1) * len / 2) * S.U, 0)]; carry.hinge = nil
                let hm = now.placed(carry) { g in angles(S.index(g.id) ?? 0) }[0]
                let A = up ? St.up(c3) : CGPoint(x: c3.x, y: c3.y), B = up ? St.up(hm) : CGPoint(x: hm.x, y: hm.y)
                return base.merging(["grab": 1, "g": Double(i), "x0": f.x, "y0": f.y, "dx": B.x - A.x, "dy": B.y - A.y, "a": 0]) { $1 }
            }, drag: { q, hd in
                var hd = hd
                let f = up ? St.up(q.x, q.y, 0) : q, dx = hd["dx"] ?? 1, dy = hd["dy"] ?? 0, dd = max(1e-6, dx * dx + dy * dy)
                let u = ((f.x - (hd["x0"] ?? f.x)) * dx + (f.y - (hd["y0"] ?? f.y)) * dy) / dd
                // a face hanging from one not folded yet doesn't move
                let i = Int(hd["g"] ?? 0), ok = S.face(i).parent == "base" || S.index(S.face(i).parent).map { folded(s, $0) } == true
                hd["a"] = ok ? max(0, min(1, u * 1.15)) : 0
                return hd
            }, release: { hd in
                var out = base
                let i = Int(hd["g"] ?? 0), ok = S.face(i).parent == "base" || S.index(S.face(i).parent).map { folded(s, $0) } == true
                guard ok else { return HandMove(hand: out, missHand: out, set: [("f", -2)], check: true) }
                guard (hd["a"] ?? 0) >= 0.45 else { return HandMove(hand: out, missHand: out, set: [("f", -1)], check: true) }
                out["u\(i)"] = 1
                let n = (1..<S.nF).filter { out["u\($0)"] != nil }.count
                return HandMove(hand: out, missHand: out, set: [("f", Double(n))], check: n == S.nF - 1)
            })
        case 2:
            return Hands(tap: { q in
                guard let i = (0..<S.nF).first(where: { A7.inside(S.sq(S.face($0)), q) }) else {
                    return HandMove(hand: s.hand, missHand: s.hand, set: [("t", -1)], check: true)
                }
                if lit(s, i) { return nil }
                var out = s.hand, keep: Numbers = [:]
                var n = Int(out["no"] ?? 0)
                let add = { (j: Int) in
                    guard out["l\(j)"] == nil else { return }
                    out["l\(j)"] = 1; keep["l\(j)"] = 1; out["o\(n)"] = Double(S.face(j).A); keep["o\(n)"] = Double(S.face(j).A); n += 1
                }
                if n == 0 { add(i) } else { for j in 0..<S.nF where S.face(j).key == S.face(i).key { add(j) } }
                out["no"] = Double(n); keep["no"] = Double(n)
                let all = (0..<S.nF).allSatisfy { out["l\($0)"] != nil }
                return HandMove(hand: out, missHand: out, set: [("t", Double(all ? S.nF : n))], keep: keep, check: all)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), U = S.U
        switch stage(s) {
        case 1:
            // each face dragged over its fold line, parents first: from where it shows to its fold line's middle (once
            // the paper stands, the finger's places on the paper are where those show)
            var moves: [GhostMove] = [], up: Set<Int> = Set((0..<S.nF).filter { folded(s, $0) })
            let St = s.standing(S.pivot)
            for (i, f) in S.N.faces.enumerated() where i > 0 && !up.contains(i) {
                let standing = !up.isEmpty, so = S.solids { up.contains($0) ? S.face($0).turn : 0 }
                let face = so.faces[i], pts = so.placed(face) { g in up.contains(S.index(g.id) ?? 0) ? S.face(S.index(g.id) ?? 0).turn : 0 }
                let c3 = pts.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(pts.count))
                let h = f.hinge, len = f.n.0 != 0 ? Double(f.h) : Double(f.w)
                // the fold line's middle, carried with the face's parents
                let hm0 = Vec3((h.0.0 + (h.1.0 - h.0.0) * len / 2) * U, (h.0.1 + (h.1.1 - h.0.1) * len / 2) * U, 0)
                var carry = so.faces[i]; carry.pts = [hm0]; carry.hinge = nil
                let hm = so.placed(carry) { g in up.contains(S.index(g.id) ?? 0) ? S.face(S.index(g.id) ?? 0).turn : 0 }[0]
                func at(_ v: Vec3) -> CGPoint { standing ? St.down(St.up(v)) : CGPoint(x: v.x, y: v.y) }
                moves.append(.drag(from: at(c3), to: at(hm)))
                up.insert(i)
            }
            return moves
        case 2:
            var moves: [GhostMove] = [], seen = Set<String>()
            for (i, f) in S.N.faces.enumerated() where !lit(s, i) && !seen.contains(f.key) {
                seen.insert(f.key); moves.append(.tap(.picture(A7.centroid(S.sq(f)))))
            }
            // the first face lights alone: its twin is tapped too
            if let first = S.N.faces.first, S.N.faces.filter({ $0.key == first.key }).count > 1, (s.h("no") ?? 0) == 0,
               let twin = S.N.faces.dropFirst().first(where: { $0.key == first.key }) { moves.insert(.tap(.picture(A7.centroid(S.sq(twin)))), at: 1) }
            return moves
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        switch stage(s) {
        case 1: return HandMove(hand: [:], missHand: [:], set: [("f", -1)], check: true)
        case 2: return HandMove(hand: s.hand, missHand: s.hand, set: [("t", -1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let N = Nets6.net(s.numbers)
        return stage(s) == 3 ? ["x": Double(N.V ?? N.SA / 2)] : nil
    }
}
