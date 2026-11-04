import Foundation

/// Adding like fractions (the web app's g4-likefrac, 4.NF.3a, 4.NF.3d) and Subtracting like fractions (g4-likesub, new:
/// its mirror); design/grade4.md chapter 4, the preview design/prototype/grade4-ch4.html. 5th grade's Adding fractions
/// without the ruler: the pieces already match. a/d ± c/d.
///
/// On the paper: a/d shaded (a whole bar named 1 when a = d), c/d striped under it, named at their right ends with the
/// sign between. Slide the striped pieces: adding, they land after the shaded pieces, the count running on, spilling into a
/// second whole bar past the end; taking away, they land on the shaded pieces from the right and cross them out, what's
/// left counting down (the box "s": 1 dropped on the top bar, 0 anywhere else). Then the record a/d ± c/d = [T]/[B].
///
/// Every step's picture has "at": 0 the question, 1 the slide, 2 write, 3 done. "story" (0–2) picks a take-away's story.
public enum LikeFractions {
    public static func numbers(a: Int, c: Int, d: Int, sub: Bool, story: Int = 0) -> Numbers {
        ["a": Double(a), "c": Double(c), "d": Double(d), "sub": sub ? 1 : 0, "story": Double(story)]
    }
    static let bottoms = [3, 4, 5, 6, 8, 10, 12]

