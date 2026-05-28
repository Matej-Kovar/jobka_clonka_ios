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
                SEmptyState(icon: "checklist", message: L10n.Survey_NotAvailable.string)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.surveys) { survey in
                            NavigationLink(value: SurveyDetailDestination(surveyId: survey.surveyId)) {
                                SurveyCardView(survey: survey)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(L10n.Survey_ListTitle.string)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    // surveyCard removed from inside the view struct. Use the shared top-level SurveyCardView below.
}

// MARK: Helpers

private func surveyTypeDictionary(_ type: String) -> String {
    switch type {
    case "SurveyType_Questionnaire": return L10n.Survey_Questionnaire.string
    case "SurveyType_Query": return L10n.Survey_Query.string
    default: return type
    }
}

// MARK: - Shared Survey Card View

struct SurveyCardView: View {
    let survey: SurveyListItem

    var body: some View {
        let isAnswered = survey.state == "answered"
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: isAnswered ? "checkmark.circle.fill" : "circle.dotted")
                    .font(.title3)
                    .foregroundStyle(isAnswered ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(survey.displayName ?? L10n.Survey_Title.string)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let type = survey.surveyType {
                        Text(surveyTypeDictionary(type))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(isAnswered ? L10n.Survey_Answered.string :L10n.Survey_Open.string)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isAnswered ? Color.green : Color.orange, in: Capsule())
            }

            // Date/Time and Expiration Date with icons
            VStack(alignment: .leading, spacing: 8) {
                if let date = survey.datePublish {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                        Text(date, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let closeDate = survey.dateClose {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Expires: ")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(closeDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(closeDate, style: .time)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
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
                            Label(L10n.Survey_Anonymous.string, systemImage: "eye.slash")
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

// MARK: - Root with tabs (nové / archiv)

struct SurveyListRoot: View {
    let moduleId: Int
    @StateObject private var viewModel: SurveyListViewModel
    @State private var selection = 0

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: SurveyListViewModel(moduleId: moduleId))
    }

    var body: some View {
        TabView(selection: $selection) {
            listView(filtered: viewModel.surveys.filter { ($0.state ?? "") != "answered" })
                .tag(0)
                .tabItem { Label(L10n.Survey_New.string, systemImage: "envelope.fill") }

            listView(filtered: viewModel.surveys.filter { ($0.state ?? "") == "answered" })
                .tag(1)
                .tabItem { Label(L10n.Survey_Archive.string, systemImage: "archivebox.fill") }
        }
        .navigationTitle(L10n.Survey_ListTitle.string)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func listView(filtered: [SurveyListItem]) -> some View {
        VStack(spacing: 0) {
            Group {
                if viewModel.isLoading && filtered.isEmpty {
                    SLoading()
                } else if let error = viewModel.errorMessage, filtered.isEmpty {
                    SErrorState(message: error) { Task { await viewModel.load() } }
                } else if filtered.isEmpty {
                    SEmptyState(icon: "checklist", message: L10n.Survey_NotAvailable.string)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { survey in
                                NavigationLink(value: SurveyDetailDestination(surveyId: survey.surveyId)) {
                                    SurveyCardView(survey: survey)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }

            Divider()
                .padding(.vertical, 8)
        }
    }
}
