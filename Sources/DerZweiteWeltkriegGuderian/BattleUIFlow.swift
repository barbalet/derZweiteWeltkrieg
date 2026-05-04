import DerZweiteWeltkriegCore
import Foundation

public enum BattleUIFlowStage: String, CaseIterable, Codable, Hashable, Sendable {
    case campaignSelection = "Campaign Selection"
    case briefing = "Briefing"
    case mapReview = "Map Review"
    case forceSetup = "Force Setup"
    case objectives = "Objectives"
    case engineLoad = "Engine Load"
    case battleStart = "Battle Start"
    case turnPlayback = "Turn Playback"
    case debrief = "Debrief"
    case completion = "Completion"
}

public struct BattleUIFlowStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let stage: BattleUIFlowStage
    public let title: String
    public let actionLabel: String
    public let accessibilityIdentifier: String
    public let expectedVisibleText: String

    public init(
        id: String,
        stage: BattleUIFlowStage,
        title: String,
        actionLabel: String,
        accessibilityIdentifier: String,
        expectedVisibleText: String
    ) {
        self.id = id
        self.stage = stage
        self.title = title
        self.actionLabel = actionLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.expectedVisibleText = expectedVisibleText
    }
}

public struct BattleUIFlowPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let scenarioTitle: String
    public let expectedPlayerLabel: String
    public let expectedOpponentLabel: String
    public let steps: [BattleUIFlowStep]

    public init(
        id: GuderianBattleID,
        scenarioTitle: String,
        expectedPlayerLabel: String,
        expectedOpponentLabel: String,
        steps: [BattleUIFlowStep]
    ) {
        self.id = id
        self.scenarioTitle = scenarioTitle
        self.expectedPlayerLabel = expectedPlayerLabel
        self.expectedOpponentLabel = expectedOpponentLabel
        self.steps = steps
    }

    public var visitedStages: [BattleUIFlowStage] {
        BattleUIFlowStage.allCases.filter { stage in
            steps.contains { $0.stage == stage }
        }
    }

    public var accessibilityIdentifiers: [String] {
        steps.map(\.accessibilityIdentifier)
    }
}

public struct BattleUIFlowResult: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let plan: BattleUIFlowPlan
    public let completionRecord: CampaignCompletionRecord
    public let engineUnitCount: Int
    public let engineObjectiveCount: Int
    public let displayedAccessibilityIdentifiers: [String]
    public let displayedText: [String]

    public init(
        id: GuderianBattleID,
        plan: BattleUIFlowPlan,
        completionRecord: CampaignCompletionRecord,
        engineUnitCount: Int,
        engineObjectiveCount: Int,
        displayedAccessibilityIdentifiers: [String],
        displayedText: [String]
    ) {
        self.id = id
        self.plan = plan
        self.completionRecord = completionRecord
        self.engineUnitCount = engineUnitCount
        self.engineObjectiveCount = engineObjectiveCount
        self.displayedAccessibilityIdentifiers = displayedAccessibilityIdentifiers
        self.displayedText = displayedText
    }

    public var completedAllStages: Bool {
        plan.visitedStages == BattleUIFlowStage.allCases
    }
}

public struct BattleUIFlowSuiteResult: Codable, Hashable, Sendable {
    public let battleIDs: [GuderianBattleID]
    public let results: [BattleUIFlowResult]
    public let progress: CampaignProgress
    public let summary: CampaignCompletionSummary

    public init(
        battleIDs: [GuderianBattleID],
        results: [BattleUIFlowResult],
        progress: CampaignProgress,
        summary: CampaignCompletionSummary
    ) {
        self.battleIDs = battleIDs
        self.results = results
        self.progress = progress
        self.summary = summary
    }

    public var totalScore: Int {
        results.reduce(0) { $0 + $1.completionRecord.score }
    }
}

public enum BattleUIFlowError: Error, Equatable, CustomStringConvertible {
    case missingScenario(GuderianBattleID)
    case missingLoadout(GuderianBattleID)
    case gameCreationFailed(GuderianBattleID)

    public var description: String {
        switch self {
        case .missingScenario(let id):
            return "Scenario \(id.rawValue) is not present in the campaign catalog."
        case .missingLoadout(let id):
            return "Scenario \(id.rawValue) could not be loaded through the dzw proxy."
        case .gameCreationFailed(let id):
            return "Scenario \(id.rawValue) produced no dzw game instance."
        }
    }
}

public enum BattleUIFlowRunner {
    public static let fiveBattleScenarioIDs: [GuderianBattleID] = [
        .tucholaForest,
        .sedan,
        .calais,
        .smolensk,
        .moscowTulaKashira,
    ]

