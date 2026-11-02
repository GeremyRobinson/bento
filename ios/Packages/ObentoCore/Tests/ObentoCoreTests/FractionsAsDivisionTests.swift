import XCTest
@testable import ObentoCore

final class FractionsAsDivisionTests: XCTestCase {
    private func move(_ l: inout LessonRun, _ box: String, _ v: Double) -> LessonRun.Outcome { l.set(box, v); return l.go() }
    private func type(_ l: inout LessonRun, _ t: String, _ b: String) -> LessonRun.Outcome {
        l.reset()
        l.active = "t"; for c in t { l.type(String(c)) }
        l.active = "b"; for c in b { l.type(String(c)) }
        return l.go()
    }

    /// The design's own: 3 subs shared by 6 friends: each gets 3/6 of a sub.
    func testWalkThroughTheDesign() {
        let spec = FractionsAsDivision.spec
        XCTAssertEqual(spec.id, "g5-fracdiv"); XCTAssertEqual(spec.title, "Fractions as division")
        let n = FractionsAsDivision.numbers(a: 3, b: 6, t: 3)
        let p = FractionsAsDivision.Parts(n)
        XCTAssertEqual(p.W, 48); XCTAssertEqual(p.pw, 8); XCTAssertEqual(p.shareBars, 1); XCTAssertEqual(p.named, "3 subs")
        XCTAssertEqual(spec.display(n), [.num(3), .op("÷"), .num(6)])
        XCTAssertEqual(spec.idea(n), "Sharing 3 by 6 is 3 ÷ 6, and each share is 3/6.")
        var l = LessonRun(spec, numbers: n)
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "3 subs, shared equally by 6 friends.")
        XCTAssertEqual(l.go(), .moved(1))

        // the cut: one piece per friend in every sub
        XCTAssertEqual(l.words.say, "3 subs, shared equally by 6 friends. Cut every one so each friend gets a piece. Drag the ruler, then cut.")
        XCTAssertEqual(l.words.action, "Cut")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture, ["ruler": 1])
        XCTAssertEqual(move(&l, "x", 4), .notYet("That’s 4 pieces in each. There are 6 friends."))
        XCTAssertEqual(move(&l, "x", 1.5), .notYet("The pieces must fill the whole bar."))
        XCTAssertEqual(move(&l, "x", 6), .moved(2))

        // the share: 3 pieces, one from every sub
        XCTAssertEqual(l.words.say, "Shade one friend’s share. Tap the pieces. Every friend gets the same.")
        XCTAssertEqual(l.words.hint, "Every sub gives each friend one piece.")
        XCTAssertEqual(l.picture, ["cut": 1, "share": 1])
        XCTAssertEqual(move(&l, "n", 1), .notYet("If each friend gets 1, 6 friends take 6. 12 are left over."))
        XCTAssertEqual(l.picture["ring"], 1, "a miss rings a piece of every sub")
        XCTAssertEqual(move(&l, "n", 4), .notYet("If each friend gets 4, 6 friends need 24. There are only 18."))
        XCTAssertEqual(move(&l, "n", 0), .notYet("If each friend gets 0, 6 friends take 0. 18 are left over."))
        XCTAssertEqual(move(&l, "n", 3), .moved(3))

        // the record: 3 ÷ 6 = [3]/[6]
        XCTAssertEqual(l.words.say, "How much is one share? Write it as a fraction of one sub.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.step.answer?.boxes, ["t", "b"])
        XCTAssertEqual(type(&l, "6", "3"), .notYet("Upside down: the top is how many pieces, the bottom is what size."))
        XCTAssertEqual(l.slips.last?.kind, "k0")
        XCTAssertEqual(type(&l, "1", "2"), .notYet("Same amount. Write it in sixths, the pieces you cut."))
        XCTAssertEqual(type(&l, "2", "6"), .notYet("Count the pieces in one share. Each is 1/6."))
        XCTAssertEqual(type(&l, "3", "6"), .moved(4))

        // the last words say why
        XCTAssertEqual(l.words.say, "Each friend gets 3/6 of a sub. Every sub gives each friend 1/6, and there are 3 of them.")
        XCTAssertEqual(l.go(), .newProblem)
    }

    /// More than a whole: 4 granola bars shared by 3 friends; fifths are 40 squares a whole.
    func testOverAWholeAndFifths() {
        let p = FractionsAsDivision.Parts(FractionsAsDivision.numbers(a: 4, b: 3, t: 2))
        XCTAssertEqual(p.shareBars, 2); XCTAssertEqual(p.pw, 16); XCTAssertEqual(p.named, "4 granola bars")
        var l = LessonRun(FractionsAsDivision.spec, numbers: FractionsAsDivision.numbers(a: 4, b: 3, t: 2))
        _ = l.go(); _ = move(&l, "x", 3)
        XCTAssertEqual(move(&l, "n", 2), .notYet("If each friend gets 2, 3 friends take 6. 6 are left over."))
        XCTAssertEqual(move(&l, "n", 4), .moved(3))
        XCTAssertEqual(type(&l, "3", "4"), .notYet("Upside down: the top is how many pieces, the bottom is what size."))
        XCTAssertEqual(type(&l, "8", "6"), .notYet("Same amount. Write it in thirds, the pieces you cut."))
        XCTAssertEqual(type(&l, "4", "3"), .moved(4))
        XCTAssertEqual(l.words.say, "Each friend gets 4/3 of a granola bar. Every granola bar gives each friend 1/3, and there are 4 of them.")
        let f = FractionsAsDivision.Parts(FractionsAsDivision.numbers(a: 2, b: 5, t: 0))
        XCTAssertEqual(f.W, 40); XCTAssertEqual(f.pw, 8); XCTAssertEqual(f.named, "2 sandwiches")
    }

    /// The preview's generator: 2 to 4 things, friends from 2, 3, 4, 5, 6, 8, never as many as things; more things
    /// than friends now and then.
    func testGenerator() {
        var rng = SeededRandom(seed: 5)
        var over = 0, under = 0, friends = Set<Int>(), things = Set<Int>()
        for i in 0..<600 {
            let p = FractionsAsDivision.Parts(FractionsAsDivision.spec.generate(&rng, i % 8))
            XCTAssertTrue((2...4).contains(p.a))
            XCTAssertTrue(FractionsAsDivision.friends.contains(p.b))
            XCTAssertNotEqual(p.a, p.b)
            XCTAssertEqual(p.W % p.b, 0, "every piece is a whole number of squares")
            if p.a > p.b { over += 1 } else { under += 1 }
            friends.insert(p.b); things.insert(p.t)
        }
        XCTAssertEqual(friends, Set(FractionsAsDivision.friends)); XCTAssertEqual(things, [0, 1, 2, 3])
        XCTAssertGreaterThan(over, 20); XCTAssertGreaterThan(under, over)
        let spec = FractionsAsDivision.spec
        var r = SeededRandom(seed: 1)
        let u = FractionsAsDivision.Parts(spec.check[0].draw(spec, using: &r))
        XCTAssertLessThan(u.a, u.b)
        let o = FractionsAsDivision.Parts(spec.check[1].draw(spec, using: &r))
        XCTAssertGreaterThan(o.a, o.b)
    }
}
