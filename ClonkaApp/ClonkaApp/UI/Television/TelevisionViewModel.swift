import Foundation

@MainActor
final class TelevisionViewModel: ObservableObject {
    @Published var detail: TelevisionDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    var hasUrl: Bool { detail?.Url != nil && !(detail?.Url?.isEmpty ?? true) }
    var hasHtml: Bool { detail?.HtmlContent != nil && !(detail?.HtmlContent?.isEmpty ?? true) }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await TelevisionAPIService.fetchDetail(companyMenuItemId: moduleId)
        switch result {
        case .success(let resp): detail = resp
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
