//
//  ClientHomeView.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Screen 4 — Client Home (5. Clients - Home)
//  Green blob top-right, hero text, lawyer search card,
//  My Cases card, Document Templates card, custom tab bar.
//

import SwiftUI

struct ClientHomeView: View {
    @State private var selectedTab:  LawMateTab = .home
    @State private var searchQuery:  String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.lmBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if selectedTab == .home {
                    // MARK: Home Content
                    ScrollView(showsIndicators: false) {
                        ZStack(alignment: .topTrailing) {
                            // Green blob top-left (Client Style)
                            GreenBlobBackground(style: .client)
                                .frame(height: 300)

                            VStack(alignment: .leading, spacing: 32) {
                                // MARK: Top bar
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Welcome to LawMate !")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.lmPrimary)

                                        // Hero text — two-tone
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("Justice,")
                                                .font(.lmHero)
                                                .foregroundColor(.lmPrimary)
                                            Text("Refined.")
                                                .font(.lmHero)
                                                .foregroundColor(.lmTextSecondary.opacity(0.5))
                                        }
                                    }
                                    Spacer()
                                    NotificationButton(badgeCount: 0)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 64)

                                // MARK: Find My Lawyer card
                                FindLawyerCard(searchQuery: $searchQuery)
                                    .padding(.horizontal, 24)

                                // MARK: My Cases card
                                HomeFeatureCard(
                                    title: "My Cases",
                                    description: "Detailed Breakthroughs On Current Legislation And Your Rights In The Modern World.",
                                    imageName: "doc.text.fill",
                                    imageOnLeft: false
                                )
                                .padding(.horizontal, 24)

                                // MARK: Document Templates card
                                HomeFeatureCard(
                                    title: "Document Templates",
                                    description: "Standard Contracts, NDAs, And More. Ready For Signature.",
                                    imageName: "doc.on.doc.fill",
                                    imageOnLeft: true
                                )
                                .padding(.horizontal, 24)

                                // Bottom padding for TabBar
                                Color.clear.frame(height: 120)
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                } else if selectedTab == .lawyers {
                    // MARK: Lawyers Content
                    LawyersListView()
                } else {
                    // Placelolder for other tabs
                    VStack {
                        Spacer()
                        Image(systemName: selectedTab.icon)
                            .font(.system(size: 80))
                            .foregroundColor(.lmPrimary.opacity(0.1))
                        Text("\(selectedTab.title) Screen\nComing Soon")
                            .font(.lmHeading)
                            .foregroundColor(.lmTextSecondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // MARK: Global Tab Bar
            VStack {
                Spacer()
                TabBarView(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// BlobTopRight is removed in favor of GreenBlobBackground(style: .client)

// MARK: - Find Lawyer search card
private struct FindLawyerCard: View {
    @Binding var searchQuery: String

    var body: some View {
        VStack(spacing: 16) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.lmTextSecondary)
                TextField("Search by name or specialization...", text: $searchQuery)
                    .font(.lmField)
                    .foregroundColor(.lmTextPrimary)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )

            // CTA button
            Button {
                // Navigate to lawyers list
            } label: {
                HStack {
                    Spacer()
                    Text("Find My Lawyer →")
                        .font(.lmButton)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.lmPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(24) // Increased padding
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30)) // Increased radius
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Home feature card (My Cases / Document Templates)
private struct HomeFeatureCard: View {
    let title: String
    let description: String
    let imageName: String
    let imageOnLeft: Bool

    var body: some View {
        Button {
            // Navigate to feature
        } label: {
            HStack(alignment: .center, spacing: 16) {
                if imageOnLeft {
                    featureIcon
                }

                VStack(alignment: imageOnLeft ? .trailing : .leading, spacing: 6) {
                    Text(title)
                        .font(.lmHeading)
                        .foregroundColor(.lmPrimary)
                        .multilineTextAlignment(imageOnLeft ? .trailing : .leading)

                    Text(description)
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary.opacity(0.7))
                        .multilineTextAlignment(imageOnLeft ? .trailing : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: imageOnLeft ? .trailing : .leading)

                if !imageOnLeft {
                    featureIcon
                }
            }
            .padding(24) // Increased padding
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30)) // More rounded corners to match images
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var featureIcon: some View {
        Image(systemName: imageName)
            .font(.system(size: 80)) // Much larger icon
            .foregroundColor(Color.lmPrimary.opacity(0.05)) // Very low opacity for background effect
            .overlay(
                Image(systemName: imageName)
                    .font(.system(size: 24))
                    .foregroundColor(Color.lmPrimary.opacity(0.4))
            )
    }
}

#Preview {
    ClientHomeView()
}
