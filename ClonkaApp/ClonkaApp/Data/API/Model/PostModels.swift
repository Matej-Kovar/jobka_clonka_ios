import Foundation

// MARK: - Client.Api Post models

struct PostListItem: Decodable, Identifiable {
    let postId: Int
    let displayName: String?
    let text: String?
    let textHtml: String?
    let approvalType: String?
    let textApprovalButton: String?
    let textApprovalCheckbox: String?
    let datePublish: Date?
    let dateUpdate: Date?
    let dateRead: Date?
    let dateApproved: Date?
    let isPopUp: Bool?

    var id: Int { postId }
    var isRead: Bool { dateRead != nil }
    var needsApproval: Bool {
        let type = approvalType ?? "none"
        return type == "approve" || type == "approveWithCheckbox"
    }
}

struct PostDetail: Decodable {
    let postId: Int
    let displayName: String?
    let text: String?
    let textHtml: String?
    let approvalType: String?
    let textApprovalButton: String?
    let textApprovalCheckbox: String?
    let datePublish: Date?
    let dateUpdate: Date?
    let dateRead: Date?
    let dateApproved: Date?
    let isManuallyApproved: Bool?
    let isPopUp: Bool?
    let attachments: [PostAttachment]?
}

struct PostAttachment: Decodable, Identifiable {
    let attachmentId: Int?
    let postId: Int?
    let documentId: Int?
    let documentHash: String?
    let documentUrl: String?
    let displayName: String?
    let size: Int?
    let fileName: String?
    let contentType: String?
    let `extension`: String?
    let hash: String?
    let fileNameExtension: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let order: Int?
    let isDownload: Bool?

    var id: Int { attachmentId ?? 0 }
    var isImage: Bool {
        contentType?.starts(with: "image/") ?? false
    }
}

struct PostPopup: Decodable, Identifiable {
    let postId: Int
    let moduleId: Int?
    let displayName: String?
    let text: String?
    let textHtml: String?
    let datePublish: Date?

    var id: Int { postId }
}

// MARK: - Request bodies

struct PostReadRequest: Encodable {
    let ID_Login: String
}

struct PostReadAllRequest: Encodable {
    let ID_Login: String
    let CompanyMenuItemId: Int
}

struct PostApproveRequest: Encodable {
    let ID_Login: String
}
