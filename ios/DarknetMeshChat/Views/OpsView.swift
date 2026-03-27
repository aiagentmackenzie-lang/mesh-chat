import SwiftUI

struct OpsView: View {
    @Environment(MeshViewModel.self) private var viewModel
    @State private var showNukeConfirm = false
    @State private var showResetConfirm = false
    @State private var nukeText = ""
    @State private var editingAlias = false
    @State private var newAlias = ""
    @State private var emergencyTapCount = 0

    var body: some View {
        ZStack {
            DarknetTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    identitySection
                    encryptionSection
                    meshConfigSection
                    messageSettingsSection
                    appearanceSection
                    dangerZone
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("NUKE ALL CHATS", isPresented: $showNukeConfirm) {
            TextField("TYPE 'NUKE' TO CONFIRM", text: $nukeText)
                .textInputAutocapitalization(.characters)
            Button("CONFIRM", role: .destructive) {
                if nukeText == "NUKE" {
                    viewModel.nukeAllChats()
                }
                nukeText = ""
            }
            Button("Cancel", role: .cancel) { nukeText = "" }
        } message: {
            Text("This will permanently delete all message history.")
        }
        .alert("RESET NODE IDENTITY", isPresented: $showResetConfirm) {
            Button("RESET", role: .destructive) {
                viewModel.resetIdentity()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will regenerate your keys and alias. Paired nodes must re-pair.")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("> OPS PANEL")
                .font(DarknetTheme.mono(.title3, weight: .bold))
                .foregroundStyle(DarknetTheme.accent)

            Text("NODE: \(viewModel.identity?.alias ?? "---") [*] MESH v1.0")
                .font(DarknetTheme.mono(.caption))
                .foregroundStyle(DarknetTheme.textSecondary)
        }
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("NODE IDENTITY")

            HStack {
                Text("Alias:")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                if editingAlias {
                    TextField("", text: $newAlias)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(DarknetTheme.textPrimary)
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DarknetTheme.background)
                        .clipShape(.rect(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DarknetTheme.borderColor, lineWidth: 1)
                        )

                    Button {
                        viewModel.updateIdentityAlias(newAlias)
                        editingAlias = false
                    } label: {
                        Text("[OK]")
                            .font(DarknetTheme.mono(.caption2, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)
                    }
                } else {
                    Text(viewModel.identity?.alias ?? "---")
                        .font(DarknetTheme.mono(.subheadline, weight: .bold))
                        .foregroundStyle(DarknetTheme.textPrimary)

                    Spacer()

                    Button {
                        newAlias = viewModel.identity?.alias ?? ""
                        editingAlias = true
                    } label: {
                        Text("[EDIT]")
                            .font(DarknetTheme.mono(.caption2, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)
                    }
                }
            }

            HStack {
                Text("Node ID:")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                Text(String((viewModel.identity?.id ?? "---").prefix(12)) + "...")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textPrimary)

                Spacer()

                Button {
                    UIPasteboard.general.string = viewModel.identity?.id
                } label: {
                    Text("[COPY]")
                        .font(DarknetTheme.mono(.caption2, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent)
                }
            }

            HStack {
                Text("Public Key:")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                Text(String((viewModel.identity?.publicKey ?? "---").prefix(16)) + "...")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                Button {
                    UIPasteboard.general.string = viewModel.identity?.publicKey
                } label: {
                    Text("[COPY]")
                        .font(DarknetTheme.mono(.caption2, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent)
                }
            }

            HStack {
                Text("Color:")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                Circle()
                    .fill(viewModel.identity?.color.swiftUIColor ?? .white)
                    .frame(width: 12, height: 12)

                Spacer()

                Text("Member since: \(viewModel.identity?.createdAt ?? Date(), format: .dateTime.month().day().year())")
                    .font(DarknetTheme.mono(.caption2))
                    .foregroundStyle(DarknetTheme.textSecondary)
            }
        }
        .darknetCard()
    }

    private var encryptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("ENCRYPTION")

            @Bindable var vm = viewModel

            ForEach(EncryptionProtocolType.allCases, id: \.self) { proto in
                Button {
                    var s = viewModel.settings
                    s.encryptionProtocol = proto
                    viewModel.updateSettings(s)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.settings.encryptionProtocol == proto ? "circle.inset.filled" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(DarknetTheme.accent)

                        Text(proto.rawValue)
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.textPrimary)

                        if proto == .x25519Aes {
                            Text("(experimental)")
                                .font(DarknetTheme.mono(.caption2))
                                .foregroundStyle(Color(hex: 0xFFAA00))
                        }
                    }
                }
            }

            Button {
                viewModel.rotateKeys()
            } label: {
                Text("[> ROTATE KEYS NOW]")
                    .font(DarknetTheme.mono(.caption, weight: .bold))
                    .foregroundStyle(DarknetTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DarknetTheme.accent.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DarknetTheme.borderColor, lineWidth: 1)
                    )
            }
        }
        .darknetCard()
    }

    private var meshConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("MESH CONFIG")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Hop Limit: \(viewModel.settings.hopLimit)")
                        .font(DarknetTheme.mono(.caption))
                        .foregroundStyle(DarknetTheme.textSecondary)
                    Spacer()
                }

                Slider(value: Binding(
                    get: { Double(viewModel.settings.hopLimit) },
                    set: { val in
                        var s = viewModel.settings
                        s.hopLimit = Int(val)
                        viewModel.updateSettings(s)
                    }
                ), in: 1...7, step: 1)
                .tint(DarknetTheme.accent)

                Text("1 = direct only (~10m), 7 = max range (~70m)")
                    .font(DarknetTheme.mono(.caption2))
                    .foregroundStyle(DarknetTheme.textSecondary.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Scan Interval")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                HStack(spacing: 6) {
                    ForEach(ScanInterval.allCases, id: \.self) { interval in
                        Button {
                            var s = viewModel.settings
                            s.scanInterval = interval
                            viewModel.updateSettings(s)
                        } label: {
                            Text(interval.rawValue.components(separatedBy: " ").first ?? "")
                                .font(DarknetTheme.mono(.caption2, weight: .bold))
                                .foregroundStyle(viewModel.settings.scanInterval == interval ? DarknetTheme.background : DarknetTheme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(viewModel.settings.scanInterval == interval ? DarknetTheme.accent : DarknetTheme.accent.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 4))
                        }
                    }
                }
            }

            HStack {
                Text("Background Scanning")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.settings.backgroundScanning },
                    set: { val in
                        var s = viewModel.settings
                        s.backgroundScanning = val
                        viewModel.updateSettings(s)
                    }
                ))
                .tint(DarknetTheme.accent)
                .labelsHidden()
            }
        }
        .darknetCard()
    }

    private var messageSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("MESSAGE SETTINGS")

            VStack(alignment: .leading, spacing: 6) {
                Text("Default TTL")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                HStack(spacing: 6) {
                    ForEach(MessageTTL.allCases, id: \.self) { ttl in
                        Button {
                            var s = viewModel.settings
                            s.defaultTTL = ttl
                            viewModel.updateSettings(s)
                        } label: {
                            Text(ttl.displayName)
                                .font(DarknetTheme.mono(.caption2, weight: .bold))
                                .foregroundStyle(viewModel.settings.defaultTTL == ttl ? DarknetTheme.background : DarknetTheme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(viewModel.settings.defaultTTL == ttl ? DarknetTheme.accent : DarknetTheme.accent.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 4))
                        }
                    }
                }
            }

            HStack {
                Text("Read Receipts")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.settings.readReceipts },
                    set: { val in
                        var s = viewModel.settings
                        s.readReceipts = val
                        viewModel.updateSettings(s)
                    }
                ))
                .tint(DarknetTheme.accent)
                .labelsHidden()
            }

            HStack {
                Text("Typing Indicators")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.settings.typingIndicators },
                    set: { val in
                        var s = viewModel.settings
                        s.typingIndicators = val
                        viewModel.updateSettings(s)
                    }
                ))
                .tint(DarknetTheme.accent)
                .labelsHidden()
            }
        }
        .darknetCard()
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("APPEARANCE")

            VStack(alignment: .leading, spacing: 6) {
                Text("Accent Color")
                    .font(DarknetTheme.mono(.caption))
                    .foregroundStyle(DarknetTheme.textSecondary)

                HStack(spacing: 12) {
                    ForEach(AccentChoice.allCases, id: \.self) { choice in
                        Button {
                            var s = viewModel.settings
                            s.accentColorChoice = choice
                            viewModel.updateSettings(s)
                        } label: {
                            Circle()
                                .fill(Color(hex: choice.hex))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if viewModel.settings.accentColorChoice == choice {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.black)
                                    }
                                }
                                .shadow(color: viewModel.settings.accentColorChoice == choice ? Color(hex: choice.hex).opacity(0.5) : .clear, radius: 6)
                        }
                    }
                }
            }
        }
        .darknetCard()
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DANGER ZONE")

            Button {
                showNukeConfirm = true
            } label: {
                Text("[> NUKE ALL CHATS]")
                    .font(DarknetTheme.mono(.caption, weight: .bold))
                    .foregroundStyle(DarknetTheme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DarknetTheme.danger.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
            }

            Button {
                showResetConfirm = true
            } label: {
                Text("[> RESET NODE IDENTITY]")
                    .font(DarknetTheme.mono(.caption, weight: .bold))
                    .foregroundStyle(DarknetTheme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DarknetTheme.danger.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
            }

            Button {
                exportChatLogs()
            } label: {
                Text("[> EXPORT CHAT LOGS]")
                    .font(DarknetTheme.mono(.caption, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFFAA00))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xFFAA00).opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
            }

            Button {
                emergencyTapCount += 1
                if emergencyTapCount >= 3 {
                    viewModel.emergencyWipe()
                    emergencyTapCount = 0
                }
            } label: {
                Text("[> EMERGENCY WIPE] (\(3 - emergencyTapCount) taps)")
                    .font(DarknetTheme.mono(.caption, weight: .bold))
                    .foregroundStyle(DarknetTheme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DarknetTheme.danger.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 6))
            }
            .sensoryFeedback(.warning, trigger: emergencyTapCount)
        }
        .padding(16)
        .background(DarknetTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DarknetTheme.danger.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: DarknetTheme.danger.opacity(0.1), radius: 8)
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            Text("DARKNET v1.0.0")
                .font(DarknetTheme.mono(.caption, weight: .bold))
                .foregroundStyle(DarknetTheme.textPrimary)

            Text("Zero trust. Zero servers. Pure mesh.")
                .font(DarknetTheme.mono(.caption2))
                .foregroundStyle(DarknetTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DarknetTheme.mono(.caption, weight: .bold))
            .foregroundStyle(DarknetTheme.accent)
    }

    private func exportChatLogs() {
        guard let data = try? JSONEncoder().encode(viewModel.messages),
              let json = String(data: data, encoding: .utf8) else { return }
        UIPasteboard.general.string = json
    }
}
