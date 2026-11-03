import Foundation

/// What 4th grade's Big numbers chapter shares (design/grade4.md, chapter 1): the places' names, a number written with
/// its commas, its digits, and its name in words the US way.
public enum BigNumbers {
    /// The places from the ones up: their names, plural and one of them.
    public static let places = ["ones", "tens", "hundreds", "thousands", "ten thousands", "hundred thousands"]
    public static let place1 = ["one", "ten", "hundred", "thousand", "ten thousand", "hundred thousand"]
    /// "1 hundred", "3 hundreds".
    public static func place(_ k: Int, _ n: Int) -> String { n == 1 ? place1[k] : places[k] }
    /// 10 to the k (k 0 to 6).
    public static func pow10(_ k: Int) -> Int { [1, 10, 100, 1000, 10_000, 100_000, 1_000_000][k] }
    /// The digit in place k (0 the ones).
    public static func digit(_ n: Int, _ k: Int) -> Int { (n / pow10(k)) % 10 }
    /// How many digits it has (0 has one).
    public static func length(_ n: Int) -> Int { String(abs(n)).count }
    /// The place a round number counts in: 100 → 2.
    public static func log10(_ p: Int) -> Int { length(p) - 1 }

    /// As school writes it: 47,382 (a comma every three digits from the right).
    public static func commas(_ n: Int) -> String {
        let s = Array(String(abs(n)))
        var out = ""
        for (i, ch) in s.enumerated() {
            if i > 0 && (s.count - i) % 3 == 0 { out.append(",") }
            out.append(ch)
        }
        return (n < 0 ? "−" : "") + out
    }

    private static let ones = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
                               "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
    private static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
    private static func name3(_ n: Int) -> String {
        let h = n / 100, r = n % 100
        var out: [String] = []
        if h > 0 { out.append("\(ones[h]) hundred") }
        if r > 0 { out.append(r < 20 ? ones[r] : tens[r / 10] + (r % 10 > 0 ? "-" + ones[r % 10] : "")) }
        return out.joined(separator: " ")
    }
    /// A number's name the US way (design/grade4.md): no "and", hyphens from twenty-one to ninety-nine, a comma after
    /// "thousand". 40,605 → "forty thousand, six hundred five".
    public static func name(_ n: Int) -> String {
        guard n > 0 else { return "zero" }
        let th = n / 1000, r = n % 1000
        return [th > 0 ? "\(name3(th)) thousand" : "", r > 0 ? name3(r) : ""].filter { !$0.isEmpty }.joined(separator: ", ")
    }
    /// The first letter a capital.
    public static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// Predictable slips, minus any that equal the right answer or repeat an earlier one (the web's `slips`).
    static func slips(_ ans: Double, _ list: [(Double, String)]) -> [(values: [String: Double], message: String)] {
        var seen: Set<Double> = [ans]
        return list.compactMap { v, m in
            guard v.isFinite, !seen.contains(v) else { return nil }
            seen.insert(v)
            return (["x": v], m)
        }
    }
}
