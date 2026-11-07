import XCTest
@testable import Splitter

final class ReceiptParserTests: XCTestCase {
    func testReadsItemsTaxAndTotals() {
        let receipt = ReceiptParser.parse(lines: [
            "LUIGI'S TRATTORIA",
            "123 Main St",
            "11/05/2026 7:42 PM",
            "Margherita Pizza 18.00",
            "Ribeye Steak $34.00",
            "2 Iced Tea 7.50",
            "Subtotal 59.50",
            "Sales Tax 5.21",
            "Total $64.71",
            "VISA ****1234 64.71",
            "Change 0.00",
        ])

        XCTAssertEqual(receipt.items.map(\.name), ["Margherita Pizza", "Ribeye Steak", "2 Iced Tea"])
        XCTAssertEqual(receipt.items.map(\.priceCents), [1_800, 3_400, 750])
        XCTAssertEqual(receipt.subtotalCents, 5_950)
        XCTAssertEqual(receipt.taxCents, 521)
        XCTAssertEqual(receipt.totalCents, 6_471)
        XCTAssertNil(receipt.tipCents)
    }

    func testHandlesTrailingTaxFlagsAndCommaDecimals() {
        let receipt = ReceiptParser.parse(lines: ["Bread 3,49 T", "Milk 2.99 F", "TOTAL 6.48"])
        XCTAssertEqual(receipt.items.map(\.priceCents), [349, 299])
        XCTAssertEqual(receipt.totalCents, 648)
    }

    func testSkipsDiscountsAndLinesWithoutNames() {
        let receipt = ReceiptParser.parse(lines: ["Burger 12.00", "Coupon -2.00", "12.00", "Total 10.00"])
        XCTAssertEqual(receipt.items.map(\.name), ["Burger"])
    }

    func testReadsTipAndGratuity() {
        XCTAssertEqual(ReceiptParser.parse(lines: ["Pasta 20.00", "Gratuity 18% 3.60"]).tipCents, 360)
        XCTAssertEqual(ReceiptParser.parse(lines: ["Pasta 20.00", "Tip 4.00"]).tipCents, 400)
    }

    func testTaxLineMentioningPercentStillReadsTheAmount() {
        XCTAssertEqual(ReceiptParser.parse(lines: ["Soup 8.00", "Tax 8.875% 0.71"]).taxCents, 71)
    }

    func testIgnoresEverythingAfterTheTotal() {
        let receipt = ReceiptParser.parse(lines: ["Soup 8.00", "Total 8.00", "Thank you! Free cookie 0.00", "Loyalty Points 120.00"])
        XCTAssertEqual(receipt.items.count, 1)
    }

    func testItemsAddUpCheck() {
        let receipt = ReceiptParser.parse(lines: ["A 5.00", "B 5.00", "Subtotal 12.00"])
        XCTAssertEqual(receipt.itemsSumCents, 1_000)
        XCTAssertFalse(receipt.itemsMatchSubtotal)
    }
}

final class ReceiptRowGroupingTests: XCTestCase {
    /// Vision often returns the item name and its price as separate boxes on the same row.
    func testMergesBoxesOnTheSameRowLeftToRight() {
        let boxes = [
            TextBox(text: "18.00", rect: CGRect(x: 0.8, y: 0.80, width: 0.1, height: 0.03)),
            TextBox(text: "Pizza", rect: CGRect(x: 0.1, y: 0.805, width: 0.3, height: 0.03)),
            TextBox(text: "Salad", rect: CGRect(x: 0.1, y: 0.75, width: 0.3, height: 0.03)),
            TextBox(text: "12.00", rect: CGRect(x: 0.8, y: 0.748, width: 0.1, height: 0.03)),
        ]
        XCTAssertEqual(ReceiptParser.rows(from: boxes), ["Pizza 18.00", "Salad 12.00"])
    }
}

final class ReceiptOCRTests: XCTestCase {
    /// End to end: render a receipt image, read it with Vision, parse it.
    func testScansARenderedReceipt() async throws {
        let image = DemoData.receiptImage()
        let receipt = try await ReceiptScanner.scan(image)
        XCTAssertEqual(receipt.items.count, 4, "\(receipt.items)")
        XCTAssertEqual(receipt.taxCents, 1_016)
        XCTAssertEqual(receipt.itemsSumCents, 10_600)
    }
}
