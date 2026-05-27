import SwiftUI

struct SurveyDetailView: View {
    @StateObject private var viewModel: SurveyDetailViewModel
    @State private var successAnimationTrigger = false

    init(surveyId: Int) {
        _viewModel = StateObject(wrappedValue: SurveyDetailViewModel(surveyId: surveyId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                SLoading()
            } else if let error = viewModel.errorMessage {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if !viewModel.questions.isEmpty {
                wizardView
            } else if viewModel.isSubmitted {
                // If there are no questions but survey is already answered, show success state
                successView
            }
        }
        .navigationTitle(L10n.Survey_Title.key)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: - Wizard View (one question at a time)

    private var wizardView: some View {
        VStack(spacing: 0) {
            // Progress header
            progressHeader
                .padding(.horizontal)
                .padding(.top, 8)

            // Question content
            TabView(selection: $viewModel.currentPage) {
                ForEach(Array(viewModel.questions.enumerated()), id: \.element.questionId) { index, question in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            questionCard(question, index: index)
                                .padding()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)

            // Bottom navigation
            navigationBar
                .padding()
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            if let name = viewModel.detail?.displayName {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            // Step dots
            HStack(spacing: 6) {
                ForEach(0..<viewModel.questions.count, id: \.self) { i in
                    Capsule()
                        .fill(stepColor(for: i))
                        .frame(height: 4)
                        .frame(maxWidth: i == viewModel.currentPage ? 24 : 12)
                }
            }
            .animation(.spring(response: 0.3), value: viewModel.currentPage)

            Text(L10n.Survey_Question.formatted(with: viewModel.currentPage + 1, viewModel.questions.count))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.bottom, 4)
    }

    private func stepColor(for index: Int) -> Color {
        if index == viewModel.currentPage { return Color.accentColor }
        if viewModel.isQuestionAnswered(index) { return .green }
        return Color(.systemGray4)
    }

    // MARK: - Question Card

    @ViewBuilder
    private func questionCard(_ q: SurveyQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                imageAttachmentsView(q.attachments, questionId: q.questionId)
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1)")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.accentColor))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(q.questionText ?? L10n.Survey_Question.string)
                            .font(.title3.weight(.semibold))
                        if q.isRequired == true {
                            Text(L10n.Survey_Required.key)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Divider()

            if q.isOptions == true || q.isMultipleOptions == true {
                optionsView(q)
            } else {
                textAnswerView(q)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        }
    }

    // MARK: - Attachments

    @ViewBuilder
    private func imageAttachmentsView(_ attachments: [SurveyAttachment]?, questionId: Int) -> some View {
        let imageAttachments = (attachments ?? []).filter { isImageAttachment($0) }
        
        if !imageAttachments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(imageAttachments) { attachment in
                    ImageAttachmentLoader(
                        attachment: attachment,
                        questionId: questionId
                    )
                }
            }
            .task {
                AppLogger.navigation.debug("📸 Q\(questionId): Rendering \(imageAttachments.count) images")
            }
        }
    }

    private func isImageAttachment(_ attachment: SurveyAttachment) -> Bool {
        if attachment.contentType?.lowercased().hasPrefix("image/") == true {
            return true
        }

        guard let urlString = attachment.documentUrl?.lowercased() else { return false }
        return [".png", ".jpg", ".jpeg", ".gif", ".webp", ".heic", ".heif"].contains {
            urlString.hasSuffix($0)
        }
    }

    // MARK: - Image Attachment Loader

    @MainActor
    private struct ImageAttachmentLoader: View {
        let attachment: SurveyAttachment
        let questionId: Int
        @State private var imageURL: URL?
        @State private var isLoading = true

        var body: some View {
            Group {
                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 180)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        case .failure(let error):
                            Label(L10n.Image_Fail.key, systemImage: "photo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 180)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onAppear {
                                    AppLogger.navigation.error("📸 Q\(questionId): ❌ Failed to load image - \(error.localizedDescription)")
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Label(L10n.Image_URL.key, systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onAppear {
                            AppLogger.navigation.warning("📸 Q\(questionId): Could not generate image URL for attachment - name: \(attachment.displayName ?? "?"), docId: \(attachment.documentId.map(String.init) ?? "unknown")")
                        }
                }
            }
            .task {
                await loadImageURL()
            }
        }

        private func loadImageURL() async {
            isLoading = true
            if let urlString = attachment.documentUrl,
               let url = URL(string: urlString) {
                imageURL = url
                AppLogger.navigation.debug("📸 Q\(questionId): Using provided documentUrl")
                isLoading = false
                return
            }
            if let documentId = attachment.documentId {
                imageURL = await DocumentAPIService.getDocumentImageURL(documentId: documentId)
                if imageURL != nil {
                    AppLogger.navigation.debug("📸 Q\(questionId): Generated URL from ID_Document=\(documentId)")
                } else {
                    AppLogger.navigation.warning("📸 Q\(questionId): Failed to generate URL from ID_Document=\(documentId)")
                }
            } else {
                AppLogger.navigation.warning("📸 Q\(questionId): Attachment has no documentUrl or documentId")
            }

            isLoading = false
        }
    }

    // MARK: - Options (single/multi select)

    @ViewBuilder
    private func optionsView(_ q: SurveyQuestion) -> some View {
        let isMulti = q.isMultipleOptions == true
        if isMulti {
            Text(L10n.Survey_SelectAll.key)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        VStack(spacing: 8) {
            ForEach(q.options ?? []) { option in
                let qId = q.questionId
                let isSelected = viewModel.selectedOptions[qId]?.contains(option.questionOptionId) ?? false

                if viewModel.isSubmitted {
                    // Read-only display for already answered survey
                    HStack(spacing: 12) {
                        Image(systemName: isMulti
                            ? (isSelected ? "checkmark.square.fill" : "square")
                            : (isSelected ? "largecircle.fill.circle" : "circle")
                        )
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))

                        Text(option.displayName ?? "")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 1.5)
                    }
                } else {
                    // Interactive selection
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            if isMulti {
                                if isSelected {
                                    viewModel.selectedOptions[qId]?.remove(option.questionOptionId)
                                } else {
                                    viewModel.selectedOptions[qId, default: []].insert(option.questionOptionId)
                                }
                            } else {
                                viewModel.selectedOptions[qId] = [option.questionOptionId]
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isMulti
                                ? (isSelected ? "checkmark.square.fill" : "square")
                                : (isSelected ? "largecircle.fill.circle" : "circle")
                            )
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
                            .symbolEffect(.bounce, value: isSelected)

                            Text(option.displayName ?? "")
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Text Answer

    @ViewBuilder
    private func textAnswerView(_ q: SurveyQuestion) -> some View {
        if viewModel.isSubmitted {
            // Read-only display of submitted/answered text
            Text(viewModel.answers[q.questionId] ?? "—")
                .font(.body)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                }
        } else {
            let binding = Binding<String>(
                get: { viewModel.answers[q.questionId] ?? "" },
                set: { viewModel.answers[q.questionId] = $0 }
            )
            if q.isTextArea == true {
                TextEditor(text: binding)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(.systemGray4), lineWidth: 1)
                    }
            } else {
                TextField(L10n.Survey_Type.key, text: binding)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(.systemGray4), lineWidth: 1)
                    }
            }
        }
    }

    // MARK: - Bottom Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                withAnimation { viewModel.currentPage -= 1 }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(L10n.Back.key)
                }
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .disabled(viewModel.currentPage == 0)
            .opacity(viewModel.currentPage == 0 ? 0.4 : 1)

            if viewModel.currentPage < viewModel.questions.count - 1 {
                Button {
                    withAnimation { viewModel.currentPage += 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text(L10n.Next.key)
                        Image(systemName: "chevron.right")
                    }
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            } else {
                if viewModel.isSubmitted {
                    Button {
                    } label: {
                        HStack(spacing: 4) {
                            Text(L10n.Next.key)
                            Image(systemName: "chevron.right")
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                    .opacity(0.4)
                } else {
                    Button {
                        Task { await viewModel.submit() }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane.fill")
                                Text(L10n.Submit.key)
                            }
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSubmitting)
                }
            }
        }
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
            Text(L10n.Survey_Submitted.key)
                .font(.title2.bold())
            Text(L10n.Survey_Thanks.key)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
