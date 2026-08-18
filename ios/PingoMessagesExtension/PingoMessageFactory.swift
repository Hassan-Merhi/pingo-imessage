import Messages
import PingoCore

@MainActor
enum PingoMessageFactory {
    static func make(payload: PingoMessagePayload, session: MSSession) throws -> MSMessage {
        let game = PingoGameCatalog.game(id: payload.match.gameID)
        let message = MSMessage(session: session)
        let layout = MSMessageTemplateLayout()
        layout.caption = "\(game?.symbol ?? "🎮") \(game?.name ?? "Pingo")"
        layout.subcaption = subtitle(for: payload)
        if let game {
            layout.image = PingoMessagePreviewRenderer.image(for: game, payload: payload)
        }
        if let series = payload.match.series {
            layout.trailingCaption = series.format.title
            layout.trailingSubcaption = "\(seriesGameLabel(payload.match)) • \(series.scoreText)"
        } else {
            layout.trailingCaption = "Pingo"
            layout.trailingSubcaption = "Turn \(payload.match.turnNumber + 1)"
        }
        message.layout = layout
        message.summaryText = summary(for: payload, gameName: game?.name ?? "Pingo")
        message.url = try PingoMessageTransport.makeURL(payload: payload, baseURL: PingoConfiguration.messageBaseURL)
        return message
    }

    private static func subtitle(for payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge:
            if let series = payload.match.series {
                return "@\(payload.sender.username) challenged you • \(series.format.title)"
            }
            return "@\(payload.sender.username) challenged you"
        case .accepted: return "@\(payload.sender.username) accepted"
        case .turn: return "@\(payload.sender.username) made a move"
        case .resigned: return "@\(payload.sender.username) resigned"
        case .completed:
            if payload.match.series?.completed == true { return "Series complete" }
            return "Match complete"
        case .rematch: return "@\(payload.sender.username) continued the series"
        }
    }

    private static func summary(for payload: PingoMessagePayload, gameName: String) -> String {
        switch payload.action {
        case .challenge:
            if let series = payload.match.series {
                return "Pingo \(gameName) \(series.format.title) challenge from @\(payload.sender.username)"
            }
            return "Pingo \(gameName) challenge from @\(payload.sender.username)"
        case .accepted: return "@\(payload.sender.username) accepted the Pingo \(gameName) challenge"
        case .turn: return "New Pingo \(gameName) move from @\(payload.sender.username)"
        case .resigned: return "@\(payload.sender.username) resigned the Pingo \(gameName) match"
        case .completed:
            return payload.match.series?.completed == true
                ? "Pingo \(gameName) series completed"
                : "Pingo \(gameName) match completed"
        case .rematch: return "Next Pingo \(gameName) series game from @\(payload.sender.username)"
        }
    }

    private static func seriesGameLabel(_ match: PingoMatchEnvelope) -> String {
        guard let series = match.series else { return "Game 1" }
        let number: Int
        if match.status == .completed || match.status == .resigned {
            number = series.completed ? series.gameNumber : max(1, series.gameNumber - 1)
        } else {
            number = series.gameNumber
        }
        return "Game \(number)"
    }
}
