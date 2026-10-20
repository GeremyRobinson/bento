import SwiftUI
import RealityKit

/// Unit cubes' words and blocks, in the paper's scene (G 17 Oct: SwiftUI on top jiggled against the cubes as the camera
/// moved). Each sits on a point of the paper and stands facing the child at any tilt, the size the paper is.
/// The camera has no perspective, so each is slid toward it along its own line of sight: it shows exactly where its point
/// is and the same size, but in front of the cubes, so they never hide it.
@MainActor
enum CubesLayout {
    enum Kind: Equatable { case main, showMe, reset }
    /// The blocks' places in points from their point on the paper (x right, y down): the main action (Show me and
    /// Start over are in the bar).
    static func blocks(_ m: UnitCubesModel) -> [(kind: Kind, rect: CGRect)] {
        [(.main, CGRect(x: 0, y: 0, width: 180, height: 40))]
    }
    /// The paper points the words hang from.
    static func blocksAt(_ m: UnitCubesModel) -> Vec3 { Vec3(m.origin.x, 0, m.origin.z + Double(m.box.width) + 1) }
    static func countAt(_ m: UnitCubesModel) -> Vec3 { Vec3(m.origin.x, 0, m.origin.z + Double(m.box.width) + 0.6) }
    static func questionAt(_ m: UnitCubesModel, tilt: Double) -> Vec3 {
        Vec3(m.origin.x - 0.4 * tilt, 4.6 * tilt, m.origin.z - 0.6 * (1 - tilt))
    }

    /// The block under a screen point, if any.
    static func block(at s: Point, _ m: UnitCubesModel) -> Kind? {
        let v = m.view(at: PaperClock.now), a = v.project(blocksAt(m), screen: m.screen), k = v.scale / Paper.unit
        return blocks(m).first { b in
            let r = b.rect
            return s.x >= a.x + r.minX * k && s.x <= a.x + r.maxX * k && s.y >= a.y + r.minY * k && s.y <= a.y + r.maxY * k
        }?.kind
    }
}

/// One standing word group: built in points, x right and y down from its point, facing the camera.
@MainActor
final class Pin {
    let root = Entity()
    init() { root.scale = SIMD3(repeating: Float(1 / Paper.unit)) }

    func clear() { for c in Array(root.children) { c.removeFromParent() } }

    /// Puts the group on `p`, facing the view, slid toward the camera so nothing hides it, and nudged down `drop` points.
    func place(_ p: Vec3, _ v: PaperView3D, drop: Double = 0) {
        let (dir, right, up) = v.axes, u = Paper.unit
        let w = p + dir * 20 - up * (drop / u)
        root.position = SIMD3(Float(w.x), Float(w.y), Float(w.z))
        root.orientation = simd_quatf(simd_float3x3(columns: (SIMD3(Float(right.x), Float(right.y), Float(right.z)),
                                                             SIMD3(Float(up.x), Float(up.y), Float(up.z)),
                                                             SIMD3(Float(dir.x), Float(dir.y), Float(dir.z)))))
    }

    func fade(_ k: Double) {
        let q = snapped(k, 40)
        root.isEnabled = q > 0
        if q >= 1 { root.components.remove(OpacityComponent.self) } else { root.components.set(OpacityComponent(opacity: Float(q))) }
    }

    /// A line of text, the point `anchor` of its box at (x, y).
    func text(_ s: String, _ f: UIFont, _ c: UIColor, _ x: Double, _ y: Double, anchor: UnitPoint = .topLeading) {
        let e = PaperText.standing(s, f, c)
        let w = PaperText.width(s, f), h = Double(f.lineHeight)
        let left = x - anchor.x * w, bottom = y - anchor.y * h + h
        e.position = SIMD3(Float(left), Float(-bottom), 0.02)
        root.addChild(e)
    }

