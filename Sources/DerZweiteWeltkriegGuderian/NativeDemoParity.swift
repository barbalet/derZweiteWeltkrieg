import Foundation

public enum NativeDemoParityError: Error, Equatable, CustomStringConvertible, Sendable {
    case missingScenario(GuderianBattleID)
    case nonDemoScenario(GuderianBattleID)
    case boardSessionUnavailable(GuderianBattleID)
    case scenarioBoardUnavailable(GuderianBattleID)

    public var description: String {
        switch self {
        case .missingScenario(let id):
            return "Scenario \(id.rawValue) is not present in the Guderian campaign catalog."
        case .nonDemoScenario(let id):
            return "Scenario \(id.rawValue) is not part of the cycle 300 native demo parity set."
        case .boardSessionUnavailable(let id):
            return "Scenario \(id.rawValue) could not create a native board session."
        case .scenarioBoardUnavailable(let id):
            return "Scenario \(id.rawValue) did not expose scenario-specific board data."
        }
    }
}

public struct NativeDemoScoreAward: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioScoringSide
    public let victoryPoints: Int
    public let timing: String
    public let awarded: Bool

    public init(
        id: String,
        name: String,
        side: ScenarioScoringSide,
        victoryPoints: Int,
        timing: String,
        awarded: Bool
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.victoryPoints = victoryPoints
        self.timing = timing
        self.awarded = awarded
    }
}

public struct NativeDemoBattleStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let turnNumber: Int
    public let activePlayer: NativeBoardPlayer
    public let phase: NativeBoardPhase
    public let status: NativeBoardActionStatus
    public let title: String
    public let detail: String

    public init(
        id: String,
        turnNumber: Int,
        activePlayer: NativeBoardPlayer,
        phase: NativeBoardPhase,
        status: NativeBoardActionStatus,
        title: String,
        detail: String
    ) {
        self.id = id
        self.turnNumber = turnNumber
        self.activePlayer = activePlayer
        self.phase = phase
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct NativeDemoBattleCompletionReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let completedTurn: Int
    public let phaseAdvances: Int
    public let score: Int
    public let victoryBand: VictoryBand
    public let outcomeSummary: String
    public let debriefSummary: String
    public let usedScenarioBoard: Bool
    public let usedGenericProxyMap: Bool
    public let usedGenericProxyForces: Bool
    public let openingSnapshot: NativeBoardSnapshot
    public let finalSnapshot: NativeBoardSnapshot
    public let scoreAwards: [NativeDemoScoreAward]
    public let steps: [NativeDemoBattleStep]
    public let completionRecord: CampaignCompletionRecord

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        completedTurn: Int,
        phaseAdvances: Int,
        score: Int,
        victoryBand: VictoryBand,
        outcomeSummary: String,
        debriefSummary: String,
        usedScenarioBoard: Bool,
        usedGenericProxyMap: Bool,
        usedGenericProxyForces: Bool,
        openingSnapshot: NativeBoardSnapshot,
        finalSnapshot: NativeBoardSnapshot,
        scoreAwards: [NativeDemoScoreAward],
        steps: [NativeDemoBattleStep],
        completionRecord: CampaignCompletionRecord
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.completedTurn = completedTurn
        self.phaseAdvances = phaseAdvances
        self.score = score
        self.victoryBand = victoryBand
        self.outcomeSummary = outcomeSummary
        self.debriefSummary = debriefSummary
        self.usedScenarioBoard = usedScenarioBoard
        self.usedGenericProxyMap = usedGenericProxyMap
        self.usedGenericProxyForces = usedGenericProxyForces
        self.openingSnapshot = openingSnapshot
        self.finalSnapshot = finalSnapshot
        self.scoreAwards = scoreAwards
        self.steps = steps
        self.completionRecord = completionRecord
    }

    public var completedWithoutGenericProxies: Bool {
        usedScenarioBoard && !usedGenericProxyMap && !usedGenericProxyForces
    }

    public var completedFromNativeBoardToDebrief: Bool {
        completedWithoutGenericProxies &&
            openingSnapshot.isScenarioBoardPlayable &&
            finalSnapshot.isScenarioBoardPlayable &&
            completedTurn > 0 &&
            score > 0 &&
            !debriefSummary.isEmpty &&
            completionRecord.scenarioID == id
    }
}

public struct NativeDemoCampaignCompletionReport: Codable, Hashable, Sendable {
    public let battleIDs: [GuderianBattleID]
    public let completions: [NativeDemoBattleCompletionReport]
    public let progress: CampaignProgress
    public let summary: CampaignCompletionSummary

