import Foundation

struct Event: Identifiable {
    var id: String
    var title: String
    var date: Date
}

struct EventDish: Identifiable {
    var id = UUID().uuidString
    var name: String
    var price: Double
    var orderedBy: String
}

struct Expenses {
    var subtotal: Double
    var tax: Double
    var tip: Double
    var total: Double
}