    /// A cell block: filled, its border inside its edge.
    func block(_ r: CGRect, fill: UIColor, stroke: UIColor) {
        func quad(_ q: CGRect, _ z: Float) -> MeshResource? {
            var d = MeshDescriptor(name: "pin")
            d.positions = MeshBuffers.Positions([SIMD3(Float(q.minX), Float(-q.minY), z), SIMD3(Float(q.maxX), Float(-q.minY), z),
                                                 SIMD3(Float(q.maxX), Float(-q.maxY), z), SIMD3(Float(q.minX), Float(-q.maxY), z)])
            d.primitives = .triangles([0, 2, 1, 0, 3, 2, 0, 1, 2, 0, 2, 3])
            return try? MeshResource.generate(from: [d])
        }
        if let m = quad(r, 0) { root.addChild(ModelEntity(mesh: m, materials: [flat(fill)])) }
        let i = r.insetBy(dx: 0.75, dy: 0.75), t = 1.5
        for edge in [CGRect(x: i.minX - t / 2, y: i.minY - t / 2, width: i.width + t, height: t),
                     CGRect(x: i.minX - t / 2, y: i.maxY - t / 2, width: i.width + t, height: t),
                     CGRect(x: i.minX - t / 2, y: i.minY - t / 2, width: t, height: i.height + t),
                     CGRect(x: i.maxX - t / 2, y: i.minY - t / 2, width: t, height: i.height + t)] {
            if let m = quad(edge, 0.01) { root.addChild(ModelEntity(mesh: m, materials: [flat(stroke)])) }
        }
    }

    func icon(_ name: String, _ c: UIColor, in r: CGRect) {
        guard let e = PaperText.icon(name, c, in: CGRect(x: 0, y: 0, width: 1, height: 1)), let material = e.model?.materials.first else { return }
        let plane = ModelEntity(mesh: .generatePlane(width: Float(r.width), height: Float(r.height)), materials: [material])
        plane.position = SIMD3(Float(r.midX), Float(-r.midY), 0.02)
        root.addChild(plane)
    }
}

extension Rig {
    /// Unit cubes' words: built when they change, placed every frame the view moves.
    func drawCubesWords(_ l: UnitCubesModel, view v: PaperView3D, at t: Double) {
        let dark = self.dark ?? false, words = l.lesson.words, b = l.box
        let key = [words.say, words.hint, words.action, l.message.map { "\($0.text)\($0.ok)" } ?? "", l.lesson.countLine ?? "",
                   "\(l.lesson.step.task != nil)", "\(l.lesson.helps)", "\(l.lesson.picture["showMe"] ?? 0)", "\(b)", "\(dark)"].joined(separator: "|")
        if key != cubesKey {
            cubesKey = key
            for p in [cubesQuestion, cubesL, cubesW, cubesH, cubesCount, cubesBlocks] { p.clear(); if p.root.parent == nil { lessonRoot.addChild(p.root) } }
            let ink = colours.ink, ink2 = colours.ink2, chapter = UIColor(hex: l.chapter.hex), right = UIColor(hex: dark ? 0x3CCF8E : 0x178A57)
            // the question, a story running onto more lines upward, and its hint under it
            let q = PaperText.font(28, .medium), h = Double(q.lineHeight)
            let lines = Array(PaperText.wrap(words.say, q, width: 480).prefix(4))
            for (i, line) in lines.enumerated() { cubesQuestion.text(line, q, ink, 0, -23 - Double(lines.count - i) * h) }
            cubesQuestion.text(words.hint, PaperText.font(18), ink2, 0, -10, anchor: UnitPoint(x: 0, y: 0.5))
            // the box's measures
            let label = PaperText.font(20, .semibold)
            cubesL.text("\(b.length)", label, ink, 0, 0, anchor: .center)
            cubesW.text("\(b.width)", label, ink, 0, 0, anchor: .center)
            cubesH.text("\(b.height)", label, ink, 0, 0, anchor: .center)
            // the count as the child taps, or what a miss says
            if l.lesson.step.task != nil {
                let (text, c) = l.message.map { ($0.text, $0.ok ? right : chapter) } ?? (l.lesson.countLine ?? "", ink2)
                cubesCount.text(text, PaperText.font(19, .medium), c, 0, 0)
            }
            // the blocks
            let surface = UIColor(hex: dark ? 0x1B1B1A : 0xFBFBFA), line = UIColor(hex: dark ? 0x3A3A37 : 0xCFCCC5), button = PaperText.font(17, .medium)
            for (kind, r) in CubesLayout.blocks(l) {
                let main = kind == .main || (kind == .showMe && l.lesson.picture["showMe"] == 1)
                cubesBlocks.block(r, fill: surface, stroke: main ? ink : line)
                switch kind {
                case .main:
                    cubesBlocks.text(words.action, button, ink, r.minX + 16, r.midY, anchor: UnitPoint(x: 0, y: 0.5))
                    cubesBlocks.icon("arrow-right", ink, in: CGRect(x: r.maxX - 30, y: r.midY - 10, width: 20, height: 20))
                case .showMe: cubesBlocks.icon("play", ink, in: CGRect(x: r.midX - 10, y: r.midY - 10, width: 20, height: 20))
                case .reset: cubesBlocks.icon("arrow-counter-clockwise", ink, in: CGRect(x: r.midX - 10, y: r.midY - 10, width: 20, height: 20))
                }
            }
        }
        let tilt = l.tilt(at: t), fresh = ease((t - l.wordsAt) / 0.5), L = Double(b.length), W = Double(b.width), H = Double(b.height), o = l.origin
        cubesQuestion.place(CubesLayout.questionAt(l, tilt: tilt), v, drop: (1 - fresh) * 8); cubesQuestion.fade(fresh)
        cubesL.place(Vec3(o.x + L / 2, 0, o.z + W + 0.3), v)
        cubesW.place(Vec3(o.x - 0.3, 0, o.z + W / 2), v)
        cubesH.place(Vec3(o.x + L + 0.3, H / 2, o.z + W), v); cubesH.fade(l.heightLabel(at: t))
        cubesCount.place(CubesLayout.countAt(l), v)
        cubesBlocks.place(CubesLayout.blocksAt(l), v); cubesBlocks.fade(l.busy ? 0.35 : 1)
    }
}

