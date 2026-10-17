import SwiftUI
import RealityKit
import simd

/// Unit cubes as a 3D lesson. The paper's grid is the floor: one cube sits on one big square.
/// It opens flat, lined up with the paper exactly; it only tilts when the squares rise into cubes.
/// Words and buttons are pinned to points on the paper, so they travel with it and always face the child.
struct UnitCubesView: View {
    let model: UnitCubesModel
    let time: Double
    let onBack: () -> Void
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1

    init(model: UnitCubesModel, time: Double, onBack: @escaping () -> Void) { self.model = model; self.time = time; self.onBack = onBack }

    var body: some View {
        let v = model.view(at: time)
        let k = v.scale / Paper.unit
        ZStack(alignment: .topLeading) {
            PaperScene3D(model: model, time: time)
            Color.clear.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 4)
                    .onChanged { g in model.pan(g.translation.width - lastDrag.width, g.translation.height - lastDrag.height); lastDrag = g.translation }
                    .onEnded { _ in lastDrag = .zero })
                .simultaneousGesture(MagnifyGesture()
                    .onChanged { g in model.zoom(g.magnification / lastPinch); lastPinch = g.magnification }
                    .onEnded { _ in lastPinch = 1 })
                .simultaneousGesture(SpatialTapGesture().onEnded { g in model.tapScreen(.init(g.location.x, g.location.y)) })
            pins(v, k)
            HStack(spacing: 20) {
                CellButton(action: onBack) { Icon(name: "arrow-left") }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Unit cubes").font(Typeface.name).foregroundStyle(Ink.ink)
                    Text("Volume · Lesson 02").font(Typeface.font(13)).foregroundStyle(Ink.ink2)
                }
            }
            .padding(.leading, 40).padding(.top, 40)
        }
    }

    @ViewBuilder private func pins(_ v: PaperView3D, _ k: Double) -> some View {
        let o = model.origin, b = model.box, L = Double(b.length), W = Double(b.width), H = Double(b.height)
        let tilt = model.tilt(at: time)
        let words = model.lesson.words
        let fresh = ease((time - model.wordsAt) / 0.5)
        let at = { (p: Vec3) -> CGPoint in let s = v.project(p, screen: model.screen); return CGPoint(x: s.x, y: s.y) }

        VStack(alignment: .leading, spacing: 0) {
            Text(words.say).font(Typeface.question).foregroundStyle(Ink.ink).frame(height: 40, alignment: .leading)
            Text(words.hint).font(Typeface.hint).foregroundStyle(Ink.ink2).frame(height: 20, alignment: .leading)
        }
        .frame(width: 480, alignment: .leading)
        .opacity(fresh).offset(y: (1 - fresh) * 8)
        .pinned(at(Vec3(o.x - 0.4 * tilt, 4.6 * tilt, o.z - 0.6 * (1 - tilt))), .bottomLeading, k)

        Text("\(b.length)").font(Typeface.label).foregroundStyle(Ink.ink).pinned(at(Vec3(o.x + L / 2, 0, o.z + W + 0.3)), .center, k)
        Text("\(b.width)").font(Typeface.label).foregroundStyle(Ink.ink).pinned(at(Vec3(o.x - 0.3, 0, o.z + W / 2)), .center, k)
        Text("\(b.height)").font(Typeface.label).foregroundStyle(Ink.ink).opacity(model.heightLabel(at: time))
            .pinned(at(Vec3(o.x + L + 0.3, H / 2, o.z + W)), .center, k)

        if model.lesson.step == .coverFloor {
            Group {
                if let m = model.message { Text(m.text).foregroundStyle(m.ok ? Ink.right : model.chapter.color) }
                else { Text(model.lesson.countLine).foregroundStyle(Ink.ink2) }
            }
            .font(Typeface.font(17, .medium)).fixedSize()
            .pinned(at(Vec3(o.x, 0, o.z + W + 0.6)), .topLeading, k)
        }

        HStack(spacing: -1.5) {
            if model.lesson.step == .coverFloor {
                CellButton(action: model.showMe) { Icon(name: "play") }
                CellButton(action: model.reset) { Icon(name: "arrow-counter-clockwise") }
                Color.clear.frame(width: 40, height: 40)
            }
            MainCellButton(title: words.action, action: model.go)
        }
        .pinned(at(Vec3(o.x, 0, o.z + W + 1)), .topLeading, k)
    }
}

