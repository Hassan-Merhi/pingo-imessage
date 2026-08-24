import PingoCore
import SwiftUI

struct PingoLudoPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var draggingPiece: Int?
    @State private var dragOffset: CGSize = .zero

    private var opponent: Int { 1 - player }

    private var die: Int {
        PingoExtraGameEngine.ludoDie(for: state)
    }

    private var localPieces: [Int] {
        positions(for: player)
    }

    private var opponentPieces: [Int] {
        positions(for: opponent)
    }

    private var legalPieces: [Int] {
        localPieces.indices.filter { index in
            let position = localPieces[index]
            return position < 24 && (position >= 0 || die == 6)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            statusStrip
            boardSurface
            piecePanel
            resultRibbon
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var statusStrip: some View {
        HStack(spacing: 9) {
            progressChip(label: "YOU", pieces: localPieces, highlighted: canMove)

            VStack(spacing: 2) {
                Text("LUDO")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.black.opacity(0.38))
                Text(canMove ? "MOVE A PIECE" : "BOARD LIVE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.70))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            progressChip(label: "RIVAL", pieces: opponentPieces, highlighted: false)
        }
    }

    private var boardSurface: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let boardSize = CGSize(width: size, height: size)

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.88, blue: 0.68),
                                Color(red: 0.84, green: 0.77, blue: 0.58)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.48), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 6)

                boardCross
                    .frame(width: size * 0.48, height: size * 0.48)

                ForEach(0..<24, id: \.self) { index in
                    trackCell(index: index)
                        .position(trackPoint(index: index, in: boardSize))
                }

                if let draggingPiece,
                   legalPieces.contains(draggingPiece),
                   localPieces.indices.contains(draggingPiece) {
                    destinationGuide(for: draggingPiece, in: boardSize)
                }

                ForEach(localPieces.indices, id: \.self) { index in
                    if (0..<24).contains(localPieces[index]) {
                        localPieceControl(index: index, in: boardSize)
                    }
                }

                ForEach(opponentPieces.indices, id: \.self) { index in
                    if (0..<24).contains(opponentPieces[index]) {
                        pieceMarker(number: index + 1, isLocal: false)
                            .position(piecePoint(position: opponentPieces[index], pieceIndex: index, in: boardSize))
                    }
                }

                centerDie

                VStack {
                    HStack {
                        yardBadge(title: "YOUR YARD", count: localPieces.filter { $0 < 0 }.count, local: true)
                        Spacer()
                        yardBadge(title: "RIVAL YARD", count: opponentPieces.filter { $0 < 0 }.count, local: false)
                    }
                    Spacer()
                    HStack {
                        homeBadge(title: "YOUR HOME", count: localPieces.filter { $0 >= 24 }.count, local: true)
                        Spacer()
                        homeBadge(title: "RIVAL HOME", count: opponentPieces.filter { $0 >= 24 }.count, local: false)
                    }
                }
                .padding(size * 0.055)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var boardCross: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.42))
                .frame(width: 74)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.42))
                .frame(height: 74)
            Circle()
                .fill(Color.black.opacity(0.07))
                .frame(width: 86, height: 86)
        }
    }

    private var centerDie: some View {
        VStack(spacing: 2) {
            Text("🎲")
                .font(.system(size: 24))
            Text("\(die)")
                .font(.system(size: 27, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.black.opacity(0.76))
        }
        .frame(width: 70, height: 70)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Deterministic roll \(die)")
    }

    private func trackCell(index: Int) -> some View {
        let localHere = localPieces.contains(index)
        let rivalHere = opponentPieces.contains(index)

        return Circle()
            .fill(localHere ? Color.pingoPrimary.opacity(0.24) : (rivalHere ? Color.red.opacity(0.20) : Color.white.opacity(0.72)))
            .overlay {
                Circle().stroke(Color.black.opacity(0.10), lineWidth: 1)
            }
            .frame(width: 25, height: 25)
            .overlay {
                Text("\(index + 1)")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.30))
            }
    }

    private func localPieceControl(index: Int, in size: CGSize) -> some View {
        let legal = canMove && legalPieces.contains(index)
        let isDragging = draggingPiece == index
        let position = localPieces[index]

        return Button {
            submitPiece(index)
        } label: {
            pieceMarker(number: index + 1, isLocal: true)
                .scaleEffect(isDragging ? 1.22 : 1)
                .shadow(color: legal ? Color.pingoPrimary.opacity(0.34) : .clear, radius: legal ? 7 : 0)
        }
        .buttonStyle(.plain)
        .disabled(!legal)
        .opacity(canMove && !legalPieces.contains(index) ? 0.45 : 1)
        .position(piecePoint(position: position, pieceIndex: index, in: size))
        .offset(isDragging ? dragOffset : .zero)
        .animation(.easeOut(duration: 0.12), value: isDragging)
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    guard legal else { return }
                    draggingPiece = index
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard legal, draggingPiece == index else { return }
                    let distance = hypot(value.translation.width, value.translation.height)
                    draggingPiece = nil
                    dragOffset = .zero
                    if distance >= 12 {
                        submitPiece(index)
                    }
                }
        )
        .accessibilityLabel("Piece \(index + 1), \(positionText(position))")
        .accessibilityHint(legal ? "Tap or drag to move this piece by \(die)" : "This piece cannot move on this roll")
    }

    private func destinationGuide(for index: Int, in size: CGSize) -> some View {
        let position = localPieces[index]
        let destination = destinationPosition(from: position)
        let start = piecePoint(position: max(position, 0), pieceIndex: index, in: size)
        let end = destination >= 24
            ? CGPoint(x: size.width * 0.31, y: size.height * 0.73)
            : trackPoint(index: destination, in: size)

        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(Color.pingoPrimary.opacity(0.62), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5]))
        .overlay {
            Circle()
                .fill(Color.pingoPrimary.opacity(0.18))
                .overlay { Circle().stroke(Color.pingoPrimary.opacity(0.62), lineWidth: 2) }
                .frame(width: 34, height: 34)
                .position(end)
        }
        .allowsHitTesting(false)
    }

    private func pieceMarker(number: Int, isLocal: Bool) -> some View {
        Circle()
            .fill(isLocal ? Color.pingoPrimary : Color(red: 0.88, green: 0.22, blue: 0.24))
            .overlay { Circle().stroke(Color.white, lineWidth: 2) }
            .overlay {
                Text("\(number)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 25, height: 25)
            .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
    }

    private var piecePanel: some View {
        VStack(spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("DIRECT PIECE CONTROL")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.black.opacity(0.40))
                    Text(canMove ? instructionText : "Waiting for opponent")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.46))
                }
                Spacer()
                Text("ROLL \(die)")
                    .font(.caption.weight(.black).monospacedDigit())
                    .foregroundStyle(.black.opacity(0.62))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.70), in: Capsule())
            }

            HStack(spacing: 8) {
                ForEach(localPieces.indices, id: \.self) { index in
                    let legal = canMove && legalPieces.contains(index)
                    Button {
                        submitPiece(index)
                    } label: {
                        VStack(spacing: 4) {
                            pieceMarker(number: index + 1, isLocal: true)
                            Text(positionText(localPieces[index]))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.black.opacity(0.68))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(
                            legal ? Color.pingoPrimary.opacity(0.12) : Color.white.opacity(0.54),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!legal)
                    .opacity(canMove && !legalPieces.contains(index) ? 0.48 : 1)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 8)
                            .onEnded { value in
                                guard legal else { return }
                                let distance = hypot(value.translation.width, value.translation.height)
                                if distance >= 12 { submitPiece(index) }
                            }
                    )
                }
            }

            if canMove && legalPieces.isEmpty {
                Button {
                    onMove(.init(primary: -1))
                } label: {
                    Label("NO LEGAL MOVE — PASS", systemImage: "arrow.turn.up.right")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
            }
        }
        .padding(11)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var resultRibbon: some View {
        if !state.lastSummary.isEmpty {
            HStack(spacing: 7) {
                Image(systemName: "flag.checkered")
                Text(state.lastSummary.uppercased())
                    .lineLimit(1)
            }
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(0.55)
            .foregroundStyle(.black.opacity(0.56))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.54), in: Capsule())
        }
    }

    private var instructionText: String {
        if legalPieces.isEmpty { return "No piece can move on this roll" }
        if die == 6 && localPieces.contains(-1) { return "Tap a yard piece to enter, or drag any legal piece" }
        return "Tap a highlighted piece, or drag it toward its destination"
    }

    private func submitPiece(_ index: Int) {
        guard canMove, legalPieces.contains(index) else { return }
        onMove(.init(primary: index))
    }

    private func destinationPosition(from position: Int) -> Int {
        if position < 0 { return 0 }
        return min(24, position + die)
    }

    private func progressChip(label: String, pieces: [Int], highlighted: Bool) -> some View {
        let homeCount = pieces.filter { $0 >= 24 }.count
        return VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
            Text("\(homeCount)/2 HOME")
                .font(.caption2.weight(.bold).monospacedDigit())
        }
        .foregroundStyle(.black.opacity(highlighted ? 0.72 : 0.48))
        .frame(minWidth: 70)
        .padding(.vertical, 8)
        .background(highlighted ? Color.pingoPrimary.opacity(0.12) : Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func yardBadge(title: String, count: Int, local: Bool) -> some View {
        badge(title: title, value: "\(count)", color: local ? Color.pingoPrimary : Color.red)
    }

    private func homeBadge(title: String, count: Int, local: Bool) -> some View {
        badge(title: title, value: "\(count)/2", color: local ? Color.pingoPrimary : Color.red)
    }

    private func badge(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.caption.weight(.black).monospacedDigit())
            Text(title)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .tracking(0.5)
        }
        .foregroundStyle(color.opacity(0.84))
        .frame(minWidth: 64)
        .padding(.vertical, 5)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func trackPoint(index: Int, in size: CGSize) -> CGPoint {
        let inset = size.width * 0.095
        let span = size.width - inset * 2
        let side = index / 6
        let offset = index % 6
        let t = (CGFloat(offset) + 0.5) / 6

        switch side {
        case 0:
            return CGPoint(x: inset + span * t, y: inset)
        case 1:
            return CGPoint(x: size.width - inset, y: inset + span * t)
        case 2:
            return CGPoint(x: size.width - inset - span * t, y: size.height - inset)
        default:
            return CGPoint(x: inset, y: size.height - inset - span * t)
        }
    }

    private func piecePoint(position: Int, pieceIndex: Int, in size: CGSize) -> CGPoint {
        let base = trackPoint(index: position, in: size)
        let offset: CGFloat = pieceIndex == 0 ? -5 : 5
        return CGPoint(x: base.x + offset, y: base.y + offset)
    }

    private func positions(for index: Int) -> [Int] {
        guard state.positions.indices.contains(index), state.positions[index].count == 2 else {
            return [-1, -1]
        }
        return state.positions[index]
    }

    private func positionText(_ position: Int) -> String {
        if position < 0 { return "Yard" }
        if position >= 24 { return "Home" }
        return "Track \(position + 1)/24"
    }
}
