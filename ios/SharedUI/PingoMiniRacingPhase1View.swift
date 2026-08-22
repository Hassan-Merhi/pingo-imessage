import PingoCore
import SwiftUI

struct PingoMiniRacingPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var throttle = 82.0
    @State private var steering = 50.0

    private var opponent: Int { 1 - player }

    var body: some View {
        VStack(spacing: 12) {
            miniRacingHeader

            miniRacingTrack
                .frame(maxWidth: .infinity)
                .aspectRatio(1.36, contentMode: .fit)

            if !state.lastSummary.isEmpty {
                miniRacingResultBanner
            }

            if canMove {
                miniRacingControls
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var miniRacingHeader: some View {
        HStack(spacing: 10) {
            miniRacingDistanceChip(title: "YOU", distance: miniRacingProgress(player), emphasized: true)

            VStack(spacing: 2) {
                Text("MINI RACING")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("RUN \(miniRacingRunNumber) OF 8")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
            }
            .frame(maxWidth: .infinity)

            miniRacingDistanceChip(title: "RIVAL", distance: miniRacingProgress(opponent), emphasized: false)
        }
        .foregroundStyle(.black.opacity(0.76))
    }

    private func miniRacingDistanceChip(title: String, distance: Int, emphasized: Bool) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.black.opacity(0.42))
            Text("\(distance)m")
                .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(emphasized ? Color.pingoPrimary : .black.opacity(0.68))
        }
        .frame(width: 66)
        .padding(.vertical, 6)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        }
    }

    private var miniRacingTrack: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let roadX = width * 0.06
            let roadWidth = width * 0.88
            let roadTop = height * 0.20
            let roadHeight = height * 0.59
            let playerY = roadTop + roadHeight * 0.69 + miniRacingSteeringOffset
            let opponentY = roadTop + roadHeight * 0.31

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.24, green: 0.55, blue: 0.23),
                                Color(red: 0.13, green: 0.36, blue: 0.16)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                miniRacingFence(width: width, height: height)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.17, green: 0.18, blue: 0.20))
                    .frame(width: roadWidth, height: roadHeight)
                    .position(x: width / 2, y: roadTop + roadHeight / 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.42), lineWidth: 2)
                            .frame(width: roadWidth, height: roadHeight)
                            .position(x: width / 2, y: roadTop + roadHeight / 2)
                    }

                Path { path in
                    path.move(to: CGPoint(x: roadX + 10, y: roadTop + roadHeight / 2))
                    path.addLine(to: CGPoint(x: roadX + roadWidth - 10, y: roadTop + roadHeight / 2))
                }
                .stroke(.white.opacity(0.58), style: StrokeStyle(lineWidth: 2, dash: [10, 9]))

                ForEach([25, 50, 75], id: \.self) { marker in
                    let markerX = roadX + roadWidth * (0.08 + 0.82 * CGFloat(marker) / 100)
                    VStack(spacing: 2) {
                        Text("\(marker)m")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                        Rectangle()
                            .fill(.white.opacity(0.14))
                            .frame(width: 1, height: roadHeight * 0.78)
                    }
                    .position(x: markerX, y: roadTop + roadHeight / 2)
                }

                miniRacingStartLine
                    .frame(width: 7, height: roadHeight * 0.86)
                    .position(x: roadX + roadWidth * 0.08, y: roadTop + roadHeight / 2)

                miniRacingFinishLine
                    .frame(width: 13, height: roadHeight * 0.88)
                    .position(x: roadX + roadWidth * 0.90, y: roadTop + roadHeight / 2)

                miniRacingCar(color: Color(red: 0.87, green: 0.20, blue: 0.17), label: "RIVAL")
                    .position(
                        x: miniRacingCarX(progress: miniRacingProgress(opponent), roadX: roadX, roadWidth: roadWidth),
                        y: opponentY
                    )

                miniRacingCar(color: Color.pingoPrimary, label: "YOU")
                    .position(
                        x: miniRacingCarX(progress: miniRacingProgress(player), roadX: roadX, roadWidth: roadWidth),
                        y: playerY
                    )
                    .shadow(color: Color.pingoPrimary.opacity(0.38), radius: 7, x: -2)

                miniRacingStartLights
                    .position(x: roadX + roadWidth * 0.14, y: roadTop * 0.48)

                VStack(spacing: 1) {
                    Text("100m")
                        .font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit())
                    Text("SPRINT")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                }
                .foregroundStyle(.white.opacity(0.90))
                .position(x: width * 0.82, y: height * 0.10)
            }
            .clipped()
        }
    }

    private func miniRacingFence(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ForEach(0..<18, id: \.self) { _ in
                    Capsule()
                        .fill(.white.opacity(0.28))
                        .frame(width: 2, height: 10)
                }
            }
            Spacer()
            HStack(spacing: 10) {
                ForEach(0..<18, id: \.self) { _ in
                    Capsule()
                        .fill(.white.opacity(0.22))
                        .frame(width: 2, height: 10)
                }
            }
        }
        .frame(width: width * 0.90, height: height * 0.84)
    }

    private var miniRacingStartLine: some View {
        Rectangle()
            .fill(.white.opacity(0.80))
    }

    private var miniRacingFinishLine: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<2, id: \.self) { column in
                            Rectangle()
                                .fill((row + column).isMultiple(of: 2) ? .white : .black)
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var miniRacingStartLights: some View {
        HStack(spacing: 5) {
            Circle().fill(Color.red.opacity(0.92)).frame(width: 10, height: 10)
            Circle().fill(Color.yellow.opacity(0.92)).frame(width: 10, height: 10)
            Circle().fill(Color.green.opacity(0.92)).frame(width: 10, height: 10)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(.black.opacity(0.72), in: Capsule())
    }

    private func miniRacingCar(color: Color, label: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.78), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 43, height: 23)
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.54))
                    .frame(width: 13, height: 11)
                    .offset(x: 4)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: -12, y: -13)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: 12, y: -13)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: -12, y: 13)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: 12, y: 13)
            }
        }
    }

    private var miniRacingResultBanner: some View {
        HStack(spacing: 7) {
            Image(systemName: "flag.fill")
                .font(.caption.bold())
            Text(state.lastSummary.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(0.5)
        }
        .foregroundStyle(Color.pingoPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.pingoPrimary.opacity(0.09), in: Capsule())
    }

    private var miniRacingControls: some View {
        VStack(spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("RACE SETUP")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(0.8)
                    Text("Keep it near the sweet spot for maximum distance.")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.42))
                }
                Spacer()
            }

            miniRacingSlider(title: "THROTTLE", value: $throttle, valueText: "\(Int(throttle.rounded()))%")
            miniRacingSlider(title: "STEERING", value: $steering, valueText: miniRacingSteeringLabel)

            Button {
                onMove(.init(primary: Int(throttle.rounded()), secondary: Int(steering.rounded())))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                    Text("Race Turn")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.pingoPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Race turn with throttle \(Int(throttle.rounded())) and steering \(Int(steering.rounded()))")
        }
    }

    private func miniRacingSlider(title: String, value: Binding<Double>, valueText: String) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.8)
                Spacer()
                Text(valueText)
                    .font(.caption.bold().monospacedDigit())
            }
            .foregroundStyle(.black.opacity(0.62))

            Slider(value: value, in: 0...100, step: 1)
                .tint(.pingoPrimary)
        }
    }

    private func miniRacingProgress(_ index: Int) -> Int {
        guard state.positions.indices.contains(index),
              let value = state.positions[index].first else { return 0 }
        return min(100, max(0, value))
    }

    private var miniRacingRunNumber: Int {
        guard state.attempts.indices.contains(player) else { return 1 }
        return min(8, max(1, state.attempts[player] + 1))
    }

    private func miniRacingCarX(progress: Int, roadX: CGFloat, roadWidth: CGFloat) -> CGFloat {
        roadX + roadWidth * (0.08 + 0.82 * CGFloat(progress) / 100)
    }

    private var miniRacingSteeringOffset: CGFloat {
        CGFloat((steering - 50) / 50) * 7
    }

    private var miniRacingSteeringLabel: String {
        let value = Int(steering.rounded())
        if value < 44 { return "LEFT \(50 - value)" }
        if value > 56 { return "RIGHT \(value - 50)" }
        return "CENTER"
    }
}
