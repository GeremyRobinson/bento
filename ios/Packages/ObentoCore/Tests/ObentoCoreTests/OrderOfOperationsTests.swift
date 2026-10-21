import XCTest
@testable import ObentoCore

final class OrderOfOperationsTests: XCTestCase {
    func run(_ t: Int, _ a: Int, _ b: Int, _ c: Int, _ d: Int) -> LessonRun {
        LessonRun(OrderOfOperations.spec, numbers: OrderOfOperations.numbers(t: t, a: a, b: b, c: c, d: d))
    }
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for ch in s { l.type(String(ch)) } }

    /// The web lesson's reference, 3 + 4 × (6 − 2), worked on the paper: tap, write, tap, write, write.
    func testWalkThroughTheReference() {
        let spec = OrderOfOperations.spec
        XCTAssertEqual(spec.id, "g5-order"); XCTAssertEqual(spec.master, "order")
        XCTAssertEqual(spec.depends, ["g3-facts", "g3-divfacts"]); XCTAssertNil(spec.story)
        var l = run(0, 3, 4, 6, 2)
        XCTAssertEqual(l.display, [.num(3), .op("+"), .num(4), .op("×"), .text("("), .num(6), .op("−"), .num(2), .text(")"), .op("="), .text("?")])
        XCTAssertEqual(spec.idea(l.numbers), "Everyone uses the same order, so a problem has only one answer.")
        XCTAssertEqual(l.steps.count, 7)
        // the first words never say the problem again: it's written in the record
        XCTAssertEqual(l.words, StepWords(say: "What does it make?", hint: "Look at the signs and the parentheses.", action: "Let’s find out"))
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // tap the part that goes first: the tap sets the sign's place (+ 0, × 1, − 2); the web's slips by part
        XCTAssertEqual(l.words, StepWords(say: "Tap the part that goes first.", hint: "Find the parentheses: they go first.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 1])
        XCTAssertEqual(l.step.answer?.byHand, true); XCTAssertNil(l.step.answer?.choices)
        l.set("c", 0)
        XCTAssertEqual(l.go(), .notYet("Parentheses go first, then × and ÷, then + and −. Left to right is only for signs of the same kind."))
        l.set("c", 1)
        XCTAssertEqual(l.go(), .notYet("The parentheses make 6 − 2 one number, so it comes even before ×."))
        XCTAssertEqual(l.misses, 2)
        XCTAssertEqual(l.showAnswer(), "The parentheses go first: 6 − 2.")
        XCTAssertEqual(l.go(), .moved(2))

        // write it in the next line, where school writes it
        XCTAssertEqual(l.words, StepWords(say: "Write what the parentheses make.", hint: "Work out the inside of the parentheses.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 2])
        XCTAssertEqual(l.step.answer?.prompt, [.op("="), .num(3), .op("+"), .num(4), .op("×"), .box("x")])
        type(&l, "8"); XCTAssertEqual(l.go(), .notYet("Inside the parentheses it's −: 6 − 2."))
        type(&l, "3"); XCTAssertEqual(l.go(), .notYet("Not quite. The parentheses make 6 − 2 one number. What is it?"))
        XCTAssertEqual(l.showAnswer(), "Inside the parentheses: 6 − 2 = 4.")
        XCTAssertEqual(l.go(), .moved(3))

        // tap the part that goes next in 3 + 4 × 4
        XCTAssertEqual(l.words, StepWords(say: "Tap the part that goes next.", hint: "× comes before +.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 3])
        l.set("c", 0); XCTAssertEqual(l.go(), .notYet("× comes before +, so the + waits."))
        l.set("c", 1); XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words, StepWords(say: "Write what the × makes.", hint: "Multiply next, before adding.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 4])
        XCTAssertEqual(l.step.answer?.prompt, [.op("="), .num(3), .op("+"), .box("x")])
        type(&l, "28"); XCTAssertEqual(l.go(), .notYet("Multiply before you add. Do only 4 × 4 here."))
        XCTAssertEqual(l.showAnswer(), "Multiplication comes before addition. That makes 16.")
        XCTAssertEqual(l.go(), .moved(5))

        // the last part is the only one left: written, with the left-to-right warning
        XCTAssertEqual(l.words, StepWords(say: "Add last, and write the answer.", hint: "Add last. Left to right would give 28, which is wrong.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 5])
        XCTAssertEqual(l.step.answer?.prompt, [.op("="), .box("x")])
        type(&l, "48"); XCTAssertEqual(l.go(), .notYet("The sign is +: add 3."))
        XCTAssertEqual(l.showAnswer(), "3 + 16 = 19.")
        XCTAssertEqual(l.go(), .moved(6))

        // the last words say why
        XCTAssertEqual(l.words, StepWords(say: "Parentheses, then × and ÷, then + and −, so everyone gets one answer.",
                                          hint: "Everyone uses the same order, so a problem has only one answer.", action: "Next problem"))
        XCTAssertEqual(l.picture, ["at": 6])
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(l.steps[5].answer?.work, [.op("="), .num(19)])
    }

    func testTheWorking() {
        let w = OrderOfOperations.working(OrderOfOperations.numbers(t: 0, a: 3, b: 4, c: 6, d: 2))
        XCTAssertEqual(w.values, [4, 16, 19])
        XCTAssertEqual(w.lines[1], [.n(3), .op("+"), .n(4), .op("×"), .n(4)])
        XCTAssertEqual(w.lines[3], [.n(19)])
        // a sign's part: the numbers either side, a parenthesis's whole group
        XCTAssertEqual(OrderOfOperations.Working.signs(w.lines[0]), [1, 3, 6])
        XCTAssertEqual(OrderOfOperations.Working.span(w.lines[0], sign: 3), 2..<9)
        XCTAssertEqual(OrderOfOperations.Working.span(w.lines[0], sign: 6), 5..<8)
        let one = OrderOfOperations.working(OrderOfOperations.numbers(t: 1, a: 2, b: 3, c: 5, d: 1))
        XCTAssertEqual(OrderOfOperations.Working.span(one.lines[0], sign: 5), 0..<7)
    }

    func testShapeOne() {
        var l = run(1, 2, 3, 5, 1)  // (2 + 3) × 5 − 1
        XCTAssertEqual(l.words.say, "What does it make?")
        _ = l.go()
        XCTAssertEqual(l.words.hint, "Find the parentheses: they go first.")
        XCTAssertEqual(l.step.answer?.expected, ["c": 0])
        l.set("c", 2); XCTAssertEqual(l.go(), .notYet("The parentheses go first: 2 + 3. Then × comes before −."))
        l.set("c", 1); XCTAssertEqual(l.go(), .notYet("The parentheses go first: 2 + 3."))
        l.set("c", 0); XCTAssertEqual(l.go(), .moved(2))
        type(&l, "6"); XCTAssertEqual(l.go(), .notYet("Inside the parentheses it's +: 2 + 3."))
        type(&l, "5"); XCTAssertEqual(l.go(), .moved(3))
        l.set("c", 1); XCTAssertEqual(l.go(), .notYet("× comes before −, so the − waits."))
        l.set("c", 0); XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words.hint, "Multiply before subtracting.")
        type(&l, "20"); XCTAssertEqual(l.go(), .notYet("Multiply before you subtract: 5 × 5."))
        type(&l, "25"); XCTAssertEqual(l.go(), .moved(5))
        XCTAssertEqual(l.words.hint, "Subtract last.", "no left-to-right warning for (a + b) × c − d")
        type(&l, "26"); XCTAssertEqual(l.go(), .notYet("The sign is −, so take 1 away."))
        XCTAssertEqual(l.showAnswer(), "25 − 1 = 24.")
        XCTAssertEqual(l.go(), .moved(6))
        XCTAssertEqual(l.words.say, "Parentheses, then × and ÷, then + and −, so everyone gets one answer.")
    }

    func testShapeTwo() {
        var l = run(2, 6, 4, 8, 2)  // 6 × 4 − 8 ÷ 2
        XCTAssertEqual(l.display.last, .text("?"))
        _ = l.go()
        XCTAssertEqual(l.words.hint, "No parentheses, and × comes before −.")
        l.set("c", 1); XCTAssertEqual(l.go(), .notYet("× and ÷ come before −, so the − waits."))
        l.set("c", 2); XCTAssertEqual(l.go(), .notYet("× and ÷ are the same kind, so go left to right: × first."))
        XCTAssertEqual(l.showAnswer(), "× comes before −, so 6 × 4 goes first.")
        _ = l.go()
        XCTAssertEqual(l.words, StepWords(say: "Write what the × makes.", hint: "Multiply first.", action: "Check"))
        type(&l, "10"); XCTAssertEqual(l.go(), .notYet("That's 6 + 4. The sign is ×."))
        type(&l, "24"); XCTAssertEqual(l.go(), .moved(3))
        l.set("c", 0); XCTAssertEqual(l.go(), .notYet("÷ comes before −, so the − waits."))
        l.set("c", 1); XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words, StepWords(say: "Write what the ÷ makes.", hint: "Divide next, still before subtracting.", action: "Check"))
        XCTAssertEqual(l.step.answer?.prompt, [.op("="), .num(24), .op("−"), .box("x")])
        type(&l, "16"); XCTAssertEqual(l.go(), .notYet("The sign is ÷: how many 2s make 8?"))
        type(&l, "4"); XCTAssertEqual(l.go(), .moved(5))
        XCTAssertEqual(l.words.hint, "Subtract last. Left to right would give 8, which is wrong.")
        type(&l, "8"); XCTAssertEqual(l.go(), .notYet("Divide 8 ÷ 2 first, then subtract it from 24."))
        type(&l, "20"); XCTAssertEqual(l.go(), .moved(6))
        XCTAssertEqual(l.words.say, "× and ÷ before + and −, so everyone gets one answer.")

        // left to right that isn't whole: no warning, and the slip is still the exact number
        let m = run(2, 5, 3, 4, 2)  // 15 − 4 ÷ 2; left to right (15 − 4) ÷ 2 = 5.5
        XCTAssertEqual(m.steps[5].words.hint, "Subtract last.")
        XCTAssertEqual(m.steps[5].answer?.known.first?.values, ["x": 5.5])
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
                XCTAssertEqual(steps.count, 7)
                let answer = [a + b * (c - d), (a + b) * c - d, a * b - c / d][t]
                XCTAssertEqual(steps[5].answer?.expected["x"], Double(answer))
                XCTAssertEqual(OrderOfOperations.working(n).values.last, answer)
                XCTAssertGreaterThanOrEqual(answer, 0)
                // each tap step names every wrong sign in its line and accepts only the right one
                let w = OrderOfOperations.working(n)
                for (s, line) in [(1, 0), (3, 1)] {
                    let tap = steps[s].answer!
                    XCTAssertTrue(tap.byHand)
                    let signs = OrderOfOperations.Working.signs(w.lines[line]).indices
                    XCTAssertEqual(Set(tap.known.map { Int($0.values["c"]!) } + [Int(tap.expected["c"]!)]), Set(signs))
                    XCTAssertFalse(tap.known.contains { $0.values == tap.expected }, "the right part is never a slip")
                }
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
