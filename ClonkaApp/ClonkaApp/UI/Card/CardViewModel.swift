import Foundation

@MainActor
final class CardViewModel: ObservableObject {
    @Published var card: CardInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await CardAPIService.fetchCard(companyMenuItemId: moduleId)
        switch result {
        case .success(let info): card = info
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
