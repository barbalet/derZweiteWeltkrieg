import DerZweiteWeltkriegCore
import Foundation

public enum CampaignAutomationStatus: String, Codable, Hashable, Sendable {
    case queued = "Queued"
    case running = "Running"
    case passed = "Passed"
    case warning = "Warning"
    case failed = "Failed"
    case blocked = "Blocked"

    public var isTerminalProblem: Bool {
        self == .failed || self == .blocked
    }
}

public enum CampaignAutomationIssueKind: String, Codable, Hashable, Sendable {
    case warning = "Warning"
    case failure = "Failure"
    case blocker = "Blocker"
}

public struct CampaignAutomationIssue: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: CampaignAutomationIssueKind
    public let stage: String
    public let title: String
    public let detail: String

    public init(id: String, kind: CampaignAutomationIssueKind, stage: String, title: String, detail: String) {
        self.id = id
        self.kind = kind
        self.stage = stage
        self.title = title
        self.detail = detail
    }
}

public struct CampaignAutomationStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let stage: String
    public let status: CampaignAutomationStatus
    public let title: String
    public let detail: String

    public init(id: String, stage: String, status: CampaignAutomationStatus, title: String, detail: String) {
        self.id = id
        self.stage = stage
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct CampaignAutomationOptions: Codable, Hashable, Sendable {
    public let maxPhaseAdvances: Int
    public let continueDiagnosticsAfterGateBlock: Bool
    public let completeWarningRuns: Bool

    public init(
        maxPhaseAdvances: Int = 80,
        continueDiagnosticsAfterGateBlock: Bool = true,
        completeWarningRuns: Bool = true
    ) {
        self.maxPhaseAdvances = max(12, maxPhaseAdvances)
        self.continueDiagnosticsAfterGateBlock = continueDiagnosticsAfterGateBlock
        self.completeWarningRuns = completeWarningRuns
    }

    public static let appDefault = CampaignAutomationOptions()
}

public struct CampaignAutomationBattleReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let order: Int
    public let title: String
    public let theater: CampaignTheater
    public let status: CampaignAutomationStatus
    public let playerArmy: String
    public let opponentArmy: String
    public let finalTurn: Int
    public let finalPhase: String
    public let engineWinner: String
    public let actionsAttempted: Int
    public let actionsSucceeded: Int
    public let phaseAdvances: Int
    public let engineUnitCount: Int
    public let engineObjectiveCount: Int
    public let completionRecord: CampaignCompletionRecord?
    public let debriefSummary: String
    public let nativeDemoBoardCompleted: Bool
    public let boardDiagnostic: NativeBoardDiagnosticReport?
    public let nativeBoardDiagnosticsPassed: Bool
    public let nativePolandPackCompleted: Bool
    public let nativePolandPackSummary: String
    public let nativeFrancePackCompleted: Bool
    public let nativeFrancePackSummary: String
    public let easternFrontFoundationReady: Bool
    public let easternFrontFoundationSummary: String
    public let nativeEasternFrontPackCompleted: Bool
    public let nativeEasternFrontPackSummary: String
    public let nativeAIEventPassReady: Bool
    public let nativeAIEventPassSummary: String
    public let nativeAIEventExecutionReady: Bool
    public let nativeAIEventExecutionSummary: String
    public let nativeBalanceUXReady: Bool
    public let nativeBalanceUXSummary: String
    public let nativePostShipAnalysisReady: Bool
    public let nativePostShipAnalysisSummary: String
    public let nativeSoakReady: Bool
    public let nativeSoakSummary: String
    public let playableScreenParityCompleted: Bool
    public let playableScreenParitySummary: String
    public let playableScreenParityBlockers: [String]
    public let steps: [CampaignAutomationStep]
    public let issues: [CampaignAutomationIssue]
    public let engineLogTail: [String]

    public var blockerCount: Int {
        issues.filter { $0.kind == .blocker }.count
    }

    public var failureCount: Int {
        issues.filter { $0.kind == .failure }.count
    }

    public var warningCount: Int {
        issues.filter { $0.kind == .warning }.count
    }
}

public struct CampaignAutomationRunReport: Codable, Hashable, Sendable {
    public let generatedAt: Date
    public let reports: [CampaignAutomationBattleReport]
    public let completionSummary: CampaignCompletionSummary

    public init(generatedAt: Date = Date(), reports: [CampaignAutomationBattleReport], completionSummary: CampaignCompletionSummary) {
        self.generatedAt = generatedAt
        self.reports = reports
        self.completionSummary = completionSummary
    }

    public var passedCount: Int {
        reports.filter { $0.status == .passed }.count
    }

    public var warningCount: Int {
        reports.filter { $0.status == .warning }.count
    }

    public var failedCount: Int {
        reports.filter { $0.status == .failed }.count
    }

    public var blockedCount: Int {
        reports.filter { $0.status == .blocked }.count
    }

    public var issueCount: Int {
        reports.reduce(0) { $0 + $1.issues.count }
    }

    public var actionSummary: String {
        let succeeded = reports.reduce(0) { $0 + $1.actionsSucceeded }
        let attempted = reports.reduce(0) { $0 + $1.actionsAttempted }
        return "\(succeeded)/\(attempted) actions"
    }
}

