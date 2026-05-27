import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    let title: String

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
                                ForEach(attachments) { att in
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
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            }
        }
        .navigationTitle(L10n.Post_Detail.string)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}
