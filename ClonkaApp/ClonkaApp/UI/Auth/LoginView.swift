import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header — Jobka branded
                    VStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundStyle(JobkaTheme.primary)
                        Text(L10n.App_Name.key)
                            .font(.largeTitle.bold())
                            .foregroundStyle(JobkaTheme.primary)
                        Text("Employee Portal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Saved Profiles
                    if !viewModel.savedProfiles.isEmpty {
                        savedProfilesSection
                    }

                    // Login Form
                    loginFormSection

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)

                    // Version
                    Text("Clonka Swift v1.0.0")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .onTapGesture {
                            viewModel.handleVersionTap()
                        }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Logging in...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Developer Mode", isPresented: $viewModel.showDeveloperPrompt) {
                TextField("Password", text: $viewModel.developerPassword)
                Button("Cancel", role: .cancel) {}
                Button("Activate") { viewModel.activateDeveloperMode() }
            } message: {
                Text("Enter developer password")
            }
            .sheet(isPresented: $viewModel.showQRScanner) {
                QRScannerView { code in
                    viewModel.loginWithQR(code: code)
                    viewModel.showQRScanner = false
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                LoginSettingsSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Saved Profiles

    private var savedProfilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Accounts")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel.savedProfiles) { profile in
                savedProfileRow(profile)
            }
        }
    }

    private func savedProfileRow(_ profile: SessionManager.SavedProfile) -> some View {
        Button {
            Task { await viewModel.loginWithSavedProfile(profile) }
        } label: {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: profile.color ?? "#666666"))
                        .frame(width: 44, height: 44)
                    Text(
                        profile.initials
                            ?? String(profile.displayName.prefix(2)).uppercased()
                    )
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.displayName)
                        .font(.body.weight(.medium))
                    Text("PN: \(profile.personalNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Environment badge
                Text(profile.environmentBadge)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(profile.environment == "Test" ? Color.orange : Color.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteProfile(profile)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Login Form

    private var loginFormSection: some View {
        VStack(spacing: 16) {
            Text("Login")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Personal Number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Enter personal number", text: $viewModel.personalNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Access Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Enter access code or scan QR", text: $viewModel.accessCode)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.showQRScanner = true
                } label: {
                    Label("Scan QR", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    Task { await viewModel.login() }
                } label: {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Login Settings Sheet

struct LoginSettingsSheet: View {
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("API Environment") {
                    ForEach(ConfigManager.AppEnvironment.allCases, id: \.self) { env in
                        Button {
                            ConfigManager.shared.switchEnvironment(env)
                            viewModel.selectedEnvironment = env
                        } label: {
                            HStack {
                                Text(env.rawValue)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.selectedEnvironment == env {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                // Custom URL fields — only shown when Custom is selected
                if viewModel.selectedEnvironment == .custom {
                    Section("Custom URLs") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Webservice URL").font(.caption).foregroundStyle(.secondary)
                            TextField("https://...", text: Binding(
                                get: { ConfigManager.shared.customWebserviceURL },
                                set: { ConfigManager.shared.customWebserviceURL = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Client API URL").font(.caption).foregroundStyle(.secondary)
                            TextField("https://...", text: Binding(
                                get: { ConfigManager.shared.customClientApiURL },
                                set: { ConfigManager.shared.customClientApiURL = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Azure File URL").font(.caption).foregroundStyle(.secondary)
                            TextField("https://...", text: Binding(
                                get: { ConfigManager.shared.customAzureFileURL },
                                set: { ConfigManager.shared.customAzureFileURL = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        }
                        Button("Save Custom URLs") {
                            ConfigManager.shared.saveCustomURLs()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Section("Developer") {
                    HStack {
                        Text("Developer Mode")
                        Spacer()
                        Image(systemName: AppState.shared.isDeveloperMode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(AppState.shared.isDeveloperMode ? .green : .secondary)
                    }
                }

                Section("Active URLs") {
                    LabeledContent("WS API", value: ConfigManager.shared.webserviceURL
                        .replacingOccurrences(of: "https://", with: ""))
                    LabeledContent("Client API", value: ConfigManager.shared.clientApiURL
                        .replacingOccurrences(of: "https://", with: ""))
                    LabeledContent("Azure Files", value: ConfigManager.shared.azureFileURL
                        .replacingOccurrences(of: "https://", with: ""))
                }

                Section("Info") {
                    LabeledContent("App Version", value: "1.0.0")
                    LabeledContent("Build", value: "Swift POC")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
