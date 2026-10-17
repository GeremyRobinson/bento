import SwiftUI
import RealityKit
import simd

/// The whole paper in one 3D scene: the grid, the lessons' pictures and, when a lesson is open, its squares and cubes.
/// One camera looks at it. Flat is that camera straight above; a 3D lesson only tilts it, so the grid never swaps or jumps.
/// Words and buttons are drawn on top as normal text, pinned to the paper.
struct PaperScene: View {
    let model: PaperModel
    let time: Double
    @Environment(\.colorScheme) private var scheme
    @State private var rig = Rig()

    init(model: PaperModel, time: Double) { self.model = model; self.time = time }

    var body: some View {
        let view = model.view(at: time)
        // read light or dark here, in the body, so switching it redraws the scene (read only inside the closures,
        // SwiftUI never knew the scene depended on it, and the paper stayed light when the words went dark)
        let dark = scheme == .dark
        RealityView { content in
            content.camera = .virtual
            rig.build(into: &content)
            rig.update(view: view, model: model, time: time, dark: dark)
        } update: { _ in
            Perf.time("scene") { rig.update(view: view, model: model, time: time, dark: dark) }
        }
        .background(Ink.paper)
        .allowsHitTesting(false)
    }
}

/// A lesson's picture as lines on the grid, in paper points, in the order they draw themselves in.
extension Piece {
    /// The picture, centred in its frame to the nearest whole cell (so it stays on the grid). A box seen in 3D can't
    /// sit on the grid's lines, so it's centred exactly.
    var strokes: [[CGPoint]] {
        let lines = drawing, pts = lines.flatMap { $0 }
        guard let x0 = pts.map(\.x).min(), let x1 = pts.map(\.x).max(), let y0 = pts.map(\.y).min(), let y1 = pts.map(\.y).max() else { return lines }
        let c = isBox ? 0.001 : Paper.cell, f = frame
        let dx = ((f.mid.x - (x0 + x1) / 2) / c).rounded() * c, dy = ((f.mid.y - (y0 + y1) / 2) / c).rounded() * c
        return lines.map { $0.map { CGPoint(x: $0.x + dx, y: $0.y + dy) } }
    }

    /// The lessons whose picture is a box of cubes, drawn as the 3D lesson shows it.
    private var isBox: Bool { id == "uc" || id == "g5-volume" }

    /// A box `l` long, `h` tall and `w` wide, seen from the tilted 3D lesson's own angle (PaperView3D.tilted), `u`
    /// points to a cube: the top, the front and the left side, as the cubes show when the paper tilts.
    private func box3D(l: Double, h: Double, w: Double, u: Double) -> [[CGPoint]] {
        let (_, right, up) = PaperView3D(elevation: PaperView3D.tilted.elevation, azimuth: PaperView3D.tilted.azimuth).axes
        func P(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
            let v = Vec3(x, y, z)
            return CGPoint(x: at.x + v.dot(right) * u, y: at.y - v.dot(up) * u)
        }
        let top = [P(0, h, 0), P(l, h, 0), P(l, h, w), P(0, h, w), P(0, h, 0)]
        let front = [P(0, h, w), P(0, 0, w), P(l, 0, w), P(l, h, w)]
        let left = [P(0, h, 0), P(0, 0, 0), P(0, 0, w)]
        // the cubes' own lines: across the top and down the front and the side
        var cuts: [[CGPoint]] = []
        for i in stride(from: 1.0, to: l, by: 1) { cuts += [[P(i, h, 0), P(i, h, w), P(i, 0, w)]] }
        for k in stride(from: 1.0, to: w, by: 1) { cuts += [[P(l, h, k), P(0, h, k), P(0, 0, k)]] }
        for j in stride(from: 1.0, to: h, by: 1) { cuts += [[P(0, j, 0), P(0, j, w), P(l, j, w)]] }
        return [top, front, left] + cuts
    }