public enum CampaignAutomationRunner {
    public static func runCampaign(options: CampaignAutomationOptions = .appDefault) -> CampaignAutomationRunReport {
        var progress = CampaignProgress()
        var reports: [CampaignAutomationBattleReport] = []

        for scenario in GuderianCampaignCatalog.all.sorted(by: { $0.order < $1.order }) {
            reports.append(runBattle(scenario, progress: &progress, options: options))
        }

        return CampaignAutomationRunReport(
            reports: reports,
            completionSummary: progress.completionSummary(catalog: GuderianCampaignCatalog.all)
        )
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        progress: inout CampaignProgress,
        options: CampaignAutomationOptions = .appDefault
    ) -> CampaignAutomationBattleReport {
        var accumulator = AutomationAccumulator(scenario: scenario)
        let gateIsOpen = progress.isAvailable(scenario, in: .chronological)
        if gateIsOpen {
            accumulator.step("Campaign Gate", .passed, "Chronological gate opened", "\(scenario.title) is available after \(progress.completedCount) completions.")
        } else {
            accumulator.issue(.blocker, "Campaign Gate", "Scenario is locked", "\(scenario.title) was not available in chronological play. Earlier automation did not produce the completion state needed to proceed.")
            accumulator.step("Campaign Gate", .blocked, "Chronological gate blocked", "The app will continue a forced diagnostic probe so the underlying scenario can still be inspected.")
            guard options.continueDiagnosticsAfterGateBlock else {
                return accumulator.finalize(loadout: nil, game: nil)
            }
        }

        let loadout = NativeScenarioLoader.load(scenario, seed: seed(for: scenario))
        accumulator.step(
            "Native Loader",
            .passed,
            "Built scenario skirmish bridge",
            "\(loadout.playerArmyName) \(loadout.playerEntries.map { "\($0.catalogName) x\($0.count)" }.joined(separator: ", ")) vs \(loadout.opponentArmyName) \(loadout.opponentEntries.map { "\($0.catalogName) x\($0.count)" }.joined(separator: ", "))."
        )
        for warning in loadout.warnings {
            accumulator.issue(.warning, "Native Loader", warning.title, warning.detail)
            accumulator.step("Native Loader", .warning, warning.title, warning.detail)
        }

        guard let loadedGame = loadout.makeGame() else {
            accumulator.issue(.blocker, "Native Loader", "dzw skirmish allocation failed", "game_create_skirmish returned nil for \(scenario.title).")
            accumulator.step("Native Loader", .blocked, "Game creation failed", "No engine instance was returned.")
            return accumulator.finalize(loadout: loadout.summary, game: nil)
        }
        let game = loadedGame.handle
        accumulator.step(
            "Native Board",
            loadedGame.boardReport.isScenarioSpecific ? .passed : .warning,
            "Applied scenario board",
            "\(loadedGame.boardReport.appliedTerrainZoneCount)/\(loadedGame.boardReport.requestedTerrainZoneCount) terrain zones and \(loadedGame.boardReport.appliedObjectiveCount)/\(loadedGame.boardReport.requestedObjectiveCount) objectives; mission target \(loadedGame.boardReport.missionTargetScore)."
        )
        for note in loadedGame.boardReport.notes {
            accumulator.step("Native Board", .warning, "Board note", note)
        }
        accumulator.step(
            "Native Loader",
            loadedGame.deploymentReport.placedAnyScenarioUnit ? .passed : .warning,
            "Applied scenario deployments",
            "\(loadedGame.deploymentReport.succeeded)/\(loadedGame.deploymentReport.attempted) skirmish units placed from native blueprint."
        )
        for note in loadedGame.deploymentReport.notes {
            accumulator.step("Native Loader", .warning, "Deployment note", note)
        }

        let boardDiagnostic = NativeBoardDiagnosticsRunner.runBattle(
            scenario,
            seed: UInt32(165_000 + scenario.order)
        )
        accumulator.recordBoardDiagnostic(boardDiagnostic)

        validateScenarioData(scenario, accumulator: &accumulator)
        validateEngineState(game, scenario: scenario, accumulator: &accumulator)
        playEngineBattle(game, scenario: scenario, accumulator: &accumulator, options: options)
        completeNativeDemoBattleIfAvailable(scenario, accumulator: &accumulator)
        completeNativePolandBattleIfAvailable(scenario, accumulator: &accumulator)
        completeNativeFranceBattleIfAvailable(scenario, accumulator: &accumulator)
        recordEasternFrontFoundationIfAvailable(scenario, accumulator: &accumulator)
        completeNativeEasternFrontBattleIfAvailable(scenario, accumulator: &accumulator)
        recordNativeAIEventPass(scenario, accumulator: &accumulator)
        recordNativeAIEventExecution(scenario, accumulator: &accumulator)
        recordNativeBalanceUXAudit(scenario, accumulator: &accumulator)
        recordNativePostShipAnalysis(scenario, accumulator: &accumulator)
        recordNativeCampaignSoak(scenario, accumulator: &accumulator)
        recordPlayableScreenParityIfRouted(scenario, accumulator: &accumulator)

        let report = accumulator.finalize(loadout: loadout.summary, game: game)
        if report.status == .passed || (report.status == .warning && options.completeWarningRuns) {
            progress.recordCompletion(report.completionRecord ?? fallbackCompletionRecord(for: scenario, report: report))
        }
        return report
    }

    private static func completeNativeDemoBattleIfAvailable(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        guard scenario.isDemoScenario else {
            return
        }

        do {
            let completion = try NativeDemoParityRunner.runBattle(
                scenario,
                seed: UInt32(140_000 + scenario.order)
            )
            accumulator.recordDemoCompletion(completion)
        } catch {
            accumulator.issue(
                .failure,
                "Native Demo",
                "Native demo completion failed",
                "\(scenario.title) could not finish the cycle 300 native demo path: \(error)."
            )
            accumulator.step(
                "Native Demo",
                .failed,
                "Native demo completion failed",
                "\(error)"
            )
        }
    }

    private static func completeNativePolandBattleIfAvailable(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        guard NativePolandBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) else {
            return
        }

