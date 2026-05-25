import Foundation

@MainActor
final class CanteenViewModel: ObservableObject {
    @Published var canteens: [CanteenItem] = []
    @Published var selectedCanteen: CanteenItem?
    @Published var slots: [CanteenSlot] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var isLoadingMenu = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await CanteenAPIService.fetchCanteens(companyMenuItemId: moduleId)
        switch result {
        case .success(let items):
            canteens = items
            if selectedCanteen == nil { selectedCanteen = items.first }
            await loadMenu()
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMenu() async {
        guard let canteen = selectedCanteen else { return }
        isLoadingMenu = true
        let day = dateFormatter.string(from: selectedDate)
        let result = await CanteenAPIService.fetchMenu(canteenId: canteen.ID, day: day, externalLogin: nil, externalPersonId: nil)
        switch result {
        case .success(let items): slots = items
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoadingMenu = false
    }
}
