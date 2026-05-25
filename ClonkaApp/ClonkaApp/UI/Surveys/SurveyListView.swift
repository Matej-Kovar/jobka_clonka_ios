import SwiftUI

struct SurveyListView: View {
    let moduleId: Int
    @StateObject private var viewModel: SurveyListViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: SurveyListViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.surveys.isEmpty {
                SLoading()
            } else if let error = viewModel.errorMessage, viewModel.surveys.isEmpty {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if viewModel.surveys.isEmpty {
                SEmptyState(icon: "checklist", message: "No surveys available")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.surveys) { survey in
                            NavigationLink(value: SurveyDetailDestination(surveyId: survey.surveyId)) {
                                surveyCard(survey)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Surveys")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func surveyCard(_ survey: SurveyListItem) -> some View {
        let isAnswered = survey.state == "Answered"
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: isAnswered ? "checkmark.circle.fill" : "circle.dotted")
                    .font(.title3)
                    .foregroundStyle(isAnswered ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(survey.displayName ?? "Survey")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let type = survey.surveyType {
                        Text(type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(isAnswered ? "Answered" : "Open")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isAnswered ? Color.green : Color.orange, in: Capsule())
            }

            if let total = survey.questionCount, total > 0 {
                let answered = survey.answeredCount ?? 0
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            Capsule()
                                .fill(answered == total ? Color.green : Color.accentColor)
                                .frame(width: geo.size.width * (Double(answered) / Double(total)), height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(answered)/\(total) questions")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        if survey.isAnonymous == true {
                            Label("Anonymous", systemImage: "eye.slash")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        }
    }
}
