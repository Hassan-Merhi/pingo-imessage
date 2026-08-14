import PingoCore
import SwiftUI

struct PingoBoardGameView: View {
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMoves: ([PingoGameMove]) -> Void

    private var localPlayerIndex: Int? {
        match.players.firstIndex(where: { $0.id == localProfile.id })
    }

    private var canMove: Bool {
        match.status == .active && match.currentPlayerID == localProfile.id
    }

    var body: some View {
        Group {
            switch match.gameID {
            case .ticTacToe:
                if let state = try? PingoBoardGameEngine.ticTacToeState(from: match.gameState) {
                    TicTacToeBoard(state: state, enabled: canMove) { onMoves([.ticTacToe($0)]) }
                }
            case .connectFour:
                if let state = try? PingoBoardGameEngine.connectFourState(from: match.gameState) {
                    ConnectFourBoard(state: state, enabled: canMove) { onMoves([.connectFour(column: $0)]) }
                }
            case .checkers:
                if let state = try? PingoBoardGameEngine.checkersState(from: match.gameState), let localPlayerIndex {
                    CheckersBoard(state: state, localPlayer: localPlayerIndex, enabled: canMove) { from, to in
                        onMoves([.checkers(from: from, to: to)])
                    }
                }
            case .chess:
                if let state = try? PingoBoardGameEngine.chessState(from: match.gameState), let localPlayerIndex {
                    ChessBoard(state: state, localPlayer: localPlayerIndex, enabled: canMove) { from, to, promotion in
                        onMoves([.chess(from: from, to: to, promotion: promotion)])
                    }
                }
            case .seaBattle:
                if let state = try? PingoBoardGameEngine.seaBattleState(from: match.gameState), let localPlayerIndex {
                    SeaBattleBoard(
                        state: state,
                        localPlayer: localPlayerIndex,
                        enabled: canMove,
                        matchComplete: match.status == .completed,
                        onMoves: onMoves
                    )
                }
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TicTacToeBoard: View {
    let state: PingoTicTacToeState
    let enabled: Bool
    let onMove: (PingoGridPoint) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(0..<9, id: \.self) { index in
                let value = state.cells[index]
                Button {
                    onMove(.init(row: index / 3, column: index % 3))
                } label: {
                    Text(value == 1 ? "X" : value == 2 ? "O" : " ")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .disabled(!enabled || value != 0)
                .accessibilityLabel("Row \(index / 3 + 1), column \(index % 3 + 1)")
            }
        }
        .padding(.horizontal, 30)
    }
}

private struct ConnectFourBoard: View {
    let state: PingoConnectFourState
    let enabled: Bool
    let onColumn: (Int) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { column in
                    Button {
                        onColumn(column)
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.pingoPrimary)
                    .disabled(!enabled || state.cells[column] != 0)
                    .accessibilityLabel("Drop in column \(column + 1)")
                }
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<42, id: \.self) { index in
                    let value = state.cells[index]
                    Circle()
                        .fill(value == 1 ? Color.pingoPrimary : value == 2 ? Color.orange : Color.primary.opacity(0.09))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 12)
    }
}

private struct CheckersBoard: View {
    let state: PingoCheckersState
    let localPlayer: Int
    let enabled: Bool
    let onMove: (PingoGridPoint, PingoGridPoint) -> Void
    @State private var selected: PingoGridPoint?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 8)

