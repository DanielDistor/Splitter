import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SplitView()
                .tabItem {
                    Label("Split", systemImage: "scissors")
                }
            MealView()  
                .tabItem {
                    Label("Meal", systemImage: "cart.fill")
                }
        }
    }
}