    /// The picture as it's drawn, before centring, in cells from the frame's corner. The frame is 15 cells by 10, so its
    /// middle is in the middle of a cell across and on a line down: every picture is an odd number of cells wide and an
    /// even number tall, so centring it keeps every corner on the grid's lines (G 17 Oct).
    private var drawing: [[CGPoint]] {
        let c = Paper.cell
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: at.x + x * c, y: at.y + y * c) }
        func box(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> [CGPoint] { [P(x, y), P(x + w, y), P(x + w, y + h), P(x, y + h), P(x, y)] }
        func line(_ pts: (Double, Double)...) -> [CGPoint] { pts.map { P($0.0, $0.1) } }
        /// A bar `w` cells long and two tall, cut into `parts`.
        func bar(_ x: Double, _ y: Double, _ w: Double, _ parts: Int) -> [[CGPoint]] {
            [box(x, y, w, 2)] + (1..<max(1, parts)).map { i in let cx = x + w * Double(i) / Double(parts); return line((cx, y), (cx, y + 2)) }
        }
        func arc(_ x0: Double, _ x1: Double, _ y: Double, _ h: Double) -> [CGPoint] {
            (0...12).map { s in let f = Double(s) / 12; return P(x0 + (x1 - x0) * f, y - sin(.pi * f) * h) }
        }
        switch id {
        case "uc": // one cube, as the lesson's cubes look when the paper tilts
            return box3D(l: 1, h: 1, w: 1, u: 70)
        case "g5-volume": // a box of cubes, 4 by 3 by 2, as the lesson shows it
            return box3D(l: 4, h: 2, w: 3, u: 32)
        case "ad": // fourths over eighths, and the eighth waiting to be added: 11 by 6
            return bar(0, 0, 8, 4) + bar(0, 4, 8, 8) + [box(10, 4, 1, 2)]
        case "add": // thirds and thirds, added: 9 by 6
            return bar(0, 0, 9, 3) + bar(0, 4, 9, 3)
        case "sub": // thirds over ninths: 9 by 6
            return bar(0, 0, 9, 3) + bar(0, 4, 9, 9)
        case "mix": // thirds, ninths, thirds: 9 by 8
            return bar(0, 0, 9, 3) + bar(0, 3, 9, 9) + bar(0, 6, 9, 3)
        case "g5-improper": // two wholes and a third, each cut into fourths: 9 by 6
            return bar(0, 0, 4, 4) + bar(5, 0, 4, 4) + bar(0, 4, 4, 4)
        case "g5-fracof": // a bar cut into thirds, and two of them bracketed: 9 by 4
            return bar(0, 0, 9, 3) + [line((0, 3), (0, 4), (6, 4), (6, 3))]
        case "g5-multfrac": // a rectangle cut into rows and columns: 9 by 6
            return [box(0, 0, 9, 6), line((3, 0), (3, 6)), line((6, 0), (6, 6)), line((0, 2), (9, 2)), line((0, 4), (9, 4))]
        case "g5-unitdiv": // three wholes, each cut into thirds: 11 by 2
            return bar(0, 0, 3, 3) + bar(4, 0, 3, 3) + bar(8, 0, 3, 3)
        case "g5-pow10", "g5-divdec": // digit boxes and the point hopping right over one: 11 by 4
            return (0..<4).map { i in box(Double(i) * 3, 2, 2, 2) } + [arc(2.5, 5.5, 2, 2)]
        case "g5-round": // tenths on a number line and a hop up to the next whole: 11 by 4
            var out: [[CGPoint]] = [line((0, 3), (11, 3)), line((10.5, 2.5), (11, 3), (10.5, 3.5))]
            for i in [0.0, 5, 10] { out.append(line((i, 2), (i, 4))) }
            for i in 1..<10 where i != 5 { out.append(line((Double(i), 2.5), (Double(i), 3.5))) }
            out.append(arc(7, 10, 2, 2))
            return out
        case "g5-adddec": // two numbers lined up at the point, and the line under them: 9 by 6
            var out: [[CGPoint]] = []
            for j in 0..<2 { for x in [1.0, 3, 6] { out.append(box(x, Double(j) * 3, 2, 2)) } }
            out.append(line((0, 6), (9, 6)))
            return out
        case "g5-multdec", "g5-mult2": // an area model: a rectangle split into parts: 9 by 6
            return [box(0, 0, 9, 6), line((6, 0), (6, 6))] + (id == "g5-multdec" ? [line((0, 4), (9, 4))] : [])
        case "g5-divide": // the long division bracket, and the number under it: 9 by 4
            return [line((0, 0), (9, 0)), line((0, 0), (1, 2), (0, 4)), line((3, 2), (7, 2))]
        case "g5-order": // parentheses around two numbers: 9 by 4
            return [line((1, 0), (0, 2), (1, 4)), line((8, 0), (9, 2), (8, 4)), box(2, 1, 2, 2), box(5, 1, 2, 2)]
        case "g5-units": // a ruler: 9 by 2
            var out: [[CGPoint]] = [box(0, 0, 9, 2)]
            for i in 1..<9 { out.append(line((Double(i), 0), (Double(i), i % 4 == 0 ? 1.5 : 0.75))) }
            return out
        default:
            return [box(0, 0, 9, 6)]
        }
    }

    var outline: [[CGPoint]] {
        [[CGPoint(x: at.x, y: at.y), CGPoint(x: at.x + Piece.size.width, y: at.y), CGPoint(x: at.x + Piece.size.width, y: at.y + Piece.size.height),
          CGPoint(x: at.x, y: at.y + Piece.size.height), CGPoint(x: at.x, y: at.y)]]
    }
}

/// A draw-in amount rounded to one of `steps` steps. Drawn with the same value its cache key holds, so the last step
/// is drawn whole: drawing the unrounded value left a gap where an outline was cached just short of finishing.
func snapped(_ k: Double, _ steps: Double) -> Double { (k * steps).rounded() / steps }

/// The first `k` (0...1) of some lines, by length, as world segments (paper points / one big square).
func drawn(_ lines: [[CGPoint]], _ k: Double) -> [(SIMD2<Float>, SIMD2<Float>)] {
    var segs: [(CGPoint, CGPoint)] = []
    for l in lines { for i in 1..<l.count { segs.append((l[i - 1], l[i])) } }
    let total = segs.reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
    var left = total * min(1, max(0, k))
    var out: [(SIMD2<Float>, SIMD2<Float>)] = []
    func w(_ p: CGPoint) -> SIMD2<Float> { SIMD2(Float(p.x / Paper.unit), Float(p.y / Paper.unit)) }
    for (a, b) in segs where left > 0.01 {
        let len = hypot(b.x - a.x, b.y - a.y), f = min(1, left / len)
        out.append((w(a), w(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))))
        left -= len
    }
    return out
}

@MainActor
final class Rig {
    let root = Entity()
    let camera = Entity()
    let sheet = ModelEntity()
    var grid = Entity()
    var gridAt: (x: Int, z: Int, half: Int)?
    let pieces = Entity()
    var piecesKey = ""
    // the map's words, in the scene (PaperWords.swift)
    let words = Entity()
    var wordsKey = ""
    var pieceWords: [String: Entity] = [:]
    var pieceWordsK: [String: Double] = [:]
    let start = Entity()
    var startKey = ""
    // the lesson page's words, in the scene (ProblemWords.swift)
    let pageWords = Entity()
    // Unit cubes' words, standing in the scene (CubesWords.swift)
    let cubesQuestion = Pin(), cubesL = Pin(), cubesW = Pin(), cubesH = Pin(), cubesCount = Pin(), cubesBlocks = Pin()
    var cubesKey = ""
    var problemWords: [UUID: ProblemWords] = [:]
    var piecesQuick = ""
    var pieceGroups: [String: ModelEntity] = [:]
    // the open lesson
    let lessonRoot = Entity()
    weak var lesson: UnitCubesModel?
    var shape: (box: UnitCubes.Box, origin: Vec3)?
    var squares: [UnitCubes.Cell: ModelEntity] = [:]
    var cubes: [(x: Int, y: Int, z: Int, e: Entity)] = []
    var outline = Entity()
    var edges: [ModelEntity] = []
    /// Cubes still to be made, a few per frame; the box mesh and the edges mesh every cube shares.
    var pendingCubes: [(Int, Int, Int)] = []
    var cubeMesh: MeshResource?
    var edgeMesh: MeshResource?
    /// Hints on the floor: the empty squares outlined (and tinted), rebuilt when they change.
    var hints = Entity()
    var hintKey = ""
    // the flat lesson
    let barsRoot = Entity()
    var drawers: [UUID: BarsDrawer] = [:]
    let boxes = Entity()
    var boxesKey = ""
    var paperHex: UInt32 = 0xF3F2EF
    // a lesson worked in steps: its picture
    let stepsRoot = Entity()
    var stepsKey = ""
    var lineScale: Double = 0
    var dark: Bool?
    var colours = Colours(dark: false, chapter: Chapter.measurement.hex)


