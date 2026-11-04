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
    /// Screenshots only (-wrong): a slip written into a typed step's boxes, when a lesson names one (nil: "1" typed into
    /// the first box).
    func wrongTyping(_ s: PaperState) -> [String: Double]?
    /// How much bigger than the paper its words, blocks and record are drawn (G 19 Oct: whole steps only): 2 or more
    /// for a problem whose true-size picture is so big that the camera steps far back to see it (an area model 98
    /// squares tall), so what's written still reads. The picture itself stays the paper's squares.
    func scale(_ n: Numbers) -> Double
    /// nil: the record always goes under the picture. A row of the picture: the record may go beside the picture
    /// instead, its first row level with that row, the blocks under it, when that shows the problem bigger on the screen
    /// (G 19 Oct rule 10: the arrangement that fills the screen best), as a picture taller than it's wide does.
    func recordBeside(_ n: Numbers) -> Double?
    /// nil: the blocks go under everything, from the record's left edge. A column of the record: the record sits beside
    /// part of the picture (in a column the hands emptied, or one shorter than the rest), and the blocks go two squares
    /// under it, from this column (4th grade's Mixed numbers, so the problem shows at 75% or more).
    func blocksLeft(_ n: Numbers) -> Double?
    /// nil: the blocks go where the layout puts them. A place in the picture's squares (its left column, its top row):
    /// the blocks start there on this step, in room the picture leaves (a story's choices beside a tall picture).
    func blocksAt(_ s: PaperState) -> CGPoint?
    /// Keys up and the camera on the line being typed: part of the picture (its squares) that must stay in the frame
    /// with the line, as the number to write is read off it (where a fold printed a point).
    func keysFocus(_ s: PaperState) -> CGRect?
    /// The same three for a run as it's shown (told as a story, its words take more rows), which is what the layout
    /// asks: its numbers' unless the lesson's size depends on more than its numbers.
    func scale(_ run: LessonRun) -> Double
    func recordBeside(_ run: LessonRun) -> Double?
    func messageRows(_ run: LessonRun) -> Int
    /// Something of it rises off the paper (shared 3D, PaperStand.swift): it draws `PaperDrawing.solids`.
    var solid: Bool { get }
    /// This state stands the paper up (3D): the point of the picture (its squares, on the paper) the paper turns about, or
    /// nil (flat). The words it writes then stand facing the child where the flat paper has them (Standing.up places them).
    func stands(_ s: PaperState) -> CGPoint?
    /// When a step stops standing: how long the paper stays up before it lies flat (a box closed a moment).
    func lingers(_ s: PaperState) -> Double
    /// How long the paper waits, lying flat, before it first stands (Where is it?: the words are read on the flat paper,
    /// then it tilts by itself).
    func standDelay(_ s: PaperState) -> Double
    /// The paper held part way up by a finger (Solid shapes' "Tilt the paper."): the pivot and how far up (0 flat, 1
    /// standing), following the finger 1:1; let go, it stands on the spring when the step stands, else it falls back.
    func standHeld(_ s: PaperState) -> (pivot: CGPoint, up: Double)?
    /// What to do now, when the hands have changed it within a step ("Push it." once rolls or slides is tapped): nil, the
    /// step's own words.
    func say(_ s: PaperState) -> String?
    /// The picture alone for a moment (K Count to 100's whole chart, call of 4 Nov): the words, the record and the blocks
    /// step aside and the camera frames only the picture, then they come back. Asked every frame (it may read the clock).
    func alone(_ s: PaperState) -> Bool
}

