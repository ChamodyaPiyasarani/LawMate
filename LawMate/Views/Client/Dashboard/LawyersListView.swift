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
    let reviewCount: Int
    let location: String
    let image: String
    let coordinate: CLLocationCoordinate2D
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Lawyer, rhs: Lawyer) -> Bool { lhs.id == rhs.id }
    
    var specialtyIcon: String {
        let spec = specialty.lowercased()
        if spec.contains("family") { return "house.fill" }
        if spec.contains("criminal") { return "building.columns.fill" }
        if spec.contains("civil") { return "person.2.fill" }
        if spec.contains("business") || spec.contains("corporate") { return "briefcase.fill" }
        return "briefcase.fill"
    }
}

enum SortingOption: String, CaseIterable {
    case alphabetical = "Name (A-Z)"
    case casesWon = "Most Cases Won"
    case experience = "Most Experience"
}

struct LawyersListView: View {
    var onBack: () -> Void = {}
    @EnvironmentObject var firestore: FirestoreManager
    @Binding var isTabBarHidden: Bool
    @State private var searchText = ""
    @State private var selectedSpecialty: String? = nil
    
    init(onBack: @escaping () -> Void = {}, isTabBarHidden: Binding<Bool> = .constant(false), initialSearchQuery: String = "") {
        self.onBack = onBack
        self._isTabBarHidden = isTabBarHidden
        self._searchText = State(initialValue: initialSearchQuery)
    }
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
    
    private let sriLankaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
        span: MKCoordinateSpan(latitudeDelta: 4.5, longitudeDelta: 4.5)
    )
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    )
    
    @Environment(\.dismiss) private var dismiss
    
    private var allSpecialties: [String] {
        let specs = firestore.lawyers.compactMap { $0.specialty }
        return Array(Set(specs)).sorted()
    }
    
    private var allLocations: [String] {
        let locs = firestore.lawyers.compactMap { user in
            user.address?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
        }
        return Array(Set(locs)).sorted()
    }

    var lawyers: [Lawyer] {
        firestore.lawyers.map { user in
            // Parse experience and cases won for sorting
            let expValue = Int(user.experience?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
            let wonValue = Int(user.casesWon?.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first ?? "0") ?? 0
            
            let lat = user.latitude ?? 6.9271
            let lng = user.longitude ?? 79.8612
            
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
                rating: user.rating ?? 0.0,
                reviewCount: user.reviewCount ?? 0,
                location: user.address ?? "Colombo, Sri Lanka",
                image: user.profileImage ?? "",
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
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
                .padding(.top, 65)
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
                
                // MARK: Filters (Horizontal Scrollable)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Category Dropdown
                        Menu {
                            Button("All Categories") { selectedSpecialty = nil }
                            ForEach(allSpecialties, id: \.self) { specialty in
                                Button(specialty) { selectedSpecialty = specialty }
                            }
                        } label: {
                            LawMateFilterPill(icon: "line.3.horizontal.decrease", 
                                      title: selectedSpecialty ?? "Category", 
                                      isActive: selectedSpecialty != nil) {}
                        }
                        
                        Menu {
                            Button("All Ratings") { minRating = 0 }
                            Button("4.5+ ★") { minRating = 4.5 }
                            Button("4.0+ ★") { minRating = 4.0 }
                            Button("3.0+ ★") { minRating = 3.0 }
                        } label: {
                            LawMateFilterPill(icon: "star.fill", 
                                      title: minRating > 0 ? "\(String(format: "%.1f", minRating))+" : "Rate", 
                                      isActive: minRating > 0) {}
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
                            LawMateFilterPill(icon: "scope", 
                                      title: selectedLocation ?? "Location", 
                                      isActive: selectedLocation != nil) {}
                        }
                        
                        // Sorting Dropdown
                        Menu {
                            ForEach(SortingOption.allCases, id: \.self) { option in
                                Button(option.rawValue) { sortOption = option }
                            }
                        } label: {
                            LawMateFilterPill(icon: "arrow.up.arrow.down", 
                                      title: sortOption.rawValue, 
                                      isActive: sortOption != .alphabetical) {}
                        }
                        
                        LawMateFilterPill(icon: "mappin.and.ellipse", 
                                   title: "Map", 
                                   isActive: isMapViewActive) {
                            withAnimation(.spring()) {
                                isMapViewActive.toggle()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                .zIndex(1)
                
                // MARK: Lawyers List OR Map
                ZStack {
                    if isMapViewActive {
                        Map(position: $cameraPosition, bounds: MapCameraBounds(maximumDistance: 1500000), selection: $selectedLawyerId) {
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
        .ignoresSafeArea(edges: .top)
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
        withAnimation(.easeInOut) {
            if let city = location {
                // Find all lawyers in this city
                let lawyersInCity = lawyers.filter { $0.location.contains(city) }
                if let first = lawyersInCity.first {
                    // Center on the first lawyer's coordinate
                    cameraPosition = .region(MKCoordinateRegion(
                        center: first.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            } else {
                // Reset to show entire country or current results
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
                    span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
                ))
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
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            HStack(alignment: .top, spacing: 16) {
                // Initial/Avatar Box
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.lmPrimary.opacity(0.05))
                        .frame(width: 56, height: 56)
                    
                    if !lawyer.image.isEmpty {
                        LawMateAvatar(url: lawyer.image, name: lawyer.name, size: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text(String(lawyer.name.prefix(2)).uppercased())
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.lmPrimary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(lawyer.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.22)) // Dark greenish
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Rating Badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 10))
                            Text(String(format: "%.1f", lawyer.rating))
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Text(lawyer.specialty)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            .padding(.bottom, 20)
            
            Divider()
                .background(Color.lmPrimary.opacity(0.05))
                .padding(.bottom, 16)
            
            // Footer Section
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 12))
                    Text(lawyer.experience)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.42))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.lmPrimary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                    Text(lawyer.location.components(separatedBy: ",").first ?? lawyer.location)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lmTextSecondary.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.lmTextSecondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    LawyersListView()
}