    struct Colours {
        let paper, minor, major, top, front, side, deep, square, ink, ink2, lineStrong, pencil: UIColor
        init(dark: Bool, chapter c: UInt32) {
            let surf: UInt32 = dark ? 0x1B1B1A : 0xFBFBFA, ink: UInt32 = dark ? 0xECEBE7 : 0x1A1A19
            let paper: UInt32 = dark ? 0x121211 : 0xF3F2EF
            func m(_ a: UInt32, _ b: UInt32, _ k: Double) -> UIColor { UIColor(hex: Ink.mix(a, b, k)) }
            self.paper = UIColor(hex: paper)
            minor = m(paper, ink, dark ? 0.035 : 0.045); major = m(paper, ink, dark ? 0.07 : 0.09)
            top = m(surf, c, dark ? 0.32 : 0.30); front = m(surf, c, dark ? 0.42 : 0.42); side = m(surf, c, dark ? 0.52 : 0.55)
            deep = dark ? m(c, 0xFFFFFF, 0.25) : m(c, ink, 0.35); square = m(surf, c, dark ? 0.38 : 0.35)
            self.ink = UIColor(hex: ink); ink2 = UIColor(hex: dark ? 0xA3A19B : 0x6B6964)
            lineStrong = UIColor(hex: dark ? 0x3A3A37 : 0xCFCCC5); pencil = UIColor(hex: dark ? 0x3D3C39 : 0xCFCCC5)
        }
    }

    func build(into content: inout RealityViewCameraContent) {
        camera.components.set(OrthographicCameraComponent())
        content.add(camera)
        content.add(root)
        // the paper itself, under the grid, large enough to fill any tilted view; it follows the camera
        sheet.model = ModelComponent(mesh: .generatePlane(width: 400, depth: 400), materials: [])
        sheet.position.y = -0.003
        root.addChild(sheet); root.addChild(pieces); root.addChild(lessonRoot); root.addChild(barsRoot); root.addChild(stepsRoot); barsRoot.addChild(boxes); barsRoot.addChild(pageWords); root.addChild(words)
    }

    func update(view v: PaperView3D, model: PaperModel, time t: Double, dark: Bool) {
        if dark != self.dark { recolour(dark) }
        let screen = model.screen

        let (dir, _, up) = v.axes
        let target = SIMD3<Float>(Float(v.target.x), Float(v.target.y), Float(v.target.z))
        let from = target + SIMD3<Float>(Float(dir.x), Float(dir.y), Float(dir.z)) * 60
        camera.look(at: target, from: from, upVector: SIMD3(Float(up.x), Float(up.y), Float(up.z)), relativeTo: nil)
        var oc = OrthographicCameraComponent()
        oc.near = 0.1; oc.far = 400
        // RealityKit's orthographic scale is half the view's height, in world units
        oc.scale = Float(screen.height / 2 / v.scale)
        camera.components.set(oc)

        let floor = v.floorTarget
        sheet.position.x = Float(floor.x); sheet.position.z = Float(floor.z)

        // a lesson that ends is only hidden: deleting hundreds of pieces as the paper comes back makes it stall
        if model.lesson !== lesson { lesson = model.lesson }
        lessonRoot.isEnabled = lesson != nil

        // lines keep their screen width at any zoom
        if lineScale == 0 || abs(v.scale / lineScale - 1) > 0.05 { lineScale = v.scale; gridAt = nil; piecesKey = ""; relines() }
        // enough grid to fill the screen even when tilted, centred on a strong line near the middle
        let half = min(120, Int((hypot(screen.width, screen.height) / 2 / v.scale / sin(.pi / 4)).rounded(.up)) + 3)
        let gx = Int(floor.x.rounded()), gz = Int(floor.z.rounded())
        if let g = gridAt, abs(g.x - gx) <= 2, abs(g.z - gz) <= 2, g.half >= half {} else { Perf.time("grid") { regrid(x: gx, z: gz, half: half) } }

        let onMap = model.lesson == nil && model.bars == nil && model.steps == nil
        pieces.isEnabled = onMap; words.isEnabled = onMap
        if onMap { Perf.time("pieces") { drawPieces(model, at: t) }; Perf.time("words") { drawWords(model, at: t) } }
        drawPage(model.bars, at: t)
        drawSteps(model.steps, at: t)

        guard let l = lesson else { return }
        // the last lesson's pieces are reused when the box is the same; otherwise cleared now, while the new one builds
        if shape?.box != l.box || shape?.origin != l.origin { Perf.time("cubes-build") { rebuild(l) } }
        if !pendingCubes.isEmpty { Perf.time("cubes-some") { buildCubes(l, count: l.instant ? .max : 6) } }
        for (c, e) in squares { let k = Float(max(0.0001, l.square(c, at: t))); e.scale = SIMD3(k, 1, k) }
        drawHints(l)
        for c in cubes {
            let k = l.cube(x: c.x, y: c.y, z: c.z, at: t)
            c.e.isEnabled = k > 0
            c.e.scale = SIMD3(1, Float(max(0.0001, k)), 1)
        }
        outline.isEnabled = l.tilt(at: t) == 0 && l.layers == 0
        Perf.time("cubes-words") { drawCubesWords(l, view: v, at: t) }
    }

