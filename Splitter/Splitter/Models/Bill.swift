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

extension BillItem {
    /// Splits one line into `count` separate items (e.g. 3 tacos) whose prices add up exactly.
    func split(into count: Int) -> [BillItem] {
        guard count > 1 else { return [self] }
        return Split.allocate(priceCents, weights: Array(repeating: 1, count: count)).map {
            BillItem(name: name, priceCents: $0, sharedBy: sharedBy)
        }
    }
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
    /// Who put the bill on their card. Everyone else pays them back.
    var paidBy: UUID?
    /// People who've already paid the payer back.
    var settled: Set<UUID> = []

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

    var payer: Person? { people.first { $0.id == paidBy } }

    /// Someone who still owes the payer money (everyone except the payer, until they're marked paid).
    func stillOwes(_ personID: UUID) -> Bool {
        paidBy != nil && personID != paidBy && !settled.contains(personID)
    }

    /// How much the payer is still waiting to get back.
    var outstandingCents: Int {
        Split.summarize(self).shares.filter { stillOwes($0.id) }.reduce(0) { $0 + $1.totalCents }
    }

    var isFullySettled: Bool {
        paidBy != nil && people.allSatisfy { !stillOwes($0.id) }
    }

    mutating func removePeople(at offsets: IndexSet) {
        let removed = Set(offsets.map { people[$0].id })
        people.remove(atOffsets: offsets)
        settled.subtract(removed)
        if let paidBy, removed.contains(paidBy) { self.paidBy = nil }
        for index in items.indices {
            items[index].sharedBy.subtract(removed)
        }
    }
}

extension Bill {
    private enum CodingKeys: String, CodingKey {
        case id, title, date, people, items, taxCents, tip, paidBy, settled
    }

    /// Reads bills saved by older versions too: fields added later fall back to their defaults.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? .now
        people = try c.decodeIfPresent([Person].self, forKey: .people) ?? []
        items = try c.decodeIfPresent([BillItem].self, forKey: .items) ?? []
        taxCents = try c.decodeIfPresent(Int.self, forKey: .taxCents) ?? 0
        tip = try c.decodeIfPresent(Tip.self, forKey: .tip) ?? .percent(18)
        paidBy = try c.decodeIfPresent(UUID.self, forKey: .paidBy)
        settled = try c.decodeIfPresent(Set<UUID>.self, forKey: .settled) ?? []
    }
}
