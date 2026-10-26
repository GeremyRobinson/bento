import SwiftUI
import RealityKit

extension Rig {
    /// Volume of a box on a lesson's page: its cubes and its standing words, drawn while it's on the paper.
    func drawCubesProblem(_ c: CubesProblem, at t: Double) {
        let d = problemCubes[c.id] ?? {
            let d = (cubes: CubesDrawer(rig: self), words: CubesWords())
            barsRoot.addChild(d.cubes.root); barsRoot.addChild(d.words.root); problemCubes[c.id] = d
            return d
        }()
        Perf.time("cubes") { d.cubes.draw(c, at: t) }
        Perf.time("cubes-words") { d.words.draw(c, rig: self, view: view, screen: screen, at: t) }
    }
    /// The cubes and words of every problem no longer on the paper go (all of them when the page closes).
    func clearCubesProblems(keeping shown: [any PageProblem]) {
        for (id, d) in problemCubes where !shown.contains(where: { $0.id == id }) {
            d.cubes.root.removeFromParent(); d.words.root.removeFromParent(); problemCubes[id] = nil
        }
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
    /// `budget`: how many groups of words may still be made this frame; one that may not waits for the next frame
    /// (making many lines' letters at once held a frame up). Returns whether it made its words.
    @discardableResult
    func show(_ key: String, _ sketch: @autoclosure () -> Sketch, rig: Rig, chapter: UInt32, start: Double, left: Double?, at t: Double, budget: inout Int) -> Bool {
        var made = false
        if left == nil, drawer.leftAt != nil { drawer.revive(); self.key = "" }
        if let left { drawer.undrawAll(at: left) }
        else if key != self.key, budget > 0 {
            budget -= 1; made = true
            self.key = key
            let s = sketch()
            Perf.time("cubes-words-build") { drawer.build(s, rig: rig, chapter: chapter, dark: rig.dark ?? false, origin: .zero, from: drawer.isEmpty ? max(t, start) : t, now: t) }
        }
        _ = drawer.update(at: t)
        return made
    }
    /// The same, free of any budget (the ghost finger, made again every frame it moves).
    func show(_ key: String, _ sketch: @autoclosure () -> Sketch, rig: Rig, chapter: UInt32, start: Double, left: Double?, at t: Double) {
        var free = 1
        show(key, sketch(), rig: rig, chapter: chapter, start: start, left: left, at: t, budget: &free)
    }
}

/// Volume of a box's words and blocks, standing facing the child (CubesProblem.places): what to do over the box, its
/// labels, each layer's own count on its front, the count of squares or the record by it, its blocks, and the ghost
/// finger that shows the hand move.
@MainActor
final class CubesWords {
    let root = Entity()
    let say = Stand(), count = Stand(), length = Stand(), width = Stand(), height = Stand(), record = Stand(lift: 0.1), finger = Stand(lift: 0.4)
    /// The record's lines, one group of words each, and each layer's count.
    private var lines: [Stand] = []
    private var counts: [Stand] = []
    private let cursor = ModelEntity()
    private var cursorKey = ""

    /// Right and wrong, the only green and the only red: green from the colour table (Ink.right); red the one a miss is
    /// written in everywhere on the paper (the table has no red of its own yet: `Ink.Hex.wrong` once it does).
    static let right = Sketch.Colour.hex(Ink.right.hexValue(dark: false), Ink.right.hexValue(dark: true))
    static let wrong = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)

    init() {
        for s in [say, count, length, width, height, record, finger] { root.addChild(s.root) }
        record.root.addChild(cursor)
    }

