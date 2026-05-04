import DerZweiteWeltkriegCore
import Foundation

public enum NativeBoardPlayer: String, Codable, Hashable, Sendable {
    case none = "None"
    case player = "Player"
    case guderianAI = "Guderian AI"

    init(_ player: player_t) {
        switch player {
        case TE_PLAYER_ONE:
            self = .player
        case TE_PLAYER_TWO:
            self = .guderianAI
        default:
            self = .none
        }
    }
}

public enum NativeBoardPhase: String, Codable, Hashable, Sendable {
    case movement = "Movement"
    case shooting = "Shooting"
    case assault = "Assault"

    init(_ phase: phase_t) {
        switch phase {
        case TE_PHASE_SHOOTING:
            self = .shooting
        case TE_PHASE_ASSAULT:
            self = .assault
        default:
            self = .movement
        }
    }
}

public enum NativeBoardActionStatus: String, Codable, Hashable, Sendable {
    case idle = "Idle"
    case succeeded = "Succeeded"
    case blocked = "Blocked"
}

public struct NativeBoardActionMessage: Codable, Hashable, Sendable {
    public let status: NativeBoardActionStatus
    public let title: String
    public let detail: String

    public init(status: NativeBoardActionStatus, title: String, detail: String) {
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct NativeBoardMissionSnapshot: Codable, Hashable, Sendable {
    public let name: String
    public let targetScore: Int
    public let playerScore: Int
    public let opponentScore: Int
    public let winner: NativeBoardPlayer
}

public struct NativeBoardUnitSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let engineName: String
    public let nativeUnitID: String?
    public let owner: NativeBoardPlayer
    public let kind: String
    public let mobility: String
    public let role: String
    public let historicalNote: String
    public let x: Double
    public let y: Double
    public let facingDegrees: Double
    public let totalWoundsRemaining: Int
    public let destroyed: Bool
    public let inCover: Bool
    public let hullDown: Bool
    public let pinned: Bool
    public let canMoveNow: Bool
    public let canShootNow: Bool
    public let canAssaultNow: Bool
    public let selected: Bool
    public let targeted: Bool

    public var roleLine: String {
        mobility == role ? role : "\(mobility) | \(role)"
    }
}

public struct NativeBoardZoneSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let kind: String
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let coverSave: Int
    public let blocksLineOfSight: Bool
    public let hullDown: Bool
}

public struct NativeBoardObjectiveSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let x: Double
    public let y: Double
    public let radius: Double
    public let controller: NativeBoardPlayer
    public let playerPresence: Int
    public let opponentPresence: Int
}

public struct NativeBoardSnapshot: Codable, Hashable, Sendable {
    public let scenarioID: GuderianBattleID
    public let scenarioTitle: String
    public let turnNumber: Int
    public let activePlayer: NativeBoardPlayer
    public let phase: NativeBoardPhase
    public let mission: NativeBoardMissionSnapshot
    public let units: [NativeBoardUnitSnapshot]
    public let zones: [NativeBoardZoneSnapshot]
    public let objectives: [NativeBoardObjectiveSnapshot]
    public let logLines: [String]
    public let lastAction: NativeBoardActionMessage
    public let boardReport: NativeScenarioBoardReport
    public let deploymentReport: NativeScenarioDeploymentReport

    public var isScenarioBoardPlayable: Bool {
        boardReport.isScenarioSpecific && !units.isEmpty && !objectives.isEmpty
    }

    public var selectedUnit: NativeBoardUnitSnapshot? {
        units.first(where: \.selected)
    }

    public var selectedTarget: NativeBoardUnitSnapshot? {
        units.first(where: \.targeted)
    }
}

public final class NativeBoardSession {
    public static let cycleRange = 281...290

    public let loadout: NativeScenarioLoadout
    private let loadedGame: NativeScenarioLoadedGame
    private let nativeUnitByEngineID: [Int: NativeBattleUnit]
    private var selectedUnitID: Int?
    private var selectedTargetID: Int?
    private var lastAction = NativeBoardActionMessage(status: .idle, title: "Ready", detail: "Board session is ready.")

    public var handle: OpaquePointer {
        loadedGame.handle
    }

