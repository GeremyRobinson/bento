import Foundation

/// Volume of a box (the web app's g5-volume), built on Unit cubes (G 20 Oct: anything 3D starts from Unit cubes): one
/// cube is one block of the paper, 1 cm each way. A box l cm long, w cm wide and h cm tall holds l × w cubes in a
/// layer, and h layers of them.
///
/// The child's hands find it, then the record writes it (design/grade5.md, "Volume of a box"):
/// 1. **cover** (flat): the floor's outline is on the paper with its length and width; a tap covers a square, a drag
///    sweeps a rectangle of them, the squares counting up ("9 squares": the hands find how many, so no total is given).
///    Cells are the floor's squares, numbered across then down, `z * length + x` (as Unit cubes numbers them).
/// 2. **build** (tilted): the paper tilts and the floor rises into the first layer; dragging up (or tapping) stacks the
///    layers above it to the box's height, each layer's own count on its front ("12" on every one, as the test page's
///    box had it: the running total is the child's to find). Cells past the floor stand for those layers: layer k
///    (1 ..< height) is cell `floor + k`. Layer 0 is the floor itself, risen.
/// 3. **volume** (tilted): the record `h layers of N = [ ]`, typed: the one number worked out, not read off the box.
/// 4. **done**: the record ends `Volume = 4 × 3 × 2 = 24 cubic cm`, and the last words say why ("The floor makes one
///    layer. The height says how many."; design/README.md: the last line says why, never the sum again).
///
/// Picture keys (master "cubes"): "floor" (the floor's outline and its measures, flat), "layers" (layers standing now,
/// at least), "box" (the box's full height dashed), "record" (1: the record being written, 2: written, with the volume),
/// "empty" / "tint" (the squares still to cover outlined / tinted: a hint, and how a problem done together points to the
/// move), "counts" (each layer's count lit: a hint after a miss on the record).
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

    /// The cell that stands for layer `k` (1 ..< height) in the build step: the cells after the floor's.
    public static func layerCell(_ k: Int, _ b: UnitCubes.Box) -> Int { b.floor + k }

    /// The record, as school writes it (design/README.md rule 1: maths, two squares a digit), a line at a time: the
    /// numbers, the signs, the words and the box to type in. The first line is written when the floor has risen:
    /// "4 × 3 = 12 cubes in a layer".
    public static func layerRecord(_ b: UnitCubes.Box) -> MathLine {
        [.num(Double(b.length)), .op("×"), .num(Double(b.width)), .op("="), .num(Double(b.floor)), .text("cubes in a layer")]
    }
    /// The second line as it's typed ("2 layers of 12 = [ ]", the step's own prompt), and once it's written.
    public static func layersRecord(_ b: UnitCubes.Box) -> MathLine { [.num(Double(b.height)), .text("layers of"), .num(Double(b.floor)), .op("="), .box("x")] }
    public static func layersDoneRecord(_ b: UnitCubes.Box) -> MathLine {
        [.num(Double(b.height)), .text("layers of"), .num(Double(b.floor)), .op("="), .num(Double(b.volume)), .text("cubes")]
    }
    /// The last line of the record, in the chapter's colour: "Volume = 4 × 3 × 2 = 24 cubic cm".
    public static func volumeRecord(_ b: UnitCubes.Box) -> MathLine {
        [.text("Volume"), .op("="), .num(Double(b.length)), .op("×"), .num(Double(b.width)), .op("×"), .num(Double(b.height)), .op("="),
         .num(Double(b.volume)), .text("cubic cm")]
    }
    /// A record line as one string, as it reads ("2 layers of 12 = [ ]").
    public static func written(_ line: MathLine) -> String {
        line.map { m -> String in
            switch m {
            case .num(let x): return fmt(x)
            case .op(let o): return o
            case .text(let t): return t
            case .box: return "[ ]"
            case .frac: return ""
            }
        }.joined(separator: " ")
    }
    public static func layerLine(_ b: UnitCubes.Box) -> String { written(layerRecord(b)) }
    public static func layersLine(_ b: UnitCubes.Box) -> String { written(layersRecord(b)) }
    public static func layersDone(_ b: UnitCubes.Box) -> String { written(layersDoneRecord(b)) }
    public static func volumeLine(_ b: UnitCubes.Box) -> String { written(volumeRecord(b)) }
    /// A layer's own count, written on its front as it stands: the same on every layer (12, 12, 12…), because every
    /// layer is the floor again. How many in all is the child's to work out and write.
    public static func count(_ layer: Int, _ b: UnitCubes.Box) -> String { "\(b.floor)" }
    /// The layers counted up to this one (12, 24, 36…): only Show me counts them up, as a preview.
    public static func total(_ layer: Int, _ b: UnitCubes.Box) -> String { "\(b.floor * (layer + 1))" }
    /// The last words: why it works, never the sum again (design/README.md rule 7).
    public static let why = "The floor makes one layer. The height says how many."

    public static let spec = LessonSpec(id: "g5-volume", title: "Volume of a box", master: "cubes", generate: { rng, index in
        guard index == tallestCheck else { return draw(&rng, index) }
        var n = draw(&rng, 3)
        for _ in 1..<50 where !tallest(n) { n = draw(&rng, 3) }
        if tallest(n) { return n }
        let s = [n["length"]!, n["width"]!, n["height"]!].sorted()
        return ["length": s[0], "width": s[1], "height": s[2]]
    }, display: { n in
        // a card names the box by its sides, as the lesson does ("4 by 3, 2 cm tall"): no × or = ?, the method is the
        // hands' to find, and it says which side is the height
        let b = UnitCubes.Box(n)
        return [.text("\(b.length) by \(b.width), \(b.height) cm tall")]
    },
    idea: { _ in "Cover the floor with cubes. Every layer is the same, so stack layers up to the top." },
    depends: ["g4-area", "g4-partial"],
    check: [CheckItem(3), CheckItem(3), CheckItem(tallestCheck, when: tallest), CheckItem(3)]) { n in
        let b = UnitCubes.Box(n), base = b.floor, V = b.volume, H = b.height
        let floor = Array(0..<base), layers = (1..<H).map { layerCell($0, b) }
        // plain words (G 18 Oct): each line says what to do; the box's sizes are its own labels, written once
        let cover = LessonStep(StepWords(say: "Drag across the floor to cover it.", hint: "Drag from one corner to the other.", action: "Check"),
            task: MarkTask(cells: Set(floor), want: base, showMe: floor,
                           mistakes: [Mistake(.tooFew) { m, w in let e = w - m; return "Not yet. \(e) \(e == 1 ? "square is" : "squares are") still empty." }],
                           // the squares counted up as they're covered, with no total: the hands find how many
                           count: { "\($0) \($0 == 1 ? "square" : "squares")" }),
            picture: ["floor": 1],
            // a miss outlines the squares still empty; then tints them (and a problem done together shows them tinted
            // from the start, pointing to the move)
            onMiss: ["empty": 1], hint2: ["tint": 1])
        let keepGoing = "Keep going. The box is \(H) cm tall."
        let build = LessonStep(StepWords(say: "Drag up to stack the layers.", hint: "The box is \(H) cm tall: \(H) layers of \(base).", action: "Check"),
            task: MarkTask(cells: Set(layers), want: H - 1, showMe: layers,
                           mistakes: [Mistake(.tooFew) { _, _ in keepGoing }],
                           // the marks so far are the floor's squares and the layers built on it
                           count: { "\($0 - base + 1) of \(H) layers" }),
            camera: .tilted, picture: ["layers": 1, "box": 1])
        let volume = LessonStep(StepWords(say: "How many cubes fill the box? Write it.", hint: "Each layer has \(base) cubes.", action: "Check"),
            answer: AnswerTask(prompt: layersRecord(b), expected: ["x": Double(V)],
                               // the slips the web knows, in its order: adding the height to the layer, adding the sides,
                               // and one layer only
                               known: [(["x": Double(base + H)], "That adds \(H) to \(base). There are \(H) layers of \(base)."),
                                       (["x": Double(b.length + b.width + H)], "That adds the sides. There are \(H) layers of \(base)."),
                                       (["x": Double(base)], "That's one layer. There are \(H).")],
                               hint: "Each layer has \(base) cubes.",
                               explain: "\(H) layers of \(base) is \(V)."),
            camera: .tilted, picture: ["layers": Double(H), "record": 1],
            // a miss lights each layer's count on its front
            onMiss: ["counts": 1])
        let done = LessonStep(StepWords(say: why, hint: volumeLine(b), action: "Next problem"),
                              camera: .tilted, picture: ["layers": Double(H), "record": 2])
        return [cover, build, volume, done]
    }
}
