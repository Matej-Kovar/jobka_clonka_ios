import Foundation

struct EnvironmentConfig: Codable {
    let webserviceUrl: String
    let clientApiUrl: String
    let azureFileUrl: String
}

struct PublicConfig: Codable {
    let Production: EnvironmentConfig
    let Test: EnvironmentConfig
}

@MainActor
final class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    @Published private(set) var currentEnvironment: AppEnvironment = .test

    enum AppEnvironment: String, CaseIterable {
        case production = "Production"
        case test = "Test"
        case testCore = "Test (core)"
        case custom = "Custom"
    }

    private var config: PublicConfig?

    // Custom environment URLs (user-editable)
    @Published var customWebserviceURL = ""
    @Published var customClientApiURL = ""
    @Published var customAzureFileURL = ""

    var webserviceURL: String {
        switch currentEnvironment {
        case .production: return config?.Production.webserviceUrl ?? ""
        case .test: return "https://jobka-test-api.azurewebsites.net"
        case .testCore: return config?.Test.webserviceUrl ?? ""
        case .custom: return customWebserviceURL
        }
    }

    var clientApiURL: String {
        switch currentEnvironment {
        case .production: return config?.Production.clientApiUrl ?? ""
        case .test: return config?.Test.clientApiUrl ?? ""
        case .testCore: return config?.Test.clientApiUrl ?? ""
        case .custom: return customClientApiURL
        }
    }

    var azureFileURL: String {
        switch currentEnvironment {
        case .production: return config?.Production.azureFileUrl ?? ""
        case .test: return config?.Test.azureFileUrl ?? ""
        case .testCore: return config?.Test.azureFileUrl ?? ""
        case .custom: return customAzureFileURL
        }
    }

    func loadConfig() {
        AppLogger.general.info("Loading publicConfig.json...")

        // Restore custom URLs from UserDefaults
        customWebserviceURL = UserDefaults.standard.string(forKey: "custom_ws_url") ?? ""
        customClientApiURL = UserDefaults.standard.string(forKey: "custom_client_url") ?? ""
        customAzureFileURL = UserDefaults.standard.string(forKey: "custom_azure_url") ?? ""

        if let path = Bundle.main.path(forResource: "publicConfig", ofType: "json"),
            let data = FileManager.default.contents(atPath: path)
        {
            do {
                config = try JSONDecoder().decode(PublicConfig.self, from: data)
                AppLogger.general.info(
                    "Config loaded: env=\(self.currentEnvironment.rawValue) wsUrl=\(self.webserviceURL) clientUrl=\(self.clientApiURL)"
                )
                return
            } catch {
                AppLogger.general.error(
                    "Failed to decode config: \(error.localizedDescription)")
            }
        }

        // Fallback: hardcode URLs
        AppLogger.general.warning(
            "publicConfig.json not found in bundle, using hardcoded URLs")
        config = PublicConfig(
            Production: EnvironmentConfig(
                webserviceUrl:
                    "https://jobka-production-webservice-core.azurewebsites.net",
                clientApiUrl: "https://jobka-production-client-api.azurewebsites.net",
                azureFileUrl: "https://jobkaproduction.file.core.windows.net"
            ),
            Test: EnvironmentConfig(
                webserviceUrl: "https://jobka-test-webservice-core.azurewebsites.net",
                clientApiUrl: "https://jobka-test-client-api.azurewebsites.net",
                azureFileUrl: "https://jobkatest.file.core.windows.net"
            )
        )
    }

    func switchEnvironment(_ env: AppEnvironment) {
        currentEnvironment = env
        AppLogger.general.info("Switched to \(env.rawValue) environment — ws=\(self.webserviceURL)")
    }

    func saveCustomURLs() {
        UserDefaults.standard.set(customWebserviceURL, forKey: "custom_ws_url")
        UserDefaults.standard.set(customClientApiURL, forKey: "custom_client_url")
        UserDefaults.standard.set(customAzureFileURL, forKey: "custom_azure_url")
        AppLogger.general.info("Custom URLs saved")
    }

    func webserviceBaseURL(for env: AppEnvironment) -> String {
        switch env {
        case .production: return config?.Production.webserviceUrl ?? "—"
        case .test: return "https://jobka-test-api.azurewebsites.net"
        case .testCore: return config?.Test.webserviceUrl ?? "—"
        case .custom: return customWebserviceURL.isEmpty ? "Not configured" : customWebserviceURL
        }
    }
}