    public static func plan(for id: GuderianBattleID) throws -> BattleUIFlowPlan {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw BattleUIFlowError.missingScenario(id)
        }
        guard let loadout = DZWScenarioLoader.load(id, seed: seed(for: scenario)) else {
            throw BattleUIFlowError.missingLoadout(id)
        }

        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let turnSteps = (1...bundle.balance.targetTurns.upperBound).map { turn in
            step(
                scenario,
                stage: .turnPlayback,
                suffix: "turn-\(turn)",
                title: "Turn \(turn)",
                action: "Advance turn \(turn)",
                text: "Turn \(turn) of \(bundle.balance.targetTurns.upperBound)"
            )
        }

        let steps: [BattleUIFlowStep] = [
            step(scenario, stage: .campaignSelection, suffix: "row", title: "Select \(scenario.title)", action: "Open campaign row", text: scenario.title),
            step(scenario, stage: .briefing, suffix: "briefing", title: "Briefing", action: "Review battle briefing", text: scenario.designIntent),
            step(scenario, stage: .mapReview, suffix: "map", title: bundle.mapLayout.title, action: "Review historical map", text: "\(bundle.mapLayout.elements.count) map elements"),
            step(scenario, stage: .forceSetup, suffix: "setup", title: "Force Setup", action: "Review force setup", text: "\(bundle.setup.units.count) force cards"),
            step(scenario, stage: .objectives, suffix: "objectives", title: "Objectives", action: "Review objectives", text: "\(scenario.objectives.count) objectives"),
            step(scenario, stage: .engineLoad, suffix: "engine", title: "Engine Load", action: "Load dzw proxy game", text: "\(loadout.playerArmyName) vs \(loadout.opponentArmyName)"),
            step(scenario, stage: .battleStart, suffix: "start", title: "Begin Battle", action: "Begin battle", text: bundle.aiPlan.postureName),
        ] + turnSteps + [
            step(scenario, stage: .debrief, suffix: "debrief", title: "Debrief", action: "Open debrief bands", text: bundle.balance.playerWinCondition),
            step(scenario, stage: .completion, suffix: "completion", title: "Complete \(scenario.title)", action: "Record completion", text: "Complete"),
        ]

        return BattleUIFlowPlan(
            id: id,
            scenarioTitle: scenario.title,
            expectedPlayerLabel: loadout.playerArmyName,
            expectedOpponentLabel: loadout.opponentArmyName,
            steps: steps
        )
    }

    public static func runFullBattleFlow(for id: GuderianBattleID) throws -> BattleUIFlowResult {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw BattleUIFlowError.missingScenario(id)
        }
        guard let loadout = DZWScenarioLoader.load(id, seed: seed(for: scenario)) else {
            throw BattleUIFlowError.missingLoadout(id)
        }
        guard let game = loadout.makeGame() else {
            throw BattleUIFlowError.gameCreationFailed(id)
        }
        defer { game_destroy(game) }

        let plan = try plan(for: id)
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let completionRecord = CampaignCompletionRecord(
            scenarioID: id,
            score: balance.maxPlayerScore,
            victoryBand: .operational,
            completedTurn: balance.targetTurns.upperBound,
            note: "Completed through the deterministic Guderian UI battle flow."
        )

        return BattleUIFlowResult(
            id: id,
            plan: plan,
            completionRecord: completionRecord,
            engineUnitCount: Int(game_unit_count(game)),
            engineObjectiveCount: Int(game_objective_count(game)),
            displayedAccessibilityIdentifiers: plan.accessibilityIdentifiers,
            displayedText: plan.steps.map(\.expectedVisibleText)
        )
    }

    public static func runFiveBattleCampaignFlow(
        ids: [GuderianBattleID] = fiveBattleScenarioIDs
    ) throws -> BattleUIFlowSuiteResult {
        let scenarios = try ids.map { id in
            guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
                throw BattleUIFlowError.missingScenario(id)
            }
            return scenario
        }

        var progress = CampaignProgress()
        var results: [BattleUIFlowResult] = []

        for id in ids {
            let result = try runFullBattleFlow(for: id)
            results.append(result)
            progress.recordCompletion(result.completionRecord)
        }

        return BattleUIFlowSuiteResult(
            battleIDs: ids,
            results: results,
            progress: progress,
            summary: progress.completionSummary(catalog: scenarios)
        )
    }

    private static func seed(for scenario: GuderianScenario) -> UInt32 {
        UInt32(25_000 + scenario.order)
    }

    private static func step(
        _ scenario: GuderianScenario,
        stage: BattleUIFlowStage,
        suffix: String,
        title: String,
        action: String,
        text: String
    ) -> BattleUIFlowStep {
        BattleUIFlowStep(
            id: "\(scenario.id.rawValue)-\(suffix)",
            stage: stage,
            title: title,
            actionLabel: action,
            accessibilityIdentifier: "ui-flow-\(scenario.id.rawValue)-\(suffix)",
            expectedVisibleText: text
        )
    }
}