    private func recolour(_ dark: Bool) {
        wordsKey = ""; cubesKey = ""
        self.dark = dark
        colours = Colours(dark: dark, chapter: Chapter.measurement.hex)
        paperHex = dark ? 0x121211 : 0xF3F2EF
        sheet.model?.materials = [flat(colours.paper)]
        problemWords.values.forEach { $0.key = "" }
        gridAt = nil; piecesKey = ""; shape = nil; stepsKey = ""; drawers.values.forEach { $0.barsKey = "" }
        relines()
    }

    // MARK: the paper

    private func regrid(x cx: Int, z cz: Int, half n: Int) {
        gridAt = (cx, cz, n)
        grid.removeFromParent(); grid = Entity()
        let px = Float(1 / lineScale)
        var minor: [(SIMD2<Float>, SIMD2<Float>)] = [], major: [(SIMD2<Float>, SIMD2<Float>)] = []
        let x0 = Float(cx - n), x1 = Float(cx + n), z0 = Float(cz - n), z1 = Float(cz + n)
        for i in -n * Paper.major...n * Paper.major {
            let d = Float(i) / Float(Paper.major)
            let lines = [(SIMD2(Float(cx) + d, z0), SIMD2(Float(cx) + d, z1)), (SIMD2(x0, Float(cz) + d), SIMD2(x1, Float(cz) + d))]
            if i % Paper.major == 0 { major += lines } else { minor += lines }
        }
        if let m = Self.lines(minor, width: px) { grid.addChild(ModelEntity(mesh: m, materials: [flat(colours.minor)])) }
        if let m = Self.lines(major, width: px) {
            let e = ModelEntity(mesh: m, materials: [flat(colours.major)]); e.position.y = 0.0005; grid.addChild(e)
        }
        root.addChild(grid)
    }

    /// Each lesson's frame and picture, drawn in as far as it has got; rebuilt only when something changed.
    private func drawPieces(_ model: PaperModel, at t: Double) {
        // one mesh per colour and line width (frames, the chosen frame, each chapter's pictures, pencil), so drawing in
        // or zooming rebuilds a handful of meshes, not two per lesson
        let px = 1 / lineScale
        // once the drawings have drawn in, only a new choice, zoom or learned lesson changes them: skip the rest
        let gone = snapped(model.mapGone(at: t), 40)
        let settled = t - model.drawnAt > Piece.drawTime + 1, quick = "\(model.selected?.id ?? "") \(lineScale) \(Progress.shared.checks.count) \(gone)"
        if settled, quick == piecesQuick, !piecesKey.isEmpty { return }
        piecesQuick = settled ? quick : ""
        let now = Map.pieces.map { p in (p, snapped(Piece.drawIn(p, time: t, drawnAt: model.drawnAt, from: model.drawFrom), 400) * gone, model.selected?.id == p.id, p.state) }
        let key = now.map { "\($0.1) \($0.2) \($0.3)" }.joined(separator: ",")
        guard key != piecesKey else { return }
        piecesKey = key
        var groups: [String: (colour: UIColor, width: Double, y: Float, segs: [(SIMD2<Float>, SIMD2<Float>)])] = [:]
        func add(_ id: String, _ c: UIColor, _ w: Double, _ y: Float, _ segs: [(SIMD2<Float>, SIMD2<Float>)]) {
            groups[id, default: (c, w, y, [])].segs += segs
        }
        var tints: [String: (colour: UIColor, rects: [CGRect])] = [:]
        for (p, k, on, state) in now {
            // the chosen lesson, and the one up next, are outlined in their chapter's colour
            let lit = on || state == .now
            // the others' frames are their chapter's colour too, lighter: no grey on the map
            let frameColour = lit ? UIColor(hex: p.chapter.hex) : UIColor(hex: Ink.mix(paperHex, p.chapter.hex, 0.3))
            add("frame-\(p.chapter.rawValue)-\(lit)-\(on)", frameColour, on ? 2 : 1.5, 0.001, drawn(p.outline, k))
            // a light fill in the chapter's colour, coming in with the drawing
            let strength = (k * 10).rounded() / 10 * 0.1
            if strength > 0 {
                let id = "tint-\(p.chapter.rawValue)-\(strength)"
                tints[id, default: (UIColor(hex: Ink.mix(paperHex, p.chapter.hex, strength)), [])].rects.append(CGRect(x: p.at.x, y: p.at.y, width: Piece.size.width, height: Piece.size.height))
            }
            // a lesson not yet open is drawn in its chapter's colour, lightened, instead of grey pencil (G 17 Oct)
            if state == .notYet { add("light-\(p.chapter.rawValue)", UIColor(hex: Ink.mix(paperHex, p.chapter.hex, 0.4)), 2.5, 0.0015, drawn(p.strokes, k)) }
            else { add("chapter-\(p.chapter.rawValue)", UIColor(hex: p.chapter.hex), 2.5, 0.0015, drawn(p.strokes, k)) }
        }
        for (id, e) in pieceGroups where groups[id] == nil && tints[id] == nil { e.isEnabled = false }
        for (id, t) in tints {
            let e = pieceGroups[id] ?? { let e = ModelEntity(); pieces.addChild(e); pieceGroups[id] = e; return e }()
            e.position.y = 0.0003  // under the strong lines, like the floor squares
            set(e, Self.fills(t.rects), t.colour)
        }
        for (id, g) in groups {
            let e = pieceGroups[id] ?? { let e = ModelEntity(); pieces.addChild(e); pieceGroups[id] = e; return e }()
            e.position.y = g.y
            set(e, Self.lines(g.segs, width: Float(g.width * px)), g.colour)
        }
    }

    private func set(_ e: ModelEntity, _ mesh: MeshResource?, _ c: UIColor) {
        guard let mesh else { e.isEnabled = false; return }
        e.model = ModelComponent(mesh: mesh, materials: [flat(c)]); e.isEnabled = true
    }

    // MARK: the flat lesson

