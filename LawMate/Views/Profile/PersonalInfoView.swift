import SwiftUI

struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = "Emily"
    @State private var lastName = "Johnson"
    @State private var email = "emily.johnson@email.com"
    @State private var phone = "+94 77 123 4567"
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .client).frame(height: 300)
            
            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Personal Info", showBack: true, onBack: { dismiss() })
                    .padding(.top, 64)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ProfileInputRow(icon: "person.fill", title: "First Name", text: $firstName)
                        ProfileInputRow(icon: "person.fill", title: "Last Name", text: $lastName)
                        ProfileInputRow(icon: "envelope.fill", title: "Email Address", text: $email)
                        ProfileInputRow(icon: "phone.fill", title: "Phone Number", text: $phone)
                        
                        Button {
                            // Save action
                            dismiss()
                        } label: {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.lmPrimary)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ProfileInputRow: View {
    let icon: String
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lmTextSecondary)
                .padding(.leading, 8)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.lmPrimary)
                    .frame(width: 24)
                
                TextField(title, text: $text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.lmTextPrimary)
            }
            .padding(16)
            .background(Color.white.opacity(0.8))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    PersonalInfoView()
}
