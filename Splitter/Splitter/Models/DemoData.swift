#if DEBUG
import Foundation

enum DemoData {
    static var bills: [Bill] {
        let alice = Person(name: "Alice")
        let bob = Person(name: "Bob")
        let cara = Person(name: "Cara")

        var dinner = Bill(title: "Birthday Dinner", date: .now, people: [alice, bob, cara])
        dinner.items = [
            BillItem(name: "Margherita Pizza", priceCents: 1_800, sharedBy: [alice.id, bob.id]),
            BillItem(name: "Ribeye", priceCents: 3_400, sharedBy: [cara.id]),
            BillItem(name: "Caesar Salad", priceCents: 1_200, sharedBy: [alice.id]),
            BillItem(name: "Bottle of Wine", priceCents: 4_200),
        ]
        dinner.taxCents = 1_016
        dinner.tip = .percent(20)

        var brunch = Bill(title: "Sunday Brunch", date: .now.addingTimeInterval(-86_400 * 4), people: [alice, bob])
        brunch.items = [
            BillItem(name: "Pancakes", priceCents: 1_400, sharedBy: [alice.id]),
            BillItem(name: "Eggs Benedict", priceCents: 1_650, sharedBy: [bob.id]),
            BillItem(name: "Coffee", priceCents: 900),
        ]
        brunch.taxCents = 349
        brunch.tip = .percent(18)

        return [dinner, brunch]
    }
}
#endif
