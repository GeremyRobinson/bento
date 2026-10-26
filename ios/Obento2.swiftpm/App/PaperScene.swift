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
    var strokes: [[CGPoint]] { let o = centring; return drawing.map { $0.map { CGPoint(x: $0.x + o.x, y: $0.y + o.y) } } }

    /// The parts of the picture softly filled (G 18 Oct, the icons' tint): what matters in it, the shaded part of a
    /// fraction, the digit that moves, the top of a box. Closed shapes, centred with the lines.
    var softs: [[CGPoint]] { let o = centring; return soft.map { $0.map { CGPoint(x: $0.x + o.x, y: $0.y + o.y) } } }

    /// How far the picture moves to sit in the middle of its frame.
    private var centring: CGPoint {
        let pts = drawing.flatMap { $0 }
        guard let x0 = pts.map(\.x).min(), let x1 = pts.map(\.x).max(), let y0 = pts.map(\.y).min(), let y1 = pts.map(\.y).max() else { return .zero }
        let c = isBox ? 0.001 : Paper.cell, f = frame
        return CGPoint(x: ((f.mid.x - (x0 + x1) / 2) / c).rounded() * c, y: ((f.mid.y - (y0 + y1) / 2) / c).rounded() * c)
    }

    private var soft: [[CGPoint]] {
        let c = Paper.cell
        func box(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> [CGPoint] {
            [CGPoint(x: at.x + x * c, y: at.y + y * c), CGPoint(x: at.x + (x + w) * c, y: at.y + y * c),
             CGPoint(x: at.x + (x + w) * c, y: at.y + (y + h) * c), CGPoint(x: at.x + x * c, y: at.y + (y + h) * c)]
        }
        if id == "test-grade" {
            let p = { (x: Double, y: Double) in CGPoint(x: at.x + x * c, y: at.y + y * c) }
            return Self.starFan(p, cx: 4.5, cy: 2.4, r: 1.4)
        }
        if isTest { return [[CGPoint(x: at.x + 3.5 * c, y: at.y), CGPoint(x: at.x + 3.5 * c, y: at.y + 1.5 * c), CGPoint(x: at.x + 5 * c, y: at.y + 1.5 * c)]] }
        switch id {
        case "g5-volume": return [Array(box3D(l: 4, h: 2, w: 3, u: 32)[0].dropLast())]
        case "add": return [box(0, 0, 3, 2), box(0, 4, 6, 2)]                   // a third and two thirds
        case "sub": return [box(0, 0, 6, 2)]                                    // two thirds, to take from
        case "mix": return [box(0, 0, 3, 2), box(0, 6, 6, 2)]
        case "g5-improper": return [box(0, 0, 4, 2), box(5, 0, 4, 2), box(0, 4, 1, 2)]   // two wholes and a fourth
        case "g5-fracof": return [box(0, 0, 6, 2)]                              // two of the thirds
        case "g5-multfrac": return [box(0, 0, 6, 4)]                            // 2/3 of 2/3
        case "g5-unitdiv": return [box(0, 0, 1, 2), box(4, 0, 1, 2), box(8, 0, 1, 2)]    // a third of each whole
        case "g5-pow10", "g5-divdec": return [box(3, 2, 2, 2)]                  // the digit the point hops over
        case "g5-round": return [box(7, 2, 3, 2)]                               // the stretch up to the whole
        case "g5-adddec": return [box(6, 0, 2, 2), box(6, 3, 2, 2)]             // the decimal places, lined up
        case "g5-multdec": return [box(0, 0, 6, 4)]
        case "g5-mult2": return [box(0, 0, 6, 6)]                               // the tens part
        case "g5-divide": return [box(3, 1, 4, 1)]
        case "g5-order": return [box(2, 1, 2, 2)]                               // the part done first
        case "g5-units": return [box(0, 0, 4, 2)]                               // a foot of it
        default: return []
        }
    }

    /// A five-pointed star's outline, closed.
    static func star(_ P: (Double, Double) -> CGPoint, cx: Double, cy: Double, r: Double) -> [CGPoint] {
        (0...10).map { i in let a = -Double.pi / 2 + Double(i) * .pi / 5, rr = i % 2 == 0 ? r : r * 0.45; return P(cx + rr * cos(a), cy + rr * sin(a)) }
    }
    /// The same star as triangles from its middle, for its fill (it isn't convex).
    static func starFan(_ P: (Double, Double) -> CGPoint, cx: Double, cy: Double, r: Double) -> [[CGPoint]] {
        let s = star(P, cx: cx, cy: cy, r: r), mid = P(cx, cy)
        return (0..<10).map { [mid, s[$0], s[$0 + 1]] }
    }

    /// The lessons whose picture is a box of cubes, drawn as the 3D lesson shows it.
    private var isBox: Bool { id == "g5-volume" }

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
        if id == "test-grade" { // the grade's test: a medal, a star in its middle and two ribbon tails: 9 by 6... 5 wide
            let ring = (0...32).map { s -> CGPoint in let a = Double(s) / 32 * 2 * .pi; return P(4.5 + 2.4 * cos(a), 2.4 + 2.4 * sin(a)) }
            return [ring, Self.star(P, cx: 4.5, cy: 2.4, r: 1.4), line((3.2, 4.3), (2.6, 6), (3.6, 5.5), (4.1, 6), (4.3, 4.8)), line((5.8, 4.3), (6.4, 6), (5.4, 5.5), (4.9, 6), (4.7, 4.8))]
        }
        if isTest { // a chapter's test: a sheet with its corner folded and answers written on it: 5 by 6
            return [line((0, 0), (3.5, 0), (5, 1.5), (5, 6), (0, 6), (0, 0)), line((3.5, 0), (3.5, 1.5), (5, 1.5)),
                    line((1, 2.5), (3.5, 2.5)), line((1, 3.5), (3.5, 3.5)), line((1, 4.5), (2.5, 4.5))]
        }
        switch id {
        case "g5-volume": // a box of cubes, 4 by 3 by 2, as the lesson shows it
            return box3D(l: 4, h: 2, w: 3, u: 32)
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
    var mapDrawer: SketchDrawer?
    // a place of its own instead of the map: Me, or the grown-ups' page (Places.swift)
    let placeRoot = Entity()
    var placeDrawer: SketchDrawer?
    /// Some problem's picture or words are still to be made.
    var pageBuilding = false
    var piecesQuick = ""
    var pieceGroups: [String: ModelEntity] = [:]
    /// Each Volume of a box problem's box of cubes on a lesson's page, with its standing words (CubesDrawer, CubesWords).
    var problemCubes: [UUID: (cubes: CubesDrawer, words: CubesWords)] = [:]
    /// The view this frame is seen through, and the screen.
    var view = PaperView3D()
    var screen = Size(1180, 820)
    // the flat lesson
    let barsRoot = Entity()
    var sketches: [UUID: SketchDrawer] = [:]
    /// What the camera last framed a problem's content for.
    var contentKey = ""
    /// The blinking cursor in the answer box being typed into.
    let cursorEntity = ModelEntity()
    var cursorKey = ""
    /// The page of problems' cards (PageCards).
    let cardsRoot = Entity()
    var cardsDrawer: SketchDrawer?
    var paperHex: UInt32 = 0xF3F2EF
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
        root.addChild(sheet); root.addChild(pieces); root.addChild(barsRoot); barsRoot.addChild(cardsRoot); barsRoot.addChild(cursorEntity); root.addChild(words); root.addChild(placeRoot)
    }

    func update(view v: PaperView3D, model: PaperModel, time t: Double, dark: Bool) {
        if dark != self.dark { recolour(dark) }
        let screen = model.screen
        self.view = v; self.screen = screen

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

        // lines keep their screen width at any zoom
        if lineScale == 0 || abs(v.scale / lineScale - 1) > 0.05 { lineScale = v.scale; gridAt = nil; piecesKey = "" }
        // enough grid to fill the screen even when tilted, centred on a strong line near the middle
        let half = min(120, Int((hypot(screen.width, screen.height) / 2 / v.scale / sin(.pi / 4)).rounded(.up)) + 3)
        let gx = Int(floor.x.rounded()), gz = Int(floor.z.rounded())
        if let g = gridAt, abs(g.x - gx) <= 2, abs(g.z - gz) <= 2, g.half >= half {} else { Perf.time("grid") { regrid(x: gx, z: gz, half: half) } }

        let onMap = model.bars == nil && model.place == nil
        pieces.isEnabled = onMap; words.isEnabled = onMap
        if onMap { Perf.time("pieces") { drawPieces(model, at: t) }; Perf.time("words") { drawWords(model, at: t) } }
        // off the map (a lesson or a place open) its words aren't updated, so they can't say they're still drawing: the
        // clock that waited on them stops (it ran at 60 fps through every lesson, 25 Oct)
        else if model.mapDrawing { Task { @MainActor in model.setMapDrawing(false) } }
        Perf.time("place") { drawPlace(model, at: t) }
        drawPage(model.bars, at: t)
    }

    private func recolour(_ dark: Bool) {
        mapDrawer?.key = ""; placeDrawer?.key = ""; placeDrawer?.live.key = ""
        self.dark = dark
        colours = Colours(dark: dark, chapter: Chapter.measurement.hex)
        paperHex = dark ? 0x121211 : 0xF3F2EF
        sheet.model?.materials = [flat(colours.paper)]
        gridAt = nil; piecesKey = ""
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
        let now = Map.all.map { p in (p, snapped(Piece.drawIn(p, time: t, drawnAt: model.drawnAt, from: model.drawFrom), 400) * gone, model.selected?.id == p.id, p.state) }
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
            // a test still waiting is a dashed frame: there, but not open yet
            let locked = p.isTest && !p.opens && state != .learned
            add("frame-\(p.chapter.rawValue)-\(lit)-\(on)", frameColour, on ? 2 : 1.5, 0.001, drawn(locked ? Self.dashes(p.outline) : p.outline, k))
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
        // the soft fills inside the pictures, a little stronger than the frame's tint, coming in with the drawing
        var softFills: [String: (colour: UIColor, polys: [[CGPoint]])] = [:]
        for (p, k, _, state) in now where k > 0.3 {
            let strength = state == .notYet ? 0.26 : 0.42, id = "soft-\(p.chapter.rawValue)-\(strength)"
            softFills[id, default: (UIColor(hex: Ink.mix(paperHex, p.chapter.hex, strength)), [])].polys += p.softs
        }
        for (id, f) in softFills {
            let e = pieceGroups[id] ?? { let e = ModelEntity(); pieces.addChild(e); pieceGroups[id] = e; return e }()
            e.position.y = 0.0008
            set(e, Self.polygons(f.polys), f.colour)
        }
        for (id, e) in pieceGroups where groups[id] == nil && tints[id] == nil && softFills[id] == nil { e.isEnabled = false }
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

    /// A lesson's page: one drawer per problem (and the How to), each with its own picture and words.
    private func drawPage(_ page: BarsPage?, at t: Double) {
        barsRoot.isEnabled = page != nil
        guard let page else {
            for d in sketches.values { d.root.removeFromParent() }
            sketches = [:]
            drawCards(nil, at: t)
            clearCubesProblems(keeping: []); return
        }
        let shown = page.all, every = page.all + (page.howToGone ? [] : page.problems)
        pageBuilding = false
        defer { let b = pageBuilding; Task { @MainActor in page.setBuilding(b) } }
        // the problems' bars are built one a frame while the How to plays, unseen (they haven't grown in), so nothing
        // is built when they arrive (building all 17 at once stalled a frame for 170 ms; 16 as they arrived, 80 ms)
        var made = 0
        for m in every {
            // Volume of a box: its cubes and its standing words, only while it's on the paper (CubesWords.swift)
            if let c = m as? CubesProblem { if shown.contains(where: { $0 === c }) { drawCubesProblem(c, at: t) }; continue }
            if sketches[m.id] == nil {
                if made >= 1 && !page.instant && m !== page.howTo { pageBuilding = true; continue }
                made += 1
            }
            if let w = m as? WorkProblem {
                let d = sketches[m.id] ?? { let d = SketchDrawer(); barsRoot.addChild(d.root); sketches[m.id] = d; return d }()
                if drawWork(w, page, into: d, at: t) { pageBuilding = true }
            }
        }
        for (id, d) in sketches where !every.contains(where: { $0.id == id }) { d.root.removeFromParent(); sketches[id] = nil }
        clearCubesProblems(keeping: shown)
        frameContent(page)
        if drawCards(page, at: t) { pageBuilding = true }
        drawCursor(page, at: t)
    }

    /// The cursor in the box being typed into (G 19 Oct): a thin line that blinks as a cursor does, held still for a
    /// moment after each key, once the problem has drawn in.
    private func drawCursor(_ page: BarsPage, at t: Double) {
        guard page.mode == .work, let m = page.current as? WorkProblem, t - m.openedAt > 1.2, let r = ProblemLayout.cursor(m) else {
            cursorEntity.isEnabled = false; return
        }
        let key = "\(r) \(dark ?? false)"
        if key != cursorKey {
            cursorKey = key
            let u = Paper.unit, w = Sketch.stroke * m.scale
            cursorEntity.model = Self.lines([(SIMD2(Float(r.minX / u), Float(r.minY / u)), SIMD2(Float(r.minX / u), Float(r.maxY / u)))], width: Float(w / u))
                .map { ModelComponent(mesh: $0, materials: [flat(colours.ink)]) }
            cursorEntity.position.y = 0.0027
        }
        let since = t - m.typedAt
        cursorEntity.isEnabled = Blink.on(since: since)
    }

    /// The camera frames what's on the paper (G 19 Oct): the problem's picture and words as they are now, so when a
    /// step adds something the paper eases out to fit it as it draws in, and eases back in when something goes.
    private func frameContent(_ page: BarsPage) {
        guard let m = page.mode == .work ? page.current : (page.howToGone ? nil : page.howTo) else { contentKey = ""; return }
        // a lesson on the paper frames its plan's rectangle for the step it's on (G 20 Oct), not what's drawn, and holds
        // still while a hand drags on it
        if let w = m as? WorkProblem, let r = w.stageFrame {
            guard !w.dragging else { return }
            let key = "\(m.id) \(r)"
            guard key != contentKey else { return }
            contentKey = key
            Task { @MainActor in page.contentChanged(r) }
            return
        }
        let key = "\(m.id) \(sketches[m.id]?.key ?? "")"
        guard key != contentKey else { return }
        contentKey = key
        let u = Paper.unit
        var r: CGRect?
        for e in [sketches[m.id]?.root].compactMap({ $0 }) {
            let b = e.visualBounds(recursive: true, relativeTo: barsRoot, excludeInactive: false)
            guard !b.isEmpty else { continue }
            let rr = CGRect(x: Double(b.min.x) * u, y: Double(b.min.z) * u, width: Double(b.max.x - b.min.x) * u, height: Double(b.max.z - b.min.z) * u)
            r = r.map { $0.union(rr) } ?? rr
        }
        if let r { Task { @MainActor in page.contentChanged(Rect(x: r.minX, y: r.minY, width: r.width, height: r.height)) } }
    }

    /// Lines broken into dashes, a cell's half on and half off.
    static func dashes(_ lines: [[CGPoint]]) -> [[CGPoint]] {
        lines.flatMap { pts in zip(pts, pts.dropFirst()).flatMap { a, b -> [[CGPoint]] in
            let len = hypot(b.x - a.x, b.y - a.y), n = max(1, Int(len / 10))
            return (0..<n).compactMap { i in
                guard i % 2 == 0 else { return nil }
                let f0 = Double(i) / Double(n), f1 = Double(i + 1) / Double(n)
                return [CGPoint(x: a.x + (b.x - a.x) * f0, y: a.y + (b.y - a.y) * f0), CGPoint(x: a.x + (b.x - a.x) * f1, y: a.y + (b.y - a.y) * f1)]
            }
        } }
    }

    /// Filled shapes on the paper, each closed and convex (a fan from its first corner).
    static func polygons(_ polys: [[CGPoint]]) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let u = Paper.unit
        for poly in polys where poly.count >= 3 {
            let base = UInt32(pos.count)
            pos += poly.map { SIMD3(Float($0.x / u), 0, Float($0.y / u)) }
            for i in 1..<(poly.count - 1) {
                let a = base, b = base + UInt32(i), c = base + UInt32(i + 1)
                idx += [a, b, c, a, c, b]
            }
        }
        guard !pos.isEmpty else { return nil }
        var d = MeshDescriptor(name: "polygons")
        d.positions = MeshBuffers.Positions(pos)
        d.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [d])
    }

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
