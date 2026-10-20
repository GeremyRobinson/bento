import SwiftUI

/// One problem on a lesson's page (BarsPage), whatever its picture: the fraction bars (AddFractionsModel) or a lesson
/// worked in typed steps with its picture drawn from a Sketch (WorkProblem). The page, its words and the bar only
/// need this much of it.
@MainActor
protocol PageProblem: AnyObject {
    var id: UUID { get }
    /// What the page calls it: "How to", "Problem 3", "Skill check 1".
    var label: String { get }
    /// The How to plays itself.
    var auto: Bool { get }
    var origin: Point { get }
    var chapter: Chapter { get }
    var lesson: LessonRun { get }
    var solved: Bool { get }
    var animating: Bool { get }
    var busy: Bool { get }
    var message: (text: String, ok: Bool)? { get }
    /// The How to's words in place of the step's, while it explains.
    var intro: String? { get set }
    var howToButtons: [ProblemLayout.Kind] { get set }
    var onSolved: (() -> Void)? { get set }
    var onTouch: (() -> Void)? { get set }
    var onChange: (() -> Void)? { get set }
    var needs: ((Rect) -> Void)? { get set }
    /// Where a pick-one step's choices go, under the step's words.
    var underStep: Double { get }
    var wordsAt: Double { get }
    /// Its box's size on the paper (BarsPage.box): 8 blocks square, or as big as its maths needs.
    var boxSize: Size { get }

    func start(after delay: Double)
    func leave()
    func gone(at t: Double) -> Double
    func words(at t: Double) -> Double
    func guide(at t: Double) -> Double
    func replay()
    @discardableResult func demonstrate() -> Double
    func go()
    func choose(_ i: Int)
    func showMe()
    /// The bar's Hint: the step's hint shown on the paper (a paper lesson writes it on rows 3–4 and lights its part of
    /// the picture).
    func showHint()
    func reset()
    func usedHint()
    func tapPaper(_ p: Point)
    /// A drag that starts on something the child can move (a point, a length, a cut): true takes it, and the drag's
    /// moves and its end come here instead of panning the paper. Paper points.
    func grab(_ p: Point) -> Bool
    func drag(to p: Point)
    func release()
    /// Brought back from where the child left it: its picture as it was, at once.
    func restore()
    /// The How to's explaining beats after the lesson's first words: what each says, and what it draws.
    func howToBeats() -> [(words: String, run: () -> Void)]
}

extension PageProblem {
    func showHint() {}
    func grab(_ p: Point) -> Bool { false }
    func drag(to p: Point) {}
    func release() {}
}
