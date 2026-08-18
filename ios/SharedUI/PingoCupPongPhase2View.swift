import PingoCore
import SwiftUI

struct PingoCupPongPhase2View: View {
    let state: PingoCupPongState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void

    var body: some View {
        PingoCupPongPhase3View(
            state: state,
            player: player,
            canMove: canMove,
            match: match,
            localProfile: localProfile,
            onMove: onMove
        )
    }
}
