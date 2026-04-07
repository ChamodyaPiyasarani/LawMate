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

struct GreenBlobBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Large outer blob
                Circle()
                    .fill(Color.lmLightGreen.opacity(0.40))
                    .frame(width: geo.size.width * 0.7,
                           height: geo.size.width * 0.7)
                    .offset(x: -geo.size.width * 0.15,
                            y: -geo.size.width * 0.15)

                // Medium inner blob
                Circle()
                    .fill(Color.lmLightGreen.opacity(0.25))
                    .frame(width: geo.size.width * 0.5,
                           height: geo.size.width * 0.5)
                    .offset(x: -geo.size.width * 0.05,
                            y: -geo.size.width * 0.05)

                // Small accent blob
                Circle()
                    .fill(Color.lmLightGreen.opacity(0.20))
                    .frame(width: geo.size.width * 0.3,
                           height: geo.size.width * 0.3)
                    .offset(x: geo.size.width * 0.05,
                            y: geo.size.width * 0.05)
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
