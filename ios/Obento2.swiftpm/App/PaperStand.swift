import SwiftUI
import RealityKit
import simd

// MARK: the paper standing up (shared 3D, 4 Nov)

/// The paper standing up for a lesson on the paper (LESSONS.md §6, G's rules in CLAUDE.md): what Volume of a box does,
/// made a piece any paper lesson can use. A step says it stands (PaperLesson.stands, the point of the picture the paper
/// turns about) and the paper tilts on the spring to Unit cubes' view, seen through the long lens (PaperView3D: 52° up,
/// turned +28°, light from the top left); what rises off the paper is drawn in true 3D (PaperDrawing.solids: faces that
/// fold on their hinges, layers of cubes that rise, lines, labels on them), in Volume of a box's colours (CubesDrawer);
/// everything the lesson writes (what to do, a miss, the record, the blocks, the picture's words) stands facing the
/// child where it was on the flat paper; and when the step no longer stands, or the problem goes, the paper lies flat.
///
/// The words stand on a board through the pivot facing the eye: a point written at (x, y) on the flat paper shows where
/// the flat camera would show it. So the flat camera still frames each step (the keys, a new record line, a pan or a
/// pinch move it, on its spring), and the tilted view is worked out from it every frame: the pivot stays where the flat
/// camera puts it, at the flat camera's zoom. A lesson places its words beside what stands with `Standing.up`, which
/// says where a point of the picture `z` squares above the paper shows on that board.
struct Standing {
    /// The point of the picture (its squares, on the paper) the paper turns about.
    let pivot: CGPoint
    /// Where the camera looks, on the board (the flat paper's squares, from the picture's corner): the middle of the
    /// screen. The long lens draws what's nearer the eye a little bigger away from there, so a word placed beside what
    /// stands is placed as it's seen from there (nil: from the pivot, as the layout measures it).
    var eye: CGPoint? = nil
    init(pivot: CGPoint, eye: CGPoint? = nil) { self.pivot = pivot; self.eye = eye }
    static let tilted = PaperView3D(elevation: PaperView3D.tilted.elevation, azimuth: PaperView3D.tilted.azimuth, scale: Paper.unit)
    /// World units a square.
    static let c = Paper.cell / Paper.unit

