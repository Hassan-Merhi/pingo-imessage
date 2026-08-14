import Testing
@testable import PingoCore

@Suite("Pingo launch catalog")
struct GameCatalogTests {
    @Test("Contains exactly the ten approved launch games")
    func launchCatalog() {
        #expect(PingoGameCatalog.launch.count == 10)
        #expect(Set(PingoGameCatalog.launch.map(\.id)) == Set(PingoGameID.allCases))
    }

    @Test("Launch catalog has five free games and five premium-pack games")
    func launchEntitlements() {
        let free = Set(PingoGameCatalog.launch.filter(\.isFreeAtLaunch).map(\.id))
        let premium = Set(PingoGameCatalog.launch.filter { !$0.isFreeAtLaunch }.map(\.id))
        #expect(free == PingoAccessPolicy.freeGames)
        #expect(premium == PingoAccessPolicy.premiumGames)
        #expect(free.count == 5)
        #expect(premium.count == 5)
        for game in PingoGameCatalog.launch {
            #expect(game.minimumPlayers == 2)
            #expect(game.maximumPlayers == 2)
        }
    }
}
