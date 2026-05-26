import SwiftUI

struct MessageListView: View {
    let moduleId: Int
    @StateObject private var viewModel: MessageListViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: MessageListViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                SLoading()
            } else if let error = viewModel.errorMessage, viewModel.conversations.isEmpty {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if viewModel.conversations.isEmpty {
                SEmptyState(icon: "bubble.left.and.bubble.right", message: "No conversations")
            } else {
                List(viewModel.conversations) { convo in
                    NavigationLink(value: ChatDestination(
                        employeeId: convo.ID_Employee,
                        groupId: convo.ID_MessageGroup,
                        menuItemId: moduleId,
                        title: convo.displayTitle
                    )) {
                        conversationRow(convo)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Messages")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.showNewChatSheet = true
                        Task { await viewModel.loadEmployees() }
                    } label: {
                        Label("New Message", systemImage: "person")
                    }
                    Button {
                        viewModel.showNewGroupSheet = true
                    } label: {
                        Label("New Group", systemImage: "person.3")
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $viewModel.showNewChatSheet) {
            newChatSheet
        }
        .sheet(isPresented: $viewModel.showNewGroupSheet) {
            newGroupSheet
        }
    }

    // MARK: - Conversation Row

    @ViewBuilder
    private func conversationRow(_ convo: ConversationListItem) -> some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                SAvatar(
                    initials: convo.Initials ?? String((convo.displayTitle).prefix(1)),
                    color: convo.Color,
                    size: 48
                )
                if convo.IsRead == false {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .overlay {
                            Circle().strokeBorder(.white, lineWidth: 2)
                        }
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(convo.displayTitle)
                        .font(.body.weight(convo.IsRead == false ? .semibold : .regular))
                    Spacer()
                    if let sent = convo.Sent {
                        Text(sent, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let msg = convo.Message {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - New Chat Sheet (Employee Picker)

    private var newChatSheet: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingEmployees {
                    SLoading()
                } else if viewModel.filteredEmployees.isEmpty {
                    SEmptyState(icon: "person.slash", message: "No employees found")
                } else {
                    List(viewModel.filteredEmployees) { emp in
                        Button {
                            viewModel.showNewChatSheet = false
                            viewModel.employeeSearchText = ""
                            // Navigate to chat with this employee
                            startNewDM(with: emp)
                        } label: {
                            HStack(spacing: 12) {
                                SAvatar(
                                    initials: emp.initials,
                                    color: emp.Color,
                                    size: 40
                                )
                                Text(emp.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.employeeSearchText, prompt: "Search employees")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showNewChatSheet = false
                        viewModel.employeeSearchText = ""
                    }
                }
            }
        }
    }

    // MARK: - New Group Sheet

    private var newGroupSheet: some View {
        NavigationStack {
            Form {
                Section("Group Name") {
                    TextField("Enter group name", text: $viewModel.newGroupName)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showNewGroupSheet = false
                        viewModel.newGroupName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.createGroup() }
                    } label: {
                        if viewModel.isCreatingGroup {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(viewModel.newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isCreatingGroup)
                }
            }
        }
    }

    // MARK: - Start DM

    private func startNewDM(with employee: ChatEmployee) {
        let chatDest = ChatDestination(
            employeeId: employee.ID,
            groupId: nil,
            menuItemId: moduleId,
            title: employee.displayName
        )
        // Use AppState to navigate via MainTabView's NavigationStack
        AppState.shared.pendingChatNavigation = chatDest
    }

    @Environment(\.dismiss) private var dismiss
}