    /// Where a point of the picture `z` squares above the paper shows while the paper stands, in the flat paper's squares.
    func up(_ x: Double, _ y: Double, _ z: Double = 0) -> CGPoint {
        let e = eye ?? pivot, (_, r, u) = Self.tilted.axes
        // the eye's point, on the board through the pivot
        let T = r * ((e.x - pivot.x) * Self.c) + u * (-(e.y - pivot.y) * Self.c)
        let d = Vec3((x - pivot.x) * Self.c, z * Self.c, (y - pivot.y) * Self.c) - T
        let p = Self.tilted.project(d, screen: Size(0, 0))
        return CGPoint(x: e.x + p.x / Paper.cell, y: e.y + p.y / Paper.cell)
    }
    func up(_ v: Vec3) -> CGPoint { up(v.x, v.y, v.z) }
    /// The point of the paper that shows at `u` on the board (where a finger there lands on the standing paper).
    func down(_ u: CGPoint) -> CGPoint {
        var p = u
        for _ in 0..<6 {
            let q = up(p.x, p.y), ex = up(p.x + 1, p.y), ey = up(p.x, p.y + 1)
            let a = ex.x - q.x, c = ex.y - q.y, b = ey.x - q.x, d = ey.y - q.y, det = a * d - b * c
            guard abs(det) > 1e-9 else { break }
            let rx = u.x - q.x, ry = u.y - q.y
            p = CGPoint(x: p.x + (d * rx - b * ry) / det, y: p.y + (-c * rx + a * ry) / det)
        }
        return p
    }
    /// What a set of points takes up, standing, in squares.
    func bounds(_ pts: [Vec3]) -> CGRect? {
        let q = pts.map(up)
        guard let x0 = q.map(\.x).min(), let x1 = q.map(\.x).max(), let y0 = q.map(\.y).min(), let y1 = q.map(\.y).max() else { return nil }
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
    /// The pivot that shows `pts` standing with their top-left at `corner` (flat paper squares): what stands is moved
    /// under the words without moving it on the paper (the paper turns about another point).
    static func pivot(showing pts: [Vec3], at corner: CGPoint, from p0: CGPoint) -> CGPoint {
        var p = p0
        func g(_ q: CGPoint) -> CGPoint { let b = Standing(pivot: q).bounds(pts) ?? .zero; return CGPoint(x: b.minX, y: b.minY) }
        for _ in 0..<4 {
            let now = g(p), ex = g(CGPoint(x: p.x + 1, y: p.y)), ey = g(CGPoint(x: p.x, y: p.y + 1))
            let a = ex.x - now.x, c = ex.y - now.y, b = ey.x - now.x, d = ey.y - now.y, det = a * d - b * c
            guard abs(det) > 1e-9 else { break }
            let rx = corner.x - now.x, ry = corner.y - now.y
            p = CGPoint(x: p.x + (d * rx - b * ry) / det, y: p.y + (-c * rx + a * ry) / det)
        }
        return p
    }
    /// How many squares something rises for a finger dragged on the standing paper from `a` to `b` (paper squares, where the
    /// finger lands on the paper): straight up the screen is away across the paper.
    static func rise(from a: CGPoint, to b: CGPoint) -> Double {
        let az = PaperView3D.tilted.azimuth * .pi / 180, el = PaperView3D.tilted.elevation * .pi / 180
        return -((b.x - a.x) * sin(az) + (b.y - a.y) * cos(az)) * tan(el)
    }
    /// Where on the paper a finger lands that has moved `h` squares up the screen from `a`'s (the ghost finger's drag).
    static func away(from a: CGPoint, rising h: Double) -> CGPoint {
        let az = PaperView3D.tilted.azimuth * .pi / 180, el = PaperView3D.tilted.elevation * .pi / 180, d = h / tan(el)
        return CGPoint(x: a.x - d * sin(az), y: a.y - d * cos(az))
    }
}

/// What stands off the paper (or lies on it in 3D) for one state of a lesson, in the picture's squares: x across, y down
/// the paper, z up off it. One cube is a block of the paper where the lesson allows (Unit cubes).
struct Solids {
    /// A face's colour: lit by the way it faces (top lightest, front, the right side darkest), as Volume of a box's cubes
    /// are; or a stronger shade (a whole made of small cubes), a preview's lighter one, or a colour of the paper's.
    enum Look: Equatable { case auto, top, front, side, lit, ghost, paint(Sketch.Colour) }
    /// A flat shape in space: on the paper, or folded up off it about its hinge (a line on the face it hangs from), by
    /// `angle` degrees. A face on a face turns with it. `live`: following a finger (no spring).
    struct Face {
        var id: String
        var pts: [Vec3]
        var look: Look = .auto
        var edges = true
        var parent: String? = nil
        var hinge: (Vec3, Vec3)? = nil
        var angle = 0.0
        var live = false
        /// Its outline dashed in the chapter's colour (a copy waiting to be fitted), not the cubes' edges.
        var dashed = false
        /// How long it waits before it turns to a new angle (a box stays closed a moment before it opens).
        var delay = 0.0
        /// New, it turns from this angle to its own on the spring (a half folding over as it appears).
        var from: Double? = nil
        /// Lying flat, it lies over what's drawn on the paper (a half folded over the other), under the marks on it.
        var over = false
        /// Its outline's colour (nil: the cubes' edges).
        var edge: Sketch.Colour? = nil
    }
    /// A layer of cubes `l` × `w`, `B` squares an edge, from its back-left-bottom corner `at` (squares, z its height). New
    /// ones rise (Unit cubes' 0.7 s) after `delay`; gone ones sink.
    struct Block { var id: String; var at: Vec3; var l: Int; var w: Int; var B: Double; var look: Look = .auto; var delay = 0.0 }
    struct Line { var id: String; var pts: [Vec3]; var colour: Sketch.Colour = .ink3; var dashed = false }
    /// Words on a point of what stands, facing the child (a length on an edge).
    struct Label { var id: String; var text: String; var at: Vec3; var words: Sketch.Words; var anchor: UnitPoint = .center }
    /// A solid drawn as one piece (Kindergarten's Shapes: a cube, sphere, cylinder or cone, a table): its facets each
    /// shaded by the way it faces (light from the top left, as the cubes are: the top lightest, the right side darkest),
    /// its edges and marks drawn on it, and, for a round one, the sides it shows from where the camera looks (worked out
    /// as the view moves). In the picture's squares, placed where it stands.
    struct Body {
        var id: String
        var facets: [[Vec3]]
        /// The whole body's tone, or each facet's (lit: a flat face found; red: tapped and wrong).
        var tone: Tone = .auto
        var tones: [Tone]? = nil
        /// Its edges (a cube's, a cylinder's rims), in the edge colour.
        var edges: [[Vec3]] = []
        /// Marks on it, thinner in tone (a can's rings, a die's dots, a ball's seam).
        var marks: [[Vec3]] = []
        /// Round parts whose outline depends on the view.
        var rounds: [Round] = []
    }
    enum Tone: Equatable { case auto, lit, red }
    enum Round: Equatable {
        case sphere(Vec3, Double)
        /// From the middle of one end to the other's, its radius.
        case cylinder(Vec3, Vec3, Double)
        /// From the middle of its base to its point, the base's radius.
        case cone(Vec3, Vec3, Double)
    }
    /// What moves by itself for a while (a solid pushed, rolling; a solid turning once): drawn as `at(t)` says from
    /// `start` for `length` seconds, then as it says at the end.
    struct Play { var start: Double; var length: Double; var at: @MainActor (Double) -> Solids }
    var faces: [Face] = [], blocks: [Block] = [], lines: [Line] = [], labels: [Label] = []
    var bodies: [Body] = []
    var play: Play?
    var isEmpty: Bool { faces.isEmpty && blocks.isEmpty && lines.isEmpty && labels.isEmpty && bodies.isEmpty }

    /// A face's corners turned on its hinge and its parents' (by `angle(face)`).
    func placed(_ f: Face, angle: (Face) -> Double) -> [Vec3] {
        var pts = f.pts, at: Face? = f
        while let g = at {
            if let h = g.hinge { let a = angle(g); pts = pts.map { Self.turn($0, g, h, a) } }
            at = g.parent.flatMap { p in faces.first { $0.id == p } }
        }
        return pts
    }
    /// Turns a point about a face's hinge by `deg`, the way that lifts the face off the paper.
    static func turn(_ p: Vec3, _ f: Face, _ h: (Vec3, Vec3), _ deg: Double) -> Vec3 {
        var u = (h.1 - h.0).normalized
        // the face's middle, flat: turning by a little lifts it (z up)
        let n = Double(f.pts.count), mid = f.pts.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / n), v = mid - h.0
        if u.cross(v).z < 0 { u = u * -1 }
        let th = deg * .pi / 180, c = cos(th), s = sin(th), d = p - h.0
        let r = d * c + u.cross(d) * s + u * (u.dot(d) * (1 - c))
        return h.0 + r
    }
    /// Every point that shows, folded as each face's angle says.
    var points: [Vec3] {
        var out = faces.flatMap { placed($0) { $0.angle } } + lines.flatMap(\.pts) + labels.map(\.at) + bodies.flatMap { $0.facets.flatMap { $0 } }
        for b in blocks { for i in [0.0, 1] { for j in [0.0, 1] { for k in [0.0, 1] {
            out.append(Vec3(b.at.x + i * Double(b.l) * b.B, b.at.y + j * Double(b.w) * b.B, b.at.z + k * b.B))
        } } } }
        return out
    }
    /// What it takes up, in the picture's squares: standing (seen through `stand`), or flat on the paper (from above).
    func bounds(_ stand: Standing?) -> CGRect? {
        let pts = points
        if let stand { return stand.bounds(pts) }
        guard let x0 = pts.map(\.x).min(), let x1 = pts.map(\.x).max(), let y0 = pts.map(\.y).min(), let y1 = pts.map(\.y).max() else { return nil }
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
}

// MARK: the problem that stands

/// A problem's standing: its pivot, and the tilt's beat up and back down (on the spring, `glide`).
@MainActor
final class StandTilt {
    var pivot: CGPoint?
    var upAt: Double?
    var downAt: Double?
    /// How far it stood when the move under way began.
    var from = 0.0
    var downTime = TiltCamera.beat
    /// Held part way up by a finger (PaperLesson.standHeld): how far, followed 1:1.
    var held: Double?
    /// It has stood once for this problem (a lesson's standDelay is waited only the first time).
    var stoodOnce = false
    /// Screenshots of a moment mid-tilt (`-slow`): the tilt this many times slower.
    static var slow = 1.0

