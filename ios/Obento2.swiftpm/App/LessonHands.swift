import SwiftUI

/// What the child does with their hands on a lesson's picture (LESSONS.md §3; G 20 Oct: the grid is the measuring tool,
/// and the answer is found on it, not only typed). A paper lesson (PaperLessons) says what its hands can do on each
/// step (Hands): tap a square, grab something and drag it (it snaps to the grid as the finger moves, its live parts
/// redrawn at once), let it go, or press one of its own blocks ("Cut"). A move can change the problem's hand state,
/// set the step's answer boxes (LessonRun.set), and check the step now (WorkProblem.go), so Core's checks, slip messages
/// and misses all apply, as they do to typing. Everything works in the lesson's own squares: a hand only ever lands on
/// a grid line or in a square.
extension WorkProblem {
    /// This step's hands, if it has any: the lesson's, for the state it's in. None while the picture proves a step, the
    /// ghost finger plays, or the problem is done.
    var hands: Hands? { solved || auto || ghost != nil ? nil : paper?.hands(state()) }

    /// A paper point in the picture's squares (the space the lesson built its drawing in).
    func squares(_ p: Point) -> CGPoint {
        let l = layout
        return CGPoint(x: (p.x - contentOrigin.x - l.pictureOffset.x) / Paper.cell, y: (p.y - contentOrigin.y - l.pictureOffset.y) / Paper.cell)
    }

    /// A tap on the picture (blocks are tapped first, BarsPage.tap).
    func handTap(_ p: Point) -> Bool {
        guard !busy, let mv = hands?.tap?(squares(p)) else { return false }
        apply(mv); return true
    }

    /// A drag starting here: true when it takes hold of something the child can move (the paper pans otherwise).
    func grab(_ p: Point) -> Bool {
        guard !busy, let held = hands?.grab?(squares(p)) else { return false }
        onTouch?()
        hand = held; dragging = true; handAt = PaperClock.now
        // what a miss said goes as the child tries again
        if message != nil { message = nil }
        return true
    }

    /// The finger moved: the hand state for where it is now, applied only when its snapped value changes (so nothing is
    /// redrawn or saved for a move within a square).
    func drag(to p: Point) {
        guard dragging, let d = hands?.drag else { return }
        let now = d(squares(p), hand)
        if now != hand { hand = now; handAt = PaperClock.now }
    }

    /// Let go: the move's result (often checked now, answering the step); the page is saved once, here.
    func release() {
        guard dragging else { return }
        dragging = false
        if let r = hands?.release { apply(r(hand)) } else { onChange?() }
    }

    /// A drag is under way: the bar shows its readout (the calm pill, G 26 Oct).
    var handMoving: Bool { dragging }
    /// What the hand move reads now, as the lesson's live drawing has it (its readout label's words).
    var liveReadout: String? {
        guard dragging, let paper else { return nil }
        if let c = readoutFor, c.hand == hand { return c.text }
        let text = paper.draw(state()).live.readout
        readoutFor = (hand, text)
        return text
    }

    /// One of the lesson's own blocks ("Cut").
    func act(_ name: String) {
        guard !busy, let a = hands?.actions[name] else { return }
        apply(a())
    }
}
