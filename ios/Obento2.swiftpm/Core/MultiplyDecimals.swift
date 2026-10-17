import Foundation

/// Multiplying decimals (the web app's g5-multdec): multiply without the points, count the places, place the point.
/// Numbers: A, B, pa, pb; the problem is A/10^pa × B/10^pb. B is 2 to 9. The first problems are tenths × a whole
/// number (pa 1, pb 0), then tenths × tenths (pa 1, pb 1, the web's own example 2.4 × 0.3), then hundredths × tenths
/// (pa 2, pb 1, A three digits), so the places answer changes from 1 to 2 to 3.
///
/// Picture master "area-model" (the web's area grid): x × y as a strip x wide and y tall laid on whole unit squares,
/// each unit square cut into the small pieces the two numbers count (tenths by tenths: hundredths). The strip covers
/// A pieces across and B up, so A × B pieces. It lies with its long side across: when y is the bigger number the strip
/// is drawn turned ("turned": 1), x up and y across. Keys, by step:
/// - "strip": 1, the strip on its unit squares, cut into pieces, with the count of pieces across under it
///   ("24 tenths") (always on).
/// - "lit": what is lit for the child to look at: 0 = the strip and the count under it (the multiply step),
///   1 = the one piece blown up (the places step). Absent: nothing lit.
/// - "piece": 1, one piece ringed in the strip's corner and shown big beside the picture with its size under it
///   (0.01): the places step, and the point step that reads it.
/// - "line": the one line under the picture, as the web's picture swaps them: 0 = "24 × 3 = 72 small pieces"
///   (once the child has multiplied), 1 = "0.1 × 0.1 = 0.01, two decimal places" (once the places are counted),
///   2 = "72 hundredths = 0.72" (the last step). Absent: no line.
public enum MultiplyDecimals {
    public static func numbers(A: Int, B: Int, pa: Int = 1, pb: Int = 1) -> Numbers {
        ["A": Double(A), "B": Double(B), "pa": Double(pa), "pb": Double(pb)]
    }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
    private static let placeNames = ["ones", "tenths", "hundredths", "thousandths"]
    private static func placeWord(_ n: Int) -> String { n == 1 ? "1 place" : "\(n) places" }

    /// The two numbers and the work, all from A, B, pa and pb.
    public struct Parts: Sendable {
        public let A: Int, B: Int, pa: Int, pb: Int
        public var x: Double { r6(Double(A) / pow(10, Double(pa))) }
        public var y: Double { r6(Double(B) / pow(10, Double(pb))) }
        /// The product without the points, and the decimal places in all.
        public var P: Int { A * B }
        public var n: Int { pa + pb }
        public var answer: Double { r6(Double(P) / pow(10, Double(n))) }
        public init(_ v: Numbers) {
            A = Int((v["A"] ?? 11).rounded()); B = Int((v["B"] ?? 2).rounded())
            pa = Int((v["pa"] ?? 1).rounded()); pb = Int((v["pb"] ?? 1).rounded())
        }
    }

