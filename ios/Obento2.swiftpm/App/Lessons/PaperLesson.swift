import SwiftUI

/// A lesson designed for the paper (G 20 Oct, design/README.md), the way Rounding decimals and Adding fractions were on
/// the test page G approved: the picture is the hero, each step is a hand move that snaps to the grid with a live
/// readout, the school working is written after it as the record, and Show me and the How to are played by a ghost
/// finger. A lesson only draws itself for the state it's in and says what the hands do; WorkProblem plays it,
/// ProblemGrid lays it out stacked (what to do, what a miss says, the picture, the record, the blocks), and Core's
/// LessonRun checks every move, so its slips, misses and points are the same as typing's.
///
/// Everything is in the lesson's own squares: the picture from its top-left corner (the stacked layout puts it under the
/// words), the record from its own top-left (put a few rows under the picture).
@MainActor
protocol PaperLesson {
    /// What it draws for this state: the picture, the live parts that follow the hand, the record, and its blocks.
    func draw(_ s: PaperState) -> PaperDrawing
    /// What the hands can do on this step (nil: nothing, as on a typed or a See step).
    func hands(_ s: PaperState) -> Hands?
    /// Show me and the How to: the ghost finger's moves for a step answered by hand (a typed or pick-one step's
    /// moves are the same for every lesson, WorkProblem.ghostMoves).
    func demo(_ s: PaperState) -> [GhostMove]
    /// The boxes of a step that an earlier move already answered (the cut answers the rewrites): set and checked at
    /// once, so the child goes straight on.
    func autoAnswer(_ s: PaperState) -> [String: Double]?
    /// Hand state that only the live parts read (a length being dragged, a point's place): the still picture isn't
    /// redrawn when only these change.
    var liveKeys: Set<String> { get }
    /// How many rows what a miss says may need (1, or 2 for a lesson whose slips run long).
    func messageRows(_ n: Numbers) -> Int
    /// The record's first row, in the picture's rows, when the lesson places it (nil: 3 rows under the biggest picture
    /// of any step). A record that comes only after the ruler and its dots are put away sits 3 rows under the picture
    /// it's written with, not under the dots that were there.
    func recordRow(_ n: Numbers) -> Double?
    /// Screenshots only (-wrong): a wrong move for this step, as a child might make it.
    func wrongMove(_ s: PaperState) -> HandMove?
    /// How much bigger than the paper its words, blocks and record are drawn (G 19 Oct: whole steps only): 2 or more
    /// for a problem whose true-size picture is so big that the camera steps far back to see it (an area model 98
    /// squares tall), so what's written still reads. The picture itself stays the paper's squares.
    func scale(_ n: Numbers) -> Double
    /// nil: the record always goes under the picture. A row of the picture: the record may go beside the picture
    /// instead, its first row level with that row, the blocks under it, when that shows the problem bigger on the screen
    /// (G 19 Oct rule 10: the arrangement that fills the screen best), as a picture taller than it's wide does.
    func recordBeside(_ n: Numbers) -> Double?
    /// The same three for a run as it's shown (told as a story, its words take more rows), which is what the layout
    /// asks: its numbers' unless the lesson's size depends on more than its numbers.
    func scale(_ run: LessonRun) -> Double
    func recordBeside(_ run: LessonRun) -> Double?
    func messageRows(_ run: LessonRun) -> Int
}

extension PaperLesson {
    func demo(_ s: PaperState) -> [GhostMove] { [] }
    func autoAnswer(_ s: PaperState) -> [String: Double]? { nil }
    var liveKeys: Set<String> { [] }
    func messageRows(_ n: Numbers) -> Int { 1 }
    func recordRow(_ n: Numbers) -> Double? { nil }
    func wrongMove(_ s: PaperState) -> HandMove? { nil }
    func scale(_ n: Numbers) -> Double { 1 }
    func recordBeside(_ n: Numbers) -> Double? { nil }
    func scale(_ run: LessonRun) -> Double { scale(run.numbers) }
    func recordBeside(_ run: LessonRun) -> Double? { recordBeside(run.numbers) }
    func messageRows(_ run: LessonRun) -> Int { messageRows(run.numbers) }
}

/// The lessons built on the paper, by lesson id. The rest keep LessonPictures' drawings until they're moved here.
@MainActor
enum PaperLessons {
    static func lesson(_ id: String) -> (any PaperLesson)? {
        switch id {
        case "g5-round": return RoundingLesson()
        case "add", "sub", "mix": return FractionsLesson()
        case "g5-mult2": return MultiplyLesson()
        case "g5-improper": return MixedNumbersLesson()
        case "g5-pow10": return PowersOfTenLesson()
        case "g5-adddec": return AddDecimalsLesson()
        case "g5-unitdiv": return UnitDivisionLesson()
        case "g5-fracof": return FractionOfLesson()
        case "g5-divide": return LongDivisionLesson()
        case "g5-multdec": return MultiplyDecimalsLesson()
        case "g5-order": return OrderLesson()
        case "g5-multfrac": return MultiplyFractionsLesson()
        case "g5-units": return UnitsLesson()
        default: return nil
        }
    }
}

