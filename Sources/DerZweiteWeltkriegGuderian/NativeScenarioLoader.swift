import DerZweiteWeltkriegCore
import Foundation

public enum NativeScenarioGameCreationMode: String, Codable, Hashable, Sendable {
    case nativeBlueprintSkirmishBridge = "Native blueprint skirmish bridge"
}

public struct NativeScenarioArmyListSelection: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let catalogID: Int
    public let count: Int
    public let catalogName: String
    public let roleHints: [String]

    public init(id: String, catalogID: Int, count: Int, catalogName: String, roleHints: [String]) {
        self.id = id
        self.catalogID = catalogID
        self.count = count
        self.catalogName = catalogName
        self.roleHints = roleHints
    }
}

public struct NativeScenarioLoaderWarning: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String

    public init(id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

public struct NativeScenarioDeploymentReport: Codable, Hashable, Sendable {
    public let attempted: Int
    public let succeeded: Int
    public let skipped: Int
    public let notes: [String]

    public init(attempted: Int, succeeded: Int, skipped: Int, notes: [String]) {
        self.attempted = attempted
        self.succeeded = succeeded
        self.skipped = skipped
        self.notes = notes
    }

    public var placedAnyScenarioUnit: Bool {
        succeeded > 0
    }
}

public struct NativeScenarioBoardReport: Codable, Hashable, Sendable {
    public let applied: Bool
    public let missionName: String
    public let missionTargetScore: Int
    public let requestedTerrainZoneCount: Int
    public let appliedTerrainZoneCount: Int
    public let requestedObjectiveCount: Int
    public let appliedObjectiveCount: Int
    public let notes: [String]

    public init(
        applied: Bool,
        missionName: String,
        missionTargetScore: Int,
        requestedTerrainZoneCount: Int,
        appliedTerrainZoneCount: Int,
        requestedObjectiveCount: Int,
        appliedObjectiveCount: Int,
        notes: [String]
    ) {
        self.applied = applied
        self.missionName = missionName
        self.missionTargetScore = missionTargetScore
        self.requestedTerrainZoneCount = requestedTerrainZoneCount
        self.appliedTerrainZoneCount = appliedTerrainZoneCount
        self.requestedObjectiveCount = requestedObjectiveCount
        self.appliedObjectiveCount = appliedObjectiveCount
        self.notes = notes
    }

    public var isScenarioSpecific: Bool {
        applied && missionTargetScore > 0 && appliedTerrainZoneCount > 0 && appliedObjectiveCount > 0
    }
}

public final class NativeScenarioLoadedGame {
    public let handle: OpaquePointer
    public let boardReport: NativeScenarioBoardReport
    public let deploymentReport: NativeScenarioDeploymentReport

    public init(
        handle: OpaquePointer,
        boardReport: NativeScenarioBoardReport,
        deploymentReport: NativeScenarioDeploymentReport
    ) {
        self.handle = handle
        self.boardReport = boardReport
        self.deploymentReport = deploymentReport
    }

    deinit {
        game_destroy(handle)
    }
}

public struct NativeScenarioLoadout {
    public let scenario: GuderianScenario
    public let seed: UInt32
    public let instance: NativeBattleInstance
    public let blueprint: NativeEngineBattleBlueprint
    public let playerArmy: army_list_t
    public let opponentArmy: army_list_t
    public let playerEntries: [NativeScenarioArmyListSelection]
    public let opponentEntries: [NativeScenarioArmyListSelection]
    public let warnings: [NativeScenarioLoaderWarning]
    public let gameCreationMode: NativeScenarioGameCreationMode

    public var playerArmyName: String {
        armyName(playerArmy)
    }

    public var opponentArmyName: String {
        armyName(opponentArmy)
    }

    public var usesForcePresetProxy: Bool {
        false
    }

    public var canCreateSkirmishBridge: Bool {
        blueprint.isCompleteForScenarioLoader && !playerEntries.isEmpty && !opponentEntries.isEmpty
    }

    public var canApplyScenarioBoardHook: Bool {
        canCreateSkirmishBridge &&
            !scenarioBoardZones.isEmpty &&
            !scenarioBoardObjectives.isEmpty &&
            blueprint.missionTargetScore > 0
    }

    public func makeGame() -> NativeScenarioLoadedGame? {
        let playerCEntries = playerEntries.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }
        let opponentCEntries = opponentEntries.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }

        let game = playerCEntries.withUnsafeBufferPointer { playerBuffer in
            opponentCEntries.withUnsafeBufferPointer { opponentBuffer in
                game_create_skirmish(
                    seed,
                    playerArmy,
                    playerBuffer.baseAddress,
                    Int32(playerBuffer.count),
                    opponentArmy,
                    opponentBuffer.baseAddress,
                    Int32(opponentBuffer.count)
                )
            }
        }
        guard let game else {
            return nil
        }

        let boardReport = applyScenarioBoard(to: game)
        let report = deployBlueprintUnits(in: game)
        return NativeScenarioLoadedGame(handle: game, boardReport: boardReport, deploymentReport: report)
    }

    private var scenarioBoardZones: [ScenarioBoardZoneSpec] {
        let preferredTerrain = blueprint.terrain
            .filter { $0.kind != .objective && $0.kind != .airPressure }
            .sorted { lhs, rhs in
                terrainPriority(lhs.kind) > terrainPriority(rhs.kind)
            }
        let terrain = preferredTerrain.isEmpty ? blueprint.terrain : preferredTerrain
        return terrain.prefix(NativeScenarioLoader.boardTerrainZoneCapacity).enumerated().map { index, terrain in
            let rect = zoneRect(for: terrain)
            return ScenarioBoardZoneSpec(
                id: index + 1,
                name: terrain.name,
                kind: engineTerrainKind(for: terrain.kind),
                rect: rect,
                coverSave: coverSave(for: terrain.kind),
                blocksLineOfSight: terrain.blocksLineOfSightHint,
                hullDown: terrain.kind == .ridge || terrain.kind == .bunker || terrain.kind == .fortifiedLine
            )
        }
    }

    private var scenarioBoardObjectives: [ScenarioBoardObjectiveSpec] {
        blueprint.objectives.prefix(NativeScenarioLoader.boardObjectiveCapacity).enumerated().map { index, objective in
            ScenarioBoardObjectiveSpec(
                id: index + 1,
                name: objective.name,
                x: Float(clamp(objective.x, min: 1, max: blueprint.engineBoardFrame.width - 1)),
                y: Float(clamp(objective.y, min: 1, max: blueprint.engineBoardFrame.height - 1)),
                radius: Float(clamp(Double(objective.victoryPoints) + 2.5, min: 3.5, max: 7.5))
            )
        }
    }

    private func applyScenarioBoard(to game: OpaquePointer) -> NativeScenarioBoardReport {
        let zones = scenarioBoardZones
        let objectives = scenarioBoardObjectives
        var notes: [String] = []
        if blueprint.terrain.count > zones.count {
            notes.append("\(blueprint.terrain.count - zones.count) terrain features were summarized because the current dzw zone view exposes \(NativeScenarioLoader.boardTerrainZoneCapacity) scenario zones.")
        }
        if blueprint.objectives.count > objectives.count {
            notes.append("\(blueprint.objectives.count - objectives.count) objectives were summarized because the current dzw objective view exposes \(NativeScenarioLoader.boardObjectiveCapacity) objectives.")
        }

        let applied = withCStringPointers(zones.map(\.name)) { zoneNames in
            withCStringPointers(objectives.map(\.name)) { objectiveNames in
                "\(scenario.title)".withCString { missionName in
                    let cZones = zones.enumerated().map { index, zone in
                        guderian_scenario_zone_t(
                            id: Int32(zone.id),
                            name: zoneNames[index],
                            kind: zone.kind,
                            rect: rect_t(
                                x: zone.rect.x,
                                y: zone.rect.y,
                                width: zone.rect.width,
                                height: zone.rect.height
                            ),
                            cover_save: Int32(zone.coverSave),
                            blocks_line_of_sight: zone.blocksLineOfSight,
                            hull_down: zone.hullDown
                        )
                    }
                    let cObjectives = objectives.enumerated().map { index, objective in
                        guderian_scenario_objective_t(
                            id: Int32(objective.id),
                            name: objectiveNames[index],
                            x: objective.x,
                            y: objective.y,
                            radius: objective.radius
                        )
                    }
                    return cZones.withUnsafeBufferPointer { zoneBuffer in
                        cObjectives.withUnsafeBufferPointer { objectiveBuffer in
                            game_apply_guderian_scenario_board(
                                game,
                                missionName,
                                Int32(blueprint.missionTargetScore),
                                zoneBuffer.baseAddress,
                                Int32(zoneBuffer.count),
                                objectiveBuffer.baseAddress,
                                Int32(objectiveBuffer.count)
                            )
                        }
                    }
                }
            }
        }

        if !applied, let error = game_last_error(game), String(cString: error).isEmpty == false {
            notes.append(String(cString: error))
        }

        let mission = game_mission_view(game)
        return NativeScenarioBoardReport(
            applied: applied,
            missionName: nativeScenarioCString(mission.name),
            missionTargetScore: Int(mission.target_score),
            requestedTerrainZoneCount: blueprint.terrain.count,
            appliedTerrainZoneCount: Int(game_zone_count(game)),
            requestedObjectiveCount: blueprint.objectives.count,
            appliedObjectiveCount: Int(game_objective_count(game)),
            notes: notes
        )
    }

    private func deployBlueprintUnits(in game: OpaquePointer) -> NativeScenarioDeploymentReport {
        let playerIDs = engineUnitIDs(in: game, owner: TE_PLAYER_ONE)
        let opponentIDs = engineUnitIDs(in: game, owner: TE_PLAYER_TWO)
        let playerSpawns = blueprint.units.filter { $0.side == .player }
        let opponentSpawns = blueprint.units.filter { $0.side == .guderianAI }

        var attempted = 0
        var succeeded = 0
        var notes: [String] = []
        let playerResult = deploy(playerSpawns, onto: playerIDs, in: game)
        attempted += playerResult.attempted
        succeeded += playerResult.succeeded
        notes.append(contentsOf: playerResult.notes)

        let opponentResult = deploy(opponentSpawns, onto: opponentIDs, in: game)
        attempted += opponentResult.attempted
        succeeded += opponentResult.succeeded
        notes.append(contentsOf: opponentResult.notes)

        let skipped = max(0, playerSpawns.count + opponentSpawns.count - attempted)
        if skipped > 0 {
            notes.append("\(skipped) native unit blueprints did not have matching skirmish-roster slots after catalog caps were applied.")
        }
        return NativeScenarioDeploymentReport(
            attempted: attempted,
            succeeded: succeeded,
            skipped: skipped,
            notes: notes
        )
    }

    private func engineUnitIDs(in game: OpaquePointer, owner: player_t) -> [Int32] {
        (0..<Int(game_unit_count(game))).compactMap { index in
            let view = game_unit_view(game, Int32(index))
            guard view.owner == owner, !view.destroyed, !view.embarked else {
                return nil
            }
            return Int32(view.id)
        }
    }

    private func deploy(
        _ spawns: [NativeEngineUnitSpawn],
        onto ids: [Int32],
        in game: OpaquePointer
    ) -> (attempted: Int, succeeded: Int, notes: [String]) {
        let count = min(spawns.count, ids.count)
        var succeeded = 0
        var notes: [String] = []
        guard count > 0 else {
            return (0, 0, [])
        }

        for index in 0..<count {
            let spawn = spawns[index]
            let unitID = ids[index]
            if deploy(unitID: unitID, near: spawn, in: game) {
                succeeded += 1
            } else {
                notes.append("Could not deploy skirmish unit \(unitID) near native spawn \(spawn.name).")
            }
        }
        return (count, succeeded, notes)
    }

    private func deploy(unitID: Int32, near spawn: NativeEngineUnitSpawn, in game: OpaquePointer) -> Bool {
        let offsets: [(Double, Double)] = [
            (0, 0), (1.5, 0), (-1.5, 0), (0, 1.5), (0, -1.5),
            (3, 0), (-3, 0), (0, 3), (0, -3),
            (3, 3), (-3, 3), (3, -3), (-3, -3),
            (5, 0), (-5, 0), (0, 5), (0, -5),
        ]

        for offset in offsets {
            let x = Float(clamp(spawn.x + offset.0, min: 2, max: blueprint.engineBoardFrame.width - 2))
            let y = Float(clamp(spawn.y + offset.1, min: 2, max: blueprint.engineBoardFrame.height - 2))
            if game_deploy_unit(game, unitID, x, y) {
                return true
            }
        }
        return false
    }

    private func zoneRect(for terrain: NativeEngineTerrainSpawn) -> ScenarioBoardRect {
        let points = terrain.points.isEmpty
            ? [NativeBattleCoordinate(x: blueprint.engineBoardFrame.width / 2, y: blueprint.engineBoardFrame.height / 2)]
            : terrain.points
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let padding = max(1.5, terrain.radius, terrain.kind == .road || terrain.kind == .river ? 1.75 : 2.75)
        let minX = clamp((xs.min() ?? 0) - padding, min: 0, max: blueprint.engineBoardFrame.width - 1)
        let maxX = clamp((xs.max() ?? blueprint.engineBoardFrame.width) + padding, min: minX + 1, max: blueprint.engineBoardFrame.width)
        let minY = clamp((ys.min() ?? 0) - padding, min: 0, max: blueprint.engineBoardFrame.height - 1)
        let maxY = clamp((ys.max() ?? blueprint.engineBoardFrame.height) + padding, min: minY + 1, max: blueprint.engineBoardFrame.height)

        return ScenarioBoardRect(
            x: Float(minX),
            y: Float(minY),
            width: Float(max(1, maxX - minX)),
            height: Float(max(1, maxY - minY))
        )
    }

    private func engineTerrainKind(for kind: NativeBattleTerrainKind) -> terrain_kind_t {
        switch kind {
        case .river:
            return TE_TERRAIN_IMPASSABLE
        case .town, .forest, .ridge, .bunker, .fortifiedLine:
            return TE_TERRAIN_DIFFICULT
        case .road, .bridge, .objective, .artilleryPark, .airPressure:
            return TE_TERRAIN_OPEN
        }
    }

    private func coverSave(for kind: NativeBattleTerrainKind) -> Int {
        switch kind {
        case .bunker, .fortifiedLine:
            return 4
        case .town, .forest, .ridge:
            return 5
        case .bridge, .artilleryPark:
            return 6
        case .road, .river, .objective, .airPressure:
            return 0
        }
    }

    private func terrainPriority(_ kind: NativeBattleTerrainKind) -> Int {
        switch kind {
        case .river, .bunker, .fortifiedLine:
            return 6
        case .town, .forest, .ridge:
            return 5
        case .bridge:
            return 4
        case .road:
            return 3
        case .artilleryPark:
            return 2
        case .objective, .airPressure:
            return 1
        }
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}

