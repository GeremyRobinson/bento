import SwiftUI

/// Kindergarten's solids (the preview's solidShape and drawSolid, design/prototype/gradeK-ch2.html), drawn in true 3D
/// with the shared 3D (PaperStand.swift, Solids.Body): a cube (a box), a sphere, a cylinder and a cone, each about its
/// own origin (a box's, a cylinder's and a cone's at the middle of its bottom, a sphere's at its middle) in squares, x
/// across, y down the paper, z up off it; posed by turning and moving it. A real thing is the solid with a few of its
/// lines on it (a can's rims, a die's dots). Flat faces are named (the top, the bottom, the sides) so a tap can find
/// one and a See can light them; round parts are "round".
enum SK {
    typealias M3 = [Double]
    static let I: M3 = [1, 0, 0, 0, 1, 0, 0, 0, 1]
    static func rx(_ a: Double) -> M3 { let c = cos(a), s = sin(a); return [1, 0, 0, 0, c, -s, 0, s, c] }
    static func ry(_ a: Double) -> M3 { let c = cos(a), s = sin(a); return [c, 0, s, 0, 1, 0, -s, 0, c] }
    static func rz(_ a: Double) -> M3 { let c = cos(a), s = sin(a); return [c, -s, 0, s, c, 0, 0, 0, 1] }
    static func mm(_ A: M3, _ B: M3) -> M3 {
        var R = [Double](repeating: 0, count: 9)
        for i in 0..<3 { for j in 0..<3 { R[3 * i + j] = A[3 * i] * B[j] + A[3 * i + 1] * B[3 + j] + A[3 * i + 2] * B[6 + j] } }
        return R
    }
    static func mv(_ A: M3, _ v: Vec3) -> Vec3 { Vec3(A[0] * v.x + A[1] * v.y + A[2] * v.z, A[3] * v.x + A[4] * v.y + A[5] * v.z, A[6] * v.x + A[7] * v.y + A[8] * v.z) }
    /// The flat faces' names, for what the hands keep.
    static let faceNames = ["top", "bottom", "front", "back", "right", "left"]

