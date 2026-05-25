import SwiftUI

struct DebugLogView: View {
    @StateObject private var store = DebugLogStore.shared
    @State private var activeTab: DebugLogStore.LogSource?
    @State private var selectedLevel: DebugLogStore.LogLevel?
    @State private var showCopied = false

    private var filteredEntries: [DebugLogStore.Entry] {
        store.filtered(source: activeTab, level: selectedLevel).reversed()
    }

    var body: some View {
        List {
            // Tab picker
            Section {
                Picker("Source", selection: $activeTab) {
                    Text("All").tag(DebugLogStore.LogSource?.none)
                    Text("HTTP").tag(DebugLogStore.LogSource?.some(.http))
                    Text("App").tag(DebugLogStore.LogSource?.some(.app))
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            // Level filter
            Section {
                HStack(spacing: 8) {
                    ForEach(
                        [DebugLogStore.LogLevel.info, .warn, .error],
                        id: \.rawValue
                    ) { lvl in
                        Button {
                            selectedLevel = selectedLevel == lvl ? nil : lvl
                        } label: {
                            Text(lvl.rawValue.uppercased())
                                .font(.caption2.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    selectedLevel == lvl
                                        ? levelColor(lvl) : Color(.systemGray5)
                                )
                                .foregroundStyle(
                                    selectedLevel == lvl ? .white : .primary
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Text("\(filteredEntries.count)/\(store.entries.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            // Entries
            if filteredEntries.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "terminal")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No log entries yet")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                Section("Log Entries") {
                    ForEach(filteredEntries) { entry in
                        DisclosureGroup {
                            entryDetail(entry)
                        } label: {
                            entryRow(entry)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Debug Log")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = store.copyToClipboard()
                    showCopied = true
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(store.entries.isEmpty)

                Button(role: .destructive) {
                    store.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(store.entries.isEmpty)
            }
        }
        .alert("Copied!", isPresented: $showCopied) {
            Button("OK") {}
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func entryRow(_ entry: DebugLogStore.Entry) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(entry.level.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(levelColor(entry.level))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                if entry.source == .http, let method = entry.method {
                    Text(method)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(JobkaTheme.primary, lineWidth: 1)
                        )
                        .foregroundStyle(JobkaTheme.primary)
                }

                if let status = entry.httpStatus {
                    Text("\(status)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(status >= 400 ? .red : .primary)
                }

                if let ms = entry.durationMs {
                    Text("\(ms)ms")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Text(entry.source == .http ? (entry.url ?? entry.message) : entry.message)
                .font(.caption)
                .lineLimit(1)

            HStack(spacing: 4) {
                if entry.source == .app {
                    Text("[\(entry.tag)]")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private func entryDetail(_ entry: DebugLogStore.Entry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.source == .app {
                detailBlock("Message", content: entry.message)
            }
            if let url = entry.url, entry.source == .http {
                detailBlock("URL", content: url)
            }
            if let detail = entry.detail {
                detailBlock("Detail", content: detail)
            }
            if entry.detail == nil && entry.source == .http {
                Text("No response body captured")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func detailBlock(_ label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(content)
                .font(.system(size: 11, design: .monospaced))
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .textSelection(.enabled)
        }
    }

    private func levelColor(_ level: DebugLogStore.LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warn: return .orange
        case .error: return .red
        }
    }
}
