import SwiftUI

@main
struct Obento2App: App {
    /// "light" or "dark" once the child picks one in the top bar; otherwise the device decides.
    @AppStorage("theme") private var theme = ""
    var body: some Scene {
        WindowGroup {
            PaperScreen(model: PaperModel()).statusBarHidden()
                // the plan: prices, and what the family has, kept up to date from the App Store (Store.swift)
                .task { Store.shared.start() }
                // screenshots follow the device's setting, never a choice saved earlier
                .preferredColorScheme(Shots.active && Shots.name != "theme" ? nil : theme == "dark" ? .dark : theme == "light" ? .light : nil)
        }
    }
}