    /// A lesson's page: one drawer per problem (and the How to), each with its own bars.
    private func drawPage(_ page: BarsPage?, at t: Double) {
        barsRoot.isEnabled = page != nil
        guard let page else {
            for d in drawers.values { d.root.removeFromParent() }
            drawers = [:]; boxesKey = ""
            for w in problemWords.values { w.root.removeFromParent() }
            problemWords = [:]; return
        }
        let shown = page.all, every = page.all + (page.howToGone ? [] : page.problems)
        // the problems' bars are built one a frame while the How to plays, unseen (they haven't grown in), so nothing
        // is built when they arrive (building all 17 at once stalled a frame for 170 ms; 16 as they arrived, 80 ms)
        var made = 0
        for m in every {
            if drawers[m.id] == nil {
                if made >= 1 && !m.instant && m !== page.howTo { continue }
                made += 1
            }
            let d = drawers[m.id] ?? { let d = BarsDrawer(rig: self); barsRoot.addChild(d.root); drawers[m.id] = d; return d }()
            d.draw(m, at: t)
        }
        for (id, d) in drawers where !every.contains(where: { $0.id == id }) { d.root.removeFromParent(); drawers[id] = nil }
        Perf.time("boxes") { drawBoxes(page, shown, at: t) }
        Perf.time("page-words") { drawProblemWords(page, shown, waiting: page.showing || made > 0 ? [] : page.problems, at: t) }
    }

    /// Every problem's box (G 17 Oct): a light outline in the chapter's colour, drawing in with its problem; the problem
    /// the child is on outlined in full colour, thicker; a solved one lightly filled, as a learned lesson is on the map.
    private func drawBoxes(_ page: BarsPage, _ shown: [AddFractionsModel], at t: Double) {
        let chapter = page.piece.chapter.hex, px = 1 / lineScale
        let ks = shown.map { (m: $0, k: snapped($0.wholeLine(at: t), 40)) }
        let key = ks.map { "\($0.k)\($0.m.solved)" }.joined() + "\(page.current?.id.uuidString ?? "") \(lineScale) \(paperHex)"
        guard key != boxesKey else { return }
        boxesKey = key
        for c in Array(boxes.children) { c.removeFromParent() }
        func outline(_ r: Rect) -> [[CGPoint]] {
            [[CGPoint(x: r.x, y: r.y), CGPoint(x: r.x + r.width, y: r.y), CGPoint(x: r.x + r.width, y: r.y + r.height), CGPoint(x: r.x, y: r.y + r.height), CGPoint(x: r.x, y: r.y)]]
        }
        var light: [(SIMD2<Float>, SIMD2<Float>)] = [], lit: [(SIMD2<Float>, SIMD2<Float>)] = [], solved: [CGRect] = []
        for (m, k) in ks where k > 0 {
            let r = BarsPage.box(of: m)
            if m === page.current { lit += drawn(outline(r), k) } else { light += drawn(outline(r), k) }
            if m.solved && !m.auto { solved.append(CGRect(x: r.x, y: r.y, width: r.width, height: r.height)) }
        }
        func add(_ mesh: MeshResource?, _ c: UInt32, _ y: Float) {
            guard let mesh else { return }
            let e = ModelEntity(mesh: mesh, materials: [flat(UIColor(hex: c))]); e.position.y = y; boxes.addChild(e)
        }
        add(Self.fills(solved), Ink.mix(paperHex, chapter, 0.08), 0.0003)
        add(Self.lines(light, width: Float(1.5 * px)), Ink.mix(paperHex, chapter, 0.3), 0.001)
        add(Self.lines(lit, width: Float(2.5 * px)), chapter, 0.0011)
    }

    // MARK: a lesson worked in steps

    /// The picture of a lesson worked in steps, drawn by its master. Rebuilt only when it changes.
    private func drawSteps(_ m: StepsModel?, at t: Double) {
        stepsRoot.isEnabled = m != nil
        guard let m else { stepsKey = ""; return }
        switch m.lesson.spec.master {
        case "shift": drawShift(m, at: t)
        default: break
        }
    }

