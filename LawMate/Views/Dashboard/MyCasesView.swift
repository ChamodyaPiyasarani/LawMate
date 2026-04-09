import SwiftUI

struct ClientCase: Identifiable, Hashable {
    let id: String
    let lawyerName: String
    let description: String
    let category: String
    let method: String?
    let statusTitle: String
    let statusColorCategory: String // Helper to determine colors
    
    // Conform to Hashable for navigation
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ClientCase, rhs: ClientCase) -> Bool { lhs.id == rhs.id }
}

struct MyCasesView: View {
    @Environment(\.dismiss) private var dismiss
    
    let mockCases = [
        ClientCase(
            id: "C1",
            lawyerName: "Nimal Perera",
            description: "Defending a client accused of theft, ensuring fair trial and legal rights",
            category: "Criminal Law",
            method: nil,
            statusTitle: "Confirmed",
            statusColorCategory: "success"
        ),
        ClientCase(
            id: "C2",
            lawyerName: "Sanduni Fernando",
            description: "I need help with divorce and child custody arrangements legally.",
            category: "Family Law",
            method: "Video Call",
            statusTitle: "In Progress",
            statusColorCategory: "warning"
        )
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Green blob top-left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "My Case Details",
                    showBack: true,
                    showNotification: true,
                    notificationCount: 0,
                    onBack: { dismiss() },
                    onNotification: {}
                )
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(mockCases) { clientCase in
                            NavigationLink(value: clientCase) {
                                // Card View
                                MyCaseCard(clientCase: clientCase)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 120) // Give space for bottom nav
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Case Card Component
struct MyCaseCard: View {
    let clientCase: ClientCase
    
    var statusColor: Color {
        switch clientCase.statusColorCategory {
        case "success": return .green
        case "warning": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Avatar Placeholder
                ZStack {
                    Circle()
                        .fill(Color.lmPrimary.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.lmPrimary.opacity(0.7))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(clientCase.lawyerName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        // Status Badge
                        Text(clientCase.statusTitle)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Text(clientCase.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.lmPrimary.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
            }
            
            HStack {
                Text(clientCase.category)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.lmPrimary.opacity(0.7))
                
                Spacer()
                
                if let method = clientCase.method {
                    Text(method)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.lmPrimary.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    MyCasesView()
}
