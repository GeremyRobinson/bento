import SwiftUI
import RealityKit
import simd

/// The whole paper in one 3D scene: the grid, the lessons' pictures and, when a lesson is open, its squares and cubes.
/// One camera looks at it. Flat is that camera straight above; a 3D lesson only tilts it, so the grid never swaps or jumps.
/// Words and buttons are drawn on top as normal text, pinned to the paper.
struct PaperScene: View {
    let model: PaperModel
    let time: Double
    @Environment(\.colorScheme) private var scheme
    @State private var rig = Rig()

    init(model: PaperModel, time: Double) { self.model = model; self.time = time }

    var body: some View {
        let view = model.view(at: time)
        // read light or dark here, in the body, so switching it redraws the scene (read only inside the closures,
        // SwiftUI never knew the scene depended on it, and the paper stayed light when the words went dark)
        let dark = scheme == .dark
        RealityView { content in
            content.camera = .virtual
            rig.build(into: &content)
            rig.update(view: view, model: model, time: time, dark: dark)
        } update: { _ in
            Perf.time("scene") { rig.update(view: view, model: model, time: time, dark: dark) }
        }
        .background(Ink.paper)
        .allowsHitTesting(false)
    }
}

/// A lesson's picture as lines on the grid, in paper points, in the order they draw themselves in.
extension Piece {
    /// The picture, centred in its frame to the nearest whole cell (so it stays on the grid). A box seen in 3D can't
    /// sit on the grid's lines, so it's centred exactly.
    var strokes: [[CGPoint]] { let o = centring; return drawing.map { $0.map { CGPoint(x: $0.x + o.x, y: $0.y + o.y) } } }

    /// The parts of the picture softly filled (G 18 Oct, the icons' tint): what matters in it, the shaded part of a
    /// fraction, the digit that moves, the top of a box. Closed shapes, centred with the lines.
    var softs: [[CGPoint]] { let o = centring; return soft.map { $0.map { CGPoint(x: $0.x + o.x, y: $0.y + o.y) } } }

    /// How far the picture moves to sit in the middle of its frame.
    private var centring: CGPoint {
        let pts = drawing.flatMap { $0 }
        guard let x0 = pts.map(\.x).min(), let x1 = pts.map(\.x).max(), let y0 = pts.map(\.y).min(), let y1 = pts.map(\.y).max() else { return .zero }
        let c = isBox ? 0.001 : Paper.cell, f = frame
        return CGPoint(x: ((f.mid.x - (x0 + x1) / 2) / c).rounded() * c, y: ((f.mid.y - (y0 + y1) / 2) / c).rounded() * c)
    }

