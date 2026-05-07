import Foundation
import SwiftUI
import FirebaseFirestore

struct FBLegalCase: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var caseNumber: String = ""
    var title: String = ""
    var clientName: String = ""
    var clientId: String = ""
    var clientImage: String? = nil
    var lawyerName: String = ""
    var lawyerId: String = ""
    var lawyerImage: String? = nil
    var type: String = "General"
    var status: String = "Pending"
    var priority: String = "Medium"
    var description: String? = nil
    var hearingDate: Date? = nil
    var hearingDates: [Date] = []
    var hearings: [FBHearingDate] = []
    var locationLat: Double? = nil
    var locationLng: Double? = nil
    var address: String? = nil
    var createdDate: Date? = nil
    var stages: [FBCaseStage] = []
    var documents: [FBDocument]? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case caseNumber, title, clientName, clientId, clientImage, lawyerName, lawyerId, lawyerImage, type, status, priority, description, hearingDate, hearingDates, hearings, locationLat, locationLng, address, createdDate, stages, documents
    }
    
    init(id: String? = nil, caseNumber: String, title: String, clientName: String, clientId: String, clientImage: String? = nil, lawyerName: String, lawyerId: String, lawyerImage: String? = nil, type: String, status: String, priority: String, description: String? = nil, hearingDate: Date? = nil, hearingDates: [Date] = [], hearings: [FBHearingDate] = [], locationLat: Double? = nil, locationLng: Double? = nil, address: String? = nil, createdDate: Date? = nil, stages: [FBCaseStage] = [], documents: [FBDocument]? = nil) {
        self._id = DocumentID(wrappedValue: id)
        self.caseNumber = caseNumber
        self.title = title
        self.clientName = clientName
        self.clientId = clientId
        self.clientImage = clientImage
        self.lawyerName = lawyerName
        self.lawyerId = lawyerId
        self.lawyerImage = lawyerImage
        self.type = type
        self.status = status
        self.priority = priority
        self.description = description
        self.hearingDate = hearingDate
        self.hearingDates = hearingDates
        self.hearings = hearings
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.address = address
        self.createdDate = createdDate
        self.stages = stages
        self.documents = documents
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(DocumentID<String>.self, forKey: .id)
        caseNumber = try container.decode(String.self, forKey: .caseNumber)
        title = try container.decode(String.self, forKey: .title)
        clientName = try container.decode(String.self, forKey: .clientName)
        clientId = try container.decode(String.self, forKey: .clientId)
        lawyerName = try container.decode(String.self, forKey: .lawyerName)
        lawyerId = try container.decode(String.self, forKey: .lawyerId)
        type = try container.decode(String.self, forKey: .type)
        status = try container.decode(String.self, forKey: .status)
        priority = try container.decode(String.self, forKey: .priority)
        description = try? container.decode(String.self, forKey: .description)
        hearingDate = try? container.decode(Date.self, forKey: .hearingDate)
        hearingDates = (try? container.decode([Date].self, forKey: .hearingDates)) ?? []
        
        // Backward compatibility
        if let hDate = hearingDate, hearingDates.isEmpty {
            hearingDates.append(hDate)
        }
        
        locationLat = try? container.decode(Double.self, forKey: .locationLat)
        locationLng = try? container.decode(Double.self, forKey: .locationLng)
        address = try? container.decode(String.self, forKey: .address)
        createdDate = try? container.decode(Date.self, forKey: .createdDate)
        stages = (try? container.decode([FBCaseStage].self, forKey: .stages)) ?? []
        documents = try? container.decode([FBDocument].self, forKey: .documents)
        
        // Flexible decoding for clientImage (String or Map)
        if let direct = try? container.decode(String.self, forKey: .clientImage) {
            clientImage = direct
        } else if let dict = try? container.decode([String: String].self, forKey: .clientImage), let url = dict["url"] {
            clientImage = url
        } else {
            clientImage = nil
        }
        
        // Flexible decoding for lawyerImage (String or Map)
        if let direct = try? container.decode(String.self, forKey: .lawyerImage) {
            lawyerImage = direct
        } else if let dict = try? container.decode([String: String].self, forKey: .lawyerImage), let url = dict["url"] {
            lawyerImage = url
        } else {
            lawyerImage = nil
        }
    }
    
    var wrappedDocuments: [FBDocument] {
        FirestoreManager.shared.caseDocuments.filter { $0.legalCaseId == id }
    }
    
    // Hashable conformance for navigation routing
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FBLegalCase, rhs: FBLegalCase) -> Bool { lhs.id == rhs.id }
    
    // Helper properties mapping what CDLegalCase did
    var completedStagesCount: Int {
        stages.filter { $0.isCompleted }.count
    }
    
    var progressProgress: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(completedStagesCount) / Double(stages.count)
    }
    
    var nextHearingDate: Date? {
        let now = Date()
        return hearingDates.filter { $0 >= now }.sorted().first ?? hearingDates.sorted().last ?? hearingDate
    }
}

