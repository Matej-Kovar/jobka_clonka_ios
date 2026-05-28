import SwiftUI

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var allMenuItems: [XMLMenuItem] = []
    @Published var badgeCounts: [Int: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var folderStack: [FolderEntry] = []
    @Published var favorites: Set<Int> = []
    @Published var searchText = ""
    @Published var companyName: String?
    @Published var companyColor: String?

    @Published var popupsQueue: [PostPopup] = []
    @Published var currentPopup: PostPopup?
    @Published var currentPopupDetail: PostDetail? = nil

    struct FolderEntry: Identifiable {
        let id: Int
        let title: String
    }

    var currentTitle: String {
        folderStack.last?.title ?? companyName ?? "Menu"
    }

    var isInFolder: Bool {
        !folderStack.isEmpty
    }

    /// Items for the current folder level (root or inside a folder)
    var currentItems: [XMLMenuItem] {
        let parentId = folderStack.last?.id
        return allMenuItems
            .filter { $0.parentItemId == parentId }
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
    }

    var filteredItems: [XMLMenuItem] {
        let items = currentItems
        if searchText.isEmpty { return items }
        // When searching, search across all items (not just current folder), exclude folders
        return allMenuItems
            .filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    && $0.itemType != "Folder"
            }
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
    }

    var favoriteItems: [XMLMenuItem] {
        allMenuItems.filter { favorites.contains($0.itemId) }
    }

    func loadMenu() async {
        isLoading = true
        errorMessage = nil

        let result = await MenuAPIService.fetchMenuFromXML()

        switch result {
        case .success(let config):
            allMenuItems = config.menuItems
            companyName = config.company?.displayName
            companyColor = config.company?.companyColor
            AppLogger.menu.info("✅ Menu loaded: \(config.menuItems.count) items")
            await loadBadgeCounts()
            await loadPopups()

        case .failure(let error):
            if case .unauthorized = error {
                AppLogger.auth.warning("🔒 Menu fetch got 401 — will logout")
                await SessionManager.shared.logout()
            } else {
                errorMessage = error.localizedDescription
                AppLogger.menu.error("❌ Menu load failed: \(error.localizedDescription)")
            }
        }

        isLoading = false
    }

    func loadBadgeCounts() async {
        let result = await MenuAPIService.fetchBadgeCounts()
        if case .success(let counts) = result {
            var map: [Int: Int] = [:]
            for item in counts {
                map[item.ID_CompanyMenuItem] = item.NumberOfNew ?? 0
            }
            badgeCounts = map
            AppLogger.menu.info("🔢 Badge counts loaded: \(counts.count) items")
        }
    }

    func loadPopups() async {
        let result = await PostAPIService.fetchPopups()
        if case .success(let popups) = result {
            self.popupsQueue = popups
            showNextPopup()
        }
    }

    func showNextPopup() {
        if let next = popupsQueue.first {
            currentPopup = next
            // Fetch full post detail (attachments, images) for richer popup display
            currentPopupDetail = nil
            Task {
                await loadPopupDetail(postId: next.postId)
            }
        } else {
            currentPopup = nil
            currentPopupDetail = nil
        }
    }

    func dismissCurrentPopup(approved: Bool = false) {
        guard let current = currentPopup else { return }
        
        // Remove from queue
        popupsQueue.removeAll { $0.id == current.id }
        currentPopup = nil
        currentPopupDetail = nil
        
        Task {
            if approved {
                _ = await PostAPIService.approve(postId: current.id)
            } else {
                _ = await PostAPIService.markRead(postId: current.id)
            }
        }
        
        // Show next if any after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showNextPopup()
        }
    }

    private func loadPopupDetail(postId: Int) async {
        let result = await PostAPIService.fetchPostDetail(postId: postId)
        switch result {
        case .success(let detail):
            currentPopupDetail = detail
        case .failure(let error):
            AppLogger.api.warning("Could not fetch popup detail for id=\(postId): \(error.localizedDescription)")
            currentPopupDetail = nil
        }
    }

    func navigateToFolder(_ item: XMLMenuItem) {
        folderStack.append(FolderEntry(id: item.itemId, title: item.title))
    }

    func navigateBack() {
        guard !folderStack.isEmpty else { return }
        folderStack.removeLast()
    }

    func navigateToRoot() {
        folderStack.removeAll()
    }

    func toggleFavorite(_ itemId: Int) {
        if favorites.contains(itemId) {
            favorites.remove(itemId)
        } else {
            favorites.insert(itemId)
        }
        // Persist locally as cache
        UserDefaults.standard.set(Array(favorites), forKey: "menuFavorites")
        // Sync to server
        Task { await saveFavoritesToServer() }
    }

    func loadFavorites() {
        // Load local cache immediately
        if let saved = UserDefaults.standard.array(forKey: "menuFavorites") as? [Int] {
            favorites = Set(saved)
        }
        // Then fetch from server (overrides local)
        Task { await fetchFavoritesFromServer() }
    }

    private func fetchFavoritesFromServer() async {
        let result = await EmployeeAPIService.fetchSettings()
        switch result {
        case .success(let settings):
            if let modules = settings.modules {
                let serverFavs = modules.compactMap { $0.moduleId }
                if !serverFavs.isEmpty {
                    favorites = Set(serverFavs)
                    UserDefaults.standard.set(serverFavs, forKey: "menuFavorites")
                    AppLogger.menu.info("⭐ Server favorites loaded: \(serverFavs.count) items")
                }
            }
        case .failure(let error):
            AppLogger.menu.warning("⭐ Could not fetch server favorites, using local: \(error.localizedDescription)")
        }
    }

    private func saveFavoritesToServer() async {
        let modules = favorites.enumerated().map { idx, id in
            ModuleSettings(moduleId: id, favoriteOrder: idx)
        }
        let settings = EmployeeSettings(
            favoriteModuleFlags: nil,
            modules: modules
        )
        guard let idLogin = await APIClient.shared.idLogin else { return }
        let request = UpdateEmployeeSettingsRequest(ID_Login: idLogin, Settings: settings)
        let result = await APIClient.shared.clientPost(
            path: "/client/v1/employee/settings",
            body: request,
            responseType: EmptyResponse.self
        )
        switch result {
        case .success:
            AppLogger.menu.info("⭐ Favorites synced to server")
        case .failure(let error):
            AppLogger.menu.warning("⭐ Failed to sync favorites: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        await loadMenu()
    }
}
