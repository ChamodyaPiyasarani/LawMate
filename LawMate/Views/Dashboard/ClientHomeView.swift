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
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.lmBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: Scrollable content
                    ScrollView(showsIndicators: false) {
                        ZStack(alignment: .topTrailing) {
                            // Green blob top-right
                            BlobTopRight()

                            VStack(alignment: .leading, spacing: 28) {

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
                                                .foregroundColor(Color.lmTextSecondary.opacity(0.3))
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

                                // Bottom padding so content doesn't sit behind tab bar
                                Color.clear.frame(height: 100)
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }

                // MARK: Tab bar overlay
                VStack(spacing: 0) {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Green blob positioned top-right
private struct BlobTopRight: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.lmLightGreen.opacity(0.40))
                    .frame(width: geo.size.width * 1.4)
                    .offset(x: geo.size.width * 0.4, y: -geo.size.width * 0.4)
                Circle()
                    .fill(Color.lmLightGreen.opacity(0.20))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.1, y: -geo.size.width * 0.1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(height: 350)
        .allowsHitTesting(false)
    }
}

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
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
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
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var featureIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.2))
                .frame(width: 64, height: 64)
            Image(systemName: imageName)
                .font(.system(size: 24))
                .foregroundColor(Color.lmPrimary.opacity(0.4))
        }
    }
}

#Preview {
    ClientHomeView()
}
