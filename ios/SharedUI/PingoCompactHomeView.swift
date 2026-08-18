import SwiftUI

struct PingoCompactHomeView: View {
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            ZStack {
                Color.pingoMessagesChrome
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    Capsule()
                        .fill(.white.opacity(0.24))
                        .frame(width: 42, height: 5)

                    HStack(spacing: 12) {
                        PingoMark(size: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pingo")
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Opening games…")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.54))
                        }

                        Spacer()

                        Image(systemName: "chevron.up")
                            .font(.headline.bold())
                            .foregroundStyle(.white.opacity(0.78))
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.vertical, 10)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Pingo games")
    }
}
