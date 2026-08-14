import Foundation

public struct PingoExtraPoint: Hashable, Codable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct PingoExtraGameMove: Hashable, Codable, Sendable {
    public let primary: Int
    public let secondary: Int
    public let text: String
    public let points: [PingoExtraPoint]

    public init(primary: Int = 0, secondary: Int = 0, text: String = "", points: [PingoExtraPoint] = []) {
        self.primary = primary
        self.secondary = secondary
        self.text = text
        self.points = points
    }
}

public struct PingoExtraGameState: Hashable, Codable, Sendable {
    public var scores: [Int]
    public var attempts: [Int]
    public var seed: UInt64
    public var phase: Int
    public var challengeIndex: Int
    public var usedWords: [String]
    public var hands: [[Int]]
    public var deck: [Int]
    public var drawIndex: Int
    public var topCard: Int
    public var positions: [[Int]]
    public var drawing: [PingoExtraPoint]
    public var promptIndex: Int
    public var lastSummary: String
    public var lastScore: Int
    public var lastTarget: Int

    public init(
        scores: [Int] = [0, 0],
        attempts: [Int] = [0, 0],
        seed: UInt64 = 1,
        phase: Int = 0,
        challengeIndex: Int = 0,
        usedWords: [String] = [],
        hands: [[Int]] = [[], []],
        deck: [Int] = [],
        drawIndex: Int = 0,
        topCard: Int = -1,
        positions: [[Int]] = [[0], [0]],
        drawing: [PingoExtraPoint] = [],
        promptIndex: Int = 0,
        lastSummary: String = "",
        lastScore: Int = 0,
        lastTarget: Int = 0
    ) {
        self.scores = scores.count == 2 ? scores : [0, 0]
        self.attempts = attempts.count == 2 ? attempts : [0, 0]
        self.seed = seed == 0 ? 1 : seed
        self.phase = phase
        self.challengeIndex = challengeIndex
        self.usedWords = usedWords
        self.hands = hands.count == 2 ? hands : [[], []]
        self.deck = deck
        self.drawIndex = drawIndex
        self.topCard = topCard
        self.positions = positions.count == 2 ? positions : [[0], [0]]
        self.drawing = drawing
        self.promptIndex = promptIndex
        self.lastSummary = lastSummary
        self.lastScore = lastScore
        self.lastTarget = lastTarget
    }
}

public struct PingoTriviaQuestion: Hashable, Sendable {
    public let prompt: String
    public let options: [String]
    public let correctIndex: Int

    public init(prompt: String, options: [String], correctIndex: Int) {
        self.prompt = prompt
        self.options = options
        self.correctIndex = correctIndex
    }
}

public struct PingoWordHuntBoard: Hashable, Sendable {
    public let letters: [Character]
    public let acceptedWords: Set<String>

    public init(letters: String, acceptedWords: Set<String>) {
        self.letters = Array(letters.prefix(16))
        self.acceptedWords = acceptedWords
    }
}

public enum PingoExtraGameEngine {
    public static let supportedGames: Set<PingoGameID> = [
        .bowling, .penaltyShootout, .archery, .airHockey,
        .drawAndGuess, .wordHunt, .anagrams, .trivia,
        .crazyEights, .ludo, .miniRacing, .reactionBattle
    ]

    public static let drawPrompts = [
        "cat", "rocket", "pizza", "tree", "car", "sun", "fish", "house", "star", "boat"
    ]

    public static let anagramPuzzles: [(scrambled: String, answer: String)] = [
        ("OGNIP", "pingo"),
        ("PLEAP", "apple"),
        ("FTSWI", "swift"),
        ("GAMSEE", "message"),
        ("MEAG", "game"),
        ("PHYTRO", "trophy"),
        ("ZLZEUP", "puzzle"),
        ("RWOAR", "arrow"),
        ("CGINAR", "racing"),
        ("SDRAC", "cards")
    ]

