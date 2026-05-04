import Foundation

public struct ScenarioContentBundle: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let scenario: GuderianScenario
    public let mapLayout: ScenarioMapLayout
    public let setup: ScenarioSetupScript
    public let aiPlan: GermanAIPlan
    public let balance: ScenarioBalanceProfile
    public let logEntries: [ScenarioLogEntry]
    public let historicalOverlay: ScenarioHistoricalOverlay

    public init(
        scenario: GuderianScenario,
        mapLayout: ScenarioMapLayout,
        setup: ScenarioSetupScript,
        aiPlan: GermanAIPlan,
        balance: ScenarioBalanceProfile,
        logEntries: [ScenarioLogEntry],
        historicalOverlay: ScenarioHistoricalOverlay
    ) {
        self.id = scenario.id
        self.scenario = scenario
        self.mapLayout = mapLayout
        self.setup = setup
        self.aiPlan = aiPlan
        self.balance = balance
        self.logEntries = logEntries
        self.historicalOverlay = historicalOverlay
    }
}

public enum ScenarioContentCatalog {
    public static let handAuthoredScenarioIDs: Set<GuderianBattleID> = [
        .tucholaForest,
        .wizna,
        .brzescLitewski,
        .kobryn,
        .sedan,
        .stonne,
        .montcornet,
        .amiensAbbeville,
        .boulogne,
        .calais,
        .dunkirk,
        .fallRot,
        .bialystokMinsk,
        .smolensk,
        .roslavlNovozybkov,
        .kiev,
        .bryansk,
        .mtsensk,
        .moscowTulaKashira,
    ]

    public static func bundle(for scenario: GuderianScenario) -> ScenarioContentBundle {
        ScenarioContentBundle(
            scenario: scenario,
            mapLayout: ScenarioMapCatalog.layout(for: scenario),
            setup: ScenarioSetupCatalog.setup(for: scenario),
            aiPlan: GermanAIPlanCatalog.plan(for: scenario),
            balance: ScenarioBalanceCatalog.profile(for: scenario),
            logEntries: ScenarioEventLogCatalog.entries(for: scenario),
            historicalOverlay: ScenarioHistoricalOverlayCatalog.overlay(for: scenario)
        )
    }

    public static func bundle(for id: GuderianBattleID) -> ScenarioContentBundle? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return bundle(for: scenario)
    }

    public static var allBundles: [ScenarioContentBundle] {
        GuderianCampaignCatalog.all.map(bundle)
    }
}
