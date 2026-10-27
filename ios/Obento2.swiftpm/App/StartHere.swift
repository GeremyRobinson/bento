import SwiftUI

/// "Start here, Mia." beside the first lesson of the child's grade (G 26 Oct, the front door): once setting up is done,
/// on a map nothing has been started on yet, written on the paper as the map draws in. Nothing is chosen for the child
/// (no Start tag, no finger tapping a lesson for them); it goes once they've started something (Core/Setup.swift, Fresh).
@MainActor
enum StartHere {
    /// The lesson it stands beside: the first one up next (today's pick on a fresh map is the grade's first lesson).
    @MainActor static var piece: Piece? { Map.today ?? Map.pieces.first(where: { $0.state == .now }) }

    /// It's on the map now.
    @MainActor static var shows: Bool { Fresh.showsStartHere(setUp: !AppSettings.needsSetup, untouched: Map.untouched) }

    /// The words, in the child's name when there is one.
    @MainActor static var words: String { Setup.startHere(AppSettings.name) }
    static let font = PaperText.font(Sketch.wordSize, .medium)

    /// Where it's written: beside the lesson's frame on its left, level with its middle, its ink half a square from the
    /// frame (as a label's is) when nothing else is there; else on the line under its name.
    @MainActor static func note(for p: Piece) -> (at: CGPoint, beside: Bool) {
        let r = p.frame, free = !Map.all.contains { q in q.id != p.id && abs(q.at.y - p.at.y) < 1 && q.at.x < p.at.x && q.at.x > p.at.x - 4 * Paper.unit }
        return free ? (CGPoint(x: r.x - Paper.cell / 2, y: r.mid.y), true) : (CGPoint(x: r.x, y: r.y + r.height + 50), false)
    }

    /// The part of the paper its words take, so the map's first view can show them with the chapter.
    @MainActor static func bounds(for p: Piece) -> Rect {
        let n = note(for: p), w = PaperText.width(words, font)
        return n.beside ? Rect(x: n.at.x - w, y: n.at.y - Sketch.row / 2, width: w, height: Sketch.row)
            : Rect(x: n.at.x, y: n.at.y - Sketch.row / 2, width: w, height: Sketch.row)
    }
}

extension Sketch {
    /// "Start here, Mia." beside the first lesson (StartHere.note): what to do, at the words' size.
    mutating func startHere(_ p: Piece) {
        let n = StartHere.note(for: p), words = StartHere.words
        if n.beside { label("start-here", words, .say, at: n.at, anchor: UnitPoint(x: 1, y: 0.5)) }
        else { label("start-here", words, Sketch.Words.status.colour(.hex(p.chapter.hex, p.chapter.hex)), at: n.at, anchor: UnitPoint(x: 0, y: 0.5)) }
    }
}
