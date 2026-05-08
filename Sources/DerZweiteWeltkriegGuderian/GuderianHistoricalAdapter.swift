import DerZweiteWeltkriegCore
import DerZweiteWeltkriegHistorical
import Foundation

extension GuderianBattleID: HistoricalBattleID {}

public enum GuderianHistoricalSideID {
    public static let guderianCommand = "guderian-command"
    public static let opposingForce = "opposing-force"
}

public enum GuderianHistoricalSideSelectionMemory {
    public static func selectedSideID(
        for scenario: GuderianScenario,
        encodedSelections: String,
        fallbackSideID: String = GuderianHistoricalSideSelectionResolver.defaultHumanSideID
    ) -> String {
        let historicalScenario = GuderianHistoricalScenarioAdapter.scenario(for: scenario)
        let selections = sideSelections(from: encodedSelections)

        if let selectedSideID = selections[scenario.id.rawValue],
           historicalScenario.sideOption(id: selectedSideID) != nil {
            return selectedSideID
        }

        if historicalScenario.sideOption(id: fallbackSideID) != nil {
            return fallbackSideID
        }

        return GuderianHistoricalSideSelectionResolver.defaultHumanSideID
    }

    public static func encodedSelections(
        _ encodedSelections: String,
        selecting sideID: String,
        for scenario: GuderianScenario
    ) -> String {
        guard GuderianHistoricalScenarioAdapter.scenario(for: scenario).sideOption(id: sideID) != nil else {
            return encodedSelections
        }

        var selections = sideSelections(from: encodedSelections)
        selections[scenario.id.rawValue] = sideID
        return encode(selections)
    }

    public static func sideSelections(from encodedSelections: String) -> [String: String] {
        guard let data = encodedSelections.data(using: .utf8),
              let selections = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return selections
    }

    private static func encode(_ selections: [String: String]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        guard let data = try? encoder.encode(selections),
              let encoded = String(data: data, encoding: .utf8) else {
            return ""
        }

        return encoded
    }
}

public enum GuderianHistoricalSideSelectionResolver {
    public static let defaultHumanSideID = GuderianHistoricalSideID.opposingForce

    public static func makeLaunch(
        for scenario: GuderianScenario,
        chosenHumanSideID: String = defaultHumanSideID,
        seed: UInt32
    ) throws -> HistoricalBattleLaunch<GuderianBattleID> {
        let historicalScenario = GuderianHistoricalScenarioAdapter.scenario(for: scenario)
        let humanSlot = enginePlayerSlot(for: chosenHumanSideID) ?? .playerOne
        return try HistoricalBattleLaunchResolver.makeLaunch(
            scenario: historicalScenario,
            chosenHumanSideID: chosenHumanSideID,
            seed: seed,
            humanSlot: humanSlot
        )
    }

    public static func resolvedSelection(
        for scenario: GuderianScenario,
        chosenHumanSideID: String = defaultHumanSideID,
        seed: UInt32
    ) throws -> HistoricalBattleSideSelection<GuderianBattleID> {
        let historicalScenario = GuderianHistoricalScenarioAdapter.scenario(for: scenario)
        let launch = try makeLaunch(
            for: scenario,
            chosenHumanSideID: chosenHumanSideID,
            seed: seed
        )
        return historicalScenario.resolvedSideSelection(for: launch)
    }

    public static func nativePlayer(for sideID: String) -> NativeBoardPlayer? {
        switch sideID {
        case GuderianHistoricalSideID.opposingForce:
            return .player
        case GuderianHistoricalSideID.guderianCommand:
            return .guderianAI
        default:
            return nil
        }
    }

    public static func sideID(for player: NativeBoardPlayer) -> String? {
        switch player {
        case .player:
            return GuderianHistoricalSideID.opposingForce
        case .guderianAI:
            return GuderianHistoricalSideID.guderianCommand
        case .none:
            return nil
        }
    }

    public static func enginePlayerSlot(for sideID: String) -> HistoricalEnginePlayerSlot? {
        switch nativePlayer(for: sideID) {
        case .some(.player):
            return .playerOne
        case .some(.guderianAI):
            return .playerTwo
        case .some(.none), nil:
            return nil
        }
    }

    public static func sideTitle(
        for player: NativeBoardPlayer,
        in scenario: GuderianScenario
    ) -> String {
        guard let sideID = sideID(for: player),
              let side = GuderianHistoricalScenarioAdapter.scenario(for: scenario).sideOption(id: sideID) else {
            return player.rawValue
        }
        return side.title
    }
}

