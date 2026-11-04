import Foundation

/// A lesson's place on a grade's map: its id (the lesson's, and the key its progress is saved under) and its name.
public struct MapLesson: Equatable, Sendable {
    public let id: String, name: String
    public init(_ id: String, _ name: String) { self.id = id; self.name = name }
}

/// A chapter on a grade's map: its key (what its test is named by), its title, its colour's family (the app's Chapter
/// colours: whole, decimals, fractions, measurement, geometry) and its lessons in teaching order.
public struct MapChapter: Equatable, Sendable {
    public let key: String, title: String, colour: String
    public let lessons: [MapLesson]
    public init(_ key: String, _ title: String, colour: String, _ lessons: [MapLesson]) {
        self.key = key; self.title = title; self.colour = colour; self.lessons = lessons
    }
    /// The chapter's test (G 18 Oct: at the end of its row).
    public var test: String { "test-\(key)" }
}

/// Every grade's map as data (G 3 Nov: the first grade after 5th): a grade is a list of chapters, each a list of
/// lessons, laid out on the paper by the same packed rule. A lesson is built once Lessons has its spec; a grade is live
/// once it has a lesson built. Each grade's progress is its own: its lessons' ids and its tests' are its own.
public enum Curriculum {
    /// 5th grade: the 17 lessons of specs/k12/grade5.md and Geometry's two (1 Nov). Its chapters' keys are their
    /// colours, so their tests keep the ids they've always had ("test-whole").
    static let grade5: [MapChapter] = [
        MapChapter("whole", "Whole numbers", colour: "whole", [
            MapLesson("g5-mult2", "Multiply two-digit numbers"), MapLesson("g5-divide", "Long division"), MapLesson("g5-order", "Order of operations")]),
        MapChapter("decimals", "Decimals", colour: "decimals", [
            MapLesson("g5-pow10", "Multiply by 10, 100, 1000"), MapLesson("g5-round", "Rounding decimals"), MapLesson("g5-compare", "Comparing decimals"),
            MapLesson("g5-adddec", "Adding decimals"), MapLesson("g5-multdec", "Multiplying decimals"), MapLesson("g5-divdec", "Dividing by a decimal")]),
        MapChapter("fractions", "Fractions", colour: "fractions", [
            MapLesson("add", "Adding fractions"), MapLesson("sub", "Subtracting fractions"), MapLesson("mix", "Adding and subtracting"),
            MapLesson("g5-multfrac", "Multiplying fractions"), MapLesson("g5-improper", "Mixed numbers to fractions"),
            MapLesson("g5-fracdiv", "Fractions as division"), MapLesson("g5-fracof", "Fraction of a number"), MapLesson("g5-unitdiv", "Dividing by a unit fraction")]),
        MapChapter("measurement", "Measurement", colour: "measurement", [MapLesson("g5-volume", "Volume of a box"), MapLesson("g5-units", "Converting units")]),
        MapChapter("geometry", "Geometry", colour: "geometry", [MapLesson("g5-coord", "Points on a grid"), MapLesson("g5-shapes", "Sorting shapes")]),
    ]

    /// 4th grade (design/grade4.md): 35 lessons in 8 chapters, in teaching order. All 8 chapters are built (3 Nov).
    static let grade4: [MapChapter] = [
        MapChapter("g4-big", "Big numbers", colour: "whole", [
            MapLesson("g4-tentimes", "Tens, hundreds, thousands"), MapLesson("g4-readwrite", "Reading and writing big numbers"),
            MapLesson("g4-compare", "Comparing big numbers"), MapLesson("g4-placevalue", "Place value and rounding"),
            MapLesson("g4-addsub", "Add and subtract big numbers")]),
        MapChapter("g4-muldiv", "Multiplying and dividing", colour: "whole", [
            MapLesson("g4-times", "Times as many"), MapLesson("g4-partial", "Multiply big numbers"), MapLesson("g4-mult2x2", "Two-digit times two-digit"),
            MapLesson("g4-divide", "Dividing with remainders"), MapLesson("g4-share", "Dividing big numbers"), MapLesson("g4-multistep", "Story problems in steps")]),
        MapChapter("g4-factors", "Factors and patterns", colour: "whole", [
            MapLesson("g4-factors", "Factors and multiples"), MapLesson("g4-prime", "Prime or composite"), MapLesson("g4-patterns", "Number and shape patterns")]),
        MapChapter("g4-fractions", "Fractions", colour: "fractions", [
            MapLesson("g4-decompose", "Breaking fractions apart"), MapLesson("g4-equiv", "Equivalent fractions"), MapLesson("g4-fraccompare", "Comparing fractions"),
            MapLesson("g4-likefrac", "Adding like fractions"), MapLesson("g4-likesub", "Subtracting like fractions")]),
        MapChapter("g4-mixed", "Mixed numbers", colour: "fractions", [
            MapLesson("g4-mixed", "Adding mixed numbers"), MapLesson("g4-mixedsub", "Subtracting mixed numbers"), MapLesson("g4-fracwhole", "Fraction times a whole number")]),
        MapChapter("g4-decimals", "Decimals", colour: "decimals", [
            MapLesson("g4-dec", "Tenths and hundredths"), MapLesson("g4-decline", "Decimals on a number line"), MapLesson("g4-deccompare", "Comparing decimals")]),
        MapChapter("g4-measurement", "Measurement", colour: "measurement", [
            MapLesson("g4-convert", "Converting measurements"), MapLesson("g4-measure", "Measurement story problems"), MapLesson("g4-area", "Area and perimeter"),
            MapLesson("g4-lineplot", "Line plots with fractions")]),
        MapChapter("g4-lines", "Lines and shapes", colour: "geometry", [
            MapLesson("g4-lines", "Points, lines, rays and angles"), MapLesson("g4-turns", "Angles and degrees"), MapLesson("g4-protractor", "Measuring angles"),
            MapLesson("g4-angles", "Angles add up"), MapLesson("g4-classify", "Sorting by sides and angles"), MapLesson("g4-symmetry", "Lines of symmetry")]),
    ]

