import Foundation

public struct HistoricalScenarioBoardHookMigration: Codable, Hashable, Sendable {
    public let legacyGuardMacroName: String
    public let legacyZoneStructName: String
    public let legacyObjectiveStructName: String
    public let legacyFunctionName: String
    public let genericZoneStructName: String
    public let genericObjectiveStructName: String
    public let genericFunctionName: String
    public let keepsLegacyCompatibilityWrapper: Bool

    public init(
        legacyGuardMacroName: String,
        legacyZoneStructName: String,
        legacyObjectiveStructName: String,
        legacyFunctionName: String,
        genericZoneStructName: String,
        genericObjectiveStructName: String,
        genericFunctionName: String,
        keepsLegacyCompatibilityWrapper: Bool
    ) {
        self.legacyGuardMacroName = legacyGuardMacroName
        self.legacyZoneStructName = legacyZoneStructName
        self.legacyObjectiveStructName = legacyObjectiveStructName
        self.legacyFunctionName = legacyFunctionName
        self.genericZoneStructName = genericZoneStructName
        self.genericObjectiveStructName = genericObjectiveStructName
        self.genericFunctionName = genericFunctionName
        self.keepsLegacyCompatibilityWrapper = keepsLegacyCompatibilityWrapper
    }

    public var isGenericMigrationReady: Bool {
        legacyFunctionName == "game_apply_guderian_scenario_board" &&
            genericFunctionName == "game_apply_historical_scenario_board" &&
            genericZoneStructName == "historical_scenario_zone_t" &&
            genericObjectiveStructName == "historical_scenario_objective_t" &&
            keepsLegacyCompatibilityWrapper
    }
}

public enum HistoricalScenarioBoardHookCatalog {
    public static let currentGuderianToHistoricalMigration = HistoricalScenarioBoardHookMigration(
        legacyGuardMacroName: "HEINZ_GUDERIAN_GAME",
        legacyZoneStructName: "guderian_scenario_zone_t",
        legacyObjectiveStructName: "guderian_scenario_objective_t",
        legacyFunctionName: "game_apply_guderian_scenario_board",
        genericZoneStructName: "historical_scenario_zone_t",
        genericObjectiveStructName: "historical_scenario_objective_t",
        genericFunctionName: "game_apply_historical_scenario_board",
        keepsLegacyCompatibilityWrapper: true
    )
}
