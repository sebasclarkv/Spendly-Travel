import SwiftUI

@main
struct SpendlyApp: App {
    @StateObject private var store = TripStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(store)
        }
    }
}
