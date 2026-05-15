//
//  NavComponents.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Shared navigation button components:
//  - LawMateBackButton        — chevron left back navigation
//  - NotificationButton       — bell icon with optional badge count
//  - LawMateNavigationBar     — title bar with optional back + notification buttons
//

import SwiftUI
import UIKit
import MapKit
import PDFKit
import CoreLocation
import Combine
import WebKit
import VisionKit
import QuickLook

// MARK: - Back Button
struct LawMateBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Rim highlight
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    .frame(width: 44, height: 44)

                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold)) // Bolder as in image
                    .foregroundColor(.lmPrimary) // Changed to primary green
            }
            .contentShape(Circle()) // Reliable tap area
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

// MARK: - Notification Button
struct NotificationButton: View {
    @EnvironmentObject var firestore: FirestoreManager
    var badgeCount: Int? = nil // Optional override
    var action: (() -> Void)? = nil // Optional override

    private var displayCount: Int {
        badgeCount ?? firestore.unreadNotificationsCount
    }

    var body: some View {
        Button {
            if let action = action {
                action()
            } else {
                NotificationManager.shared.showNotifications = true
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    // Liquid glass background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    
                    // Rim highlight
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        .frame(width: 44, height: 44)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.lmPrimary)
                }

                if displayCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                        Text("\(min(displayCount, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Notifications\(displayCount > 0 ? ", \(displayCount) unread" : "")")
    }
}

struct AppointmentRowView: View {
    let appointment: FBAppointment
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var firestore: FirestoreManager
    
    @State private var showRejectAlert = false
    @State private var showDeleteAlert = false
    @State private var showReschedulePicker = false
    @State private var showReviewSheet = false
    
    private func confirmReject() {
        firestore.updateAppointmentStatus(appointmentId: appointment.id ?? "", status: "Rejected") { success in
            if success {
                let targetUserId = (auth.currentUser?.role == .lawyer) ? appointment.clientId : appointment.lawyerId
                let senderName = auth.currentUser?.fullName ?? "Someone"
                let notification = FBNotification(
                    title: "Appointment Rejected",
                    body: "\(senderName) has rejected the appointment request for \(appointment.time) on \(formatDate(appointment.date)).",
                    type: "appointment",
                    timestamp: Date(),
                    relatedId: appointment.id
                )
                firestore.addNotification(notification, toUserId: targetUserId)
            }
        }
    }
    
