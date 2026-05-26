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
            } else if viewModel.isSubmitted {
                successView
            } else if !viewModel.questions.isEmpty {
                wizardView
            }
        }
        .navigationTitle("Survey")
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

            Text("Question \(viewModel.currentPage + 1) of \(viewModel.questions.count)")
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
            // Question header
            HStack(alignment: .top, spacing: 8) {
                Text("\(index + 1)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.accentColor))

                VStack(alignment: .leading, spacing: 4) {
                    Text(q.questionText ?? "Question")
                        .font(.title3.weight(.semibold))
                    if q.isRequired == true {
                        Text("Required")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Divider()

            // Answer section
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

    // MARK: - Options (single/multi select)

    @ViewBuilder
    private func optionsView(_ q: SurveyQuestion) -> some View {
        let isMulti = q.isMultipleOptions == true
        if isMulti {
            Text("Select all that apply")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        VStack(spacing: 8) {
            ForEach(q.options ?? []) { option in
                let qId = q.questionId
                let isSelected = viewModel.selectedOptions[qId]?.contains(option.questionOptionId) ?? false
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

    // MARK: - Text Answer

    @ViewBuilder
    private func textAnswerView(_ q: SurveyQuestion) -> some View {
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
            TextField("Type your answer...", text: binding)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
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
                    Text("Back")
                }
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .disabled(viewModel.currentPage == 0)
            .opacity(viewModel.currentPage == 0 ? 0.4 : 1)

            // Next or Submit button
            if viewModel.currentPage < viewModel.questions.count - 1 {
                Button {
                    withAnimation { viewModel.currentPage += 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
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
                            Text("Submit")
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
            Text("Survey Submitted")
                .font(.title2.bold())
            Text("Thank you for your answers.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
