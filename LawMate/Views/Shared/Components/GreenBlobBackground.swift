//
//  GreenBlobBackground.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Decorative overlapping soft-green circles that appear in the
//  top portion of auth screens and the Home screen.
//

import SwiftUI

enum BlobStyle {
    case auth   // Side-by-side overlapping (Login/SignUp)
    case client // Left-aligned (Home/Other client screens)
}

struct GreenBlobBackground: View {
    var style: BlobStyle = .auth

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if style == .auth {
                    // Blob 1: Top-Left
                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.35))
                        .frame(width: geo.size.width * 1.2,
                               height: geo.size.width * 1.2)
                        .offset(x: -geo.size.width * 0.40,
                                y: -geo.size.width * 0.45)

                    // Blob 2: Top-Right
                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.20))
                        .frame(width: geo.size.width * 1.1,
                               height: geo.size.width * 1.1)
                        .offset(x: geo.size.width * 0.30,
                                y: -geo.size.width * 0.35)

                    // Blob 3: Far Right / Accent
                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.12))
                        .frame(width: geo.size.width * 0.8,
                               height: geo.size.width * 0.8)
                        .offset(x: geo.size.width * 0.70,
                                y: -geo.size.width * 0.15)
                } else {
                    // Client Style: Concentrated on the left (matches new requirement)
                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.40))
                        .frame(width: geo.size.width * 1.4)
                        .offset(x: -geo.size.width * 0.5, y: -geo.size.width * 0.3)

                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.25))
                        .frame(width: geo.size.width * 1.1)
                        .offset(x: -geo.size.width * 0.2, y: -geo.size.width * 0.1)

                    Circle()
                        .fill(Color.lmLightGreen.opacity(0.15))
                        .frame(width: geo.size.width * 0.8)
                        .offset(x: -geo.size.width * 0.1, y: geo.size.width * 0.1)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.lmBackground
        GreenBlobBackground()
    }
}
