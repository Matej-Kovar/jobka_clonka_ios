import Foundation

struct StreamAPIService {
    static func fetchPosts(moduleId: Int) async -> AppResult<[StreamPostItem]> {
        AppLogger.api.info("📢 Fetching stream posts module=\(moduleId)")
        return await APIClient.shared.wsGet(
            path: "/api/StreamPost/All",
            queryItems: [URLQueryItem(name: "ID_Module", value: String(moduleId))],
            responseType: [StreamPostItem].self
        )
    }

    static func fetchDetail(postId: Int) async -> AppResult<StreamPostDetail> {
        AppLogger.api.info("📢 Fetching stream detail id=\(postId)")
        return await APIClient.shared.wsGet(
            path: "/api/StreamPost/Detail",
            queryItems: [URLQueryItem(name: "ID", value: String(postId))],
            responseType: StreamPostDetail.self
        )
    }

    static func createPost(displayName: String, message: String, moduleId: Int) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/StreamPost/New",
            body: StreamPostNewRequest(ID_Login: idLogin, DisplayName: displayName, Message: message, ID_Module: moduleId),
            responseType: EmptyResponse.self
        )
    }

    static func createComment(streamPostId: Int, comment: String, parentId: Int? = nil) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/StreamPostComment/New",
            body: StreamCommentNewRequest(ID_Login: idLogin, ID_StreamPost: streamPostId, Comment: comment, ID_StreamPostParent: parentId),
            responseType: EmptyResponse.self
        )
    }
}
