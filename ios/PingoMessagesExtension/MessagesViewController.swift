import Messages
import PingoCore
import SwiftUI

@MainActor
final class MessagesViewController: MSMessagesAppViewController {
    private let model = MessagesExtensionModel()
    private var host: UIHostingController<PingoMessagesRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        installSwiftUIRoot()
    }

    private func installSwiftUIRoot() {
        let root = PingoMessagesRootView(
            model: model,
            onRequestExpanded: { [weak self] in
                self?.requestPresentationStyle(.expanded)
            },
            onChallenge: { [weak self] gameID in
                self?.insertChallenge(gameID: gameID)
            },
            onAccept: { [weak self] in
                self?.acceptSelectedChallenge()
            },
            onResign: { [weak self] in
                self?.resignSelectedMatch()
            }
        )
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        self.host = host
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        model.activate(style: presentationStyle, conversation: conversation)
    }

    override func didResignActive(with conversation: MSConversation) {
        model.deactivate()
        super.didResignActive(with: conversation)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        model.transition(to: presentationStyle)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        model.handle(message: message)
        requestPresentationStyle(.expanded)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        model.handle(message: message)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        super.didStartSending(message, conversation: conversation)
        model.setStatus("Pingo challenge sent")
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        super.didCancelSending(message, conversation: conversation)
        model.setStatus("Send cancelled")
    }

    private func insertChallenge(gameID: PingoGameID) {
        guard let conversation = activeConversation else {
            model.setStatus("Open Pingo inside an iMessage conversation first.")
            return
        }

        do {
            let match = PingoMatchReducer.challenge(gameID: gameID, creator: model.profile)
            let payload = PingoMessagePayload(action: .challenge, sender: model.profile, match: match)
            let message = try PingoMessageFactory.make(payload: payload, session: MSSession())
            conversation.insert(message)
            model.setStatus("Challenge added to the message box — tap Send.")
        } catch {
            model.setStatus("Pingo could not create that challenge.")
        }
    }

    private func acceptSelectedChallenge() {
        guard let conversation = activeConversation,
              let payload = model.incomingPayload,
              payload.match.status == .awaitingOpponent,
              payload.sender.id != model.profile.id
        else {
            model.setStatus("This challenge cannot be accepted.")
            return
        }

        do {
            let match = try PingoMatchReducer.accept(
                payload.match,
                opponent: model.profile,
                expectedRevision: payload.match.revision
            )
            let accepted = PingoMessagePayload(action: .accepted, sender: model.profile, match: match)
            let session = conversation.selectedMessage?.session ?? MSSession()
            let message = try PingoMessageFactory.make(payload: accepted, session: session)
            conversation.insert(message)
            model.incomingPayload = accepted
            model.setStatus("Acceptance added to the message box — tap Send.")
        } catch {
            model.setStatus("This challenge is stale or already accepted.")
        }
    }

    private func resignSelectedMatch() {
        guard let conversation = activeConversation,
              let payload = model.incomingPayload,
              payload.match.status == .active
        else {
            model.setStatus("There is no active Pingo match to resign.")
            return
        }

        do {
            let match = try PingoMatchReducer.resign(
                payload.match,
                actorID: model.profile.id,
                expectedRevision: payload.match.revision
            )
            let resigned = PingoMessagePayload(action: .resigned, sender: model.profile, match: match)
            let session = conversation.selectedMessage?.session ?? MSSession()
            let message = try PingoMessageFactory.make(payload: resigned, session: session)
            conversation.insert(message)
            model.incomingPayload = resigned
            model.setStatus("Resignation added to the message box — tap Send.")
        } catch {
            model.setStatus("Pingo could not resign this match.")
        }
    }
}