    func blend(at t: Double, instant: Bool) -> Double {
        if let h = held { return h }
        // screenshots cut straight to it, unless a move is being filmed (`-slow`)
        let instant = instant && PaperClock.slow == 1
        if let d = downAt { return instant ? 0 : from * (1 - glide(max(0, t - d) / (downTime * Self.slow))) }
        guard let u = upAt else { return 0 }
        // waiting flat a moment first (standDelay)
        if t < u { return from }
        return instant ? 1 : from + (1 - from) * glide((t - u) / (TiltCamera.beat * Self.slow))
    }
    func holds(at t: Double) -> Bool { held != nil || (upAt != nil && (downAt.map { t - $0 < downTime * Self.slow } ?? true)) }
    var standing: Bool { upAt != nil && downAt == nil }
    func clear() { pivot = nil; upAt = nil; downAt = nil; from = 0; held = nil }
}

extension WorkProblem: TiltOwner {
    /// The pivot on the paper, in world units.
    var pivotWorld: Vec3? {
        guard let p = stand.pivot else { return nil }
        let l = layout, o = contentOrigin
        return Vec3((o.x + l.pictureOffset.x + p.x * Paper.cell) / Paper.unit, 0, (o.y + l.pictureOffset.y + p.y * Paper.cell) / Paper.unit)
    }

    /// Between frames (PaperModel.settle): a step that stands has the paper tilt; one that doesn't, the paper lie flat.
    func standCheck(at t: Double) {
        guard leftAt == nil, let paper, paper.solid else { return }
        let st = state()
        // held part way up by a finger: it follows the finger
        if let h = paper.standHeld(st) {
            stand.pivot = h.pivot; stand.held = max(0, min(1, h.up)); stand.upAt = nil; stand.downAt = nil
            if TiltCamera.owner !== self { if let o = TiltCamera.owner, o.holdsCamera { o.lieFlat() }; TiltCamera.owner = self }
            return
        }
        // let go: on up on the spring when the step now stands, else back down flat
        if let was = stand.held {
            stand.held = nil; stand.from = was
            if paper.stands(st) != nil { stand.upAt = t; stand.downAt = nil; stand.stoodOnce = true; return }
            stand.upAt = t; stand.downAt = t; stand.downTime = TiltCamera.beat * 0.6
            return
        }
        let want = paper.stands(st)
        if let p = want {
            if !stand.standing {
                stand.from = stand.blend(at: t, instant: instant)
                let wait = stand.stoodOnce ? 0 : paper.standDelay(st)
                stand.stoodOnce = true
                stand.pivot = p; stand.downAt = nil; stand.upAt = t + (instant && PaperClock.slow == 1 ? 0 : wait)
                if let o = TiltCamera.owner, o !== self, o.holdsCamera { o.lieFlat() }
                TiltCamera.owner = self
            } else if stand.pivot != p { stand.pivot = p }
        } else if stand.standing { lieFlat(over: TiltCamera.beat, after: paper.lingers(state())) }
    }

    /// The paper lies flat again over `duration`, `after` seconds from now (what stood stays a moment first).
    func lieFlat(over duration: Double, after: Double = 0) {
        guard stand.standing else { return }
        let now = PaperClock.now
        stand.from = stand.blend(at: now, instant: instant); stand.downAt = now + (instant && PaperClock.slow == 1 ? 0 : after); stand.downTime = instant && PaperClock.slow == 1 ? 0.0001 : duration
    }

    /// The tilted view at `b` (0 flat, 1 standing), from the flat camera's: the pivot where the flat camera shows it, at its zoom.
    func standingView(_ b: Double, flat: PaperView3D, screen: Size) -> PaperView3D? {
        guard let P = pivotWorld else { return nil }
        var v = PaperView3D(elevation: PaperView3D.flat + (PaperView3D.tilted.elevation - PaperView3D.flat) * b, azimuth: PaperView3D.tilted.azimuth * b, scale: flat.scale)
        let s = flat.project(P, screen: screen), (_, r, u) = v.axes
        v.target = P + r * ((screen.width / 2 - s.x) / v.scale) + u * ((s.y - screen.height / 2) / v.scale)
        return v
    }

