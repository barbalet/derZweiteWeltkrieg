import Foundation

public enum ScenarioLogCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case briefing = "Briefing"
    case objectives = "Objectives"
    case forces = "Forces"
    case aiPlan = "AI Plan"
    case balance = "Balance"
    case reinforcements = "Reinforcements"
    case historical = "Historical"
}

public struct ScenarioLogEntry: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let category: ScenarioLogCategory
    public let turnWindow: String
    public let title: String
    public let detail: String

    public init(id: String, category: ScenarioLogCategory, turnWindow: String, title: String, detail: String) {
        self.id = id
        self.category = category
        self.turnWindow = turnWindow
        self.title = title
        self.detail = detail
    }
}

public enum ScenarioEventLogCatalog {
    public static func entries(for scenario: GuderianScenario) -> [ScenarioLogEntry] {
        let setup = ScenarioSetupCatalog.setup(for: scenario)
        let aiPlan = GermanAIPlanCatalog.plan(for: scenario)
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let overlay = ScenarioHistoricalOverlayCatalog.overlay(for: scenario)

        let objectiveEntries = scenario.objectives.map { objective in
            entry(
                "\(scenario.id.rawValue)-objective-\(objective.name)",
                .objectives,
                objective.name,
                "\(objective.victoryPoints) VP",
                objective.description
            )
        }

        let forceEntries = setup.units.map { unit in
            entry(unit.id, .forces, unit.side.rawValue, unit.name, "\(unit.role): \(unit.historicalNote)")
        }

        let aiEntries = aiPlan.orders.map { order in
            entry(order.id, .aiPlan, order.turnWindow, "\(order.kind.rawValue): \(order.target)", order.instruction)
        }

        let balanceEntries = balance.pacingRules.map { rule in
            entry(rule.id, .balance, rule.turnWindow, rule.name, rule.effect)
        }

        let reinforcementEntries = balance.reinforcements.map { reinforcement in
            entry(
                reinforcement.id,
                .reinforcements,
                reinforcement.turnWindow,
                reinforcement.unitName,
                "\(reinforcement.side.rawValue): \(reinforcement.entryCondition)"
            )
        }

        let historicalEntries = [
            entry("\(scenario.id.rawValue)-commander-context", .historical, "Context", "Commander context", overlay.commanderContext),
            entry("\(scenario.id.rawValue)-outcome-summary", .historical, "Outcome", "Historical outcome", overlay.outcomeSummary),
        ] + overlay.caveats.enumerated().map { index, caveat in
            entry("\(scenario.id.rawValue)-caveat-\(index)", .historical, "Caveat", "Scenario caveat", caveat)
        }

        return [
            entry(
                "\(scenario.id.rawValue)-briefing",
                .briefing,
                scenario.dateLabel,
                scenario.title,
                setup.playerBriefing
            ),
        ] + historicalEntries + objectiveEntries + forceEntries + aiEntries + balanceEntries + reinforcementEntries
    }
}

private func entry(
    _ id: String,
    _ category: ScenarioLogCategory,
    _ turnWindow: String,
    _ title: String,
    _ detail: String
) -> ScenarioLogEntry {
    ScenarioLogEntry(id: id, category: category, turnWindow: turnWindow, title: title, detail: detail)
}