extension View {
    /// Puts this view's `anchor` on a screen point, scaled with the paper.
    func pinned(_ p: CGPoint, _ anchor: UnitPoint, _ k: Double) -> some View {
        let h: HorizontalAlignment = anchor.x == 0 ? .leading : anchor.x == 1 ? .trailing : .center
        let v: VerticalAlignment = anchor.y == 0 ? .top : anchor.y == 1 ? .bottom : .center
        return fixedSize()
            .scaleEffect(k, anchor: anchor)
            .frame(width: 0, height: 0, alignment: Alignment(horizontal: h, vertical: v))
            .position(p)
    }
}

/// The RealityKit side: the floor grid, the box's dashed outline, squares and cubes.
/// Nothing animates by itself in here; every frame is read from the lesson's clock.
struct PaperScene3D: View {
    let model: UnitCubesModel
    let time: Double
    @Environment(\.colorScheme) private var scheme
    @State private var rig = Rig()

    init(model: UnitCubesModel, time: Double) { self.model = model; self.time = time }

    var body: some View {
        RealityView { content in
            content.camera = .virtual
            rig.build(into: &content, model: model, dark: scheme == .dark)
            rig.update(model: model, time: time)
        } update: { _ in
            rig.update(model: model, time: time)
        }
        .background(Ink.paper)
        .allowsHitTesting(false)
    }
}

@MainActor
final class Rig {
    let root = Entity()
    let camera = Entity()
    var grid = Entity()
    var shape: UnitCubes.Box?
    var squares: [UnitCubes.Cell: ModelEntity] = [:]
    var cubes: [(x: Int, y: Int, z: Int, e: Entity)] = []
    var outline = Entity()
    var edges: [ModelEntity] = []
    var lineScale: Double = 0
    var dark = false
    var colours = Colours(dark: false, chapter: 0xE39B00)

    init() { EdgeAxis.registerComponent() }

    struct Colours {
        let paper, minor, major, top, front, side, deep, square: UIColor
        init(dark: Bool, chapter c: UInt32) {
            let surf: UInt32 = dark ? 0x1B1B1A : 0xFBFBFA, ink: UInt32 = dark ? 0xECEBE7 : 0x1A1A19
            let paper: UInt32 = dark ? 0x121211 : 0xF3F2EF
            func m(_ a: UInt32, _ b: UInt32, _ k: Double) -> UIColor { UIColor(hex: Ink.mix(a, b, k)) }
            self.paper = UIColor(hex: paper)
            minor = m(paper, ink, dark ? 0.035 : 0.045); major = m(paper, ink, dark ? 0.07 : 0.09)
            top = m(surf, c, dark ? 0.32 : 0.30); front = m(surf, c, dark ? 0.42 : 0.42); side = m(surf, c, dark ? 0.52 : 0.55)
            deep = dark ? m(c, 0xFFFFFF, 0.25) : m(c, ink, 0.35); square = m(surf, c, dark ? 0.38 : 0.35)
        }
    }

    func build(into content: inout RealityViewCameraContent, model: UnitCubesModel, dark: Bool) {
        self.dark = dark
        colours = Colours(dark: dark, chapter: model.chapter.hex)
        camera.components.set(OrthographicCameraComponent())
        content.add(camera)
        content.add(root)
        // the paper itself, under the grid, large enough to fill any tilted view
        let sheet = ModelEntity(mesh: .generatePlane(width: 400, depth: 400), materials: [flat(colours.paper)])
        sheet.position = SIMD3(Float(model.origin.x), -0.003, Float(model.origin.z))
        root.addChild(sheet)
    }

