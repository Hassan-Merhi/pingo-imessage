import Messages
import PingoCore

@MainActor
enum PingoMessageFactory {
    static func make(payload: PingoMessagePayload, session: MSSession) throws -> MSMessage {
        let game = PingoGameCatalog.launch.first(where: { $0.id == payload.match.gameID })
        let message = MSMessage(session: session)
        let layout = MSMessageTemplateLayout()
        layout.caption = "\(game?.symbol ?? "🎮") \(game?.name ?? "Pingo")"
        layout.subcaption = subtitle(for: payload)
        layout.trailingCaption = "Pingo"
        layout.trailingSubcaption = "Turn \(payload.match.turnNumber + 1)"
        message.layout = layout
        message.summaryText = summary(for: payload, gameName: game?.name ?? "Pingo")
        message.url = try PingoMessageTransport.makeURL(payload: payload, baseURL: PingoConfiguration.messageBaseURL)
        return message
    }

    private static func subtitle(for payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge:
            return "@\(payload.sender.username) challenged you"
        case .accepted:
            return "@\(payload.sender.username) accepted"
        case .turn:
            return "@\(payload.sender.username) made a move"
        case .resigned:
            return "@\(payload.sender.username) resigned"
        case .completed:
            return "Match complete"
        case .rematch:
            return "@\(payload.sender.username) wants a rematch"
        }
    }

    private static func summary(for payload: PingoMessagePayload, gameName: String) -> String {
        switch payload.action {
        case .challenge: return "Pingo \(gameName) challenge from @\(payload.sender.username)"
        case .accepted: return "@\(payload.sender.username) accepted the Pingo \(gameName) challenge"
        case .turn: return "New Pingo \(gameName) move from @\(payload.sender.username)"
        case .resigned: return "@\(payload.sender.username) resigned the Pingo \(gameName) match"
        case .completed: return "Pingo \(gameName) match completed"
        case .rematch: return "Pingo \(gameName) rematch from @\(payload.sender.username)"
        }
    }
}
