import SwiftUI
import RealityKit
import simd

/// A box of cubes on the paper (Unit cubes, and every 3D lesson built on it: Volume of a box): what the paper's scene
/// needs to draw it at any moment. One cube is one block of the paper; the floor's squares are the blocks it stands on.
@MainActor
protocol CubesPicture: AnyObject {
    /// The floor's back-left corner, in world units (one unit is one block), on the paper's strong lines.
    var corner: Vec3 { get }
    var box: UnitCubes.Box { get }
    /// Its chapter: the cubes are its colour (colour lives only in the maths).
    var chapter: Chapter { get }
    var instant: Bool { get }
    /// How far the floor's dashed outline has drawn itself in (0 = not there).
    func outline(at t: Double) -> Double
    /// Floor square `i` (z * length + x): how far the child's fill has grown in, and a preview's lighter fill.
    func square(_ i: Int, at t: Double) -> (fill: Double, ghost: Double)
    /// How layer `y` stands now (0 is the floor's, risen).
    func layer(_ y: Int, at t: Double) -> CubesLayer
    /// A layer rising cube by cube: how tall cube (x, z) of it is (0...1).
    func cube(x: Int, y: Int, z: Int, at t: Double) -> Double
    /// The floor's hints (LESSONS.md §7): its empty squares outlined, and tinted.
    var hints: (outline: Bool, tint: Bool, empty: [Int]) { get }
    /// How far the box's full height has drawn itself in, dashed (0 = not shown).
    func wire(at t: Double) -> Double
}

extension CubesPicture {
    /// How high the cubes stand now (a layer rising stands part way), counting a preview's lighter ones: the box's full
    /// height shows dashed only above them.
    func stands(at t: Double) -> Double {
        var top = 0.0
        for y in 0..<box.height {
            switch layer(y, at: t) {
            case .none: continue
            case .cubes: top = max(top, Double(y) + 1)
            case .whole(let h), .ghost(let h): if h > 0.001 { top = max(top, Double(y) + h) }
            }
        }
        return top
    }
}

/// How a layer of cubes stands: not there, rising cube by cube, or as one piece this tall (0...1), in the cubes'
/// colours or a preview's lighter ones.
enum CubesLayer: Equatable { case none, cubes, whole(Double), ghost(Double) }

/// When the cubes of a layer rise, one after another (LESSONS.md: 0.7 s each, 40 ms apart), however big the floor:
/// a layer takes at most about a second to start rising (a floor of 64 doesn't take 2.5 s).
enum CubesTiming {
    static let rise = 0.7
    static func stagger(floor: Int, first: Bool = true) -> Double { min(first ? 0.04 : 0.035, 1.0 / Double(max(1, floor))) }
    /// When the last cube of a layer that starts rising at `start` stands at its full height.
    static func end(_ start: Double, floor: Int, first: Bool = true) -> Double { start + stagger(floor: floor, first: first) * Double(max(0, floor - 1)) + rise }
}

/// Draws a CubesPicture into the paper's scene. Each settled layer is one mesh (its faces and every line between its
/// cubes), so a box of 8 × 8 × 6 is six pieces, not 384; only a layer rising cube by cube is drawn as single cubes,
/// from a few kept for it. The floor's squares fill and empty in place; the box's outline and its full height are
/// dashed lines that stroke on.
@MainActor
final class CubesDrawer {
    unowned let rig: Rig
    let root = Entity()
    private var shape: (box: UnitCubes.Box, corner: Vec3)?
    private var squares: [ModelEntity] = []
    private var squareLook: [Int: (k: Float, ghost: Bool)] = [:]
    private var layers: [ModelEntity] = []
    private var layerLook: [Int: CubesLayer] = [:]
    /// Single cubes for the layer rising cube by cube, and which layer they're showing.
    private var pool: [ModelEntity] = []
    private var poolLayer: Int?
    private var outline = ModelEntity(), outlineK = -1.0
    private var wire = ModelEntity(), wireK = -1.0, wireTop = -1.0
    private var hints = Entity(), hintKey = ""
    private var cubeMesh: MeshResource?, layerMesh: MeshResource?
    /// A floor square's edges, in the cubes' edge colour: covered squares read as squares, to count, at any zoom.
    private var squareEdge: MeshResource?
    private var lines: Double = 0
    private var looks: (solid: [UnlitMaterial], ghost: [UnlitMaterial], square: UnlitMaterial, ghostSquare: UnlitMaterial, deep: UIColor, wire: UIColor)?
    private var lookKey = ""

