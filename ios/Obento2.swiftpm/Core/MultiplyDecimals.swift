import Foundation

/// Multiplying decimals (the web app's g5-multdec): multiply without the points, count the places, place the point.
/// Numbers: A, B, pa, pb; the problem is A/10^pa × B/10^pb. B is 2 to 9. The first problems are tenths × a whole
/// number (pa 1, pb 0), then tenths × tenths (pa 1, pb 1, the web's own example 2.4 × 0.3), then hundredths × tenths
/// (pa 2, pb 1, A three digits), so the places answer changes from 1 to 2 to 3.
///
/// On the paper (design/grade5.md): a whole is a bold square 10 squares a side, so one square is a tenth by a tenth, a
/// hundredth. The strip x by y lies on the wholes from their bottom-left corner; its pieces are a tenth by a whole
/// (tenths × a whole number), a square (tenths × tenths) or a tenth of a square (hundredths × tenths). The steps:
/// the strip's corner dragged out to its two marks (its sides, the problem's own names; hundredths × tenths has its width
/// already, too fine for a finger, and is dragged up), the pieces counted without the points and written
/// (`A × B = [P]`), then a tap where the point goes in `P`, the places counted from the right. Picture key "at", the
/// stage: 0 the question, 1 the strip, 2 write the pieces, 3 place the point, 4 done. Hints: "marks" (the two marks
/// ringed), "rows" (each row of pieces counted), "count" (the places hopped from the right).
public enum MultiplyDecimals {
    public static func numbers(A: Int, B: Int, pa: Int = 1, pb: Int = 1) -> Numbers {
        ["A": Double(A), "B": Double(B), "pa": Double(pa), "pb": Double(pb)]
    }

    private static func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
    static let placeNames = ["ones", "tenths", "hundredths", "thousandths"]
    static func placeWord(_ n: Int) -> String { n == 1 ? "1 place" : "\(n) places" }

    /// P with its point `k` places from the right: what a tap there makes.
    public static func pointed(_ P: Int, _ k: Int) -> Double { r6(Double(P) / pow(10, Double(k))) }
    /// How many places from the right a value made from P has its point.
    public static func places(of t: Double, P: Int) -> Int { (0...6).first { abs(pointed(P, $0) - t) < 1e-9 } ?? 0 }

    /// The strip let go with `a` pieces across and `b` up: right at the marks, else where it is, measured.
    public static func stripVerdict(_ a: Double?, _ b: Double?, _ s: Parts) -> Verdict {
        guard let a, let b, a > 0, b > 0 else { return .soft("Drag the corner out to both marks.") }
        let across = fmt(r6(a / pow(10, Double(s.pa)))), up = fmt(r6(b / pow(10, Double(s.pb))))
        let okA = Int(a.rounded()) == s.A, okB = Int(b.rounded()) == s.B
        if okA && okB { return .right }
        if !okA && !okB { return .wrong("That’s \(across) across and \(up) up. Take the corner to both marks.") }
        return okA ? .wrong("That’s \(up) up. The mark is at \(fmt(s.y)).") : .wrong("That’s \(across) across. The mark is at \(fmt(s.x)).")
    }

    /// The two numbers and the work, all from A, B, pa and pb.
    public struct Parts: Sendable {
        public let A: Int, B: Int, pa: Int, pb: Int
        public var x: Double { r6(Double(A) / pow(10, Double(pa))) }
        public var y: Double { r6(Double(B) / pow(10, Double(pb))) }
        /// The product without the points, and the decimal places in all.
        public var P: Int { A * B }
        public var n: Int { pa + pb }
        public var answer: Double { r6(Double(P) / pow(10, Double(n))) }
        /// What one piece is (0.1, 0.01, 0.001), and what multiplies to it.
        public var piece: Double { r6(1 / pow(10, Double(n))) }
        /// The last words: why the answer has that many places.
        public var why: String {
            let a = pa == 1 ? "Tenths" : "Hundredths", b = pb == 0 ? "wholes" : "tenths"
            return "\(a) times \(b) are \(MultiplyDecimals.placeNames[n]): \(MultiplyDecimals.placeWord(n))."
        }
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

