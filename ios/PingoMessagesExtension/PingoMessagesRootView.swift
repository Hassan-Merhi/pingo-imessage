import Messages
import PingoCore
import SwiftUI

struct PingoMessagesRootView: View {
    @ObservedObject var model: MessagesExtensionModel
    let onRequestExpanded: () -> Void
    let onChallenge: (PingoGameID) -> Void
    let onAccept: () -> Void
    let onResign: () -> Void

    var body: some View {
        Group {
            if model.presentationStyle == .compact {
                PingoCompactHomeView(onOpen: onRequestExpanded)
            } else {
                NavigationStack {
                    Group {
                        if let payload = model.incomingPayload {
                            PingoIncomingMatchView(
                                payload: payload,
                                localProfile: model.profile,
                                onAccept: onAccept,
                                onResign: onResign,
                                onClose: model.clearIncomingMatch
                            )
                        } else {
                            PingoHomeView(onChallenge: onChallenge)
                        }
                    }
                    .navigationTitle("Pingo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                model.isProfilePresented = true
                            } label: {
                                Image(systemName: "person.crop.circle")
                            }
                            .accessibilityLabel("Pingo profile")
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let status = model.statusMessage, model.presentationStyle == .expanded {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $model.isProfilePresented) {
            PingoProfileView(profile: model.profile) { username, avatar in
                try model.updateProfile(username: username, avatar: avatar)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.presentationStyle)
    }
}