    func view(at t: Double, flat: PaperView3D) -> PaperView3D? {
        guard stand.holds(at: t) else { return nil }
        let b = stand.blend(at: t, instant: instant)
        return b > 0.0001 ? standingView(b, flat: flat, screen: TiltCamera.screen) : nil
    }
    func settle(at t: Double, flat: PaperView3D) {
        if !stand.holds(at: t) { stand.clear() }
    }
    var holdsCamera: Bool { stand.holds(at: PaperClock.now) }
    var flatEnds: Double? { stand.downAt.map { $0 + stand.downTime * StandTilt.slow }.flatMap { $0 > PaperClock.now ? $0 : nil } }
    func lieFlat() { lieFlat(over: TiltCamera.away) }
    /// The view now while it stands (or tilts), nil flat.
    var standingNow: PaperView3D? { view(at: PaperClock.now, flat: TiltCamera.flatNow) }

    /// A tap on a block or a box (they stand where the flat paper has them), else the paper under the finger.
    func tapPoint(_ s: Point) -> Point? {
        guard let v = standingNow else { return nil }
        let f = TiltCamera.flatNow.unproject(s, screen: TiltCamera.screen), u = Point(f.x * Paper.unit, f.z * Paper.unit)
        if ProblemLayout.blocks(self).contains(where: { $0.rect.insetBy(dx: -Paper.cell, dy: -Paper.cell).contains(CGPoint(x: u.x, y: u.y)) }) { return u }
        let p = v.unproject(s, screen: TiltCamera.screen)
        return Point(p.x * Paper.unit, p.z * Paper.unit)
    }
    func dragPoint(_ s: Point) -> Point? {
        // held part way up by the finger: the finger is read on the flat paper (it's the tilt it's moving)
        guard stand.held == nil, let v = standingNow else { return nil }
        let p = v.unproject(s, screen: TiltCamera.screen)
        return Point(p.x * Paper.unit, p.z * Paper.unit)
    }
    /// A pan or a pinch moves the flat camera, which the standing view follows.
    func pan(_ dx: Double, _ dy: Double) -> Bool { false }
    func pinch(_ f: Double) -> Bool { false }

    /// The words' board while the paper stands: the problem's drawing (in the paper's points) turned to face the eye
    /// through the pivot, nearer the eye and smaller by as much (so the cubes never hide it), showing exactly where the flat
    /// paper would; nil flat.
    func board(_ v: PaperView3D, screen: Size) -> Transform? {
        guard holdsCamera, let P = pivotWorld, v.elevation < PaperView3D.flat - 0.01 else { return nil }
        let (dir, right, up) = v.axes, s = v.project(P, screen: screen)
        let (at, k) = v.standing(s, ahead: 20, screen: screen)
        func f(_ a: Vec3) -> SIMD3<Float> { SIMD3(Float(a.x), Float(a.y), Float(a.z)) }
        let R = simd_float3x3(columns: (f(right), f(dir), f(up * -1))), q = simd_quatf(R)
        let local = SIMD3<Float>(Float(P.x), 0, Float(P.z)) * Float(k)
        return Transform(scale: SIMD3(repeating: Float(k)), rotation: q, translation: f(at) - q.act(local))
    }

    /// A point of the picture (squares, on the paper) where it shows now: standing, on the board.
    func shown(_ p: CGPoint) -> CGPoint {
        guard holdsCamera, let pv = stand.pivot else { return p }
        return Standing(pivot: pv, eye: standEye).up(p.x, p.y, 0)
    }
    /// Where the camera looks while the paper stands, in the picture's squares (to the nearest two): the flat camera's
    /// middle, which the standing view keeps on the board.
    var standEye: CGPoint? {
        // the picture's top from the plan (the layout itself reads this, through the problem's state)
        guard holdsCamera, let top = plan?.pictureTop else { return nil }
        let t = TiltCamera.flatNow.floorTarget, o = contentOrigin
        func q(_ v: Double) -> Double { (v / 2).rounded() * 2 }
        return CGPoint(x: q((t.x * Paper.unit - o.x) / Paper.cell), y: q((t.z * Paper.unit - o.y) / Paper.cell - top))
    }
}

// MARK: drawing what stands

extension Rig {
    /// A paper lesson's solids, while its problem is on the paper.
    func drawSolids(_ m: WorkProblem, _ page: BarsPage, at t: Double) {
        guard let paper = m.paper, paper.solid else { return }
        let d = solids[m.id] ?? { let d = SolidsDrawer(rig: self); barsRoot.addChild(d.root); solids[m.id] = d; return d }()
        let l = m.layout, o = m.contentOrigin
        d.root.position = SIMD3(Float((o.x + l.pictureOffset.x) / Paper.unit), 0, Float((o.y + l.pictureOffset.y) / Paper.unit))
        let key = stackedStillKey(m, page, dark: dark ?? false) + stackedLiveKey(m, at: t, dark: dark ?? false)
        if key != d.key { d.key = key; d.solids = paper.draw(m.state(at: t)).solids }
        d.draw(chapter: m.chapter.hex, view: view, screen: screen, instant: m.instant && PaperClock.slow == 1, opened: m.openedAt + 0.3, left: m.leftAt, at: t)
    }
}

/// Draws a lesson's Solids into the paper's scene: faces (folding on their hinges on the spring), layers of cubes (rising,
/// sinking), lines, and labels standing facing the child. Its root sits on the picture's top-left corner and is a square
/// a unit, so everything is in the picture's squares (x across, z down the paper, y up off it).
@MainActor
final class SolidsDrawer {
    unowned let rig: Rig
    let root = Entity()
    var key = ""
    var solids = Solids()
    init(rig: Rig) { self.rig = rig; root.scale = SIMD3(repeating: Float(Standing.c)) }

