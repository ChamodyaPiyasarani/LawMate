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
    var badgeCount: Int = 0
    var action: () -> Void = {}

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

                if badgeCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                        Text("\(min(badgeCount, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Notifications\(badgeCount > 0 ? ", \(badgeCount) unread" : "")")
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
    var notificationCount: Int = 0
    var onBack: () -> Void = {}
    var onNotification: () -> Void = {}
    var onCamera: () -> Void = {}

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
            
            if showNotification {
                NotificationButton(badgeCount: notificationCount, action: onNotification)
            } else if showCamera {
                CameraButton(action: onCamera)
            } else if showBack {
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
                              notificationCount: 2,
                              onBack: {},
                              onNotification: {})
        .background(Color.lmBackground)
    }
    .padding()
    .background(Color.lmFieldBg)
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
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Final sanity check for file size
        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = attr?[.size] as? Int64 ?? 0
        
        if size > 0 {
            if let data = try? Data(contentsOf: url) {
                pdfView.document = PDFDocument(data: data)
            } else {
                pdfView.document = PDFDocument(url: url)
            }
        }
        
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear 
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct PDFKitViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let document: AdvisoryDocument
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.lmBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let url = document.fileURL, FileManager.default.fileExists(atPath: url.path) {
                        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
                        let size = attr?[.size] as? Int64 ?? 0
                        
                        if size == 0 {
                            errorView(message: "The document file is empty (0 bytes). This usually happens if the upload was interrupted.")
                        } else {
                            let ext = url.pathExtension.lowercased()
                            if ["jpg", "jpeg", "png", "heic"].contains(ext) {
                                // Image Viewer
                                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .padding(.top, 20)
                                    } else {
                                        errorView(message: "Failed to parse image data.")
                                    }
                                }
                            } else {
                                // PDF Viewer
                                PDFKitView(url: url)
                                    .edgesIgnoringSafeArea(.bottom)
                            }
                        }
                    } else {
                        errorView(message: "Document file not found. Please try uploading it again.")
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
                    if document.fileURL != nil {
                        Button {
                            shareDocument()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(.lmPrimary.opacity(0.2))
            
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
    
    private func shareDocument() {
        guard let url = document.fileURL else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Timeline Component
struct TimelineNode: View {
    let index: Int
    let stage: CaseStage
    let isLast: Bool
    let isActive: Bool
    let canEdit: Bool
    var onToggle: () -> Void = {}
    var onUpload: () -> Void = {}
    
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
