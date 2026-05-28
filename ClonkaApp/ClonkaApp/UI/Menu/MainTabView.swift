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
                            withAnimation(.easeInOut) {
                                menuViewModel.navigateBack()
                            }
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
            .searchable(text: $menuViewModel.searchText, prompt: L10n.Menu_SearchMenu.key)
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
        .overlay {
            if let popup = menuViewModel.currentPopup {
                popupView(for: popup)
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
            withAnimation(.easeInOut) {
                menuViewModel.navigateToFolder(item)
            }
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
            PostListView(moduleId: moduleId, title: destination.title)
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
            FormView(moduleId: moduleId, title: destination.title)
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
            DataListView(moduleId: moduleId, title: destination.title)
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

    @ViewBuilder
    private func popupView(for popup: PostPopup) -> some View {
        PopupContentView(popup: popup, detail: menuViewModel.currentPopupDetail, viewModel: menuViewModel)
            .zIndex(100)
    }

    // Extracted popup content into its own view so we can use @State for checkbox, loading, etc.
    private struct PopupContentView: View {
        let popup: PostPopup
        let detail: PostDetail?
        @ObservedObject var viewModel: MenuViewModel

        @State private var checkboxChecked: Bool = false
        @State private var pdfURL: IdentifiableURL?

        var body: some View {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with title and optional close
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(popup.displayName ?? L10n.Post_Notice.string)
                                .font(.headline)
                            if let date = popup.datePublish ?? detail?.datePublish ?? detail?.dateUpdate {
                                Text(date, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if !popup.needsApproval {
                            Button {
                                viewModel.dismissCurrentPopup()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.accentColor)
                                    .font(.title3)
                            }
                        }
                    }
                    .padding(24)
                    
                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    // Image(s) (if available) — use shared SImageView component
                    if let attachments = detail?.attachments {
                        let imageAttachments = attachments.filter { att in
                            // reuse same logic as PostDetailView's isImageAttachment
                            if att.contentType?.lowercased().hasPrefix("image/") == true { return true }
                            let candidates = [att.documentUrl, att.fileNameExtension, att.fileName, att.displayName]
                                .compactMap { $0?.lowercased() }
                            for value in candidates {
                                if [".png", ".jpg", ".jpeg", ".gif", ".webp", ".heic", ".heif"].contains(where: { value.hasSuffix($0) }) {
                                    return true
                                }
                            }
                            return false
                        }

                        if !imageAttachments.isEmpty {
                            SImageView(images: imageAttachments.map { SImageAttachment(documentId: $0.documentId, documentUrl: $0.documentUrl) })
                                .padding([.leading, .trailing])
                        }
                        // Non-image attachments
                        let fileAttachments = detail?.attachments?.filter { att in
                            // reuse same logic as image filter
                            if att.contentType?.lowercased().hasPrefix("image/") == true { return false }
                            let candidates = [att.documentUrl, att.fileNameExtension, att.fileName, att.displayName]
                                .compactMap { $0?.lowercased() }
                            for value in candidates {
                                if [".png", ".jpg", ".jpeg", ".gif", ".webp", ".heic", ".heif"].contains(where: { value.hasSuffix($0) }) {
                                    return false
                                }
                            }
                            return true
                        } ?? []

                        if !fileAttachments.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(fileAttachments) { att in
                                    Button {
                                        Task { await openAttachment(att) }
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
                                            Text(att.displayName ?? att.fileName ?? "Attachment")
                                                .font(.callout)
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "arrow.up.right.square")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding([.leading, .trailing])
                        }
                    }

                    // Description (HTML or plain text)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if let html = popup.textHtml, !html.isEmpty {
                                HTMLContentView(html: html)
                                    .frame(minHeight: 200)
                            } else if let text = popup.text, !text.isEmpty {
                                Text(text)
                                    .foregroundColor(.primary)
                            } else if let body = detail?.textHtml ?? detail?.text, !body.isEmpty {
                                if let html = detail?.textHtml, !html.isEmpty {
                                    HTMLContentView(html: html)
                                        .frame(minHeight: 200)
                                } else {
                                    Text(detail?.text ?? "")
                                        .foregroundColor(.primary)
                                }
                            } else {
                                Text("")
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 400)

                    // Approval / Close area
                    if popup.needsApproval {
                        VStack(spacing: 12) {
                            if let checkboxText = popup.textApprovalCheckbox,
                               !checkboxText.isEmpty {
                                Toggle(isOn: $checkboxChecked) {
                                    Text(checkboxText)
                                }
                                .padding([.leading, .trailing])
                            }
                            Divider()
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8 )
                            Button {
                                viewModel.dismissCurrentPopup(approved: true)
                            } label: {
                                Text(popup.textApprovalButton ?? "Confirm")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .cornerRadius(8)
                            }
                            .disabled(popup.textApprovalCheckbox != nil && !(checkboxChecked))
                            .padding([.leading, .trailing, .bottom])
                        }
                    } else {
                        VStack(spacing: 0) {
                            Divider()
                                .padding(.horizontal, 24)
                            Button {
                                viewModel.dismissCurrentPopup()
                            } label: {
                                Text("Close")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 20)
                .padding(24)
                .sheet(item: $pdfURL) { identifiableURL in
                    SPDFViewer(url: identifiableURL.url, title: identifiableURL.title)
                }
            }
        }

        // Attachment helpers for popup (methods on the view so they are in-scope)
        private func resolveDocumentURL(documentUrl: String?, documentId: Int?) async -> URL? {
            if let urlStr = documentUrl, let url = URL(string: urlStr) { return url }
            if let id = documentId { return await DocumentAPIService.getDocumentImageURL(documentId: id) }
            return nil
        }

        private func isPDFAttachment(_ attachment: PostAttachment) -> Bool {
            if let ct = attachment.contentType?.lowercased(), ct.contains("pdf") { return true }
            let candidates = [attachment.documentUrl, attachment.fileNameExtension, attachment.fileName, attachment.displayName]
                .compactMap { $0?.lowercased() }
            for v in candidates { if v.hasSuffix(".pdf") { return true } }
            return false
        }

        private func openAttachment(_ attachment: PostAttachment) async {
            guard let url = await resolveDocumentURL(documentUrl: attachment.documentUrl, documentId: attachment.documentId) else { return }

            let resolvedURL = PDFDocumentResolver.resolvePDFURL(from: url)
            let preferredPDFURL: URL
            if let docId = attachment.documentId,
               let directURL = await DocumentAPIService.getDocumentImageURL(documentId: docId) {
                preferredPDFURL = directURL
            } else {
                preferredPDFURL = resolvedURL
            }
            AppLogger.navigation.debug("📎 Popup opening attachment URL: \(url) -> resolved: \(resolvedURL) (attachmentId=\(attachment.attachmentId ?? 0))")

            if isPDFAttachment(attachment) {
                do {
                    let localURL = try await PDFDocumentResolver.downloadPDFToTemporaryFile(
                        from: preferredPDFURL,
                        filePrefix: "popup_attachment"
                    )
                    await MainActor.run {
                        self.pdfURL = IdentifiableURL(url: localURL, title: attachment.displayName ?? attachment.fileName)
                    }
                } catch {
                    AppLogger.navigation.error("❌ Failed to load popup PDF in-app: \(error.localizedDescription)")
                }
                return
            }

            DispatchQueue.main.async { UIApplication.shared.open(resolvedURL) }
        }
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
