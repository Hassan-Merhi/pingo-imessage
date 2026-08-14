import PingoCore
import SwiftUI

struct PingoPhysicsGameView: View {
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void

    private var localIndex: Int? { match.players.firstIndex(where: { $0.id == localProfile.id }) }
    private var canMove: Bool { match.status == .active && match.currentPlayerID == localProfile.id }

    @ViewBuilder
    var body: some View {
        if let index = localIndex {
            switch match.gameID {
            case .eightBall:
                EightBallPlayView(state: (try? PingoPhysicsGameEngine.eightBallState(from: match.gameState)) ?? PingoEightBallState(), player: index, canMove: canMove, onMove: onMove)
            case .cupPong:
                CupPongPlayView(state: (try? PingoPhysicsGameEngine.cupPongState(from: match.gameState)) ?? PingoCupPongState(), player: index, canMove: canMove, onMove: onMove)
            case .basketball:
                BasketballPlayView(state: (try? PingoPhysicsGameEngine.basketballState(from: match.gameState)) ?? PingoBasketballState(), player: index, canMove: canMove, onMove: onMove)
            case .darts:
                DartsPlayView(state: (try? PingoPhysicsGameEngine.dartsState(from: match.gameState)) ?? PingoDartsState(), player: index, canMove: canMove, onMove: onMove)
            case .miniGolf:
                MiniGolfPlayView(state: (try? PingoPhysicsGameEngine.miniGolfState(from: match.gameState)) ?? PingoMiniGolfState(), player: index, canMove: canMove, onMove: onMove)
            default:
                EmptyView()
            }
        }
    }
}

private struct GameControlCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: 12, content: content)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct EightBallPlayView: View {
    let state: PingoEightBallState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void
    @State private var angle = 0.0
    @State private var power = 0.58

    var body: some View {
        GameControlCard {
            HStack {
                Text("8-Ball").font(.headline)
                Spacer()
                Text(groupText).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            PoolTableView(state: state).frame(height: 190)
            if !state.lastPocketed.isEmpty || state.lastScratch {
                Text(lastShotText).font(.caption).foregroundStyle(.secondary)
            }
            if canMove {
                control(title: "Aim", value: angle, suffix: "°")
                Slider(value: $angle, in: 0...359)
                control(title: "Power", value: power * 100, suffix: "%")
                Slider(value: $power, in: 0.05...1)
                Button("Shoot & Send") { onMove(.eightBall(.init(angleDegrees: angle, power: power))) }
                    .buttonStyle(.borderedProminent).tint(.pingoPrimary)
            } else { waitingText }
        }
    }

    private var groupText: String {
        guard state.groups.indices.contains(player) else { return "Open table" }
        return state.groups[player] == 1 ? "Solids" : state.groups[player] == 2 ? "Stripes" : "Open table"
    }
    private var lastShotText: String {
        if state.lastScratch { return "Last shot: scratch" }
        return "Last shot pocketed: " + state.lastPocketed.map(String.init).joined(separator: ", ")
    }
}

private struct PoolTableView: View {
    let state: PingoEightBallState
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(Color.green.opacity(0.75))
                ForEach(pockets, id: \.0) { item in
                    Circle().fill(Color.black).frame(width: 17, height: 17)
                        .position(x: proxy.size.width * item.1.x, y: proxy.size.height * item.1.y)
                }
                ForEach(state.balls.filter { !$0.pocketed }) { ball in
                    ZStack {
                        Circle().fill(ballFill(ball.id))
                        if ball.id != 0 { Text("\(ball.id)").font(.system(size: 7, weight: .bold)).foregroundStyle(ball.id == 8 ? .white : .black) }
                    }
                    .frame(width: 14, height: 14)
                    .position(x: proxy.size.width * ball.position.x, y: proxy.size.height * ball.position.y)
                }
            }
        }
    }
    private var pockets: [(Int, PingoVector2)] { [
        (0,.init(x:0.03,y:0.05)),(1,.init(x:0.5,y:0.03)),(2,.init(x:0.97,y:0.05)),
        (3,.init(x:0.03,y:0.95)),(4,.init(x:0.5,y:0.97)),(5,.init(x:0.97,y:0.95))
    ] }
    private func ballFill(_ id: Int) -> Color {
        if id == 0 { return .white }
        if id == 8 { return .black }
        return (1...7).contains(id) ? .yellow : .orange
    }
}

