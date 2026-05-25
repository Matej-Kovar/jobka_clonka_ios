import SwiftUI

struct StreamListView: View {
    let moduleId: Int
    @StateObject private var viewModel: StreamListViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showNewPost = false

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: StreamListViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                SLoading()
            } else if let error = viewModel.errorMessage, viewModel.posts.isEmpty {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if viewModel.posts.isEmpty {
                SEmptyState(icon: "text.bubble", message: "No posts yet. Be the first!")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(value: StreamDetailDestination(postId: post.id)) {
                                streamCard(post)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Stream")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewPost = true } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .sheet(isPresented: $showNewPost) {
            newPostSheet
        }
    }

    @ViewBuilder
    private func streamCard(_ post: StreamPostItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SAvatar(initials: String((post.Author ?? "?").prefix(1)), color: nil, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.Author ?? "Unknown")
                        .font(.subheadline.weight(.semibold))
                    if let date = post.DateCreated {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Text(post.Message ?? "")
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            if let count = post.NumberOfComments, count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("\(count)")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
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
    }

    // MARK: - New Post Sheet (replaces alert)

    private var newPostSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $viewModel.newPostMessage)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(.systemGray4), lineWidth: 1)
                    }
                    .frame(minHeight: 120)

                Text("\(viewModel.newPostMessage.count) characters")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Spacer()
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.newPostMessage = ""
                        showNewPost = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task {
                            await viewModel.createPost(displayName: sessionManager.currentProfile?.displayName ?? "")
                            showNewPost = false
                        }
                    }
                    .disabled(viewModel.newPostMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
