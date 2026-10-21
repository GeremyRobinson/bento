import XCTest
@testable import ObentoCore

private func put(_ l: inout LessonRun, _ box: String, _ s: String) {
    l.reset()
    l.active = box
    for ch in s { l.type(String(ch)) }
}

final class FractionOfTests: XCTestCase {
    /// A hand move: its box set, checked as Cut or Take does.
    private func move(_ l: inout LessonRun, _ box: String, _ v: Int) -> LessonRun.Outcome { l.set(box, Double(v)); return l.go() }

    /// The web lesson's reference: 3/4 of 20 = 15.
    func testWalkThroughTheReference() {
        let n = FractionOf.numbers(n: 3, d: 4, W: 20)
        let spec = FractionOf.spec
        XCTAssertEqual(spec.id, "g5-fracof"); XCTAssertEqual(spec.master, "tape")
        XCTAssertEqual(spec.display(n), [.frac(.num(3), .num(4)), .text("of"), .num(20)])
        XCTAssertEqual(spec.idea(n), "The bottom says how many equal groups to make, and the top says how many to take.")
        XCTAssertEqual(spec.story?(n), "There are 20 marbles in a bag. 3/4 of them are blue. How many marbles are blue?")
        XCTAssertEqual(spec.depends, ["g3-divfacts", "g4-fracwhole"])

        var l = LessonRun(spec, numbers: n)
        XCTAssertEqual(l.steps.count, 5, "ask, cut, take, write, done")
        // the first words never repeat the problem: it's written once, as the picture's names
        XCTAssertEqual(l.words.say, "Each square is one thing. How many of them is that?")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.picture, [:])
        XCTAssertEqual(l.go(), .moved(1))

        // the cut: the ruler makes equal groups; its box is how many (the web's "groups")
        XCTAssertEqual(l.words.say, "Drag the ruler to make 4 equal groups, then cut.")
        XCTAssertEqual(l.words.hint, "The bottom says 4 equal groups.")
        XCTAssertEqual(l.words.action, "Cut")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture, ["ruler": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        XCTAssertEqual(move(&l, "x", 2), .notYet("That makes 2 groups. The bottom says 4."))
        XCTAssertEqual(move(&l, "x", 5), .notYet("That makes 5 groups. The bottom says 4."))
        XCTAssertEqual(l.misses, 2)
        XCTAssertEqual(l.showAnswer(), "The bottom number tells how many equal groups: 4. That makes 5 in each.")
        l.reset()
        XCTAssertEqual(move(&l, "x", 4), .moved(2))

        // the take: groups tapped, then Take
        XCTAssertEqual(l.words.say, "Tap 3 groups to take them.")
        XCTAssertEqual(l.words.hint, "The top says take 3 of them.")
        XCTAssertEqual(l.words.action, "Take")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture, ["cut": 1, "tap": 1])
        XCTAssertEqual(move(&l, "t", 0), .notYet("Tap a group to take it."))
        XCTAssertEqual(l.misses, 0, "nothing tapped isn’t a miss")
        XCTAssertEqual(move(&l, "t", 1), .notYet("That’s 1 group. The top says take 3."))
        XCTAssertEqual(move(&l, "t", 4), .notYet("That’s 4 groups. The top says take 3."))
        XCTAssertEqual(move(&l, "t", 3), .moved(3))