    private var soft: [[CGPoint]] {
        let c = Paper.cell
        func box(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> [CGPoint] {
            [CGPoint(x: at.x + x * c, y: at.y + y * c), CGPoint(x: at.x + (x + w) * c, y: at.y + y * c),
             CGPoint(x: at.x + (x + w) * c, y: at.y + (y + h) * c), CGPoint(x: at.x + x * c, y: at.y + (y + h) * c)]
        }
        if Map.isGradeTest(id) {
            let p = { (x: Double, y: Double) in CGPoint(x: at.x + x * c, y: at.y + y * c) }
            return Self.starFan(p, cx: 4.5, cy: 2.4, r: 1.4)
        }
        if isTest { return [[CGPoint(x: at.x + 3.5 * c, y: at.y), CGPoint(x: at.x + 3.5 * c, y: at.y + 1.5 * c), CGPoint(x: at.x + 5 * c, y: at.y + 1.5 * c)]] }
        switch id {
        case "g5-volume": return [Array(box3D(l: 4, h: 2, w: 3, u: 32)[0].dropLast())]
        case "add": return [box(0, 0, 3, 2), box(0, 4, 6, 2)]                   // a third and two thirds
        case "sub": return [box(0, 0, 6, 2)]                                    // two thirds, to take from
        case "mix": return [box(0, 0, 3, 2), box(0, 6, 6, 2)]
        case "g5-improper": return [box(0, 0, 4, 2), box(5, 0, 4, 2), box(0, 4, 1, 2)]   // two wholes and a fourth
        case "g5-fracof": return [box(0, 0, 6, 2)]                              // two of the thirds
        case "g5-multfrac": return [box(0, 0, 6, 4)]                            // 2/3 of 2/3
        case "g5-unitdiv": return [box(0, 0, 1, 2), box(4, 0, 1, 2), box(8, 0, 1, 2)]    // a third of each whole
        case "g5-pow10", "g5-divdec": return [box(3, 2, 2, 2)]                  // the digit the point hops over
        case "g5-round": return [box(7, 2, 3, 2)]                               // the stretch up to the whole
        case "g5-compare": return [box(0, 0, 2, 2), box(6, 0, 2, 2)]            // the digits that decide
        case "g5-fracdiv": return [box(0, 0, 3, 2), box(0, 3, 3, 2), box(0, 6, 6, 2)]   // a piece of each, and the share
        case "g5-adddec": return [box(6, 0, 2, 2), box(6, 3, 2, 2)]             // the decimal places, lined up
        case "g5-multdec": return [box(0, 0, 6, 4)]
        case "g5-mult2": return [box(0, 0, 6, 6)]                               // the tens part
        case "g5-divide": return [box(3, 1, 4, 1)]
        case "g5-order": return [box(2, 1, 2, 2)]                               // the part done first
        case "g5-units": return [box(0, 0, 4, 2)]                               // a foot of it
        case "g5-coord": return [box(5, 1, 2, 2)]                               // the point
        case "g5-shapes": return [[CGPoint(x: at.x + 2 * c, y: at.y), CGPoint(x: at.x + 9 * c, y: at.y), CGPoint(x: at.x + 7 * c, y: at.y + 4 * c), CGPoint(x: at.x, y: at.y + 4 * c)]]
        // 4th grade, Big numbers (3 Nov)
        case "g4-tentimes": return [box(6, 1, 5, 2)]                            // the full ten
        case "g4-readwrite": return [box(0, 0, 2, 2)]                           // the digit pulled
        case "g4-compare": return [box(3, 0, 2, 2)]                             // the place that decides
        case "g4-placevalue": return [box(0, 2, 3, 2)]                          // the stretch down to the round number
        case "g4-addsub": return [box(7, 0, 2, 2)]                              // the ones, first
        // 4th grade, Multiplying and dividing (3 Nov)
        case "g4-times": return [box(0, 0, 3, 2)]                               // Red
        case "g4-partial": return [box(0, 0, 3, 6)]                             // the hundreds, every row
        case "g4-mult2x2": return [box(0, 0, 6, 4)]                             // tens × tens
        case "g4-divide", "g4-share": return [box(0, 3, 3, 1)]                  // one row's share
        case "g4-multistep": return [box(6, 4, 3, 2)]                           // the part taken away
        // 4th grade, Factors and patterns (3 Nov)
        case "g4-factors": return [box(0, 0, 6, 2)]                             // the first rectangle found
        case "g4-prime": return [box(0, 0, 11, 1)]                              // the one long row
        case "g4-patterns": return [box(8, 0, 1, 2)]                            // the newest squares
        // 4th grade, Fractions (3 Nov)
        case "g4-decompose": return [box(0, 0, 2, 2), box(3, 0, 2, 2), box(6, 0, 2, 2)] // the pieces parted
        case "g4-equiv": return [box(0, 4, 4.5, 2)]                             // the same amount, cut smaller
        case "g4-fraccompare": return [box(0, 0, 6, 2), box(0, 4, 4.5, 2)]      // the two amounts
        case "g4-likefrac": return [box(0, 0, 6, 2)]                            // the pieces together
        case "g4-likesub": return [box(0, 0, 6, 2)]                             // what's left
        // 4th grade, Mixed numbers (3 Nov)
        case "g4-mixed": return [box(0, 0, 4, 1), box(0, 2, 4, 1), box(0, 4, 3, 2)] // the wholes, and the pieces
        case "g4-mixedsub": return [box(0, 0, 4, 1), box(0, 2, 4, 1), box(0, 4, 3, 2)]
        case "g4-fracwhole": return [box(0, 0, 2, 2), box(0, 3, 2, 2), box(5, 0, 4, 2)] // two groups' pieces, packed
        // 4th grade, Decimals (3 Nov)
        case "g4-dec": return [box(0, 0, 2, 4), box(2, 0, 1, 2)]                // tenths, and the hundredths poured after them
        case "g4-decline": return [box(6, 0, 1, 1)]                             // the tenth it's in
        case "g4-deccompare": return [box(0, 0, 2, 4), box(7, 0, 1, 4), box(8, 0, 1, 2)] // 0.5 against 0.45
        // 4th grade, Measurement (3 Nov)
        case "g4-convert": return [box(0, 0, 3, 2)]                             // two inches of the first foot
        case "g4-measure": return []
        case "g4-area": return [box(0, 0, 6, 4)]                                // the square meters inside
        case "g4-lineplot": return [box(6, 2, 2, 2)]                            // the tallest stack's top X
        // 4th grade, Lines and shapes (3 Nov)
        // 6th grade, Ratios and percents (3 Nov)
        case "g6-ratio": return [box(0, 0, 4, 6)]                               // the left side's rows
        case "g6-ratiotable":                                                   // the two points
            return [(3.0, 4.0), (6.0, 2.0)].map { c in (0..<16).map { k in let a = Double(k) / 16 * 2 * .pi; return CGPoint(x: at.x + (c.0 + 0.6 * cos(a)) * Paper.cell, y: at.y + (c.1 + 0.6 * sin(a)) * Paper.cell) } }
        case "g6-rate": return [box(6, 0, 3, 1)]                                // the row copied
        case "g6-pctof": return [box(0, 2, 3, 2)]                               // 30% shaded
        case "g6-pctwhole": return [box(0, 2, 3, 2)]                            // the block known
        // 6th grade, Factors and fractions (3 Nov)
        case "g6-lcm":                                                          // where both counts land
            return [(0..<16).map { k in let a = Double(k) / 16 * 2 * .pi; return CGPoint(x: at.x + (6 + 0.6 * cos(a)) * c, y: at.y + (2 + 0.6 * sin(a)) * c) }]
        case "g6-gcf": return [box(0, 0, 3, 2), box(0, 4, 3, 2)]                // a piece of each bar
        case "g6-divide": return [box(0, 0, 8, 2)]                              // the amount laid along
        // 6th grade, Long division and decimals (4 Nov)
        case "g6-longdiv": return [box(0, 0, 5, 2)]                             // the rows dragged down
        case "g6-decaddsub": return [box(6, 1, 4, 1)]                           // the discs slid in
        case "g6-decmult": return [box(1, 0, 6, 2)]                             // the digits made whole
        case "g6-decdiv": return [box(0, 2, 3, 1)]                              // the ones left, broken into tenths
        // 6th grade, Negative numbers (4 Nov)
        case "g6-negatives": return [box(4, 3, 2, 3)]                           // below 0
        case "g6-compare": return [box(1, 1, 2, 2)]                             // the lesser point
        case "g6-numline": return [box(1, 0, 4, 2)]                             // the steps to 0
        case "g6-quadrants": return [box(0, 0, 5, 3)]                           // quadrant II
        case "g6-planeshapes": return [box(2, 1, 6, 4)]                         // the rectangle across the axis
        // 6th grade, Expressions (4 Nov)
        case "g6-expo": return [box(0, 1, 4, 4)]                                // the square built
        case "g6-write": return [box(0, 2, 5, 2)]                               // the n strip
        case "g6-eval": return [box(0, 0, 4, 1), box(0, 1.5, 4, 1), box(0, 3, 4, 1)] // the x rows, stretched to x
        case "g6-equiv": return [box(0, 1, 6, 3)]                               // the rows of x
        // 6th grade, Equations (4 Nov)
        case "g6-onestep": return [box(0, 0, 5, 1.5)]                           // x, what's left
        case "g6-ineq": return [box(4, 1.5, 7, 1)]                              // the numbers that work
        case "g6-depend": return [[CGPoint(x: at.x, y: at.y + 6 * c), CGPoint(x: at.x + 9 * c, y: at.y), CGPoint(x: at.x + 9 * c, y: at.y + 6 * c)]] // under the rule's line
        // 6th grade, Area and volume (4 Nov)
        case "g6-para", "g6-tri", "g6-trap", "g6-poly", "g6-nets", "g6-fracvol":
            func q(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: at.x + x * c, y: at.y + y * c) }
            switch id {
            case "g6-para": return [[q(0, 4), q(3, 0), q(3, 4)]]                  // the piece cut off
            case "g6-tri": return [[q(0, 6), q(10, 6), q(10, 0)]]                 // the triangle, half the rectangle
            case "g6-trap": return [[q(0, 4), q(4, 4), q(7, 0), q(0, 0)]]         // the trapezoid
            case "g6-poly": return [box(0, 0, 5, 6)]                              // one piece of the L
            case "g6-nets": return [box(3, 2, 3, 2)]                              // the base
            default: return [[q(1, 4), q(3, 4), q(3, 6), q(1, 6)]]                // a whole cube of small ones
            }
        // 6th grade, Data (4 Nov)
        // Kindergarten, Count to 10 (4 Nov)
        case "gk-count10": return [box(0, 5, 3, 1)]                             // the dots counted onto the track
        case "gk-onemore": return [box(6, 5, 1, 1)]                             // the one more cube
        case "k-compare": return [box(5, 0, 2, 1)]                              // the dots with no partner
        case "gk-numcompare": return [box(4, 4, 3, 2)]                          // the cubes that are more
        // Kindergarten, Shapes (4 Nov)
        case "k-shapes", "gk-draw", "k-solids", "gk-position", "gk-compose":
            func q(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: at.x + x * c, y: at.y + y * c) }
            switch id {
            case "k-shapes": return [[q(0, 6), q(7, 6), q(3, 0)]]                 // the triangle
            case "gk-draw": return [[q(0, 6), q(6, 6), q(3, 0)]]                  // the triangle drawn on the dots
            case "k-solids": return [[q(0, 2), q(2, 0), q(6, 0), q(4, 2)]]        // the cube's top
            case "gk-position": return [box(4, 1, 3, 3)]                          // the cube in front
            default: return [[q(0, 0), q(6, 6), q(0, 6)]]                         // one triangle in the square
            }
        // Kindergarten, Measure and sort (4 Nov)
        case "k-length": return [box(6, 0, 3, 2)]                               // the part that sticks out
        case "gk-heavier": return [box(0.5, 3.6, 2, 1.2)]                       // the heavier one, gone down
        case "k-sort": return [box(2, 0, 7, 1.6)]                               // the row with the most
        // Kindergarten, Add and take away (4 Nov)
        case "k-add": return [box(4, 4, 3, 2)]                                  // the cubes counted on
        case "k-sub": return [box(0, 0, 4, 2)]                                  // what's left
        case "k-story": return [box(5, 0, 2, 2)]                                // the ones that come
        case "k-bonds": return [(0...24).map { k in let a = Double(k) / 24 * 2 * .pi; return CGPoint(x: at.x + (6 + cos(a)) * c, y: at.y + (5 + sin(a)) * c) }] // the other part
        case "k-make10": return [box(4, 2, 6, 2)]                               // the empty boxes: how many more
        case "gk-five": return [box(6, 0, 1, 4)]                                // the finger raised
        // Kindergarten, Teens and tens (4 Nov)
        case "k-count20": return [box(0, 3, 4, 1)]                              // the bottom row, counted on from 10
        case "k-write": return [box(7, 1, 3.5, 4.5)]                            // the numeral traced
        case "k-teens": return [box(6, 2, 5, 1), box(6, 3, 1, 1)]               // the ones
        case "k-tens": return [box(4, 4, 2, 1)]                                 // the last ten counted
        case "gk-count100": return [box(9, 0, 1, 6)]                            // the last column: 10, 20, 30…
        // 1st grade, Add and take away to 20 (4 Nov)
        case "g1-add20": return [box(7, 2, 3, 1)]                               // the counters hopped on
        case "g1-ten": return [box(8, 1, 2, 1)]                                 // the two that fill the ten
        case "g1-doubles": return [box(6, 4, 1, 1)]                             // the one more
        case "g1-three": return [box(0, 5, 10, 1)]                              // the ten made first
        case "g1-sub20": return [box(6, 2, 4, 1)]                               // the counters hopped back over
        // 1st grade, Equations and stories (4 Nov)
        case "g1-related": return [box(6, 1, 4, 1)]                             // the part added on
        case "g1-missing": return [box(4, 2.5, 5, 1.5)]                            // the two hops
        case "g1-equal": return [box(7, 2, 1, 3)]                                 // where the rows end
        case "g1-story": return [box(6, 2, 3, 1)]                               // the ones that came
        case "g1-more": return [box(6, 1, 3, 1)]                                // the ones with no partner
        // 1st grade, Numbers to 120 (4 Nov)
        case "g1-count120": return [box(7, 2, 3, 1), box(0, 3, 2, 1)]           // the count on, past a row's end
        case "g1-tensones": return [box(0, 0.5, 10, 1)]                         // a ten
        case "g1-compare": return [box(5.5, 3.5, 4.5, 1)]                       // the ten more
        case "g1-tenmore": return [box(4, 3.5, 1, 1)]                           // one row down
        // 1st grade, Adding and taking away tens (4 Nov)
        case "g1-addtens": return [box(0, 2.5, 10, 2)]                          // the new tens, joined
        case "g1-add100": return [box(0, 2.5, 10, 1)]                           // ten ones closed into a new ten
        case "g1-subtens": return [box(0, 0.5, 4.5, 2)]                         // the tens left
        // 1st grade, Length, time and graphs (4 Nov)
        case "g1-order3": return [box(0, 0.5, 9, 1)]                            // the longest, on top
        case "g1-measure": return [box(4, 1.5, 3, 1)]                           // the cubes that stick out
        case "g1-time": return [box(0, 5, 5, 1)]                                // half the hour, on the strip
        case "g1-picgraph": return [box(0, 1, 8, 1)]                            // the longest row
        case "g1-tally": return [box(0, 1, 4.5, 1.2)]                           // a bundle of five
        // 1st grade, Shapes and equal parts (4 Nov)
        case "g1-shapes", "g1-compose", "g1-build":
            func q(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: at.x + x * c, y: at.y + y * c) }
            switch id {
            case "g1-shapes": return [[q(0, 6), q(7, 6), q(2, 0)]]                 // the triangle traced
            case "g1-compose": return [[q(0, 3), q(6, 3), q(4.5, 6), q(1.5, 6)]]   // the trapezoid slid in
            default: return [[q(2, 1.5), q(5, 1.5), q(4, 3), q(1, 3)]]             // the box's top
            }
        case "g1-halves": return [box(0, 0, 5, 6)]                              // a half, shaded
        // 2nd grade, Adding and subtracting to 100 (4 Nov)
        case "g2-facts": return [box(8, 1, 2, 1)]                               // the two slid up to make the ten
        case "g2-regroup": return [box(0, 3.8, 4.5, 0.6)]                       // ten ones closed into a new ten
        case "g2-subregroup": return [box(0, 4.6, 5, 0.6)]                      // the ten opened into ones
        case "g2-addfour": return [box(0, 3, 4.5, 0.6)]                         // the new ten the ones made
        case "g2-story": return [box(6, 2.5, 4, 1.5)]                           // the part we don't know
        case "g2-twostep": return [box(6, 2, 3, 1.5)]                           // the first change, joined
        // 2nd grade, Numbers to 1000 (4 Nov)
        case "g2-hundreds": return [box(0, 0.5, 3, 3)]                          // a hundred, its flat
        case "g2-skip": return [box(3.5, 4.4, 0.4, 0.4)]                       // where the hop lands
        case "g2-compare": return [box(4, 1.2, 1, 0.8)]                         // the hundred both are in
        case "g2-within1000": return [box(2, 4.2, 4, 0.8)]                      // the block that opened
        // 2nd grade, Equal groups (4 Nov)
        case "g2-evenodd": return [box(8.1, -0.1, 0.8, 0.8)]                    // the dot with no partner
        case "g2-arrays": return [box(2, 0, 6, 2)]                              // a row lit
        case "g2-squares": return [box(2, 0, 2, 2), box(6, 0, 2, 2), box(4, 2, 2, 2), box(2, 4, 2, 2), box(6, 4, 2, 2)] // the checker
        // 2nd grade, Length (4 Nov)
        case "g2-measure": return [box(1, 0.5, 6, 1)]                           // the pencil measured
        case "g2-twounits": return [box(0, 0, 2.5, 1.2), box(0, 4.8, 1, 1.2)]    // an inch and a centimeter
        case "g2-estimate": return [box(0, 2, 2, 0.6), box(4, 2, 2, 0.6)]        // the paper clips laid
        case "g2-numline": return [box(0, 1, 7, 1.5)]                            // the length from 0
        // 2nd grade, Data (4 Nov)
        case "g2-makegraph": return [box(3, 1, 5, 1.2)]                          // the bar made to its tally
        case "g2-bargraph": return [box(6.5, 1, 1.5, 1.2)]                       // the part sticking out
        case "g2-lineplot": return [box(4, 1.5, 1, 3)]                           // the tallest stack
        // 2nd grade, Time and money (4 Nov)
        case "g2-time5":                                                         // the face shaded from 12 to the long hand
            var pts = [CGPoint(x: at.x + 3 * c, y: at.y + 3 * c)]
            for k in 0...10 { let t = Double(k) / 10 * 2.6; pts.append(CGPoint(x: at.x + (3 + 3 * sin(t)) * c, y: at.y + (3 - 3 * cos(t)) * c)) }
            return [pts]
        case "g2-coins":                                                         // the small coin worth more
            var pts: [CGPoint] = []
            for k in 0..<32 { let t = Double(k) / 32 * 2 * .pi; pts.append(CGPoint(x: at.x + (8 + 1.15 * cos(t)) * c, y: at.y + (3.5 + 1.15 * sin(t)) * c)) }
            return [pts]
        case "g2-money": return [box(4, 0, 3, 3), box(7, 0, 1, 1)]               // a quarter's block, a dime's row
        case "g2-dollars": return [box(5, 0.5, 5, 1), box(5, 1.5, 2, 0.5)]       // the dollars counted in
        // 2nd grade, Shapes (4 Nov)
        case "g2-shapes", "g2-solids":
            func q(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: at.x + x * c, y: at.y + y * c) }
            if id == "g2-shapes" { return [[q(2.5, 0), q(5, 2), q(4, 5), q(1, 5), q(0, 2)]] }   // the pentagon, its corners counted
            return [[q(6.5, 1), q(9.5, 1), q(10.5, 2.5), q(7.5, 2.5)]]                              // a face counted
        case "g2-shares": return [box(0, 0, 10.0 / 3, 6), box(10.0 / 3, 0, 10.0 / 3, 6)] // 2 thirds, shaded
        // 3rd grade, Multiply and divide (4 Nov)
        case "g3-facts": return [box(0, 4, 10, 2)]                              // the row just dragged down
        case "g3-divfacts": return [box(6, 0, 4, 6)]                            // the rows shared into
        case "g3-unknown": return [box(7.5, 2, 2.5, 2)]                         // the missing number's box
        case "g3-twostep": return [box(6, 4, 4, 2)]                             // the ones slid away
        // 3rd grade, Times-table tricks (4 Nov)
        case "g3-split": return [box(0, 0, 6, 6)]                               // the 5 part, lit
        case "g3-three": return [box(0, 0.5, 10.0 / 3, 2)]                       // a group done first
        case "g3-double": return [box(0, 0, 10, 2.5)]                           // one half
        case "g3-mult10": return [box(5, 0.5, 5, 5)]                            // ten tens, a hundred
        // 3rd grade, Place value (4 Nov)
        case "g3-round": return [box(4, 0.5, 1, 1)]                             // the block the number is in
        case "g3-addsub": return [box(3.6, 0.5, 2.8, 2)]                        // a place, filled
        case "g3-estimate": return [box(7, 4, 2, 1)]                            // the band round the estimate
        // 3rd grade, Shapes and area (4 Nov)
        case "g3-quads":                                                        // the parallelogram
            let quad: [(Double, Double)] = [(2, 1), (10, 1), (8, 5), (0, 5)]
            return [quad.map { CGPoint(x: at.x + $0.0 * c, y: at.y + $0.1 * c) }]
        case "g3-area": return [box(0, 0, 10, 2)]                               // the top row tiled
        case "g3-lshape": return [box(0, 0.5, 6, 5)]                            // one part of the cut
        case "g3-perim": return [box(0, 0.5, 10, 0.5), box(9.5, 0.5, 0.5, 5)]   // the edge walked so far
        case "g3-perimarea": return [box(6, 0.5, 4, 4)]                         // the garden made
        // 3rd grade, Fractions (4 Nov)
        case "g3-shapeparts": return [box(0, 0, 2, 5)]                          // the part lifted
        case "g3-unitfrac": return [box(0, 3, 2, 3), box(2, 0, 2, 2)]           // the shading, and the part slid up
        case "g3-fracline": return [box(5.6, 3.6, 0.8, 0.8)]                    // the point
        case "g3-equiv": return [box(3.6, 1.6, 0.8, 0.8), box(3.6, 5.6, 0.8, 0.8)] // the same point on both lines
        case "g3-fraccompare": return [box(0, 0, 6, 2), box(0, 3, 5, 2)]        // 3/4 and 5/8 shaded
        // 3rd grade, Time and measuring (4 Nov)
        case "g3-elapsed": return [box(0.8, 5, 1.6, 0.6), box(8.4, 5, 1.2, 0.6)]   // the minutes before and after the hours
        case "g3-clock": return [box(0, 5, 7.8, 0.5)]                           // the hour line filled to the long hand
        case "g6-dotplot": return [box(5, 2, 1, 4)]                               // the tallest stack
        case "g6-histogram": return [box(5, 1, 2, 5)]                           // the tallest stretch
        case "g6-mean": return [box(0, 0, 2, 2)]                                // the squares that level the bars
        case "g6-mad": return [box(0, 1, 2, 1), box(6, 0, 2, 2)]                // what's over the mean
        case "g6-median": return [box(5, 3, 1, 3)]                              // the middle bar, left standing
        case "g6-boxplot": return [box(3, 1, 4, 4)]                             // the middle half
        case "g4-lines", "g4-turns", "g4-protractor", "g4-angles", "g4-classify", "g4-symmetry":
            func q(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: at.x + x * c, y: at.y + y * c) }
            func pie(_ cx: Double, _ cy: Double, _ r: Double, _ a0: Double, _ a1: Double) -> [CGPoint] {
                [q(cx, cy)] + (0...12).map { k in let a = (a0 + (a1 - a0) * Double(k) / 12) * .pi / 180; return q(cx + r * cos(a), cy - r * sin(a)) }
            }
            switch id {
            case "g4-lines": return [pie(0.5, 1, 0.5, 0, 360)]                   // the endpoint
            case "g4-turns": return [pie(3, 3, 3, 0, 90)]                         // a quarter turn
            case "g4-protractor": return [pie(4.5, 5, 2, 0, 50)]                  // the angle measured
            case "g4-angles": return [pie(0, 6, 3, 0, 35)]                        // the part we know
            case "g4-classify": return [[q(0, 1), q(3, 1), q(3, 5), q(0, 5)].reversed()] // the shape sorted
            default: return [[q(4.5, 0), q(9, 6), q(4.5, 6)]]                     // the half folded over
            }
        default: return []
        }
    }

    /// A five-pointed star's outline, closed.
    static func star(_ P: (Double, Double) -> CGPoint, cx: Double, cy: Double, r: Double) -> [CGPoint] {
        (0...10).map { i in let a = -Double.pi / 2 + Double(i) * .pi / 5, rr = i % 2 == 0 ? r : r * 0.45; return P(cx + rr * cos(a), cy + rr * sin(a)) }
    }
    /// The same star as triangles from its middle, for its fill (it isn't convex).
    static func starFan(_ P: (Double, Double) -> CGPoint, cx: Double, cy: Double, r: Double) -> [[CGPoint]] {
        let s = star(P, cx: cx, cy: cy, r: r), mid = P(cx, cy)
        return (0..<10).map { [mid, s[$0], s[$0 + 1]] }
    }

    /// The lessons whose picture is a box of cubes, drawn as the 3D lesson shows it.
    private var isBox: Bool { id == "g5-volume" }

    /// A box `l` long, `h` tall and `w` wide, seen from the tilted 3D lesson's own angle (PaperView3D.tilted), `u`
    /// points to a cube: the top, the front and the left side, as the cubes show when the paper tilts.
    private func box3D(l: Double, h: Double, w: Double, u: Double) -> [[CGPoint]] {
        let (_, right, up) = PaperView3D(elevation: PaperView3D.tilted.elevation, azimuth: PaperView3D.tilted.azimuth).axes
        func P(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
            let v = Vec3(x, y, z)
            return CGPoint(x: at.x + v.dot(right) * u, y: at.y - v.dot(up) * u)
        }
        // the side that shows: the right end when the view is turned that way (CubesProblem.widthOnRight), else the left
        let sx = CubesProblem.widthOnRight ? l : 0, ox = l - sx
        let top = [P(0, h, 0), P(l, h, 0), P(l, h, w), P(0, h, w), P(0, h, 0)]
        let front = [P(0, h, w), P(0, 0, w), P(l, 0, w), P(l, h, w)]
        let side = [P(sx, h, 0), P(sx, 0, 0), P(sx, 0, w)]
        // the cubes' own lines: across the top and down the front and the side
        var cuts: [[CGPoint]] = []
        for i in stride(from: 1.0, to: l, by: 1) { cuts += [[P(i, h, 0), P(i, h, w), P(i, 0, w)]] }
        for k in stride(from: 1.0, to: w, by: 1) { cuts += [[P(ox, h, k), P(sx, h, k), P(sx, 0, k)]] }
        for j in stride(from: 1.0, to: h, by: 1) { cuts += [[P(sx, j, 0), P(sx, j, w), P(ox, j, w)]] }
        return [top, front, side] + cuts
    }

    /// The picture as it's drawn, before centring, in cells from the frame's corner. The frame is 15 cells by 10, so its
    /// middle is in the middle of a cell across and on a line down: every picture is an odd number of cells wide and an
    /// even number tall, so centring it keeps every corner on the grid's lines (G 17 Oct).
    private var drawing: [[CGPoint]] {
        let c = Paper.cell
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: at.x + x * c, y: at.y + y * c) }
        func box(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> [CGPoint] { [P(x, y), P(x + w, y), P(x + w, y + h), P(x, y + h), P(x, y)] }
        func line(_ pts: (Double, Double)...) -> [CGPoint] { pts.map { P($0.0, $0.1) } }
        /// A bar `w` cells long and two tall, cut into `parts`.
        func bar(_ x: Double, _ y: Double, _ w: Double, _ parts: Int) -> [[CGPoint]] {
            [box(x, y, w, 2)] + (1..<max(1, parts)).map { i in let cx = x + w * Double(i) / Double(parts); return line((cx, y), (cx, y + 2)) }
        }
        func arc(_ x0: Double, _ x1: Double, _ y: Double, _ h: Double) -> [CGPoint] {
            (0...12).map { s in let f = Double(s) / 12; return P(x0 + (x1 - x0) * f, y - sin(.pi * f) * h) }
        }
        if Map.isGradeTest(id) { // the grade's test: a medal, a star in its middle and two ribbon tails: 9 by 6... 5 wide
            let ring = (0...32).map { s -> CGPoint in let a = Double(s) / 32 * 2 * .pi; return P(4.5 + 2.4 * cos(a), 2.4 + 2.4 * sin(a)) }
            return [ring, Self.star(P, cx: 4.5, cy: 2.4, r: 1.4), line((3.2, 4.3), (2.6, 6), (3.6, 5.5), (4.1, 6), (4.3, 4.8)), line((5.8, 4.3), (6.4, 6), (5.4, 5.5), (4.9, 6), (4.7, 4.8))]
        }
        if isTest { // a chapter's test: a sheet with its corner folded and answers written on it: 5 by 6
            return [line((0, 0), (3.5, 0), (5, 1.5), (5, 6), (0, 6), (0, 0)), line((3.5, 0), (3.5, 1.5), (5, 1.5)),
                    line((1, 2.5), (3.5, 2.5)), line((1, 3.5), (3.5, 3.5)), line((1, 4.5), (2.5, 4.5))]
        }
        // a lesson still to come (G 3 Nov): an empty frame
        if !isTest && spec == nil { return [] }
        switch id {
        // Kindergarten, Count to 10 (4 Nov)
        case "gk-count10": // dots scattered over a ten track, three counted onto it: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.4 * cos(a), y + 0.4 * sin(a)) } }
            return [box(0, 5, 10, 1)] + (1...9).map { x in line((Double(x), 5), (Double(x), 6)) }
                + [dot(0.5, 5.5), dot(1.5, 5.5), dot(2.5, 5.5), dot(4.5, 0.5), dot(7.5, 1.5), dot(2.5, 2.5), dot(10.5, 0.5), dot(5.5, 3.5)]
        case "gk-onemore": // the number stairs, each train one cube longer: 7 by 6
            return (1...6).flatMap { k -> [[CGPoint]] in
                let y = Double(k - 1), w = Double(k + 1)
                var parts: [[CGPoint]] = [box(0, y, w, 1)]
                for x in 1..<(k + 1) { parts.append(line((Double(x), y), (Double(x), y + 1))) }
                return parts
            }
        case "k-compare": // two rows of dots matched in pairs, two on top with no partner: 7 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.4 * cos(a), y + 0.4 * sin(a)) } }
            var parts: [[CGPoint]] = []
            for i in 0..<7 { parts.append(dot(Double(i) + 0.5, 0.5)) }
            for i in 0..<5 {
                let x: Double = Double(i) + 0.5
                parts += [dot(x, 5.5), line((x, 1), (x, 5))]
            }
            return parts
        case "gk-numcompare": // two trains, the shorter one's end dropped across to the longer: 7 by 6
            return [box(0, 0, 4, 2), box(0, 4, 7, 2), line((4, 0), (4, 6))] + (1..<4).map { x in line((Double(x), 0), (Double(x), 2)) }
                + (1..<7).map { x in line((Double(x), 4), (Double(x), 6)) }
        // Kindergarten, Shapes (4 Nov)
        case "k-shapes": // a triangle, its corners dotted: 7 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.35 * cos(a), y + 0.35 * sin(a)) } }
            return [line((0, 6), (7, 6), (3, 0), (0, 6)), dot(0, 6), dot(7, 6), dot(3, 0)]
        case "gk-draw": // dots on the crossings, a triangle drawn on them: 9 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...12).map { k in let a = Double(k) / 12 * 2 * .pi; return P(x + 0.2 * cos(a), y + 0.2 * sin(a)) } }
            return [line((0, 6), (6, 6), (3, 0), (0, 6))] + [0.0, 3, 6, 9].flatMap { x in [0.0, 3, 6].map { y in dot(x, y) } }
        case "k-solids": // a cube standing, and the flat square beside it: 11 by 6
            return [box(0, 2, 4, 4), line((0, 2), (2, 0), (6, 0), (4, 2)), line((6, 0), (6, 4), (4, 6)), box(7, 2, 4, 4)]
        case "gk-position": // a floor, a cube on it in front, a ball behind: 11 by 6
            let ball = (0...20).map { k -> CGPoint in let a = Double(k) / 20 * 2 * .pi; return P(9 + 1 * cos(a), 2 + 1 * sin(a)) }
            return [line((0, 6), (8, 6), (11, 3), (3, 3), (0, 6)), box(4, 1, 3, 3), line((4, 1), (5, 0), (8, 0), (7, 1)), line((8, 0), (8, 3), (7, 4)), ball]
        case "gk-compose": // a square of two triangles, and a triangle waiting beside it: 11 by 6
            return [box(0, 0, 6, 6), line((0, 0), (6, 6)), line((8, 0), (8, 6), (11, 6), (8, 0))]
        // Kindergarten, Measure and sort (4 Nov)
        case "k-length": // two things from one start line, the shorter one's end dropped across the longer: 9 by 6
            let dash = stride(from: 0.0, to: 6, by: 1).map { y in line((6, y), (6, y + 0.5)) }
            return [line((0, 0), (0, 6)), box(0, 0.5, 9, 1.5), box(0, 4, 6, 1.5)] + (1..<9).map { x in line((Double(x), 0.5), (Double(x), 2)) }
                + (1..<6).map { x in line((Double(x), 4), (Double(x), 5.5)) } + dash
        case "gk-heavier": // a pan balance tipped, the heavy one down on the left: 11 by 6
            // in parts: GitHub's compiler can't read it as one list
            let beam: [[CGPoint]] = [line((5.5, 1.5), (5.5, 6)), line((4, 6), (7, 6)), line((1.5, 2.3), (9.5, 0.7))]
            let left: [[CGPoint]] = [line((1.5, 2.3), (0, 4.8)), line((1.5, 2.3), (3, 4.8)), line((0, 4.8), (3, 4.8)), box(0.8, 3.8, 1.4, 1)]
            let right: [[CGPoint]] = [line((9.5, 0.7), (8, 3.2)), line((9.5, 0.7), (11, 3.2)), line((8, 3.2), (11, 3.2)), box(8.2, 2.2, 2.6, 1)]
            return beam + left + right
        case "k-sort": // three rows of things from one line, most at the top: 9 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.45 * cos(a), y + 0.45 * sin(a)) } }
            var parts: [[CGPoint]] = [line((1.6, 0), (1.6, 6)), box(0, 0, 1.6, 1.6), box(0, 2.2, 1.6, 1.6), box(0, 4.4, 1.6, 1.6)]
            for (count, y) in [(6, 0.8), (4, 3.0), (2, 5.2)] {
                for i in 0..<count { parts.append(dot(2.4 + Double(i) * 1.1, y)) }
            }
            return parts
        // Kindergarten, Add and take away (4 Nov)
        case "k-add": // a train on a track, hops over the cubes counted on: 7 by 6
            return [box(0, 4, 7, 2)] + (1..<7).map { x in line((Double(x), 4), (Double(x), 6)) } + (4..<7).map { j in arc(Double(j) - 0.5, Double(j) + 0.5, 4, 1.5) }
        case "k-sub": // a train with three cubes taken off into the strip under it, crossed out: 7 by 6
            return [box(0, 0, 4, 2)] + (1..<4).map { x in line((Double(x), 0), (Double(x), 2)) }
                + (4..<7).flatMap { x in [box(Double(x), 4, 1, 2), line((Double(x) + 0.2, 5.8), (Double(x) + 0.8, 4.2))] }
        case "k-story": // counters on a track, two more waiting above it to come on: 7 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.35 * cos(a), y + 0.35 * sin(a)) } }
            return [box(0, 4, 7, 2)] + (1..<7).map { x in line((Double(x), 4), (Double(x), 6)) }
                + (0..<5).map { dot(Double($0) + 0.5, 5) } + [dot(5.5, 1), dot(6.5, 1)]
        case "k-bonds": // a number bond: the whole's circle over its two parts', lines between: 7 by 6
            func ring(_ x: Double, _ y: Double) -> [CGPoint] { (0...24).map { k in let a = Double(k) / 24 * 2 * .pi; return P(x + cos(a), y + sin(a)) } }
            return [ring(3.5, 1), ring(1, 5), ring(6, 5), line((2.85, 1.76), (1.65, 4.24)), line((4.15, 1.76), (5.35, 4.24))]
        case "k-make10": // a ten frame with seven dots, three boxes empty: 10 by 4
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.6 * cos(a), y + 0.6 * sin(a)) } }
            let walls: [[CGPoint]] = (1..<5).map { x in line((Double(x) * 2, 0), (Double(x) * 2, 4)) }
            let dots: [[CGPoint]] = (0..<7).map { j in dot(Double(j % 5) * 2 + 1, Double(j / 5) * 2 + 1) }
            return [box(0, 0, 10, 4), line((0, 2), (10, 2))] + walls + dots
        case "gk-five": // a hand: a palm, four fingers up and one folded: 9 by 6
            return [box(0, 4, 9, 2), box(0, 1, 1, 3), box(2, 0, 1, 4), box(4, 0, 1, 4), box(6, 0, 1, 4), box(8, 3, 1, 1)]
        // Kindergarten, Teens and tens (4 Nov)
        case "k-count20": // the twenty track, the top row full, four on the bottom row: 10 by 2, from row 2
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.3 * cos(a), y + 0.3 * sin(a)) } }
            var out: [[CGPoint]] = [box(0, 2, 10, 2), line((0, 3), (10, 3))]
            for x in 1..<10 { out.append(line((Double(x), 2), (Double(x), 4))) }
            for j in 0..<14 { out.append(dot(Double(j % 10) + 0.5, Double(j / 10) + 2.5)) }
            return out
        case "k-write": // a ten frame with seven dots, and a 7 to trace beside it: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.3 * cos(a), y + 0.3 * sin(a)) } }
            var out: [[CGPoint]] = [box(0, 2, 5, 2), line((0, 3), (5, 3)), line((7.5, 1.5), (10.5, 1.5), (8.5, 5.5))]
            for x in 1..<5 { out.append(line((Double(x), 2), (Double(x), 4))) }
            for j in 0..<7 { out.append(dot(Double(j % 5) + 0.5, Double(j / 5) + 2.5)) }
            return out
        case "k-teens": // a full ten frame and one with six, side by side: 11 by 2, from row 2
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.3 * cos(a), y + 0.3 * sin(a)) } }
            var out: [[CGPoint]] = [box(0, 2, 5, 2), line((0, 3), (5, 3)), box(6, 2, 5, 2), line((6, 3), (11, 3))]
            for x in 1..<5 { out.append(line((Double(x), 2), (Double(x), 4))); out.append(line((Double(x) + 6, 2), (Double(x) + 6, 4))) }
            for j in 0..<10 { out.append(dot(Double(j % 5) + 0.5, Double(j / 5) + 2.5)) }
            for j in 0..<6 { out.append(dot(Double(j % 5) + 6.5, Double(j / 5) + 2.5)) }
            return out
        case "k-tens": // tiles of ten in rows of five: 10 by 5
            return (0..<8).flatMap { t -> [[CGPoint]] in
                let x = Double(t % 5) * 2, y = Double(t / 5) * 3 + 1
                return [box(x + 0.15, y, 1.7, 1), line((x + 0.15, y + 0.5), (x + 1.85, y + 0.5))]
            }
        case "gk-count100": // the hundred chart's top rows: 10 by 6
            return [box(0, 0, 10, 6)] + (1..<10).map { x in line((Double(x), 0), (Double(x), 6)) } + (1..<6).map { y in line((0, Double(y)), (10, Double(y))) }
        // 1st grade, Numbers to 120 (4 Nov)
        case "g1-count120": // four rows of the 120 chart: 10 by 4, from row 1
            return [box(0, 1, 10, 4)] + (1..<10).map { x in line((Double(x), 1), (Double(x), 5)) } + [2.0, 3, 4].map { y in line((0, y), (10, y)) }
        case "g1-tensones": // three tens closed into rows, four ones under them: 10 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.4 * cos(a), y + 0.4 * sin(a)) } }
            var out: [[CGPoint]] = []
            for r in 0..<3 { out.append(box(0, 0.5 + 1.5 * Double(r), 10, 1)) }
            for j in 0..<4 { out.append(dot(Double(j) + 0.5, 5)) }
            return out
        case "g1-compare": // two stacks of tens side by side, the right one a ten taller: 10 by 6
            var out: [[CGPoint]] = []
            for r in 0..<3 { out.append(box(0, 0.5 + Double(r), 4.5, 1)) }
            for r in 0..<4 { out.append(box(5.5, 0.5 + Double(r), 4.5, 1)) }
            return out + [line((0, 5.5), (2, 5.5)), line((5.5, 5.5), (7, 5.5))]
        // 1st grade, Adding and taking away tens (4 Nov)
        case "g1-addtens", "g1-add100", "g1-subtens":
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.4 * cos(a), y + 0.4 * sin(a)) } }
            var out: [[CGPoint]] = []
            switch id {
            case "g1-addtens": // two tens, two more joined under them, three ones: 10 by 6
                for r in 0..<4 { out.append(box(0, 0.5 + Double(r), 10, 1)) }
                for j in 0..<3 { out.append(dot(Double(j) + 0.5, 5.25)) }
            case "g1-add100": // two tens, a full row of ones closed into a ten, three ones: 10 by 6
                for r in 0..<3 { out.append(box(0, 0.5 + Double(r), 10, 1)) }
                for j in 0..<10 { out.append(dot(Double(j) + 0.5, 3)) }
                for j in 0..<3 { out.append(dot(Double(j) + 0.5, 4.75)) }
            default: // four tens on the left, two left; two slid away and crossed out: 10 by 6
                for r in 0..<2 { out.append(box(0, 0.5 + Double(r), 4.5, 1)) }
                for r in 0..<2 {
                    out.append(box(5.5, 0.5 + Double(r), 4.5, 1))
                    out.append(line((5.7, 1.35 + Double(r)), (9.8, 0.65 + Double(r))))
                }
            }
            return out
        // 1st grade, Length, time and graphs (4 Nov)
        case "g1-order3": // three things from a dashed line, longest on top: 10 by 6
            var out: [[CGPoint]] = [box(0, 0.5, 9, 1), box(0, 2.5, 6, 1), box(0, 4.5, 3, 1)]
            for y in stride(from: 0.0, to: 6, by: 0.8) { out.append(line((-0.4, y), (-0.4, y + 0.4))) }
            return out
        case "g1-measure": // a pencil and its cubes, a shorter one and its cubes: 10 by 6
            var out: [[CGPoint]] = [box(0, 0.5, 7, 0.6), box(0, 3.5, 4, 0.6)]
            for j in 0..<7 { out.append(box(Double(j), 1.5, 1, 1)) }
            for j in 0..<4 { out.append(box(Double(j), 4.5, 1, 1)) }
            return out
        case "g1-time": // the clock at half past, the hour strip under it: 10 by 6
            let face = (0...32).map { k in let a = Double(k) / 32 * 2 * .pi; return P(5 + 2.4 * cos(a), 2.4 + 2.4 * sin(a)) }
            return [face, line((5, 2.4), (5, 4.2)), line((5, 2.4), (6.2, 1.3)), box(0, 5, 10, 1), line((5, 5), (5, 6))]
        case "g1-picgraph": // three rows of pictures from one line: 10 by 6
            func pic(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.38 * cos(a), y + 0.38 * sin(a)) } }
            var out: [[CGPoint]] = [line((0, 0.5), (0, 5.5))]
            for (r, n) in [8, 3, 5].enumerated() { for j in 0..<n { out.append(pic(Double(j) + 0.5, 1.5 + 1.75 * Double(r))) } }
            return out
        case "g1-tally": // three rows of tally marks, five across in bundles: 10 by 6
            var out: [[CGPoint]] = []
            for (r, n) in [7, 4, 9].enumerated() {
                let y = 1 + 1.75 * Double(r)
                for i in 0..<n {
                    let b = Double(i / 5), j = i % 5
                    if j < 4 { out.append(line((b * 5 + 0.5 + Double(j), y), (b * 5 + 0.5 + Double(j), y + 1.2))) }
                    else { out.append(line((b * 5, y + 1.0), (b * 5 + 4, y + 0.2))) }
                }
            }
            return out
        // 1st grade, Shapes and equal parts (4 Nov)
        case "g1-shapes": // a triangle, its corners dotted, and a long thin one drawn beside it: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.3 * cos(a), y + 0.3 * sin(a)) } }
            return [line((0, 6), (7, 6), (2, 0), (0, 6)), dot(0, 6), dot(7, 6), dot(2, 0), line((8, 6), (11, 5), (9, 0), (8, 6))]
        case "g1-compose": // a hexagon of two trapezoids, and a triangle waiting beside it: 11 by 6
            return [line((0, 3), (1.5, 0), (4.5, 0), (6, 3), (4.5, 6), (1.5, 6), (0, 3)), line((0, 3), (6, 3)), line((8, 6), (9, 3), (11, 6), (8, 6))]
        case "g1-build": // a box of two cubes, a cone standing beside it: 11 by 6
            let base = (0...20).map { k -> CGPoint in let a = Double(k) / 20 * .pi; return P(9 + 1.5 * cos(a), 5.4 + 0.6 * sin(a)) }
            return [box(1, 3, 6, 3), line((1, 3), (2, 1.5), (8, 1.5), (7, 3)), line((8, 1.5), (8, 4.5), (7, 6)), line((4, 3), (4, 6)), line((4, 3), (5, 1.5)),
                    line((7.5, 5.4), (9, 0.5), (10.5, 5.4)), base]
        case "g1-halves": // a rectangle cut straight down into halves: 10 by 6
            return [box(0, 0, 10, 6), line((5, 0), (5, 6))]
        // 2nd grade, Adding and subtracting to 100 (4 Nov)
        case "g2-facts", "g2-regroup", "g2-subregroup", "g2-addfour", "g2-story", "g2-twostep":
            func dot(_ x: Double, _ y: Double, _ r: Double = 0.4) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + r * cos(a), y + r * sin(a)) } }
            func ten(_ x: Double, _ y: Double) -> [[CGPoint]] { [box(x, y, 4.5, 0.6)] + (1..<10).map { i in line((x + 0.45 * Double(i), y), (x + 0.45 * Double(i), y + 0.6)) } }
            func cross(_ x: Double, _ y: Double) -> [CGPoint] { line((x, y + 0.6), (x + 4.5, y)) }
            switch id {
            case "g2-facts": // two rows of ten places, two slid up to fill the top: 10 by 6
                var out: [[CGPoint]] = [box(0, 1, 10, 1), box(0, 3.5, 10, 1)]
                for x in 1..<10 { out.append(line((Double(x), 1), (Double(x), 2))); out.append(line((Double(x), 3.5), (Double(x), 4.5))) }
                for j in 0..<10 { out.append(dot(Double(j) + 0.5, 1.5)) }
                for j in 0..<3 { out.append(dot(Double(j) + 0.5, 4)) }
                out.append(arc(3.5, 8.5, 3.4, 0.5)); out.append(arc(4.5, 9.5, 3.4, 0.5))
                return out
            case "g2-regroup": // 4 tens and a new one, 3 tens beside, 5 ones: 10 by 6
                var out = [0.6, 1.4, 2.2, 3.0, 3.8].flatMap { ten(0, $0) } + [0.6, 1.4, 2.2].flatMap { ten(5.5, $0) }
                for j in 0..<5 { out.append(dot(0.25 + 0.45 * Double(j), 4.9, 0.18)) }
                return out
            case "g2-subregroup": // 5 tens, two crossed, one opened into ones: 10 by 6
                var out = [0.6, 1.4, 2.2, 3.0].flatMap { ten(0, $0) } + [cross(0, 2.2), cross(0, 3.0)]
                for j in 0..<10 { out.append(dot(0.25 + 0.45 * Double(j), 4.9, 0.18)); if j >= 5 { out.append(line((0.05 + 0.45 * Double(j), 5.1), (0.45 + 0.45 * Double(j), 4.7))) } }
                return out
            case "g2-addfour": // the total's tens, a new ten, three numbers beside: 10 by 6
                var out = [0.6, 1.4, 2.2, 3.0].flatMap { ten(0, $0) }
                out += [0.6, 2.2, 3.8].flatMap { ten(5.5, $0) }
                for y in [1.6, 3.2, 4.8] { for j in 0..<4 { out.append(dot(5.75 + 0.45 * Double(j), y, 0.18)) } }
                return out
            case "g2-story": // a bar in two parts under the whole's bracket, the unknown part dashed: 10 by 6
                var out: [[CGPoint]] = [box(0, 2.5, 6, 1.5), line((0, 2), (0, 1.5), (4.6, 1.5), (5, 1), (5.4, 1.5), (10, 1.5), (10, 2))]
                for x in stride(from: 6.0, to: 10, by: 0.8) { out.append(line((x, 2.5), (min(10, x + 0.4), 2.5))); out.append(line((x, 4), (min(10, x + 0.4), 4))) }
                out.append(line((10, 2.5), (10, 4))); out.append(line((3, 2.5), (3, 4)))
                return out
            default: // a start bar, a change joined at its end, the next one waiting under it: 10 by 6
                return [box(0, 2, 6, 1.5), box(6, 2, 3, 1.5), line((3, 2), (3, 3.5)), box(0, 4.5, 4, 1.5), line((0, 1.5), (0, 6))]
            }
        case "g2-measure", "g2-twounits", "g2-estimate", "g2-numline":
            func ticks(_ y: Double, _ step: Double, _ n: Int, _ h: Double) -> [[CGPoint]] { (0...n).map { i in line((Double(i) * step, y), (Double(i) * step, y + h)) } }
            switch id {
            case "g2-measure": // a pencil over a ruler, the hops between: 10 by 6
                var out: [[CGPoint]] = [[P(1, 0.5), P(6, 0.5), P(7, 1), P(6, 1.5), P(1, 1.5), P(1, 0.5)], box(0, 3.5, 10, 2)]
                out += ticks(3.5, 1, 10, 0.5)
                for i in 1..<7 { let pts = (0...8).map { k -> CGPoint in let t = Double(k) / 8; return P(Double(i) + t, 3.5 - sin(.pi * t) * 0.5) }; out.append(pts) }
                return out
            case "g2-twounits": // an inch ruler over a key, a centimeter ruler under it: 10 by 6
                var out: [[CGPoint]] = [box(0, 0, 10, 1.2), box(0.5, 2.4, 6, 1.2), box(0, 4.8, 10, 1.2)]
                out += ticks(0.7, 2.5, 4, 0.5); out += ticks(4.8, 1, 10, 0.4)
                return out
            case "g2-estimate": // a paper clip, a pencil, clips laid along it: 10 by 6
                var out: [[CGPoint]] = [box(0, 0, 2, 0.6), [P(0, 3.5), P(9, 3.5), P(10, 4), P(9, 4.5), P(0, 4.5), P(0, 3.5)]]
                for j in 0..<5 { out.append(box(Double(j) * 2, 2, 2, 0.6)) }
                return out
            default: // a bar from 0 over a tape measure, hops back: 10 by 6
                var out: [[CGPoint]] = [box(0, 1, 7, 1.5), line((0, 4.5), (10, 4.5))]
                out += ticks(4.5, 1, 10, 0.4)
                for (a, b) in [(7.0, 5.0), (5.0, 4.0)] { out.append((0...8).map { k -> CGPoint in let t = Double(k) / 8; return P(a + (b - a) * t, 4.5 - sin(.pi * t) * 0.8) }) }
                return out
            }
        case "g2-time5", "g2-coins", "g2-money", "g2-dollars":
            func ring(_ cx: Double, _ cy: Double, _ r: Double) -> [CGPoint] { (0...32).map { k in let a = Double(k) / 32 * 2 * .pi; return P(cx + r * cos(a), cy + r * sin(a)) } }
            switch id {
            case "g2-time5": // a clock, its hands; the hour strip beside it: 10 by 6
                var out: [[CGPoint]] = [ring(3, 3, 3), line((3, 3), (3 + 2.4 * sin(2.6), 3 - 2.4 * cos(2.6))), line((3, 3), (4.2, 2.1))]
                for k in 0..<12 { let t = Double(k) / 12 * 2 * .pi; out.append(line((3 + 2.6 * sin(t), 3 - 2.6 * cos(t)), (3 + 3 * sin(t), 3 - 3 * cos(t)))) }
                out.append(box(7, 1.5, 3, 1)); out.append(line((8, 1.5), (8, 2.5))); out.append(line((9, 1.5), (9, 2.5)))
                return out
            case "g2-coins": // a big smooth coin and a small bumpy one: 10 by 6
                var out: [[CGPoint]] = [ring(3, 3, 3), ring(3, 3, 2.6), ring(8, 3.5, 1.4), ring(8, 3.5, 1.15)]
                for k in 0..<16 { let t = Double(k) / 16 * 2 * .pi; out.append(line((8 + 1.15 * cos(t), 3.5 + 1.15 * sin(t)), (8 + 1.4 * cos(t), 3.5 + 1.4 * sin(t)))) }
                return out
            case "g2-money": // coins fanned at the left, the dollar square in four blocks: 10 by 6
                var out: [[CGPoint]] = [box(4, 0, 6, 6), line((7, 0), (7, 6)), line((4, 3), (10, 3))]
                for (cx, cy) in [(0.8, 1.0), (1.8, 1.0), (0.7, 3.0), (1.5, 3.0), (0.7, 4.9)] { out.append(ring(cx, cy, 0.7)) }
                return out
            default: // bills fanned, the dollar chart's rows: 10 by 6
                var out: [[CGPoint]] = [box(0, 0.5, 3, 1.5), box(0.8, 0.5, 3, 1.5), box(0, 3, 3, 1.5), box(5, 0.5, 5, 5)]
                for r in 1..<5 { out.append(line((5, 0.5 + Double(r)), (10, 0.5 + Double(r)))) }
                out.append(line((7.5, 0.5), (7.5, 5.5)))
                return out
            }
        // 2nd grade, Shapes (4 Nov)
        case "g2-shapes": // a pentagon, its corners dotted, and a hexagon drawn beside it: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.3 * cos(a), y + 0.3 * sin(a)) } }
            var out: [[CGPoint]] = [line((2.5, 0), (5, 2), (4, 5), (1, 5), (0, 2), (2.5, 0))]
            for p in [(2.5, 0.0), (5.0, 2.0), (4.0, 5.0), (1.0, 5.0), (0.0, 2.0)] { out.append(dot(p.0, p.1)) }
            out.append(line((7, 3), (8, 1.2), (10, 1.2), (11, 3), (10, 4.8), (8, 4.8), (7, 3)))
            return out
        case "g2-solids": // a box standing in the tilted view, its hidden edges dashed: 11 by 6
            return [box(1, 2.5, 6, 3.5), line((1, 2.5), (2.5, 1), (8.5, 1), (7, 2.5)), line((8.5, 1), (8.5, 4.5), (7, 6)),
                    line((7.5, 5.4), (9.5, 0.5), (11, 4.6), (7.5, 5.4)), line((9.5, 0.5), (10, 5.8))]
        case "g3-round": // a line in blocks, one opened below, the hop to the closer end: 10 by 6
            var out: [[CGPoint]] = [line((0, 1.5), (10, 1.5)), line((0, 5.5), (10, 5.5)), line((4, 2), (0, 4)), line((5, 2), (10, 4))]
            for i in 0...10 { out.append(line((Double(i), i % 5 == 0 ? 0.5 : 1), (Double(i), 1.5))) }
            for i in [0.0, 5, 10] { out.append(line((i, i == 5 ? 4.5 : 5), (i, 5.5))) }
            out.append(arc(7, 10, 5.5, 1.5))
            return out
        case "g3-addsub": // the place chart: three columns of disks over three more, a column full: 10 by 6
            func disk(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.42 * cos(a), y + 0.42 * sin(a)) } }
            var out: [[CGPoint]] = []
            for (col, n) in [(0, 2), (1, 3), (2, 1)] {
                let x = Double(col) * 3.6
                out.append(box(x, 0.5, 2.8, 2)); out.append(box(x, 3.5, 2.8, 2))
                for d in 0..<n { out.append(disk(x + 0.5 + 0.9 * Double(d), 1.5)) }
                for d in 0..<[1, 2, 2][col] { out.append(disk(x + 0.5 + 0.9 * Double(d), 4.5)) }
            }
            return out
        case "g3-estimate": // a line, two big hops to the estimate, ringed: 10 by 6
            func ring(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.45 * cos(a), y + 0.45 * sin(a)) } }
            var out: [[CGPoint]] = [line((0, 4.5), (10, 4.5))]
            for i in 0...10 { out.append(line((Double(i), i % 5 == 0 ? 3.7 : 4.1), (Double(i), 4.5))) }
            out.append(arc(0, 5, 4.2, 3)); out.append(arc(5, 8, 4.2, 2)); out.append(ring(8, 4.5))
            return out
        // 3rd grade, Shapes and area (4 Nov)
        case "g3-quads": // a parallelogram, its parallel sides arrowed, its equal sides ticked: 10 by 6
            return [line((2, 1), (10, 1), (8, 5), (0, 5), (2, 1)), line((5.6, 0.6), (6, 1), (5.6, 1.4)), line((4.6, 4.6), (5, 5), (4.6, 5.4)),
                    line((0.55, 2.75), (1.45, 3.25)), line((8.55, 2.75), (9.45, 3.25))]
        case "g3-area", "g3-lshape", "g3-perim", "g3-perimarea":
            func grid(_ x: Double, _ y: Double, _ w: Int, _ h: Int) -> [[CGPoint]] {
                var out: [[CGPoint]] = [box(x, y, Double(w), Double(h))]
                for i in 1..<w { out.append(line((x + Double(i), y), (x + Double(i), y + Double(h)))) }
                for j in 1..<h { out.append(line((x, y + Double(j)), (x + Double(w), y + Double(j)))) }
                return out
            }
            switch id {
            case "g3-area": // a rectangle of tiles, each 2 cells (one square unit) here: 10 by 6
                var out: [[CGPoint]] = [box(0, 0, 10, 6)]
                for i in 1..<5 { out.append(line((2 * Double(i), 0), (2 * Double(i), 6))) }
                for j in 1..<3 { out.append(line((0, 2 * Double(j)), (10, 2 * Double(j)))) }
                return out
            case "g3-lshape": // an L, cut down from its inside corner: 10 by 6
                var out: [[CGPoint]] = [line((0, 0.5), (6, 0.5), (6, 2.5), (10, 2.5), (10, 5.5), (0, 5.5), (0, 0.5))]
                for k in 0..<3 { out.append(line((6, 2.5 + Double(k)), (6, 3 + Double(k)))) }
                return out
            case "g3-perim": // a rectangle with a tick at every cm and the point walking it: 10 by 6
                var out: [[CGPoint]] = [box(0, 0.5, 10, 5)]
                for i in 1..<10 { out.append(line((Double(i), 0.5), (Double(i), 0.9))); out.append(line((Double(i), 5.1), (Double(i), 5.5))) }
                for j in 1..<5 { out.append(line((0, 0.5 + Double(j)), (0.4, 0.5 + Double(j)))); out.append(line((9.6, 0.5 + Double(j)), (10, 0.5 + Double(j)))) }
                out.append((0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(10 + 0.45 * cos(a), 3 + 0.45 * sin(a)) })
                return out
            default: return grid(0, 1.5, 5, 3) + grid(6, 0.5, 4, 4)                          // two gardens, one fence: 10 by 6
            }
        case "g3-shapeparts": // a rectangle cut into four equal strips, one lifted a square: 8 by 6
            return [box(0, 0, 2, 5), line((2, 1), (8, 1), (8, 6), (0, 6), (0, 5)), line((4, 1), (4, 6)), line((6, 1), (6, 6))]
        case "g3-unitfrac": // a bar of fourths, two shaded, one part slid up out of it: 8 by 6
            return [box(2, 0, 2, 2), box(0, 3, 8, 3), line((2, 3), (2, 6)), line((4, 3), (4, 6)), line((6, 3), (6, 6))]
        case "g3-fracline": // a line 0 to 1 in fourths, three hops landing on the point: 9 by 6... 8 wide
            var out: [[CGPoint]] = [line((0, 4), (8, 4))]
            for i in 0...4 { out.append(line((Double(i) * 2, i % 4 == 0 ? 3 : 3.4), (Double(i) * 2, 4))) }
            for i in 0..<3 { out.append(arc(Double(i) * 2, Double(i + 1) * 2, 4, 1.6)) }
            out.append((0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(6 + 0.4 * cos(a), 4 + 0.4 * sin(a)) })
            return out
        case "g3-equiv": // halves over fourths, the points one under the other, a dashed line between: 8 by 6
            var out: [[CGPoint]] = [line((0, 2), (8, 2)), line((0, 6), (8, 6)), line((4, 2.6), (4, 5.4))]
            for i in 0...2 { out.append(line((Double(i) * 4, 1.2), (Double(i) * 4, 2))) }
            for i in 0...4 { out.append(line((Double(i) * 2, i % 4 == 0 ? 5.2 : 5.5), (Double(i) * 2, 6))) }
            for y in [2.0, 6.0] { out.append((0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(4 + 0.4 * cos(a), y + 0.4 * sin(a)) }) }
            return out
        case "g3-elapsed": // a timeline of o'clocks, a hop to the o'clock, the hour, the minutes left: 10 by 6
            func arc(_ a: Double, _ b: Double, _ h: Double) -> [CGPoint] { (0...12).map { k in let t = Double(k) / 12; return P(a + (b - a) * t, 4 - sin(.pi * t) * h) } }
            var out: [[CGPoint]] = [line((0, 4), (10, 4)), arc(0.8, 2.4, 1), arc(2.4, 8.4, 2.6), arc(8.4, 9.6, 0.9)]
            for x in [0.0, 2.4, 8.4] { out.append(line((x, 3.3), (x, 4))) }
            return out
        case "g3-clock": // a clock at 9:47, its marks and hands; the hour laid out straight under it: 10 by 6
            func ring(_ cx: Double, _ cy: Double, _ r: Double) -> [CGPoint] { (0...32).map { k in let a = Double(k) / 32 * 2 * .pi; return P(cx + r * cos(a), cy + r * sin(a)) } }
            var out: [[CGPoint]] = [ring(5, 2.2, 2.2), line((5, 2.2), (5 + 1.8 * sin(4.92), 2.2 - 1.8 * cos(4.92))), line((5, 2.2), (5 + 1.1 * sin(5.1), 2.2 - 1.1 * cos(5.1)))]
            for k in 0..<12 { let t = Double(k) / 12 * 2 * .pi; out.append(line((5 + 1.9 * sin(t), 2.2 - 1.9 * cos(t)), (5 + 2.2 * sin(t), 2.2 - 2.2 * cos(t)))) }
            out.append(line((0, 5.5), (10, 5.5)))
            for k in 0...12 { let x = Double(k) * 10 / 12; out.append(line((x, 5.5), (x, k % 3 == 0 ? 5 : 5.2))) }
            return out
        case "g3-fraccompare": // fourths over eighths, 3/4 shaded over 5/8, the shading's end dropped dashed: 8 by 6
            var out: [[CGPoint]] = bar(0, 0, 8, 4) + bar(0, 3, 8, 8)
            out.append(line((6, 5.5), (6, 6)))
            return out
        case "g3-split", "g3-three", "g3-double", "g3-mult10":
            func dot(_ x: Double, _ y: Double, _ r: Double = 0.35) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + r * cos(a), y + r * sin(a)) } }
            var out: [[CGPoint]] = []
            switch id {
            case "g3-split": // an array cut after 5, the other part a square away: 10 by 6
                out.append(box(0, 0, 6, 6)); out.append(box(7, 0, 3, 6))
                for r in 0..<3 { for x in [1.0, 3.0, 5.0, 8.5] { out.append(dot(x, 1 + 2 * Double(r))) } }
            case "g3-three": // two rows of three groups of two: 10 by 6
                for r in 0..<2 {
                    let y = 0.5 + 3 * Double(r)
                    out.append(box(0, y, 10, 2))
                    for g in 1..<3 { out.append(line((10 * Double(g) / 3, y), (10 * Double(g) / 3, y + 2))) }
                    for g in 0..<3 { for d in 0..<2 { out.append(dot(10 * Double(g) / 3 + 0.85 + 1.65 * Double(d), y + 1)) } }
                }
            case "g3-double": // four rows cut into two equal halves a square apart: 10 by 6
                out.append(box(0, 0, 10, 2.5)); out.append(box(0, 3.5, 10, 2.5))
                for y in [0.65, 1.85, 4.15, 5.35] { for x in 0..<5 { out.append(dot(1 + 2 * Double(x), y, 0.3)) } }
            default: // ten-frames in rows, ten of them closed into a hundred: 10 by 6
                for r in 0..<3 { out.append(box(0, 0.5 + 2 * Double(r), 4, 1.5)); out.append(line((2, 0.5 + 2 * Double(r)), (2, 2 + 2 * Double(r)))) }
                out.append(box(5, 0.5, 5, 5))
                for r in 1..<5 { out.append(line((5, 0.5 + Double(r)), (10, 0.5 + Double(r)))) }
                out.append(line((7.5, 0.5), (7.5, 5.5)))
            }
            return out
        case "g3-facts", "g3-divfacts", "g3-unknown", "g3-twostep":
            func dot(_ x: Double, _ y: Double, _ r: Double = 0.35) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + r * cos(a), y + r * sin(a)) } }
            var out: [[CGPoint]] = []
            switch id {
            case "g3-facts": // three rows of five dots, the bottom row just made: 10 by 6
                out.append(box(0, 0, 10, 6))
                for r in 0..<3 { for c in 0..<5 { out.append(dot(1 + 2 * Double(c), 1 + 2 * Double(r))) } }
            case "g3-divfacts": // a pile on the left, shared into three rows on the right: 10 by 6
                for r in 0..<2 { for c in 0..<3 { out.append(dot(0.5 + 1.5 * Double(c), 0.8 + 1.5 * Double(r))) } }
                out.append(box(6, 0, 4, 6))
                for r in 0..<3 { out.append(line((6, 2 * Double(r)), (10, 2 * Double(r)))); for c in 0..<2 { out.append(dot(7 + 2 * Double(c), 1 + 2 * Double(r))) } }
            case "g3-unknown": // an array, its total in a bracket, a side's name an empty box: 10 by 6
                out.append(box(0, 0, 6, 6))
                for r in 0..<3 { for c in 0..<3 { out.append(dot(1 + 2 * Double(c), 1 + 2 * Double(r))) } }
                out.append(line((6.8, 0), (7.2, 0), (7.2, 6), (6.8, 6))); out.append(box(7.5, 2, 2.5, 2))
            default: // packs of dots, the last few crossed out: 10 by 6
                for r in 0..<3 { out.append(box(0, 2 * Double(r), 10, 2)); for c in 0..<5 { out.append(dot(1 + 2 * Double(c), 1 + 2 * Double(r))) } }
                for c in 3..<5 { out.append(line((0.4 + 2 * Double(c), 5.6), (1.6 + 2 * Double(c), 4.4))) }
            }
            return out
        case "g2-shares": // a rectangle cut straight down into thirds: 10 by 6
            return [box(0, 0, 10, 6), line((10.0 / 3, 0), (10.0 / 3, 6)), line((20.0 / 3, 0), (20.0 / 3, 6))]
        case "g2-makegraph", "g2-bargraph", "g2-lineplot":
            switch id {
            case "g2-makegraph": // tally marks beside three bars made to them: 10 by 6
                var out: [[CGPoint]] = []
                for (r, n) in [5, 3, 4].enumerated() {
                    let y = 1 + 1.8 * Double(r)
                    for i in 0..<min(n, 4) { out.append(line((0.3 + 0.5 * Double(i), y), (0.3 + 0.5 * Double(i), y + 1.2))) }
                    if n == 5 { out.append(line((0.1, y + 1.1), (2, y + 0.1))) }
                    out.append(box(3, y, Double(n), 1.2))
                }
                out.append(line((3, 0.5), (3, 6)))
                return out
            case "g2-bargraph": // three bars over a scale, a line dropped from one's end: 10 by 6
                var out: [[CGPoint]] = []
                for (r, n) in [8.0, 6.5, 4.5].enumerated() { out.append(box(0, 1 + 1.6 * Double(r), n, 1.2)) }
                out.append(line((0, 0.5), (0, 5.8))); out.append(line((0, 5.8), (10, 5.8)))
                for x in stride(from: 0.0, through: 10, by: 1.6) { out.append(line((x, 5.8), (x, 6.2))) }
                for y in stride(from: 2.6, to: 5.8, by: 0.4) { out.append(line((6.5, y), (6.5, y + 0.2))) }
                return out
            default: // X's stacked over a line: 10 by 6
                var out: [[CGPoint]] = [line((0, 5), (10, 5))]
                for i in 0...5 { out.append(line((Double(i) * 2 - 0.5 + 0.5, 5), (Double(i) * 2, 5.4))) }
                for (i, n) in [1, 2, 3, 2, 1].enumerated() {
                    for k in 0..<n { let cx = 1 + 2 * Double(i), t = 4.5 - 1.1 * Double(k); out.append(line((cx - 0.4, t - 0.4), (cx + 0.4, t + 0.4))); out.append(line((cx - 0.4, t + 0.4), (cx + 0.4, t - 0.4))) }
                }
                return out
            }
        case "g2-evenodd", "g2-arrays", "g2-squares":
            func dot(_ x: Double, _ y: Double, _ r: Double = 0.4) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + r * cos(a), y + r * sin(a)) } }
            switch id {
            case "g2-evenodd": // two rows of dots in pairs, one left over: 9 by 2, from row 0
                var out: [[CGPoint]] = []
                for j in 0..<9 { out.append(dot(Double(j / 2) * 2 + 0.5, Double(j % 2) * 1.4 + 0.3, 0.3)) }
                for c in 0..<4 { out.append(box(Double(c) * 2 - 0.2, -0.2, 1.4, 2.4)) }
                return out
            case "g2-arrays": // three rows of three dots, a dot in the middle of each block: 6 by 6, from column 2
                var out: [[CGPoint]] = []
                for r in 0..<3 { for c in 0..<3 { out.append(dot(3 + 2 * Double(c), 1 + 2 * Double(r), 0.5)) } }
                return out
            default: // a rectangle cut into rows and columns of squares: 6 by 6, from column 2
                var out: [[CGPoint]] = [box(2, 0, 6, 6)]
                for k in 1..<3 { out.append(line((2 + 2 * Double(k), 0), (2 + 2 * Double(k), 6))); out.append(line((2, 2 * Double(k)), (8, 2 * Double(k)))) }
                return out
            }
        case "g2-hundreds", "g2-skip", "g2-compare", "g2-within1000":
            switch id {
            case "g2-hundreds": // two flats, four strips, three ones: 10 by 6
            var out: [[CGPoint]] = [box(0, 0.5, 3, 3), box(3.5, 0.5, 3, 3)]
            for x in 1..<3 { out.append(line((Double(x), 0.5), (Double(x), 3.5))); out.append(line((3.5 + Double(x), 0.5), (3.5 + Double(x), 3.5))) }
            for i in 0..<4 { out.append(box(7 + 0.6 * Double(i), 0.5, 0.3, 3)) }
            for i in 0..<3 { out.append(box(9.7, 0.5 + 0.6 * Double(i), 0.3, 0.3)) }
            out.append(line((0, 5.5), (10, 5.5)))
            return out
        case "g2-skip": // a line, five hops of the same size: 10 by 6
            var out: [[CGPoint]] = [line((0, 4.8), (10, 4.8))]
            for i in 0...5 { out.append(line((Double(i) * 2, 4.2), (Double(i) * 2, 4.8))) }
            for i in 0..<4 { out.append(arc(Double(i) * 2, Double(i) * 2 + 2, 4.6, 1.2)) }
            return out
        case "g2-compare": // line 1 in ten blocks, one lit, opened below into line 2: 10 by 6
            var out: [[CGPoint]] = [line((0, 2), (10, 2)), line((0, 5.5), (10, 5.5)), line((4, 2.3), (0, 4.6)), line((5, 2.3), (10, 4.6))]
            for i in 0...10 { out.append(line((Double(i), i % 5 == 0 ? 1.2 : 1.6), (Double(i), 2))); out.append(line((Double(i), i % 5 == 0 ? 4.7 : 5.1), (Double(i), 5.5))) }
            return out
        default: // within 1000: a line, a hop, the point dropped to the next line: 10 by 6
            var out: [[CGPoint]] = [line((0, 5), (10, 5)), line((0, 1.5), (10, 1.5)), arc(2, 4, 4.8, 1)]
            for i in 0...10 { out.append(line((Double(i), 4.5), (Double(i), 5))) }
            out.append(line((3, 1.8), (0, 3.6))); out.append(line((4, 1.8), (10, 3.6)))
            return out
            }
        case "g1-tenmore": // three rows of the chart, a number ringed, one row down lit: 10 by 3, from row 1.5
            let ring = (0...24).map { k in let a = Double(k) / 24 * 2 * .pi; return P(4.5 + 0.7 * cos(a), 3 + 0.7 * sin(a)) }
            return [box(0, 1.5, 10, 3)] + (1..<10).map { x in line((Double(x), 1.5), (Double(x), 4.5)) } + [2.5, 3.5].map { y in line((0, y), (10, y)) } + [ring]
        // 1st grade, Add and take away to 20 (4 Nov)
        case "g1-add20", "g1-sub20", "g1-ten", "g1-doubles", "g1-three", "g1-related", "g1-missing", "g1-equal", "g1-story", "g1-more":
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.4 * cos(a), y + 0.4 * sin(a)) } }
            func ticks(_ y: Double) -> [[CGPoint]] { var out = [line((0, y), (10, y))]; for x in 0...10 { out.append(line((Double(x), y), (Double(x), y + 0.4))) }; return out }
            switch id {
            case "g1-add20": // counters on a line, three hopped on: 10 by 6
                var out = ticks(3)
                for j in 0..<10 { out.append(dot(Double(j) + 0.5, 2.5)) }
                for j in 7..<10 { out.append(arc(Double(j), Double(j) + 1, 2, 0.6)) }
                return out
            case "g1-sub20": // counters on a line, the last four crossed out under a hop back: 10 by 6
                var out = ticks(3)
                for j in 0..<10 { out.append(dot(Double(j) + 0.5, 2.5)) }
                for j in 6..<10 { out.append(line((Double(j) + 0.15, 2.85), (Double(j) + 0.85, 2.15))) }
                out.append(arc(10, 6, 2, 1.6))
                return out
            case "g1-ten": // two rows of ten places, the top filled to ten: 10 by 6
                var out: [[CGPoint]] = [box(0, 1, 10, 1), box(0, 3.5, 10, 1)]
                for x in 1..<10 { out.append(line((Double(x), 1), (Double(x), 2))); out.append(line((Double(x), 3.5), (Double(x), 4.5))) }
                for j in 0..<10 { out.append(dot(Double(j) + 0.5, 1.5)) }
                for j in 0..<3 { out.append(dot(Double(j) + 0.5, 4)) }
                return out
            case "g1-doubles": // two rows lined up, pairs joined, one more: 7 by 6
                var out: [[CGPoint]] = []
                for j in 0..<7 { out.append(dot(Double(j) + 0.5, 4.5)) }
                for j in 0..<6 { out.append(dot(Double(j) + 0.5, 1.5)); out.append(line((Double(j) + 0.5, 1.9), (Double(j) + 0.5, 4.1))) }
                return out
            case "g1-related": // the whole, and the part that makes it up: 10 by 6
                var out: [[CGPoint]] = [box(0, 1, 10, 1)]
                for x in 1..<10 { out.append(line((Double(x), 1), (Double(x), 2))) }
                for j in 0..<6 { out.append(dot(Double(j) + 0.5, 1.5)) }
                out.append(line((6, 2.6), (6, 2.4))); out.append(line((6, 2.6), (10, 2.6))); out.append(line((10, 2.6), (10, 2.4)))
                for j in 0..<6 { out.append(dot(Double(j) + 0.5, 4)) }
                return out
            case "g1-missing": // a line with two hops to a flag: 10 by 6
                var out = ticks(4)
                out.append(arc(4, 6, 4, 1.0)); out.append(arc(6, 9, 4, 1.4))
                out.append(line((9, 4), (9, 1.4))); out.append([P(9, 1.4), P(10, 1.75), P(9, 2.1)])
                return out
            case "g1-equal": // two rows that end level, and = over them: 10 by 6
                var out: [[CGPoint]] = [line((3.5, 0.6), (5, 0.6)), line((3.5, 1.1), (5, 1.1))]
                for j in 0..<8 { out.append(dot(Double(j) + 0.5, 2.5)); out.append(dot(Double(j) + 0.5, 4.5)) }
                out.append(line((8, 1.8), (8, 5.2)))
                return out
            case "g1-story": // a row of places, some came onto it: 10 by 6
                var out: [[CGPoint]] = [box(0, 2, 10, 1)]
                for x in 1..<10 { out.append(line((Double(x), 2), (Double(x), 3))) }
                for j in 0..<9 { out.append(dot(Double(j) + 0.5, 2.5)) }
                out.append(line((6.1, 3.6), (6.1, 3.4))); out.append(line((6.1, 3.6), (8.9, 3.6))); out.append(line((8.9, 3.6), (8.9, 3.4)))
                return out
            case "g1-more": // two rows lined up, partners joined, three with none: 9 by 6
                var out: [[CGPoint]] = []
                for j in 0..<9 { out.append(dot(Double(j) + 0.5, 1.5)) }
                for j in 0..<6 { out.append(dot(Double(j) + 0.5, 4.5)); out.append(line((Double(j) + 0.5, 1.9), (Double(j) + 0.5, 4.1))) }
                return out
            default: // three groups, and the ten they make: 10 by 6
                var out: [[CGPoint]] = [box(0, 5, 10, 1)]
                for (y, n) in [(0.5, 3), (1.7, 4), (2.9, 7)] { for j in 0..<n { out.append(dot(Double(j) + 0.5, y)) } }
                for x in 1..<10 { out.append(line((Double(x), 5), (Double(x), 6))) }
                return out
            }
        case "g6-ratio": // two rectangles of cells growing together a row at a time: 11 by 6
            return [box(0, 0, 4, 6), box(5, 0, 6, 6), line((2, 0), (2, 6)), line((7, 0), (7, 6)), line((9, 0), (9, 6))]
                + [2.0, 4].flatMap { y in [line((0, y), (4, y)), line((5, y), (11, y))] }
        case "g6-ratiotable": // the plane's corner, two points and the line through 0 and them: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.6 * cos(a), y + 0.6 * sin(a)) } }
            return [line((0, 0), (0, 6), (11, 6)), line((0, 6), (9, 0)), dot(3, 4), dot(6, 2)]
        case "g6-rate": // rows shared a column at a time, and one row copied down: 9 by 6
            return [box(0, 0, 3, 4), line((1, 0), (1, 4)), line((2, 0), (2, 4))] + (1...3).map { y in line((0, Double(y)), (3, Double(y))) }
                + [box(6, 0, 3, 6), line((7, 0), (7, 6)), line((8, 0), (8, 6))] + (1...5).map { y in line((6, Double(y)), (9, Double(y))) }
        case "g6-pctof": // a 0%–100% scale over a bar cut into tenths: 10 by 4
            return [line((0, 0), (0, 1), (10, 1), (10, 0)), line((5, 0.4), (5, 1)), box(0, 2, 10, 2)] + (1...9).map { x in line((Double(x), 2), (Double(x), 4)) }
        case "g6-lcm": // a number line, hops of 3 above and of 2 under, meeting at 6: 7 by 4
            return [line((0, 2), (7, 2))] + (0...7).map { x in line((Double(x), 2), (Double(x), 2.4)) }
                + [arc(0, 3, 2, 1.6), arc(3, 6, 2, 1.6), arc(0, 2, 2, -1.6), arc(2, 4, 2, -1.6), arc(4, 6, 2, -1.6)]
        case "g6-gcf": // two bars cut into the same pieces: 9 by 6
            return [box(0, 0, 6, 2), line((3, 0), (3, 2)), box(0, 4, 9, 2), line((3, 4), (3, 6)), line((6, 4), (6, 6))]
        case "g6-divide": // an amount, and pieces laid along under it, the last cut off at its end: 9 by 4
            return [box(0, 0, 8, 2), box(0, 2, 3, 2), box(3, 2, 3, 2), line((6, 2), (9, 2), (9, 4), (6, 4)), line((8, 2), (8, 4))]
        case "g6-longdiv", "g6-decdiv": // an amount in rows of 5, a short last row, and the bracket: 11 by 4 (a point under it)
            let rows = [line((0, 0), (5, 0), (5, 2), (3, 2), (3, 3), (0, 3), (0, 0)), line((0, 1), (5, 1)), line((0, 2), (3, 2))]
                + (1...4).map { x in line((Double(x), 0), (Double(x), x < 3 ? 3 : 2)) }
            let bracket = line((7, 4), (7.6, 2.6), (7.3, 1), (11, 1))
            if id == "g6-decdiv" { let pt = (0...12).map { k -> CGPoint in let a = Double(k) / 12 * 2 * .pi; return P(9 + 0.25 * cos(a), 3.3 + 0.25 * sin(a)) }; return rows + [bracket, pt] }
            return rows + [bracket]
        case "g6-decaddsub": // discs in place columns, the point's line between them, the line under: 11 by 6
            func disc(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.4 * cos(a), y + 0.4 * sin(a)) } }
            return [line((5, 0), (5, 6)), line((0, 5), (11, 5))] + [(1.0, 1.5), (2, 1.5), (3, 1.5), (7, 1.5), (1, 3.5), (7, 3.5), (8, 3.5), (9, 3.5)].map { disc($0.0, $0.1) }
        case "g6-decmult": // a number's digit tiles moved a column left of the point's line: 11 by 4
            return [box(1, 0, 3, 2), box(4, 0, 3, 2), line((7, 0), (7, 4)), line((8, 3), (10, 3)), line((8.6, 2.4), (8, 3), (8.6, 3.6)), box(4, 2, 3, 2)]
        case "g6-negatives": // an upright line through 0, a point under it and its opposite printed over it, the fold across 0: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.5 * cos(a), y + 0.5 * sin(a)) } }
            return [line((5, 0), (5, 6)), line((1, 3), (10, 3))] + [1.0, 2, 4, 5].map { y in line((4.6, y), (5.4, y)) } + [dot(5, 4.5), dot(5, 1.5)]
        case "g6-compare": // a line across with two points, the lesser on the left, and < between their names: 11 by 4
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.5 * cos(a), y + 0.5 * sin(a)) } }
            return [line((0, 2), (11, 2))] + [2.0, 5, 8].map { x in line((x, 1.6), (x, 2.4)) } + [dot(2, 2), dot(8, 2), line((6, 3.2), (5, 3.6), (6, 4))]
        case "g6-numline": // a line through 0, a bracket from a point to 0 and on to another: 11 by 4
            return [line((0, 3), (11, 3)), line((1, 2.5), (1, 1), (5, 1), (5, 2.5)), line((5, 2.5), (5, 0.5), (10, 0.5), (10, 2.5))]
                + [1.0, 5, 10].map { x in line((x, 2.6), (x, 3.4)) }
        case "g6-quadrants": // two axes crossing at 0, a point and its mirror over the x-axis: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.5 * cos(a), y + 0.5 * sin(a)) } }
            return [line((0, 3), (11, 3)), line((5.5, 0), (5.5, 6)), dot(2.5, 1), dot(2.5, 5)]
        case "g6-planeshapes": // two axes and a rectangle across the y-axis: 11 by 6
            return [line((0, 4), (11, 4)), line((5.5, 0), (5.5, 6)), box(2, 1, 6, 4)]
        case "g6-expo": // a square of 4 by 4 blocks, and a cube standing beside it: 11 by 6
            var parts: [[CGPoint]] = [box(0, 1, 4, 4)]
            for k in [1.0, 2, 3] { parts += [line((k, 1), (k, 5)), line((0, 1 + k), (4, 1 + k))] }
            let cube: [[CGPoint]] = [box(6, 2.5, 3, 3), line((6, 2.5), (7.5, 1), (10.5, 1), (9, 2.5)), line((10.5, 1), (10.5, 4), (9, 5.5))]
            return parts + cube
        case "g6-write": // an n strip, its end dashed, then squares laid after it: 11 by 4
            return [line((5, 2), (0, 2), (0, 4), (5, 4)), line((5, 2), (5, 2.6)), line((5, 3.4), (5, 4))]
                + [5.5, 7, 8.5].map { x in box(x, 2.5, 1.5, 1.5) }
        case "g6-eval": // three x rows stretched to the same length, their cells, and a y row striped: 11 by 6
            return [0.0, 1.5, 3].flatMap { y in [box(0, y, 4, 1)] + [1.0, 2, 3].map { x in line((x, y), (x, y + 1)) } } + [box(6, 0, 5, 1), box(6, 1.5, 5, 1)]
        case "g6-equiv": // rows of x and the number part, cut where x ends: 11 by 4
            return [box(0, 1, 6, 3), box(7, 1, 3, 3), line((0, 2), (6, 2)), line((0, 3), (6, 3)), line((7, 2), (10, 2)), line((7, 3), (10, 3)),
                    line((8, 1), (8, 4)), line((9, 1), (9, 4))]
        case "g6-onestep": // x and 3 cells over a bar of cells, its last 3 crossed off with them: 11 by 4
            return [box(0, 0, 5, 1.5)] + [5.0, 7, 9].map { x in box(x, 0, 2, 1.5) } + [box(0, 2.5, 11, 1.5)] + [5.0, 7, 9].map { x in line((x, 2.5), (x, 4)) }
                + [5.0, 7, 9].map { x in line((x + 0.4, 3.7), (x + 1.6, 2.8)) }
        case "g6-ineq": // a line, an open circle on it and the band running off its end: 11 by 4
            let circ = (0...16).map { k -> CGPoint in let a = Double(k) / 16 * 2 * .pi; return P(4 + 0.5 * cos(a), 2 + 0.5 * sin(a)) }
            return [line((0, 2), (3.5, 2)), circ, line((4.5, 2), (11, 2)), line((10.2, 1.2), (11, 2), (10.2, 2.8))] + [1.0, 2, 3, 5, 6, 7, 8, 9].map { x in line((x, 1.7), (x, 2.3)) }
        case "g6-depend": // two axes, the rule's line from 0 and its points at the stops: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.4 * cos(a), y + 0.4 * sin(a)) } }
            return [line((0, 0), (0, 6), (11, 6)), line((0, 6), (9, 0)), dot(3, 4), dot(6, 2)]
        case "g6-para": // a parallelogram cut straight down, its piece to slide to the other end: 11 by 4
            return [line((0, 4), (8, 4), (11, 0), (3, 0), (0, 4)), line((3, 0), (3, 4)), line((8, 4), (11, 4), (11, 0))]
        case "g6-tri": // a triangle and its turned copy, a rectangle together: 11 by 6
            return [line((0, 6), (10, 6), (10, 0), (0, 6)), line((0, 6), (0, 0), (10, 0))]
        case "g6-trap": // a trapezoid and its turned copy, a rectangle together: 11 by 4
            return [line((0, 0), (0, 4), (11, 4), (11, 0), (0, 0)), line((4, 4), (7, 0))]
        case "g6-poly": // an L cut into two rectangles: 11 by 6
            return [line((0, 0), (5, 0), (5, 2), (11, 2), (11, 6), (0, 6), (0, 0)), line((5, 2), (5, 6))]
        case "g6-nets": // a box's net: the strip of four sides, the top and bottom on one: 11 by 6
            return [box(0, 2, 11, 2), line((3, 2), (3, 4)), line((6, 2), (6, 4)), line((8, 2), (8, 4)), box(3, 0, 3, 2), box(3, 4, 3, 2)]
        case "g6-fracvol": // a box of small cubes standing, a whole one in its corner: 11 by 6
            return [box(1, 2, 6, 4), line((1, 2), (4, 0), (10, 0), (7, 2)), line((10, 0), (10, 4), (7, 6))]
                + [3.0, 5].map { x in line((x, 2), (x, 6)) } + [line((1, 4), (7, 4))] + [line((2.5, 1), (8.5, 1))]
        case "g6-dotplot": // dots stacked over a line with its ticks: 11 by 6
            func dot(_ x: Double, _ y: Double) -> [CGPoint] { (0...16).map { k in let a = Double(k) / 16 * 2 * .pi; return P(x + 0.5 * cos(a), y + 0.5 * sin(a)) } }
            var out: [[CGPoint]] = [line((0, 6), (11, 6))]
            for (x, n) in [(2.5, 2), (5.5, 4), (8.5, 1)] { for k in 0..<n { out.append(dot(x, 5.5 - Double(k))) } }
            return out
        case "g6-histogram": // bars side by side over an axis, counted up the side: 11 by 6
            return [line((0, 0), (0, 6), (11, 6)), box(1, 4, 2, 2), box(3, 2, 2, 4), box(5, 1, 2, 5), box(7, 3, 2, 3), box(9, 5, 2, 1)]
        case "g6-mean": // four bars and the level they share out to: 11 by 6
            return [line((0, 6), (11, 6)), box(0, 0, 2, 6), box(3, 4, 2, 2), box(6, 2, 2, 4), box(9, 2, 2, 4), line((0, 2), (11, 2))]
        case "g6-mad": // four bars and the mean's line across them: 11 by 6
            return [line((0, 6), (11, 6)), box(0, 1, 2, 5), box(3, 3, 2, 3), box(6, 0, 2, 6), box(9, 4, 2, 2), line((0, 2), (11, 2))]
        case "g6-median": // bars in order, crossed off from both ends, the middle one left: 11 by 6
            var out: [[CGPoint]] = [line((0, 6), (11, 6))]
            for (x, h) in [(1.0, 1.0), (3, 2), (5, 3), (7, 5), (9, 6)] { out.append(box(x, 6 - h, 1, h)); if x != 5 { out.append(line((x, 6), (x + 1, 6 - h))) } }
            return out
        case "g6-boxplot": // a box from one middle to the other, the median across it, whiskers to the ends: 11 by 6
            return [box(3, 1, 4, 4), line((5, 1), (5, 5)), line((0, 3), (3, 3)), line((7, 3), (11, 3)), line((0, 2), (0, 4)), line((11, 2), (11, 4))]
        case "g6-pctwhole": // a block, copies laid end to end with hops over them: 12 by 4
            return [box(0, 2, 3, 2), box(3, 2, 3, 2), box(6, 2, 3, 2), box(9, 2, 3, 2), arc(1.5, 4.5, 2, 1.5), arc(4.5, 7.5, 2, 1.5), arc(7.5, 10.5, 2, 1.5)]
        case "g4-tentimes": // a disk opening into a ten-frame: 11 by 4
            let disk = (0...24).map { k -> CGPoint in let a = Double(k) / 24 * 2 * .pi; return P(1 + cos(a), 2 + sin(a)) }
            return [disk, line((3, 2), (5, 2)), line((4.5, 1.5), (5, 2), (4.5, 2.5)), box(6, 1, 5, 2), line((6, 2), (11, 2))]
                + (7...10).map { x in line((Double(x), 1), (Double(x), 3)) }
        case "g4-readwrite": // a number's digits, a comma after the thousands: 11 by 2
            return [box(0, 0, 2, 2), box(2, 0, 2, 2), line((4.5, 1.6), (4.2, 2.4)), box(5, 0, 2, 2), box(7, 0, 2, 2), box(9, 0, 2, 2)]
        case "g4-compare": // a longer number over a shorter one, lined up on the right: 11 by 4
            return [3, 5, 7, 9].map { box(Double($0), 0, 2, 2) } + [5, 7, 9].map { box(Double($0), 2, 2, 2) } + [line((0, 1), (2, 2), (0, 3))]
        case "g4-placevalue": // a number line in blocks and a hop down to the round number: 11 by 4
            var out: [[CGPoint]] = [line((0, 4), (11, 4))]
            for i in [0.0, 5, 10] { out.append(line((i, 3), (i, 4))) }
            out.append(arc(3, 0, 4, 2))
            return out
        case "g4-addsub": // two numbers in columns, and the line under them: 9 by 4
            return [1, 3, 5, 7].flatMap { x in [box(Double(x), 0, 2, 2), box(Double(x), 2, 2, 2)] } + [line((0, 4), (9, 4))]
        case "g4-times": // Red, and Blue three copies of it: 9 by 6
            return [box(0, 0, 3, 2)] + bar(0, 4, 9, 3)
        case "g4-partial": // a row of a number's places, copied down: 11 by 6
            return [box(0, 0, 11, 6), line((0, 2), (11, 2)), line((0, 4), (11, 4)), line((3, 0), (3, 6)), line((7, 0), (7, 6))]
        case "g4-mult2x2": // a rectangle cut both ways where the tens end: 9 by 6
            return [box(0, 0, 9, 6), line((6, 0), (6, 6)), line((0, 4), (9, 4))]
        case "g4-divide", "g4-share": // a frame on top, dealt into three rows: 9 by 6
            return [box(0, 0, 9, 2), line((0, 3), (9, 3)), line((0, 4), (9, 4)), line((0, 5), (9, 5)), line((0, 6), (9, 6))]
        case "g4-multistep": // three groups, and a part taken off the end: 9 by 6
            return bar(0, 0, 9, 3) + [box(0, 4, 9, 2), line((6, 4), (6, 6))]
        case "g4-factors": // 12 squares as 2 rows of 6, and as 3 rows of 4: 6 by 6
            return [box(0, 0, 6, 2), line((0, 1), (6, 1))] + (1...5).map { x in line((Double(x), 0), (Double(x), 2)) }
                + [box(0, 3, 4, 3), line((0, 4), (4, 4)), line((0, 5), (4, 5))] + (1...3).map { x in line((Double(x), 3), (Double(x), 6)) }
        case "g4-prime": // 11 squares in one long row, and two rows of 5 with one over: 11 by 6
            return [box(0, 0, 11, 1)] + (1...10).map { x in line((Double(x), 0), (Double(x), 1)) }
                + [box(0, 3, 5, 2), line((0, 4), (5, 4))] + (1...4).map { x in line((Double(x), 3), (Double(x), 5)) } + [box(0, 5, 1, 1)]
        case "g4-patterns": // towers growing by 2: 9 by 6
            return [box(0, 4, 1, 2), line((0, 5), (1, 5)), box(4, 2, 1, 4)] + (3...5).map { y in line((4, Double(y)), (5, Double(y))) }
                + [box(8, 0, 1, 6)] + (1...5).map { y in line((8, Double(y)), (9, Double(y))) }
        case "g4-decompose": // eighths, parted into three pieces: 8 by 2 (a square between)
            return [box(0, 0, 2, 2), box(3, 0, 2, 2), box(6, 0, 2, 2)]
        case "g4-equiv": // halves, and the same half cut into eighths: 9 by 6
            return bar(0, 0, 9, 2) + [box(0, 4, 9, 2)] + (1..<8).map { i in let x = 9 * Double(i) / 8; return line((x, 4), (x, 6)) }
        case "g4-fraccompare": // thirds over fourths: 9 by 6
            return bar(0, 0, 9, 3) + [box(0, 4, 9, 2)] + (1..<4).map { i in let x = 9 * Double(i) / 4; return line((x, 4), (x, 6)) }
        case "g4-likefrac": // sixths and sixths, put together: 9 by 6
            return bar(0, 0, 9, 3) + bar(0, 4, 9, 3)
        case "g4-likesub": // sixths, the last two crossed out: 9 by 2
            return bar(0, 0, 9, 6) + [line((6.3, 1.7), (7.2, 0.3)), line((7.8, 1.7), (8.7, 0.3))]
        case "g4-mixed": // two wholes and a part on the left, a whole and a part on the right: 9 by 6
            return [box(0, 0, 4, 1), box(0, 2, 4, 1)] + bar(0, 4, 4, 4) + [box(5, 0, 4, 1)] + bar(5, 2, 4, 4)
        case "g4-mixedsub": // the same, the right's whole crossed out: 9 by 6
            return [box(0, 0, 4, 1), box(0, 2, 4, 1)] + bar(0, 4, 4, 4) + [box(5, 0, 4, 1), line((5.3, 0.8), (8.7, 0.2))] + bar(5, 2, 4, 4)
        case "g4-fracwhole": // two groups of two fourths, packed into one bar: 9 by 5
            return bar(0, 0, 4, 4) + bar(0, 3, 4, 4) + bar(5, 0, 4, 4)
        case "g4-dec", "g4-deccompare": // two wholes cut into tenths (with < between when they're compared): 9 or 11 by 4
            let x2 = id == "g4-dec" ? 5.0 : 7.0
            var out: [[CGPoint]] = [box(0, 0, 4, 4), box(x2, 0, 4, 4)]
            for x in [0.0, x2] { for i in 1...3 { out.append(line((x + Double(i), 0), (x + Double(i), 4))) } }
            if id == "g4-deccompare" { out.append(line((6, 1), (5, 2), (6, 3))) }
            return out
        case "g4-decline": // a line of tenths, one opened below into hundredths: 11 by 6
            var out: [[CGPoint]] = []
            for y in [1.0, 5] {
                out.append(line((0, y), (11, y))); out.append(line((10.5, y - 0.5), (11, y), (10.5, y + 0.5)))
                for i in 0...10 { let tall = i % 5 == 0; out.append(line((Double(i), y - (tall ? 1 : 0.5)), (Double(i), y + (tall ? 1 : 0.5)))) }
            }
            return out + [line((6, 2), (0, 4)), line((7, 2), (10, 4))]
        case "g4-convert": // two feet as bars, the first cut into inches: 9 by 6
            return bar(0, 0, 9, 6) + [box(0, 4, 9, 2)]
        case "g4-measure": // a line with a long tick each hour and two hops along it: 11 by 4
            var out: [[CGPoint]] = [line((0, 4), (11, 4))]
            for i in 0...11 { let big = i % 5 == 0; out.append(line((Double(i), big ? 3.4 : 3.7), (Double(i), big ? 4.6 : 4.3))) }
            return out + [arc(1, 6, 4, 2.5), arc(6, 9, 4, 1.8)]
        case "g4-area": // a rectangle of square meters, 3 by 2, its edge: 9 by 6
            return [box(0, 0, 9, 6), line((3, 0), (3, 6)), line((6, 0), (6, 6)), line((0, 3), (9, 3))]
        case "g4-lineplot": // X's stacked over a line with its ticks: 11 by 6
            var out: [[CGPoint]] = [line((0, 5), (11, 5))]
            for i in 0...4 { let x = 0.5 + 2.5 * Double(i); out.append(line((x, 5), (x, 6))) }
            for (x, n) in [(3.0, 2), (5.5, 3), (8.0, 1)] {
                for k in 0..<n { let y = 4.5 - 1.5 * Double(k); out.append(line((x - 0.5, y - 0.5), (x + 0.5, y + 0.5))); out.append(line((x - 0.5, y + 0.5), (x + 0.5, y - 0.5))) }
            }
            return out
        case "g4-lines": // a ray: an endpoint, a point on it, an arrowhead: 11 by 2
            let dot = (0...16).map { k -> CGPoint in let a = Double(k) / 16 * 2 * .pi; return P(0.5 + 0.5 * cos(a), 1 + 0.5 * sin(a)) }
            return [dot, line((1, 1), (11, 1)), line((10, 0), (11, 1), (10, 2)), line((6, 0.6), (6, 1.4))]
        case "g4-turns": // a circle, a fixed arm and an arm turned a quarter of the way round: 6 by 6
            let ring = (0...32).map { k -> CGPoint in let a = Double(k) / 32 * 2 * .pi; return P(3 + 3 * cos(a), 3 + 3 * sin(a)) }
            return [ring, line((3, 3), (6, 3)), line((3, 3), (3, 0))]
        case "g4-protractor": // a protractor on an angle: its half circle, its ticks, the arm it reads: 9 by 5
            let half = (0...24).map { k -> CGPoint in let a = Double(k) / 24 * .pi; return P(4.5 + 4.5 * cos(a), 5 - 4.5 * sin(a)) }
            var out: [[CGPoint]] = [half + [P(9, 5)], line((4.5, 5), (4.5 + 5 * cos(50 * .pi / 180), 5 - 5 * sin(50 * .pi / 180)))]
            for d in stride(from: 30.0, to: 180, by: 30) { let a = d * .pi / 180; out.append(line((4.5 + 4.5 * cos(a), 5 - 4.5 * sin(a)), (4.5 + 3.8 * cos(a), 5 - 3.8 * sin(a)))) }
            return out
        case "g4-angles": // a square corner with a part inside it: 9 by 6
            return [line((0, 0), (0, 6), (9, 6)), line((0, 6), (9 * cos(35 * .pi / 180) * 0.95, 6 - 9 * sin(35 * .pi / 180) * 0.95)), line((0, 5), (1, 5), (1, 6))]
        case "g4-classify": // a shape beside two overlapping loops: 11 by 6
            func loop(_ cx: Double) -> [CGPoint] { (0...32).map { k in let a = Double(k) / 32 * 2 * .pi; return P(cx + 2.5 * cos(a), 3 + 2.6 * sin(a)) } }
            return [line((0, 1), (3, 1), (3, 5), (0, 5), (0, 1)), loop(6.5), loop(8.5)]
        case "g4-symmetry": // a triangle with its line of symmetry: 9 by 6
            return [line((4.5, 0), (9, 6), (0, 6), (4.5, 0)), line((4.5, 0), (4.5, 6))]
        case "g5-volume": // a box of cubes, 4 by 3 by 2, as the lesson shows it
            return box3D(l: 4, h: 2, w: 3, u: 32)
        case "add": // thirds and thirds, added: 9 by 6
            return bar(0, 0, 9, 3) + bar(0, 4, 9, 3)
        case "sub": // thirds over ninths: 9 by 6
            return bar(0, 0, 9, 3) + bar(0, 4, 9, 9)
        case "mix": // thirds, ninths, thirds: 9 by 8
            return bar(0, 0, 9, 3) + bar(0, 3, 9, 9) + bar(0, 6, 9, 3)
        case "g5-improper": // two wholes and a third, each cut into fourths: 9 by 6
            return bar(0, 0, 4, 4) + bar(5, 0, 4, 4) + bar(0, 4, 4, 4)
        case "g5-fracof": // a bar cut into thirds, and two of them bracketed: 9 by 4
            return bar(0, 0, 9, 3) + [line((0, 3), (0, 4), (6, 4), (6, 3))]
        case "g5-multfrac": // a rectangle cut into rows and columns: 9 by 6
            return [box(0, 0, 9, 6), line((3, 0), (3, 6)), line((6, 0), (6, 6)), line((0, 2), (9, 2)), line((0, 4), (9, 4))]
        case "g5-unitdiv": // three wholes, each cut into thirds: 11 by 2
            return bar(0, 0, 3, 3) + bar(4, 0, 3, 3) + bar(8, 0, 3, 3)
        case "g5-pow10", "g5-divdec": // digit boxes and the point hopping right over one: 11 by 4
            return (0..<4).map { i in box(Double(i) * 3, 2, 2, 2) } + [arc(2.5, 5.5, 2, 2)]
        case "g5-round": // tenths on a number line and a hop up to the next whole: 11 by 4
            var out: [[CGPoint]] = [line((0, 3), (11, 3)), line((10.5, 2.5), (11, 3), (10.5, 3.5))]
            for i in [0.0, 5, 10] { out.append(line((i, 2), (i, 4))) }
            for i in 1..<10 where i != 5 { out.append(line((Double(i), 2.5), (Double(i), 3.5))) }
            out.append(arc(7, 10, 2, 2))
            return out
        case "g5-compare": // 5 > 49 (0.5 > 0.49): a digit box, the sign, two digit boxes: 11 by 2
            return [box(0, 0, 2, 2), line((3, 0), (5, 1), (3, 2)), box(6, 0, 2, 2), box(9, 0, 2, 2)]
        case "g5-fracdiv": // two things cut into thirds, and one friend's share slid together under them: 9 by 8
            return bar(0, 0, 9, 3) + bar(0, 3, 9, 3) + bar(0, 6, 9, 3)
        case "g5-adddec": // two numbers lined up at the point, and the line under them: 9 by 6
            var out: [[CGPoint]] = []
            for j in 0..<2 { for x in [1.0, 3, 6] { out.append(box(x, Double(j) * 3, 2, 2)) } }
            out.append(line((0, 6), (9, 6)))
            return out
        case "g5-multdec", "g5-mult2": // an area model: a rectangle split into parts: 9 by 6
            return [box(0, 0, 9, 6), line((6, 0), (6, 6))] + (id == "g5-multdec" ? [line((0, 4), (9, 4))] : [])
        case "g5-divide": // the long division bracket, and the number under it: 9 by 4
            return [line((0, 0), (9, 0)), line((0, 0), (1, 2), (0, 4)), line((3, 2), (7, 2))]
        case "g5-order": // parentheses around two numbers: 9 by 4
            return [line((1, 0), (0, 2), (1, 4)), line((8, 0), (9, 2), (8, 4)), box(2, 1, 2, 2), box(5, 1, 2, 2)]
        case "g5-units": // a ruler: 9 by 2
            var out: [[CGPoint]] = [box(0, 0, 9, 2)]
            for i in 1..<9 { out.append(line((Double(i), 0), (Double(i), i % 4 == 0 ? 1.5 : 0.75))) }
            return out
        case "g5-coord": // the two edges of the grid, the walk up from the bottom, and the point: 9 by 6
            return [line((0, 0), (0, 6), (9, 6)), line((6, 6), (6, 3)), box(5, 1, 2, 2)]
        case "g5-shapes": // a parallelogram, its corners on the grid: 9 by 4
            return [line((2, 0), (9, 0), (7, 4), (0, 4), (2, 0))]
        default:
            return [box(0, 0, 9, 6)]
        }
    }

    var outline: [[CGPoint]] {
        [[CGPoint(x: at.x, y: at.y), CGPoint(x: at.x + Piece.size.width, y: at.y), CGPoint(x: at.x + Piece.size.width, y: at.y + Piece.size.height),
          CGPoint(x: at.x, y: at.y + Piece.size.height), CGPoint(x: at.x, y: at.y)]]
    }
}

