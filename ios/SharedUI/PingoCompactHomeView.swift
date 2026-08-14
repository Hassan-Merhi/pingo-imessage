import PingoCore
import SwiftUI

struct PingoCompactHomeView: View {
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PingoMark(size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("Pingo")
                    .font(.headline)
                    .foregroundStyle(Color.pingoInk)
                Text("10 games ready to challenge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button("Play", action: onOpen)
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
        }
        .padding(12)
        .background(Color.pingoSurface)
        .accessibilityElement(children: .contain)
    }
}
