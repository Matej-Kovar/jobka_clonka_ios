import SwiftUI

struct MenuGridView: View {
    @ObservedObject var viewModel: MenuViewModel
    let onItemTap: (XMLMenuItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Favorites section
                if !viewModel.favoriteItems.isEmpty && !viewModel.isInFolder {
                    Text("Favorites")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.favoriteItems) { item in
                            MenuTileView(
                                item: item,
                                badgeCount: viewModel.badgeCounts[item.itemId] ?? 0,
                                isFavorite: true
                            )
                            .onTapGesture { onItemTap(item) }
                            .onLongPressGesture {
                                viewModel.toggleFavorite(item.itemId)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)
                }

                // All items
                if viewModel.isLoading && viewModel.allMenuItems.isEmpty {
                    ForEach(0..<6, id: \.self) { _ in
                        ShimmerView()
                            .frame(height: 100)
                    }
                    .padding(.horizontal)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.refresh() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else if viewModel.filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No menu items")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.filteredItems) { item in
                            MenuTileView(
                                item: item,
                                badgeCount: viewModel.badgeCounts[item.itemId] ?? 0,
                                isFavorite: viewModel.favorites.contains(item.itemId)
                            )
                            .onTapGesture { onItemTap(item) }
                            .onLongPressGesture {
                                viewModel.toggleFavorite(item.itemId)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}
