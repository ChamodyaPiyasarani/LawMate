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
    var action: () -> Void = {}

    private var displayCount: Int {
        badgeCount ?? firestore.unreadNotificationsCount
    }

    var body: some View {
        Button(action: action) {
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
    @State private var showReschedulePicker = false
    
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
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                // Time (Left)
                VStack(spacing: 4) {
                    Text(appointment.time.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Rectangle()
                        .fill(Color.lmPrimary.opacity(0.2))
                        .frame(width: 2, height: 24)
                }
                .frame(width: 50)
                
                // Info (Center - Left Aligned)
                VStack(alignment: .leading, spacing: 4) {
                    let currentRole = auth.currentUser?.role ?? .client
                    let displayName = currentRole == .lawyer ? appointment.clientName : appointment.lawyerName
                    
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .lineLimit(1)
                        
                        if let specialty = appointment.lawyerSpecialty {
                            HStack(spacing: 4) {
                                Image(systemName: appointment.specialtyIcon)
                                    .font(.system(size: 8))
                                Text(specialty)
                                    .font(.system(size: 8, weight: .bold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.lmPrimary.opacity(0.1))
                            .foregroundColor(.lmPrimary)
                            .clipShape(Capsule())
                            .layoutPriority(1)
                        }
                    }
                    
                    Text(appointment.service)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(1)
                    
                    Text(appointment.description)
                        .font(.system(size: 11))
                        .foregroundColor(.lmTextSecondary.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                // Status & Method (Right)
                VStack(alignment: .trailing, spacing: 6) {
                    Text(appointment.statusTitle)
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appointment.statusColor.opacity(0.12))
                        .foregroundColor(appointment.statusColor)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(appointment.statusColor.opacity(0.3), lineWidth: 1))
                    
                    Image(systemName: appointment.method == "Video Call" ? "video.fill" : "building.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.lmPrimary.opacity(0.4))
                }
            }
            
            // Confirm/Reschedule/Reject Actions (Bidirectional)
            let currentUserId = auth.currentUser?.id ?? ""
            let isPendingOrRescheduled = appointment.status.lowercased() == "pending" || appointment.status.lowercased() == "rescheduled"
            let isRecipient = appointment.lastActionBy != currentUserId
            
            if isPendingOrRescheduled && isRecipient {
                HStack(spacing: 8) {
                    Button {
                        firestore.updateAppointmentStatus(appointmentId: appointment.id ?? "", status: "Confirmed") { success in
                            if success {
                                let targetUserId = (auth.currentUser?.role == .lawyer) ? appointment.clientId : appointment.lawyerId
                                let senderName = auth.currentUser?.fullName ?? "Someone"
                                let notification = FBNotification(
                                    title: "Appointment Confirmed",
                                    body: "\(senderName) has confirmed the appointment for \(appointment.time) on \(formatDate(appointment.date)).",
                                    type: "appointment",
                                    timestamp: Date(),
                                    relatedId: appointment.id
                                )
                                firestore.addNotification(notification, toUserId: targetUserId)
                            }
                        }
                    } label: {
                        Text("Confirm")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        showReschedulePicker = true
                    } label: {
                        Text("Reschedule")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        showRejectAlert = true
                    } label: {
                        Text("Reject")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .alert("Reject Appointment", isPresented: $showRejectAlert) {
            Button("Reject", role: .destructive) {
                confirmReject()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to reject this appointment request?")
        }
        .sheet(isPresented: $showReschedulePicker) {
            ReschedulePickerSheet(appointment: appointment)
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
        self._selectedDate = State(initialValue: appointment.date)
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
    var onNotification: () -> Void = {}
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
        .padding(.vertical, 10)
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
    
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    var onConfirm: (CLLocationCoordinate2D) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $mapCameraPosition) {}
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
                if let userLoc = locationManager.userLocation {
                    mapCameraPosition = .region(MKCoordinateRegion(center: userLoc, span: region.span))
                }
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
                        ProgressView("Preparing document...")
                            .frame(maxHeight: .infinity)
                    } else if let url = localURL {
                        let ext = url.pathExtension.lowercased()
                        if ["jpg", "jpeg", "png", "heic"].contains(ext) {
                            // Image Viewer
                            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                                Image(uiImage: UIImage(contentsOfFile: url.path) ?? UIImage())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 20)
                            }
                        } else {
                            // Document Viewer (PDF/DOCX)
                            PDFKitView(url: url)
                                .edgesIgnoringSafeArea(.bottom)
                        }
                    } else if let urlString = document.fileURL, let url = URL(string: urlString) {
                        // Fallback to URL if no Base64 (Old documents)
                        PDFKitView(url: url)
                            .edgesIgnoringSafeArea(.bottom)
                    } else {
                        errorView(message: "Document file not found. It may have been removed or is still uploading.")
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
                    } else if let urlString = document.fileURL, let url = URL(string: urlString) {
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
        // If we have Base64, decode it to a temp file
        if let base64 = document.fileBase64 {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = Data(base64Encoded: base64) {
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileName = document.title.replacingOccurrences(of: " ", with: "_") + "." + (document.fileType.lowercased())
                    let fileURL = tempDir.appendingPathComponent(fileName)
                    
                    try? data.write(to: fileURL)
                    
                    DispatchQueue.main.async {
                        self.localURL = fileURL
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async { self.isLoading = false }
                }
            }
        } else if let urlString = document.fileURL, let url = URL(string: urlString) {
            // Already a URL, just use it
            self.localURL = url
            self.isLoading = false
        } else {
            self.isLoading = false
        }
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


// MARK: - Timeline Component
struct TimelineNode: View {
    let index: Int
    let stage: FBCaseStage
    let isLast: Bool
    let isActive: Bool
    let canEdit: Bool
    var onToggle: () -> Void = {}
    var onUpload: () -> Void = {}
    var onDateChange: ((Date) -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Indicator line and circle
            VStack(spacing: 0) {
                ZStack {
                    if canEdit {
                        Button(action: onToggle) {
                            ZStack {
                                Circle()
                                    .fill(stage.isCompleted ? Color.lmPrimary : Color.white)
                                    .frame(width: 26, height: 26)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Circle()
                                    .stroke(stage.isCompleted ? Color.lmPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 26, height: 26)
                                
                                if stage.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
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
                    Button(action: onUpload) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.doc.fill")
                                .font(.system(size: 12))
                            Text("Upload Files")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.lmPrimary)
                        .clipShape(Capsule())
                        .shadow(color: Color.lmPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 4)
                }
                
                if !isLast {
                    Spacer().frame(height: canEdit ? 30 : 20)
                }
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
