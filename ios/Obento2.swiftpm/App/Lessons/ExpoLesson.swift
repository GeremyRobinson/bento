import SwiftUI

/// Exponents and order on the paper, as in the preview (design/prototype/grade6-ch5.html, dExpo): `4² + 5 × 3` written
/// once, big, on the picture's top rows (the part being worked underlined, the parts done grey). Tap what goes first; under
/// it an empty corner, a tick a block (one block is one, as in Unit cubes): drag the corner out a block at a time to 4 by
/// 4. A cube's floor stands up in Unit cubes' tilted view and its layers are dragged up, each rising from the one under
/// it, counted on its front; the floor lies flat again once it's counted. The record beside the picture: `4² = [16]`,
/// then (the × tapped) `5 × 3 = [15]`, then `16 + 15 = [31]`.
///
/// Everything is in the picture's squares (recordRow 0). Hand keys: "w", "h" (the corner), "l" (the layers), "y0", "l0".
@MainActor
struct ExpoLesson: PaperLesson {
    static let ox = 0.0, oy = 4.0, top = 3.5
    var liveKeys: Set<String> { ["w", "h", "grab", "part"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct Shape {
        let P: Expo6.Parts
        init(_ n: Numbers) { P = Expo6.Parts(n) }
        var a: Double { Double(P.a) }
        /// Squares a one: a block, as in Unit cubes; a cube of 4 or 5 a side 4 or 3 squares a one, so it stands up in
        /// the tilted view at 75% or more.
        var B: Double { P.cube && P.a >= 4 ? Double(8 - P.a) : 5 }
        /// The empty corner's size, in blocks.
        var cap: Int { max(4, min(5, P.a + 1)) }
        var toks: [M7.Tok] { [.t(P.pw), .op("+"), .n(P.b), .op("×"), .n(P.c)] }
        /// The parts a tap picks (Expo6.pow, plus, times), by their tokens.
        static let parts = [0...0, 1...1, 2...4]
        var cols: [(Double, Double)] { X6.columns(toks, x: 0) }
        func span(_ p: Int) -> (Double, Double) { (cols[Shape.parts[p].lowerBound].0, cols[Shape.parts[p].upperBound].1) }
        /// The tilted view of the cube, moved down so its top clears the line.
        var view: X6.View {
            var v = X6.View(px: ExpoLesson.ox + a * B / 2, py: ExpoLesson.oy + a * B / 2)
            let b = v.bounds(ExpoLesson.ox, ExpoLesson.oy, ExpoLesson.ox + a * B, ExpoLesson.oy + a * B, a * B)
            v.dy = max(0, ExpoLesson.top - b.minY).rounded(.up)
            return v
        }
        var cubeBounds: CGRect { view.bounds(ExpoLesson.ox, ExpoLesson.oy, ExpoLesson.ox + a * B, ExpoLesson.oy + a * B, a * B) }
        /// The record's left column: beside the corner (or the standing cube), on a block line.
        var rx: Double {
            let flat = ((Double(cap) * B + 3) / 5).rounded(.up) * 5
            return P.cube ? max(flat, ((cubeBounds.maxX + 3) / 5).rounded(.up) * 5) : flat
        }
        /// The record lines' middles: the power, the product, the sum.
        func line(_ i: Int) -> Double { ExpoLesson.oy + 5 + 4 * Double(i) }
    }

    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers), at = stage(s)
        switch at {
        case 4: return CGPoint(x: S.rx, y: S.line(0) + 2)
        case 6: return CGPoint(x: S.rx, y: S.line(1) + 2)
        case 7, 8: return CGPoint(x: S.rx, y: S.line(2) + 2)
        default: return nil
        }
    }
    func keysFocus(_ s: PaperState) -> CGRect? {
        // the squares (or cubes) the power is counted from stay in the frame with its line
        let S = Shape(s.numbers)
        guard stage(s) == 4 else { return nil }
        return S.P.cube ? S.cubeBounds : CGRect(x: Self.ox, y: Self.oy, width: S.a * S.B, height: S.a * S.B)
    }

