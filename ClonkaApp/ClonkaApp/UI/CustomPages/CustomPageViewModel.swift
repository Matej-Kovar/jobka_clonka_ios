import Foundation

@MainActor
final class CustomPageViewModel: ObservableObject {
    @Published var pages: [CustomPage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    func load() async {
        isLoading = true
        errorMessage = nil

        AppLogger.api.info("📄 CustomPage: loading moduleId=\(self.moduleId)")

        let result = await CustomPageAPIService.fetchPages(companyMenuItemId: moduleId)
        switch result {
        case .success(let items):
            pages = items
            AppLogger.api.info("📄 CustomPage: loaded \(items.count) page(s)")
        case .failure(let error):
            errorMessage = error.localizedDescription
            AppLogger.api.error("📄 CustomPage: failed — \(error.localizedDescription)")
        }
        isLoading = false
    }
}
