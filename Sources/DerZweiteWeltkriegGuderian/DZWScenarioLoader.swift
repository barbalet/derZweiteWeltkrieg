import DerZweiteWeltkriegCore
import Foundation

public struct DZWScenarioLoadout {
    public let scenario: GuderianScenario
    public let seed: UInt32
    public let playerArmy: army_list_t
    public let playerForceIndex: Int32
    public let opponentArmy: army_list_t
    public let opponentForceIndex: Int32
    public let adapterNotes: [String]

    public var playerArmyName: String {
        armyName(playerArmy)
    }

    public var opponentArmyName: String {
        armyName(opponentArmy)
    }

    public func makeGame() -> OpaquePointer? {
        game_create_demo_with_forces(
            seed,
            playerArmy,
            Int32(playerForceIndex),
            opponentArmy,
            Int32(opponentForceIndex)
        )
    }
}

public enum DZWScenarioLoader {
    public static func load(_ id: GuderianBattleID, seed: UInt32 = 1941) -> DZWScenarioLoadout? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        let mapping = mapping(for: scenario)
        return DZWScenarioLoadout(
            scenario: scenario,
            seed: seed,
            playerArmy: mapping.playerArmy,
            playerForceIndex: mapping.playerForceIndex,
            opponentArmy: mapping.opponentArmy,
            opponentForceIndex: mapping.opponentForceIndex,
            adapterNotes: mapping.notes
        )
    }

    public static func loadFirstDemoScenario(seed: UInt32 = 19390907) -> DZWScenarioLoadout {
        guard let loadout = load(.wizna, seed: seed) else {
            preconditionFailure("Wizna scenario metadata must be present.")
        }
        return loadout
    }

    private static func mapping(for scenario: GuderianScenario) -> DZWForceMapping {
        switch scenario.theater {
        case .easternFront1941:
            return DZWForceMapping(
                playerArmy: TE_ARMY_SOVIET,
                playerForceIndex: scenario.id == .moscowTulaKashira ? 1 : 0,
                opponentArmy: TE_ARMY_GERMAN,
                opponentForceIndex: 1,
                notes: [
                    "Uses the inherited Soviet and German dzw rosters until Guderian-specific 1941 data tables exist.",
                    "Eastern Front campaign systems, terrain, objectives, and mission identity remain metadata-owned in GuderianCore while dzw supplies the playable rules skeleton.",
                ]
            )
        case .france1940:
            return DZWForceMapping(
                playerArmy: TE_ARMY_BRITISH,
                playerForceIndex: 0,
                opponentArmy: TE_ARMY_GERMAN,
                opponentForceIndex: 0,
                notes: [
                    "Uses the inherited British roster as a Western Allied unit-stat proxy until a native French 1940 C roster is added.",
                    "France 1940 campaign systems, objectives, and balance data are owned by GuderianCore while dzw supplies the playable rules skeleton.",
                    "The dzw C engine is loaded through game_create_demo_with_forces without modifying the submodule.",
                ]
            )
        case .poland1939:
            return DZWForceMapping(
                playerArmy: TE_ARMY_BRITISH,
                playerForceIndex: 0,
                opponentArmy: TE_ARMY_GERMAN,
                opponentForceIndex: 0,
                notes: [
                    "Uses the inherited British roster as a temporary Allied infantry proxy until a Polish 1939 C roster is added.",
                    "Polish campaign systems, scenario identity, and historical objectives are owned by GuderianCore while dzw supplies the playable rules skeleton.",
                ]
            )
        }
    }
}

public func armyName(_ army: army_list_t) -> String {
    guard let name = army_name(army) else {
        return "Unknown"
    }
    return String(cString: name)
}

private struct DZWForceMapping {
    let playerArmy: army_list_t
    let playerForceIndex: Int32
    let opponentArmy: army_list_t
    let opponentForceIndex: Int32
    let notes: [String]
}
