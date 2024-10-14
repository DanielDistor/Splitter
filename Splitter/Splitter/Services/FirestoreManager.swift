import Firebase
import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()

    private init() {}

    func addEvent(title: String, date: Date, completion: @escaping (Bool) -> Void) {
        db.collection("events").addDocument(data: [
            "title": title,
            "date": Timestamp(date: date)
        ]) { error in
            completion(error == nil)
        }
    }

    func fetchEvents(completion: @escaping ([Event]) -> Void) {
        db.collection("events").order(by: "date", descending: true).getDocuments { snapshot, error in
            var events: [Event] = []
            if let snapshot = snapshot {
                events = snapshot.documents.compactMap { doc -> Event? in
                    let data = doc.data()
                    let id = doc.documentID
                    let title = data["title"] as? String ?? "Untitled"
                    let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                    return Event(id: id, title: title, date: date)
                }
            } else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
            }
            completion(events)
        }
    }

    func addParticipantToEvent(eventId: String, name: String, completion: @escaping (Bool) -> Void) {
        db.collection("events").document(eventId).collection("participants").addDocument(data: [
            "name": name
        ]) { error in
            completion(error == nil)
        }
    }

    func addDishToEvent(eventId: String, dishName: String, price: Double, orderedBy: String, completion: @escaping (Bool) -> Void) {
        db.collection("events").document(eventId).collection("dishes").addDocument(data: [
            "dishName": dishName,
            "price": price,
            "orderedBy": orderedBy
        ]) { error in
            completion(error == nil)
        }
    }

    func addExpensesToEvent(eventId: String, subtotal: Double, tax: Double, tip: Double, total: Double, completion: @escaping (Bool) -> Void) {
        db.collection("events").document(eventId).collection("expenses").addDocument(data: [
            "subtotal": subtotal,
            "tax": tax,
            "tip": tip,
            "total": total
        ]) { error in
            completion(error == nil)
        }
    }
}
