<p align="center">
  <img src="docs/logo.png" width="96" alt="Splitter app icon">
</p>

<h1 align="center">Splitter</h1>

<p align="center">
  Splitter is an iPhone app that helps you split a restaurant bill with your friends.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.2%2B-225E82" alt="iOS 17.2+">
  <img src="https://img.shields.io/badge/SwiftUI-native-225E82" alt="SwiftUI">
  <img src="https://img.shields.io/badge/accounts-none-225E82" alt="No accounts">
  <img src="https://img.shields.io/badge/data-stays%20on%20your%20phone-225E82" alt="Data stays on your phone">
</p>

---

## First launch

This is the first thing you see when you open Splitter. You can see it again anytime with the ⓘ button on the home screen.

<p align="center">
  <img src="docs/screenshots/welcome.png" width="300" alt="Welcome to Splitter: scan the receipt, pick who had what, fair to the penny">
</p>

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/home.png" width="240" alt="Home screen"><br><sub><b>Your bills</b><br>Everything you've split, grouped by month</sub></td>
    <td align="center"><img src="docs/screenshots/bill.png" width="240" alt="A bill"><br><sub><b>A bill</b><br>Who owes what, right at the top</sub></td>
    <td align="center"><img src="docs/screenshots/settle.png" width="240" alt="Who paid and settling up"><br><sub><b>Settle up</b><br>Who paid and who's paid them back</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/person.png" width="240" alt="One person's breakdown"><br><sub><b>One person</b><br>Their breakdown and a Venmo request</sub></td>
    <td align="center"><img src="docs/screenshots/scan.png" width="240" alt="Scanned receipt review"><br><sub><b>Scan a receipt</b><br>Check what it read before adding</sub></td>
    <td align="center"><img src="docs/screenshots/home-dark.png" width="240" alt="Dark mode"><br><sub><b>Dark mode</b></sub></td>
  </tr>
</table>

## What it does

**Scan the receipt.** Take a photo of the receipt and Splitter fills in the items, tax and tip for you. It reads the receipt on your phone using Apple's Vision.

**Tap who had what.** Each item shows everyone's initials. Tap the people who had it, like two people sharing a pizza or the whole table sharing a bottle of wine.

**Fair to the penny.** Tax and tip are split by how much each person ordered instead of evenly. Everyone's shares always add up to the exact total.

**Settle up.** Mark who paid the bill and check people off as they pay them back.

**Get paid back.** Send a Venmo request with the amount already filled in, or share the whole split in your group chat.

**Edit anything.** Add someone you forgot, change who had what or fix the tip and everything updates. If you delete something by accident you can tap Undo.

**Private.** There are no accounts and nothing gets uploaded. Your bills stay on your phone.

## How the split works

Here's the Birthday Dinner from the screenshots. Alice and Bob shared an $18 pizza and Alice also had a $12 salad. Cara had a $34 ribeye. Everyone shared a $42 bottle of wine. Tax was $10.16 and they tipped 20%.

| | Food | Share of tax | Share of tip | **Owes** |
|---|---:|---:|---:|---:|
| Alice | $9 + $12 + $14 = $35.00 | $3.36 | $7.00 | **$45.36** |
| Bob | $9 + $14 = $23.00 | $2.20 | $4.60 | **$29.80** |
| Cara | $34 + $14 = $48.00 | $4.60 | $9.60 | **$62.20** |
| **Total** | $106.00 | $10.16 | $21.20 | **$137.36** |

Cara ordered the most food so she pays the most tax and tip. When the math doesn't divide evenly the extra pennies go to whoever was closest to the next cent, so the shares always add up to the exact total.

## Build & run

You need a Mac with Xcode 16 or newer. Open `Splitter/Splitter.xcodeproj`, pick a simulator or your iPhone at the top and press **Run** (⌘R). To run it on your own iPhone, pick your team under **Signing & Capabilities** first. There's nothing else to install or set up.

> **Tip:** The simulator has no camera. To try scanning there, drag a receipt photo onto the simulator and use **Scan Receipt → Choose from Photos**.

### Debug launch arguments

Add these under **Product → Scheme → Edit Scheme → Run → Arguments** to help with testing.

| Argument | What it does |
|---|---|
| `-demo` | Starts with sample bills kept in a temporary file, so your real data isn't touched |
| `-skipWelcome` | Goes straight to the home screen |
| `-openBill` | Opens the newest bill on launch |
| `-scanDemoReceipt` | Scans a built-in sample receipt when a bill opens |

## Tests

```sh
cd Splitter
xcodebuild test -project Splitter.xcodeproj -scheme Splitter \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

There are 45 tests. The unit tests check the split math, receipt scanning, settling up and saving your bills. The UI tests use the app the way a person would to make sure the main things work.

## Project structure

```
Splitter/
├── Splitter/
│   ├── Setup/        App entry point
│   ├── Models/       Bill, Split (the math), Money, ReceiptParser, DemoData
│   ├── Services/     BillStore (saves bills on the device), ReceiptScanner (Vision)
│   ├── Views/        Screens and the Theme (colors, cards, avatars)
│   └── PrivacyInfo.xcprivacy
├── SplitterTests/    Unit tests
└── SplitterUITests/  UI tests
```

## History

Splitter started in 2024 as a class project. That version had sign-in and a recipe tab. In 2026 I rebuilt it to focus on splitting bills.

The original version is saved under the [`v1-original`](https://github.com/DanielDistor/Splitter/tree/v1-original) tag and the [`original-2024`](https://github.com/DanielDistor/Splitter/tree/original-2024) branch. The original write-up is in [`docs/original-2024/`](docs/original-2024/aboutme.md).

---

<p align="center"><sub>Made by Daniel Distor</sub></p>