    /// The decimal shift: digit boxes, the hops drawn so far, and the point.
    private func drawShift(_ m: StepsModel, at t: Double) {
        let s = ShiftPicture(m.lesson.numbers), grow = snapped(m.grow(at: t), 20)
        let h = snapped(s.hops(m.sincePicture(t), moving: m.lesson.picture["hop"] == 1), 40)
        let key = "\(m.lesson.numbers) \(h) \(grow) \(lineScale)"
        guard key != stepsKey else { return }
        stepsKey = key
        for c in Array(stepsRoot.children) { c.removeFromParent() }
        guard grow > 0 else { return }
        let o = m.origin, chapter = UIColor(hex: m.chapter.hex), u = Paper.unit
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x, y: o.y + y) }
        func add(_ lines: [[CGPoint]], width: Double, _ c: UIColor) {
            guard let mesh = Self.lines(drawn(lines, 1), width: Float(width / lineScale)) else { return }
            let e = ModelEntity(mesh: mesh, materials: [flat(c)]); e.position.y = 0.0012; stepsRoot.addChild(e)
        }
        let boxes = s.digits.indices.filter { s.shows($0, hops: h) }.map { i -> [CGPoint] in
            let x = s.boxX(i), y = ShiftPicture.top, b = ShiftPicture.box
            return [P(x, y), P(x + b, y), P(x + b, y + b), P(x, y + b), P(x, y)]
        }
        add(boxes, width: 1.5, colours.lineStrong)
        add(s.arcs(h).map { $0.map { P($0.x, $0.y) } }, width: 2, chapter)
        // the point: a dot in the chapter's colour
        let p = s.point(h), d = Float(10 / u)
        let dot = ModelEntity(mesh: .generatePlane(width: d, depth: d, cornerRadius: d / 2), materials: [flat(chapter)])
        dot.position = SIMD3(Float((o.x + p.x) / u), 0.0016, Float((o.y + p.y) / u))
        stepsRoot.addChild(dot)
    }

    // MARK: the open lesson

    /// Hints on the floor (LESSONS.md §7): after a miss the empty squares are outlined; after a second, tinted too.
    private func drawHints(_ l: UnitCubesModel) {
        let p = l.lesson.picture, b = l.box, o = l.origin
        let empty = (0..<b.floor).filter { l.lesson.marks[$0] == nil }
        let key = "\(p["empty"] ?? 0) \(p["tint"] ?? 0) \(empty) \(lineScale)"
        guard key != hintKey else { return }
        hintKey = key
        hints.removeFromParent(); hints = Entity(); lessonRoot.addChild(hints)
        guard p["empty"] == 1, l.lesson.step.task != nil else { return }
        let chapter = UIColor(hex: l.chapter.hex), px = Float(1 / lineScale), inset: Float = 0.06
        var dashes: [(SIMD2<Float>, SIMD2<Float>)] = []
        for i in empty {
            let c = UnitCubes.cell(i, in: b), x = Float(o.x) + Float(c.x) + inset, z = Float(o.z) + Float(c.z) + inset, s = 1 - 2 * inset
            for (a, e) in [(SIMD2(x, z), SIMD2(x + s, z)), (SIMD2(x + s, z), SIMD2(x + s, z + s)), (SIMD2(x + s, z + s), SIMD2(x, z + s)), (SIMD2(x, z + s), SIMD2(x, z))] {
                let len = simd_length(e - a), d = (e - a) / len
                var u: Float = 0
                while u < len { dashes.append((a + d * u, a + d * min(len, u + 0.06))); u += 0.11 }
            }
            if p["tint"] == 1 {
                let f = ModelEntity(mesh: .generatePlane(width: s, depth: s), materials: [flat(UIColor(hex: Ink.mix(paperHex, l.chapter.hex, 0.12)))])
                f.position = SIMD3(x + s / 2, 0.0002, z + s / 2); hints.addChild(f)
            }
        }
        if let m = Self.lines(dashes, width: 2 * px) {
            let e = ModelEntity(mesh: m, materials: [flat(chapter)]); e.position.y = 0.0018; hints.addChild(e)
        }
    }

    private func clearLesson() {
        for c in Array(lessonRoot.children) { c.removeFromParent() }
        squares = [:]; cubes = []; edges = []; outline = Entity(); hintKey = ""; pendingCubes = []
    }

    private func rebuild(_ l: UnitCubesModel) {
        clearLesson()
        shape = (l.box, l.origin)
        let b = l.box, o = l.origin
        let sq = MeshResource.generatePlane(width: 1, depth: 1)
        for z in 0..<b.width { for x in 0..<b.length {
            let e = ModelEntity(mesh: sq, materials: [flat(colours.square)])
            e.position = SIMD3(Float(o.x) + Float(x) + 0.5, 0.0003, Float(o.z) + Float(z) + 0.5)  // under the strong lines, so each big square shows
            lessonRoot.addChild(e); squares[.init(x, z)] = e
        } }
        // the cubes are made a few per frame while the child reads the question, not all at once (it took 130 ms)
        pendingCubes = []
        for y in 0..<b.height { for z in 0..<b.width { for x in 0..<b.length { pendingCubes.append((x, y, z)) } } }
        relines()
    }

    /// Makes up to `count` of the cubes still to come: each is a group (which rises), its faces, and its edges, whose
    /// mesh every cube shares.
    private func buildCubes(_ l: UnitCubesModel, count: Int) {
        let o = l.origin
        if cubeMesh == nil { cubeMesh = MeshResource.generateBox(width: 1, height: 1, depth: 1, cornerRadius: 0, splitFaces: true) }
        if edgeMesh == nil { edgeMesh = Self.cubeEdges(width: Float(2.5 / lineScale)) }
        // splitFaces order: front, top, back, bottom, right, left
        let faces: [any RealityKit.Material] = [colours.front, colours.top, colours.front, colours.top, colours.side, colours.side].map { flat($0) as any RealityKit.Material }
        for (x, y, z) in pendingCubes.prefix(count) {
            let g = Entity()
            g.position = SIMD3(Float(o.x) + Float(x), Float(y), Float(o.z) + Float(z))
            let m = ModelEntity(mesh: cubeMesh!, materials: faces); m.position = SIMD3(0.5, 0.5, 0.5); g.addChild(m)
            if let edgeMesh { let e = ModelEntity(mesh: edgeMesh, materials: [flat(colours.deep)]); g.addChild(e); edges.append(e) }
            g.isEnabled = false
            lessonRoot.addChild(g); cubes.append((x, y, z, g))
        }
        pendingCubes.removeFirst(min(count, pendingCubes.count))
    }

    /// The 12 edges of a unit cube, as thin bars of the given width, in one mesh.
    static func cubeEdges(width w: Float) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let h = w / 2
        for a in 0..<3 { for i in 0..<2 { for j in 0..<2 {
            let (u, v) = [(1, 2), (0, 2), (0, 1)][a]
            var lo = SIMD3<Float>(repeating: 0), hi = SIMD3<Float>(repeating: 0)
            lo[u] = Float(i) - h; hi[u] = Float(i) + h; lo[v] = Float(j) - h; hi[v] = Float(j) + h; lo[a] = -h; hi[a] = 1 + h
            let base = UInt32(pos.count)
            for k in 0..<8 { pos.append(SIMD3(k & 1 == 0 ? lo.x : hi.x, k & 2 == 0 ? lo.y : hi.y, k & 4 == 0 ? lo.z : hi.z)) }
            // six faces, both windings, so the bar shows from any side
            for f in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]] {
                let q = f.map { base + UInt32($0) }
                idx += [q[0], q[1], q[2], q[0], q[2], q[3], q[0], q[2], q[1], q[0], q[3], q[2]]
            }
        } } }
        var desc = MeshDescriptor(name: "edges")
        desc.positions = MeshBuffers.Positions(pos)
        desc.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [desc])
    }

    /// The lesson's lines at the current zoom: cube edges and the box's dashed floor.
    private func relines() {
        guard lineScale > 0 else { return }
        let px = Float(1 / lineScale)
        if !edges.isEmpty || edgeMesh != nil {
            edgeMesh = Self.cubeEdges(width: 2.5 * px)
            if let edgeMesh { for e in edges { e.model?.mesh = edgeMesh } }
        }
        guard let l = lesson else { return }
        outline.removeFromParent(); outline = Entity()
        // the box's floor, dashed, on the paper's strong lines
        let o = l.origin, b = l.box, L = Float(b.length), W = Float(b.width)
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
        lessonRoot.addChild(outline)
    }

    /// Filled rectangles on the paper (paper points), one quad each, facing up.
    static func fills(_ rects: [CGRect]) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let u = Paper.unit
        for r in rects {
            let base = UInt32(pos.count)
            pos += [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
                .map { SIMD3(Float($0.x / u), 0, Float($0.y / u)) }
            idx += [base, base + 1, base + 2, base, base + 2, base + 3, base, base + 2, base + 1, base, base + 3, base + 2]
        }
        guard !pos.isEmpty else { return nil }
        var desc = MeshDescriptor(name: "fills")
        desc.positions = MeshBuffers.Positions(pos)
        desc.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [desc])
    }

    /// Flat bars on the paper, one quad per line, facing up.
    static func lines(_ segs: [(SIMD2<Float>, SIMD2<Float>)], width: Float) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        for (a, b) in segs where simd_distance(a, b) > 0 {
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
        guard !pos.isEmpty else { return nil }
        var desc = MeshDescriptor(name: "lines")
        desc.positions = MeshBuffers.Positions(pos)
        desc.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [desc])
    }
}