private struct CupPongPlayView: View {
    let state: PingoCupPongState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void
    @State private var aim = 0.0
    @State private var power = 0.58

    var body: some View {
        GameControlCard {
            HStack {
                Text("Cup Pong").font(.headline)
                Spacer()
                Text("You \(remaining(player)) • Them \(remaining(1-player))").font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Text(state.cups[1-player][index] ? "🥤" : "·").font(.system(size: 30)).frame(height: 38)
                }
            }
            if let hit = state.lastCup { Text("Last throw sank cup \(hit + 1)!").font(.caption).foregroundStyle(.secondary) }
            if canMove {
                control(title: "Aim", value: aim, suffix: "°")
                Slider(value: $aim, in: -30...30)
                control(title: "Arc power", value: power * 100, suffix: "%")
                Slider(value: $power, in: 0.15...1)
                Button("Throw & Send") { onMove(.cupPong(.init(angleDegrees: aim, power: power))) }
                    .buttonStyle(.borderedProminent).tint(.pingoPrimary)
            } else { waitingText }
        }
    }
    private func remaining(_ index: Int) -> Int { state.cups[index].filter { $0 }.count }
}

private struct BasketballPlayView: View {
    let state: PingoBasketballState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void
    @State private var angle = 52.0
    @State private var power = 0.72

