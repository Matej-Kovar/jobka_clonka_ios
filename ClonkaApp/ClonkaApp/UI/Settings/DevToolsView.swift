import SwiftUI

struct DevToolsView: View {
    @StateObject private var errorStore = ErrorReportStore.shared
    @State private var selectedEntry: ErrorReportStore.ErrorEntry?
    @State private var showCopied = false

    var body: some View {
        List {
            Section("Overview") {
                NavigationLink {
                    DebugLogView()
                } label: {
                    HStack {
                        Label("Debug Log", systemImage: "terminal")
                        Spacer()
                        Text("\(DebugLogStore.shared.entries.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent(
                    "Errors",
                    value: "\(errorStore.entries.filter { $0.type == .error }.count)")
                LabeledContent(
                    "Slow Requests",
                    value: "\(errorStore.entries.filter { $0.type == .slow }.count)")

                HStack {
                    Text("Slow Threshold")
                    Spacer()
                    TextField(
                        "seconds", value: $errorStore.slowRequestThreshold,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                    Text("s")
                }
            }

            Section("Environment") {
                LabeledContent("API", value: ConfigManager.shared.currentEnvironment.rawValue)
                LabeledContent(
                    "WS URL",
                    value: ConfigManager.shared.webserviceURL
                        .replacingOccurrences(of: "https://", with: ""))
                LabeledContent(
                    "Client API",
                    value: ConfigManager.shared.clientApiURL
                        .replacingOccurrences(of: "https://", with: ""))
                if let profile = SessionManager.shared.currentProfile {
                    LabeledContent("User", value: profile.displayName)
                    LabeledContent(
                        "ID_Login", value: AppLogger.redact(profile.idLogin))
                }
            }

            Section("App Info") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                LabeledContent(
                    "Platform",
                    value: UIDevice.current.systemName + " "
                        + UIDevice.current.systemVersion)
                LabeledContent("Device", value: UIDevice.current.name)
            }

            Section("Actions") {
                Button("Copy Error Log") {
                    UIPasteboard.general.string = errorStore.copyToClipboard()
                    showCopied = true
                }
                Button("Copy Device Info") {
                    let info = """
                        Clonka Swift v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
                        Device: \(UIDevice.current.name)
                        API: \(ConfigManager.shared.currentEnvironment.rawValue)
                        WS: \(ConfigManager.shared.webserviceURL)
                        Errors: \(errorStore.entries.count)
                        """
                    UIPasteboard.general.string = info
                    showCopied = true
                }
                Button("Clear Error Log", role: .destructive) {
                    errorStore.clear()
                }
                Button("Clear All Data", role: .destructive) {
                    UserDefaults.standard.removePersistentDomain(
                        forName: Bundle.main.bundleIdentifier ?? "")
                }
            }

            Section("Error Log (\(errorStore.entries.count))") {
                if errorStore.entries.isEmpty {
                    Text("No errors recorded")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(errorStore.entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            HStack(spacing: 8) {
                                Text(entry.type == .error ? "🔴" : "🟡")
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(entry.method)
                                            .font(.caption.monospaced().bold())
                                        Text(entry.statusCode.map { "\($0)" } ?? "—")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(
                                                entry.type == .error ? .red : .orange)
                                        if let d = entry.duration {
                                            Text(String(format: "%.1fs", d))
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text(entry.url)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Text(entry.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
        .navigationTitle("Developer Tools")
        .alert("Copied!", isPresented: $showCopied) {
            Button("OK") {}
        }
        .sheet(item: $selectedEntry) { entry in
            ErrorDetailSheet(entry: entry)
        }
    }
}

// MARK: - Error Detail Sheet

struct ErrorDetailSheet: View {
    let entry: ErrorReportStore.ErrorEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        detailRow("Type", value: entry.type.rawValue)
                        detailRow("URL", value: entry.url)
                        detailRow("Method", value: entry.method)
                        detailRow("Status", value: entry.statusCode.map { "\($0)" } ?? "—")
                        detailRow(
                            "Duration",
                            value: entry.duration.map { String(format: "%.3fs", $0) } ?? "—")
                        detailRow(
                            "Time",
                            value: entry.timestamp.formatted(
                                date: .abbreviated, time: .standard))
                    }

                    if let msg = entry.errorMessage {
                        detailBlock("Error", content: msg)
                    }
                    if let body = entry.requestBody {
                        detailBlock("Request Body", content: body)
                    }
                    if let body = entry.responseBody {
                        detailBlock("Response Body", content: body)
                    }
                }
                .padding()
            }
            .navigationTitle("Error Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Copy") {
                        let text = """
                            [\(entry.type.rawValue)] \(entry.method) \(entry.url)
                            Status: \(entry.statusCode ?? 0)
                            Duration: \(entry.duration.map { String(format: "%.3f", $0) } ?? "-")s
                            Error: \(entry.errorMessage ?? "-")
                            Request: \(entry.requestBody ?? "-")
                            Response: \(entry.responseBody ?? "-")
                            """
                        UIPasteboard.general.string = text
                    }
                }
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption.bold()).frame(width: 70, alignment: .leading)
            Text(value).font(.caption.monospaced()).textSelection(.enabled)
        }
    }

    private func detailBlock(_ label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold())
            Text(content)
                .font(.caption2.monospaced())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .textSelection(.enabled)
        }
    }
}
