import XCTest
@testable import ObentoCore

/// 2nd grade, chapter 6: Time and money (design/grade2.md, the preview design/prototype/grade2-ch6.html).
final class TimeMoney2Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(77 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testSpoken() {
        XCTAssertEqual(Spoken.text("That's 3:05. Keep going."), "That's 3 oh 5. Keep going.")
        XCTAssertEqual(Spoken.text("Make it 7:45."), "Make it 7 45.")
        XCTAssertEqual(Spoken.text("School ends in the afternoon: p.m."), "School ends in the afternoon: P M")
        XCTAssertEqual(Spoken.text("Ben has 93¢."), "Ben has 93 cents.")
        XCTAssertEqual(Spoken.text("A $5 bill is 5 dollars."), "A 5 dollar bill is 5 dollars.")
        XCTAssertEqual(Spoken.text("Slide in the $10 bills."), "Slide in the 10 dollar bills.")
        XCTAssertEqual(Spoken.text("Keep the $20 you already counted and count on."), "Keep the 20 dollars you already counted and count on.")
        XCTAssertEqual(Spoken.text("It costs $1.35."), "It costs 1 dollar and 35 cents.")
        XCTAssertEqual(Spoken.text("That's 8:30."), "That's half past 8.")
    }

    func testTime() {
        var l = LessonRun(Time5.spec, numbers: Time5.numbers(hour: 3, minute: 25))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap the hour.")
        XCTAssertEqual(move(&l, ["h": 4]), .notYet("The short hand is past 3 but has not reached 4 yet, so the hour is still 3."))
        XCTAssertEqual(move(&l, ["h": 5]), .notYet("That's the long hand. The hour hand is the short one."))
        XCTAssertEqual(move(&l, ["h": 9]), .notYet("Find the short hand. Which number has it just passed?"))
        XCTAssertEqual(move(&l, ["h": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Trace from 12 to the long hand.")
        XCTAssertEqual(move(&l, ["n": -1]), .notYet("Start at 12."))
        XCTAssertEqual(move(&l, ["n": -2]), .notYet("Clocks go this way."))
        XCTAssertEqual(move(&l, ["n": 6]), .notYet("That's 30. Stop at the long hand."))
        XCTAssertEqual(move(&l, ["n": 3]), .notYet("Keep going to the long hand."))
        XCTAssertEqual(move(&l, ["n": 5]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the time.")
        XCTAssertEqual(move(&l, ["x": 4, "y": 25]), .notYet("The short hand has not reached 4 yet, so the hour is 3."))
        XCTAssertEqual(move(&l, ["x": 3, "y": 5]), .notYet("The long hand on 5 means 25 minutes."))
        XCTAssertEqual(move(&l, ["x": 5, "y": 15]), .notYet("The short hand gives the hour and the long hand gives the minutes."))
        XCTAssertEqual(move(&l, ["x": 3, "y": 20]), .notYet("The hour from the short hand goes first, then the minutes you counted."))
        XCTAssertEqual(move(&l, ["x": 3, "y": 25]), .moved(3))
        XCTAssertEqual(l.words.say, "The long hand moves 5 minutes from one number to the next.")

        var o = LessonRun(Time5.spec, numbers: Time5.numbers(hour: 7, minute: 0))
        XCTAssertEqual(move(&o, ["h": 12]), .notYet("That's the long hand. The hour hand is the short one."))
        XCTAssertEqual(move(&o, ["h": 8]), .notYet("Find the short hand. Which number does it point to?"))
        XCTAssertEqual(move(&o, ["h": 7]), .moved(1))
        XCTAssertEqual(move(&o, ["n": 2]), .notYet("On 12, no minutes have gone by."))
        XCTAssertEqual(move(&o, ["n": 0]), .moved(2))
        XCTAssertEqual(move(&o, ["x": 7, "y": 12]), .notYet("The long hand on 12 means 0 minutes."))

        var a = LessonRun(Time5.spec, numbers: Time5.numbers(kind: .ampm, hour: 2, minute: 15, e: 5))
        XCTAssertEqual(a.steps.count, 5)
        XCTAssertEqual(a.words.say, "School ends. Tap the hour.")
        XCTAssertEqual(move(&a, ["h": 2]), .moved(1))
        XCTAssertEqual(move(&a, ["n": 3]), .moved(2))
        XCTAssertEqual(move(&a, ["x": 2, "y": 15]), .moved(3))
        XCTAssertEqual(a.words.say, "School ends. Tap a.m. or p.m.")
        XCTAssertEqual(move(&a, ["c": 0]), .notYet("School ends in the afternoon: p.m."))
        XCTAssertEqual(move(&a, ["c": 1]), .moved(4))
        XCTAssertEqual(a.words.say, "School ends. The long hand moves 5 minutes from one number to the next.")

        var s = LessonRun(Time5.spec, numbers: Time5.numbers(kind: .set, hour: 3, minute: 25))
        XCTAssertEqual(s.steps.count, 2)
        XCTAssertEqual(s.words.say, "Turn the long hand to this time.")
        XCTAssertEqual(move(&s, ["t": 6]), .notYet("That's 3:30. Back one number."))
        XCTAssertEqual(move(&s, ["t": 8]), .notYet("That's 3:40. Back to 5."))
        XCTAssertEqual(move(&s, ["t": 2]), .notYet("That's 3:10. Keep going."))
        XCTAssertEqual(Time5.Parts(s.numbers).timeOf(12), "4:00")
        XCTAssertEqual(move(&s, ["t": 5]), .moved(1))

        for i in 0..<12 {
            each(Time5.spec, i) { x in
                let P = Time5.Parts(x)
                XCTAssertEqual(P.kind, Time5.kind(i))
                if i < 3 { XCTAssertTrue((5...30).contains(P.M)) }
                if P.set { XCTAssertTrue(P.M > 0) }
                if let ev = P.ev { XCTAssertTrue(ev.hours.contains(P.H)) }
            }
        }
        XCTAssertEqual((0..<12).map { Time5.kind($0).rawValue }, [0, 0, 0, 0, 1, 2, 0, 1, 2, 0, 1, 2])
        let c = checks(Time5.spec).map(Time5.Parts.init)
        XCTAssertTrue(c[1].M >= 35); XCTAssertEqual(c[2].M, 0)
    }

    func testCoins() {
        var l = LessonRun(Coins2.spec, numbers: Coins2.numbers(coin: TM2.dime))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Tap its name.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("The dime is the smallest coin and has a bumpy edge. A nickel is bigger and smooth."))
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("A penny is the copper-colored coin. This one is silver."))
        XCTAssertEqual(move(&l, ["c": 3]), .notYet("This is the smallest coin, with a bumpy edge: a dime."))
        XCTAssertEqual(move(&l, ["c": 2]), .moved(1))
        XCTAssertEqual(l.words.say, "Write what it's worth.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("A dime is small but worth 10 cents."))
        XCTAssertEqual(move(&l, ["x": 25]), .notYet("That's what a quarter is worth. A dime is worth 10 cents."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Penny 1, nickel 5, dime 10, quarter 25."))
        XCTAssertEqual(move(&l, ["x": 10]), .moved(2))
        XCTAssertEqual(l.words.say, "A coin's size doesn't tell what it's worth.")
        var n = LessonRun(Coins2.spec, numbers: Coins2.numbers(coin: TM2.nickel))
        XCTAssertEqual(move(&n, ["c": 2]), .notYet("A dime is smaller and has a bumpy edge. This one is smooth: a nickel."))
        XCTAssertEqual(move(&n, ["c": 1]), .moved(1))
        XCTAssertEqual(move(&n, ["x": 1]), .notYet("A nickel is worth 5 pennies: 5 cents."))

        var p = LessonRun(Coins2.spec, numbers: Coins2.numbers(coin: TM2.nickel, other: TM2.dime))
        XCTAssertEqual(p.steps.count, 4)
        XCTAssertEqual(p.words.say, "Tap the left coin's name.")
        XCTAssertEqual(move(&p, ["c": 1]), .moved(1))
        XCTAssertEqual(p.words.say, "Tap the right coin's name.")
        XCTAssertEqual(move(&p, ["d": 1]), .notYet("The dime is the smallest coin and has a bumpy edge. A nickel is bigger and smooth."))
        XCTAssertEqual(move(&p, ["d": 2]), .moved(2))
        XCTAssertEqual(p.words.say, "Tap the one worth more.")
        XCTAssertEqual(move(&p, ["w": 0]), .notYet("The nickel is bigger, but the dime is worth more: 10 cents to 5."))
        XCTAssertEqual(move(&p, ["w": 1]), .moved(3))
        let q = Coins2.Parts(Coins2.numbers(coin: TM2.quarter, other: TM2.penny))
        XCTAssertEqual(q.moreMiss, "A penny is worth 1 cent and a quarter 25 cents. The quarter is worth more.")

        XCTAssertEqual((0..<5).map { Coins2.Parts(Coins2.spec.generate(&rngCopy, $0)).coin }, [1, 0, 3, 2, 1])
        for i in [5, 8, 11] { each(Coins2.spec, i) { x in let P = Coins2.Parts(x); XCTAssertTrue(P.pair); XCTAssertNotEqual(P.coin, P.other) } }
        let c = checks(Coins2.spec).map(Coins2.Parts.init)
        XCTAssertEqual(c[0].coin, TM2.nickel); XCTAssertEqual(c[1].coin, TM2.dime); XCTAssertTrue(c[2].fooled); XCTAssertTrue(c[3].pair)
    }
    private var rngCopy = SeededRandom(seed: 3)

    func testMoney() {
        var l = LessonRun(Money2.spec, numbers: Money2.numbers(q: 2, d: 1, n: 1, p: 3))
        XCTAssertEqual(l.steps.count, 9)
        XCTAssertEqual(l.words.say, "Slide in the quarters.")
        XCTAssertEqual(move(&l, ["s0": 2]), .notYet("Start with the quarters."))
        XCTAssertEqual(move(&l, ["s0": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Count the cents. Write how much.")
        XCTAssertEqual(move(&l, ["a0": 2]), .notYet("A quarter is worth 25¢, not 1¢. Count on by 25s."))
        XCTAssertEqual(move(&l, ["a0": 20]), .notYet("A quarter is 25¢. Count 25, 50, 75."))
        XCTAssertEqual(move(&l, ["a0": 75]), .notYet("There are 2 quarters. Count one 25 for each."))
        XCTAssertEqual(move(&l, ["a0": 50]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide in the dime.")
        XCTAssertEqual(move(&l, ["s1": 3]), .notYet("The dime comes next."))
        XCTAssertEqual(move(&l, ["s1": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Count on. Write how much.")
        XCTAssertEqual(move(&l, ["a1": 55]), .notYet("A dime is 10¢, even though it's the smallest coin."))
        XCTAssertEqual(move(&l, ["a1": 10]), .notYet("Keep the 50¢ you already counted and count on from there."))
        XCTAssertEqual(move(&l, ["a1": 61]), .notYet("Start at 50¢ and count on by 10s, one count for each coin."))
        XCTAssertEqual(move(&l, ["a1": 60]), .moved(4))
        XCTAssertEqual(move(&l, ["s2": 2]), .moved(5))
        XCTAssertEqual(move(&l, ["a2": 70]), .notYet("A nickel is 5¢. It's bigger than a dime, but worth less."))
        XCTAssertEqual(move(&l, ["a2": 65]), .moved(6))
        XCTAssertEqual(l.words.say, "Slide in the pennies.")
        XCTAssertEqual(move(&l, ["s3": 3]), .moved(7))
        XCTAssertEqual(move(&l, ["a3": 80]), .notYet("A penny is only 1¢. Count on by ones."))
        XCTAssertEqual(move(&l, ["a3": 68]), .moved(8))
        XCTAssertEqual(l.words.say, "Count the coins worth most first, then count on.")

        for i in 0..<8 {
            each(Money2.spec, i) { x in
                let P = Money2.Parts(x)
                XCTAssertTrue(P.G.count >= 2); XCTAssertTrue(P.total <= 99); XCTAssertTrue(P.q + P.d + P.n + P.p <= 9)
                if i < 3 { XCTAssertEqual(P.q, 0); XCTAssertEqual(P.G.count, 2) } else { XCTAssertTrue(P.q >= 1) }
            }
        }
        let c = checks(Money2.spec).map(Money2.Parts.init)
        XCTAssertEqual(c[1].d, 0); XCTAssertTrue(c[2].G.count >= 3)
        XCTAssertEqual(TM2.centAt(0).x, 0); XCTAssertEqual(TM2.centAt(26).x, 18); XCTAssertEqual(TM2.centAt(54).y, 15); XCTAssertEqual(TM2.centAt(59).y, 18)
        XCTAssertEqual(TM2.coinsFor(68).map(\.count), [2, 1, 1, 3])
    }

    func testDollars() {
        var l = LessonRun(Dollars2.spec, numbers: Dollars2.numbers(bills: [10: 2, 5: 1, 1: 2]))
        XCTAssertEqual(l.steps.count, 7)
        XCTAssertEqual(l.words.say, "Slide in the $10 bills.")
        XCTAssertEqual(move(&l, ["s0": 1]), .notYet("Start with the $10 bills."))
        XCTAssertEqual(move(&l, ["s0": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Count the dollars. Write how much.")
        XCTAssertEqual(move(&l, ["a0": 2]), .notYet("A $10 bill is 10 dollars. Count on by 10."))
        XCTAssertEqual(move(&l, ["a0": 30]), .notYet("That's a ten too many. Each full row is $10."))
        XCTAssertEqual(move(&l, ["a0": 20]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide in the $5 bill.")
        XCTAssertEqual(move(&l, ["s1": 1]), .moved(3))
        XCTAssertEqual(move(&l, ["a1": 21]), .notYet("A $5 bill is 5 dollars. Count on by 5."))
        XCTAssertEqual(move(&l, ["a1": 5]), .notYet("Keep the $20 you already counted and count on."))
        XCTAssertEqual(move(&l, ["a1": 25]), .moved(4))
        XCTAssertEqual(move(&l, ["s2": 2]), .moved(5))
        XCTAssertEqual(move(&l, ["a2": 27]), .moved(6))
        XCTAssertEqual(l.words.say, "Count bills like coins: biggest first.")

        var d = LessonRun(Dollars2.spec, numbers: Dollars2.numbers(.dollar, who: 1, A: 65))
        XCTAssertEqual(d.words.say, "Ben has 65¢. Fill it to make a dollar.")
        XCTAssertEqual(Dollars2.Parts(d.numbers).fills, [70, 75, 100])
        XCTAssertEqual(move(&d, ["f": -1]), .notYet("That part is full. Tap an empty row."))
        XCTAssertEqual(move(&d, ["f": 100]), .moved(1))
        XCTAssertEqual(d.words.say, "Ben has 65¢. How much more makes a dollar?")
        XCTAssertEqual(move(&d, ["x": 65]), .notYet("That's what you have. How much more makes 100¢?"))
        XCTAssertEqual(move(&d, ["x": 45]), .notYet("That's a ten too many. A block is 25 and a row is 5."))
        XCTAssertEqual(move(&d, ["x": 35]), .moved(2))
        XCTAssertEqual(d.words.say, "Ben has 65¢. 100 cents fill the dollar square.")

        var b = LessonRun(Dollars2.spec, numbers: Dollars2.numbers(.buy, who: 0, A: 45, price: 30, item: 0))
        XCTAssertEqual(b.words.say, "Ana has 45¢. A pencil is 30¢. Slide it over.")
        XCTAssertEqual(move(&b, ["t": 1]), .moved(1))
        XCTAssertEqual(b.words.say, "Ana has 45¢. How much is left? Write it.")
        XCTAssertEqual(move(&b, ["x": 75]), .notYet("Buying takes money away. Count the cents not crossed out."))
        XCTAssertEqual(move(&b, ["x": 30]), .notYet("That's the price. Count the cents not crossed out."))
        XCTAssertEqual(move(&b, ["x": 15]), .moved(2))

        var a = LessonRun(Dollars2.spec, numbers: Dollars2.numbers(.inall, who: 2, A: 45, B: 30, who2: 3))
        XCTAssertEqual(a.words.say, "Mia has 45¢. Sam has 30¢. Slide in Sam's coins.")
        XCTAssertEqual(move(&a, ["t": 1]), .moved(1))
        XCTAssertEqual(move(&a, ["x": 15]), .notYet("In all means put them together. Add."))
        XCTAssertEqual(move(&a, ["x": 45]), .notYet("That's Mia's money. Count both together."))
        XCTAssertEqual(move(&a, ["x": 75]), .moved(2))

        let kinds: [Dollars2.Kind] = [.bills, .dollar, .buy, .bills, .dollar, .buy, .inall, .bills]
        for i in 0..<8 {
            XCTAssertEqual(Dollars2.kind(i), kinds[i])
            each(Dollars2.spec, i) { x in
                let P = Dollars2.Parts(x)
                switch P.kind {
                case .bills:
                    var all = 0
                    for g in P.G { all += g.count }
                    XCTAssertTrue((2...7).contains(all)); XCTAssertTrue(P.total <= 99); XCTAssertTrue(P.G.count >= 2)
                    if i < 3 { XCTAssertTrue(P.G.allSatisfy { $0.value == 10 || $0.value == 1 }) }
                    if i < 6 { XCTAssertFalse(P.G.contains { $0.value == 20 }) }
                case .dollar: XCTAssertEqual(P.A % (i < 3 ? 10 : 5), 0); XCTAssertTrue((10...95).contains(P.A))
                case .buy: XCTAssertTrue(P.price < P.A); if i < 3 { XCTAssertTrue(P.price % 10 <= P.A % 10) }
                case .inall: XCTAssertTrue(P.A + P.B <= 99); XCTAssertNotEqual(P.who, P.who2)
                }
            }
        }
        let c = checks(Dollars2.spec).map(Dollars2.Parts.init)
        XCTAssertEqual(c.map { $0.kind }, [.bills, .dollar, .buy, .inall])
    }
}
