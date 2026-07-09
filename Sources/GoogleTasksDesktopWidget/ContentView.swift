import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState

    init(state: AppState) {
        self.state = state
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            taskList
            footer
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .frame(width: 360)
        .background(widgetBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 12)
        .padding(14)
        .sheet(isPresented: $state.showSettings) {
            SettingsView(state: state)
        }
        .task {
            if state.isSignedIn {
                await state.refresh()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Desktop")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.86))

            Spacer()

            Button {
                state.showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.055), in: Circle())
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if state.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(state.isSignedIn ? "No open tasks" : "Not signed in")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text(state.isSignedIn ? "Your Desktop list is clear." : "Connect Google Tasks to show your Desktop list here.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 26)
            } else {
                ForEach(state.tasks.prefix(6)) { task in
                    HStack(alignment: .top, spacing: 18) {
                        Circle()
                            .stroke(Color.secondary.opacity(0.75), lineWidth: 2.6)
                            .frame(width: 26, height: 26)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary.opacity(0.84))
                                .lineLimit(2)
                            if let due = task.due, !due.isEmpty {
                                Text(formatDueDate(due))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if state.tasks.count > 6 {
                    Text("+ \(state.tasks.count - 6) more")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 44)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            HStack(spacing: 10) {
                Button {
                    Task { await state.refresh() }
                } label: {
                    Label(state.isRefreshing ? "Refreshing" : "Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(WidgetButtonStyle())
                .disabled(state.isRefreshing || !state.isSignedIn)

                Button {
                    state.openGoogleTasks()
                } label: {
                    Label("Manage", systemImage: "safari")
                }
                .buttonStyle(WidgetButtonStyle())

                Spacer()

                if state.isSigningIn {
                    ProgressView()
                        .scaleEffect(0.75)
                } else if !state.isSignedIn {
                    Button("Sign in") {
                        state.signIn()
                    }
                    .buttonStyle(WidgetButtonStyle())
                }
            }

            HStack {
                Text(state.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                if let lastRefreshed = state.lastRefreshed {
                    Text(lastRefreshed, style: .time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var widgetBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.28))
            )
    }

    private func formatDueDate(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else { return value }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

struct WidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.primary.opacity(configuration.isPressed ? 0.55 : 0.75))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.black.opacity(configuration.isPressed ? 0.12 : 0.075), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SettingsView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.title2)

            VStack(alignment: .leading, spacing: 8) {
                Text("Google OAuth Desktop Client ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("1234567890-abc.apps.googleusercontent.com", text: $state.clientID)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Google OAuth Desktop Client Secret")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Paste client secret", text: $state.clientSecret)
                    .textFieldStyle(.roundedBorder)
            }

            Picker("Auto refresh", selection: $state.refreshHours) {
                Text("Off").tag(0)
                Text("Every 1 hour").tag(1)
                Text("Every 2 hours").tag(2)
                Text("Every 4 hours").tag(4)
                Text("Every 8 hours").tag(8)
                Text("Every 12 hours").tag(12)
            }
            .pickerStyle(.menu)

            HStack {
                if state.isSignedIn {
                    Button("Sign out", role: .destructive) {
                        state.signOut()
                    }
                }

                Button("Quit App") {
                    state.quitApp()
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    state.saveSettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