struct FBCaseStage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var isCompleted: Bool
    var date: Date?
    
    static var defaultStages: [FBCaseStage] {
        [
            FBCaseStage(title: "Client Consultation", description: "Initial meeting and preliminary legal advice.", isCompleted: false),
            FBCaseStage(title: "Case Evaluation", description: "Review of facts, evidence, and legal validity.", isCompleted: false),
            FBCaseStage(title: "Agreement / Engagement", description: "Formal hiring and agreement on terms.", isCompleted: false),
            FBCaseStage(title: "Legal Research & Preparation", description: "Collection of evidence and witness details.", isCompleted: false),
            FBCaseStage(title: "Filing the Case", description: "Submission of legal documents to the court.", isCompleted: false),
            FBCaseStage(title: "Case Number & Assignment", description: "Allocation of case number and judge.", isCompleted: false),
            FBCaseStage(title: "Summons / Notice", description: "Notice sent to the opponent party.", isCompleted: false),
            FBCaseStage(title: "Opponent Response", description: "Opponent files their answer or defense.", isCompleted: false),
            FBCaseStage(title: "Preliminary Hearings", description: "Initial court sessions to set timelines.", isCompleted: false),
            FBCaseStage(title: "Interim Applications", description: "Requests for bail, injunctions, or orders.", isCompleted: false),
            FBCaseStage(title: "Evidence Submission", description: "Submission of documents and proof.", isCompleted: false),
            FBCaseStage(title: "Witness Examination", description: "Witness statements and cross-examination.", isCompleted: false),
            FBCaseStage(title: "Arguments / Trial", description: "Final arguments presented in court.", isCompleted: false),
            FBCaseStage(title: "Judgment", description: "Court issues the final verdict.", isCompleted: false),
            FBCaseStage(title: "Post-Judgment Actions", description: "Enforcement or settlement execution.", isCompleted: false),
            FBCaseStage(title: "Appeal (Optional)", description: "Opportunity to appeal to a higher court.", isCompleted: false),
            FBCaseStage(title: "Case Closure", description: "Case is officially completed and closed.", isCompleted: false)
        ]
    }
}

struct FBCaseTask: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var caseId: String
    var caseTitle: String
    var lawyerId: String
    var clientId: String
    var assigneeId: String
    var assigneeRole: String
    var title: String
    var notes: String?
    var status: String
    var priority: String
    var dueDate: Date?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case caseId, caseTitle, lawyerId, clientId, assigneeId, assigneeRole, title, notes, status, priority, dueDate, createdAt
    }
}

struct FBDocument: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var legalCaseId: String
    var fileName: String
    var fileType: String // e.g., "PDF", "JPG"
    var fileURL: String?
    var stageIndex: Int? // Optional linkage to a specific Case Lifecycle stage
    var uploadedAt: Date
    var localFileName: String?
    var fileBase64: String?
    
    enum CodingKeys: String, CodingKey {
        case legalCaseId, fileName, fileType, fileURL, stageIndex, uploadedAt, localFileName, fileBase64
    }
}

