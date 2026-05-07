import SwiftUI

struct LawyerHearingsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var auth: AuthService
    
    @State private var searchText = ""
    @State private var selectedTimeFrame = "Upcoming"
    
    private let timeFrames = ["Upcoming", "This Week", "Past"]
    
    var allHearings: [(case: FBLegalCase, hearing: FBHearingDate)] {
        var result: [(case: FBLegalCase, hearing: FBHearingDate)] = []
        for legalCase in firestore.cases {
            for hearing in legalCase.hearings {
                result.append((case: legalCase, hearing: hearing))
            }
        }
        return result.sorted { $0.hearing.date < $1.hearing.date }
    }
    
    var filteredHearings: [(case: FBLegalCase, hearing: FBHearingDate)] {
        allHearings.filter { item in
            let matchesSearch = searchText.isEmpty || 
                               item.case.clientName.localizedCaseInsensitiveContains(searchText) ||
                               item.hearing.location.localizedCaseInsensitiveContains(searchText) ||
                               item.hearing.notes.localizedCaseInsensitiveContains(searchText)
            
            let isUpcoming = item.hearing.date >= Calendar.current.startOfDay(for: Date())
            let matchesTimeFrame: Bool
            
            switch selectedTimeFrame {
            case "Upcoming":
                matchesTimeFrame = isUpcoming
            case "This Week":
                let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                matchesTimeFrame = item.hearing.date >= Date() && item.hearing.date <= weekEnd
            case "Past":
                matchesTimeFrame = !isUpcoming
            default:
                matchesTimeFrame = true
            }
            
            return matchesSearch && matchesTimeFrame
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            GreenBlobBackground(style: .lawyer)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    LawMateBackButton(action: { dismiss() })
                    
                    Spacer()
                    
                    Text("Court Hearings")
                        .font(.lmHeading)
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Circle().fill(.clear).frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 65)
                .zIndex(10)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Filters
                        VStack(spacing: 16) {
                            LawMateSearchBar(text: $searchText, placeholder: "Search client, court, or notes")
                            
                            HStack {
                                ForEach(timeFrames, id: \.self) { frame in
                                    FilterChip(title: frame, isSelected: selectedTimeFrame == frame) {
                                        selectedTimeFrame = frame
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                        
                        // Hearings List
                        VStack(spacing: 16) {
                            if filteredHearings.isEmpty {
                                emptyState
                            } else {
                                ForEach(0..<filteredHearings.count, id: \.self) { index in
                                    let item = filteredHearings[index]
                                    HearingRowCard(hearingItem: item)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Color.clear.frame(height: 120)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 48))
                .foregroundColor(.lmPrimary.opacity(0.1))
            Text("No hearings found")
                .font(.lmHeading)
                .foregroundColor(.lmPrimary.opacity(0.5))
            Text("Your courtroom schedule is clear.")
                .font(.lmCaption)
                .foregroundColor(.lmTextSecondary)
        }
        .padding(.vertical, 64)
    }
}

struct HearingRowCard: View {
    let hearingItem: (case: FBLegalCase, hearing: FBHearingDate)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(hearingItem.hearing.date))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text(formatTime(hearingItem.hearing.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                    Text(hearingItem.hearing.location)
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.lmPrimary.opacity(0.1))
                .foregroundColor(.lmPrimary)
                .clipShape(Capsule())
            }
            
            Divider().opacity(0.5)
            
            HStack(spacing: 12) {
                LawMateAvatar(url: hearingItem.case.clientImage, name: hearingItem.case.clientName, size: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(hearingItem.case.clientName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text(hearingItem.case.caseNumber)
                        .font(.system(size: 12))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.3))
            }
            
            if !hearingItem.hearing.notes.isEmpty {
                Text(hearingItem.hearing.notes)
                    .font(.system(size: 12))
                    .foregroundColor(.lmTextSecondary.opacity(0.8))
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM dd"
        return f.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f.string(from: date)
    }
}

#Preview {
    LawyerHearingsListView()
        .environmentObject(FirestoreManager.shared)
}
