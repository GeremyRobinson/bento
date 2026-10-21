import Foundation

/// Long division in chunks (the web app's g5-divide): take out tens of the divisor first, then divide what's left.
/// Numbers: dv (the divisor, 3–9 or 11–25), qt (the answer, 12–99, never a multiple of 10) and n = dv × qt.
///
/// On the paper (design/grade5.md): g5-mult2's rectangle run backwards. One square is one thing (a marble, in the
/// story): a rectangle dv squares tall (a row for each jar) whose width is found. The child drags its right edge out ten
/// columns at a time, the readout counting the squares used and what's left ("840 used", "24 left"), and presses Check:
/// that answers the tens (its box is set from the edge) and leaves what's left in the record, so the subtraction is
/// written for the child (no step of its own). Then the edge is dragged on a column at a time until nothing is left (the
/// ones, set from the edge). The record is the division as school writes it, the partial quotients beside it as the
/// strips are found; only the answer over the bracket is typed.
/// Picture key "at", the stage: 0 the question, 1 the tens strip being dragged, 2 the ones strip, 3 both found (the
/// answer to write), 4 done. `look` (onMiss): the lit strip's ten-column groups counted.
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

        // the problem is written once, in the record's bracket and as the rectangle's side: the first words ask about
        // the picture, not the sum again
        let ask = LessonStep(StepWords(say: "How wide is the rectangle?", hint: "It's \(D) tall and holds \(N) squares.", action: "Let’s find out"),
                             picture: ["at": 0])
        // the edge, dragged out ten columns at a time: Check puts how wide it is in the box (the web's tens and its slips;
        // what else a move makes is measured in squares)
        let tensHint = "Try \(D) × 10, \(D) × 20, … and stop before you go past \(N)."
        let tens = LessonStep(StepWords(say: "Drag the edge out ten columns at a time, as far as the squares go.",
                                        hint: "Ten columns of \(D) use \(dv * 10) squares.", action: "Check"),
            answer: AnswerTask(prompt: [.text("tens"), .op("="), .box("x")], expected: ["x": d(T)],
                               known: [(["x": d(T - 10)], "\(D) × \(T) still fits, so you can use more tens."),
                                       (["x": d(T / 10)], "\(tensWord(T / 10)) is written \(T)."),
                                       (["x": d(T + 10)], "\(D) × \(T + 10) = \(dv * (T + 10)), which is more than \(N).")],
                               hint: tensHint, explain: "\(tensHint) That makes \(T).",
                               check: { v in
                                   guard let x = v["x"], x > 0 else { return .soft("Drag the edge out first.") }
                                   let c = Int(x.rounded()), used = dv * c
                                   if c == T { return .right }
                                   if used > n { return .wrong("\(D) × \(c) = \(used), which is more than \(N).") }
                                   if c % 10 != 0 { return .wrong("Take out whole tens first: \(c) isn't a ten.") }
                                   return .wrong("That uses \(used), and \(n - used) are left: ten more columns fit.")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["look": 1], look: look)
        // the web's slips(): drop a slip equal to the answer or repeating one, then any below 0
        var onesKnown: [(values: [String: Double], message: String)] = []
        for (v, message) in [(O + 1, "\(D) × \(O + 1) = \(dv * (O + 1)), which is more than \(left)."), (O - 1, "One more \(D) still fits in \(left).")]
        where v != O && v >= 0 && !onesKnown.contains(where: { $0.values["x"] == d(v) }) { onesKnown.append((["x": d(v)], message)) }
        let onesHint = "How many \(D)s make \(left)?"
        let ones = LessonStep(StepWords(say: "Now drag it on a column at a time until none are left.",
                                        hint: "One column of \(D) uses \(D) squares.", action: "Check"),
            answer: AnswerTask(prompt: [.num(d(left)), .op("÷"), .num(d(dv)), .op("="), .box("x")], expected: ["x": d(O)],
                               known: onesKnown, hint: onesHint, explain: "\(onesHint) That makes \(O).",
                               check: { v in
                                   guard let x = v["x"], x > 0 else { return .soft("Drag the edge on first.") }
                                   let c = Int(x.rounded()), used = dv * c
                                   if c == O { return .right }
                                   if used > left { return .wrong("\(D) × \(c) = \(used), which is more than \(left).") }
                                   return .wrong("That uses \(used), and \(left - used) are left: another column fits.")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["look": 1], look: look)
        // the answer over the bracket: the one number school writes here (the parts were written as they were found)
        let sumHint = "\(T) + \(O)."
        let sum = LessonStep(StepWords(say: "How wide is it? Write it over the bracket.", hint: "The tens and the ones together are the answer.", action: "Check"),
            answer: AnswerTask(prompt: [.num(d(n)), .op("÷"), .num(d(dv)), .op("="), .box("x")], expected: ["x": d(qt)],
                               known: [(["x": d(T / 10 + O)], "The first part was \(T), not \(T / 10).")],
                               hint: sumHint, explain: "\(sumHint) That makes \(qt)."),
            picture: ["at": 3], onMiss: ["look": 1], look: look)
        // the last words say why: the rectangle is the division
        let done = LessonStep(StepWords(say: "\(D) rows of \(qt) make \(N).",
                                        hint: "Taking out ten groups at a time gets to the answer faster than going one by one.",
                                        action: "Next problem"),
                              picture: ["at": 4])
        return [ask, tens, ones, sum, done]
    }
}
