import SwiftUI

struct FormView: View {
    let moduleId: Int
    @StateObject private var viewModel: FormViewModel
    @State private var successAnimationTrigger = false
    @EnvironmentObject private var appState: AppState
    
    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: FormViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                SLoading()
            } else if let error = viewModel.errorMessage, viewModel.fields.isEmpty {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if viewModel.isSubmitted {
                successView
            } else if viewModel.fields.isEmpty {
                SEmptyState(icon: "doc.text", message: "No form fields")
            } else {
                formContent
            }
        }
        .navigationTitle("Form")
        .task { await viewModel.load() }
        .environment(\.openURL, OpenURLAction { url in
            handleLinkTap(url)
        })
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: successAnimationTrigger)
                .onAppear{
                    successAnimationTrigger.toggle()
                }
            Text("Form Submitted")
                .font(.title2.bold())
            Text("Your data has been saved.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.sortedFields) { field in
                    formField(field)
                }

                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                            Text("Submit")
                        }
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSubmitting)
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Form Field

    @ViewBuilder
    private func formField(_ field: FormFieldDefinition) -> some View {
        let fieldType = (field.ID_FormItemType ?? "").lowercased()
        VStack(alignment: .leading, spacing: 10) {
            if fieldType == "label" {
                labelField(field)
            } else {
                // Field header
                HStack(spacing: 4) {
                    Text(field.DisplayName ?? "Field")
                        .font(.subheadline.weight(.semibold))
                    if field.IsRequired == true {
                        Text("*")
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                    }
                }

                if let desc = field.Description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                let binding = Binding<String>(
                    get: { viewModel.values[field.id] ?? "" },
                    set: { viewModel.values[field.id] = $0 }
                )

                // Input control
                Group {
                    switch fieldType {
                    case "select":
                        selectField(field)
                    case "multiselect":
                        multiSelectField(field)
                    case "checkbox":
                        checkboxField(field)
                    case "date":
                        dateField(field)
                    case "time", "timepicker":
                        timeField(field)
                    case "number":
                        numberField(field, binding: binding)
                    case "editor", "multilinetext":
                        multilineField(binding)
                    default:
                        textField(field, binding: binding)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        }
    }

    // MARK: - Field Types

    private func labelField(_ field: FormFieldDefinition) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.DisplayName ?? "")
                .font(.headline)
            if let desc = field.Description, !desc.isEmpty {
                htmlText(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func selectField(_ field: FormFieldDefinition) -> some View {
        Menu {
            Button("Select...") { viewModel.values[field.id] = "" }
            ForEach(field.Options ?? []) { opt in
                Button(opt.displayText) {
                    viewModel.values[field.id] = String(opt.id)
                }
            }
        } label: {
            HStack {
                let selectedId = viewModel.values[field.id] ?? ""
                let selectedName = field.Options?.first(where: { String($0.id) == selectedId })?.displayText
                Text(selectedName ?? "Select...")
                    .foregroundStyle(selectedName != nil ? .primary : .secondary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func multiSelectField(_ field: FormFieldDefinition) -> some View {
        VStack(spacing: 8) {
            ForEach(field.Options ?? []) { opt in
                let isSelected = (viewModel.values[field.id] ?? "").contains(String(opt.id))
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        toggleMultiSelect(fieldId: field.id, optionId: opt.id)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
                        Text(opt.displayText)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func checkboxField(_ field: FormFieldDefinition) -> some View {
        Toggle(isOn: Binding<Bool>(
            get: { (viewModel.values[field.id] ?? "false") == "true" },
            set: { viewModel.values[field.id] = $0 ? "true" : "false" }
        )) {
            Text(field.DisplayName ?? "")
                .font(.body)
        }
        .tint(Color.accentColor)
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func dateField(_ field: FormFieldDefinition) -> some View {
        DatePicker(
            "",
            selection: Binding<Date>(
                get: { parseDate(viewModel.values[field.id]) ?? Date() },
                set: { viewModel.values[field.id] = formatDate($0) }
            ),
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func timeField(_ field: FormFieldDefinition) -> some View {
        DatePicker(
            "Time",
            selection: Binding<Date>(
                get: { parseTime(viewModel.values[field.id]) ?? Date() },
                set: { viewModel.values[field.id] = formatTime($0) }
            ),
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.wheel)
        .frame(height: 120)
        .clipped()
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func numberField(_ field: FormFieldDefinition, binding: Binding<String>) -> some View {
        TextField(field.Placeholder ?? "Enter number", text: binding)
            .keyboardType(.decimalPad)
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(.systemGray4), lineWidth: 1)
            }
    }

    private func multilineField(_ binding: Binding<String>) -> some View {
        TextEditor(text: binding)
            .frame(minHeight: 100)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(.systemGray4), lineWidth: 1)
            }
    }

    private func textField(_ field: FormFieldDefinition, binding: Binding<String>) -> some View {
        TextField(field.Placeholder ?? "Enter value", text: binding)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(.systemGray4), lineWidth: 1)
            }
    }

    // MARK: - Helpers

    private func htmlText(_ string: String) -> some View {
        Text(attributedHTMLText(string))
    }

    private func sanitizedHTMLText(_ string: String) -> String {
        guard !string.isEmpty else { return "" }

        let withLineBreaks = string
            .replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "(?i)</p>", with: "\n", options: .regularExpression)

        let withoutTags = withLineBreaks.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        return decodeHTMLEntities(withoutTags)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeHTMLEntities(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private func attributedHTMLText(_ string: String) -> AttributedString {
        let markdown = htmlToMarkdown(string)
        if let attributed = try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(sanitizedHTMLText(string))
    }

    private func htmlToMarkdown(_ string: String) -> String {
        guard !string.isEmpty else { return "" }

        let unescapedQuotes = string.replacingOccurrences(of: "\\\"", with: "\"")
        let withLineBreaks = unescapedQuotes
            .replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "(?i)</p>", with: "\n", options: .regularExpression)

        let withLinks = convertAnchorTagsToMarkdown(withLineBreaks)
        let withoutTags = withLinks.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        return decodeHTMLEntities(withoutTags)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func convertAnchorTagsToMarkdown(_ value: String) -> String {
        let pattern = "(?is)<a\\s+[^>]*href\\s*=\\s*[\"']([^\"']+)[\"'][^>]*>(.*?)</a>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return value }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        let matches = regex.matches(in: value, range: range)
        guard !matches.isEmpty else { return value }

        var result = value
        for match in matches.reversed() {
            guard
                let hrefRange = Range(match.range(at: 1), in: result),
                let textRange = Range(match.range(at: 2), in: result),
                let fullRange = Range(match.range(at: 0), in: result)
            else {
                continue
            }

            let href = String(result[hrefRange])
            let text = sanitizedHTMLText(String(result[textRange]))
            result.replaceSubrange(fullRange, with: "[\(text)](\(href))")
        }

        return result
    }

    private func handleLinkTap(_ url: URL) -> OpenURLAction.Result {
        guard url.scheme?.lowercased() == "appnavigation" else {
            return .systemAction
        }

        Task {
            await routeAppNavigationLink(url)
        }

        return .handled
    }

    private func routeAppNavigationLink(_ url: URL) async {
        let moduleId = Int(url.host ?? "") ?? Int(url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        guard let moduleId else {
            AppLogger.navigation.warning("⚠️ Invalid appnavigation URL: \(url.absoluteString)")
            return
        }

        let menuResult = await MenuAPIService.fetchMenuFromXML()
        guard case .success(let config) = menuResult else {
            AppLogger.navigation.warning("⚠️ Could not resolve module \(moduleId) from appnavigation URL")
            return
        }

        guard let menuItem = config.menuItems.first(where: { $0.itemId == moduleId }) else {
            AppLogger.navigation.warning("⚠️ Module \(moduleId) not found in menu config")
            return
        }

        if menuItem.itemType == "Url", let urlString = menuItem.params["Url"] {
            var destination = ModuleDestination(route: .url, moduleId: menuItem.itemId, title: menuItem.title)
            destination.urlString = urlString
            await MainActor.run {
                appState.pendingNavigation = destination
            }
            return
        }

        let route = MenuRoute(rawValue: menuItem.itemType) ?? .unknown
        let destination = ModuleDestination(route: route, moduleId: menuItem.itemId, title: menuItem.title)
        await MainActor.run {
            appState.pendingNavigation = destination
        }
    }

    private func toggleMultiSelect(fieldId: Int, optionId: Int) {
        var ids = Set((viewModel.values[fieldId] ?? "").split(separator: ",").compactMap { Int($0) })
        if ids.contains(optionId) { ids.remove(optionId) } else { ids.insert(optionId) }
        viewModel.values[fieldId] = ids.map(String.init).joined(separator: ",")
    }

    private func parseDate(_ str: String?) -> Date? {
        guard let str, !str.isEmpty else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: str)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func parseTime(_ str: String?) -> Date? {
        guard let str, !str.isEmpty else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.date(from: str)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
