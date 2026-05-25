import Foundation

struct DataDetailPresentation: Identifiable {
    let id = UUID()
    let response: DataDetailResponse
}

@MainActor
final class DataListViewModel: ObservableObject {
    @Published var items: [DataListItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isLoadingDetail = false
    @Published var errorMessage: String?
    @Published var detailError: String?
    @Published var searchText = ""
    @Published var hasMore = false
    @Published var isDetail = false
    @Published var emptyText: String?
    @Published var description: String?
    @Published var canCreateNew = false
    @Published var newFormMenuItemId: Int?
    @Published var selectedDetail: DataDetailPresentation?

    let moduleId: Int
    private var page = 0
    private let pageSize = 20

    init(moduleId: Int) { self.moduleId = moduleId }

    func load() async {
        isLoading = true
        errorMessage = nil
        page = 0
        let result = await DataListAPIService.fetchList(
            companyMenuItemId: moduleId, search: searchText.isEmpty ? nil : searchText,
            top: pageSize, offset: 0
        )
        switch result {
        case .success(let data):
            items = data.Items ?? []
            hasMore = (data.Items?.count ?? 0) >= pageSize
            emptyText = data.EmptyDataText
            description = data.Description
            canCreateNew = data.IsNew == true
            isDetail = data.IsDetail == true
            if let id = data.ID_NewFormCompanyMenuItem, id > 0 { newFormMenuItemId = id }
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        page += 1
        let result = await DataListAPIService.fetchList(
            companyMenuItemId: moduleId, search: searchText.isEmpty ? nil : searchText,
            top: pageSize, offset: page * pageSize
        )
        switch result {
        case .success(let data):
            items.append(contentsOf: data.Items ?? [])
            hasMore = (data.Items?.count ?? 0) >= pageSize
        case .failure: break
        }
        isLoadingMore = false
    }

    func search() async {
        await load()
    }

    func loadDetail(item: DataListItem) async {
        guard let dataId = item.ID, !dataId.isEmpty else {
            AppLogger.ui.warning("DataList item has no ID, cannot load detail")
            detailError = "This item has no detail available"
            return
        }
        isLoadingDetail = true
        detailError = nil
        AppLogger.api.info("📊 Loading detail for moduleId=\(self.moduleId) dataId=\(dataId)")
        let result = await DataListAPIService.fetchDetail(moduleId: self.moduleId, dataId: dataId)
        switch result {
        case .success(let detail):
            selectedDetail = DataDetailPresentation(response: detail)
        case .failure(let error):
            AppLogger.api.error("📊 Detail load failed: \(error.localizedDescription)")
            detailError = error.localizedDescription
        }
        isLoadingDetail = false
    }
}