/// What a lesson draws from: the run (its numbers, its steps, what's typed), the step drawn, the hand's state now, and
/// the picture keys (the step's, with its hint drawings when a hint is shown or a miss earned one).
struct PaperState {
    var run: LessonRun
    /// The step drawn: the run's own, or any step when the layout measures them all.
    var index: Int
    /// The problem's hand state: what's held and where (a ruler's length, a point's place, pieces being slid). It lives
    /// only while the step does.
    var hand: Numbers = [:]
    var picture: Numbers = [:]
    /// What's typed in the record's boxes (the ghost's, faint, while Show me plays).
    var typed: [String: String] = [:]
    var faint = false
    /// Right or wrong on the record's box that was checked (green and red mean only these).
    var verdict: Bool?
    var active: String?

    var numbers: Numbers { run.numbers }
    var step: LessonStep { run.steps[index] }
    func v(_ k: String) -> Double { run.numbers[k] ?? 0 }
    func int(_ k: String) -> Int { Int((run.numbers[k] ?? 0).rounded()) }
    func on(_ k: String) -> Bool { (picture[k] ?? 0) != 0 }
    func h(_ k: String) -> Double? { hand[k] }
    var grabbed: Bool { (hand["grab"] ?? 0) != 0 }
    /// A pick-one step (a story's "Pick what to do"): the sign stays hidden until it's picked.
    var picking: Bool { step.answer?.choices != nil }
    /// This step is answered by the hands.
    var byHand: Bool { step.answer?.byHand == true }

    /// The state at step `i` with nothing held or typed: what the layout measures.
    func at(_ i: Int, hint: Bool) -> PaperState {
        var s = PaperState(run: run, index: i)
        let st = run.steps[i]
        s.picture = hint ? st.picture.merging(st.onMiss) { $1 } : st.picture
        return s
    }
}

/// A lesson's drawing for one state, in its own squares (GridPen, so everything lands on the grid).
@MainActor
struct PaperDrawing {
    /// The picture, from its top-left: drawn in, as everything is (SketchDrawer).
    var picture = Sketch()
    /// What follows the hand, from the same corner: drawn at once as the finger moves, never drawn in or glided.
    var live = Sketch()
    /// The record (the school working), from its own top-left, and its boxes there.
    var record = Sketch()
    var boxes: [WorkBox] = []
    /// The lesson's own blocks shown now ("Cut"), each running the lesson's code (Hands.actions).
    var actions: [String] = []
    /// Room the picture needs beyond what's drawn now (a move about to make room for more), in its points.
    var extent: CGRect?
}

/// What the hands do on a step, in the lesson's squares (the picture's): a tap, a drag that starts on something the
/// child can move (it grabs, follows the finger snapping to the grid, and is let go), and the lesson's own blocks.
/// Taps on blocks win over the picture.
struct Hands {
    var tap: ((CGPoint) -> HandMove?)? = nil
    /// A drag starting here takes hold (the hand state while held), or nil: the paper pans instead.
    var grab: ((CGPoint) -> Numbers?)? = nil
    /// The hand state for the finger here, from the state while held (snapped: it only changes square by square).
    var drag: ((CGPoint, Numbers) -> Numbers)? = nil
    /// Let go: what the move does, from the state as it was let go.
    var release: ((Numbers) -> HandMove)? = nil
    /// The lesson's blocks: what each does when tapped.
    var actions: [String: () -> HandMove] = [:]
}

/// What a hand move does: the hand state just after it, the answer boxes it sets (LessonRun.set), the cells it marks or
/// unmarks (LessonRun.tap, a step with a MarkTask), and whether it's checked now (WorkProblem.go: a release that answers
/// the step). A miss puts the hand state back to `missHand` (nil keeps it: the ruler stays where it was).
struct HandMove {
    var hand: Numbers? = nil
    var missHand: Numbers? = [:]
    var set: [(box: String, value: Double?)] = []
    var marks: [Int] = []
    var check = false
}

/// Where the ghost finger goes: a place on the picture (its squares), or a block or box by what it is.
enum GhostSpot: Equatable {
    case picture(CGPoint)
    case action(String)
    case check
    case choice(Int)
    case box(String)
    /// Just past a box's bottom-right corner: where the finger lifts away to, so what it wrote shows.
    case beside(String)
}

/// One move the ghost finger makes (Show me and the How to, G 20 Oct).
enum GhostMove {
    /// A tap: on the picture (the lesson's tap), or on a block (it's pressed).
    case tap(GhostSpot)
    /// Press, drag (the live parts follow it), let go: from one place on the picture to another.
    case drag(from: CGPoint, to: CGPoint)
    /// Into a record box: its number written.
    case write(box: String, text: String)
}