    private func confirmDelete() {
        guard let id = appointment.id else { return }
        
        // 1. Remove from System Calendar
        let otherParty = (auth.currentUser?.role == .lawyer) ? appointment.clientName : appointment.lawyerName
        let eventTitle = "\(appointment.service) with \(otherParty)"
        EventKitManager.shared.removeEvent(title: eventTitle, startDate: appointment.date)
        
        // 2. Notify other party
        let otherUserId = (auth.currentUser?.role == .lawyer) ? appointment.clientId : appointment.lawyerId
        let senderName = auth.currentUser?.fullName ?? "Someone"
        
        let notification = FBNotification(
            title: "Appointment Cancelled",
            body: "\(senderName) has cancelled the \(appointment.service) scheduled for \(appointment.date.formatted(date: .abbreviated, time: .omitted)).",
            type: "appointment",
            timestamp: Date(),
            relatedId: id
        )
        firestore.addNotification(notification, toUserId: otherUserId)

        // 3. Remove from Firestore
        firestore.deleteAppointment(id: id) { success in
            if success {
                ToastManager.shared.show(title: "Deleted", message: "Appointment removed successfully.", type: .success)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                identitySection
                contentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            actionButtonsSection
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .alert("Reject Appointment", isPresented: $showRejectAlert) {
            Button("Reject", role: .destructive) {
                confirmReject()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to reject this appointment request?")
        }
        .alert("Delete Appointment", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                confirmDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this appointment? This will also remove it from your system calendar.")
        }
        .sheet(isPresented: $showReschedulePicker) {
            ReschedulePickerSheet(appointment: appointment)
        }
        .sheet(isPresented: $showReviewSheet) {
            ReviewSheet(appointment: appointment)
        }
    }

    private var identitySection: some View {
        let currentRole = auth.currentUser?.role ?? .client
        let displayImage = currentRole == .lawyer ? appointment.clientImage : appointment.lawyerImage
        
        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
            
            if let imgStr = displayImage, let imgData = Data(base64Encoded: imgStr.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")), let uiImg = UIImage(data: imgData) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.lmPrimary.opacity(0.5))
            }
        }
        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var contentSection: some View {
        let currentRole = auth.currentUser?.role ?? .client
        let displayName = currentRole == .lawyer ? appointment.clientName : appointment.lawyerName
        
        return VStack(alignment: .leading, spacing: 6) {
            // Row 1: Name & Actions
            HStack {
                Text(displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.7))
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    
                    Text(appointment.statusTitle.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(appointment.statusColor.opacity(0.12))
                        .foregroundColor(appointment.statusColor)
                        .clipShape(Capsule())
                }
            }
            
            // Row 2: Time & Category
            HStack(spacing: 8) {
                Label(appointment.time.components(separatedBy: " ").first ?? "", systemImage: "clock.fill")
                Text("•").opacity(0.3)
                Label(appointment.method, systemImage: appointment.method == "Video Call" ? "video.fill" : "mappin.and.ellipse.circle.fill")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.lmTextSecondary)
            
            // Row 3: Selected Service
            Text(appointment.service)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.lmPrimary)
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        let currentUserId = auth.currentUser?.id ?? ""
        let isPendingOrRescheduled = appointment.status.lowercased() == "pending" || appointment.status.lowercased() == "rescheduled"
        let isRecipient = appointment.lastActionBy != currentUserId
        let isConfirmed = appointment.status.lowercased() == "confirmed"
        let isLawyer = auth.currentUser?.role == .lawyer
        
        if (isPendingOrRescheduled && isRecipient) || isConfirmed {
            Divider()
                .padding(.horizontal, 16)
                .opacity(0.1)
            
            VStack(spacing: 0) {
                if isPendingOrRescheduled && isRecipient {
                    HStack(spacing: 12) {
                        Button {
                            firestore.updateAppointmentStatus(appointmentId: appointment.id ?? "", status: "Confirmed") { success in
                                if success {
                                    let targetUserId = isLawyer ? appointment.clientId : appointment.lawyerId
                                    let senderName = auth.currentUser?.fullName ?? "Someone"
                                    let notification = FBNotification(
                                        title: "Appointment Confirmed",
                                        body: "\(senderName) has confirmed the appointment for \(appointment.time) on \(formatDate(appointment.date)).",
                                        type: "appointment",
                                        timestamp: Date(),
                                        relatedId: appointment.id
                                    )
                                    firestore.addNotification(notification, toUserId: targetUserId)
                                    
                                    EventKitManager.shared.createEvent(
                                        title: "Confirmed: \(appointment.service) with \(isLawyer ? appointment.clientName : appointment.lawyerName)",
                                        startDate: appointment.date,
                                        endDate: appointment.date.addingTimeInterval(3600),
                                        location: appointment.method,
                                        notes: appointment.description
                                    ) { _, _ in }
                                }
                            }
                        } label: {
                            Text("Confirm")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            showReschedulePicker = true
                        } label: {
                            Text("Reschedule")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            showRejectAlert = true
                        } label: {
                            Text("Reject")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                } else if isConfirmed {
                    HStack(spacing: 12) {
                        // Join/Directions for BOTH Client and Lawyer
                        Button {
                            if appointment.method == "Video Call" {
                                if let url = URL(string: "https://join.lawmate.sh") {
                                    UIApplication.shared.open(url)
                                }
                            } else {
                                var lat = appointment.locationLat ?? 6.9271
                                var lng = appointment.locationLng ?? 79.8612
                                
                                // Override simulator defaults (SF/Cupertino) to Sri Lanka
                                if (lat > 37.0 && lat < 38.0) && (lng < -121.0 && lng > -123.0) {
                                    lat = 6.9271
                                    lng = 79.8612
                                }
                                
                                let sLat = 6.9064
                                let sLng = 79.8708
                                
                                if let url = URL(string: "http://maps.apple.com/?saddr=\(sLat),\(sLng)&daddr=\(lat),\(lng)&q=\(appointment.lawyerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Consultation")") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: appointment.method == "Video Call" ? "video.fill" : "mappin.and.ellipse")
                                Text(appointment.method == "Video Call" ? "Join" : "Directions")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        // Complete button ONLY for Lawyer
                        if isLawyer {
                            Button {
                                firestore.updateAppointmentStatus(appointmentId: appointment.id ?? "", status: "Done") { _ in }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Complete")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if appointment.status.lowercased() == "done" && !isLawyer {
                    // Rate Experience for Client
                    Button {
                        showReviewSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                            Text("Rate Experience")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: date)
    }
}

// MARK: - Reschedule Picker Sheet
struct ReschedulePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let appointment: FBAppointment
    
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    @State private var selectedDate: Date
    @State private var isSaving = false
    
    init(appointment: FBAppointment) {
        self.appointment = appointment
        // Default to 1 hour after the current appointment time
        self._selectedDate = State(initialValue: appointment.date.addingTimeInterval(3600))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select New Date & Time")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    DatePicker(
                        "Reschedule",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.lmPrimary)
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                Button {
                    saveReschedule()
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Confirm Reschedule")
                            .font(.lmButton)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.lmPrimary)
                            .clipShape(Capsule())
                    }
                }
                .disabled(isSaving)
            }
            .padding(24)
            .background(Color.lmBackground)
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func saveReschedule() {
        isSaving = true
        
        let timeString = formatTime(selectedDate)
        
        firestore.rescheduleAppointment(
            appointmentId: appointment.id ?? "",
            newDate: selectedDate,
            newTime: timeString
        ) { success in
            isSaving = false
            if success {
                // Notify Other Party
                let isLawyer = auth.currentUser?.role == .lawyer
                let targetUserId = isLawyer ? appointment.clientId : appointment.lawyerId
                let senderName = auth.currentUser?.fullName ?? "Someone"
                
                let notification = FBNotification(
                    title: "Appointment Rescheduled",
                    body: "\(senderName) has suggested a new time: \(timeString) on \(formatDate(selectedDate))",
                    type: "appointment",
                    timestamp: Date(),
                    relatedId: appointment.id
                )
                firestore.addNotification(notification, toUserId: targetUserId)
                
                dismiss()
            } else {
                ToastManager.shared.show(title: "Error", message: "Failed to reschedule. Please try again.", type: .error)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f.string(from: date)
    }
}

// MARK: - Camera Button
struct CameraButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Rim highlight
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    .frame(width: 44, height: 44)

                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.lmPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Navigation Bar
struct LawMateNavigationBar: View {
    var title: String = ""
    var showBack: Bool = false
    var showNotification: Bool = false
    var showCamera: Bool = false
    var onBack: () -> Void = {}
    var onNotification: (() -> Void)? = nil
    var onCamera: () -> Void = {}
    var trailingView: AnyView? = nil
    
    @EnvironmentObject var firestore: FirestoreManager

    var body: some View {
        HStack {
            if showBack {
                LawMateBackButton(action: onBack)
            }
            Spacer()
            if !title.isEmpty {
                Text(title)
                    .font(.lmHeading)
                    .foregroundColor(.lmPrimary)
            }
            Spacer()
            
            if let trailingView = trailingView {
                trailingView
            } else if showNotification {
                NotificationButton(badgeCount: firestore.unreadNotificationsCount, action: onNotification)
            } else if showCamera {
                CameraButton(action: onCamera)
            } else if showBack {
                Color.clear.frame(width: 44, height: 44)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

#Preview {
    VStack(spacing: 20) {
        LawMateBackButton(action: {})
        NotificationButton(badgeCount: 3, action: {})
        NotificationButton(badgeCount: 0, action: {})
        LawMateNavigationBar(title: "My Cases",
                              showBack: true,
                              showNotification: true,
                              onBack: {},
                              onNotification: {})
        .background(Color.lmBackground)
    }
    .padding()
    .background(Color.lmFieldBg)
}


// MARK: - Shared Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .lmTextSecondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.lmPrimary : Color.clear)
                .clipShape(Capsule())
        }
    }
}


// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location.coordinate
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    var onConfirm: (CLLocationCoordinate2D) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $mapCameraPosition, bounds: MapCameraBounds(maximumDistance: 1500000)) {}
                .onMapCameraChange(frequency: .continuous) { context in
                    region = context.region
                }
                
                VStack {
                    ZStack {
                        Image(systemName: "mappin")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                            .offset(y: -20)
                        Circle()
                            .fill(.black.opacity(0.1))
                            .frame(width: 8, height: 8)
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            if let userLoc = locationManager.userLocation {
                                withAnimation {
                                    mapCameraPosition = .region(MKCoordinateRegion(
                                        center: userLoc,
                                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                    ))
                                }
                            } else {
                                locationManager.requestPermission()
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .padding()
                                .background(.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.leading, 20)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                    Button {
                        onConfirm(region.center)
                        dismiss()
                    } label: {
                        Text("Confirm Location")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.lmPrimary)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }
}

// MARK: - PDF Viewer Components
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // Handle local files vs remote URLs
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct PDFKitViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let document: FBAdvisoryDocument
    @State private var localURL: URL? = nil
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.lmBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.lmPrimary)
                            Text("Preparing document...")
                                .font(.lmCaption)
                                .foregroundColor(.lmTextSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else if let url = localURL {
                        QuickLookController(url: url)
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        errorView(message: "Document preview unavailable. Please try downloading the file manually.")
                    }
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let url = localURL {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .onAppear {
                prepareDocument()
            }
        }
    }
    
    private func prepareDocument() {
        // 1. Handle Base64 Data
        if let base64 = document.fileBase64, let data = Data(base64Encoded: base64) {
            decodeAndSave(data: data)
            return
        }
        
        // 2. Handle Remote/Local URL
        if let urlString = document.fileURL, let url = URL(string: urlString) {
            if url.isFileURL {
                self.localURL = url
                self.isLoading = false
            } else {
                downloadDocument(url: url)
            }
            return
        }
        
        self.isLoading = false
    }
    
    private func decodeAndSave(data: Data) {
        DispatchQueue.global(qos: .userInitiated).async {
            let tempDir = FileManager.default.temporaryDirectory
            let extensionName = document.fileType.lowercased()
            let fileName = (document.id ?? UUID().uuidString) + "." + (extensionName.isEmpty ? "pdf" : extensionName)
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try? data.write(to: fileURL)
            
            DispatchQueue.main.async {
                self.localURL = fileURL
                self.isLoading = false
            }
        }
    }
    
    private func downloadDocument(url: URL) {
        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: destinationURL)
            try? FileManager.default.moveItem(at: tempURL, to: destinationURL)
            
            DispatchQueue.main.async {
                self.localURL = destinationURL
                self.isLoading = false
            }
        }.resume()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.8))
            
            Text("Preview Unavailable")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary)
            
            Text(message)
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Generic Document Viewer
struct LawMateDocumentViewer: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let url: URL
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.lmBackground.ignoresSafeArea()
                
                PDFKitView(url: url)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - Live Text Image Viewer
struct ZoomableLiveTextImageView: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tag = 999
        
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        if #available(iOS 16.0, *) {
            let analyzer = ImageAnalyzer()
            let interaction = ImageAnalysisInteraction()
            imageView.addInteraction(interaction)
            
            Task {
                let config = ImageAnalyzer.Configuration([.text, .machineReadableCode])
                if let analysis = try? await analyzer.analyze(image, configuration: config) {
                    DispatchQueue.main.async {
                        interaction.analysis = analysis
                        interaction.preferredInteractionTypes = .automatic
                    }
                }
            }
        }
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let imageView = uiView.viewWithTag(999) as? UIImageView {
            imageView.image = image
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(999)
        }
    }
}


// MARK: - Timeline Component
struct TimelineNode: View {
    let index: Int
    let stage: FBCaseStage
    let isLast: Bool
    let isActive: Bool
    let canEdit: Bool
    var onToggle: () -> Void = {}
    var onUpload: () -> Void = {}
    var onCamera: (() -> Void)? = nil
    var onGallery: ((UIImage?) -> Void)? = nil
    var onDateChange: ((Date) -> Void)? = nil
    var onAction: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage? = nil
    
    var body: some View {
        let isLocked = canEdit && !stage.isCompleted && !isActive
        
        HStack(alignment: .top, spacing: 16) {
            // Indicator line and circle
            VStack(spacing: 0) {
                ZStack {
                    if canEdit {
                        Button(action: onToggle) {
                            ZStack {
                                Circle()
                                    .fill(stage.isCompleted ? Color.lmPrimary : (isLocked ? Color.gray.opacity(0.1) : Color.white))
                                    .frame(width: 26, height: 26)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Circle()
                                    .stroke(stage.isCompleted ? Color.lmPrimary : (isLocked ? Color.gray.opacity(0.2) : Color.gray.opacity(0.3)), lineWidth: 2)
                                    .frame(width: 26, height: 26)
                                
                                if stage.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                        .disabled(isLocked)
                    } else {
                        Circle()
                            .fill(stage.isCompleted ? Color.lmPrimary : Color.gray.opacity(0.1))
                            .frame(width: 24, height: 24)
                        
                        if stage.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        } else if isActive {
                            Circle()
                                .stroke(Color.lmPrimary, lineWidth: 2)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(stage.isCompleted ? Color.lmPrimary : Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(minHeight: canEdit ? 70 : 40)
                }
            }
            .opacity(isLocked ? 0.6 : 1.0)
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(String(format: "%02d", index + 1))")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(stage.isCompleted || isActive ? .lmPrimary.opacity(0.6) : .lmTextSecondary.opacity(0.5))
                        .textCase(.uppercase)
                    
                    HStack {
                        Text(stage.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(stage.isCompleted || isActive ? .lmPrimary : .lmTextSecondary)
                        
                        if isActive {
                            Text("Current")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        if let date = stage.date {
                            Text(formatDate(date))
                                .font(.system(size: 12))
                                .foregroundColor(.lmTextSecondary)
                        }
                    }
                }
                
                Text(stage.description)
                    .font(.system(size: 13))
                    .foregroundColor(.lmTextSecondary)
                    .lineLimit(2)
                
                if let onDateChange = onDateChange, stage.title.lowercased().contains("hearing") {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundColor(.lmPrimary)
                        
                        DatePicker(
                            "Set Hearing",
                            selection: Binding(
                                get: { stage.date ?? Date() },
                                set: { onDateChange($0) }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .padding(.top, 4)
                }
                
                if canEdit {
                    HStack(spacing: 12) {
                        Button(action: onUpload) {
                            Image(systemName: "arrow.up.doc.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.lmPrimary)
                                .clipShape(Circle())
                                .shadow(color: Color.lmPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        
                        if let onCamera = onCamera {
                            Menu {
                                Button {
                                    onCamera()
                                } label: {
                                    Label("Scan with Camera", systemImage: "camera")
                                }
                                
                                if onGallery != nil {
                                    Button {
                                        showImagePicker = true
                                    } label: {
                                        Label("Select from Gallery", systemImage: "photo.on.rectangle")
                                    }
                                }
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.lmPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.lmPrimary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        
                        if let onAction = onAction {
                            Button(action: onAction) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 14))
                                    .foregroundColor(.lmPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.lmPrimary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                if !isLast {
                    Spacer().frame(height: canEdit ? 30 : 20)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedUIImage)
        }
        .onChange(of: selectedUIImage) { _, newImage in
            if let img = newImage, let onGallery = onGallery {
                onGallery(img)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

// MARK: - LawMate Avatar
struct LawMateAvatar: View {
    let url: String?
    let name: String
    let size: CGFloat
    
    var body: some View {
        Group {
            if let urlString = url, urlString.lowercased().hasPrefix("http") {
                // Remote Image
                if let imageURL = URL(string: urlString) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: size, height: size)
                                .background(Color.lmPrimary.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: size, height: size)
                        case .failure:
                            fallbackView
                                .overlay(
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: size * 0.2))
                                        .foregroundColor(.red)
                                        .padding(2)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .offset(x: size * 0.35, y: size * 0.35)
                                )
                        @unknown default:
                            fallbackView
                        }
                    }
                } else {
                    fallbackView
                }
            } else if let base64String = url, base64String.hasPrefix("data:image") {
                // Base64 Image
                if let data = Data(base64Encoded: base64String.components(separatedBy: ",").last ?? ""),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                } else {
                    fallbackView
                }
            } else if let localName = url, !localName.isEmpty {
                // Local Mock Asset
                Image(localName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else {
                // Initials Fallback
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    
    private var fallbackView: some View {
        Circle()
            .fill(Color.lmPrimary)
            .overlay(
                Text(initials(for: name))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

// MARK: - Plus Button
struct LawMatePlusButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Rim highlight
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    .frame(width: 44, height: 44)

                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lmPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add New Chat")
    }
}

// MARK: - QuickLook Controller
struct QuickLookController: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookController

        init(parent: QuickLookController) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            parent.url as QLPreviewItem
        }
    }
}

// MARK: - Shared Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.lmPrimary : Color.white)
                .foregroundColor(isSelected ? .white : .lmPrimary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.lmPrimary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
import SwiftUI

struct BookingCalendarView: View {
    @Binding var selectedDate: Date
    let lawyerId: String?
    
    @State private var currentMonth = Date()
    @State private var busyDates: [Date] = []
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Header
            HStack {
                Text(currentMonth, formatter: monthYearFormatter)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.lmPrimary)
                    }
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.lmPrimary)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // Day Names
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lmTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid
            let days = generateDaysInMonth(for: currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days) { day in
                    if let date = day.date {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            fetchBusyDates()
        }
        .onChange(of: currentMonth) { _, _ in
            fetchBusyDates()
        }
        .onChange(of: lawyerId) { _, _ in
            fetchBusyDates()
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        let isPast = date < Calendar.current.startOfDay(for: Date())
        let isBusy = busyDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) })
        let isDisabled = isPast || isBusy
        
        return Button {
            if !isDisabled {
                selectedDate = date
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.lmPrimary)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(Color.lmPrimary, lineWidth: 1)
                        .frame(width: 36, height: 36)
                }
                
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 15, weight: isSelected || isToday ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : (isDisabled ? .gray.opacity(0.3) : .lmPrimary))
                    
                    if isBusy {
                        Text("FULL")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.red.opacity(0.6))
                    }
                }
            }
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
    
    private func fetchBusyDates() {
        guard let id = lawyerId else { return }
        FirestoreManager.shared.fetchLawyerBusyDates(lawyerId: id, forMonth: currentMonth) { dates in
            DispatchQueue.main.async {
                self.busyDates = dates
            }
        }
    }
    
    private func generateDaysInMonth(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmptyDays = weekday - 1
        
        var days: [CalendarDay] = []
        for _ in 0..<leadingEmptyDays {
            days.append(CalendarDay(date: nil))
        }
        for day in 1...monthRange.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date))
            }
        }
        return days
    }
    
    private func nextMonth() {
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = next
        }
    }
    
    private func previousMonth() {
        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = prev
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }
}

// MARK: - Premium Glass Components

/// A premium, glassmorphism-styled Date and Time picker for LawMate.
struct GlassDateTimePicker: View {
    @Binding var selectedDate: Date
    let busyDates: [Date] // Dates/Times that are already booked
    
    @State private var showTimePicker = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Date Selector (Horizontal Scroll)
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Date")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
                    .padding(.horizontal, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<14) { day in
                            let date = calendar.date(byAdding: .day, value: day, to: Date()) ?? Date()
                            DateCard(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate)) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // MARK: - Time Selector (Liquid Glass Grid)
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Slots")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmTextSecondary)
                    .padding(.horizontal, 4)
                
                let times = generateTimeSlots()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(times, id: \.self) { timeStr in
                        let isBusy = checkIfBusy(timeStr: timeStr)
                        let isSelected = formatTime(selectedDate) == timeStr
                        
                        TimeSlotCard(time: timeStr, isSelected: isSelected, isBusy: isBusy) {
                            if !isBusy {
                                updateSelectedTime(timeStr: timeStr)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
    }
    
    // MARK: - Helpers
    private func generateTimeSlots() -> [String] {
        return ["09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "02:00 PM", "03:00 PM", "04:00 PM", "05:00 PM", "06:00 PM"]
    }
    
    private func checkIfBusy(timeStr: String) -> Bool {
        // Simple overlap check against busyDates
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        
        return busyDates.contains { busyDate in
            calendar.isDate(busyDate, inSameDayAs: selectedDate) && 
            formatTime(busyDate) == timeStr
        }
    }
    
    private func updateSelectedTime(timeStr: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        if let timeDate = formatter.date(from: timeStr) {
            let components = calendar.dateComponents([.hour, .minute], from: timeDate)
            if let newDate = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}

struct DateCard: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayOfWeek)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .white : .lmTextSecondary)
                
                Text(dayNumber)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(isSelected ? .white : .lmPrimary)
            }
            .frame(width: 60, height: 80)
            .background(isSelected ? Color.lmPrimary : Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    private var dayOfWeek: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }
    
    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "dd"
        return f.string(from: date)
    }
}

struct TimeSlotCard: View {
    let time: String
    let isSelected: Bool
    let isBusy: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .opacity(isBusy ? 0.4 : 1.0)
        }
        .disabled(isBusy)
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        if isBusy { return Color.gray.opacity(0.1) }
        if isSelected { return Color.lmPrimary }
        return Color.white.opacity(0.4)
    }
    
    private var textColor: Color {
        if isBusy { return Color.lmTextSecondary.opacity(0.5) }
        if isSelected { return .white }
        return .lmPrimary
    }
}

// MARK: - Data Unavailable View
struct DataUnavailableView: View {
    let title: String
    let message: String
    let image: String
    var onBack: () -> Void = {}
    
    var body: some View {
        ZStack {
            Color.lmBackground.ignoresSafeArea()
            
            // Background blob for aesthetic consistency
            GreenBlobBackground(style: .client)
                .frame(height: 300)
                .offset(y: -50)
            
            VStack(spacing: 24) {
                // MARK: Navigation header (minimal)
                HStack {
                    LawMateBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 65)
                
                Spacer()
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
                        
                        Image(systemName: image)
                            .font(.system(size: 50))
                            .foregroundColor(.lmPrimary.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Text(message)
                            .font(.system(size: 15))
                            .foregroundColor(.lmTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                LawMatePrimaryButton(title: "Go Back") {
                    onBack()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Document Versioning Components

struct DocumentGroupRow: View {
    let latestDoc: FBDocument
    let versions: [FBDocument]
    let isLawyer: Bool
    let onSelect: (FBDocument) -> Void
    let onAddVersion: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: latestDoc.fileType.uppercased() == "PDF" ? "doc.fill" : "photo.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.lmPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(latestDoc.fileName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .lineLimit(1)
                        
                        DocumentCategoryBadge(category: latestDoc.category)
                    }
                    
                    Text("Version \(latestDoc.version) • \(latestDoc.uploadedAt, style: .date)")
                        .font(.system(size: 12))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if versions.count > 1 {
                        Button {
                            withAnimation { isExpanded.toggle() }
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "clock.arrow.circlepath")
                                .font(.system(size: 24))
                                .foregroundColor(.lmPrimary.opacity(0.6))
                        }
                    }
                    
                    if isLawyer {
                        Button(action: onAddVersion) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button {
                        onSelect(latestDoc)
                    } label: {
                        Image(systemName: "eye.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.lmPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(versions.dropFirst()) { doc in
                        Divider().padding(.horizontal, 16)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Version \(doc.version)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                Text(doc.uploadedAt, style: .date)
                                    .font(.system(size: 11))
                                    .foregroundColor(.lmTextSecondary)
                            }
                            Spacer()
                            Button("View") { onSelect(doc) }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.lmPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
                .background(Color.lmPrimary.opacity(0.02))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

struct DocumentCategoryBadge: View {
    let category: String
    
    var color: Color {
        switch category {
        case "Evidence": return .blue
        case "Contract": return .purple
        case "Court Order": return .orange
        case "Identity": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        Text(category)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Review Sheet
struct ReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    let appointment: FBAppointment
    
    @State private var rating: Int = 5
    @State private var reviewText: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Rate your Experience")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Text("How was your consultation with \(appointment.lawyerName)?")
                            .font(.system(size: 16))
                            .foregroundColor(.lmTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Star Rating
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(index <= rating ? .orange : .gray.opacity(0.3))
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        rating = index
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Feedback text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Feedback")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        TextEditor(text: $reviewText)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Submit Button
                    Button {
                        submitReview()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit Review")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(isSubmitting || reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitReview() {
        guard let currentUser = auth.currentUser else { return }
        isSubmitting = true
        
        let review = FBReview(
            lawyerId: appointment.lawyerId,
            clientId: currentUser.id,
            clientName: currentUser.fullName,
            clientImage: currentUser.profileImage,
            rating: rating,
            reviewText: reviewText,
            timestamp: Date()
        )
        
        firestore.addReview(review) { success in
            isSubmitting = false
            if success {
                ToastManager.shared.show(title: "Success", message: "Thank you for your feedback!", type: .success)
                dismiss()
            } else {
                ToastManager.shared.show(title: "Error", message: "Failed to submit review. Please try again.", type: .error)
            }
        }
    }
}


// MARK: - Lawyer Referral Picker
struct LawyerReferralPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    var onSelect: (User) -> Void
    
    @State private var searchText = ""
    @State private var showSuggestions = false
    
    var filteredLawyers: [User] {
        let currentUserId = AuthService.shared.currentUser?.id ?? ""
        return firestore.lawyers.filter { lawyer in
            if lawyer.id == currentUserId { return false }
            
            let nameMatch = lawyer.fullName.lowercased().contains(searchText.lowercased())
            let specialtyMatch = lawyer.specialty?.lowercased().contains(searchText.lowercased()) ?? false
            return nameMatch || specialtyMatch
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.lmBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    LawMateTextField(icon: "magnifyingglass", placeholder: "Search by name or specialty...", text: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .onChange(of: searchText) { _, newValue in
                            showSuggestions = !newValue.isEmpty
                        }
                    
                    if showSuggestions {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if filteredLawyers.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "person.fill.questionmark")
                                            .font(.system(size: 40))
                                            .foregroundColor(.lmPrimary.opacity(0.2))
                                        Text("No colleagues found")
                                            .font(.lmBody)
                                            .foregroundColor(.lmTextSecondary)
                                    }
                                    .padding(.top, 40)
                                } else {
                                    ForEach(filteredLawyers) { lawyer in
                                        Button {
                                            onSelect(lawyer)
                                            dismiss()
                                        } label: {
                                            LawyerReferralRow(lawyer: lawyer)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(20)
                        }
                    } else {
                        // Empty state when not searching
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.lmPrimary.opacity(0.1))
                            Text("Type a name to find a colleague")
                                .font(.lmBody)
                                .foregroundColor(.lmTextSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Select Colleague")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            firestore.listenForLawyers()
        }
    }
}

struct LawyerReferralRow: View {
    let lawyer: User
    
    var body: some View {
        HStack(spacing: 16) {
            LawMateAvatar(url: lawyer.profileImage, name: lawyer.fullName, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(lawyer.fullName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                if let specialty = lawyer.specialty {
                    Text(specialty)
                        .font(.system(size: 12))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.lmPrimary.opacity(0.3))
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
