import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    var idLogin: String?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatters: [DateFormatter] = {
                let f1 = DateFormatter()
                f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
                f1.locale = Locale(identifier: "en_US_POSIX")
                let f2 = DateFormatter()
                f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                f2.locale = Locale(identifier: "en_US_POSIX")
                let f3 = DateFormatter()
                f3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                f3.locale = Locale(identifier: "en_US_POSIX")
                let isoFormatter = DateFormatter()
                isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                isoFormatter.locale = Locale(identifier: "en_US_POSIX")
                return [f1, f2, f3, isoFormatter]
            }()
            for formatter in formatters {
                if let date = formatter.date(from: dateString) { return date }
            }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Generic request methods

    /// Execute a GET request to the Webservice.Core API
    func wsGet<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        responseType: T.Type
    ) async -> AppResult<T> {
        let config = await ConfigManager.shared.webserviceURL
        return await get(
            baseURL: config, path: path, queryItems: queryItems,
            responseType: responseType, isClientApi: false)
    }

    /// Execute a GET request to the Client.Api
    func clientGet<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        responseType: T.Type
    ) async -> AppResult<T> {
        let config = await ConfigManager.shared.clientApiURL
        return await get(
            baseURL: config, path: path, queryItems: queryItems,
            responseType: responseType, isClientApi: true)
    }

    /// Execute a POST request to the Webservice.Core API
    func wsPost<B: Encodable, T: Decodable>(
        path: String,
        body: B,
        responseType: T.Type
    ) async -> AppResult<T> {
        let config = await ConfigManager.shared.webserviceURL
        return await post(
            baseURL: config, path: path, body: body,
            responseType: responseType, isClientApi: false)
    }

    /// Execute a POST request to the Client.Api
    func clientPost<B: Encodable, T: Decodable>(
        path: String,
        body: B,
        responseType: T.Type
    ) async -> AppResult<T> {
        let config = await ConfigManager.shared.clientApiURL
        return await post(
            baseURL: config, path: path, body: body,
            responseType: responseType, isClientApi: true)
    }

    /// Execute a PUT request to the Client.Api
    func clientPut<B: Encodable, T: Decodable>(
        path: String,
        body: B,
        responseType: T.Type
    ) async -> AppResult<T> {
        let config = await ConfigManager.shared.clientApiURL
        return await request(
            method: "PUT", baseURL: config, path: path, body: body,
            responseType: responseType, isClientApi: true)
    }

    /// Execute a PATCH request to the Client.Api
    func clientPatch<B: Encodable, T: Decodable>(
        path: String,
        body: B,
        responseType: T.Type
    ) async -> AppResult<T> {
        let config = await ConfigManager.shared.clientApiURL
        return await request(
            method: "PATCH", baseURL: config, path: path, body: body,
            responseType: responseType, isClientApi: true)
    }

    /// Download raw data (for documents/images)
    func downloadData(url: URL) async -> AppResult<Data> {
        AppLogger.api.debug("⬇️ DOWNLOAD \(AppLogger.redactURL(url))")
        do {
            let (data, response) = try await performNonCancellableDataTask(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknown(URLError(.badServerResponse)))
            }
            AppLogger.api.debug(
                "⬇️ DOWNLOAD \(httpResponse.statusCode) [\(data.count) bytes]")
            guard (200...299).contains(httpResponse.statusCode) else {
                return .failure(
                    .server(statusCode: httpResponse.statusCode, message: nil))
            }
            return .success(data)
        } catch let error as URLError {
            AppLogger.api.error(
                "⬇️ DOWNLOAD FAILED: \(error.localizedDescription)")
            return .failure(.network(error))
        } catch {
            AppLogger.api.error(
                "⬇️ DOWNLOAD FAILED: \(error.localizedDescription)")
            return .failure(.unknown(error))
        }
    }

    private func performNonCancellableDataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let result = try await session.data(for: request)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func performNonCancellableDataTask(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let result = try await session.data(from: url)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func injectIdLogin(_ queryItems: inout [URLQueryItem]) {
        if let idLogin = idLogin,
            !queryItems.contains(where: { $0.name == "ID_Login" })
        {
            queryItems.append(URLQueryItem(name: "ID_Login", value: idLogin))
        }
    }

    private func get<T: Decodable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem],
        responseType: T.Type,
        isClientApi: Bool
    ) async -> AppResult<T> {
        var items = queryItems
        injectIdLogin(&items)

        guard var components = URLComponents(string: baseURL + path) else {
            return .failure(.unknown(URLError(.badURL)))
        }
        components.queryItems = items.isEmpty ? nil : items

        guard let url = components.url else {
            return .failure(.unknown(URLError(.badURL)))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return await execute(
            request, responseType: responseType, isClientApi: isClientApi)
    }

    private func post<B: Encodable, T: Decodable>(
        baseURL: String,
        path: String,
        body: B,
        responseType: T.Type,
        isClientApi: Bool
    ) async -> AppResult<T> {
        return await self.request(
            method: "POST", baseURL: baseURL, path: path, body: body,
            responseType: responseType, isClientApi: isClientApi)
    }

    private func request<B: Encodable, T: Decodable>(
        method: String,
        baseURL: String,
        path: String,
        body: B,
        responseType: T.Type,
        isClientApi: Bool
    ) async -> AppResult<T> {
        guard var components = URLComponents(string: baseURL + path) else {
            return .failure(.unknown(URLError(.badURL)))
        }

        // Inject ID_Login as query param for Client API auth
        var queryItems = components.queryItems ?? []
        injectIdLogin(&queryItems)
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            return .failure(.unknown(URLError(.badURL)))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return .failure(.unknown(error))
        }

        return await execute(
            request, responseType: responseType, isClientApi: isClientApi)
    }

    private func execute<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        isClientApi: Bool
    ) async -> AppResult<T> {
        let method = request.httpMethod ?? "GET"
        let urlStr = request.url.map { AppLogger.redactURL($0) } ?? "<nil>"
        let bodyStr = AppLogger.redactBody(request.httpBody)

        AppLogger.api.info("➡️ \(method) \(urlStr)")
        if request.httpBody != nil {
            AppLogger.api.debug("📤 Body: \(bodyStr)")
        }

        // Log to in-app debug store
        await DebugLogStore.shared.logHTTP(
            method: method, url: urlStr,
            detail: request.httpBody != nil ? "Body: \(bodyStr)" : nil)

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let (data, response) = try await performNonCancellableDataTask(for: request)
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.api.error(
                    "⬅️ \(method) \(urlStr) — no HTTP response")
                await ErrorReportStore.shared.addError(
                    url: urlStr, method: method, statusCode: nil,
                    duration: elapsed, requestBody: bodyStr,
                    errorMessage: "No HTTP response")
                return .failure(.unknown(URLError(.badServerResponse)))
            }

            let statusCode = httpResponse.statusCode
            AppLogger.api.info(
                "⬅️ \(method) \(urlStr) → \(statusCode) [\(String(format: "%.0f", elapsed * 1000))ms, \(data.count)B]"
            )

            // Log every response to in-app debug store
            let responseSnippet = String(data: data, encoding: .utf8)
            await DebugLogStore.shared.logHTTP(
                level: (200...299).contains(statusCode) ? .info : .error,
                method: method, url: urlStr,
                httpStatus: statusCode,
                durationMs: Int(elapsed * 1000),
                detail: responseSnippet)

            let threshold = await ErrorReportStore.shared.slowRequestThreshold
            if elapsed > threshold {
                AppLogger.api.warning(
                    "🐌 Slow request: \(method) \(urlStr) took \(String(format: "%.1f", elapsed))s"
                )
                let responsePreview = String(data: data, encoding: .utf8)
                await ErrorReportStore.shared.addSlowRequest(
                    url: urlStr, method: method, statusCode: statusCode,
                    duration: elapsed, responseBody: responsePreview)
            }

            // Handle 401 — unauthorized
            if statusCode == 401 {
                AppLogger.auth.warning(
                    "🔒 401 Unauthorized — session expired")
                await ErrorReportStore.shared.addError(
                    url: urlStr, method: method, statusCode: statusCode,
                    duration: elapsed, requestBody: bodyStr,
                    errorMessage: "401 Unauthorized — session expired")
                return .failure(.unauthorized)
            }

            // Handle other errors
            guard (200...299).contains(statusCode) else {
                let bodyPreview = String(data: data, encoding: .utf8) ?? "<binary>"
                AppLogger.api.error(
                    "❌ Server error \(statusCode): \(bodyPreview)")
                await ErrorReportStore.shared.addError(
                    url: urlStr, method: method, statusCode: statusCode,
                    duration: elapsed, requestBody: bodyStr,
                    responseBody: bodyPreview,
                    errorMessage: "Server error \(statusCode)")
                return .failure(
                    .server(
                        statusCode: statusCode,
                        message: String(
                            data: data, encoding: .utf8)))
            }

            // Log response preview
            let _ = String(data: data, encoding: .utf8).map { _ in
                AppLogger.api.debug(
                    "📥 Response: \(AppLogger.redactBody(data))")
            }

            // Decode response
            if isClientApi {
                return decodeClientApiResponse(
                    data: data, responseType: responseType)
            } else {
                return decodeWSResponse(
                    data: data, responseType: responseType)
            }
        } catch let error as URLError {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.api.error(
                "❌ \(method) \(urlStr) — Network error [\(String(format: "%.0f", elapsed * 1000))ms]: \(error.localizedDescription)"
            )
            await ErrorReportStore.shared.addError(
                url: urlStr, method: method, statusCode: nil,
                duration: elapsed, requestBody: bodyStr,
                errorMessage: "Network error: \(error.localizedDescription)")
            return .failure(.network(error))
        } catch {
            AppLogger.api.error(
                "❌ \(method) \(urlStr) — Error: \(error.localizedDescription)"
            )
            await ErrorReportStore.shared.addError(
                url: urlStr, method: method, statusCode: nil,
                requestBody: bodyStr,
                errorMessage: error.localizedDescription)
            return .failure(.unknown(error))
        }
    }

    // MARK: - Response decoding

    private func decodeClientApiResponse<T: Decodable>(
        data: Data, responseType: T.Type
    ) -> AppResult<T> {
        do {
            let wrapper = try decoder.decode(
                ClientApiResponse<T>.self, from: data)
            if wrapper.isSuccess {
                if let responseData = wrapper.data {
                    return .success(responseData)
                } else {
                    if T.self == EmptyResponse.self,
                        let empty = EmptyResponse() as? T
                    {
                        return .success(empty)
                    }
                    return .failure(
                        .server(
                            statusCode: 200, message: "No data in response"))
                }
            } else {
                let messages =
                    wrapper.validationMessages?.map {
                        $0.message ?? $0.code ?? "Unknown error"
                    } ?? []
                return .failure(
                    .validation(
                        messages: messages.isEmpty
                            ? [wrapper.message ?? "Request failed"] : messages))
            }
        } catch {
            AppLogger.api.error("🔴 Client.Api decode error: \(error)")
            // Try to decode directly as T (some endpoints return raw data)
            do {
                let result = try decoder.decode(T.self, from: data)
                return .success(result)
            } catch {
                return .failure(.decoding(error))
            }
        }
    }

    private func decodeWSResponse<T: Decodable>(
        data: Data, responseType: T.Type
    ) -> AppResult<T> {
        do {
            let wrapper = try decoder.decode(WSResponse<T>.self, from: data)
            if wrapper.isSuccess != false {
                if let responseData = wrapper.data {
                    return .success(responseData)
                } else if T.self == EmptyResponse.self,
                    let empty = EmptyResponse() as? T
                {
                    return .success(empty)
                }
                let result = try decoder.decode(T.self, from: data)
                return .success(result)
            } else {
                let messages =
                    wrapper.validationMessages?.map {
                        $0.message ?? $0.code ?? "Unknown"
                    } ?? []
                return .failure(
                    .validation(
                        messages: messages.isEmpty
                            ? [wrapper.message ?? "Request failed"] : messages))
            }
        } catch {
            // Fallback: decode T directly (login response etc.)
            do {
                let result = try decoder.decode(T.self, from: data)
                return .success(result)
            } catch let decodingError {
                AppLogger.api.error(
                    "🔴 WS decode error: \(decodingError)")
                return .failure(.decoding(decodingError))
            }
        }
    }
}