        // the record: the answer typed, the rest written for the child; the web's slips
        XCTAssertEqual(l.words.say, "How many are taken? Write it.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.step.answer?.boxes, ["x"])
        XCTAssertEqual(l.picture, ["cut": 1, "taken": 1])
        put(&l, "x", "240")
        XCTAssertEqual(l.go(), .notYet("Split 20 into 4 equal groups: divide."))
        put(&l, "x", "8")
        XCTAssertEqual(l.go(), .notYet("Take 3 groups of 5: that’s multiplying."))
        put(&l, "x", "5")
        XCTAssertEqual(l.go(), .notYet("That’s the groups left over. The top says to take 3 groups."))
        put(&l, "x", "14")
        XCTAssertEqual(l.go(), .notYet("Not quite. 3 groups of 5."))
        XCTAssertEqual(l.picture["ring"], 1, "a miss rings the taken groups' counts")
        XCTAssertEqual(l.showAnswer(), "3 groups of 5. That makes 15.")
        XCTAssertEqual(l.go(), .moved(4))

        // the last words say why
        XCTAssertEqual(l.words.say, "The bottom made 4 equal groups. The top took 3.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture, ["cut": 1, "taken": 1, "done": 1])
        XCTAssertEqual(l.go(), .newProblem)

        XCTAssertEqual(l.steps[3].answer?.work, [.frac(.num(3), .num(4)), .text("of"), .num(20), .op("="), .num(20), .op("÷"), .num(4),
                                                 .op("×"), .num(3), .op("="), .num(15)])
        XCTAssertEqual(l.steps.map(\.picture), [[:], ["ruler": 1], ["cut": 1, "tap": 1], ["cut": 1, "taken": 1], ["cut": 1, "taken": 1, "done": 1]])
    }

    /// One group: the take is dropped (the one group is the answer), and the record has no × 1.
    func testOneGroup() {
        var l = LessonRun(FractionOf.spec, numbers: FractionOf.numbers(n: 1, d: 3, W: 12))
        XCTAssertEqual(l.steps.map(\.words.say), ["Each square is one thing. How many of them is that?",
                                                  "Drag the ruler to make 3 equal groups, then cut.",
                                                  "How many in one group? Write it.",
                                                  "The bottom made 3 equal groups. The top took 1."])
        XCTAssertEqual(l.steps[2].answer?.prompt, [.frac(.num(1), .num(3)), .text("of"), .num(12), .op("="), .num(12), .op("÷"), .num(3), .op("="), .box("x")])
        XCTAssertEqual(l.steps[2].answer?.known.map(\.message), ["Split 12 into 3 equal groups: divide.", "Take 1 group of 4: that’s multiplying.",
                                                                 "That’s the groups left over. The top says to take 1 group."])
        _ = l.go()
        XCTAssertEqual(move(&l, "x", 6), .notYet("That makes 6 groups. The bottom says 3."))
        XCTAssertEqual(move(&l, "x", 3), .moved(2))
        put(&l, "x", "36")
        XCTAssertEqual(l.go(), .notYet("Split 12 into 3 equal groups: divide."))
        put(&l, "x", "4")
        XCTAssertEqual(l.go(), .moved(3))
    }

    /// The ruler snaps to every group size that divides W: Cut is right only at d groups.
    func testTheRulerAtEverySize() {
        XCTAssertEqual(FractionOf.groupSizes(20), [1, 2, 4, 5, 10])
        XCTAssertEqual(FractionOf.readout(W: 20, each: 5), "fourths, 5 in each")
        XCTAssertEqual(FractionOf.readout(W: 20, each: 10), "halves, 10 in each")
        XCTAssertEqual(FractionOf.readout(W: 108, each: 12), "ninths, 12 in each")
        for d in 2...9 {
            for k in 2...12 {
                let W = d * k, task = LessonRun(FractionOf.spec, numbers: FractionOf.numbers(n: 1, d: d, W: W)).steps[1].answer!
                var right = 0
                for each in FractionOf.groupSizes(W) {
                    if task.check!(["x": Double(W / each)]) == .right { right += 1; XCTAssertEqual(each, k) }
                }
                XCTAssertEqual(right, 1, "\(d) \(W)")
            }
        }
    }

    /// 2/3 of 6 makes 4: an added slip (2 + 2) would be the answer, so it isn't one.
    func testASlipThatIsTheAnswerIsDropped() {
        let l = LessonRun(FractionOf.spec, numbers: FractionOf.numbers(n: 2, d: 3, W: 6))
        XCTAssertEqual(l.steps[3].answer?.known.map(\.values), [["x": 36], ["x": 2]])
    }

    /// 8/9 of 108 = 96, the biggest the generator makes.
    func testTheBiggestProblem() {
        var l = LessonRun(FractionOf.spec, numbers: FractionOf.numbers(n: 8, d: 9, W: 108))
        _ = l.go()
        XCTAssertEqual(move(&l, "x", 9), .moved(2))
        XCTAssertEqual(move(&l, "t", 8), .moved(3))
        put(&l, "x", "96")
        XCTAssertEqual(l.go(), .moved(4))
    }

    /// Told as its story: "Pick what to do" first (×), then the same steps.
    func testTheStory() {
        var l = LessonRun(FractionOf.spec, numbers: FractionOf.numbers(n: 2, d: 5, W: 30), story: true)
        XCTAssertEqual(l.steps.count, 6)
        l.choose(Int(l.step.answer?.expected["c"] ?? 0))
        XCTAssertEqual(l.go(), .moved(1))
        l.skipAsk()
        XCTAssertEqual(l.index, 2)
        XCTAssertEqual(move(&l, "x", 5), .moved(3))
        XCTAssertEqual(move(&l, "t", 2), .moved(4))
        put(&l, "x", "12")
        XCTAssertEqual(l.go(), .moved(5))
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 5)
        for index in [0, 1, 2, 3, 7] {
            for _ in 0..<300 {
                let p = FractionOf.spec.generate(&rng, index)
                let n = Int(p["n"]!), d = Int(p["d"]!), W = Int(p["W"]!)
                XCTAssertEqual(W % d, 0)
                if index < 3 {
                    XCTAssertEqual(n, 1); XCTAssertTrue((2...5).contains(d)); XCTAssertTrue((2...6).contains(W / d))
                } else {
                    XCTAssertTrue((2...9).contains(d)); XCTAssertTrue((1..<d).contains(n)); XCTAssertEqual(gcd(n, d), 1)
                    XCTAssertTrue((2...12).contains(W / d))
                }
                // the answer is the web oracle's, its slips never the answer, and Show me on every step gets through
                var l = LessonRun(FractionOf.spec, numbers: p)
                let write = l.steps[l.steps.count - 2].answer!
                XCTAssertEqual(write.expected["x"], Double(W * n / d))
                XCTAssertFalse(write.known.contains { $0.values["x"] == Double(W * n / d) })
                for _ in 0..<(l.steps.count - 1) { _ = l.showAnswer(); XCTAssertEqual(l.go(), .moved(l.index)) }
                XCTAssertEqual(l.go(), .newProblem)
            }
        }
    }

    func testSkillCheckDrawsKeepTheirRecipe() {
        let spec = FractionOf.spec
        XCTAssertEqual(spec.check.map(\.index), [3, 3, 3, 3])
        XCTAssertEqual(spec.check.map(\.story), [false, false, false, true])
        var rng = SeededRandom(seed: 21)
        for item in spec.check {
            for _ in 0..<300 {
                let p = item.draw(spec, using: &rng)
                XCTAssertTrue(item.when?(p) ?? true)
            }
        }
    }
}