    struct Shape {
        var facets: [[Vec3]] = []
        /// Each facet's face: a flat face's name, or "round".
        var ids: [String] = []
        var edges: [[Vec3]] = []
        var marks: [[Vec3]] = []
        /// A line round it that shows it turning (a ball's seam), drawn while it moves.
        var seam: [[Vec3]] = []
        var rounds: [Solids.Round] = []
        var points: [Vec3] { facets.flatMap { $0 } }
        var flatFaces: [String] { Array(Set(ids.filter { $0 != "round" })).sorted() }
        func posed(_ R: M3, _ C: Vec3) -> Shape {
            func f(_ p: Vec3) -> Vec3 { SK.mv(R, p) + C }
            var o = self
            o.facets = facets.map { $0.map(f) }; o.edges = edges.map { $0.map(f) }; o.marks = marks.map { $0.map(f) }; o.seam = seam.map { $0.map(f) }
            o.rounds = rounds.map {
                switch $0 {
                case .sphere(let c, let r): .sphere(f(c), r)
                case .cylinder(let a, let b, let r): .cylinder(f(a), f(b), r)
                case .cone(let a, let b, let r): .cone(f(a), f(b), r)
                }
            }
            return o
        }
        /// A face's corners (all its facets' points), and its middle.
        func face(_ id: String) -> [Vec3] { zip(facets, ids).filter { $0.1 == id }.flatMap { $0.0 } }
        func middle(_ id: String) -> Vec3? { let p = face(id); return p.isEmpty ? nil : p.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(p.count)) }
        /// The body to draw: `lit` faces lit, the seam shown when `seam`.
        func body(_ id: String, lit: Set<String> = [], tone: Solids.Tone = .auto, seam showSeam: Bool = false) -> Solids.Body {
            Solids.Body(id: id, facets: facets, tone: tone, tones: lit.isEmpty ? nil : ids.map { lit.contains($0) ? .lit : tone },
                        edges: edges, marks: marks + (showSeam ? seam : []), rounds: rounds)
        }
    }

    static func ring(_ r: Double, _ z: Double, _ n: Int = 32, closed: Bool = false) -> [Vec3] {
        (0..<(n + (closed ? 1 : 0))).map { i in let a = Double(i) / Double(n) * 2 * .pi; return Vec3(r * cos(a), r * sin(a), z) }
    }

    /// A box X × Y × Z, its bottom's middle at the origin. Things: 0 a block (a frame on each face), 1 a die (its dots),
    /// 2 a box (tape over the top and down the front).
    static func box(_ X: Double, _ Y: Double, _ Z: Double, thing: Int = -1) -> Shape {
        let x = X / 2, y = Y / 2
        func v(_ i: Int, _ j: Int, _ k: Int) -> Vec3 { Vec3(i == 1 ? x : -x, j == 1 ? y : -y, k == 1 ? Z : 0) }
        let faces: [(String, [Vec3])] = [("top", [v(0, 0, 1), v(1, 0, 1), v(1, 1, 1), v(0, 1, 1)]), ("bottom", [v(0, 0, 0), v(1, 0, 0), v(1, 1, 0), v(0, 1, 0)]),
                                         ("front", [v(0, 1, 0), v(1, 1, 0), v(1, 1, 1), v(0, 1, 1)]), ("back", [v(0, 0, 0), v(1, 0, 0), v(1, 0, 1), v(0, 0, 1)]),
                                         ("right", [v(1, 0, 0), v(1, 1, 0), v(1, 1, 1), v(1, 0, 1)]), ("left", [v(0, 0, 0), v(0, 1, 0), v(0, 1, 1), v(0, 0, 1)])]
        var s = Shape()
        for (id, p) in faces { s.facets.append(p); s.ids.append(id) }
        s.edges = [[v(0, 0, 0), v(1, 0, 0), v(1, 1, 0), v(0, 1, 0), v(0, 0, 0)], [v(0, 0, 1), v(1, 0, 1), v(1, 1, 1), v(0, 1, 1), v(0, 0, 1)],
                   [v(0, 0, 0), v(0, 0, 1)], [v(1, 0, 0), v(1, 0, 1)], [v(1, 1, 0), v(1, 1, 1)], [v(0, 1, 0), v(0, 1, 1)]]
        let lift = 0.06
        for (id, f) in faces {
            let c = f.reduce(Vec3(0, 0, 0)) { $0 + $1 } * 0.25, n = (f[1] - f[0]).cross(f[3] - f[0]).normalized
            let out = n.dot(c - Vec3(0, 0, Z / 2)) < 0 ? n * -1 : n
            let e1 = (f[1] - f[0]) * 1, e2 = (f[3] - f[0]) * 1
            if thing == 0 { s.marks.append((f + [f[0]]).map { c + ($0 - c) * 0.62 + out * lift }) }
            if thing == 1 {
                let pips: [String: [(Double, Double)]] = ["top": [(0, 0)], "front": [(-0.25, -0.25), (0.25, 0.25)], "right": [(-0.25, -0.25), (0, 0), (0.25, 0.25)],
                                                          "left": [(-0.25, -0.25), (0.25, -0.25), (-0.25, 0.25), (0.25, 0.25)], "back": [(-0.25, -0.25), (0.25, -0.25), (0, 0), (-0.25, 0.25), (0.25, 0.25)]]
                for (u, w) in pips[id] ?? [] {
                    let o = c + e1 * u + e2 * w
                    s.marks.append((0...12).map { i in let t = Double(i) / 12 * 2 * .pi; return o + e1 * (0.07 * cos(t)) + e2 * (0.07 * sin(t)) + out * lift })
                }
            }
        }
        if thing == 2 {
            s.marks += [[Vec3(-1, -y, Z + lift), Vec3(-1, y, Z + lift)], [Vec3(1, -y, Z + lift), Vec3(1, y, Z + lift)],
                        [Vec3(-1, y + lift, Z), Vec3(-1, y + lift, Z * 0.6)], [Vec3(1, y + lift, Z), Vec3(1, y + lift, Z * 0.6)]]
        }
        return s
    }

    /// A sphere of radius r about the origin. Things: 0 a ball (a band round it), 1 an orange (a stem and a leaf), 2 a
    /// marble (a swirl).
    static func sphere(_ r: Double, thing: Int = -1) -> Shape {
        var s = Shape()
        let nLat = 12, nLon = 24
        func p(_ i: Int, _ j: Int) -> Vec3 {
            let b = -Double.pi / 2 + Double(i) / Double(nLat) * .pi, a = Double(j) / Double(nLon) * 2 * .pi
            return Vec3(r * cos(b) * cos(a), r * cos(b) * sin(a), r * sin(b))
        }
        for i in 0..<nLat { for j in 0..<nLon {
            let q = [p(i, j), p(i, j + 1), p(i + 1, j + 1), p(i + 1, j)]
            s.facets.append(i == 0 ? [q[0], q[2], q[3]] : i == nLat - 1 ? [q[0], q[1], q[2]] : q); s.ids.append("round")
        } }
        s.rounds = [.sphere(Vec3(0, 0, 0), r)]
        let k = 1.015
        func great(_ tilt: Double) -> [Vec3] { (0...48).map { i in let a = Double(i) / 48 * 2 * .pi; return SK.mv(SK.rx(tilt), Vec3(r * k * cos(a), 0, r * k * sin(a))) } }
        s.seam = [great(0.35)]
        if thing == 0 { s.marks.append(great(.pi / 2 + 0.2)) }
        if thing == 1 { s.marks += [[Vec3(0, 0, r), Vec3(0.4, 0, r + 1.6)], [Vec3(0.4, 0, r + 1.2), Vec3(2, 0, r + 2), Vec3(3, 0, r + 1.4), Vec3(0.4, 0, r + 1.2)]] }
        if thing == 2 {
            s.marks.append((0...24).map { i in
                let a = Double(i) / 24 * .pi * 1.4 - 0.3, b = 0.5 * sin(Double(i) / 24 * .pi * 2)
                return Vec3(r * k * cos(b) * cos(a), r * k * cos(b) * sin(a), r * k * sin(b))
            })
        }
        return s
    }

    /// A cylinder of radius r and height h standing on the origin. Things: 0 a can (its rims' rings), 1 a drum (a zigzag
    /// round it), 2 a candle (its wick and flame).
    static func cylinder(_ r: Double, _ h: Double, thing: Int = -1) -> Shape {
        var s = Shape()
        let n = 32, bot = ring(r, 0, n), top = ring(r, h, n)
        s.facets += [bot, top]; s.ids += ["bottom", "top"]
        for i in 0..<n { s.facets.append([bot[i], bot[(i + 1) % n], top[(i + 1) % n], top[i]]); s.ids.append("round") }
        s.edges = [ring(r, 0, 48, closed: true), ring(r, h, 48, closed: true)]
        s.rounds = [.cylinder(Vec3(0, 0, 0), Vec3(0, 0, h), r)]
        s.seam = [[Vec3(r * 1.01, 0, 0), Vec3(r * 1.01, 0, h)]]
        if thing == 0 { s.marks += [ring(r * 1.01, 1.6, 48, closed: true), ring(r * 1.01, h - 1.6, 48, closed: true)] }
        if thing == 1 { s.marks.append((0...24).map { i in let a = Double(i) / 24 * 2 * .pi; return Vec3(r * 1.01 * cos(a), r * 1.01 * sin(a), i % 2 == 1 ? h - 4 : 4) }) }
        if thing == 2 {
            s.marks.append([Vec3(0, 0, h), Vec3(0, 0, h + 3)])
            s.marks.append((0...12).map { i in let a = Double(i) / 12 * 2 * .pi; return Vec3(0.9 * cos(a), 0, h + 4.2 + 1.2 * sin(a)) })
        }
        return s
    }

    /// A cone of base radius r and height h, its base on the origin. Things: 0 a party hat (two rings), 1 an ice-cream
    /// cone (its crossing lines), 2 a traffic cone (two stripes).
    static func cone(_ r: Double, _ h: Double, thing: Int = -1) -> Shape {
        var s = Shape()
        let n = 32, bot = ring(r, 0, n), apex = Vec3(0, 0, h)
        s.facets.append(bot); s.ids.append("bottom")
        for i in 0..<n { s.facets.append([bot[i], bot[(i + 1) % n], apex]); s.ids.append("round") }
        s.edges = [ring(r, 0, 48, closed: true)]
        s.rounds = [.cone(Vec3(0, 0, 0), apex, r)]
        s.seam = [[Vec3(r * 1.01, 0, 0), Vec3(0.001, 0, h)]]
        func band(_ u: Double) -> [Vec3] { ring(r * (1 - u) * 1.02, h * u, 48, closed: true) }
        if thing == 0 { s.marks += [band(0.35), band(0.65)] }
        if thing == 1 { for i in 0..<6 { let a = Double(i) / 6 * 2 * .pi; s.marks.append([Vec3(r * 1.01 * cos(a), r * 1.01 * sin(a), 0), Vec3(r * 0.31 * cos(a + 1.4), r * 0.31 * sin(a + 1.4), h * 0.7)]) } }
        if thing == 2 { s.marks += [band(0.42), band(0.58)] }
        return s
    }

    // MARK: seeing it

    /// The way to the camera while the paper stands, in the picture's squares (x across, y down the paper, z up).
    @MainActor static var eye: Vec3 { let d = Standing.tilted.axes.dir; return Vec3(d.x, d.z, d.y).normalized }
    /// A facet faces the child.
    @MainActor static func seen(_ f: [Vec3], centre c: Vec3) -> Bool {
        guard f.count >= 3 else { return false }
        var n = (f[1] - f[0]).cross(f[2] - f[0])
        let m = f.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(f.count))
        if n.dot(m - c) < 0 { n = n * -1 }
        return n.dot(eye) > 0.02
    }
    /// The outline of points on the board (convex hull).
    nonisolated static func hull(_ pts: [CGPoint]) -> [(Double, Double)] {
        let P = pts.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        guard P.count >= 3 else { return P.map { ($0.x, $0.y) } }
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Double { (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) }
        var lo: [CGPoint] = [], hi: [CGPoint] = []
        for p in P { while lo.count >= 2 && cross(lo[lo.count - 2], lo[lo.count - 1], p) <= 0 { lo.removeLast() }; lo.append(p) }
        for p in P.reversed() { while hi.count >= 2 && cross(hi[hi.count - 2], hi[hi.count - 1], p) <= 0 { hi.removeLast() }; hi.append(p) }
        return (lo.dropLast() + hi.dropLast()).map { ($0.x, $0.y) }
    }
    static func bounds(_ pts: [CGPoint]) -> CGRect {
        guard let x0 = pts.map(\.x).min(), let x1 = pts.map(\.x).max(), let y0 = pts.map(\.y).min(), let y1 = pts.map(\.y).max() else { return .zero }
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
}
