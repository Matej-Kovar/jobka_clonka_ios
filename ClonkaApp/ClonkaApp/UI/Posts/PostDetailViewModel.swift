import Foundation

@MainActor
final class PostDetailViewModel: ObservableObject {
    @Published var detail: PostDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isApproved = false
    @Published var isApproving = false
    @Published var approveError: String?
    @Published var checkboxChecked = false

    let postId: Int
    init(postId: Int) { self.postId = postId }

    var needsApproval: Bool {
        guard let detail else { return false }
        let type = detail.approvalType ?? "none"
        return type == "approve" || type == "approveWithCheckbox"
    }

    var needsCheckbox: Bool {
        detail?.approvalType == "approveWithCheckbox"
    }

    var canApprove: Bool {
        if needsCheckbox { return checkboxChecked }
        return true
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await PostAPIService.fetchPostDetail(postId: postId)
        switch result {
        case .success(let d):
            detail = d
            isApproved = d.dateApproved != nil || d.isManuallyApproved == true
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
        _ = await PostAPIService.markRead(postId: postId)
    }

    func approve() async {
        guard canApprove else { return }
        isApproving = true
        approveError = nil
        let result = await PostAPIService.approve(postId: postId)
        if result.isSuccess {
            isApproved = true
        } else {
            approveError = result.error?.localizedDescription ?? "Approval failed"
        }
        isApproving = false
    }
}
