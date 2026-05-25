import Foundation

@MainActor
final class TrustBoxViewModel: ObservableObject {
    @Published var body = ""
    @Published var email = ""
    @Published var isSubmitting = false
    @Published var isSubmitted = false
    @Published var errorMessage: String?

    let moduleId: Int
    init(moduleId: Int) { self.moduleId = moduleId }

    var isValid: Bool { body.count >= 10 }

    func submit() async {
        guard isValid else { return }
        isSubmitting = true
        errorMessage = nil
        let emailValue = email.isEmpty ? nil : email
        let result = await TrustBoxAPIService.submit(body: body, email: emailValue, moduleId: moduleId)
        switch result {
        case .success: isSubmitted = true
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
