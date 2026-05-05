import SwiftUI
import MapKit

struct MyCaseDetailsView: View {
    let appointment: FBAppointment
    @Environment(\.dismiss) private var dismiss
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
    @State private var showRescheduleSheet = false
    @State private var showCancelSheet = false
    @State private var route: MKRoute?
    
    // Mock user location and lawyer location
    let userLocation = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
    let lawyerLocation = CLLocationCoordinate2D(latitude: 6.9355, longitude: 79.8485)
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left (Client Style)
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "My Booking Details",
                    showBack: true,
                    showNotification: true,
                    showCamera: false,
                    onBack: { dismiss() },
                    onNotification: {
                        navPath.append(ClientHomeView.AppRoute.notifications)
                    }
                )
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: Appointment Details Card
                        appointmentCard
                        
                        // MARK: Video/Map Placeholder Area
                        if appointment.method == "In Person" {
                            Map(initialPosition: .automatic) {
                                Marker("You", coordinate: userLocation)
                                Marker("Lawyer", coordinate: lawyerLocation)
                                    .tint(Color.lmPrimary)
                                
                                if let currentRoute = route {
                                    MapPolyline(currentRoute.polyline)
                                        .stroke(Color.blue, lineWidth: 5)
                                }
                            }
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .onAppear {
                                fetchRoute()
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                )
                        }
                        
                        // MARK: Primary CTA (Join/Directions)
                        Button {
                            // Action
                        } label: {
                            HStack {
                                Spacer()
                                Text(appointment.method == "In Person" ? "Get Directions" : "Join the Meeting")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .background(Color.lmPrimary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        
                        // Bottom Padding for Tab Bar equivalent area
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRescheduleSheet) {
            RescheduleBookingView(appointment: appointment)
        }
        .sheet(isPresented: $showCancelSheet) {
            CancelBookingView(appointment: appointment)
        }
    }
    
    private func fetchRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: lawyerLocation))
        request.transportType = .automobile
        
        Task {
            let directions = MKDirections(request: request)
            if let response = try? await directions.calculate() {
                self.route = response.routes.first
            }
        }
    }
    
    // MARK: - Subcomponents
    private var appointmentCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: Card Header (Specialty Badge)
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: appointment.specialtyIcon)
                        .font(.system(size: 14))
                    Text(appointment.lawyerSpecialty ?? "Legal Advice")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.lmPrimary.opacity(0.1))
                .foregroundColor(.lmPrimary)
                .clipShape(Capsule())
                
                Spacer()
                
                // Status Badge (Right)
                Text(appointment.statusTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(appointment.statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(appointment.statusColor.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(appointment.statusColor.opacity(0.3), lineWidth: 1))
            }

            HStack {
                Spacer()

                Button {
                    showRescheduleSheet = true
                } label: {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lmPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.lmPrimary.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reschedule")

                Button {
                    showCancelSheet = true
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel")
            }
            
            HStack(alignment: .top, spacing: 16) {
                // Profile Avatar (LawMate Consistent)
                LawMateAvatar(url: appointment.lawyerImage, name: appointment.lawyerName, size: 66)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.lawyerName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text(appointment.service)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                    
                    HStack(spacing: 12) {
                        Label(formatDate(appointment.date), systemImage: "calendar")
                        Label(appointment.time, systemImage: "clock")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.lmTextSecondary.opacity(0.7))
                    .padding(.top, 4)
                }
            }
            
            Divider()
                .background(Color.lmPrimary.opacity(0.1))
            
            // Meeting Details
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: appointment.method == "Video Call" ? "video.fill" : "building.2.fill")
                        .foregroundColor(.lmPrimary)
                    Text(appointment.method)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lmPrimary)
                }
                
                Spacer()
                
                Text(appointment.method == "In Person" ? "Location: Colombo 07" : "Link: join.lawmate.sh")
                    .font(.system(size: 12))
                    .foregroundColor(.lmTextSecondary)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: date)
    }
}

#Preview {
    MyCaseDetailsView(
        appointment: FBAppointment(
            clientId: "C1",
            clientName: "John Doe",
            lawyerId: "L1",
            lawyerName: "Sanduni Fernando",
            service: "Family Law",
            date: Date(),
            time: "02:00 PM - 03:00 PM",
            method: "Video Call",
            description: "Consultation about divorce",
            status: "In Progress"
        ),
        navPath: .constant(NavigationPath()),
        activeConversation: .constant(nil)
    )
}
