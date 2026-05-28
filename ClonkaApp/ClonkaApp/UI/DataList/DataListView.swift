import SwiftUI

struct DataListView: View {
    let moduleId: Int
    let title: String
    @StateObject private var viewModel: DataListViewModel

    init(moduleId: Int, title: String = "Data List") {
        self.moduleId = moduleId
        self.title = title
        _viewModel = StateObject(wrappedValue: DataListViewModel(moduleId: moduleId))
    }

    var body: some View {
        contentView
            .navigationTitle(title)
            .searchable(text: $viewModel.searchText, prompt: "Search")
            .onSubmit(of: .search) { Task { await viewModel.search() } }
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .overlay {
                if viewModel.isLoadingDetail {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .overlay { ProgressView().controlSize(.large) }
                }
            }
            .sheet(item: $viewModel.selectedDetail) { detail in
                if let editFormId = detail.editFormModuleId, detail.response.IsUpdate == true {
                    NavigationStack {
                        FormView(
                            moduleId: editFormId,
                            title: detail.response.DisplayName ?? title,
                            dataId: detail.dataId
                        )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { viewModel.selectedDetail = nil }
                            }
                        }
                    }
                } else {
                    dataDetailSheet(detail)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.detailError != nil },
                set: { if !$0 { viewModel.detailError = nil } }
            )) {
                Button("OK") { viewModel.detailError = nil }
            } message: {
                Text(viewModel.detailError ?? "")
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            SLoading()
        } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
            SErrorState(message: error) { Task { await viewModel.load() } }
        } else if viewModel.items.isEmpty {
            SEmptyState(
                icon: "list.bullet",
                message: viewModel.emptyText ?? "No items found"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let desc = viewModel.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                    }

                    ForEach(viewModel.items) { item in
                        dataRow(item)
                        if item.id != viewModel.items.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }

                    if viewModel.hasMore {
                        Button {
                            Task { await viewModel.loadMore() }
                        } label: {
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Load More")
                                    .font(.callout.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dataRow(_ item: DataListItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(item.Highlighted == true ? Color.orange.opacity(0.15) : Color(.systemGray6))
                    .frame(width: 42, height: 42)
                Image(systemName: item.Highlighted == true ? "star.fill" : "doc.text")
                    .font(.body)
                    .foregroundStyle(item.Highlighted == true ? .orange : .secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.DisplayName ?? "Item")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let desc = item.Description, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let date = item.Date, !date.isEmpty {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if item.ID != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            guard item.ID != nil, !viewModel.isLoadingDetail else { return }
            Task { await viewModel.loadDetail(item: item) }
        }
    }

    // MARK: - Detail Sheet

    @ViewBuilder
    private func dataDetailSheet(_ detail: DataDetailPresentation) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    if let title = detail.response.DisplayName {
                        VStack(spacing: 6) {
                            Text(title)
                                .font(.title3.bold())
                            if let date = detail.response.DateCreated {
                                Text(date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let user = detail.response.UserInsert {
                                Text("by \(user)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                    }

                    // Detail items (key-value)
                    if let items = detail.response.Items, !items.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.DisplayName ?? "")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Text(item.Value ?? "—")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .textSelection(.enabled)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()

                                if item.id != items.last?.id {
                                    Divider().padding(.leading)
                                }
                            }
                        }
                    } else {
                        SEmptyState(icon: "doc.text", message: "No details available")
                            .frame(height: 200)
                    }

                    if let editFormId = detail.editFormModuleId, detail.response.IsUpdate == true {
                        VStack(spacing: 12) {
                            Divider()
                            NavigationLink {
                                FormView(
                                    moduleId: editFormId,
                                    title: detail.response.DisplayName ?? title,
                                    dataId: detail.dataId
                                )
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil.circle.fill")
                                    Text("Edit / Approve")
                                }
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { viewModel.selectedDetail = nil }
                }
            }
        }
    }
}
