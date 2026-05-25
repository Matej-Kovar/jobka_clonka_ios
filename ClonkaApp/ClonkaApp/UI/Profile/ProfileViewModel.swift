import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: EmployeeProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await EmployeeAPIService.fetchProfile()
        switch result {
        case .success(let p): profile = p
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deletePhoto() async {
        _ = await EmployeeAPIService.deletePhoto()
        await load()
    }
}
