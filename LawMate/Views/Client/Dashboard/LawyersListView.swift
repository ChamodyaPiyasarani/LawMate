import SwiftUI
import MapKit

struct Lawyer: Identifiable, Hashable {
    let id: String
    let name: String
    let specialty: String
    let bio: String
    let description: String
    let experience: String
    let experienceYears: Int // For sorting
    let casesWon: String
    let wonCount: Int // For sorting
    let rating: Double
    let location: String
    let image: String
    let coordinate: CLLocationCoordinate2D
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Lawyer, rhs: Lawyer) -> Bool { lhs.id == rhs.id }
}

enum SortingOption: String, CaseIterable {
    case alphabetical = "Name (A-Z)"
    case casesWon = "Most Cases Won"
    case experience = "Most Experience"
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
    @State private var sortOption: SortingOption = .alphabetical
    @State private var showSuggestions = false
    
    private var suggestions: [String] {
        if searchText.isEmpty { return [] }
        var combined: [String] = []
        
        let matchesNames = lawyers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.map { $0.name }
        let matchesSpecialties = allSpecialties.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        combined.append(contentsOf: matchesNames)
        combined.append(contentsOf: matchesSpecialties)
        
        return Array(Set(combined)).prefix(5).sorted()
    }
    
    // Mock user location for routing
    private let userLocation = CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8773)
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    )
    
    @Environment(\.dismiss) private var dismiss
    
    private let allSpecialties = ["Family Law", "Criminal Law", "Civil Law", "Business Law"]
    private let allLocations = ["Colombo", "Gampaha", "Kandy", "Negombo", "Galle"]

    var lawyers: [Lawyer] {
        firestore.lawyers.map { user in
            // Parse experience and cases won for sorting
            let expValue = Int(user.experience?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
            let wonValue = Int(user.casesWon?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
            
            return Lawyer(
                id: user.id,
                name: user.fullName,
                specialty: user.specialty ?? "General Practice",
                bio: user.bio ?? "Professional Lawyer",
                description: user.bio ?? "",
                experience: user.experience ?? "5 YEARS",
                experienceYears: expValue,
                casesWon: user.casesWon ?? "0",
                wonCount: wonValue,
                rating: 4.8, // Default rating for now
                location: "Colombo, Sri Lanka",
                image: user.profileImage ?? "",
                coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
            )
        }
    }

    var filteredLawyers: [Lawyer] {
        let filtered = lawyers.filter { lawyer in
            let matchesSearch = searchText.isEmpty || 
                               lawyer.name.localizedCaseInsensitiveContains(searchText) || 
                               lawyer.specialty.localizedCaseInsensitiveContains(searchText) ||
                               lawyer.bio.localizedCaseInsensitiveContains(searchText)
            
            let matchesSpecialty = selectedSpecialty == nil || lawyer.specialty.contains(selectedSpecialty!)
            let matchesRating = lawyer.rating >= minRating
            let matchesLocation = selectedLocation == nil || lawyer.location.contains(selectedLocation!)
            
            return matchesSearch && matchesSpecialty && matchesRating && matchesLocation
        }
        
        switch sortOption {
        case .alphabetical:
            return filtered.sorted { $0.name < $1.name }
        case .casesWon:
            return filtered.sorted { $0.wonCount > $1.wonCount }
        case .experience:
            return filtered.sorted { $0.experienceYears > $1.experienceYears }
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
                    
                    NotificationButton()
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .zIndex(10)
                
                // MARK: Search Bar
                VStack(spacing: 0) {
                    LawMateSearchBar(text: $searchText, placeholder: "Search lawyers or legal fields")
                        .onChange(of: searchText) { _, newValue in
                            showSuggestions = !newValue.isEmpty && !suggestions.isEmpty
                        }
                    
                    if showSuggestions {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    searchText = suggestion
                                    showSuggestions = false
                                } label: {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 12))
                                            .foregroundColor(.lmPrimary.opacity(0.3))
                                        Text(suggestion)
                                            .font(.system(size: 14))
                                            .foregroundColor(.lmPrimary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                                
                                if suggestion != suggestions.last {
                                    Divider().padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                        .padding(.top, 4)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .zIndex(100) // Ensure suggestions are above EVERYTHING
                
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
                    
                    // Sorting Dropdown
                    Menu {
                        ForEach(SortingOption.allCases, id: \.self) { option in
                            Button(option.rawValue) { sortOption = option }
                        }
                    } label: {
                        FilterPill(icon: "arrow.up.arrow.down", 
                                  title: sortOption.rawValue, 
                                  isActive: sortOption != .alphabetical,
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
                .padding(.bottom, 12)
                .zIndex(1)
                
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                LawMateAvatar(url: lawyer.image, name: lawyer.name, size: 64)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center) {
                        Text(lawyer.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .lineLimit(1)
                        
                        Spacer(minLength: 8)
                        
                        HStack(spacing: 4) {
                            let spec = lawyer.specialty.lowercased()
                            let icon = spec.contains("family") ? "house.fill" : 
                                      spec.contains("criminal") ? "gavel.fill" : 
                                      spec.contains("civil") ? "person.2.fill" : "briefcase.fill"
                            
                            Image(systemName: icon)
                                .font(.system(size: 10))
                            Text(lawyer.specialty)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.lmPrimary.opacity(0.1))
                        .foregroundColor(.lmPrimary)
                        .clipShape(Capsule())
                        .layoutPriority(1)
                    }
                    
                    Text(lawyer.bio)
                        .font(.system(size: 13))
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text(String(format: "%.1f", lawyer.rating))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    Text("(120+ Reviews)")
                        .font(.system(size: 10))
                        .foregroundColor(.lmTextSecondary.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                Label(lawyer.location, systemImage: "mappin.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.lmPrimary.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    LawyersListView()
}