/// A draw-in amount rounded to one of `steps` steps. Drawn with the same value its cache key holds, so the last step
/// is drawn whole: drawing the unrounded value left a gap where an outline was cached just short of finishing.
func snapped(_ k: Double, _ steps: Double) -> Double { (k * steps).rounded() / steps }

/// The first `k` (0...1) of some lines, by length, as world segments (paper points / one big square).
func drawn(_ lines: [[CGPoint]], _ k: Double) -> [(SIMD2<Float>, SIMD2<Float>)] {
    var segs: [(CGPoint, CGPoint)] = []
    for l in lines { for i in 1..<l.count { segs.append((l[i - 1], l[i])) } }
    let total = segs.reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
    var left = total * min(1, max(0, k))
    var out: [(SIMD2<Float>, SIMD2<Float>)] = []
    func w(_ p: CGPoint) -> SIMD2<Float> { SIMD2(Float(p.x / Paper.unit), Float(p.y / Paper.unit)) }
    for (a, b) in segs where left > 0.01 {
        let len = hypot(b.x - a.x, b.y - a.y), f = min(1, left / len)
        out.append((w(a), w(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))))
        left -= len
    }
    return out
}

@MainActor
final class Rig {
    let root = Entity()
    let camera = Entity()
    let sheet = ModelEntity()
    var grid = Entity()
    var gridAt: (x: Int, z: Int, half: Int)?
    let pieces = Entity()
    var piecesKey = ""
    // the map's words, in the scene (PaperWords.swift)
    let words = Entity()
    var mapDrawer: SketchDrawer?
    // a place of its own instead of the map: Me, or the grown-ups' page (Places.swift)
    let placeRoot = Entity()
    var placeDrawer: SketchDrawer?
    /// Some problem's picture or words are still to be made.
    var pageBuilding = false
    var piecesQuick = ""
    var pieceGroups: [String: ModelEntity] = [:]
    /// Each Volume of a box problem's box of cubes on a lesson's page, with its standing words (CubesDrawer, CubesWords).
    var problemCubes: [UUID: (cubes: CubesDrawer, words: CubesWords)] = [:]
    /// The view this frame is seen through, and the screen.
    var view = PaperView3D()
    var screen = Size(1180, 820)
    // the flat lesson
    let barsRoot = Entity()
    var sketches: [UUID: SketchDrawer] = [:]
    /// A paper lesson's solids, by problem (PaperStand.swift).
    var solids: [UUID: SolidsDrawer] = [:]
    /// What the camera last framed a problem's content for.
    var contentKey = ""
    /// The blinking cursor in the answer box being typed into.
    let cursorEntity = ModelEntity()
    var cursorKey = ""
    /// The page of problems' cards (PageCards).
    let cardsRoot = Entity()
    var cardsDrawer: SketchDrawer?
    var paperHex: UInt32 = 0xF3F2EF
    var lineScale: Double = 0
    var dark: Bool?
    var colours = Colours(dark: false, chapter: Chapter.measurement.hex)