extension PaperLesson {
    func demo(_ s: PaperState) -> [GhostMove] { [] }
    func autoAnswer(_ s: PaperState) -> [String: Double]? { nil }
    var liveKeys: Set<String> { [] }
    func messageRows(_ n: Numbers) -> Int { 1 }
    func recordRow(_ n: Numbers) -> Double? { nil }
    func wrongMove(_ s: PaperState) -> HandMove? { nil }
    func wrongTyping(_ s: PaperState) -> [String: Double]? { nil }
    func scale(_ n: Numbers) -> Double { 1 }
    func recordBeside(_ n: Numbers) -> Double? { nil }
    func blocksLeft(_ n: Numbers) -> Double? { nil }
    func blocksAt(_ s: PaperState) -> CGPoint? { nil }
    func keysFocus(_ s: PaperState) -> CGRect? { nil }
    var solid: Bool { false }
    func stands(_ s: PaperState) -> CGPoint? { nil }
    func lingers(_ s: PaperState) -> Double { 0 }
    func standDelay(_ s: PaperState) -> Double { 0 }
    func standHeld(_ s: PaperState) -> (pivot: CGPoint, up: Double)? { nil }
    func say(_ s: PaperState) -> String? { nil }
    func alone(_ s: PaperState) -> Bool { false }
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
        case "g5-divdec": return DivideByDecimalLesson()
        case "g5-coord": return CoordLesson()
        case "g5-shapes": return ShapesLesson()
        case "g5-compare": return CompareDecimalsLesson()
        case "g5-fracdiv": return FractionsAsDivisionLesson()
        // 4th grade, Big numbers (3 Nov 2026)
        case "g4-tentimes": return TensHundredsLesson()
        case "g4-readwrite": return ReadWriteLesson()
        case "g4-compare": return CompareBigLesson()
        case "g4-placevalue": return PlaceValueLesson()
        case "g4-addsub": return AddSubBigLesson()
        // 4th grade, Multiplying and dividing (3 Nov 2026)
        case "g4-times": return TimesAsManyLesson()
        case "g4-partial": return MultiplyBigLesson()
        case "g4-mult2x2": return TwoByTwoLesson()
        case "g4-divide": return DealLesson(big: false)
        case "g4-share": return DealLesson(big: true)
        case "g4-multistep": return StoryStepsLesson()
        // 4th grade, Factors and patterns (3 Nov 2026)
        case "g4-factors": return FactorsLesson()
        case "g4-prime": return PrimeLesson()
        case "g4-patterns": return PatternsLesson()
        // 4th grade, Fractions (3 Nov 2026)
        case "g4-decompose": return DecomposeLesson()
        case "g4-equiv": return EquivLesson()
        case "g4-fraccompare": return CompareFractionsLesson()
        case "g4-likefrac", "g4-likesub": return LikeFractionsLesson()
        // 4th grade, Mixed numbers (3 Nov 2026)
        case "g4-mixed": return AddMixedLesson()
        case "g4-mixedsub": return SubtractMixedLesson()
        case "g4-fracwhole": return FracTimesWholeLesson()
        // 4th grade, Decimals (3 Nov 2026)
        case "g4-dec": return TenthsHundredthsLesson()
        case "g4-decline": return DecimalLineLesson()
        case "g4-deccompare": return CompareDec4Lesson()
        // 4th grade, Measurement (3 Nov 2026)
        case "g4-convert": return ConvertLesson()
        case "g4-measure": return MeasureStoryLesson()
        case "g4-area": return AreaPerimLesson()
        case "g4-lineplot": return LinePlotLesson()
        // 4th grade, Lines and shapes (3 Nov 2026)
        case "g4-lines": return LinesLesson()
        case "g4-turns": return TurnsLesson()
        case "g4-protractor": return ProtractorLesson()
        case "g4-angles": return AnglesAddLesson()
        case "g4-classify": return ClassifyLesson()
        case "g4-symmetry": return SymmetryLesson()
        // 6th grade, Ratios and percents (3 Nov 2026)
        case "g6-ratio": return EquivRatioLesson()
        case "g6-ratiotable": return RatioTableLesson()
        case "g6-rate": return UnitRateLesson()
        case "g6-pctof": return PercentOfLesson()
        case "g6-pctwhole": return PercentWholeLesson()
        // 6th grade, Factors and fractions (3 Nov 2026)
        case "g6-lcm": return LcmLesson()
        case "g6-gcf": return GcfLesson()
        case "g6-divide": return DivideFractionsLesson()
        // 6th grade, Long division and decimals (4 Nov 2026)
        case "g6-longdiv": return LongDiv6Lesson(dec: false)
        case "g6-decdiv": return LongDiv6Lesson(dec: true)
        case "g6-decaddsub": return DecAddSubLesson()
        case "g6-decmult": return DecMultLesson()
        // 6th grade, Negative numbers (4 Nov 2026)
        case "g6-negatives": return NegativesLesson()
        case "g6-compare": return CompareNegLesson()
        case "g6-numline": return DistanceLesson()
        case "g6-quadrants": return QuadrantsLesson()
        case "g6-planeshapes": return PlaneShapesLesson()
        // 6th grade, Expressions (4 Nov 2026)
        case "g6-expo": return ExpoLesson()
        case "g6-write": return WriteExprLesson()
        case "g6-eval": return EvalExprLesson()
        case "g6-equiv": return EquivExprLesson()
        // 6th grade, Equations (4 Nov 2026)
        case "g6-onestep": return OneStepLesson()
        case "g6-ineq": return InequalitiesLesson()
        case "g6-depend": return TwoQuantitiesLesson()
        // 6th grade, Area and volume (4 Nov 2026)
        case "g6-para": return ParaLesson()
        case "g6-tri": return TriLesson()
        case "g6-trap": return TrapLesson()
        case "g6-poly": return PolyLesson()
        case "g6-nets": return NetsLesson()
        case "g6-fracvol": return FracVolLesson()
        // 6th grade, Data (4 Nov 2026)
        case "g6-dotplot": return DotPlotLesson()
        case "g6-histogram": return HistogramLesson()
        case "g6-mean": return MeanLesson()
        case "g6-mad": return MadLesson()
        case "g6-median": return MedianLesson()
        case "g6-boxplot": return BoxPlotLesson()
        // Kindergarten, Count to 10 (4 Nov 2026)
        case "gk-count10": return CountToTenLesson()
        case "gk-onemore": return OneMoreLesson()
        case "k-compare": return CompareGroupsLesson()
        case "gk-numcompare": return CompareNumbersLesson()
        // Kindergarten, Shapes (4 Nov 2026)
        case "k-shapes": return FlatShapesLesson()
        case "gk-draw": return DrawShapesLesson()
        case "k-solids": return SolidShapesLesson()
        case "gk-position": return WhereIsItLesson()
        case "gk-compose": return PutShapesLesson()
        // Kindergarten, Measure and sort (4 Nov 2026)
        case "k-length": return LengthLesson()
        case "gk-heavier": return HeavierLesson()
        case "k-sort": return SortLesson()
        // Kindergarten, Add and take away (4 Nov 2026)
        case "k-add": return AddLesson()
        case "k-sub": return TakeAwayLesson()
        case "k-story": return StoryLesson()
        case "k-bonds": return BondsLesson()
        case "k-make10": return MakeTenLesson()
        case "gk-five": return FiveLesson()
        // Kindergarten, Teens and tens (4 Nov 2026)
        case "k-count20": return CountTwentyLesson()
        case "k-write": return WriteNumbersLesson()
        case "k-teens": return TeenNumbersLesson()
        case "k-tens": return CountTensLesson()
        case "gk-count100": return CountHundredLesson()
        // 1st grade, Add and take away to 20 (4 Nov 2026)
        case "g1-add20": return Add20Lesson()
        case "g1-ten": return MakeTen1Lesson()
        case "g1-doubles": return Doubles1Lesson()
        case "g1-three": return Three1Lesson()
        case "g1-sub20": return Sub20Lesson()
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
    /// The iPad's keys are up for this step's box (a lesson may lay its record line out on its own row then, so the line
    /// being typed and its part of the picture show at 75%: Ratio tables).
    var keys = false
    /// The picture's top row, counted from the block line the problem starts on: where the grid's strong lines fall in the
    /// picture's rows (a sheet of paper a fold lifts draws the grid's own lines on it).
    var gridTop = 6.0
    /// While the paper stands: where the camera looks (Standing.eye), so words beside what stands are placed as it shows.
    var standEye: CGPoint?
    /// How the paper is seen while it stands about `pivot`, from where the camera looks now.
    func standing(_ pivot: CGPoint) -> Standing { Standing(pivot: pivot, eye: standEye) }

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
        // a hint's drawings, the first miss's and the second's (the exact spot, call of 3 Nov), so neither moves the camera
        s.picture = hint ? st.picture.merging(st.onMiss) { $1 }.merging(st.hint2) { $1 } : st.picture
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
    /// What stands off the paper, or lies on it in 3D (PaperStand.swift), in the picture's squares.
    var solids = Solids()
    /// While the step stands: how the paper is seen (what `solids` takes up is measured through it).
    var standing: Standing?
    /// The room the picture takes: what's drawn, the room it keeps, and its solids (seen standing or flat), in its points.
    var room: CGRect? {
        let s = solids.bounds(standing).map { CGRect(x: $0.minX * Paper.cell, y: $0.minY * Paper.cell, width: $0.width * Paper.cell, height: $0.height * Paper.cell) }
        return [picture.bounds, extent, s].compactMap { $0 }.reduce(nil as CGRect?) { acc, r in acc.map { $0.union(r) } ?? r }
    }
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
    /// What later steps still draw from this move (LessonRun.kept: the rows shaded, the groups taken).
    var keep: Numbers = [:]
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
    /// The same, through places in turn (a drag that bends round a circle).
    case path([CGPoint])
    /// Into a record box: its number written.
    case write(box: String, text: String)
}
