import Foundation

struct ItemShare: Hashable {
    let name: String
    let cents: Int
    let splitCount: Int
}

struct PersonShare: Identifiable, Hashable {
    var id: UUID { person.id }
    let person: Person
    var items: [ItemShare] = []
    var subtotalCents = 0
    var taxCents = 0
    var tipCents = 0
    var totalCents: Int { subtotalCents + taxCents + tipCents }
}

struct BillSummary: Hashable {
    let subtotalCents: Int
    let taxCents: Int
    let tipCents: Int
    let shares: [PersonShare]
    var totalCents: Int { subtotalCents + taxCents + tipCents }
}

/// All money is handled in whole cents so every person's share adds up exactly to the bill.
enum Split {
    /// Splits `total` across recipients in proportion to `weights` (largest-remainder method),
    /// so the parts always sum to `total`. Equal remainders go to earlier recipients.
    static func allocate(_ total: Int, weights: [Int]) -> [Int] {
        guard !weights.isEmpty else { return [] }
        let weights = weights.reduce(0, +) > 0 ? weights : Array(repeating: 1, count: weights.count)
        let weightSum = weights.reduce(0, +)

        var parts = weights.map { total * $0 / weightSum }
        let remainders = weights.map { total * $0 % weightSum }
        let leftover = total - parts.reduce(0, +)
        let order = remainders.indices.sorted { remainders[$0] != remainders[$1] ? remainders[$0] > remainders[$1] : $0 < $1 }
        for index in order.prefix(leftover) {
            parts[index] += 1
        }
        return parts
    }

    static func tipCents(for bill: Bill, subtotalCents: Int) -> Int {
        switch bill.tip {
        case .percent(let percent): Int((Double(subtotalCents) * percent / 100).rounded())
        case .amount(let cents): cents
        }
    }

    static func summarize(_ bill: Bill) -> BillSummary {
        let subtotal = bill.items.reduce(0) { $0 + $1.priceCents }
        let tip = tipCents(for: bill, subtotalCents: subtotal)
        var shares = bill.people.map { PersonShare(person: $0) }

        if !shares.isEmpty {
            for item in bill.items {
                var sharers = bill.people.indices.filter { item.sharedBy.contains(bill.people[$0].id) }
                if sharers.isEmpty { sharers = Array(bill.people.indices) }

                let parts = allocate(item.priceCents, weights: Array(repeating: 1, count: sharers.count))
                for (sharer, cents) in zip(sharers, parts) {
                    shares[sharer].items.append(ItemShare(name: item.name, cents: cents, splitCount: sharers.count))
                    shares[sharer].subtotalCents += cents
                }
            }

            let weights = shares.map(\.subtotalCents)
            for (index, cents) in allocate(bill.taxCents, weights: weights).enumerated() {
                shares[index].taxCents = cents
            }
            for (index, cents) in allocate(tip, weights: weights).enumerated() {
                shares[index].tipCents = cents
            }
        }

        return BillSummary(subtotalCents: subtotal, taxCents: bill.taxCents, tipCents: tip, shares: shares)
    }
}
