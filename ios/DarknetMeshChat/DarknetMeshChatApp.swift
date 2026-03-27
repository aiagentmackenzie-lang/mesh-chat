import SwiftUI

@main
struct DarknetMeshChatApp: App {
    @State private var viewModel = MeshViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
