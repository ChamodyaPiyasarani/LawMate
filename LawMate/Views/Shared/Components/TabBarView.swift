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
enum LawMateTab: Int, CaseIterable {
    case home, lawyers, booking, messages, profile

    var title: String {
        switch self {
        case .home:     return "Home"
        case .lawyers:  return "Lawyers"
        case .booking:  return "Booking"
        case .messages: return "Messages"
        case .profile:  return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .lawyers:  return "scalemass"
        case .booking:  return "calendar.badge.checkmark"
        case .messages: return "bubble.left"
        case .profile:  return "person"
        }
    }
}

// MARK: - Tab Bar View
struct TabBarView: View {
    @Binding var selectedTab: LawMateTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LawMateTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: selectedTab == tab ? .bold : .regular))
                            .foregroundColor(selectedTab == tab ? .lmPrimary : .lmTextSecondary)

                        Text(tab.title)
                            .font(.lmTab)
                            .foregroundColor(selectedTab == tab ? .lmPrimary : .lmTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        // Active indicator capsule behind icon (Home tab in screenshot)
                        selectedTab == tab
                        ? Color.lmPaleMint
                        : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -4)
        )
    }
}

#Preview {
    VStack {
        Spacer()
        TabBarView(selectedTab: .constant(.home))
    }
    .background(Color.lmBackground)
}