        do {
            let completion = try NativePolandPackRunner.runBattle(
                scenario,
                seed: UInt32(180_000 + scenario.order)
            )
            accumulator.recordPolandCompletion(completion)
        } catch {
            accumulator.issue(
                .failure,
                "Native Poland Pack",
                "Native Poland completion failed",
                "\(scenario.title) could not finish the cycle 325 native Poland path: \(error)."
            )
            accumulator.step(
                "Native Poland Pack",
                .failed,
                "Native Poland completion failed",
                "\(error)"
            )
        }
    }

    private static func completeNativeFranceBattleIfAvailable(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        guard NativeFranceBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) else {
            return
        }

        do {
            let completion = try NativeFrancePackRunner.runBattle(
                scenario,
                seed: UInt32(200_000 + scenario.order)
            )
            accumulator.recordFranceCompletion(completion)
        } catch {
            accumulator.issue(
                .failure,
                "Native France Pack",
                "Native France completion failed",
                "\(scenario.title) could not finish the cycle 345 native France path: \(error)."
            )
            accumulator.step(
                "Native France Pack",
                .failed,
                "Native France completion failed",
                "\(error)"
            )
        }
    }

    private static func recordEasternFrontFoundationIfAvailable(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        guard NativeEasternFrontBattlefieldFoundationCatalog.foundationBattleIDs.contains(scenario.id),
              let foundation = NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: scenario)
        else {
            return
        }
        accumulator.recordEasternFrontFoundation(
            foundation,
            ready: NativeEasternFrontBattlefieldFoundationCatalog.isFoundationReady(scenario)
        )
    }

    private static func completeNativeEasternFrontBattleIfAvailable(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        guard NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) else {
            return
        }

        do {
            let completion = try NativeEasternFrontPackRunner.runBattle(
                scenario,
                seed: UInt32(225_000 + scenario.order)
            )
            accumulator.recordEasternFrontCompletion(completion)
        } catch {
            accumulator.issue(
                .failure,
                "Native Eastern Front Pack",
                "Native Eastern Front completion failed",
                "\(scenario.title) could not finish the cycle 370 native Eastern Front path: \(error)."
            )
            accumulator.step(
                "Native Eastern Front Pack",
                .failed,
                "Native Eastern Front completion failed",
                "\(error)"
            )
        }
    }

    private static func recordNativeAIEventPass(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let report = NativeAIEventPassCatalog.report(for: scenario)
        accumulator.recordNativeAIEventPass(report)
    }

    private static func recordNativeAIEventExecution(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let report = NativeAIEventExecutionCatalog.report(for: scenario)
        accumulator.recordNativeAIEventExecution(report)
    }

    private static func recordNativeBalanceUXAudit(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let report = NativeBalanceUXAuditCatalog.report(for: scenario)
        accumulator.recordNativeBalanceUXAudit(report)
    }

    private static func recordNativePostShipAnalysis(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let report = NativePostShipAnalysisCatalog.report(for: scenario)
        accumulator.recordNativePostShipAnalysis(report)
    }

    private static func recordNativeCampaignSoak(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let report = NativeCampaignSoakRunner.runBattle(scenario)
        accumulator.recordNativeCampaignSoak(report)
    }

    private static func recordPlayableScreenParityIfRouted(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        guard PlayableBattleSurfaceCatalog.isRoutedToPlayableScreen(scenario.id) else {
            return
        }

        do {
            let result = try DZWPlayableScreenHarness.runBattleFlow(
                for: scenario.id,
                seed: UInt32(590_500 + scenario.order)
            )
            accumulator.recordPlayableScreenParity(result)
        } catch {
            accumulator.issue(
                .failure,
                "Playable Screen Parity",
                "DZW-style playable screen harness failed",
                "\(scenario.title) could not finish the routed playable-screen path: \(error)."
            )
            accumulator.step(
                "Playable Screen Parity",
                .failed,
                "DZW-style playable screen harness failed",
                "\(error)"
            )
        }
    }

    private static func validateScenarioData(
        _ scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        accumulator.step("Scenario Data", .passed, "Loaded authored content", "\(bundle.mapLayout.elements.count) map elements, \(bundle.setup.units.count) units, \(scenario.objectives.count) objectives.")

        let readiness = NativePlayabilityArchitectureCatalog.readiness(for: scenario)
        accumulator.step(
            "Native Playability",
            readiness.status == .nativePlayable ? .passed : .warning,
            readiness.status.rawValue,
            readiness.summary
        )
        if readiness.status != .nativePlayable {
            accumulator.issue(
                .warning,
                "Native Playability",
                "Native scenario instance unavailable",
                "\(scenario.title) is past proxy loading but still has native-playability work before the cycle 400 full-campaign target. Pending hooks: \(readiness.requiredHookIDs.joined(separator: ", ")). \(readiness.notes.joined(separator: " "))"
            )
        }

        if bundle.mapLayout.elements.isEmpty {
            accumulator.issue(.failure, "Scenario Data", "No map elements", "\(scenario.title) has no authored map elements for the automated player to inspect.")
        }
        if bundle.setup.units.isEmpty {
            accumulator.issue(.failure, "Scenario Data", "No setup units", "\(scenario.title) has no scenario setup units.")
        }
        if bundle.aiPlan.orders.isEmpty {
            accumulator.issue(.failure, "Scenario Data", "No AI plan", "\(scenario.title) has no German AI orders.")
        }
        if bundle.balance.outcomeBands.isEmpty {
            accumulator.issue(.failure, "Scenario Data", "No debrief bands", "\(scenario.title) cannot show a useful automated debrief.")
        }
    }

    private static func validateEngineState(
        _ game: OpaquePointer,
        scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let unitCount = Int(game_unit_count(game))
        let objectiveCount = Int(game_objective_count(game))
        let mission = game_mission_view(game)

        accumulator.step("Engine State", .passed, "Loaded engine state", "\(unitCount) units, \(objectiveCount) objectives, target score \(Int(mission.target_score)).")
        if unitCount == 0 {
            accumulator.issue(.blocker, "Engine State", "No engine units", "\(scenario.title) loaded a dzw game with no units.")
        }
        if objectiveCount == 0 {
            accumulator.issue(.blocker, "Engine State", "No engine objectives", "\(scenario.title) loaded a dzw game with no objectives.")
        }
        if Int(mission.target_score) <= 0 {
            accumulator.issue(.blocker, "Engine State", "No mission target", "\(scenario.title) cannot complete because the dzw mission target score is not positive.")
        }
    }

    private static func playEngineBattle(
        _ game: OpaquePointer,
        scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator,
        options: CampaignAutomationOptions
    ) {
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let targetTurn = balance.targetTurns.upperBound
        var guardCounter = 0

        accumulator.step("Battle Start", .passed, "Automated battle started", "Target turn window \(balance.targetTurns.lowerBound)-\(balance.targetTurns.upperBound).")

        while Int(game_view(game).turn_number) <= targetTurn &&
            game_mission_view(game).winner == TE_PLAYER_NONE &&
            guardCounter < options.maxPhaseAdvances {
            guardCounter += 1
            if !resolvePendingChoices(game, accumulator: &accumulator) {
                return
            }

            let view = game_view(game)
            switch view.phase {
            case TE_PHASE_MOVEMENT:
                runMovementPhase(game, scenario: scenario, accumulator: &accumulator)
            case TE_PHASE_SHOOTING:
                runShootingPhase(game, accumulator: &accumulator)
            case TE_PHASE_ASSAULT:
                runAssaultPhase(game, accumulator: &accumulator)
            default:
                accumulator.issue(.blocker, "Turn Playback", "Unknown phase", "The engine returned an unknown phase value on turn \(Int(view.turn_number)).")
                return
            }

            if !resolvePendingChoices(game, accumulator: &accumulator) {
                return
            }
            if !advancePhase(game, accumulator: &accumulator) {
                return
            }
        }

        let winner = game_mission_view(game).winner
        if winner == TE_PLAYER_NONE {
            accumulator.issue(.warning, "Debrief", "No engine winner by target turn", "\(scenario.title) reached turn \(Int(game_view(game).turn_number)) without the dzw proxy mission declaring a winner.")
            accumulator.step("Debrief", .warning, "Target turn reached", "Use this as a pacing signal rather than a hard gameplay failure.")
        } else {
            accumulator.step("Debrief", .passed, "Engine winner recorded", "\(playerName(winner)) won the proxy mission.")
        }

        if guardCounter >= options.maxPhaseAdvances {
            accumulator.issue(.blocker, "Turn Playback", "Phase advance guard tripped", "\(scenario.title) exceeded \(options.maxPhaseAdvances) phase advances before completion.")
        }
    }

    private static func runMovementPhase(
        _ game: OpaquePointer,
        scenario: GuderianScenario,
        accumulator: inout AutomationAccumulator
    ) {
        let view = game_view(game)
        let units = unitSnapshots(in: game)
        let objectives = objectiveSnapshots(in: game)
        var moved = 0

        for unit in units where unit.canMoveNow {
            guard let target = movementTarget(for: unit, scenario: scenario, units: units, objectives: objectives) else {
                continue
            }
            if attemptMove(unit, toward: target, in: game, accumulator: &accumulator) {
                moved += 1
            }
        }

        accumulator.step(
            "Turn \(Int(view.turn_number)) \(playerName(view.active_player)) Movement",
            .passed,
            "Movement phase probed",
            moved == 0 ? "No legal automated movement was found." : "\(moved) units moved toward objectives or contact."
        )
    }

    private static func runShootingPhase(_ game: OpaquePointer, accumulator: inout AutomationAccumulator) {
        let view = game_view(game)
        var shots = 0

        for unit in unitSnapshots(in: game) where unit.canShootNow {
            let enemies = unitSnapshots(in: game)
                .filter { $0.owner != unit.owner && !$0.destroyed && !$0.embarked }
                .sorted { distance(unit.point, $0.point) < distance(unit.point, $1.point) }

            for enemy in enemies {
                accumulator.actionsAttempted += 1
                if game_shoot_unit(game, Int32(unit.id), Int32(enemy.id)) {
                    accumulator.actionsSucceeded += 1
                    shots += 1
                    _ = resolvePendingChoices(game, accumulator: &accumulator)
                    break
                }
            }
        }

        accumulator.step(
            "Turn \(Int(view.turn_number)) \(playerName(view.active_player)) Shooting",
            .passed,
            "Shooting phase probed",
            shots == 0 ? "No legal automated shots were found." : "\(shots) units fired."
        )
    }

    private static func runAssaultPhase(_ game: OpaquePointer, accumulator: inout AutomationAccumulator) {
        let view = game_view(game)
        var assaults = 0

        for unit in unitSnapshots(in: game) where unit.canAssaultNow {
            let enemies = unitSnapshots(in: game)
                .filter { $0.owner != unit.owner && !$0.destroyed && !$0.embarked }
                .filter { distance(unit.point, $0.point) - unit.footprintRadius - $0.footprintRadius <= 8.5 }
                .sorted { distance(unit.point, $0.point) < distance(unit.point, $1.point) }

            for enemy in enemies {
                accumulator.actionsAttempted += 1
                if game_assault_unit(game, Int32(unit.id), Int32(enemy.id), TE_FOLLOW_UP_ADVANCE) {
                    accumulator.actionsSucceeded += 1
                    assaults += 1
                    _ = resolvePendingChoices(game, accumulator: &accumulator)
                    break
                }
            }
        }

        accumulator.step(
            "Turn \(Int(view.turn_number)) \(playerName(view.active_player)) Assault",
            .passed,
            "Assault phase probed",
            assaults == 0 ? "No legal automated assaults were found." : "\(assaults) units assaulted."
        )
    }

    private static func attemptMove(
        _ unit: AutomationUnit,
        toward target: AutomationPoint,
        in game: OpaquePointer,
        accumulator: inout AutomationAccumulator
    ) -> Bool {
        let dx = target.x - unit.x
        let dy = target.y - unit.y
        let baseAngle = atan2(dy, dx)
        let totalDistance = max(0, distance(unit.point, target))
        guard totalDistance > 0.25 else {
            return false
        }

        let maxDistance: Double
        if unit.kind == TE_UNIT_VEHICLE {
            maxDistance = unit.fast ? 18 : 12
        } else {
            maxDistance = 6
        }

        let angleOffsets: [Double] = [0, .pi / 8, -.pi / 8, .pi / 4, -.pi / 4, .pi / 2, -.pi / 2]
        var step = min(totalDistance, maxDistance)
        while step >= 1 {
            for offset in angleOffsets {
                let x = clamp(unit.x + cos(baseAngle + offset) * step, min: unit.footprintRadius, max: 72 - unit.footprintRadius)
                let y = clamp(unit.y + sin(baseAngle + offset) * step, min: unit.footprintRadius, max: 48 - unit.footprintRadius)
                accumulator.actionsAttempted += 1
                if game_move_unit(game, Int32(unit.id), Float(x), Float(y)) {
                    accumulator.actionsSucceeded += 1
                    return true
                }
            }
            step -= 1.5
        }
        return false
    }

    private static func advancePhase(_ game: OpaquePointer, accumulator: inout AutomationAccumulator) -> Bool {
        let before = game_view(game)
        game_advance_phase(game)
        let after = game_view(game)
        let error = lastError(in: game)

        if before.turn_number == after.turn_number &&
            before.active_player == after.active_player &&
            before.phase == after.phase &&
            !error.isEmpty {
            accumulator.issue(.blocker, "Turn Playback", "Phase could not advance", error)
            accumulator.step("Turn Playback", .blocked, "Advance phase blocked", error)
            return false
        }

        accumulator.phaseAdvances += 1
        accumulator.step(
            "Turn Playback",
            .passed,
            "Advanced phase",
            "\(playerName(after.active_player)) \(phaseName(after.phase)), turn \(Int(after.turn_number))."
        )
        return true
    }

    private static func resolvePendingChoices(
        _ game: OpaquePointer,
        accumulator: inout AutomationAccumulator
    ) -> Bool {
        for _ in 0..<64 {
            let weaponChoice = game_pending_weapon_destroy_view(game)
            if weaponChoice.active {
                let optionCount = Int(game_pending_weapon_destroy_option_count(game))
                guard optionCount > 0 else {
                    accumulator.issue(.blocker, "Pending Choice", "No weapon-destroy options", "The engine requested a weapon-destroy choice but exposed no options.")
                    return false
                }
                let option = game_pending_weapon_destroy_option_view(game, 0)
                accumulator.actionsAttempted += 1
                if !game_choose_pending_weapon_destroy(game, option.weapon_index) {
                    accumulator.issue(.blocker, "Pending Choice", "Weapon-destroy choice failed", lastError(in: game))
                    return false
                }
                accumulator.actionsSucceeded += 1
                accumulator.step("Pending Choice", .passed, "Resolved weapon damage", cString(option.name))
                continue
            }

            let hitChoice = game_pending_hit_allocation_view(game)
            if hitChoice.active {
                let groupCount = Int(game_unit_profile_group_count(game, hitChoice.target_id))
                var resolved = false
                for index in 0..<groupCount {
                    accumulator.actionsAttempted += 1
                    if game_choose_pending_hit_allocation(game, Int32(index)) {
                        accumulator.actionsSucceeded += 1
                        accumulator.step("Pending Choice", .passed, "Allocated mixed-profile hit", "\(Int(hitChoice.hits_assigned) + 1)/\(Int(hitChoice.total_hits)) hits assigned.")
                        resolved = true
                        break
                    }
                }
                if !resolved {
                    accumulator.issue(.blocker, "Pending Choice", "Hit allocation could not resolve", lastError(in: game))
                    return false
                }
                continue
            }

            return true
        }

        accumulator.issue(.blocker, "Pending Choice", "Pending choice loop exceeded guard", "The engine kept producing pending choices after 64 automated resolutions.")
        return false
    }

    private static func movementTarget(
        for unit: AutomationUnit,
        scenario: GuderianScenario,
        units: [AutomationUnit],
        objectives: [AutomationObjective]
    ) -> AutomationPoint? {
        if unit.owner == TE_PLAYER_TWO,
           let preferredName = NativeAIEventExecutionCatalog.preferredObjectiveName(
            for: scenario,
            objectiveNames: objectives.map(\.name)
           ),
           let objective = objectives.first(where: { $0.name == preferredName }) {
            return objective.point
        }

        if let objective = objectives.sorted(by: {
            objectivePriority(for: unit, objective: $0) < objectivePriority(for: unit, objective: $1)
        }).first {
            return objective.point
        }

        return units
            .filter { $0.owner != unit.owner && !$0.destroyed && !$0.embarked }
            .min { distance(unit.point, $0.point) < distance(unit.point, $1.point) }?
            .point
    }

    private static func objectivePriority(for unit: AutomationUnit, objective: AutomationObjective) -> Double {
        let ownershipPenalty: Double = objective.controller == unit.owner ? 100 : 0
        return ownershipPenalty + distance(unit.point, objective.point)
    }

    private static func unitSnapshots(in game: OpaquePointer) -> [AutomationUnit] {
        (0..<Int(game_unit_count(game))).map { index in
            let view = game_unit_view(game, Int32(index))
            return AutomationUnit(
                id: Int(view.id),
                name: cString(view.name),
                owner: view.owner,
                kind: view.kind,
                x: Double(view.x),
                y: Double(view.y),
                footprintRadius: Double(view.footprint_radius),
                fast: view.fast,
                canMoveNow: view.can_move_now,
                canShootNow: view.can_shoot_now,
                canAssaultNow: view.can_assault_now,
                destroyed: view.destroyed,
                embarked: view.embarked
            )
        }
    }

    private static func objectiveSnapshots(in game: OpaquePointer) -> [AutomationObjective] {
        (0..<Int(game_objective_count(game))).map { index in
            let view = game_objective_view(game, Int32(index))
            return AutomationObjective(
                id: Int(view.id),
                name: cString(view.name),
                x: Double(view.x),
                y: Double(view.y),
                controller: view.controller
            )
        }
    }

    private static func engineLogTail(in game: OpaquePointer?, limit: Int = 12) -> [String] {
        guard let game else {
            return []
        }
        let count = Int(game_log_count(game))
        guard count > 0 else {
            return []
        }
        return (max(0, count - limit)..<count).map { index in
            cString(game_log_line(game, Int32(index)))
        }
    }

    private static func lastError(in game: OpaquePointer) -> String {
        cString(game_last_error(game))
    }

    private static func seed(for scenario: GuderianScenario) -> UInt32 {
        UInt32(70_000 + scenario.order)
    }

    private static func fallbackCompletionRecord(
        for scenario: GuderianScenario,
        report: CampaignAutomationBattleReport
    ) -> CampaignCompletionRecord {
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        return CampaignCompletionRecord(
            scenarioID: scenario.id,
            score: balance.maxPlayerScore,
            victoryBand: report.status == .passed ? .operational : .tactical,
            completedTurn: max(1, report.finalTurn),
            note: "Completed by GuderianTest automation with status \(report.status.rawValue)."
        )
    }

    private static func playerName(_ player: player_t) -> String {
        switch player {
        case TE_PLAYER_ONE:
            return "Player"
        case TE_PLAYER_TWO:
            return "Guderian AI"
        default:
            return "None"
        }
    }

    private static func phaseName(_ phase: phase_t) -> String {
        switch phase {
        case TE_PHASE_MOVEMENT:
            return "Movement"
        case TE_PHASE_SHOOTING:
            return "Shooting"
        case TE_PHASE_ASSAULT:
            return "Assault"
        default:
            return "Unknown"
        }
    }

    private static func cString(_ pointer: UnsafePointer<CChar>?) -> String {
        guard let pointer else {
            return ""
        }
        return String(cString: pointer)
    }

    private static func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    private static func distance(_ lhs: AutomationPoint, _ rhs: AutomationPoint) -> Double {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}

