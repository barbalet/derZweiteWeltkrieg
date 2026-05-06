import Foundation

public enum PlayableTestAIController: String, Codable, Hashable, Sendable {
    case antiGuderian = "Anti-Guderian AI"
    case guderian = "Guderian AI"

    init(activePlayer: NativeBoardPlayer) {
        switch activePlayer {
        case .guderianAI:
            self = .guderian
        default:
            self = .antiGuderian
        }
    }
}

public struct AntiGuderianAIOrder: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let turnWindow: String
    public let kind: GermanAIActionKind
    public let target: String
    public let instruction: String

    public init(id: String, turnWindow: String, kind: GermanAIActionKind, target: String, instruction: String) {
        self.id = id
        self.turnWindow = turnWindow
        self.kind = kind
        self.target = target
        self.instruction = instruction
    }
}

public struct AntiGuderianAIPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let postureName: String
    public let strategicGoal: String
    public let targetPriorities: [String]
    public let orders: [AntiGuderianAIOrder]

    public init(
        id: GuderianBattleID,
        postureName: String,
        strategicGoal: String,
        targetPriorities: [String],
        orders: [AntiGuderianAIOrder]
    ) {
        self.id = id
        self.postureName = postureName
        self.strategicGoal = strategicGoal
        self.targetPriorities = targetPriorities
        self.orders = orders
    }
}

public enum AntiGuderianAIPlanCatalog {
    public static func plan(for scenario: GuderianScenario) -> AntiGuderianAIPlan {
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let playerObjectiveNames = scenario.objectives.map(\.name)
        let playerScoreNames = bundle.balance.scoreChannels
            .filter { $0.side == .player || $0.side == .contested }
            .map(\.name)
        let denialTargets = bundle.aiPlan.targetPriorities.reversed()
        let priorities = uniqueNonEmpty(playerObjectiveNames + playerScoreNames + denialTargets)
        let primaryTarget = priorities.first ?? scenario.title
        let fallbackTarget = priorities.dropFirst().first ?? primaryTarget

        return AntiGuderianAIPlan(
            id: scenario.id,
            postureName: postureName(for: scenario.playerPosture),
            strategicGoal: scenario.designIntent,
            targetPriorities: priorities,
            orders: [
                order(
                    "\(scenario.id.rawValue)-anti-guderian-screen",
                    "Opening turns",
                    .movement,
                    primaryTarget,
                    "Move the normally human force toward the highest value delay, evacuation, breakout, or counterattack objective."
                ),
                order(
                    "\(scenario.id.rawValue)-anti-guderian-fire",
                    "Contact turns",
                    .shooting,
                    fallbackTarget,
                    "Select nearest German threats and fire to preserve the player scoring route."
                ),
                order(
                    "\(scenario.id.rawValue)-anti-guderian-deny",
                    "Endgame",
                    .assault,
                    primaryTarget,
                    "Contest the priority target and deny the German AI a clean scenario close."
                ),
            ]
        )
    }

    public static var allPlans: [AntiGuderianAIPlan] {
        GuderianCampaignCatalog.all.map(plan)
    }

    private static func postureName(for posture: PlayerPosture) -> String {
        switch posture {
        case .breakout:
            return "Breakout preservation"
        case .counterattack:
            return "Counterattack pressure"
        case .evacuationDefense:
            return "Evacuation defense"
        case .fortifiedDelay:
            return "Fortified delay"
        case .mobileDelay:
            return "Mobile delay"
        case .urbanDefense:
            return "Urban denial"
        }
    }

    private static func order(
        _ id: String,
        _ turnWindow: String,
        _ kind: GermanAIActionKind,
        _ target: String,
        _ instruction: String
    ) -> AntiGuderianAIOrder {
        AntiGuderianAIOrder(
            id: id,
            turnWindow: turnWindow,
            kind: kind,
            target: target,
            instruction: instruction
        )
    }

    private static func uniqueNonEmpty(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !trimmed.isEmpty, !seen.contains(key) else {
                continue
            }
            seen.insert(key)
            result.append(trimmed)
        }
        return result
    }
}

