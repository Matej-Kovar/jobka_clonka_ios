import Foundation

@MainActor
final class MessageListViewModel: ObservableObject {
    @Published var conversations: [ConversationListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // New chat
    @Published var showNewChatSheet = false
    @Published var availableEmployees: [ChatEmployee] = []
    @Published var isLoadingEmployees = false
    @Published var employeeSearchText = ""

    // New group
    @Published var showNewGroupSheet = false
    @Published var newGroupName = ""
    @Published var isCreatingGroup = false

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    var filteredEmployees: [ChatEmployee] {
        if employeeSearchText.isEmpty { return availableEmployees }
        return availableEmployees.filter {
            $0.displayName.localizedCaseInsensitiveContains(employeeSearchText)
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await MessageAPIService.fetchConversations(companyMenuItemId: moduleId)
        switch result {
        case .success(let items): conversations = items
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadEmployees() async {
        isLoadingEmployees = true
        let result = await MessageAPIService.fetchAvailableEmployees(companyMenuItemId: moduleId)
        switch result {
        case .success(let emps): availableEmployees = emps
        case .failure(let error):
            AppLogger.api.error("💬 Failed to load employees: \(error.localizedDescription)")
        }
        isLoadingEmployees = false
    }

    func createGroup() async {
        guard !newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isCreatingGroup = true
        let result = await MessageAPIService.createGroup(
            displayName: newGroupName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: nil,
            menuItemId: moduleId
        )
        if result.isSuccess {
            showNewGroupSheet = false
            newGroupName = ""
            await load()
        }
        isCreatingGroup = false
    }
}