private struct AutomationAccumulator {
    let scenario: GuderianScenario
    var steps: [CampaignAutomationStep] = []
    var issues: [CampaignAutomationIssue] = []
    var actionsAttempted = 0
    var actionsSucceeded = 0
    var phaseAdvances = 0
    var completionRecord: CampaignCompletionRecord?
    var debriefSummary = ""
    var nativeDemoBoardCompleted = false
    var boardDiagnostic: NativeBoardDiagnosticReport?
    var nativeBoardDiagnosticsPassed = false
    var nativePolandPackCompleted = false
    var nativePolandPackSummary = ""
    var nativeFrancePackCompleted = false
    var nativeFrancePackSummary = ""
    var easternFrontFoundationReady = false
    var easternFrontFoundationSummary = ""
    var nativeEasternFrontPackCompleted = false
    var nativeEasternFrontPackSummary = ""
    var nativeAIEventPassReady = false
    var nativeAIEventPassSummary = ""
    var nativeAIEventExecutionReady = false
    var nativeAIEventExecutionSummary = ""
    var nativeBalanceUXReady = false
    var nativeBalanceUXSummary = ""
    var nativePostShipAnalysisReady = false
    var nativePostShipAnalysisSummary = ""
    var nativeSoakReady = false
    var nativeSoakSummary = ""
    var playableScreenParityCompleted = false
    var playableScreenParitySummary = ""
    var playableScreenParityBlockers: [String] = []

