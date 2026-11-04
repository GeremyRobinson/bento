import SwiftUI

/// Solid shapes on the paper, as in the preview (design/prototype/gradeK-ch2.html, lSolids), with the shared 3D
/// (PaperStand.swift). Flat first: the solid seen straight down (one block a floor square: the cube 3 blocks a side; the
/// sphere, cylinder and cone 2 blocks across, a cylinder and cone 3 tall: the design's 4 and 5 stood up at 55% on the iPad) beside a flat shape with the same outline, 2 blocks apart: from
/// above they look the same. Drag the paper up: it tilts with the finger (on up on the spring past a third, else back),
/// and the solid rises off it while the flat one stays. Tap the solid one. Tap a flat face (a round part: "That’s round.
/// Find a flat part."; None, the sphere's answer, lights a face for one that has one). It turns once where it stands with
/// every flat face lit, then: tap rolls or slides, and push it: a sphere rolls; a cylinder lies down and rolls; a cone
/// rolls round its point; a cube slides and stops; it comes to rest and is set back. Tap its name. The record beside it.
///
/// Kept: "flatx" the flat one tapped, "hint" a face lit by None (its index in SK.faceNames), "wrongNone", "seeAt" when
/// it began to turn, "guess" rolls (0) or slides (1), "wrongRoll", "push" when it was pushed, "wrong" a name tapped.
/// Hand: "grab", "y0", "up" (the tilt held), "x0", "mv" (a push).
@MainActor
struct SolidShapesLesson: PaperLesson {
    var solid: Bool { true }
    var liveKeys: Set<String> { ["up", "y0", "x0", "mv"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let D = 10.0, top = 2.0
    static let go = 1.5, hold = 0.5, back = 0.7, push = 2.7, spin = 2.4

    /// The problem laid out: the solid's shape, where it and the flat one sit, and the pivot that shows it standing.
    @MainActor struct Scene {
        let P: Solids3K.Parts
        let G: SK.Shape
        let H: Double, foot: Double, sx: Double, fx: Double
        var yc: Double, fy: Double
        var pivot = CGPoint.zero
        static var cache: [String: CGPoint] = [:]
        init(_ n: Numbers) {
            P = Solids3K.Parts(n)
            let D = SolidShapesLesson.D, kind = P.kind
            H = kind == "cube" || kind == "sphere" ? D : 15
            let thing = P.thing
            G = kind == "cube" ? SK.box(D, D, D, thing: thing) : kind == "sphere" ? SK.sphere(D / 2, thing: thing) : kind == "cylinder" ? SK.cylinder(D / 2, H, thing: thing) : SK.cone(D / 2, H, thing: thing)
            foot = P.lying ? H : D
            sx = P.side == 1 ? foot + 10 : 0; fx = P.side == 1 ? 0 : foot + 10
            // the paper is seen turned (+28°), so something beside the solid shows lower or higher: the flat one sits up or
            // down the paper (whole squares) so that, standing, it shows level with the solid; then both move down the paper
            // until neither is over the words
            yc = 0; fy = 0
            let v = Standing(pivot: .zero), a = v.up(fx + foot / 2, 0, 0).y, b = v.up(sx + foot / 2, 0, 0).y, k = v.up(fx + foot / 2, 1, 0).y - a
            fy = abs(k) > 1e-6 ? ((b - a) / k).rounded() : 0
            let low = min(shape(rest).points.map(\.y).min() ?? 0, flat.map(\.1).min() ?? 0)
            yc = SolidShapesLesson.top - low
            let key = n.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()
            if let p = Scene.cache[key] { pivot = p; return }
            let all = reach, c = SK.bounds(all.map { CGPoint(x: $0.x, y: $0.y) })
            pivot = Standing.pivot(showing: all, at: CGPoint(x: 0, y: 6), from: CGPoint(x: c.midX, y: c.midY))
            Scene.cache[key] = pivot
        }
        /// At rest: upright, upside down (an ice-cream cone), or on its side (its axis along the paper).
        var rest: (R: SK.M3, C: Vec3) {
            let D = SolidShapesLesson.D
            if P.lying { return (SK.ry(.pi / 2), Vec3(sx, yc, D / 2)) }
            if P.upsideDown { return (SK.rx(.pi), Vec3(sx + D / 2, yc, H)) }
            return (P.kind == "cube" && P.turn == 1 ? SK.rz(.pi / 2) : SK.I, Vec3(sx + D / 2, yc, P.kind == "sphere" ? D / 2 : 0))
        }
        /// Lifted or lowered so its lowest point touches the paper.
        func ground(_ R: SK.M3, _ C: Vec3) -> Vec3 { let m = G.points.map { SK.mv(R, $0).z }.min() ?? 0; return Vec3(C.x, C.y, -m) }
        /// Pushed `e` seconds ago, away from the flat one (G 4 Nov: never over it): a sphere rolls; a cylinder lies down and
        /// rolls away; a cone tips and rolls round its point; a cube slides and stops. It rests, then is set back.
        func pushed(_ e: Double) -> (R: SK.M3, C: Vec3) {
            let r0 = rest, D = SolidShapesLesson.D
            guard e >= 0, e < SolidShapesLesson.push else { return r0 }
            let g = SolidShapesLesson.go, f = e < g ? e : e < g + SolidShapesLesson.hold ? g : g - (e - g - SolidShapesLesson.hold) / SolidShapesLesson.back * g
            let u = f / g, away = P.side == 1 ? 1.0 : -1
            switch P.kind {
            case "cube": return (r0.R, r0.C + Vec3(away * 10 * (1 - pow(1 - u, 3)), 0, 0))
            case "sphere": let d = 10 * ease(u); return (SK.mm(SK.ry(away * d / 10), r0.R), r0.C + Vec3(away * d, 0, 0))
            default:
                let lying = P.lying
                let tipU = lying ? 1 : ease(min(1, u / 0.3)), rollU = lying ? ease(u) : ease(max(0, (u - 0.3) / 0.7))
                let R = lying ? r0.R : SK.mm(SK.ry(away * tipU * .pi / 2), r0.R)
                var C = lying ? r0.C : r0.C + Vec3(away * (D / 2) * (1 - cos(tipU * .pi / 2)), 0, 0)
                if !lying { C = ground(R, C) }
                if P.kind == "cylinder" { let d = 6 * rollU; return (SK.mm(R, SK.rz(d / (D / 2))), C + Vec3(0, -d, 0)) }
                let apex = SK.mv(R, Vec3(0, 0, H)) + C, psi = -away * rollU * 0.7, sp = psi * hypot(D / 2, H) / (D / 2)
                let Rz = SK.rz(psi), q = SK.mv(Rz, C - apex), R2 = SK.mm(Rz, SK.mm(R, SK.rz(sp)))
                return (R2, ground(R2, apex + q))
            }
        }
        /// Turned once about its own upright, `e` seconds in (the See).
        func turned(_ e: Double) -> (R: SK.M3, C: Vec3) {
            let r0 = rest, a = 2 * .pi * ease(min(1, max(0, e) / SolidShapesLesson.spin)), Rz = SK.rz(a)
            let c = Vec3(sx + foot / 2, yc, 0), rel = SK.mv(Rz, r0.C - c)
            return (SK.mm(Rz, r0.R), c + rel)
        }
        func shape(_ pose: (R: SK.M3, C: Vec3)) -> SK.Shape { G.posed(pose.R, pose.C) }
        /// The flat one: the solid's outline from above, on the paper beside it.
        var flat: [KS.Pt] {
            let p = shape(rest).points.map { CGPoint(x: $0.x + fx - sx, y: $0.y + fy) }
            return SK.hull(p)
        }
        /// Everything it reaches: at rest, along its push, and the flat one.
        var reach: [Vec3] {
            var out: [Vec3] = shape(rest).points + flat.map { Vec3($0.0, $0.1, 0) }
            for e in [0.3, 0.6, 0.9, 1.2, 1.5] { out += shape(pushed(e)).points }
            return out
        }
        var stand: Standing { Standing(pivot: pivot) }
    }

    func stands(_ s: PaperState) -> CGPoint? { at(s) >= 1 ? Scene(s.numbers).pivot : nil }
    func standHeld(_ s: PaperState) -> (pivot: CGPoint, up: Double)? {
        guard at(s) == 0, s.grabbed else { return nil }
        return (Scene(s.numbers).pivot, s.h("up") ?? 0)
    }
    func say(_ s: PaperState) -> String? { at(s) == 3 && (s.run.kept["guess"] ?? -1) >= 0 ? "Push it." : nil }

    /// Where the word blocks and the record go: over the flat one (the paper there is empty: it doesn't rise).
    /// Where the word blocks and the record go: in a row over everything that stands.
    private func col(_ S: Scene, _ St: Standing) -> CGPoint { CGPoint(x: 0, y: 0) }
    private func blockRects(_ s: PaperState, _ S: Scene, _ St: Standing) -> [CGRect] {
        let c = col(S, St)
        switch at(s) {
        case 2: return KS.rects(1, x: c.x, y: c.y, w: 10, .row)
        case 3: return KS.rects(2, x: c.x, y: c.y, w: 10, .row)
        case 4: return KS.rects(4, x: c.x, y: c.y, w: 11, .row)
        default: return []
        }
    }
    private func lit(_ s: PaperState, _ S: Scene) -> Set<String> {
        let st = at(s)
        if st >= 3 { return Set(S.G.flatFaces) }
        if st == 2, let h = s.run.kept["hint"], h >= 0 { return [SK.faceNames[Int(h)]] }
        return []
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Scene(s.numbers), P = S.P, st = at(s), St = s.standing(S.pivot)
        var pic = GridPen(), so = Solids()
        // the flat one, on the paper (it tilts with it)
        let flatWrong = st == 1 && s.run.kept["flatx"] == 1
        so.faces.append(Solids.Face(id: "flat\(flatWrong)", pts: S.flat.map { Vec3($0.0, $0.1, 0) }, look: flatWrong ? .paint(.hex(0xF0CFCB, 0x5A2A27)) : .top, edges: true))
        let litNow = lit(s, S), seam = st >= 3
        so.bodies = [S.shape(S.rest).body("sol", lit: litNow, seam: seam)]
        // what plays by itself: the turn (the See, as the roll step begins), the push
        let now = PaperClock.now
        if st == 3, let t0 = s.run.kept["seeAt"], now - t0 < Self.spin + 0.3, (s.run.kept["push"] ?? -1) < t0 {
            let base = so
            so.play = Solids.Play(start: t0, length: Self.spin) { t in var o = base; o.bodies = [S.shape(S.turned(t - t0)).body("sol", lit: litNow, seam: true)]; return o }
        } else if st >= 3, let t0 = s.run.kept["push"], now - t0 < Self.push + 0.3 {
            let base = so
            so.play = Solids.Play(start: t0, length: Self.push) { t in var o = base; o.bodies = [S.shape(S.pushed(t - t0)).body("sol", lit: litNow, seam: true)]; return o }
        }
        let pushEnds = (s.run.kept["push"] ?? -100) + Self.push
        if st >= 1 {
            let solidBox = SK.bounds(S.shape(S.rest).points.map { St.up($0) })
            // a real thing is named under it
            if let name = P.thingName { pic.word("thing\(name)", name, at: solidBox.midX, solidBox.maxY + 1.5, Sketch.Words.note) }
            let r = blockRects(s, S, St)
            switch st {
            case 1:
                if s.on("ring") { KK.hintBox(&pic, "hr", x: solidBox.minX, y: solidBox.minY, w: solidBox.width, h: solidBox.height) }
            case 2:
                KS.blocks(&pic, "none", ["None"], r, wrong: s.run.kept["wrongNone"] == 1 ? 0 : nil, spot: s.on("spot") && P.s.faces == 0 ? 0 : nil)
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: solidBox.minX, y: solidBox.minY, w: solidBox.width, h: solidBox.height) }
                if s.on("spot"), P.s.faces > 0, let f = seenFlat(S).first, let m = S.shape(S.rest).middle(f) { let p = St.up(m); pic.circle("spot", at: p.x, p.y, radius: 2.4, .chapter) }
            case 3:
                let g = Int(s.run.kept["guess"] ?? -1), w = Int(s.run.kept["wrongRoll"] ?? -1)
                pic.sketch.startAt = (s.run.kept["seeAt"] ?? 0) + Self.spin > now ? (s.run.kept["seeAt"] ?? 0) + Self.spin : nil
                KS.blocks(&pic, "roll", Solids3K.rollChoices, r, wrong: w >= 0 && g < 0 ? w : nil, spot: s.on("spot") ? (P.s.rolls ? 0 : 1) : nil,
                          ring: s.on("ring") && !s.on("spot"), picked: g >= 0 ? g : nil)
                pic.sketch.startAt = nil
            case 4:
                pic.sketch.startAt = pushEnds > now ? pushEnds : nil
                let w = s.run.kept["wrong"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil }
                KS.blocks(&pic, "nm", P.names, r, wrong: w, spot: s.on("spot") ? P.rightName : nil, ring: s.on("ring") && !s.on("spot"))
                pic.sketch.startAt = nil
            default:
                // the record in one line over it
                let c = col(S, St)
                KS.line(&pic, "rec", P.record.map { M7.Tok.w($0) }, x: c.x, line: c.y + 2)
            }
        }
        // room: it standing all along its push, and the blocks and record; flat, what's seen from above
        let room: CGRect
        if st >= 1 {
            let b = SK.bounds(S.reach.map { St.up($0) }), c = col(S, St)
            room = b.union(CGRect(x: c.x, y: c.y, width: 47, height: 4)).insetBy(dx: -1, dy: -1)
        } else {
            room = SK.bounds(S.shape(S.rest).points.map { CGPoint(x: $0.x, y: $0.y) } + S.flat.map { CGPoint(x: $0.0, y: $0.1) }).insetBy(dx: -1, dy: -1)
        }
        return PaperDrawing(picture: pic.sketch, extent: pic.R(room.minX, room.minY, room.width, room.height), solids: so, standing: st >= 1 ? St : nil)
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        guard at(s) == 5 else { return nil }
        let P = Solids3K.Parts(s.numbers)
        return CGPoint(x: (M7.width(P.record.map { M7.Tok.w($0) }) + 2).rounded(.up), y: 1)
    }