private struct ScenarioBoardRect {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
}

private struct ScenarioBoardZoneSpec {
    let id: Int
    let name: String
    let kind: terrain_kind_t
    let rect: ScenarioBoardRect
    let coverSave: Int
    let blocksLineOfSight: Bool
    let hullDown: Bool
}

private struct ScenarioBoardObjectiveSpec {
    let id: Int
    let name: String
    let x: Float
    let y: Float
    let radius: Float
}

private func withCStringPointers<Result>(
    _ strings: [String],
    _ body: ([UnsafePointer<CChar>?]) -> Result
) -> Result {
    var result: Result?

    func recurse(_ index: Int, _ pointers: [UnsafePointer<CChar>?]) {
        if index == strings.count {
            result = body(pointers)
            return
        }
        strings[index].withCString { pointer in
            recurse(index + 1, pointers + [pointer])
        }
    }

    recurse(0, [])
    return result!
}

private func nativeScenarioCString(_ pointer: UnsafePointer<CChar>?) -> String {
    guard let pointer else {
        return ""
    }
    return String(cString: pointer)
}

public enum NativeScenarioLoader {
    public static let cycleRange = 271...280
    public static let boardHookCycleRange = 281...290
    public static let boardTerrainZoneCapacity = 8
    public static let boardObjectiveCapacity = 8