    mutating func step(_ stage: String, _ status: CampaignAutomationStatus, _ title: String, _ detail: String) {
        steps.append(
            CampaignAutomationStep(
                id: "\(scenario.id.rawValue)-step-\(steps.count)",
                stage: stage,
                status: status,
                title: title,
                detail: detail
            )
        )
    }

    mutating func issue(_ kind: CampaignAutomationIssueKind, _ stage: String, _ title: String, _ detail: String) {
        issues.append(
            CampaignAutomationIssue(
                id: "\(scenario.id.rawValue)-issue-\(issues.count)",
                kind: kind,
                stage: stage,
                title: title,
                detail: detail.isEmpty ? "The engine did not provide an error string." : detail
            )
        )
    }

    mutating func recordDemoCompletion(_ completion: NativeDemoBattleCompletionReport) {
        completionRecord = completion.completionRecord
        debriefSummary = completion.debriefSummary
        nativeDemoBoardCompleted = completion.completedFromNativeBoardToDebrief
        actionsAttempted += completion.steps.count
        actionsSucceeded += completion.steps.filter { $0.status == .succeeded }.count
        phaseAdvances += completion.phaseAdvances
        step(
            "Native Demo",
            completion.completedFromNativeBoardToDebrief ? .passed : .warning,
            "Completed native demo battle",
            "\(completion.title) finished on turn \(completion.completedTurn) with \(completion.score) VP and \(completion.victoryBand.rawValue) debrief."
        )
    }

