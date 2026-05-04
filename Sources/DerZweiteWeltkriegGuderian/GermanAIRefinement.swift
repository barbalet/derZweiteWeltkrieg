import Foundation

public enum GermanAIDifficultyTier: String, CaseIterable, Codable, Hashable, Sendable {
    case cautious = "Cautious"
    case historical = "Historical"
    case aggressive = "Aggressive"
}

public struct GermanAIBehavior: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let trigger: String
    public let response: String

    public init(id: String, trigger: String, response: String) {
        self.id = id
        self.trigger = trigger
        self.response = response
    }
}

public struct GermanAISnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let primaryOrderID: String
    public let fallbackBehaviors: [GermanAIBehavior]
    public let difficultyTiers: [GermanAIDifficultyTier]
    public let deterministicSeedHint: UInt32

    public init(
        id: GuderianBattleID,
        primaryOrderID: String,
        fallbackBehaviors: [GermanAIBehavior],
        difficultyTiers: [GermanAIDifficultyTier],
        deterministicSeedHint: UInt32
    ) {
        self.id = id
        self.primaryOrderID = primaryOrderID
        self.fallbackBehaviors = fallbackBehaviors
        self.difficultyTiers = difficultyTiers
        self.deterministicSeedHint = deterministicSeedHint
    }
}

public enum GermanAIRefinementCatalog {
    public static func snapshot(for scenario: GuderianScenario) -> GermanAISnapshot {
        let plan = GermanAIPlanCatalog.plan(for: scenario)
        return GermanAISnapshot(
            id: scenario.id,
            primaryOrderID: plan.orders.first?.id ?? "\(scenario.id.rawValue)-advance",
            fallbackBehaviors: fallbackBehaviors(for: scenario, plan: plan),
            difficultyTiers: GermanAIDifficultyTier.allCases,
            deterministicSeedHint: UInt32(10_000 + scenario.order * 37 + scenario.id.rawValue.count)
        )
    }

    public static func snapshot(for id: GuderianBattleID) -> GermanAISnapshot? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return snapshot(for: scenario)
    }

    public static var allSnapshots: [GermanAISnapshot] {
        GuderianCampaignCatalog.all.map(snapshot)
    }

    private static func fallbackBehaviors(for scenario: GuderianScenario, plan: GermanAIPlan) -> [GermanAIBehavior] {
        var behaviors = [
            behavior(
                "\(scenario.id.rawValue)-fallback-preserve-mobile",
                "The primary target is blocked, demolished, or covered by high-value anti-tank fire.",
                "Shift one order to suppression or flank movement before committing mobile formations."
            ),
            behavior(
                "\(scenario.id.rawValue)-fallback-reduce-objective",
                "A player objective remains contested after the German attack window.",
                "Prioritize infantry, artillery, or engineer support before the next assault order."
            ),
        ]

        switch scenario.playerPosture {
        case .breakout:
            behaviors.append(behavior("\(scenario.id.rawValue)-fallback-cut-exit", "A breakout or evacuation lane remains open.", "Redirect the nearest mobile order toward the exit lane instead of chasing low-value units."))
        case .counterattack:
            behaviors.append(behavior("\(scenario.id.rawValue)-fallback-cover-columns", "Player armor or cavalry threatens column or support units.", "Hold one mobile reserve back as a security group until the raid is contained."))
        case .evacuationDefense:
            behaviors.append(behavior("\(scenario.id.rawValue)-fallback-capacity-pressure", "Evacuation scoring continues for two consecutive turns.", "Target evacuation capacity or port/beach control before local attrition."))
        case .fortifiedDelay, .urbanDefense:
            behaviors.append(behavior("\(scenario.id.rawValue)-fallback-suppress-strongpoint", "A strongpoint survives an assault.", "Use artillery or engineer support before another direct assault."))
        case .mobileDelay:
            behaviors.append(behavior("\(scenario.id.rawValue)-fallback-road-control", "Player delay units remain mobile on road objectives.", "Prioritize road hubs and exits over low-value combat exchanges."))
        }

        if let lastOrder = plan.orders.last {
            behaviors.append(behavior("\(scenario.id.rawValue)-fallback-final", "Final order \(lastOrder.id) cannot legally score.", "Fall back to the highest remaining target priority: \(plan.targetPriorities.first ?? lastOrder.target)."))
        }

        return behaviors
    }
}

private func behavior(_ id: String, _ trigger: String, _ response: String) -> GermanAIBehavior {
    GermanAIBehavior(id: id, trigger: trigger, response: response)
}
