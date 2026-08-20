import PingoCore
import SwiftUI

// Phase 1 compatibility helpers kept local to the Mini Golf overhaul.
// The core engine exposes this geometry as PingoMiniGolfRect; the Phase 1
// presentation uses the shorter name without changing the shared game-state contract.
typealias PingoRect = PingoMiniGolfRect

@MainActor
func controlRow<Control: View>(
    title: String,
    value: Int,
    suffix: String,
    @ViewBuilder control: () -> Control
) -> some View {
    HStack(spacing: 10) {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.black.opacity(0.56))
            .frame(width: 48, alignment: .leading)
        control()
            .tint(Color.pingoPrimary)
        Text("\(value)\(suffix)")
            .font(.caption.monospacedDigit().weight(.bold))
            .foregroundStyle(.black.opacity(0.50))
            .frame(width: 48, alignment: .trailing)
    }
}

@MainActor
func sendButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Label(title, systemImage: icon)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.pingoPrimary, in: Capsule())
    }
}
