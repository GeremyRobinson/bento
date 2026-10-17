import Foundation

/// Volume of a box (the web app's g5-volume): a box l cm long, w cm wide and h cm tall holds l × w cubes in a layer,
/// and h layers of them. Numbers: length, width, height (whole cm), named as the "cubes" master already reads them.
///
/// Picture keys (master "cubes"):
/// - "outline": 1 = the box's floor drawn on the paper as a length × width outline, with its length, width and height
///   written beside it (the web diagram's beat 0: the box and its labels, no cubes yet).
/// - "floor": 1 = the floor filled with length × width squares, the length and width labels lit, and the line
///   "l × w = N cubes in a layer" (beat 1, the base layer).
/// - "layers": k = k layers of cubes stand on the floor (the master's own key, as in Unit cubes).
/// - "height": 1 = the height label lit and the line "h layers: base × h = V" (beat 2, the layers stacked).
/// The camera is flat while the picture is on the paper (outline, floor) and tilts once the cubes rise (layers).
public enum VolumeOfBox {
    public static func numbers(length: Int, width: Int, height: Int) -> Numbers {
        ["length": Double(length), "width": Double(width), "height": Double(height)]
    }

    /// The skill check's third item: index 3, redrawn until the height is the biggest side, and when 50 draws never
    /// manage it, the last draw's sides sorted so the height is the biggest (the web recipe's `fix`). `CheckItem`
    /// can't change a draw, so the generator does the whole web draw for this index and `when` holds on the first try.
    public static let tallestCheck = 103

    static func tallest(_ n: Numbers) -> Bool { (n["height"] ?? 0) >= (n["length"] ?? 0) && (n["height"] ?? 0) >= (n["width"] ?? 0) }

    /// The web's generateBox: the first three boxes 2–5 on every side so they can be counted cube by cube,
    /// then length and width 2–8 and height 2–6 (up to 384 cubes).
    static func draw(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        if index < 3 {
            let l = Int.random(in: 2...5, using: &rng), w = Int.random(in: 2...5, using: &rng), h = Int.random(in: 2...5, using: &rng)
            return numbers(length: l, width: w, height: h)
        }
        let l = Int.random(in: 2...8, using: &rng), w = Int.random(in: 2...8, using: &rng), h = Int.random(in: 2...6, using: &rng)
        return numbers(length: l, width: w, height: h)
    }

    public static let spec = LessonSpec(id: "g5-volume", title: "Volume of a box", master: "cubes", generate: { rng, index in
        guard index == tallestCheck else { return draw(&rng, index) }
        var n = draw(&rng, 3)
        for _ in 1..<50 where !tallest(n) { n = draw(&rng, 3) }
        if tallest(n) { return n }
        let s = [n["length"]!, n["width"]!, n["height"]!].sorted()
        return ["length": s[0], "width": s[1], "height": s[2]]
    }, display: { n in [.num(n["length"] ?? 0), .op("×"), .num(n["width"] ?? 0), .op("×"), .num(n["height"] ?? 0), .op("="), .text("?")] },
    idea: { _ in "Every layer of cubes is the same, so the layers stack up to fill the box." },
    depends: ["g4-area", "g4-partial"],
    check: [CheckItem(3), CheckItem(3), CheckItem(tallestCheck, when: tallest), CheckItem(3)]) { n in
        let l = n["length"] ?? 0, w = n["width"] ?? 0, h = n["height"] ?? 0, base = l * w, V = base * h
        let L = fmt(l), W = fmt(w), H = fmt(h)
        // the spec's lead (specs/k12/grade5.md §2) replaces the web's displayNote
        let ask = LessonStep(StepWords(say: "A box is \(L) cm long, \(W) cm wide and \(H) cm tall. How many 1 cm cubes fill it?",
                                       hint: "Look at its floor first.", action: "Let’s find out"),
                             picture: ["outline": 1])
        // hints are the spec's narration (§3); the say is the web step's label, since it has no question
        let floor = LessonStep(StepWords(say: "Area of the base", hint: "The bottom layer is \(L) by \(W).", action: "Check"),
            answer: AnswerTask(prompt: [.num(l), .op("×"), .num(w), .op("="), .box("x")], expected: ["x": base],
                               known: [(["x": l + w], "Area means length × width.")],
                               hint: "Length times width."),
            picture: ["floor": 1])
        let stack = LessonStep(StepWords(say: "Times the height", hint: "Stack \(H) layers to fill the box, in cubic cm.", action: "Check"),
            answer: AnswerTask(prompt: [.num(base), .op("×"), .num(h), .op("="), .box("x")], expected: ["x": V],
                               known: [(["x": base + h], "Each layer is the base. Multiply by the number of layers.")],
                               hint: "Stack the base layer up the height."),
            camera: .tilted, picture: ["layers": h, "height": 1])
        let done = LessonStep(StepWords(say: "\(fmt(V)) cubes fill the box.",
                                        hint: "Every layer of cubes is the same, so the layers stack up to fill the box.",
                                        action: "Next problem"),
                              camera: .tilted, picture: ["layers": h, "height": 1])
        return [ask, floor, stack, done]
    }
}
