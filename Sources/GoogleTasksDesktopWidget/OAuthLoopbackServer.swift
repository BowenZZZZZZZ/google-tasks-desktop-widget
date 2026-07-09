import Foundation
import Network

final class OAuthLoopbackServer {
    private var listener: NWListener?
    private var continuation: CheckedContinuation<(code: String, state: String?), Error>?
    private var startContinuation: CheckedContinuation<String, Error>?
    private var redirectURI: String?

    func start() async throws -> String {
        let listener = try NWListener(using: .tcp, on: .any)
        self.listener = listener

        listener.newConnectionHandler = { connection in
            connection.start(queue: .main)
            connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, _, error in
                if let error {
                    self.resume(throwing: error)
                    return
                }

                guard
                    let data,
                    let request = String(data: data, encoding: .utf8),
                    let firstLine = request.components(separatedBy: "\r\n").first,
                    let target = firstLine.split(separator: " ").dropFirst().first
                else {
                    self.respond(connection, body: "Invalid OAuth callback request.")
                    self.resume(throwing: OAuthLocalError.invalidRequest)
                    return
                }

                guard let redirectURI = self.redirectURI else {
                    self.respond(connection, body: "OAuth callback server is not ready.")
                    self.resume(throwing: OAuthLocalError.noPort)
                    return
                }

                let components = URLComponents(string: redirectURI + String(target))
                let query = components?.queryItems ?? []
                if let error = query.first(where: { $0.name == "error" })?.value {
                    self.respond(connection, body: "Google sign-in failed: \(error)")
                    self.resume(throwing: OAuthLocalError.oauthError(error))
                    return
                }

                guard let code = query.first(where: { $0.name == "code" })?.value else {
                    self.respond(connection, body: "Missing authorization code.")
                    self.resume(throwing: OAuthLocalError.missingCode)
                    return
                }

                self.respond(connection, body: "Signed in. You can close this browser tab and return to the widget.")
                let state = query.first(where: { $0.name == "state" })?.value
                self.resume(returning: (code, state))
            }
        }

        listener.stateUpdateHandler = { state in
            if case .ready = state {
                guard let port = listener.port?.rawValue, port != 0 else {
                    self.resumeStart(throwing: OAuthLocalError.noPort)
                    return
                }
                let redirectURI = "http://127.0.0.1:\(port)"
                self.redirectURI = redirectURI
                self.resumeStart(returning: redirectURI)
            } else if case let .failed(error) = state {
                self.resumeStart(throwing: error)
                self.resume(throwing: error)
            }
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.startContinuation = continuation
                listener.start(queue: .main)
            }
        } onCancel: {
            self.stop()
        }
    }

    func waitForCode() async throws -> (code: String, state: String?) {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        } onCancel: {
            self.stop()
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        startContinuation = nil
        redirectURI = nil
    }

    private func resumeStart(returning redirectURI: String) {
        startContinuation?.resume(returning: redirectURI)
        startContinuation = nil
    }

    private func resumeStart(throwing error: Error) {
        startContinuation?.resume(throwing: error)
        startContinuation = nil
    }

    private func resume(returning result: (code: String, state: String?)) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    private func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    private func respond(_ connection: NWConnection, body: String) {
        let html = """
        <!doctype html>
        <html><head><meta charset="utf-8"><title>Google Tasks Widget</title></head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 40px;">
        <h2>Google Tasks Desktop Widget</h2>
        <p>\(body)</p>
        </body></html>
        """
        let response = """
        HTTP/1.1 200 OK\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(Data(html.utf8).count)\r
        Connection: close\r
        \r
        \(html)
        """
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
            self.stop()
        })
    }
}

enum OAuthLocalError: LocalizedError {
    case noPort
    case invalidRequest
    case invalidState
    case missingCode
    case oauthError(String)

    var errorDescription: String? {
        switch self {
        case .noPort:
            return "Could not allocate a local OAuth callback port."
        case .invalidRequest:
            return "The OAuth callback request was invalid."
        case .invalidState:
            return "The OAuth callback state did not match the sign-in request."
        case .missingCode:
            return "Google did not return an authorization code."
        case .oauthError(let error):
            return "Google OAuth error: \(error)"
        }
    }
}
