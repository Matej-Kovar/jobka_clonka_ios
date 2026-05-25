# API Reference — Skeleton.Jobka.Client.Api

Modern versioned API for employee client applications. Prefer this over Webservice.Core wherever an endpoint exists.

- **Base URL:** `/client/v{version}`
- **Auth:** `ID_Login` (Guid) passed as query param or in request body — obtained from `GET api/Employee/Login` (Webservice.Core). Validated by stored procedures at DB level; invalid/expired sessions return 401 with no response body (CORS blocked).
- **Response wrapper:** `{ isSuccess, data, message, validationMessages, logId, statusCode }`

```json
{
  "isSuccess": true,
  "message": null,
  "data": {},
  "validationMessages": [],
  "logId": null,
  "statusCode": 200
}
```

---

## Table of Contents

- [Company](#company)
- [Employee](#employee)
- [Post](#post)
- [Survey V1](#survey-v1)
- [Survey V2](#survey-v2)
- [ETag & Caching](#etag--caching)
- [Versioning](#versioning)

---

## Company

### GET /client/v1/company/{companyId}/Languages

Returns available languages for a company.

**Request:**

| Field | Type | Required | Notes |
|---|---|---|---|
| companyId | int | Yes | Route parameter |
| ID_Login | Guid | Yes | Query parameter |

**Response:** `ApiResponse<IReadOnlyList<ListCompanyLanguagesResponse>>`

| Field | Type | Notes |
|---|---|---|
| id | string | Language identifier |
| caption | string | Display name |
| code | string | Language code |
| isBase | boolean | Whether this is the default language |

---

## Employee

### GET /client/v1/employee

Returns the authenticated employee's profile.

**Request:**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Query parameter |

**Response:** `ApiResponse<GetEmployeeResponse>`

| Field | Type | Notes |
|---|---|---|
| displayName | string? | Full display name |
| userId | int? | User ID |
| employeeId | int? | Employee ID |
| personalNumber | string? | Personal number |
| qrCode | Guid | QR code identifier |
| phone | string? | Phone number |
| email | string? | Email address |
| isTester | bool? | Tester flag |
| noteJson | string? | Notes in JSON format |
| languageId | string? | Selected language ID |
| lang | string? | Language code |
| initials | string? | Display initials |
| color | string? | Avatar color |
| documentId | int? | Profile picture document ID |
| documentHash | string? | Profile picture hash |

---

### GET /client/v1/employee/settings

Returns employee settings. Supports ETag caching (7-day sliding expiration).

**Request:**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Query parameter |

**Headers:** `If-None-Match` — send stored ETag to check for changes (304 = unchanged)

**Response:** `ApiResponse<GetEmployeeSettingsResponse>`

**EmployeeSettingsApiModel:**

| Field | Type | Notes |
|---|---|---|
| favoriteModuleFlags | FavoriteModuleFlagsApiModel | Favorites UI state flags |
| modules | ModuleSettingsApiModel[] | Per-module settings |

**FavoriteModuleFlagsApiModel:**

| Field | Type | Notes |
|---|---|---|
| introShown | bool | Favorites intro guide shown |
| infoHighlighted | bool | Info icon highlighted |
| suggestionShown | bool | Add-to-favorites suggestion shown |

**ModuleSettingsApiModel:**

| Field | Type | Notes |
|---|---|---|
| moduleId | int | Module identifier |
| favoriteOrder | int? | Position in favorites (null = not a favourite) |

---

### PUT /client/v1/employee/settings

Updates employee settings. Generates a new ETag on response.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | |
| Settings | EmployeeSettingsApiModel | Yes | Full settings object |

**Response:** `ApiResponse<UpdateEmployeeSettingsResponse>` (empty data)

---

## Post

### GET /client/v1/post

Returns list of posts for a module.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | |
| CompanyMenuItemId | int | Yes | Module identifier |

**Response:** `ApiResponse<IReadOnlyList<ListPostResponse>>`

| Field | Type | Notes |
|---|---|---|
| postId | int | Post identifier |
| displayName | string | Title |
| text | string | Plain text content |
| textHtml | string | HTML content |
| approvalType | PostApprovalType | See enum below |
| textApprovalButton | string | Approval button label |
| textApprovalCheckbox | string | Checkbox label |
| datePublish | DateTime? | Publication date |
| dateUpdate | DateTime | Last updated |
| dateRead | DateTime? | When user read it |
| dateApproved | DateTime? | When user approved it |
| isPopUp | bool | Is a popup post |

**PostApprovalType enum:** `none` | `approve` | `approveWithCheckbox`

---

### GET /client/v1/post/{postId}

Returns full post detail including attachments.

**Request:**

| Field | Type | Required | Notes |
|---|---|---|---|
| postId | int | Yes | Route parameter |
| ID_Login | Guid | Yes | Query parameter |

**Response:** `ApiResponse<GetPostResponse>`

| Field | Type | Notes |
|---|---|---|
| postId | int | |
| displayName | string | |
| text | string | |
| textHtml | string | |
| approvalType | PostApprovalType | |
| textApprovalButton | string | |
| textApprovalCheckbox | string | |
| datePublish | DateTime? | |
| dateUpdate | DateTime | |
| dateRead | DateTime? | |
| dateApproved | DateTime? | |
| isManuallyApproved | bool? | |
| isPopUp | bool | |
| attachments | GetPostDocumentResponse[] | See below |

**GetPostDocumentResponse:**

| Field | Type | Notes |
|---|---|---|
| attachmentId | int | |
| postId | int | |
| documentId | int? | |
| documentHash | string | |
| documentUrl | string | Download URL |
| displayName | string | |
| size | int | Bytes |
| fileName | string | |
| contentType | string | MIME type |
| extension | string | |
| hash | string | |
| fileNameExtension | string | |
| imageWidth | int? | If image |
| imageHeight | int? | If image |
| order | int? | Display order |
| isDownload | bool | Allow download |

---

### POST /client/v1/post/{postId}/read

Mark a post as read.

**Request (body):**

| Field | Type | Required |
|---|---|---|
| postId | int | Yes (route) |
| ID_Login | Guid | Yes |

**Response:** `ApiResponse` (empty data)

---

### PATCH /client/v1/post/{postId}/readdetail

Mark post detail as read. Returns the full post (same shape as GET /post/{postId}).

**Request (body):**

| Field | Type | Required |
|---|---|---|
| postId | int | Yes (route) |
| ID_Login | Guid | Yes |

---

### POST /client/v1/post/readall

Mark all posts in a module as read.

**Request (body):**

| Field | Type | Required |
|---|---|---|
| ID_Login | Guid | Yes |
| CompanyMenuItemId | int | Yes |

**Response:** `ApiResponse` (empty data)

---

### POST /client/v1/post/{postId}/approve

Approve a post.

**Request (body):**

| Field | Type | Required |
|---|---|---|
| postId | int | Yes (route) |
| ID_Login | Guid | Yes |

**Response:** `ApiResponse` (empty data)

---

### GET /client/v1/post/popup

Returns popup posts. Cached 120 seconds client-side.

**Request (query params):**

| Field | Type | Required |
|---|---|---|
| ID_Login | Guid | Yes |

**Response:** `ApiResponse<IReadOnlyList<ListPostPopUpResponse>>`

| Field | Type | Notes |
|---|---|---|
| postId | int | |
| moduleId | int | |
| displayName | string | |
| text | string | |
| textHtml | string | |
| approvalType | PostApprovalType | |
| textApprovalButton | string? | |
| textApprovalCheckbox | string? | |
| datePublish | DateTime | |
| dateUpdate | DateTime | |
| dateRead | DateTime? | |
| dateApproved | DateTime? | |
| isManuallyApproved | bool | |
| isPopUp | bool | |
| attachments | GetPostDocumentResponse[] | |

---

## Survey V1

### GET /client/v1/survey

List surveys for a module.

**Request (query params):**

| Field | Type | Required |
|---|---|---|
| ID_Login | Guid | Yes |
| ModuleId | int | Yes |

**Response:** `ApiResponse<IReadOnlyList<ListWSSurveyResponse>>`

| Field | Type | Notes |
|---|---|---|
| surveyId | int | |
| displayName | string? | |
| text | string? | |
| textHtml | string? | |
| answerStateId | string? | V1 only |
| answerState | string? | V1 only |
| surveyStateId | string? | V1 only |
| questionCount | int? | |
| answeredCount | int? | |
| surveyTypeId | string | |
| surveyType | string | |
| isAnonymous | bool | |
| datePublish | DateTime? | |
| dateCreated | DateTime? | |
| dateClose | DateTime | Response deadline |
| documentCount | int | |
| documentId | int? | |
| documentHash | string? | |
| documentUrl | string? | |
| documentDisplayName | string? | |
| documentSize | int? | |
| documentFileName | string? | |
| documentContentType | string? | |
| documentExtension | string? | |
| documentFileNameExtension | string? | |
| documentImageWidth | int? | |
| documentImageHeight | int? | |

---

### GET /client/v1/survey/{surveyId}

Returns survey detail with questions and answer options.

**Request:**

| Field | Type | Required |
|---|---|---|
| surveyId | int | Yes (route) |
| ID_Login | Guid | Yes (query) |

**Response:** `ApiResponse<GetWSSurveyResponse>`

| Field | Type | Notes |
|---|---|---|
| surveyId | int | |
| surveyTypeId | string | |
| surveyType | string | |
| datePublish | DateTime? | |
| dateClose | DateTime | |
| isAnonymous | bool | |
| displayName | string? | |
| surveyText | string? | |
| surveyTextHtml | string? | |
| answerStateId | string? | V1 only |
| answerState | string? | V1 only |
| attachments | GetWSSurveyDocumentResponse[] | |
| questions | GetWSSurveyQuestionResponse[] | |

**GetWSSurveyQuestionResponse:**

| Field | Type | Notes |
|---|---|---|
| questionId | int | |
| isRequired | bool | |
| isTextArea | bool | Free text allowed |
| isOptions | bool | Multiple choice |
| isMultipleOptions | bool | Multi-select |
| order | int | |
| questionText | string? | |
| questionTextHtml | string? | |
| answerText | string? | User's current answer |
| attachments | GetWSSurveyQuestionAttachmentResponse[] | |
| options | GetWSSurveyQuestionOptionResponse[] | |

**GetWSSurveyQuestionOptionResponse:**

| Field | Type | Notes |
|---|---|---|
| questionOptionId | int | |
| order | int | |
| displayName | string | |
| isSelected | bool? | User selected this |

---

### PUT /client/v1/survey/{surveyId}/Answer

Submit or update survey answers.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| surveyId | int | Yes (route) | |
| ID_Login | Guid | Yes | |
| Questions | AddOrEditSurveyAnswerQuestionRequest[]? | No | |

**AddOrEditSurveyAnswerQuestionRequest:**

| Field | Type | Required |
|---|---|---|
| questionId | int | Yes |
| text | string? | No |
| options | AddOrEditSurveyAnswerOptionsRequest[]? | No |

**AddOrEditSurveyAnswerOptionsRequest:**

| Field | Type | Required |
|---|---|---|
| questionOptionId | int | Yes |

**Response:** `ApiResponse` (empty data)

---

### PATCH /client/v1/survey/{surveyId}/state

Update the survey answer state (e.g. submit as answered).

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| surveyId | int | Yes (route) | |
| ID_Login | Guid | Yes | |
| AnswerStateId | EditSurveyStateAnswerState | Yes | `Answered` |

**Response:** `ApiResponse` (empty data)

---

## Survey V2

### GET /client/v2/survey

Same as V1 but `answerStateId`, `answerState`, `surveyStateId` replaced by single `state` field.

**Request:** Same as V1.

**Response changes vs V1:**

| V1 Fields (removed) | V2 Replacement |
|---|---|
| answerStateId, answerState, surveyStateId | state (string?) |

---

### GET /client/v2/survey/{surveyId}

Same as V1 but `answerStateId` / `answerState` replaced by `state`.

**Response changes vs V1:**

| V1 Fields (removed) | V2 Replacement |
|---|---|
| answerStateId, answerState | state (string?) |

---

## ETag & Caching

### Employee Settings
- Send `If-None-Match: <etag>` on GET — server returns `304 Not Modified` if unchanged
- Store ETag from response `ETag` header
- Sliding expiration: 7 days

### Post Popup
- `Cache-Control: public, max-age=120` — cache on client for 120 seconds

---

## Versioning

| Version | Route prefix | Notes |
|---|---|---|
| V1 | `/client/v1/` | Full feature set |
| V2 | `/client/v2/` | Survey state field simplified |

Only Survey endpoints differ between V1 and V2. All other controllers are V1 only.
