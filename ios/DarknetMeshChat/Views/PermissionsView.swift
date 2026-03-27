import SwiftUI
import CoreBluetooth

struct PermissionsView: View {
    @State private var bluetoothGranted = false
    @State private var notificationsGranted = false
    @State private var permissionsChecked = false
    @State private var bluetoothDenied = false
    @State private var allCriticalGranted = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            DarknetTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("> SYSTEM PERMISSIONS REQUIRED")
                            .font(DarknetTheme.mono(.title3, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        Text("DARKNET requires these to operate")
                            .font(DarknetTheme.mono(.caption))
                            .foregroundStyle(DarknetTheme.textSecondary)
                    }
                    .padding(.top, 60)

                    VStack(spacing: 12) {
                        PermissionCard(
                            name: "BLUETOOTH",
                            description: "Required to discover and connect to nearby nodes",
                            status: bluetoothGranted ? .granted : (bluetoothDenied ? .denied : .required),
                            isCritical: true
                        )

                        PermissionCard(
                            name: "LOCAL NETWORK",
                            description: "Required for BLE peer discovery",
                            status: bluetoothGranted ? .granted : .required,
                            isCritical: true
                        )

                        PermissionCard(
                            name: "NOTIFICATIONS",
                            description: "Optional: background message alerts",
                            status: notificationsGranted ? .granted : .optional,
                            isCritical: false
                        )
                    }

                    if bluetoothDenied {
                        VStack(spacing: 12) {
                            Text("[ ! ] BLUETOOTH ACCESS DENIED")
                                .font(DarknetTheme.mono(.subheadline, weight: .bold))
                                .foregroundStyle(DarknetTheme.danger)

                            Text("DARKNET CANNOT OPERATE")
                                .font(DarknetTheme.mono(.caption))
                                .foregroundStyle(DarknetTheme.danger.opacity(0.7))

                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text("[> OPEN SETTINGS]")
                                    .font(DarknetTheme.mono(.subheadline, weight: .bold))
                                    .foregroundStyle(DarknetTheme.danger)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(DarknetTheme.danger.opacity(0.15))
                                    .clipShape(.rect(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(DarknetTheme.danger.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .darknetCard(glow: DarknetTheme.danger)
                    }

                    if !permissionsChecked {
                        Button {
                            requestPermissions()
                        } label: {
                            Text("[> REQUEST ALL PERMISSIONS]")
                                .font(DarknetTheme.mono(.subheadline, weight: .bold))
                                .foregroundStyle(DarknetTheme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(DarknetTheme.accent)
                                .clipShape(.rect(cornerRadius: 8))
                                .shadow(color: DarknetTheme.accent.opacity(0.3), radius: 8)
                        }
                    }

                    if allCriticalGranted {
                        Button {
                            onComplete()
                        } label: {
                            Text("[> INITIALIZE NODE]")
                                .font(DarknetTheme.mono(.subheadline, weight: .bold))
                                .foregroundStyle(DarknetTheme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(DarknetTheme.accent)
                                .clipShape(.rect(cornerRadius: 8))
                                .shadow(color: DarknetTheme.accent.opacity(0.3), radius: 8)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func requestPermissions() {
        permissionsChecked = true
        bluetoothGranted = true
        allCriticalGranted = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in
                notificationsGranted = granted
            }
        }
    }
}

struct PermissionCard: View {
    let name: String
    let description: String
    let status: PermissionStatus
    let isCritical: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(DarknetTheme.mono(.subheadline, weight: .bold))
                    .foregroundStyle(DarknetTheme.accent)

                Text(description)
                    .font(DarknetTheme.mono(.caption2))
                    .foregroundStyle(DarknetTheme.textSecondary)
            }

            Spacer()

            Text(status.label)
                .font(DarknetTheme.mono(.caption2, weight: .bold))
                .foregroundStyle(status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.15))
                .clipShape(.rect(cornerRadius: 4))
        }
        .darknetCard()
    }
}

enum PermissionStatus {
    case granted, required, optional, denied

    var label: String {
        switch self {
        case .granted: "[GRANTED]"
        case .required: "[REQUIRED]"
        case .optional: "[OPTIONAL]"
        case .denied: "[DENIED]"
        }
    }

    var color: Color {
        switch self {
        case .granted: DarknetTheme.accent
        case .required: DarknetTheme.danger
        case .optional: Color(hex: 0xFFAA00)
        case .denied: DarknetTheme.danger
        }
    }
}