    private final class FaceNode {
        let fill = ModelEntity(), edge = ModelEntity()
        var shown = 0.0, target = 0.0, from = 0.0, start = -100.0
        var pts: [Vec3] = [], look: Solids.Look = .auto, sig = ""
        var born = 0.0
    }
    private var faces: [String: FaceNode] = [:]
    private final class BlockNode { let e = ModelEntity(); var sig = ""; var riseAt = 0.0; var sinkAt: Double?; var lookKey = "" }
    private var blocks: [String: BlockNode] = [:]
    private var lines: [String: (e: ModelEntity, sig: String)] = [:]
    private var labels: [String: (stand: Stand, at: Vec3)] = [:]
    private final class BodyNode { let fill = ModelEntity(), edges = ModelEntity(), marks = ModelEntity(), outline = ModelEntity(); var sig = "", outlineSig = "" }
    private var bodies: [String: BodyNode] = [:]
    /// The bodies' shades: 9 steps from the top's to the side's, for each tone (auto, lit, red).
    private var bodyMats: [UnlitMaterial] = [], markColour = UIColor.gray
    static let shades = 9
    private var lineScale = 0.0, lookKey = ""
    private var looks: (solid: [UnlitMaterial], ghost: [UnlitMaterial], lit: [UnlitMaterial], deep: UIColor)?
    private var fade = 1.0

    /// Lines keep their width on the screen: a stroke, in squares.
    private var stroke: Float { Float(Sketch.stroke / max(1, lineScale) / Standing.c) }

    private func colour(_ c: Sketch.Colour, chapter: UInt32, dark: Bool) -> UIColor {
        let paper: UInt32 = dark ? 0x121211 : 0xF3F2EF
        switch c {
        case .ink: return rig.colours.ink
        case .ink2: return rig.colours.ink2
        case .ink3: return UIColor(hex: dark ? 0x878177 : 0x8C867D)
        case .chapter: return UIColor(hex: dark ? Chapter.darkInk(chapter) : chapter)
        case .tint(let f): return UIColor(hex: Ink.mix(paper, dark ? Chapter.darkTint(chapter) : chapter, f))
        case .paper: return UIColor(hex: paper)
        case .line: return rig.colours.lineStrong
        case .hex(let l, let d): return UIColor(hex: dark ? d : l)
        }
    }
    /// A face's material for its look, and which way it faces now.
    private func material(_ look: Solids.Look, normal n: Vec3, chapter: UInt32, dark: Bool) -> UnlitMaterial {
        guard let looks else { return flat(.gray) }
        func by(_ set: [UnlitMaterial]) -> UnlitMaterial {
            let len = max(1e-9, n.length)
            if abs(n.z) / len > 0.8 { return set[0] }
            return abs(n.x) > abs(n.y) ? set[2] : set[1]
        }
        switch look {
        case .auto: return by(looks.solid)
        case .top: return looks.solid[0]
        case .front: return looks.solid[1]
        case .side: return looks.solid[2]
        case .lit: return by(looks.lit)
        case .ghost: return by(looks.ghost)
        case .paint(let c): return flat(colour(c, chapter: chapter, dark: dark))
        }
    }

