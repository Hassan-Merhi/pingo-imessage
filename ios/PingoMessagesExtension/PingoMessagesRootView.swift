import Messages
import PingoCore
import SwiftUI

struct PingoMessagesRootView: View {
    @ObservedObject var model: MessagesExtensionModel
    let onRequestExpanded: () -> Void
    let onChallenge: (PingoGameID, PingoSeriesFormat) -> Void
    let onAccept: () -> Void
    let onMoves: ([PingoGameMove]) -> Void
    let onPhysicsMove: (PingoPhysicsMove) -> Void
    let onExtraMove: (PingoExtraGameMove) -> Void
    let onContinueSeries: () -> Void
    let onResign: () -> Void

    var body: some View {
        Group {
            if model.presentationStyle == .compact {
                PingoCompactHomeView(onOpen: onRequestExpanded)
                    .onAppear {
                        // Match the interaction pattern people expect from game-first
                        // iMessage apps: tapping Pingo should open the actual game browser,
                        // not leave them stranded on a mostly-empty compact launcher.
                        Task { @MainActor in
                            onRequestExpanded()
                        }
                    }
            } else {
                ZStack(alignment: .topTrailing) {
                    if let payload = model.incomingPayload {
                        PingoIncomingMatchView(
                            payload: payload,
                            localProfile: model.profile,
                            entitlements: model.progression.entitlements,
                            onAccept: onAccept,
                            onMoves: onMoves,
                            onPhysicsMove: onPhysicsMove,
                            onExtraMove: onExtraMove,
                            onContinueSeries: onContinueSeries,
                            onResign: onResign,
                            onOpenStore: model.showStore,
                            onClose: model.clearIncomingMatch
                        )
                    } else {
                        PingoHomeView(
                            progression: model.progression,
                            onChallenge: onChallenge,
                            onOpenStore: model.showStore
                        )

                        homeToolbar
                    }

                    if let status = model.statusMessage {
                        statusToast(status)
                    }
                }
            }
        }
        .sheet(isPresented: $model.isProfilePresented) {
            PingoProfileView(
                profile: model.profile,
                progression: $model.progression,
                onSave: { username, avatar in
                    try model.updateProfile(username: username, avatar: avatar)
                },
                onEquip: { cosmeticID in
                    try model.equip(cosmeticID: cosmeticID)
                }
            )
        }
        .sheet(isPresented: $model.isStorePresented) {
            PingoStoreView(
                manager: model.storeManager,
                entitlements: model.progression.entitlements,
                onEntitlementsChanged: model.applyVerifiedStoreEntitlements
            )
        }
        .animation(.easeInOut(duration: 0.2), value: model.presentationStyle)
    }

    private var homeToolbar: some View {
        HStack(spacing: 8) {
            Button {
                model.showStore()
            } label: {
                Image(systemName: "bag")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pingo store")

            Button {
                model.isProfilePresented = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pingo profile")
        }
        .padding(.top, 18)
        .padding(.trailing, 16)
    }

    private func statusToast(_ status: String) -> some View {
        VStack {
            Spacer()
            Text(status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.black.opacity(0.76), in: Capsule())
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
