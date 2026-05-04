import Foundation

public struct ScenarioBalanceAudit: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let agencyNote: String
    public let pressureNote: String
    public let victoryGradeCount: Int
    public let minimumPlayerScore: Int
    public let maximumPlayerScore: Int

    public init(
        id: GuderianBattleID,
        agencyNote: String,
        pressureNote: String,
        victoryGradeCount: Int,
        minimumPlayerScore: Int,
        maximumPlayerScore: Int
    ) {
        self.id = id
        self.agencyNote = agencyNote
        self.pressureNote = pressureNote
        self.victoryGradeCount = victoryGradeCount
        self.minimumPlayerScore = minimumPlayerScore
        self.maximumPlayerScore = maximumPlayerScore
    }
}

public enum ScenarioBalanceAuditCatalog {
    public static func audit(for scenario: GuderianScenario) -> ScenarioBalanceAudit {
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        return ScenarioBalanceAudit(
            id: scenario.id,
            agencyNote: balance.playerWinCondition,
            pressureNote: balance.germanPressureLimit,
            victoryGradeCount: Set(balance.outcomeBands.map(\.grade)).count,
            minimumPlayerScore: balance.outcomeBands.map(\.scoreRange.lowerBound).min() ?? 0,
            maximumPlayerScore: balance.maxPlayerScore
        )
    }

    public static func audit(for id: GuderianBattleID) -> ScenarioBalanceAudit? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return audit(for: scenario)
    }

    public static var allAudits: [ScenarioBalanceAudit] {
        GuderianCampaignCatalog.all.map(audit)
    }
}
