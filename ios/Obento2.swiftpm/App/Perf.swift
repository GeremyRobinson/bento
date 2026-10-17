import Foundation
import QuartzCore

/// Launch with `-perf` to time the work done each frame: every two seconds it prints, for each part, how often it ran,
/// its average and its slowest time. Off otherwise, so it costs nothing.
@MainActor
enum Perf {
    static let on = ProcessInfo.processInfo.arguments.contains("-perf")
    private static var stats: [String: (n: Int, total: Double, worst: Double)] = [:]
    private static var since = CACurrentMediaTime()

    @discardableResult
    static func time<T>(_ label: String, _ work: () -> T) -> T {
        guard on else { return work() }
        let t0 = CACurrentMediaTime()
        let r = work()
        let ms = (CACurrentMediaTime() - t0) * 1000
        var s = stats[label] ?? (0, 0, 0)
        s.n += 1; s.total += ms; s.worst = max(s.worst, ms)
        stats[label] = s
        report()
        return r
    }

    private static var lastFrame = 0.0
    /// The time between two drawn frames: a long one is a hitch you can see.
    static func frame(_ t: Double) {
        guard on else { return }
        if lastFrame > 0, t - lastFrame < 0.5 {
            let ms = (t - lastFrame) * 1000
            var s = stats["frame"] ?? (0, 0, 0)
            s.n += 1; s.total += ms; s.worst = max(s.worst, ms)
            stats["frame"] = s
        }
        lastFrame = t
    }

    private static func report() {
        let now = CACurrentMediaTime()
        guard now - since > 2 else { return }
        since = now
        let line = stats.sorted { $0.key < $1.key }.map { "\($0.key) n=\($0.value.n) avg=\(String(format: "%.1f", $0.value.total / Double($0.value.n)))ms max=\(String(format: "%.1f", $0.value.worst))ms" }
        print("PERF " + line.joined(separator: " | "))
        stats = [:]
    }
}