    /// Draws them as they are at `t`. `opened`: when the problem drew in (they fade in with it); `left`: leaving (they fade).
    func draw(chapter: UInt32, view v: PaperView3D, screen: Size, instant: Bool, opened: Double, left: Double?, at t: Double) {
        let dark = rig.dark ?? false, lk = "\(chapter) \(dark)"
        if lk != lookKey {
            lookKey = lk
            let l = CubesDrawer.looks(chapter: chapter, dark: dark, paper: rig.paperHex)
            let surface = Ink.surface.hexValue(dark: dark)
            func face(_ f: Double) -> UnlitMaterial { flat(UIColor(hex: Ink.mix(surface, chapter, f))) }
            let lit = dark ? [face(0.95), face(0.82), face(0.7)] : [face(0.5), face(0.64), face(0.78)]
            looks = (l.solid, l.ghost, lit + [l.solid[3]], l.deep)
            // the bodies' shades: the cubes' top, front and side as one run (light from the top left), lit toward the
            // chapter's colour, red toward wrong's
            let red: UInt32 = dark ? 0xFF6B5E : 0xC8372D
            bodyMats = []
            for tone in 0..<3 {
                for i in 0..<Self.shades {
                    let t = Double(i) / Double(Self.shades - 1)
                    let f = dark ? 0.78 - 0.34 * t : 0.30 + 0.25 * t
                    var c = Ink.mix(surface, chapter, f)
                    if tone == 1 { c = Ink.mix(c, chapter, 0.45) }
                    if tone == 2 { c = Ink.mix(c, red, 0.42) }
                    bodyMats.append(flat(UIColor(hex: c)))
                }
            }
            markColour = UIColor(hex: Ink.mix(l.deep.hexValue, surface, 0.35))
            for b in bodies.values { b.sig = ""; b.outlineSig = "" }
            for n in faces.values { n.sig = "" }
            for b in blocks.values { b.lookKey = "" }
            for (id, l) in lines { lines[id] = (l.e, "") }
        }
        if rig.lineScale != lineScale { lineScale = rig.lineScale; for n in faces.values { n.sig = "" }; for (id, l) in lines { lines[id] = (l.e, "") }; for b in blocks.values { b.sig = "" }; for b in bodies.values { b.sig = ""; b.outlineSig = "" } }
        guard let looks else { return }
        // coming in with the problem, going with it
        let k = instant ? (left == nil ? 1 : 0) : min(ease((t - opened) / 0.4), left.map { 1 - ease((t - $0) / 0.3) } ?? 1)
        if k != fade { fade = k; root.isEnabled = k > 0.001; if k >= 1 { root.components.remove(OpacityComponent.self) } else { root.components.set(OpacityComponent(opacity: Float(k))) } }
        func P(_ p: Vec3) -> SIMD3<Float> { SIMD3(Float(p.x), Float(p.z), Float(p.y)) }

        // what plays by itself (a push, a turn) is drawn as it is now
        let s: Solids
        if let p = solids.play { s = p.at(min(t, p.start + p.length)) } else { s = solids }
        drawBodies(s.bodies, view: v)
        // faces: each folds to its angle on the spring (at once while a finger holds it)
        for f in s.faces {
            let n = faces[f.id] ?? {
                let n = FaceNode(); root.addChild(n.fill); n.fill.addChild(n.edge); n.born = t; faces[f.id] = n
                n.shown = f.from ?? f.angle; n.target = f.angle; n.from = n.shown
                if f.from != nil && !instant { n.start = t + f.delay } else { n.shown = f.angle }
                return n
            }()
            if f.live || instant { n.shown = f.angle; n.target = f.angle; n.start = -100 }
            else if f.angle != n.target { n.from = n.shown; n.target = f.angle; n.start = t + f.delay }
        }
        for (id, n) in faces where !s.faces.contains(where: { $0.id == id }) { n.fill.removeFromParent(); faces[id] = nil }
        for f in faces.values where f.start > 0 {
            let u = (t - f.start) / SketchDrawer.morphTime
            f.shown = f.from + (f.target - f.from) * glide(u)
            if u >= 1 { f.shown = f.target; f.start = -100 }
        }
        for f in s.faces {
            guard let n = faces[f.id] else { continue }
            let pts = s.placed(f) { faces[$0.id]?.shown ?? $0.angle }
            let normal = pts.count >= 3 ? (pts[1] - pts[0]).cross(pts[2] - pts[0]) : Vec3(0, 0, 1)
            let cat = abs(normal.z) / max(1e-9, normal.length) > 0.8 ? 0 : abs(normal.x) > abs(normal.y) ? 2 : 1
            let sig = "\(pts.map { "\(($0.x * 1000).rounded()),\(($0.y * 1000).rounded()),\(($0.z * 1000).rounded())" }) \(f.look) \(cat) \(f.edges) \(f.dashed) \(String(describing: f.edge))"
            guard sig != n.sig else { continue }
            n.sig = sig
            // on the paper, a hair over it (under the lines drawn on the paper)
            let lifted = pts.map { abs($0.z) < 0.001 ? Vec3($0.x, $0.y, f.over ? 0.0095 : 0.006) : $0 }
            n.fill.model = Self.polygon(lifted.map(P), flat: f.pts.map { CGPoint(x: $0.x, y: $0.y) }).map { ModelComponent(mesh: $0, materials: [material(f.look, normal: normal, chapter: chapter, dark: dark)]) }
            if f.edges {
                let segs = zip(lifted, lifted.dropFirst() + [lifted[0]]).map { (P($0), P($1)) }
                n.edge.model = Self.bars(f.dashed ? Self.dashed(segs) : segs, width: stroke)
                    .map { ModelComponent(mesh: $0, materials: [flat(f.edge.map { colour($0, chapter: chapter, dark: dark) } ?? (f.dashed ? colour(.chapter, chapter: chapter, dark: dark) : looks.deep))]) }
            } else { n.edge.model = nil }
        }

        // layers of cubes: one piece each, rising from the one under it
        for b in s.blocks {
            let n = blocks[b.id] ?? { let n = BlockNode(); root.addChild(n.e); n.riseAt = instant ? -100 : t + b.delay; blocks[b.id] = n; return n }()
            if n.sinkAt != nil { n.sinkAt = nil; n.riseAt = t }
            let sig = "\(b.l) \(b.w) \(b.B)"
            if sig != n.sig {
                n.sig = sig
                n.e.model = CubesDrawer.layerMesh(length: b.l, width: b.w, edge: stroke / Float(b.B)).map { ModelComponent(mesh: $0, materials: looks.solid) }
                n.lookKey = ""
            }
            let lk = "\(b.look)"
            if lk != n.lookKey { n.lookKey = lk; n.e.model?.materials = b.look == .lit ? looks.lit : b.look == .ghost ? looks.ghost : looks.solid }
            n.e.position = P(b.at)
        }
        for (id, n) in blocks where !s.blocks.contains(where: { $0.id == id }) && n.sinkAt == nil { n.sinkAt = instant ? t - 100 : t }
        for (id, n) in blocks {
            let B = Float(s.blocks.first { $0.id == id }?.B ?? Double(n.e.scale.x))
            var h = ease((t - n.riseAt) / CubesTiming.rise)
            if let k = n.sinkAt { h = min(h, 1 - ease((t - k) / 0.35)); if t - k > 0.35 { n.e.removeFromParent(); blocks[id] = nil; continue } }
            n.e.isEnabled = h > 0.001
            n.e.scale = SIMD3(B, B * Float(max(0.0001, h)), B)
        }

        // lines (a box's full height, dashed)
        for l in s.lines {
            let sig = "\(l.pts.map { "\($0.x),\($0.y),\($0.z)" }) \(l.colour) \(l.dashed)"
            if let was = lines[l.id], was.sig == sig { continue }
            let e = lines[l.id]?.e ?? { let e = ModelEntity(); root.addChild(e); return e }()
            var segs = zip(l.pts, l.pts.dropFirst()).map { (P($0), P($1)) }
            if l.dashed { segs = Self.dashed(segs) }
            e.model = Self.bars(segs, width: stroke).map { ModelComponent(mesh: $0, materials: [flat(colour(l.colour, chapter: chapter, dark: dark))]) }
            lines[l.id] = (e, sig)
        }
        for (id, l) in lines where !s.lines.contains(where: { $0.id == id }) { l.e.removeFromParent(); lines[id] = nil }

        // labels, standing facing the child on their points
        let o = root.position
        for lb in s.labels {
            let st = labels[lb.id]?.stand ?? { let st = Stand(lift: 0.05); rig.barsRoot.addChild(st.root); return st }()
            labels[lb.id] = (st, lb.at)
            st.show("\(lb.text) \(lb.words.colour) \(dark) \(lb.anchor)", {
                var sk = Sketch(); sk.label("l", lb.text, lb.words, at: .zero, anchor: lb.anchor); return sk
            }(), rig: rig, chapter: chapter, start: opened, left: left, at: t)
            let w = Vec3(Double(o.x) + lb.at.x * Standing.c, lb.at.z * Standing.c, Double(o.z) + lb.at.y * Standing.c)
            let q = v.project(w, screen: screen)
            st.place(CGPoint(x: q.x, y: q.y), v, screen: screen)
        }
        for (id, l) in labels where !s.labels.contains(where: { $0.id == id }) { l.stand.root.removeFromParent(); labels[id] = nil }
    }

