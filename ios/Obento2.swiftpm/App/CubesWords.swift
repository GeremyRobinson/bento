import SwiftUI
import RealityKit

/// Unit cubes' words and blocks, in the paper's scene (G 17 Oct: SwiftUI on top jiggled against the cubes as the camera
/// moved). Each sits on a point of the paper and stands facing the child at any tilt, the size the paper is.
/// The camera has no perspective, so each is slid toward it along its own line of sight: it shows exactly where its point
/// is and the same size, but in front of the cubes, so they never hide it.
@MainActor
enum CubesLayout {
    enum Kind: Equatable { case main, showMe, reset }
    /// The blocks' places in points from their point on the paper (x right, y down), as one row: Show me (not in the
    /// skill check), Reset, a gap, the main action.
    static func blocks(_ m: UnitCubesModel) -> [(kind: Kind, rect: CGRect)] {
        var out: [(Kind, CGRect)] = [], x = 0.0
        if m.lesson.step.task != nil {
            if m.lesson.helps { out.append((.showMe, CGRect(x: x, y: 0, width: 40, height: 40))); x += 38.5 }
            out.append((.reset, CGRect(x: x, y: 0, width: 40, height: 40))); x += 38.5 + 38.5
        }
        out.append((.main, CGRect(x: x, y: 0, width: 180, height: 40)))
        return out
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
            for (i, line) in lines.enumerated() { cubesQuestion.text(line, q, ink, 0, -20 - Double(lines.count - i) * h) }
            cubesQuestion.text(words.hint, PaperText.font(16), ink2, 0, -10, anchor: UnitPoint(x: 0, y: 0.5))
            // the box's measures
            let label = PaperText.font(20, .semibold)
            cubesL.text("\(b.length)", label, ink, 0, 0, anchor: .center)
            cubesW.text("\(b.width)", label, ink, 0, 0, anchor: .center)
            cubesH.text("\(b.height)", label, ink, 0, 0, anchor: .center)
            // the count as the child taps, or what a miss says
            if l.lesson.step.task != nil {
                let (text, c) = l.message.map { ($0.text, $0.ok ? right : chapter) } ?? (l.lesson.countLine ?? "", ink2)
                cubesCount.text(text, PaperText.font(17, .medium), c, 0, 0)
            }
            // the blocks
            let surface = UIColor(hex: dark ? 0x1B1B1A : 0xFBFBFA), line = UIColor(hex: dark ? 0x3A3A37 : 0xCFCCC5), button = PaperText.font(15, .medium)
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
