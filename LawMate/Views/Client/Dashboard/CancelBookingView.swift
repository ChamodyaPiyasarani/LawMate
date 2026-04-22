import SwiftUI

struct CancelBookingView: View {
    let appointment: FBAppointment
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String? = nil
    @State private var otherReason: String = ""
    @State private var isCancelling = false
    
    let cancellationReasons = [
        "I have a scheduling conflict",
        "I found another lawyer",
        "My legal issue was resolved",
        "The consultation fee is too high",
        "Other"
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "Cancel Appointment",
                    showBack: true,
                    onBack: { dismiss() }
                )
                .padding(.top, 64)
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        Text("Please select a reason for cancellation:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.lmTextSecondary)
                            .padding(.top, 20)
                        
                        // MARK: Reasons List
                        VStack(spacing: 12) {
                            ForEach(cancellationReasons, id: \.self) { reason in
                                Button {
                                    selectedReason = reason
                                } label: {
                                    HStack {
                                        Text(reason)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.lmPrimary)
                                        
                                        Spacer()
                                        
                                        ZStack {
                                            Circle()
                                                .stroke(Color.lmPrimary.opacity(0.3), lineWidth: 1)
                                                .frame(width: 20, height: 20)
                                            
                                            if selectedReason == reason {
                                                Circle()
                                                    .fill(Color.lmPrimary)
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedReason == reason ? Color.lmPrimary : Color.clear, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if selectedReason == "Other" {
                            TextField("Please specify...", text: $otherReason)
                                .font(.system(size: 14))
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // MARK: Important Notice
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Important Notice")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                            }
                            
                            Text("Cancellations made less than 24 hours before the appointment may be subject to a fee according to our terms of service.")
                                .font(.system(size: 13))
                                .foregroundColor(.lmTextSecondary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Spacer(minLength: 40)
                        
                        // MARK: Confirm Action
                        Button {
                            guard let appointmentId = appointment.id else {
                                ToastManager.shared.show(title: "Cancellation Failed", message: "Appointment not found.", type: .error)
                                return
                            }
                            isCancelling = true
                            FirestoreManager.shared.deleteAppointment(id: appointmentId) { success in
                                DispatchQueue.main.async {
                                    isCancelling = false
                                    if success {
                                        dismiss()
                                    } else {
                                        ToastManager.shared.show(title: "Cancellation Failed", message: "We couldn't cancel this appointment. Please try again.", type: .error)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if isCancelling {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Confirm Cancellation")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .background(selectedReason == nil || isCancelling ? Color.gray : Color.red)
                            .clipShape(Capsule())
                            .shadow(color: selectedReason == nil || isCancelling ? .clear : Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(selectedReason == nil || isCancelling)
                        .buttonStyle(.plain)
                        .padding(.bottom, 120) // Moved significantly higher to avoid tab bar
                    }
                    .padding(.horizontal, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    CancelBookingView(appointment: FBAppointment(
        clientId: "C1",
        clientName: "Client",
        lawyerId: "L1",
        lawyerName: "Lawyer",
        service: "Consultation",
        date: Date(),
        time: "09:00 AM",
        method: "Video Call",
        description: "",
        status: "Confirmed"
    ))
}
