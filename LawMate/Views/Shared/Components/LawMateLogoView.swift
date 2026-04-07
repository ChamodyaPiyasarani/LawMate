//
//  LawMateLogoView.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Reusable brand header: scales icon + "Legal & Professional Assistant" + "LAWMATE"
//

import SwiftUI

enum LogoStyle {
    case compact   // Small inline version (auth screen header)
    case large     // Big centered version (splash screen)
}

struct LawMateLogoView: View {
    var style: LogoStyle = .compact

    var body: some View {
        switch style {
        case .compact:
            compactLogo
        case .large:
            largeLogo
        }
    }

    // MARK: - Compact (used in auth screen headers)
    private var compactLogo: some View {
        HStack(spacing: 10) {
            AppLogoView(size: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text("Legal & Professional Assistant")
                    .font(.lmTagline)
                    .foregroundColor(.lmAccent)
                Text("LAWMATE")
                    .font(.lmBrand)
                    .foregroundColor(.lmPrimary)
            }
        }
    }

    // MARK: - Large (used on splash screen)
    private var largeLogo: some View {
        VStack(spacing: 16) {
            AppLogoView(size: 110)
            VStack(spacing: 4) {
                Text("Legal & Professional Assistant")
                    .font(.lmBody)
                    .foregroundColor(.lmAccent)
                Text("LAWMATE")
                    .font(Font.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.lmPrimary)
            }
        }
    }
}

// MARK: - Application Logo View
/// Displays the custom "AppLogo" image asset.
struct AppLogoView: View {
    let size: CGFloat

    var body: some View {
        Image("AppLogo") // Uses the user-provided image asset
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview("Compact") {
    LawMateLogoView(style: .compact)
        .padding()
}

#Preview("Large") {
    LawMateLogoView(style: .large)
        .padding()
}
