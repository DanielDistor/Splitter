import CoreGraphics
import Foundation

/// A piece of text Vision found, in Vision's normalized coordinates (origin bottom-left).
struct TextBox {
    let text: String
    let rect: CGRect
}

struct ScannedItem: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var priceCents: Int
    /// "2 Iced Tea" → 2. Added to the bill as separate items so each can go to a different person.
    var quantity = 1
    var include = true
}

struct ScannedReceipt: Identifiable, Hashable {
    var id = UUID()
    var items: [ScannedItem] = []
    var subtotalCents: Int?
    var taxCents: Int?
    var tipCents: Int?
    var totalCents: Int?

    var itemsSumCents: Int { items.reduce(0) { $0 + $1.priceCents } }

    /// False when the receipt shows a subtotal that the items we found don't add up to.
    var itemsMatchSubtotal: Bool { subtotalCents.map { $0 == itemsSumCents } ?? true }
}

/// Turns the lines of a receipt into items, tax, tip and totals. Pure and testable.
enum ReceiptParser {
    /// "<name> <price> <optional one-letter tax flag>", e.g. "Bread 3,49 T" or "Ribeye $34.00".
    private static let priceLine = /^(.*?)\s*(-)?\s*\$?\s?(\d{1,5}[.,]\d{2})\s*[A-Za-z]?$/

    private static let paymentWords: Set<String> = [
        "change", "cash", "visa", "mastercard", "amex", "card", "debit", "credit",
        "payment", "tender", "tendered", "discount", "coupon", "savings", "paid",
    ]

    static func parse(lines: [String]) -> ScannedReceipt {
        var receipt = ScannedReceipt()

        for line in lines {
            guard let match = line.trimmingCharacters(in: .whitespaces).wholeMatch(of: priceLine) else { continue }
            let name = String(match.1).trimmingCharacters(in: .whitespaces.union(.punctuationCharacters.subtracting(["%", "'"])))
            guard match.2 == nil, let cents = Money.parseCents(String(match.3)) else { continue }

            let words = Set(name.lowercased().split { !$0.isLetter }.map(String.init))
            if words.isEmpty { continue }

            if words.contains("subtotal") || (words.contains("sub") && words.contains("total")) {
                receipt.subtotalCents = cents
            } else if words.contains("tax") || words.contains("hst") || words.contains("gst") || words.contains("vat") {
                receipt.taxCents = (receipt.taxCents ?? 0) + cents
            } else if words.contains("tip") || words.contains("gratuity") {
                receipt.tipCents = cents
            } else if words.contains("total") || words.contains("balance") || (words.contains("amount") && words.contains("due")) {
                receipt.totalCents = cents
                break // Anything after the total is payment details.
            } else if words.isDisjoint(with: paymentWords) {
                let (quantity, itemName) = splitQuantity(name)
                receipt.items.append(ScannedItem(name: itemName, priceCents: cents, quantity: quantity))
            }
        }
        return receipt
    }

    private static let leadingQuantity = /^(\d{1,2})\s*[xX]?\s+(.*[A-Za-z].*)$/
    private static let trailingQuantity = /^(.*[A-Za-z].*?)\s+[xX]\s?(\d{1,2})$/

    /// "2 Iced Tea", "3x Tacos", "Beer x4" → (quantity, name). Leaves names like "7UP" alone.
    static func splitQuantity(_ name: String) -> (Int, String) {
        if let match = name.wholeMatch(of: leadingQuantity), let count = Int(match.1), (2...20).contains(count) {
            return (count, String(match.2))
        }
        if let match = name.wholeMatch(of: trailingQuantity), let count = Int(match.2), (2...20).contains(count) {
            return (count, String(match.1))
        }
        return (1, name)
    }

    /// Groups text boxes into printed rows (top to bottom), joining each row left to right.
    static func rows(from boxes: [TextBox]) -> [String] {
        var rows: [[TextBox]] = []
        for box in boxes.sorted(by: { $0.rect.midY > $1.rect.midY }) {
            if let last = rows.last?.last,
               abs(last.rect.midY - box.rect.midY) < min(last.rect.height, box.rect.height) * 0.5 {
                rows[rows.count - 1].append(box)
            } else {
                rows.append([box])
            }
        }
        return rows.map { row in
            row.sorted { $0.rect.minX < $1.rect.minX }.map(\.text).joined(separator: " ")
        }
    }
}