    struct Colours {
        let paper, minor, major, top, front, side, deep, square, ink, ink2, lineStrong, pencil: UIColor
        init(dark: Bool, chapter c: UInt32) {
            let surf: UInt32 = dark ? 0x1B1B1A : 0xFBFBFA, ink: UInt32 = dark ? 0xECEBE7 : 0x1A1A19
            let paper: UInt32 = dark ? 0x121211 : 0xF3F2EF
            func m(_ a: UInt32, _ b: UInt32, _ k: Double) -> UIColor { UIColor(hex: Ink.mix(a, b, k)) }
            self.paper = UIColor(hex: paper)
            minor = m(paper, ink, dark ? 0.035 : 0.045); major = m(paper, ink, dark ? 0.07 : 0.09)
            top = m(surf, c, dark ? 0.32 : 0.30); front = m(surf, c, dark ? 0.42 : 0.42); side = m(surf, c, dark ? 0.52 : 0.55)
            deep = dark ? m(c, 0xFFFFFF, 0.25) : m(c, ink, 0.35); square = m(surf, c, dark ? 0.38 : 0.35)
            self.ink = UIColor(hex: ink); ink2 = UIColor(hex: dark ? 0xA3A19B : 0x6B6964)
            lineStrong = UIColor(hex: dark ? 0x3A3A37 : 0xCFCCC5); pencil = UIColor(hex: dark ? 0x3D3C39 : 0xCFCCC5)
        }
    }

