import Testing
@testable import PingoCore

@Suite("Pingo launch catalog")
struct GameCatalogTests {
    @Test("Contains exactly the ten approved launch games")
    func launchCatalog() {
        #expect(PingoGameCatalog.launch.count == 10)
        #expect(Set(PingoGameCatalog.launch.map(\.id)) == Set(PingoGameID.allCases))
    }

    @Test("Every launch game is a two-player free game")
    func launchEntitlements() {
        for game in PingoGameCatalog.launch {
            #expect(game.isFreeAtLaunch)
            #expect(game.minimumPlayers == 2)
            #expect(game.maximumPlayers == 2)
        }
    }
}
