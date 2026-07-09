import AppKit
import Darwin
import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var tasks: [GoogleTask] = []
    @Published var clientID: String = UserDefaults.standard.string(forKey: "clientID") ?? ""
    @Published var clientSecret: String = UserDefaults.standard.string(forKey: "clientSecret") ?? ""
    @Published var refreshHours: Int = UserDefaults.standard.object(forKey: "refreshHours") == nil ? 2 : UserDefaults.standard.integer(forKey: "refreshHours")
    @Published var isRefreshing = false
    @Published var isSigningIn = false
    @Published var lastRefreshed: Date?
    @Published var statusMessage = "Add your Google OAuth client ID, then sign in."
    @Published var showSettings = false

    private let service = GoogleTasksService()
    private var refreshTask: Task<Void, Never>?

    var isSignedIn: Bool {
        service.hasRefreshToken
    }

    init() {
        if isSignedIn {
            statusMessage = "Ready to refresh."
        }
        scheduleAutoRefresh()
    }

    func saveSettings() {
        UserDefaults.standard.set(clientID.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "clientID")
        UserDefaults.standard.set(clientSecret.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "clientSecret")
        UserDefaults.standard.set(refreshHours, forKey: "refreshHours")
        scheduleAutoRefresh()
    }

    func signIn() {
        let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientID.isEmpty else {
            statusMessage = "Paste a Google OAuth Desktop client ID first."
            showSettings = true
            return
        }
        guard !trimmedClientSecret.isEmpty else {
            statusMessage = "Paste the OAuth Desktop client secret first."
            showSettings = true
            return
        }

        saveSettings()
        isSigningIn = true
        statusMessage = "Opening Google sign-in..."

        Task {
            do {
                try await service.signIn(clientID: trimmedClientID, clientSecret: trimmedClientSecret)
                statusMessage = "Signed in."
                await refresh()
            } catch {
                statusMessage = error.localizedDescription
            }
            isSigningIn = false
            objectWillChange.send()
        }
    }

    func signOut() {
        service.signOut()
        tasks = []
        lastRefreshed = nil
        statusMessage = "Signed out."
        objectWillChange.send()
    }

    func refresh() async {
        let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientID.isEmpty else {
            statusMessage = "Paste a Google OAuth Desktop client ID first."
            showSettings = true
            return
        }
        guard !trimmedClientSecret.isEmpty else {
            statusMessage = "Paste the OAuth Desktop client secret first."
            showSettings = true
            return
        }

        guard service.hasRefreshToken else {
            statusMessage = "Sign in before refreshing."
            return
        }

        isRefreshing = true
        statusMessage = "Refreshing..."
        do {
            let fetched = try await service.fetchDesktopTasks(clientID: trimmedClientID, clientSecret: trimmedClientSecret)
            tasks = fetched
            lastRefreshed = Date()
            statusMessage = fetched.isEmpty ? "No open Desktop tasks." : "\(fetched.count) open task\(fetched.count == 1 ? "" : "s")."
        } catch {
            statusMessage = error.localizedDescription
        }
        isRefreshing = false
    }

    func openGoogleTasks() {
        NSWorkspace.shared.open(URL(string: "https://tasks.google.com/")!)
    }

    func quitApp() {
        NSApp.terminate(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            exit(0)
        }
    }

    func scheduleAutoRefresh() {
        refreshTask?.cancel()
        guard refreshHours > 0 else { return }
        refreshTask = Task { [weak self] in
            guard let self else { return }
            let interval = UInt64(refreshHours) * 60 * 60 * 1_000_000_000
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                if Task.isCancelled { break }
                await self.refresh()
            }
        }
    }
}
