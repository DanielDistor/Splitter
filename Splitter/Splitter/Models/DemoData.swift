#if DEBUG
import UIKit

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

    /// A fake restaurant receipt photo, for trying the scanner in the simulator (no camera there).
    static func receiptImage() -> UIImage {
        let lines: [(String, String)] = [
            ("BELLA NOTTE", ""),
            ("Table 12   Server: Jo", ""),
            ("Margherita Pizza", "18.00"),
            ("Ribeye", "34.00"),
            ("Caesar Salad", "12.00"),
            ("Bottle of Wine", "42.00"),
            ("Subtotal", "106.00"),
            ("Tax", "10.16"),
            ("Total", "116.16"),
            ("VISA ****4821", "116.16"),
        ]
        let size = CGSize(width: 640, height: 120 + lines.count * 64)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .medium),
                .foregroundColor: UIColor.black,
            ]
            for (row, line) in lines.enumerated() {
                let y = 60 + CGFloat(row) * 64
                (line.0 as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: attributes)
                let price = line.1 as NSString
                price.draw(at: CGPoint(x: size.width - 40 - price.size(withAttributes: attributes).width, y: y), withAttributes: attributes)
            }
        }
    }
}
#endif
