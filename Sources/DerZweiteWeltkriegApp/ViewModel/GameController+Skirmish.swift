import Foundation
import CoreGraphics
import AppKit
import UniformTypeIdentifiers
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

extension GameController {
    func startBattleFromSetup() {
        guard let playerArmy = playerOneArmy else {
            setupMessage = "Choose a nation before starting an operation."
            return
        }

        let playerSelections = currentPlayerSelections()
        let playerPoints = points(for: playerArmy.preset, selections: playerSelections)
        guard playerPoints > 0 else {
            setupMessage = "Add at least one squad, gun, or vehicle to your force before starting."
            return
        }
        guard playerPoints <= pointsLimit else {
            setupMessage = "Trim your list to fit the \(pointsLimit)-point cap."
            return
        }
        guard let opponentPlan = currentOpponentPlan else {
            setupMessage = "The computer could not build an opposing force yet."
            return
        }

        let configuration = SkirmishConfiguration(
            seed: UInt32(seedText) ?? 1_944,
            pointsLimit: pointsLimit,
            playerArmyID: playerArmy.id,
            playerSelections: playerSelections,
            aiArmyID: opponentPlan.army.id,
            aiSelections: opponentPlan.selections
        )
        loadConfiguration(configuration, replaying: [], mode: .deployment)
        setupMessage = "Deployment is ready. Drag squads, guns, and vehicles into position, then begin the battle."
    }

    func returnToSetup() {
        cancelAI()
        clearSelection()
        appMode = .setup
        setupMessage = ""
        refreshOpponentPlan()
    }

    func resumeCurrentBattle() {
        guard currentBattleConfiguration != nil else { return }
        appMode = resumableAppMode
        if appMode == .battle {
            scheduleAITurnIfNeeded()
        }
    }

    func restartCurrentBattle() {
        guard let currentBattleConfiguration else {
            startBattleFromSetup()
            return
        }
        let updatedConfiguration = SkirmishConfiguration(
            seed: UInt32(seedText) ?? currentBattleConfiguration.seed,
            pointsLimit: currentBattleConfiguration.pointsLimit,
            playerArmyID: currentBattleConfiguration.playerArmyID,
            playerSelections: currentBattleConfiguration.playerSelections,
            aiArmyID: currentBattleConfiguration.aiArmyID,
            aiSelections: currentBattleConfiguration.aiSelections
        )
        loadConfiguration(updatedConfiguration, replaying: [], mode: resumableAppMode)
        setupMessage = ""
    }

    func beginBattle() {
        guard currentBattleConfiguration != nil else {
            setupMessage = "Load an operation before trying to begin play."
            return
        }
        clearTarget()
        setupMessage = ""
        appMode = .battle
        resumableAppMode = .battle
        scheduleAITurnIfNeeded()
    }