    public static let triviaQuestions: [PingoTriviaQuestion] = [
        .init(prompt: "Which planet is known as the Red Planet?", options: ["Venus", "Mars", "Jupiter", "Mercury"], correctIndex: 1),
        .init(prompt: "How many sides does a hexagon have?", options: ["5", "6", "7", "8"], correctIndex: 1),
        .init(prompt: "Which ocean is the largest?", options: ["Atlantic", "Indian", "Pacific", "Arctic"], correctIndex: 2),
        .init(prompt: "What is H₂O commonly called?", options: ["Salt", "Water", "Oxygen", "Hydrogen"], correctIndex: 1),
        .init(prompt: "How many players are on a soccer team on the field?", options: ["9", "10", "11", "12"], correctIndex: 2),
        .init(prompt: "Which animal is the fastest on land?", options: ["Cheetah", "Lion", "Horse", "Gazelle"], correctIndex: 0),
        .init(prompt: "What color do blue and yellow make?", options: ["Purple", "Orange", "Green", "Red"], correctIndex: 2),
        .init(prompt: "Which instrument has black and white keys?", options: ["Violin", "Piano", "Flute", "Drums"], correctIndex: 1),
        .init(prompt: "How many minutes are in one hour?", options: ["30", "45", "60", "90"], correctIndex: 2),
        .init(prompt: "Which shape has three sides?", options: ["Square", "Circle", "Triangle", "Pentagon"], correctIndex: 2)
    ]

    public static let wordHuntBoards: [PingoWordHuntBoard] = [
        .init(
            letters: "PINGOWORDHUNTABC",
            acceptedWords: ["ping", "word", "hunt", "ring", "bird", "wind", "road", "town", "coin", "boat"]
        ),
        .init(
            letters: "PLAYGAMEFUNWORDS",
            acceptedWords: ["play", "game", "fun", "word", "words", "same", "name", "day", "say", "sun"]
        ),
        .init(
            letters: "CHATTURNPUZZLESX",
            acceptedWords: ["chat", "turn", "puzzle", "puzzles", "star", "start", "run", "sun", "hat", "art"]
        )
    ]

    private struct Resolution {
        var state: PingoExtraGameState
        var nextPlayer: Int
        var winner: Int?
        var draw: Bool
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    private static let decoder = JSONDecoder()

    public static func initialStateData(for gameID: PingoGameID, matchID: UUID) -> Data {
        guard supportedGames.contains(gameID) else { return Data() }
        var state = PingoExtraGameState(seed: seed(for: matchID))
        state.challengeIndex = Int(mixed(state.seed, 7) % UInt64(max(1, wordHuntBoards.count)))
        state.promptIndex = Int(mixed(state.seed, 11) % UInt64(max(1, drawPrompts.count)))

        if gameID == .crazyEights {
            let deck = shuffledDeck(seed: state.seed)
            state.deck = deck
            state.hands = [Array(deck[0..<5]), Array(deck[5..<10])]
            state.topCard = deck[10]
            state.drawIndex = 11
        } else if gameID == .ludo {
            state.positions = [[-1, -1], [-1, -1]]
        } else if gameID == .miniRacing {
            state.positions = [[0], [0]]
        }
        return (try? encoder.encode(state)) ?? Data()
    }

    public static func state(from data: Data, gameID: PingoGameID, matchID: UUID) throws -> PingoExtraGameState {
        let source = data.isEmpty ? initialStateData(for: gameID, matchID: matchID) : data
        do { return try decoder.decode(PingoExtraGameState.self, from: source) }
        catch { throw PingoGameRuleError.invalidState }
    }

