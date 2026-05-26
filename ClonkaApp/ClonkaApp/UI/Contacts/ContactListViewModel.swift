import Foundation

@MainActor
final class ContactListViewModel: ObservableObject {
    @Published var contacts: [ContactItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    var filteredContacts: [ContactItem] {
        if searchText.isEmpty { return contacts }
        return contacts.filter {
            ($0.DisplayName ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.JobTitle ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.Department ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await ContactAPIService.fetchContacts(companyMenuItemId: moduleId)
        switch result {
        case .success(let resp): contacts = resp.Data ?? []
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