    func saveBattleToJSON() {
        guard let currentBattleConfiguration else {
            setupMessage = "Start or load an operation before saving."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = "derzweiteweltkrieg-operation.json"
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let document = SavedSkirmishDocument(
            version: 2,
            configuration: currentBattleConfiguration,
            actions: recordedActions,
            mode: appMode == .setup ? resumableAppMode : appMode
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(document)
            try data.write(to: url, options: Data.WritingOptions.atomic)
            setupMessage = "Saved operation to \(url.lastPathComponent)."
        } catch {
            setupMessage = "Failed to save operation: \(error.localizedDescription)"
        }
    }

    func loadBattleFromJSON() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(SavedSkirmishDocument.self, from: data)
            loadConfiguration(document.configuration, replaying: document.actions, mode: document.mode)
            setupMessage = "Loaded \(url.lastPathComponent)."
        } catch {
            setupMessage = "Failed to load operation: \(error.localizedDescription)"
        }
    }

    func suggestedOpponentPlan() -> GeneratedOpponentPlan? {
        guard let playerArmy = playerOneArmy else {
            return nil
        }

        let playerSelections = currentPlayerSelections()
        let playerPoints = points(for: playerArmy.preset, selections: playerSelections)
        guard playerPoints > 0 else {
            return nil
        }

        let targetPoints = min(pointsLimit, playerPoints)
        let preferredOpponents = armyReferences.filter { $0.opposes(playerArmy) }
        let candidateArmies = preferredOpponents.isEmpty ? armyReferences : preferredOpponents

        var bestPlan: GeneratedOpponentPlan?
        for army in candidateArmies {
            guard let plan = bestOpponentPlan(for: army, targetPoints: targetPoints) else {
                continue
            }
            guard let currentBest = bestPlan else {
                bestPlan = plan
                continue
            }

            let currentDelta = abs(currentBest.points - targetPoints)
            let newDelta = abs(plan.points - targetPoints)
            if newDelta < currentDelta || (newDelta == currentDelta && plan.points > currentBest.points) {
                bestPlan = plan
            }
        }

        return bestPlan
    }

    @discardableResult
    func executeRecordedAction(_ action: RecordedBattleAction, record: Bool = true, triggerAI: Bool = true) -> Bool {
        let succeeded: Bool

        switch action.kind {
        case .deployUnit:
            guard let unitID = action.unitID,
                  let pointX = action.pointX,
                  let pointY = action.pointY else {
                return false
            }
            succeeded = game_deploy_unit(handle, Int32(unitID), Float(pointX), Float(pointY))
        case .deployRotate:
            guard let unitID = action.unitID, let degrees = action.degrees else {
                return false
            }
            succeeded = game_deploy_rotate_unit(handle, Int32(unitID), Float(degrees))
        case .advancePhase:
            game_advance_phase(handle)
            succeeded = true
        case .moveUnit:
            guard let unitID = action.unitID,
                  let pointX = action.pointX,
                  let pointY = action.pointY else {
                return false
            }
            succeeded = game_move_unit(handle, Int32(unitID), Float(pointX), Float(pointY))
        case .tankShock:
            guard let unitID = action.unitID, let targetID = action.targetID else {
                return false
            }
            succeeded = game_tank_shock_unit(handle, Int32(unitID), Int32(targetID))
        case .embark:
            guard let unitID = action.unitID, let transportID = action.transportID else {
                return false
            }
            succeeded = game_embark_unit(handle, Int32(unitID), Int32(transportID))
        case .disembark:
            guard let transportID = action.transportID else {
                return false
            }
            succeeded = game_disembark_unit(handle, Int32(transportID))
        case .rotate:
            guard let unitID = action.unitID, let degrees = action.degrees else {
                return false
            }
            succeeded = game_rotate_unit(handle, Int32(unitID), Float(degrees))
        case .toggleCover:
            guard let unitID = action.unitID, let enabled = action.enabled else {
                return false
            }
            succeeded = game_toggle_cover(handle, Int32(unitID), enabled)
        case .toggleHullDown:
            guard let unitID = action.unitID, let enabled = action.enabled else {
                return false
            }
            succeeded = game_toggle_hull_down(handle, Int32(unitID), enabled)
        case .useSmoke:
            guard let unitID = action.unitID else {
                return false
            }
            succeeded = game_use_smoke(handle, Int32(unitID))
        case .shoot:
            guard let unitID = action.unitID, let targetID = action.targetID else {
                return false
            }
            succeeded = game_shoot_unit(handle, Int32(unitID), Int32(targetID))
        case .firePassenger:
            guard let transportID = action.transportID, let targetID = action.targetID else {
                return false
            }
            succeeded = game_fire_passenger(handle, Int32(transportID), Int32(targetID))
        case .assault:
            guard let unitID = action.unitID,
                  let targetID = action.targetID,
                  let followUp = action.followUp else {
                return false
            }
            succeeded = game_assault_unit(handle, Int32(unitID), Int32(targetID), followUp.cValue)
        case .chooseWeaponDestroy:
            guard let optionID = action.optionID else {
                return false
            }
            succeeded = game_choose_pending_weapon_destroy(handle, Int32(optionID))
        case .chooseHitAllocation:
            guard let groupIndex = action.groupIndex else {
                return false
            }
            succeeded = game_choose_pending_hit_allocation(handle, Int32(groupIndex))
        case .setPreferredCasualtyGroup:
            guard let unitID = action.unitID else {
                return false
            }
            succeeded = game_set_preferred_casualty_group(handle, Int32(unitID), Int32(action.groupIndex ?? -1))
        }

        reload()
        if succeeded && record {
            recordedActions.append(action)
        }
        if succeeded && triggerAI && !isReplayingBattle {
            scheduleAITurnIfNeeded()
        }
        return succeeded
    }

    func scheduleAITurnIfNeeded() {
        guard appMode == .battle,
              currentBattleConfiguration != nil,
              !isReplayingBattle,
              !isAITurnInProgress,
              mission.winner == nil,
              game.activePlayer == TE_PLAYER_TWO else {
            return
        }
        if pendingWeaponDestroyChoice?.chooserOwner == TE_PLAYER_ONE || pendingHitAllocationChoice?.chooserOwner == TE_PLAYER_ONE {
            return
        }

        isAITurnInProgress = true
        aiTask = Task { [weak self] in
            await self?.performAITurn()
        }
    }

    private func performAITurn() async {
        while !Task.isCancelled &&
                appMode == .battle &&
                game.activePlayer == TE_PLAYER_TWO &&
                mission.winner == nil {
            if humanDecisionIsBlockingAI {
                break
            }

            if resolveAIPendingChoices() {
                await Task.yield()
                continue
            }

            switch game.phase {
            case TE_PHASE_MOVEMENT:
                performAIMovementPhase()
            case TE_PHASE_SHOOTING:
                performAIShootingPhase()
            case TE_PHASE_ASSAULT:
                performAIAssaultPhase()
            default:
                _ = executeRecordedAction(RecordedBattleAction(kind: .advancePhase), record: true, triggerAI: false)
            }

            await Task.yield()
        }

        aiTask = nil
        isAITurnInProgress = false
    }

    private var humanDecisionIsBlockingAI: Bool {
        pendingWeaponDestroyChoice?.chooserOwner == TE_PLAYER_ONE || pendingHitAllocationChoice?.chooserOwner == TE_PLAYER_ONE
    }

    private func resolveAIPendingChoices() -> Bool {
        if let pendingWeaponDestroyChoice, pendingWeaponDestroyChoice.chooserOwner == TE_PLAYER_TWO,
           let chosen = pendingWeaponDestroyChoice.options.max(by: { $0.id < $1.id }) {
            return executeRecordedAction(
                RecordedBattleAction(kind: .chooseWeaponDestroy, optionID: chosen.id),
                record: true,
                triggerAI: false
            )
        }

        if let pendingHitAllocationChoice, pendingHitAllocationChoice.chooserOwner == TE_PLAYER_TWO {
            let group = pendingHitAllocationGroups
                .filter { $0.models > 0 }
                .max {
                    if $0.toughness == $1.toughness {
                        return $0.save > $1.save
                    }
                    return $0.toughness < $1.toughness
                }
            if let group {
                return executeRecordedAction(
                    RecordedBattleAction(kind: .chooseHitAllocation, groupIndex: group.id),
                    record: true,
                    triggerAI: false
                )
            }
        }

        return false
    }

    private func performAIMovementPhase() {
        let unitIDs = activeUnits.map(\.id)
        for unitID in unitIDs {
            guard let unit = units.first(where: { $0.id == unitID }), unit.canMoveNow else {
                continue
            }
            if let target = aiMovementTarget(for: unit) {
                _ = attemptAIMove(for: unit, toward: target)
            }
            if humanDecisionIsBlockingAI {
                return
            }
        }

        _ = executeRecordedAction(RecordedBattleAction(kind: .advancePhase), record: true, triggerAI: false)
    }

    private func performAIShootingPhase() {
        let unitIDs = activeUnits.map(\.id)
        for unitID in unitIDs {
            guard let unit = units.first(where: { $0.id == unitID }) else {
                continue
            }

            if unit.canShootNow {
                for target in aiTargetCandidates(for: unit) {
                    let action = RecordedBattleAction(kind: .shoot, unitID: unit.id, targetID: target.id)
                    if executeRecordedAction(action, record: true, triggerAI: false) {
                        break
                    }
                }
            }

            guard !humanDecisionIsBlockingAI else {
                return
            }

            while resolveAIPendingChoices() {
                guard !humanDecisionIsBlockingAI else {
                    return
                }
            }

            if let updatedUnit = units.first(where: { $0.id == unitID }), updatedUnit.transportCapacity > 0, canFirePassenger(from: updatedUnit) {
                for target in aiTargetCandidates(for: updatedUnit) {
                    let action = RecordedBattleAction(kind: .firePassenger, targetID: target.id, transportID: updatedUnit.id)
                    if executeRecordedAction(action, record: true, triggerAI: false) {
                        break
                    }
                }
            }

            guard !humanDecisionIsBlockingAI else {
                return
            }

            while resolveAIPendingChoices() {
                guard !humanDecisionIsBlockingAI else {
                    return
                }
            }
        }

        _ = executeRecordedAction(RecordedBattleAction(kind: .advancePhase), record: true, triggerAI: false)
    }

    private func performAIAssaultPhase() {
        let unitIDs = activeUnits.map(\.id)
        for unitID in unitIDs {
            guard let unit = units.first(where: { $0.id == unitID }), unit.canAssaultNow else {
                continue
            }

            let candidates = aiTargetCandidates(for: unit)
                .filter { distance(from: unit, to: $0) - unit.footprintRadius - $0.footprintRadius <= 8.5 }
            for target in candidates {
                let action = RecordedBattleAction(kind: .assault, unitID: unit.id, targetID: target.id, followUp: .advance)
                if executeRecordedAction(action, record: true, triggerAI: false) {
                    break
                }
            }

            guard !humanDecisionIsBlockingAI else {
                return
            }

            while resolveAIPendingChoices() {
                guard !humanDecisionIsBlockingAI else {
                    return
                }
            }
        }

        _ = executeRecordedAction(RecordedBattleAction(kind: .advancePhase), record: true, triggerAI: false)
    }

    private func attemptAIMove(for unit: UnitSnapshot, toward target: CGPoint) -> Bool {
        for candidate in aiMovementCandidates(for: unit, toward: target) {
            let action = RecordedBattleAction(
                kind: .moveUnit,
                unitID: unit.id,
                pointX: candidate.x,
                pointY: candidate.y
            )
            if executeRecordedAction(action, record: true, triggerAI: false) {
                return true
            }
        }
        return false
    }

    private func aiMovementTarget(for unit: UnitSnapshot) -> CGPoint? {
        let objective = objectiveStates
            .sorted { lhs, rhs in
                objectivePriority(for: unit, objective: lhs) < objectivePriority(for: unit, objective: rhs)
            }
            .first
        if let objective {
            return CGPoint(x: objective.x, y: objective.y)
        }

        if let enemy = aiTargetCandidates(for: unit).first {
            return CGPoint(x: enemy.x, y: enemy.y)
        }

        return nil
    }

    private func objectivePriority(for unit: UnitSnapshot, objective: ObjectiveSnapshot) -> CGFloat {
        let ownershipPenalty: CGFloat = objective.controller == TE_PLAYER_TWO ? 100 : 0
        let distancePenalty = hypot(unit.x - objective.x, unit.y - objective.y)
        return ownershipPenalty + distancePenalty
    }

    private func aiMovementCandidates(for unit: UnitSnapshot, toward target: CGPoint) -> [CGPoint] {
        let maxDistance = aiMovementAllowance(for: unit)
        let dx = target.x - unit.x
        let dy = target.y - unit.y
        let baseAngle = atan2(dy, dx)
        let distance = max(0, hypot(dx, dy))
        guard distance > 0.25 else {
            return []
        }

        let stepDistances: [CGFloat] = stride(from: min(distance, maxDistance), through: 1.5, by: -1.5).map { $0 }
        let angleOffsets: [CGFloat] = [0, .pi / 8, -.pi / 8, .pi / 5, -.pi / 5]

        return stepDistances.flatMap { step in
            angleOffsets.map { offset in
                CGPoint(
                    x: clamp(unit.x + cos(baseAngle + offset) * step, min: unit.footprintRadius, max: Self.boardWidth - unit.footprintRadius),
                    y: clamp(unit.y + sin(baseAngle + offset) * step, min: unit.footprintRadius, max: Self.boardHeight - unit.footprintRadius)
                )
            }
        }
    }

    private func aiMovementAllowance(for unit: UnitSnapshot) -> CGFloat {
        if unit.kind == TE_UNIT_VEHICLE {
            return unit.fast ? 18 : 12
        }
        return 6
    }

    private func aiTargetCandidates(for unit: UnitSnapshot) -> [UnitSnapshot] {
        units
            .filter { $0.owner != unit.owner && !$0.destroyed && !$0.embarked }
            .sorted { lhs, rhs in
                aiTargetPriority(for: unit, target: lhs) < aiTargetPriority(for: unit, target: rhs)
            }
    }

    private func aiTargetPriority(for unit: UnitSnapshot, target: UnitSnapshot) -> CGFloat {
        let edgeDistance = max(0, distance(from: unit, to: target) - unit.footprintRadius - target.footprintRadius)
        let objectiveBias: CGFloat = objectiveStates.contains(where: {
            $0.controller != TE_PLAYER_TWO && hypot(target.x - $0.x, target.y - $0.y) <= max($0.radius + 3, 6)
        }) ? -12 : 0
        let vehicleBias: CGFloat = target.usesVehicleRules ? -4 : 0
        return edgeDistance + objectiveBias + vehicleBias
    }

    private func bestOpponentPlan(for army: ArmyReference, targetPoints: Int) -> GeneratedOpponentPlan? {
        let catalog = catalogUnits(for: army.preset)
        guard !catalog.isEmpty else {
            return nil
        }

        struct Choice {
            var counts: [Int: Int]
            var unitCount: Int
        }

        struct Item {
            let catalogID: Int
            let points: Int
        }

        let items = catalog.flatMap { unit in
            Array(repeating: Item(catalogID: unit.id, points: unit.points), count: unit.maxCount)
        }
        guard !items.isEmpty else {
            return nil
        }

        let cappedTarget = max(targetPoints, catalog.map(\.points).min() ?? 1)
        var dp: [Choice?] = Array(repeating: nil, count: cappedTarget + 1)
        dp[0] = Choice(counts: [:], unitCount: 0)

        for item in items {
            guard item.points <= cappedTarget else { continue }
            for total in stride(from: cappedTarget, through: item.points, by: -1) {
                guard let previous = dp[total - item.points] else { continue }
                var nextCounts = previous.counts
                nextCounts[item.catalogID, default: 0] += 1
                let nextChoice = Choice(counts: nextCounts, unitCount: previous.unitCount + 1)

                if let existing = dp[total] {
                    if nextChoice.unitCount > existing.unitCount {
                        dp[total] = nextChoice
                    }
                } else {
                    dp[total] = nextChoice
                }
            }
        }

        let bestTotal = stride(from: cappedTarget, through: 1, by: -1).first(where: { dp[$0] != nil })
        guard let bestTotal, let choice = dp[bestTotal] else {
            let fallback = catalog.min(by: { $0.points < $1.points })!
            return GeneratedOpponentPlan(
                army: army,
                selections: [ArmyListSelection(catalogID: fallback.id, count: 1)],
                points: fallback.points
            )
        }

        let selections = choice.counts
            .map { ArmyListSelection(catalogID: $0.key, count: $0.value) }
            .sorted { $0.catalogID < $1.catalogID }

        return GeneratedOpponentPlan(army: army, selections: selections, points: bestTotal)
    }

    private func loadConfiguration(_ configuration: SkirmishConfiguration, replaying actions: [RecordedBattleAction], mode: AppMode) {
        cancelAI()
        clearSelection()
        setupMessage = ""

        seedText = "\(configuration.seed)"
        pointsLimit = configuration.pointsLimit
        playerOneArmyID = configuration.playerArmyID
        playerTwoArmyID = configuration.aiArmyID
        playerUnitCounts = Dictionary(uniqueKeysWithValues: configuration.playerSelections.map { ($0.catalogID, $0.count) })
        currentBattleConfiguration = configuration
        if let aiArmy = armyReference(id: configuration.aiArmyID) {
            currentOpponentPlan = GeneratedOpponentPlan(
                army: aiArmy,
                selections: configuration.aiSelections,
                points: points(for: aiArmy.preset, selections: configuration.aiSelections)
            )
        } else {
            currentOpponentPlan = nil
        }
        recordedActions = []
        appMode = mode
        resumableAppMode = mode

        withArmyEntryBuffers(configuration.playerSelections, configuration.aiSelections) { playerEntries, aiEntries in
            game_reset_skirmish(
                handle,
                configuration.seed,
                armyReference(id: configuration.playerArmyID)?.preset ?? TE_ARMY_DEMO,
                playerEntries.baseAddress,
                Int32(playerEntries.count),
                armyReference(id: configuration.aiArmyID)?.preset ?? TE_ARMY_DEMO,
                aiEntries.baseAddress,
                Int32(aiEntries.count)
            )
        }

        reload()

        if !actions.isEmpty {
            isReplayingBattle = true
            for action in actions {
                _ = executeRecordedAction(action, record: false, triggerAI: false)
            }
            isReplayingBattle = false
            recordedActions = actions
            reload()
        }

        if mode == .deployment, selectedUnitID == nil {
            selectedUnitID = activeUnits.first?.id
        }

        scheduleAITurnIfNeeded()
    }

    private func withArmyEntryBuffers<T>(_ playerSelections: [ArmyListSelection], _ aiSelections: [ArmyListSelection], _ body: (UnsafeBufferPointer<army_list_entry_t>, UnsafeBufferPointer<army_list_entry_t>) -> T) -> T {
        let playerEntries = playerSelections.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }
        let aiEntries = aiSelections.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }
        return playerEntries.withUnsafeBufferPointer { playerBuffer in
            aiEntries.withUnsafeBufferPointer { aiBuffer in
                body(playerBuffer, aiBuffer)
            }
        }
    }

    private func cancelAI() {
        aiTask?.cancel()
        aiTask = nil
        isAITurnInProgress = false
    }
}

private func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
    Swift.min(Swift.max(value, minimum), maximum)
}