struct FBAdvisoryDocument: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var category: String
    var tags: [String]
    var lawyerName: String
    var date: String
    var fileType: String // e.g., "PDF", "DOCX", "IMAGE"
    var fileURL: String?
    var localFileName: String?
    var lawyerId: String? // To easily match which lawyer uploaded it
    var visibility: String = "Public" // "Public" or "Private"
    var fileBase64: String?
    
    enum CodingKeys: String, CodingKey {
        case title, description, category, tags, lawyerName, date, fileType, fileURL, localFileName, lawyerId, visibility, fileBase64
    }
}

struct FBConversation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var participants: [String] // Array of user UIDs
    var lastMessage: String?
    var lastMessageAt: Date?
    var memberNames: [String: String]? // [UID: Name] for easy display
    var memberImages: [String: String?]? // [UID: ImageURL?] for easy display
    var unreadCounts: [String: Int]? // [UID: Count] for unread badges
    
    enum CodingKeys: String, CodingKey {
        case id
        case participants, lastMessage, lastMessageAt, memberNames, memberImages, unreadCounts
    }
    
    init(id: String? = nil, participants: [String], lastMessage: String? = nil, lastMessageAt: Date? = nil, memberNames: [String: String]? = nil, memberImages: [String: String?]? = nil, unreadCounts: [String: Int]? = nil) {
        self._id = DocumentID(wrappedValue: id)
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.memberNames = memberNames
        self.memberImages = memberImages
        self.unreadCounts = unreadCounts
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(DocumentID<String>.self, forKey: .id)
        participants = try container.decode([String].self, forKey: .participants)
        lastMessage = try? container.decode(String.self, forKey: .lastMessage)
        lastMessageAt = try? container.decode(Date.self, forKey: .lastMessageAt)
        memberNames = try? container.decode([String: String].self, forKey: .memberNames)
        unreadCounts = try? container.decode([String: Int].self, forKey: .unreadCounts)
        
        // Flexible decoding for memberImages (String or Map within the dictionary)
        let rawImages = try? container.decode([String: AnyCodable].self, forKey: .memberImages)
        var parsedImages: [String: String?] = [:]
        
        rawImages?.forEach { key, value in
            if let stringValue = value.value as? String {
                parsedImages[key] = stringValue
            } else if let dictValue = value.value as? [String: String], let url = dictValue["url"] {
                parsedImages[key] = url
            } else {
                parsedImages[key] = nil
            }
        }
        memberImages = parsedImages
    }
    
    // Hashable conformance for navigation routing — using only ID ensures stable identity
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FBConversation, rhs: FBConversation) -> Bool { lhs.id == rhs.id }
    
    // Helper to get the other participant's info
    func partnerInfo(for currentUserId: String) -> (id: String, name: String, image: String?) {
        let partnerId = participants.first(where: { $0 != currentUserId }) ?? "Unknown"
        let name = memberNames?[partnerId] ?? "User"
        let image = memberImages?[partnerId] ?? nil
        return (partnerId, name, image)
    }
}

// Helper for dynamic decoding in dictionaries
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) { self.value = value }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) { value = stringValue }
        else if let dictValue = try? container.decode([String: String].self) { value = dictValue }
        else { value = "" }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let stringValue = value as? String { try container.encode(stringValue) }
        else if let dictValue = value as? [String: String] { try container.encode(dictValue) }
    }
}

struct FBMessage: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var senderId: String
    var text: String
    var ciphertext: String?
    var senderPublicKey: String?
    var isEncrypted: Bool?
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case senderId, text, ciphertext, senderPublicKey, isEncrypted, timestamp
    }
}

struct FBNotification: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String = "Notification"
    var body: String = ""
    var type: String = "system" // e.g., "message", "case", "booking", "appointment"
    var timestamp: Date = Date()
    var isRead: Bool = false
    var relatedId: String? = nil // e.g., conversationId or caseId or appointmentId
    
    var iconName: String {
        switch type {
        case "message": return "message.fill"
        case "case": return "doc.text.fill"
        case "booking", "appointment": return "calendar"
        case "document": return "doc.on.doc.fill"
        case "payment": return "creditcard.fill"
        default: return "bell.fill"
        }
    }
    
    var dynamicColor: Color {
        switch type {
        case "message": return .lmPrimary
        case "case": return .blue
        case "booking", "appointment": return .orange
        case "document": return .purple
        case "payment": return .green
        default: return .lmPrimary
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case title, body, type, timestamp, isRead, relatedId
    }
    
    init(id: String? = nil, title: String, body: String, type: String, timestamp: Date, isRead: Bool = false, relatedId: String? = nil) {
        self._id = DocumentID(wrappedValue: id)
        self.title = title
        self.body = body
        self.type = type
        self.timestamp = timestamp
        self.isRead = isRead
        self.relatedId = relatedId
    }
    
}

