import SwiftUI

/// What the child does with their hands on a lesson's picture (LESSONS.md §3; G 20 Oct: the grid is the measuring
/// tool, and the answer is found on it, not only typed). A lesson's hands work in its own squares, the space its
/// Drawing is built in: a tap on a square, or a drag that starts on something movable, puts a value in one of the
/// step's answer boxes (as typing would), and the drawing shows it at once (it reads the boxes' values from its picture
/// keys as "typed.<box>"). Everything snaps to the grid: a hand only ever lands on a grid line or in a square.
struct Hands {
    /// A tap at a place (in squares): the box it sets and its value (nil clears it), or nil when it's not on anything.
    var tap: ((CGPoint) -> (box: String, value: Double?)?)? = nil
    /// Whether a drag starting here (in squares) is taken by the problem rather than panning the paper.
    var grab: ((CGPoint) -> Bool)? = nil
    /// Where the drag is now (in squares): the box it sets and its value.
    var drag: ((CGPoint) -> (box: String, value: Double?)?)? = nil
}

@MainActor
enum LessonHands {
    /// The hands a lesson's step has, from its numbers and the picture keys it's drawn with (none: typing only).
    static func hands(_ id: String, _ n: Numbers, _ keys: Numbers) -> Hands? {
        switch id {
        default: return nil
        }
    }
}

extension WorkProblem {
    /// This step's hands, if it has any.
    var hands: Hands? { solved || auto ? nil : LessonHands.hands(lesson.spec.id, lesson.numbers, drawingKeys) }

    /// A paper point in the picture's squares (the space the lesson built its drawing in).
    func squares(_ p: Point) -> CGPoint {
        let l = layout
        return CGPoint(x: (p.x - contentOrigin.x - l.pictureOffset.x) / Paper.cell, y: (p.y - contentOrigin.y - l.pictureOffset.y) / Paper.cell)
    }

    func handTap(_ p: Point) -> Bool {
        guard !busy, let r = hands?.tap?(squares(p)) else { return false }
        apply(r); return true
    }
    func grab(_ p: Point) -> Bool {
        guard !busy, let h = hands, h.grab?(squares(p)) == true else { return false }
        drag(to: p); return true
    }
    func drag(to p: Point) {
        guard let r = hands?.drag?(squares(p)) else { return }
        apply(r)
    }
    func release() {}
}