    // MARK: drawing

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), B = S.B, ox = Self.ox, oy = Self.oy, a = S.a
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let tilted = P.cube && (at == 3 || at == 4)

        // the problem, written once: the part being worked underlined, the parts done grey
        let grey: (Int) -> Sketch.Colour = { p in
            let done = p == Expo6.pow ? at > 4 : p == Expo6.times ? at > 6 : at > 7
            return done ? .ink3 : .ink
        }
        let toks: [M7.Tok] = [.t(P.pw, grey(0)), .op("+", grey(1)), .n(P.b, grey(2)), .op("×", grey(2)), .n(P.c, grey(2))]
        M7.row(&pic, "ex", toks, x: 0, line: 1)
        let working: Int? = (2...4).contains(at) ? Expo6.pow : at == 6 ? Expo6.times : nil
        if let w = working { let (x0, x1) = S.span(w); pic.line("ul\(w)", [(x0 + 0.3, 2.4), (x1 - 0.3, 2.4)], .chapter) }
        if at == 7 { pic.line("ulall", [(S.cols[0].0 + 0.3, 2.4), (S.cols[4].1 - 0.3, 2.4)], .chapter) }
        if at == 1 || at == 5 {
            // a wrong part tapped, red under it
            if let j = s.h("wrong").map({ Int($0) }), (0...2).contains(j) { let (x0, x1) = S.span(j); pic.line("bad\(j)", [(x0 + 0.3, 2.4), (x1 - 0.3, 2.4)], R6.red) }
            if s.on("ring") { X6.ring(&pic, "ring", x: S.cols[0].0, y: 0, w: S.cols[4].1 - S.cols[0].0, h: 2.2) }
            if s.on("spot") { let (x0, x1) = S.span(at == 1 ? Expo6.pow : Expo6.times); pic.circle("spot", at: (x0 + x1) / 2, 1, radius: max(1.6, (x1 - x0) / 2 + 0.6), .chapter, dashed: true) }
        }

        // the empty corner: two edges, a tick a block
        if !tilted {
            let cap = Double(S.cap)
            pic.line("edT", [(ox, oy), (ox + cap * B, oy)], .ink3); pic.line("edL", [(ox, oy), (ox, oy + cap * B)], .ink3)
            let ticks = (1...S.cap).flatMap { k -> [(CGPoint, CGPoint)] in
                let d = Double(k) * B
                return [(pic.P(ox + d, oy - 0.6), pic.P(ox + d, oy)), (pic.P(ox - 0.6, oy + d), pic.P(ox, oy + d))]
            }
            pic.sketch.segments("ticks", ticks, .ink3, width: Sketch.stroke)
        }

        // building: the rectangle follows the corner a block at a time
        if at == 2 {
            let w = s.h("w") ?? 1, h = s.h("h") ?? 1, bad = (s.h("bad") ?? 0) != 0 && !s.grabbed
            Self.floor(&live, w: w, h: h, B: B, P.cube, bad: bad)
            R6.handle(&live, "hd", ox + w * B, oy + h * B, held: s.grabbed)
            live.word("ro", "\(Int(w)) × \(Int(h))", at: ox + w * B + 1.2, oy + h * B, X6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            if s.grabbed { live.reads("\(Int(w)) × \(Int(h))") }
            if s.on("ring") { X6.ring(&pic, "ring", x: ox, y: oy, w: Double(S.cap) * B, h: Double(S.cap) * B) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(ox, oy, a * B, a * B), .chapter, width: Sketch.stroke, dashed: true) }
        }

        // built: the square (flat), or the cube standing up in the tilted view
        if at >= 3 {
            let flat = Self.floorShape(w: a, h: a, B: B), V = S.view
            pic.sketch.morphs = true
            for (id, k) in flat { pic.sketch.from[id] = k }
            if tilted { Self.floor(&pic, w: a, h: a, B: B, true, map: { x, y in V.at(x, y, 0) }) }
            else { Self.floor(&pic, w: a, h: a, B: B, P.cube) }
            pic.sketch.morphs = false; pic.sketch.from = [:]
            if tilted {
                let layers = at == 4 ? P.a : Int(s.h("l") ?? 1)
                cubes(&pic, S, V, layers: layers, wire: at == 3, lit: at == 3 && s.on("spot"))
                if at == 3 {
                    let tp = V.at(ox + a * B / 2, oy + a * B / 2, Double(layers) * B), b = S.cubeBounds
                    let ro = "\(P.a) × \(P.a) × \(layers)"
                    pic.word("rol\(layers)", ro, at: b.maxX + 1.5, tp.y, X6.lit, anchor: UnitPoint(x: 0, y: 0.5))
                    if s.grabbed { live.reads(ro) }
                    if s.on("ring") { X6.ring(&pic, "ring", x: b.minX, y: b.minY, w: b.width, h: b.height) }
                }
                if at == 4 && s.on("spot") {
                    // the running count beside each layer
                    for l in 0..<P.a {
                        let q = V.at(ox + a * B, oy + a * B, (Double(l) + 0.5) * B)
                        pic.word("run\(l)", "\(P.a * P.a * (l + 1))", at: q.x + 1, q.y, X6.lit, anchor: UnitPoint(x: 0, y: 0.5))
                    }
                }
            } else {
                // its sides named left and under it (over it would crowd the line above)
                pic.label("sL", "\(P.a)", X6.words.colour(.chapter), .left, edge: ox - 0.6, along: oy + a * B / 2)
                pic.label("sB", P.cube ? "\(P.a) layers of \(P.a * P.a)" : "\(P.a)", P.cube ? X6.lit : X6.words.colour(.chapter), .below, edge: oy + a * B + 0.4, along: ox + a * B / 2)
                if at == 4 && s.on("spot") {
                    for r in 0..<P.a { pic.word("run\(r)", "\(P.a * (r + 1))", at: ox + a * B + 1, oy + (Double(r) + 0.5) * B, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
                }
                if at == 4 && s.on("ring") { X6.ring(&pic, "ring", x: ox, y: oy, w: a * B, h: a * B) }
            }
        }

        // the record beside the picture
        func val(_ v: Int, _ step: Int) -> M7.Tok { at == step ? .box("x", cells: max(2, "\(v)".count)) : .n(v, .chapter) }
        if at >= 4 { M7.row(&rec, "r0", [.t(P.pw), .op("="), val(P.E, 4)], x: S.rx, line: S.line(0)) }
        if at >= 6 { M7.row(&rec, "r1", [.n(P.b), .op("×"), .n(P.c), .op("="), val(P.M, 6)], x: S.rx, line: S.line(1)) }
        if at >= 7 { M7.row(&rec, "r2", [.n(P.E), .op("+"), .n(P.M), .op("="), val(P.S, 7)], x: S.rx, line: S.line(2)) }
        if at == 6 && s.on("ring") { let (x0, x1) = S.span(Expo6.times); X6.ring(&pic, "ring", x: x0, y: 0, w: x1 - x0, h: 2.2) }
        if at == 7 && s.on("ring") { X6.ring(&rec, "ring", x: S.rx, y: S.line(0) - 1, w: 12, h: S.line(1) - S.line(0) + 2) }

        var ext = pic.R(-1, 0, S.rx + 17, oy + Double(S.cap) * B + 2.5)
        if P.cube { let b = S.cubeBounds; ext = ext.union(pic.R(b.minX - 1, b.minY, b.width + 2, b.height + 1)) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    /// The floor's parts, flat: its fill, its outline and the lines between its blocks (each its own part, so the whole
    /// floor can morph into the tilted view and back).
    static func floorShape(w: Double, h: Double, B: Double, map: ((Double, Double) -> CGPoint)? = nil) -> [(String, Sketch.Kind)] {
        let sq = Paper.cell
        func P(_ x: Double, _ y: Double) -> CGPoint { let p = map?(x, y) ?? CGPoint(x: x, y: y); return CGPoint(x: p.x * sq, y: p.y * sq) }
        let x0 = ox, y0 = oy, x1 = ox + w * B, y1 = oy + h * B
        var out: [(String, Sketch.Kind)] = [("flf", .fill([P(x0, y0), P(x1, y0), P(x1, y1), P(x0, y1)])),
                                            ("flo", .line([P(x0, y0), P(x1, y0), P(x1, y1), P(x0, y1), P(x0, y0)], width: Sketch.stroke, dashed: false))]
        for k in stride(from: 1.0, to: w, by: 1) { out.append(("flv\(Int(k))", .line([P(x0 + k * B, y0), P(x0 + k * B, y1)], width: Sketch.stroke, dashed: false))) }
        for k in stride(from: 1.0, to: h, by: 1) { out.append(("flh\(Int(k))", .line([P(x0, y0 + k * B), P(x1, y0 + k * B)], width: Sketch.stroke, dashed: false))) }
        return out
    }
    static func floor(_ pen: inout GridPen, w: Double, h: Double, B: Double, _ cube: Bool, bad: Bool = false, map: ((Double, Double) -> CGPoint)? = nil) {
        for (id, k) in floorShape(w: w, h: h, B: B, map: map) {
            switch k {
            case .fill(let pts): pen.sketch.polygon(id, pts, cube ? X6.cubeTop : .tint(0.22))
            case .line(let pts, let wd, _): pen.sketch.line(id, pts, bad && id == "flo" ? R6.red : .chapter, width: wd)
            default: break
            }
        }
    }

    /// The layers of cubes standing on the floor, each rising from the top of the one under it; the cube's own shape
    /// dashed round them while they're built; each layer's count on its front.
    private func cubes(_ pen: inout GridPen, _ S: Shape, _ V: X6.View, layers: Int, wire: Bool, lit: Bool) {
        let a = S.a, B = S.B, X0 = Self.ox, Y0 = Self.oy, X1 = X0 + a * B, Y1 = Y0 + a * B, sq = Paper.cell
        func P(_ x: Double, _ y: Double, _ z: Double) -> CGPoint { let p = V.at(x, y, z); return CGPoint(x: p.x * sq, y: p.y * sq) }
        if wire {
            let Z = a * B, xs = [X0, X1], ys = [Y0, Y1], zs = [0, Z]
            let edges = [(0,0,0,1,0,0),(0,1,0,1,1,0),(0,0,0,0,1,0),(1,0,0,1,1,0),(0,0,1,1,0,1),(0,1,1,1,1,1),(0,0,1,0,1,1),(1,0,1,1,1,1),(0,0,0,0,0,1),(1,0,0,1,0,1),(0,1,0,0,1,1),(1,1,0,1,1,1)]
            for (k, e) in edges.enumerated() {
                pen.sketch.line("wire\(k)", [P(xs[e.0], ys[e.1], zs[e.2]), P(xs[e.3], ys[e.4], zs[e.5])], lit ? .chapter : .ink3, width: Sketch.stroke, dashed: true)
            }
        }
        // each part of a layer starts flat on the layer under it and rises to its own height
        func part(_ id: String, _ pts: (Double) -> [CGPoint], z0: Double, plate: Sketch.Colour?) {
            let to = pts(z0 + B), from = pts(z0)
            if let c = plate { pen.sketch.from[id] = .plate(from); pen.sketch.plate(id, to, c) }
            else { pen.sketch.from[id] = .overLine(from, width: Sketch.stroke); pen.sketch.overLine(id, to, .chapter, width: Sketch.stroke) }
        }
        for l in 0..<layers {
            let z0 = Double(l) * B
            // the floor rises into the first layer once it has stood up
            pen.sketch.delay = l == 0 ? SketchDrawer.morphTime : 0
            part("cf\(l)", { z in [P(X0, Y1, z0), P(X1, Y1, z0), P(X1, Y1, z), P(X0, Y1, z)] }, z0: z0, plate: X6.cubeFront)
            part("cs\(l)", { z in [P(X1, Y1, z0), P(X1, Y0, z0), P(X1, Y0, z), P(X1, Y1, z)] }, z0: z0, plate: X6.cubeSide)
            part("co\(l)", { z in [P(X0, Y1, z), P(X0, Y1, z0), P(X1, Y1, z0), P(X1, Y0, z0), P(X1, Y0, z), P(X1, Y1, z), P(X0, Y1, z)] }, z0: z0, plate: nil)
            for j in 1..<S.P.a {
                let d = Double(j) * B
                part("cfv\(l)_\(j)", { z in [P(X0 + d, Y1, z0), P(X0 + d, Y1, z)] }, z0: z0, plate: nil)
                part("csv\(l)_\(j)", { z in [P(X1, Y0 + d, z0), P(X1, Y0 + d, z)] }, z0: z0, plate: nil)
            }
            let q = V.at(X0 + (Double(S.P.a / 2) + 0.5) * B, Y1, z0 + B / 2)
            pen.word("lay\(l)", "\(S.P.a * S.P.a)", at: q.x, q.y, X6.small.colour(.ink))
        }
        pen.sketch.from = [:]
        // the top, on the highest layer: it moves up as layers are added
        // (shown at once on the floor when it's new, rising with the first layer)
        let z = Double(max(1, layers)) * B, z0 = z - B
        pen.sketch.morphs = true
        func top(_ z: Double) -> [(String, Sketch.Kind)] {
            var out: [(String, Sketch.Kind)] = [("ctop", .plate([P(X0, Y0, z), P(X1, Y0, z), P(X1, Y1, z), P(X0, Y1, z)])),
                                                ("ctopo", .overLine([P(X0, Y0, z), P(X1, Y0, z), P(X1, Y1, z), P(X0, Y1, z), P(X0, Y0, z)], width: Sketch.stroke))]
            for j in 1..<S.P.a {
                let d = Double(j) * B
                out.append(("ctv\(j)", .overLine([P(X0 + d, Y0, z), P(X0 + d, Y1, z)], width: Sketch.stroke)))
                out.append(("cth\(j)", .overLine([P(X0, Y0 + d, z), P(X1, Y0 + d, z)], width: Sketch.stroke)))
            }
            return out
        }
        for (id, k) in top(z0) { pen.sketch.from[id] = k }
        pen.sketch.delay = layers <= 1 ? SketchDrawer.morphTime : 0
        for (id, k) in top(z) {
            switch k {
            case .plate(let pts): pen.sketch.plate(id, pts, X6.cubeTop)
            case .overLine(let pts, let w): pen.sketch.overLine(id, pts, .chapter, width: w)
            default: break
            }
        }
        pen.sketch.morphs = false; pen.sketch.from = [:]; pen.sketch.delay = 0
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), at = stage(s), B = S.B
        switch at {
        case 1, 5:
            return Hands(tap: { q in
                guard q.y >= -0.8, q.y <= 2.8, let t = X6.token(at: q.x, S.cols) else { return nil }
                let p = Shape.parts.firstIndex { $0.contains(t) } ?? 0
                if at == 5 && p == Expo6.pow { return nil }
                return HandMove(hand: ["part": Double(p)], missHand: ["wrong": Double(p)], set: [("p", Double(p))], check: true)
            })
        case 2:
            let w = s.h("w") ?? 1, h = s.h("h") ?? 1
            return Hands(grab: { q in
                hypot(q.x - (Self.ox + w * B), q.y - (Self.oy + h * B)) <= 3.5 ? ["grab": 1, "w": w, "h": h] : nil
            }, drag: { q, _ in
                ["grab": 1, "w": Double(max(1, min(S.cap, Int(((q.x - Self.ox) / B).rounded())))),
                 "h": Double(max(1, min(S.cap, Int(((q.y - Self.oy) / B).rounded()))))]
            }, release: { hd in
                let w = hd["w"] ?? 1, h = hd["h"] ?? 1
                return HandMove(hand: ["w": w, "h": h], missHand: ["w": w, "h": h, "bad": 1], set: [("x", w * 10 + h)], check: true)
            })
        case 3:
            let l = s.h("l") ?? 1, b = S.cubeBounds, per = B * sin(PaperView3D.tilted.elevation * .pi / 180)
            return Hands(grab: { q in
                b.insetBy(dx: -2, dy: -2).contains(q) ? ["grab": 1, "y0": q.y, "l0": l, "l": l] : nil
            }, drag: { q, hd in
                var hd = hd
                hd["l"] = Double(max(1, min(S.P.a + 1, Int(hd["l0"] ?? 1) + Int((((hd["y0"] ?? q.y) - q.y) / per).rounded()))))
                return hd
            }, release: { hd in
                let l = hd["l"] ?? 1
                return HandMove(hand: ["l": l], missHand: ["l": l], set: [("l", l)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), at = stage(s), B = S.B, a = S.a
        switch at {
        case 1, 5: let (x0, x1) = S.span(at == 1 ? Expo6.pow : Expo6.times); return [.tap(.picture(CGPoint(x: (x0 + x1) / 2, y: 1)))]
        case 2:
            let w = s.h("w") ?? 1, h = s.h("h") ?? 1
            return [.drag(from: CGPoint(x: Self.ox + w * B, y: Self.oy + h * B), to: CGPoint(x: Self.ox + a * B, y: Self.oy + a * B))]
        case 3:
            let l = s.h("l") ?? 1, per = B * sin(PaperView3D.tilted.elevation * .pi / 180)
            let p = S.view.at(Self.ox + a * B / 2, Self.oy + a * B / 2, l * B)
            return [.drag(from: p, to: CGPoint(x: p.x, y: p.y - (a - l) * per))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let S = Shape(s.numbers), at = stage(s), a = S.a
        switch at {
        case 1: return HandMove(hand: ["part": 2], missHand: ["wrong": 2], set: [("p", 2)], check: true)
        case 5: return HandMove(hand: ["part": 1], missHand: ["wrong": 1], set: [("p", 1)], check: true)
        case 2: let h = a > 2 ? a - 1 : a + 1; return HandMove(hand: ["w": a, "h": h], missHand: ["w": a, "h": h, "bad": 1], set: [("x", a * 10 + h)], check: true)
        case 3: return HandMove(hand: ["l": a - 1], missHand: ["l": a - 1], set: [("l", a - 1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Expo6.Parts(s.numbers)
        switch stage(s) {
        case 4: return ["x": Double(P.a * P.n)]
        case 6: return ["x": Double(P.b + P.c)]
        case 7: return ["x": Double((P.E + P.b) * P.c)]
        default: return nil
        }
    }
}
