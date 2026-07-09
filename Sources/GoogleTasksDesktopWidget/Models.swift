import Foundation

struct TaskListResponse: Decodable {
    let items: [GoogleTaskList]?
}

struct GoogleTaskList: Decodable, Identifiable {
    let id: String
    let title: String
}

struct TasksResponse: Decodable {
    let items: [GoogleTask]?
}

struct GoogleTask: Decodable, Identifiable {
    let id: String
    let title: String
    let notes: String?
    let due: String?
    let status: String?
    let updated: String?
}

struct TokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int?
    let refreshToken: String?
    let scope: String?
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
    }
}

struct OAuthErrorResponse: Decodable {
    let error: String
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}
