import Foundation
import Messages
import PingoCore

@MainActor
final class MessagesExtensionModel: ObservableObject {
    @Published var presentationStyle: MSMessagesAppPresentationStyle = .compact
    @Published var isConversationActive = false
    @Published var profile: PingoPublicProfile
    @Published var incomingPayload: PingoMessagePayload?
    @Published var statusMessage: String?
    @Published var isProfilePresented = false
    @Published var remoteParticipantCount = 0

    private let identityStore: PingoIdentityStore
    private let apiClient: PingoAPIClient
    private var isSyncingProfile = false

    init() {
        let store = PingoIdentityStore()
        identityStore = store
        apiClient = PingoAPIClient()
        profile = store.loadOrCreateProfile()
    }

    func activate(style: MSMessagesAppPresentationStyle, conversation: MSConversation) {
        presentationStyle = style
        isConversationActive = true
        remoteParticipantCount = conversation.remoteParticipantIdentifiers.count
        if let selected = conversation.selectedMessage {
            handle(message: selected)
        }
        syncBackendIfConfigured()
    }

    func handle(message: MSMessage) {
        guard let url = message.url else { return }
        do {
            incomingPayload = try PingoMessageTransport.decode(url: url)
            statusMessage = nil
        } catch {
            statusMessage = "This Pingo message could not be opened."
        }
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
            stats: profile.stats,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
        profile = updated
        identityStore.save(profile: updated)
        statusMessage = "Profile saved"
        syncBackendIfConfigured()
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

    private func syncBackendIfConfigured() {
        guard PingoConfiguration.backendEnabled, !isSyncingProfile else { return }
        isSyncingProfile = true
        let localProfile = profile
        let token = identityStore.loadAccessToken()

        Task { [weak self] in
            guard let self else { return }
            defer { self.isSyncingProfile = false }
            do {
                if let token {
                    let remote = try await self.apiClient.updateProfile(localProfile, token: token)
                    self.profile = remote
                    self.identityStore.save(profile: remote)
                } else {
                    let bootstrap = try await self.apiClient.bootstrap(profile: localProfile)
                    self.identityStore.saveAccessToken(bootstrap.accessToken)
                    self.profile = bootstrap.profile
                    self.identityStore.save(profile: bootstrap.profile)
                }
            } catch {
                self.statusMessage = "Profile saved on this device. Online sync will retry later."
            }
        }
    }
}
