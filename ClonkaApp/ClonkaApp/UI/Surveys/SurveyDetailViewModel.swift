import Foundation

@MainActor
final class SurveyDetailViewModel: ObservableObject {
    @Published var detail: SurveyDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var answers: [Int: String] = [:]
    @Published var selectedOptions: [Int: Set<Int>] = [:]
    @Published var isSubmitting = false
    @Published var isSubmitted = false
    @Published var currentPage = 0

    let surveyId: Int
    init(surveyId: Int) { self.surveyId = surveyId }

    var questions: [SurveyQuestion] {
        detail?.questions?.sorted { ($0.order ?? 0) < ($1.order ?? 0) } ?? []
    }

    func isQuestionAnswered(_ index: Int) -> Bool {
        guard index >= 0, index < questions.count else { return false }
        let q = questions[index]
        if q.isOptions == true || q.isMultipleOptions == true {
            return !(selectedOptions[q.questionId]?.isEmpty ?? true)
        }
        return !(answers[q.questionId]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        let result = await SurveyAPIService.fetchSurveyDetail(surveyId: surveyId)
        switch result {
        case .success(let d):
            detail = d
            isSubmitted = d.state == "answered"
            AppLogger.navigation.debug("📋 Survey loaded: \(d.questions?.count ?? 0) questions")
            for (idx, q) in (d.questions ?? []).enumerated() {
                if let attachments = q.attachments, !attachments.isEmpty {
                    AppLogger.navigation.debug("📸 Q\(q.questionId) (index \(idx)): \(attachments.count) attachments - types: \(attachments.map { $0.contentType ?? "unknown" }.joined(separator: ", "))")
                    for att in attachments {
                        AppLogger.navigation.debug("   - \(att.displayName ?? "?") | \(att.contentType ?? "?") | URL: \(att.documentUrl ?? "NONE")")
                    }
                }
                if let text = q.answerText { answers[q.questionId] = text }
                let selected = q.options?.filter { $0.isSelected == true }.map { $0.questionOptionId } ?? []
                if !selected.isEmpty { selectedOptions[q.questionId] = Set(selected) }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            AppLogger.navigation.error("📋 Survey load failed: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func submit() async {
        isSubmitting = true
        let questionAnswers: [SurveyAnswerQuestion] = questions.map { q in
            let text = answers[q.questionId]
            let opts = selectedOptions[q.questionId]?.map { SurveyAnswerOption(questionOptionId: $0) }
            return SurveyAnswerQuestion(questionId: q.questionId, text: text, options: opts)
        }
        let result = await SurveyAPIService.submitAnswers(surveyId: surveyId, questions: questionAnswers)
        if result.isSuccess {
            _ = await SurveyAPIService.setSurveyState(surveyId: surveyId)
            isSubmitted = true
        } else {
            errorMessage = result.error?.localizedDescription
        }
        isSubmitting = false
    }
}
