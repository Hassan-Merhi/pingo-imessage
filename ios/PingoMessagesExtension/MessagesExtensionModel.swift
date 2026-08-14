import Foundation
import Messages
import PingoCore

@MainActor
final class MessagesExtensionModel: ObservableObject {
    @Published var presentationStyle: MSMessagesAppPresentationStyle = .compact
    @Published var isConversationActive = false
    @Published var profile: PingoPublicProfile
    @Published var progression: PingoProgressionState
    @Published var incomingPayload: PingoMessagePayload?
    @Published var statusMessage: String?
    @Published var isProfilePresented = false
    @Published var isStorePresented = false
    @Published var remoteParticipantCount = 0

    let storeManager = PingoStoreManager()

    private let identityStore: PingoIdentityStore
    private let progressionStore: PingoProgressionStore
    private let apiClient: PingoAPIClient
    private var isSyncingProfile = false
    private var isSyncingProgression = false

    init() {
        let identity = PingoIdentityStore()
        let progressionStore = PingoProgressionStore()
        identityStore = identity
        self.progressionStore = progressionStore
        apiClient = PingoAPIClient()

        let storedProfile = identity.loadOrCreateProfile()
        profile = storedProfile
        var storedProgression = progressionStore.load()
        if storedProgression.gamesPlayed == 0, storedProfile.stats.gamesPlayed > 0 {
            storedProgression.wins = storedProfile.stats.wins
            storedProgression.losses = storedProfile.stats.losses
            storedProgression.draws = storedProfile.stats.draws
            storedProgression.currentStreak = storedProfile.stats.currentStreak
            storedProgression.bestStreak = storedProfile.stats.bestStreak
        }
        progression = storedProgression
        mirrorProgressionStatsIntoProfile()
    }

    func activate(style: MSMessagesAppPresentationStyle, conversation: MSConversation) {
        presentationStyle = style
        isConversationActive = true
        remoteParticipantCount = conversation.remoteParticipantIdentifiers.count
        if let selected = conversation.selectedMessage {
            handle(message: selected)
        }
        syncBackendIfConfigured()
        refreshStoreEntitlements()
    }

    func handle(message: MSMessage) {
        guard let url = message.url else { return }
        do {
            let payload = try PingoMessageTransport.decode(url: url)
            incomingPayload = payload
            statusMessage = nil
            recordResultIfNeeded(match: payload.match)
        } catch {
            statusMessage = "This Pingo message could not be opened."
        }
    }

    func recordSentResult(from message: MSMessage) {
        guard let url = message.url,
              let payload = try? PingoMessageTransport.decode(url: url) else { return }
        recordResultIfNeeded(match: payload.match)
    }

    func clearIncomingMatch() {
        incomingPayload = nil
        statusMessage = nil
    }

    func updateProfile(username: String, avatar: PingoAvatar) throws {
        let canonical = try PingoProfileValidator.canonicalUsername(username)
        let validatedAvatar = PingoProfileValidator.validatedAvatar(avatar)
        let updated = PingoPublicProfile(
            id: profile.id,
            username: canonical,
            avatar: validatedAvatar,
            stats: progressionStats,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
        profile = updated
        identityStore.save(profile: updated)
        statusMessage = "Profile saved"
        syncBackendIfConfigured()
    }

    func canPlay(_ gameID: PingoGameID) -> Bool {
        PingoAccessPolicy.canPlay(gameID, entitlements: progression.entitlements)
    }

    func showStore() {
        isStorePresented = true
    }

    func applyVerifiedStoreEntitlements(_ entitlements: Set<PingoEntitlementID>) {
        let next = PingoProgression.replacingStoreEntitlements(entitlements, in: progression)
        saveProgression(next, syncCloud: false)
    }

    func equip(cosmeticID: String) throws {
        let next = try PingoProgression.equip(cosmeticID: cosmeticID, in: progression)
        saveProgression(next, syncCloud: false)
    }

    func setStatus(_ message: String?) {
        statusMessage = message
    }

    func transition(to style: MSMessagesAppPresentationStyle) {
        presentationStyle = style
    }

    func deactivate() {
        isConversationActive = false
    }

    private var progressionStats: PingoStats {
        PingoStats(
            wins: progression.wins,
            losses: progression.losses,
            draws: progression.draws,
            currentStreak: progression.currentStreak,
            bestStreak: progression.bestStreak
        )
    }

    private func recordResultIfNeeded(match: PingoMatchEnvelope) {
        guard match.status == .completed || match.status == .resigned,
              match.players.contains(where: { $0.id == profile.id }) else { return }
        do {
            let next = try PingoProgression.applyingResult(from: match, localPlayerID: profile.id, to: progression)
            guard !next.processedMatchIDs.symmetricDifference(progression.processedMatchIDs).isEmpty else { return }
            saveProgression(next, syncCloud: true)
        } catch {
            return
        }
    }

    private func saveProgression(_ state: PingoProgressionState, syncCloud: Bool) {
        progression = state
        progressionStore.save(state)
        mirrorProgressionStatsIntoProfile()
        if syncCloud { syncProgressionIfConfigured() }
    }

    private func mirrorProgressionStatsIntoProfile() {
        let updated = PingoPublicProfile(
            id: profile.id,
            username: profile.username,
            avatar: profile.avatar,
            stats: progressionStats,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
        profile = updated
        identityStore.save(profile: updated)
    }

    private func refreshStoreEntitlements() {
        Task { [weak self] in
            guard let self else { return }
            let entitlements = await self.storeManager.currentEntitlements()
            self.applyVerifiedStoreEntitlements(entitlements)
        }
    }

    private func syncBackendIfConfigured() {
        guard PingoConfiguration.backendEnabled, !isSyncingProfile else { return }
        isSyncingProfile = true
        let localProfile = profile
        let existingToken = identityStore.loadAccessToken()

        Task { [weak self] in
            guard let self else { return }
            defer { self.isSyncingProfile = false }
            do {
                let token: String
                if let existingToken {
                    let remote = try await self.apiClient.updateProfile(localProfile, token: existingToken)
                    self.profile = remote
                    token = existingToken
                } else {
                    let bootstrap = try await self.apiClient.bootstrap(profile: localProfile)
                    self.identityStore.saveAccessToken(bootstrap.accessToken)
                    self.profile = bootstrap.profile
                    token = bootstrap.accessToken
                }
                self.mirrorProgressionStatsIntoProfile()
                await self.syncProgression(using: token)
            } catch {
                self.statusMessage = "Profile saved on this device. Online sync will retry later."
            }
        }
    }

    private func syncProgressionIfConfigured() {
        guard PingoConfiguration.backendEnabled,
              let token = identityStore.loadAccessToken(),
              !isSyncingProgression else { return }
        Task { [weak self] in
            guard let self else { return }
            await self.syncProgression(using: token)
        }
    }

    private func syncProgression(using token: String) async {
        guard !isSyncingProgression else { return }
        isSyncingProgression = true
        defer { isSyncingProgression = false }
        do {
            if let remote = try await apiClient.loadProgression(token: token) {
                let merged = PingoProgression.merging(local: progression, remote: remote)
                saveProgression(merged, syncCloud: false)
            }
            _ = try await apiClient.saveProgression(progression.snapshot(), token: token)
        } catch {
            // Progression remains durable on-device and retries on the next activation/change.
        }
    }
}
