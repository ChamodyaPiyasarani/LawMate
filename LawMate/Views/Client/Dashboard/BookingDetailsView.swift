import SwiftUI

// FBAppointment is now used as the source of truth from FirebaseModels.swift

// MARK: - Booking Details View
struct BookingDetailsView: View {
    @Binding var navPath: NavigationPath
    var onBack: () -> Void = {}
    
    @EnvironmentObject var firestore: FirestoreManager
    @State private var searchQuery = ""
    @State private var selectedFilter = "Confirmed"
    
    private let filters = ["Confirmed", "Pending", "Rescheduled", "Overdue", "Cancelled", "Done"]
    
    var filteredBookings: [FBAppointment] {
        firestore.appointments.filter { booking in
            let matchesSearch = searchQuery.isEmpty || 
                               booking.lawyerName.localizedCaseInsensitiveContains(searchQuery) ||
                               booking.clientName.localizedCaseInsensitiveContains(searchQuery)
            
            let matchesFilter: Bool
            let s = booking.status.lowercased()
            
            if selectedFilter == "Overdue" {
                matchesFilter = booking.isOverdue
            } else if selectedFilter == "Done" {
                matchesFilter = (s == "done" || s == "completed")
            } else {
                matchesFilter = s == selectedFilter.lowercased()
            }
            
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
                .padding(.top, 65)
                .zIndex(10)
                
                // MARK: Fixed Search Bar (Standardized with Lawyers List)
                LawMateSearchBar(text: $searchQuery, placeholder: "Search bookings or lawyers")
                    .padding(.horizontal, 24)
                    .padding(.top, 10) // Match Lawyers List
                
                // MARK: Fixed Filter Chips (Standardized with Lawyers List)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        LawMateFilterPill(icon: "checkmark.circle.fill", title: "Confirmed", isActive: selectedFilter == "Confirmed") { selectedFilter = "Confirmed" }
                        LawMateFilterPill(icon: "clock.fill", title: "Pending", isActive: selectedFilter == "Pending") { selectedFilter = "Pending" }
                        LawMateFilterPill(icon: "calendar.badge.clock", title: "Rescheduled", isActive: selectedFilter == "Rescheduled") { selectedFilter = "Rescheduled" }
                        LawMateFilterPill(icon: "exclamationmark.triangle.fill", title: "Overdue", isActive: selectedFilter == "Overdue") { selectedFilter = "Overdue" }
                        LawMateFilterPill(icon: "xmark.circle.fill", title: "Cancelled", isActive: selectedFilter == "Cancelled") { selectedFilter = "Cancelled" }
                        LawMateFilterPill(icon: "checkmark.seal.fill", title: "Done", isActive: selectedFilter == "Done") { selectedFilter = "Done" }
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
                                    Button {
                                        navPath.append(booking)
                                    } label: {
                                        AppointmentRowView(appointment: booking)
                                    }
                                    .buttonStyle(.plain)
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
            
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    BookingDetailsView(navPath: .constant(NavigationPath()))
}
