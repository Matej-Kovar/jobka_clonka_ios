import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            // Appearance
            Section("Appearance") {
                Picker("Theme", selection: Binding<Int>(
                    get: {
                        if appState.colorSchemeOverride == .dark { return 2 }
                        if appState.colorSchemeOverride == .light { return 1 }
                        return 0
                    },
                    set: {
                        switch $0 {
                        case 1: appState.colorSchemeOverride = .light
                        case 2: appState.colorSchemeOverride = .dark
                        default: appState.colorSchemeOverride = nil
                        }
                    }
                )) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
            }

            // Language
            if !viewModel.languages.isEmpty {
                Section("Language") {
                    ForEach(viewModel.languages) { lang in
                        Button {
                            Task {
                                if let code = lang.Code {
                                    await viewModel.changeLanguage(code: code)
                                }
                            }
                        } label: {
                            HStack {
                                Text(lang.Caption ?? lang.Code ?? "")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if lang.ID == viewModel.selectedLanguage || lang.Code == viewModel.selectedLanguage {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }
            }

            // About
            Section {
                NavigationLink(destination: AboutAppView()) {
                    Label("About App", systemImage: "info.circle")
                }
            }

            // Developer-only sections (activated via version tap on login screen)
            if appState.isDeveloperMode {
                Section("Environment") {
                    LabeledContent("Mode", value: ConfigManager.shared.currentEnvironment.rawValue)
                    LabeledContent("WS API", value: ConfigManager.shared.webserviceURL
                        .replacingOccurrences(of: "https://", with: ""))
                    LabeledContent("Client API", value: ConfigManager.shared.clientApiURL
                        .replacingOccurrences(of: "https://", with: ""))
                    LabeledContent("Azure Files", value: ConfigManager.shared.azureFileURL
                        .replacingOccurrences(of: "https://", with: ""))
                }

                Section("Developer") {
                    NavigationLink {
                        DevToolsView()
                    } label: {
                        Label("Developer Tools", systemImage: "wrench.and.screwdriver")
                    }
                    NavigationLink {
                        DebugLogView()
                    } label: {
                        Label("Debug Log", systemImage: "terminal")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            viewModel.loadFromSession(sessionManager)
        }
    }
}
