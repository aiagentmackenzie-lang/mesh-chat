import SwiftUI

struct IdentitySetupView: View {
    @Environment(MeshViewModel.self) private var viewModel
    @State private var alias = ""
    @State private var selectedColor: NodeColor = .green
    @State private var passphrase = ""

    let onComplete: () -> Void

    private let prefixes = ["SPECTER", "WRAITH", "PHANTOM", "CIPHER", "SHADOW", "GHOST", "VOID", "NULL", "REAPER", "DAEMON"]

    var body: some View {
        ZStack {
            DarknetTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("> NODE IDENTITY SETUP")
                            .font(DarknetTheme.mono(.title3, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        Text("You are anonymous. This is stored only on your device.")
                            .font(DarknetTheme.mono(.caption))
                            .foregroundStyle(DarknetTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("NODE ALIAS")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        TextField("", text: $alias, prompt: Text("e.g. GHOST-X9, VOID-23")
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
                            .onChange(of: alias) { _, newValue in
                                alias = String(newValue.uppercased().prefix(12))
                            }

                        Text("Max 12 chars. Your public name on the mesh.")
                            .font(DarknetTheme.mono(.caption2))
                            .foregroundStyle(DarknetTheme.textSecondary)
                    }
                    .darknetCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("NODE COLOR")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        HStack(spacing: 12) {
                            ForEach(NodeColor.allCases, id: \.self) { color in
                                Button {
                                    withAnimation(.snappy) { selectedColor = color }
                                } label: {
                                    Circle()
                                        .fill(color.swiftUIColor)
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            if selectedColor == color {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(color == .white ? .black : .white)
                                            }
                                        }
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? color.swiftUIColor : .clear, lineWidth: 2)
                                                .padding(-4)
                                        )
                                        .shadow(color: selectedColor == color ? color.swiftUIColor.opacity(0.5) : .clear, radius: 8)
                                }
                            }
                        }
                    }
                    .darknetCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSPHRASE (Optional)")
                            .font(DarknetTheme.mono(.caption, weight: .bold))
                            .foregroundStyle(DarknetTheme.accent)

                        SecureField("", text: $passphrase, prompt: Text("Encrypts local history")
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
                    .darknetCard()

                    Button {
                        generateRandomAlias()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                            Text("GENERATE RANDOM ALIAS")
                                .font(DarknetTheme.mono(.caption, weight: .bold))
                        }
                        .foregroundStyle(DarknetTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DarknetTheme.accent.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DarknetTheme.borderColor, lineWidth: 1)
                        )
                    }

                    Button {
                        guard !alias.isEmpty else { return }
                        viewModel.createIdentity(alias: alias, color: selectedColor)
                        viewModel.initializeBLE()
                        onComplete()
                    } label: {
                        Text("[> INITIALIZE NODE]")
                            .font(DarknetTheme.mono(.subheadline, weight: .bold))
                            .foregroundStyle(DarknetTheme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(alias.isEmpty ? DarknetTheme.textSecondary : DarknetTheme.accent)
                            .clipShape(.rect(cornerRadius: 8))
                            .shadow(color: alias.isEmpty ? .clear : DarknetTheme.accent.opacity(0.3), radius: 8)
                    }
                    .disabled(alias.isEmpty)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func generateRandomAlias() {
        let prefix = prefixes.randomElement() ?? "NODE"
        let suffix = String(format: "%02X", Int.random(in: 0...255))
        withAnimation { alias = "\(prefix)-\(suffix)" }
    }
}