public enum GuderianHistoricalScenarioAdapter {
    public static func scenario(for guderianScenario: GuderianScenario) -> HistoricalBattleScenario<GuderianBattleID> {
        let balance = ScenarioBalanceCatalog.profile(for: guderianScenario)

        return HistoricalBattleScenario(
            id: guderianScenario.id,
            order: guderianScenario.order,
            title: guderianScenario.title,
            dateLabel: guderianScenario.dateLabel,
            theater: guderianScenario.theater.rawValue,
            status: historicalStatus(for: guderianScenario.status),
            historicalResult: guderianScenario.historicalResult,
            designIntent: guderianScenario.designIntent,
            sourceLinks: guderianScenario.sourceLinks.map { source in
                HistoricalSourceLink(title: source.title, url: source.url.absoluteString)
            },
            sideOptions: sideOptions(for: guderianScenario),
            map: historicalMap(for: guderianScenario),
            objectives: guderianScenario.objectives.enumerated().map { index, objective in
                HistoricalObjective(
                    id: "\(guderianScenario.id.rawValue)-objective-\(index + 1)",
                    name: objective.name,
                    sideID: GuderianHistoricalSideID.opposingForce,
                    victoryPoints: objective.victoryPoints,
                    location: objectiveLocation(index: index, total: guderianScenario.objectives.count),
                    radius: 4,
                    description: objective.description
                )
            },
            victory: HistoricalVictoryProfile(
                targetScore: balance.maxPlayerScore,
                targetTurnUpperBound: balance.targetTurns.upperBound,
                bands: balance.outcomeBands.map { band in
                    HistoricalVictoryBand(
                        id: band.id,
                        label: band.grade.rawValue,
                        scoreRange: band.scoreRange,
                        summary: band.summary
                    )
                }
            ),
            tags: guderianScenario.tags
        )
    }

    public static func allScenarios() -> [HistoricalBattleScenario<GuderianBattleID>] {
        GuderianCampaignCatalog.all.map(scenario)
    }

    public static func scenario(id: GuderianBattleID) -> HistoricalBattleScenario<GuderianBattleID>? {
        GuderianCampaignCatalog.scenario(id: id).map(scenario)
    }

    private static func sideOptions(for scenario: GuderianScenario) -> [HistoricalSideOption] {
        [
            HistoricalSideOption(
                id: GuderianHistoricalSideID.guderianCommand,
                role: .protagonist,
                title: "Guderian's command",
                historicalForce: scenario.guderianCommand,
                commander: "Heinz Guderian",
                armyListName: "German",
                playerBriefing: "Use the German command-side study mode to compare operational pressure while keeping the non-celebratory historical framing visible.",
                aiBriefing: "Use German AI priorities to pressure the scenario objectives."
            ),
            HistoricalSideOption(
                id: GuderianHistoricalSideID.opposingForce,
                role: .opponent,
                title: "Opposing army",
                historicalForce: scenario.playerForceSummary,
                commander: nil,
                armyListName: opposingArmyListName(for: scenario),
                playerBriefing: "Use the default opposing-force lens to delay, counterattack, evacuate, or defend according to the scenario posture.",
                aiBriefing: "Use anti-Guderian priorities to contest the German plan."
            ),
        ]
    }

    private static func historicalMap(for scenario: GuderianScenario) -> HistoricalBattleMap {
        HistoricalBattleMap(
            title: "\(scenario.title) operations map",
            elements: scenario.mapFeatures.enumerated().map { index, feature in
                HistoricalMapElement(
                    id: "\(scenario.id.rawValue)-feature-\(index + 1)",
                    name: feature.name,
                    kind: mapElementKind(for: feature),
                    points: mapFeaturePoints(index: index, total: scenario.mapFeatures.count),
                    note: feature.role
                )
            },
            deploymentZones: [
                HistoricalDeploymentZone(
                    id: "\(scenario.id.rawValue)-opposition-start",
                    sideID: GuderianHistoricalSideID.opposingForce,
                    name: "Opposing force deployment",
                    origin: HistoricalBattleCoordinate(x: 6, y: 8),
                    width: 28,
                    height: 18,
                    note: scenario.playerForceSummary
                ),
                HistoricalDeploymentZone(
                    id: "\(scenario.id.rawValue)-guderian-start",
                    sideID: GuderianHistoricalSideID.guderianCommand,
                    name: "Guderian command deployment",
                    origin: HistoricalBattleCoordinate(x: Double(game_board_width()) - 34, y: Double(game_board_height()) - 26),
                    width: 28,
                    height: 18,
                    note: scenario.guderianCommand
                ),
            ]
        )
    }

