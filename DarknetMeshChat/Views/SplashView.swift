import SwiftUI

struct SplashView: View {
    @State private var progressWidth: CGFloat = 0
    @State private var statusIndex = 0
    @State private var appeared = false

    let onComplete: () -> Void

    private let statuses = [
        "INITIALIZING MESH PROTOCOL...",
        "LOADING ENCRYPTION KEYS...",
        "SCANNING LOCAL NODES...",
        "ESTABLISHING DARKNET...",
    ]

    private let asciiLogo = """
    ██████╗  █████╗ ██████╗ ██╗  ██╗
    ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝
    ██║  ██║███████║██████╔╝█████╔╝
    ██████╔╝██║  ██║██║  ██║██╔═██╗
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═╝
    """

    private let asciiNet = """
    ███╗   ██╗███████╗████████╗
    ████╗  ██║██╔════╝╚══██╔══╝
    ██╔██╗ ██║█████╗     ██║
    ██║╚██╗██║██╔══╝     ██║
    ██║ ╚████║███████╗   ██║
    ╚═╝  ╚═══╝╚══════╝   ╚═╝
    """

    var body: some View {
        ZStack {
            DarknetTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 4) {
                    Text(asciiLogo)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(DarknetTheme.accent)
                        .multilineTextAlignment(.center)

                    Text(asciiNet)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(DarknetTheme.accent)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)

                Text("[ ZERO TRUST. ZERO SERVERS. PURE MESH. ]")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(DarknetTheme.accent)
                    .tracking(2)
                    .opacity(appeared ? 1 : 0)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DarknetTheme.accent.opacity(0.1))
                            .frame(height: 8)
                            .clipShape(.rect(cornerRadius: 2))

                        Rectangle()
                            .fill(DarknetTheme.accent)
                            .frame(width: progressWidth, height: 8)
                            .clipShape(.rect(cornerRadius: 2))
                            .shadow(color: DarknetTheme.accent.opacity(0.5), radius: 4)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 3.0)) {
                            progressWidth = geo.size.width
                        }
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 40)

                Text(statuses[statusIndex])
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(DarknetTheme.accent.opacity(0.7))
                    .contentTransition(.numericText())
                    .id(statusIndex)

                Spacer()

                Text("v1.0.0")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(DarknetTheme.textSecondary.opacity(0.4))
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            startStatusCycling()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                onComplete()
            }
        }
    }

    private func startStatusCycling() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                statusIndex = (statusIndex + 1) % statuses.count
            }
            if statusIndex == 0 {
                timer.invalidate()
            }
        }
    }
}
