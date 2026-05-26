# API Reference — Skeleton.Jobka.Webservice.Core

Legacy monolithic API. Use for login and any endpoints not available in Client.Api.

- **Base URL:** `api/[controller]/[action]`
- **Auth:** `ID_Login` (Guid) passed as query param or in body — obtained from the Login endpoint
- **Response wrapper:** `{ data, message, actions, isSuccess, validationMessages }`

---

## Table of Contents

- [Employee (Auth)](#employee-auth)
- [Answers](#answers)
- [Canteen](#canteen)
- [Card](#card)
- [Company](#company)
- [CompanyMenuItems](#companymenuitems)
- [Contacts](#contacts)
- [CustomModuleSettings](#custommodulesettings)
- [CustomPages](#custompages)
- [Data](#data)
- [EmployeeMessages](#employeemessages)
- [FormItems](#formitems)
- [Framework / Documents](#framework--documents)
- [Groups](#groups)
- [LicensePlates](#licenseplates)
- [Members](#members)
- [MessageGroups](#messagegroups)
- [Posts](#posts)
- [StreamPosts](#streamposts)
- [StreamPostComments](#streampostcomments)
- [Surveys](#surveys)
- [Televisions](#televisions)
- [TrustBox](#trustbox)
- [UserPhotos](#userphotos)

---

## Employee (Auth)

### GET /api/Employee/Login

Primary login endpoint. Returns session ID used in all subsequent requests.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| PersonalNumber | string | Yes | Employee personal number |
| Code | string | Yes | Access code or URI with access code |
| ID_Company | int? | No | Company ID |
| Token | string | No | Token |
| Browser | string | No | Browser / device info |
| Lang | string | No | Device language code |
| IsPersistent | bool? | No | Enable persistent login |
| ID_PersistentLogin | Guid? | No | Persistent login ID (for re-auth) |
| UriPersonalNumber | string | No | Personal number from QR code |
| DeviceID | string | No | Unique device identifier |
| DeviceName | string | No | Device name |
| ID_DeviceType | string | No | Device type ID |

**Response:**

| Field | Type | Notes |
|---|---|---|
| ID_Login | Guid? | Session token — store and pass to all subsequent calls |
| ID_PersistentLogin | Guid? | Persistent session ID |
| DisplayName | string | Full display name |
| ID_User | int? | User ID |
| ID_Language | string | Current language ID |
| ID_Employee | int? | Employee ID |
| Lang | string | Language code |
| IsFirstLogin | bool | Whether this is the first login |
| IsTester | bool | Tester flag |
| Initials | string | User initials |
| Color | string | Avatar color |
| ID_Document | int? | Profile picture document ID |
| DocumentHash | string | Hash for profile picture caching |
| PersonalNumber | string | Employee personal number |
| Phone | string | Phone number |
| Email | string | Email address |
| QrCode | Guid? | QR code identifier |
| NoteJson | string | Notes in JSON format |
| Languages | LanguageItem[] | Available languages |
| ValidationMessages | ValidateMessage[] | Errors / validation failures |

**LanguageItem:**

| Field | Type | Notes |
|---|---|---|
| ID | string | Language ID |
| Caption | string | Language name |
| Code | string | Language code |
| IsBase | bool | Whether it's the base language |

---

### POST /api/Employee/EditLanguage

Change the authenticated employee's language.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| Code | string | Yes | Language code to switch to |

**Response:** `{ ValidationMessages[] }`

---

### GET /api/Employee/CheckPrivateData

Returns a SAS-signed Azure blob URL pointing to the company's `XMLConfiguration` file. The XML contains all navigation menu items (with icons, colors, types, folder hierarchy) and company branding.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| DateUpdate | DateTime? | No | Pass last `Date` value to detect changes |

**Response:**

| Field | Type | Notes |
|---|---|---|
| Url | string | SAS URL valid 10 min — download XML from here |
| IsChange | bool | False if data unchanged since `DateUpdate` |
| Date | DateTime? | Timestamp of last data change |

**Downloaded XML structure (`XMLConfiguration`):**
- `Company` — branding: `DisplayName`, `CompanyColor`, `BackgroundColor`, `CompanyAccentColor`
- `MenuItems[]` — each `MenuItemData`:
  - `ItemId` (int), `Title` (string), `Order` (int?), `IdParentItem` (int? — null = root)
  - `Icon` (Unicode char for custom font), `IconName` (string), `FontFamily` (string)
  - `TileColor`, `TextColor`, `IconColor` — each `{ Alpha, Red, Green, Blue }`
  - `ItemType` — enum: `PostList | SurveyList | AboutApp | CustomPage | TrustBox | Settings | Stream | Canteen | LicensePlates | Contacts | Url | ChatList | Form | Television | Folder | Card | List`
  - `IsEnabled` (bool), `NumberOfNew` (int)

---

### GET /api/Employee/Detail

Get employee details.

**Request (query params):** `ID_Login` (Guid)

---

### GET /api/Employee/DetailUnread

Get employee details with unread notification counts.

**Request (query params):** `ID_Login` (Guid)

---

### GET /api/Employee/AllCompanyChat

Get all employees available in company chat.

**Request (query params):** `ID_Login` (Guid)

---

### POST /api/Employee/Register

Self-register a new employee.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| RegisterKey | string | Yes | Registration key |
| DisplayName | string | Yes | Display name |
| PersonalNumber | string | Yes | Personal number |
| Email | string | No | Email address |
| Campaign | string | No | Campaign code |
| Lang | string | No | Language code |

---

## Answers

### POST /api/Answer/New

Submit a survey answer.

**Request (body):** `AnswerNewWSInput` — `{ ID_Login, ... }`

**Response:** `{ ID }` — ID of the created answer record

---

## Canteen

### GET /api/Canteen/All

List all canteens available to the employee.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_CompanyMenuItem | int? | No | CompanyMenuItem ID for multi-canteen setup |
| ExternalLogin | string | No | External system session ID |
| ExternalPersonId | string | No | External personal number |

**Response:** `CanteenAllWSOutput[]`

| Field | Type | Notes |
|---|---|---|
| ID | int | Canteen ID |
| DisplayName | string | Canteen name |
| ExternalId | string | External system identifier |

---

### POST /api/Canteen/Login

Authenticate with the external canteen system. Required before ordering.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| Password | string | Yes | Canteen PIN / password |
| ID_CompanyMenuItem | int? | No | CompanyMenuItem ID |

**Response:**

| Field | Type | Notes |
|---|---|---|
| ExternalLogin | string | External canteen session ID — pass to subsequent canteen calls |
| ExternalPersonId | string | External personal number |

---

### GET /api/Canteen/CarteChoiceAll

Get menu choices for a specific canteen and day.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_Canteen | int | Yes | Canteen ID from `/Canteen/All` |
| Day | DateTime | Yes | Date to fetch menu for |
| ID_CompanyMenuItem | int? | No | CompanyMenuItem ID |
| ExternalLogin | string | No | External session from `/Canteen/Login` |
| ExternalPersonId | string | No | External personal number |
| ExternalCanteenId | string | No | External canteen identifier |

**Response:** `CarteChoiceAllSlotModel[]` (time slots)

**CarteChoiceAllSlotModel:**

| Field | Type | Notes |
|---|---|---|
| ID_CarteSlot | int? | Slot ID |
| DisplayName | string | Slot name (e.g. "Lunch") |
| ExternalId | string | External slot ID |
| Sections | CarteChoiceAllSectionModel[] | Food sections within slot |

**CarteChoiceAllSectionModel:**

| Field | Type | Notes |
|---|---|---|
| ID_CarteSection | int? | Section ID |
| DisplayName | string | Section name (e.g. "Soup", "Main") |
| ExternalId | string | External section ID |
| Choices | CarteChoiceAllCarteChoiceModel[] | Individual food items |

**CarteChoiceAllCarteChoiceModel:**

| Field | Type | Notes |
|---|---|---|
| ID_Choice | int? | Choice ID |
| DisplayName | string | Food name |
| Description | string | Food description |
| FullPrice | decimal | Full price |
| AllowedPrice | decimal | Subsidised price |
| StateCount | int | Currently ordered portions |
| ExternalId | string | External choice ID |
| CanOrder | bool | Whether this item can be ordered |

---

### POST /api/Canteen/OrderNew

Place or update a canteen order for a given day.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| Day | DateTime | Yes | Date to order for |
| CarteChoices | OrderNewCanteenCarteChoiceInput[] | Yes | Items to order |
| ID_Canteen | int? | No | Canteen ID |
| ExternalCanteenId | string | No | External canteen ID |
| ID_CompanyMenuItem | int? | No | CompanyMenuItem ID |
| ExternalLogin | string | No | External session ID |
| ExternalPersonId | string | No | External personal number |
| ID_Employee | int? | No | Employee ID (admin use) |

**OrderNewCanteenCarteChoiceInput:**

| Field | Type | Notes |
|---|---|---|
| ID_CarteChoice | int | Choice ID |
| StateCount | int | Number of portions (0 = cancel) |
| ExternalSlotId | string | External slot ID |
| ExternalSectionId | string | External section ID |
| ExternalChoiceId | string | External choice ID |

**Response:**

| Field | Type | Notes |
|---|---|---|
| CarteChoices | OrderNewCanteenCarteChoiceOutput[] | Result per ordered item |
| SlotValidations | OrderNewCanteenSlotValidationOutput[] | Slot-level validation errors |

**OrderNewCanteenCarteChoiceOutput:**

| Field | Type | Notes |
|---|---|---|
| ID_CarteChoice | int? | Choice ID |
| IsSuccess | bool | Whether this item was ordered successfully |
| StateCount | int | Current ordered portion count |
| ExternalSlotId | string | |
| ExternalSectionId | string | |
| ExternalChoiceId | string | |

**OrderNewCanteenSlotValidationOutput:**

| Field | Type | Notes |
|---|---|---|
| ID_CarteSlot | int | Slot ID |
| IsSuccess | bool | True if no validation errors for this slot |
| ValidationMessages | ValidateMessage[] | Slot-level errors |

---

## Card

### GET /api/Card/ActualCard

Get the employee's current loyalty/benefit card.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_CompanyMenuItem | int? | No | CompanyMenuItem ID |

**Response:** `CardAllActualCardWSOutputModel` (card details — structure depends on card provider)

---

### GET /api/Card/IsEmailRegistered

Check if an email is already registered for a card.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| Email | string | Yes | Email to check |

**Response:**

| Field | Type | Notes |
|---|---|---|
| Result | bool | True if email is already registered |

---

### POST /api/Card/AddPromoCode

Add a promotion code to a card.

**Request (body):** `AddPromoCardProviderModel` — provider-specific fields

---

### POST /api/Card/RegisterWithPromo

Register a new card with a promo code.

**Request (body):** `RegisterWithPromoCardProviderModel` — provider-specific fields

---

## Company

### GET /api/Company/CheckState

Check company state / license status.

**Request (query params):** `ID_Login` (Guid)

---

## CompanyMenuItems

### GET /api/CompanyMenuItem/AllNavigation

Get navigation menu items for the authenticated employee. Returns root-level items when `ID_CompanyMenuItem` is omitted; returns folder contents when provided.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_CompanyMenuItem | int? | No | Folder ID — omit for root menu |
| IsBackOffice | bool? | No | Back-office mode (default false) |

**Response:** `CompanyMenuItemAllNavigationWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID | int | CompanyMenuItem ID |
| Icon | string | Icon name |
| IconUnicode | string | Unicode icon character |
| ID_MenuItem | string | Module type key (e.g. "Posts", "Surveys") |
| MenuItem | string | Module type name |
| DisplayName | string | Custom display name for this company |
| TileColor | string | Hex color for tile background |
| HasGroup | bool? | True if item is a folder with sub-items |
| IsDisable | bool | Whether item is disabled |
| MenuType_ResourceName | string | Resource name |
| Order | int | Sort order |
| Route | string | Navigation route |

---

### GET /api/CompanyMenuItem/AllNumberOfNew

Get count of new/unread items per menu entry.

**Request (query params):** `ID_Login` (Guid)

**Response:** `CompanyMenuItemAllNumberOfNewWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID_CompanyMenuItem | int | Module ID |
| ID_MenuItem | string | Module type key |
| NumberOfNew | int | Count of unread/new items |

---

## Contacts

### GET /api/Contact/All

Get contacts list with change detection support.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_CompanyMenuItem | int? | No | CompanyMenuItem ID |
| LastUpdate | DateTime? | No | Pass last known `LastUpdate` to get only changed data |

**Response:** `ContactAllChangedWSOutputModel`

| Field | Type | Notes |
|---|---|---|
| IsChange | bool | True if data changed since `LastUpdate` |
| LastUpdate | DateTime? | Current data timestamp |
| Data | ContactAllChangedWSItemOutputModel[] | Contact items |

**ContactAllChangedWSItemOutputModel:**

| Field | Type | Notes |
|---|---|---|
| ID | int | Contact ID |
| ID_CompanyMenuItem | int | CompanyMenuItem ID |
| DisplayName | string | Display name |
| FirstName | string | First name |
| MiddleName | string | Middle name |
| LastName | string | Last name |
| NamePrefix | string | Title before name |
| NameSuffix | string | Title after name |
| SortName | string | Name used for sorting |
| Initials | string | Initials |
| JobTitle | string | Job title / role |
| Department | string | Department |
| Phone | string | Primary phone |
| SecondPhone | string | Secondary phone |
| Email | string | Primary email |
| SecondEmail | string | Secondary email |
| Color | string | Avatar color |
| ID_Document | int? | Profile photo document ID |
| DocumentHash | string | Profile photo hash |

---

## CustomModuleSettings

### GET /api/CustomModuleSettings/All

Get all custom module settings for the authenticated company.

**Request (query params):** `ID_Login` (Guid), `ID_CompanyMenuItem` (int?)

---

## CustomPages

### GET /api/CustomPage/All

Get all custom pages (legacy).

**Request (query params):** `ID_Login` (Guid), `ID_CompanyMenuItem` (int?)

---

### POST /api/CustomPage/AllWeb

Get custom pages for web display.

**Request (body):** `{ ID_Login, ID_CompanyMenuItem? }`

---

## Data

Form data module — used for generic list/detail/new/delete on company-configured forms.

### GET /api/Data/AllCompanyMenuItem

Get list data for a form module (legacy).

**Request (query params):** `ID_Login`, `ID_CompanyMenuItem` (int)

---

### GET /api/Data/AllCompanyMenuItemV2

Get list data for a form module (V2 — prefer over V1).

**Request (query params):** `ID_Login`, `ID_CompanyMenuItem` (int)

---

### GET /api/Data/DetailCompanyMenuItem

Get detail of a data record (legacy).

**Request (query params):** `ID_Login`, `ID_CompanyMenuItem` (int), `ID` (int — record ID)

---

### GET /api/Data/DetailCompanyMenuItemV2

Get detail of a data record (V2 — prefer over V1).

**Request (query params):** `ID_Login`, `ID_CompanyMenuItem` (int), `ID` (int — record ID)

---

### POST /api/Data/NewDataItems

Create or update a data record (legacy).

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_CompanyForm | int? | No | Form definition ID |
| ID_Data | int? | No | Record ID to edit (omit to create) |
| DataItems | InputItemModel[] | Yes | Field values |

---

### POST /api/Data/NewDataItemsV2

Create or update a data record (V2).

**Request (body):** Same structure as V1.

---

### POST /api/Data/DelDataItems

Delete a data record (legacy).

**Request (body):** `{ ID_Login, ID? }` — ID of the record to delete

---

### POST /api/Data/DelDataItemsV2

Delete a data record (V2).

**Request (body):** `{ ID_Login, ID? }`

---

### POST /api/Data/Translate

Translate data items to the employee's language.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| Items | DataTranslateInputItemModel[] | Yes | Items to translate |

---

## EmployeeMessages

Direct messages and group chat.

### GET /api/EmployeeMessage/All

Get list of conversations (one per peer or group).

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_CompanyMenuItem | int? | No | Chat module ID |
| Top | int? | No | Max results (default 500) |

**Response:** `EmployeeMessageAllWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID_Employee | int? | Peer employee ID (null for group) |
| Employee | string | Peer employee name |
| Initials | string | Peer initials |
| Color | string | Peer avatar color |
| ID_MessageGroup | int? | Group ID (null for direct) |
| MessageGroup | string | Group name |
| Message | string | Last message text |
| Sent | DateTime | Last message timestamp |
| ID_Document | int? | Last message attachment ID |
| IsDocument | bool | True if last message is a document |
| DocumentHash | string | Attachment hash |
| IsOut | bool? | True if last message was sent by current user |
| IsRead | bool? | True if last message has been read |
| IsLogged | bool? | True if this is a logged (system) message |
| ID_Member | int? | Current user's member ID in group |
| ID_MemberPermission | string | Current user's permission in group |
| ID_EmployeeMember | int? | Co-member ID (for 1:1 chats in group context) |
| EmployeeMember | string | Co-member name |
| EmployeeMemberInitials | string | Co-member initials |
| EmployeeMemberColor | string | Co-member color |
| IsNotify | bool? | Whether notifications are enabled |
| MemberCount | int? | Group member count |
| MemberRequestCount | int? | Pending join requests (admin only) |
| IsLeavingEnabled | bool? | Whether the user can leave the group |

---

### GET /api/EmployeeMessage/AllEmployee

Get message history with a specific employee.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_Employee | int? | No | Peer employee ID |
| ID_CompanyMenuItem | int? | No | Chat module ID |
| Top | int? | No | Max results |
| OffsetDate | DateTime? | No | Pagination offset timestamp |
| OffsetAscending | bool? | No | Pagination direction |

**Response:** `EmployeeMessageAllEmployeeWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID | int | Message ID |
| Message | string | Message text |
| Sent | DateTime | Sent timestamp |
| ID_Document | int? | Attachment document ID |
| Hash | string | Attachment hash |
| IsOut | bool? | True if sent by current user |
| Employee | string | Sender name |
| EmployeeInicial | string | Sender initials |
| EmployeeColor | string | Sender color |
| EmployeeDocument | int? | Sender profile photo ID |
| EmployeeDocumentHash | string | Sender photo hash |
| EmployeeReceiver | string | Receiver name |
| EmployeeRecieverInicial | string | Receiver initials |
| EmployeeRecieverColor | string | Receiver color |
| EmployeeReceiverDocument | int? | Receiver profile photo ID |
| EmployeeReceiverDocumentHash | string | Receiver photo hash |

---

### GET /api/EmployeeMessage/AllMessageGroup

Get message history for a group chat.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_MessageGroup | int? | No | Group ID |
| Top | int? | No | Max results |
| OffsetDate | DateTime? | No | Pagination offset timestamp |
| OffsetAscending | bool? | No | Pagination direction |

**Response:** `EmployeeMessageAllMessageGroupWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID | int | Message ID |
| Message | string | Message text |
| Sent | DateTime | Sent timestamp |
| ID_Document | int? | Attachment document ID |
| Hash | string | Attachment hash |
| IsOut | bool? | True if sent by current user |
| IsLogged | bool? | System message flag |
| ID_Employee | int? | Sender employee ID |
| DisplayName | string | Sender display name |
| Initials | string | Sender initials |
| Color | string | Sender avatar color |
| ID_DocumentEmployee | int? | Sender profile photo ID |
| HashEmployee | string | Sender photo hash |

---

### POST /api/EmployeeMessage/New

Send a direct or group message.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_EmployeeReceiver | int? | No | Receiver employee ID (direct message) |
| ID_MessageGroup | int? | No | Group ID (group message) |
| Message | string | No | Message text |
| DocumentContent | byte[] | No | Attachment file bytes |
| FileName | string | No | Attachment filename |
| ID_CompanyMenuItem | int? | No | Chat module ID |

**Response:** `EmployeeMessageNewWSOutput` — `{ ID?, ValidationMessages[] }`

---

### POST /api/EmployeeMessage/Del

Delete a conversation (marks chat as deleted for current user).

**Request (body):** `EmployeeMessageDelChatWSInputModel` — `{ ID_Login, ID_Employee?, ID_MessageGroup? }`

---

### GET /api/EmployeeMessage/IsNew

Check if there are any new unread messages.

**Request (query params):** `ID_Login` (Guid), `ID_CompanyMenuItem` (int?)

**Response:** `EmployeeMessageIsNewWSOutput` — `{ IsNew: bool }`

---

### GET /api/EmployeeMessage/IsNewMessageGroup

Check if there are new messages in a specific group.

**Request (query params):** `ID_Login` (Guid), `ID_MessageGroup` (int?)

**Response:** `EmployeeMessageIsNewMessageGroupWSOutputModel` — `{ IsNew: bool }`

---

## FormItems

### GET /api/FormItem/AllForm

Get form field definitions for a form module (legacy).

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_CompanyMenuItem | int? | No | Form module ID |
| ID_Data | int? | No | Record ID to pre-fill values |
| QueryParameters | string | No | Additional parameters from URL query string |

---

### GET /api/FormItem/AllFormV2

Get form field definitions (V2 — prefer over V1).

**Request (query params):** Same as V1.

---

## Framework / Documents

### GET /api/Framework/Document/Detail

Download a document / image by ID. Returns raw file bytes.

**Note:** This controller has an explicit route `[Route("api/Framework/Document")]`.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID | int | Yes | Document ID |
| ID_Login | Guid? | No | Session token (some docs require auth) |
| Width | int? | No | Resize image to this width |
| Height | int? | No | Resize image to this height |
| Effect | string | No | Image effect (e.g. "grayscale") |

**Response:** Raw file — `Content-Type` set to actual MIME type, `Content-Disposition` with filename. HTTP status reflects success/not-found.

---

## Groups

### GET /api/Group/AllCompanyChat

Get all groups available in company chat.

**Request (query params):** `ID_Login` (Guid)

---

## LicensePlates

### POST /api/LicensePlate/ProcessImage

Process a license plate image to identify the employee.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| Image | byte[] | No | Raw image bytes |
| LicensePlate | string | No | Manually entered plate (alternative to image) |

**Response:**

| Field | Type | Notes |
|---|---|---|
| ID_Employee | int? | Matched employee ID |
| Displayname | string | Employee display name |
| LicensePlate | string | Recognized plate text |

---

## Members

Group chat member management.

### GET /api/Member/All

Get members of a message group.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_MessageGroup | int? | No | Group ID |
| ID | int? | No | Specific member ID |
| ID_Employee | int? | No | Filter by employee |
| ID_MemberPermission | string | No | Filter by permission level |
| Top | int? | No | Max results |

**Response:** `MemberAllMessageGroupWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID | int | Member record ID |
| ID_MessageGroup | int | Group ID |
| MessageGroup | string | Group name |
| ID_Employee | int | Employee ID |
| Employee | string | Employee display name |
| RealName | string | Employee real name |
| ID_Document | int? | Profile photo ID |
| Hash | string | Profile photo hash |
| ID_MemberPermission | string | Permission: `"Admin"` or `"Member"` |
| IsLogged | bool? | Whether this member is currently logged |
| Initials | string | Initials |
| Color | string | Avatar color |

---

### GET /api/Member/Del

Remove a member from a group.

**Request (query params):** `{ ID_Login, ID }` — ID = member record ID

---

### POST /api/Member/New

Add a member to a group.

**Request (body):** `MemberNewWSInput` — `{ ID_Login, ID_MessageGroup, ID_Employee, ID_MemberPermission? }`

---

### POST /api/Member/Edit

Edit a member record.

**Request (body):** `MemberEditWSInput` — `{ ID_Login, ID, ... }`

---

### POST /api/Member/EditPermission

Change a member's permission level.

**Request (body):** `MemberEditPermissionWSInput` — `{ ID_Login, ID, ID_MemberPermission }`

---

## MessageGroups

### GET /api/MessageGroup/All

Get all group chats the user belongs to or can see.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| DisplayName | string | No | Filter by group name |
| ID_Employee | int? | No | Filter by employee membership |
| Top | int? | No | Max results (default 500) |

**Response:** `MessageGroupAllWSOutput[]`

| Field | Type | Notes |
|---|---|---|
| ID | int? | Group ID |
| DisplayName | string | Group name |
| Description | string | Group description |
| ID_Document | int? | Group avatar document ID |
| DocumentHash | string | Group avatar hash |
| ID_Member | int? | Current user's member record ID |
| ID_MemberPermission | string | Current user's permission |
| ID_Employee | int? | Employee ID (context dependent) |
| Employee | string | Employee name |
| ID_EmployeeMember | int? | Co-member ID |
| EmployeeMember | string | Co-member name |
| IsNotify | bool? | Notifications enabled |
| MemberCount | int? | Number of members |
| MemberRequestCount | int? | Pending join requests (admin only) |
| IsLeavingEnabled | bool? | Whether user can leave |

---

### GET /api/MessageGroup/Detail

Get details of a specific message group.

**Request (query params):** `{ ID_Login, ID }`

---

### POST /api/MessageGroup/New

Create a new group chat.

**Request (body):** `MessageGroupNewWSInput` — `{ ID_Login, DisplayName, Description?, ... }`

---

### POST /api/MessageGroup/Edit

Edit group chat details.

**Request (body):** `MessageGroupEditWSInput` — `{ ID_Login, ID, DisplayName?, Description?, ... }`

---

### GET /api/MessageGroup/Del

Delete a message group.

**Request (query params):** `{ ID_Login, ID }`

---

## Posts

### GET /api/Post/All

Get list of posts for the authenticated employee.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_Module | int? | No | CompanyMenuItem ID (post module) |
| ID_Company | int? | No | Company ID filter |
| ID_Employee | int? | No | Employee ID filter |

**Response:** `PostAllWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID | int | Post ID |
| DisplayName | string | Post title |
| Text | string | Post text (plaintext) |
| TextHtml | string | Post text (HTML) |
| DateCreated | DateTime | Publication date |
| IsNew | bool | True if unread |
| IsEdited | bool? | True if post was edited |
| DocumentCount | int? | Number of attachments |
| ID_Document | int? | Primary image/attachment ID |
| DocumentHash | string | Primary attachment hash |
| DocumentUrl | string | Primary attachment URL |
| DocumentDisplayName | string | Primary attachment filename |
| DocumentSize | int? | File size in bytes |
| DocumentFileName | string | Filename with extension |
| DocumentContentType | string | MIME type |
| DocumentExtension | string | Extension without dot |
| DocumentFileNameExtension | string | Extension with dot |
| DocumentImageWidth | int? | Image width (px) |
| DocumentImageHeight | int? | Image height (px) |

---

### GET /api/Post/Detail

Get full post details including attachments.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_Post | int? | No | Post ID |

**Response:** `PostDetailWSOutputModel`

| Field | Type | Notes |
|---|---|---|
| ID | int | Post ID |
| DisplayName | string | Title |
| Text | string | Plaintext body |
| TextHtml | string | HTML body |
| DateCreated | DateTime | Publication date |
| IsNew | bool | Unread flag |
| IsEdited | bool? | Edited flag |
| ID_Document | int? | Primary attachment ID |
| DocumentHash | string | Primary attachment hash |
| DocumentUrl | string | Primary attachment URL |

---

### POST /api/Post/ChangeNewAll

Mark all posts in a module as read.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_Module | int? | No | Post module CompanyMenuItem ID |

---

## StreamPosts

### GET /api/StreamPost/All

Get list of stream (social wall) posts.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_Module | int? | No | Stream module ID |
| Top | int? | No | Max results (default 500) |

**Response:** `StreamPostAllWSOutput[]`

| Field | Type | Notes |
|---|---|---|
| ID | int? | Post ID |
| DisplayName | string | Post title |
| DateCreated | DateTime? | Creation date |
| Message | string | Post text (plaintext) |
| MessageHtml | string | Post text (HTML) |
| Author | string | Author display name |
| NumberOfComments | int? | Comment count |
| ID_Document | int? | Attachment document ID |
| DocumentHash | string | Attachment hash |

---

### GET /api/StreamPost/Detail

Get full stream post detail including comments.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID | int? | No | Post ID |

**Response:** `StreamPostDetailWSOutput`

| Field | Type | Notes |
|---|---|---|
| ID | int? | Post ID |
| DisplayName | string | Title |
| DateCreated | DateTime? | Creation date |
| Message | string | Plaintext body |
| MessageHtml | string | HTML body |
| Author | string | Author name |
| ID_Document | int? | Attachment ID |
| DocumentHash | string | Attachment hash |
| DocumentUrl | string | Attachment URL |
| Comments | StreamPostDetailWSCommentOutput[] | Threaded comments (max 2 levels) |

**StreamPostDetailWSCommentOutput:**

| Field | Type | Notes |
|---|---|---|
| ID | int | Comment ID |
| Author | string | Author name |
| DateCreated | DateTime | Posted at |
| Comment | string | Comment text |
| IsReply | bool | True if this is a reply |
| Level | int | 1 = top-level, 2 = reply |
| ID_StreamPostParent | int? | Parent comment ID (for replies) |
| ReplyComments | StreamPostDetailWSCommentOutput[] | Nested replies |

---

### POST /api/StreamPost/New

Create a new stream post.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| DisplayName | string | No | Post title |
| Message | string | No | Post text (plaintext) |
| MessageHtml | string | No | Post text (HTML) |
| Photo | byte[] | No | Attached image bytes |
| ID_Module | int? | No | Stream module ID |

**Response:** `{ ID?, ValidationMessages[] }`

---

## StreamPostComments

### POST /api/StreamPostComment/New

Post a comment on a stream post.

**Request (body):** `StreamPostCommentNewStreamPostWSInput` — `{ ID_Login, ID_StreamPost, Comment, ID_StreamPostParent? }`

**Response:** `{ ID?, ValidationMessages[] }`

---

## Surveys

### GET /api/Survey/All

Get list of surveys available to the employee.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID_Module | int? | No | Survey module CompanyMenuItem ID |
| ID_Company | int? | No | Company ID filter |

**Response:** `SurveyAllWSOutputModel[]`

| Field | Type | Notes |
|---|---|---|
| ID | int | Survey ID |
| DisplayName | string | Survey title |
| DateCreated | DateTime | Created date |
| DateClose | DateTime | Deadline for answers |
| SurveyText | string | Survey description (plaintext) |
| SurveyTextHtml | string | Survey description (HTML) |
| IsAnswered | bool? | Whether current user has answered |
| ID_SurveyState | string | State: `"Open"`, `"Closed"`, etc. |
| DocumentCount | int? | Attachment count |
| ID_Document | int? | Attachment ID |
| DocumentHash | string | Attachment hash |
| DocumentUrl | string | Attachment URL |
| DocumentDisplayName | string | Attachment filename |
| DocumentSize | int? | File size |
| DocumentFileName | string | Filename |
| DocumentContentType | string | MIME type |
| DocumentExtension | string | Extension |
| DocumentFileNameExtension | string | Extension with dot |
| DocumentImageWidth | int? | Image width |
| DocumentImageHeight | int? | Image height |

---

### GET /api/Survey/Detail

Get full survey detail including answer options.

**Request (query params):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| ID | int? | No | Survey ID |
| ID_Employee | int? | No | Employee ID (admin use) |

**Response:** `SurveyDetailWSOutputModel`

| Field | Type | Notes |
|---|---|---|
| ID | int | Survey ID |
| DisplayName | string | Title |
| DateCreated | DateTime | Created date |
| DateClose | DateTime | Deadline |
| SurveyText | string | Description (plaintext) |
| SurveyTextHtml | string | Description (HTML) |
| IsTextarea | bool | True if free-text answer |
| IsOptions | bool | True if multiple choice |
| IsMultipleOptions | bool | True if multiple selections allowed |
| AnswerText | string | Current user's free-text answer |
| IsAnswered | bool? | Whether current user has answered |
| ID_SurveyState | string | Survey state |
| ID_Document | int? | Attachment ID |
| DocumentHash | string | Attachment hash |
| DocumentUrl | string | Attachment URL |
| Options | SurveyDetailWSOptionOutputModel[] | Answer choices |

**SurveyDetailWSOptionOutputModel:**

| Field | Type | Notes |
|---|---|---|
| ID | int? | Option ID |
| DisplayName | string | Option text |
| IsSelected | bool | True if current user selected this option |

---

### GET /api/Survey/TmpDetail

Alias for `/api/Survey/Detail` — same request/response. Legacy endpoint; use `Detail` instead.

---

## Televisions

### GET /api/Television/DetailIsChanged

Check if TV content has changed since a given version.

**Request (query params):** `{ ID_Login, ID_CompanyMenuItem?, Version? }`

**Response:** `TelevisionDetailIsChangedOutputModel` — `{ IsChanged: bool, ... }`

---

## TrustBox

### POST /api/TrustBox/New

Submit an anonymous trust box entry (suggestion / complaint).

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| Body | string | No | Message body |
| Email | string | No | Sender email (optional, for non-anonymous) |
| ID_Module | int? | No | TrustBox module ID |

**Response:** `int?` — ID of the created entry

---

## UserPhotos

### POST /api/UserPhoto/DelUserLogin

Delete the current user's profile photo.

**Request (body):** `{ ID_Login }`

---

### POST /api/UserPhoto/EditUserLogin

Upload or replace the current user's profile photo.

**Request (body):**

| Field | Type | Required | Notes |
|---|---|---|---|
| ID_Login | Guid | Yes | Session token |
| FileName | string | Yes | Filename with extension |
| DocumentContent | byte[] | Yes | Raw image bytes |

---

## Common Patterns

### Response envelope
All endpoints return:
```json
{
  "data": { ... },
  "message": "string or null",
  "actions": [],
  "isSuccess": true,
  "validationMessages": []
}
```

### Access denied
If `ID_Login` is invalid or expired the API returns `401 Unauthorized`.

### Validation errors
Errors are returned in `validationMessages[]`:
```json
{ "code": "ERROR_CODE", "message": "Human readable message" }
```

### V1 vs V2 endpoints
Several domains have both legacy and V2 variants. Always prefer V2 when available.

### Document references
Many responses include optional document fields:
- `ID_Document` — document ID, used with `/api/Framework/Document/Detail?ID={id}`
- `DocumentHash` — ETag-style hash for cache invalidation
- `DocumentUrl` — direct URL (may be pre-signed)
