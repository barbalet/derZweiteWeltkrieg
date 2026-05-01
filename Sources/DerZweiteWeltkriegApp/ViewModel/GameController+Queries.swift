import Foundation
import CoreGraphics
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

extension GameController {
    var isDeploymentMode: Bool {
        appMode == .deployment
    }

    var isHumanTurn: Bool {
        game.activePlayer == TE_PLAYER_ONE && mission.winner == nil
    }

    var resumeBattleButtonTitle: String {
        resumableAppMode == .deployment ? "Resume Deployment" : "Resume Current Battle"
    }

    var selectedUnit: UnitSnapshot? {
        guard let id = selectedUnitID else { return nil }
        return units.first(where: { $0.id == id })
    }

    var selectedTarget: UnitSnapshot? {
        guard let id = selectedTargetID else { return nil }
        return units.first(where: { $0.id == id })
    }

    var hasPendingDecision: Bool {
        pendingWeaponDestroyChoice != nil || pendingHitAllocationChoice != nil
    }

    var selectedUnitProfileGroups: [ProfileGroupSnapshot] {
        guard let unit = selectedUnit, unit.mixedProfiles else { return [] }
        let count = Int(game_unit_profile_group_count(handle, Int32(unit.id)))
        return (0..<count).compactMap { index in
            let raw = game_unit_profile_group_view(handle, Int32(unit.id), Int32(index))
            guard raw.name != nil else {
                return nil
            }
            return ProfileGroupSnapshot(raw: raw)
        }
    }

    var pendingHitAllocationGroups: [ProfileGroupSnapshot] {
        guard let pendingHitAllocationChoice else { return [] }
        let count = Int(game_unit_profile_group_count(handle, Int32(pendingHitAllocationChoice.targetID)))
        return (0..<count).compactMap { index in
            let raw = game_unit_profile_group_view(handle, Int32(pendingHitAllocationChoice.targetID), Int32(index))
            guard raw.name != nil else {
                return nil
            }
            return ProfileGroupSnapshot(raw: raw)
        }
    }

    var renderableUnits: [UnitSnapshot] {
        units.filter { !$0.embarked }
    }

    var playerOneArmy: ArmyReference? {
        armyReference(id: playerOneArmyID)
    }

    var playerTwoArmy: ArmyReference? {
        armyReference(id: playerTwoArmyID)
    }

    var playerCatalogUnits: [ArmyCatalogUnitSnapshot] {
        catalogUnits(for: playerOneArmy?.preset ?? TE_ARMY_DEMO)
    }

    var playerSelectedPoints: Int {
        points(for: playerOneArmy?.preset ?? TE_ARMY_DEMO, selections: currentPlayerSelections())
    }

    var playerSelectedUnitCount: Int {
        currentPlayerSelections().reduce(0) { $0 + $1.count }
    }

    var battlePlayerSelections: [ArmyListSelection] {
        currentBattleConfiguration?.playerSelections ?? []
    }

    var battleAISelections: [ArmyListSelection] {
        currentBattleConfiguration?.aiSelections ?? []
    }

    func selectedPlayerCount(for catalogID: Int) -> Int {
        playerUnitCounts[catalogID] ?? 0
    }

    func catalogUnit(for armyID: String, catalogID: Int) -> ArmyCatalogUnitSnapshot? {
        guard let army = armyReference(id: armyID) else {
            return nil
        }
        return catalogUnits(for: army.preset).first(where: { $0.id == catalogID })
    }

    func selectionDetails(for armyID: String, selections: [ArmyListSelection]) -> [(ArmyCatalogUnitSnapshot, Int)] {
        selections.compactMap { selection in
            guard let unit = catalogUnit(for: armyID, catalogID: selection.catalogID) else {
                return nil
            }
            return (unit, selection.count)
        }
    }

    var playerOneRosterPreview: ArmyRosterPreviewSnapshot {
        rosterPreview(for: playerOneArmy?.preset ?? TE_ARMY_DEMO, forceIndex: playerOneForceIndex)
    }