/// A plain colour with no lighting and no tone mapping, so the paper in 3D is the same colour as the flat paper.
/// The bars of one problem on a lesson's page: a row of a-ths over a row of b-ths, the piece waiting to be added, and the
/// lines around them. Rebuilt only for a new problem or zoom; each frame only what moved changes.
@MainActor
final class BarsDrawer {
    unowned let rig: Rig
    let root = Entity()
    var barsKey = ""
    var bars: [(row: Int, i: Int, group: Entity, fill: ModelEntity, outline: ModelEntity)] = []
    var barLevel: [String: Double] = [:]
    /// The line between two filled pieces of a row, keyed "row-i" for the line on piece i's left edge.
    var seams: [String: ModelEntity] = [:]
    var seamLevel: [String: Double] = [:]
    var decor = Entity()
    var decorKey = ""

    init(rig: Rig) { self.rig = rig }

    /// The bars: a row of a-ths over a row of b-ths, and the piece waiting to be added. Rebuilt only for a new problem or zoom.
    func draw(_ b: AddFractionsModel, at t: Double) {
        let s = b.problem
        // zoom isn't in it: the bars' lines are paper-sized and scale with the paper, like the words, so zooming never
        // rebuilds them (rebuilding all 17 at every step of a zoom made it stall)
        let key = "\(s.a) \(s.p) \(s.b) \(s.q) \(b.origin.x) \(b.origin.y)"
        if key != barsKey { Perf.time("bars-build") { buildBars(b) }; barsKey = key }
        let waiting = b.lesson.picture["waiting"] == 1 && b.lesson.marked.isEmpty
        var levels: [String: Double] = [:]
        for piece in bars {
            let k = piece.row == 2 ? (waiting ? 1 : 0) : b.grow(row: piece.row, piece.i, at: t)
            piece.group.isEnabled = k > 0
            piece.group.scale.z = Float(max(0.0001, k))
            let level = piece.row == 0 ? (piece.i < s.p ? 1 : 0) : piece.row == 1 ? b.shown(piece.i, at: t) : 0.5
            paint(piece, level, chapter: b.chapter.hex)
            levels["\(piece.row)-\(piece.i)"] = level
        }
        // filled pieces side by side stay pieces: a light line between them (G 17 Oct)
        for (id, seam) in seams {
            let parts = id.split(separator: "-").compactMap { Int($0) }
            let left = levels["\(parts[0])-\(parts[1] - 1)"] ?? 0, right = levels[id] ?? 0
            let level = min(left, right) > 0.01 ? max(left, right) : 0
            if let last = seamLevel[id], abs(last - level) < 0.01 { continue }
            seamLevel[id] = level
            seam.isEnabled = level > 0
            if level > 0 { seam.model?.materials = [flat(UIColor(hex: Ink.mix(Ink.mix(rig.paperHex, b.chapter.hex, level), 0xFFFFFF, 0.5)))] }
        }
        drawDecor(b, at: t)
    }

    private func buildBars(_ b: AddFractionsModel) {
        for c in Array(root.children) { c.removeFromParent() }
        bars = []; barLevel = [:]; seams = [:]; seamLevel = [:]; decorKey = ""
        let s = b.problem, u = Paper.unit, px = Float(1 / Paper.unit), h = AddFractionsModel.barHeight
        func piece(_ row: Int, _ i: Int, x: Double, y: Double, w: Double) {
            // the group's origin is the piece's bottom-left corner, so growing in rises from the bottom
            let g = Entity(); g.position = SIMD3(Float((b.origin.x + x) / u), 0, Float((b.origin.y + y + h) / u))
            let W = Float(w / u), H = Float(h / u)
            let fill = ModelEntity(mesh: .generatePlane(width: W, depth: H), materials: [])
            // over the grid: its strong lines don't fall on the pieces' edges, and would read as extra cuts
            fill.position = SIMD3(W / 2, 0.0008, -H / 2)
            let outline = ModelEntity()
            if let m = Rig.lines([(SIMD2(0, 0), SIMD2(W, 0)), (SIMD2(W, 0), SIMD2(W, -H)), (SIMD2(W, -H), SIMD2(0, -H)), (SIMD2(0, -H), SIMD2(0, 0))], width: 2 * px) {
                outline.model = ModelComponent(mesh: m, materials: [])
            }
            outline.position.y = 0.0012
            g.addChild(fill); g.addChild(outline); root.addChild(g)
            if row < 2, i > 0, let m = Rig.lines([(SIMD2(0, -px), SIMD2(0, -H + px))], width: 1.5 * px) {
                let seam = ModelEntity(mesh: m, materials: []); seam.position.y = 0.0014; seam.isEnabled = false
                g.addChild(seam); seams["\(row)-\(i)"] = seam
            }
            bars.append((row, i, g, fill, outline))
        }
        let top = b.wholeWidth / Double(s.a)
        for i in 0..<s.a { piece(0, i, x: Double(i) * top, y: AddFractionsModel.row1, w: top) }
        for i in 0..<s.b { piece(1, i, x: Double(i) * b.pieceWidth, y: AddFractionsModel.row2, w: b.pieceWidth) }
        piece(2, 0, x: b.wholeWidth + 20, y: AddFractionsModel.row2, w: b.pieceWidth)
        decor = Entity(); root.addChild(decor)
    }

