import Foundation

/// Adding decimals (the web app's g5-adddec): line up the points, add the whole parts and the decimal parts, put them
/// together. Numbers: a (tenths, 1.1 to 99.9) and b (hundredths, 1.01 to 99.99); the problem is a + b.
///
/// On the paper (design/grade5.md): the record leads, because lining up is the lesson. a over b in columns, two squares
/// to a digit, their points on one strong line; the part after each point is drawn beside the record as a 10 × 10 grid
/// of hundredths (a cell is a hundredth, a column a tenth, the grid one whole), a's shaded and b's striped. The child
/// taps each empty place after a point and a 0 is written there (12.5 is 12.50: the web's line-up beat, made a hand
/// move); slides b's hundredths into a's grid, where they pour in column by column and a full grid overflows into the
/// next (that answers the web's decimal-parts step: its box is set from the hundredths poured, as a decimal); taps the
/// full grid, when there is one, and its 1 goes to the ones column as the carried 1; then writes the total in the
/// record, the one number school writes. The web's whole-parts step is written as part of that total, and its slips
/// are caught there, with the web's other slips, each said of what the paper shows.
///
/// Picture keys: "at", the stage: 0 the question, 1 write the 0s, 2 slide the hundredths, 3 carry the full grid, 4 write
/// the total, 5 done. A hint (after a miss, or asked for) lights: "gaps" (each empty place ringed), "target" (where the
/// hundredths go in the first grid, dashed), "full" (the full grid outlined), "read" (what the total is read from: the
/// grid with what's after the point, outlined, and the carried 1, ringed).
public enum AddDecimals {
    public static func numbers(a: Double, b: Double) -> Numbers { ["a": r6(a), "b": r6(b)] }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
    /// x written with two decimal places, as JavaScript's toFixed(2): 12.5 → "12.50".
    public static func two(_ x: Double) -> String { String(format: "%.2f", x) }
    /// "1 tenth", "5 tenths"
    private static func count(_ n: Int, _ one: String) -> String { "\(n) \(n == 1 ? one : one + "s")" }

    /// An empty place after a number's point, where a 0 is written: the row (0 for a, 1 for b) and the place (−1 the
    /// tenths, −2 the hundredths).
    public struct Gap: Hashable, Sendable {
        public let row: Int, place: Int
        public init(_ row: Int, _ place: Int) { self.row = row; self.place = place }
    }

    /// A tap on the record that isn't on an empty place after a point is set as 100 + 10 × row + (place + 2) (100 to 114;
    /// the right answer, how many 0s were written, is 1 to 4), so the check can say what's there.
    public static func tapCode(_ row: Int, _ place: Int) -> Double { Double(100 + 10 * row + place + 2) }

    /// The worked parts of a problem, all from a and b.
    public struct Parts: Sendable {
        public let a: Double, b: Double
        public var wa: Int { Int(a.rounded(.down)) }
        public var wb: Int { Int(b.rounded(.down)) }
        public var da: Double { r6(a - Double(wa)) }
        public var db: Double { r6(b - Double(wb)) }
        public var W: Int { wa + wb }
        public var D: Double { r6(da + db) }
        public var sum: Double { r6(a + b) }
        public init(_ n: Numbers) { a = n["a"] ?? 0; b = n["b"] ?? 0 }

        /// The hundredths after each point (12.5 → 50, 3.75 → 75), and both together.
        public var na: Int { Int((da * 100).rounded()) }
        public var nb: Int { Int((db * 100).rounded()) }
        public var n: Int { na + nb }
        /// a's tenths digit (it has no hundredths).
        public var ta: Int { na / 10 }
        /// The hundredths make a whole: a grid fills, and its 1 is carried to the ones.
        public var carries: Bool { n >= 100 }
        /// The hundredths left once a whole is carried (all of them when none is).
        public var left: Int { carries ? n - 100 : n }

        /// A number as it's written (12.5, 3.75, 7), and how many decimals it shows: row 0 is a, row 1 is b.
        public func written(_ row: Int) -> String { fmt(row == 0 ? a : b) }
        public func decimals(_ row: Int) -> Int { written(row).split(separator: ".").dropFirst().first?.count ?? 0 }
        /// The empty places after the points, where 0s go so both numbers have hundredths: a's first (it always has one:
        /// it has tenths at most), then b's; each number's tenths before its hundredths.
        public var gaps: [Gap] {
            (0...1).flatMap { row in (decimals(row)..<2).map { Gap(row, -($0 + 1)) } }
        }
        /// The digit a number shows in a place (2 the hundreds … −2 the hundredths), before any 0 is written.
        public func digit(_ row: Int, _ place: Int) -> Character? {
            let parts = written(row).split(separator: ".", omittingEmptySubsequences: false).map(Array.init)
            if place >= 0 {
                let whole = parts[0], i = whole.count - 1 - place
                return whole.indices.contains(i) ? whole[i] : nil
            }
            guard parts.count > 1 else { return nil }
            let i = -place - 1
            return parts[1].indices.contains(i) ? parts[1][i] : nil
        }
        /// What a tap on the record that isn't on an empty place after a point says: what's there.
        public func tapped(_ row: Int, _ place: Int) -> String {
            if let d = digit(row, place) { return "That place has a \(d) in it." }
            if place < 0 { return "Tap the empty place after the point." }
            return "No 0 is needed in front of the \(written(row).first.map(String.init) ?? "number")."
        }
        /// The numbers that stop short of hundredths, written with them: "12.5 as 12.50" (the web's line-up words).
        var padded: [Double] { [a, b].filter { fmt($0) != two($0) } }
        public var lineUp: String {
            padded.isEmpty ? "Both already have hundredths, so the points line up."
                : "Write \(padded.map { "\(fmt($0)) as \(two($0))" }.joined(separator: " and ")) so both numbers have hundredths."
        }

