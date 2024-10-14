import Foundation

class MealService {
    static let shared = MealService()

    private init() {}

    func fetchMeals(query: String, completion: @escaping ([Meal]?) -> Void) {
        let urlString = "https://www.themealdb.com/api/json/v1/1/search.php?s=\(query)"
        performRequest(with: urlString, completion: completion)
    }

    func fetchRandomMeal(completion: @escaping (Meal?) -> Void) {
        let urlString = "https://www.themealdb.com/api/json/v1/1/random.php"
        performRequest(with: urlString) { meals in
            completion(meals?.first)
        }
    }

    private func performRequest(with urlString: String, completion: @escaping ([Meal]?) -> Void) {
        guard let url = URL(string: urlString) else { return completion(nil) }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return completion(nil)
            }
            let decoder = JSONDecoder()
            if let mealResponse = try? decoder.decode(MealResponse.self, from: data) {
                DispatchQueue.main.async {
                    completion(mealResponse.meals)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }
}
