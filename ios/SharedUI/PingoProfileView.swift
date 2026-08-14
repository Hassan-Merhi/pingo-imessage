import PingoCore
import SwiftUI

struct PingoProfileView: View {
    let profile: PingoPublicProfile
    let onSave: (String, PingoAvatar) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var avatarKind: PingoAvatarKind
    @State private var avatarValue: String
    @State private var avatarBackground: String
    @State private var validationMessage: String?

    private let presets = ["ping", "orbit", "bolt", "star", "rocket", "smile", "trophy", "wave"]
    private let backgrounds = ["mint", "blue", "purple", "orange", "pink", "slate"]

    init(profile: PingoPublicProfile, onSave: @escaping (String, PingoAvatar) throws -> Void) {
        self.profile = profile
        self.onSave = onSave
        _username = State(initialValue: profile.username)
        _avatarKind = State(initialValue: profile.avatar.kind)
        _avatarValue = State(initialValue: profile.avatar.value)
        _avatarBackground = State(initialValue: profile.avatar.background)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack(spacing: 14) {
                        avatarPreview
                        VStack(alignment: .leading) {
                            Text("@\(username.isEmpty ? "username" : username)")
                                .font(.headline)
                            Text("Pingo player")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    TextField("Pingo username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Avatar") {
                    Picker("Avatar type", selection: $avatarKind) {
                        Text("Pingo").tag(PingoAvatarKind.preset)
                        Text("Emoji").tag(PingoAvatarKind.emoji)
                    }
                    .pickerStyle(.segmented)

                    if avatarKind == .preset {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 54))], spacing: 10) {
                            ForEach(presets, id: \.self) { preset in
                                Button {
                                    avatarValue = preset
                                } label: {
                                    Text(symbol(for: preset))
                                        .font(.title2)
                                        .frame(width: 48, height: 48)
                                        .background(avatarValue == preset ? Color.pingoPrimary.opacity(0.18) : Color.secondary.opacity(0.08), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(preset)
                            }
                        }
                    } else {
                        TextField("Emoji", text: $avatarValue)
                    }

                    Picker("Background", selection: $avatarBackground) {
                        ForEach(backgrounds, id: \.self) { background in
                            Text(background.capitalized).tag(background)
                        }
                    }
                }

                Section("Stats") {
                    HStack {
                        stat("Wins", profile.stats.wins)
                        Spacer()
                        stat("Losses", profile.stats.losses)
                        Spacer()
                        stat("Streak", profile.stats.currentStreak)
                    }
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Pingo Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private var avatarPreview: some View {
        Text(avatarKind == .emoji ? String(avatarValue.prefix(4)) : symbol(for: avatarValue))
            .font(.system(size: 30))
            .frame(width: 58, height: 58)
            .background(Color.pingoPrimary.opacity(0.14), in: Circle())
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 3) {
            Text("\(value)").font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func save() {
        do {
            let avatar = PingoAvatar(kind: avatarKind, value: avatarValue, background: avatarBackground)
            try onSave(username, avatar)
            validationMessage = nil
            dismiss()
        } catch PingoUsernameValidationError.tooShort {
            validationMessage = "Username must be at least 3 characters."
        } catch PingoUsernameValidationError.tooLong {
            validationMessage = "Username can be at most 20 characters."
        } catch PingoUsernameValidationError.invalidCharacters {
            validationMessage = "Use only letters, numbers, and underscores."
        } catch PingoUsernameValidationError.reserved {
            validationMessage = "That username is reserved."
        } catch {
            validationMessage = "Pingo could not save that profile."
        }
    }

    private func symbol(for preset: String) -> String {
        switch preset {
        case "orbit": return "🪐"
        case "bolt": return "⚡️"
        case "star": return "⭐️"
        case "rocket": return "🚀"
        case "smile": return "🙂"
        case "trophy": return "🏆"
        case "wave": return "🌊"
        default: return "🎮"
        }
    }
}
