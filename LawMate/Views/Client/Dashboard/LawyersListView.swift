import SwiftUI
import MapKit

struct Lawyer: Identifiable, Hashable {
    let id: String
    let name: String
    let specialty: String
    let bio: String
    let description: String
    let experience: String
    let casesWon: String
    let rating: Double
    let location: String
    let image: String
    let coordinate: CLLocationCoordinate2D
    
    // Conform to Hashable for navigation
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Lawyer, rhs: Lawyer) -> Bool { lhs.id == rhs.id }
}

struct LawyersListView: View {
    var onBack: () -> Void = {}
    @StateObject private var firestore = FirestoreManager.shared
    @State private var searchText = ""
    @State private var selectedSpecialty: String? = nil
    @State private var minRating: Double = 0.0
    @State private var selectedLocation: String? = nil
    @State private var isMapViewActive = false
    @State private var selectedLawyerId: String? = nil
    @State private var route: MKRoute? = nil
    
    // Mock user location for routing
    private let userLocation = CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8773)
    
    // Initial camera position centered on Sri Lanka
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    )
    
    @Environment(\.dismiss) private var dismiss
    
    private let allSpecialties = ["Criminal Law", "Family Law", "Corporate Law", "Property Law", "Civil Law"]
    private let allLocations = ["Colombo", "Gampaha", "Kandy", "Negombo", "Galle"]

    var lawyers: [Lawyer] {
        firestore.lawyers.map { user in
            Lawyer(
                id: user.id,
                name: user.fullName,
                specialty: user.specialty ?? "General Practice",
                bio: user.bio ?? "Professional Lawyer",
                description: user.bio ?? "",
                experience: user.experience ?? "5+ YEARS",
                casesWon: "N/A",
                rating: 4.5, // Default rating for now
                location: "Colombo, Sri Lanka", // Default location
                image: "person.fill",
                coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612) // Default coord
            )
        }
    }

    var filteredLawyers: [Lawyer] {
        lawyers.filter { lawyer in
            let matchesSearch = searchText.isEmpty || 
                               lawyer.name.localizedCaseInsensitiveContains(searchText) || 
                               lawyer.specialty.localizedCaseInsensitiveContains(searchText)
            
            let matchesSpecialty = selectedSpecialty == nil || lawyer.specialty == selectedSpecialty
            let matchesRating = lawyer.rating >= minRating
            let matchesLocation = selectedLocation == nil || lawyer.location.contains(selectedLocation!)
            
            return matchesSearch && matchesSpecialty && matchesRating && matchesLocation
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left (Client Style)
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header (Left-Aligned)
                HStack {
                    Text("Find Your Lawyer")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    NotificationButton(badgeCount: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .zIndex(10)
                
                // MARK: Search Bar
                LawMateSearchBar(text: $searchText, placeholder: "Search lawyers or legal fields")
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                
                // MARK: Filters (Fixed on one line - Full Width)
                HStack(spacing: 8) {
                    // Category Dropdown
                    Menu {
                        Button("All Categories") { selectedSpecialty = nil }
                        ForEach(allSpecialties, id: \.self) { specialty in
                            Button(specialty) { selectedSpecialty = specialty }
                        }
                    } label: {
                        FilterPill(icon: "line.3.horizontal.decrease", 
                                  title: selectedSpecialty ?? "Category", 
                                  isActive: selectedSpecialty != nil,
                                  maxWidth: .infinity) {}
                    }
                    
                    FilterPill(icon: "star.fill", 
                              title: minRating > 0 ? "\(String(format: "%.1f", minRating))+" : "Rate", 
                              isActive: minRating > 0,
                              maxWidth: .infinity) {
                        minRating = minRating == 0 ? 4.6 : 0
                    }
                    
                    // Location Dropdown
                    Menu {
                        Button("All Locations") { 
                            selectedLocation = nil 
                            updateMapForLocation(nil)
                        }
                        ForEach(allLocations, id: \.self) { location in
                            Button(location) { 
                                selectedLocation = location 
                                updateMapForLocation(location)
                            }
                        }
                    } label: {
                        FilterPill(icon: "scope", 
                                  title: selectedLocation ?? "Location", 
                                  isActive: selectedLocation != nil,
                                  maxWidth: .infinity) {}
                    }
                    
                    FilterPill(icon: "mappin.and.ellipse", 
                              title: "Map", 
                              isActive: isMapViewActive,
                              maxWidth: .infinity) {
                        withAnimation(.spring()) {
                            isMapViewActive.toggle()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12) // Added padding for spacing
                .zIndex(1) // Ensure filters are above map
                
                // MARK: Lawyers List OR Map
                ZStack {
                    if isMapViewActive {
                        Map(position: $cameraPosition, selection: $selectedLawyerId) {
                            // User Location Marker
                            Marker("You", systemImage: "person.circle.fill", coordinate: userLocation)
                                .tint(.blue)
                            
                            ForEach(filteredLawyers) { lawyer in
                                Annotation(lawyer.name, coordinate: lawyer.coordinate) {
                                    LawyerMapAnnotation(lawyer: lawyer)
                                        .onTapGesture {
                                            selectedLawyerId = lawyer.id
                                        }
                                }
                                .tag(lawyer.id)
                            }
                            
                            if let currentRoute = route {
                                MapPolyline(currentRoute)
                                    .stroke(Color.blue, lineWidth: 5)
                            }
                        }
                        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .overlay(alignment: .bottom) {
                            // Selection Info / View Profile Button
                            if let selectedId = selectedLawyerId,
                               let lawyer = lawyers.first(where: { $0.id == selectedId }) {
                                NavigationLink(value: lawyer) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(lawyer.name)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.lmPrimary)
                                            Text("Tap to View Details")
                                                .font(.system(size: 10))
                                                .foregroundColor(.lmTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.lmPrimary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    .padding(.bottom, 120) // Adjust for tab bar
                                    .padding(.horizontal, 24)
                                }
                                .buttonStyle(.plain)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(filteredLawyers) { lawyer in
                                    NavigationLink(value: lawyer) {
                                        LawyerRow(lawyer: lawyer)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 140) // Extra space for TabBar
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .onChange(of: searchText) { oldValue, newValue in
            // If search result identifies a single lawyer, center map on them
            if isMapViewActive && filteredLawyers.count == 1 {
                updateMapForLocation(filteredLawyers[0].location.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces))
            }
        }
        .onChange(of: selectedLawyerId) { oldValue, newValue in
            if let newId = newValue, let lawyer = lawyers.first(where: { $0.id == newId }) {
                fetchRoute(to: lawyer)
            } else {
                route = nil
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            firestore.listenForLawyers()
        }
    }
    
    private func fetchRoute(to lawyer: Lawyer) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: lawyer.coordinate))
        request.transportType = .automobile
        
        Task {
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                await MainActor.run {
                    self.route = response.routes.first
                    // Adjust camera to show the route
                    if let polyline = response.routes.first?.polyline {
                        cameraPosition = .rect(polyline.boundingMapRect.padded())
                    }
                }
            } catch {
                print("Error calculating route: \(error)")
            }
        }
    }
    
    private func updateMapForLocation(_ location: String?) {
        let coordinates: [String: CLLocationCoordinate2D] = [
            "Colombo": CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            "Gampaha": CLLocationCoordinate2D(latitude: 7.0873, longitude: 79.9925),
            "Kandy": CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337),
            "Negombo": CLLocationCoordinate2D(latitude: 7.2089, longitude: 79.8354),
            "Galle": CLLocationCoordinate2D(latitude: 6.0535, longitude: 80.2210)
        ]
        
        withAnimation(.easeInOut) {
            if let city = location, let coord = coordinates[city] {
                cameraPosition = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)))
            } else {
                cameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718), span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)))
            }
        }
    }
}

