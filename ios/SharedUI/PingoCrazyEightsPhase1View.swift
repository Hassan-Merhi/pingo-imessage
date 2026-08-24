import PingoCore
import SwiftUI

struct PingoCrazyEightsPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var draggedCardIndex: Int?
    @State private var dragOffset: CGSize = .zero

    private var opponent: Int { 1 - player }

    private var localHand: [Int] {
        state.hands.indices.contains(player) ? state.hands[player] : []
    }

    private var opponentCount: Int {
        state.hands.indices.contains(opponent) ? state.hands[opponent].count : 0
    }

    private var playableCount: Int {
        localHand.filter { PingoExtraGameEngine.isPlayableCard($0, on: state.topCard) }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            scoreStrip
            tableSurface
            handSection
            statusRibbon
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var scoreStrip: some View {
        HStack(spacing: 10) {
            countChip(label: "YOUR HAND", value: localHand.count, highlighted: canMove)

            VStack(spacing: 2) {
                Text("CRAZY EIGHTS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.05)
                    .foregroundStyle(.black.opacity(0.38))
                Text(canMove ? "YOUR TURN" : "TABLE LIVE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.68))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            countChip(label: "RIVAL", value: opponentCount, highlighted: false)
        }
    }

    private var tableSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.34, blue: 0.24),
                            Color(red: 0.04, green: 0.23, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)

            VStack(spacing: 15) {
                opponentHand

                HStack(spacing: 24) {
                    drawPile
                    discardPile
                }

                HStack(spacing: 7) {
                    Image(systemName: "hand.draw.fill")
                    Text(playableCount > 0 ? "DRAG A CARD UP TO PLAY" : "NO MATCH • TAP DRAW")
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(.white.opacity(0.72))
            }
            .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 268)
    }

    private var opponentHand: some View {
        VStack(spacing: 6) {
            Text("OPPONENT")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.48))

            HStack(spacing: -12) {
                ForEach(0..<min(max(opponentCount, 1), 7), id: \.self) { index in
                    cardBack
                        .rotationEffect(.degrees(Double(index - min(opponentCount, 7) / 2) * 2.2))
                }
            }
            .frame(height: 62)
        }
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.24, blue: 0.50), Color(red: 0.09, green: 0.12, blue: 0.30)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 2)
                    .padding(3)
            }
            .overlay {
                Image(systemName: "8.circle.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(width: 44, height: 60)
            .shadow(color: .black.opacity(0.20), radius: 3, y: 2)
    }

    private var drawPile: some View {
        Button {
            guard canMove else { return }
            onMove(.init(primary: -1))
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    cardBack.offset(x: 5, y: -4)
                    cardBack
                }
                .frame(width: 50, height: 64)

                Text("DRAW")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(canMove ? 0.82 : 0.40))
            }
        }
        .buttonStyle(.plain)
        .disabled(!canMove)
        .accessibilityLabel("Draw a card")
    }

    private var discardPile: some View {
        VStack(spacing: 6) {
            cardFace(card: state.topCard, emphasized: true)
                .rotationEffect(.degrees(-3))
            Text("DISCARD")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var handSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("YOUR CARDS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.black.opacity(0.42))
                Spacer()
                Text("\(playableCount) playable")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black.opacity(0.36))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(localHand.enumerated()), id: \.offset) { index, card in
                        let playable = canMove && PingoExtraGameEngine.isPlayableCard(card, on: state.topCard)
                        handCard(card: card, index: index, playable: playable)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 12)
            }
        }
    }

    private func handCard(card: Int, index: Int, playable: Bool) -> some View {
        let isDragging = draggedCardIndex == index

        return cardFace(card: card, emphasized: playable)
            .opacity(playable || !canMove ? 1 : 0.48)
            .scaleEffect(isDragging ? 1.12 : (playable ? 1.03 : 1))
            .offset(isDragging ? dragOffset : .zero)
            .zIndex(isDragging ? 20 : 0)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onTapGesture {
                guard playable else { return }
                play(card)
            }
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { value in
                        guard playable else { return }
                        draggedCardIndex = index
                        dragOffset = CGSize(
                            width: value.translation.width * 0.45,
                            height: min(0, value.translation.height)
                        )
                    }
                    .onEnded { value in
                        guard playable else {
                            resetDrag()
                            return
                        }

                        let committed = value.translation.height < -42 && abs(value.translation.width) < 110
                        if committed {
                            play(card)
                        }
                        resetDrag()
                    }
            )
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: dragOffset)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: draggedCardIndex)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Play \(PingoExtraGameEngine.cardLabel(card))")
            .accessibilityHint(playable ? "Double tap or drag upward to play this card" : "This card cannot be played on the current discard")
            .accessibilityAddTraits(playable ? .isButton : [])
            .accessibilityAction {
                guard playable else { return }
                play(card)
            }
    }

    private func play(_ card: Int) {
        guard canMove, PingoExtraGameEngine.isPlayableCard(card, on: state.topCard) else { return }
        onMove(.init(primary: card))
    }

    private func resetDrag() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
            draggedCardIndex = nil
            dragOffset = .zero
        }
    }

    private func cardFace(card: Int, emphasized: Bool) -> some View {
        let label = PingoExtraGameEngine.cardLabel(card)
        let redSuit = label.contains("♥") || label.contains("♦")

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(emphasized ? 0.18 : 0.10), radius: emphasized ? 6 : 3, y: 3)

            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(redSuit ? Color.red.opacity(0.82) : Color.black.opacity(0.78))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                if label.contains("8") {
                    Text("WILD")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(Color.pingoPrimary)
                }
            }
        }
        .frame(width: 58, height: 82)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(emphasized ? Color.pingoPrimary.opacity(0.56) : Color.black.opacity(0.08), lineWidth: emphasized ? 2 : 1)
        }
    }

    @ViewBuilder
    private var statusRibbon: some View {
        if !state.lastSummary.isEmpty {
            HStack(spacing: 7) {
                Image(systemName: "rectangle.stack.fill")
                Text(state.lastSummary.uppercased())
            }
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(0.75)
            .foregroundStyle(.black.opacity(0.48))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.white.opacity(0.52), in: Capsule())
        } else {
            Text(canMove ? "TAP OR DRAG A PLAYABLE CARD • EIGHTS ARE WILD" : "WAITING FOR THE NEXT TURN")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.black.opacity(0.36))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }

    private func countChip(label: String, value: Int, highlighted: Bool) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.black.opacity(0.34))
            Text("\(value)")
                .font(.system(size: 24, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.black.opacity(0.72))
        }
        .frame(width: 82)
        .padding(.vertical, 7)
        .background(highlighted ? Color.pingoPrimary.opacity(0.16) : Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}
