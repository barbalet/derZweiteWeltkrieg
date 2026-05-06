#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

enum ArmyAllegiance: String {
    case allies = "Allies"
    case axis = "Axis"
}

struct ArmyReference: Identifiable, Hashable {
    let id: String
    let displayName: String
    let allegiance: ArmyAllegiance
    let preset: army_list_t

    var subtitle: String {
        "\(allegiance.rawValue) nation"
    }

    func opposes(_ other: ArmyReference) -> Bool {
        allegiance != other.allegiance
    }
}

enum ArmyReferenceCatalog {
    private struct KnownArmy {
        let id: String
        let displayName: String
        let allegiance: ArmyAllegiance
        let preset: army_list_t
    }

    private static let supportedArmies: [KnownArmy] = [
        KnownArmy(id: "british", displayName: "British", allegiance: .allies, preset: DZW_ARMY_BRITISH),
        KnownArmy(id: "american", displayName: "American", allegiance: .allies, preset: DZW_ARMY_AMERICAN),
        KnownArmy(id: "australian", displayName: "Australian", allegiance: .allies, preset: DZW_ARMY_AUSTRALIAN),
        KnownArmy(id: "soviet", displayName: "Soviet", allegiance: .allies, preset: DZW_ARMY_SOVIET),
        KnownArmy(id: "german", displayName: "German", allegiance: .axis, preset: DZW_ARMY_GERMAN),
        KnownArmy(id: "italian", displayName: "Italian", allegiance: .axis, preset: DZW_ARMY_ITALIAN),
    ]

    static func load() -> [ArmyReference] {
        supportedArmies.map { army in
            ArmyReference(
                id: army.id,
                displayName: army.displayName,
                allegiance: army.allegiance,
                preset: army.preset
            )
        }
    }
}
