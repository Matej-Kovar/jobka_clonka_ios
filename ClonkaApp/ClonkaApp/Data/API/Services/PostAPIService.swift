import Foundation

struct PostAPIService {
    static func fetchPosts(companyMenuItemId: Int) async -> AppResult<[PostListItem]> {
        AppLogger.api.info("📰 Fetching posts for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.clientGet(
            path: "/client/v1/post",
            queryItems: [URLQueryItem(name: "CompanyMenuItemId", value: String(companyMenuItemId))],
            responseType: [PostListItem].self
        )
    }

    static func fetchPostDetail(postId: Int) async -> AppResult<PostDetail> {
        AppLogger.api.info("📰 Fetching post detail id=\(postId)")
        return await APIClient.shared.clientGet(
            path: "/client/v1/post/\(postId)",
            queryItems: [],
            responseType: PostDetail.self
        )
    }

    static func markRead(postId: Int) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.clientPost(
            path: "/client/v1/post/\(postId)/read",
            body: PostReadRequest(ID_Login: idLogin),
            responseType: EmptyResponse.self
        )
    }

    static func markAllRead(companyMenuItemId: Int) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.clientPost(
            path: "/client/v1/post/readall",
            body: PostReadAllRequest(ID_Login: idLogin, CompanyMenuItemId: companyMenuItemId),
            responseType: EmptyResponse.self
        )
    }

    static func approve(postId: Int) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.clientPost(
            path: "/client/v1/post/\(postId)/approve",
            body: PostApproveRequest(ID_Login: idLogin),
            responseType: EmptyResponse.self
        )
    }

    static func fetchPopups() async -> AppResult<[PostPopup]> {
        return await APIClient.shared.clientGet(
            path: "/client/v1/post/popup",
            queryItems: [],
            responseType: [PostPopup].self
        )
    }
}