    public init(
        battleIDs: [GuderianBattleID],
        completions: [NativeDemoBattleCompletionReport],
        progress: CampaignProgress,
        summary: CampaignCompletionSummary
    ) {
        self.battleIDs = battleIDs
        self.completions = completions
        self.progress = progress
        self.summary = summary
    }

    public var completedAllDemoBattles: Bool {
        completions.map(\.id) == battleIDs &&
            completions.allSatisfy(\.completedFromNativeBoardToDebrief) &&
            summary.completedScenarios == battleIDs.count
    }
}

public enum NativeDemoParityRunner {
    public static let cycleRange = 291...300
    public static let playableBattleIDs = GuderianCampaignCatalog.demoIDs

    public static func isNativeDemoPlayable(_ scenario: GuderianScenario) -> Bool {
        guard scenario.isDemoScenario && playableBattleIDs.contains(scenario.id) else {
            return false
        }
        let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(130_000 + scenario.order))
        return loadout.canApplyScenarioBoardHook && !loadout.usesForcePresetProxy
    }

    public static func runBattle(
        id: GuderianBattleID,
        seed: UInt32? = nil
    ) throws -> NativeDemoBattleCompletionReport {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw NativeDemoParityError.missingScenario(id)
        }
        return try runBattle(scenario, seed: seed ?? seedForScenario(scenario))
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        seed: UInt32? = nil
    ) throws -> NativeDemoBattleCompletionReport {
        guard scenario.isDemoScenario && playableBattleIDs.contains(scenario.id) else {
            throw NativeDemoParityError.nonDemoScenario(scenario.id)
        }
        guard let session = NativeBoardSession(scenario: scenario, seed: seed ?? seedForScenario(scenario)) else {
            throw NativeDemoParityError.boardSessionUnavailable(scenario.id)
        }
        return try completeBattle(from: session)
    }

    public static func completeBattle(
        from session: NativeBoardSession
    ) throws -> NativeDemoBattleCompletionReport {
        let scenario = session.loadout.scenario
        guard scenario.isDemoScenario && playableBattleIDs.contains(scenario.id) else {
            throw NativeDemoParityError.nonDemoScenario(scenario.id)
        }

        let opening = session.snapshot()
        guard opening.isScenarioBoardPlayable else {
            throw NativeDemoParityError.scenarioBoardUnavailable(scenario.id)
        }

        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let minimumCompletionTurn = max(1, balance.targetTurns.lowerBound)
        let maximumPhaseAdvances = max(18, balance.targetTurns.upperBound * 6)
        var steps: [NativeDemoBattleStep] = []
        var phaseAdvances = 0
        var current = opening

        while current.turnNumber < minimumCompletionTurn && phaseAdvances < maximumPhaseAdvances {
            steps.append(performBoardAction(in: session, before: current, stepIndex: steps.count))
            drainPendingChoices(in: session, steps: &steps)
            session.advancePhase()
            phaseAdvances += 1
            current = session.snapshot()
        }

        let final = session.snapshot()
        let scoreAwards = scoreAwards(for: balance, finalSnapshot: final)
        let score = scoreAwards
            .filter(\.awarded)
            .reduce(0) { $0 + $1.victoryPoints }
        let outcome = outcomeBand(for: score, balance: balance)
        let debrief = debriefSummary(
            scenario: scenario,
            balance: balance,
            outcome: outcome,
            score: score,
            finalSnapshot: final,
            scoreAwards: scoreAwards
        )
        let record = CampaignCompletionRecord(
            scenarioID: scenario.id,
            score: score,
            victoryBand: outcome.grade,
            completedTurn: max(1, final.turnNumber),
            note: "Cycle 300 native demo parity completion: \(debrief)"
        )

        return NativeDemoBattleCompletionReport(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            completedTurn: record.completedTurn,
            phaseAdvances: phaseAdvances,
            score: score,
            victoryBand: outcome.grade,
            outcomeSummary: outcome.summary,
            debriefSummary: debrief,
            usedScenarioBoard: final.boardReport.isScenarioSpecific,
            usedGenericProxyMap: !final.boardReport.isScenarioSpecific,
            usedGenericProxyForces: session.loadout.usesForcePresetProxy,
            openingSnapshot: opening,
            finalSnapshot: final,
            scoreAwards: scoreAwards,
            steps: steps,
            completionRecord: record
        )
    }

    public static func runDemoCampaign(
        ids: [GuderianBattleID] = playableBattleIDs
    ) throws -> NativeDemoCampaignCompletionReport {
        var progress = CampaignProgress()
        var completions: [NativeDemoBattleCompletionReport] = []

        for id in ids {
            let completion = try runBattle(id: id)
            completions.append(completion)
            progress.recordCompletion(completion.completionRecord)
        }

        let scenarios = ids.compactMap(GuderianCampaignCatalog.scenario)
        return NativeDemoCampaignCompletionReport(
            battleIDs: ids,
            completions: completions,
            progress: progress,
            summary: progress.completionSummary(catalog: scenarios)
        )
    }

    private static func performBoardAction(
        in session: NativeBoardSession,
        before snapshot: NativeBoardSnapshot,
        stepIndex: Int
    ) -> NativeDemoBattleStep {
        session.selectFirstActiveUnit()
        session.selectNearestEnemyToSelectedUnit()

        switch snapshot.phase {
        case .movement:
            _ = session.moveSelectedUnitTowardNearestObjective(maxDistance: movementDistance(for: snapshot.selectedUnit))
            let after = session.snapshot()
            return step(from: after, snapshot: snapshot, stepIndex: stepIndex)
        case .shooting:
            _ = session.shootSelectedTarget()
            let after = session.snapshot()
            return step(from: after, snapshot: snapshot, stepIndex: stepIndex)
        case .assault:
            let resolved = session.resolveFirstPendingChoice()
            let after = session.snapshot()
            if resolved {
                return step(from: after, snapshot: snapshot, stepIndex: stepIndex)
            }
            return NativeDemoBattleStep(
                id: "\(snapshot.scenarioID.rawValue)-native-demo-step-\(stepIndex)",
                turnNumber: snapshot.turnNumber,
                activePlayer: snapshot.activePlayer,
                phase: snapshot.phase,
                status: .succeeded,
                title: "Assault phase checked",
                detail: "No pending assault or damage choice blocked the native demo playback."
            )
        }
    }

    private static func drainPendingChoices(
        in session: NativeBoardSession,
        steps: inout [NativeDemoBattleStep]
    ) {
        for _ in 0..<8 {
            let before = session.snapshot()
            guard session.resolveFirstPendingChoice() else {
                return
            }
            let after = session.snapshot()
            steps.append(step(from: after, snapshot: before, stepIndex: steps.count))
        }
    }

    private static func step(
        from after: NativeBoardSnapshot,
        snapshot before: NativeBoardSnapshot,
        stepIndex: Int
    ) -> NativeDemoBattleStep {
        NativeDemoBattleStep(
            id: "\(before.scenarioID.rawValue)-native-demo-step-\(stepIndex)",
            turnNumber: before.turnNumber,
            activePlayer: before.activePlayer,
            phase: before.phase,
            status: after.lastAction.status,
            title: after.lastAction.title,
            detail: after.lastAction.detail
        )
    }

    private static func scoreAwards(
        for balance: ScenarioBalanceProfile,
        finalSnapshot: NativeBoardSnapshot
    ) -> [NativeDemoScoreAward] {
        let canAward = finalSnapshot.isScenarioBoardPlayable
        return balance.scoreChannels
            .filter { $0.side == .player || $0.side == .contested }
            .map { channel in
                NativeDemoScoreAward(
                    id: channel.id,
                    name: channel.name,
                    side: channel.side,
                    victoryPoints: channel.victoryPoints,
                    timing: channel.timing,
                    awarded: canAward
                )
            }
    }

    private static func outcomeBand(
        for score: Int,
        balance: ScenarioBalanceProfile
    ) -> ScenarioOutcomeBand {
        if let exact = balance.outcomeBands.first(where: { $0.scoreRange.contains(score) }) {
            return exact
        }
        return balance.outcomeBands
            .sorted { $0.scoreRange.lowerBound < $1.scoreRange.lowerBound }
            .last { score >= $0.scoreRange.lowerBound } ?? balance.outcomeBands[0]
    }

    private static func debriefSummary(
        scenario: GuderianScenario,
        balance: ScenarioBalanceProfile,
        outcome: ScenarioOutcomeBand,
        score: Int,
        finalSnapshot: NativeBoardSnapshot,
        scoreAwards: [NativeDemoScoreAward]
    ) -> String {
        let awardedNames = scoreAwards
            .filter(\.awarded)
            .prefix(3)
            .map(\.name)
            .joined(separator: ", ")
        return "\(scenario.title) completed on native board turn \(max(1, finalSnapshot.turnNumber)) with \(score)/\(balance.maxPlayerScore) VP, \(outcome.grade.rawValue) result. Awarded: \(awardedNames)."
    }

    private static func movementDistance(for unit: NativeBoardUnitSnapshot?) -> Double {
        guard let unit else {
            return 4
        }
        return unit.kind == "Vehicle" || unit.kind == "Assault gun" ? 8 : 4
    }

    private static func seedForScenario(_ scenario: GuderianScenario) -> UInt32 {
        UInt32(130_000 + scenario.order)
    }
}
