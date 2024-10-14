import SwiftUI
import FirebaseFirestore

struct NewEventView: View {
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var participants: [String] = [""]
    @State private var dishes: [Dish] = [Dish()]
    @State private var subtotal: String = ""
    @State private var tax: String = ""
    @State private var tip: String = ""
    @State private var total: String = ""
    
    @Environment(\.presentationMode) var presentationMode
    var onEventSaved: (() -> Void)?  // Optional callback

    var body: some View {
        NavigationView {
            Form {
                TextField("Event Title", text: $title)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Section(header: Text("Participants")) {
                    ForEach($participants.indices, id: \.self) { index in
                        TextField("Participant Name", text: $participants[index])
                    }
                    Button("Add Participant") {
                        participants.append("")
                    }
                }
                
                Section(header: Text("Dishes")) {
                    ForEach($dishes.indices, id: \.self) { index in
                        DishView(dish: $dishes[index])
                    }
                    Button("Add Dish") {
                        dishes.append(Dish())
                    }
                }
                
                Section(header: Text("Expenses")) {
                    TextField("Subtotal", text: $subtotal)
                    TextField("Tax", text: $tax)
                    TextField("Tip", text: $tip)
                    TextField("Total", text: $total)
                }
                
                Button("Save Event") {
                    saveEvent()
                }
            }
            .navigationBarTitle("New Event", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func saveEvent() {
        guard let doubleSubtotal = Double(subtotal),
              let doubleTax = Double(tax),
              let doubleTip = Double(tip),
              let doubleTotal = Double(total) else {
            print("Invalid numbers entered.")
            return
        }
        
        let db = Firestore.firestore()
        let eventRef = db.collection("events").document()
        
        eventRef.setData([
            "title": title,
            "date": Timestamp(date: date),
            "subtotal": doubleSubtotal,
            "tax": doubleTax,
            "tip": doubleTip,
            "total": doubleTotal
        ]) { error in
            if let error = error {
                print("Error saving event: \(error)")
                return
            }
            
            // Save participants
            for participant in participants where !participant.isEmpty {
                eventRef.collection("participants").addDocument(data: ["name": participant])
            }
            
            // Save dishes
            for dish in dishes {
                eventRef.collection("dishes").addDocument(data: [
                    "name": dish.name,
                    "price": dish.price,
                    "orderedBy": dish.orderedBy
                ])
            }
            
            // Update expenses as a single document
            eventRef.collection("expenses").addDocument(data: [
                "subtotal": doubleSubtotal,
                "tax": doubleTax,
                "tip": doubleTip,
                "total": doubleTotal
            ])
            
            onEventSaved?()  // Call the callback if set
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct DishView: View {
    @Binding var dish: Dish
    
    @State private var priceString: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Ordered By:")
                TextField("Who ordered?", text: $dish.orderedBy)
            }
            HStack {
                Text("Dish Name:")
                TextField("Enter dish name", text: $dish.name)
            }
            HStack {
                Text("Price:")
                TextField("Enter price", text: $priceString)
                    .onAppear {
                        if dish.price != 0 {
                            priceString = String(format: "%.2f", dish.price)
                        }
                    }
                    .onChange(of: priceString) { newValue in
                        if let value = Double(newValue) {
                            dish.price = value
                        } else {
                            priceString = "" 
                        }
                    }
                    .keyboardType(.decimalPad)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct Dish: Identifiable {
    let id = UUID()
    var name: String = ""
    var price: Double = 0
    var orderedBy: String = ""
}

extension View {
    @ViewBuilder
    func placeholder<T: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> T) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder().foregroundColor(.secondary)
            }
            self
        }
    }
}
