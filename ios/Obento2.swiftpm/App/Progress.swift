import Foundation

/// What the child has learned, kept on the device. A lesson counts as learned once a problem is worked to the end;
/// the skill check and rechecks come with milestone 5.
@MainActor @Observable
final class Progress {
    static let shared = Progress()
    private(set) var learned: Set<String>
    /// Screenshots set a fixed state and don't save it.
    var saving = true

    init() { learned = Set(UserDefaults.standard.stringArray(forKey: "learned") ?? []) }

    func learn(_ id: String) {
        guard !learned.contains(id) else { return }
        learned.insert(id)
        if saving { UserDefaults.standard.set(Array(learned), forKey: "learned") }
    }

    func reset(to ids: Set<String>) { learned = ids }
}
