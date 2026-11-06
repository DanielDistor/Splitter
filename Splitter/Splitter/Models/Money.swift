import Foundation

enum Money {
    static var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }

    static var currencySymbol: String { Locale.current.currencySymbol ?? "$" }

    static func format(_ cents: Int) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: currencyCode))
    }

    /// Plain editable text, e.g. 1250 -> "12.50".
    static func plain(_ cents: Int) -> String {
        String(format: "%d.%02d", cents / 100, abs(cents % 100))
    }

    /// Parses what someone typed ("12.5", "$19.99", "12,50") into cents.
    static func parseCents(_ text: String) -> Int? {
        let cleaned = text
            .filter { $0.isNumber || $0 == "." || $0 == "," }
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned) else { return nil }
        return NSDecimalNumber(decimal: value * 100)
            .rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
            .intValue
    }
}
