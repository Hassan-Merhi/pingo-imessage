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
        } else if payload.match.gameID == .darts {
            layout.image = PingoDartsMessagePreviewRenderer.image(payload: payload)
        } else if payload.match.gameID == .miniGolf {
            layout.image = PingoMiniGolfMessagePreviewRenderer.image(payload: payload)
        } else if payload.match.gameID == .miniRacing {
            layout.image = PingoMiniRacingMessagePreviewRenderer.image(payload: payload)
        } else if let game {
            layout.image = PingoMessagePreviewRenderer.image(for: game, payload: payload)
        }

        if payload.match.gameID == .eightBall {
            configureEightBallTrailing(layout: layout, payload: payload)
        } else if payload.match.gameID == .cupPong {
            configureCupPongTrailing(layout: layout, payload: payload)
        } else if payload.match.gameID == .basketball {
            configureBasketballTrailing(layout: layout, payload: payload)
        } else if payload.match.gameID == .darts {
            configureDartsTrailing(layout: layout, payload: payload)
        } else if payload.match.gameID == .miniGolf {
            configureMiniGolfTrailing(layout: layout, payload: payload)
        } else if payload.match.gameID == .miniRacing {
            configureMiniRacingTrailing(layout: layout, payload: payload)
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
            layout.trailingCaption = state?.lastPoints == 3 ? "SWISH +3" : state?.lastPoints == 2 ? "BUCKET +2" : (senderAttempts + (attempts.indices.contains(opponentIndex) ? attempts[opponentIndex] : 0) > 0 ? "MISS" : "BASKETBALL")
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

    private static func configureDartsTrailing(layout: MSMessageTemplateLayout, payload: PingoMessagePayload) {
        let state = try? PingoPhysicsGameEngine.dartsState(from: payload.match.gameState)
        let remaining = state?.remaining ?? [301, 301]
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderRemaining = remaining.indices.contains(senderIndex) ? remaining[senderIndex] : 301
        let opponentRemaining = remaining.indices.contains(opponentIndex) ? remaining[opponentIndex] : 301

        if let series = payload.match.series {
            layout.trailingCaption = "DARTS 301 • \(series.format.title)"
            layout.trailingSubcaption = "\(seriesGameLabel(payload.match)) • \(series.scoreText)"
            return
        }

        switch payload.match.status {
        case .awaitingOpponent:
            layout.trailingCaption = "DARTS 301"
            layout.trailingSubcaption = "Race to zero • Challenge"
        case .active:
            layout.trailingCaption = (state?.lastVisitScore ?? 0) > 0 ? "VISIT \(state?.lastVisitScore ?? 0)" : "DARTS 301"
            layout.trailingSubcaption = "You \(senderRemaining) • Them \(opponentRemaining)"
        case .completed:
            layout.trailingCaption = "DARTS 301"
            layout.trailingSubcaption = "Final \(senderRemaining)–\(opponentRemaining)"
        case .resigned:
            layout.trailingCaption = "DARTS 301"
            layout.trailingSubcaption = "Match ended"
        case .draft:
            layout.trailingCaption = "DARTS 301"
            layout.trailingSubcaption = "Preparing"
        case .expired:
            layout.trailingCaption = "DARTS 301"
            layout.trailingSubcaption = "Expired"
        }
    }

    private static func configureMiniGolfTrailing(layout: MSMessageTemplateLayout, payload: PingoMessagePayload) {
        let state = try? PingoPhysicsGameEngine.miniGolfState(from: payload.match.gameState)
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderTotal = value(state?.totals, senderIndex) + value(state?.holeStrokes, senderIndex)
        let opponentTotal = value(state?.totals, opponentIndex) + value(state?.holeStrokes, opponentIndex)
        let hole = min(max((state?.holeIndex ?? 0) + 1, 1), PingoMiniGolf.course.count)

        if let series = payload.match.series {
            layout.trailingCaption = "MINI GOLF • \(series.format.title)"
            layout.trailingSubcaption = "\(seriesGameLabel(payload.match)) • \(series.scoreText)"
            return
        }

        switch payload.match.status {
        case .awaitingOpponent:
            layout.trailingCaption = "MINI GOLF"
            layout.trailingSubcaption = "9 holes • Challenge"
        case .active:
            layout.trailingCaption = state?.lastAutoFinished == true ? "STROKE LIMIT" : "HOLE \(hole)/\(PingoMiniGolf.course.count)"
            layout.trailingSubcaption = "You \(senderTotal) • Them \(opponentTotal)"
        case .completed:
            layout.trailingCaption = "MINI GOLF"
            layout.trailingSubcaption = "Final \(senderTotal)–\(opponentTotal)"
        case .resigned:
            layout.trailingCaption = "MINI GOLF"
            layout.trailingSubcaption = "Match ended"
        case .draft:
            layout.trailingCaption = "MINI GOLF"
            layout.trailingSubcaption = "Preparing"
        case .expired:
            layout.trailingCaption = "MINI GOLF"
            layout.trailingSubcaption = "Expired"
        }
    }

    private static func configureMiniRacingTrailing(layout: MSMessageTemplateLayout, payload: PingoMessagePayload) {
        let state = try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .miniRacing, matchID: payload.match.id)
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderDistance = progress(state, senderIndex)
        let opponentDistance = progress(state, opponentIndex)
        let senderAttempts = value(state?.attempts, senderIndex)

        if let series = payload.match.series {
            layout.trailingCaption = "MINI RACING • \(series.format.title)"
            layout.trailingSubcaption = "\(seriesGameLabel(payload.match)) • \(series.scoreText)"
            return
        }

        switch payload.match.status {
        case .awaitingOpponent:
            layout.trailingCaption = "MINI RACING"
            layout.trailingSubcaption = "100m sprint • Challenge"
        case .active:
            layout.trailingCaption = state?.lastSummary.isEmpty == false ? state!.lastSummary.uppercased() : "MINI RACING"
            layout.trailingSubcaption = "You \(senderDistance)m • Them \(opponentDistance)m • \(senderAttempts)/8"
        case .completed:
            layout.trailingCaption = "MINI RACING"
            layout.trailingSubcaption = "Final \(senderDistance)m–\(opponentDistance)m"
        case .resigned:
            layout.trailingCaption = "MINI RACING"
            layout.trailingSubcaption = "Race ended"
        case .draft:
            layout.trailingCaption = "MINI RACING"
            layout.trailingSubcaption = "Preparing"
        case .expired:
            layout.trailingCaption = "MINI RACING"
            layout.trailingSubcaption = "Expired"
        }
    }

    private static func subtitle(for payload: PingoMessagePayload) -> String {
        if payload.match.gameID == .eightBall {
            switch payload.action {
            case .challenge:
                if let series = payload.match.series { return "@\(payload.sender.username) challenged you • \(series.format.title)" }
                return "@\(payload.sender.username) challenged you to 8 Ball"
            case .accepted: return "Table ready • @\(payload.sender.username) joined"
            case .turn: return "Shot sent • open the table"
            case .resigned: return "@\(payload.sender.username) ended the match"
            case .completed: return payload.match.series?.completed == true ? "Series complete • see the result" : "Rack complete • see the result"
            case .rematch: return "New rack ready"
            }
        }

        if payload.match.gameID == .cupPong {
            let state = try? PingoPhysicsGameEngine.cupPongState(from: payload.match.gameState)
            switch payload.action {
            case .challenge:
                if let series = payload.match.series { return "@\(payload.sender.username) challenged you • \(series.format.title)" }
                return "@\(payload.sender.username) challenged you to Cup Pong"
            case .accepted: return "Table ready • first throw is live"
            case .turn: return state?.lastCup == nil ? "Miss • your throw" : "Cup sunk • your throw"
            case .resigned: return "@\(payload.sender.username) ended the match"
            case .completed: return payload.match.series?.completed == true ? "Series complete • see the result" : "Last cup down • see the result"
            case .rematch: return "Fresh cups • next game ready"
            }
        }

        if payload.match.gameID == .basketball {
            let state = try? PingoPhysicsGameEngine.basketballState(from: payload.match.gameState)
            switch payload.action {
            case .challenge:
                if let series = payload.match.series { return "@\(payload.sender.username) challenged you • \(series.format.title)" }
                return "@\(payload.sender.username) challenged you to Basketball"
            case .accepted: return "Court ready • first shot is live"
            case .turn:
                if state?.lastPoints == 3 { return "Swish +3 • your shot" }
                if state?.lastPoints == 2 { return "Bucket +2 • your shot" }
                return "Miss • your shot"
            case .resigned: return "@\(payload.sender.username) ended the match"
            case .completed: return payload.match.series?.completed == true ? "Series complete • see the result" : "Shootout complete • see the result"
            case .rematch: return "Fresh shootout • next game ready"
            }
        }

        if payload.match.gameID == .darts {
            let state = try? PingoPhysicsGameEngine.dartsState(from: payload.match.gameState)
            switch payload.action {
            case .challenge:
                if let series = payload.match.series { return "@\(payload.sender.username) challenged you • \(series.format.title)" }
                return "@\(payload.sender.username) challenged you to Darts 301"
            case .accepted: return "Oche ready • first visit is live"
            case .turn:
                let score = state?.lastVisitScore ?? 0
                return score > 0 ? "Visit \(score) • your turn" : "No score • your turn"
            case .resigned: return "@\(payload.sender.username) ended the match"
            case .completed: return payload.match.series?.completed == true ? "Series complete • see the result" : "Checkout complete • see the result"
            case .rematch: return "Fresh leg • next game ready"
            }
        }

        if payload.match.gameID == .miniGolf {
            let state = try? PingoPhysicsGameEngine.miniGolfState(from: payload.match.gameState)
            switch payload.action {
            case .challenge:
                if let series = payload.match.series { return "@\(payload.sender.username) challenged you • \(series.format.title)" }
                return "@\(payload.sender.username) challenged you to Mini Golf"
            case .accepted: return "Course ready • first putt is live"
            case .turn: return state?.lastAutoFinished == true ? "Stroke limit reached • your putt" : "Putt sent • your turn"
            case .resigned: return "@\(payload.sender.username) ended the match"
            case .completed: return payload.match.series?.completed == true ? "Series complete • see the result" : "Course complete • see the result"
            case .rematch: return "Fresh course • next round ready"
            }
        }

        if payload.match.gameID == .miniRacing {
            let state = try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .miniRacing, matchID: payload.match.id)
            switch payload.action {
            case .challenge:
                if let series = payload.match.series { return "@\(payload.sender.username) challenged you • \(series.format.title)" }
                return "@\(payload.sender.username) challenged you to Mini Racing"
            case .accepted: return "Grid ready • first run is live"
            case .turn: return state?.lastSummary.isEmpty == false ? "\(state!.lastSummary) • your run" : "Run sent • your turn"
            case .resigned: return "@\(payload.sender.username) ended the race"
            case .completed: return payload.match.series?.completed == true ? "Series complete • see the result" : "Race complete • see the result"
            case .rematch: return "Fresh grid • next race ready"
            }
        }

        switch payload.action {
        case .challenge:
            if let series = payload.match.series { return "@\(payload.sender.username) challenged you • \(series.format.title)" }
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
            if let series = payload.match.series { return "Pingo \(gameName) \(series.format.title) challenge from @\(payload.sender.username)" }
            return "Pingo \(gameName) challenge from @\(payload.sender.username)"
        case .accepted: return "@\(payload.sender.username) accepted the Pingo \(gameName) challenge"
        case .turn: return "New Pingo \(gameName) move from @\(payload.sender.username)"
        case .resigned: return "@\(payload.sender.username) resigned the Pingo \(gameName) match"
        case .completed:
            return payload.match.series?.completed == true ? "Pingo \(gameName) series completed" : "Pingo \(gameName) match completed"
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

    private static func value(_ values: [Int]?, _ index: Int) -> Int {
        guard let values, values.indices.contains(index) else { return 0 }
        return values[index]
    }

    private static func progress(_ state: PingoExtraGameState?, _ index: Int) -> Int {
        guard let state, state.positions.indices.contains(index), let distance = state.positions[index].first else { return 0 }
        return min(100, max(0, distance))
    }
}
