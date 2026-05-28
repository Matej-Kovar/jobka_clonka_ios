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
                            Text(sessionManager.currentProfile?.displayName ?? L10n.Profile_User.string)
                                .font(.title3.bold())
                            Text("\(L10n.Auth_PN.string): \(sessionManager.currentProfile?.personalNumber ?? L10n.Unknown.string)")
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
                    Section(L10n.Profile_Details.key) {
                        if let lang = profile.lang {
                            Label(lang, systemImage: "globe")
                        }
                        if profile.isTester == true {
                            Label(L10n.Profile_TesterAccount.key, systemImage: "wrench.and.screwdriver")
                        }
                    }
                }

                // Photo actions
                Section {
                    Button(role: .destructive) {
                        Task { await viewModel.deletePhoto() }
                    } label: {
                        Label(L10n.Profile_RemovePhoto.key, systemImage: "trash")
                    }
                }

                // Navigation
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label(L10n.Profile_Settings.key, systemImage: "gearshape")
                    }
                    NavigationLink(destination: AboutAppView()) {
                        Label(L10n.Profile_About.key, systemImage: "info.circle")
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
                        Label(L10n.Profile_Logout.key, systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle(L10n.Profile_Title.key)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Done.key) { dismiss() }
                }
            }
            .task { await viewModel.load() }
        }
    }
}
