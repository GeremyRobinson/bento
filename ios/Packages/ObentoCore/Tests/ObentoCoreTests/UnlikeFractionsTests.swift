import XCTest
@testable import ObentoCore

final class UnlikeFractionsTests: XCTestCase {
    /// Clears the step, then types each box's value in turn.
    private func fill(_ l: inout LessonRun, _ values: [(String, String)]) {
        l.reset()
        for (box, s) in values { l.active = box; for ch in s { l.type(String(ch)) } }
    }

    func testAddWalkThroughTheReference() {
        // the web's reference: 1/2 + 1/3 = 3/6 + 2/6 = 5/6
        let n = UnlikeFractions.numbers(a: 1, b: 2, c: 1, d: 3, minus: false)
        XCTAssertEqual(n["L"], 6); XCTAssertEqual(n["A"], 3); XCTAssertEqual(n["C"], 2); XCTAssertEqual(n["S"], 5)
        var l = LessonRun(AddingFractions.spec, numbers: n)
        XCTAssertEqual(l.display, [.frac(.num(1), .num(2)), .op("+"), .frac(.num(1), .num(3))])
        XCTAssertEqual(l.steps.count, 7)
        XCTAssertEqual(l.words.say, "What is 1/2 + 1/3?")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.go(), .moved(1))

        // lcd
        XCTAssertEqual(l.words.say, "Smallest number that both 2 and 3 go into:")
        XCTAssertEqual(l.words.hint, "Both 2 and 3 go into 6, so cut both bars into sixths.")
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        fill(&l, [("x", "5")])
        XCTAssertEqual(l.go(), .notYet("You added 2 + 3. The bottom number is the size of the pieces, so it doesn’t get added. Find a number that 2 and 3 both go into evenly."))
        fill(&l, [("x", "12")])
        XCTAssertEqual(l.go(), .notYet("12 works, since 2 and 3 both go into it. Find a smaller one. It keeps the numbers easier."))
        fill(&l, [("x", "4")])
        XCTAssertEqual(l.go(), .notYet("3 doesn’t go into 4 evenly (4 ÷ 3 has a remainder). Both bottom numbers must divide into it."))
        fill(&l, [("x", "0")])
        XCTAssertEqual(l.go(), .notYet("Type a number first."))
        XCTAssertEqual(l.misses, 4)
        XCTAssertEqual(l.showAnswer(), "Counting by 3s, the first number 2 also goes into is 6.")
        XCTAssertEqual(l.go(), .moved(2))

        // first
        XCTAssertEqual(l.words.say, "Rewrite the first fraction")
        XCTAssertEqual(l.words.hint, "Each half is 3 sixths.")
        fill(&l, [("x", "1")])
        XCTAssertEqual(l.go(), .notYet("You changed the bottom from 2 to 6, but kept the top as 1. Whatever you multiply the bottom by, multiply the top by the same number."))
        fill(&l, [("x", "5")])
        XCTAssertEqual(l.go(), .notYet("You added 4 to the top because the bottom went up by 4. A fraction stays the same only when you multiply top and bottom by the same number. What times 2 makes 6?"))
        fill(&l, [("x", "2")])
        XCTAssertEqual(l.go(), .notYet("2 × ? = 6. Then multiply the top, 1, by that number."))
        XCTAssertEqual(l.showAnswer(), "2 × 3 = 6, so 1 × 3 = 3.")
        XCTAssertEqual(l.go(), .moved(3))

        // second
        XCTAssertEqual(l.words.say, "Rewrite the second fraction")
        XCTAssertEqual(l.words.hint, "Each third is 2 sixths.")
        XCTAssertEqual(l.step.answer?.hint, "3 × ? = 6. Whatever you multiply the bottom by, do the same to the top.")
        fill(&l, [("x", "4")])
        XCTAssertEqual(l.go(), .notYet("You added 3 to the top because the bottom went up by 3. A fraction stays the same only when you multiply top and bottom by the same number. What times 3 makes 6?"))
        XCTAssertEqual(l.showAnswer(), "3 × 2 = 6, so 1 × 2 = 2.")
        XCTAssertEqual(l.go(), .moved(4))