    /// Empty pieces are outlined in a light tint; filled ones take the chapter colour, half strength for an added piece.
    private func paint(_ p: (row: Int, i: Int, group: Entity, fill: ModelEntity, outline: ModelEntity), _ level: Double, chapter: UInt32) {
        let id = "\(p.row)-\(p.i)"
        if let last = barLevel[id], abs(last - level) < 0.01 { return }
        barLevel[id] = level
        p.fill.isEnabled = level > 0.01
        if level > 0.01 { p.fill.model?.materials = [flat(UIColor(hex: Ink.mix(rig.paperHex, chapter, level)))] }
        p.outline.model?.materials = [flat(UIColor(hex: level > 0.01 ? chapter : Ink.mix(rig.paperHex, chapter, 0.45)))]
    }

    /// The lines around the bars: the whole's length, the matching dashes, the guide after a wrong count, the total's bracket.
    private func drawDecor(_ b: AddFractionsModel, at t: Double) {
        let whole = snapped(b.wholeLine(at: t), 50), guide = snapped(b.guide(at: t), 50), picture = b.lesson.picture, gone = snapped(b.gone(at: t), 50)
        let bracket = picture["total"] == 1 ? snapped(ease((t - b.wordsAt - 0.2) / 0.5), 50) : 0
        let key = "\(b.lesson.index) \(whole) \(guide) \(bracket) \(gone) \(picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }) \(b.lesson.marks.count)"
        guard key != decorKey else { return }
        decorKey = key
        for c in Array(decor.children) { c.removeFromParent() }
        let o = b.origin, W = b.wholeWidth, e = b.coverEnd, r1 = AddFractionsModel.row1, r2 = AddFractionsModel.row2, h = AddFractionsModel.barHeight
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x, y: o.y + y) }
        func dashed(_ a: CGPoint, _ c: CGPoint, _ on: Double = 4, _ off: Double = 6) -> [[CGPoint]] {
            let len = hypot(c.x - a.x, c.y - a.y), dx = (c.x - a.x) / len, dy = (c.y - a.y) / len
            var out: [[CGPoint]] = []
            for s in stride(from: 0, to: len, by: on + off) {
                let f: Double = min(len, s + on)
                out.append([CGPoint(x: a.x + dx * s, y: a.y + dy * s), CGPoint(x: a.x + dx * f, y: a.y + dy * f)])
            }
            return out
        }
        func add(_ lines: [[CGPoint]], _ k: Double, width: Double, _ c: UIColor) {
            guard let m = Rig.lines(drawn(lines, k * gone), width: Float(width / Paper.unit)) else { return }
            let e = ModelEntity(mesh: m, materials: [flat(c)]); e.position.y = 0.0012; decor.addChild(e)
        }
        let chapter = UIColor(hex: b.chapter.hex)
        add([[P(0, 92), P(0, 108)], [P(0, 100), P(W, 100)], [P(W, 92), P(W, 108)]], whole, width: 1.5, rig.colours.ink2)
        if picture["match"] == 1 {
            add(dashed(P(0, r1 + h + 6), P(0, r2 - 28)) + dashed(P(e, r1 + h + 6), P(e, r2 - 6)), 1, width: 2, chapter)
        }
        if picture["guide"] == 1, guide > 0 { add(dashed(P(e, r1 - 34), P(e, r2 + h + 12), 4, 5), guide, width: 1.5, rig.colours.ink) }
        // hints (LESSONS.md §7): the child's own count as a bracket under the bottom row, from its left end, so it can be
        // seen against where the fraction really ends
        let pw = b.pieceWidth, s = b.problem, mine = Double(b.lesson.marks.count) * pw
        if picture["yours"] == 1, mine > 0 {
            add([[P(0, r2 + h + 4), P(0, r2 + h + 12), P(mine, r2 + h + 12), P(mine, r2 + h + 4)]], guide, width: 2, chapter)
        }
        if picture["totalGuide"] == 1 {
            let t = Double(s.total) * pw
            add(dashed(P(t, r1 + h + 6), P(t, r2 + h + 12), 4, 5), guide, width: 1.5, rig.colours.ink)
        }
        // and then the pieces that are right, outlined
        if picture["outline"] == 1 {
            let want = b.lesson.step.task?.style == 2 ? s.covered..<s.total : 0..<s.covered
            let boxes = want.map { i -> [CGPoint] in
                let x = Double(i) * pw + 3, w = pw - 6
                return [P(x, r2 + 3), P(x + w, r2 + 3), P(x + w, r2 + h - 3), P(x, r2 + h - 3), P(x, r2 + 3)]
            }
            add(boxes.flatMap { dashed($0[0], $0[1], 4, 4) + dashed($0[1], $0[2], 4, 4) + dashed($0[2], $0[3], 4, 4) + dashed($0[3], $0[4], 4, 4) }, 1, width: 1.5, chapter)
        }
        if bracket > 0 {
            let end = Double(b.problem.total) * b.pieceWidth
            add([[P(0, r2 + h + 14), P(0, r2 + h + 24), P(end, r2 + h + 24), P(end, r2 + h + 14)]], bracket, width: 2, chapter)
        }
    }

}

/// Each colour's material is made once and reused (making a new one for every line on every frame was costly).
@MainActor func flat(_ c: UIColor) -> UnlitMaterial {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    c.getRed(&r, green: &g, blue: &b, alpha: &a)
    let key = UInt32(r * 255) << 16 | UInt32(g * 255) << 8 | UInt32(b * 255)
    if let m = flatMaterials[key] { return m }
    var m = UnlitMaterial(applyPostProcessToneMap: false)
    m.color = .init(tint: c)
    flatMaterials[key] = m
    return m
}
@MainActor private var flatMaterials: [UInt32: UnlitMaterial] = [:]
