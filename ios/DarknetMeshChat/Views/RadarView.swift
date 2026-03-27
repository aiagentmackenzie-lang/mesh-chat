import SwiftUI

struct RadarView: View {
    @Environment(MeshViewModel.self) private var viewModel
    @State private var showCreateChannel = false
    @State private var pairingNode: MeshNode?
    @State private var pairingCode = ""
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            DarknetTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                scanningBar
                nodeList
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showCreateChannel = true
                    } label: {
                        Text("[+]")
                            .font(DarknetTheme.mono(.title3, weight: .bold))
                            .foregroundStyle(DarknetTheme.background)
                            .frame(width: 56, height: 56)
                            .background(DarknetTheme.accent)
                            .clipShape(Circle())
                            .shadow(color: DarknetTheme.accent.opacity(0.4), radius: 12)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showCreateChannel) {
            CreateChannelSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(DarknetTheme.cardBackground)
        }
        .sheet(item: $pairingNode) { node in
            PairingSheet(node: node, code: pairingCode)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                .presentationBackground(DarknetTheme.cardBackground)
        }
        .onAppear {
            viewModel.startScanning()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Text("[ DARKNET ]")
                .font(DarknetTheme.mono(.headline, weight: .bold))
                .foregroundStyle(DarknetTheme.accent)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.bleService.meshStatus == .active ? DarknetTheme.accent : DarknetTheme.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(viewModel.bleService.meshStatus == .active && pulseAnimation ? 1.3 : 1.0)
                    .opacity(viewModel.bleService.meshStatus == .active && pulseAnimation ? 0.6 : 1.0)

                Text(viewModel.bleService.meshStatus.rawValue)
                    .font(DarknetTheme.mono(.caption2, weight: .bold))
                    .foregroundStyle(viewModel.bleService.meshStatus == .active ? DarknetTheme.accent : DarknetTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DarknetTheme.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DarknetTheme.borderColor).frame(height: 1)
        }
    }

    private var scanningBar: some View {
        Button {
            viewModel.startScanning()
        } label: {
            HStack {
                if viewModel.bleService.isScanning {
                    Text("[ SCANNING... ]")
                        .font(DarknetTheme.mono(.caption, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent)
                } else {
                    Text("[ \(viewModel.bleService.discoveredNodes.count) NODES DETECTED ]")
                        .font(DarknetTheme.mono(.caption, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent)
                }
                Spacer()
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundStyle(DarknetTheme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DarknetTheme.accent.opacity(0.05))
        }
    }

    private var nodeList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.bleService.discoveredNodes.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.bleService.discoveredNodes) { node in
                        NodeCard(node: node, onOpenChannel: {
                            viewModel.openPrivateChannel(with: node)
                        }, onPair: {
                            pairingCode = CryptoService.generatePairingCode()
                            pairingNode = node
                        })
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("[ NO NODES DETECTED ]")
                .font(DarknetTheme.mono(.subheadline, weight: .bold))
                .foregroundStyle(DarknetTheme.textSecondary)

            Text("Ensure nearby devices have DARKNET active\nRange: ~10m direct, ~70m via mesh relay")
                .font(DarknetTheme.mono(.caption2))
                .foregroundStyle(DarknetTheme.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                viewModel.startScanning()
            } label: {
                Text("[> RESCAN MESH]")
                    .font(DarknetTheme.mono(.caption, weight: .bold))
                    .foregroundStyle(DarknetTheme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(DarknetTheme.accent.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DarknetTheme.borderColor, lineWidth: 1)
                    )
            }
        }
        .padding(.top, 60)
    }
}

struct NodeCard: View {
    let node: MeshNode
    let onOpenChannel: () -> Void
    let onPair: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(node.color.swiftUIColor)
                    .frame(width: 10, height: 10)

                Text(node.alias)
                    .font(DarknetTheme.mono(.subheadline, weight: .bold))
                    .foregroundStyle(DarknetTheme.textPrimary)

                Spacer()

                Text("[\(node.distanceShort)]")
                    .font(DarknetTheme.mono(.caption2))
                    .foregroundStyle(DarknetTheme.textSecondary)

