import SwiftUI

/// The very first time the app opens (G 20 Oct): once the map has drawn itself in, a ghost finger (the lessons' own:
/// GhostPlay's calm timing, Sketch.ghostFinger's look) comes to the first lesson up next and taps it once, so it's
/// chosen as a tap chooses it (it glides into view, its tab saying Start), and "Start here." is written beside it on
/// the paper. Shown once, remembered on the device, and never again.
struct StartHere {
    let piece: Piece
    /// When the finger starts coming in.
    let start: Double
    /// Screenshots only: the moment it stays at, in seconds from its start.
    var frozen: Double?
    /// The tap has been made (the lesson chosen).
    var tapped = false

    /// Remembered once it has played: it never plays again.
    static let key = "start-here-shown"
    static var shown: Bool { UserDefaults.standard.bool(forKey: key) }

    // the lessons' ghost's calm hand: in, a moment to reach the lesson, a press, a lift, a hold, then gone
    static let come = 0.25, reach = GhostPlay.reach, press = GhostPlay.press, lift = GhostPlay.lift, hold = 1.1, fade = GhostPlay.fade
    /// Seconds from its start to the press (the tap), to its lift, and to its end.
    static var tapTime: Double { come + reach + press }
    static var liftTime: Double { tapTime + lift }
    static var end: Double { liftTime + hold + fade }

    func time(_ t: Double) -> Double { frozen ?? (t - start) }
    /// The tap is due (the press has landed).
    func tapDue(at t: Double) -> Bool { !tapped && time(t) >= Self.tapTime }
    /// It's still on the paper (the clock keeps running).
    func playing(at t: Double) -> Bool { frozen != nil ? false : time(t) < Self.end + 0.2 }

    /// Where the finger is at `t` (paper points), whether it's pressing, where it was a moment ago (newest first), and
    /// how much of it shows; nil before it starts and once it's gone.
    func finger(at t: Double) -> (at: CGPoint, down: Bool, trail: [CGPoint], shows: Double)? {
        let now = time(t)
        guard now >= 0, now < Self.end else { return nil }
        func place(_ s: Double) -> CGPoint {
            // from three squares below and right of the lesson's middle, in to it
            let target = CGPoint(x: piece.frame.mid.x, y: piece.frame.mid.y), d = 3 * Paper.cell
            let k = ease((s - Self.come) / Self.reach)
            return CGPoint(x: target.x + d * (1 - k), y: target.y + d * (1 - k))
        }
        let p = place(now)
        let shows = min(1, now / Self.come) * (1 - min(1, max(0, (now - Self.liftTime - Self.hold) / Self.fade)))
        let down = now >= Self.come + Self.reach && now < Self.liftTime
        var trail: [CGPoint] = []
        for k in 1...3 { let q = place(now - 0.05 * Double(k)); if hypot(q.x - p.x, q.y - p.y) > 3 { trail.append(q) } }
        return (p, down, trail, shows)
    }

    /// Where "Start here." is written: beside the lesson's frame on its left, level with its middle, its ink half a square
    /// from the frame (as a label's is) when nothing else is there; else on the line under its name.
    static func note(for p: Piece) -> (at: CGPoint, beside: Bool) {
        let r = p.frame, free = !Map.all.contains { q in q.id != p.id && abs(q.at.y - p.at.y) < 1 && q.at.x < p.at.x && q.at.x > p.at.x - 4 * Paper.unit }
        return free ? (CGPoint(x: r.x - Paper.cell / 2, y: r.mid.y), true) : (CGPoint(x: r.x, y: r.y + r.height + 50), false)
    }
}

extension Sketch {
    /// "Start here." beside the lesson the first launch chose (StartHere.note): what to do, at the words' size.
    mutating func startHere(_ p: Piece) {
        let n = StartHere.note(for: p)
        if n.beside { label("start-here", "Start here.", .say, at: n.at, anchor: UnitPoint(x: 1, y: 0.5)) }
        else { label("start-here", "Start here.", Sketch.Words.status.colour(.hex(p.chapter.hex, p.chapter.hex)), at: n.at, anchor: UnitPoint(x: 0, y: 0.5)) }
    }
}