    public static func submit(
        move: PingoExtraGameMove,
        to match: PingoMatchEnvelope,
        actorID: UUID,
        expectedRevision: Int,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard supportedGames.contains(match.gameID) else { throw PingoGameRuleError.unsupportedGame }
        guard match.status == .active else { throw PingoMatchTransitionError.invalidStatus }
        guard match.revision == expectedRevision else { throw PingoMatchTransitionError.staleRevision }
        guard match.currentPlayerID == actorID else { throw PingoMatchTransitionError.notActorsTurn }
        guard let actor = match.players.firstIndex(where: { $0.id == actorID }), match.players.count == 2 else {
            throw PingoMatchTransitionError.actorNotInMatch
        }

        let current = try state(from: match.gameState, gameID: match.gameID, matchID: match.id)
        let resolution: Resolution
        switch match.gameID {
        case .bowling: resolution = try applyBowling(move, player: actor, state: current)
        case .penaltyShootout: resolution = try applyPenalty(move, player: actor, state: current)
        case .archery: resolution = try applyArchery(move, player: actor, state: current)
        case .airHockey: resolution = try applyAirHockey(move, player: actor, state: current)
        case .drawAndGuess: resolution = try applyDrawAndGuess(move, player: actor, state: current)
        case .wordHunt: resolution = try applyWordHunt(move, player: actor, state: current)
        case .anagrams: resolution = try applyAnagram(move, player: actor, state: current)
        case .trivia: resolution = try applyTrivia(move, player: actor, state: current)
        case .crazyEights: resolution = try applyCrazyEights(move, player: actor, state: current)
        case .ludo: resolution = try applyLudo(move, player: actor, state: current)
        case .miniRacing: resolution = try applyMiniRacing(move, player: actor, state: current)
        case .reactionBattle: resolution = try applyReaction(move, player: actor, state: current)
        default: throw PingoGameRuleError.unsupportedGame
        }

        let data = try encoder.encode(resolution.state)
        if resolution.draw {
            return try PingoMatchReducer.completeTurn(
                match,
                actorID: actorID,
                expectedRevision: expectedRevision,
                winnerPlayerID: nil,
                gameState: data,
                now: now
            )
        }
        if let winner = resolution.winner {
            return try PingoMatchReducer.completeTurn(
                match,
                actorID: actorID,
                expectedRevision: expectedRevision,
                winnerPlayerID: match.players[winner].id,
                gameState: data,
                now: now
            )
        }
        return try PingoMatchReducer.submitTurn(
            match,
            actorID: actorID,
            expectedRevision: expectedRevision,
            nextPlayerID: match.players[resolution.nextPlayer].id,
            gameState: data,
            now: now
        )
    }

    public static func drawPrompt(for state: PingoExtraGameState) -> String {
        drawPrompts[bounded(state.promptIndex, 0, drawPrompts.count - 1)]
    }

    public static func anagramPrompt(for state: PingoExtraGameState) -> String {
        let index = (state.attempts[0] + state.attempts[1]) % anagramPuzzles.count
        return anagramPuzzles[index].scrambled
    }

    public static func triviaQuestion(for state: PingoExtraGameState) -> PingoTriviaQuestion {
        let index = (state.attempts[0] + state.attempts[1]) % triviaQuestions.count
        return triviaQuestions[index]
    }

    public static func wordHuntBoard(for state: PingoExtraGameState) -> PingoWordHuntBoard {
        wordHuntBoards[bounded(state.challengeIndex, 0, wordHuntBoards.count - 1)]
    }

    public static func ludoDie(for state: PingoExtraGameState) -> Int {
        1 + Int(mixed(state.seed, state.attempts[0] + state.attempts[1] + 101) % 6)
    }

    public static func reactionDelayMilliseconds(for state: PingoExtraGameState) -> Int {
        850 + Int(mixed(state.seed, state.attempts[0] + state.attempts[1] + 303) % 951)
    }

    public static func cardLabel(_ card: Int) -> String {
        guard (0..<52).contains(card) else { return "Card" }
        let ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
        let suits = ["♠︎", "♥︎", "♦︎", "♣︎"]
        return "\(ranks[card % 13])\(suits[card / 13])"
    }

    public static func isPlayableCard(_ card: Int, on topCard: Int) -> Bool {
        guard (0..<52).contains(card), (0..<52).contains(topCard) else { return false }
        let rank = card % 13
        let topRank = topCard % 13
        return rank == 7 || topRank == 7 || rank == topRank || card / 13 == topCard / 13
    }

    private static func applyBowling(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard (0...100).contains(move.primary), (0...100).contains(move.secondary) else { throw PingoGameRuleError.invalidMove }
        var next = state
        let accuracy = max(0, 100 - abs(50 - move.primary) * 2)
        let powerFit = max(0, 100 - abs(82 - move.secondary) * 2)
        let variance = Int(mixed(state.seed, totalAttempts(state) + 1) % 3) - 1
        let pins = bounded((accuracy + powerFit) / 20 + variance, 0, 10)
        next.scores[player] += pins
        next.attempts[player] += 1
        next.lastScore = pins
        next.lastSummary = pins == 10 ? "Strike!" : "\(pins) pins"
        return scoreDuel(next, player: player, attemptsEach: 5)
    }

