import SwiftUI

struct MealDetailView: View {
    var meal: Meal
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImage(url: URL(string: meal.strMealThumb)) {
                    image in image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)

                Text(meal.strMeal).font(.title).fontWeight(.bold)
                Text("Category: \(meal.strCategory)")
                Text("Area: \(meal.strArea)")
                Text("Instructions: \(meal.strInstructions)")
                if let tags = meal.strTags {
                    Text("Tags: \(tags)")
                }
                if let youtubeURL = meal.strYoutube {
                    Link("Watch on YouTube", destination: URL(string: youtubeURL)!)
                }
            }
            .padding()
        }
        .navigationBarTitle(meal.strMeal, displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.left")
        })
    }
}
