import SwiftUI

struct ChannelsView: View {
    @Environment(MeshViewModel.self) private var viewModel
    @State private var selectedChannel: Channel?
    @State private var showCreateChannel = false

    private var publicChannels: [Channel] {
        viewModel.channels.filter { $0.type == .publicMesh }
    }

    private var privateChannels: [Channel] {
        viewModel.channels.filter { $0.type == .private1to1 }
    }

    private var groupChannels: [Channel] {
        viewModel.channels.filter { $0.type == .group }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DarknetTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("> CHANNEL DECK [ \(viewModel.channels.count) ACTIVE ]")
                                .font(DarknetTheme.mono(.headline, weight: .bold))
                                .foregroundStyle(DarknetTheme.accent)
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        if !publicChannels.isEmpty {
                            channelSection(title: "PUBLIC MESH CHANNELS", channels: publicChannels)
                        }

                        if !privateChannels.isEmpty {
                            channelSection(title: "PRIVATE CHANNELS", channels: privateChannels)
                        }

                        if !groupChannels.isEmpty {
                            channelSection(title: "GROUP CHANNELS", channels: groupChannels)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationDestination(item: $selectedChannel) { channel in
                ChatTerminalView(channel: channel)
            }
        }
        .sheet(isPresented: $showCreateChannel) {
            CreateChannelSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(DarknetTheme.cardBackground)
        }
    }

    private func channelSection(title: String, channels: [Channel]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DarknetTheme.mono(.caption, weight: .bold))
                .foregroundStyle(DarknetTheme.textSecondary)
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(channels) { channel in
                    ChannelRow(channel: channel) {
                        selectedChannel = channel
                    } onLeave: {
                        viewModel.leaveChannel(channel.id)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ChannelRow: View {
    let channel: Channel
    let onTap: () -> Void
    let onLeave: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if channel.isProtected {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: 0xFFAA00))
                        }

                        Text(channel.displayName)
                            .font(DarknetTheme.mono(.subheadline, weight: .bold))
                            .foregroundStyle(DarknetTheme.textPrimary)

                        if channel.type == .private1to1 {
                            Text("[private]")
                                .font(DarknetTheme.mono(.caption2))
                                .foregroundStyle(DarknetTheme.textSecondary)
                        }
                    }

                    if let preview = channel.lastMessagePreview {
                        Text(preview)
                            .font(DarknetTheme.mono(.caption2))
                            .foregroundStyle(DarknetTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if channel.unreadCount > 0 {
                        Text("\(channel.unreadCount)")
                            .font(DarknetTheme.mono(.caption2, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(DarknetTheme.danger)
                            .clipShape(Circle())
                    }

                    Text(channel.lastActivity, style: .time)
                        .font(DarknetTheme.mono(.caption2))
                        .foregroundStyle(DarknetTheme.textSecondary)
                }
            }
            .darknetCard()
        }
        .contextMenu {
            Button("Nuke Messages", role: .destructive) {
                onLeave()
            }
            Button("Leave", role: .destructive) {
                onLeave()
            }
        }
    }
}