    private var legal: [(from: PingoGridPoint, to: PingoGridPoint)] {
        PingoCheckers.legalMoves(in: state, player: localPlayer)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(0..<64, id: \.self) { index in
                let point = PingoGridPoint(row: index / 8, column: index % 8)
                let piece = state.cells[index]
                let isDark = (point.row + point.column) % 2 == 1
                let isSelected = selected == point
                let isDestination = selected.map { from in legal.contains(where: { $0.from == from && $0.to == point }) } ?? false
                Button {
                    tapped(point: point, piece: piece)
                } label: {
                    ZStack {
                        Rectangle().fill(isDark ? Color.primary.opacity(0.16) : Color.primary.opacity(0.04))
                        if isDestination { Circle().fill(Color.pingoPrimary.opacity(0.28)).padding(11) }
                        if piece != 0 {
                            Circle()
                                .fill(PingoCheckers.owner(of: piece) == 0 ? Color.pingoPrimary : Color.orange)
                                .padding(4)
                                .overlay {
                                    if PingoCheckers.isKing(piece) {
                                        Image(systemName: "crown.fill").font(.caption).foregroundStyle(.white)
                                    }
                                }
                                .overlay { if isSelected { Circle().stroke(Color.white, lineWidth: 3).padding(4) } }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 10)
        .onChange(of: state.forcedFrom) { forced in
            if let forced { selected = .init(row: forced / 8, column: forced % 8) }
        }
    }

    private func tapped(point: PingoGridPoint, piece: Int) {
        if let selected, legal.contains(where: { $0.from == selected && $0.to == point }) {
            onMove(selected, point)
            self.selected = nil
            return
        }
        if PingoCheckers.owner(of: piece) == localPlayer,
           legal.contains(where: { $0.from == point }) {
            selected = point
        } else {
            selected = nil
        }
    }
}

private struct PendingPromotion: Identifiable {
    let id = UUID()
    let from: PingoGridPoint
    let to: PingoGridPoint
}

private struct ChessBoard: View {
    let state: PingoChessState
    let localPlayer: Int
    let enabled: Bool
    let onMove: (PingoGridPoint, PingoGridPoint, PingoChessPromotion?) -> Void
    @State private var selected: PingoGridPoint?
    @State private var promotion: PendingPromotion?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(0..<64, id: \.self) { displayIndex in
                let row = localPlayer == 0 ? displayIndex / 8 : 7 - displayIndex / 8
                let column = localPlayer == 0 ? displayIndex % 8 : 7 - displayIndex % 8
                let point = PingoGridPoint(row: row, column: column)
                let piece = state.cells[point.index8]
                let destinations = selected.map { PingoChess.legalDestinations(from: $0, player: localPlayer, in: state) } ?? []
                let highlighted = destinations.contains(point)
                Button {
                    tapped(point: point, piece: piece, destinations: destinations)
                } label: {
                    ZStack {
                        Rectangle().fill((row + column) % 2 == 0 ? Color.primary.opacity(0.05) : Color.primary.opacity(0.17))
                        if highlighted { Circle().fill(Color.pingoPrimary.opacity(piece == 0 ? 0.28 : 0.18)).padding(piece == 0 ? 13 : 4) }
                        if piece != 0 {
                            Text(symbol(piece))
                                .font(.system(size: 30))
                                .minimumScaleFactor(0.65)
                        }
                        if selected == point { Rectangle().stroke(Color.pingoPrimary, lineWidth: 3) }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 10)
        .confirmationDialog("Promote pawn", item: $promotion) { pending in
            Button("Queen") { onMove(pending.from, pending.to, .queen) }
            Button("Rook") { onMove(pending.from, pending.to, .rook) }
            Button("Bishop") { onMove(pending.from, pending.to, .bishop) }
            Button("Knight") { onMove(pending.from, pending.to, .knight) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func tapped(point: PingoGridPoint, piece: Int, destinations: [PingoGridPoint]) {
        if let selected, destinations.contains(point) {
            let moving = state.cells[selected.index8]
            if PingoChess.kind(of: moving) == 1, point.row == (localPlayer == 0 ? 0 : 7) {
                promotion = .init(from: selected, to: point)
            } else {
                onMove(selected, point, nil)
            }
            self.selected = nil
            return
        }
        if PingoChess.owner(of: piece) == localPlayer,
           !PingoChess.legalDestinations(from: point, player: localPlayer, in: state).isEmpty {
            selected = point
        } else {
            selected = nil
        }
    }

    private func symbol(_ code: Int) -> String {
        let symbols = [
            1: "♙", 2: "♘", 3: "♗", 4: "♖", 5: "♕", 6: "♔",
            7: "♟", 8: "♞", 9: "♝", 10: "♜", 11: "♛", 12: "♚"
        ]
        return symbols[code] ?? ""
    }
}

private struct SeaBattleBoard: View {
    let state: PingoSeaBattleState
    let localPlayer: Int
    let enabled: Bool
    let matchComplete: Bool
    let onMoves: ([PingoGameMove]) -> Void

    @State private var draftPlacements: [PingoSeaBattlePlacement] = []
    @State private var selectedShip: PingoSeaBattleShip = .carrier
    @State private var orientation: PingoSeaBattleOrientation = .horizontal
    @State private var placementError: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 10)
    private var opponent: Int { 1 - localPlayer }
    private var localFleetReady: Bool { state.fleetReady(player: localPlayer) }
    private var allFleetsReady: Bool { state.fleetReady(player: 0) && state.fleetReady(player: 1) }

    var body: some View {
        VStack(spacing: 14) {
            if !localFleetReady {
                placementControls
                Text("Your fleet")
                    .font(.headline)
                grid(
                    ships: Set(draftPlacements.flatMap(\.cells)),
                    hits: [],
                    misses: [],
                    revealShips: true,
                    tap: enabled ? placeDraft : nil
                )
                Button("Lock Fleet") {
                    let ordered = PingoSeaBattleShip.allCases.compactMap { ship in draftPlacements.first(where: { $0.ship == ship }) }
                    onMoves(ordered.map { .seaBattlePlace(ship: $0.ship, start: $0.start, orientation: $0.orientation) })
                }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
                .disabled(!enabled || Set(draftPlacements.map(\.ship)) != Set(PingoSeaBattleShip.allCases))
            } else if !allFleetsReady {
                Label("Fleet locked. Waiting for your opponent to place theirs.", systemImage: "lock.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(matchComplete ? "Final battlefield" : "Opponent waters")
                    .font(.headline)
                targetGrid
                Text("Your fleet")
                    .font(.headline)
                ownGrid
            }
            if let placementError {
                Text(placementError).font(.caption).foregroundStyle(.red)
            }
        }
        .onAppear {
            if draftPlacements.isEmpty { draftPlacements = state.placements[localPlayer] }
            selectFirstUnplaced()
        }
    }

    private var placementControls: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PingoSeaBattleShip.allCases, id: \.self) { ship in
                        let placed = draftPlacements.contains(where: { $0.ship == ship })
                        Button("\(ship.title) · \(ship.length)") { selectedShip = ship }
                            .buttonStyle(.bordered)
                            .tint(selectedShip == ship ? .pingoPrimary : .secondary)
                            .disabled(placed)
                    }
                }
            }
            HStack {
                Picker("Orientation", selection: $orientation) {
                    Text("Horizontal").tag(PingoSeaBattleOrientation.horizontal)
                    Text("Vertical").tag(PingoSeaBattleOrientation.vertical)
                }
                .pickerStyle(.segmented)
                Button("Reset") {
                    draftPlacements = []
                    selectedShip = .carrier
                    placementError = nil
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var targetGrid: some View {
        let fired = Set(state.shots[localPlayer])
        let opponentShips = state.occupiedCells(player: opponent)
        let hits = fired.intersection(opponentShips)
        let misses = fired.subtracting(opponentShips)
        return grid(
            ships: opponentShips,
            hits: hits,
            misses: misses,
            revealShips: matchComplete,
            tap: enabled && !matchComplete ? { point in onMoves([.seaBattleFire(point)]) } : nil
        )
    }

    private var ownGrid: some View {
        let firedAtMe = Set(state.shots[opponent])
        let ships = state.occupiedCells(player: localPlayer)
        return grid(
            ships: ships,
            hits: firedAtMe.intersection(ships),
            misses: firedAtMe.subtracting(ships),
            revealShips: true,
            tap: nil
        )
    }

    private func grid(ships: Set<Int>, hits: Set<Int>, misses: Set<Int>, revealShips: Bool, tap: ((PingoGridPoint) -> Void)?) -> some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<100, id: \.self) { index in
                Button {
                    tap?(.init(row: index / 10, column: index % 10))
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(cellColor(index: index, ships: ships, hits: hits, misses: misses, revealShips: revealShips))
                        if hits.contains(index) { Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(.white) }
                        else if misses.contains(index) { Circle().fill(Color.white.opacity(0.9)).frame(width: 5, height: 5) }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .disabled(tap == nil || hits.contains(index) || misses.contains(index))
            }
        }
        .padding(6)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 4)
    }

    private func cellColor(index: Int, ships: Set<Int>, hits: Set<Int>, misses: Set<Int>, revealShips: Bool) -> Color {
        if hits.contains(index) { return .red }
        if revealShips && ships.contains(index) { return .gray }
        if misses.contains(index) { return .blue.opacity(0.55) }
        return .blue.opacity(0.2)
    }

    private func placeDraft(_ point: PingoGridPoint) {
        var draftState = state
        draftState.placements[localPlayer] = draftPlacements
        do {
            let next = try PingoSeaBattle.place(ship: selectedShip, start: point, orientation: orientation, player: localPlayer, in: draftState)
            draftPlacements = next.placements[localPlayer]
            placementError = nil
            selectFirstUnplaced()
        } catch PingoGameRuleError.shipsOverlap {
            placementError = "Ships cannot overlap."
        } catch PingoGameRuleError.outOfBounds {
            placementError = "That ship would extend outside the board."
        } catch {
            placementError = "Choose another position."
        }
    }

    private func selectFirstUnplaced() {
        if let next = PingoSeaBattleShip.allCases.first(where: { ship in !draftPlacements.contains(where: { $0.ship == ship }) }) {
            selectedShip = next
        }
    }
}