// MARK: - Map Helpers
extension MKMapRect {
    func padded() -> MKMapRect {
        let paddingX = self.width * 0.15
        let paddingY = self.height * 0.15
        return self.insetBy(dx: -paddingX, dy: -paddingY)
    }
}

// MARK: - Custom Map Annotation
struct LawyerMapAnnotation: View {
    let lawyer: Lawyer
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.lmPrimary)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: 44, height: 44)
            
            Image(systemName: "briefcase.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(1.0)
    }
}


// MARK: - Lawyer Row Card
struct LawyerRow: View {
    let lawyer: Lawyer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                // Profile Image Placeholder
                ZStack {
                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.5))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.lmPrimary.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(lawyer.name)
                            .font(.system(size: 14, weight: .bold)) // Smaller and bold
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        Text(lawyer.specialty)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.lmPrimary.opacity(0.8))
                    }
                    
                    Text(lawyer.bio)
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(String(format: "%.1f", lawyer.rating))
                        .font(.lmCaption.weight(.bold))
                        .foregroundColor(.lmTextPrimary)
                }
                
                Spacer()
                
                Text(lawyer.location)
                    .font(.lmCaption.weight(.semibold))
                    .foregroundColor(.lmPrimary.opacity(0.7))
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
    LawyersListView()
}
