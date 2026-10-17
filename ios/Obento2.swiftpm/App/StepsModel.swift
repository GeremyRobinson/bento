import SwiftUI

/// A lesson worked in steps on the flat paper: the child types each step's answer on the keypad, and the
/// finished steps stay on the paper like written work. The lesson logic is the engine's (Core/LessonEngine.swift);
/// this keeps the timing, and the picture master reads it.
@MainActor @Observable
final class StepsModel {
    /// The lesson's top-left, in paper points, on grid lines.
    let origin: Point
    let chapter: Chapter
    /// The lesson's number in its chapter.
    let number: Int
    let instant: Bool
    private(set) var lesson: LessonRun
    private var rng: SeededRandom
    private(set) var openedAt: Double
    private(set) var wordsAt: Double = PaperClock.now
    /// When the picture last changed (the point hopping, say).
    private(set) var pictureAt: Double = PaperClock.now
    enum Said { case wrong, explain }
    var message: (text: String, kind: Said)?

    // where things sit, in paper points from `origin`
    static let pictureTop: Double = 100, workTop: Double = 280, row: Double = 60, keypadX: Double = 540

    init(spec: LessonSpec, origin: Point, chapter: Chapter, number: Int, instant: Bool, numbers: Numbers? = nil) {
        self.origin = origin; self.chapter = chapter; self.number = number; self.instant = instant
        var r = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        lesson = LessonRun(spec, numbers: numbers ?? spec.generate(&r))
        rng = r
        openedAt = instant ? PaperClock.now - 100 : PaperClock.now
    }

    func start() { openedAt = time(0); wordsAt = PaperClock.now }

    /// The words, the picture, the work, the keypad and the buttons: what opening the lesson frames.
    var frame: Rect { Rect(x: origin.x - 40, y: origin.y - 120, width: Self.keypadX + 200, height: 720) }
    /// The steps whose work is written on the paper so far, and the one being worked.
    var workSteps: [Int] { (0...lesson.index).filter { lesson.steps[$0].answer != nil } }
    /// Where the buttons go: under the last line of work.
    var toolsY: Double { Self.workTop + Double(max(1, workSteps.count)) * Self.row + 60 }

    var animating: Bool {
        let now = PaperClock.now
        return now - openedAt < 1.6 || now - wordsAt < 0.8 || now - pictureAt < 2.4
    }

    func go() {
        switch lesson.go() {
        case .moved: message = nil; wordsAt = PaperClock.now; pictureAt = time(0)
        case .notYet(let line): message = (line, .wrong)
        case .newProblem: restart()
        }
    }

    func type(_ key: String) { lesson.type(key); if message?.kind == .wrong { message = nil } }
    func select(_ box: String) { lesson.active = box }
    func showMe() { if let e = lesson.showAnswer() { message = (e, .explain) } }
    func reset() { lesson.reset(); message = nil }

    private func restart() {
        lesson = LessonRun.fresh(lesson.spec, using: &rng)
        message = nil; openedAt = time(0); wordsAt = PaperClock.now; pictureAt = PaperClock.now
    }

    private func time(_ delay: Double) -> Double { instant ? PaperClock.now - 100 : PaperClock.now + delay }

    // MARK: read at a moment in time, for drawing

    /// The picture growing in when the lesson opens.
    func grow(at t: Double) -> Double { ease((t - openedAt - 0.3) / 0.6) }
    /// Seconds since the picture last changed.
    func sincePicture(_ t: Double) -> Double { t - pictureAt }
}