    mutating func recordBoardDiagnostic(_ diagnostic: NativeBoardDiagnosticReport) {
        boardDiagnostic = diagnostic
        nativeBoardDiagnosticsPassed = diagnostic.passedRealBoardDiagnostics
        actionsAttempted += diagnostic.legalActionsAttempted
        actionsSucceeded += diagnostic.legalActionsSucceeded
        phaseAdvances += diagnostic.phaseAdvances
        step(
            "Native Board Diagnostics",
            diagnostic.passedRealBoardDiagnostics ? .passed : .warning,
            diagnostic.passedRealBoardDiagnostics ? "Real board diagnostics passed" : "Real board diagnostics found issues",
            "\(diagnostic.legalActionsSucceeded)/\(diagnostic.legalActionsAttempted) legal actions, \(diagnostic.phaseAdvances) phase advances, \(diagnostic.findings.count) findings."
        )
        for finding in diagnostic.findings {
            let kind: CampaignAutomationIssueKind
            switch finding.kind {
            case .invalidTarget:
                kind = .warning
            case .boardUnavailable, .blockedPhase, .impossibleReinforcement, .unwinnableGate:
                kind = .blocker
            }
            issue(kind, "Native Board Diagnostics", finding.title, finding.detail)
        }
    }

    mutating func recordPolandCompletion(_ completion: NativePolandCompletionReport) {
        completionRecord = completion.completionRecord
        debriefSummary = completion.debriefSummary
        nativePolandPackCompleted = completion.completedFromNativePolandBattlefield
        nativePolandPackSummary = completion.debriefSummary
        actionsAttempted += completion.steps.count
        actionsSucceeded += completion.steps.filter { $0.status == .succeeded }.count
        phaseAdvances += completion.phaseAdvances
        step(
            "Native Poland Pack",
            completion.completedFromNativePolandBattlefield ? .passed : .warning,
            "Completed native Poland battle",
            "\(completion.pack.title) finished on turn \(completion.completionRecord.completedTurn) with \(completion.completionRecord.score) VP and \(completion.completionRecord.victoryBand.rawValue) debrief."
        )
    }

