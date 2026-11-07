import SwiftUI

@main
struct SplitterApp: App {
    @State private var store = SplitterApp.makeStore()
    /// The welcome screen opens the app every time it launches; "Get Started" goes to your bills.
    @State private var showWelcome = !ProcessInfo.processInfo.arguments.contains("-skipWelcome")

    var body: some Scene {
        WindowGroup {
            Group {
                if !showWelcome {
                    BillListView()
                        .transition(.opacity)
                } else {
                    WelcomeView {
                        withAnimation(.easeInOut(duration: 0.4)) { showWelcome = false }
                    }
                    .transition(.opacity)
                }
            }
            .environment(store)
            .tint(Theme.brand)
        }
    }

    private static func makeStore() -> BillStore {
        #if DEBUG
        // `-demo` launches with sample bills in a throwaway file (used for screenshots / simulator runs).
        if ProcessInfo.processInfo.arguments.contains("-demo") {
            let store = BillStore(fileURL: .temporaryDirectory.appending(path: "demo-bills.json"))
            store.bills = DemoData.bills
            return store
        }
        #endif
        return BillStore()
    }
}
