import Foundation
import CoreGraphics
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

extension GameController {
    func reset() {
        restartCurrentBattle()
    }

    func clearSelection() {
        selectedUnitID = nil
        selectedTargetID = nil
    }

    func swapArmyReferences() {
        let originalPlayerOne = playerOneArmyID
        let originalPlayerOneForce = playerOneForceIndex
        playerOneArmyID = playerTwoArmyID
        playerOneForceIndex = playerTwoForceIndex
        playerTwoArmyID = originalPlayerOne
        playerTwoForceIndex = originalPlayerOneForce
        reconcileForceSelections()
    }

    func clearTarget() {
        selectedTargetID = nil
    }

    func advancePhase() {
        guard appMode == .battle, isHumanTurn, !isAITurnInProgress else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .advancePhase))
    }

    func selectUnit(_ unit: UnitSnapshot) {
        guard appMode != .setup, !isAITurnInProgress else { return }

        if appMode == .deployment {
            guard unit.owner == DZW_PLAYER_ONE, !unit.destroyed, !unit.embarked else { return }
            selectedUnitID = unit.id
            selectedTargetID = nil
            return
        }

        guard isHumanTurn else { return }
        if unit.owner == game.activePlayer {
            selectedUnitID = unit.id
            if let target = selectedTarget, target.owner == unit.owner {
                selectedTargetID = nil
            }
            return
        }

        selectedTargetID = unit.id
    }

    func cycleActiveUnit(forward: Bool) {
        let candidates = activeUnits
        guard !candidates.isEmpty else { return }

        guard let selectedUnitID,
              let currentIndex = candidates.firstIndex(where: { $0.id == selectedUnitID }) else {
            self.selectedUnitID = candidates.first?.id
            if let target = selectedTarget, target.owner == game.activePlayer {
                selectedTargetID = nil
            }
            return
        }

        let offset = forward ? 1 : -1
        let nextIndex = (currentIndex + offset + candidates.count) % candidates.count
        self.selectedUnitID = candidates[nextIndex].id
        if let target = selectedTarget, target.owner == game.activePlayer {
            selectedTargetID = nil
        }
    }

    func selectNearestEnemy() {
        guard appMode == .battle else { return }
        guard let unit = selectedUnit else { return }
        selectedTargetID = units
            .filter { $0.owner != unit.owner && !$0.destroyed && !$0.embarked }
            .min { lhs, rhs in
                distance(from: unit, to: lhs) < distance(from: unit, to: rhs)
            }?
            .id
    }

    func moveUnit(id: Int, to point: CGPoint) {
        guard appMode != .setup, !isAITurnInProgress else { return }

        let kind: RecordedBattleAction.Kind
        switch appMode {
        case .deployment:
            kind = .deployUnit
        case .battle:
            guard isHumanTurn else { return }
            kind = .moveUnit
        case .setup:
            return
        }

        _ = executeRecordedAction(
            RecordedBattleAction(
                kind: kind,
                unitID: id,
                pointX: point.x,
                pointY: point.y
            )
        )
    }

    func tankShockSelected() {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit, let target = selectedTarget else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .tankShock, unitID: unit.id, targetID: target.id))
    }

    func embarkSelected(into transportID: Int) {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit else { return }
        let succeeded = executeRecordedAction(RecordedBattleAction(kind: .embark, unitID: unit.id, transportID: transportID))
        guard succeeded else { return }
        if units.contains(where: { $0.id == transportID }) {
            selectedUnitID = transportID
        }
        selectedTargetID = nil
    }

    func disembarkSelected() {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let transport = selectedUnit else { return }
        let passengerID = transport.embarkedUnitID
        let succeeded = executeRecordedAction(RecordedBattleAction(kind: .disembark, transportID: transport.id))
        guard succeeded else { return }
        if passengerID > 0, units.contains(where: { $0.id == passengerID }) {
            selectedUnitID = passengerID
        }
    }

    func rotateSelected(by degrees: CGFloat) {
        guard appMode != .setup, !isAITurnInProgress, let unit = selectedUnit else { return }

        let kind: RecordedBattleAction.Kind
        switch appMode {
        case .deployment:
            kind = .deployRotate
        case .battle:
            guard isHumanTurn else { return }
            kind = .rotate
        case .setup:
            return
        }

        _ = executeRecordedAction(
            RecordedBattleAction(
                kind: kind,
                unitID: unit.id,
                degrees: unit.facingDegrees + degrees
            )
        )
    }

    func toggleCover(_ enabled: Bool) {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .toggleCover, unitID: unit.id, enabled: enabled))
    }

    func toggleHullDown(_ enabled: Bool) {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .toggleHullDown, unitID: unit.id, enabled: enabled))
    }

    func useSmoke() {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .useSmoke, unitID: unit.id))
    }

    func shootSelected() {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit, let target = selectedTarget else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .shoot, unitID: unit.id, targetID: target.id))
    }

    func firePassengerSelected() {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let transport = selectedUnit, let target = selectedTarget else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .firePassenger, targetID: target.id, transportID: transport.id))
    }

    func assaultSelected(followUp: FollowUpChoice) {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit, let target = selectedTarget else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .assault, unitID: unit.id, targetID: target.id, followUp: followUp))
    }

    func resolvePendingWeaponDestroy(_ option: VehicleWeaponOptionSnapshot) {
        _ = executeRecordedAction(RecordedBattleAction(kind: .chooseWeaponDestroy, optionID: option.id))
    }

    func resolvePendingHitAllocation(_ group: ProfileGroupSnapshot) {
        _ = executeRecordedAction(RecordedBattleAction(kind: .chooseHitAllocation, groupIndex: group.id))
    }

    func setPreferredCasualtyGroup(_ groupIndex: Int?) {
        guard appMode == .battle, !isAITurnInProgress, isHumanTurn, let unit = selectedUnit else { return }
        _ = executeRecordedAction(RecordedBattleAction(kind: .setPreferredCasualtyGroup, unitID: unit.id, groupIndex: groupIndex))
    }
}