    init(rig: Rig) { self.rig = rig }

    func draw(_ p: any CubesPicture, at t: Double) {
        let dark = rig.dark ?? false, key = "\(p.chapter.hex) \(dark)"
        if key != lookKey { lookKey = key; looks = Self.looks(chapter: p.chapter.hex, dark: dark, paper: rig.paperHex); shape = nil }
        if shape?.box != p.box || shape?.corner != p.corner { rebuild(p) }
        if rig.lineScale != lines { relines(p) }
        guard let looks else { return }
        let b = p.box, o = p.corner

        // the floor's squares: the child's fill, or a preview's lighter one over an empty square
        for i in 0..<min(squares.count, b.floor) {
            let s = p.square(i, at: t), ghost = s.ghost > s.fill
            let k = Float(snapped(max(s.fill, s.ghost), 60))
            if let was = squareLook[i], was.k == k, was.ghost == ghost { continue }
            squareLook[i] = (k, ghost)
            let e = squares[i]
            e.isEnabled = k > 0
            e.scale = SIMD3(max(0.0001, k), 1, max(0.0001, k))
            e.model?.materials = [ghost ? looks.ghostSquare : looks.square]
            (e.children.first as? ModelEntity)?.model?.materials = [ghost ? looks.ghost[3] : looks.solid[3]]
        }
        drawHints(p)

        // the layers: one piece each, rising and sinking whole; the one rising cube by cube from the single cubes
        var wave: Int?
        for y in 0..<b.height {
            let now = p.layer(y, at: t)
            if now == .cubes, wave == nil { wave = y }
            let shown: CubesLayer = now == .cubes ? .none : now
            guard layers.indices.contains(y), layerLook[y] != shown else { continue }
            let e = layers[y], was = layerLook[y]
            layerLook[y] = shown
            switch shown {
            case .none, .cubes: e.isEnabled = false
            case .whole(let h), .ghost(let h):
                e.isEnabled = h > 0.001
                e.scale = SIMD3(1, Float(max(0.0001, h)), 1)
                let ghost: Bool = { if case .ghost = shown { return true } else { return false } }()
                let wasGhost: Bool = { if case .ghost? = was { return true } else { return false } }()
                if ghost != wasGhost || was == nil || was == CubesLayer.none || was == .cubes { e.model?.materials = ghost ? looks.ghost : looks.solid }
            }
        }
        if let y = wave {
            if pool.count < b.floor, let cubeMesh {
                for _ in pool.count..<b.floor {
                    let e = ModelEntity(mesh: cubeMesh, materials: looks.solid); e.isEnabled = false
                    root.addChild(e); pool.append(e)
                }
            }
            for i in 0..<b.floor {
                let c = UnitCubes.cell(i, in: b), k = p.cube(x: c.x, y: y, z: c.z, at: t), e = pool[i]
                e.isEnabled = k > 0
                e.position = SIMD3(Float(o.x) + Float(c.x), Float(y), Float(o.z) + Float(c.z))
                e.scale = SIMD3(1, Float(max(0.0001, k)), 1)
            }
            poolLayer = y
        } else if poolLayer != nil {
            for e in pool { e.isEnabled = false }
            poolLayer = nil
        }

        // the floor's outline, dashed on the paper's strong lines, and the box's full height, dashed
        let ok = snapped(p.outline(at: t), 30)
        if ok != outlineK { outlineK = ok; drawOutline(p, ok, looks.deep) }
        // the full height's dashes go where the box is still empty: above the cubes as they stand now (a tenth of a cube
        // ahead of a rising layer, so no dash shows over it)
        let wk = snapped(p.wire(at: t), 30), top = wk > 0 ? (p.stands(at: t) * 10).rounded(.up) / 10 : 0
        if wk != wireK || top != wireTop { wireK = wk; wireTop = top; drawWire(p, wk, stands: top, looks.wire) }
    }

    /// Everything goes (the lesson or problem has left the paper).
    func clear() {
        for c in Array(root.children) { c.removeFromParent() }
        squares = []; layers = []; pool = []; poolLayer = nil; squareLook = [:]; layerLook = [:]
        outline = ModelEntity(); wire = ModelEntity(); hints = Entity(); outlineK = -1; wireK = -1; wireTop = -1; hintKey = ""; shape = nil
    }

