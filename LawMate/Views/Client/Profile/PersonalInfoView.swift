import SwiftUI
import CoreLocation

struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var auth: AuthService
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var specialty = ""
    @State private var experience = ""
    @State private var bio = ""
    @State private var address = ""
    
    // Validation Errors
    @State private var fullNameError: String?
    @State private var phoneError: String?
    
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
                        ProfileInputRow(icon: "person.fill", title: "Full Name", text: $fullName, errorMessage: fullNameError)
                        ProfileInputRow(icon: "envelope.fill", title: "Email Address", text: $email)
                            .disabled(true)
                            .opacity(0.6)
                        ProfileInputRow(icon: "phone.fill", title: "Phone Number", text: $phone, errorMessage: phoneError)
                        ProfileInputRow(icon: "mappin.and.ellipse", title: "Address", text: $address)
                        
                        if auth.currentUser?.role == .lawyer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Professional Details")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                    .padding(.leading, 8)
                                
                                ProfileInputRow(icon: "briefcase.fill", title: "Specialty", text: $specialty)
                                ProfileInputRow(icon: "star.fill", title: "Experience", text: $experience)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bio / Description")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.lmTextSecondary)
                                        .padding(.leading, 8)
                                    
                                    TextEditor(text: $bio)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.lmTextPrimary)
                                        .frame(height: 100)
                                        .padding(12)
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
                        
                        Button {
                            if validateForm() {
                                // Geocode before updating
                                geocodeAddress(address) { coordinate in
                                    auth.updateUserProfile(
                                        fullName: fullName,
                                        phoneNumber: phone,
                                        specialty: specialty.isEmpty ? nil : specialty,
                                        experience: experience.isEmpty ? nil : experience,
                                        bio: bio.isEmpty ? nil : bio,
                                        address: address,
                                        latitude: coordinate?.latitude,
                                        longitude: coordinate?.longitude
                                    )
                                    ToastManager.shared.show(title: "Profile Updated", message: "Your changes have been saved.", type: .success)
                                    dismiss()
                                }
                            } else {
                                ToastManager.shared.show(title: "Update Failed", message: "Please resolve the errors.", type: .error)
                            }
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
            .onAppear {
                if let user = auth.currentUser {
                    fullName = user.fullName
                    email = user.email
                    phone = user.phoneNumber
                    specialty = user.specialty ?? ""
                    experience = user.experience ?? ""
                    bio = user.bio ?? ""
                    address = user.address ?? ""
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            completion(placemarks?.first?.location?.coordinate)
        }
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        fullNameError = fullName.trimmingCharacters(in: .whitespaces).isEmpty ? "Full name is required" : nil
        if fullNameError != nil { isValid = false }
        
        phoneError = phone.count < 10 ? "Enter a valid phone number" : nil
        if phoneError != nil { isValid = false }
        
        return isValid
    }
}

struct ProfileInputRow: View {
    let icon: String
    let title: String
    @Binding var text: String
    var errorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.lmTextSecondary)
                .padding(.leading, 8)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(errorMessage != nil ? .red : .lmPrimary)
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
                    .stroke(errorMessage != nil ? Color.red : Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.leading, 12)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }
}

#Preview {
    PersonalInfoView()
}