    func build(into content: inout RealityViewCameraContent) {
        camera.components.set(PerspectiveCameraComponent())
        content.add(camera)
        content.add(root)
        // the paper itself, under the grid, large enough to fill any tilted view; it follows the camera
        sheet.model = ModelComponent(mesh: .generatePlane(width: 400, depth: 400), materials: [])
        sheet.position.y = -0.003
        root.addChild(sheet); root.addChild(pieces); root.addChild(barsRoot); barsRoot.addChild(cardsRoot); barsRoot.addChild(cursorEntity); root.addChild(words); root.addChild(placeRoot)
    }

    func update(view v: PaperView3D, model: PaperModel, time t: Double, dark: Bool) {
        if dark != self.dark { recolour(dark) }
        let screen = model.screen
        self.view = v; self.screen = screen

        // seen with perspective (PaperView3D): the eye a set distance back through the lens that keeps the target's
        // plane at the view's scale; looking straight down, that plane is the paper, so flat it lines up exactly
        let (_, _, up) = v.axes, eye = v.eye(screen: screen)
        let target = SIMD3<Float>(Float(v.target.x), Float(v.target.y), Float(v.target.z))
        camera.look(at: target, from: SIMD3(Float(eye.x), Float(eye.y), Float(eye.z)), upVector: SIMD3(Float(up.x), Float(up.y), Float(up.z)), relativeTo: nil)
        let dist = v.distance(screen: screen)
        camera.components.set(PerspectiveCameraComponent(near: Float(max(0.05, dist / 400)), far: Float(dist + 600), fieldOfViewInDegrees: Float(v.fieldOfView(screen: screen))))

        let floor = v.floorTarget
        sheet.position.x = Float(floor.x); sheet.position.z = Float(floor.z)

        // lines keep their screen width at any zoom
        if lineScale == 0 || abs(v.scale / lineScale - 1) > 0.05 { lineScale = v.scale; gridAt = nil; piecesKey = "" }
        // enough grid to fill the screen even when tilted, centred on a strong line near the middle
        // (tilted with perspective, the far side of the screen shows more paper: half as much again)
        let half = min(120, Int((hypot(screen.width, screen.height) / 2 / v.scale / sin(.pi / 4) * 1.5).rounded(.up)) + 3)
        let gx = Int(floor.x.rounded()), gz = Int(floor.z.rounded())
        if let g = gridAt, abs(g.x - gx) <= 2, abs(g.z - gz) <= 2, g.half >= half {} else { Perf.time("grid") { regrid(x: gx, z: gz, half: half) } }

        let onMap = model.bars == nil && model.place == nil
        pieces.isEnabled = onMap; words.isEnabled = onMap
        if onMap { Perf.time("pieces") { drawPieces(model, at: t) }; Perf.time("words") { drawWords(model, at: t) } }
        // off the map (a lesson or a place open) its words aren't updated, so they can't say they're still drawing: the
        // clock that waited on them stops (it ran at 60 fps through every lesson, 25 Oct)
        else if model.mapDrawing { Task { @MainActor in model.setMapDrawing(false) } }
        Perf.time("place") { drawPlace(model, at: t) }
        drawPage(model.bars, at: t)
    }

