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
    let onContinueSeries: () -> Void
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
                                entitlements: model.progression.entitlements,
                                onAccept: onAccept,
                                onMoves: onMoves,
                                onPhysicsMove: onPhysicsMove,
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
                        }
                    }
                    .navigationTitle("Pingo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button {
                                model.showStore()
                            } label: {
                                Image(systemName: "bag")
                            }
                            .accessibilityLabel("Pingo store")

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
}
