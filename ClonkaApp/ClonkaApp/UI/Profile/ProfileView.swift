import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Header section
                Section {
                    HStack(spacing: 16) {
                        SAvatar(
                            initials: sessionManager.currentProfile?.initials,
                            color: sessionManager.currentProfile?.color,
                            size: 70
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionManager.currentProfile?.displayName ?? "User")
                                .font(.title3.bold())
                            Text("PN: \(sessionManager.currentProfile?.personalNumber ?? "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let email = sessionManager.currentProfile?.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let phone = sessionManager.currentProfile?.phone {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Extended profile info
                if let profile = viewModel.profile {
                    Section("Details") {
                        if let lang = profile.lang {
                            Label(lang, systemImage: "globe")
                        }
                        if profile.isTester == true {
                            Label("Tester Account", systemImage: "wrench.and.screwdriver")
                        }
                    }
                }

                // Photo actions
                Section {
                    Button(role: .destructive) {
                        Task { await viewModel.deletePhoto() }
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }

                // Navigation
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    NavigationLink(destination: AboutAppView()) {
                        Label("About", systemImage: "info.circle")
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        Task {
                            await sessionManager.logout()
                            dismiss()
                        }
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.load() }
        }
    }
}