    public struct Parts: Sendable {
        public let a: Int, c: Int, d: Int, sub: Bool, story: Int
        public init(_ x: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((x[k] ?? Double(v)).rounded()) }
            a = i("a", 1); c = i("c", 1); d = max(2, i("d", 4)); sub = i("sub", 0) != 0; story = i("story", 0)
        }
        public var R: Int { sub ? a - c : a + c }
        public var sign: String { sub ? "−" : "+" }
        /// Past a whole: the pieces spill into a second whole bar.
        public var spill: Bool { !sub && R > d }
        public var W: Int { Fractions4.whole(d) }
        public var pw: Int { W / d }
        public var name: String { Fractions4.piece(d) }
        public var text: String {
            if !sub {
                return a + c <= d ? "Sam ate \(a)/\(d) of a pizza. Ana ate \(c)/\(d) of the same pizza. How much pizza did they eat together?"
                    : "Sam ate \(a)/\(d) of a pizza. Ana ate \(c)/\(d) of another pizza the same size. How much pizza did they eat together?"
            }
            let whole = a == d ? "1" : "\(a)/\(d)"
            switch story % 3 {
            case 0: return a == d ? "A pizza is cut into \(d) slices. Sam eats \(c)/\(d) of it. How much pizza is left?"
                : "There is \(a)/\(d) of a pizza. Sam eats \(c)/\(d) of the pizza. How much is left?"
            case 1: return "A ribbon is \(whole) m long. Mia cuts off \(c)/\(d) m. How much ribbon is left?"
            default: return "A jug holds \(whole) L of juice. Leo drinks \(c)/\(d) L. How much juice is left?"
            }
        }
    }

    /// The web's generator (adding): index < 3 d 3–6 with a + c < d, then d 3, 4, 5, 6, 8, 10 or 12; the sum already in
    /// lowest terms (never exactly 1). Taking away (its mirror): a 2 to d (a = d, a whole bar, now and then from index 3),
    /// c 1 to a − 1, the difference in lowest terms.
    static func make(_ rng: inout SeededRandom, _ i: Int, sub: Bool) -> Numbers {
        let d = Fractions4.pick(i < 3 ? [3, 4, 5, 6] : bottoms, &rng)
        var a: Int, c: Int
        if sub {
            repeat {
                a = i >= 3 && Double.random(in: 0..<1, using: &rng) < 0.3 ? d : Int.random(in: 2...(d - 1), using: &rng)
                c = Int.random(in: 1...(a - 1), using: &rng)
            } while gcd(a - c, d) != 1
        } else {
            repeat { a = Int.random(in: 1...(d - 1), using: &rng); c = Int.random(in: 1...(d - 1), using: &rng) }
            while gcd(a + c, d) != 1 || (i < 3 && a + c >= d)
        }
        return numbers(a: a, c: c, d: d, sub: sub, story: Int.random(in: 0...2, using: &rng))
    }

    static func makeSpec(sub: Bool) -> LessonSpec {
        LessonSpec(id: sub ? "g4-likesub" : "g4-likefrac", title: sub ? "Subtracting like fractions" : "Adding like fractions", master: "bars",
            generate: { rng, i in make(&rng, i, sub: sub) },
            display: { x in let s = Parts(x); return [.frac(.num(Double(s.a)), .num(Double(s.d))), .op(s.sign), .frac(.num(Double(s.c)), .num(Double(s.d)))] },
            idea: { _ in sub ? "The bottom is the size of the pieces, so it stays the same when you take away."
                : "The bottom is the size of the pieces, so it stays the same when you add." },
            story: { Parts($0).text }, storyOp: { Parts($0).sign },
            depends: sub ? ["g4-likefrac"] : ["g3-unitfrac", "g3-fracline"],
            check: sub ? [CheckItem(0), CheckItem(3, when: { Parts($0).a == Parts($0).d }), CheckItem(3), CheckItem(3, story: true)]
                : [CheckItem(0), CheckItem(3, when: { let s = Parts($0); return s.a + s.c > s.d }), CheckItem(3, when: { let s = Parts($0); return s.a + s.c < s.d }),
                   CheckItem(3, story: true)]) { x in steps(x) }
    }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), d = s.d, R = s.R, name = s.name, sub = s.sub
        let say = sub ? "Take the striped pieces away. Slide them onto the shaded ones." : "Put the pieces together. Slide the striped pieces into the top bar."
        let hint = sub ? "Each striped piece takes away a shaded one." : "They go after the shaded pieces."
        let slide = LessonStep(StepWords(say: say, hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: hint,
                               explain: sub ? "\(Fractions4.cap(Fractions4.pieces(s.c, d))) taken away: \(R) left." : "\(Fractions4.cap(Fractions4.pieces(s.a, d))) and \(s.c) more: \(R).",
                               // dropped anywhere else they go back: what to do (a notice, not a miss)
                               check: { v in (v["s"] ?? 0) == 1 ? .right : .soft(sub ? "Slide them onto the shaded pieces." : "Put them in the top bar.") },
                               byHand: true),
            picture: ["at": 1], onMiss: ["target": 1], hint2: ["spot": 1])
        let more = !sub && R > d ? " More than 1 is fine here." : ""
        let count = sub ? "Count the \(name) that aren’t crossed out." : "Count the shaded \(name)\(s.spill ? " in both bars" : "")."
        let bottom = "The pieces are still \(name), so the bottom stays \(d)."
        let write = LessonStep(StepWords(say: (sub ? "Write what’s left." : "Write how much in all.") + more, hint: count, action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(s.a)), .num(Double(d))), .op(s.sign), .frac(.num(Double(s.c)), .num(Double(d))), .op("="),
                                        .frac(.box("T"), .box("B"))],
                               expected: ["T": Double(R), "B": Double(d)], hint: count,
                               explain: sub ? "\(s.a) − \(s.c) = \(R), and the pieces are still \(name)." : "The pieces are still \(name), so the bottom stays \(d): \(R)/\(d).",
                               check: { v in
                                   let T = Int((v["T"] ?? -1).rounded()), B = Int((v["B"] ?? -1).rounded())
                                   if T != R {
                                       if sub && T == s.a + s.c { return .wrong("\(s.c)/\(d) is taken away, so there’s less.") }
                                       if !sub && T == s.a * s.c { return .wrong("Putting the pieces together is adding: count them all.") }
                                       return .wrong(count)
                                   }
                                   if B != d {
                                       if !sub && B == 2 * d { return .wrong("\(Fractions4.cap(name)) and \(name) are still \(name).") }
                                       if sub && B == 0 { return .wrong("The pieces are still \(name).") }
                                       return .wrong(bottom)
                                   }
                                   return .right
                               }, incomplete: "Fill in both boxes."),
            picture: ["at": 2], onMiss: ["last": 1], hint2: ["spot": 1])
        let why = sub ? "Same-size pieces, so the tops are taken away." : "Same-size pieces, so the tops add."
        return [LessonStep(StepWords(say: say, hint: hint, action: "Let’s find out"), picture: ["at": 0]),
                slide, write,
                LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 3])]
    }

    public static let add = makeSpec(sub: false)
    public static let take = makeSpec(sub: true)
}