public struct PlayableTestGameStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let turnNumber: Int
    public let activePlayer: NativeBoardPlayer
    public let controller: PlayableTestAIController
    public let phase: NativeBoardPhase
    public let status: NativeBoardActionStatus
    public let title: String
    public let detail: String

    public init(
        id: String,
        turnNumber: Int,
        activePlayer: NativeBoardPlayer,
        controller: PlayableTestAIController,
        phase: NativeBoardPhase,
        status: NativeBoardActionStatus,
        title: String,
        detail: String
    ) {
        self.id = id
        self.turnNumber = turnNumber
        self.activePlayer = activePlayer
        self.controller = controller
        self.phase = phase
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct PlayableTestGameBattleResult: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let openingSnapshot: NativeBoardSnapshot
    public let finalSnapshot: NativeBoardSnapshot
    public let antiGuderianPlan: AntiGuderianAIPlan
    public let germanPlan: GermanAIPlan
    public let completion: PlayableBattleCompletionSummary
    public let steps: [PlayableTestGameStep]
    public let phaseAdvances: Int
    public let blockers: [String]

    public init(
        id: GuderianBattleID,
        title: String,
        openingSnapshot: NativeBoardSnapshot,
        finalSnapshot: NativeBoardSnapshot,
        antiGuderianPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan,
        completion: PlayableBattleCompletionSummary,
        steps: [PlayableTestGameStep],
        phaseAdvances: Int,
        blockers: [String]
    ) {
        self.id = id
        self.title = title
        self.openingSnapshot = openingSnapshot
        self.finalSnapshot = finalSnapshot
        self.antiGuderianPlan = antiGuderianPlan
        self.germanPlan = germanPlan
        self.completion = completion
        self.steps = steps
        self.phaseAdvances = phaseAdvances
        self.blockers = blockers
    }

    public var automatedSides: Set<NativeBoardPlayer> {
        Set(steps.map(\.activePlayer).filter { $0 == .player || $0 == .guderianAI })
    }

    public var antiGuderianStepCount: Int {
        steps.filter { $0.controller == .antiGuderian }.count
    }

    public var germanStepCount: Int {
        steps.filter { $0.controller == .guderian }.count
    }

    public var completedToEnd: Bool {
        blockers.isEmpty &&
            completion.completionRecord.scenarioID == id &&
            completion.completionRecord.completedTurn > 0 &&
            automatedSides.isSuperset(of: [.player, .guderianAI])
    }

    public var summary: String {
        "\(title) played to debrief with \(antiGuderianStepCount) Anti-Guderian AI steps, \(germanStepCount) German AI steps, and \(phaseAdvances) phase advances."
    }
}

public struct PlayableTestGameCampaignResult: Codable, Hashable, Sendable {
    public let battleIDs: [GuderianBattleID]
    public let results: [PlayableTestGameBattleResult]
    public let progress: CampaignProgress
    public let summary: CampaignCompletionSummary

    public init(
        battleIDs: [GuderianBattleID],
        results: [PlayableTestGameBattleResult],
        progress: CampaignProgress,
        summary: CampaignCompletionSummary
    ) {
        self.battleIDs = battleIDs
        self.results = results
        self.progress = progress
        self.summary = summary
    }

    public var completedAllBattlesToEnd: Bool {
        results.map(\.id) == battleIDs &&
            results.allSatisfy(\.completedToEnd) &&
            summary.isComplete
    }
}

public enum PlayableTestGameRunner {
    public static func runCampaign(
        ids: [GuderianBattleID] = GuderianCampaignCatalog.all.sorted { $0.order < $1.order }.map(\.id)
    ) throws -> PlayableTestGameCampaignResult {
        var progress = CampaignProgress()
        var results: [PlayableTestGameBattleResult] = []

        for id in ids {
            let result = try runBattle(for: id)
            results.append(result)
            progress.recordCompletion(result.completion.completionRecord)
        }

        let scenarios = ids.compactMap(GuderianCampaignCatalog.scenario)
        return PlayableTestGameCampaignResult(
            battleIDs: ids,
            results: results,
            progress: progress,
            summary: progress.completionSummary(catalog: scenarios)
        )
    }

