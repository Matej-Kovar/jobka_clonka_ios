import Foundation

@MainActor
final class StreamListViewModel: ObservableObject {
    @Published var posts: [StreamPostItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newPostMessage = ""
    @Published var isPosting = false

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await StreamAPIService.fetchPosts(moduleId: moduleId)
        switch result {
        case .success(let items): posts = items
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createPost(displayName: String) async {
        guard !newPostMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isPosting = true
        let result = await StreamAPIService.createPost(displayName: displayName, message: newPostMessage, moduleId: moduleId)
        if result.isSuccess {
            newPostMessage = ""
            await load()
        }
        isPosting = false
    }
}
