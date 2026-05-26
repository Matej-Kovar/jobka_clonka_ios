import Foundation

@MainActor
final class LicensePlateViewModel: ObservableObject {
    @Published var licensePlate = ""
    @Published var result: LicensePlateResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    func search() async {
        guard !licensePlate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        result = nil
        let apiResult = await LicensePlateAPIService.processImage(licensePlate: licensePlate)
        switch apiResult {
        case .success(let resp): result = resp
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
