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

    /// Who is paying for an item. An empty `sharedBy` means everyone, including people added later.
    func sharers(of item: BillItem) -> [Person] {
        let explicit = people.filter { item.sharedBy.contains($0.id) }
        return explicit.isEmpty ? people : explicit
    }

    func person(_ personID: UUID, had item: BillItem) -> Bool {
        sharers(of: item).contains { $0.id == personID }
    }

    /// Adds or removes someone from an item. Returns false if that would leave the item with nobody.
    @discardableResult
    mutating func setPerson(_ personID: UUID, had: Bool, itemID: UUID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return false }
        var ids = Set(sharers(of: items[index]).map(\.id))
        if had { ids.insert(personID) } else { ids.remove(personID) }
        guard !ids.isEmpty else { return false }
        // Everyone selected goes back to "Everyone", so people added later are included too.
        items[index].sharedBy = ids == Set(people.map(\.id)) ? [] : ids
        return true
    }

    mutating func removePerson(_ personID: UUID) {
        if let index = people.firstIndex(where: { $0.id == personID }) {
            removePeople(at: [index])
        }
    }

    mutating func removePeople(at offsets: IndexSet) {
        let removed = Set(offsets.map { people[$0].id })
        people.remove(atOffsets: offsets)
        for index in items.indices {
            items[index].sharedBy.subtract(removed)
        }
    }
}
