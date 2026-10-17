import XCTest
@testable import ObentoCore

final class OrderOfOperationsTests: XCTestCase {
    func run(_ t: Int, _ a: Int, _ b: Int, _ c: Int, _ d: Int) -> LessonRun {
        LessonRun(OrderOfOperations.spec, numbers: OrderOfOperations.numbers(t: t, a: a, b: b, c: c, d: d))
    }
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for ch in s { l.type(String(ch)) } }

    /// The web lesson's reference, 3 + 4 × (6 − 2).
    func testWalkThroughTheReference() {
        let spec = OrderOfOperations.spec
        XCTAssertEqual(spec.id, "g5-order"); XCTAssertEqual(spec.master, "order")
        XCTAssertEqual(spec.depends, ["g3-facts", "g3-divfacts"]); XCTAssertNil(spec.story)
        var l = run(0, 3, 4, 6, 2)
        XCTAssertEqual(l.display, [.num(3), .op("+"), .num(4), .op("×"), .text("("), .num(6), .op("−"), .num(2), .text(")"), .op("="), .text("?")])
        XCTAssertEqual(spec.idea(l.numbers), "Everyone uses the same order, so a problem has only one answer.")
        XCTAssertEqual(l.words, StepWords(say: "What is 3 + 4 × (6 − 2)?", hint: "Look at the signs and the parentheses.", action: "Let’s find out"))
        XCTAssertEqual(l.picture, ["beat": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // What goes first? ① 3 + 4  ② 4 × 6  ③ 6 − 2 (the web's choices), the answer is ③
        XCTAssertEqual(l.words, StepWords(say: "Which part do you do first?", hint: "Find the parentheses: they go first.", action: "Check"))
        XCTAssertEqual(l.picture, ["beat": 0])
        XCTAssertEqual(l.step.answer?.choices, ["3 + 4", "4 × 6", "6 − 2"])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."), "nothing picked yet isn't a miss")
        l.choose(0)
        XCTAssertEqual(l.go(), .notYet("Parentheses go first, then × and ÷, then + and −. Left to right is only for signs of the same kind."))
        l.choose(1)
        XCTAssertEqual(l.go(), .notYet("The parentheses make 6 − 2 one number, so it comes even before ×."))
        XCTAssertEqual(l.misses, 2)
        XCTAssertEqual(l.showAnswer(), "The parentheses go first: 6 − 2.")
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.steps[1].answer?.work, [.text("First:"), .text("6 − 2")])

        // s0: inside the parentheses
        XCTAssertEqual(l.words, StepWords(say: "Parentheses first", hint: "Work out the inside of the parentheses.", action: "Check"))
        XCTAssertEqual(l.picture, ["beat": 1])
        type(&l, "8"); XCTAssertEqual(l.go(), .notYet("Inside the parentheses it's −: 6 − 2."))
        type(&l, "3"); XCTAssertEqual(l.go(), .notYet("Not quite. The parentheses make 6 − 2 one number. What is it?"))
        XCTAssertEqual(l.showAnswer(), "Inside the parentheses: 6 − 2 = 4.")
        XCTAssertEqual(l.go(), .moved(3))

        // s1: multiply next
        XCTAssertEqual(l.words, StepWords(say: "Multiply next", hint: "Multiply next, before adding.", action: "Check"))
        XCTAssertEqual(l.picture, ["beat": 2])
        type(&l, "28"); XCTAssertEqual(l.go(), .notYet("Multiply before you add. Do only 4 × 4 here."))
        XCTAssertEqual(l.showAnswer(), "Multiplication comes before addition. That makes 16.")
        XCTAssertEqual(l.go(), .moved(4))

        // s2: add last, with the left-to-right warning
        XCTAssertEqual(l.words, StepWords(say: "Add last", hint: "Add last. Left to right would give 28, which is wrong.", action: "Check"))
        XCTAssertEqual(l.picture, ["beat": 3])
        type(&l, "48"); XCTAssertEqual(l.go(), .notYet("The sign is +: add 3."))
        XCTAssertEqual(l.showAnswer(), "3 + 16 = 19.")
        XCTAssertEqual(l.go(), .moved(5))

        XCTAssertEqual(l.words, StepWords(say: "Parentheses, then ×, then +, makes 19.", hint: "Everyone uses the same order, so a problem has only one answer.", action: "Next problem"))
        XCTAssertEqual(l.picture, ["beat": 4])
        XCTAssertEqual(l.go(), .newProblem)

        XCTAssertEqual(l.steps[1].answer?.work.last, .text("6 − 2"))
        XCTAssertEqual(l.steps[2].answer?.work, [.num(6), .op("−"), .num(2), .op("="), .num(4)])
        XCTAssertEqual(l.steps[3].answer?.work, [.num(4), .op("×"), .num(4), .op("="), .num(16)])
        XCTAssertEqual(l.steps[4].answer?.work, [.num(3), .op("+"), .num(16), .op("="), .num(19)])
    }

    func testShapeOne() {
        var l = run(1, 2, 3, 5, 1)  // (2 + 3) × 5 − 1
        XCTAssertEqual(l.words.say, "What is (2 + 3) × 5 − 1?")
        _ = l.go()
        XCTAssertEqual(l.words.hint, "Find the parentheses: they go first.")
        XCTAssertEqual(l.step.answer?.expected, ["c": 0])
        l.choose(1); XCTAssertEqual(l.go(), .notYet("The parentheses go first: 2 + 3. Then × comes before −."))
        l.choose(0); XCTAssertEqual(l.go(), .moved(2))
        type(&l, "6"); XCTAssertEqual(l.go(), .notYet("Inside the parentheses it's +: 2 + 3."))
        type(&l, "5"); XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.hint, "Multiply before subtracting.")
        type(&l, "20"); XCTAssertEqual(l.go(), .notYet("Multiply before you subtract: 5 × 5."))
        type(&l, "25"); XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words.hint, "Subtract last.", "no left-to-right warning for (a + b) × c − d")
        type(&l, "26"); XCTAssertEqual(l.go(), .notYet("The sign is −, so take 1 away."))
        XCTAssertEqual(l.showAnswer(), "25 − 1 = 24.")
        XCTAssertEqual(l.go(), .moved(5))
        XCTAssertEqual(l.words.say, "Parentheses, then ×, then −, makes 24.")
    }

    func testShapeTwo() {
        var l = run(2, 6, 4, 8, 2)  // 6 × 4 − 8 ÷ 2
        XCTAssertEqual(l.display.last, .text("?"))
        _ = l.go()
        XCTAssertEqual(l.words.hint, "No parentheses, and × comes before −.")
        l.choose(1); XCTAssertEqual(l.go(), .notYet("× and ÷ come before −, so the − waits."))
        XCTAssertEqual(l.showAnswer(), "× comes before −, so 6 × 4 goes first.")
        _ = l.go()
        XCTAssertEqual(l.words, StepWords(say: "Multiply", hint: "Multiply first.", action: "Check"))
        type(&l, "10"); XCTAssertEqual(l.go(), .notYet("That's 6 + 4. The sign is ×."))
        type(&l, "24"); XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words, StepWords(say: "Divide", hint: "Divide next, still before subtracting.", action: "Check"))
        type(&l, "16"); XCTAssertEqual(l.go(), .notYet("The sign is ÷: how many 2s make 8?"))
        type(&l, "4"); XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words.hint, "Subtract last. Left to right would give 8, which is wrong.")
        type(&l, "8"); XCTAssertEqual(l.go(), .notYet("Divide 8 ÷ 2 first, then subtract it from 24."))
        type(&l, "20"); XCTAssertEqual(l.go(), .moved(5))
        XCTAssertEqual(l.words.say, "× and ÷ first, then −, makes 20.")

        // left to right that isn't whole: no warning, and the slip is still the exact number
        let m = run(2, 5, 3, 4, 2)  // 15 − 4 ÷ 2; left to right (15 − 4) ÷ 2 = 5.5
        XCTAssertEqual(m.steps[4].words.hint, "Subtract last.")
        XCTAssertEqual(m.steps[4].answer?.known.first?.values, ["x": 5.5])
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 19)
        for index in [0, 3, 4, 5, 6] {
            for _ in 0..<300 {
                let n = OrderOfOperations.spec.generate(&rng, index)
                let t = Int(n["t"]!), a = Int(n["a"]!), b = Int(n["b"]!), c = Int(n["c"]!), d = Int(n["d"]!)
                XCTAssertEqual(t, index < 3 ? 0 : index % 3)
                if index < 3 {
                    XCTAssertTrue((5...9).contains(c) && ((c - 2)...(c - 1)).contains(d) && (2...5).contains(a) && (2...4).contains(b))
                    XCTAssertLessThanOrEqual(a + b * (c - d), 9)
                } else if t == 2 {
                    XCTAssertTrue((3...9).contains(a) && (3...9).contains(b) && (2...6).contains(d))
                    XCTAssertEqual(c % d, 0); XCTAssertGreaterThanOrEqual(c, d); XCTAssertLessThanOrEqual(c, a * b)
                } else {
                    XCTAssertTrue((2...9).contains(a) && (2...9).contains(b) && (5...12).contains(c) && (1...(c - 1)).contains(d))
                }
                let steps = OrderOfOperations.spec.steps(n)
                XCTAssertEqual(steps.count, 6)
                let answer = [a + b * (c - d), (a + b) * c - d, a * b - c / d][t]
                XCTAssertEqual(steps[4].answer?.expected["x"], Double(answer))
                XCTAssertGreaterThanOrEqual(answer, 0)
                // the pick-one step names every wrong part and accepts only the right one
                let first = steps[1].answer!
                XCTAssertEqual(first.choices?.count, t == 0 ? 3 : 2)
                XCTAssertEqual(first.known.count, t == 0 ? 2 : 1)
                XCTAssertFalse(first.known.contains { $0.values == first.expected }, "the right part is never a slip")
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 3)
        let check = OrderOfOperations.spec.check
        XCTAssertEqual(check.map(\.index), [3, 4, 5, 6]); XCTAssertFalse(check.contains { $0.story })
        for (item, t) in zip(check, [0, 1, 2, 0]) {
            for _ in 0..<300 {
                let n = item.draw(OrderOfOperations.spec, using: &rng)
                XCTAssertTrue(item.when?(n) ?? true); XCTAssertEqual(n["t"], Double(t))
            }
        }
    }
}
