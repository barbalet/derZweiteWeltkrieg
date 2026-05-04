import Foundation

public enum NativeAIEventBindingKind: String, Codable, Hashable, Sendable {
    case germanPriority = "German priority"
    case fallbackBehavior = "Fallback behavior"
    case reinforcementTiming = "Reinforcement timing"
    case scriptedTrigger = "Scripted trigger"
    case scenarioRule = "Scenario rule"
    case pacingRule = "Pacing rule"
    case tutorialCue = "Tutorial cue"
    case victoryGate = "Victory gate"
}

public struct NativeAIEventBinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: NativeAIEventBindingKind
    public let sourceID: String
    public let title: String
    public let timing: String
    public let target: String
    public let effect: String

    public init(
        id: String,
        kind: NativeAIEventBindingKind,
        sourceID: String,
        title: String,
        timing: String,
        target: String,
        effect: String
    ) {
        self.id = id
        self.kind = kind
        self.sourceID = sourceID
        self.title = title
        self.timing = timing
        self.target = target
        self.effect = effect
    }
}

public struct NativeAIEventPassReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let aiOrderCount: Int
    public let targetPriorityCount: Int
    public let fallbackBehaviorCount: Int
    public let eventTriggerCount: Int
    public let reinforcementEventCount: Int
    public let scenarioRuleEventCount: Int
    public let deterministicSeedHint: UInt32
    public let bindings: [NativeAIEventBinding]

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        aiOrderCount: Int,
        targetPriorityCount: Int,
        fallbackBehaviorCount: Int,
        eventTriggerCount: Int,
        reinforcementEventCount: Int,
        scenarioRuleEventCount: Int,
        deterministicSeedHint: UInt32,
        bindings: [NativeAIEventBinding]
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.aiOrderCount = aiOrderCount
        self.targetPriorityCount = targetPriorityCount
        self.fallbackBehaviorCount = fallbackBehaviorCount
        self.eventTriggerCount = eventTriggerCount
        self.reinforcementEventCount = reinforcementEventCount
        self.scenarioRuleEventCount = scenarioRuleEventCount
        self.deterministicSeedHint = deterministicSeedHint
        self.bindings = bindings
    }

    public var isNativeAIEventPassReady: Bool {
        aiOrderCount > 0 &&
            targetPriorityCount > 0 &&
            fallbackBehaviorCount > 0 &&
            eventTriggerCount > 0 &&
            deterministicSeedHint > 0 &&
            bindings.contains { $0.kind == .germanPriority } &&
            bindings.contains { $0.kind == .fallbackBehavior } &&
            bindings.contains { $0.kind == .victoryGate } &&
            bindings.allSatisfy { !$0.sourceID.isEmpty && !$0.title.isEmpty && !$0.effect.isEmpty }
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) AI/event pass: \(aiOrderCount) AI orders, \(fallbackBehaviorCount) fallbacks, \(eventTriggerCount) native events, \(bindings.count) bindings."
    }

    public func hasBinding(_ kind: NativeAIEventBindingKind) -> Bool {
        bindings.contains { $0.kind == kind }
    }
}

public enum NativeAIEventPassCatalog {
    public static let cycleRange = 371...375

    public static func report(for id: GuderianBattleID) -> NativeAIEventPassReport? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return report(for: scenario)
    }

    public static func report(for scenario: GuderianScenario) -> NativeAIEventPassReport {
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        let aiSnapshot = GermanAIRefinementCatalog.snapshot(for: scenario)
        let bindings = bindings(for: scenario, instance: instance, aiSnapshot: aiSnapshot)
        return NativeAIEventPassReport(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            aiOrderCount: instance.aiProfile.orders.count,
            targetPriorityCount: instance.aiProfile.targetPriorities.count,
            fallbackBehaviorCount: aiSnapshot.fallbackBehaviors.count,
            eventTriggerCount: instance.events.count,
            reinforcementEventCount: instance.events.filter { $0.kind == .reinforcement }.count,
            scenarioRuleEventCount: instance.events.filter { eventKind(for: $0) == .scenarioRule }.count,
            deterministicSeedHint: aiSnapshot.deterministicSeedHint,
            bindings: bindings
        )
    }

    public static var allReports: [NativeAIEventPassReport] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map { report(for: $0) }
    }

    public static func isPassReady(_ scenario: GuderianScenario) -> Bool {
        report(for: scenario).isNativeAIEventPassReady
    }

    private static func bindings(
        for scenario: GuderianScenario,
        instance: NativeBattleInstance,
        aiSnapshot: GermanAISnapshot
    ) -> [NativeAIEventBinding] {
        let priorityBindings = instance.aiProfile.orders.map { order in
            NativeAIEventBinding(
                id: "\(scenario.id.rawValue)-ai-order-\(order.id)",
                kind: .germanPriority,
                sourceID: order.id,
                title: order.kind.rawValue,
                timing: order.turnWindow,
                target: order.target,
                effect: order.instruction
            )
        }
        let fallbackBindings = aiSnapshot.fallbackBehaviors.map { behavior in
            NativeAIEventBinding(
                id: "\(scenario.id.rawValue)-ai-fallback-\(behavior.id)",
                kind: .fallbackBehavior,
                sourceID: behavior.id,
                title: behavior.trigger,
                timing: "Deterministic fallback",
                target: instance.aiProfile.targetPriorities.first ?? scenario.title,
                effect: behavior.response
            )
        }
        let eventBindings = instance.events.map { event in
            NativeAIEventBinding(
                id: "\(scenario.id.rawValue)-event-binding-\(event.id)",
                kind: eventKind(for: event),
                sourceID: event.sourceID,
                title: event.title,
                timing: event.timing,
                target: event.condition,
                effect: event.effect
            )
        }
        let victoryBindings = instance.victory.scoreRules.map { scoreRule in
            NativeAIEventBinding(
                id: "\(scenario.id.rawValue)-victory-gate-\(scoreRule.id)",
                kind: .victoryGate,
                sourceID: scoreRule.id,
                title: scoreRule.name,
                timing: scoreRule.timing,
                target: scoreRule.side.rawValue,
                effect: scoreRule.description
            )
        }
        return priorityBindings + fallbackBindings + eventBindings + victoryBindings
    }

    private static func eventKind(for event: NativeBattleEventTrigger) -> NativeAIEventBindingKind {
        switch event.kind {
        case .reinforcement:
            return .reinforcementTiming
        case .pacing:
            return .pacingRule
        case .tutorial:
            return .tutorialCue
        case .trigger:
            return event.timing.hasPrefix("Native ") ? .scenarioRule : .scriptedTrigger
        }
    }
}