    var playerTwoRosterPreview: ArmyRosterPreviewSnapshot {
        rosterPreview(for: playerTwoArmy?.preset ?? TE_ARMY_DEMO, forceIndex: playerTwoForceIndex)
    }

    var playerOneForceOptions: [ArmyForceOptionSnapshot] {
        forceOptions(for: playerOneArmy?.preset ?? TE_ARMY_DEMO)
    }

    var playerTwoForceOptions: [ArmyForceOptionSnapshot] {
        forceOptions(for: playerTwoArmy?.preset ?? TE_ARMY_DEMO)
    }

    var loadedMatchupText: String {
        "\(armyName(for: loadedPlayerOneArmy)) (\(forceName(for: loadedPlayerOneArmy, index: loadedPlayerOneForceIndex))) vs \(armyName(for: loadedPlayerTwoArmy)) (\(forceName(for: loadedPlayerTwoArmy, index: loadedPlayerTwoForceIndex)))"
    }

    var selectedMatchupText: String {
        "\(playerOneArmy?.displayName ?? "Unassigned") (\(selectedPlayerOneForceName())) vs \(playerTwoArmy?.displayName ?? "Unassigned") (\(selectedPlayerTwoForceName()))"
    }

    var hasPendingArmySelectionChanges: Bool {
        let selectedPlayerOne = playerOneArmy?.preset ?? TE_ARMY_DEMO
        let selectedPlayerTwo = playerTwoArmy?.preset ?? TE_ARMY_DEMO
        let selectedPlayerOneForce = sanitizedForceIndex(playerOneForceIndex, for: selectedPlayerOne)
        let selectedPlayerTwoForce = sanitizedForceIndex(playerTwoForceIndex, for: selectedPlayerTwo)
        return selectedPlayerOne != loadedPlayerOneArmy ||
            selectedPlayerTwo != loadedPlayerTwoArmy ||
            selectedPlayerOneForce != loadedPlayerOneForceIndex ||
            selectedPlayerTwoForce != loadedPlayerTwoForceIndex
    }

    var activeUnits: [UnitSnapshot] {
        units
            .filter {
                if isDeploymentMode {
                    return $0.owner == TE_PLAYER_ONE && !$0.destroyed && !$0.embarked
                }
                return $0.owner == game.activePlayer && !$0.destroyed && !$0.embarked
            }
            .sorted { $0.id < $1.id }
    }

    func rangeBetweenSelection() -> CGFloat? {
        guard let unit = selectedUnit, let target = selectedTarget else { return nil }
        let centerDistance = hypot(unit.x - target.x, unit.y - target.y)
        return max(0, centerDistance - unit.footprintRadius - target.footprintRadius)
    }

    func eligibleEmbarkTransports(for unit: UnitSnapshot) -> [UnitSnapshot] {
        units.filter { candidate in
            candidate.owner == unit.owner &&
            candidate.id != unit.id &&
            candidate.transportCapacity > 0 &&
            candidate.embarkedUnitID == 0 &&
            !candidate.destroyed
        }
    }

    func embarkedPassenger(for transport: UnitSnapshot) -> UnitSnapshot? {
        guard transport.embarkedUnitID > 0 else { return nil }
        return units.first(where: { $0.id == transport.embarkedUnitID })
    }

    func canFirePassenger(from transport: UnitSnapshot) -> Bool {
        guard game.phase == TE_PHASE_SHOOTING,
              selectedTarget != nil,
              transport.transportCapacity > 0,
              transport.embarkedUnitID > 0,
              let passenger = embarkedPassenger(for: transport) else {
            return false
        }

        return !transport.destroyed && !passenger.shotThisTurn && !passenger.pinned && !passenger.fallingBack
    }

    func canManipulate(_ unit: UnitSnapshot) -> Bool {
        if isDeploymentMode {
            return unit.owner == TE_PLAYER_ONE && !unit.destroyed && !unit.embarked
        }
        return isHumanTurn && !isAITurnInProgress && unit.canMoveNow && !unit.destroyed && !unit.embarked
    }

    func distance(from lhs: UnitSnapshot, to rhs: UnitSnapshot) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
