import Foundation
import CoreGraphics
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

enum AppMode: String, Codable {
    case setup
    case deployment
    case battle
}

extension FollowUpChoice: Codable {}

struct ArmyCatalogUnitSnapshot: Identifiable {
    let id: Int
    let name: String
    let points: Int
    let maxCount: Int
    let unit: ArmyRosterUnitSnapshot

    init(raw: army_catalog_unit_view_t) {
        id = Int(raw.catalog_id)
        name = raw.name.map { String(cString: $0) } ?? "Unit"
        points = Int(raw.points)
        maxCount = Int(raw.max_count)
        unit = ArmyRosterUnitSnapshot(index: Int(raw.catalog_id), raw: raw.unit)
    }
}

struct ArmyListSelection: Identifiable, Codable, Hashable {
    let catalogID: Int
    let count: Int

    var id: Int { catalogID }
}

struct GeneratedOpponentPlan: Hashable {
    let army: ArmyReference
    let selections: [ArmyListSelection]
    let points: Int
}

struct SkirmishConfiguration: Codable, Hashable {
    let seed: UInt32
    let pointsLimit: Int
    let playerArmyID: String
    let playerSelections: [ArmyListSelection]
    let aiArmyID: String
    let aiSelections: [ArmyListSelection]
}

struct RecordedBattleAction: Codable, Hashable {
    enum Kind: String, Codable {
        case deployUnit
        case deployRotate
        case advancePhase
        case moveUnit
        case tankShock
        case embark
        case disembark
        case rotate
        case toggleCover
        case toggleHullDown
        case useSmoke
        case shoot
        case firePassenger
        case assault
        case chooseWeaponDestroy
        case chooseHitAllocation
        case setPreferredCasualtyGroup
    }

    let kind: Kind
    var unitID: Int?
    var targetID: Int?
    var transportID: Int?
    var optionID: Int?
    var groupIndex: Int?
    var pointX: Double?
    var pointY: Double?
    var degrees: Double?
    var enabled: Bool?
    var followUp: FollowUpChoice?
}

struct SavedSkirmishDocument: Codable {
    let version: Int
    let configuration: SkirmishConfiguration
    let actions: [RecordedBattleAction]
    let mode: AppMode

    init(version: Int, configuration: SkirmishConfiguration, actions: [RecordedBattleAction], mode: AppMode) {
        self.version = version
        self.configuration = configuration
        self.actions = actions
        self.mode = mode
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case configuration
        case actions
        case mode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        configuration = try container.decode(SkirmishConfiguration.self, forKey: .configuration)
        actions = try container.decodeIfPresent([RecordedBattleAction].self, forKey: .actions) ?? []
        mode = try container.decodeIfPresent(AppMode.self, forKey: .mode) ?? .battle
    }
}