    public static let spec = LessonSpec(id: "g5-multdec", title: "Multiplying decimals", master: "area-model", generate: { rng, index in
        // tenths × a whole number first, then tenths × tenths, then hundredths × tenths, so the places answer changes
        let (pa, pb) = index < 3 ? (1, 0) : index < 6 ? (1, 1) : (2, 1)
        var A: Int
        repeat { A = pa == 1 ? Int.random(in: 11...99, using: &rng) : Int.random(in: 101...999, using: &rng) } while A % 10 == 0
        return numbers(A: A, B: Int.random(in: 2...9, using: &rng), pa: pa, pb: pb)
    }, display: { v in let s = Parts(v); return [.num(s.x), .op("×"), .num(s.y)] },
    idea: { _ in "A tenth of a tenth is a hundredth, so the answer has as many decimal places as both numbers together." },
    story: { v in let s = Parts(v); return "A garden bed is \(fmt(s.x)) m long and \(fmt(s.y)) m wide. What is its area in square meters?" },
    storyOp: { _ in "×" },
    depends: ["g4-partial", "g4-dec"],
    check: [CheckItem(1), CheckItem(4), CheckItem(7), CheckItem(5, story: true)]) { v in
        let s = Parts(v), A = s.A, B = s.B, pa = s.pa, pb = s.pb, x = s.x, y = s.y, P = s.P, n = s.n, ans = s.answer
        let X = fmt(x), Y = fmt(y)
        let big = r6(Double(P) / pow(10, Double(n - 1))), small = r6(Double(P) / pow(10, Double(n + 1)))
        let near = x.rounded() * y
        let strip: Numbers = ["strip": 1, "turned": y > x ? 1 : 0]
        let pic = { (extra: Numbers) in strip.merging(extra) { $1 } }

        let ask = LessonStep(StepWords(say: "What is \(X) × \(Y)?", hint: "Look at the digits. Where will the point go?", action: "Let’s find out"),
                             picture: strip)

        // hints are the spec's narration (specs/k12/grade5.md §3), the task's hint the web step's own
        let whole = LessonStep(StepWords(say: "Multiply without the points.", hint: "Leave the points out and multiply.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(A)), .op("×"), .num(Double(B)), .op("="), .box("x")], expected: ["x": Double(P)],
                               known: [(["x": Double(A + B)], "The sign is ×: \(A) × \(B).")],
                               hint: "Leave the points out for now: \(X) has the same digits as \(A).",
                               explain: "Without the points it’s \(A) × \(B) = \(P)."),
            picture: pic(["lit": 0]))

        // counting just one number's places, unless that is the answer (or the same count twice)
        var placeSlips: [(values: [String: Double], message: String)] = []
        for v in [pa, pb] where v != n && !placeSlips.contains(where: { $0.values["x"] == Double(v) }) {
            placeSlips.append((["x": Double(v)], "Count the places in both numbers."))
        }
        let places = LessonStep(StepWords(say: "How many digits come after the points, in both numbers together?", hint: "Count the digits after each point.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(n)], known: placeSlips,
                               hint: "How many digits are after the point in \(X)? And in \(Y)? Add them.",
                               explain: "\(X) has \(pa) and \(Y) has \(pb), so \(n) in all."),
            picture: pic(["line": 0, "piece": 1, "lit": 1]))

        var pointSlips: [(values: [String: Double], message: String)] = [
            (["x": big], pb > 0 ? "\(fmt(big)) is too big. \(Y) is less than 1, so the answer must be less than \(X)."
                                : "\(fmt(big)) is too big. \(X) × \(B) is close to \(fmt(x.rounded())) × \(B) = \(fmt(near)).")]
        if small != ans { pointSlips.append((["x": small], "\(fmt(small)) is too small. Count the places again: \(pa) + \(pb) = \(n).")) }
        if Double(P) != big { pointSlips.append((["x": Double(P)], "Put the decimal point back, \(placeWord(n)) from the right.")) }
        let place = LessonStep(StepWords(say: "Place the point.", hint: "Put the point \(placeWord(n)) from the right.", action: "Check"),
            answer: AnswerTask(prompt: [.num(x), .op("×"), .num(y), .op("="), .box("x")], expected: ["x": ans], known: pointSlips,
                               hint: "The answer counts \(placeNames[n]), so \(placeWord(n)) \(n == 1 ? "goes" : "go") after the point.",
                               explain: "Put the point \(placeWord(n)) from the right of \(P): \(fmt(ans))."),
            picture: pic(["line": 1, "piece": 1]))

        // the idea is too long for the last line, so it keeps the last narration
        let done = LessonStep(StepWords(say: "\(X) × \(Y) = \(fmt(ans)).", hint: "Put the point \(placeWord(n)) from the right.", action: "Next problem"),
                              picture: pic(["line": 2]))
        return [ask, whole, places, place, done]
    }
}
