import SwiftUI
import FirebaseFirestore

struct SplitView: View {
    @State private var events: [Event] = []
    @State private var showingNewEventView = false

    var body: some View {
        NavigationView {
            List(events, id: \.id) { event in
                NavigationLink(destination: EventDetailView(event: event)) {
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.headline)
                        Text("\(event.date, formatter: itemFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Events")
            .navigationBarItems(trailing: Button("New") {
                showingNewEventView = true
            })
            .sheet(isPresented: $showingNewEventView, onDismiss: loadEvents) {
                NewEventView(onEventSaved: loadEvents)
            }
            .onAppear {
                loadEvents()
            }
        }
    }

    private func loadEvents() {
        let db = Firestore.firestore()
        db.collection("events").order(by: "date", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            self.events = documents.compactMap { doc -> Event? in
                guard let title = doc.data()["title"] as? String,
                      let timestamp = doc.data()["date"] as? Timestamp else {
                    print("Document data was not correctly mapped")
                    return nil
                }
                return Event(id: doc.documentID, title: title, date: timestamp.dateValue())
            }
        }
    }

    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
}
