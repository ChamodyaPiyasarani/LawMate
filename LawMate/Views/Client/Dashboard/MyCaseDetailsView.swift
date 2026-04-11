import SwiftUI
import MapKit

struct MyCaseDetailsView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss
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
                    notificationCount: 0,
                    onBack: { dismiss() },
                    onNotification: {}
                )
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: Appointment Details Card
                        appointmentCard
                        
                        // MARK: Video/Map Placeholder Area
                        if booking.method == "In Person" {
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
                                Text(booking.method == "In Person" ? "Get Directions" : "Join the Meeting")
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
                        
                        // MARK: Secondary Actions
                        HStack(spacing: 16) {
                            Button {
                                showRescheduleSheet = true
                            } label: {
                                Text("Reschedule")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.lmPrimary)
                                    .clipShape(Capsule())
                            }
                            
                            Button {
                                showCancelSheet = true
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.lmPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.lmPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.top, 40)
                        
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
            RescheduleBookingView()
        }
        .sheet(isPresented: $showCancelSheet) {
            CancelBookingView()
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Avatar Placeholder
                ZStack {
                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.lmPrimary.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(booking.lawyerName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        // Status Badge
                        Text(booking.status.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(booking.status.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(booking.status.color.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Text(booking.date)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                    
                    Text(booking.time)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            Divider()
                .background(Color.lmPrimary.opacity(0.1))
            
            HStack {
                Text(booking.category)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lmPrimary.opacity(0.8))
                
                Spacer()
                
                Text(booking.method)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lmPrimary.opacity(0.8))
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
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    MyCaseDetailsView(booking: Booking(id: "B1", lawyerName: "Sanduni Fernando", date: "Apr 30, 2026", time: "02:00 PM - 03:00 PM", category: "Family Law", method: "Video Call", status: .inProgress))
}
