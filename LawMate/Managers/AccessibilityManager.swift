import SwiftUI
import Combine
import UIKit

public class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()
    
    private let authService = AuthService.shared
    
    @Published public var textScale: Double = 1.0
    @Published public var highContrast: Bool = false
    @Published public var systemHighContrast: Bool = UIAccessibility.isDarkerSystemColorsEnabled
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Sync with AuthService current user
        authService.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.textScale = user.textScale ?? 1.0
                self?.highContrast = user.highContrast ?? false
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.systemHighContrast = UIAccessibility.isDarkerSystemColorsEnabled
            }
            .store(in: &cancellables)
    }

    public var effectiveHighContrast: Bool {
        highContrast || systemHighContrast
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