    private static func applyPenalty(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard (0...4).contains(move.primary), (0...100).contains(move.secondary) else { throw PingoGameRuleError.invalidMove }
        var next = state
        let keeper = Int(mixed(state.seed, totalAttempts(state) + 41) % 5)
        let goal = move.primary != keeper && move.secondary >= 40
        if goal { next.scores[player] += 1 }
        next.attempts[player] += 1
        next.lastScore = goal ? 1 : 0
        next.lastTarget = keeper
        next.lastSummary = goal ? "Goal!" : "Saved"
        return scoreDuel(next, player: player, attemptsEach: 5)
    }

    private static func applyArchery(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard (0...100).contains(move.primary), (0...100).contains(move.secondary) else { throw PingoGameRuleError.invalidMove }
        var next = state
        let dx = move.primary - 50
        let dy = move.secondary - 50
        let distanceSquared = dx * dx + dy * dy
        let score: Int
        switch distanceSquared {
        case 0...25: score = 10
        case 26...100: score = 8
        case 101...225: score = 6
        case 226...400: score = 4
        case 401...625: score = 2
        default: score = 0
        }
        next.scores[player] += score
        next.attempts[player] += 1
        next.lastScore = score
        next.lastSummary = score == 10 ? "Bullseye!" : "\(score) points"
        return scoreDuel(next, player: player, attemptsEach: 5)
    }

    private static func applyAirHockey(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard (0...100).contains(move.primary), (0...100).contains(move.secondary) else { throw PingoGameRuleError.invalidMove }
        var next = state
        let opening = Int(mixed(state.seed, totalAttempts(state) + 67) % 101)
        let tolerance = max(8, move.secondary / 5)
        let goal = move.secondary >= 50 && abs(move.primary - opening) <= tolerance
        if goal { next.scores[player] += 1 }
        next.attempts[player] += 1
        next.lastScore = goal ? 1 : 0
        next.lastTarget = opening
        next.lastSummary = goal ? "Goal!" : "Blocked"
        return scoreDuel(next, player: player, attemptsEach: 7)
    }

    private static func applyDrawAndGuess(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        var next = state
        let opponent = 1 - player
        if state.phase == 0 {
            guard move.points.count >= 2, move.points.count <= 160,
                  move.points.allSatisfy({ (0...1000).contains($0.x) && (0...1000).contains($0.y) }) else {
                throw PingoGameRuleError.invalidMove
            }
            next.drawing = move.points
            next.phase = 1
            next.lastSummary = "Drawing sent"
            return Resolution(state: next, nextPlayer: opponent, winner: nil, draw: false)
        }

        let guess = canonical(move.text)
        guard !guess.isEmpty else { throw PingoGameRuleError.invalidMove }
        let correct = guess == drawPrompt(for: state)
        if correct {
            next.scores[player] += 2
            next.scores[opponent] += 1
        }
        next.attempts[player] += 1
        next.lastScore = correct ? 2 : 0
        next.lastSummary = correct ? "Correct guess!" : "Not quite"

        if totalAttempts(next) >= 6 {
            return finishByScore(next, nextPlayer: player)
        }

        next.phase = 0
        next.drawing = []
        next.promptIndex = Int(mixed(next.seed, totalAttempts(next) + 89) % UInt64(drawPrompts.count))
        return Resolution(state: next, nextPlayer: player, winner: nil, draw: false)
    }

    private static func applyWordHunt(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        let word = canonical(move.text)
        let board = wordHuntBoard(for: state)
        guard board.acceptedWords.contains(word), !state.usedWords.contains(word) else { throw PingoGameRuleError.invalidMove }
        var next = state
        next.usedWords.append(word)
        let points = max(1, word.count - 2)
        next.scores[player] += points
        next.attempts[player] += 1
        next.lastScore = points
        next.lastSummary = "+\(points) for \(word.uppercased())"
        return scoreDuel(next, player: player, attemptsEach: 6)
    }

