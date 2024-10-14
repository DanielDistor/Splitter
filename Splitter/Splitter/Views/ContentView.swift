import SwiftUI

struct ContentView: View {
    @State private var isSignedIn = false

    var body: some View {
        if isSignedIn {
            MainTabView()
        } else {
            WelcomeView(isSignedIn: $isSignedIn)
        }
    }
}
