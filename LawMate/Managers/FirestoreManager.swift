import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()
    
    @Published var cases: [FBLegalCase] = []
    @Published var lawyers: [User] = []
    @Published var clients: [User] = []
    @Published var conversations: [FBConversation] = []
    @Published var messages: [FBMessage] = []
    @Published var totalUnreadCount: Int = 0
    @Published var notifications: [FBNotification] = []
    @Published var appointments: [FBAppointment] = []
    
    private var casesListener: ListenerRegistration?
    private var lawyersListener: ListenerRegistration?
    private var clientsListener: ListenerRegistration?
    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private var notificationsListener: ListenerRegistration?
    private var appointmentsListener: ListenerRegistration?
    private var lastKnownMessageDate: Date? = Date()
    
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
        notificationsListener?.remove()
        appointmentsListener?.remove()
    }
    
    func startSync(role: UserRole, userId: String) {
        listenForCases(role: role, userId: userId)
        listenForConversations(userId: userId)
        listenForNotifications(userId: userId)
        listenForAppointments(userId: userId, role: role)
        if role == .lawyer {
            listenForClients()
        } else {
            listenForLawyers()
        }
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
    
    func updateCaseStage(caseId: String, stageIndex: Int, isCompleted: Bool) {
        db.collection("cases").document(caseId).getDocument { [weak self] snapshot, error in
            guard var legalCase = try? snapshot?.data(as: FBLegalCase.self) else { return }
            if stageIndex < legalCase.stages.count {
                legalCase.stages[stageIndex].isCompleted = isCompleted
                legalCase.stages[stageIndex].date = isCompleted ? Date() : nil
                self?.updateCase(legalCase)
                
                // Add a notification for the client
                let notification = FBNotification(
                    title: "Case Progress Update",
                    body: "The stage '\(legalCase.stages[stageIndex].title)' was marked as \(isCompleted ? "completed" : "pending").",
                    type: "case",
                    timestamp: Date(),
                    relatedId: caseId
                )
                self?.addNotification(notification, toUserId: legalCase.clientId)
            }
        }
    }
    
    // MARK: - Documents
    
    func addDocument(toCaseId caseId: String, fileName: String, fileType: String, fileURL: String? = nil, stageIndex: Int? = nil) {
        let newDoc = FBDocument(
            legalCaseId: caseId,
            fileName: fileName,
            fileType: fileType,
            fileURL: fileURL,
            stageIndex: stageIndex,
            uploadedAt: Date()
        )
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
                let loadedConversations = documents.compactMap { try? $0.data(as: FBConversation.self) }
                self?.conversations = loadedConversations.sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
                
                // Calculate total unread
                self?.totalUnreadCount = loadedConversations.reduce(0) { total, conv in
                    total + (conv.unreadCounts?[userId] ?? 0)
                }
                
                // Trigger notification for new messages
                for conv in loadedConversations {
                    if let lastAt = conv.lastMessageAt, let lastKnown = self?.lastKnownMessageDate {
                        if lastAt > lastKnown {
                            let partner = conv.partnerInfo(for: userId)
                            if (conv.unreadCounts?[userId] ?? 0) > 0 {
                                NotificationManager.shared.scheduleNotification(
                                    title: partner.name,
                                    body: conv.lastMessage ?? "New message"
                                )
                            }
                        }
                    }
                }
                self?.lastKnownMessageDate = Date()
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
        
        // Find recipient ID
        let conversation = conversations.first(where: { $0.id == conversationId })
        let recipientId = conversation?.participants.first(where: { $0 != senderId })
        
        do {
            let _ = try db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(from: newMessage)
            
            // Update last message in conversation and increment unread for recipient
            var updateData: [String: Any] = [
                "lastMessage": text,
                "lastMessageAt": Timestamp(date: Date())
            ]
            
            if let recipientId = recipientId {
                updateData["unreadCounts.\(recipientId)"] = FieldValue.increment(Int64(1))
            }
            
            db.collection("conversations").document(conversationId).updateData(updateData)
            
            // Send a persistent notification to the recipient
            if let recipientId = recipientId {
                let notification = FBNotification(
                    title: "New Message",
                    body: text,
                    type: "message",
                    timestamp: Date(),
                    relatedId: conversationId
                )
                addNotification(notification, toUserId: recipientId)
            }
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
                    var unreadCounts = [user1: 0, user2: 0]
                    
                    // Correct the names/images for the current user
                    memberNames[currentUser.id] = currentUser.fullName
                    memberImages[currentUser.id] = currentUser.profileImage
                    
                    let newConversation = FBConversation(
                        participants: sortedParticipants,
                        lastMessage: "Start a conversation",
                        lastMessageAt: Date(),
                        memberNames: memberNames,
                        memberImages: memberImages,
                        unreadCounts: unreadCounts
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
    
    func markConversationAsRead(id: String, userId: String) {
        db.collection("conversations").document(id).updateData([
            "unreadCounts.\(userId)": 0
        ])
    }
    
    // MARK: - Notifications
    
    func listenForNotifications(userId: String) {
        notificationsListener?.remove()
        
        notificationsListener = db.collection("users")
            .document(userId)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching notifications: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self?.notifications = documents.compactMap { try? $0.data(as: FBNotification.self) }
            }
    }
    
    func addNotification(_ notification: FBNotification, toUserId userId: String, completion: ((Bool) -> Void)? = nil) {
        do {
            try db.collection("users").document(userId).collection("notifications").addDocument(from: notification) { error in
                completion?(error == nil)
            }
        } catch {
            print("Error adding notification: \(error)")
            completion?(false)
        }
    }
    
    // MARK: - Appointments
    
    func listenForAppointments(userId: String, role: UserRole) {
        appointmentsListener?.remove()
        
        var query: Query = db.collection("appointments")
        
        if role == .lawyer {
            query = query.whereField("lawyerId", isEqualTo: userId)
        } else {
            query = query.whereField("clientId", isEqualTo: userId)
        }
        
        appointmentsListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching appointments: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            let fetched = documents.compactMap { try? $0.data(as: FBAppointment.self) }
            // Sort by date then time
            self?.appointments = fetched.sorted { ($0.date) > ($1.date) }
        }
    }
    
    func addAppointment(_ appointment: FBAppointment, completion: ((Bool) -> Void)? = nil) {
        var normalizedAppointment = appointment
        // We no longer reset to startOfDay here because we want to preserve the specific time slot (e.g., 10:30 AM)
        // selected by the client. Isolation is handled by unique IDs and the time slot check.
        
        // Auto-fill specialty if missing
        if normalizedAppointment.lawyerSpecialty == nil {
            if let lawyer = lawyers.first(where: { $0.id == appointment.lawyerId }) {
                normalizedAppointment.lawyerSpecialty = lawyer.specialty
            }
        }
        do {
            try db.collection("appointments").addDocument(from: normalizedAppointment) { error in
                completion?(error == nil)
            }
        } catch {
            print("Error creating appointment: \(error)")
            completion?(false)
        }
    }
    
    // MARK: - consistency Helpers
    
    func updateUserImageInConversations(userId: String, imageUrl: String) {
        // Find all conversations where this user is a participant
        db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for doc in documents {
                    let convId = doc.documentID
                    self?.db.collection("conversations").document(convId).updateData([
                        "memberImages.\(userId)": imageUrl
                    ])
                }
            }
    }
    
    func updateUserImageInCases(userId: String, imageUrl: String, role: UserRole) {
        let collection = db.collection("cases")
        let fieldToMatch = (role == .lawyer) ? "lawyerId" : "clientId"
        let fieldToUpdate = (role == .lawyer) ? "lawyerImage" : "clientImage"
        
        collection.whereField(fieldToMatch, isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for doc in documents {
                    self?.db.collection("cases").document(doc.documentID).updateData([
                        fieldToUpdate: imageUrl
                    ])
                }
            }
    }

    func updateUserImageInAppointments(userId: String, imageUrl: String, role: UserRole) {
        let fieldToMatch = (role == .lawyer) ? "lawyerId" : "clientId"
        let fieldToUpdate = (role == .lawyer) ? "lawyerImage" : "clientImage"
        
        db.collection("appointments")
            .whereField(fieldToMatch, isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for doc in documents {
                    self?.db.collection("appointments").document(doc.documentID).updateData([
                        fieldToUpdate: imageUrl
                    ])
                }
            }
    }
    
    func uploadFile(data: Data, path: String, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child(path).child(fileName)
        let metadata = StorageMetadata()
        
        // Accurate MIME type detection
        let ext = fileName.lowercased()
        if ext.hasSuffix(".pdf") {
            metadata.contentType = "application/pdf"
        } else if ext.hasSuffix(".png") {
            metadata.contentType = "image/png"
        } else if ext.hasSuffix(".jpg") || ext.hasSuffix(".jpeg") {
            metadata.contentType = "image/jpeg"
        } else if ext.hasSuffix(".docx") {
            metadata.contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        } else if ext.hasSuffix(".doc") {
            metadata.contentType = "application/msword"
        } else {
            metadata.contentType = "application/octet-stream"
        }
        
        print("DEBUG: Starting upload to \(path)/\(fileName) (Type: \(metadata.contentType ?? "unknown"))")
        
        // Path safety check
        if path.contains("unknown") || path.contains("temp") {
            let error = NSError(domain: "Storage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid storage path. Case data may not be fully synchronized."])
            completion(.failure(error))
            return
        }

        storageRef.putData(data, metadata: metadata) { [weak self] _, error in
            if let error = error {
                print("CRITICAL: Upload failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("CRITICAL: Failed to get download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let downloadURL = url?.absoluteString {
                    print("DEBUG: Upload successful! URL: \(downloadURL)")
                    completion(.success(downloadURL))
                }
            }
        }
    }
    
    /// Validates daily limit (max 3) AND checks for time slot conflict.
    /// Returns a tuple: (canBook: Bool, reason: String?)
    func validateAppointmentSlot(lawyerId: String, date: Date, time: String, completion: @escaping (Bool, String?) -> Void) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            completion(true, nil)
            return
        }

        db.collection("appointments")
            .whereField("lawyerId", isEqualTo: lawyerId)
            .whereField("date", isGreaterThanOrEqualTo: start)
            .whereField("date", isLessThan: end)
            .getDocuments { snapshot, error in
                if let error = error as NSError? {
                    print("CRITICAL: Appointment validation failed: \(error.localizedDescription)")
                    
                    let errDesc = error.localizedDescription.lowercased()
                    if errDesc.contains("index") || errDesc.contains("composite") || error.code == 9 {
                        completion(false, "Database Index Missing. Please check Xcode console for the creation link.")
                    } else {
                        completion(false, "System was unable to verify availability. Please try again or check your connection.")
                    }
                    return
                }

                let documents = snapshot?.documents ?? []
                let count = documents.count
                print("DEBUG: Lawyer \(lawyerId) has \(count) appointment(s) on \(date).")

                // 1. DAILY LIMIT CHECK
                if count >= 3 {
                    completion(false, "This lawyer is fully booked for the selected date. Please choose another day.")
                    return
                }

                // 2. TIME SLOT CONFLICT CHECK
                let existingTimes = documents.compactMap { $0.data()["time"] as? String }
                let normalizedNew = time.trimmingCharacters(in: .whitespaces).uppercased()
                let hasConflict = existingTimes.contains { existing in
                    existing.trimmingCharacters(in: .whitespaces).uppercased() == normalizedNew
                }

                if hasConflict {
                    completion(false, "The \(time) slot is already booked for this day. Please choose a different time.")
                    return
                }

                // All checks passed
                completion(true, nil)
            }
    }

    /// Legacy wrapper for backwards compatibility
    func checkLawyerAvailability(lawyerId: String, date: Date, completion: @escaping (Bool) -> Void) {
        validateAppointmentSlot(lawyerId: lawyerId, date: date, time: "") { canBook, _ in
            completion(canBook)
        }
    }
}



