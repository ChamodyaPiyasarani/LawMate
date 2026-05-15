import SwiftUI

public enum ToastType {
    case info
    case success
    case warning
    case error
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

public struct Toast: Equatable {
    public var title: String
    public var message: String?
    public var type: ToastType
    public var duration: TimeInterval = 10
    
    public static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message && lhs.type == rhs.type
    }
}

public class ToastManager: ObservableObject {
    public static let shared = ToastManager()
    
    @Published public var currentToast: Toast?
    @Published public var isShowing: Bool = false
    
    private var dismissWorkItem: DispatchWorkItem?
    
    private init() {}
    
    public func show(title: String, message: String? = nil, type: ToastType, duration: TimeInterval = 10) {
        // Cancel any pending dismiss
        dismissWorkItem?.cancel()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.currentToast = Toast(title: title, message: message, type: type, duration: duration)
            self.isShowing = true
        }
        
        // Schedule new dismiss
        let task = DispatchWorkItem { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self?.isShowing = false
            }
        }
        dismissWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
    
    public func dismiss() {
        dismissWorkItem?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isShowing = false
        }
    }
}

public struct ToastView: View {
    @ObservedObject public var manager = ToastManager.shared
    
    
    public var body: some View {
        VStack {
            if manager.isShowing, let toast = manager.currentToast {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: toast.type.icon)
                        .foregroundColor(toast.type.color)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(toast.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let message = toast.message {
                            Text(message)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    
                    Button {
                        manager.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
                .padding(.top, safeAreaTop)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    manager.dismiss()
                }
                // Gesture for Swipe up to dismiss
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.height < 0 {
                                manager.dismiss()
                            }
                        }
                )
            }
            Spacer()
        }
        .zIndex(999)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.isShowing)
    }
    
    private var safeAreaTop: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let safeArea = windowScene.windows.first?.safeAreaInsets.top {
            return safeArea > 0 ? safeArea : 20
        }
        return 20
    }
}