    public static func load(_ id: GuderianBattleID, seed: UInt32 = 1941) -> NativeScenarioLoadout? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return load(scenario, seed: seed)
    }

    public static func load(_ scenario: GuderianScenario, seed: UInt32 = 1941) -> NativeScenarioLoadout {
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        let blueprint = instance.engineBlueprint(seed: seed)
        let armies = armyMapping(for: scenario)
        let playerUnits = instance.units.filter { $0.side == .player }
        let opponentUnits = instance.units.filter { $0.side == .guderianAI }
        let playerEntries = armyListSelections(for: playerUnits, army: armies.playerArmy)
        let opponentEntries = armyListSelections(for: opponentUnits, army: armies.opponentArmy)
        let warnings = warnings(
            scenario: scenario,
            blueprint: blueprint,
            playerEntries: playerEntries,
            opponentEntries: opponentEntries
        )

        return NativeScenarioLoadout(
            scenario: scenario,
            seed: seed,
            instance: instance,
            blueprint: blueprint,
            playerArmy: armies.playerArmy,
            opponentArmy: armies.opponentArmy,
            playerEntries: playerEntries,
            opponentEntries: opponentEntries,
            warnings: warnings,
            gameCreationMode: .nativeBlueprintSkirmishBridge
        )
    }

    private static func armyListSelections(
        for units: [NativeBattleUnit],
        army: army_list_t
    ) -> [NativeScenarioArmyListSelection] {
        let options = catalogOptions(for: army)
        var counts: [Int: Int] = [:]
        var hints: [Int: Set<String>] = [:]

        for unit in units {
            guard let option = bestCatalogOption(for: unit, options: options, currentCounts: counts) else {
                continue
            }
            counts[option.catalogID, default: 0] += 1
            hints[option.catalogID, default: []].insert(unit.mobility.rawValue)
            for weapon in unit.weapons.prefix(2) {
                hints[option.catalogID, default: []].insert(weapon.role.rawValue)
            }
        }

        return counts.keys.sorted().compactMap { catalogID in
            guard let option = options.first(where: { $0.catalogID == catalogID }) else {
                return nil
            }
            return NativeScenarioArmyListSelection(
                id: "\(armyName(army))-\(catalogID)",
                catalogID: catalogID,
                count: counts[catalogID, default: 0],
                catalogName: option.name,
                roleHints: Array(hints[catalogID, default: []]).sorted()
            )
        }
    }

    private static func bestCatalogOption(
        for unit: NativeBattleUnit,
        options: [CatalogOption],
        currentCounts: [Int: Int]
    ) -> CatalogOption? {
        options
            .filter { currentCounts[$0.catalogID, default: 0] < $0.maxCount }
            .max { lhs, rhs in
                score(lhs, for: unit) < score(rhs, for: unit)
            }
    }

    private static func score(_ option: CatalogOption, for unit: NativeBattleUnit) -> Int {
        let text = "\(option.name) \(option.primaryWeaponName)".lowercased()
        var score = 1
        switch unit.mobility {
        case .armor:
            if option.kind == TE_UNIT_VEHICLE || option.kind == TE_UNIT_ASSAULT_GUN { score += 8 }
            if containsAny(text, ["tank", "sherman", "stug", "m10", "semovente", "armored", "car"]) { score += 4 }
        case .gun, .artillery:
            if containsAny(text, ["mortar", "mg", "piat", "anti", "gun", "battery", "destroyer"]) { score += 7 }
        case .engineer:
            if containsAny(text, ["engineer", "pioneer", "sapper", "flamethrower"]) { score += 8 }
        case .command:
            if containsAny(text, ["command", "hq", "officer", "observer"]) { score += 8 }
        case .cavalry:
            if option.kind == TE_UNIT_INFANTRY { score += 4 }
            if containsAny(text, ["recon", "scout", "dingo", "jeep"]) { score += 5 }
        case .airPressure, .navalSupport:
            if containsAny(text, ["mortar", "battery", "observer", "command"]) { score += 4 }
        case .armoredTrain:
            if option.kind == TE_UNIT_VEHICLE || option.kind == TE_UNIT_ASSAULT_GUN { score += 5 }
            if containsAny(text, ["gun", "tank", "transport"]) { score += 3 }
        case .infantry:
            if option.kind == TE_UNIT_INFANTRY { score += 6 }
        }

        for weapon in unit.weapons {
            switch weapon.role {
            case .antiTank:
                if containsAny(text, ["anti", "piat", "tank", "destroyer", "gun"]) { score += 3 }
            case .armorGun:
                if option.kind == TE_UNIT_VEHICLE || option.kind == TE_UNIT_ASSAULT_GUN { score += 3 }
            case .artillery:
                if containsAny(text, ["mortar", "battery", "gun"]) { score += 3 }
            case .demolition:
                if containsAny(text, ["engineer", "pioneer", "sapper", "flamethrower"]) { score += 3 }
            case .command:
                if containsAny(text, ["command", "hq", "observer"]) { score += 3 }
            case .reconnaissance:
                if containsAny(text, ["recon", "scout", "dingo", "jeep"]) { score += 3 }
            case .machineGun:
                if containsAny(text, ["mg", "machine"]) { score += 3 }
            case .airSupport, .navalSupport, .smallArms:
                break
            }
        }
        return score
    }

    private static func catalogOptions(for army: army_list_t) -> [CatalogOption] {
        (0..<Int(army_catalog_unit_count(army))).map { index in
            let view = army_catalog_unit_view(army, Int32(index))
            return CatalogOption(
                catalogID: index,
                name: cString(view.name),
                primaryWeaponName: cString(view.unit.primary_weapon_name),
                kind: view.unit.kind,
                maxCount: max(1, Int(view.max_count))
            )
        }
    }

    private static func warnings(
        scenario: GuderianScenario,
        blueprint: NativeEngineBattleBlueprint,
        playerEntries: [NativeScenarioArmyListSelection],
        opponentEntries: [NativeScenarioArmyListSelection]
    ) -> [NativeScenarioLoaderWarning] {
        var warnings: [NativeScenarioLoaderWarning] = [
            NativeScenarioLoaderWarning(
                id: "\(scenario.id.rawValue)-event-hook",
                title: "Scripted event hook pending",
                detail: "The native loader now applies Guderian terrain, objectives, and mission target score through the guarded dzw board hook. Reinforcements, weather, supply, demolition, evacuation, pocket, and air-pressure events still need the later scenario event hook."
            )
        ]
        if !blueprint.isCompleteForScenarioLoader {
            warnings.append(
                NativeScenarioLoaderWarning(
                    id: "\(scenario.id.rawValue)-blueprint-incomplete",
                    title: "Native blueprint incomplete",
                    detail: "The engine blueprint is missing units, objectives, terrain, or mission target score."
                )
            )
        }
        if playerEntries.isEmpty || opponentEntries.isEmpty {
            warnings.append(
                NativeScenarioLoaderWarning(
                    id: "\(scenario.id.rawValue)-army-list-empty",
                    title: "Army-list bridge incomplete",
                    detail: "The loader could not map one side of the native unit roster onto the current dzw army catalog."
                )
            )
        }
        return warnings
    }

    private static func armyMapping(for scenario: GuderianScenario) -> (playerArmy: army_list_t, opponentArmy: army_list_t) {
        switch scenario.theater {
        case .easternFront1941:
            return (TE_ARMY_SOVIET, TE_ARMY_GERMAN)
        case .france1940, .poland1939:
            return (TE_ARMY_BRITISH, TE_ARMY_GERMAN)
        }
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private static func cString(_ pointer: UnsafePointer<CChar>?) -> String {
        guard let pointer else {
            return ""
        }
        return String(cString: pointer)
    }
}

private struct CatalogOption {
    let catalogID: Int
    let name: String
    let primaryWeaponName: String
    let kind: unit_kind_t
    let maxCount: Int
}
