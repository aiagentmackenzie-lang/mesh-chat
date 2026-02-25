import SwiftUI

struct ContentView: View {
    @Environment(MeshViewModel.self) private var viewModel
    @State private var appPhase: AppPhase = .splash
    @State private var isHydrated = false

    var body: some View {
        ZStack {
            DarknetTheme.background.ignoresSafeArea()

            switch appPhase {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        if viewModel.hasIdentity {
                            appPhase = .mainApp
                            viewModel.initializeBLE()
                        } else {
                            appPhase = .permissions
                        }
                    }
                }
                .transition(.opacity)

            case .permissions:
                PermissionsView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appPhase = .identitySetup
                    }
                }
                .transition(.opacity)

            case .identitySetup:
                IdentitySetupView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appPhase = .mainApp
                    }
                }
                .transition(.opacity)

            case .mainApp:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !isHydrated {
                viewModel.hydrate()
                isHydrated = true
            }
        }
    }
}

enum AppPhase {
    case splash, permissions, identitySetup, mainApp
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("RADAR", systemImage: "antenna.radiowaves.left.and.right", value: 0) {
                RadarView()
            }

            Tab("CHANNELS", systemImage: "number", value: 1) {
                ChannelsView()
            }

            Tab("OPS", systemImage: "gearshape.fill", value: 2) {
                OpsView()
            }
        }
        .tint(DarknetTheme.accent)
    }
}
