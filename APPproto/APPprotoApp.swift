//
//  APPprotoApp.swift
//  APPproto
//
//  Created by alumno on 04/09/26.
//

import SwiftUI

@main
struct APPprotoApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let configuration: Result<AppConfig, Error>

    init() {
        configuration = Result {
            try AppConfig()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                appContent
                    .accessibilityHidden(scenePhase != .active)
                    .allowsHitTesting(scenePhase == .active)

                if scenePhase != .active {
                    PrivacyOverlay()
                        .zIndex(1)
                }
            }
        }
    }

    @ViewBuilder
    private var appContent: some View {
        switch configuration {
        case .success(let configuration):
            ContentView(configuration: configuration)

        case .failure:
            ContentUnavailableView {
                Label {
                    Text(verbatim: "No se pudo iniciar ClickSafe")
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            } description: {
                Text(verbatim: "La configuración de la app no es válida.")
            }
        }
    }
}
