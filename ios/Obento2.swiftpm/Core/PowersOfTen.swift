import Foundation

/// Multiply by 10, 100, 1000 (the web app's g5-pow10): each zero moves the decimal point one place right.
/// Numbers: x (two decimal places at most, 1.01 to 99.99) and k (1 to 3); the problem is x × 10^k.
public enum PowersOfTen {
    public static func numbers(x: Double, k: Int) -> Numbers { ["x": (x * 100).rounded() / 100, "k": Double(k)] }

    static let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    static func places(_ k: Int) -> String { "\(k) place\(k > 1 ? "s" : "")" }

    /// The digits as written without the point, and how many sit left of it: 3.47 → ("347", 1).
    public static func digits(_ x: Double) -> (digits: String, whole: Int) {
        let s = fmt(x), parts = s.split(separator: ".", omittingEmptySubsequences: false)
        return (parts.joined(), parts[0].count)
    }

    public static let spec = LessonSpec(id: "g5-pow10", title: "Multiply by 10, 100, 1000", master: "shift", generate: { rng in
        // a tenth-only number times 100 now and then, so the point runs past the last digit and a 0 is written in
        if Int.random(in: 0..<4, using: &rng) == 0 {
            var n = Int.random(in: 11...99, using: &rng); if n % 10 == 0 { n += 1 }
            return numbers(x: Double(n) / 10, k: 2)
        }
        return numbers(x: Double(Int.random(in: 101...9999, using: &rng)) / 100, k: Int.random(in: 1...3, using: &rng))
    }, display: { n in [.num(n["x"] ?? 0), .op("×"), .num(pow(10, n["k"] ?? 1))] }) { n in
        let x = n["x"] ?? 0, k = Int(n["k"] ?? 1), m = pow(10, Double(k)), ans = (x * m * 1_000_000).rounded() / 1_000_000
        let M = fmt(m), X = fmt(x)
        let ask = LessonStep(StepWords(say: "What is \(X) × \(M)?", hint: "Look at the point. Where does it go?", action: "Let’s find out"))
        let zeros = LessonStep(StepWords(say: "How many zeros does \(M) have?", hint: "Count the zeros.", action: "Check"),
            answer: AnswerTask(prompt: [.num(m), .text("has"), .box("x"), .text(k == 1 ? "zero" : "zeros")], expected: ["x": Double(k)],
                               known: [(["x": Double(k + 1)], "The 1 isn’t a zero. Count only the 0s in \(M)."),
                                       (["x": m], "That’s the whole number. How many 0s are in it?")],
                               hint: "Count the 0s in \(M)."),
            picture: ["zeros": 1])
        let move = LessonStep(StepWords(say: "Move the point \(places(k)) to the right.", hint: "One place for each zero.", action: "Check"),
            answer: AnswerTask(prompt: [.num(x), .op("×"), .num(m), .op("="), .box("x")], expected: ["x": ans],
                               known: [(["x": ans / 10], "Move it one place for each zero."),
                                       (["x": ans * 10], "Move it one place for each zero, no more."),
                                       (["x": x / m], "Multiplying by \(M) makes the number bigger, so the point moves right.")],
                               hint: "Each zero moves the point one place to the right."),
            picture: ["zeros": 1])
        let done = LessonStep(StepWords(say: "\(X) × \(M) = \(fmt(ans)).",
                                        hint: "Each zero hops the point one place right.",
                                        action: "Next problem"),
                              picture: ["zeros": 1, "hop": 1])
        return [ask, zeros, move, done]
    }
}
