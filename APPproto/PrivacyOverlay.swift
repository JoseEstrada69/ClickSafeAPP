//
//  PrivacyOverlay.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

@MainActor
struct PrivacyOverlay: View {
    var body: some View {
        ZStack {
            Color.csNavy
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.largeTitle)
                    .accessibilityHidden(true)

                Text(verbatim: "ClickSafe")
                    .font(.largeTitle.bold())
            }
            .foregroundStyle(Color.csOnNavy)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PrivacyOverlay()
}
