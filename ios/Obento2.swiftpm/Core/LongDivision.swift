import Foundation

/// Long division in chunks (the web app's g5-divide): take out tens of the divisor first, then divide what's left.
/// Numbers: dv (the divisor, 3–9 or 11–25), qt (the answer, 12–99, never a multiple of 10) and n = dv × qt.
///
/// Picture master: "area-model" (web `explanations/diagrams/area-model`, in its `find` mode): g5-mult2's picture run
/// backwards. A rectangle dv tall with n inside it, split across the top into two strips: the answer's tens (T) and
/// ones (O). The strips' widths are found one at a time; a top label waits until its strip is found ("?" while asked).
/// Picture keys:
/// - `strip`: the strip being asked about, lit up: 1 = the tens strip, 2 = the ones strip; 0 = none.
/// - `found`: how many strips, from the left, have their width (T, then O) and product (dv × T, dv × O) written in.
/// - `left`: 1 = what's left after taking out the tens (n − dv × T) is written in the ones strip.
/// - `sum`: 1 = both strips found and the answer's T + O shown across the top.
/// - `look` (onMiss only): 1 = after a miss with no named slip, point at the lit strip and its height dv again.
/// Per step: ask {strip 0, found 0} · tens {strip 1, found 0} · subtract {strip 2, found 1, left 0} ·
/// ones {strip 2, found 1, left 1} · sum {found 2, sum 1} · done {found 2, sum 1}.
public enum LongDivision {
    public static func numbers(dv: Int, qt: Int) -> Numbers { ["dv": Double(dv), "qt": Double(qt), "n": Double(dv * qt)] }

    private static func tensWord(_ n: Int) -> String { "\(n) \(n == 1 ? "ten" : "tens")" }

    public static let spec = LessonSpec(id: "g5-divide", title: "Long division", master: "area-model", generate: { rng, _ in
        // the web generator: half the time a one-digit divisor, else 11–25; the answer 12–99, never a multiple of 10
        let dv = Double.random(in: 0..<1, using: &rng) < 0.5 ? Int.random(in: 3...9, using: &rng) : Int.random(in: 11...25, using: &rng)
        var qt: Int
        repeat { qt = Int.random(in: 12...99, using: &rng) } while qt % 10 == 0
        return numbers(dv: dv, qt: qt)
    }, display: { n in [.num(n["n"] ?? 0), .op("÷"), .num(n["dv"] ?? 0)] },
    idea: { _ in "Taking out ten groups at a time gets to the answer faster than going one by one." },
    story: { n in "\(fmt(n["n"] ?? 0)) marbles are packed equally into \(fmt(n["dv"] ?? 0)) jars. How many marbles go in each jar?" },
    storyOp: { _ in "÷" },
    depends: ["g4-divide", "g3-mult10"],
    check: [CheckItem(3, when: { ($0["dv"] ?? 0) <= 9 }), CheckItem(3, when: { ($0["dv"] ?? 0) >= 11 }), CheckItem(3, when: { ($0["dv"] ?? 0) >= 11 }),
            CheckItem(3, story: true)]) { nums in
        let dv = Int(nums["dv"] ?? 0), qt = Int(nums["qt"] ?? 0), n = dv * qt
        let T = qt - qt % 10, O = qt % 10, left = n - dv * T
        let D = String(dv), N = String(n)
        let look = "Look again at the lit-up strip: it's \(D) tall."
        func d(_ x: Int) -> Double { Double(x) }

        let ask = LessonStep(StepWords(say: "What is \(N) ÷ \(D)?", hint: "The strip is \(D) tall. How wide is it?", action: "Let’s find out"),
                             picture: ["strip": 0, "found": 0])
        let tensHint = "Try \(D) × 10, \(D) × 20, … and stop before you go past \(N)."
        let tens = LessonStep(StepWords(say: "How many tens of \(D) fit in \(N)?", hint: "Take out as many tens of \(D) as fit.", action: "Check"),
            answer: AnswerTask(prompt: [.text("tens"), .op("="), .box("x")], expected: ["x": d(T)],
                               known: [(["x": d(T - 10)], "\(D) × \(T) still fits, so you can use more tens."),
                                       (["x": d(T / 10)], "\(tensWord(T / 10)) is written \(T)."),
                                       (["x": d(T + 10)], "\(D) × \(T + 10) = \(dv * (T + 10)), which is more than \(N).")],
                               hint: tensHint, explain: "\(tensHint) That makes \(T)."),
            picture: ["strip": 1, "found": 0], onMiss: ["look": 1], look: look)
        let subHint = "\(D) × \(T) = \(dv * T). Take that away from \(N)."
        let subtract = LessonStep(StepWords(say: "Subtract", hint: "Take those away to see what's left.", action: "Check"),
            answer: AnswerTask(prompt: [.num(d(n)), .op("−"), .num(d(dv * T)), .op("="), .box("x")], expected: ["x": d(left)],
                               known: [(["x": d(n + dv * T)], "Those \(dv * T) have been shared out, so take them away from \(N).")],
                               hint: subHint, explain: "\(subHint) That makes \(left)."),
            picture: ["strip": 2, "found": 1, "left": 0], onMiss: ["look": 1], look: look)
        // the web's slips(): drop a slip equal to the answer or repeating one, then any below 0
        var onesKnown: [(values: [String: Double], message: String)] = []
        for (v, message) in [(O + 1, "\(D) × \(O + 1) = \(dv * (O + 1)), which is more than \(left)."), (O - 1, "One more \(D) still fits in \(left).")]
        where v != O && v >= 0 && !onesKnown.contains(where: { $0.values["x"] == d(v) }) { onesKnown.append((["x": d(v)], message)) }
        let onesHint = "How many \(D)s make \(left)?"
        let ones = LessonStep(StepWords(say: "Divide what's left", hint: "Now count how many \(D)s fit in what's left.", action: "Check"),
            answer: AnswerTask(prompt: [.num(d(left)), .op("÷"), .num(d(dv)), .op("="), .box("x")], expected: ["x": d(O)],
                               known: onesKnown, hint: onesHint, explain: "\(onesHint) That makes \(O)."),
            picture: ["strip": 2, "found": 1, "left": 1], onMiss: ["look": 1], look: look)
        let sumHint = "\(T) + \(O)."
        let sum = LessonStep(StepWords(say: "Add the parts", hint: "The tens and the ones together are the answer.", action: "Check"),
            answer: AnswerTask(prompt: [.num(d(n)), .op("÷"), .num(d(dv)), .op("="), .box("x")], expected: ["x": d(qt)],
                               known: [(["x": d(T / 10 + O)], "The first part was \(T), not \(T / 10).")],
                               hint: sumHint, explain: "\(sumHint) That makes \(qt)."),
            picture: ["strip": 0, "found": 2, "sum": 1], onMiss: ["look": 1], look: look)
        let done = LessonStep(StepWords(say: "The tens and the ones make \(qt).",
                                        hint: "Taking out ten groups at a time gets to the answer faster than going one by one.",
                                        action: "Next problem"),
                              picture: ["strip": 0, "found": 2, "sum": 1])
        return [ask, tens, subtract, ones, sum, done]
    }
}