    func update(model: UnitCubesModel, time t: Double) {
        let v = model.view(at: t)
        if shape != model.box { rebuild(model) }
        // lines keep their screen width at any zoom
        if lineScale == 0 || abs(v.scale / lineScale - 1) > 0.05 { relines(model, scale: v.scale) }

        let (dir, _, up) = v.axes
        let target = SIMD3<Float>(Float(v.target.x), Float(v.target.y), Float(v.target.z))
        let from = target + SIMD3<Float>(Float(dir.x), Float(dir.y), Float(dir.z)) * 60
        camera.look(at: target, from: from, upVector: SIMD3(Float(up.x), Float(up.y), Float(up.z)), relativeTo: nil)
        var oc = OrthographicCameraComponent()
        oc.near = 0.1; oc.far = 400
        // RealityKit's orthographic scale is half the view's height, in world units
        oc.scale = Float(model.screen.height / 2 / v.scale)
        camera.components.set(oc)

        for (c, e) in squares { let k = Float(max(0.0001, model.square(c, at: t))); e.scale = SIMD3(k, 1, k) }
        for c in cubes {
            let k = model.cube(x: c.x, y: c.y, z: c.z, at: t)
            c.e.isEnabled = k > 0
            c.e.scale = SIMD3(1, Float(max(0.0001, k)), 1)
        }
        outline.isEnabled = model.tilt(at: t) == 0 && model.lesson.layers == 0
    }

    private func rebuild(_ model: UnitCubesModel) {
        shape = model.box
        squares.values.forEach { $0.removeFromParent() }; squares = [:]
        cubes.forEach { $0.e.removeFromParent() }; cubes = []; edges = []
        let b = model.box, o = model.origin
        let sq = MeshResource.generatePlane(width: 1, depth: 1)
        for z in 0..<b.width { for x in 0..<b.length {
            let e = ModelEntity(mesh: sq, materials: [flat(colours.square)])
            e.position = SIMD3(Float(o.x) + Float(x) + 0.5, 0.001, Float(o.z) + Float(z) + 0.5)
            root.addChild(e); squares[.init(x, z)] = e
        } }
        let cube = MeshResource.generateBox(width: 1, height: 1, depth: 1, cornerRadius: 0, splitFaces: true)
        // splitFaces order: front, top, back, bottom, right, left
        let faces: [any RealityKit.Material] = [colours.front, colours.top, colours.front, colours.top, colours.side, colours.side].map { flat($0) as any RealityKit.Material }
        for y in 0..<b.height { for z in 0..<b.width { for x in 0..<b.length {
            let g = Entity()
            g.position = SIMD3(Float(o.x) + Float(x), Float(y), Float(o.z) + Float(z))
            let m = ModelEntity(mesh: cube, materials: faces); m.position = SIMD3(0.5, 0.5, 0.5); g.addChild(m)
            for e in Self.cubeEdges() { e.model?.materials = [flat(colours.deep)]; g.addChild(e); edges.append(e) }
            g.isEnabled = false
            root.addChild(g); cubes.append((x, y, z, g))
        } } }
        lineScale = 0
    }

    /// The 12 edges of a unit cube as thin bars. Their thickness is set in `relines`.
    private static func cubeEdges() -> [ModelEntity] {
        var out: [ModelEntity] = []
        let bar = MeshResource.generateBox(size: 1)
        for a in 0..<3 { for i in 0..<2 { for j in 0..<2 {
            let e = ModelEntity(mesh: bar, materials: [])
            var p = SIMD3<Float>(0.5, 0.5, 0.5)
            let (u, w) = [(1, 2), (0, 2), (0, 1)][a]
            p[u] = Float(i); p[w] = Float(j)
            e.position = p
            e.components.set(EdgeAxis(axis: a))
            out.append(e)
        } } }
        return out
    }