    mutating func recordFranceCompletion(_ completion: NativeFranceCompletionReport) {
        completionRecord = completion.completionRecord
        debriefSummary = completion.debriefSummary
        nativeFrancePackCompleted = completion.completedFromNativeFranceBattlefield
        nativeFrancePackSummary = completion.debriefSummary
        actionsAttempted += completion.steps.count
        actionsSucceeded += completion.steps.filter { $0.status == .succeeded }.count
        phaseAdvances += completion.phaseAdvances
        step(
            "Native France Pack",
            completion.completedFromNativeFranceBattlefield ? .passed : .warning,
            "Completed native France battle",
            "\(completion.pack.title) finished on turn \(completion.completionRecord.completedTurn) with \(completion.completionRecord.score) VP and \(completion.completionRecord.victoryBand.rawValue) debrief."
        )
    }

    mutating func recordEasternFrontFoundation(
        _ foundation: NativeEasternFrontBattlefieldFoundation,
        ready: Bool
    ) {
        easternFrontFoundationReady = ready
        easternFrontFoundationSummary = foundation.summary
        step(
            "Native Eastern Front Foundation",
            ready ? .passed : .warning,
            "Mapped native Eastern Front foundation",
            foundation.summary
        )
    }

    mutating func recordEasternFrontCompletion(_ completion: NativeEasternFrontCompletionReport) {
        completionRecord = completion.completionRecord
        debriefSummary = completion.debriefSummary
        nativeEasternFrontPackCompleted = completion.completedFromNativeEasternFrontBattlefield
        nativeEasternFrontPackSummary = completion.debriefSummary
        actionsAttempted += completion.steps.count
        actionsSucceeded += completion.steps.filter { $0.status == .succeeded }.count
        phaseAdvances += completion.phaseAdvances
        step(
            "Native Eastern Front Pack",
            completion.completedFromNativeEasternFrontBattlefield ? .passed : .warning,
            "Completed native Eastern Front battle",
            "\(completion.pack.title) finished on turn \(completion.completionRecord.completedTurn) with \(completion.completionRecord.score) VP and \(completion.completionRecord.victoryBand.rawValue) debrief."
        )
    }

    mutating func recordNativeAIEventPass(_ report: NativeAIEventPassReport) {
        nativeAIEventPassReady = report.isNativeAIEventPassReady
        nativeAIEventPassSummary = report.summary
        step(
            "Native AI/Event Pass",
            report.isNativeAIEventPassReady ? .passed : .warning,
            "Mapped native AI/event pass",
            report.summary
        )
    }

    mutating func recordNativeAIEventExecution(_ report: NativeAIEventExecutionReport) {
        nativeAIEventExecutionReady = report.isNativeAIEventExecutionReady
        nativeAIEventExecutionSummary = report.summary
        step(
            "Native AI/Event Execution",
            report.isNativeAIEventExecutionReady ? .passed : .warning,
            "Resolved AI/event pass on board state",
            report.summary
        )
    }

    mutating func recordNativeBalanceUXAudit(_ report: NativeBalanceUXAuditReport) {
        nativeBalanceUXReady = report.isNativeBalanceUXReady
        nativeBalanceUXSummary = report.summary
        step(
            "Native Balance/UX",
            report.isNativeBalanceUXReady ? .passed : .warning,
            "Audited native balance and UX",
            report.summary
        )
        for blocker in report.blockers {
            issue(.blocker, "Native Balance/UX", "Balance/UX blocker", blocker)
        }
    }

    mutating func recordNativePostShipAnalysis(_ report: NativePostShipAnalysisReport) {
        nativePostShipAnalysisReady = report.isPostShipAnalysisReady
        nativePostShipAnalysisSummary = report.summary
        step(
            "Native Post-Ship Analysis",
            report.isPostShipAnalysisReady ? .passed : .warning,
            "Recorded post-ship analysis",
            report.summary
        )
    }

    mutating func recordNativeCampaignSoak(_ report: NativeCampaignSoakBattleReport) {
        nativeSoakReady = report.isSoakStable
        nativeSoakSummary = report.summary
        actionsAttempted += report.probes.reduce(0) { $0 + $1.legalActionsAttempted }
        actionsSucceeded += report.probes.reduce(0) { $0 + $1.legalActionsSucceeded }
        phaseAdvances += report.probes.reduce(0) { $0 + $1.phaseAdvances }
        step(
            "Native Campaign Soak",
            report.isSoakStable ? .passed : .warning,
            "Ran deterministic soak probes",
            report.summary
        )
    }

