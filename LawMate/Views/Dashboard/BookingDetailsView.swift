import SwiftUI

// MARK: - Booking Model
struct Booking: Identifiable, Hashable {
    let id: String
    let lawyerName: String
    let date: String
    let time: String
    let category: String
    let method: String
    let status: BookingStatus
    
    // Conform to Hashable for navigation
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Booking, rhs: Booking) -> Bool { lhs.id == rhs.id }
}

enum BookingStatus {
    case confirmed, pending, inProgress, done
    
    var title: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        }
    }
    
    var color: Color {
        switch self {
        case .confirmed: return .green
        case .pending: return .red
        case .inProgress: return .orange
        case .done: return .gray
        }
    }
}

// MARK: - Booking Details View
struct BookingDetailsView: View {
    var onBack: () -> Void = {}
    
    @State private var searchQuery = ""
    @State private var selectedFilter = "Confirmed"
    @State private var showBookingView = false
    
    private let filters = ["Confirmed", "Pending", "In progress", "Done"]
    private let bookings = [
        Booking(id: "B1", lawyerName: "Nimal Perera", date: "Apr 15, 2026", time: "10:00 AM - 11:00 AM", category: "Criminal Law", method: "In Person", status: .confirmed),
        Booking(id: "B2", lawyerName: "Sanduni Fernando", date: "Apr 30, 2026", time: "02:00 PM - 03:00 PM", category: "Family Law", method: "Video Call", status: .pending),
        Booking(id: "B3", lawyerName: "Sanduni Fernando", date: "Apr 30, 2026", time: "02:00 PM - 03:00 PM", category: "Family Law", method: "Video Call", status: .inProgress)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob background style — fits client home
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header (Left-Aligned)
                HStack {
                    Text("Booking Details")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    // MARK: + Add Button (Standardized as Circle)
                    Button {
                        showBookingView = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .zIndex(10)
                
                // MARK: Fixed Search Bar (Standardized with Lawyers List)
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.lmTextSecondary)
                    TextField("Search", text: $searchQuery)
                        .font(.lmField)
                }
                .padding()
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.top, 10) // Match Lawyers List
                
                // MARK: Fixed Filter Chips (Standardized with Lawyers List)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(icon: "checkmark.circle.fill", title: "Confirmed", isActive: selectedFilter == "Confirmed") { selectedFilter = "Confirmed" }
                        FilterPill(icon: "clock.fill", title: "Pending", isActive: selectedFilter == "Pending") { selectedFilter = "Pending" }
                        FilterPill(icon: "arrow.triangle.2.circlepath", title: "In progress", isActive: selectedFilter == "In progress") { selectedFilter = "In progress" }
                        FilterPill(icon: "checkmark.seal.fill", title: "Done", isActive: selectedFilter == "Done") { selectedFilter = "Done" }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 20) // Match Lawyers List
                .padding(.bottom, 12) // Match Lawyers List
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) { // Match Lawyers List
                        // MARK: Booking List
                        VStack(spacing: 16) { // Match Lawyers List
                            ForEach(bookings) { booking in
                                NavigationLink(value: booking) {
                                    BookingCard(booking: booking)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Footer space for TabBar
                        Color.clear.frame(height: 180)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20) // Match Lawyers List
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationDestination(isPresented: $showBookingView) {
            BookingView(lawyer: Lawyer(
                id: "L1",
                name: "Nimal Perera",
                specialty: "Criminal Law",
                bio: "Criminal specialist",
                description: "Bio",
                experience: "14 YEARS",
                casesWon: "250 +",
                rating: 4.8,
                location: "Colombo",
                image: "person",
                coordinate: .init(latitude: 6.9271, longitude: 79.8612)
            ))
        }
    }
}

// MARK: - Subcomponents

private struct BookingCard: View {
    let booking: Booking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                // Profile Avatar Placeholder
                ZStack {
                    Circle()
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.lmPrimary.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(booking.lawyerName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        // Status Badge (Standardized with Lawyer Specialty style)
                        Text(booking.status.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(booking.status.color)
                    }
                    
                    Text(booking.date)
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary)
                    
                    Text(booking.time)
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            HStack {
                Text(booking.category)
                    .font(.lmCaption.weight(.semibold))
                    .foregroundColor(.lmTextSecondary)
                
                Spacer()
                
                Text(booking.method)
                    .font(.lmCaption.weight(.semibold))
                    .foregroundColor(.lmTextSecondary)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    BookingDetailsView()
}
