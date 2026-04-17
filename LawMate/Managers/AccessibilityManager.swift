import SwiftUI
import Combine

public class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()
    
    @ObservedObject private var authService = AuthService.shared
    
    @Published public var textScale: Double = 1.0
    @Published public var highContrast: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Sync with AuthService current user
        authService.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.textScale = user.textScale
                self?.highContrast = user.highContrast
            }
            .store(in: &cancellables)
    }
    
    /// Converts the user's scale (e.g. 1.5) to a SwiftUI DynamicTypeSize
    public var dynamicTypeSize: DynamicTypeSize {
        if textScale <= 1.0 { return .large } // Standard
        if textScale <= 1.15 { return .xLarge }
        if textScale <= 1.3 { return .xxLarge }
        if textScale <= 1.5 { return .xxxLarge }
        if textScale <= 1.7 { return .accessibility1 }
        return .accessibility3
    }
}
