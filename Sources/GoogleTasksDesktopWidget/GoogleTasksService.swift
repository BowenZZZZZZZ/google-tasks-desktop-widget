import AppKit
import CryptoKit
import Foundation

final class GoogleTasksService {
    private let session: URLSession
    private let scope = "https://www.googleapis.com/auth/tasks.readonly"
    private var accessToken: String?
    private var accessTokenExpiry: Date?
    private var loopbackServer: OAuthLoopbackServer?

    init(session: URLSession = .shared) {
        self.session = session
    }

    var hasRefreshToken: Bool {
        KeychainStore.loadRefreshToken() != nil
    }

    func signOut() {
        accessToken = nil
        accessTokenExpiry = nil
        KeychainStore.deleteRefreshToken()
    }

    func signIn(clientID: String, clientSecret: String) async throws {
        let verifier = Self.makeCodeVerifier()
        let challenge = Self.makeCodeChallenge(verifier)
        let state = Self.makeCodeVerifier(length: 32)
        let server = OAuthLoopbackServer()
        loopbackServer = server

        let redirectURI = try await server.start()
        openAuthURL(
            clientID: clientID,
            redirectURI: redirectURI,
            challenge: challenge,
            state: state
        )

        let callback = try await server.waitForCode()
        guard callback.state == state else {
            throw OAuthLocalError.invalidState
        }

        let token = try await exchangeCode(
            code: callback.code,
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            verifier: verifier
        )
        accessToken = token.accessToken
        accessTokenExpiry = Date().addingTimeInterval(TimeInterval(token.expiresIn ?? 3600))
        if let refreshToken = token.refreshToken {
            try KeychainStore.saveRefreshToken(refreshToken)
        }
    }

    func fetchDesktopTasks(clientID: String, clientSecret: String, listName: String = "Desktop") async throws -> [GoogleTask] {
        let token = try await validAccessToken(clientID: clientID, clientSecret: clientSecret)
        let lists = try await request(
            URL(string: "https://tasks.googleapis.com/tasks/v1/users/@me/lists")!,
            token: token,
            as: TaskListResponse.self
        ).items ?? []

        guard let desktop = lists.first(where: { $0.title.caseInsensitiveCompare(listName) == .orderedSame }) else {
            throw TasksError.listNotFound(listName)
        }

        var components = URLComponents(string: "https://tasks.googleapis.com/tasks/v1/lists/\(desktop.id)/tasks")!
        components.queryItems = [
            URLQueryItem(name: "showCompleted", value: "false"),
            URLQueryItem(name: "showHidden", value: "false"),
            URLQueryItem(name: "maxResults", value: "100")
        ]

        let tasks = try await request(components.url!, token: token, as: TasksResponse.self).items ?? []
        return tasks.filter { $0.status != "completed" }
    }

    private func validAccessToken(clientID: String, clientSecret: String) async throws -> String {
        if let accessToken, let accessTokenExpiry, accessTokenExpiry > Date().addingTimeInterval(60) {
            return accessToken
        }

        guard let refreshToken = KeychainStore.loadRefreshToken() else {
            throw TasksError.notSignedIn
        }

        let token = try await refreshAccessToken(clientID: clientID, clientSecret: clientSecret, refreshToken: refreshToken)
        accessToken = token.accessToken
        accessTokenExpiry = Date().addingTimeInterval(TimeInterval(token.expiresIn ?? 3600))
        return token.accessToken
    }

    private func openAuthURL(
        clientID: String,
        redirectURI: String,
        challenge: String,
        state: String
    ) {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    private func exchangeCode(
        code: String,
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        verifier: String
    ) async throws -> TokenResponse {
        try await tokenRequest(parameters: [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI
        ])
    }

    private func refreshAccessToken(clientID: String, clientSecret: String, refreshToken: String) async throws -> TokenResponse {
        try await tokenRequest(parameters: [
            "client_id": clientID,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ])
    }

    private func tokenRequest(parameters: [String: String]) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formURLEncoded(parameters).data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if let oauthError = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
                throw TasksError.api("\(oauthError.error): \(oauthError.errorDescription ?? "No details")")
            }
            throw TasksError.api("Token endpoint returned HTTP \(http.statusCode)")
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func request<T: Decodable>(_ url: URL, token: String, as type: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw TasksError.api("Google Tasks returned HTTP \(http.statusCode)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func makeCodeVerifier(length: Int = 64) -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return String(bytes.map { alphabet[Int($0) % alphabet.count] })
    }

    private static func makeCodeChallenge(_ verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func formURLEncoded(_ parameters: [String: String]) -> String {
        parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key.urlQueryEscaped)=\($0.value.urlQueryEscaped)" }
            .joined(separator: "&")
    }
}

enum TasksError: LocalizedError {
    case notSignedIn
    case listNotFound(String)
    case api(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Sign in before refreshing tasks."
        case .listNotFound(let name):
            return "No Google Tasks list named \(name) was found."
        case .api(let message):
            return message
        }
    }
}

private extension String {
    var urlQueryEscaped: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
