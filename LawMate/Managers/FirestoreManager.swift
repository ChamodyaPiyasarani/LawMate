import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    @Published var cases: [FBLegalCase] = []
    @Published var lawyers: [User] = []
    
    private var casesListener: ListenerRegistration?
    private var lawyersListener: ListenerRegistration?
    
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
    
    func listenForCases(role: UserRole, userFullName: String) {
        // Query cases where user is either client or lawyer depending on role
        var query: Query = db.collection("cases")
        
        switch role {
        case .lawyer:
            query = query.whereField("lawyerName", isEqualTo: userFullName)
        case .client:
            query = query.whereField("clientName", isEqualTo: userFullName)
        default:
            return
        }
        
        casesListener = query.order(by: "createdDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching cases: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                self?.cases = documents.compactMap { doc -> FBLegalCase? in
                    try? doc.data(as: FBLegalCase.self)
                }
            }
    }
    
    func stopListening() {
        casesListener?.remove()
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
}
