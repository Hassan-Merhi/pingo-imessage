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
            onRequestExpanded: { [weak self] in self?.requestPresentationStyle(.expanded) },
            onChallenge: { [weak self] gameID, format in
                self?.insertChallenge(gameID: gameID, seriesFormat: format)
            },
            onAccept: { [weak self] in self?.acceptSelectedChallenge() },
            onMoves: { [weak self] moves in self?.submitGameMoves(moves) },
            onPhysicsMove: { [weak self] move in self?.submitPhysicsMove(move) },
            onExtraMove: { [weak self] move in self?.submitExtraMove(move) },
            onContinueSeries: { [weak self] in self?.continueSelectedSeries() },
            onResign: { [weak self] in self?.resignSelectedMatch() }
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
        model.recordSentResult(from: message)
        model.setStatus("Pingo message sent")
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        super.didCancelSending(message, conversation: conversation)
        model.setStatus("Send cancelled")
    }

    private func insertChallenge(gameID: PingoGameID, seriesFormat: PingoSeriesFormat) {
        guard let conversation = activeConversation else {
            model.setStatus("Open Pingo inside an iMessage conversation first.")
            return
        }
        guard isSupportedGame(gameID) else {
            model.setStatus("That Pingo game is not playable in this build.")
            return
        }
        guard model.canPlay(gameID) else {
            model.showStore()
            model.setStatus(lockedPackMessage(for: gameID, action: "challenge someone to that game"))
            return
        }

        do {
            let match = PingoMatchReducer.challenge(
                gameID: gameID,
                creator: model.profile,
                seriesFormat: seriesFormat
            )
            let payload = PingoMessagePayload(action: .challenge, sender: model.profile, match: match)
            let message = try PingoMessageFactory.make(payload: payload, session: MSSession())
            conversation.insert(message)
            let label = seriesFormat == .single ? "Challenge" : seriesFormat.title
            model.setStatus("\(label) added to the message box — tap Send.")
        } catch {
            model.setStatus("Pingo could not create that challenge.")
        }
    }

    private func acceptSelectedChallenge() {
        guard let conversation = activeConversation,
              let payload = model.incomingPayload,
              payload.match.status == .awaitingOpponent,
              payload.sender.id != model.profile.id else {
            model.setStatus("This challenge cannot be accepted.")
            return
        }
        guard isSupportedGame(payload.match.gameID) else {
            model.setStatus("That Pingo game is not playable in this build.")
            return
        }
        guard model.canPlay(payload.match.gameID) else {
            model.showStore()
            model.setStatus(lockedPackMessage(for: payload.match.gameID, action: "accept this challenge"))
            return
        }

        do {
            var match = try PingoMatchReducer.accept(
                payload.match,
                opponent: model.profile,
                expectedRevision: payload.match.revision
            )
            // Legacy physics challenges from pre-Wave-6 cards may still arrive without state.
            if match.gameState.isEmpty, PingoPhysicsGameEngine.supportedGames.contains(match.gameID) {
                let initial = PingoPhysicsGameEngine.initialStateData(for: match.gameID)
                match = replacingGameState(in: match, with: initial)
            }
            // Defensive support for early Wave-6 challenge cards created before reducer initialization.
            if match.gameState.isEmpty, PingoExtraGameEngine.supportedGames.contains(match.gameID) {
                let initial = PingoExtraGameEngine.initialStateData(for: match.gameID, matchID: match.id)
                match = replacingGameState(in: match, with: initial)
            }
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

    private func submitGameMoves(_ moves: [PingoGameMove]) {
        guard !moves.isEmpty,
              let conversation = activeConversation,
              let payload = model.incomingPayload,
              payload.match.status == .active,
              payload.match.currentPlayerID == model.profile.id else {
            model.setStatus("It is not your turn in this match.")
            return
        }
        guard model.canPlay(payload.match.gameID) else {
            model.showStore()
            model.setStatus(lockedPackMessage(for: payload.match.gameID, action: "continue this match"))
            return
        }

        do {
            var match = payload.match
            for move in moves {
                if case .seaBattleLockFleet(let fleet) = move {
                    try PingoSeaBattlePrivateStore.shared.save(fleet, matchID: match.id)
                }
                match = try PingoBoardGameEngine.submit(
                    move: move,
                    to: match,
                    actorID: model.profile.id,
                    expectedRevision: match.revision
                )
                if match.status != .active { break }
            }
            try insertUpdatedMatch(match, conversation: conversation)
        } catch PingoMatchTransitionError.staleRevision {
            model.setStatus("That match changed. Open the newest Pingo message and try again.")
        } catch PingoMatchTransitionError.notActorsTurn {
            model.setStatus("It is not your turn yet.")
        } catch PingoGameRuleError.invalidMove {
            model.setStatus("That move is not legal.")
        } catch PingoGameRuleError.captureRequired {
            model.setStatus("A capture is available and must be played.")
        } catch PingoGameRuleError.fleetNotReady {
            model.setStatus("Finish placing all five ships before locking your fleet.")
        } catch PingoGameRuleError.pendingShotRequired {
            model.setStatus("Open the newest Sea Battle card before taking your shot.")
        } catch {
            model.setStatus("Pingo could not apply that move.")
        }
    }

    private func submitPhysicsMove(_ move: PingoPhysicsMove) {
        guard let conversation = activeConversation,
              let payload = model.incomingPayload,
              payload.match.status == .active,
              payload.match.currentPlayerID == model.profile.id,
              PingoPhysicsGameEngine.supportedGames.contains(payload.match.gameID) else {
            model.setStatus("It is not your turn in this match.")
            return
        }
        guard model.canPlay(payload.match.gameID) else {
            model.showStore()
            model.setStatus(lockedPackMessage(for: payload.match.gameID, action: "continue this match"))
            return
        }

        do {
            let match = try PingoPhysicsGameEngine.submit(
                move: move,
                to: payload.match,
                actorID: model.profile.id,
                expectedRevision: payload.match.revision
            )
            try insertUpdatedMatch(match, conversation: conversation)
        } catch PingoMatchTransitionError.staleRevision {
            model.setStatus("That match changed. Open the newest Pingo message and try again.")
        } catch PingoMatchTransitionError.notActorsTurn {
            model.setStatus("It is not your turn yet.")
        } catch PingoGameRuleError.invalidMove {
            model.setStatus("Adjust the shot and try again.")
        } catch {
            model.setStatus("Pingo could not simulate that shot.")
        }
    }

    private func submitExtraMove(_ move: PingoExtraGameMove) {
        guard let conversation = activeConversation,
              let payload = model.incomingPayload,
              payload.match.status == .active,
              payload.match.currentPlayerID == model.profile.id,
              PingoExtraGameEngine.supportedGames.contains(payload.match.gameID) else {
            model.setStatus("It is not your turn in this match.")
            return
        }
        guard model.canPlay(payload.match.gameID) else {
            model.showStore()
            model.setStatus(lockedPackMessage(for: payload.match.gameID, action: "continue this match"))
            return
        }

        do {
            let match = try PingoExtraGameEngine.submit(
                move: move,
                to: payload.match,
                actorID: model.profile.id,
                expectedRevision: payload.match.revision
            )
            try insertUpdatedMatch(match, conversation: conversation)
        } catch PingoMatchTransitionError.staleRevision {
            model.setStatus("That match changed. Open the newest Pingo message and try again.")
        } catch PingoMatchTransitionError.notActorsTurn {
            model.setStatus("It is not your turn yet.")
        } catch PingoGameRuleError.invalidMove {
            model.setStatus("That move is not legal. Adjust it and try again.")
        } catch {
            model.setStatus("Pingo could not apply that move.")
        }
    }

    private func continueSelectedSeries() {
        guard let conversation = activeConversation,
              let payload = model.incomingPayload,
              (payload.match.status == .completed || payload.match.status == .resigned),
              let series = payload.match.series,
              !series.completed else {
            model.setStatus("There is no unfinished series to continue.")
            return
        }
        guard payload.match.createdByPlayerID == model.profile.id else {
            model.setStatus("The player who started this series sends the next game.")
            return
        }
        guard model.canPlay(payload.match.gameID) else {
            model.showStore()
            model.setStatus(lockedPackMessage(for: payload.match.gameID, action: "continue this series"))
            return
        }

        do {
            let match = try PingoMatchReducer.continueSeries(payload.match, actorID: model.profile.id)
            let continued = PingoMessagePayload(action: .rematch, sender: model.profile, match: match)
            let session = conversation.selectedMessage?.session ?? MSSession()
            let message = try PingoMessageFactory.make(payload: continued, session: session)
            conversation.insert(message)
            model.incomingPayload = continued
            model.setStatus("Game \(series.gameNumber) added to the message box — tap Send.")
        } catch PingoMatchTransitionError.notActorsTurn {
            model.setStatus("The player who started this series sends the next game.")
        } catch {
            model.setStatus("Pingo could not continue this series.")
        }
    }

    private func insertUpdatedMatch(_ match: PingoMatchEnvelope, conversation: MSConversation) throws {
        let action: PingoMessageAction = match.status == .completed ? .completed : .turn
        let updated = PingoMessagePayload(action: action, sender: model.profile, match: match)
        let session = conversation.selectedMessage?.session ?? MSSession()
        let message = try PingoMessageFactory.make(payload: updated, session: session)
        conversation.insert(message)
        model.incomingPayload = updated
        model.setStatus(match.status == .completed ? "Result added to the message box — tap Send." : "Move added to the message box — tap Send.")
    }

    private func resignSelectedMatch() {
        guard let conversation = activeConversation,
              let payload = model.incomingPayload,
              payload.match.status == .active else {
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

    private func isSupportedGame(_ gameID: PingoGameID) -> Bool {
        PingoPlayableGameRegistry.supportedGames.contains(gameID) || PingoExtraGameEngine.supportedGames.contains(gameID)
    }

    private func lockedPackMessage(for gameID: PingoGameID, action: String) -> String {
        let title = PingoAccessPolicy.packTitle(for: gameID) ?? "required game pack"
        return "Unlock the \(title) to \(action)."
    }

    private func replacingGameState(in match: PingoMatchEnvelope, with gameState: Data) -> PingoMatchEnvelope {
        PingoMatchEnvelope(
            id: match.id,
            schemaVersion: match.schemaVersion,
            gameID: match.gameID,
            status: match.status,
            createdAt: match.createdAt,
            updatedAt: match.updatedAt,
            expiresAt: match.expiresAt,
            revision: match.revision,
            turnNumber: match.turnNumber,
            createdByPlayerID: match.createdByPlayerID,
            currentPlayerID: match.currentPlayerID,
            winnerPlayerID: match.winnerPlayerID,
            players: match.players,
            gameState: gameState,
            series: match.series
        )
    }
}
