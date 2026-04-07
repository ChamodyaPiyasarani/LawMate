//
//  NavComponents.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Shared navigation button components:
//  - LawMateBackButton        — chevron left back navigation
//  - NotificationButton       — bell icon with optional badge count
//  - LawMateNavigationBar     — title bar with optional back + notification buttons
//

import SwiftUI

// MARK: - Back Button
struct LawMateBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 34, height: 34)
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lmTextPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

// MARK: - Notification Button
struct NotificationButton: View {
    var badgeCount: Int = 0
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 34, height: 34)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.lmPrimary)
                }

                if badgeCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                        Text("\(min(badgeCount, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Notifications\(badgeCount > 0 ? ", \(badgeCount) unread" : "")")
        .background(
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Reusable Navigation Bar
struct LawMateNavigationBar: View {
    var title: String = ""
    var showBack: Bool = false
    var showNotification: Bool = false
    var notificationCount: Int = 0
    var onBack: () -> Void = {}
    var onNotification: () -> Void = {}

    var body: some View {
        HStack {
            if showBack {
                LawMateBackButton(action: onBack)
            }
            Spacer()
            if !title.isEmpty {
                Text(title)
                    .font(.lmHeading)
                    .foregroundColor(.lmPrimary)
            }
            Spacer()
            if showNotification {
                NotificationButton(badgeCount: notificationCount, action: onNotification)
            } else if showBack {
                Color.clear.frame(width: 34, height: 34)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

#Preview {
    VStack(spacing: 20) {
        LawMateBackButton(action: {})
        NotificationButton(badgeCount: 3, action: {})
        NotificationButton(badgeCount: 0, action: {})
        LawMateNavigationBar(title: "My Cases",
                              showBack: true,
                              showNotification: true,
                              notificationCount: 2,
                              onBack: {},
                              onNotification: {})
        .background(Color.lmBackground)
    }
    .padding()
    .background(Color.lmFieldBg)
}
