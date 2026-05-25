import Foundation

enum AppResult<T> {
    case success(T)
    case failure(AppError)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var data: T? {
        if case .success(let value) = self { return value }
        return nil
    }

    var error: AppError? {
        if case .failure(let error) = self { return error }
        return nil
    }

    func map<U>(_ transform: (T) -> U) -> AppResult<U> {
        switch self {
        case .success(let value): return .success(transform(value))
        case .failure(let error): return .failure(error)
        }
    }
}

enum AppError: Error, LocalizedError {
    case network(URLError)
    case server(statusCode: Int, message: String?)
    case decoding(Error)
    case unauthorized
    case maintenance
    case unknown(Error)
    case validation(messages: [String])

    var errorDescription: String? {
        switch self {
        case .network(let error): return "Network error: \(error.localizedDescription)"
        case .server(let code, let message): return "Server error \(code): \(message ?? "Unknown")"
        case .decoding(let error): return "Decoding error: \(error.localizedDescription)"
        case .unauthorized: return "Session expired. Please log in again."
        case .maintenance: return "App is under maintenance."
        case .unknown(let error): return "Unexpected error: \(error.localizedDescription)"
        case .validation(let messages): return messages.joined(separator: "\n")
        }
    }
}
