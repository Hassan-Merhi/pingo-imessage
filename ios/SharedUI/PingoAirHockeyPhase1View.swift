import PingoCore
import SwiftUI

struct PingoAirHockeyPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var lane = 50.0
    @State private var power = 75.0

    var body: some View {
        VStack(spacing: 12) {
            header

            rink
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statusRibbon

            if canMove {
                controls
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AIR HOCKEY")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("FIRST TO 7 SHOTS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.44))
            }

            Spacer()

            HStack(spacing: 8) {
                scoreChip(title: "YOU", score: score(player), attempts: attempts(player), emphasized: true)
                scoreChip(title: "THEM", score: score(1 - player), attempts: attempts(1 - player), emphasized: false)
            }
        }
        .foregroundStyle(.black.opacity(0.78))
    }

    private var rink: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.08, blue: 0.13),
                                Color(red: 0.08, green: 0.14, blue: 0.20),
                                Color(red: 0.03, green: 0.06, blue: 0.10)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.28), radius: 12, y: 6)

                airTable(size: size)
                centerDetails(size: size)
                goals(size: size)
                mallets(size: size)
                puck(size: size)
                aimGuide(size: size)

                VStack {
                    HStack {
                        Text("ARCADE TABLE")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(.white.opacity(0.72))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.30), in: Capsule())
                        Spacer()
                    }
                    Spacer()
                }
                .padding(18)
            }
        }
    }

    private func airTable(size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.96), Color(red: 0.84, green: 0.94, blue: 0.98)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.cyan.opacity(0.42), lineWidth: 3)
            }
            .padding(.horizontal, size.width * 0.08)
            .padding(.vertical, size.height * 0.05)
    }

    private func centerDetails(size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.cyan.opacity(0.32))
                .frame(width: 2, height: size.height * 0.80)

            Circle()
                .stroke(Color.cyan.opacity(0.34), lineWidth: 2)
                .frame(width: min(size.width, size.height) * 0.28)

            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 12, height: 12)
        }
        .allowsHitTesting(false)
    }

    private func goals(size: CGSize) -> some View {
        ZStack {
            Capsule()
                .fill(Color.pink.opacity(0.82))
                .frame(width: 8, height: size.height * 0.23)
                .position(x: size.width * 0.09, y: size.height * 0.50)

            Capsule()
                .fill(Color.cyan.opacity(0.86))
                .frame(width: 8, height: size.height * 0.23)
                .position(x: size.width * 0.91, y: size.height * 0.50)
        }
    }

    private func mallets(size: CGSize) -> some View {
        ZStack {
            mallet(color: .pink)
                .position(x: size.width * 0.26, y: size.height * 0.50)

            mallet(color: .cyan)
                .position(x: size.width * 0.74, y: size.height * 0.50)
        }
    }

    private func mallet(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.92))
                .frame(width: 46, height: 46)
                .shadow(color: .black.opacity(0.20), radius: 4, y: 3)
            Circle()
                .stroke(.white.opacity(0.7), lineWidth: 3)
                .frame(width: 34, height: 34)
            Circle()
                .fill(.white.opacity(0.20))
                .frame(width: 14, height: 14)
        }
    }

    private func puck(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.88))
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.28), radius: 4, y: 2)
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 20, height: 20)
        }
        .position(x: size.width * 0.42, y: size.height * 0.50)
    }

    private func aimGuide(size: CGSize) -> some View {
        let start = CGPoint(x: size.width * 0.43, y: size.height * 0.50)
        let laneOffset = CGFloat((lane - 50) / 50) * size.height * 0.22
        let end = CGPoint(x: size.width * 0.87, y: size.height * 0.50 + laneOffset)

        return ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(
                Color.pingoPrimary.opacity(canMove ? 0.72 : 0.30),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 6])
            )

            Circle()
                .stroke(Color.pingoPrimary.opacity(canMove ? 0.8 : 0.35), lineWidth: 2)
                .frame(width: 24, height: 24)
                .position(end)
        }
        .allowsHitTesting(false)
    }

    private var statusRibbon: some View {
        HStack(spacing: 8) {
            Image(systemName: state.lastScore == 1 ? "burst.fill" : "circle.fill")
                .font(.caption)
                .foregroundStyle(state.lastScore == 1 ? Color.green : Color.secondary)

            Text(statusText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
                .lineLimit(1)

            Spacer()

            Text("SHOT \(min(7, attempts(player) + 1))/7")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.42))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.72), in: Capsule())
    }

    private var controls: some View {
        VStack(spacing: 9) {
            valueRow(title: "Lane", value: lane)
            Slider(value: $lane, in: 0...100, step: 1)
                .tint(.pingoPrimary)

            valueRow(title: "Power", value: power)
            Slider(value: $power, in: 0...100, step: 1)
                .tint(.pingoPrimary)

            Button("Shoot Puck") {
                onMove(.init(primary: Int(lane.rounded()), secondary: Int(power.rounded())))
            }
            .buttonStyle(.borderedProminent)
            .tint(.pingoPrimary)
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func scoreChip(title: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.40))
            Text("\(score)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .monospacedDigit()
            Text("\(attempts)/7")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.34))
        }
        .frame(width: 48)
        .padding(.vertical, 6)
        .background(emphasized ? Color.pingoPrimary.opacity(0.16) : Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func valueRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
            Spacer()
            Text("\(Int(value.rounded()))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        if !state.lastSummary.isEmpty {
            return state.lastSummary
        }
        return canMove ? "Line up the puck and take your shot." : "Table locked while the turn changes."
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }
}
