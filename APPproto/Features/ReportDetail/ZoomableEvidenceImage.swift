//
//  ZoomableEvidenceImage.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct ZoomableEvidenceImage: View {
    let image: Image

    @State private var scale: CGFloat = 1
    @GestureState private var magnification: CGFloat = 1

    private var displayedScale: CGFloat {
        min(max(scale * magnification, 1), 5)
    }

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .scaleEffect(displayedScale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .clipped()
            .gesture(
                MagnifyGesture()
                    .updating($magnification) { value, state, _ in
                        state = value.magnification
                    }
                    .onEnded { value in
                        scale = min(
                            max(scale * value.magnification, 1),
                            5
                        )
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    scale = scale > 1 ? 1 : 2
                }
            }
            .accessibilityLabel(
                Text(verbatim: "Imagen de evidencia")
            )
            .accessibilityHint(
                Text(
                    verbatim: "Pellizca para ampliar. Toca dos veces para ampliar o restablecer."
                )
            )
            .accessibilityAction(
                named: Text(verbatim: "Ampliar")
            ) {
                scale = min(scale + 1, 5)
            }
            .accessibilityAction(
                named: Text(verbatim: "Restablecer zoom")
            ) {
                scale = 1
            }
            .onDisappear {
                scale = 1
            }
    }
}

@MainActor
private struct EvidenceImagesPreview: View {
    @State private var selectedPage = 1

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedPage) {
                ZoomableEvidenceImage(
                    image: Image("EvidenceDemo1")
                )
                .tag(1)

                ZoomableEvidenceImage(
                    image: Image("EvidenceDemo2")
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.csBackground)
            .navigationTitle(
                Text(verbatim: "\(selectedPage) de 2")
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Zoom y paginado") {
    EvidenceImagesPreview()
}