    private func recolour(_ dark: Bool) {
        mapDrawer?.key = ""; placeDrawer?.key = ""; placeDrawer?.live.key = ""
        self.dark = dark
        colours = Colours(dark: dark, chapter: Chapter.measurement.hex)
        paperHex = dark ? 0x121211 : 0xF3F2EF
        sheet.model?.materials = [flat(colours.paper)]
        gridAt = nil; piecesKey = ""
    }

    // MARK: the paper

    private func regrid(x cx: Int, z cz: Int, half n: Int) {
        gridAt = (cx, cz, n)
        grid.removeFromParent(); grid = Entity()
        let px = Float(1 / lineScale)
        var minor: [(SIMD2<Float>, SIMD2<Float>)] = [], major: [(SIMD2<Float>, SIMD2<Float>)] = []
        let x0 = Float(cx - n), x1 = Float(cx + n), z0 = Float(cz - n), z1 = Float(cz + n)
        for i in -n * Paper.major...n * Paper.major {
            let d = Float(i) / Float(Paper.major)
            let lines = [(SIMD2(Float(cx) + d, z0), SIMD2(Float(cx) + d, z1)), (SIMD2(x0, Float(cz) + d), SIMD2(x1, Float(cz) + d))]
            if i % Paper.major == 0 { major += lines } else { minor += lines }
        }
        if let m = Self.lines(minor, width: px) { grid.addChild(ModelEntity(mesh: m, materials: [flat(colours.minor)])) }
        if let m = Self.lines(major, width: px) {
            let e = ModelEntity(mesh: m, materials: [flat(colours.major)]); e.position.y = 0.0005; grid.addChild(e)
        }
        root.addChild(grid)
    }