        // add
        XCTAssertEqual(l.words.say, "Add")
        XCTAssertEqual(l.words.hint, "Same-size pieces now, so add the tops. The bottom stays 6.")
        fill(&l, [("n", "5")])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        fill(&l, [("n", "5"), ("d", "12")])
        XCTAssertEqual(l.go(), .notYet("You added the bottoms too (6 + 6). The pieces are already the same size, 6ths, so the bottom stays 6. Picture a pizza: 3 slices plus 2 slices is 5 slices, still 6ths."))
        fill(&l, [("n", "5"), ("d", "7")])
        XCTAssertEqual(l.go(), .notYet("When the bottoms match, the bottom stays the same: 6. Only the tops get added."))
        fill(&l, [("n", "1"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("You subtracted. Look at the sign: this one is a plus."))
        fill(&l, [("n", "4"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("The bottom is right. Check the top: 3 + 2 = ?"))
        XCTAssertEqual(l.showAnswer(), "3 + 2 = 5, and the bottom stays 6.")
        XCTAssertEqual(l.go(), .moved(5))

        // simplify: 5/6 is already simplest
        XCTAssertEqual(l.words.say, "Simplify")
        XCTAssertEqual(l.words.hint, "It’s already as simple as it gets.")
        XCTAssertEqual(l.step.answer?.boxes, ["n", "d"])
        XCTAssertEqual(l.step.answer?.hint, "No number (other than 1) divides both 5 and 6. It’s already simplest.")
        fill(&l, [("n", "10"), ("d", "12")])
        XCTAssertEqual(l.go(), .notYet("Same amount. 10/12 can still be simplified. Both 10 and 12 divide by 2."))
        fill(&l, [("n", "4"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("That’s not equal to 5/6. Divide the top and the bottom by the same number."))
        XCTAssertEqual(l.showAnswer(), "It was already as simple as it gets.")
        XCTAssertEqual(l.go(), .moved(6))

        XCTAssertEqual(l.words.say, "1/2 + 1/3 = 5/6.")
        XCTAssertEqual(l.words.hint, "The bottom is the size of the pieces, and only same-size pieces can be added.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.go(), .newProblem)

        // the finished work lines
        XCTAssertEqual(l.steps[1].answer?.work, [.text("LCD of"), .num(2), .text("and"), .num(3), .text("is"), .num(6)])
        XCTAssertEqual(l.steps[2].answer?.work, [.frac(.num(1), .num(2)), .op("="), .frac(.num(3), .num(6))])
        XCTAssertEqual(l.steps[3].answer?.work, [.frac(.num(1), .num(3)), .op("="), .frac(.num(2), .num(6))])
        XCTAssertEqual(l.steps[4].answer?.work, [.frac(.num(3), .num(6)), .op("+"), .frac(.num(2), .num(6)), .op("="), .frac(.num(5), .num(6))])
        XCTAssertEqual(l.steps[5].answer?.work, [.frac(.num(5), .num(6)), .op("="), .frac(.num(5), .num(6))])

        // the picture, step by step
        XCTAssertEqual(l.steps.map(\.picture), [
            [:], ["focus": 3], ["cut": 1, "focus": 1], ["cut": 1, "first": 1, "focus": 2],
            ["cut": 1, "first": 1, "second": 1, "focus": 3], ["cut": 1, "first": 1, "second": 1, "combine": 1, "focus": 4],
            ["cut": 1, "first": 1, "second": 1, "combine": 1, "answer": 0],
        ])
        XCTAssertEqual(AddingFractions.spec.story?(n), "You walked 1/2 of a mile to the park and then 1/3 of a mile to the store. How far did you walk in all?")
        XCTAssertEqual(AddingFractions.spec.idea(n), "The bottom is the size of the pieces, and only same-size pieces can be added.")
        XCTAssertEqual(AddingFractions.spec.master, "tape")
    }

    func testSubWalkThroughTheReference() {
        // 1/2 − 1/3 = 3/6 − 2/6 = 1/6
        let n = UnlikeFractions.numbers(a: 1, b: 2, c: 1, d: 3, minus: true)
        var l = LessonRun(SubtractingFractions.spec, numbers: n)
        XCTAssertEqual(l.display, [.frac(.num(1), .num(2)), .op("−"), .frac(.num(1), .num(3))])
        XCTAssertEqual(l.words.say, "What is 1/2 − 1/3?")
        _ = l.go()
        fill(&l, [("x", "1")])
        XCTAssertEqual(l.go(), .notYet("You subtracted 3 − 2. The bottom number is the size of the pieces, so it doesn’t get subtracted. Find a number that 2 and 3 both go into evenly."))
        fill(&l, [("x", "5")])
        XCTAssertEqual(l.go(), .notYet("You added 2 + 3. The bottom number is the size of the pieces, so it doesn’t get added. Find a number that 2 and 3 both go into evenly."))
        fill(&l, [("x", "6")]); XCTAssertEqual(l.go(), .moved(2))
        fill(&l, [("x", "3")]); XCTAssertEqual(l.go(), .moved(3))
        fill(&l, [("x", "2")]); XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words.say, "Subtract")
        XCTAssertEqual(l.words.hint, "Same-size pieces now, so take away. The bottom stays 6.")
        XCTAssertEqual(l.step.answer?.hint, "The pieces are the same size now, so only the tops get taken away. Does the size of a piece change?")
        fill(&l, [("n", "1"), ("d", "0")])
        XCTAssertEqual(l.go(), .notYet("You subtracted the bottoms too (6 − 6 = 0). The pieces are already the same size, 6ths, so the bottom stays 6. Picture a pizza: 3 slices take away 2 is 1 slices, still 6ths."))
        fill(&l, [("n", "1"), ("d", "5")])
        XCTAssertEqual(l.go(), .notYet("When the bottoms match, the bottom stays the same: 6. Only the tops get subtracted."))
        fill(&l, [("n", "5"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("You added 3 + 2. Look at the sign: this one is a minus."))
        XCTAssertEqual(l.showAnswer(), "3 − 2 = 1, and the bottom stays 6.")
        XCTAssertEqual(l.go(), .moved(5))
        fill(&l, [("n", "1"), ("d", "6")]); XCTAssertEqual(l.go(), .moved(6))
        XCTAssertEqual(l.words.say, "1/2 − 1/3 = 1/6.")
        XCTAssertEqual(l.words.hint, "Only same-size pieces can be taken away, so the bottoms have to match first.")
        XCTAssertEqual(SubtractingFractions.spec.story?(n), "There was 1/2 of a cake left. The family ate 1/3 of a cake. How much cake is left now?")
    }

    func testMixWalkThroughTheReference() {
        // 2/3 + 1/4 = 8/12 + 3/12 = 11/12
        let n = UnlikeFractions.numbers(a: 2, b: 3, c: 1, d: 4, minus: false)
        var l = LessonRun(AddAndSubtract.spec, numbers: n)
        XCTAssertEqual(l.words.say, "What is 2/3 + 1/4?")
        _ = l.go()
        XCTAssertEqual(l.words.hint, "Both 3 and 4 go into 12, so cut both bars into twelfths.")
        fill(&l, [("x", "7")])
        XCTAssertEqual(l.go(), .notYet("You added 3 + 4. The bottom number is the size of the pieces, so it doesn’t get added. Find a number that 3 and 4 both go into evenly."))
        fill(&l, [("x", "24")])
        XCTAssertEqual(l.go(), .notYet("24 works, since 3 and 4 both go into it. Find a smaller one. It keeps the numbers easier."))
        fill(&l, [("x", "9")])
        XCTAssertEqual(l.go(), .notYet("4 doesn’t go into 9 evenly (9 ÷ 4 has a remainder). Both bottom numbers must divide into it."))
        XCTAssertEqual(l.showAnswer(), "Counting by 4s, the first number 3 also goes into is 12.")
        _ = l.go()
        XCTAssertEqual(l.words.hint, "Each third is 4 twelfths.")
        fill(&l, [("x", "11")])
        XCTAssertEqual(l.go(), .notYet("You added 9 to the top because the bottom went up by 9. A fraction stays the same only when you multiply top and bottom by the same number. What times 3 makes 12?"))
        fill(&l, [("x", "8")]); _ = l.go()
        XCTAssertEqual(l.words.hint, "Each fourth is 3 twelfths.")
        fill(&l, [("x", "3")]); _ = l.go()
        fill(&l, [("n", "5"), ("d", "12")])
        XCTAssertEqual(l.go(), .notYet("You subtracted. Look at the sign: this one is a plus."))
        fill(&l, [("n", "11"), ("d", "12")]); _ = l.go()
        fill(&l, [("n", "11"), ("d", "12")]); _ = l.go()
        XCTAssertEqual(l.words.say, "2/3 + 1/4 = 11/12.")
        XCTAssertEqual(l.words.hint, "Adding and taking away both need same-size pieces, so the first steps never change.")
        XCTAssertEqual(AddAndSubtract.spec.story?(n), "A plant grew 2/3 inch in May and 1/4 inch in June. How much did it grow in all?")
        XCTAssertEqual(AddAndSubtract.spec.story?(UnlikeFractions.numbers(a: 2, b: 3, c: 1, d: 4, minus: true)),
                       "A jug had 2/3 gallon of water. You poured out 1/4 gallon. How much is left?")
    }

    func testSimplifyMixedAndReducible() {
        // 3/4 + 5/6 = 9/12 + 10/12 = 19/12 = 1 7/12
        let m = LessonRun(AddingFractions.spec, numbers: UnlikeFractions.numbers(a: 3, b: 4, c: 5, d: 6, minus: false))
        let s = m.steps[5]
        XCTAssertEqual(s.words.hint, "Every 12 pieces make one whole.")
        XCTAssertEqual(s.answer?.boxes, ["w", "n", "d"])
        XCTAssertEqual(s.answer?.hint, "19 ÷ 12 = 1 remainder 7. The remainder goes on top.")
        XCTAssertEqual(s.answer?.explain, "19 ÷ 12 = 1 remainder 7, then simplify.")
        XCTAssertEqual(s.answer?.work, [.frac(.num(19), .num(12)), .op("="), .num(1), .frac(.num(7), .num(12))])
        let check = s.answer!.check!
        XCTAssertEqual(check(["w": 1, "n": 7, "d": 12]), .right)
        XCTAssertEqual(check(["w": 0, "n": 19, "d": 12]), .soft("That’s the right amount. Now write it as a mixed number. How many whole 12s fit into 19?"))
        XCTAssertEqual(check(["w": 1, "n": 14, "d": 24]), .wrong("Same amount. 14/24 can still be simplified. Both 14 and 24 divide by 2."))
        XCTAssertEqual(check(["w": 1, "n": 5, "d": 12]), .wrong("That’s not equal to 19/12. How many whole 12s fit into 19? That’s the whole number. What’s left over goes on top."))
        XCTAssertEqual(check(["w": 1, "n": 7, "d": 0]), .soft("The bottom can’t be 0."))
        XCTAssertEqual(check(["w": 1, "n": 7]), .soft("Fill in the bottom number too."))
        XCTAssertEqual(m.steps[6].words.say, "3/4 + 5/6 = 1 7/12.")
        XCTAssertEqual(m.steps[6].picture["answer"], 1)

        // a take-away that simplifies: 1/2 − 1/6 = 3/6 − 1/6 = 2/6 = 1/3
        var l = LessonRun(SubtractingFractions.spec, numbers: UnlikeFractions.numbers(a: 1, b: 2, c: 1, d: 6, minus: true))
        for _ in 0..<5 { _ = l.showAnswer(); _ = l.go() }
        XCTAssertEqual(l.words.hint, "Divide the top and the bottom by 2.")
        XCTAssertEqual(l.step.answer?.hint, "Both 2 and 6 can be divided by 2.")
        XCTAssertEqual(l.step.answer?.explain, "Divide top and bottom by 2.")
        XCTAssertEqual(l.step.answer?.expected, ["n": 1, "d": 3])
        fill(&l, [("n", "2"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("Same amount. 2/6 can still be simplified. Both 2 and 6 divide by 2."))
        fill(&l, [("n", "4"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("That’s not equal to 2/6. Divide the top and the bottom by the same number."))
        fill(&l, [("n", "1"), ("d", "3")])
        XCTAssertEqual(l.go(), .moved(6))
        XCTAssertEqual(l.words.say, "1/2 − 1/6 = 1/3.")

        // the bar already in sixths: 6 ÷ 6 = 1 sixth each, and the rewrite keeps its top
        XCTAssertEqual(l.steps[3].words.hint, "Each sixth is 1 sixth.")
        XCTAssertEqual(l.steps[3].answer?.expected, ["x": 1])
    }

    func testWebPictureNumbers() {
        // the web's tape test: 3/4 − 1/6 has L 12, A 9, C 2, S 7
        let n = UnlikeFractions.numbers(a: 3, b: 4, c: 1, d: 6, minus: true)
        XCTAssertEqual(n["L"], 12); XCTAssertEqual(n["A"], 9); XCTAssertEqual(n["C"], 2); XCTAssertEqual(n["S"], 7)
        XCTAssertEqual(UnlikeFractions.mixedLabel(19, 12), "1 7/12")
        XCTAssertEqual(UnlikeFractions.mixedLabel(4, 6), "2/3")
        XCTAssertEqual(UnlikeFractions.pieceName(22), "22nds")
        XCTAssertEqual(UnlikeFractions.pieceName(21, false), "21st")
    }

    private func checkInvariants(_ n: Numbers, index: Int, minus: Bool) {
        let a = Int(n["a"]!), b = Int(n["b"]!), c = Int(n["c"]!), d = Int(n["d"]!)
        let L = Int(n["L"]!), A = Int(n["A"]!), C = Int(n["C"]!), S = Int(n["S"]!)
        XCTAssertTrue((2...12).contains(b) && (2...12).contains(d) && b != d)
        XCTAssertTrue(L <= 24 && L % b == 0 && L % d == 0 && L == b * d / gcd(b, d))
        XCTAssertTrue(a >= 1 && a < b && c >= 1 && c < d && gcd(a, b) == 1 && gcd(c, d) == 1)
        XCTAssertEqual(A, a * L / b); XCTAssertEqual(C, c * L / d)
        XCTAssertEqual(n["minus"], minus ? 1 : 0)
        XCTAssertEqual(S, minus ? A - C : A + C)
        XCTAssertGreaterThan(S, 0)
        if index == 0 { XCTAssertTrue(b % d == 0 || d % b == 0, "the first problem is the easy kind") }
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 17)
        for index in 0...5 {
            for _ in 0..<300 {
                checkInvariants(AddingFractions.spec.generate(&rng, index), index: index, minus: false)
                checkInvariants(SubtractingFractions.spec.generate(&rng, index), index: index, minus: true)
                checkInvariants(AddAndSubtract.spec.generate(&rng, index), index: index, minus: index % 2 == 1)
            }
        }
        // every generated problem walks through with Show me on each step
        for index in 0...5 {
            for spec in [AddingFractions.spec, SubtractingFractions.spec, AddAndSubtract.spec] {
                var l = LessonRun.fresh(spec, using: &rng, index: index)
                var outcome = l.go()
                while outcome != .newProblem {
                    _ = l.showAnswer()
                    outcome = l.go()
                    if case .notYet(let why) = outcome { XCTFail("\(spec.id) \(l.numbers): \(why)"); break }
                }
            }
        }
    }

    func testSkillChecksDrawWhatTheyAskFor() {
        var rng = SeededRandom(seed: 23)
        for spec in [AddingFractions.spec, SubtractingFractions.spec, AddAndSubtract.spec] {
            XCTAssertEqual(spec.check.count, 4)
            for (k, item) in spec.check.enumerated() {
                // like the web (check-kit: up to 50 redraws, then the last draw stands), a rare item can miss its
                // condition; "the answer simplifies" holds for only about 1 problem in 10, so allow a few in 300
                var misses = 0
                for _ in 0..<300 where !(item.when?(item.draw(spec, using: &rng)) ?? true) { misses += 1 }
                XCTAssertLessThanOrEqual(misses, 6, "\(spec.id) item \(k) (i\(item.index)) missed \(misses) of 300")
            }
        }
        XCTAssertEqual(AddingFractions.spec.check.map(\.index), [1, 3, 3, 4])
        XCTAssertEqual(AddingFractions.spec.check.map(\.story), [false, false, false, true])
        XCTAssertEqual(SubtractingFractions.spec.check.map(\.story), [false, false, false, true])
        XCTAssertEqual(AddAndSubtract.spec.check.map(\.index), [2, 3, 4, 5])
        XCTAssertEqual(AddingFractions.spec.depends, ["g4-equiv", "g4-likefrac", "g4-factors"])
        XCTAssertEqual(SubtractingFractions.spec.depends, ["add"])
        XCTAssertEqual(AddAndSubtract.spec.depends, ["add", "sub"])
    }
}