/// Words that stand up facing the child wherever the paper tilts (G 17 Oct: words stay pinned to the paper, facing the
/// child): a SketchDrawer whose paper is turned to face the camera, so they draw themselves in and out as every word on
/// the paper does. Built in points from their anchor (x right, y down) and slid toward the camera along its line of
/// sight, so the cubes never hide them; flat, they lie exactly on the paper.
@MainActor
final class Stand {
    let root = Entity()
    let drawer = SketchDrawer()
    var key = ""
    private let lift: Double
    init(lift: Double = 0) { self.lift = lift; root.addChild(drawer.root) }

    /// Puts its anchor on the screen point `s`, through view `v`.
    func place(_ s: CGPoint, _ v: PaperView3D, screen: Size) {
        let (dir, right, up) = v.axes
        let w = v.target + right * ((s.x - screen.width / 2) / v.scale) + up * ((screen.height / 2 - s.y) / v.scale) + dir * (20 + lift)
        root.position = SIMD3(Float(w.x), Float(w.y), Float(w.z))
        func f(_ a: Vec3) -> SIMD3<Float> { SIMD3(Float(a.x), Float(a.y), Float(a.z)) }
        // its paper's across is the screen's, its paper's down the screen's down, and it faces the camera
        root.orientation = simd_quatf(simd_float3x3(columns: (f(right), f(dir), f(up * -1))))
    }

    /// Draws `sketch` when `key` says it changed (from `start`), undraws when the problem leaves, and moves what's moving.
    func show(_ key: String, _ sketch: @autoclosure () -> Sketch, rig: Rig, chapter: UInt32, start: Double, left: Double?, at t: Double) {
        if left == nil, drawer.leftAt != nil { drawer.revive(); self.key = "" }
        if let left { drawer.undrawAll(at: left) }
        else if key != self.key {
            self.key = key
            drawer.build(sketch(), rig: rig, chapter: chapter, dark: rig.dark ?? false, origin: .zero, from: drawer.isEmpty ? max(t, start) : t, now: t)
        }
        _ = drawer.update(at: t)
    }
}

