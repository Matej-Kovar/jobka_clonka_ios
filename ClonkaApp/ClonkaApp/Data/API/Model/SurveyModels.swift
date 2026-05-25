import Foundation

struct SurveyListItem: Decodable, Identifiable {
    let surveyId: Int
    let displayName: String?
    let text: String?
    let textHtml: String?
    let state: String?
    let questionCount: Int?
    let answeredCount: Int?
    let surveyTypeId: String?
    let surveyType: String?
    let isAnonymous: Bool?
    let datePublish: Date?
    let dateCreated: Date?
    let dateClose: Date?
    let documentCount: Int?
    let documentId: Int?
    let documentHash: String?

    var id: Int { surveyId }
}

struct SurveyDetail: Decodable {
    let surveyId: Int
    let surveyTypeId: String?
    let surveyType: String?
    let datePublish: Date?
    let dateClose: Date?
    let isAnonymous: Bool?
    let displayName: String?
    let surveyText: String?
    let surveyTextHtml: String?
    let state: String?
    let attachments: [SurveyAttachment]?
    let questions: [SurveyQuestion]?
}

struct SurveyAttachment: Decodable, Identifiable {
    let documentId: Int?
    let documentHash: String?
    let documentUrl: String?
    let displayName: String?
    let contentType: String?

    var id: Int { documentId ?? 0 }
}

struct SurveyQuestion: Decodable, Identifiable {
    let questionId: Int
    let isRequired: Bool?
    let isTextArea: Bool?
    let isOptions: Bool?
    let isMultipleOptions: Bool?
    let order: Int?
    let questionText: String?
    let questionTextHtml: String?
    let answerText: String?
    let attachments: [SurveyAttachment]?
    let options: [SurveyQuestionOption]?

    var id: Int { questionId }
}

struct SurveyQuestionOption: Decodable, Identifiable {
    let questionOptionId: Int
    let order: Int?
    let displayName: String?
    let isSelected: Bool?

    var id: Int { questionOptionId }
}

struct SurveyAnswerRequest: Encodable {
    let ID_Login: String
    let Questions: [SurveyAnswerQuestion]?
}

struct SurveyAnswerQuestion: Encodable {
    let questionId: Int
    let text: String?
    let options: [SurveyAnswerOption]?
}

struct SurveyAnswerOption: Encodable {
    let questionOptionId: Int
}

struct SurveyStateRequest: Encodable {
    let ID_Login: String
    let AnswerStateId: String
}