    /// Something is still moving: a face folding, a layer rising or sinking, something playing by itself.
    func moving(at t: Double) -> Bool {
        faces.values.contains { $0.start > 0 } || blocks.values.contains { t - $0.riseAt < CubesTiming.rise || $0.sinkAt != nil }
            || (solids.play.map { t <= $0.start + $0.length + 0.05 } ?? false)
    }

    func clear() { root.removeFromParent(); for l in labels.values { l.stand.root.removeFromParent() } }

    // MARK: bodies

    /// The bodies as they are: a mesh each (rebuilt only when they move), and the outline its round parts show from
    /// where the camera looks now.
    private func drawBodies(_ list: [Solids.Body], view v: PaperView3D) {
        guard let looks else { return }
        let d = v.axes.dir, eye = Vec3(d.x, d.z, d.y)
        for b in list {
            let n = bodies[b.id] ?? { let n = BodyNode(); root.addChild(n.fill); root.addChild(n.edges); root.addChild(n.marks); root.addChild(n.outline); bodies[b.id] = n; return n }()
            func r(_ x: Double) -> Int { Int((x * 100).rounded()) }
            let sig = "\(b.facets.count) \(b.facets.first.map { $0.map { "\(r($0.x)),\(r($0.y)),\(r($0.z))" }.joined() } ?? "") \(b.facets.last.map { $0.map { "\(r($0.x)),\(r($0.y)),\(r($0.z))" }.joined() } ?? "") \(b.edges.count) \(b.marks.count) \(b.tone) \(b.tones.map { "\($0)" } ?? "")"
            if sig != n.sig {
                n.sig = sig; n.outlineSig = ""
                n.fill.model = Self.bodyMesh(b).map { ModelComponent(mesh: $0, materials: bodyMats) }
                n.edges.model = Self.bars(b.edges.flatMap { l in zip(l, l.dropFirst()).map { (Self.P($0), Self.P($1)) } }, width: stroke)
                    .map { ModelComponent(mesh: $0, materials: [flat(looks.deep)]) }
                n.marks.model = Self.bars(b.marks.flatMap { l in zip(l, l.dropFirst()).map { (Self.P($0), Self.P($1)) } }, width: stroke * 0.8)
                    .map { ModelComponent(mesh: $0, materials: [flat(markColour)]) }
            }
            // the outline of what's round, as it's seen now
            let os = "\(r(eye.x * 50)) \(r(eye.y * 50)) \(r(eye.z * 50)) \(n.sig)"
            if os != n.outlineSig {
                n.outlineSig = os
                let segs = b.rounds.flatMap { Self.outline($0, eye: eye) }.flatMap { l in zip(l, l.dropFirst()).map { (Self.P($0), Self.P($1)) } }
                n.outline.model = Self.bars(segs, width: stroke).map { ModelComponent(mesh: $0, materials: [flat(looks.deep)]) }
            }
        }
        for (id, n) in bodies where !list.contains(where: { $0.id == id }) {
            for e in [n.fill, n.edges, n.marks, n.outline] { e.removeFromParent() }
            bodies[id] = nil
        }
    }
    private static func P(_ p: Vec3) -> SIMD3<Float> { SIMD3(Float(p.x), Float(p.z), Float(p.y)) }