    /// Each lesson's frame and picture, drawn in as far as it has got; rebuilt only when something changed.
    private func drawPieces(_ model: PaperModel, at t: Double) {
        // one mesh per colour and line width (frames, the chosen frame, each chapter's pictures, pencil), so drawing in
        // or zooming rebuilds a handful of meshes, not two per lesson
        let px = 1 / lineScale
        // once the drawings have drawn in, only a new choice, zoom or learned lesson changes them: skip the rest
        let gone = snapped(model.mapGone(at: t), 40)
        let settled = t - model.drawnAt > Piece.drawTime + 1, quick = "\(Map.grade) \(model.selected?.id ?? "") \(lineScale) \(Progress.shared.checks.count) \(gone) \(Store.shared.hasAllGrades)"
        if settled, quick == piecesQuick, !piecesKey.isEmpty { return }
        piecesQuick = settled ? quick : ""
        let now = Map.shown.map { p in (p, snapped(Piece.drawIn(p, time: t, drawnAt: model.drawnAt, from: model.drawFrom), 400) * gone, model.selected?.id == p.id, p.state) }
        let key = now.map { "\($0.0.id) \($0.1) \($0.2) \($0.3) \($0.0.locked)" }.joined(separator: ",")
        guard key != piecesKey else { return }
        piecesKey = key
        var groups: [String: (colour: UIColor, width: Double, y: Float, segs: [(SIMD2<Float>, SIMD2<Float>)])] = [:]
        func add(_ id: String, _ c: UIColor, _ w: Double, _ y: Float, _ segs: [(SIMD2<Float>, SIMD2<Float>)]) {
            groups[id, default: (c, w, y, [])].segs += segs
        }
        var tints: [String: (colour: UIColor, rects: [CGRect])] = [:]
        for (p, k, on, state) in now {
            let hex = (dark ?? false) ? p.chapter.darkHex : p.chapter.hex
            // the chosen lesson, and the one up next, are outlined in their chapter's colour
            let lit = on || state == .now
            // the others' frames are their chapter's colour too, lighter: no grey on the map
            let frameColour = lit ? UIColor(hex: hex) : UIColor(hex: Ink.mix(paperHex, hex, 0.3))
            // a test still waiting is a dashed frame: there, but not open yet
            let locked = (p.isTest && !p.opens && state != .learned) || p.locked || p.coming
            add("frame-\(p.chapter.rawValue)-\(lit)-\(on)", frameColour, on ? 2 : 1.5, 0.001, drawn(locked ? Self.dashes(p.outline) : p.outline, k))
            // a light fill in the chapter's colour, coming in with the drawing
            let strength = (k * 10).rounded() / 10 * 0.1
            if strength > 0 {
                let id = "tint-\(p.chapter.rawValue)-\(strength)"
                tints[id, default: (UIColor(hex: Ink.mix(paperHex, hex, strength)), [])].rects.append(CGRect(x: p.at.x, y: p.at.y, width: Piece.size.width, height: Piece.size.height))
            }
            // a lesson not yet open is drawn in its chapter's colour, lightened, instead of grey pencil (G 17 Oct)
            if state == .notYet { add("light-\(p.chapter.rawValue)", UIColor(hex: Ink.mix(paperHex, hex, 0.4)), 2.5, 0.0015, drawn(p.strokes, k)) }
            else { add("chapter-\(p.chapter.rawValue)", UIColor(hex: hex), 2.5, 0.0015, drawn(p.strokes, k)) }
        }
        // the soft fills inside the pictures, a little stronger than the frame's tint, coming in with the drawing
        var softFills: [String: (colour: UIColor, polys: [[CGPoint]])] = [:]
        for (p, k, _, state) in now where k > 0.3 {
            let strength = state == .notYet ? 0.26 : 0.42, id = "soft-\(p.chapter.rawValue)-\(strength)"
            softFills[id, default: (UIColor(hex: Ink.mix(paperHex, (dark ?? false) ? p.chapter.darkHex : p.chapter.hex, strength)), [])].polys += p.softs
        }
        for (id, f) in softFills {
            let e = pieceGroups[id] ?? { let e = ModelEntity(); pieces.addChild(e); pieceGroups[id] = e; return e }()
            e.position.y = 0.0008
            set(e, Self.polygons(f.polys), f.colour)
        }
        for (id, e) in pieceGroups where groups[id] == nil && tints[id] == nil && softFills[id] == nil { e.isEnabled = false }
        for (id, t) in tints {
            let e = pieceGroups[id] ?? { let e = ModelEntity(); pieces.addChild(e); pieceGroups[id] = e; return e }()
            e.position.y = 0.0003  // under the strong lines, like the floor squares
            set(e, Self.fills(t.rects), t.colour)
        }
        for (id, g) in groups {
            let e = pieceGroups[id] ?? { let e = ModelEntity(); pieces.addChild(e); pieceGroups[id] = e; return e }()
            e.position.y = g.y
            set(e, Self.lines(g.segs, width: Float(g.width * px)), g.colour)
        }
    }

