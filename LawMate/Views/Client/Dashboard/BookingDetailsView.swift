import SwiftUI

// FBAppointment is now used as the source of truth from FirebaseModels.swift

// MARK: - Booking Details View
struct BookingDetailsView: View {
    var onBack: () -> Void = {}
    
    @StateObject private var firestore = FirestoreManager.shared
    @State private var searchQuery = ""
    @State private var selectedFilter = "Confirmed"
    
    private let filters = ["Confirmed", "Pending", "In progress", "Done"]
    
    var filteredBookings: [FBAppointment] {
        firestore.appointments.filter { booking in
            let matchesSearch = searchQuery.isEmpty || booking.lawyerName.localizedCaseInsensitiveContains(searchQuery)
            let matchesFilter = booking.status.lowercased() == selectedFilter.lowercased()
            return matchesSearch && matchesFilter
        }
    }
    
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
                    NavigationLink(value: ClientHomeView.AppRoute.booking(nil)) {
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
                LawMateSearchBar(text: $searchQuery, placeholder: "Search bookings or lawyers")
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
                        VStack(spacing: 16) {
                            if filteredBookings.isEmpty {
                                Text("No \(selectedFilter.lowercased()) bookings found")
                                    .font(.lmCaption)
                                    .foregroundColor(.lmTextSecondary.opacity(0.5))
                                    .padding(.top, 40)
                            } else {
                                ForEach(filteredBookings) { booking in
                                    BookingCard(booking: booking)
                                }
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
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Subcomponents

private struct BookingCard: View {
    let booking: FBAppointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                // Profile Avatar Placeholder
                ZStack {
                    Circle()
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person")
                        .font(.system(size: 24))
                        .foregroundColor(.lmPrimary.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(booking.lawyerName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        // Status Badge
                        Text(booking.status)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(statusColor(for: booking.status))
                    }
                    
                    Text(formatDate(booking.date))
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary)
                    
                    Text(booking.time)
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            HStack {
                Text(booking.service)
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
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "confirmed": return .green
        case "pending": return .red
        case "in progress": return .orange
        case "done": return .gray
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: date)
    }
}

#Preview {
    BookingDetailsView()
}
