import SwiftUI

struct ChatTerminalView: View {
    @Environment(MeshViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var showAttachments = false
    let channel: Channel

    private var channelMessages: [ChatMessage] {
        viewModel.messages[channel.id] ?? []
    }

    var body: some View {
        ZStack {
            DarknetTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader
                messageList
                inputBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("BACK")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                    }
                    .foregroundStyle(DarknetTheme.accent)
                }
            }
        }
        .toolbarBackground(DarknetTheme.cardBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var chatHeader: some View {
        HStack(spacing: 8) {
            Text(channel.displayName)
                .font(DarknetTheme.mono(.caption, weight: .bold))
                .foregroundStyle(DarknetTheme.accent)

            Circle()
                .fill(DarknetTheme.accent)
                .frame(width: 5, height: 5)

            Text("\(channel.members.count) NODES")
                .font(DarknetTheme.mono(.caption2))
                .foregroundStyle(DarknetTheme.accent.opacity(0.7))

            Circle()
                .fill(DarknetTheme.accent)
                .frame(width: 5, height: 5)

            Text("AES-256")
                .font(DarknetTheme.mono(.caption2))
                .foregroundStyle(DarknetTheme.accent.opacity(0.7))

            Circle()
                .fill(DarknetTheme.accent)
                .frame(width: 5, height: 5)

            Text("MESH")
                .font(DarknetTheme.mono(.caption2))
                .foregroundStyle(DarknetTheme.accent.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DarknetTheme.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DarknetTheme.borderColor).frame(height: 1)
        }
    }

    private var messageList: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 8) {
                    ForEach(channelMessages) { message in
                        MessageBubble(
                            message: message,
                            isOwn: message.fromAlias == viewModel.identity?.alias
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: channelMessages.count) { _, _ in
                    if let lastId = channelMessages.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .defaultScrollAnchor(.bottom)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(DarknetTheme.borderColor).frame(height: 1)

            if showAttachments {
                attachmentOptions
            }

            HStack(spacing: 8) {
                Button {
                    withAnimation(.snappy) { showAttachments.toggle() }
                } label: {
                    Text("[+]")
                        .font(DarknetTheme.mono(.subheadline, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent)
                        .frame(width: 36, height: 36)
                }

                HStack {
                    Text("[>]")
                        .font(DarknetTheme.mono(.caption2, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent.opacity(0.5))

                    TextField("", text: $messageText, prompt: Text("Enter message...")
                        .foregroundStyle(DarknetTheme.textSecondary.opacity(0.4)), axis: .vertical)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(DarknetTheme.textPrimary)
                        .lineLimit(1...4)
                        .onChange(of: messageText) { _, newValue in
                            if newValue.count > 500 {
                                messageText = String(newValue.prefix(500))
                            }
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(DarknetTheme.background)
                .clipShape(.rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DarknetTheme.borderColor, lineWidth: 1)
                )

                Button {
                    sendMessage()
                } label: {
                    Text("SEND")
                        .font(DarknetTheme.mono(.caption, weight: .bold))
                        .foregroundStyle(messageText.isEmpty ? DarknetTheme.textSecondary : DarknetTheme.background)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(messageText.isEmpty ? DarknetTheme.textSecondary.opacity(0.2) : DarknetTheme.accent)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .disabled(messageText.isEmpty)
                .sensoryFeedback(.impact(weight: .medium), trigger: channelMessages.count)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DarknetTheme.cardBackground)

            if messageText.count > 400 {
                HStack {
                    Spacer()
                    Text("\(messageText.count)/500")
                        .font(DarknetTheme.mono(.caption2))
                        .foregroundStyle(messageText.count > 480 ? DarknetTheme.danger : DarknetTheme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
                .background(DarknetTheme.cardBackground)
            }
        }
    }

    private var attachmentOptions: some View {
        HStack(spacing: 12) {
            AttachmentButton(label: "LOCATION", icon: "location.fill") {
                messageText = "GPS: 37.7749,-122.4194"
                showAttachments = false
            }
            AttachmentButton(label: "PASSPHRASE", icon: "key.fill") {
                messageText = CryptoService.generateSymmetricKey().prefix(24).description
                showAttachments = false
            }
            AttachmentButton(label: "SYS INFO", icon: "info.circle.fill") {
                messageText = "NODE: \(viewModel.identity?.alias ?? "?") | MESH: \(viewModel.bleService.meshStatus.rawValue) | NODES: \(viewModel.bleService.discoveredNodes.count)"
                showAttachments = false
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DarknetTheme.cardBackground)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.sendMessage(content: text, channelId: channel.id)
        messageText = ""
    }
}

struct AttachmentButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(DarknetTheme.mono(.caption2, weight: .bold))
            }
            .foregroundStyle(DarknetTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(DarknetTheme.accent.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isOwn: Bool

    var body: some View {
        if message.isSystem {
            systemMessage
        } else if isOwn {
            ownMessage
        } else {
            otherMessage
        }
    }

    private var systemMessage: some View {
        Text("[ \(message.content.uppercased()) ]")
            .font(DarknetTheme.mono(.caption2))
            .foregroundStyle(DarknetTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    private var ownMessage: some View {
        HStack {
            Spacer(minLength: 60)

            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .font(DarknetTheme.mono(.subheadline))
                    .foregroundStyle(DarknetTheme.textPrimary)

                HStack(spacing: 6) {
                    if let remaining = message.selfDestructsIn {
                        Text("[*] \(remaining)")
                            .font(DarknetTheme.mono(.caption2))
                            .foregroundStyle(DarknetTheme.danger)
                    }

                    Text(message.timestamp, format: .dateTime.hour().minute())
                        .font(DarknetTheme.mono(.caption2))
                        .foregroundStyle(DarknetTheme.textSecondary)

                    Text(message.deliveryStatus.symbol)
                        .font(DarknetTheme.mono(.caption2))
                        .foregroundStyle(DarknetTheme.accent)
                }
            }
            .padding(10)
            .background(DarknetTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DarknetTheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var otherMessage: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(message.fromAlias)
                        .font(DarknetTheme.mono(.caption2, weight: .bold))
                        .foregroundStyle(DarknetTheme.accent)

                    Text(message.timestamp, format: .dateTime.hour().minute().second())
                        .font(DarknetTheme.mono(.caption2))
                        .foregroundStyle(DarknetTheme.textSecondary)
                }

                Text(message.content)
                    .font(DarknetTheme.mono(.subheadline))
                    .foregroundStyle(DarknetTheme.textPrimary)

                if message.hops > 0 {
                    Text("[RELAYED x\(message.hops)]")
                        .font(DarknetTheme.mono(.caption2))
                        .foregroundStyle(DarknetTheme.textSecondary.opacity(0.6))
                }
            }
            .padding(10)
            .background(DarknetTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DarknetTheme.borderColor, lineWidth: 1)
            )

            Spacer(minLength: 60)
        }
    }
}