        /// The ones column: both numbers' ones and the 1 carried from the hundredths.
        public var ones: Int { wa % 10 + wb % 10 + (carries ? 1 : 0) }
        /// The tens column, with the ten carried from the ones.
        public var tens: Int { (wa / 10) % 10 + (wb / 10) % 10 + (ones >= 10 ? 1 : 0) }

        /// A grid's name: what's after a point, written to `places` decimals (0.5, 0.50, 0).
        public static func part(_ x: Double, _ places: Int) -> String { String(format: "%.\(max(0, places))f", x) }
        /// The live count as the hundredths pour in: "50 + 75 = 125 hundredths".
        public var pour: String { "\(na) + \(nb) = \(n) hundredths" }
        /// What a tap on the grid that isn't full says.
        public var notFull: String { "That grid has \(left) hundredth\(left == 1 ? "" : "s"). Tap the full one." }
        /// What the total is read from, said as a hint: the grid shows what goes after the point.
        public var read: String {
            if carries && left == 0 { return "Nothing is left after the point. Add the ones and the carried 1." }
            return "The grid shows what goes after the point. " + (carries ? "Add the ones and the carried 1." : "Then add the whole numbers.")
        }
        /// The total typed with its point in another place (the digits right, as typing 1625 for 16.25 is).
        public func pointMoved(_ x: Double) -> Bool {
            [0.01, 0.1, 10, 100].contains { abs(x - sum * $0) < 1e-9 }
        }
    }