    public init?(scenario: GuderianScenario, seed: UInt32 = 1941) {
        let loadout = NativeScenarioLoader.load(scenario, seed: seed)
        guard let loadedGame = loadout.makeGame() else {
            return nil
        }
        self.loadout = loadout
        self.loadedGame = loadedGame
        nativeUnitByEngineID = Self.nativeUnitMap(handle: loadedGame.handle, instance: loadout.instance)
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
    }

    public convenience init?(battleID: GuderianBattleID, seed: UInt32 = 1941) {
        guard let scenario = GuderianCampaignCatalog.scenario(id: battleID) else {
            return nil
        }
        self.init(scenario: scenario, seed: seed)
    }

    public func snapshot() -> NativeBoardSnapshot {
        let view = game_view(handle)
        let mission = game_mission_view(handle)
        return NativeBoardSnapshot(
            scenarioID: loadout.scenario.id,
            scenarioTitle: loadout.scenario.title,
            turnNumber: Int(view.turn_number),
            activePlayer: NativeBoardPlayer(view.active_player),
            phase: NativeBoardPhase(view.phase),
            mission: NativeBoardMissionSnapshot(
                name: nativeBoardCString(mission.name),
                targetScore: Int(mission.target_score),
                playerScore: Int(mission.player_one_score),
                opponentScore: Int(mission.player_two_score),
                winner: NativeBoardPlayer(mission.winner)
            ),
            units: unitSnapshots(),
            zones: zoneSnapshots(),
            objectives: objectiveSnapshots(),
            logLines: logLines(),
            lastAction: lastAction,
            boardReport: loadedGame.boardReport,
            deploymentReport: loadedGame.deploymentReport
        )
    }

    public func selectUnit(_ id: Int) {
        selectedUnitID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Unit selected", detail: unitName(id: id))
        if selectedTargetID == id {
            selectedTargetID = nil
        }
    }

    public func selectTarget(_ id: Int) {
        selectedTargetID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Target selected", detail: unitName(id: id))
    }

    public func selectFirstActiveUnit() {
        selectedUnitID = (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { $0.owner == game_view(self.handle).active_player && !$0.destroyed && !$0.embarked }
            .map { Int($0.id) }
    }

    public func selectNearestEnemyToSelectedUnit() {
        guard let selected = selectedUnitView() else {
            selectedTargetID = nil
            return
        }
        selectedTargetID = (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .filter { $0.owner != selected.owner && $0.owner != TE_PLAYER_NONE && !$0.destroyed && !$0.embarked }
            .min { lhs, rhs in
                distance(from: selected, to: lhs) < distance(from: selected, to: rhs)
            }
            .map { Int($0.id) }
    }

    @discardableResult
    public func moveSelectedUnitTowardNearestObjective(maxDistance: Double = 4) -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before issuing movement.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move in the current phase.")
        }
        guard let objective = nearestObjective(to: unit) else {
            return failAction("No objective", "The board has no scenario objective to move toward.")
        }

        return move(unit, toward: objective, maxDistance: maxDistance)
    }