    private func set(_ e: ModelEntity, _ mesh: MeshResource?, _ c: UIColor) {
        guard let mesh else { e.isEnabled = false; return }
        e.model = ModelComponent(mesh: mesh, materials: [flat(c)]); e.isEnabled = true
    }

    // MARK: the flat lesson

    /// A lesson's page: one drawer per problem (and the How to), each with its own picture and words.
    private func drawPage(_ page: BarsPage?, at t: Double) {
        barsRoot.isEnabled = page != nil
        guard let page else {
            for d in sketches.values { d.root.removeFromParent() }
            sketches = [:]
            for d in solids.values { d.clear() }
            solids = [:]
            drawCards(nil, at: t)
            clearCubesProblems(keeping: []); return
        }
        let shown = page.all, every = page.all + (page.howToGone ? [] : page.problems)
        pageBuilding = false
        defer { let b = pageBuilding; Task { @MainActor in page.setBuilding(b) } }
        // the problems' bars are built one a frame while the How to plays, unseen (they haven't grown in), so nothing
        // is built when they arrive (building all 17 at once stalled a frame for 170 ms; 16 as they arrived, 80 ms)
        var made = 0
        for m in every {
            // Volume of a box: its cubes and its standing words, only while it's on the paper (CubesWords.swift)
            if let c = m as? CubesProblem { if shown.contains(where: { $0 === c }) { drawCubesProblem(c, at: t) }; continue }
            if sketches[m.id] == nil {
                if made >= 1 && !page.instant && m !== page.howTo { pageBuilding = true; continue }
                made += 1
            }
            if let w = m as? WorkProblem {
                let d = sketches[m.id] ?? { let d = SketchDrawer(); barsRoot.addChild(d.root); sketches[m.id] = d; return d }()
                if drawWork(w, page, into: d, at: t) { pageBuilding = true }
            }
        }
        for (id, d) in sketches where !every.contains(where: { $0.id == id }) { d.root.removeFromParent(); sketches[id] = nil }
        for (id, d) in solids where !every.contains(where: { $0.id == id }) { d.clear(); solids[id] = nil }
        clearCubesProblems(keeping: shown)
        frameContent(page)
        if drawCards(page, at: t) { pageBuilding = true }
        drawCursor(page, at: t)
    }

    /// The cursor in the box being typed into (G 19 Oct): a thin line that blinks as a cursor does, held still for a
    /// moment after each key, once the problem has drawn in.
    private func drawCursor(_ page: BarsPage, at t: Double) {
        guard page.mode == .work, let m = page.current as? WorkProblem, t - m.openedAt > 1.2, let r = ProblemLayout.cursor(m) else {
            cursorEntity.isEnabled = false; return
        }
        let key = "\(r) \(dark ?? false)"
        if key != cursorKey {
            cursorKey = key
            let u = Paper.unit, w = Sketch.stroke * m.scale
            cursorEntity.model = Self.lines([(SIMD2(Float(r.minX / u), Float(r.minY / u)), SIMD2(Float(r.minX / u), Float(r.maxY / u)))], width: Float(w / u))
                .map { ModelComponent(mesh: $0, materials: [flat(colours.ink)]) }
            cursorEntity.position.y = 0.0027
        }
        let since = t - m.typedAt
        cursorEntity.isEnabled = Blink.on(since: since)
        // on the words' board while the paper stands
        let local = Transform(translation: SIMD3(0, 0.0027, 0))
        let b = (m as? WorkProblem)?.board(view, screen: screen)
        cursorEntity.transform = b.map { Transform(matrix: $0.matrix * local.matrix) } ?? local
    }

    /// The camera frames what's on the paper (G 19 Oct): the problem's picture and words as they are now, so when a
    /// step adds something the paper eases out to fit it as it draws in, and eases back in when something goes.
    private func frameContent(_ page: BarsPage) {
        guard let m = page.mode == .work ? page.current : (page.howToGone ? nil : page.howTo) else { contentKey = ""; return }
        // a lesson on the paper frames its plan's rectangle for the step it's on (G 20 Oct), not what's drawn, and holds
        // still while a hand drags on it
        if let w = m as? WorkProblem, let r = w.stageFrame {
            guard !w.dragging else { return }
            let key = "\(m.id) \(r)"
            guard key != contentKey else { return }
            contentKey = key
            Task { @MainActor in page.contentChanged(r) }
            return
        }
        let key = "\(m.id) \(sketches[m.id]?.key ?? "")"
        guard key != contentKey else { return }
        contentKey = key
        let u = Paper.unit
        var r: CGRect?
        for e in [sketches[m.id]?.root].compactMap({ $0 }) {
            let b = e.visualBounds(recursive: true, relativeTo: barsRoot, excludeInactive: false)
            guard !b.isEmpty else { continue }
            let rr = CGRect(x: Double(b.min.x) * u, y: Double(b.min.z) * u, width: Double(b.max.x - b.min.x) * u, height: Double(b.max.z - b.min.z) * u)
            r = r.map { $0.union(rr) } ?? rr
        }
        if let r { Task { @MainActor in page.contentChanged(Rect(x: r.minX, y: r.minY, width: r.width, height: r.height)) } }
    }

    /// Lines broken into dashes, a cell's half on and half off.
    static func dashes(_ lines: [[CGPoint]]) -> [[CGPoint]] {
        lines.flatMap { pts in zip(pts, pts.dropFirst()).flatMap { a, b -> [[CGPoint]] in
            let len = hypot(b.x - a.x, b.y - a.y), n = max(1, Int(len / 10))
            return (0..<n).compactMap { i in
                guard i % 2 == 0 else { return nil }
                let f0 = Double(i) / Double(n), f1 = Double(i + 1) / Double(n)
                return [CGPoint(x: a.x + (b.x - a.x) * f0, y: a.y + (b.y - a.y) * f0), CGPoint(x: a.x + (b.x - a.x) * f1, y: a.y + (b.y - a.y) * f1)]
            }
        } }
    }

    /// Filled shapes on the paper, each closed and convex (a fan from its first corner).
    static func polygons(_ polys: [[CGPoint]]) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let u = Paper.unit
        for poly in polys where poly.count >= 3 {
            let base = UInt32(pos.count)
            pos += poly.map { SIMD3(Float($0.x / u), 0, Float($0.y / u)) }
            for i in 1..<(poly.count - 1) {
                let a = base, b = base + UInt32(i), c = base + UInt32(i + 1)
                idx += [a, b, c, a, c, b]
            }
        }
        guard !pos.isEmpty else { return nil }
        var d = MeshDescriptor(name: "polygons")
        d.positions = MeshBuffers.Positions(pos)
        d.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [d])
    }

    static func fills(_ rects: [CGRect]) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        let u = Paper.unit
        for r in rects {
            let base = UInt32(pos.count)
            pos += [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
                .map { SIMD3(Float($0.x / u), 0, Float($0.y / u)) }
            idx += [base, base + 1, base + 2, base, base + 2, base + 3, base, base + 2, base + 1, base, base + 3, base + 2]
        }
        guard !pos.isEmpty else { return nil }
        var desc = MeshDescriptor(name: "fills")
        desc.positions = MeshBuffers.Positions(pos)
        desc.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [desc])
    }

    /// Flat bars on the paper, one quad per line, facing up.
    static func lines(_ segs: [(SIMD2<Float>, SIMD2<Float>)], width: Float) -> MeshResource? {
        var pos: [SIMD3<Float>] = [], idx: [UInt32] = []
        for (a, b) in segs where simd_distance(a, b) > 0 {
            let d: SIMD2<Float> = simd_normalize(b - a)
            let half: Float = width / 2
            let nrm: SIMD2<Float> = SIMD2<Float>(-d.y, d.x) * half
            let ext: SIMD2<Float> = d * half
            let a0: SIMD2<Float> = a - ext, b0: SIMD2<Float> = b + ext
            let p: [SIMD2<Float>] = [a0 + nrm, b0 + nrm, b0 - nrm, a0 - nrm]
            let base = UInt32(pos.count)
            pos += p.map { SIMD3($0.x, 0, $0.y) }
            // both windings, so the bar shows whichever way the quad turned out
            idx += [base, base + 1, base + 2, base, base + 2, base + 3, base, base + 2, base + 1, base, base + 3, base + 2]
        }
        guard !pos.isEmpty else { return nil }
        var desc = MeshDescriptor(name: "lines")
        desc.positions = MeshBuffers.Positions(pos)
        desc.primitives = .triangles(idx)
        return try? MeshResource.generate(from: [desc])
    }
}


/// A plain colour with no lighting and no tone mapping, so the paper in 3D is the same colour as the flat paper.
/// Each colour's material is made once and reused (making a new one for every line on every frame was costly).
@MainActor func flat(_ c: UIColor) -> UnlitMaterial {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    c.getRed(&r, green: &g, blue: &b, alpha: &a)
    let key = UInt32(r * 255) << 16 | UInt32(g * 255) << 8 | UInt32(b * 255)
    if let m = flatMaterials[key] { return m }
    var m = UnlitMaterial(applyPostProcessToneMap: false)
    m.color = .init(tint: c)
    flatMaterials[key] = m
    return m
}
@MainActor private var flatMaterials: [UInt32: UnlitMaterial] = [:]