struct FBAppointment: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var clientId: String
    var clientName: String
    var clientImage: String?
    var lawyerId: String
    var lawyerName: String
    var lawyerImage: String?
    var lawyerSpecialty: String?
    var service: String
    var date: Date
    var time: String
    var method: String
    var description: String
    var status: String
    var lastActionBy: String?
    var locationLat: Double?
    var locationLng: Double?
    
    var statusTitle: String { 
        if isOverdue { return "Overdue" }
        return status 
    }
    
    var statusColor: Color {
        if isOverdue { return .red }
        switch status.lowercased() {
        case "confirmed": return .green
        case "pending": return .orange
        case "rescheduled": return .blue
        case "cancelled", "rejected": return .red
        case "in progress": return .blue
        case "done": return .gray
        default: return .gray
        }
    }
    
    var isOverdue: Bool {
        guard let start = startTime else { return false }
        let terminalStatuses = ["done", "cancelled", "rejected"]
        return start < Date() && !terminalStatuses.contains(status.lowercased())
    }
    
    var startTime: Date? {
        // Parse "02:00 PM - 03:00 PM" or similar
        let timePart = time.components(separatedBy: " - ").first ?? time
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let timeDate = formatter.date(from: timePart) else { return nil }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                           minute: timeComponents.minute ?? 0,
                           second: 0,
                           of: date)
    }
    
    var specialtyIcon: String {
        guard let spec = lawyerSpecialty?.lowercased() else { return "briefcase.fill" }
        if spec.contains("family") { return "house.fill" }
        if spec.contains("criminal") { return "building.columns.fill" }
        if spec.contains("civil") { return "person.2.fill" }
        if spec.contains("business") || spec.contains("corporate") { return "briefcase.fill" }
        return "briefcase.fill"
    }
    
    enum CodingKeys: String, CodingKey {
        case clientId, clientName, clientImage, lawyerId, lawyerName, lawyerImage, lawyerSpecialty, service, date, time, method, description, status, lastActionBy, locationLat, locationLng
    }
    
    init(id: String? = nil, clientId: String, clientName: String, clientImage: String? = nil, lawyerId: String, lawyerName: String, lawyerImage: String? = nil, lawyerSpecialty: String? = nil, service: String, date: Date, time: String, method: String, description: String, status: String, lastActionBy: String? = nil, locationLat: Double? = nil, locationLng: Double? = nil) {
        self._id = DocumentID(wrappedValue: id)
        self.clientId = clientId
        self.clientName = clientName
        self.clientImage = clientImage
        self.lawyerId = lawyerId
        self.lawyerName = lawyerName
        self.lawyerImage = lawyerImage
        self.lawyerSpecialty = lawyerSpecialty
        self.service = service
        self.date = date
        self.time = time
        self.method = method
        self.description = description
        self.status = status
        self.lastActionBy = lastActionBy
        self.locationLat = locationLat
        self.locationLng = locationLng
    }
}



struct FBReview: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var lawyerId: String
    var clientId: String
    var clientName: String
    var clientImage: String?
    var rating: Int
    var reviewText: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case lawyerId, clientId, clientName, clientImage, rating, reviewText, timestamp
    }
}

struct FBReferral: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var requesterId: String
    var requesterName: String
    var targetLawyerId: String
    var targetLawyerName: String
    var status: String
    var note: String?
    var recommendedLawyerId: String?
    var recommendedLawyerName: String?
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case requesterId, requesterName, targetLawyerId, targetLawyerName, status, note, recommendedLawyerId, recommendedLawyerName, timestamp
    }
}

struct FBHearingDate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var location: String
    var notes: String
}