    private func relines(_ model: UnitCubesModel, scale: Double) {
        lineScale = scale
        let px = Float(1 / scale)
        for e in edges {
            guard let a = e.components[EdgeAxis.self]?.axis else { continue }
            var s = SIMD3<Float>(repeating: 2.5 * px); s[a] = 1 + 2.5 * px; e.scale = s
        }
        grid.removeFromParent(); outline.removeFromParent()
        grid = Entity(); outline = Entity()
        let o = model.origin, n = 16
        var minor: [(SIMD2<Float>, SIMD2<Float>)] = [], major: [(SIMD2<Float>, SIMD2<Float>)] = []
        let x0 = Float(o.x) - Float(n), x1 = Float(o.x) + Float(n), z0 = Float(o.z) - Float(n), z1 = Float(o.z) + Float(n)
        for i in -n * Paper.major...n * Paper.major {
            let d = Float(i) / Float(Paper.major)
            let lines = [(SIMD2(Float(o.x) + d, z0), SIMD2(Float(o.x) + d, z1)), (SIMD2(x0, Float(o.z) + d), SIMD2(x1, Float(o.z) + d))]
            if i % Paper.major == 0 { major += lines } else { minor += lines }
        }
        if let m = Self.lines(minor, width: px) { grid.addChild(ModelEntity(mesh: m, materials: [flat(colours.minor)])) }
        if let m = Self.lines(major, width: px) {
            let e = ModelEntity(mesh: m, materials: [flat(colours.major)]); e.position.y = 0.0005; grid.addChild(e)
        }
        // the box's floor, dashed, on the paper's strong lines
        let b = model.box, L = Float(b.length), W = Float(b.width)
        let ox = Float(o.x), oz = Float(o.z)
        var dashes: [(SIMD2<Float>, SIMD2<Float>)] = []
        for (a, c) in [(SIMD2(ox, oz), SIMD2(ox + L, oz)), (SIMD2(ox + L, oz), SIMD2(ox + L, oz + W)), (SIMD2(ox + L, oz + W), SIMD2(ox, oz + W)), (SIMD2(ox, oz + W), SIMD2(ox, oz))] {
            let len = simd_length(c - a), dirn = (c - a) / len
            var s: Float = 0
            while s < len { dashes.append((a + dirn * s, a + dirn * min(len, s + 0.08))); s += 0.14 }
        }
        if let m = Self.lines(dashes, width: 2 * px) {
            let e = ModelEntity(mesh: m, materials: [flat(colours.deep)]); e.position.y = 0.002; outline.addChild(e)
        }
        root.addChild(grid); root.addChild(outline)
    }

    /// Flat bars on the paper, one quad per line, facing up.
    static func lines(_ segs: [(SIMD2<Float>, SIMD2<Float>)], width: Float) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        for (a, b) in segs {
            let d: SIMD2<Float> = simd_normalize(b - a)
            let half: Float = width / 2
            let nrm: SIMD2<Float> = SIMD2<Float>(-d.y, d.x) * half
            let ext: SIMD2<Float> = d * half
            let a0: SIMD2<Float> = a - ext, b0: SIMD2<Float> = b + ext
            let p: [SIMD2<Float>] = [a0 + nrm, b0 + nrm, b0 - nrm, a0 - nrm]
            let base = UInt32(pos.count)
            pos += p.map { SIMD3($0.x, 0, $0.y) }
            // both windings, so the bar shows whichever way the quad turned out
            idx += [base, base + 1, base + 2, base, base + 2, base + 3, base, base + 2, base + 1, base, base + 3, base + 2]
        }
        var desc = MeshDescriptor(name: "lines")
        desc.positions = MeshBuffers.Positions(pos)
        desc.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [desc])
    }
}

struct EdgeAxis: Component { let axis: Int }

/// A plain colour with no lighting and no tone mapping, so the paper in 3D is the same colour as the flat paper.
@MainActor func flat(_ c: UIColor) -> UnlitMaterial {
    var m = UnlitMaterial(applyPostProcessToneMap: false)
    m.color = .init(tint: c)
    return m
}