    /// A body's facets as one mesh: each facet's material is its tone's shade for the way it faces (outward, from the
    /// body's middle): score = up − right, the top lightest, the right side darkest.
    static func bodyMesh(_ b: Solids.Body) -> MeshResource? {
        let all = b.facets.flatMap { $0 }
        guard !all.isEmpty else { return nil }
        let c = all.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(all.count))
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = [], mats: [UInt32] = []
        for (i, f) in b.facets.enumerated() where f.count >= 3 {
            let m = f.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(f.count))
            var nrm = Vec3(0, 0, 1)
            for k in 1..<(f.count - 1) { let q = (f[k] - f[0]).cross(f[k + 1] - f[0]); if q.length > 1e-9 { nrm = q.normalized; break } }
            if nrm.dot(m - c) < 0 { nrm = nrm * -1 }
            let score = max(-1, min(1, nrm.z - nrm.x)), level = Int(((1 - score) / 2 * Double(shades - 1)).rounded())
            let tone = b.tones?[safe: i] ?? b.tone
            let mat = UInt32((tone == .lit ? 1 : tone == .red ? 2 : 0) * shades + level)
            let start = UInt32(pos.count)
            pos += f.map(P)
            for k in 1..<(f.count - 1) {
                let a = start, p1 = start + UInt32(k), p2 = start + UInt32(k + 1)
                idx += [a, p1, p2, a, p2, p1]; mats += [mat, mat]
            }
        }
        guard !idx.isEmpty else { return nil }
        var d = MeshDescriptor(name: "body")
        d.positions = MeshBuffers.Positions(pos)
        d.primitives = .triangles(idx)
        d.materials = .perFace(mats)
        return try? MeshResource.generate(from: [d])
    }

    /// The outline a round part shows from `eye` (the way to the camera): a sphere's circle across the view, a
    /// cylinder's two sides, a cone's two sides to its point (none when it's seen end on).
    static func outline(_ r: Solids.Round, eye e: Vec3) -> [[Vec3]] {
        let d = e.normalized
        func ring(_ c: Vec3, _ u: Vec3, _ v: Vec3, _ rad: Double) -> [Vec3] { (0...48).map { i in let a = Double(i) / 48 * 2 * .pi; return c + u * (rad * cos(a)) + v * (rad * sin(a)) } }
        func perp(_ a: Vec3) -> Vec3 { abs(a.z) < 0.9 ? a.cross(Vec3(0, 0, 1)).normalized : a.cross(Vec3(1, 0, 0)).normalized }
        switch r {
        case .sphere(let c, let rad):
            let u = perp(d), v = d.cross(u).normalized
            return [ring(c, u, v, rad * 1.012)]
        case .cylinder(let a0, let a1, let rad):
            let ax = (a1 - a0).normalized, side = ax.cross(d)
            guard side.length > 0.05 else { return [] }
            let s = side.normalized * (rad * 1.01)
            return [[a0 + s, a1 + s], [a0 - s, a1 - s]]
        case .cone(let base, let apex, let rad):
            let ax = (apex - base).normalized, h = (apex - base).length
            let dp = d - ax * d.dot(ax), m = dp.length
            guard m > 1e-6 else { return [] }
            let e1 = dp * (1 / m), e2 = ax.cross(e1), cs = -rad * d.dot(ax) / (h * m)
            guard abs(cs) <= 1 else { return [] }
            let sn = (1 - cs * cs).squareRoot()
            return [1.0, -1.0].map { k in [base + (e1 * cs + e2 * (k * sn)) * (rad * 1.01), apex] }
        }
    }

    // MARK: meshes

    /// A flat shape in space, both sides: cut into triangles as it lies flat (`flat`, its corners on the paper), so one
    /// that bends in (half an arrow) fills as itself.
    static func polygon(_ pts: [SIMD3<Float>], flat: [CGPoint]? = nil) -> MeshResource? {
        guard pts.count >= 3 else { return nil }
        var idx: [UInt32] = []
        for (a, b, c) in triangles(flat ?? pts.map { CGPoint(x: Double($0.x), y: Double($0.z)) }) {
            idx += [UInt32(a), UInt32(b), UInt32(c), UInt32(a), UInt32(c), UInt32(b)]
        }
        var d = MeshDescriptor(name: "face")
        d.positions = MeshBuffers.Positions(pts)
        d.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [d])
    }
    /// A polygon's triangles by its corners' indexes (ear clipping).
    static func triangles(_ p: [CGPoint]) -> [(Int, Int, Int)] {
        var v = Array(p.indices)
        let area = p.indices.reduce(0.0) { s, i in let a = p[i], b = p[(i + 1) % p.count]; return s + a.x * b.y - b.x * a.y }
        if area < 0 { v.reverse() }
        func cross(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double { (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x) }
        var out: [(Int, Int, Int)] = [], tries = 0
        while v.count > 3 && tries < 500 {
            tries += 1
            var cut = false
            for k in v.indices {
                let i0 = v[(k + v.count - 1) % v.count], i1 = v[k], i2 = v[(k + 1) % v.count]
                guard cross(p[i0], p[i1], p[i2]) > 1e-9 else { continue }
                let inside = v.contains { j in j != i0 && j != i1 && j != i2 && A7.inside([p[i0], p[i1], p[i2]], p[j]) }
                if inside { continue }
                out.append((i0, i1, i2)); v.remove(at: k); cut = true; break
            }
            // what's left doesn't clip cleanly (corners in a line): a fan
            if !cut { for k in 1..<(v.count - 1) { out.append((v[0], v[k], v[k + 1])) }; return out }
        }
        if v.count == 3 { out.append((v[0], v[1], v[2])) }
        return out
    }
    /// Thin square bars along segments in space, `width` across (a line drawn in 3D).
    static func bars(_ segs: [(SIMD3<Float>, SIMD3<Float>)], width: Float) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let h = width / 2
        for (a, b) in segs where simd_distance(a, b) > 1e-5 {
            let d = simd_normalize(b - a)
            let ref: SIMD3<Float> = abs(d.y) < 0.9 ? [0, 1, 0] : [1, 0, 0]
            let p1 = simd_normalize(simd_cross(d, ref)) * h, p2 = simd_normalize(simd_cross(d, p1)) * h
            let a0 = a - d * h, b0 = b + d * h, base = UInt32(pos.count)
            for k in 0..<8 { pos.append((k & 4 == 0 ? a0 : b0) + (k & 1 == 0 ? p1 : -p1) + (k & 2 == 0 ? p2 : -p2)) }
            for f in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]] {
                let q = f.map { base + UInt32($0) }
                idx += [q[0], q[1], q[2], q[0], q[2], q[3], q[0], q[2], q[1], q[0], q[3], q[2]]
            }
        }
        guard !pos.isEmpty else { return nil }
        var d = MeshDescriptor(name: "bars")
        d.positions = MeshBuffers.Positions(pos)
        d.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [d])
    }
    /// Segments broken into dashes (in squares: on 0.35, every 0.75).
    static func dashed(_ segs: [(SIMD3<Float>, SIMD3<Float>)]) -> [(SIMD3<Float>, SIMD3<Float>)] {
        segs.flatMap { a, b -> [(SIMD3<Float>, SIMD3<Float>)] in
            let len = simd_distance(a, b), d = (b - a) / max(1e-6, len)
            var out: [(SIMD3<Float>, SIMD3<Float>)] = [], s: Float = 0
            while s < len { out.append((a + d * s, a + d * min(len, s + 0.35))); s += 0.75 }
            return out
        }
    }
}
