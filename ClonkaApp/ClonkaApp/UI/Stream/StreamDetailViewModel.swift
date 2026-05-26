import Foundation

@MainActor
final class StreamDetailViewModel: ObservableObject {
    @Published var detail: StreamPostDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var commentText = ""
    @Published var isCommenting = false

    let postId: Int
    init(postId: Int) { self.postId = postId }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await StreamAPIService.fetchDetail(postId: postId)
        switch result {
        case .success(let d): detail = d
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addComment() async {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isCommenting = true
        let result = await StreamAPIService.createComment(streamPostId: postId, comment: commentText)
        if result.isSuccess {
            commentText = ""
            await load()
        }
        isCommenting = false
    }
}
