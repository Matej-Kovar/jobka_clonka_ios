import SwiftUI

struct StreamDetailView: View {
    @StateObject private var viewModel: StreamDetailViewModel

    init(postId: Int) {
        _viewModel = StateObject(wrappedValue: StreamDetailViewModel(postId: postId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                SLoading()
            } else if let error = viewModel.errorMessage {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if let detail = viewModel.detail {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Original post
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    SAvatar(initials: String((detail.Author ?? "?").prefix(1)), color: nil, size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(detail.Author ?? "Unknown")
                                            .font(.subheadline.weight(.semibold))
                                        if let date = detail.DateCreated {
                                            Text(date, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Text(detail.Message ?? "")
                                    .font(.body)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
                            }

                            // Comments
                            if let comments = detail.Comments, !comments.isEmpty {
                                HStack {
                                    Text("Comments")
                                        .font(.headline)
                                    Text("(\(comments.count))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(comments) { comment in
                                    HStack(alignment: .top, spacing: 10) {
                                        SAvatar(initials: String((comment.Author ?? "?").prefix(1)), color: nil, size: 30)
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(comment.Author ?? "")
                                                    .font(.caption.bold())
                                                Spacer()
                                                if let d = comment.DateCreated {
                                                    Text(d, style: .relative)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Text(comment.Comment ?? "")
                                                .font(.body)
                                        }
                                    }
                                    .padding(12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemGray6))
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    // Comment input
                    Divider()
                    HStack(spacing: 10) {
                        TextField("Add comment...", text: $viewModel.commentText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        Button {
                            Task { await viewModel.addComment() }
                        } label: {
                            if viewModel.isCommenting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.body)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Circle())
                        .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isCommenting)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .navigationTitle(viewModel.detail?.DisplayName ?? "Post")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}