                Text("[\(node.status.rawValue)]")
                    .font(DarknetTheme.mono(.caption2, weight: .bold))
                    .foregroundStyle(node.status == .paired ? DarknetTheme.accent : (node.status == .busy ? DarknetTheme.danger : Color(hex: 0xFFAA00)))
            }

            HStack(spacing: 4) {
                Text("Last seen: just now")
                    .font(DarknetTheme.mono(.caption2))
                    .foregroundStyle(DarknetTheme.textSecondary)
            }

            HStack(spacing: 4) {
                Text("Signal:")
                    .font(DarknetTheme.mono(.caption2))
                    .foregroundStyle(DarknetTheme.textSecondary)

                HStack(spacing: 1) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle()
                            .fill(i < node.signalStrength ? DarknetTheme.accent : DarknetTheme.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 10)
                    }
                }

                Text("\(node.rssi) dBm")
                    .font(DarknetTheme.mono(.caption2))
                    .foregroundStyle(DarknetTheme.textSecondary)
            }

            HStack(spacing: 12) {
                Button {
                    onOpenChannel()
                } label: {
                    Text("[> OPEN CHANNEL]")
                        .font(DarknetTheme.mono(.caption2, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DarknetTheme.accent.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 4))
                }

                if node.status != .paired {
                    Button {
                        onPair()
                    } label: {
                        Text("[> PAIR NOW]")
                            .font(DarknetTheme.mono(.caption2, weight: .bold))
                            .foregroundStyle(Color(hex: 0xFFAA00))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: 0xFFAA00).opacity(0.1))
                            .clipShape(.rect(cornerRadius: 4))
                    }
                }
            }
        }
        .darknetCard()
    }
}

struct PairingSheet: View {
    let node: MeshNode
    let code: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("PAIRING WITH \(node.alias)")
                .font(DarknetTheme.mono(.headline, weight: .bold))
                .foregroundStyle(DarknetTheme.accent)

            Text("YOUR PAIRING CODE:")
                .font(DarknetTheme.mono(.caption))
                .foregroundStyle(DarknetTheme.textSecondary)

            Text(code)
                .font(.system(size: 48, design: .monospaced).bold())
                .foregroundStyle(DarknetTheme.accent)
                .tracking(8)
                .shadow(color: DarknetTheme.accent.opacity(0.3), radius: 8)

            Text("Ask \(node.alias) to confirm this code")
                .font(DarknetTheme.mono(.caption2))
                .foregroundStyle(DarknetTheme.textSecondary)

            Button {
                dismiss()
            } label: {
                Text("[> CONFIRM PAIRING]")
                    .font(DarknetTheme.mono(.subheadline, weight: .bold))
                    .foregroundStyle(DarknetTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DarknetTheme.accent)
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding(24)
    }
}

struct CreateChannelSheet: View {
    @Environment(MeshViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var channelName = ""
    @State private var channelType: ChannelType = .publicMesh
    @State private var password = ""
    @State private var ttl: MessageTTL = .infinite

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CHANNEL NAME")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        TextField("", text: $channelName, prompt: Text("MAX 16 CHARS")
                            .foregroundStyle(DarknetTheme.textSecondary.opacity(0.5)))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(DarknetTheme.textPrimary)
                            .textInputAutocapitalization(.characters)
                            .padding(12)
                            .background(DarknetTheme.background)
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DarknetTheme.borderColor, lineWidth: 1)
                            )
                            .onChange(of: channelName) { _, newValue in
                                channelName = String(newValue.uppercased().prefix(16))
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TYPE")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        HStack(spacing: 8) {
                            ForEach([ChannelType.publicMesh, .private1to1, .group], id: \.self) { type in
                                Button {
                                    channelType = type
                                } label: {
                                    Text("[\(type.rawValue)]")
                                        .font(DarknetTheme.mono(.caption2, weight: .bold))
                                        .foregroundStyle(channelType == type ? DarknetTheme.background : DarknetTheme.accent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(channelType == type ? DarknetTheme.accent : DarknetTheme.accent.opacity(0.1))
                                        .clipShape(.rect(cornerRadius: 6))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD (Optional)")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        SecureField("", text: $password, prompt: Text("Channel password")
                            .foregroundStyle(DarknetTheme.textSecondary.opacity(0.5)))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(DarknetTheme.textPrimary)
                            .padding(12)
                            .background(DarknetTheme.background)
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DarknetTheme.borderColor, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TTL")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        HStack(spacing: 8) {
                            ForEach(MessageTTL.allCases, id: \.self) { option in
                                Button {
                                    ttl = option
                                } label: {
                                    Text(option.displayName)
                                        .font(DarknetTheme.mono(.caption2, weight: .bold))
                                        .foregroundStyle(ttl == option ? DarknetTheme.background : DarknetTheme.accent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(ttl == option ? DarknetTheme.accent : DarknetTheme.accent.opacity(0.1))
                                        .clipShape(.rect(cornerRadius: 6))
                                }
                            }
                        }
                    }

                    Button {
                        guard !channelName.isEmpty else { return }
                        viewModel.createChannel(name: channelName, type: channelType, password: password.isEmpty ? nil : password, ttl: ttl)
                        dismiss()
                    } label: {
                        Text("[> SPAWN CHANNEL]")
                            .font(DarknetTheme.mono(.subheadline, weight: .bold))
                            .foregroundStyle(DarknetTheme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(channelName.isEmpty ? DarknetTheme.textSecondary : DarknetTheme.accent)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    .disabled(channelName.isEmpty)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("SPAWN CHANNEL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DarknetTheme.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
