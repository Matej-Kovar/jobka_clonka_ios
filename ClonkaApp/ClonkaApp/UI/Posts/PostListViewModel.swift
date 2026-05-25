import Foundation

@MainActor
final class PostListViewModel: ObservableObject {
    @Published var posts: [PostListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    func loadPosts() async {
        isLoading = true
        errorMessage = nil
        let result = await PostAPIService.fetchPosts(companyMenuItemId: moduleId)
        switch result {
        case .success(let items): posts = items
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markAllRead() async {
        _ = await PostAPIService.markAllRead(companyMenuItemId: moduleId)
        await loadPosts()
    }
}
