import SwiftUI

@MainActor
struct ContentView: View {
    let configuration: AppConfig
    var body: some View {
        MainTabView()
            .environment(\.mockEvidenceImagesEnabled, configuration.useMockAPI)
    }
}