    public static let spec = LessonSpec(id: "g5-adddec", title: "Adding decimals", master: "columns", generate: { rng, index in
        // the first three: one-digit whole parts
        if index < 3 { return numbers(a: Double(Int.random(in: 11...99, using: &rng)) / 10, b: Double(Int.random(in: 101...999, using: &rng)) / 100) }
        return numbers(a: Double(Int.random(in: 11...999, using: &rng)) / 10, b: Double(Int.random(in: 101...9999, using: &rng)) / 100)
    }, display: { n in [.num(n["a"] ?? 0), .op("+"), .num(n["b"] ?? 0)] },
    idea: { _ in "Line up the points so tenths add to tenths and hundredths to hundredths." },
    story: { n in "Maya biked \(fmt(n["a"] ?? 0)) km on Saturday and \(fmt(n["b"] ?? 0)) km on Sunday. How far did she bike in all?" },
    storyOp: { _ in "+" },
    depends: ["g4-dec", "g4-addsub"],
    check: [CheckItem(3, when: { n in let s = Parts(n); return s.da + s.db >= 1 - 1e-9 }),
            CheckItem(3, when: { n in let s = Parts(n); return s.da + s.db < 1 - 1e-9 }),
            CheckItem(3), CheckItem(3, story: true)]) { n in
        let s = Parts(n), a = s.a, b = s.b, wa = s.wa, wb = s.wb, da = s.da, db = s.db, W = s.W, D = s.D, sum = s.sum
        let gaps = s.gaps, lineUp = s.lineUp

        // the problem is written once, as the record (G 20 Oct): the first words say what to do with it
        let ask = LessonStep(StepWords(say: "Add the two numbers.", hint: lineUp, action: "Let’s find out"), picture: ["at": 0])

        // the web's line-up beat, made a hand move: tap each empty place after a point, and a 0 is written there; the last
        // one answers the step (its box is how many were written). A tap anywhere else on the record says what's there: a
        // notice, not a miss (a 0 in front, or on a digit, changes nothing)
        let rewrites = s.padded.map { "\(fmt($0)) is \(two($0))" }.joined(separator: " and ")
        let zeros = LessonStep(
            StepWords(say: gaps.count == 1 ? "Tap the empty place after the point to write a 0." : "Tap each empty place after the point to write a 0.",
                      hint: lineUp, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(gaps.count)], hint: lineUp,
                               explain: "\(rewrites): the same number\(s.padded.count == 1 ? "" : "s"), with hundredths.",
                               check: { v in
                                   guard let z = v["x"] else { return .soft("Tap the empty place after the point.") }
                                   let t = Int(z.rounded())
                                   if t == gaps.count { return .right }
                                   if (100...114).contains(t) { return .soft(s.tapped((t - 100) / 10, (t - 100) % 10 - 2)) }
                                   return .soft("Tap the empty place after the point.")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["gaps": 1])

        // the web's decimal-parts step, answered by sliding b's hundredths into a's grid: its box is set from the hundredths
        // poured (as a decimal, the web's answer). Dropped anywhere else they go back: what happened, then what to do (a
        // notice, not a miss). With no hundredths to slide (b a whole number) the hands make it pointless: left out.
        let slide = LessonStep(
            StepWords(say: "Slide the striped hundredths into the first grid.", hint: "Drag the striped hundredths onto the first grid.", action: "Check"),
            answer: AnswerTask(prompt: [.num(da), .op("+"), .num(db), .op("="), .box("x")], expected: ["x": D],
                               hint: "Hundredths add to hundredths.", explain: "\(s.pour): \(two(D)).",
                               check: { v in
                                   guard let x = v["x"], x > 0 else { return .soft("They went back. Drop them on the first grid.") }
                                   return abs(x - D) < 1e-9 ? .right : .wrong("Drop them on the first grid.")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["target": 1])

        // a full grid is one whole: tap it, and its 1 goes to the ones column as the carried 1 (the web's "more than 1
        // whole", made a hand move). A tap on the grid that isn't full is a miss, said of that grid.
        let carry = LessonStep(
            StepWords(say: "A full grid is 1 whole. Tap it to carry the 1.", hint: "100 hundredths make 1 whole. Tap the full grid.", action: "Check"),
            answer: AnswerTask(prompt: [.num(D), .op("="), .box("x"), .op("+"), .num(r6(D - 1))], expected: ["x": 1],
                               hint: "100 hundredths make 1 whole.", explain: "100 hundredths make 1 whole: it goes to the ones.",
                               check: { v in
                                   guard let x = v["x"] else { return .soft("Tap the full grid.") }
                                   return x == 1 ? .right : .wrong(s.notFull)
                               }, byHand: true),
            picture: ["at": 3], onMiss: ["full": 1])

        // the record, as school writes it: one number, the total, typed under the line. The web's slips are caught here,
        // each said of what the paper shows by now, in the same order every time (so each kind of slip means one thing):
        // putting the parts together (the carried whole lost, or what's after the point left off), the whole numbers
        // (the ten not carried, or the whole numbers taken away), and the points not lined up (5 tenths added to 75
        // hundredths, the web's decimal slip; not when a has no tenths, where it's the answer)
        var known: [(values: [String: Double], message: String)] = []
        if s.carries { known.append((["x": r6(sum - 1)], "The full grid is 1 whole: that 1 goes with the whole numbers.")) }
        else if D > 0 { known.append((["x": Double(W)], "Keep the \(fmt(D)) after the point.")) }
        if s.ones >= 10 { known.append((["x": r6(sum - 10)], "The ones make \(s.ones): carry the 1 ten.")) }
        else { known.append((["x": r6(Double(abs(wa - wb)) + D)], "That takes away the whole numbers. This one adds.")) }
        let tenths = s.ta, hundredths = s.na
        if tenths > 0 {
            known.append((["x": r6(Double(W) + Double(tenths + s.nb) / 100)],
                          "\(fmt(da)) means \(count(tenths, "tenth")), which is \(count(hundredths, "hundredth")). Line up the points."))
        }
        // never the answer, and never the same number twice
        var seen: [Double] = [sum]
        known = known.filter { k in
            let v = k.values["x"] ?? 0
            guard !seen.contains(where: { abs($0 - v) < 1e-9 }) else { return false }
            seen.append(v); return true
        }
        let total = LessonStep(
            StepWords(say: "Write the total.", hint: s.read, action: "Check"),
            answer: AnswerTask(prompt: [.num(a), .op("+"), .num(b), .op("="), .box("x")], expected: ["x": sum], known: known,
                               hint: "Add each column, right to left.", explain: "\(two(a)) + \(two(b)) = \(two(sum)).",
                               check: { v in
                                   guard let x = v["x"] else { return .soft("Fill in every box.") }
                                   if abs(x - sum) < 1e-9 { return .right }
                                   // the digits right, the point somewhere else: the lesson is where it goes
                                   if s.pointMoved(x) { return .wrong("The digits are right. The point goes under the points.") }
                                   return .wrong("Not quite. Add each column, right to left.")
                               }),
            picture: ["at": 4], onMiss: ["read": 1])

        // the answer is in the record, in the chapter's colour; the last words say why
        let done = LessonStep(StepWords(say: "Points under points, so tenths add to tenths.",
                                        hint: "Line up the points so tenths add to tenths and hundredths to hundredths.",
                                        action: "Next problem"),
                              picture: ["at": 5])
        return [ask, zeros] + (s.nb > 0 ? [slide] : []) + (s.carries ? [carry] : []) + [total, done]
    }
}
