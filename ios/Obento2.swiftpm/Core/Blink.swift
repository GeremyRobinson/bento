/// The cursor in an answer box (G 19 Oct): held on for a moment after each key, then on and off as a cursor blinks.
/// Only its on and off change, so while nothing else moves the paper's clock ticks just at those moments
/// (PaperScreen), instead of drawing the whole paper sixty times a second while a number is wanted.
public enum Blink {
    /// How long it stays on after a key.
    public static let hold = 0.6
    /// How long each on and each off lasts after that.
    public static let half = 0.53

    /// The cursor shows, `s` seconds after the last key.
    public static func on(since s: Double) -> Bool {
        s < hold || (s - hold).truncatingRemainder(dividingBy: 2 * half) < half
    }

    /// Seconds after the last key when the cursor next turns on or off, later than `s`.
    public static func nextChange(after s: Double) -> Double {
        guard s >= hold else { return hold + half }
        // a hair over, so a moment that is itself a change finds the one after it
        return hold + (((s - hold) / half + 1e-9).rounded(.down) + 1) * half
    }
}
