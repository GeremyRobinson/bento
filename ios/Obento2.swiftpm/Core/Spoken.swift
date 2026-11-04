import Foundation

/// A line of the paper as the voice says it (Kindergarten and 1st grade, whose children mostly can't read yet): numbers
/// and signs said the way a person says them ("3 + 4 = 7" is "3 plus 4 equals 7", "45¢" is "45 cents", "3/4" is
/// "3 fourths"), the curly apostrophe made plain. The synthesizer reads numerals well by itself.
public enum Spoken {
    static let signs: [(String, String)] = [
        (" + ", " plus "), (" − ", " minus "), (" - ", " minus "), (" × ", " times "), (" ÷ ", " divided by "),
        (" = ", " equals "), (" > ", " is greater than "), (" < ", " is less than "),
    ]
    static let denominators = [2: "half", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth", 8: "eighth", 10: "tenth", 12: "twelfth"]

    public static func text(_ s: String) -> String {
        var out = s.replacingOccurrences(of: "’", with: "'")
        // the three signs to pick from, named
        out = out.replacingOccurrences(of: "<, = or >", with: "less than, equals or greater than")
        for (sign, words) in signs { out = out.replacingOccurrences(of: sign, with: words) }
        // a sign with no spaces round it: 3+4=7
        for (sign, words) in [("+", " plus "), ("=", " equals "), ("×", " times "), ("÷", " divided by ")] { out = out.replacingOccurrences(of: sign, with: words) }
        // a time as a person says it: 8:30 → half past 8, 8:00 → 8 o'clock
        out = replace(out, #"\b(\d{1,2}):(\d\d)\b"#) { m in m[2] == "30" ? "half past \(m[1])" : m[2] == "00" ? "\(m[1]) o'clock" : "\(m[1]) \(m[2])" }
        // cents and dollars: 45¢ → 45 cents, 1¢ → 1 cent
        out = replace(out, #"\b1¢"#) { _ in "1 cent" }
        out = replace(out, #"(\d+)¢"#) { "\($0[1]) cents" }
        // a fraction: 1/2 → 1 half, 3/4 → 3 fourths
        out = replace(out, #"\b(\d+)/(\d+)\b"#) { m in
            guard let top = Int(m[1]), let bottom = Int(m[2]), let name = denominators[bottom] else { return "\(m[1]) over \(m[2])" }
            return "\(top) \(name)\(top == 1 ? "" : "s")"
        }
        // a length's unit after its number: 7 cm → 7 centimeters, 1 in. → 1 inch ("4 in a row" stays)
        for (u, one, many) in [("cm", "centimeter", "centimeters"), ("ft", "foot", "feet"), ("m", "meter", "meters"), ("in", "inch", "inches")] {
            let after = u == "in" ? #"(?= long| more|[.,?]|$)"# : #"\b"#
            out = replace(out, #"\b(\d+) "# + u + after) { $0[1] == "1" ? "1 \(one)" : "\($0[1]) \(many)" }
        }
        // a lone ? (the story's unknown): "Put the ? on what we don't know."
        out = replace(out, #"(^|\s)\?(?=[\s.,]|$)"#) { "\($0[1])question mark" }
        while out.contains("  ") { out = out.replacingOccurrences(of: "  ", with: " ") }
        return out.trimmingCharacters(in: .whitespaces)
    }

    private static func replace(_ s: String, _ pattern: String, _ with: ([String]) -> String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return s }
        var out = s
        for m in re.matches(in: s, range: NSRange(s.startIndex..., in: s)).reversed() {
            let groups = (0..<m.numberOfRanges).map { i -> String in Range(m.range(at: i), in: s).map { String(s[$0]) } ?? "" }
            if let r = Range(m.range, in: out) { out.replaceSubrange(r, with: with(groups)) }
        }
        return out
    }
}
