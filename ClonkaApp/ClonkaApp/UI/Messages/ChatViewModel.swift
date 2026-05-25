import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var messageText = ""
    @Published var isSending = false

    let employeeId: Int?
    let groupId: Int?
    let menuItemId: Int?

    init(employeeId: Int?, groupId: Int?, menuItemId: Int?) {
        self.employeeId = employeeId
        self.groupId = groupId
        self.menuItemId = menuItemId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result: AppResult<[ChatMessage]>
        if let groupId = groupId {
            result = await MessageAPIService.fetchGroupHistory(groupId: groupId, companyMenuItemId: menuItemId ?? 0)
        } else if let employeeId = employeeId {
            result = await MessageAPIService.fetchDMHistory(employeeId: employeeId, companyMenuItemId: menuItemId ?? 0)
        } else {
            isLoading = false
            return
        }
        switch result {
        case .success(let items): messages = items
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func send() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        let result = await MessageAPIService.sendMessage(
            employeeId: employeeId, groupId: groupId,
            message: messageText, menuItemId: menuItemId
        )
        if result.isSuccess {
            messageText = ""
            await load()
        }
        isSending = false
    }
}
