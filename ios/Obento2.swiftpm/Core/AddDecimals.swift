import Foundation

/// Adding decimals (the web app's g5-adddec): line up the points, add the whole parts and the decimal parts, put them together.
/// Numbers: a (tenths, 1.1 to 99.9) and b (hundredths, 1.01 to 99.99); the problem is a + b.
///
/// Picture master "columns" (the web's decimal columns, in its early-g4 diagram folder): two stages side by side. On the
/// left, a over b in columns lined up on their points, with a line down through the points; on the right, the whole
/// parts' sum, the decimal parts' sum under it, and their total. Keys, by step:
/// - "lineUp": 1, a and b in columns on their points, the point line drawn, and the zeros written in to give both
///   numbers hundredths (12.5 → 12.50) drawn in the picture's colour (always on).
/// - "lit": what is lit for the child to look at: 0 = the written-in zeros (the first step), 1 = the whole columns,
///   digits and band (the whole-number step), 2 = the decimal columns (the decimal step). Absent: nothing lit.
/// - "whole": 1, the whole parts' sum written on the right, under the whole columns (once the child has added them).
/// - "decimal": 1, the decimal parts' sum written on the right, under the decimal columns; with "carry": 1 when it is
///   1 or more, so its 1 sits left of the point, in the ones column, ringed.
/// - "total": 1, the plus sign and line on the right and the total under them, in the answer's colour (the last step).
public enum AddDecimals {
    public static func numbers(a: Double, b: Double) -> Numbers { ["a": r6(a), "b": r6(b)] }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
    /// x written with two decimal places, as JavaScript's toFixed(2): 12.5 → "12.50".
    private static func two(_ x: Double) -> String { String(format: "%.2f", x) }
    /// "1 tenth", "5 tenths"
    private static func count(_ n: Int, _ one: String) -> String { "\(n) \(n == 1 ? one : one + "s")" }

    /// The whole and decimal parts of each number.
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
    }

    public static let spec = LessonSpec(id: "g5-adddec", title: "Adding decimals", master: "columns", generate: { rng, index in
        // the first three: one-digit whole parts
        if index < 3 { return numbers(a: Double(Int.random(in: 11...99, using: &rng)) / 10, b: Double(Int.random(in: 101...999, using: &rng)) / 100) }
        return numbers(a: Double(Int.random(in: 11...999, using: &rng)) / 10, b: Double(Int.random(in: 101...9999, using: &rng)) / 100)
    }, display: { n in [.num(n["a"] ?? 0), .op("+"), .num(n["b"] ?? 0)] },
    idea: { _ in "Line up the points so tenths add to tenths and hundredths to hundredths." },
    story: { n in "Maya biked \(fmt(n["a"] ?? 0)) km on Saturday and \(fmt(n["b"] ?? 0)) km on Sunday. How far did she bike in all?" },
    depends: ["g4-dec", "g4-addsub"],
    check: [CheckItem(3, when: { n in let s = Parts(n); return s.da + s.db >= 1 - 1e-9 }),
            CheckItem(3, when: { n in let s = Parts(n); return s.da + s.db < 1 - 1e-9 }),
            CheckItem(3), CheckItem(3, story: true)]) { n in
        let s = Parts(n), a = s.a, b = s.b, wa = s.wa, wb = s.wb, da = s.da, db = s.db, W = s.W, D = s.D, sum = s.sum
        // the numbers that stop short of hundredths, written with them
        let padded = [a, b].filter { fmt($0) != two($0) }
        let rewrite = padded.map { "\(fmt($0)) as \(two($0))" }.joined(separator: " and ")
        let lineUp = padded.isEmpty ? "Both already have hundredths, so the points line up." : "Write \(rewrite) so both numbers have hundredths."

        let ask = LessonStep(StepWords(say: "What is \(fmt(a)) + \(fmt(b))?", hint: lineUp, action: "Let’s find out"),
                             picture: ["lineUp": 1, "lit": 0])

        let ones = wa % 10 + wb % 10
        let whole = LessonStep(StepWords(say: "Add the whole numbers.", hint: "Add the whole numbers.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(wa)), .op("+"), .num(Double(wb)), .op("="), .box("x")], expected: ["x": Double(W)],
                               known: ones >= 10 ? [(["x": Double(W - 10)], "The ones make \(ones): carry the 1 ten.")]
                                                 : [(["x": Double(abs(wa - wb))], "This step adds the whole parts.")],
                               hint: "Add the parts before the decimal points."),
            picture: ["lineUp": 1, "lit": 1])

        let tenths = Int((da * 10).rounded()), hundredths = Int((da * 100).rounded())
        let decimal = LessonStep(StepWords(say: "Add the decimal parts.", hint: "Add the parts after the point." + (D >= 1 ? " That’s more than 1 whole." : ""), action: "Check"),
            answer: AnswerTask(prompt: [.num(da), .op("+"), .num(db), .op("="), .box("x")], expected: ["x": D],
                               known: [(["x": r6(Double(tenths + Int((db * 100).rounded())) / 100)],
                                        "\(fmt(da)) means \(count(tenths, "tenth")), which is \(count(hundredths, "hundredth")). Line up the points.")],
                               hint: "Line up the points: \(fmt(da)) is the same as \(two(da))."),
            picture: ["lineUp": 1, "whole": 1, "lit": 2])

        let carried: Numbers = ["lineUp": 1, "whole": 1, "decimal": 1, "carry": D >= 1 ? 1 : 0]
        let total = LessonStep(StepWords(say: "Put them together.", hint: "Put the two answers together.", action: "Check"),
            answer: AnswerTask(prompt: [.num(a), .op("+"), .num(b), .op("="), .box("x")], expected: ["x": sum],
                               known: D >= 1 ? [(["x": r6(a + b - 1)], "\(fmt(D)) is more than 1 whole: that 1 goes with the whole numbers.")]
                                             : [(["x": Double(W)], "Keep the \(fmt(D)) after the point.")],
                               hint: "\(W) + \(fmt(D))."),
            picture: carried)

        let done = LessonStep(StepWords(say: "\(fmt(a)) + \(fmt(b)) = \(fmt(sum)).",
                                        hint: "Line up the points so tenths add to tenths and hundredths to hundredths.",
                                        action: "Next problem"),
                              picture: carried.merging(["total": 1]) { $1 })
        return [ask, whole, decimal, total, done]
    }
}
