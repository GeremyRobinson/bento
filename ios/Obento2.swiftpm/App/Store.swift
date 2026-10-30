import StoreKit
import SwiftUI

/// The plan (G 30 Oct, the money plan: design/prototype and the shared Money Plan page): one subscription, All grades,
/// monthly or yearly, a week free to start, shared with the family. Apple's StoreKit does the buying, checks it, and
/// remembers it on the iPad; nothing goes to a server of ours. Bought only in the island's Plan tab, behind the hold.
/// Until the App Store has the products (G's developer account), Xcode tests them from `Obento2.storekit`.
@MainActor @Observable
final class Store {
    static let shared = Store()

    static let monthly = "education.bento.obento2.all.monthly"
    static let yearly = "education.bento.obento2.all.yearly"
    static let ids = [monthly, yearly]
    /// The prices a screenshot shows (it runs outside Xcode, where the test store isn't there).
    static let shotPrices = [monthly: "$6.99", yearly: "$49.99"]

    enum Loading: Equatable { case loading, ready, failed }
    private(set) var loading: Loading = .loading
    private(set) var products: [String: Product] = [:]
    /// What the family has: nil, or the subscription now in force.
    private(set) var active: (id: String, renews: Date?, willRenew: Bool)?
    /// A week free is offered (only to a family that hasn't had it).
    private(set) var trialOffered = true
    /// Buying now (the sheet is up): the button waits.
    private(set) var buying = false
    /// What the last try said, when it wasn't bought.
    private(set) var said: String?
    /// The Plan tab's choice: yearly (the default) or monthly.
    var yearly = true

    /// Every chapter of every grade is open: the family has the plan, or this is a build from Xcode (G 30 Oct: G's
    /// daughter keeps everything on her iPad), unless "Preview as a new family" is on (or `-locked`, for screenshots).
    var hasAllGrades: Bool { active != nil || (Self.fromXcode && !previewLocked) }
    /// A build from Xcode (debug), not one from the App Store or TestFlight.
    static var fromXcode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    /// Plan's test-only switch: see the app as a family without the plan (kept on this iPad; never in an App Store build).
    var previewLocked: Bool = UserDefaults.standard.bool(forKey: "previewLocked") || ProcessInfo.processInfo.arguments.contains("-locked") {
        didSet { if !Shots.active { UserDefaults.standard.set(previewLocked, forKey: "previewLocked") } }
    }
    private var updates: Task<Void, Never>?

    /// Loads the prices and what's owned, and keeps listening for changes (a renewal, Ask to Buy approved, a refund).
    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refresh()
            }
        }
        Task { await load() }
    }

    func load() async {
        if Shots.active { loading = .ready; return }
        loading = .loading
        do {
            let found = try await Product.products(for: Self.ids)
            products = Dictionary(uniqueKeysWithValues: found.map { ($0.id, $0) })
            loading = found.isEmpty ? .failed : .ready
        } catch { loading = .failed }
        await refresh()
    }

    /// What's owned now, from Apple's own record on the iPad.
    func refresh() async {
        var now: (String, Date?, Bool)?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result, Self.ids.contains(t.productID), t.revocationDate == nil else { continue }
            var renews = true
            if let p = products[t.productID], let status = try? await p.subscription?.status.first(where: { $0.state == .subscribed || $0.state == .inGracePeriod || $0.state == .inBillingRetryPeriod }),
               case .verified(let info) = status.renewalInfo { renews = info.willAutoRenew }
            now = (t.productID, t.expirationDate, renews)
        }
        active = now.map { (id: $0.0, renews: $0.1, willRenew: $0.2) }
        if let sub = products[Self.yearly]?.subscription { trialOffered = await sub.isEligibleForIntroOffer }
    }

    /// The price shown for a plan: Apple's, in the family's own currency.
    func price(_ id: String) -> String? { products[id]?.displayPrice ?? (Shots.active ? Self.shotPrices[id] : nil) }
    /// The yearly plan's price a month: "$4.17".
    var yearlyPerMonth: String? {
        guard let p = products[Self.yearly] else { return Shots.active ? "$4.17" : nil }
        return (p.price / 12).formatted(p.priceFormatStyle)
    }

    /// How much the yearly plan saves against twelve months: "Save 40%".
    var yearlySaving: String? {
        guard let m = products[Self.monthly]?.price, let y = products[Self.yearly]?.price, m > 0 else { return Shots.active ? "Save 40%" : nil }
        let pct = Int((1 - NSDecimalNumber(decimal: y / (m * 12)).doubleValue) * 100)
        return pct > 0 ? "Save \(pct)%" : nil
    }

    func buy(_ id: String) async {
        guard let p = products[id], !buying else { return }
        buying = true; said = nil
        defer { buying = false }
        do {
            switch try await p.purchase() {
            case .success(.verified(let t)): await t.finish(); await refresh()
            case .success(.unverified): said = "The purchase couldn't be checked. Nothing was charged."
            case .pending: said = "Waiting for approval. It starts once it's approved."
            case .userCancelled: break
            @unknown default: break
            }
        } catch { said = "That didn't go through. Try again." }
    }

    /// Restore Purchases: asks the App Store for this Apple Account's purchases again.
    func restore() async {
        said = nil
        try? await AppStore.sync()
        await refresh()
        if active == nil { said = "Nothing to restore on this Apple Account." }
    }
}