    private func rebuild(_ p: any CubesPicture) {
        clear()
        shape = (p.box, p.corner)
        guard let looks else { return }
        let b = p.box, o = p.corner
        let plane = MeshResource.generatePlane(width: 1, depth: 1)
        relines(p)
        for i in 0..<b.floor {
            let c = UnitCubes.cell(i, in: b)
            let e = ModelEntity(mesh: plane, materials: [looks.square])
            // under the strong lines, so each big square shows
            e.position = SIMD3(Float(o.x) + Float(c.x) + 0.5, 0.0003, Float(o.z) + Float(c.z) + 0.5)
            e.isEnabled = false
            // its edges over the strong lines, as a cube's top has them: a covered square reads as one square
            let edge = ModelEntity()
            if let squareEdge { edge.model = ModelComponent(mesh: squareEdge, materials: [looks.solid[3]]) }
            edge.position.y = 0.0004
            e.addChild(edge)
            root.addChild(e); squares.append(e)
        }
        for y in 0..<b.height {
            let e = ModelEntity()
            if let layerMesh { e.model = ModelComponent(mesh: layerMesh, materials: looks.solid) }
            e.position = SIMD3(Float(o.x), Float(y), Float(o.z))
            e.isEnabled = false
            root.addChild(e); layers.append(e)
        }
        root.addChild(outline); root.addChild(wire); root.addChild(hints)
    }

    /// The lines at the paper's zoom: they keep their width on the screen (Sketch.stroke), so their meshes are made
    /// again when the zoom changes.
    func relines(_ p: any CubesPicture) {
        lines = rig.lineScale
        guard lines > 0 else { return }
        let w = Float(Sketch.stroke / lines), b = p.box
        cubeMesh = Self.layerMesh(length: 1, width: 1, edge: w)
        layerMesh = Self.layerMesh(length: b.length, width: b.width, edge: w)
        squareEdge = Rig.lines([(SIMD2(-0.5, -0.5), SIMD2(0.5, -0.5)), (SIMD2(0.5, -0.5), SIMD2(0.5, 0.5)),
                                (SIMD2(0.5, 0.5), SIMD2(-0.5, 0.5)), (SIMD2(-0.5, 0.5), SIMD2(-0.5, -0.5))], width: w)
        if let squareEdge { for e in squares { (e.children.first as? ModelEntity)?.model?.mesh = squareEdge } }
        if let cubeMesh { for e in pool { e.model?.mesh = cubeMesh } }
        if let layerMesh { for e in layers { if e.model == nil { e.model = ModelComponent(mesh: layerMesh, materials: looks?.solid ?? []) } else { e.model?.mesh = layerMesh } } }
        outlineK = -1; wireK = -1; wireTop = -1; hintKey = ""
    }

    // MARK: the pieces

    /// The colours: the cube faces in the chapter's colour, lighter for a preview's, the floor's squares, the edges, the
    /// dashed full height (ink3, from the colour table). On dark paper the faces are lit as they are on light paper, the
    /// top lightest and the sides darker, each a clear step from the next (mixed thinly into the dark surface they were
    /// all a muddy brown, the top the darkest), and a covered square is the cube top it rises into.
    static func looks(chapter c: UInt32, dark: Bool, paper: UInt32) -> (solid: [UnlitMaterial], ghost: [UnlitMaterial], square: UnlitMaterial, ghostSquare: UnlitMaterial, deep: UIColor, wire: UIColor) {
        let k = Rig.Colours(dark: dark, chapter: c)
        func light(_ u: UIColor, _ f: Double = 0.55) -> UIColor { UIColor(hex: Ink.mix(u.hexValue, paper, f)) }
        let surface = Ink.surface.hexValue(dark: dark)
        func face(_ f: Double) -> UIColor { UIColor(hex: Ink.mix(surface, c, f)) }
        let (top, front, side, square) = dark ? (face(0.78), face(0.60), face(0.44), face(0.70)) : (k.top, k.front, k.side, k.square)
        let solid = [top, front, side, k.deep].map(flat)
        let ghost = [light(top), light(front), light(side), light(k.deep, 0.45)].map(flat)
        return (solid, ghost, flat(square), flat(light(square, 0.5)), k.deep, UIColor(hex: Ink.ink3.hexValue(dark: dark)))
    }

    /// A count lit on a cube's face (a hint, or Show me counting): the chapter's colour in a shade that reads on the
    /// faces (3.8 : 1 on amber, light or dark), underlined: no patch of paper over the cubes.
    static func lit(chapter c: UInt32) -> Sketch.Colour {
        // darker on light paper (mixed toward the ink), lighter on dark (toward the near-white of light paper's surface)
        .hex(Ink.mix(c, Ink.ink.hexValue(dark: false), 0.45), Ink.mix(c, Ink.surface.hexValue(dark: false), 0.7))
    }

