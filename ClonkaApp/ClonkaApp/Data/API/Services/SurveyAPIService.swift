import Foundation

struct SurveyAPIService {
    static func fetchSurveys(moduleId: Int) async -> AppResult<[SurveyListItem]> {
        AppLogger.api.info("📋 Fetching surveys for module=\(moduleId)")
        return await APIClient.shared.clientGet(
            path: "/client/v2/survey",
            queryItems: [URLQueryItem(name: "ModuleId", value: String(moduleId))],
            responseType: [SurveyListItem].self
        )
    }

    static func fetchSurveyDetail(surveyId: Int) async -> AppResult<SurveyDetail> {
        AppLogger.api.info("📋 Fetching survey detail id=\(surveyId)")
        return await APIClient.shared.clientGet(
            path: "/client/v2/survey/\(surveyId)",
            queryItems: [],
            responseType: SurveyDetail.self
        )
    }

    static func submitAnswers(surveyId: Int, questions: [SurveyAnswerQuestion]) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.clientPut(
            path: "/client/v1/survey/\(surveyId)/Answer",
            body: SurveyAnswerRequest(ID_Login: idLogin, Questions: questions),
            responseType: EmptyResponse.self
        )
    }

    static func setSurveyState(surveyId: Int) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.clientPatch(
            path: "/client/v1/survey/\(surveyId)/state",
            body: SurveyStateRequest(ID_Login: idLogin, AnswerStateId: "Answered"),
            responseType: EmptyResponse.self
        )
    }
}
