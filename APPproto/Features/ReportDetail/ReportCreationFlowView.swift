//
//  ReportCreationFlowView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct ReportCreationFlowView: View {
    private enum Route: Hashable {
        case evidence
        case success(Int)
        case reportDetail(Int)
    }

    @Binding var publicationURL: String

    let onReturnHome: () -> Void

    private let api: any APIClient

    @State private var model: ReportCreationViewModel
    @State private var path: [Route] = []

    init(
        api: any APIClient,
        publicationURL: Binding<String>,
        onReturnHome: @escaping () -> Void
    ) {
        self.api = api
        self.onReturnHome = onReturnHome
        _publicationURL = publicationURL

        _model = State(
            initialValue: ReportCreationViewModel(api: api)
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            ReportCreationDataScreen(
                model: model,
                onContinue: {
                    guard model.canContinue else {
                        return
                    }

                    path.append(.evidence)
                }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .evidence:
                    ReportCreationEvidenceScreen(
                        model: model,
                        onBack: {
                            guard !model.isBusy else {
                                return
                            }

                            if path.last == .evidence {
                                path.removeLast()
                            }
                        },
                        onSubmitted: { report in
                            model.reset()
                            path = [.success(report.id)]
                        }
                    )

                case .success(let reportID):
                    ReportCreationSuccessScreen(
                        onViewReport: {
                            path = [.reportDetail(reportID)]
                        },
                        onReturnHome: {
                            returnHome()
                        }
                    )

                case .reportDetail(let reportID):
                    ReportDetailScreen(
                        reportID: reportID,
                        api: api
                    )
                }
            }
        }
        .tint(Color.csNavy)
        .task {
            applyIncomingPublicationURL()
        }
        .onChange(of: publicationURL) { _, _ in
            applyIncomingPublicationURL()
        }
        .onChange(of: model.isBusy) { _, isBusy in
            if !isBusy {
                applyIncomingPublicationURL()
            }
        }
    }

    private func applyIncomingPublicationURL() {
        guard !publicationURL.isEmpty,
              !model.isBusy else {
            return
        }

        model.draft.publicationURL = publicationURL
        publicationURL = ""
        path.removeAll()
    }

    private func returnHome() {
        guard !model.isBusy else {
            return
        }

        model.reset()
        publicationURL = ""
        path.removeAll()
        onReturnHome()
    }
}
