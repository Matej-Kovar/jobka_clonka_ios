import Foundation

@MainActor
final class SurveyListViewModel: ObservableObject {
    @Published var surveys: [SurveyListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await SurveyAPIService.fetchSurveys(moduleId: moduleId)
        switch result {
        case .success(let items): surveys = items
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
