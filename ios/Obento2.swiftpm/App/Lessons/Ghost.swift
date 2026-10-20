import SwiftUI

/// Show me and the How to, played with a ghost finger (G 20 Oct): a soft round fingertip with a short trail, drawn on the
/// paper in ink2, making the step's moves while the picture's live parts follow it. Show me is a preview (G 17 Oct): it
/// plays on a copy of the problem, holds a moment, then everything goes back exactly as the child left it; only the
/// step is counted as shown. The How to plays the same moves on its own problem and keeps them (it does the step).
struct GhostPlay {
    enum Mode { case preview, howTo }
    enum Event { case tap, grab, release, write }
    let id = UUID()
    let mode: Mode
    let start: Double
    /// Screenshots: the moment it stays at, in seconds from its start.
    var frozen: Double?
    /// The problem it plays on: a copy of the child's (Show me), or the How to's own, kept when it ends.
    var run: LessonRun
    var hand: Numbers
    let moves: [GhostMove]
    /// The finger's path: when it's where, and whether it's pressing.
    private(set) var keys: [(t: Double, at: GhostSpot, down: Bool)] = []
    /// What the moves do, when: in order, each fired once.
    private(set) var events: [(t: Double, move: Int, what: Event)] = []
    var fired = 0
    /// A drag under way: the hand state when it took hold.
    var held: Numbers?
    /// When the last move is made, and when it's over (Show me: everything goes back then).
    private(set) var done = 0.0, end = 0.0

    // a calm hand: a moment to reach each place, a press, a lift; a drag at a child's pace; then a hold to see it
    static let reach = 0.55, press = 0.14, lift = 0.3, hold = 0.9, fade = 0.3

    init(mode: Mode, start: Double, run: LessonRun, hand: Numbers, moves: [GhostMove]) {
        self.mode = mode; self.start = start; self.run = run; self.hand = hand; self.moves = moves
        var t = 0.25
        for (i, mv) in moves.enumerated() {
            switch mv {
            case .tap(let spot):
                keys += [(t + Self.reach, spot, false), (t + Self.reach + Self.press, spot, true), (t + Self.reach + Self.press + Self.lift, spot, false)]
                events.append((t + Self.reach + Self.press, i, .tap))
                t += Self.reach + Self.press + Self.lift
            case .drag(let from, let to):
                let along = min(1.3, max(0.6, hypot(to.x - from.x, to.y - from.y) * 0.03))
                let pressed = t + Self.reach + Self.press, letGo = pressed + along
                keys += [(t + Self.reach, .picture(from), false), (pressed, .picture(from), true), (letGo, .picture(to), true), (letGo + Self.lift, .picture(to), false)]
                events += [(pressed, i, .grab), (letGo, i, .release)]
                t = letGo + Self.lift
            case .write(let box, _):
                // a press in the box writes its number; the finger lifts away past the box's corner, so it shows
                keys += [(t + Self.reach, .box(box), false), (t + Self.reach + Self.press, .box(box), true), (t + Self.reach + Self.press + Self.lift, .box(box), false),
                         (t + Self.reach + Self.press + Self.lift + Self.reach, .beside(box), false)]
                events.append((t + Self.reach + Self.press + 0.1, i, .write))
                t += Self.reach + Self.press + Self.lift + Self.reach
            }
        }
        done = t
        end = t + Self.fade + Self.hold
    }

    /// Seconds since it started (or the moment it's frozen at).
    func time(_ now: Double) -> Double { frozen ?? (now - start) }
    var over: Bool { fired >= events.count }

    /// Where the finger is at `t` (its spots, and how far from one to the next), whether it's pressing, and how much
    /// of it shows (it comes in at the start and goes once the moves are made).
    func finger(at t: Double) -> (from: GhostSpot, to: GhostSpot, k: Double, down: Bool, shows: Double)? {
        guard let first = keys.first else { return nil }
        let shows = min(1, max(0, t / 0.25)) * (1 - min(1, max(0, (t - done) / Self.fade)))
        if t <= first.t { return (first.at, first.at, 1, false, shows) }
        for j in 1..<keys.count where t <= keys[j].t {
            let a = keys[j - 1], b = keys[j]
            let k = b.t > a.t ? ease((t - a.t) / (b.t - a.t)) : 1
            return (a.at, b.at, k, a.down && b.down ? true : (k < 0.5 ? a.down : b.down), shows)
        }
        let last = keys[keys.count - 1]
        return (last.at, last.at, 1, false, shows)
    }

    /// Where the finger is at `t` while it drags: from the press to the let-go, in the picture's squares.
    func dragPoint(at t: Double) -> CGPoint? {
        guard held != nil, let f = finger(at: t), case .picture(let a) = f.from, case .picture(let b) = f.to else { return nil }
        return CGPoint(x: a.x + (b.x - a.x) * f.k, y: a.y + (b.y - a.y) * f.k)
    }
}

extension Sketch {
    /// The ghost finger (G 20 Oct): a soft round fingertip, a short trail behind it, in ink2 on the paper. Pressing, it's
    /// a little smaller and firmer. `trail`: where it was a moment ago, newest first. Points are the paper's.
    mutating func ghostFinger(_ id: String, at p: CGPoint, down: Bool, trail: [CGPoint], shows: Double) {
        guard shows > 0.05 else { return }
        let paper: (UInt32, UInt32) = (0xF3F2EF, 0x121211), ink2: (UInt32, UInt32) = (0x6B6964, 0xA3A19B)
        func soft(_ k: Double) -> Colour { .hex(Ink.mix(paper.0, ink2.0, k * shows), Ink.mix(paper.1, ink2.1, k * shows)) }
        func disc(_ id: String, _ c: CGPoint, _ r: Double, _ colour: Colour) {
            polygon(id, (0..<28).map { i in let a = Double(i) / 28 * 2 * .pi; return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) }, colour)
        }
        let cell = Paper.cell
        for (i, q) in trail.enumerated() {
            let k = Double(trail.count - i) / Double(trail.count + 1)
            disc("\(id)trail\(i)", q, cell * (0.35 + 0.35 * k), soft(0.1 + 0.12 * k))
        }
        let r = cell * (down ? 0.82 : 0.95)
        disc("\(id)tip", p, r, soft(down ? 0.34 : 0.24))
        overLine("\(id)ring", (0...32).map { i in let a = Double(i) / 32 * 2 * .pi; return CGPoint(x: p.x + r * cos(a), y: p.y + r * sin(a)) }, soft(0.75), width: Sketch.stroke)
    }
}