    @discardableResult
    public func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double = 6) -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before issuing movement.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move in the current phase.")
        }
        let priorityObjectives = priorityObjectives(named: priorityNames)
        var candidateObjectives = priorityObjectives
        if let nearest = nearestObjective(to: unit), !candidateObjectives.contains(where: { $0.id == nearest.id }) {
            candidateObjectives.append(nearest)
        }
        guard !candidateObjectives.isEmpty else {
            return failAction("No objective", "The board has no scenario objective to move toward.")
        }

        for objective in candidateObjectives {
            if move(unit, toward: objective, maxDistance: maxDistance) {
                return true
            }
        }

        return failFromEngine("Priority move blocked")
    }

    @discardableResult
    public func moveUnit(_ id: Int, to point: NativeBattleCoordinate) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move in the current phase.")
        }

        let x = clamp(point.x, min: 1, max: loadout.blueprint.engineBoardFrame.width - 1)
        let y = clamp(point.y, min: 1, max: loadout.blueprint.engineBoardFrame.height - 1)
        if game_move_unit(handle, Int32(id), Float(x), Float(y)) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unitDisplayName(unit)) moved to \(Int(x)), \(Int(y)).")
            return true
        }
        return failFromEngine("Move blocked")
    }

    @discardableResult
    public func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_rotate_unit(handle, Int32(id), Float(facingDegrees)) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Rotated", detail: "\(unitDisplayName(unit)) rotated to \(Int(facingDegrees)) degrees.")
            return true
        }
        return failFromEngine("Rotate blocked")
    }

    @discardableResult
    public func toggleCover(for id: Int, enabled: Bool) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_toggle_cover(handle, Int32(id), enabled) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Cover updated", detail: "\(unitDisplayName(unit)) \(enabled ? "entered" : "left") cover.")
            return true
        }
        return failFromEngine("Cover toggle blocked")
    }

    @discardableResult
    public func toggleHullDown(for id: Int, enabled: Bool) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_toggle_hull_down(handle, Int32(id), enabled) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Hull-down updated", detail: "\(unitDisplayName(unit)) \(enabled ? "took" : "left") hull-down position.")
            return true
        }
        return failFromEngine("Hull-down toggle blocked")
    }

    @discardableResult
    public func shootUnit(_ attackerID: Int, targetID: Int) -> Bool {
        guard let unit = unitView(id: attackerID) else {
            return failAction("Unit unavailable", "Unit \(attackerID) is not present on the board.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .shooting, unit.can_shoot_now else {
            return failAction("Shooting blocked", "\(unitDisplayName(unit)) cannot shoot in the current phase.")
        }
        if game_shoot_unit(handle, Int32(attackerID), Int32(targetID)) {
            selectedUnitID = attackerID
            selectedTargetID = targetID
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Fired", detail: "\(unitDisplayName(unit)) fired at \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Shot blocked")
    }

    @discardableResult
    public func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool = true) -> Bool {
        guard let unit = unitView(id: attackerID) else {
            return failAction("Unit unavailable", "Unit \(attackerID) is not present on the board.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .assault, unit.can_assault_now else {
            return failAction("Assault blocked", "\(unitDisplayName(unit)) cannot assault in the current phase.")
        }
        let followUp = advance ? TE_FOLLOW_UP_ADVANCE : TE_FOLLOW_UP_CONSOLIDATE
        if game_assault_unit(handle, Int32(attackerID), Int32(targetID), followUp) {
            selectedUnitID = attackerID
            selectedTargetID = targetID
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Assaulted", detail: "\(unitDisplayName(unit)) assaulted \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Assault blocked")
    }

    @discardableResult
    public func shootSelectedTarget() -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before shooting.")
        }
        guard let targetID = selectedTargetID else {
            return failAction("No target selected", "Select an enemy unit before shooting.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .shooting, unit.can_shoot_now else {
            return failAction("Shooting blocked", "\(unitDisplayName(unit)) cannot shoot in the current phase.")
        }

        if game_shoot_unit(handle, Int32(unit.id), Int32(targetID)) {
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Fired", detail: "\(unitDisplayName(unit)) fired at \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Shot blocked")
    }

    public func advancePhase() {
        game_advance_phase(handle)
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
        let view = game_view(handle)
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Phase advanced", detail: "\(NativeBoardPlayer(view.active_player).rawValue) \(NativeBoardPhase(view.phase).rawValue), turn \(Int(view.turn_number)).")
    }

    @discardableResult
    public func resolveFirstPendingChoice() -> Bool {
        let hitAllocation = game_pending_hit_allocation_view(handle)
        if hitAllocation.active {
            let result = game_choose_pending_hit_allocation(handle, 0)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Hit allocation resolved" : "Hit allocation blocked",
                detail: result ? "Applied the first legal damage allocation." : lastEngineError()
            )
            return result
        }

        let weaponChoice = game_pending_weapon_destroy_view(handle)
        if weaponChoice.active, game_pending_weapon_destroy_option_count(handle) > 0 {
            let option = game_pending_weapon_destroy_option_view(handle, 0)
            let result = game_choose_pending_weapon_destroy(handle, option.weapon_index)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Weapon damage resolved" : "Weapon damage blocked",
                detail: result ? "Applied the first legal weapon-damage option." : lastEngineError()
            )
            return result
        }

        return false
    }

    private func unitSnapshots() -> [NativeBoardUnitSnapshot] {
        (0..<Int(game_unit_count(handle))).map { index in
            let unit = game_unit_view(handle, Int32(index))
            let engineName = nativeBoardCString(unit.name)
            let nativeUnit = nativeUnitByEngineID[Int(unit.id)]
            let engineKind = unitKindName(unit.kind)
            return NativeBoardUnitSnapshot(
                id: Int(unit.id),
                name: nativeUnit?.name ?? engineName,
                engineName: engineName,
                nativeUnitID: nativeUnit?.id,
                owner: NativeBoardPlayer(unit.owner),
                kind: engineKind,
                mobility: nativeUnit?.mobility.rawValue ?? engineKind,
                role: nativeUnit?.role ?? engineKind,
                historicalNote: nativeUnit?.historicalNote ?? "",
                x: Double(unit.x),
                y: Double(unit.y),
                facingDegrees: Double(unit.facing_degrees),
                totalWoundsRemaining: Int(unit.total_wounds_remaining),
                destroyed: unit.destroyed,
                inCover: unit.in_cover,
                hullDown: unit.hull_down,
                pinned: unit.pinned,
                canMoveNow: unit.can_move_now,
                canShootNow: unit.can_shoot_now,
                canAssaultNow: unit.can_assault_now,
                selected: Int(unit.id) == selectedUnitID,
                targeted: Int(unit.id) == selectedTargetID
            )
        }
    }

    private func zoneSnapshots() -> [NativeBoardZoneSnapshot] {
        (0..<Int(game_zone_count(handle))).map { index in
            let zone = game_zone_view(handle, Int32(index))
            return NativeBoardZoneSnapshot(
                id: Int(zone.id),
                name: nativeBoardCString(zone.name),
                kind: terrainKindName(zone.kind),
                x: Double(zone.rect.x),
                y: Double(zone.rect.y),
                width: Double(zone.rect.width),
                height: Double(zone.rect.height),
                coverSave: Int(zone.cover_save),
                blocksLineOfSight: zone.blocks_line_of_sight,
                hullDown: zone.hull_down
            )
        }
    }

    private func objectiveSnapshots() -> [NativeBoardObjectiveSnapshot] {
        (0..<Int(game_objective_count(handle))).map { index in
            let objective = game_objective_view(handle, Int32(index))
            return NativeBoardObjectiveSnapshot(
                id: Int(objective.id),
                name: nativeBoardCString(objective.name),
                x: Double(objective.x),
                y: Double(objective.y),
                radius: Double(objective.radius),
                controller: NativeBoardPlayer(objective.controller),
                playerPresence: Int(objective.player_one_presence),
                opponentPresence: Int(objective.player_two_presence)
            )
        }
    }

    private func logLines() -> [String] {
        (0..<Int(game_log_count(handle))).map { index in
            nativeBoardCString(game_log_line(handle, Int32(index)))
        }
    }

    private func selectedUnitView() -> unit_view_t? {
        guard let selectedUnitID else {
            return nil
        }
        return unitView(id: selectedUnitID)
    }

    private func unitView(id: Int) -> unit_view_t? {
        return (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == id }
    }

    private func nearestObjective(to unit: unit_view_t) -> objective_view_t? {
        (0..<Int(game_objective_count(handle))).lazy
            .map { game_objective_view(self.handle, Int32($0)) }
            .min { lhs, rhs in
                distance(from: unit, to: lhs) < distance(from: unit, to: rhs)
            }
    }

    private func priorityObjectives(named priorityNames: [String]) -> [objective_view_t] {
        let objectives = (0..<Int(game_objective_count(handle))).map { game_objective_view(self.handle, Int32($0)) }
        var matches: [objective_view_t] = []
        for priorityName in priorityNames {
            let priority = normalized(priorityName)
            if let objective = objectives.first(where: { objective in
                let name = normalized(nativeBoardCString(objective.name))
                return name.contains(priority) || priority.contains(name)
            }), !matches.contains(where: { $0.id == objective.id }) {
                matches.append(objective)
            }
        }
        return matches
    }

    private func move(_ unit: unit_view_t, toward objective: objective_view_t, maxDistance: Double) -> Bool {
        let dx = Double(objective.x) - Double(unit.x)
        let dy = Double(objective.y) - Double(unit.y)
        let length = max(0.01, sqrt(dx * dx + dy * dy))
        let baseStep = min(maxDistance, length)
        let candidateDistances = [baseStep, baseStep / 2, min(1.5, length), min(0.75, length)]
            .filter { $0 > 0.05 }
        let xDirection = dx == 0 ? 0 : dx / abs(dx)
        let yDirection = dy == 0 ? 0 : dy / abs(dy)

        for distance in candidateDistances {
            let candidates = [
                (
                    Double(unit.x) + (dx / length) * distance,
                    Double(unit.y) + (dy / length) * distance
                ),
                (
                    Double(unit.x) + xDirection * distance,
                    Double(unit.y)
                ),
                (
                    Double(unit.x),
                    Double(unit.y) + yDirection * distance
                ),
            ]

            for candidate in candidates {
                let x = clamp(candidate.0, min: 1, max: loadout.blueprint.engineBoardFrame.width - 1)
                let y = clamp(candidate.1, min: 1, max: loadout.blueprint.engineBoardFrame.height - 1)
                if game_move_unit(handle, Int32(unit.id), Float(x), Float(y)) {
                    lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unitDisplayName(unit)) advanced toward \(nativeBoardCString(objective.name)).")
                    return true
                }
            }
        }
        return failFromEngine("Move blocked")
    }

    private func unitName(id: Int) -> String {
        (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == id }
            .map(unitDisplayName) ?? "Unit \(id)"
    }

    private func unitDisplayName(_ unit: unit_view_t) -> String {
        nativeUnitByEngineID[Int(unit.id)]?.name ?? nativeBoardCString(unit.name)
    }

    private static func nativeUnitMap(handle: OpaquePointer, instance: NativeBattleInstance) -> [Int: NativeBattleUnit] {
        let nativeBySide: [NativeBoardPlayer: [NativeBattleUnit]] = [
            .player: instance.units.filter { $0.side == .player },
            .guderianAI: instance.units.filter { $0.side == .guderianAI },
        ]
        var sideOffsets: [NativeBoardPlayer: Int] = [:]
        var result: [Int: NativeBattleUnit] = [:]

        for index in 0..<Int(game_unit_count(handle)) {
            let unit = game_unit_view(handle, Int32(index))
            let owner = NativeBoardPlayer(unit.owner)
            guard owner == .player || owner == .guderianAI, !unit.destroyed, !unit.embarked else {
                continue
            }
            let offset = sideOffsets[owner, default: 0]
            sideOffsets[owner] = offset + 1
            if let nativeUnit = nativeBySide[owner]?[safe: offset] {
                result[Int(unit.id)] = nativeUnit
            }
        }
        return result
    }

    private func failFromEngine(_ title: String) -> Bool {
        failAction(title, lastEngineError())
    }

    private func failAction(_ title: String, _ detail: String) -> Bool {
        lastAction = NativeBoardActionMessage(status: .blocked, title: title, detail: detail)
        return false
    }

    private func lastEngineError() -> String {
        let error = nativeBoardCString(game_last_error(handle))
        return error.isEmpty ? "The engine rejected the action." : error
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    private func normalized(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private func distance(from unit: unit_view_t, to objective: objective_view_t) -> Double {
    let dx = Double(unit.x) - Double(objective.x)
    let dy = Double(unit.y) - Double(objective.y)
    return sqrt(dx * dx + dy * dy)
}

private func distance(from lhs: unit_view_t, to rhs: unit_view_t) -> Double {
    let dx = Double(lhs.x) - Double(rhs.x)
    let dy = Double(lhs.y) - Double(rhs.y)
    return sqrt(dx * dx + dy * dy)
}

private func nativeBoardCString(_ pointer: UnsafePointer<CChar>?) -> String {
    guard let pointer else {
        return ""
    }
    return String(cString: pointer)
}

private func unitKindName(_ kind: unit_kind_t) -> String {
    switch kind {
    case TE_UNIT_VEHICLE:
        return "Vehicle"
    case TE_UNIT_ASSAULT_GUN:
        return "Assault gun"
    default:
        return "Infantry"
    }
}

private func terrainKindName(_ kind: terrain_kind_t) -> String {
    switch kind {
    case TE_TERRAIN_DIFFICULT:
        return "Difficult"
    case TE_TERRAIN_IMPASSABLE:
        return "Impassable"
    default:
        return "Open"
    }
}