    /// The letters its words will need later (the record, the counts, the typed digits, what a slip says), made a few
    /// a frame while it's on the paper: a letter's shape is made the first time it's written, and a whole record's
    /// worth at once held a frame up for a tenth of a second.
    private var warm: [(text: String, size: CGFloat, weight: UIFont.Weight, digits: Bool)] = []
    private var warmFor: UUID?
    private func prewarm(_ p: CubesProblem) {
        if warmFor != p.id {
            warmFor = p.id
            let b = p.box
            var seen = Set<String>()
            func add(_ s: String, _ size: CGFloat, _ weight: UIFont.Weight, _ digits: Bool) {
                for ch in s where ch != " " && seen.insert("\(ch) \(size) \(weight.rawValue) \(digits)").inserted { warm.append((String(ch), size, weight, digits)) }
            }
            let l = p.lesson
            // the record: its digits and signs (as numbers are written) and its words, at the maths size
            for line in p.finalRecord + [VolumeOfBox.layersRecord(b)] {
                for m in line {
                    switch m {
                    case .num(let x): add(fmt(x), Sketch.maths, .medium, true)
                    case .op(let o): add(o, Sketch.maths, .medium, true)
                    case .text(let t): add(t, Sketch.maths, .medium, false)
                    default: break
                    }
                }
            }
            for s in l.steps.map(\.words.say) { add(s, Sketch.wordSize, .medium, false) }
            for y in 0..<b.height { add(VolumeOfBox.count(y, b) + VolumeOfBox.total(y, b), CubesProblem.labelSize, .semibold, true) }
            add("0123456789", Sketch.maths, .medium, true)
            add("\(b.length) cm \(b.width) cm \(b.height) cm", CubesProblem.labelSize, .medium, true)
            add("Check Next problem", Sketch.Words.block.size, .medium, false)
            for st in l.steps {
                for k in st.answer?.known ?? [] { add(k.message, Sketch.small, .medium, false) }
                if let a = st.answer { add(a.hint, Sketch.small, .medium, false) }
                add(st.words.hint, Sketch.small, .medium, false)
                if let t = st.task { for m in t.mistakes { add(m.message(0, t.want), Sketch.small, .medium, false) } }
            }
        }
        for _ in 0..<4 {
            guard !warm.isEmpty else { return }
            let w = warm.removeFirst()
            _ = PaperText.label(w.text, PaperText.font(w.size, w.weight, digits: w.digits), .black, at: .zero)
        }
    }

    func draw(_ p: CubesProblem, rig: Rig, view v: PaperView3D, screen: Size, at t: Double) {
        Perf.time("cubes-words-prewarm") { prewarm(p) }
        // two groups of words made a frame at most
        var budget = 2
        let pl = Perf.time("cubes-words-places") { p.places(v, screen: screen) }, k = pl.k, b = p.box, chapter = p.chapter.hex, dark = rig.dark ?? false
        let start = p.openedAt + 0.3, left = p.leftAt
        let tilted = p.camera != nil && p.flatAt == nil

        // what to do, over the box; under it what a miss says (red), a word about what's left (grey), or the hint
        let sayKey = "\(p.sayText)|\(p.message.map { "\($0.text)\($0.ok)" } ?? "")|\(p.hintText ?? "")|\(dark)"
        say.show(sayKey, {
            var s = Sketch()
            let n = s.words("say", p.sayText, .say, x: 0, top: 0, width: CubesProblem.wordsWidth, max: 2)
            if let m = p.message { s.words("msg", m.text, Sketch.Words(size: Sketch.small, weight: .medium, colour: m.ok ? .ink2 : Self.wrong), x: 0, top: Double(n) * Sketch.row, width: CubesProblem.wordsWidth) }
            else if let h = p.hintText { s.words("hint", h, Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), x: 0, top: Double(n) * Sketch.row, width: CubesProblem.wordsWidth) }
            return s
        }(), rig: rig, chapter: chapter, start: start, left: left, at: t, budget: &budget)
        say.place(pl.say, v, screen: screen)