// MARK: - Response wrappers

struct ClientApiResponse<T: Decodable>: Decodable {
    let isSuccess: Bool
    let data: T?
    let message: String?
    let validationMessages: [ValidationMessage]?
    let logId: String?
    let statusCode: Int?
}

struct WSResponse<T: Decodable>: Decodable {
    let data: T?
    let message: String?
    let actions: [String]?
    let isSuccess: Bool?
    let validationMessages: [ValidationMessage]?

    enum CodingKeys: String, CodingKey {
        case data = "Data"
        case message = "Message"
        case actions = "Actions"
        case isSuccess = "IsSucccess"  // Note: API has typo with 3 s's
        case isSuccessAlt = "IsSuccess"  // Some endpoints use correct 2-s spelling
        case validationMessages = "ValidationMessages"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent(T.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        actions = try container.decodeIfPresent([String].self, forKey: .actions)
        validationMessages = try container.decodeIfPresent([ValidationMessage].self, forKey: .validationMessages)
        // Handle both spellings: "IsSucccess" (3 s's) and "IsSuccess" (2 s's)
        isSuccess = try container.decodeIfPresent(Bool.self, forKey: .isSuccess)
            ?? container.decodeIfPresent(Bool.self, forKey: .isSuccessAlt)
    }
}

struct ValidationMessage: Decodable {
    let code: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case code = "Code"
        case message = "Message"
        // Also support camelCase from Client.Api
        case codeLower = "code"
        case messageLower = "message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(String.self, forKey: .code)
            ?? container.decodeIfPresent(String.self, forKey: .codeLower)
        message = try container.decodeIfPresent(String.self, forKey: .message)
            ?? container.decodeIfPresent(String.self, forKey: .messageLower)
    }
}

struct EmptyResponse: Decodable {}

// MARK: - safeAPICall helper

func safeAPICall<T>(_ operation: () async -> AppResult<T>) async -> AppResult<T>
{
    return await operation()
}

// MARK: - APIClient idLogin setter

extension APIClient {
    func setIdLogin(_ value: String?) {
        self.idLogin = value
    }
}
