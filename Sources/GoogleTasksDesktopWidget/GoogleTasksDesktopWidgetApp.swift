import SwiftUI

@main
struct GoogleTasksDesktopWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView(state: state)
                .background(WindowConfigurator())
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        .terminateNow
    }
}

enum WindowController {
    @MainActor
    static func showWidget() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !$0.isSheet }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
            window.title = "Google Tasks Desktop"
            window.level = .normal
            window.collectionBehavior = [.managed, .fullScreenAuxiliary]
            window.backgroundColor = .windowBackgroundColor
            window.isOpaque = true
            window.hasShadow = true
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
