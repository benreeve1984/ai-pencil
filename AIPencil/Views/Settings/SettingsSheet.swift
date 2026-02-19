import SwiftUI

/// Settings sheet for API key management.
///
/// Security measures:
/// - API key entered via SecureField (masked input)
/// - Stored in Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
/// - Displayed as masked string (sk-ant-******abcd) — no full readback
/// - No copy/paste of stored key
/// - Only options: enter new key or remove existing key
struct SettingsSheet: View {

    @EnvironmentObject private var anthropicService: AnthropicChatService
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyInput = ""
    @State private var showSaveConfirmation = false
    @State private var showRemoveConfirmation = false

    private let keychain = KeychainService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if keychain.hasAPIKey {
                        HStack {
                            Text(keychain.maskedAPIKey() ?? "••••••")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .accessibilityLabel("API key is configured")

                        Button("Remove API Key", role: .destructive) {
                            showRemoveConfirmation = true
                        }
                    } else {
                        Label(
                            "No API key configured",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.orange)
                    }

                    SecureField("Enter Anthropic API key", text: $apiKeyInput)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Your API key is stored securely in the device Keychain. It is never sent to anyone except the Anthropic API and is not included in backups.")
                }

                Section("Model") {
                    LabeledContent("Model", value: "Claude Sonnet 4.6")
                    LabeledContent("Model ID", value: Constants.modelID)
                }

                Section("About") {
                    LabeledContent("App Version", value: Bundle.main.shortVersionString)
                    LabeledContent("Platform", value: "iPad")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("API Key Saved", isPresented: $showSaveConfirmation) {
                Button("OK") {}
            } message: {
                Text("Your API key has been securely stored.")
            }
            .confirmationDialog(
                "Remove API Key?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    removeAPIKey()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to enter a new API key to continue using the tutor.")
            }
        }
    }

    // MARK: - Actions

    private func saveAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }

        do {
            try keychain.saveAPIKey(key)
            anthropicService.configure(apiKey: key)
            apiKeyInput = ""
            showSaveConfirmation = true
        } catch {
            // TODO: Surface save errors to the user
            print("Failed to save API key: \(error)")
        }
    }

    private func removeAPIKey() {
        try? keychain.deleteAPIKey()
        anthropicService.reset()
    }
}
