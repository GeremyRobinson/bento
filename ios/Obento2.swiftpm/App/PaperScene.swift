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
        RealityView { content in
            content.camera = .virtual
            rig.build(into: &content)
            rig.update(view: view, model: model, time: time, dark: scheme == .dark)
        } update: { _ in
            rig.update(view: view, model: model, time: time, dark: scheme == .dark)
        }
        .background(Ink.paper)
        .allowsHitTesting(false)
    }
}

/// A lesson's picture as lines on the grid, in paper points, in the order they draw themselves in.
extension Piece {
    var strokes: [[CGPoint]] {
        let r = CGRect(x: at.x, y: at.y, width: Piece.size.width, height: Piece.size.height)
        let c = Paper.cell
        func box(_ b: CGRect) -> [CGPoint] { [CGPoint(x: b.minX, y: b.minY), CGPoint(x: b.maxX, y: b.minY), CGPoint(x: b.maxX, y: b.maxY), CGPoint(x: b.minX, y: b.maxY), CGPoint(x: b.minX, y: b.minY)] }
        func bar(y: Double, parts: Int, x: Double = 40, w: Double = 160) -> [[CGPoint]] {
            let b = CGRect(x: r.minX + x, y: r.minY + y, width: w, height: 2 * c), step: Double = b.width / Double(parts)
            let cuts: [[CGPoint]] = (1..<max(1, parts)).map { i in
                let x: Double = b.minX + Double(i) * step
                return [CGPoint(x: x, y: b.minY), CGPoint(x: x, y: b.maxY)]
            }
            return [box(b)] + cuts
        }
        func arc(_ x0: Double, _ x1: Double, _ y: Double, _ h: Double) -> [CGPoint] {
            (0...12).map { s in
                let f = Double(s) / 12
                return CGPoint(x: r.minX + x0 + (x1 - x0) * f, y: r.minY + y - sin(.pi * f) * h)
            }
        }
        func line(_ pts: (Double, Double)...) -> [CGPoint] { pts.map { CGPoint(x: r.minX + $0.0, y: r.minY + $0.1) } }
        switch id {
        case "uc": // one cube, drawn on the grid
            let x = r.minX + 80, y = r.minY + 60, s = 4 * c, o = 2 * c
            return [box(CGRect(x: x, y: y, width: s, height: s)),
                    [CGPoint(x: x, y: y), CGPoint(x: x + o, y: y - o), CGPoint(x: x + s + o, y: y - o), CGPoint(x: x + s, y: y)],
                    [CGPoint(x: x + s + o, y: y - o), CGPoint(x: x + s + o, y: y + s - o), CGPoint(x: x + s, y: y + s)]]
        case "ad", "add", "mix": // a fourths bar over an eighths bar, one whole long
            return bar(y: 40, parts: 4) + bar(y: 100, parts: 8)
        case "sub": // thirds over sixths
            return bar(y: 40, parts: 3) + bar(y: 100, parts: 6)
        case "g5-improper": // two wholes and part of a third, all cut into fourths
            return bar(y: 40, parts: 4, x: 20, w: 80) + bar(y: 40, parts: 4, x: 120, w: 80) + bar(y: 100, parts: 4, x: 20, w: 80)
        case "g5-fracof": // a bar of twenty cut into four groups
            return bar(y: 60, parts: 4) + [line((40, 120), (40, 130), (120, 130), (120, 120))]
        case "g5-multfrac": // a square cut into rows and columns
            let sq = CGRect(x: r.minX + 60, y: r.minY + 20, width: 6 * c, height: 6 * c)
            var out: [[CGPoint]] = [box(sq)]
            for i in 1..<3 { let y: Double = 20 + Double(i) * 40; out.append(line((60, y), (180, y))) }
            for i in 1..<4 { let x: Double = 60 + Double(i) * 30; out.append(line((x, 20), (x, 140))) }
            return out
        case "g5-unitdiv": // three wholes, each cut into fourths
            return (0..<3).flatMap { i in bar(y: 40 + Double(i) * 40, parts: 4) }
        case "g5-pow10", "g5-divdec": // digit boxes and the point hopping right
            let y = r.minY + 70
            var out: [[CGPoint]] = (0..<3).map { i in box(CGRect(x: r.minX + 50 + Double(i) * 3 * c, y: y, width: 2 * c, height: 2 * c)) }
            out.append(arc(100, 160, 62, 30))
            return out
        case "g5-round": // a number line with the halfway mark
            return [line((30, 90), (210, 90)), line((40, 80), (40, 100)), line((200, 80), (200, 100)), line((120, 84), (120, 96)), arc(150, 200, 70, 20)]
        case "g5-adddec": // two numbers lined up at the point, and the line under them
            var out: [[CGPoint]] = []
            for j in 0..<2 { for i in 0..<3 {
                let x: Double = r.minX + 60 + Double(i) * 2 * c, y: Double = r.minY + 30 + Double(j) * 2 * c
                out.append(box(CGRect(x: x, y: y, width: 2 * c, height: 2 * c)))
            } }
            out.append(line((50, 120), (190, 120)))
            return out
        case "g5-multdec", "g5-mult2": // an area model: a rectangle split into strips
            return [box(CGRect(x: r.minX + 40, y: r.minY + 40, width: 8 * c, height: 5 * c)), line((160, 40), (160, 140))]
                + (id == "g5-multdec" ? [line((40, 100), (200, 100))] : [])
        case "g5-divide": // the long division bracket
            return [line((60, 50), (200, 50)), line((60, 50), (52, 90), (60, 130)), line((80, 90), (160, 90))]
        case "g5-order": // a pair of parentheses around a small sum
            return [line((70, 50), (60, 90), (70, 130)), line((170, 50), (180, 90), (170, 130)),
                    line((100, 90), (140, 90)), line((120, 70), (120, 110))]
        case "g5-units": // a ruler
            var out: [[CGPoint]] = [box(CGRect(x: r.minX + 30, y: r.minY + 70, width: 9 * c, height: 2 * c))]
            for i in 1..<9 {
                let x: Double = 30 + Double(i) * 20, end: Double = i % 4 == 0 ? 100 : 84
                out.append(line((x, 70), (x, end)))
            }
            return out
        default: // a box with its three sides
            return [box(CGRect(x: r.minX + 40, y: r.minY + 60, width: 6 * c, height: 4 * c)),
                    [CGPoint(x: r.minX + 40, y: r.minY + 60), CGPoint(x: r.minX + 80, y: r.minY + 20), CGPoint(x: r.minX + 200, y: r.minY + 20), CGPoint(x: r.minX + 160, y: r.minY + 60)],
                    [CGPoint(x: r.minX + 200, y: r.minY + 20), CGPoint(x: r.minX + 200, y: r.minY + 100), CGPoint(x: r.minX + 160, y: r.minY + 140)]]
        }
    }