        // the squares counted up as the floor is covered, under it (no total: the hands find how many)
        let covered = (0..<b.floor).filter { i in p.squares[i].map { $0.on && $0.at <= t } ?? false }.count
        let counting = p.lesson.step.task != nil && p.lesson.step.camera == .flat
        count.show(counting ? "\(covered) \(dark)" : "", {
            var s = Sketch()
            // from the first square covered (the test page's box counted only once there was something to count); its
            // digits roll over as it counts, from the opening it's in (a How to played again starts from nothing)
            if counting, covered > 0 {
                // the number rolls over as it counts; the word after it stays
                let words = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), n = "\(covered)"
                s.label("count", n, words, at: CGPoint(x: 0, y: Sketch.row / 2), anchor: UnitPoint(x: 0, y: 0.5), slot: "cubes\(p.id)\(Int(p.openedAt))")
                s.label("squares", covered == 1 ? "square" : "squares", words, at: CGPoint(x: CubesProblem.measure(n + " ", Sketch.small, digits: true), y: Sketch.row / 2),
                        anchor: UnitPoint(x: 0, y: 0.5))
            }
            return s
        }(), rig: rig, chapter: chapter, start: start, left: left, at: t, budget: &budget)
        count.place(pl.record, v, screen: screen)

        // the box's measures: its length and width from the start, its height once it stands up
        let label = Sketch.Words(size: CubesProblem.labelSize, weight: .medium, colour: .ink2)
        for (stand, text, at, anchor, shown) in [(length, "\(b.length) cm", pl.length, UnitPoint.center, true), (width, "\(b.width) cm", pl.width, UnitPoint(x: 1, y: 0.5), true),
                                                 (height, "\(b.height) cm", pl.height, UnitPoint(x: 0, y: 0.5), p.heightShown(at: t))] {
            stand.show(shown ? "\(text) \(dark)" : "", {
                var s = Sketch()
                if shown { s.label("m", text, label, at: .zero, anchor: anchor) }
                return s
            }(), rig: rig, chapter: chapter, start: start + 0.4, left: left, at: t, budget: &budget)
            stand.place(at, v, screen: screen)
        }

        // each layer's own count on its front, once it stands: the same on every layer. Lit after a miss on the record
        // (or by the bar's Hint, or on a problem aimed at it); Show me counts them up, each layer's running count as it's
        // reached (12, 24…), a preview that goes back.
        while counts.count < b.height { let s = Stand(lift: 0.05); root.addChild(s.root); counts.append(s) }
        let countUp = p.preview.flatMap { $0.kind == .answer ? $0 : nil }
        let litColour = CubesDrawer.lit(chapter: chapter)
        for (y, stand) in counts.enumerated() {
            var text = "", lit = false
            if y < b.height, tilted, p.lesson.step.task == nil || p.lesson.step.camera == .tilted {
                let stands: Bool = { if case .whole(let h) = p.layer(y, at: t) { return h > 0.97 } else { return false } }()
                if stands {
                    if let c = countUp, t >= c.at + 0.45 * Double(y), t < c.end - CubesProblem.Preview.fade { text = VolumeOfBox.total(y, b); lit = true }
                    else { text = VolumeOfBox.count(y, b); lit = p.countsLit }
                }
            }
            stand.show(text.isEmpty ? "" : "\(text) \(lit) \(dark)", {
                var s = Sketch()
                guard !text.isEmpty else { return s }
                s.label("c", text, Sketch.Words(size: CubesProblem.labelSize, weight: .semibold, colour: lit ? litColour : .ink), at: .zero, anchor: .center)
                // lit: in the chapter's colour where it reads on the cubes, and underlined (no patch over the cubes)
                if lit {
                    let w = CubesProblem.measure(text, CubesProblem.labelSize, digits: true) / 2 + 2
                    s.line("u", [CGPoint(x: -w, y: 15), CGPoint(x: w, y: 15)], litColour, width: Sketch.stroke)
                }
                return s
            }(), rig: rig, chapter: chapter, start: t, left: left, at: t, budget: &budget)
            if y < pl.counts.count { stand.place(pl.counts[y], v, screen: screen) }
        }

        // the record, a line at a time (maths, two squares a digit), and the box to type in on its line
        let lines = p.recordLines(at: t), typed = p.lesson.typed["x"] ?? "", pitch = CubesProblem.recordPitch
        let answering = p.preview?.kind == .answer && t < (p.preview?.end ?? 0) - CubesProblem.Preview.fade && t >= (p.preview?.at ?? 0) + 0.45 * Double(b.height)
        let shownTyped = p.wrongTyped ?? (answering && typed.isEmpty ? "\(b.volume)" : typed)
        let cells = p.answerCells
        let boxRect: CGRect? = lines.firstIndex { $0.line.contains(.box("x")) }.flatMap { i in CubesRecord.box(lines[i].line, cells: cells)?.offsetBy(dx: 0, dy: Double(i) * pitch) }
        let verdict = p.verdict.map { $0.right }
        while self.lines.count < 3 { let s = Stand(lift: 0.1); root.addChild(s.root); self.lines.append(s) }
        for (i, stand) in self.lines.enumerated() {
            let line = i < lines.count ? lines[i] : nil
            stand.show(line.map { "\(VolumeOfBox.written($0.line))|\($0.chapter)|\(dark)" } ?? "", {
                var s = Sketch()
                if let line { CubesRecord.draw(&s, "r", line.line, cells: cells, line.chapter ? .chapter : .ink) }
                return s
            }(), rig: rig, chapter: chapter, start: start, left: left, at: t, budget: &budget)
            stand.place(CGPoint(x: pl.record.x, y: pl.record.y + Double(i) * pitch * k), v, screen: screen)
        }
        // the box, the digits typed in it (as the line writes a number), and the blocks under the record
        let recordKey = "\(boxRect.map { "\($0)" } ?? "")|\(shownTyped)|\(answering)|\(verdict as Bool?)|\(p.blockKinds)|\(pl.blocks.map { "\(($0.rect.minX - pl.record.x) / k),\(($0.rect.minY - pl.record.y) / k)" })|\(dark)"
        record.show(recordKey, {
            var s = Sketch()
            if let boxRect {
                let style: Sketch.Block = verdict.map { $0 ? Sketch.Block(stroke: Self.right, text: Self.right) : Sketch.Block(stroke: Self.wrong, text: Self.wrong) } ?? .main
                s.block("box\(verdict as Bool?)", boxRect, style, grows: true)
                s.pace = 0
                if !shownTyped.isEmpty {
                    s.text("typed\(shownTyped)\(verdict as Bool?)\(answering)", shownTyped, at: CubesRecord.typed(shownTyped, in: boxRect).at, size: Sketch.maths, weight: .medium,
                           answering ? .ink3 : style.text, anchor: UnitPoint(x: 0, y: 0.5))
                }
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
        }(), rig: rig, chapter: chapter, start: start, left: left, at: t, budget: &budget)
        record.place(pl.record, v, screen: screen)

        // the cursor in the box after the last digit, blinking as a cursor does, held still a moment after each key
        let since = t - p.typedAt
        let blink = p.wantsTyping && p.preview == nil && p.verdict == nil && left == nil && t - p.wordsAt > 0.4 && Blink.on(since: since)
        cursor.isEnabled = blink && boxRect != nil
        if cursor.isEnabled, let boxRect {
            let x = CubesRecord.typed(typed, in: boxRect).cursor, u = Paper.unit
            let key = "\(x) \(boxRect.minY) \(dark)"
            if key != cursorKey {
                cursorKey = key
                cursor.model = Rig.lines([(SIMD2(Float(x / u), Float((boxRect.minY + 9) / u)), SIMD2(Float(x / u), Float((boxRect.maxY - 9) / u)))], width: Float(Sketch.stroke / u))
                    .map { ModelComponent(mesh: $0, materials: [flat(rig.colours.ink)]) }
                cursor.position.y = 0.003
            }
        }

        Perf.time("cubes-words-finger") { drawFinger(p, rig: rig, view: v, screen: screen, k: k, at: t) }
    }

    /// The ghost finger making the move (Show me, the How to), as it plays every lesson's moves: a soft round fingertip,
    /// pressing while it drags, with a short trail behind it; drawn at once wherever it is now.
    private func drawFinger(_ p: CubesProblem, rig: Rig, view v: PaperView3D, screen: Size, k: Double, at t: Double) {
        let chapter = p.chapter.hex, dark = rig.dark ?? false
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
    /// coming and going by fading into the paper (`shows`). Drawn at once: it moves every frame. Its colours are the
    /// table's paper and ink2, mixed.
    static func fingertip(down: Bool, trail: [CGPoint], shows: Double) -> Sketch {
        var s = Sketch()
        s.pace = 0
        let paper = (Ink.paper.hexValue(dark: false), Ink.paper.hexValue(dark: true)), ink2 = (Ink.ink2.hexValue(dark: false), Ink.ink2.hexValue(dark: true))
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