    var body: some View {
        GameControlCard {
            HStack {
                VStack(alignment: .leading) { Text("Basketball").font(.headline); Text("5-shot shootout").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Text("\(state.scores[player]) – \(state.scores[1-player])").font(.title2.bold())
            }
            HStack {
                Label("You \(state.attempts[player])/5", systemImage: "basketball.fill")
                Spacer()
                Text(state.lastPoints == 3 ? "SWISH +3" : state.lastPoints == 2 ? "+2" : state.attempts.reduce(0,+) == 0 ? "Ready" : "Miss")
                    .font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            if canMove {
                control(title: "Release angle", value: angle, suffix: "°")
                Slider(value: $angle, in: 30...75)
                control(title: "Power", value: power * 100, suffix: "%")
                Slider(value: $power, in: 0.2...1)
                Button("Shoot & Send") { onMove(.basketball(.init(angleDegrees: angle, power: power))) }
                    .buttonStyle(.borderedProminent).tint(.pingoPrimary)
            } else { waitingText }
        }
    }
}

private struct DartsPlayView: View {
    let state: PingoDartsState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void
    @State private var darts: [PingoDartPoint] = []

    var body: some View {
        GameControlCard {
            HStack {
                VStack(alignment: .leading) { Text("Darts 301").font(.headline); Text("Straight-out • 3 darts per turn").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Text("\(state.remaining[player])").font(.title2.bold())
            }
            DartBoard(darts: darts, enabled: canMove && darts.count < 3) { point in darts.append(point) }
                .frame(height: 240)
            HStack {
                Text("Darts: \(darts.count)/3").font(.caption).foregroundStyle(.secondary)
                Spacer()
                if !darts.isEmpty { Button("Clear") { darts.removeAll() }.font(.caption) }
            }
            if canMove {
                Button("Send Visit") { onMove(.darts(.init(darts: darts))); darts.removeAll() }
                    .buttonStyle(.borderedProminent).tint(.pingoPrimary).disabled(darts.count != 3)
            } else { waitingText }
        }
    }
}

private struct DartBoard: View {
    let darts: [PingoDartPoint]
    let enabled: Bool
    let onTap: (PingoDartPoint) -> Void
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle().fill(Color.black.opacity(0.86))
                Circle().stroke(Color.white.opacity(0.6), lineWidth: 1).padding(proxy.size.width * 0.07)
                Circle().stroke(Color.green, lineWidth: 12).padding(proxy.size.width * 0.20)
                Circle().stroke(Color.red, lineWidth: 10).padding(proxy.size.width * 0.43)
                ForEach(Array(darts.enumerated()), id: \.offset) { _, dart in
                    Circle().fill(Color.pingoPrimary).frame(width: 12, height: 12)
                        .position(x: proxy.size.width * (dart.x / 2 + 0.5), y: proxy.size.height * (dart.y / 2 + 0.5))
                }
            }
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).onEnded { value in
                guard enabled, proxy.size.width > 0, proxy.size.height > 0 else { return }
                let x = (value.location.x / proxy.size.width - 0.5) * 2
                let y = (value.location.y / proxy.size.height - 0.5) * 2
                onTap(.init(x: x, y: y))
            })
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct MiniGolfPlayView: View {
    let state: PingoMiniGolfState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void
    @State private var angle = 0.0
    @State private var power = 0.45

    var body: some View {
        let layout = PingoMiniGolf.course[min(state.holeIndex, PingoMiniGolf.course.count - 1)]
        GameControlCard {
            HStack {
                VStack(alignment: .leading) { Text("Mini Golf").font(.headline); Text("Hole \(state.holeIndex + 1) of 9").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Text("\(state.totals[player] + state.holeStrokes[player]) – \(state.totals[1-player] + state.holeStrokes[1-player])").font(.title2.bold())
            }
            MiniGolfCourseView(layout: layout, state: state, player: player).frame(height: 250)
            Text(state.holed[player] ? "You're in! Waiting for the other player to finish the hole." : "Stroke \(state.holeStrokes[player] + 1) • aim for the cup")
                .font(.caption).foregroundStyle(.secondary)
            if canMove && !state.holed[player] {
                control(title: "Aim", value: angle, suffix: "°")
                Slider(value: $angle, in: 0...359)
                control(title: "Power", value: power * 100, suffix: "%")
                Slider(value: $power, in: 0.05...1)
                Button("Putt & Send") { onMove(.miniGolf(.init(angleDegrees: angle, power: power))) }
                    .buttonStyle(.borderedProminent).tint(.pingoPrimary)
            } else { waitingText }
        }
    }
}

private struct MiniGolfCourseView: View {
    let layout: PingoMiniGolfCourse
    let state: PingoMiniGolfState
    let player: Int
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color.green.opacity(0.55))
                ForEach(Array(layout.obstacles.enumerated()), id: \.offset) { _, obstacle in
                    Rectangle().fill(Color.brown.opacity(0.8))
                        .frame(width: proxy.size.width * (obstacle.maxX - obstacle.minX), height: proxy.size.height * (obstacle.maxY - obstacle.minY))
                        .position(x: proxy.size.width * ((obstacle.minX + obstacle.maxX) / 2), y: proxy.size.height * ((obstacle.minY + obstacle.maxY) / 2))
                }
                Circle().fill(Color.black).frame(width: 16, height: 16)
                    .position(x: proxy.size.width * layout.hole.x, y: proxy.size.height * layout.hole.y)
                Text("⚑").font(.system(size: 20))
                    .position(x: proxy.size.width * layout.hole.x + 8, y: proxy.size.height * layout.hole.y - 13)
                Circle().fill(Color.white).overlay(Circle().stroke(Color.pingoPrimary, lineWidth: 2)).frame(width: 15, height: 15)
                    .position(x: proxy.size.width * state.positions[player].x, y: proxy.size.height * state.positions[player].y)
                Circle().fill(Color.gray).frame(width: 12, height: 12)
                    .position(x: proxy.size.width * state.positions[1-player].x, y: proxy.size.height * state.positions[1-player].y)
            }
        }
    }
}

private func control(title: String, value: Double, suffix: String) -> some View {
    HStack {
        Text(title).font(.caption.weight(.semibold))
        Spacer()
        Text("\(Int(value.rounded()))\(suffix)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
    }
}

private var waitingText: some View {
    Text("Waiting for the newest Pingo turn.")
        .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
}