    var outline: [[CGPoint]] {
        [[CGPoint(x: at.x, y: at.y), CGPoint(x: at.x + Piece.size.width, y: at.y), CGPoint(x: at.x + Piece.size.width, y: at.y + Piece.size.height),
          CGPoint(x: at.x, y: at.y + Piece.size.height), CGPoint(x: at.x, y: at.y)]]
    }
}

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
    var pieceState: [String: String] = [:]
    var pieceLines: [String: (frame: ModelEntity, picture: ModelEntity)] = [:]
    // the open lesson
    let lessonRoot = Entity()
    weak var lesson: UnitCubesModel?
    var shape: (box: UnitCubes.Box, origin: Vec3)?
    var squares: [UnitCubes.Cell: ModelEntity] = [:]
    var cubes: [(x: Int, y: Int, z: Int, e: Entity)] = []
    var outline = Entity()
    var edges: [ModelEntity] = []
    /// Hints on the floor: the empty squares outlined (and tinted), rebuilt when they change.
    var hints = Entity()
    var hintKey = ""
    // the flat lesson
    let barsRoot = Entity()
    var barsKey = ""
    var bars: [(row: Int, i: Int, group: Entity, fill: ModelEntity, outline: ModelEntity)] = []
    var barLevel: [String: Double] = [:]
    var decor = Entity()
    var decorKey = ""
    var paperHex: UInt32 = 0xF3F2EF
    // a lesson worked in steps: its picture
    let stepsRoot = Entity()
    var stepsKey = ""
    var lineScale: Double = 0
    var dark: Bool?
    var colours = Colours(dark: false, chapter: Chapter.measurement.hex)

    init() { EdgeAxis.registerComponent() }

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
        root.addChild(sheet); root.addChild(pieces); root.addChild(lessonRoot); root.addChild(barsRoot); root.addChild(stepsRoot)
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
        if lineScale == 0 || abs(v.scale / lineScale - 1) > 0.05 { lineScale = v.scale; gridAt = nil; pieceState = [:]; relines() }
        // enough grid to fill the screen even when tilted, centred on a strong line near the middle
        let half = min(120, Int((hypot(screen.width, screen.height) / 2 / v.scale / sin(.pi / 4)).rounded(.up)) + 3)
        let gx = Int(floor.x.rounded()), gz = Int(floor.z.rounded())
        if let g = gridAt, abs(g.x - gx) <= 2, abs(g.z - gz) <= 2, g.half >= half {} else { regrid(x: gx, z: gz, half: half) }

        let onMap = model.lesson == nil && model.bars == nil && model.steps == nil
        pieces.isEnabled = onMap
        if onMap { drawPieces(model, at: t) }
        drawBars(model.bars, at: t)
        drawSteps(model.steps, at: t)

        guard let l = lesson else { return }
        // the last lesson's pieces are reused when the box is the same; otherwise cleared now, while the new one builds
        if shape?.box != l.box || shape?.origin != l.origin { rebuild(l) }
        for (c, e) in squares { let k = Float(max(0.0001, l.square(c, at: t))); e.scale = SIMD3(k, 1, k) }
        drawHints(l)
        for c in cubes {
            let k = l.cube(x: c.x, y: c.y, z: c.z, at: t)
            c.e.isEnabled = k > 0
            c.e.scale = SIMD3(1, Float(max(0.0001, k)), 1)
        }
        outline.isEnabled = l.tilt(at: t) == 0 && l.layers == 0
    }

    private func recolour(_ dark: Bool) {
        self.dark = dark
        colours = Colours(dark: dark, chapter: Chapter.measurement.hex)
        paperHex = dark ? 0x121211 : 0xF3F2EF
        sheet.model?.materials = [flat(colours.paper)]
        gridAt = nil; pieceState = [:]; shape = nil; barsKey = ""; stepsKey = ""
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
        let px = 1 / lineScale
        for p in Map.pieces {
            let k = Piece.drawIn(p, time: t, drawnAt: model.drawnAt)
            let on = model.selected?.id == p.id
            let key = "\((k * 500).rounded()) \(on) \(p.state)"
            guard pieceState[p.id] != key else { continue }
            pieceState[p.id] = key
            if pieceLines[p.id] == nil {
                let frame = ModelEntity(), picture = ModelEntity()
                frame.position.y = 0.001; picture.position.y = 0.0015
                pieces.addChild(frame); pieces.addChild(picture); pieceLines[p.id] = (frame, picture)
            }
            guard let e = pieceLines[p.id] else { continue }
            set(e.frame, Self.lines(drawn(p.outline, k), width: Float((on ? 2 : 1.5) * px)), on ? colours.ink : colours.lineStrong)
            set(e.picture, Self.lines(drawn(p.strokes, k), width: Float(2.5 * px)), p.state == .notYet ? colours.pencil : UIColor(hex: p.chapter.hex))
        }
    }

    private func set(_ e: ModelEntity, _ mesh: MeshResource?, _ c: UIColor) {
        guard let mesh else { e.isEnabled = false; return }
        e.model = ModelComponent(mesh: mesh, materials: [flat(c)]); e.isEnabled = true
    }

    // MARK: the flat lesson

    /// The bars: a row of a-ths over a row of b-ths, and the piece waiting to be added. Rebuilt only for a new problem or zoom.
    private func drawBars(_ b: AddFractionsModel?, at t: Double) {
        barsRoot.isEnabled = b != nil
        guard let b else { return }
        let s = b.problem
        let key = "\(s.a) \(s.p) \(s.b) \(s.q) \(b.origin.x) \(b.origin.y) \(lineScale)"
        if key != barsKey { buildBars(b); barsKey = key }
        let waiting = b.lesson.picture["waiting"] == 1 && b.lesson.marked.isEmpty
        for piece in bars {
            let k = piece.row == 2 ? (waiting ? 1 : 0) : b.grow(row: piece.row, piece.i, at: t)
            piece.group.isEnabled = k > 0
            piece.group.scale.z = Float(max(0.0001, k))
            let level = piece.row == 0 ? (piece.i < s.p ? 1 : 0) : piece.row == 1 ? b.shown(piece.i, at: t) : 0.5
            paint(piece, level, chapter: b.chapter.hex)
        }
        drawDecor(b, at: t)
    }

    private func buildBars(_ b: AddFractionsModel) {
        for c in Array(barsRoot.children) { c.removeFromParent() }
        bars = []; barLevel = [:]; decorKey = ""
        let s = b.problem, u = Paper.unit, px = Float(1 / lineScale), h = AddFractionsModel.barHeight
        func piece(_ row: Int, _ i: Int, x: Double, y: Double, w: Double) {
            // the group's origin is the piece's bottom-left corner, so growing in rises from the bottom
            let g = Entity(); g.position = SIMD3(Float((b.origin.x + x) / u), 0, Float((b.origin.y + y + h) / u))
            let W = Float(w / u), H = Float(h / u)
            let fill = ModelEntity(mesh: .generatePlane(width: W, depth: H), materials: [])
            // over the grid: its strong lines don't fall on the pieces' edges, and would read as extra cuts
            fill.position = SIMD3(W / 2, 0.0008, -H / 2)
            let outline = ModelEntity()
            if let m = Self.lines([(SIMD2(0, 0), SIMD2(W, 0)), (SIMD2(W, 0), SIMD2(W, -H)), (SIMD2(W, -H), SIMD2(0, -H)), (SIMD2(0, -H), SIMD2(0, 0))], width: 2 * px) {
                outline.model = ModelComponent(mesh: m, materials: [])
            }
            outline.position.y = 0.0012
            g.addChild(fill); g.addChild(outline); barsRoot.addChild(g)
            bars.append((row, i, g, fill, outline))
        }
        let top = b.wholeWidth / Double(s.a)
        for i in 0..<s.a { piece(0, i, x: Double(i) * top, y: AddFractionsModel.row1, w: top) }
        for i in 0..<s.b { piece(1, i, x: Double(i) * b.pieceWidth, y: AddFractionsModel.row2, w: b.pieceWidth) }
        piece(2, 0, x: b.wholeWidth + 20, y: AddFractionsModel.row2, w: b.pieceWidth)
        decor = Entity(); barsRoot.addChild(decor)
    }

    /// Empty pieces are outlined in a light tint; filled ones take the chapter colour, half strength for an added piece.
    private func paint(_ p: (row: Int, i: Int, group: Entity, fill: ModelEntity, outline: ModelEntity), _ level: Double, chapter: UInt32) {
        let id = "\(p.row)-\(p.i)"
        if let last = barLevel[id], abs(last - level) < 0.01 { return }
        barLevel[id] = level
        p.fill.isEnabled = level > 0.01
        if level > 0.01 { p.fill.model?.materials = [flat(UIColor(hex: Ink.mix(paperHex, chapter, level)))] }
        p.outline.model?.materials = [flat(UIColor(hex: level > 0.01 ? chapter : Ink.mix(paperHex, chapter, 0.45)))]
    }

    /// The lines around the bars: the whole's length, the matching dashes, the guide after a wrong count, the total's bracket.
    private func drawDecor(_ b: AddFractionsModel, at t: Double) {
        let whole = b.wholeLine(at: t), guide = b.guide(at: t), picture = b.lesson.picture
        let bracket = picture["total"] == 1 ? ease((t - b.wordsAt - 0.2) / 0.5) : 0
        let key = "\(b.lesson.index) \((whole * 50).rounded()) \((guide * 50).rounded()) \((bracket * 50).rounded()) \(picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }) \(b.lesson.marks.count)"
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
            guard let m = Self.lines(drawn(lines, k), width: Float(width / lineScale)) else { return }
            let e = ModelEntity(mesh: m, materials: [flat(c)]); e.position.y = 0.0012; decor.addChild(e)
        }
        let chapter = UIColor(hex: b.chapter.hex)
        add([[P(0, 92), P(0, 108)], [P(0, 100), P(W, 100)], [P(W, 92), P(W, 108)]], whole, width: 1.5, colours.ink2)
        if picture["match"] == 1 {
            add(dashed(P(0, r1 + h + 6), P(0, r2 - 28)) + dashed(P(e, r1 + h + 6), P(e, r2 - 6)), 1, width: 2, chapter)
        }
        if picture["guide"] == 1, guide > 0 { add(dashed(P(e, r1 - 34), P(e, r2 + h + 12), 4, 5), guide, width: 1.5, colours.ink) }
        // hints (LESSONS.md §7): the child's own count as a bracket under the bottom row, from its left end, so it can be
        // seen against where the fraction really ends
        let pw = b.pieceWidth, s = b.problem, mine = Double(b.lesson.marks.count) * pw
        if picture["yours"] == 1, mine > 0 {
            add([[P(0, r2 + h + 4), P(0, r2 + h + 12), P(mine, r2 + h + 12), P(mine, r2 + h + 4)]], guide, width: 2, chapter)
        }
        if picture["totalGuide"] == 1 {
            let t = Double(s.total) * pw
            add(dashed(P(t, r1 + h + 6), P(t, r2 + h + 12), 4, 5), guide, width: 1.5, colours.ink)
        }
        // and then the pieces that are right, outlined
        if picture["outline"] == 1 {
            let want = b.lesson.index == 1 ? 0..<s.covered : s.covered..<s.total
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
        let s = ShiftPicture(m.lesson.numbers), grow = m.grow(at: t)
        let h = s.hops(m.sincePicture(t), moving: m.lesson.picture["hop"] == 1)
        let key = "\(m.lesson.numbers) \((h * 40).rounded()) \((grow * 20).rounded()) \(lineScale)"
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
        squares = [:]; cubes = []; edges = []; outline = Entity(); hintKey = ""
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
        let cube = MeshResource.generateBox(width: 1, height: 1, depth: 1, cornerRadius: 0, splitFaces: true)
        // splitFaces order: front, top, back, bottom, right, left
        let faces: [any RealityKit.Material] = [colours.front, colours.top, colours.front, colours.top, colours.side, colours.side].map { flat($0) as any RealityKit.Material }
        for y in 0..<b.height { for z in 0..<b.width { for x in 0..<b.length {
            let g = Entity()
            g.position = SIMD3(Float(o.x) + Float(x), Float(y), Float(o.z) + Float(z))
            let m = ModelEntity(mesh: cube, materials: faces); m.position = SIMD3(0.5, 0.5, 0.5); g.addChild(m)
            for e in Self.cubeEdges() { e.model?.materials = [flat(colours.deep)]; g.addChild(e); edges.append(e) }
            g.isEnabled = false
            lessonRoot.addChild(g); cubes.append((x, y, z, g))
        } } }
        relines()
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

    /// The lesson's lines at the current zoom: cube edges and the box's dashed floor.
    private func relines() {
        guard lineScale > 0 else { return }
        let px = Float(1 / lineScale)
        for e in edges {
            guard let a = e.components[EdgeAxis.self]?.axis else { continue }
            var s = SIMD3<Float>(repeating: 2.5 * px); s[a] = 1 + 2.5 * px; e.scale = s
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

struct EdgeAxis: Component { let axis: Int }

/// A plain colour with no lighting and no tone mapping, so the paper in 3D is the same colour as the flat paper.
@MainActor func flat(_ c: UIColor) -> UnlitMaterial {
    var m = UnlitMaterial(applyPostProcessToneMap: false)
    m.color = .init(tint: c)
    return m
}