/// Volume of a box's words and blocks, standing facing the child (CubesProblem.places): what to do over the box, its
/// labels, each layer's running count on its front, the count of squares or the record under it, its blocks, and the
/// ghost finger that shows the hand move.
@MainActor
final class CubesWords {
    let root = Entity()
    let say = Stand(), count = Stand(), length = Stand(), width = Stand(), height = Stand(), record = Stand(lift: 0.1), finger = Stand(lift: 0.4)
    private var counts: [Stand] = []
    private let cursor = ModelEntity()
    private var cursorKey = ""

    init() {
        for s in [say, count, length, width, height, record, finger] { root.addChild(s.root) }
        record.root.addChild(cursor)
    }

    func draw(_ p: CubesProblem, rig: Rig, view v: PaperView3D, screen: Size, at t: Double) {
        let pl = p.places(v, screen: screen), k = pl.k, b = p.box, chapter = p.chapter.hex, dark = rig.dark ?? false
        let start = p.openedAt + 0.3, left = p.leftAt
        let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E), green = Sketch.Colour.hex(0x178A57, 0x3CCF8E)
        let tilted = p.camera != nil && p.flatAt == nil

        // what to do, over the box; under it what a miss says (red), a word about what's left (grey), or the hint
        let sayKey = "\(p.sayText)|\(p.message.map { "\($0.text)\($0.ok)" } ?? "")|\(p.hintText ?? "")|\(dark)"
        say.show(sayKey, {
            var s = Sketch()
            let n = s.words("say", p.sayText, .say, x: 0, top: 0, width: CubesProblem.wordsWidth, max: 2)
            if let m = p.message { s.words("msg", m.text, Sketch.Words(size: Sketch.small, weight: .medium, colour: m.ok ? .ink2 : red), x: 0, top: Double(n) * Sketch.row, width: CubesProblem.wordsWidth) }
            else if let h = p.hintText { s.words("hint", h, Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), x: 0, top: Double(n) * Sketch.row, width: CubesProblem.wordsWidth) }
            return s
        }(), rig: rig, chapter: chapter, start: start, left: left, at: t)
        say.place(pl.say, v, screen: screen)

        // the squares counted as the floor is covered, under it
        let covered = (0..<b.floor).filter { i in p.squares[i].map { $0.on && $0.at <= t } ?? false }.count
        let counting = p.lesson.step.task != nil && p.lesson.step.camera == .flat
        count.show(counting ? "\(covered) \(dark)" : "", {
            var s = Sketch()
            if counting { s.label("count", "\(covered) of \(b.floor) squares", Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), at: CGPoint(x: 0, y: Sketch.row / 2), anchor: UnitPoint(x: 0, y: 0.5), slot: "cubes\(p.id)") }
            return s
        }(), rig: rig, chapter: chapter, start: start, left: left, at: t)
        count.place(pl.record, v, screen: screen)

        // the box's measures: its length and width from the start, its height once it stands up
        let label = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
        for (stand, text, at, anchor, shown) in [(length, "\(b.length) cm", pl.length, UnitPoint.center, true), (width, "\(b.width) cm", pl.width, UnitPoint(x: 1, y: 0.5), true),
                                                 (height, "\(b.height) cm", pl.height, UnitPoint(x: 0, y: 0.5), p.heightShown(at: t))] {
            stand.show(shown ? "\(text) \(dark)" : "", {
                var s = Sketch()
                if shown { s.label("m", text, label, at: .zero, anchor: anchor) }
                return s
            }(), rig: rig, chapter: chapter, start: start + 0.4, left: left, at: t)
            stand.place(at, v, screen: screen)
        }

        // each layer's running count on its front, once it stands (lit after a miss, or counted up by Show me)
        while counts.count < b.height { let s = Stand(lift: 0.05); root.addChild(s.root); counts.append(s) }
        for (y, stand) in counts.enumerated() {
            var text = ""
            if y < b.height, tilted, p.lesson.step.task == nil || p.lesson.step.camera == .tilted {
                let stands: Bool = { if case .whole(let h) = p.layer(y, at: t) { return h > 0.97 } else { return false } }()
                if stands { text = VolumeOfBox.count(y, b) }
            }
            let preview = p.preview.map { $0.kind == .answer && t >= $0.at + 0.45 * Double(y) && t < $0.end - CubesProblem.Preview.fade } ?? false
            let lit = !text.isEmpty && (p.lesson.picture["counts"] == 1 || preview || (p.hinting && p.lesson.step.answer != nil))
            stand.show(text.isEmpty ? "" : "\(text) \(lit) \(dark)", {
                var s = Sketch()
                if !text.isEmpty { s.label("c", text, Sketch.Words(size: Sketch.small, weight: .semibold, colour: lit ? .chapter : .ink), at: .zero, anchor: .center) }
                return s
            }(), rig: rig, chapter: chapter, start: t, left: left, at: t)
            if y < pl.counts.count { stand.place(pl.counts[y], v, screen: screen) }
        }

        // the record under the box, and the blocks under it
        let lines = p.recordLines(at: t), typed = p.lesson.typed["x"] ?? ""
        let answering = p.preview?.kind == .answer && t < (p.preview?.end ?? 0) - CubesProblem.Preview.fade && t >= (p.preview?.at ?? 0) + 0.45 * Double(b.height)
        let shownTyped = p.wrongTyped ?? (answering && typed.isEmpty ? "\(b.volume)" : typed)
        let lineFont = PaperText.font(Sketch.wordSize, .medium)
        let boxX = lines.first(where: { $0.box }).map { ((PaperText.width($0.text, lineFont) + 20) / Paper.cell).rounded(.up) * Paper.cell } ?? 0
        let boxRect = CGRect(x: boxX, y: 60, width: 40 * Double(p.answerCells), height: 40)
        let verdict = p.verdict.map { $0.right }
        let recordKey = "\(lines.map(\.text))|\(shownTyped)|\(answering)|\(verdict as Bool?)|\(p.blockKinds)|\(dark)"
        record.show(recordKey, {
            var s = Sketch()
            for (i, line) in lines.enumerated() {
                s.words("r\(i)", line.text, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: line.chapter ? .chapter : .ink), x: 0, top: Double(i) * 60, width: 900)
            }
            if lines.contains(where: { $0.box }) {
                let style: Sketch.Block = verdict.map { $0 ? Sketch.Block(stroke: green, text: green) : Sketch.Block(stroke: red, text: red) } ?? .main
                s.block("box\(verdict as Bool?)", boxRect, style, grows: true)
                s.pace = 0
                if !shownTyped.isEmpty { s.text("typed\(shownTyped)\(verdict as Bool?)\(answering)", shownTyped, at: CGPoint(x: boxRect.midX, y: boxRect.midY), size: Sketch.maths, weight: .medium, answering ? .ink3 : style.text) }
                s.pace = 1
            }
            for bl in pl.blocks {
                let r = CGRect(x: (bl.rect.minX - pl.record.x) / k, y: (bl.rect.minY - pl.record.y) / k, width: bl.rect.width / k, height: bl.rect.height / k), id = "\(bl.kind)"
                switch bl.kind {
                case .main: s.block(id, r, .main, word: p.lesson.words.action, arrow: true)
                case .nextProblem: s.block(id, r, .main, word: "Next problem", arrow: true)
                case .next: s.block(id, r, .main, word: "Next step", arrow: true)
                case .practise: s.block(id, r, .main, word: "Practice", arrow: true)
                case .again: s.block(id, r, .plain, word: "Watch again")
                case .skip: s.block(id, r, .plain, word: "Skip")
                default: break
                }
            }
            return s
        }(), rig: rig, chapter: chapter, start: start, left: left, at: t)
        record.place(pl.record, v, screen: screen)

        // the cursor in the box, blinking as a cursor does, held still a moment after each key
        let since = t - p.typedAt
        let blink = p.wantsNumber && p.verdict == nil && left == nil && t - p.wordsAt > 0.4 && (since < 0.6 || (since - 0.6).truncatingRemainder(dividingBy: 1.06) < 0.53)
        cursor.isEnabled = blink && lines.contains { $0.box }
        if cursor.isEnabled {
            let x = boxRect.midX + PaperText.width(typed, PaperText.font(Sketch.maths, .medium, digits: true)) / 2 + 6, u = Paper.unit
            let key = "\(x) \(dark)"
            if key != cursorKey {
                cursorKey = key
                cursor.model = Rig.lines([(SIMD2(Float(x / u), Float((boxRect.minY + 9) / u)), SIMD2(Float(x / u), Float((boxRect.maxY - 9) / u)))], width: Float(Sketch.stroke / u))
                    .map { ModelComponent(mesh: $0, materials: [flat(rig.colours.ink)]) }
                cursor.position.y = 0.003
            }
        }

        // the ghost finger making the move (Show me, the How to), as it plays every lesson's moves: a soft round
        // fingertip, pressing while it drags, with a short trail behind it; drawn at once wherever it is now
        let f = p.finger, shows = snapped(f.map { $0.shown(t) } ?? 0, 12)
        if let f, shows > 0.05 {
            let q = v.project(f.at(t), screen: screen), down = f.down(t)
            // the trail: where the finger was a moment ago, in the words' points from the fingertip
            let trail: [CGPoint] = down ? (1...4).map { i in
                let w = v.project(f.at(t - 0.045 * Double(i) * CubesProblem.slow), screen: screen)
                return CGPoint(x: ((w.x - q.x) / k).rounded(), y: ((w.y - q.y) / k).rounded())
            } : []
            let key = "\(shows) \(down) \(trail.map { "\($0.x),\($0.y)" }) \(dark)"
            finger.show(key, Self.fingertip(down: down, trail: trail, shows: shows), rig: rig, chapter: chapter, start: t, left: nil, at: t)
            finger.place(CGPoint(x: q.x, y: q.y), v, screen: screen)
            finger.root.isEnabled = true
        } else {
            finger.show("", Sketch(), rig: rig, chapter: chapter, start: t, left: nil, at: t)
            finger.root.isEnabled = false
        }
    }

    /// The ghost finger (Show me, the How to; the same fingertip the flat lessons' moves are played with): a soft round
    /// tip in ink2 on the paper, a little smaller and firmer while it presses, a short trail behind it as it drags, and
    /// coming and going by fading into the paper (`shows`). Drawn at once: it moves every frame.
    static func fingertip(down: Bool, trail: [CGPoint], shows: Double) -> Sketch {
        var s = Sketch()
        s.pace = 0
        let paper: (UInt32, UInt32) = (0xF3F2EF, 0x121211), ink2: (UInt32, UInt32) = (0x6B6964, 0xA3A19B)
        func soft(_ k: Double) -> Sketch.Colour { .hex(Ink.mix(paper.0, ink2.0, k * shows), Ink.mix(paper.1, ink2.1, k * shows)) }
        func ring(_ c: CGPoint, _ r: Double, _ n: Int) -> [CGPoint] { (0...n).map { i in let a = Double(i) / Double(n) * 2 * .pi; return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) } }
        let cell = Paper.cell
        for (i, q) in trail.enumerated() {
            let k = Double(trail.count - i) / Double(trail.count + 1)
            s.polygon("trail\(i)", Array(ring(q, cell * (0.35 + 0.35 * k), 28).dropLast()), soft(0.1 + 0.12 * k))
        }
        // the tip over its trail (a plate sits over fills), its ring over both
        let r = cell * (down ? 0.82 : 0.95)
        s.plate("tip", Array(ring(.zero, r, 28).dropLast()), soft(down ? 0.34 : 0.24))
        s.overLine("ring", ring(.zero, r, 32), soft(0.75), width: Sketch.stroke)
        return s
    }
}
