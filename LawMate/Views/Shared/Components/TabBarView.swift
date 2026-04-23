//
//  TabBarView.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Custom bottom tab bar matching the design screenshot:
//  Home | Lawyers | Booking | Messages | Profile
//

import SwiftUI

// MARK: - Tab items
enum LawMateTab: String, CaseIterable {
    case home, lawyers, booking, cases, calendar, messages, profile

    func title(for role: UserRole) -> String {
        switch self {
        case .home:     return "Home"
        case .lawyers:  return "Lawyers"
        case .booking:  return "Booking"
        case .cases:    return "Cases"
        case .calendar: return "Calendar"
        case .messages: return "Messages"
        case .profile:  return "Profile"
        }
    }

    func icon(for role: UserRole) -> String {
        switch self {
        case .home:     return "house.fill"
        case .lawyers:  return "briefcase.fill"
        case .booking:  return "calendar.badge.clock"
        case .cases:    return "briefcase.fill"
        case .calendar: return "calendar"
        case .messages: return "bubble.left.fill"
        case .profile:  return "person.fill"
        }
    }
    
    static func tabs(for role: UserRole) -> [LawMateTab] {
        if role == .lawyer {
            return [.home, .cases, .calendar, .messages, .profile]
        } else {
            return [.home, .lawyers, .booking, .messages, .profile]
        }
    }
}

// MARK: - Tab Bar View
struct TabBarView: View {
    @Binding var selectedTab: LawMateTab
    var role: UserRole = .client
    @StateObject private var firestore = FirestoreManager.shared

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LawMateTab.tabs(for: role), id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.lmPrimary.opacity(0.15))
                                    .frame(width: 44, height: 44)
                            }
                            Image(systemName: tab.icon(for: role))
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? .lmPrimary : .lmTextSecondary)
                                .overlay(
                                    Group {
                                        if tab == .messages && firestore.unreadChatCount > 0 {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 16, height: 16)
                                                Text("\(min(firestore.unreadChatCount, 99))")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .offset(x: 10, y: -10)
                                        }
                                    }
                                )
                        }

                        Text(tab.title(for: role))
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? .lmPrimary : .lmTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20) // Floating padding from bottom
    }
}

#Preview {
    VStack {
        Spacer()
        TabBarView(selectedTab: .constant(.home), role: .client)
    }
    .background(Color.lmBackground)
}