    private static func applyAnagram(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        let answer = canonical(move.text)
        guard !answer.isEmpty else { throw PingoGameRuleError.invalidMove }
        let index = totalAttempts(state) % anagramPuzzles.count
        let puzzle = anagramPuzzles[index]
        var next = state
        let correct = answer == puzzle.answer
        let points = correct ? puzzle.answer.count : 0
        next.scores[player] += points
        next.attempts[player] += 1
        next.lastScore = points
        next.lastSummary = correct ? "Solved! +\(points)" : "Answer: \(puzzle.answer.uppercased())"
        return scoreDuel(next, player: player, attemptsEach: 5)
    }

    private static func applyTrivia(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard (0...3).contains(move.primary) else { throw PingoGameRuleError.invalidMove }
        let question = triviaQuestion(for: state)
        var next = state
        let correct = move.primary == question.correctIndex
        if correct { next.scores[player] += 1 }
        next.attempts[player] += 1
        next.lastScore = correct ? 1 : 0
        next.lastSummary = correct ? "Correct!" : "Wrong answer"
        return scoreDuel(next, player: player, attemptsEach: 5)
    }

    private static func applyCrazyEights(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard state.hands.count == 2, state.hands[player].count <= 52 else { throw PingoGameRuleError.invalidState }
        var next = state
        let opponent = 1 - player

        if move.primary == -1 {
            if next.drawIndex < next.deck.count {
                next.hands[player].append(next.deck[next.drawIndex])
                next.drawIndex += 1
                next.lastSummary = "Drew a card"
            } else {
                next.lastSummary = "Deck empty"
            }
        } else {
            guard let index = next.hands[player].firstIndex(of: move.primary),
                  isPlayableCard(move.primary, on: next.topCard) else {
                throw PingoGameRuleError.invalidMove
            }
            next.hands[player].remove(at: index)
            next.topCard = move.primary
            next.lastSummary = "Played \(cardLabel(move.primary))"
            if next.hands[player].isEmpty {
                next.attempts[player] += 1
                return Resolution(state: next, nextPlayer: opponent, winner: player, draw: false)
            }
        }

        next.attempts[player] += 1
        if totalAttempts(next) >= 80 || (next.drawIndex >= next.deck.count && !hasPlayableCard(in: next.hands[0], top: next.topCard) && !hasPlayableCard(in: next.hands[1], top: next.topCard)) {
            if next.hands[0].count == next.hands[1].count {
                return Resolution(state: next, nextPlayer: opponent, winner: nil, draw: true)
            }
            let winner = next.hands[0].count < next.hands[1].count ? 0 : 1
            return Resolution(state: next, nextPlayer: opponent, winner: winner, draw: false)
        }
        return Resolution(state: next, nextPlayer: opponent, winner: nil, draw: false)
    }

    private static func applyLudo(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard state.positions.count == 2,
              state.positions[player].count == 2 else { throw PingoGameRuleError.invalidState }
        let die = ludoDie(for: state)
        var next = state
        let opponent = 1 - player
        let legalPieces = (0..<2).filter { isLegalLudoMove(piece: $0, die: die, positions: state.positions[player]) }

        if move.primary == -1 {
            guard legalPieces.isEmpty else { throw PingoGameRuleError.invalidMove }
            next.lastSummary = "Rolled \(die) — no move"
        } else {
            guard legalPieces.contains(move.primary) else { throw PingoGameRuleError.invalidMove }
            let current = next.positions[player][move.primary]
            let destination = current == -1 ? 0 : min(24, current + die)
            next.positions[player][move.primary] = destination
            if destination < 24 {
                for index in next.positions[opponent].indices where next.positions[opponent][index] == destination {
                    next.positions[opponent][index] = -1
                }
            }
            next.lastSummary = "Rolled \(die) • piece \(move.primary + 1) → \(destination)"
        }

        next.attempts[player] += 1
        if next.positions[player].allSatisfy({ $0 >= 24 }) {
            return Resolution(state: next, nextPlayer: opponent, winner: player, draw: false)
        }
        if totalAttempts(next) >= 80 {
            let totals = next.positions.map { $0.reduce(0) { $0 + max(0, $1) } }
            if totals[0] == totals[1] { return Resolution(state: next, nextPlayer: opponent, winner: nil, draw: true) }
            return Resolution(state: next, nextPlayer: opponent, winner: totals[0] > totals[1] ? 0 : 1, draw: false)
        }
        return Resolution(state: next, nextPlayer: opponent, winner: nil, draw: false)
    }

