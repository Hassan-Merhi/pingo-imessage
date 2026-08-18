import PingoCore
import SwiftUI

struct PingoImmersiveArcadeView: View {
    let gameID: PingoGameID
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var primary = 50.0
    @State private var secondary = 75.0

    var body: some View {
        VStack(spacing: 12) {
            scoreHeader

            stage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !state.lastSummary.isEmpty {
                Text(state.lastSummary.uppercased())
                    .font(.caption.weight(.heavy))
                    .tracking(0.8)
                    .foregroundStyle(.black.opacity(0.48))
            }

            if canMove {
                controls
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .onAppear(perform: configureDefaults)
        .onChange(of: gameID) { _ in configureDefaults() }
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.42))
            }
            Spacer()
            Text("\(score(player))  –  \(score(1 - player))")
                .font(.title2.bold().monospacedDigit())
        }
        .foregroundStyle(.black.opacity(0.72))
    }

    @ViewBuilder
    private var stage: some View {
        switch gameID {
        case .bowling:
            bowlingStage
        case .penaltyShootout:
            penaltyStage
        case .archery:
            archeryStage
        case .airHockey:
            airHockeyStage
        case .miniRacing:
            racingStage
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var controls: some View {
        if gameID == .penaltyShootout {
            penaltyControls
        } else {
            sliderRow(title: primaryLabel, value: $primary)
            sliderRow(title: secondaryLabel, value: $secondary)
            Button {
                onMove(.init(primary: Int(primary.rounded()), secondary: Int(secondary.rounded())))
            } label: {
                Label(actionTitle, systemImage: actionIcon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.pingoPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var bowlingStage: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.78, green: 0.58, blue: 0.34), Color(red: 0.52, green: 0.30, blue: 0.17)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.20), radius: 10, y: 5)

                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width * 0.18, y: proxy.size.height))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.39, y: 0))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.61, y: 0))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.82, y: proxy.size.height))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.92, green: 0.75, blue: 0.49))

                VStack(spacing: 3) {
                    HStack(spacing: 8) {
                        pin; pin; pin; pin
                    }
                    HStack(spacing: 8) {
                        pin; pin; pin
                    }
                    HStack(spacing: 8) {
                        pin; pin
                    }
                    pin
                }
                .scaleEffect(0.66)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.22)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.21, green: 0.23, blue: 0.34), Color.black],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 38
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 3) {
                            Circle().fill(.black.opacity(0.55)).frame(width: 6, height: 6)
                            Circle().fill(.black.opacity(0.55)).frame(width: 6, height: 6)
                        }
                        .padding(10)
                    }
                    .frame(width: 70, height: 70)
                    .position(
                        x: proxy.size.width * CGFloat(0.18 + primary / 100 * 0.64),
                        y: proxy.size.height * 0.78
                    )
                    .shadow(color: .black.opacity(0.28), radius: 5, y: 3)
            }
        }
    }

    private var pin: some View {
        VStack(spacing: -3) {
            Circle().fill(.white).frame(width: 12, height: 12)
            Capsule().fill(.white).frame(width: 16, height: 32)
                .overlay(alignment: .top) { Rectangle().fill(.red).frame(height: 4).padding(.top, 4) }
        }
    }

    private var penaltyStage: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.22, green: 0.68, blue: 0.33), Color(red: 0.08, green: 0.42, blue: 0.19)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Rectangle()
                    .stroke(.white.opacity(0.82), lineWidth: 4)
                    .frame(width: proxy.size.width * 0.72, height: proxy.size.height * 0.42)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.28)

                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(0.24))
                        .frame(width: 2, height: proxy.size.height * 0.42)
                        .position(x: proxy.size.width * (0.32 + CGFloat(index) * 0.18), y: proxy.size.height * 0.28)
                }

                Image(systemName: "figure.soccer")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.36)

                Circle()
                    .fill(.white)
                    .overlay { Image(systemName: "soccerball").font(.title2).foregroundStyle(.black) }
                    .frame(width: 50, height: 50)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.80)
            }
        }
    }

    private var archeryStage: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.84, green: 0.83, blue: 0.72), Color(red: 0.55, green: 0.68, blue: 0.49)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                ForEach(Array([0.82, 0.64, 0.46, 0.28, 0.12].enumerated()), id: \.offset) { index, fraction in
                    Circle()
                        .fill(targetColor(index))
                        .frame(width: proxy.size.width * fraction, height: proxy.size.width * fraction)
                }

                Circle()
                    .fill(Color.black.opacity(0.78))
                    .frame(width: 12, height: 12)
                    .offset(
                        x: CGFloat((primary - 50) / 50) * proxy.size.width * 0.34,
                        y: CGFloat((secondary - 50) / 50) * proxy.size.width * 0.34
                    )
                    .overlay { Circle().stroke(.white, lineWidth: 2) }
            }
        }
        .aspectRatio(1.25, contentMode: .fit)
    }

    private var airHockeyStage: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.91, green: 0.95, blue: 0.97))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.blue.opacity(0.62), lineWidth: 6)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

                Rectangle()
                    .fill(Color.red.opacity(0.50))
                    .frame(height: 2)
                Circle()
                    .stroke(Color.blue.opacity(0.44), lineWidth: 2)
                    .frame(width: 82, height: 82)

                Capsule()
                    .fill(Color.red.opacity(0.80))
                    .frame(width: proxy.size.width * 0.34, height: 8)
                    .position(x: proxy.size.width / 2, y: 12)
                Capsule()
                    .fill(Color.blue.opacity(0.80))
                    .frame(width: proxy.size.width * 0.34, height: 8)
                    .position(x: proxy.size.width / 2, y: proxy.size.height - 12)

                Circle()
                    .fill(Color.red)
                    .frame(width: 54, height: 54)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.22)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 54, height: 54)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.78)
                Circle()
                    .fill(.black)
                    .frame(width: 32, height: 32)
                    .position(
                        x: proxy.size.width * CGFloat(0.12 + primary / 100 * 0.76),
                        y: proxy.size.height * 0.54
                    )
            }
        }
    }

    private var racingStage: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.56, blue: 0.24), Color(red: 0.12, green: 0.32, blue: 0.14)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 80, style: .continuous)
                    .stroke(Color(red: 0.19, green: 0.20, blue: 0.22), lineWidth: 64)
                    .padding(42)
                RoundedRectangle(cornerRadius: 80, style: .continuous)
                    .stroke(.white.opacity(0.76), style: StrokeStyle(lineWidth: 2, dash: [9, 9]))
                    .padding(42)

                car(color: .red)
                    .position(x: proxy.size.width * raceX(player), y: proxy.size.height * 0.64)
                car(color: .blue)
                    .position(x: proxy.size.width * raceX(1 - player), y: proxy.size.height * 0.76)

                VStack(spacing: 1) {
                    Text("\(progress(player))m")
                        .font(.title2.bold().monospacedDigit())
                    Text("OF 100m")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(.white.opacity(0.92))
            }
        }
    }

    private func car(color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(color).frame(width: 40, height: 21)
            Circle().fill(.black).frame(width: 8, height: 8).offset(x: -12, y: 10)
            Circle().fill(.black).frame(width: 8, height: 8).offset(x: 12, y: 10)
        }
        .shadow(color: .black.opacity(0.24), radius: 3, y: 2)
    }

    private var penaltyControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                ForEach(0..<5, id: \.self) { lane in
                    Button {
                        primary = Double(lane)
                    } label: {
                        Text(penaltySymbol(lane))
                            .font(.headline)
                            .foregroundStyle(Int(primary.rounded()) == lane ? .white : .black.opacity(0.60))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                Int(primary.rounded()) == lane ? Color.pingoPrimary : Color.white.opacity(0.48),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            sliderRow(title: "Power", value: $secondary)

            Button {
                onMove(.init(primary: Int(primary.rounded()), secondary: Int(secondary.rounded())))
            } label: {
                Label("Take Penalty", systemImage: "soccerball")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.pingoPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func sliderRow(title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black.opacity(0.56))
                .frame(width: 58, alignment: .leading)
            Slider(value: value, in: 0...100, step: 1)
                .tint(Color.pingoPrimary)
            Text("\(Int(value.wrappedValue.rounded()))")
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(.black.opacity(0.50))
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func configureDefaults() {
        switch gameID {
        case .bowling:
            primary = 50; secondary = 82
        case .penaltyShootout:
            primary = 2; secondary = 75
        case .archery:
            primary = 50; secondary = 50
        case .airHockey:
            primary = 50; secondary = 75
        case .miniRacing:
            primary = 82; secondary = 50
        default:
            primary = 50; secondary = 75
        }
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func progress(_ index: Int) -> Int {
        guard state.positions.indices.contains(index), let value = state.positions[index].first else { return 0 }
        return value
    }

    private func raceX(_ index: Int) -> CGFloat {
        let value = min(100, max(0, progress(index)))
        return 0.18 + CGFloat(value) / 100 * 0.64
    }

    private func targetColor(_ index: Int) -> Color {
        switch index {
        case 0: return .white
        case 1: return .black
        case 2: return .blue
        case 3: return .red
        default: return .yellow
        }
    }

    private func penaltySymbol(_ lane: Int) -> String {
        switch lane {
        case 0: return "↙︎"
        case 1: return "←"
        case 2: return "↑"
        case 3: return "→"
        default: return "↘︎"
        }
    }

    private var title: String {
        switch gameID {
        case .bowling: return "BOWLING"
        case .penaltyShootout: return "PENALTY SHOOTOUT"
        case .archery: return "ARCHERY"
        case .airHockey: return "AIR HOCKEY"
        case .miniRacing: return "MINI RACING"
        default: return "PINGO"
        }
    }

    private var subtitle: String {
        switch gameID {
        case .bowling: return "5 rolls each"
        case .penaltyShootout: return "5 penalties each"
        case .archery: return "5 arrows each"
        case .airHockey: return "First through 7 turns"
        case .miniRacing: return "Race to 100m"
        default: return "Your turn"
        }
    }

    private var primaryLabel: String {
        switch gameID {
        case .bowling: return "Aim"
        case .archery: return "Horizontal"
        case .airHockey: return "Lane"
        case .miniRacing: return "Throttle"
        default: return "Aim"
        }
    }

    private var secondaryLabel: String {
        switch gameID {
        case .archery: return "Vertical"
        case .miniRacing: return "Steering"
        default: return "Power"
        }
    }

    private var actionTitle: String {
        switch gameID {
        case .bowling: return "Roll"
        case .archery: return "Shoot Arrow"
        case .airHockey: return "Shoot Puck"
        case .miniRacing: return "Race Turn"
        default: return "Send Move"
        }
    }

    private var actionIcon: String {
        switch gameID {
        case .bowling: return "circle.fill"
        case .archery: return "scope"
        case .airHockey: return "circle.circle.fill"
        case .miniRacing: return "flag.checkered"
        default: return "paperplane.fill"
        }
    }
}
