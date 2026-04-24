import Foundation
import FirebaseFirestore
import FirebaseStorage

class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()

    private let appointmentSlotMinutes: Int = 60
    private let appointmentTimeFormat = "hh:mm a"
    private let appointmentValidationDomain = "AppointmentValidation"
    
    @Published var cases: [FBLegalCase] = []
    @Published var lawyers: [User] = []
    @Published var clients: [User] = []
    @Published var conversations: [FBConversation] = []
    @Published var messages: [FBMessage] = []
    @Published var totalUnreadCount: Int = 0
    @Published var unreadNotificationsCount: Int = 0
    @Published var unreadChatCount: Int = 0
    @Published var notifications: [FBNotification] = []
    @Published var appointments: [FBAppointment] = []
    @Published var advisoryDocuments: [FBAdvisoryDocument] = []
    
    private var casesListener: ListenerRegistration?
    private var lawyersListener: ListenerRegistration?
    private var clientsListener: ListenerRegistration?
    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private var notificationsListener: ListenerRegistration?
    private var appointmentsListener: ListenerRegistration?
    private var advisoryDocumentsListener: ListenerRegistration?
    private var lastKnownMessageDate: Date? = Date()
    private var lastKnownNotificationDate: Date? = Date()
    /// IDs of conversations deleted locally — prevents the snapshot listener from re-adding them
    private var deletedConversationIds: Set<String> = []
    
    // MARK: - Lawyers
    
    func listenForLawyers() {
        lawyersListener = db.collection("users")
            .whereField("role", isEqualTo: "Lawyer")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching lawyers: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                let fetched = documents.compactMap { try? $0.data(as: User.self) }
                DispatchQueue.main.async {
                    self?.lawyers = fetched
                }
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
                let fetched = documents.compactMap { try? $0.data(as: User.self) }
                DispatchQueue.main.async {
                    self?.clients = fetched
                }
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
            
            DispatchQueue.main.async {
                // Sort manually in Swift to avoid index requirements and missing field exclusions
                self?.cases = fetchedCases.sorted { ($0.createdDate ?? Date.distantPast) > ($1.createdDate ?? Date.distantPast) }
            }
        }
    }
    
    func stopListening() {
        casesListener?.remove()
        lawyersListener?.remove()
        clientsListener?.remove()
        conversationsListener?.remove()
        messagesListener?.remove()
        notificationsListener?.remove()
        appointmentsListener?.remove()
        advisoryDocumentsListener?.remove()
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
        listenForAdvisoryDocuments()
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
            
            // Notify other party (if case is found)
            if let legalCase = cases.first(where: { $0.id == caseId }) {
                let currentUserId = AuthService.shared.currentUser?.id ?? ""
                let recipientId = currentUserId == legalCase.lawyerId ? legalCase.clientId : legalCase.lawyerId
                
                let notification = FBNotification(
                    title: "New Document Added",
                    body: "A new document '\(fileName)' has been uploaded to case \(legalCase.title).",
                    type: "case",
                    timestamp: Date(),
                    relatedId: caseId
                )
                addNotification(notification, toUserId: recipientId)
            }
        } catch {
            print("Error uploading document: \(error)")
        }
    }
    
    func fetchDocuments(forCaseId caseId: String, completion: @escaping ([FBDocument]) -> Void) {
        db.collection("documents")
            .whereField("legalCaseId", isEqualTo: caseId)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else {
                    print("Error fetching docs: \(error?.localizedDescription ?? "unknown")")
                    completion([])
                    return
                }
                
                let documents = docs.compactMap { try? $0.data(as: FBDocument.self) }
                // Sort by uploadedAt descending in memory to avoid index requirements
                let sortedDocs = documents.sorted { ($0.uploadedAt) > ($1.uploadedAt) }
                completion(sortedDocs)
            }
    }
    
    // MARK: - Advisory Documents
    
    func listenForAdvisoryDocuments() {
        advisoryDocumentsListener?.remove()
        
        advisoryDocumentsListener = db.collection("advisoryDocuments")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching advisory documents: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                let fetchedDocs = documents.compactMap { try? $0.data(as: FBAdvisoryDocument.self) }
                // Sort newest first
                self?.advisoryDocuments = fetchedDocs.sorted { 
                    // Using ID as a rough sort since date is a string, or parse the date string
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM dd, yyyy"
                    let date0 = dateFormatter.date(from: $0.date) ?? Date.distantPast
                    let date1 = dateFormatter.date(from: $1.date) ?? Date.distantPast
                    return date0 > date1
                }
            }
    }
    
    func uploadAdvisoryDocument(title: String, category: String, description: String, tags: [String], visibility: String, lawyerName: String, lawyerId: String, tempURL: URL, completion: @escaping (Bool, String?) -> Void) {
        let fileExtension = tempURL.pathExtension
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let storagePath = "cases/advisory_documents"
        
        do {
            let data = try Data(contentsOf: tempURL)
            uploadFile(data: data, path: storagePath, fileName: fileName) { [weak self] result in
                switch result {
                case .success(let downloadURL):
                    let newDoc = FBAdvisoryDocument(
                        title: title,
                        description: description,
                        category: category,
                        tags: tags,
                        lawyerName: lawyerName,
                        date: self?.formatDate(Date()) ?? "",
                        fileType: fileExtension.uppercased(),
                        fileURL: downloadURL,
                        lawyerId: lawyerId,
                        visibility: visibility
                    )
                    
                    do {
                        let _ = try self?.db.collection("advisoryDocuments").addDocument(from: newDoc)
                        completion(true, nil)
                    } catch {
                        print("Error saving advisory document metadata: \(error)")
                        completion(false, error.localizedDescription)
                    }
                    
                case .failure(let error):
                    print("Error uploading advisory document file: \(error)")
                    completion(false, error.localizedDescription)
                }
            }
        } catch {
            print("Failed to read tempURL data: \(error)")
            completion(false, error.localizedDescription)
        }
    }
    
    func deleteAdvisoryDocument(id: String) {
        db.collection("advisoryDocuments").document(id).delete() { error in
            if let error = error {
                print("Error removing advisory document: \(error)")
            }
        }
    }
    
    func updateAdvisoryDocumentVisibility(id: String, visibility: String) {
        db.collection("advisoryDocuments").document(id).updateData([
            "visibility": visibility
        ]) { error in
            if let error = error {
                print("Error updating advisory document visibility: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Messaging
    
    func listenForConversations(userId: String) {
        conversationsListener?.remove()
        
        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                let loadedConversations = documents.compactMap { try? $0.data(as: FBConversation.self) }
                // Filter out locally-deleted conversations so they never re-appear
                let filtered = loadedConversations.filter { conv in
                    guard let id = conv.id else { return true }
                    return !self.deletedConversationIds.contains(id)
                }
                DispatchQueue.main.async {
                    self.conversations = filtered.sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }

                    // Calculate total unread (messages + notifications)
                    self.updateTotalUnreadCount()

                    self.lastKnownMessageDate = Date()
                }
            }
    }
    
    func listenForMessages(conversationId: String) {
        messagesListener?.remove()
        DispatchQueue.main.async { [weak self] in
            self?.messages = []
        }
        
        messagesListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                let loadedMessages = documents.compactMap { try? $0.data(as: FBMessage.self) }
                DispatchQueue.main.async {
                    self.messages = loadedMessages
                }
            }
    }

    func stopListeningForMessages() {
        messagesListener?.remove()
        messagesListener = nil
        DispatchQueue.main.async { [weak self] in
            self?.messages = []
        }
    }
    
    func sendMessage(to conversationId: String, text: String, senderId: String) {
        let newMessage = FBMessage(senderId: senderId, text: text, timestamp: Date())
        
        // Find recipient ID from loaded conversations
        let conversation = conversations.first(where: { $0.id == conversationId })
        let recipientId = conversation?.participants.first(where: { $0 != senderId })
        let senderName = AuthService.shared.currentUser?.fullName ?? "Someone"
        
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
            
            db.collection("conversations").document(conversationId).updateData(updateData) { error in
                if let error = error {
                    print("Error updating conversation: \(error)")
                }
            }
            
            // Send a persistent in-app notification to the recipient
            if let recipientId = recipientId {
                let notification = FBNotification(
                    title: "New Message from \(senderName)",
                    body: text.count > 60 ? String(text.prefix(60)) + "…" : text,
                    type: "message",
                    timestamp: Date(),
                    relatedId: conversationId
                )
                addNotification(notification, toUserId: recipientId)
            }
        } catch {
            print("Error sending message: \(error)")
            DispatchQueue.main.async {
                ToastManager.shared.show(title: "Send Failed", message: "Could not send your message. Please try again.", type: .error)
            }
        }
    }
    
    func getOrCreateConversation(between user1: String, and user2: String, partnerInfo: (name: String, image: String?), currentUser: User, completion: @escaping (String) -> Void) {
        // Firestore does not support isEqualTo on arrays.
        // Use arrayContains on one participant, then filter client-side for the second.
        let sortedParticipants = [user1, user2].sorted()
        
        db.collection("conversations")
            .whereField("participants", arrayContains: user1)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error)")
                }
                
                // Client-side: find conversation that has exactly both participants
                let existing = snapshot?.documents.first { doc in
                    let participants = (doc.data()["participants"] as? [String] ?? []).sorted()
                    return participants == sortedParticipants
                }
                
                if let existing = existing {
                    let existingId = existing.documentID
                    guard !existingId.isEmpty else {
                        DispatchQueue.main.async {
                            ToastManager.shared.show(title: "Chat Error", message: "Conversation is missing an ID. Please try again.", type: .error)
                        }
                        return
                    }
                    DispatchQueue.main.async { completion(existingId) }
                } else {
                    // Build correct names/images map
                    var memberNames: [String: String] = [:]
                    var memberImages: [String: String?] = [:]
                    let unreadCounts = [user1: 0, user2: 0]
                    let partnerId = currentUser.id == user1 ? user2 : user1
                    
                    memberNames[currentUser.id] = currentUser.fullName
                    memberImages[currentUser.id] = currentUser.profileImage
                    memberNames[partnerId] = partnerInfo.name
                    memberImages[partnerId] = partnerInfo.image
                    
                    let newConversation = FBConversation(
                        participants: sortedParticipants,
                        lastMessage: nil,
                        lastMessageAt: Date(),
                        memberNames: memberNames,
                        memberImages: memberImages,
                        unreadCounts: unreadCounts
                    )
                    
                    do {
                        let ref = try self?.db.collection("conversations").addDocument(from: newConversation)
                        let newId = ref?.documentID ?? ""
                        guard !newId.isEmpty else {
                            DispatchQueue.main.async {
                                ToastManager.shared.show(title: "Chat Error", message: "Unable to create the conversation. Please try again.", type: .error)
                            }
                            return
                        }
                        DispatchQueue.main.async { completion(newId) }
                    } catch {
                        print("Error creating conversation: \(error)")
                        DispatchQueue.main.async {
                            ToastManager.shared.show(title: "Chat Error", message: "Unable to create the conversation. Please try again.", type: .error)
                        }
                    }
                }
            }
    }
    
    func markConversationAsRead(id: String, userId: String) {
        db.collection("conversations").document(id).updateData([
            "unreadCounts.\(userId)": 0
        ])
    }
    
    func deleteConversation(id: String, completion: ((Bool) -> Void)? = nil) {
        print("DEBUG: deleteConversation called for id=\(id)")
        // 1. Add to tombstone set FIRST — listener will filter it out immediately
        deletedConversationIds.insert(id)
        // 2. Remove from local array right now
        conversations.removeAll { $0.id == id }
        
        let messagesRef = db.collection("conversations").document(id).collection("messages")
        messagesRef.getDocuments { [weak self] snapshot, error in
            guard let self else { completion?(false); return }
            
            if let error = error {
                print("DEBUG: Failed to fetch messages for deletion: \(error.localizedDescription)")
            }
            
            let batch = self.db.batch()
            let msgDocs = snapshot?.documents ?? []
            print("DEBUG: Deleting \(msgDocs.count) message(s) in conversation \(id)")
            msgDocs.forEach { batch.deleteDocument($0.reference) }
            batch.deleteDocument(self.db.collection("conversations").document(id))
            
            batch.commit { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("DEBUG: Batch delete failed: \(error.localizedDescription)")
                        // Rollback — remove from tombstone so conversation reappears
                        self?.deletedConversationIds.remove(id)
                        completion?(false)
                    } else {
                        print("DEBUG: Conversation \(id) deleted successfully")
                        // Keep ID in tombstone — it's gone from Firestore anyway
                        completion?(true)
                    }
                }
            }
        }
    }
    
    private func updateTotalUnreadCount() {
        let currentUserId = AuthService.shared.currentUser?.id ?? ""
        let chatUnread = conversations.reduce(0) { total, conv in
            total + (conv.unreadCounts?[currentUserId] ?? 0)
        }
        self.unreadChatCount = chatUnread
        self.totalUnreadCount = chatUnread + unreadNotificationsCount
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
                let fetched = documents.compactMap { try? $0.data(as: FBNotification.self) }
                
                DispatchQueue.main.async {
                    // Trigger local notifications for new unread notifications
                    if let lastDate = self?.lastKnownNotificationDate {
                        for notification in fetched {
                            if !notification.isRead && notification.timestamp > lastDate {
                                NotificationManager.shared.scheduleNotification(
                                    title: notification.title,
                                    body: notification.body,
                                    relatedId: notification.relatedId,
                                    type: notification.type
                                )
                            }
                        }
                    }
                    
                    self?.notifications = fetched
                    // EXCLUDE chat messages from the Notification UI count (they have their own tab badge)
                    self?.unreadNotificationsCount = fetched.filter { !$0.isRead && $0.type != "message" }.count
                    self?.updateTotalUnreadCount()
                    self?.lastKnownNotificationDate = fetched.first?.timestamp ?? Date()
                }
            }
    }
    
    func markNotificationsAsRead(userId: String) {
        let batch = db.batch()
        let unread = notifications.filter { !$0.isRead }
        
        for notification in unread {
            if let id = notification.id {
                let ref = db.collection("users").document(userId).collection("notifications").document(id)
                batch.updateData(["isRead": true], forDocument: ref)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error marking notifications as read: \(error)")
            }
        }
    }
    
    func clearAllNotifications(userId: String) {
        let batch = db.batch()
        for notification in notifications {
            if let id = notification.id {
                let ref = db.collection("users").document(userId).collection("notifications").document(id)
                batch.deleteDocument(ref)
            }
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error clearing notifications: \(error)")
            } else {
                print("DEBUG: All notifications cleared for user \(userId)")
                DispatchQueue.main.async {
                    self?.notifications = []
                    self?.unreadNotificationsCount = 0
                    self?.updateTotalUnreadCount()
                }
            }
        }
    }
    
    func markNotificationAsRead(userId: String, notificationId: String) {
        db.collection("users").document(userId).collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
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

    func combineDateAndTime(day: Date, timeString: String) -> Date? {
        let trimmed = timeString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return day }
        
        // Robustness: Handle both 02:30 and 02.30 formats
        let normalizedTime = trimmed.replacingOccurrences(of: ".", with: ":")
        
        let formatter = DateFormatter()
        formatter.dateFormat = appointmentTimeFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let timeDate = formatter.date(from: normalizedTime) else { 
            print("DEBUG: Failed to parse time string: \(normalizedTime)")
            return nil 
        }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components)
    }

    private func appointmentStartDate(date: Date, timeString: String?) -> Date? {
        // CRITICAL: If a time string is provided, it MUST take precedence over 
        // any time component currently in the date object (e.g. current system time).
        if let timeString = timeString, !timeString.isEmpty {
            return combineDateAndTime(day: date, timeString: timeString)
        }
        
        return date
    }

    private func overlaps(start: Date, end: Date, otherStart: Date, otherEnd: Date) -> Bool {
        return start < otherEnd && otherStart < end
    }

    private func validationError(_ message: String, code: Int) -> NSError {
        NSError(domain: appointmentValidationDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
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
            DispatchQueue.main.async {
                self?.appointments = fetched.sorted { ($0.date) > ($1.date) }
            }
        }
    }
    
    func addAppointment(_ appointment: FBAppointment, completion: ((Bool) -> Void)? = nil) {
        createAppointmentWithValidation(appointment) { success, _ in
            completion?(success)
        }
    }

    func createAppointmentWithValidation(_ appointment: FBAppointment, completion: @escaping (Bool, String?) -> Void) {
        var normalizedAppointment = appointment

        if let combined = combineDateAndTime(day: appointment.date, timeString: appointment.time) {
            normalizedAppointment.date = combined
        } else if !appointment.time.trimmingCharacters(in: .whitespaces).isEmpty {
            completion(false, "Invalid time slot. Please select a valid time.")
            return
        }

        if normalizedAppointment.lawyerSpecialty == nil {
            if let lawyer = lawyers.first(where: { $0.id == appointment.lawyerId }) {
                normalizedAppointment.lawyerSpecialty = lawyer.specialty
            }
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: normalizedAppointment.date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            completion(false, "System was unable to verify availability. Please try again.")
            return
        }

        let query = db.collection("appointments")
            .whereField("lawyerId", isEqualTo: normalizedAppointment.lawyerId)

        query.getDocuments { [weak self] snapshot, error in
            guard let self else {
                completion(false, "System was unable to verify availability. Please try again.")
                return
            }

            if let error = error as NSError? {
                let errDesc = error.localizedDescription.lowercased()
                if errDesc.contains("index") || errDesc.contains("composite") || error.code == 9 {
                    completion(false, "Database Index Missing. Please check Xcode console for the creation link.")
                } else {
                    completion(false, "System was unable to verify availability. Please try again or check your connection.")
                }
                return
            }

            // Filter by date range in memory to avoid composite index requirements
            let filteredDocuments = snapshot?.documents.filter { doc in
                guard let timestamp = doc.get("date") as? Timestamp else { return false }
                let dateValue = timestamp.dateValue()
                return dateValue >= start && dateValue < end
            } ?? []

            let docRefs = filteredDocuments.map { $0.reference }

            self.db.runTransaction({ transaction, errorPointer in
                do {
                    var documents: [DocumentSnapshot] = []
                    documents.reserveCapacity(docRefs.count)
                    for ref in docRefs {
                        let doc = try transaction.getDocument(ref)
                        if doc.exists {
                            documents.append(doc)
                        }
                    }

                    if documents.count >= 3 {
                        errorPointer?.pointee = self.validationError("This lawyer is fully booked for the selected date. Please choose another day.", code: 1001)
                        return nil
                    }

                    guard let newStart = self.appointmentStartDate(date: normalizedAppointment.date, timeString: normalizedAppointment.time) else {
                        errorPointer?.pointee = self.validationError("Invalid time slot. Please select a valid time.", code: 1002)
                        return nil
                    }
                    let newEnd = newStart.addingTimeInterval(TimeInterval(self.appointmentSlotMinutes * 60))

                    for doc in documents {
                        let data = doc.data() ?? [:]
                        let time = data["time"] as? String
                        let dateValue = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        guard let existingStart = self.appointmentStartDate(date: dateValue, timeString: time) else { continue }
                        let existingEnd = existingStart.addingTimeInterval(TimeInterval(self.appointmentSlotMinutes * 60))
                        if self.overlaps(start: newStart, end: newEnd, otherStart: existingStart, otherEnd: existingEnd) {
                            errorPointer?.pointee = self.validationError("The selected time overlaps with another appointment. Please choose a different time.", code: 1003)
                            return nil
                        }
                    }

                    let ref = self.db.collection("appointments").document()
                    try transaction.setData(from: normalizedAppointment, forDocument: ref)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }) { _, error in
                if let error = error as NSError? {
                    if error.domain == self.appointmentValidationDomain {
                        completion(false, error.localizedDescription)
                        return
                    }

                    let errDesc = error.localizedDescription.lowercased()
                    if errDesc.contains("index") || errDesc.contains("composite") || error.code == 9 {
                        completion(false, "Database Index Missing. Please check Xcode console for the creation link.")
                    } else {
                        completion(false, "System was unable to verify availability. Please try again or check your connection.")
                    }
                    return
                }

                completion(true, nil)
            }
        }
    }

    func updateAppointmentSchedule(appointmentId: String, newDate: Date, newTime: String, completion: @escaping (Bool, String?) -> Void) {
        let docRef = db.collection("appointments").document(appointmentId)
        let calendar = Calendar.current

        guard let combinedDate = combineDateAndTime(day: newDate, timeString: newTime) else {
            completion(false, "Invalid time slot. Please select a valid time.")
            return
        }

        let start = calendar.startOfDay(for: combinedDate)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            completion(false, "System was unable to verify availability. Please try again.")
            return
        }

        docRef.getDocument { [weak self] snapshot, error in
            guard let self else {
                completion(false, "System was unable to verify availability. Please try again.")
                return
            }

            if let error = error as NSError? {
                let errDesc = error.localizedDescription.lowercased()
                if errDesc.contains("index") || errDesc.contains("composite") || error.code == 9 {
                    completion(false, "Database Index Missing. Please check Xcode console for the creation link.")
                } else {
                    completion(false, "System was unable to verify availability. Please try again or check your connection.")
                }
                return
            }

            guard let data = snapshot?.data(), let lawyerId = data["lawyerId"] as? String else {
                completion(false, "Appointment not found.")
                return
            }

            let query = self.db.collection("appointments")
                .whereField("lawyerId", isEqualTo: lawyerId)

            query.getDocuments { [weak self] snapshot, error in
                guard let self else {
                    completion(false, "System was unable to verify availability. Please try again.")
                    return
                }

                if let error = error as NSError? {
                    let errDesc = error.localizedDescription.lowercased()
                    if errDesc.contains("index") || errDesc.contains("composite") || error.code == 9 {
                        completion(false, "Database Index Missing. Please check Xcode console for the creation link.")
                    } else {
                        completion(false, "System was unable to verify availability. Please try again or check your connection.")
                    }
                    return
                }

                // Filter by date range in memory to avoid composite index requirements
                let filteredDocuments = snapshot?.documents.filter { doc in
                    guard let timestamp = doc.get("date") as? Timestamp else { return false }
                    let dateValue = timestamp.dateValue()
                    return dateValue >= start && dateValue < end
                } ?? []

                let docRefs = filteredDocuments.map { $0.reference }

                self.db.runTransaction({ transaction, errorPointer in
                do {
                    let existingSnapshot = try transaction.getDocument(docRef)
                    var existing = try existingSnapshot.data(as: FBAppointment.self)

                    existing.date = combinedDate
                    existing.time = newTime

                    var documents: [DocumentSnapshot] = []
                    documents.reserveCapacity(docRefs.count)
                    for ref in docRefs {
                        if ref.documentID == appointmentId { continue }
                        let doc = try transaction.getDocument(ref)
                        if doc.exists {
                            documents.append(doc)
                        }
                    }

                    if documents.count >= 3 {
                        errorPointer?.pointee = self.validationError("This lawyer is fully booked for the selected date. Please choose another day.", code: 1001)
                        return nil
                    }

                    let newStart = combinedDate
                    let newEnd = newStart.addingTimeInterval(TimeInterval(self.appointmentSlotMinutes * 60))

                    for doc in documents {
                        let data = doc.data() ?? [:]
                        let time = data["time"] as? String
                        let dateValue = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        guard let existingStart = self.appointmentStartDate(date: dateValue, timeString: time) else { continue }
                        let existingEnd = existingStart.addingTimeInterval(TimeInterval(self.appointmentSlotMinutes * 60))
                        if self.overlaps(start: newStart, end: newEnd, otherStart: existingStart, otherEnd: existingEnd) {
                            errorPointer?.pointee = self.validationError("The selected time overlaps with another appointment. Please choose a different time.", code: 1003)
                            return nil
                        }
                    }

                    try transaction.setData(from: existing, forDocument: docRef)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                }) { _, error in
                if let error = error as NSError? {
                    if error.domain == self.appointmentValidationDomain {
                        completion(false, error.localizedDescription)
                        return
                    }

                    let errDesc = error.localizedDescription.lowercased()
                    if errDesc.contains("index") || errDesc.contains("composite") || error.code == 9 {
                        completion(false, "Database Index Missing. Please check Xcode console for the creation link.")
                    } else {
                        completion(false, "System was unable to verify availability. Please try again or check your connection.")
                    }
                    return
                }

                completion(true, nil)
                
                // Notify other party
                if let appointment = self.appointments.first(where: { $0.id == appointmentId }) {
                    let currentUserId = AuthService.shared.currentUser?.id ?? ""
                    let recipientId = currentUserId == appointment.lawyerId ? appointment.clientId : appointment.lawyerId
                    
                    let notification = FBNotification(
                        title: "Appointment Rescheduled",
                        body: "An appointment has been moved to \(newTime) on \({ let f = DateFormatter(); f.dateFormat = "MMM dd, yyyy"; return f.string(from: newDate) }()).",
                        type: "appointment",
                        timestamp: Date(),
                        relatedId: appointmentId
                    )
                    self.addNotification(notification, toUserId: recipientId)
                }
                }
            }
        }
    }

    func deleteAppointment(id: String, completion: ((Bool) -> Void)? = nil) {
        db.collection("appointments").document(id).delete { error in
            completion?(error == nil)
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
        
        // CRITICAL: Path Validation to prevent security rule violations
        // Rules require: /cases/{id}/docs/{file} OR /cases/advisory_documents/{file}
        let normalizedPath = path.lowercased()
        if !normalizedPath.contains("/docs") && !normalizedPath.contains("advisory_documents") {
            let error = NSError(domain: "Storage", code: 403, userInfo: [NSLocalizedDescriptionKey: "Security Violation: Upload path '\(path)' is not authorized. Must include '/docs' subfolder."])
            print("CRITICAL SECURITY ERROR: Rejected upload to \(path)/\(fileName)")
            completion(.failure(error))
            return
        }
        
        if normalizedPath.contains("unknown") || normalizedPath.contains("temp") {
            let error = NSError(domain: "Storage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Case ID: The case ID is not yet synchronized. Please wait a moment."])
            print("DEBUG: Rejected upload due to unsynced ID in path: \(path)")
            completion(.failure(error))
            return
        }

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
        
        storageRef.putData(data, metadata: metadata) { [weak self] _, error in
            if let error = error {
                print("CRITICAL: Storage PutData failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Success - Get download URL with small delay to handle eventual consistency
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("CRITICAL: Failed to get download URL for \(path)/\(fileName): \(error.localizedDescription)")
                        // One-time retry
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            storageRef.downloadURL { url, error in
                                if let error = error {
                                    completion(.failure(error))
                                } else if let downloadURL = url?.absoluteString {
                                    completion(.success(downloadURL))
                                }
                            }
                        }
                    } else if let downloadURL = url?.absoluteString {
                        print("DEBUG: Upload successful! URL: \(downloadURL)")
                        completion(.success(downloadURL))
                    }
                }
            }
        }
    }

    
    /// Validates daily limit (max 3) AND checks for time slot conflict.
    /// Returns a tuple: (canBook: Bool, reason: String?)
    func validateAppointmentSlot(lawyerId: String, date: Date, time: String, excludingAppointmentId: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            completion(true, nil)
            return
        }

        db.collection("appointments")
            .whereField("lawyerId", isEqualTo: lawyerId)
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

                // Filter by date range in memory to avoid composite index requirements
                let filteredDocuments = (snapshot?.documents ?? []).filter { doc in
                    guard let timestamp = doc.get("date") as? Timestamp else { return false }
                    let dateValue = timestamp.dateValue()
                    return dateValue >= start && dateValue < end
                }

                let documents = filteredDocuments.filter { $0.documentID != excludingAppointmentId }
                let count = documents.count
                print("DEBUG: Lawyer \(lawyerId) has \(count) appointment(s) on \(date).")

                // 1. DAILY LIMIT CHECK
                if count >= 3 {
                    completion(false, "This lawyer is fully booked for the selected date. Please choose another day.")
                    return
                }

                // 2. TIME SLOT CONFLICT CHECK
                let trimmedTime = time.trimmingCharacters(in: .whitespaces)
                if !trimmedTime.isEmpty {
                    guard let newStart = self.appointmentStartDate(date: date, timeString: trimmedTime) else {
                        completion(false, "Invalid time slot. Please select a valid time.")
                        return
                    }
                    let newEnd = newStart.addingTimeInterval(TimeInterval(self.appointmentSlotMinutes * 60))

                    for doc in documents {
                        let data = doc.data()
                        let existingTime = data["time"] as? String
                        let dateValue = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        guard let existingStart = self.appointmentStartDate(date: dateValue, timeString: existingTime) else { continue }
                        let existingEnd = existingStart.addingTimeInterval(TimeInterval(self.appointmentSlotMinutes * 60))
                        if self.overlaps(start: newStart, end: newEnd, otherStart: existingStart, otherEnd: existingEnd) {
                            completion(false, "The selected time overlaps with another appointment. Please choose a different time.")
                            return
                        }
                    }
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



