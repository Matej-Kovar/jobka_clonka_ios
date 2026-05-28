import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    let title: String
    @State private var showPDF: Bool = false
    @State private var pdfURL: URL?

    init(postId: Int, title: String = L10n.Post_Title.string) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: postId))
        self.title = title
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                SLoading()
            } else if let error = viewModel.errorMessage {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if let detail = viewModel.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(detail.displayName ?? title)
                                .font(.title2.bold())
                            if let date = detail.datePublish {
                                Label {
                                    Text(date, style: .date)
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }

                        Divider()
                            .padding(.bottom, 12)
                        
                        if let attachments = detail.attachments {
                            let imageAttachments = attachments.filter { isImageAttachment($0) }
                            if !imageAttachments.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    SImageView(images: imageAttachments.map { SImageAttachment(documentId: $0.documentId, documentUrl: $0.documentUrl) })
                                }
                                .padding(.bottom, 8)
                            }
                        }

                        // Content
                        if let html = detail.textHtml, !html.isEmpty {
                            HTMLContentView(html: html)
                                .frame(minHeight: 200)
                        } else if let text = detail.text {
                            Text(text)
                                .font(.body)
                        }

                        // Attachments
                        if let attachments = detail.attachments, !attachments.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.Post_Attachments.string)
                                    .font(.headline)
                                let fileAttachments = attachments.filter { !isImageAttachment($0) }



                                if !fileAttachments.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(fileAttachments) { att in
                                            Button {
                                                Task {
                                                    await openAttachment(att)
                                                }
                                            } label: {
                                                HStack(spacing: 10) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                            .fill(Color(.systemGray6))
                                                            .frame(width: 36, height: 36)
                                                        Image(systemName: "paperclip")
                                                            .font(.callout)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                    Text(att.displayName ?? att.fileName ?? L10n.Post_Attachments.string)
                                                        .font(.callout)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Image(systemName: "arrow.up.right.square")
                                                        .font(.caption)
                                                        .foregroundStyle(.tertiary)
                                                }
                                                .padding(8)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color(.systemGray6))
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Approval section
                        if viewModel.needsApproval {
                            if viewModel.isApproved {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(L10n.Post_Approved.string)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.green)
                                        if let date = detail.dateApproved {
                                            Text(date, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            } else {
                                VStack(spacing: 12) {
                                    if viewModel.needsCheckbox {
                                        Button {
                                            viewModel.checkboxChecked.toggle()
                                        } label: {
                                            HStack(spacing: 10) {
                                                Image(systemName: viewModel.checkboxChecked
                                                    ? "checkmark.square.fill" : "square")
                                                    .font(.title3)
                                                    .foregroundStyle(viewModel.checkboxChecked ? Color.accentColor : Color(.systemGray3))
                                                Text(detail.textApprovalCheckbox ?? L10n.Post_ApproveMessage.string)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if let error = viewModel.approveError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }

                                    Button {
                                        Task { await viewModel.approve() }
                                    } label: {
                                        if viewModel.isApproving {
                                            ProgressView()
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                        } else {
                                            HStack(spacing: 6) {
                                                Image(systemName: "checkmark.seal")
                                                Text(detail.textApprovalButton ?? L10n.Post_Approve.string)
                                            }
                                            .font(.body.weight(.semibold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!viewModel.canApprove || viewModel.isApproving)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .task(id: detail.postId) {
                    await preloadPDFAttachments(detail.attachments ?? [])
                }
            }
        }
        .navigationTitle(L10n.Post_Detail.string)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $showPDF) {
            if let url = pdfURL {
                PDFKitView(url: url)
                    .id(url.absoluteString)
            }
        }
    }

    // MARK: - Attachments

    private func isImageAttachment(_ attachment: PostAttachment) -> Bool {
        if attachment.contentType?.lowercased().hasPrefix("image/") == true {
            return true
        }

        let candidates = [attachment.documentUrl, attachment.fileNameExtension, attachment.fileName, attachment.displayName]
            .compactMap { $0?.lowercased() }

        for value in candidates {
            if [".png", ".jpg", ".jpeg", ".gif", ".webp", ".heic", ".heif"].contains(where: { value.hasSuffix($0) }) {
                return true
            }
        }

        return false
    }

    private func isPDFAttachment(_ attachment: PostAttachment) -> Bool {
        if let ct = attachment.contentType?.lowercased(), ct.contains("pdf") { return true }
        let candidates = [attachment.documentUrl, attachment.fileNameExtension, attachment.fileName, attachment.displayName]
            .compactMap { $0?.lowercased() }
        for v in candidates {
            if v.hasSuffix(".pdf") { return true }
        }
        return false
    }

    private func openURLInBrowser(_ url: URL) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    private func resolveDocumentURL(documentUrl: String?, documentId: Int?) async -> URL? {
        if let urlStr = documentUrl, let url = URL(string: urlStr) {
            return url
        }
        if let docId = documentId {
            return await DocumentAPIService.getDocumentImageURL(documentId: docId)
        }
        return nil
    }

    private func openAttachment(_ attachment: PostAttachment) async {
        guard let url = await resolveDocumentURL(documentUrl: attachment.documentUrl, documentId: attachment.documentId) else {
            AppLogger.navigation.error("❌ Attachment has no URL or documentId")
            return
        }

        let resolvedURL = PDFDocumentResolver.resolvePDFURL(from: url)
        let preferredPDFURL: URL
        if let docId = attachment.documentId,
           let directURL = await DocumentAPIService.getDocumentImageURL(documentId: docId) {
            preferredPDFURL = directURL
        } else {
            preferredPDFURL = resolvedURL
        }
        AppLogger.navigation.debug("📎 Opening attachment URL: \(url) -> resolved: \(resolvedURL) (attachmentId=\(attachment.attachmentId ?? 0))")

        if isPDFAttachment(attachment) {
            do {
                if let cached = await PDFDocumentResolver.cachedLocalPDF(for: preferredPDFURL) {
                    await MainActor.run {
                        self.pdfURL = cached
                        self.showPDF = true
                    }
                    return
                }

                let localURL = try await PDFDocumentResolver.downloadPDFToTemporaryFile(
                    from: preferredPDFURL,
                    filePrefix: "post_attachment"
                )
                await MainActor.run {
                    self.pdfURL = localURL
                    self.showPDF = true
                }
            } catch {
                AppLogger.navigation.error("❌ Failed to load PDF in-app: \(error.localizedDescription)")
            }
            return
        }

        openURLInBrowser(resolvedURL)
    }

    private func preloadPDFAttachments(_ attachments: [PostAttachment]) async {
        for attachment in attachments where isPDFAttachment(attachment) {
            guard let url = await resolveDocumentURL(documentUrl: attachment.documentUrl, documentId: attachment.documentId) else { continue }
            let resolvedURL = PDFDocumentResolver.resolvePDFURL(from: url)
            let preferredPDFURL: URL
            if let docId = attachment.documentId,
               let directURL = await DocumentAPIService.getDocumentImageURL(documentId: docId) {
                preferredPDFURL = directURL
            } else {
                preferredPDFURL = resolvedURL
            }
            await PDFDocumentResolver.preloadPDF(from: preferredPDFURL, filePrefix: "post_attachment")
        }
    }
}
