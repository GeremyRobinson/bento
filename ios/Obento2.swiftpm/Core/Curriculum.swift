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

    /// Kindergarten (design/gradeK.md): 23 lessons in 5 chapters, in teaching order. All 5 chapters are built (4 Nov): every
    /// chapter is on the map, and the grade's test under them. Teens and tens is base-ten work, in the decimals' pink (as 1st grade's Numbers to 120).
    static let gradeK: [MapChapter] = [
        MapChapter("gk-count", "Count to 10", colour: "whole", [
            MapLesson("gk-count10", "Count to 10"), MapLesson("gk-onemore", "One more"), MapLesson("k-compare", "More, less or the same"),
            MapLesson("gk-numcompare", "Which number is more?")]),
        MapChapter("gk-shapes", "Shapes", colour: "geometry", [
            MapLesson("k-shapes", "Flat shapes"), MapLesson("gk-draw", "Draw shapes"), MapLesson("k-solids", "Solid shapes"),
            MapLesson("gk-position", "Where is it?"), MapLesson("gk-compose", "Put shapes together")]),
        MapChapter("gk-measure", "Measure and sort", colour: "measurement", [
            MapLesson("k-length", "Longer and shorter"), MapLesson("gk-heavier", "Heavier and lighter"), MapLesson("k-sort", "Sort and count")]),
        MapChapter("gk-addsub", "Add and take away", colour: "whole", [
            MapLesson("k-add", "Adding within 10"), MapLesson("k-sub", "Taking away within 10"), MapLesson("k-story", "Story problems within 10"),
            MapLesson("k-bonds", "Number bonds"), MapLesson("k-make10", "Make 10"), MapLesson("gk-five", "Facts to 5")]),
        MapChapter("gk-teens", "Teens and tens", colour: "decimals", [
            MapLesson("k-count20", "Count to 20"), MapLesson("k-write", "Write numbers 0 to 20"), MapLesson("k-teens", "Teen numbers"),
            MapLesson("k-tens", "Count by tens to 100"), MapLesson("gk-count100", "Count to 100")]),
    ]

    /// 1st grade (design/grade1.md): 26 lessons in 6 chapters, in teaching order. Chapters 1 to 5 are built (4 Nov): only they are on
    /// the map. Numbers to 120 is base-ten work, in the decimals' pink (as Kindergarten's Teens and tens).
    static let grade1: [MapChapter] = [
        MapChapter("g1-addsub", "Add and take away to 20", colour: "whole", [
            MapLesson("g1-add20", "Add within 20"), MapLesson("g1-ten", "Make a ten to add"), MapLesson("g1-doubles", "Doubles and near doubles"),
            MapLesson("g1-three", "Add three numbers"), MapLesson("g1-sub20", "Subtract within 20")]),
        MapChapter("g1-equations", "Equations and stories", colour: "fractions", [
            MapLesson("g1-related", "Add to take away"), MapLesson("g1-missing", "Missing numbers"), MapLesson("g1-equal", "True or false?"),
            MapLesson("g1-story", "Story problems"), MapLesson("g1-more", "How many more?")]),
        MapChapter("g1-numbers", "Numbers to 120", colour: "decimals", [
            MapLesson("g1-count120", "Count to 120"), MapLesson("g1-tensones", "Tens and ones"), MapLesson("g1-compare", "Compare two-digit numbers"),
            MapLesson("g1-tenmore", "10 more, 10 less")]),
        MapChapter("g1-tens", "Adding and taking away tens", colour: "whole", [
            MapLesson("g1-addtens", "Add tens to a number"), MapLesson("g1-add100", "Add within 100"), MapLesson("g1-subtens", "Take away tens")]),
        MapChapter("g1-measure", "Length, time and graphs", colour: "measurement", [
            MapLesson("g1-order3", "Longest to shortest"), MapLesson("g1-measure", "Measure length"), MapLesson("g1-time", "Time to the hour and half hour"),
            MapLesson("g1-picgraph", "Picture graphs"), MapLesson("g1-tally", "Tally charts")]),
        MapChapter("g1-shapes", "Shapes and equal parts", colour: "geometry", [
            MapLesson("g1-shapes", "What makes a triangle"), MapLesson("g1-compose", "Put shapes together"), MapLesson("g1-build", "Build with solids"),
            MapLesson("g1-halves", "Halves and fourths")]),
    ]

    /// 2nd grade (design/grade2.md): 27 lessons in 7 chapters, in teaching order. Chapters 1 to 5 are built (4 Nov): only they are on the map.
    static let grade2: [MapChapter] = [
        MapChapter("g2-addsub", "Adding and subtracting to 100", colour: "whole", [
            MapLesson("g2-facts", "Facts to 20"), MapLesson("g2-regroup", "Adding with regrouping"), MapLesson("g2-subregroup", "Subtracting with regrouping"),
            MapLesson("g2-addfour", "Add up to four numbers"), MapLesson("g2-story", "Story problems to 100"), MapLesson("g2-twostep", "Two-step story problems")]),
        MapChapter("g2-numbers", "Numbers to 1000", colour: "decimals", [
            MapLesson("g2-hundreds", "Hundreds, tens and ones"), MapLesson("g2-skip", "Skip counting"), MapLesson("g2-compare", "Compare three-digit numbers"),
            MapLesson("g2-within1000", "Add and subtract within 1000")]),
        MapChapter("g2-groups", "Equal groups", colour: "fractions", [
            MapLesson("g2-evenodd", "Even and odd"), MapLesson("g2-arrays", "Arrays"), MapLesson("g2-squares", "Rows and columns of squares")]),
        MapChapter("g2-length", "Length", colour: "measurement", [
            MapLesson("g2-measure", "Inches and centimeters"), MapLesson("g2-twounits", "Measure with two units"), MapLesson("g2-estimate", "Estimate length"),
            MapLesson("g2-numline", "Lengths on a number line")]),
        MapChapter("g2-data", "Data", colour: "decimals", [
            MapLesson("g2-makegraph", "Make a graph"), MapLesson("g2-bargraph", "Bar graphs"), MapLesson("g2-lineplot", "Line plots")]),
        MapChapter("g2-timemoney", "Time and money", colour: "measurement", [
            MapLesson("g2-time5", "Time to 5 minutes"), MapLesson("g2-coins", "Name the coin"), MapLesson("g2-money", "Counting money"),
            MapLesson("g2-dollars", "Dollars and cents")]),
        MapChapter("g2-shapes", "Shapes", colour: "geometry", [
            MapLesson("g2-shapes", "Sides and corners"), MapLesson("g2-solids", "Faces, edges and corners"), MapLesson("g2-shares", "Halves, thirds and fourths")]),
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

    /// 6th grade (design/grade6.md): 36 lessons in 8 chapters, in teaching order. Chapters 1 and 2 are built (3 Nov), 3 to 8 on 4 Nov: every
    /// chapter is on the map, and the grade's test under them.
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
        switch grade { case 0: gradeK; case 1: grade1; case 2: grade2; case 4: grade4; case 5: grade5; case 6: grade6; default: [] }
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
    /// Its words are spoken (Kindergarten to 2nd grade: most can't read yet, or are still young readers).
    public static func voiced(_ id: String) -> Bool { grade(of: id).map { $0 <= 2 } ?? false }
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
