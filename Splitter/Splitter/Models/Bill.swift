import Foundation

struct Person: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}

struct BillItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var priceCents: Int
    /// Who shares this item. Empty means it's split among everyone on the bill.
    var sharedBy: Set<UUID> = []
}

enum Tip: Codable, Hashable {
    case percent(Double)
    case amount(cents: Int)
}

struct Bill: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var date: Date = .now
    var people: [Person] = []
    var items: [BillItem] = []
    var taxCents: Int = 0
    var tip: Tip = .percent(18)

    mutating func removePeople(at offsets: IndexSet) {
        let removed = Set(offsets.map { people[$0].id })
        people.remove(atOffsets: offsets)
        for index in items.indices {
            items[index].sharedBy.subtract(removed)
        }
    }
}