    mutating func recordPlayableScreenParity(_ result: DZWPlayableScreenHarnessResult) {
        playableScreenParityCompleted = result.completedAllStages
        playableScreenParityBlockers = result.blockers
        playableScreenParitySummary = "\(result.title) completed \(result.completedStages.count)/\(DZWPlayableScreenHarnessStage.allCases.count) DZW-style playable-screen stages via \(result.completion.sourceName)."
        actionsAttempted += result.steps.count
        actionsSucceeded += result.completedAllStages ? result.steps.count : result.steps.filter { $0.status != .blocked }.count
        step(
            "Playable Screen Parity",
            result.completedAllStages ? .passed : .blocked,
            result.completedAllStages ? "DZW-style playable screen completed" : "DZW-style playable screen blocked",
            playableScreenParitySummary
        )
        for blocker in result.blockers {
            issue(.blocker, "Playable Screen Parity", "Playable screen blocker", blocker)
        }
    }

    func finalize(loadout: AutomationLoadoutSummary?, game: OpaquePointer?) -> CampaignAutomationBattleReport {
        let gameView = game.map { game_view($0) }
        let mission = game.map { game_mission_view($0) }
        let status: CampaignAutomationStatus

        if issues.contains(where: { $0.kind == .blocker }) {
            status = .blocked
        } else if issues.contains(where: { $0.kind == .failure }) {
            status = .failed
        } else if issues.contains(where: { $0.kind == .warning }) {
            status = .warning
        } else {
            status = .passed
        }

        return CampaignAutomationBattleReport(
            id: scenario.id,
            order: scenario.order,
            title: scenario.title,
            theater: scenario.theater,
            status: status,
            playerArmy: loadout?.playerArmyName ?? "Unavailable",
            opponentArmy: loadout?.opponentArmyName ?? "Unavailable",
            finalTurn: gameView.map { Int($0.turn_number) } ?? 0,
            finalPhase: gameView.map { phaseName($0.phase) } ?? "Unavailable",
            engineWinner: mission.map { playerName($0.winner) } ?? "Unavailable",
            actionsAttempted: actionsAttempted,
            actionsSucceeded: actionsSucceeded,
            phaseAdvances: phaseAdvances,
            engineUnitCount: game.map { Int(game_unit_count($0)) } ?? 0,
            engineObjectiveCount: game.map { Int(game_objective_count($0)) } ?? 0,
            completionRecord: completionRecord,
            debriefSummary: debriefSummary,
            nativeDemoBoardCompleted: nativeDemoBoardCompleted,
            boardDiagnostic: boardDiagnostic,
            nativeBoardDiagnosticsPassed: nativeBoardDiagnosticsPassed,
            nativePolandPackCompleted: nativePolandPackCompleted,
            nativePolandPackSummary: nativePolandPackSummary,
            nativeFrancePackCompleted: nativeFrancePackCompleted,
            nativeFrancePackSummary: nativeFrancePackSummary,
            easternFrontFoundationReady: easternFrontFoundationReady,
            easternFrontFoundationSummary: easternFrontFoundationSummary,
            nativeEasternFrontPackCompleted: nativeEasternFrontPackCompleted,
            nativeEasternFrontPackSummary: nativeEasternFrontPackSummary,
            nativeAIEventPassReady: nativeAIEventPassReady,
            nativeAIEventPassSummary: nativeAIEventPassSummary,
            nativeAIEventExecutionReady: nativeAIEventExecutionReady,
            nativeAIEventExecutionSummary: nativeAIEventExecutionSummary,
            nativeBalanceUXReady: nativeBalanceUXReady,
            nativeBalanceUXSummary: nativeBalanceUXSummary,
            nativePostShipAnalysisReady: nativePostShipAnalysisReady,
            nativePostShipAnalysisSummary: nativePostShipAnalysisSummary,
            nativeSoakReady: nativeSoakReady,
            nativeSoakSummary: nativeSoakSummary,
            playableScreenParityCompleted: playableScreenParityCompleted,
            playableScreenParitySummary: playableScreenParitySummary,
            playableScreenParityBlockers: playableScreenParityBlockers,
            steps: steps,
            issues: issues,
            engineLogTail: engineLogTail(in: game)
        )
    }

    private func phaseName(_ phase: phase_t) -> String {
        switch phase {
        case TE_PHASE_MOVEMENT:
            return "Movement"
        case TE_PHASE_SHOOTING:
            return "Shooting"
        case TE_PHASE_ASSAULT:
            return "Assault"
        default:
            return "Unknown"
        }
    }

    private func playerName(_ player: player_t) -> String {
        switch player {
        case TE_PLAYER_ONE:
            return "Player"
        case TE_PLAYER_TWO:
            return "Guderian AI"
        default:
            return "None"
        }
    }

    private func engineLogTail(in game: OpaquePointer?, limit: Int = 12) -> [String] {
        guard let game else {
            return []
        }
        let count = Int(game_log_count(game))
        guard count > 0 else {
            return []
        }
        return (max(0, count - limit)..<count).map { index in
            guard let line = game_log_line(game, Int32(index)) else {
                return ""
            }
            return String(cString: line)
        }
    }
}

private struct AutomationLoadoutSummary {
    let playerArmyName: String
    let opponentArmyName: String
}

private extension NativeScenarioLoadout {
    var summary: AutomationLoadoutSummary {
        AutomationLoadoutSummary(
            playerArmyName: playerArmyName,
            opponentArmyName: opponentArmyName
        )
    }
}

private struct AutomationPoint {
    let x: Double
    let y: Double
}

private struct AutomationUnit {
    let id: Int
    let name: String
    let owner: player_t
    let kind: unit_kind_t
    let x: Double
    let y: Double
    let footprintRadius: Double
    let fast: Bool
    let canMoveNow: Bool
    let canShootNow: Bool
    let canAssaultNow: Bool
    let destroyed: Bool
    let embarked: Bool

    var point: AutomationPoint {
        AutomationPoint(x: x, y: y)
    }
}

private struct AutomationObjective {
    let id: Int
    let name: String
    let x: Double
    let y: Double
    let controller: player_t

    var point: AutomationPoint {
        AutomationPoint(x: x, y: y)
    }
}