    private static func applyMiniRacing(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard (0...100).contains(move.primary), (0...100).contains(move.secondary),
              state.positions.count == 2, !state.positions[player].isEmpty else { throw PingoGameRuleError.invalidMove }
        var next = state
        let opponent = 1 - player
        let variance = Int(mixed(state.seed, totalAttempts(state) + 131) % 5) - 2
        let gain = max(2, 20 - abs(82 - move.primary) / 6 - abs(50 - move.secondary) / 10 + variance)
        next.positions[player][0] = min(100, next.positions[player][0] + gain)
        next.scores[player] = next.positions[player][0]
        next.attempts[player] += 1
        next.lastScore = gain
        next.lastSummary = "+\(gain)m • \(next.positions[player][0])m"
        if next.positions[player][0] >= 100 {
            return Resolution(state: next, nextPlayer: opponent, winner: player, draw: false)
        }
        if next.attempts[0] >= 8 && next.attempts[1] >= 8 {
            return finishByScore(next, nextPlayer: opponent)
        }
        return Resolution(state: next, nextPlayer: opponent, winner: nil, draw: false)
    }

    private static func applyReaction(_ move: PingoExtraGameMove, player: Int, state: PingoExtraGameState) throws -> Resolution {
        guard (80...1500).contains(move.primary) else { throw PingoGameRuleError.invalidMove }
        var next = state
        let points = max(0, 1_200 - move.primary)
        next.scores[player] += points
        next.attempts[player] += 1
        next.lastScore = points
        next.lastTarget = move.primary
        next.lastSummary = "\(move.primary) ms • +\(points)"
        return scoreDuel(next, player: player, attemptsEach: 5)
    }

    private static func scoreDuel(_ state: PingoExtraGameState, player: Int, attemptsEach: Int) -> Resolution {
        let opponent = 1 - player
        if state.attempts[0] >= attemptsEach && state.attempts[1] >= attemptsEach {
            return finishByScore(state, nextPlayer: opponent)
        }
        return Resolution(state: state, nextPlayer: opponent, winner: nil, draw: false)
    }

    private static func finishByScore(_ state: PingoExtraGameState, nextPlayer: Int) -> Resolution {
        if state.scores[0] == state.scores[1] {
            return Resolution(state: state, nextPlayer: nextPlayer, winner: nil, draw: true)
        }
        return Resolution(state: state, nextPlayer: nextPlayer, winner: state.scores[0] > state.scores[1] ? 0 : 1, draw: false)
    }

    private static func isLegalLudoMove(piece: Int, die: Int, positions: [Int]) -> Bool {
        guard positions.indices.contains(piece) else { return false }
        let position = positions[piece]
        if position >= 24 { return false }
        if position == -1 { return die == 6 }
        return true
    }

    private static func hasPlayableCard(in hand: [Int], top: Int) -> Bool {
        hand.contains(where: { isPlayableCard($0, on: top) })
    }

    private static func totalAttempts(_ state: PingoExtraGameState) -> Int {
        state.attempts[0] + state.attempts[1]
    }

    private static func canonical(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func seed(for id: UUID) -> UInt64 {
        id.uuidString.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { partial, byte in
            (partial ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }

    private static func mixed(_ seed: UInt64, _ step: Int) -> UInt64 {
        var value = seed &+ UInt64(max(0, step)) &* 0x9E37_79B9_7F4A_7C15
        value ^= value >> 30
        value &*= 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        value &*= 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return value
    }

    private static func shuffledDeck(seed: UInt64) -> [Int] {
        var cards = Array(0..<52)
        var random = seed
        for index in stride(from: cards.count - 1, through: 1, by: -1) {
            random = mixed(random, index + 17)
            let other = Int(random % UInt64(index + 1))
            cards.swapAt(index, other)
        }
        return cards
    }

    private static func bounded(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
