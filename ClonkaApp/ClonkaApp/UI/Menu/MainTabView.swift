import SwiftUI

struct MainTabView: View {
    @StateObject private var menuViewModel = MenuViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MenuGridView(viewModel: menuViewModel) { item in
                handleMenuItemTap(item)
            }
            .navigationTitle(menuViewModel.currentTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if menuViewModel.isInFolder {
                        Button {
                            menuViewModel.navigateBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        if let profile = sessionManager.currentProfile {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: profile.color ?? "#666"))
                                    .frame(width: 32, height: 32)
                                Text(profile.initials ?? "?")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        } else {
                            Image(systemName: "person.circle")
                        }
                    }
                }
            }
            .searchable(text: $menuViewModel.searchText, prompt: "Search menu")
            .refreshable {
                await menuViewModel.refresh()
            }
            .navigationDestination(for: ModuleDestination.self) { destination in
                moduleView(for: destination)
            }
            .navigationDestination(for: SurveyDetailDestination.self) { dest in
                SurveyDetailView(surveyId: dest.surveyId)
            }
            .navigationDestination(for: PostDetailDestination.self) { dest in
                PostDetailView(postId: dest.postId)
            }
            .navigationDestination(for: ChatDestination.self) { dest in
                ChatView(employeeId: dest.employeeId, groupId: dest.groupId,
                         menuItemId: dest.menuItemId, title: dest.title)
            }
            .navigationDestination(for: StreamDetailDestination.self) { dest in
                StreamDetailView(postId: dest.postId)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
        .task {
            menuViewModel.loadFavorites()
            await menuViewModel.loadMenu()
            autoNavigateIfNeeded()
        }
        .onChange(of: appState.pendingNavigation) { _, destination in
            if let destination {
                navigationPath.append(destination)
                appState.pendingNavigation = nil
            }
        }
        .onChange(of: appState.pendingChatNavigation) { _, destination in
            if let destination {
                navigationPath.append(destination)
                appState.pendingChatNavigation = nil
            }
        }
    }

    private func handleMenuItemTap(_ item: XMLMenuItem) {
        let type = item.itemType
        AppLogger.navigation.info("🧭 Menu tap: \(item.title) type=\(type) id=\(item.itemId)")

        if type == "Folder" {
            menuViewModel.navigateToFolder(item)
            return
        }

        if type == "Url" {
            if let urlStr = item.params["Url"], let url = URL(string: urlStr) {
                let openInBrowser = item.params["IsOpenInBrowser"]?.lowercased() == "true"
                if openInBrowser {
                    UIApplication.shared.open(url)
                } else {
                    var destination = ModuleDestination(route: .url, moduleId: item.itemId, title: item.title)
                    destination.urlString = urlStr
                    navigationPath.append(destination)
                }
            } else {
                AppLogger.navigation.error("❌ URL module missing Url param for \(item.title)")
            }
            return
        }

        let route = MenuRoute(rawValue: type) ?? .unknown
        let destination = ModuleDestination(route: route, moduleId: item.itemId, title: item.title)
        navigationPath.append(destination)
    }

    @ViewBuilder
    private func moduleView(for destination: ModuleDestination) -> some View {
        let moduleId = destination.moduleId
        switch destination.route {
        case .postList:
            PostListView(moduleId: moduleId)
        case .surveyList:
            SurveyListRoot(moduleId: moduleId)
        case .chatList:
            MessageListView(moduleId: moduleId)
        case .contacts:
            ContactListView(moduleId: moduleId)
        case .settings:
            SettingsView()
        case .aboutApp:
            AboutAppView()
        case .form:
            FormView(moduleId: moduleId)
        case .canteen:
            CanteenView(moduleId: moduleId)
        case .stream:
            StreamListView(moduleId: moduleId)
        case .card:
            CardView(moduleId: moduleId)
        case .trustBox:
            TrustBoxView(moduleId: moduleId)
        case .customPage:
            CustomPageView(moduleId: moduleId)
        case .url:
            WebURLView(url: destination.urlString, title: destination.title)
        case .licensePlates:
            LicensePlateView(moduleId: moduleId)
        case .television:
            TelevisionView(moduleId: moduleId)
        case .list:
            DataListView(moduleId: moduleId)
        case .unknown:
            UnknownModuleView()
        }
    }

    /// Auto-navigate from launch arguments: -navigateTo SurveyList -moduleId 29780
    private func autoNavigateIfNeeded() {
        let args = ProcessInfo.processInfo.arguments
        guard let navIndex = args.firstIndex(of: "-navigateTo"),
              navIndex + 1 < args.count else { return }
        let routeStr = args[navIndex + 1]
        guard let route = MenuRoute(rawValue: routeStr) else {
            AppLogger.navigation.error("❌ Unknown route: \(routeStr)")
            return
        }
        var moduleId = 0
        if let midIndex = args.firstIndex(of: "-moduleId"), midIndex + 1 < args.count {
            moduleId = Int(args[midIndex + 1]) ?? 0
        }
        let dest = ModuleDestination(route: route, moduleId: moduleId, title: routeStr)
        AppLogger.navigation.info("🤖 Auto-navigate: \(routeStr) moduleId=\(moduleId)")
        navigationPath.append(dest)
    }
}

struct ModuleDestination: Hashable {
    let route: MenuRoute
    let moduleId: Int
    let title: String
    var urlString: String?
}

enum MenuRoute: String, Hashable {
    case postList = "PostList"
    case surveyList = "SurveyList"
    case chatList = "ChatList"
    case contacts = "Contacts"
    case settings = "Settings"
    case aboutApp = "AboutApp"
    case form = "Form"
    case canteen = "Canteen"
    case stream = "Stream"
    case card = "Card"
    case trustBox = "TrustBox"
    case customPage = "CustomPage"
    case url = "Url"
    case licensePlates = "LicensePlates"
    case television = "Television"
    case list = "List"
    case unknown = "Unknown"
}

// MARK: - Detail Navigation Destinations

struct SurveyDetailDestination: Hashable {
    let surveyId: Int
}

struct PostDetailDestination: Hashable {
    let postId: Int
}

struct ChatDestination: Hashable {
    let employeeId: Int?
    let groupId: Int?
    let menuItemId: Int
    let title: String
}

struct StreamDetailDestination: Hashable {
    let postId: Int
}