    /// A layer of cubes `length` × `width`, one block tall, from its back-left-bottom corner: its six faces as six big
    /// faces (the top and bottom in the top colour, front and back, the two sides), and the cubes' edges as thin bars
    /// (every line across the top, and down the four sides) in the edge colour. Materials: top, front, side, edges.
    static func layerMesh(length l: Int, width w: Int, edge: Float) -> MeshResource? {
        let L = Float(l), W = Float(w)
        func quad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>, into pos: inout [SIMD3<Float>], _ idx: inout [UInt32]) {
            let base = UInt32(pos.count)
            pos += [a, b, c, d]
            // both windings, so it shows from either side
            idx += [base, base + 1, base + 2, base, base + 2, base + 3, base, base + 2, base + 1, base, base + 3, base + 2]
        }
        var top: ([SIMD3<Float>], [UInt32]) = ([], []), front = top, side = top, bars = top
        quad([0, 1, 0], [L, 1, 0], [L, 1, W], [0, 1, W], into: &top.0, &top.1)
        quad([0, 0, 0], [L, 0, 0], [L, 0, W], [0, 0, W], into: &top.0, &top.1)
        quad([0, 0, W], [L, 0, W], [L, 1, W], [0, 1, W], into: &front.0, &front.1)
        quad([0, 0, 0], [L, 0, 0], [L, 1, 0], [0, 1, 0], into: &front.0, &front.1)
        quad([0, 0, 0], [0, 0, W], [0, 1, W], [0, 1, 0], into: &side.0, &side.1)
        quad([L, 0, 0], [L, 0, W], [L, 1, W], [L, 1, 0], into: &side.0, &side.1)
        // the edges: a thin bar from a to b, `edge` wide each way, as long again by half its width at each end
        let h = edge / 2
        func bar(_ a: SIMD3<Float>, _ b: SIMD3<Float>) {
            var lo = simd_min(a, b) - SIMD3(repeating: h), hi = simd_max(a, b) + SIMD3(repeating: h)
            lo = simd_min(lo, hi); hi = simd_max(lo, hi)
            let base = UInt32(bars.0.count)
            for k in 0..<8 { bars.0.append(SIMD3(k & 1 == 0 ? lo.x : hi.x, k & 2 == 0 ? lo.y : hi.y, k & 4 == 0 ? lo.z : hi.z)) }
            for f in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]] {
                let q = f.map { base + UInt32($0) }
                bars.1 += [q[0], q[1], q[2], q[0], q[2], q[3], q[0], q[2], q[1], q[0], q[3], q[2]]
            }
        }
        for z in 0...w { bar([0, 1, Float(z)], [L, 1, Float(z)]) }             // across the top
        for x in 0...l { bar([Float(x), 1, 0], [Float(x), 1, W]) }
        for z in [0, W] { bar([0, 0, z], [L, 0, z]) }                          // round the bottom
        for x in [0, L] { bar([x, 0, 0], [x, 0, W]) }
        for x in 0...l { for z in [0, W] { bar([Float(x), 0, z], [Float(x), 1, z]) } }   // down the front and back
        for z in 1..<max(1, w) { for x in [0, L] { bar([x, 0, Float(z)], [x, 1, Float(z)]) } }  // and the sides
        var parts: [MeshDescriptor] = []
        for (i, part) in [top, front, side, bars].enumerated() {
            var d = MeshDescriptor(name: "layer\(i)")
            d.positions = MeshBuffers.Positions(part.0)
            d.primitives = .triangles(part.1)
            d.materials = .allFaces(UInt32(i))
            parts.append(d)
        }
        return try? MeshResource.generate(from: parts)
    }

    /// The floor's outline, dashed, on the paper's strong lines, drawn in as far as `k`.
    private func drawOutline(_ p: any CubesPicture, _ k: Double, _ c: UIColor) {
        outline.isEnabled = k > 0
        guard k > 0, lines > 0 else { return }
        let o = p.corner, b = p.box, L = Float(b.length), W = Float(b.width), x = Float(o.x), z = Float(o.z)
        let sides = [(SIMD2(x, z), SIMD2(x + L, z)), (SIMD2(x + L, z), SIMD2(x + L, z + W)), (SIMD2(x + L, z + W), SIMD2(x, z + W)), (SIMD2(x, z + W), SIMD2(x, z))]
        var dashes: [(SIMD2<Float>, SIMD2<Float>)] = []
        // every side draws at once, from its corner, as far as k
        for (a, e) in sides {
            let len = simd_length(e - a) * Float(k), d = simd_normalize(e - a)
            var s: Float = 0
            while s < len { dashes.append((a + d * s, a + d * min(len, s + 0.08))); s += 0.14 }
        }
        outline.model = Rig.lines(dashes, width: Float(Sketch.stroke / lines)).map { ModelComponent(mesh: $0, materials: [flat(c)]) }
        outline.position.y = 0.002
    }

    /// The box's full height (its 12 edges), dashed, drawn in as far as `k`, only where the box is still empty: a dash
    /// that would cross the cubes standing now (`stands` high) isn't drawn, as if the cubes stood in front of it (over
    /// the cubes' top it read as a cut through them). The tilted view's angles are fixed, so what the cubes hide is
    /// worked out on the view's plane, whatever the pan or zoom. Set a hair inside the box, so the cubes hide its
    /// lowest edges too.
    private func drawWire(_ p: any CubesPicture, _ k: Double, stands: Double, _ c: UIColor) {
        wire.isEnabled = k > 0
        guard k > 0, lines > 0 else { return }
        let o = p.corner, b = p.box, w = Float(Sketch.stroke / lines), i = w * 1.2
        let x0 = Float(o.x) + i, x1 = Float(o.x) + Float(b.length) - i, y0 = i, y1 = Float(b.height) - i, z0 = Float(o.z) + i, z1 = Float(o.z) + Float(b.width) - i
        var edges: [(SIMD3<Float>, SIMD3<Float>)] = []
        for y in [y0, y1] { edges += [([x0, y, z0], [x1, y, z0]), ([x0, y, z1], [x1, y, z1]), ([x0, y, z0], [x0, y, z1]), ([x1, y, z0], [x1, y, z1])] }
        for x in [x0, x1] { for z in [z0, z1] { edges.append(([x, y0, z], [x, y1, z])) } }
        // the cubes standing, outlined on the view's plane (right, up), a hair bigger so a dash along their edge goes too
        let hidden = stands > 0 ? Self.outline(of: o, b.length, stands, b.width, grow: Double(w)) : []
        func covered(_ q: SIMD3<Float>) -> Bool {
            guard !hidden.isEmpty else { return false }
            let (r, u) = Self.plane
            return Self.inside((Double(q.x) * r.x + Double(q.y) * r.y + Double(q.z) * r.z, Double(q.x) * u.x + Double(q.y) * u.y + Double(q.z) * u.z), hidden)
        }
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let h = w / 2
        for (a, e) in edges {
            let len = simd_length(e - a) * Float(k), d = simd_normalize(e - a)
            var s: Float = 0
            while s < len {
                let p0 = a + d * s, p1 = a + d * min(len, s + 0.07)
                s += 0.15
                if covered((p0 + p1) / 2) { continue }
                let lo = simd_min(p0, p1) - SIMD3(repeating: h), hi = simd_max(p0, p1) + SIMD3(repeating: h)
                let base = UInt32(pos.count)
                for n in 0..<8 { pos.append(SIMD3(n & 1 == 0 ? lo.x : hi.x, n & 2 == 0 ? lo.y : hi.y, n & 4 == 0 ? lo.z : hi.z)) }
                for f in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]] {
                    let q = f.map { base + UInt32($0) }
                    idx += [q[0], q[1], q[2], q[0], q[2], q[3], q[0], q[2], q[1], q[0], q[3], q[2]]
                }
            }
        }
        guard !pos.isEmpty else { wire.isEnabled = false; return }
        var d = MeshDescriptor(name: "wire")
        d.positions = MeshBuffers.Positions(pos)
        d.primitives = .triangles(idx)
        wire.model = (try? MeshResource.generate(from: [d])).map { ModelComponent(mesh: $0, materials: [flat(c)]) }
    }

    /// The tilted view's plane: its right and up, the same for every tilted view (only the pan and zoom differ).
    static let plane: (right: Vec3, up: Vec3) = {
        let v = PaperView3D(elevation: PaperView3D.tilted.elevation, azimuth: PaperView3D.tilted.azimuth)
        return (v.axes.right, v.axes.up)
    }()

    /// The outline of a block of cubes `l` × `h` × `w` from corner `o`, on the tilted view's plane, grown by `grow`: the
    /// hull of its eight corners.
    static func outline(of o: Vec3, _ l: Int, _ h: Double, _ w: Int, grow: Double) -> [(Double, Double)] {
        let (r, u) = plane
        var pts: [(Double, Double)] = []
        for x in [o.x, o.x + Double(l)] { for y in [0, h] { for z in [o.z, o.z + Double(w)] { let q = Vec3(x, y, z); pts.append((q.dot(r), q.dot(u))) } } }
        // the convex hull (monotone chain), counter-clockwise
        pts.sort { $0.0 == $1.0 ? $0.1 < $1.1 : $0.0 < $1.0 }
        func cross(_ a: (Double, Double), _ b: (Double, Double), _ c: (Double, Double)) -> Double { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
        var lower: [(Double, Double)] = [], upper: [(Double, Double)] = []
        for q in pts { while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], q) <= 0 { lower.removeLast() }; lower.append(q) }
        for q in pts.reversed() { while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], q) <= 0 { upper.removeLast() }; upper.append(q) }
        let hull = Array(lower.dropLast()) + Array(upper.dropLast())
        // grown out from its middle
        let mx = hull.map(\.0).reduce(0, +) / Double(max(1, hull.count)), my = hull.map(\.1).reduce(0, +) / Double(max(1, hull.count))
        return hull.map { q in
            let dx = q.0 - mx, dy = q.1 - my, d = max(1e-9, (dx * dx + dy * dy).squareRoot())
            return (q.0 + dx / d * grow, q.1 + dy / d * grow)
        }
    }

    /// Whether a point is inside a convex outline (counter-clockwise).
    static func inside(_ p: (Double, Double), _ hull: [(Double, Double)]) -> Bool {
        guard hull.count >= 3 else { return false }
        for i in hull.indices {
            let a = hull[i], b = hull[(i + 1) % hull.count]
            if (b.0 - a.0) * (p.1 - a.1) - (b.1 - a.1) * (p.0 - a.0) < 0 { return false }
        }
        return true
    }

    /// Hints on the floor (LESSONS.md §7): the empty squares outlined, dashed, and lightly tinted.
    private func drawHints(_ p: any CubesPicture) {
        let h = p.hints
        let key = "\(h.outline) \(h.tint) \(h.empty) \(lines)"
        guard key != hintKey else { return }
        hintKey = key
        hints.removeFromParent(); hints = Entity(); root.addChild(hints)
        guard h.outline || h.tint, lines > 0 else { return }
        let b = p.box, o = p.corner, chapter = UIColor(hex: p.chapter.hex), px = Float(1 / lines), inset: Float = 0.06
        let paper = rig.paperHex
        var dashes: [(SIMD2<Float>, SIMD2<Float>)] = []
        for i in h.empty {
            let c = UnitCubes.cell(i, in: b), x = Float(o.x) + Float(c.x) + inset, z = Float(o.z) + Float(c.z) + inset, s = 1 - 2 * inset
            if h.outline {
                for (a, e) in [(SIMD2(x, z), SIMD2(x + s, z)), (SIMD2(x + s, z), SIMD2(x + s, z + s)), (SIMD2(x + s, z + s), SIMD2(x, z + s)), (SIMD2(x, z + s), SIMD2(x, z))] {
                    let len = simd_length(e - a), d = (e - a) / len
                    var u: Float = 0
                    while u < len { dashes.append((a + d * u, a + d * min(len, u + 0.06))); u += 0.11 }
                }
            }
            if h.tint {
                let f = ModelEntity(mesh: .generatePlane(width: s, depth: s), materials: [flat(UIColor(hex: Ink.mix(paper, p.chapter.hex, 0.12)))])
                f.position = SIMD3(x + s / 2, 0.0002, z + s / 2); hints.addChild(f)
            }
        }
        if let m = Rig.lines(dashes, width: Float(Sketch.stroke) * px) {
            let e = ModelEntity(mesh: m, materials: [flat(chapter)]); e.position.y = 0.0018; hints.addChild(e)
        }
    }
}

extension UIColor {
    /// Its colour as 0xRRGGBB.
    var hexValue: UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        func byte(_ v: CGFloat) -> UInt32 { UInt32(max(0, min(255, (v * 255).rounded()))) }
        return byte(r) << 16 | byte(g) << 8 | byte(b)
    }
}

extension Color {
    /// A colour of the table (Ink) as 0xRRGGBB on light or dark paper, for what's drawn in the paper's scene.
    func hexValue(dark: Bool) -> UInt32 { UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light)).hexValue }
}
