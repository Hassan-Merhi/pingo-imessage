import Testing
@testable import PingoCore

@Suite("Pingo game catalog")
struct GameCatalogTests {
    @Test("Contains the original ten plus twelve Wave 6 games")
    func gameCatalog() {
        #expect(PingoGameCatalog.launch.count == 22)
        #expect(PingoGameCatalog.wave6.count == 12)
        #expect(Set(PingoGameCatalog.launch.map(\.id)) == Set(PingoGameID.allCases))
    }

    @Test("Catalog separates free, premium and expansion packs")
    func catalogEntitlements() {
        let free = Set(PingoGameCatalog.launch.filter(\.isFreeAtLaunch).map(\.id))
        let paid = Set(PingoGameCatalog.launch.filter { !$0.isFreeAtLaunch }.map(\.id))
        let expectedPaid = PingoAccessPolicy.premiumGames
            .union(PingoAccessPolicy.arcadeExpansionGames)
            .union(PingoAccessPolicy.wordPartyExpansionGames)
            .union(PingoAccessPolicy.classicsExpansionGames)

        #expect(free == PingoAccessPolicy.freeGames)
        #expect(paid == expectedPaid)
        #expect(free.count == 5)
        #expect(PingoAccessPolicy.premiumGames.count == 5)
        #expect(PingoAccessPolicy.arcadeExpansionGames.count == 6)
        #expect(PingoAccessPolicy.wordPartyExpansionGames.count == 4)
        #expect(PingoAccessPolicy.classicsExpansionGames.count == 2)
        #expect(paid.count == 17)

        for game in PingoGameCatalog.launch {
            #expect(game.minimumPlayers == 2)
            #expect(game.maximumPlayers == 2)
        }
    }
}
