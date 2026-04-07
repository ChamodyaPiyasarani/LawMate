//
//  LawMateFooter.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//
//  Fixed footer component displaying the copyright notice.
//

import SwiftUI

struct LawMateFooter: View {
    var body: some View {
        Text("© Lawmate 2026")
            .font(.lmCaption)
            .foregroundColor(.lmTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.lmBackground.opacity(0.8)) // Slight blur/opacity if needed
    }
}

#Preview {
    VStack {
        Spacer()
        LawMateFooter()
    }
    .background(Color.lmFieldBg)
}