    private static func historicalStatus(for status: ScenarioStatus) -> HistoricalBattleStatus {
        switch status {
        case .dataLocked:
            return .dataLocked
        case .dzwProxyLoadable:
            return .playable
        case .planned:
            return .planned
        }
    }

    private static func opposingArmyListName(for scenario: GuderianScenario) -> String {
        switch scenario.theater {
        case .easternFront1941:
            return "Soviet"
        case .france1940, .poland1939:
            return "British"
        }
    }

    private static func mapElementKind(for feature: ScenarioMapFeature) -> HistoricalMapElementKind {
        let text = "\(feature.name) \(feature.role)".lowercased()
        if text.contains("river") || text.contains("canal") {
            return .river
        }
        if text.contains("road") || text.contains("route") {
            return .road
        }
        if text.contains("forest") || text.contains("wood") {
            return .forest
        }
        if text.contains("bridge") || text.contains("crossing") {
            return .bridge
        }
        if text.contains("mine") {
            return .minefield
        }
        if text.contains("ridge") || text.contains("height") || text.contains("hill") {
            return .ridge
        }
        if text.contains("town") || text.contains("city") || text.contains("village") || text.contains("hub") {
            return .town
        }
        return .other
    }

    private static func mapFeaturePoints(index: Int, total: Int) -> [HistoricalBattleCoordinate] {
        let count = max(1, total)
        let x = 12 + (Double(index % 4) * 18)
        let y = 12 + (Double(index / 4) * max(7, 42 / Double(count)))
        return [
            HistoricalBattleCoordinate(x: x, y: y),
            HistoricalBattleCoordinate(x: min(Double(game_board_width()) - 8, x + 12), y: min(Double(game_board_height()) - 6, y + 4)),
        ]
    }

    private static func objectiveLocation(index: Int, total: Int) -> HistoricalBattleCoordinate {
        let spacing = Double(game_board_width()) / Double(max(2, total + 1))
        return HistoricalBattleCoordinate(
            x: spacing * Double(index + 1),
            y: Double(game_board_height()) * 0.48
        )
    }
}

public struct GuderianHistoricalAutoplayRewriteReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let primaryBattleID: GuderianBattleID
    public let sharedScenarioTitle: String
    public let sideIDs: [String]
    public let sharedSurfaceName: String
    public let retiredEmbeddedSurfaceNames: [String]
    public let requiredAccessibilityIdentifiers: [String]
    public let speedModes: [String]
    public let supportsDeterministicSeed: Bool
    public let exposesSharedAutoplayConfiguration: Bool

    public var isReady: Bool {
        cycleRange == 46...55 &&
            primaryBattleID == .tucholaForest &&
            sideIDs == [
                GuderianHistoricalSideID.guderianCommand,
                GuderianHistoricalSideID.opposingForce,
            ] &&
            sharedSurfaceName == HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName &&
            retiredEmbeddedSurfaceNames.contains("DZWPlayableBattleView") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-run-to-debrief-button") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-result-summary") &&
            speedModes == HistoricalAutoplaySpeed.allCases.map(\.rawValue) &&
            supportsDeterministicSeed &&
            exposesSharedAutoplayConfiguration
    }
}

public enum GuderianHistoricalAutoplayCatalog {
    public static let cycleRange = 46...55
    public static let primaryBattleID: GuderianBattleID = .tucholaForest
    public static let defaultSeed: UInt32 = 620_001

    public static let firstBattleContract = HistoricalAutoplayContract(
        primarySurfaceName: "GuderianTestFirstBattleAutoplayView",
        retiredEmbeddedSurfaceNames: ["DZWPlayableBattleView"],
        requiredAccessibilityIdentifiers: [
            "guderian-test-first-battle-autoplay",
            "guderian-test-primary-battle-surface",
            "guderian-test-run-to-debrief-button",
            "guderian-test-step-button",
            "guderian-test-pause-button",
            "guderian-test-speed-picker",
            "guderian-test-safety-cap",
            "guderian-test-event-log",
            "guderian-test-result-panel",
            "guderian-test-result-summary",
        ],
        speedModes: HistoricalAutoplaySpeed.allCases.map(\.rawValue)
    )

