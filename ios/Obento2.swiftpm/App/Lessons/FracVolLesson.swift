import SwiftUI

/// Volume with fraction edges on the paper, as in the preview (design/prototype/grade6-ch7.html, dFrac), with the shared
/// 3D (PaperStand.swift): a small cube with edges of 1/2 (or 1/3) is `B` squares (a block where that shows at 75%); a
/// whole cube is 2 × 2 × 2 of them (3 × 3 × 3), its lines on the floor in ink. Flat: the floor, its lengths as
/// fractions, its small squares; drag across it to cover it ("12 small squares"). Then the paper stands up and the floor
/// rises into the first layer; drag up the layers ("36 small cubes"); 8 small cubes in a corner light as one whole; the
/// record beside: `36 ÷ 8 = [4] [1/2] cubic units`, then `V = 1½ × 2 × 1½ = 4½` (or B × h). The paper stays up to the
/// end and lies flat as the problem goes.
///
/// Hand keys: "cov" (the covered squares, a bit each), "a0", "b0" (where a sweep started), "grab", "x0", "y0", "l0", "l".
@MainActor
struct FracVolLesson: PaperLesson {
    var liveKeys: Set<String> { ["grab"] }
    var solid: Bool { true }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }

    @MainActor struct Shape {
        let P: FracVol6.Parts
        let B: Double
        let pivot: CGPoint
        static var cache: [String: (B: Double, pivot: CGPoint)] = [:]
        init(_ n: Numbers) {
            let P = FracVol6.Parts(n), key = "\(P.x) \(P.y) \(P.z) \(P.d) \(P.mode)"
            self.P = P
            if let c = Shape.cache[key] { B = c.B; pivot = c.pivot; return }
            var pick = 3.0
            for b in [5.0, 4, 3, 2] {
                let s = Shape(P: P, B: b), bx = s.boxBounds
                let flat = ProblemGrid.zoom(squares: max(Double(P.x) * b + 18, 44), 6 + Double(P.y) * b + 4)
                let rows = s.line(s.shareLine + 1) + 4
                let up = ProblemGrid.zoom(squares: s.rx + 30, 6 + max(bx.height + 1, rows))
                if min(flat, up) >= 0.79 { pick = b; break }
            }
            B = pick
            pivot = Shape(P: P, B: pick).pivot
            Shape.cache[key] = (B, pivot)
        }
        private init(P: FracVol6.Parts, B: Double) {
            self.P = P; self.B = B
            var out: [Vec3] = []
            let X1 = Double(P.x) * B, Y1 = Double(P.y) * B, Z = Double(P.z) * B
            for x in [0, X1] { for y in [0, Y1] { for z in [0, Z + B] { out.append(Vec3(x, y, z)) } } }
            pivot = Standing.pivot(showing: out, at: CGPoint(x: 3, y: 0), from: CGPoint(x: X1 / 2, y: Y1 / 2))
        }
        var X1: Double { Double(P.x) * B }
        var Y1: Double { Double(P.y) * B }
        var Z: Double { Double(P.z) * B }
        /// The box at its full height and a layer more (the room a drag past the top makes).
        var corners: [Vec3] {
            var out: [Vec3] = []
            for x in [0, X1] { for y in [0, Y1] { for z in [0, Z + B] { out.append(Vec3(x, y, z)) } } }
            return out
        }
        /// The paper stands about the point that shows the box under the words, from the floor's left edge.
        var stand: Standing { Standing(pivot: pivot) }
        var boxBounds: CGRect { stand.bounds(corners) ?? .zero }
        var rx: Double { ((boxBounds.maxX + 4) / 5).rounded(.up) * 5 }
        func line(_ i: Int) -> Double { 1 + (P.whole && P.floor % (P.d * P.d) == 0 && P.x % P.d == 0 && P.y % P.d == 0 ? 3 : 4) * Double(i) }
        /// The record's lines: the floor's area first (B × h), then the share, then V.
        var shareLine: Int { P.mode == 1 ? 1 : 0 }
        func edge(_ n: Int) -> String { P.edge(n) }
        /// A number of `d`ths (or of d²ths, d³ths) written as the record writes it: whole, a fraction, or both.
        func toks(_ n: Int, _ den: Int, _ c: Sketch.Colour = .ink) -> [M7.Tok] {
            func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
            let g = max(1, gcd(n, den)), a = n / g, b = den / g, w = a / b, r = a % b
            if r == 0 { return [.n(w, c)] }
            return (w > 0 ? [.n(w, c)] : []) + [.f(r, b, c)]
        }
    }

    func stands(_ s: PaperState) -> CGPoint? { stage(s) >= 2 ? Shape(s.numbers).stand.pivot : nil }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers), at = stage(s)
        switch at {
        case 3: return CGPoint(x: S.rx, y: S.line(S.shareLine) + 2)
        case 4: return CGPoint(x: S.rx, y: S.line(S.shareLine + 1) + 2)
        default: return nil
        }
    }
    func keysFocus(_ s: PaperState) -> CGRect? { let S = Shape(s.numbers); return stage(s) == 3 ? s.standing(S.pivot).bounds(S.corners) : nil }

    private func covered(_ s: PaperState) -> Set<Int> {
        let m = UInt64(s.h("cov") ?? 0)
        return Set((0..<64).filter { m & (1 << UInt64($0)) != 0 })
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), B = S.B, X1 = S.X1, Y1 = S.Y1
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen(), solids = Solids()
        var standing: Standing?
        if at <= 1 {
            // flat: the floor, its small squares, the wholes' lines in ink, what's covered shaded
            let cov = covered(s)
            for c in cov.sorted() { pic.fill("cv\(c)", col: Double(c % P.x) * B, row: Double(c / P.x) * B, w: B, h: B, A7.strong) }
            pic.fill("floor", col: 0, row: 0, w: X1, h: Y1, .tint(0.12))
            for a in 1..<P.x { pic.line("gx\(a)", [(Double(a) * B, 0), (Double(a) * B, Y1)], a % P.d == 0 ? .ink : .chapter) }
            for b in 1..<P.y { pic.line("gy\(b)", [(0, Double(b) * B), (X1, Double(b) * B)], b % P.d == 0 ? .ink : .chapter) }
            pic.sketch.box("fo", pic.R(0, 0, X1, Y1), .ink, width: Sketch.stroke)
            pic.label("lx", S.edge(P.x), A7.words, .below, edge: Y1, along: X1 / 2)
            pic.label("ly", S.edge(P.y), A7.words, .left, edge: 0, along: Y1 / 2)
            if !cov.isEmpty {
                let t = "\(cov.count) small square\(cov.count == 1 ? "" : "s")"
                live.word("cnt", t, at: X1 + 1.5, 1, A7.lit, anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { live.reads(t) }
            }
            if at == 1 && s.on("ring") { A7.ring(&pic, "ring", x: 0, y: 0, w: X1, h: Y1) }
            if at == 1 && s.on("spot"), let c = (0..<P.floor).first(where: { !cov.contains($0) }) {
                pic.sketch.box("spot", pic.R(Double(c % P.x) * B + 0.4, Double(c / P.x) * B + 0.4, B - 0.8, B - 0.8), .chapter, width: Sketch.stroke, dashed: true)
            }
        } else {
            let St = s.standing(S.pivot)
            standing = St
            let layers = at == 2 ? Int(s.h("l") ?? 1) : P.z, lit = at >= 3
            solids = box(S, layers: layers, lit: lit, wire: at == 2)
            let b = St.bounds(S.corners) ?? .zero
            if at == 2 {
                let top = St.up(X1, Y1 / 2, Double(layers) * B), t = "\(P.floor * layers) small cubes"
                if s.grabbed || s.run.missed { live.word("ro", t, at: b.maxX + 1.5, top.y, A7.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
                if s.grabbed { live.reads(t) }
                if s.on("ring") { A7.ring(&pic, "ring", x: b.minX, y: b.minY, w: b.width, h: b.height) }
                if s.on("spot") { let p = St.up(0, Y1, S.Z); pic.word("spot", S.edge(P.z), at: p.x - 1, p.y, A7.lit, anchor: UnitPoint(x: 1, y: 0.5)) }
            }
            if at == 3 && s.on("ring") {
                // the whole cube made of small ones, ringed
                let pts = [0.0, Double(P.d) * B].flatMap { x in [Y1 - Double(P.d) * B, Y1].flatMap { y in [0.0, Double(P.d) * B].map { Vec3(x, y, $0) } } }
                if let c = St.bounds(pts) { A7.ring(&pic, "ring", x: c.minX + 1, y: c.minY + 1, w: c.width - 2, h: c.height - 2) }
            }
        }
        // the record beside the standing box
        if at >= 2 {
            var row = 0
            if P.mode == 1 {
                M7.row(&rec, "rB", [.t("B"), .op("=")] + S.toks(P.x, P.d) + [.op("×")] + S.toks(P.y, P.d) + [.op("=")] + S.toks(P.floor, P.d * P.d, .chapter), x: S.rx, line: S.line(row))
                row += 1
            }
            if at >= 3 {
                let ans: [M7.Tok] = at == 3 ? (P.whole ? [.box("w", cells: 2)] : [.box("w", cells: 1), .fb("n", "d")]) : S.toks(P.N, P.per, .chapter)
                M7.row(&rec, "rD", [.n(P.N), .op("÷"), .n(P.per), .op("=")] + ans + [.w("cubic units")], x: S.rx, line: S.line(row))
                if at >= 4 {
                    let v: [M7.Tok] = P.mode == 1 ? S.toks(P.floor, P.d * P.d) + [.op("×")] + S.toks(P.z, P.d)
                        : S.toks(P.x, P.d) + [.op("×")] + S.toks(P.y, P.d) + [.op("×")] + S.toks(P.z, P.d)
                    M7.row(&rec, "rV", [.t("V"), .op("=")] + v + [.op("=")] + S.toks(P.N, P.per, .chapter), x: S.rx, line: S.line(row + 1))
                }
            }
        }
        var room = pic.R(-3, -1, max(X1 + 18, S.rx + 30), max(Y1 + 4, S.boxBounds.maxY + 1))
        if let st = standing, let b = st.bounds(S.corners) { room = room.union(pic.R(b.minX - 3, b.minY, b.width + 3, b.height + 1)) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: room, solids: solids, standing: standing)
    }

    /// The box standing on the paper: its floor and its lines (the wholes' in ink), its layers of small cubes (each in
    /// three pieces, so the whole cube in the front-left corner can light), its full height dashed where it's still
    /// empty, its lengths on its edges.
    private func box(_ S: Shape, layers: Int, lit: Bool, wire: Bool) -> Solids {
        var so = Solids()
        let P = S.P, B = S.B, X1 = S.X1, Y1 = S.Y1, Z = S.Z, d = P.d
        so.faces.append(Solids.Face(id: "floor", pts: [Vec3(0, 0, 0), Vec3(X1, 0, 0), Vec3(X1, Y1, 0), Vec3(0, Y1, 0)], look: .top))
        for a in 1..<P.x { so.lines.append(Solids.Line(id: "gx\(a)", pts: [Vec3(Double(a) * B, 0, 0.01), Vec3(Double(a) * B, Y1, 0.01)], colour: a % d == 0 ? .ink : .chapter)) }
        for b in 1..<P.y { so.lines.append(Solids.Line(id: "gy\(b)", pts: [Vec3(0, Double(b) * B, 0.01), Vec3(X1, Double(b) * B, 0.01)], colour: b % d == 0 ? .ink : .chapter)) }
        let cx = min(d, P.x), cy = min(d, P.y)
        for k in 0..<layers {
            let z = Double(k) * B, delay = k == 0 ? TiltCamera.beat * 0.55 : 0.12 * Double(k)
            // the front-left corner (a whole's worth once it's lit), the rest beside it and behind it
            let corner = Solids.Block(id: "L\(k)c", at: Vec3(0, Y1 - Double(cy) * B, z), l: cx, w: cy, B: B, look: lit && k < d ? .lit : .auto, delay: delay)
            so.blocks.append(corner)
            if P.x > cx { so.blocks.append(Solids.Block(id: "L\(k)r", at: Vec3(Double(cx) * B, 0, z), l: P.x - cx, w: P.y, B: B, delay: delay)) }
            if P.y > cy { so.blocks.append(Solids.Block(id: "L\(k)b", at: Vec3(0, 0, z), l: cx, w: P.y - cy, B: B, delay: delay)) }
        }
        let z0 = Double(layers) * B
        if wire, z0 < Z - 0.01 {
            so.lines.append(Solids.Line(id: "wiretop", pts: [Vec3(0, 0, Z), Vec3(X1, 0, Z), Vec3(X1, Y1, Z), Vec3(0, Y1, Z), Vec3(0, 0, Z)], dashed: true))
            for (k, (x, y)) in [(0.0, 0.0), (X1, 0), (X1, Y1), (0, Y1)].enumerated() {
                so.lines.append(Solids.Line(id: "wireup\(k)", pts: [Vec3(x, y, z0), Vec3(x, y, Z)], dashed: true))
            }
        }
        // its lengths on the edges the child sees: along the front, along the right side, up the front corner
        so.labels.append(Solids.Label(id: "lx", text: S.edge(P.x), at: Vec3(X1 / 2, Y1, 0), words: A7.words, anchor: UnitPoint(x: 0.5, y: -0.3)))
        so.labels.append(Solids.Label(id: "ly", text: S.edge(P.y), at: Vec3(X1, Y1 / 2, 0), words: A7.words, anchor: UnitPoint(x: -0.3, y: 0.2)))
        so.labels.append(Solids.Label(id: "lz", text: S.edge(P.z), at: Vec3(0, Y1, Z / 2), words: A7.words, anchor: UnitPoint(x: 1.6, y: 0.5)))
        return so
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), P = S.P, B = S.B, at = stage(s)
        func cell(_ q: CGPoint, clamped: Bool = false) -> (Int, Int)? {
            var a = Int((q.x / B).rounded(.down)), b = Int((q.y / B).rounded(.down))
            if clamped { a = max(0, min(P.x - 1, a)); b = max(0, min(P.y - 1, b)) }
            return a >= 0 && a < P.x && b >= 0 && b < P.y ? (a, b) : nil
        }
        func mask(_ cs: Set<Int>) -> Double { Double(cs.reduce(UInt64(0)) { $0 | (1 << UInt64($1)) }) }
        switch at {
        case 1:
            let have = covered(s)
            func done(_ cs: Set<Int>) -> HandMove {
                HandMove(hand: ["cov": mask(cs)], missHand: ["cov": mask(cs)], set: [("c", Double(cs.count))], check: true)
            }
            return Hands(tap: { q in
                guard let (a, b) = cell(q) else { return nil }
                return done(have.union([b * P.x + a]))
            }, grab: { q in
                guard let (a, b) = cell(q) else { return nil }
                return ["grab": 1, "a0": Double(a), "b0": Double(b), "base": mask(have), "cov": mask(have.union([b * P.x + a]))]
            }, drag: { q, hd in
                var hd = hd
                guard let (a, b) = cell(q, clamped: true) else { return hd }
                let a0 = Int(hd["a0"] ?? 0), b0 = Int(hd["b0"] ?? 0)
                var cs = Set((0..<64).filter { UInt64(hd["base"] ?? 0) & (1 << UInt64($0)) != 0 })
                for i in min(a, a0)...max(a, a0) { for j in min(b, b0)...max(b, b0) { cs.insert(j * P.x + i) } }
                hd["cov"] = mask(cs); return hd
            }, release: { hd in
                done(Set((0..<64).filter { UInt64(hd["cov"] ?? 0) & (1 << UInt64($0)) != 0 }))
            })
        case 2:
            let l = s.h("l") ?? 1
            return Hands(grab: { q in
                q.x > -6 && q.x < S.X1 + 6 && q.y > -S.Z * 2 - 6 && q.y < S.Y1 + 6 ? ["grab": 1, "x0": q.x, "y0": q.y, "l0": l, "l": l] : nil
            }, drag: { q, hd in
                var hd = hd
                let r = Standing.rise(from: CGPoint(x: hd["x0"] ?? q.x, y: hd["y0"] ?? q.y), to: q)
                hd["l"] = Double(max(1, min(P.z + 1, Int(hd["l0"] ?? 1) + Int((r / B).rounded()))))
                return hd
            }, release: { hd in
                let l = hd["l"] ?? 1
                return HandMove(hand: ["l": l], missHand: ["l": l], set: [("l", l)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), P = S.P, B = S.B
        switch stage(s) {
        case 1: return [.drag(from: CGPoint(x: B / 2, y: B / 2), to: CGPoint(x: S.X1 - B / 2, y: S.Y1 - B / 2))]
        case 2:
            let l = s.h("l") ?? 1, p = CGPoint(x: S.X1 / 2, y: S.Y1 / 2)
            return [.drag(from: p, to: Standing.away(from: p, rising: (Double(P.z) - l) * B))]
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = FracVol6.Parts(s.numbers)
        switch stage(s) {
        case 1: return HandMove(hand: ["cov": 1], missHand: ["cov": 1], set: [("c", 1)], check: true)
        case 2: let l = Double(P.z > 1 ? P.z - 1 : P.z + 1); return HandMove(hand: ["l": l], missHand: ["l": l], set: [("l", l)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = FracVol6.Parts(s.numbers)
        return stage(s) == 3 ? (P.whole ? ["w": Double(P.N)] : ["w": Double(P.N), "n": 0, "d": 1]) : nil
    }
}
