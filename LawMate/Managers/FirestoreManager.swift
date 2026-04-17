import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    @Published var cases: [FBLegalCase] = []
    @Published var lawyers: [User] = []
    @Published var clients: [User] = []
    @Published var conversations: [FBConversation] = []
    @Published var messages: [FBMessage] = []
    
    private var casesListener: ListenerRegistration?
    private var lawyersListener: ListenerRegistration?
    private var clientsListener: ListenerRegistration?
    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    
    // MARK: - Lawyers
    
    func listenForLawyers() {
        lawyersListener = db.collection("users")
            .whereField("role", isEqualTo: "Lawyer")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching lawyers: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self?.lawyers = documents.compactMap { try? $0.data(as: User.self) }
            }
    }
    
    func listenForClients() {
        clientsListener = db.collection("users")
            .whereField("role", isEqualTo: "Client")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching clients: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self?.clients = documents.compactMap { try? $0.data(as: User.self) }
            }
    }
    
    func seedInitialLawyers() {
        let mockLawyers = [
            User(id: "L1", fullName: "Nimal Perera", email: "nimal@lawmate.com", role: .lawyer, phoneNumber: "+94 77 111 2222", specialty: "Criminal Law", experience: "14 YEARS", bio: "Experienced criminal lawyer handling complex court cases"),
            User(id: "L2", fullName: "Sanduni Fernando", email: "sanduni@lawmate.com", role: .lawyer, phoneNumber: "+94 77 333 4444", specialty: "Family Law", experience: "10 YEARS", bio: "Family law specialist focusing on divorce and custody"),
            User(id: "L3", fullName: "Ravindu Silva", email: "ravindu@lawmate.com", role: .lawyer, phoneNumber: "+94 77 555 6666", specialty: "Corporate Law", experience: "12 YEARS", bio: "Corporate lawyer advising businesses on legal compliance"),
            User(id: "L4", fullName: "Ishara Jayasinghe", email: "ishara@lawmate.com", role: .lawyer, phoneNumber: "+94 77 777 8888", specialty: "Property Law", experience: "8 YEARS", bio: "Property law expert handling land disputes")
        ]
        
        for lawyer in mockLawyers {
            try? db.collection("users").document(lawyer.id).setData(from: lawyer)
        }
    }
    
    // MARK: - Cases
    
    func listenForCases(role: UserRole, userId: String) {
        // Query cases where user is either client or lawyer depending on role
        var query: Query = db.collection("cases")
        
        switch role {
        case .lawyer:
            query = query.whereField("lawyerId", isEqualTo: userId)
        case .client:
            query = query.whereField("clientId", isEqualTo: userId)
        default:
            return
        }
        
        // Remove existing listener before re-subscribing
        casesListener?.remove()
        
        casesListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching cases: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            let fetchedCases = documents.compactMap { doc -> FBLegalCase? in
                try? doc.data(as: FBLegalCase.self)
            }
            
            // Sort manually in Swift to avoid index requirements and missing field exclusions
            self?.cases = fetchedCases.sorted { ($0.createdDate ?? Date.distantPast) > ($1.createdDate ?? Date.distantPast) }
        }
    }
    
    func stopListening() {
        casesListener?.remove()
        lawyersListener?.remove()
        clientsListener?.remove()
        conversationsListener?.remove()
        messagesListener?.remove()
    }
    
    func addCase(_ newCase: FBLegalCase) {
        do {
            let _ = try db.collection("cases").addDocument(from: newCase)
        } catch {
            print("Error creating case: \(error)")
        }
    }
    
    func updateCase(_ modifiedCase: FBLegalCase) {
        guard let id = modifiedCase.id else { return }
        do {
            try db.collection("cases").document(id).setData(from: modifiedCase)
        } catch {
            print("Error updating case: \(error)")
        }
    }
    
    func deleteCase(id: String) {
        db.collection("cases").document(id).delete()
    }
    
    // MARK: - Documents
    
    func addDocument(toCaseId caseId: String, fileName: String, fileType: String) {
        let newDoc = FBDocument(legalCaseId: caseId, fileName: fileName, fileType: fileType, uploadedAt: Date())
        do {
            let _ = try db.collection("documents").addDocument(from: newDoc)
        } catch {
            print("Error uploading document: \(error)")
        }
    }
    
    func fetchDocuments(forCaseId caseId: String, completion: @escaping ([FBDocument]) -> Void) {
        db.collection("documents")
            .whereField("legalCaseId", isEqualTo: caseId)
            .order(by: "uploadedAt", descending: true)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else {
                    print("Error fetching docs: \(error?.localizedDescription ?? "unknown")")
                    completion([])
                    return
                }
                
                let documents = docs.compactMap { try? $0.data(as: FBDocument.self) }
                completion(documents)
            }
    }
    
    // MARK: - Messaging
    
    func listenForConversations(userId: String) {
        conversationsListener?.remove()
        
        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self?.conversations = documents.compactMap { try? $0.data(as: FBConversation.self) }
            }
    }
    
    func listenForMessages(conversationId: String) {
        messagesListener?.remove()
        
        messagesListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self?.messages = documents.compactMap { try? $0.data(as: FBMessage.self) }
            }
    }
    
    func sendMessage(to conversationId: String, text: String, senderId: String) {
        let newMessage = FBMessage(senderId: senderId, text: text, timestamp: Date())
        
        do {
            let _ = try db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(from: newMessage)
            
            // Update last message in conversation
            db.collection("conversations").document(conversationId).updateData([
                "lastMessage": text,
                "lastMessageAt": Timestamp(date: Date())
            ])
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    func getOrCreateConversation(between user1: String, and user2: String, partnerInfo: (name: String, image: String?), currentUser: User, completion: @escaping (String) -> Void) {
        // Sort participants to have consistent ID formation or querying
        let sortedParticipants = [user1, user2].sorted()
        
        db.collection("conversations")
            .whereField("participants", isEqualTo: sortedParticipants)
            .getDocuments { [weak self] snapshot, error in
                if let doc = snapshot?.documents.first {
                    completion(doc.documentID)
                } else {
                    // Create new conversation
                    var memberNames = [user1: partnerInfo.name, user2: partnerInfo.name]
                    var memberImages = [user1: partnerInfo.image, user2: partnerInfo.image]
                    
                    // Correct the names/images for the current user
                    memberNames[currentUser.id] = currentUser.fullName
                    memberImages[currentUser.id] = currentUser.profileImage
                    
                    let newConversation = FBConversation(
                        participants: sortedParticipants,
                        lastMessage: "Start a conversation",
                        lastMessageAt: Date(),
                        memberNames: memberNames,
                        memberImages: memberImages
                    )
                    
                    do {
                        let ref = try self?.db.collection("conversations").addDocument(from: newConversation)
                        completion(ref?.documentID ?? "")
                    } catch {
                        print("Error creating conversation: \(error)")
                    }
                }
            }
    }
}