    public static func firstBattleScenario() -> HistoricalBattleScenario<GuderianBattleID>? {
        GuderianHistoricalScenarioAdapter.scenario(id: primaryBattleID)
    }

    public static func configuration(
        for scenario: GuderianScenario,
        seed: UInt32 = defaultSeed
    ) -> HistoricalAutoplayConfiguration<GuderianBattleID> {
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let opposingForcePlan = OpposingForceAIPlanCatalog.plan(for: scenario)
        let germanPlan = GermanAIPlanCatalog.plan(for: scenario)

        return HistoricalAutoplayConfiguration(
            battleID: scenario.id,
            battleTitle: scenario.title,
            seed: seed,
            contract: firstBattleContract,
            targetTurnUpperBound: balance.targetTurns.upperBound,
            sidePlans: [
                HistoricalAutoplaySidePlan(
                    sideID: GuderianHistoricalSideID.opposingForce,
                    controllerLabel: "Default-side automation",
                    movementPriorityNames: opposingForcePlan.targetPriorities(for: .movement),
                    movementDistance: 5,
                    tacticalPlan: HistoricalAutoplayTacticalPlan(opposingForcePlan: opposingForcePlan)
                ),
                HistoricalAutoplaySidePlan(
                    sideID: GuderianHistoricalSideID.guderianCommand,
                    controllerLabel: "Guderian-command automation",
                    movementPriorityNames: germanPlan.targetPriorities(for: .movement),
                    movementDistance: 7,
                    tacticalPlan: HistoricalAutoplayTacticalPlan(germanPlan: germanPlan)
                ),
            ]
        )
    }

    public static var rewriteReport: GuderianHistoricalAutoplayRewriteReport {
        let scenario = firstBattleScenario()
        let configuration = GuderianCampaignCatalog.scenario(id: primaryBattleID).map {
            self.configuration(for: $0)
        }

        return GuderianHistoricalAutoplayRewriteReport(
            cycleRange: cycleRange,
            primaryBattleID: primaryBattleID,
            sharedScenarioTitle: scenario?.title ?? "",
            sideIDs: scenario?.sideOptions.map(\.id) ?? [],
            sharedSurfaceName: firstBattleContract.embeddedBattleSurfaceName,
            retiredEmbeddedSurfaceNames: firstBattleContract.retiredEmbeddedSurfaceNames,
            requiredAccessibilityIdentifiers: firstBattleContract.requiredAccessibilityIdentifiers,
            speedModes: firstBattleContract.speedModes,
            supportsDeterministicSeed: configuration?.seed == defaultSeed,
            exposesSharedAutoplayConfiguration: configuration != nil
        )
    }
}

private extension HistoricalAutoplayTacticalPlan {
    init(opposingForcePlan plan: OpposingForceAIPlan) {
        self.init(
            id: plan.id.rawValue,
            armyFamilyName: plan.armyFamily.rawValue,
            behaviorProfileName: plan.behaviorProfile.rawValue,
            strategicGoal: plan.strategicGoal,
            targetPriorities: plan.targetPriorities,
            orders: plan.orders.map {
                HistoricalAutoplayTacticalOrder(
                    id: $0.id,
                    turnWindow: $0.turnWindow,
                    phase: HistoricalBoardPhase(native: $0.kind.nativeBoardPhase),
                    target: $0.target,
                    instruction: $0.instruction
                )
            }
        )
    }

    init(germanPlan plan: GermanAIPlan) {
        self.init(
            id: "german-\(plan.id.rawValue)",
            armyFamilyName: "German command",
            behaviorProfileName: plan.postureName,
            strategicGoal: plan.strategicGoal,
            targetPriorities: plan.targetPriorities,
            orders: plan.orders.map {
                HistoricalAutoplayTacticalOrder(
                    id: $0.id,
                    turnWindow: $0.turnWindow,
                    phase: HistoricalBoardPhase(native: $0.kind.nativeBoardPhase),
                    target: $0.target,
                    instruction: $0.instruction
                )
            }
        )
    }
}

private extension HistoricalBoardPhase {
    init(native phase: NativeBoardPhase) {
        switch phase {
        case .movement:
            self = .movement
        case .shooting:
            self = .shooting
        case .assault:
            self = .assault
        }
    }
}
