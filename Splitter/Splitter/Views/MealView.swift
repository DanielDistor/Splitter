import SwiftUI

struct MealView: View {
    @State private var searchQuery = ""
    @State private var selectedMeal: Meal?
    @State private var isLoading = false
    @State private var showDetailView = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Discover New Recipes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Enter a dish name or try a random dish!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)

                TextField("Enter a dish name...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .submitLabel(.done)
                    .onSubmit {
                        fetchMeals()
                    }

                if isLoading {
                    ProgressView()
                }

                Button("Random Dish") {
                    fetchRandomMeal()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
                .padding(.top, 10)

                Spacer()
                

                if let meal = selectedMeal {
                    NavigationLink(destination: MealDetailView(meal: meal), isActive: $showDetailView) {
                        EmptyView()
                    }
                }
            }
            .background(Color(red: 0.8, green: 0.2, blue: 0.2).edgesIgnoringSafeArea(.all))
            .navigationTitle("Meals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func fetchMeals() {
        isLoading = true
        MealService.shared.fetchMeals(query: searchQuery) { fetchedMeals in
            isLoading = false
            if let meals = fetchedMeals, !meals.isEmpty {
                self.selectedMeal = meals[0]
                self.showDetailView = true
            }
        }
    }

    private func fetchRandomMeal() {
        isLoading = true
        MealService.shared.fetchRandomMeal { fetchedMeal in
            isLoading = false
            if let meal = fetchedMeal {
                self.selectedMeal = meal
                self.showDetailView = true
            }
        }
    }
}