    /// The flat faces that face the child at rest.
    private func seenFlat(_ S: Scene) -> [String] {
        let G = S.shape(S.rest), c = G.points.reduce(Vec3(0, 0, 0)) { $0 + $1 } * (1 / Double(max(1, G.points.count)))
        return Array(Set(zip(G.facets, G.ids).filter { $0.1 != "round" && SK.seen($0.0, centre: c) }.map(\.1))).sorted()
    }
    private func onSolid(_ S: Scene, _ St: Standing, _ f: CGPoint) -> Bool { KS.inside((f.x, f.y), SK.hull(S.shape(S.rest).points.map { St.up($0) })) }

    func hands(_ s: PaperState) -> Hands? {
        let S = Scene(s.numbers), P = S.P, St = s.standing(S.pivot), st = at(s)
        func board(_ q: CGPoint) -> CGPoint { St.up(q.x, q.y, 0) }
        switch st {
        case 0:
            return Hands(grab: { q in ["grab": 1, "y0": q.y, "up": 0] },
                         drag: { q, h in var h = h; h["up"] = max(0, min(1, ((h["y0"] ?? q.y) - q.y) / 12)); return h },
                         release: { h in
                             (h["up"] ?? 0) >= 0.35 ? HandMove(hand: [:], set: [("t", 1)], check: true) : HandMove(hand: [:], missHand: [:], set: [("t", 0)], check: true)
                         })
        case 1:
            return Hands(tap: { q in
                let f = board(q)
                if onSolid(S, St, f) { return HandMove(hand: nil, missHand: nil, set: [("w", 1)], keep: ["flatx": 0], check: true) }
                if KS.inside((f.x, f.y), S.flat.map { let p = St.up($0.0, $0.1, 0); return (p.x, p.y) }) {
                    return HandMove(hand: nil, missHand: nil, set: [("w", 0)], keep: ["flatx": 1], check: true)
                }
                return nil
            })
        case 2:
            let r = blockRects(s, S, St)
            return Hands(tap: { q in
                let f = board(q)
                if KS.hit(f, r) != nil {
                    // None: the sphere's answer; a solid with a flat face has one lit
                    let face = seenFlat(S).first.flatMap { SK.faceNames.firstIndex(of: $0) } ?? 1
                    return HandMove(hand: nil, missHand: nil, set: [("f", 0)], keep: P.s.faces > 0 ? ["hint": Double(face), "wrongNone": 1] : ["seeAt": PaperClock.now], check: true)
                }
                let G = S.shape(S.rest)
                for id in seenFlat(S) where KS.inside((f.x, f.y), SK.hull(G.face(id).map { St.up($0) })) {
                    return HandMove(hand: nil, missHand: nil, set: [("f", 1)], keep: ["seeAt": PaperClock.now, "wrongNone": 0], check: true)
                }
                if let h = s.run.kept["hint"], h >= 0, KS.inside((f.x, f.y), SK.hull(G.face(SK.faceNames[Int(h)]).map { St.up($0) })) {
                    return HandMove(hand: nil, missHand: nil, set: [("f", 1)], keep: ["seeAt": PaperClock.now, "wrongNone": 0], check: true)
                }
                return onSolid(S, St, f) ? HandMove(hand: nil, missHand: nil, set: [("f", -1)], check: true) : nil
            })
        case 3:
            let r = blockRects(s, S, St), guess = Int(s.run.kept["guess"] ?? -1)
            func pushed() -> HandMove {
                let right = guess == (P.s.rolls ? 0 : 1)
                return HandMove(hand: [:], missHand: [:], set: [("r", Double(guess))],
                                keep: right ? ["push": PaperClock.now] : ["push": PaperClock.now, "guess": -1, "wrongRoll": Double(guess)], check: true)
            }
            return Hands(
                tap: { q in
                    let f = board(q)
                    if let j = KS.hit(f, r) { return HandMove(hand: nil, missHand: nil, keep: ["guess": Double(j), "wrongRoll": -1]) }
                    return nil
                },
                grab: { q in guess >= 0 && onSolid(S, St, board(q)) ? ["grab": 1, "x0": q.x, "y0": q.y, "mv": 0] : nil },
                drag: { q, h in var h = h; if hypot(q.x - (h["x0"] ?? q.x), q.y - (h["y0"] ?? q.y)) > 2 { h["mv"] = 1 }; return h },
                release: { h in (h["mv"] ?? 0) == 1 ? pushed() : HandMove(hand: [:]) })
        case 4:
            let r = blockRects(s, S, St)
            return Hands(tap: { q in
                guard let j = KS.hit(board(q), r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wrong": j == P.rightName ? -1 : Double(j)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Scene(s.numbers), P = S.P, St = s.standing(S.pivot), st = at(s)
        func paper(_ b: CGPoint) -> CGPoint { st == 0 ? b : St.down(b) }
        let solidC: CGPoint = { let b = SK.bounds(S.shape(S.rest).points.map { St.up($0) }); return CGPoint(x: b.midX, y: b.midY) }()
        let r = blockRects(s, S, St)
        switch st {
        case 0:
            let c = SK.bounds(S.shape(S.rest).points.map { CGPoint(x: $0.x, y: $0.y) })
            return [.drag(from: CGPoint(x: c.midX, y: c.maxY), to: CGPoint(x: c.midX, y: c.maxY - 10))]
        case 1: return [.tap(.picture(paper(solidC)))]
        case 2:
            if P.s.faces == 0, let b = r.first { return [.tap(.picture(paper(CGPoint(x: b.midX, y: b.midY))))] }
            let G = S.shape(S.rest)
            guard let f = seenFlat(S).first, let m = G.middle(f) else { return [] }
            return [.tap(.picture(paper(St.up(m))))]
        case 3:
            let j = P.s.rolls ? 0 : 1, from = paper(solidC)
            var moves: [GhostMove] = []
            if r.indices.contains(j) { moves.append(.tap(.picture(paper(CGPoint(x: r[j].midX, y: r[j].midY))))) }
            moves.append(.drag(from: from, to: CGPoint(x: from.x + (P.side == 1 ? 6 : -6), y: from.y)))
            return moves
        case 4: return r.indices.contains(P.rightName) ? [.tap(.picture(paper(CGPoint(x: r[P.rightName].midX, y: r[P.rightName].midY))))] : []
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let S = Scene(s.numbers), P = S.P
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("t", 0)], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("w", 0)], keep: ["flatx": 1], check: true)
        case 2:
            if P.s.faces > 0 { let face = seenFlat(S).first.flatMap { SK.faceNames.firstIndex(of: $0) } ?? 1; return HandMove(hand: nil, missHand: nil, set: [("f", 0)], keep: ["hint": Double(face), "wrongNone": 1], check: true) }
            return HandMove(hand: nil, missHand: nil, set: [("f", -1)], check: true)
        case 3:
            let g = P.s.rolls ? 1 : 0
            return HandMove(hand: [:], missHand: [:], set: [("r", Double(g))], keep: ["push": PaperClock.now, "guess": -1, "wrongRoll": Double(g)], check: true)
        case 4:
            let j = (P.rightName + 1) % 4
            return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wrong": Double(j)], check: true)
        default: return nil
        }
    }
}
