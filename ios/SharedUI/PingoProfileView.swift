import PingoCore
import SwiftUI

struct PingoProfileView: View {
    let profile: PingoPublicProfile
    @Binding var progression: PingoProgressionState
    let onSave: (String, PingoAvatar) throws -> Void
    let onEquip: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var avatarKind: PingoAvatarKind
    @State private var avatarValue: String
    @State private var avatarBackground: String
    @State private var validationMessage: String?

    private let presets = ["ping", "orbit", "bolt", "star", "rocket", "smile", "trophy", "wave"]
    private let backgrounds = ["mint", "blue", "purple", "orange", "pink", "slate"]

    init(
        profile: PingoPublicProfile,
        progression: Binding<PingoProgressionState>,
        onSave: @escaping (String, PingoAvatar) throws -> Void,
        onEquip: @escaping (String) throws -> Void
    ) {
        self.profile = profile
        _progression = progression
        self.onSave = onSave
        self.onEquip = onEquip
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(username.isEmpty ? "username" : username)")
                                .font(.headline)
                            Text("Level \(progression.level) • \(progression.xp) XP")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.pingoPrimary)
                            ProgressView(
                                value: Double(progression.xpIntoLevel),
                                total: Double(PingoProgression.xpPerLevel)
                            )
                            .tint(.pingoPrimary)
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

                Section("Competitive Stats") {
                    HStack {
                        stat("Wins", progression.wins)
                        Spacer()
                        stat("Losses", progression.losses)
                        Spacer()
                        stat("Draws", progression.draws)
                        Spacer()
                        stat("Streak", progression.currentStreak)
                    }
                    if progression.bestStreak > 0 {
                        LabeledContent("Best streak", value: "\(progression.bestStreak)")
                    }
                }

                Section("Achievements") {
                    if progression.achievements.isEmpty {
                        Text("Play matches to unlock achievements.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(progression.achievements.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { achievement in
                            Label(achievement.title, icon: achievement.symbol)
                        }
                    }
                }

                Section("Locker") {
                    ForEach(PingoCosmeticSlot.allCases, id: \.self) { slot in
                        let cosmetics = ownedCosmetics(for: slot)
                        if !cosmetics.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(slotTitle(slot))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(cosmetics) { cosmetic in
                                            Button {
                                                equip(cosmetic)
                                            } label: {
                                                VStack(spacing: 4) {
                                                    Text(cosmetic.symbol).font(.title2)
                                                    Text(cosmetic.name)
                                                        .font(.caption2)
                                                        .lineLimit(1)
                                                    if progression.equippedCosmetics[slot] == cosmetic.id {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.caption)
                                                            .foregroundStyle(Color.pingoPrimary)
                                                    }
                                                }
                                                .frame(width: 86, minHeight: 72)
                                                .padding(6)
                                                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Recent Matches") {
                    if progression.history.isEmpty {
                        Text("Your match history will appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(progression.history.prefix(6))) { entry in
                            HStack {
                                Text(PingoGameCatalog.game(id: entry.gameID)?.symbol ?? "🎮")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(PingoGameCatalog.game(id: entry.gameID)?.name ?? "Pingo")
                                        .font(.subheadline.weight(.semibold))
                                    Text("vs @\(entry.opponentName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(entry.result.rawValue.capitalized)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(entry.result == .win ? Color.pingoPrimary : .secondary)
                            }
                        }
                    }
                }

                Section("Friend Records") {
                    if progression.opponentRecords.isEmpty {
                        Text("Friend-specific records appear after you finish matches.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(progression.opponentRecords.prefix(6)), id: \.opponentID) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("@\(opponentName(for: record.opponentID))")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Best streak \(record.bestStreak)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(record.wins)-\(record.losses)-\(record.draws)")
                                    .font(.subheadline.monospacedDigit())
                            }
                        }
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
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func ownedCosmetics(for slot: PingoCosmeticSlot) -> [PingoCosmeticDescriptor] {
        PingoCosmeticCatalog.all.filter { $0.slot == slot && progression.ownedCosmetics.contains($0.id) }
    }

    private func equip(_ cosmetic: PingoCosmeticDescriptor) {
        do {
            try onEquip(cosmetic.id)
            validationMessage = nil
        } catch {
            validationMessage = "Pingo could not equip that cosmetic."
        }
    }

    private func opponentName(for id: UUID) -> String {
        progression.history.first(where: { $0.opponentID == id })?.opponentName ?? "friend"
    }

    private func slotTitle(_ slot: PingoCosmeticSlot) -> String {
        switch slot {
        case .avatar: "Avatar Cosmetics"
        case .theme: "Themes"
        case .cue: "Pool Cues"
        case .darts: "Darts"
        case .golfBall: "Golf Balls"
        case .cup: "Cup Pong"
        case .basketball: "Basketballs"
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

private extension Label where Title == Text, Icon == Text {
    init(_ title: String, icon: String) {
        self.init {
            Text(title)
        } icon: {
            Text(icon)
        }
    }
}
