//
//  LawyersListView.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//

import SwiftUI

struct Lawyer: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let bio: String
    let rating: Double
    let location: String
    let image: String
}

struct LawyersListView: View {
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    let lawyers = [
        Lawyer(name: "Nimal Perera", specialty: "Criminal Law", bio: "Experienced criminal lawyer handling complex court cases", rating: 4.8, location: "Colombo, Sri Lanka", image: "person.fill"),
        Lawyer(name: "Sanduni Fernando", specialty: "Family Law", bio: "Family law specialist focusing on divorce and custody", rating: 4.6, location: "Gampaha, Sri Lanka", image: "person.fill"),
        Lawyer(name: "Ravindu Silva", specialty: "Corporate Law", bio: "Corporate lawyer advising businesses on legal compliance matters", rating: 4.7, location: "Kandy, Sri Lanka", image: "person.fill"),
        Lawyer(name: "Ishara Jayasinghe", specialty: "Property Law", bio: "Property law expert handling land disputes and documentation", rating: 4.4, location: "Negombo, Sri Lanka", image: "person.fill"),
        Lawyer(name: "Tharindu Wijeshinghe", specialty: "Civil Law", bio: "Civil litigation lawyer representing clients in legal disputes", rating: 4.6, location: "Galle, Sri Lanka", image: "person.fill")
    ]

    var filteredLawyers: [Lawyer] {
        if searchText.isEmpty { return lawyers }
        return lawyers.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.specialty.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Client style blob on the left
            GreenBlobBackground(style: .client)
                .frame(height: 300)
            
            VStack(spacing: 0) {
                // MARK: Custom Header
                HStack {
                    LawMateBackButton {
                        // In a real app, this might go back or switch tab
                    }
                    
                    Spacer()
                    
                    Text("Find Your Lawyer")
                        .font(.lmHeading)
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    NotificationButton(badgeCount: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // MARK: Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.lmTextSecondary)
                    TextField("Search", text: $searchText)
                        .font(.lmField)
                }
                .padding()
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.top, 30)
                
                // MARK: Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterPill(icon: "line.3.horizontal.decrease.circle.fill", title: "Category")
                        FilterPill(icon: "star.fill", title: "Rate")
                        FilterPill(icon: "scope", title: "Location")
                        FilterPill(icon: "mappin.and.ellipse", title: "Map")
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                
                // MARK: Lawyers List
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(filteredLawyers) { lawyer in
                            LawyerRow(lawyer: lawyer)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 120) // Space for TabBar
                }
            }
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(title)
                .font(.lmCaption.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .foregroundColor(.lmPrimary)
    }
}

// MARK: - Lawyer Row Card
struct LawyerRow: View {
    let lawyer: Lawyer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Image Placeholder
                ZStack {
                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.5))
                        .frame(width: 70, height: 70)
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.lmPrimary.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(lawyer.name)
                            .font(.lmHeading)
                            .foregroundColor(.lmPrimary)
                        
                        Spacer()
                        
                        Text(lawyer.specialty)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.lmPrimary.opacity(0.8))
                    }
                    
                    Text(lawyer.bio)
                        .font(.lmCaption)
                        .foregroundColor(.lmTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(String(format: "%.1f", lawyer.rating))
                        .font(.lmCaption.weight(.bold))
                        .foregroundColor(.lmTextPrimary)
                }
                
                Spacer()
                
                Text(lawyer.location)
                    .font(.lmCaption.weight(.semibold))
                    .foregroundColor(.lmPrimary.opacity(0.7))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    LawyersListView()
}