        // the problem is written once, as the strip's marks (G 20 Oct): the first words say what a square is
        let ask = LessonStep(StepWords(say: "Each bold square is one whole.", hint: "The strip's sides are the two numbers.", action: "Let’s find out"),
                             picture: ["at": 0])

        // the strip: its corner dragged out to the marks, the pieces it covers counted as it goes; what it covers goes in
        // the boxes (pieces across, pieces up)
        let strip = LessonStep(StepWords(say: pa == 1 ? "Drag the corner out to both marks." : "Drag the strip up to its mark.",
                                         hint: pa == 1 ? "Across to \(X), up to \(Y)." : "Up to \(Y).", action: "Check"),
            answer: AnswerTask(prompt: [.box("a"), .op("×"), .box("b")], expected: ["a": Double(A), "b": Double(B)],
                               hint: pa == 1 ? "Take the corner across to \(X) and up to \(Y)." : "Take the top up to \(Y).",
                               explain: "The strip is \(X) across and \(Y) up: \(A) × \(B) pieces.",
                               check: { v in MultiplyDecimals.stripVerdict(v["a"], v["b"], s) }, byHand: true),
            picture: ["at": 1], onMiss: ["marks": 1])

        // hints are the spec's narration (specs/k12/grade5.md §3), the task's hint the web step's own
        let whole = LessonStep(StepWords(say: "How many pieces in the strip? Write it.", hint: "Leave the points out and multiply.", action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(A)), .op("×"), .num(Double(B)), .op("="), .box("x")], expected: ["x": Double(P)],
                               known: [(["x": Double(A + B)], "The sign is ×: \(A) × \(B).")],
                               hint: "Leave the points out for now: \(X) has the same digits as \(A).",
                               explain: "Without the points it’s \(A) × \(B) = \(P)."),
            picture: ["at": 2], onMiss: ["rows": 1])

        // the point: tapped between the digits of P (or before them, or after them), which sets the answer
        var pointSlips: [(values: [String: Double], message: String)] = [
            (["x": big], pb > 0 ? "\(fmt(big)) is too big. \(Y) is less than 1, so the answer must be less than \(X)."
                                : "\(fmt(big)) is too big. \(X) × \(B) is close to \(fmt(x.rounded())) × \(B) = \(fmt(near)).")]
        if small != ans { pointSlips.append((["x": small], "\(fmt(small)) is too small. Count the places again: \(pa) + \(pb) = \(n).")) }
        if Double(P) != big { pointSlips.append((["x": Double(P)], "Put the decimal point back, \(placeWord(n)) from the right.")) }
        let place = LessonStep(StepWords(say: "Tap where the point goes.", hint: "Put the point \(placeWord(n)) from the right.", action: "Check"),
            answer: AnswerTask(prompt: [.num(x), .op("×"), .num(y), .op("="), .box("x")], expected: ["x": ans], known: pointSlips,
                               hint: "The answer counts \(placeNames[n]), so \(placeWord(n)) \(n == 1 ? "goes" : "go") after the point.",
                               explain: "Put the point \(placeWord(n)) from the right of \(P): \(fmt(ans)).",
                               check: { v in
                                   guard let t = v["x"] else { return .soft("Tap where the point goes.") }
                                   if abs(t - ans) < 1e-9 { return .right }
                                   let k = MultiplyDecimals.places(of: t, P: P)
                                   return .wrong("That’s \(placeWord(k)) from the right. \(X) and \(Y) have \(placeWord(n)) between them.")
                               }, byHand: true),
            picture: ["at": 3], onMiss: ["count": 1])

        // the answer is in the record; the last words say why it has that many places
        let done = LessonStep(StepWords(say: s.why, hint: "Put the point \(placeWord(n)) from the right.", action: "Next problem"),
                              picture: ["at": 4])
        return [ask, strip, whole, place, done]
    }
}
