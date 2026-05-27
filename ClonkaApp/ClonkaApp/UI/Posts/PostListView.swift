import SwiftUI

struct PostListView: View {
    let moduleId: Int
    let title: String
    @StateObject private var viewModel: PostListViewModel

    init(moduleId: Int, title: String = "Posts") {
        self.moduleId = moduleId
        self.title = title
        _viewModel = StateObject(wrappedValue: PostListViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                SLoading()
            } else if let error = viewModel.errorMessage, viewModel.posts.isEmpty {
                SErrorState(message: error) { Task { await viewModel.loadPosts() } }
            } else if viewModel.posts.isEmpty {
                SEmptyState(icon: "newspaper", message: "No posts yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(value: PostDetailDestination(postId: post.postId)) {
                                postRow(post)
                            }
                            .buttonStyle(.plain)

                            if post.postId != viewModel.posts.last?.postId {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.markAllRead() }
                } label: {
                    Image(systemName: "checkmark.circle")
                }
            }
        }
        .refreshable { await viewModel.loadPosts() }
        .task { await viewModel.loadPosts() }
    }

    @ViewBuilder
    private func postRow(_ post: PostListItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(post.isRead ? Color(.systemGray6) : Color.blue.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: post.isRead ? "envelope.open" : "envelope.badge.fill")
                    .font(.body)
                    .foregroundStyle(post.isRead ? Color.secondary : Color.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(post.displayName ?? "Post")
                        .font(.body.weight(post.isRead ? .regular : .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if post.needsApproval && post.dateApproved == nil {
                        Image(systemName: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if post.dateApproved != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                if let date = post.datePublish {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let text = post.text {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(post.isRead ? Color.clear : Color.blue.opacity(0.02))
        .contentShape(Rectangle())
    }
}
