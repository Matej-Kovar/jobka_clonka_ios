import SwiftUI

struct ContactListView: View {
    let moduleId: Int
    @StateObject private var viewModel: ContactListViewModel
    @State private var selectedContact: ContactItem?

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: ContactListViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contacts.isEmpty {
                SLoading()
            } else if let error = viewModel.errorMessage, viewModel.contacts.isEmpty {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if viewModel.contacts.isEmpty {
                SEmptyState(icon: "person.2", message: "No contacts found")
            } else {
                List(viewModel.filteredContacts) { contact in
                    Button {
                        selectedContact = contact
                    } label: {
                        HStack(spacing: 14) {
                            SAvatar(initials: contact.Initials, color: contact.Color, size: 48)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(contact.DisplayName ?? "Unknown")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                if let job = contact.JobTitle {
                                    Text(job)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if let dept = contact.Department {
                                    Text(dept)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()

                            if contact.Phone != nil || contact.Email != nil {
                                Image(systemName: "ellipsis.circle")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Contacts")
        .searchable(text: $viewModel.searchText, prompt: "Search contacts")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .sheet(item: $selectedContact) { contact in
            contactDetailSheet(contact)
        }
    }

    @ViewBuilder
    private func contactDetailSheet(_ contact: ContactItem) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 12) {
                        SAvatar(initials: contact.Initials, color: contact.Color, size: 80)
                        VStack(spacing: 4) {
                            Text(contact.DisplayName ?? "")
                                .font(.title3.bold())
                            if let job = contact.JobTitle {
                                Text(job)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let dept = contact.Department {
                                Text(dept)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // Action buttons
                    HStack(spacing: 16) {
                        if let phone = contact.Phone, !phone.isEmpty,
                           let url = URL(string: "tel:\(phone)") {
                            Link(destination: url) {
                                VStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                        .font(.title3)
                                        .frame(width: 50, height: 50)
                                        .background(Color.green.opacity(0.12))
                                        .foregroundStyle(.green)
                                        .clipShape(Circle())
                                    Text("Call")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if let email = contact.Email, !email.isEmpty,
                           let url = URL(string: "mailto:\(email)") {
                            Link(destination: url) {
                                VStack(spacing: 6) {
                                    Image(systemName: "envelope.fill")
                                        .font(.title3)
                                        .frame(width: 50, height: 50)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(Circle())
                                    Text("Email")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Info rows
                    VStack(spacing: 0) {
                        if let phone = contact.Phone, !phone.isEmpty {
                            infoRow(icon: "phone", label: "Phone", value: phone)
                            Divider().padding(.leading, 52)
                        }
                        if let email = contact.Email, !email.isEmpty {
                            infoRow(icon: "envelope", label: "Email", value: email)
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemBackground))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(.systemGray5), lineWidth: 1)
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { selectedContact = nil }
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .textSelection(.enabled)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
