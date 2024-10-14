import SwiftUI
import FirebaseFirestore

struct EventDetailView: View {
    var event: Event
    @State private var participants: [String]? = []
    @State private var dishes: [EventDish]? = []
    @State private var expenses: Expenses?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(event.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.blue)
                
                Text("Date: \(event.date, formatter: DateFormatter.eventDateFormatter())")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                participantsView
                dishesView
                VStack(alignment: .center, spacing: 15) {
                    expensesView
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)

                    totalPerPersonView
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationBarTitle("Event Details", displayMode: .inline)
        .onAppear {
            loadEventDetails()
        }
    }

    private var participantsView: some View {
        Group {
            if let participants = participants, !participants.isEmpty {
                HStack {
                    Text("Participants: ")
                        .font(.headline)
                    ForEach(participants, id: \.self) { participant in
                        Text(participant)
                            .padding(5)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(5)
                    }
                }.padding(.vertical, 5)
            } else {
                Text("No participants added")
                    .italic()
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }

    private var dishesView: some View {
        Group {
            Text("Dishes")
                .font(.headline)
                .padding(.vertical, 5)
            
            if let dishes = dishes, !dishes.isEmpty {
                VStack {
                    ForEach(dishes.sorted { first, second in
                        participants?.firstIndex(of: first.orderedBy) ?? 0 < participants?.firstIndex(of: second.orderedBy) ?? 0
                    }) { dish in
                        HStack {
                            Text(dish.orderedBy)
                                .bold()
                                .frame(width: 100, alignment: .leading)
                            Text(dish.name)
                                .frame(width: 150, alignment: .center)
                            Text("$\(dish.price, specifier: "%.2f")")
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                    }
                }
            } else {
                Text("No dishes added")
                    .italic()
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }

    private var expensesView: some View {
        Group {
            if let expenses = expenses {
                VStack(alignment: .leading) {
                    Text("Expenses")
                        .font(.headline)
                        .padding(.vertical, 5)
                    
                    Text("Subtotal: $\(expenses.subtotal, specifier: "%.2f")")
                    Text("Tax: $\(expenses.tax, specifier: "%.2f")")
                    Text("Tip: $\(expenses.tip, specifier: "%.2f")")
                    Text("Total: $\(expenses.total, specifier: "%.2f")")
                }
            } else {
                Text("No expenses recorded")
                    .italic()
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }

    private var totalPerPersonView: some View {
        VStack {
            let totalPerPerson = calculateTotalPerPerson()
            Text("Total Per Person")
                .font(.headline)
                .padding(.vertical, 5)
            ForEach(participants ?? [], id: \.self) { participant in
                let personalExpense = (dishes?.first(where: { $0.orderedBy == participant })?.price ?? 0) + totalPerPerson
                Text("\(participant): $\(personalExpense, specifier: "%.2f")")
            }
        }
    }

    private func loadEventDetails() {
        let db = Firestore.firestore()
        let eventRef = db.collection("events").document(event.id)

        eventRef.collection("participants").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching participants: \(error.localizedDescription)")
                return
            }
            participants = snapshot?.documents.compactMap { $0.data()["name"] as? String }
        }

        eventRef.collection("dishes").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching dishes: \(error.localizedDescription)")
                return
            }
            dishes = snapshot?.documents.compactMap { doc -> EventDish? in
                guard let name = doc.data()["name"] as? String,
                      let price = doc.data()["price"] as? Double,
                      let orderedBy = doc.data()["orderedBy"] as? String else {
                        return nil
                    }
                return EventDish(id: doc.documentID, name: name, price: price, orderedBy: orderedBy)
            }
        }

        eventRef.collection("expenses").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching expenses: \(error.localizedDescription)")
                return
            }
            if let data = snapshot?.documents.first?.data() {
                expenses = Expenses(
                    subtotal: data["subtotal"] as? Double ?? 0,
                    tax: data["tax"] as? Double ?? 0,
                    tip: data["tip"] as? Double ?? 0,
                    total: data["total"] as? Double ?? 0
                )
            }
        }
    }

    private func calculateTotalPerPerson() -> Double {
        guard let expenses = expenses, let participants = participants, !participants.isEmpty else {
            return 0
        }
        let sharedCost = (expenses.tax + expenses.tip) / Double(participants.count)
        return sharedCost
    }
}

extension DateFormatter {
    static func eventDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