    public static func runBattle(
        for id: GuderianBattleID,
        seed: UInt32? = nil
    ) throws -> PlayableTestGameBattleResult {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw NativeDemoParityError.missingScenario(id)
        }
        return try runBattle(scenario, seed: seed ?? defaultSeed(for: scenario))
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        seed: UInt32? = nil
    ) throws -> PlayableTestGameBattleResult {
        guard let session = NativeBoardSession(scenario: scenario, seed: seed ?? defaultSeed(for: scenario)) else {
            throw NativeDemoParityError.boardSessionUnavailable(scenario.id)
        }
        return try runBattle(from: session)
    }

    public static func runBattle(from session: NativeBoardSession) throws -> PlayableTestGameBattleResult {
        let scenario = session.loadout.scenario
        let opening = session.snapshot()
        guard opening.isScenarioBoardPlayable else {
            throw NativeDemoParityError.scenarioBoardUnavailable(scenario.id)
        }

        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let antiPlan = AntiGuderianAIPlanCatalog.plan(for: scenario)
        let germanPlan = GermanAIPlanCatalog.plan(for: scenario)
        let maxPhaseAdvances = max(24, balance.targetTurns.upperBound * 8)
        var steps: [PlayableTestGameStep] = []
        var phaseAdvances = 0
        var blockers: [String] = []
        var current = opening

        while current.turnNumber <= balance.targetTurns.upperBound &&
            current.mission.winner == .none &&
            phaseAdvances < maxPhaseAdvances {
            steps.append(
                performActiveAIPhase(
                    in: session,
                    before: current,
                    antiPlan: antiPlan,
                    germanPlan: germanPlan,
                    stepIndex: steps.count
                )
            )
            drainPendingChoices(in: session, steps: &steps)
            session.advancePhase()
            phaseAdvances += 1
            current = session.snapshot()
        }

        if phaseAdvances >= maxPhaseAdvances {
            blockers.append("\(scenario.title) hit the \(maxPhaseAdvances)-phase autoplay guard before debrief.")
        }
        let automatedSides = Set(steps.map(\.activePlayer))
        if !automatedSides.contains(.player) {
            blockers.append("Anti-Guderian AI did not receive an active phase.")
        }
        if !automatedSides.contains(.guderianAI) {
            blockers.append("Guderian AI did not receive an active phase.")
        }

        let completion = try PlayableBattleCompletionResolver.completeBattle(from: session)
        let final = session.snapshot()

        return PlayableTestGameBattleResult(
            id: scenario.id,
            title: scenario.title,
            openingSnapshot: opening,
            finalSnapshot: final,
            antiGuderianPlan: antiPlan,
            germanPlan: germanPlan,
            completion: completion,
            steps: steps,
            phaseAdvances: phaseAdvances,
            blockers: blockers
        )
    }

    private static func performActiveAIPhase(
        in session: NativeBoardSession,
        before snapshot: NativeBoardSnapshot,
        antiPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan,
        stepIndex: Int
    ) -> PlayableTestGameStep {
        let controller = PlayableTestAIController(activePlayer: snapshot.activePlayer)
        let status: NativeBoardActionStatus
        let title: String
        let detail: String

        switch snapshot.phase {
        case .movement:
            let moved = moveActiveUnits(in: session, snapshot: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            status = moved == 0 ? .blocked : .succeeded
            title = "\(controller.rawValue) movement"
            detail = moved == 0 ? "No legal movement was available." : "\(moved) active units moved toward priority objectives."
        case .shooting:
            let shots = shootActiveUnits(in: session, snapshot: snapshot)
            status = shots == 0 ? .blocked : .succeeded
            title = "\(controller.rawValue) shooting"
            detail = shots == 0 ? "No legal shots were available." : "\(shots) active units fired at nearest enemies."
        case .assault:
            let assaults = assaultActiveUnits(in: session, snapshot: snapshot)
            let resolved = session.resolveFirstPendingChoice()
            title = "\(controller.rawValue) assault"
            if assaults > 0 {
                status = .succeeded
                detail = "\(assaults) active units assaulted nearest enemies."
            } else if resolved {
                status = .succeeded
                detail = "Resolved a pending assault or damage choice."
            } else {
                status = .blocked
                detail = "No legal assaults or pending choices were available."
            }
        }

        return PlayableTestGameStep(
            id: "\(snapshot.scenarioID.rawValue)-playable-test-step-\(stepIndex)",
            turnNumber: snapshot.turnNumber,
            activePlayer: snapshot.activePlayer,
            controller: controller,
            phase: snapshot.phase,
            status: status,
            title: title,
            detail: detail
        )
    }

    private static func moveActiveUnits(
        in session: NativeBoardSession,
        snapshot: NativeBoardSnapshot,
        antiPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan
    ) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canMoveNow }
            .sorted { $0.id < $1.id }
        var moved = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            let usedPriority: Bool
            if snapshot.activePlayer == .guderianAI {
                usedPriority = session.moveSelectedUnitTowardPriorityObjective(named: germanPlan.targetPriorities(for: snapshot.phase), maxDistance: movementDistance(for: unit, controller: .guderian))
            } else {
                usedPriority = session.moveSelectedUnitTowardPriorityObjective(named: antiPlan.targetPriorities, maxDistance: movementDistance(for: unit, controller: .antiGuderian))
            }
            if usedPriority || session.moveSelectedUnitTowardNearestObjective(maxDistance: movementDistance(for: unit, controller: PlayableTestAIController(activePlayer: snapshot.activePlayer))) {
                moved += 1
            }
        }

        return moved
    }

    private static func shootActiveUnits(
        in session: NativeBoardSession,
        snapshot: NativeBoardSnapshot
    ) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canShootNow }
            .sorted { $0.id < $1.id }
        var shots = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if session.shootSelectedTarget() {
                shots += 1
                drainPendingChoices(in: session)
            }
        }

        return shots
    }

    private static func assaultActiveUnits(
        in session: NativeBoardSession,
        snapshot: NativeBoardSnapshot
    ) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canAssaultNow }
            .sorted { $0.id < $1.id }
        var assaults = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if let target = session.snapshot().selectedTarget,
               session.assaultUnit(unit.id, targetID: target.id, advance: true) {
                assaults += 1
                drainPendingChoices(in: session)
            }
        }

        return assaults
    }

    private static func drainPendingChoices(
        in session: NativeBoardSession,
        steps: inout [PlayableTestGameStep]
    ) {
        for _ in 0..<16 {
            let before = session.snapshot()
            guard session.resolveFirstPendingChoice() else {
                return
            }
            let after = session.snapshot()
            steps.append(
                PlayableTestGameStep(
                    id: "\(before.scenarioID.rawValue)-playable-test-step-\(steps.count)",
                    turnNumber: before.turnNumber,
                    activePlayer: before.activePlayer,
                    controller: PlayableTestAIController(activePlayer: before.activePlayer),
                    phase: before.phase,
                    status: after.lastAction.status,
                    title: after.lastAction.title,
                    detail: after.lastAction.detail
                )
            )
        }
    }

    private static func drainPendingChoices(in session: NativeBoardSession) {
        for _ in 0..<16 {
            guard session.resolveFirstPendingChoice() else {
                return
            }
        }
    }

    private static func movementDistance(for unit: NativeBoardUnitSnapshot, controller: PlayableTestAIController) -> Double {
        let base: Double
        if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
            base = controller == .guderian ? 9 : 7
        } else {
            base = controller == .guderian ? 5 : 4
        }
        return base
    }

    private static func defaultSeed(for scenario: GuderianScenario) -> UInt32 {
        UInt32(620_000 + scenario.order)
    }
}
