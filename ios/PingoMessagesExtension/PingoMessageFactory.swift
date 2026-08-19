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

        if payload.match.gameID == .cupPong {
            layout.image = PingoCupPongMessagePreviewRenderer.image(payload: payload)
        } else if payload.match.gameID == .basketball {
            layout.image = PingoBasketballMessagePreviewRenderer.image(payload: payload)
        } else if let game {
            layout.image = PingoMessagePreviewRenderer.image(for: game, payload: payload)
        }

        if payload.match.gameID == .eightBall {
            configureEightBallTrailing(layout: layout, payload: payload)
        } else if payload.match.gameID == .cupPong {
            configureCupPongTrailing(layout: layout, payload: payload)
        } else if payload.match.gameID == .basketball {
            configureBasketballTrailing(layout: layout, payload: payload)
        } else if let series = payload.match.series {
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

    private static func configureEightBallTrailing(layout: MSMessageTemplateLayout, payload: PingoMessagePayload) {
        let state = try? PingoPhysicsGameEngine.eightBallState(from: payload.match.gameState)
        if let series = payload.match.series {
            layout.trailingCaption = "8 BALL • \(series.format.title)"
            layout.trailingSubcaption = "\(seriesGameLabel(payload.match)) • \(series.scoreText)"
            return
        }

        switch payload.match.status {
        case .awaitingOpponent:
            layout.trailingCaption = "8 BALL"
            layout.trailingSubcaption = "Challenge"
        case .active:
            layout.trailingCaption = state?.groups == [0, 0] ? "OPEN TABLE" : "8 BALL"
            layout.trailingSubcaption = "Shot \((state?.shotCount ?? payload.match.turnNumber) + 1)"
        case .completed:
            layout.trailingCaption = "8 BALL"
            layout.trailingSubcaption = "Final result"
        case .resigned:
            layout.trailingCaption = "8 BALL"
            layout.trailingSubcaption = "Match ended"
        case .draft:
            layout.trailingCaption = "8 BALL"
            layout.trailingSubcaption = "Preparing"
        case .expired:
            layout.trailingCaption = "8 BALL"
            layout.trailingSubcaption = "Expired"
        }
    }

    private static func configureCupPongTrailing(layout: MSMessageTemplateLayout, payload: PingoMessagePayload) {
        let state = try? PingoPhysicsGameEngine.cupPongState(from: payload.match.gameState)
        let cups = state?.cups ?? []
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderRemaining = cups.indices.contains(senderIndex) ? cups[senderIndex].filter { $0 }.count : 6
        let opponentRemaining = cups.indices.contains(opponentIndex) ? cups[opponentIndex].filter { $0 }.count : 6

        if let series = payload.match.series {
            layout.trailingCaption = "CUP PONG • \(series.format.title)"
            layout.trailingSubcaption = "\(seriesGameLabel(payload.match)) • \(series.scoreText)"
            return
        }

        switch payload.match.status {
        case .awaitingOpponent:
            layout.trailingCaption = "CUP PONG"
            layout.trailingSubcaption = "6 cups • Challenge"
        case .active:
            layout.trailingCaption = state?.lastCup == nil && (state?.turns ?? 0) > 0 ? "MISS" : "CUP PONG"
            layout.trailingSubcaption = "You \(senderRemaining) • Them \(opponentRemaining)"
        case .completed:
            layout.trailingCaption = "CUP PONG"
            layout.trailingSubcaption = "Final cups \(senderRemaining)–\(opponentRemaining)"
        case .resigned:
            layout.trailingCaption = "CUP PONG"
            layout.trailingSubcaption = "Match ended"
        case .draft:
            layout.trailingCaption = "CUP PONG"
            layout.trailingSubcaption = "Preparing"
        case .expired:
            layout.trailingCaption = "CUP PONG"
            layout.trailingSubcaption = "Expired"
        }
    }

    private static func configureBasketballTrailing(layout: MSMessageTemplateLayout, payload: PingoMessagePayload) {
        let state = try? PingoPhysicsGameEngine.basketballState(from: payload.match.gameState)
        let scores = state?.scores ?? [0, 0]
        let attempts = state?.attempts ?? [0, 0]
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = scores.indices.contains(senderIndex) ? scores[senderIndex] : 0
        let opponentScore = scores.indices.contains(opponentIndex) ? scores[opponentIndex] : 0
        let senderAttempts = attempts.indices.contains(senderIndex) ? attempts[senderIndex] : 0
        let opponentAttempts = attempts.indices.contains(opponentIndex) ? attempts[opponentIndex] : 0
        let attemptsPerPlayer = state?.attemptsPerPlayer ?? 5

        if let series = payload.match.series {
            layout.trailingCaption = "BASKETBALL • \(series.format.title)"
            layout.trailingSubcaption = "\(seriesGameLabel(payload.match)) • \(series.scoreText)"
            return
        }

        switch payload.match.status {
        case .awaitingOpponent:
            layout.trailingCaption = "BASKETBALL"
            layout.trailingSubcaption = "5 shots • Challenge"
        case .active:
            layout.trailingCaption = state?.lastPoints == 3 ? "SWISH +3" : state?.lastPoints == 2 ? "BUCKET +2" : (senderAttempts + opponentAttempts > 0 ? "MISS" : "BASKETBALL")
            layout.trailingSubcaption = "You \(senderScore) • Them \(opponentScore) • \(senderAttempts)/\(attemptsPerPlayer)"
        case .completed:
            layout.trailingCaption = "BASKETBALL"
            layout.trailingSubcaption = "Final \(senderScore)–\(opponentScore)"
        case .resigned:
            layout.trailingCaption = "BASKETBALL"
            layout.trailingSubcaption = "Match ended"
        case .draft:
            layout.trailingCaption = "BASKETBALL"
            layout.trailingSubcaption = "Preparing"
        case .expired:
            layout.trailingCaption = "BASKETBALL"
            layout.trailingSubcaption = "Expired"
        }
    }

    private static func subtitle(for payload: PingoMessagePayload) -> String {
        if payload.match.gameID == .eightBall {
            switch payload.action {
            case .challenge:
                if let series = payload.match.series {
                    return "@\(payload.sender.username) challenged you • \(series.format.title)"
                }
                return "@\(payload.sender.username) challenged you to 8 Ball"
            case .accepted:
                return "Table ready • @\(payload.sender.username) joined"
            case .turn:
                return "Shot sent • open the table"
            case .resigned:
                return "@\(payload.sender.username) ended the match"
            case .completed:
                return payload.match.series?.completed == true ? "Series complete • see the result" : "Rack complete • see the result"
            case .rematch:
                return "New rack ready"
            }
        }

        if payload.match.gameID == .cupPong {
            let state = try? PingoPhysicsGameEngine.cupPongState(from: payload.match.gameState)
            switch payload.action {
            case .challenge:
                if let series = payload.match.series {
                    return "@\(payload.sender.username) challenged you • \(series.format.title)"
                }
                return "@\(payload.sender.username) challenged you to Cup Pong"
            case .accepted:
                return "Table ready • first throw is live"
            case .turn:
                return state?.lastCup == nil ? "Miss • your throw" : "Cup sunk • your throw"
            case .resigned:
                return "@\(payload.sender.username) ended the match"
            case .completed:
                return payload.match.series?.completed == true ? "Series complete • see the result" : "Last cup down • see the result"
            case .rematch:
                return "Fresh cups • next game ready"
            }
        }

        if payload.match.gameID == .basketball {
            let state = try? PingoPhysicsGameEngine.basketballState(from: payload.match.gameState)
            switch payload.action {
            case .challenge:
                if let series = payload.match.series {
                    return "@\(payload.sender.username) challenged you • \(series.format.title)"
                }
                return "@\(payload.sender.username) challenged you to Basketball"
            case .accepted:
                return "Court ready • first shot is live"
            case .turn:
                if state?.lastPoints == 3 { return "Swish +3 • your shot" }
                if state?.lastPoints == 2 { return "Bucket +2 • your shot" }
                return "Miss • your shot"
            case .resigned:
                return "@\(payload.sender.username) ended the match"
            case .completed:
                return payload.match.series?.completed == true ? "Series complete • see the result" : "Shootout complete • see the result"
            case .rematch:
                return "Fresh shootout • next game ready"
            }
        }

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