    /// 6th grade (design/grade6.md): 36 lessons in 8 chapters, in teaching order. Chapter 1 is built (3 Nov); the map
    /// shows only built chapters (call of 3 Nov), so the rest wait off it.
    static let grade6: [MapChapter] = [
        MapChapter("g6-ratios", "Ratios and percents", colour: "fractions", [
            MapLesson("g6-ratio", "Equivalent ratios"), MapLesson("g6-ratiotable", "Ratio tables"), MapLesson("g6-rate", "Unit rates"),
            MapLesson("g6-pctof", "Percent of a number"), MapLesson("g6-pctwhole", "Find the whole")]),
        MapChapter("g6-factors", "Factors and fractions", colour: "fractions", [
            MapLesson("g6-lcm", "Least common multiple"), MapLesson("g6-gcf", "Factor out the GCF"), MapLesson("g6-divide", "Dividing fractions")]),
        MapChapter("g6-decimals", "Long division and decimals", colour: "decimals", [
            MapLesson("g6-longdiv", "Long division"), MapLesson("g6-decaddsub", "Adding and subtracting decimals"),
            MapLesson("g6-decmult", "Multiplying decimals"), MapLesson("g6-decdiv", "Dividing decimals")]),
        MapChapter("g6-negatives", "Negative numbers", colour: "whole", [
            MapLesson("g6-negatives", "Negative numbers"), MapLesson("g6-compare", "Compare and order"), MapLesson("g6-numline", "Distance on a number line"),
            MapLesson("g6-quadrants", "Points in four quadrants"), MapLesson("g6-planeshapes", "Shapes on the plane")]),
        MapChapter("g6-expressions", "Expressions", colour: "whole", [
            MapLesson("g6-expo", "Exponents and order"), MapLesson("g6-write", "Write expressions"), MapLesson("g6-eval", "Evaluate expressions"),
            MapLesson("g6-equiv", "Equivalent expressions")]),
        MapChapter("g6-equations", "Equations", colour: "whole", [
            MapLesson("g6-onestep", "One-step equations"), MapLesson("g6-ineq", "Inequalities"), MapLesson("g6-depend", "Two quantities")]),
        MapChapter("g6-area", "Area and volume", colour: "geometry", [
            MapLesson("g6-para", "Area of a parallelogram"), MapLesson("g6-tri", "Area of a triangle"), MapLesson("g6-trap", "Area of a trapezoid"),
            MapLesson("g6-poly", "Area of a polygon"), MapLesson("g6-nets", "Nets and surface area"), MapLesson("g6-fracvol", "Volume with fraction edges")]),
        MapChapter("g6-data", "Data", colour: "measurement", [
            MapLesson("g6-dotplot", "Dot plots"), MapLesson("g6-histogram", "Histograms"), MapLesson("g6-mean", "Find the mean"),
            MapLesson("g6-mad", "Mean absolute deviation"), MapLesson("g6-median", "Find the median"), MapLesson("g6-boxplot", "Box plots")]),
    ]

    /// A grade's chapters, in order (none for a grade with no map yet).
    public static func chapters(_ grade: Int) -> [MapChapter] {
        switch grade { case 4: grade4; case 5: grade5; case 6: grade6; default: [] }
    }
    /// A lesson is built when the app has its spec.
    public static func built(_ id: String) -> Bool { Lessons.spec(id) != nil }
    /// Every lesson in its chapter is built: its test can open.
    public static func built(_ c: MapChapter) -> Bool { c.lessons.allSatisfy { built($0.id) } }
    /// A grade with lessons to play: it can be chosen.
    public static func isLive(_ grade: Int) -> Bool { chapters(grade).contains { $0.lessons.contains { built($0.id) } } }
    /// The grade's own test, under everything. 5th grade's keeps the id it's always had.
    public static func gradeTest(_ grade: Int) -> String { grade == 5 ? "test-grade" : "test-grade-\(grade)" }
    public static func isGradeTest(_ id: String) -> Bool { id.hasPrefix("test-grade") }
    /// A lesson's name on its map ("Comparing big numbers").
    public static func name(of id: String) -> String? {
        for g in Grades.all { for c in chapters(g) { if let l = c.lessons.first(where: { $0.id == id }) { return l.name } } }
        return nil
    }
    /// The grade a lesson or test is on (nil when it's on none).
    public static func grade(of id: String) -> Int? {
        Grades.all.first { g in id == gradeTest(g) || chapters(g).contains { $0.test == id || $0.lessons.contains { $0.id == id } } }
    }
}
