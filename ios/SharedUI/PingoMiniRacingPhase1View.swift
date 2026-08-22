import PingoCore
import SwiftUI

struct PingoMiniRacingPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var steering = 50.0
    @State private var throttle = 72.0
    @State private var dragStart: CGPoint?
    @State private var isDriving = false

    private var opponent: Int { 1 - player }

    var body: some View {
        VStack(spacing: 12) {
            header

            track
                .frame(maxWidth: .infinity)
                .aspectRatio(1.36, contentMode: .fit)
                .contentShape(Rectangle())
                .gesture(canMove ? drivingGesture : nil)

            if !state.lastSummary.isEmpty {
                resultBanner
            }

            if canMove {
                controlsHint
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            distanceChip(title: "YOU", distance: progress(player), emphasized: true)
            VStack(spacing: 2) {
                Text("MINI RACING")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("RUN \(runNumber) OF 8")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
            }
            .frame(maxWidth: .infinity)
            distanceChip(title: "RIVAL", distance: progress(opponent), emphasized: false)
        }
        .foregroundStyle(.black.opacity(0.76))
    }

    private func distanceChip(title: String, distance: Int, emphasized: Bool) -> some View {
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

    private var track: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let roadX = width * 0.06
            let roadWidth = width * 0.88
            let roadTop = height * 0.20
            let roadHeight = height * 0.59
            let playerY = roadTop + roadHeight * 0.69 + steeringOffset
            let opponentY = roadTop + roadHeight * 0.31

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.24, green: 0.55, blue: 0.23), Color(red: 0.13, green: 0.36, blue: 0.16)], startPoint: .top, endPoint: .bottom))

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
                        Rectangle().fill(.white.opacity(0.14)).frame(width: 1, height: roadHeight * 0.78)
                    }
                    .position(x: markerX, y: roadTop + roadHeight / 2)
                }

                Rectangle().fill(.white.opacity(0.80))
                    .frame(width: 7, height: roadHeight * 0.86)
                    .position(x: roadX + roadWidth * 0.08, y: roadTop + roadHeight / 2)

                finishLine
                    .frame(width: 13, height: roadHeight * 0.88)
                    .position(x: roadX + roadWidth * 0.90, y: roadTop + roadHeight / 2)

                car(color: Color(red: 0.87, green: 0.20, blue: 0.17), label: "RIVAL")
                    .position(x: carX(progress: progress(opponent), roadX: roadX, roadWidth: roadWidth), y: opponentY)

                car(color: Color.pingoPrimary, label: "YOU")
                    .position(x: carX(progress: progress(player), roadX: roadX, roadWidth: roadWidth), y: playerY)
                    .shadow(color: Color.pingoPrimary.opacity(0.38), radius: 7, x: -2)

                if canMove {
                    VStack(spacing: 2) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(isDriving ? "RELEASE TO RACE" : "DRAG TO STEER • FLICK UP TO RACE")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.4)
                    }
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.52), in: Capsule())
                    .position(x: width / 2, y: height * 0.91)
                }
            }
            .clipped()
        }
    }

    private var finishLine: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<2, id: \.self) { column in
                            Rectangle().fill((row + column).isMultiple(of: 2) ? .white : .black)
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func car(color: Color, label: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.78), color], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 43, height: 23)
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.54)).frame(width: 13, height: 11).offset(x: 4)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: -12, y: -13)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: 12, y: -13)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: -12, y: 13)
                Capsule().fill(.black).frame(width: 9, height: 4).offset(x: 12, y: 13)
            }
        }
    }

    private var resultBanner: some View {
        HStack(spacing: 7) {
            Image(systemName: "flag.fill").font(.caption.bold())
            Text(state.lastSummary.uppercased()).font(.caption.weight(.heavy)).tracking(0.5)
        }
        .foregroundStyle(Color.pingoPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.pingoPrimary.opacity(0.09), in: Capsule())
    }

    private var controlsHint: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DIRECT DRIVE")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("Steering \(steeringLabel)  •  Throttle \(Int(throttle.rounded()))%")
                    .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.black.opacity(0.48))
            }
            Spacer()
            Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.pingoPrimary)
        }
        .padding(.horizontal, 4)
    }

    private var drivingGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                if dragStart == nil { dragStart = value.startLocation }
                isDriving = true
                let horizontal = value.translation.width
                steering = min(100, max(0, 50 + Double(horizontal) * 0.75))
                let upward = max(0, -value.translation.height)
                throttle = min(100, max(35, 45 + Double(upward) * 0.55))
            }
            .onEnded { value in
                defer {
                    dragStart = nil
                    isDriving = false
                }
                let upward = max(0, -value.translation.height)
                guard upward >= 36 else { return }
                let finalThrottle = min(100, max(35, Int((45 + Double(upward) * 0.55).rounded())))
                let finalSteering = min(100, max(0, Int(steering.rounded())))
                throttle = Double(finalThrottle)
                onMove(.init(primary: finalThrottle, secondary: finalSteering))
            }
    }

    private func progress(_ index: Int) -> Int {
        guard state.positions.indices.contains(index), let value = state.positions[index].first else { return 0 }
        return min(100, max(0, value))
    }

    private var runNumber: Int {
        guard state.attempts.indices.contains(player) else { return 1 }
        return min(8, max(1, state.attempts[player] + 1))
    }

    private func carX(progress: Int, roadX: CGFloat, roadWidth: CGFloat) -> CGFloat {
        roadX + roadWidth * (0.08 + 0.82 * CGFloat(progress) / 100)
    }

    private var steeringOffset: CGFloat {
        CGFloat((steering - 50) / 50) * 7
    }

    private var steeringLabel: String {
        let value = Int(steering.rounded())
        if value < 44 { return "LEFT \(50 - value)" }
        if value > 56 { return "RIGHT \(value - 50)" }
        return "CENTER"
    }
}
