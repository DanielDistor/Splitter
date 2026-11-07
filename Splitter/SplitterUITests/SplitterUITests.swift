import XCTest

final class SplitterUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Creates a bill from scratch the way a person would and checks the split.
    func testSplittingANewBill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launch()

        app.navigationBars.buttons["New Bill"].tap()
        let title = app.textFields["What's this bill for?"]
        title.tap()
        title.typeText("Tacos")

        let addPerson = app.textFields["Add a person"]
        addPerson.tap()
        addPerson.typeText("Dani\n")
        addPerson.typeText("Sam\n")

        app.buttons["Add Item"].tap()
        let itemName = app.textFields["Item name"]
        XCTAssertTrue(itemName.waitForExistence(timeout: 3))
        itemName.typeText("Taco Platter")
        app.textFields["Price"].tap()
        app.textFields["Price"].typeText("30")
        app.buttons["Save"].tap()

        app.buttons["0%"].tap()
        app.swipeUp()

        XCTAssertTrue(app.staticTexts["$30.00"].exists)
        XCTAssertTrue(app.staticTexts["$15.00"].waitForExistence(timeout: 2), "Each person should owe half")
        snapshot(app, "4-new-bill")
    }

    func testDemoBillBreakdown() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-openBill"]
        app.launch()
        app.swipeUp()
        snapshot(app, "5-totals")
        app.swipeUp()
        let alice = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Alice'")).firstMatch
        XCTAssertTrue(alice.label.contains("$45.36"), "Alice owes her food + proportional tax and tip")
        alice.tap()
        XCTAssertTrue(app.staticTexts["Margherita Pizza (÷2)"].waitForExistence(timeout: 2))
        snapshot(app, "6-who-owes")
    }

    /// The simulator has no camera, so `-scanDemoReceipt` feeds the scanner a rendered sample receipt.
    func testScanningAReceiptFillsTheBill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-scanDemoReceipt"]
        app.launch()
        app.navigationBars.buttons["New Bill"].tap()

        XCTAssertTrue(app.navigationBars["Scanned Receipt"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Matches the receipt subtotal."].exists)
        snapshot(app, "7-scan-review")

        app.buttons["Add 4 Items"].tap()
        XCTAssertTrue(app.staticTexts["Ribeye"].waitForExistence(timeout: 3))
        app.swipeUp()
        snapshot(app, "8-scan-added")
        XCTAssertTrue(app.anyElement(containing: "$106.00").exists, "Subtotal from the scanned items")
        XCTAssertTrue(app.anyElement(containing: "$10.16").exists, "Tax picked up from the receipt")
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appending(path: "\(name).png"))
        }
    }
}

private extension XCUIApplication {
    func anyElement(containing text: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)).firstMatch
    }
}
