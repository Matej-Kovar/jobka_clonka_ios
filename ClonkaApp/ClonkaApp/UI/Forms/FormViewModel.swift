import Foundation

@MainActor
final class FormViewModel: ObservableObject {
    @Published var fields: [FormFieldDefinition] = []
    @Published var values: [Int: String] = [:]
    @Published var selectedOptions: [Int: Int] = [:]
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var isSubmitted = false
    @Published var errorMessage: String?

    let moduleId: Int
    let dataId: String?

    init(moduleId: Int, dataId: String? = nil) {
        self.moduleId = moduleId
        self.dataId = dataId
    }

    var sortedFields: [FormFieldDefinition] {
        fields.sorted { ($0.Order ?? 0) < ($1.Order ?? 0) }
    }

    var companyFormId: Int? {
        fields.first?.ID_CompanyForm
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        if let cached = FormAPIService.cachedFields(companyMenuItemId: moduleId, dataId: dataId) {
            fields = cached
            for f in cached {
                if let v = f.DefaultValue, !v.isEmpty { values[f.id] = v }
            }
            isLoading = false
            return
        }

        let result = await FormAPIService.fetchFields(companyMenuItemId: moduleId, dataId: dataId)
        switch result {
        case .success(let items):
            fields = items
            // Pre-populate default values
            for f in items {
                if let v = f.DefaultValue, !v.isEmpty { values[f.id] = v }
            }
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func submit() async {
        guard let formId = companyFormId else {
            errorMessage = "No form ID found"
            return
        }
        isSubmitting = true
        errorMessage = nil
        let dataItems = fields.map { field in
            FormDataItemValue(
                ID_FormItem: field.id,
                Value: values[field.id] ?? ""
            )
        }
        let result = await FormAPIService.submitForm(companyFormId: formId, dataItems: dataItems, dataId: dataId)
        switch result {
        case .success: isSubmitted = true
        case .failure(let error): errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
