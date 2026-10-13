//
//  RootView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

@MainActor
struct RootView<LoggedOutContent: View, LoggedInContent: View>: View {
    @Environment(AppState.self) private var appState

    private let loggedOutContent: () -> LoggedOutContent
    private let loggedInContent: () -> LoggedInContent

    init(
        @ViewBuilder loggedOut: @escaping () -> LoggedOutContent,
        @ViewBuilder loggedIn: @escaping () -> LoggedInContent
    ) {
        self.loggedOutContent = loggedOut
        self.loggedInContent = loggedIn
    }

    var body: some View {
        Group {
            switch appState.sessionState {
            case .loading:
                loadingView

            case .loggedOut:
                loggedOutContent()
                    .id(appState.sessionID)

            case .loggedIn:
                loggedInContent()
                    .id(appState.sessionID)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let message = appState.sessionMessage {
                Text(verbatim: message)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .accessibilityLabel(Text(verbatim: message))
            }
        }
        .task {
            await appState.start()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text(verbatim: "Cargando sesión…")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
