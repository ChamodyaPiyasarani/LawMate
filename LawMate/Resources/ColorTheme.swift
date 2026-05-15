//
//  ColorTheme.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//

import SwiftUI

// MARK: - LawMate Color Design Tokens
// MARK: - LawMate Color Design Tokens
extension Color {
    // Primary brand green (dark) — buttons, active states, logo
    static var lmPrimary: Color {
        AccessibilityManager.shared.effectiveHighContrast ? Color(hex: "#000000") : Color(hex: "#1A4731")
    }
    
    // Medium green — secondary accents
    static var lmAccent: Color {
        AccessibilityManager.shared.effectiveHighContrast ? Color(hex: "#000000") : Color(hex: "#2D6A4F") 
    }
    
    // Soft light green — background blobs, cards
    static var lmLightGreen: Color {
        AccessibilityManager.shared.effectiveHighContrast ? Color(hex: "#E6E6E6") : Color(hex: "#C8EDDA")
    }
    
    // Very pale green — wash backgrounds
    static var lmPaleMint: Color {
        AccessibilityManager.shared.effectiveHighContrast ? Color(hex: "#F7F7F7") : Color(hex: "#EEF8F2")
    }
    
    // Pure white — screen backgrounds
    static var lmBackground: Color {
        Color(hex: "#FFFFFF")
    }
    
    // Input field fill
    static var lmFieldBg: Color {
        AccessibilityManager.shared.effectiveHighContrast ? Color(hex: "#FFFFFF") : Color(hex: "#F0F0F0")
    }
    
    // Primary text
    static var lmTextPrimary: Color {
        Color(hex: "#000000") // Always black for primary text in LawMate
    }
    
    // Secondary / muted text
    static var lmTextSecondary: Color {
        AccessibilityManager.shared.effectiveHighContrast ? Color(hex: "#1A1A1A") : Color(hex: "#8A8A8A")
    }
    
    // Divider / border
    static var lmBorder: Color {
        AccessibilityManager.shared.effectiveHighContrast ? Color(hex: "#4A4A4A") : Color(hex: "#E0E0E0")
    }
}

// MARK: - Hex color initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
