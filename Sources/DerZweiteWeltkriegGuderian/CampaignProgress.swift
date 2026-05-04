import Foundation

public enum CampaignPlayMode: String, Codable, Hashable, Sendable {
    case chronological = "Chronological"
    case standalone = "Standalone"
}

public struct CampaignCompletionRecord: Codable, Hashable, Sendable {
    public let scenarioID: GuderianBattleID
    public let score: Int
    public let victoryBand: VictoryBand
    public let completedTurn: Int
    public let note: String

    public init(
        scenarioID: GuderianBattleID,
        score: Int,
        victoryBand: VictoryBand,
        completedTurn: Int,
        note: String
    ) {
        self.scenarioID = scenarioID
        self.score = score
        self.victoryBand = victoryBand
        self.completedTurn = completedTurn
        self.note = note
    }
}

public struct CampaignProgressionSnapshot: Codable, Hashable, Sendable {
    public let mode: CampaignPlayMode
    public let completedRecords: [CampaignCompletionRecord]
    public let availableScenarioIDs: [GuderianBattleID]
    public let nextScenarioID: GuderianBattleID?

    public init(
        mode: CampaignPlayMode,
        completedRecords: [CampaignCompletionRecord],
        availableScenarioIDs: [GuderianBattleID],
        nextScenarioID: GuderianBattleID?
    ) {
        self.mode = mode
        self.completedRecords = completedRecords
        self.availableScenarioIDs = availableScenarioIDs
        self.nextScenarioID = nextScenarioID
    }
}

public struct CampaignCompletionSummary: Codable, Hashable, Sendable {
    public let totalScenarios: Int
    public let completedScenarios: Int
    public let remainingScenarioIDs: [GuderianBattleID]
    public let nextScenarioID: GuderianBattleID?
    public let totalScore: Int
    public let victoryBands: [VictoryBand: Int]

    public init(
        totalScenarios: Int,
        completedScenarios: Int,
        remainingScenarioIDs: [GuderianBattleID],
        nextScenarioID: GuderianBattleID?,
        totalScore: Int,
        victoryBands: [VictoryBand: Int]
    ) {
        self.totalScenarios = totalScenarios
        self.completedScenarios = completedScenarios
        self.remainingScenarioIDs = remainingScenarioIDs
        self.nextScenarioID = nextScenarioID
        self.totalScore = totalScore
        self.victoryBands = victoryBands
    }

    public var isComplete: Bool {
        completedScenarios == totalScenarios && totalScenarios > 0
    }

    public var progressLabel: String {
        "\(completedScenarios) of \(totalScenarios) complete"
    }

    public var completionTitle: String {
        isComplete ? "Full Campaign Complete" : "Campaign In Progress"
    }

    public var completionMessage: String {
        if isComplete {
            return "Every command-scope battle in the Guderian campaign has a completion record."
        }
        return "\(remainingScenarioIDs.count) scenarios remain before the full campaign completion screen is unlocked."
    }
}

public struct CampaignProgress: Codable, Hashable, Sendable {
    public private(set) var completedScenarioIDs: Set<GuderianBattleID>
    public private(set) var completionRecords: [GuderianBattleID: CampaignCompletionRecord]

    public init(
        completedScenarioIDs: Set<GuderianBattleID> = [],
        completionRecords: [GuderianBattleID: CampaignCompletionRecord] = [:]
    ) {
        self.completedScenarioIDs = completedScenarioIDs
        self.completionRecords = completionRecords

        for id in completionRecords.keys {
            self.completedScenarioIDs.insert(id)
        }
    }

    public var completedCount: Int {
        completedScenarioIDs.count
    }

    public func isCompleted(_ id: GuderianBattleID) -> Bool {
        completedScenarioIDs.contains(id)
    }

    public func isAvailable(_ scenario: GuderianScenario) -> Bool {
        isAvailable(scenario, in: .chronological)
    }

    public func isAvailable(_ scenario: GuderianScenario, in mode: CampaignPlayMode) -> Bool {
        switch mode {
        case .standalone:
            return true
        case .chronological:
            return scenario.isDemoScenario || scenario.order == nextLockedOrder || completedScenarioIDs.contains(scenario.id)
        }
    }

    public func availableScenarios(
        in mode: CampaignPlayMode,
        catalog: [GuderianScenario] = GuderianCampaignCatalog.all
    ) -> [GuderianScenario] {
        catalog
            .sorted { $0.order < $1.order }
            .filter { isAvailable($0, in: mode) }
    }

    public func nextScenario(
        in catalog: [GuderianScenario] = GuderianCampaignCatalog.all
    ) -> GuderianScenario? {
        catalog
            .sorted { $0.order < $1.order }
            .first { !completedScenarioIDs.contains($0.id) }
    }

    public func completionRecord(for id: GuderianBattleID) -> CampaignCompletionRecord? {
        completionRecords[id]
    }

    public func isComplete(
        in catalog: [GuderianScenario] = GuderianCampaignCatalog.all
    ) -> Bool {
        catalog.allSatisfy { completedScenarioIDs.contains($0.id) }
    }

    public func remainingScenarioIDs(
        in catalog: [GuderianScenario] = GuderianCampaignCatalog.all
    ) -> [GuderianBattleID] {
        catalog
            .sorted { $0.order < $1.order }
            .filter { !completedScenarioIDs.contains($0.id) }
            .map(\.id)
    }

    public mutating func markCompleted(_ id: GuderianBattleID) {
        completedScenarioIDs.insert(id)
    }

    public mutating func recordCompletion(_ record: CampaignCompletionRecord) {
        completedScenarioIDs.insert(record.scenarioID)
        completionRecords[record.scenarioID] = record
    }

    public mutating func reset() {
        completedScenarioIDs.removeAll()
        completionRecords.removeAll()
    }

    public func snapshot(
        mode: CampaignPlayMode,
        catalog: [GuderianScenario] = GuderianCampaignCatalog.all
    ) -> CampaignProgressionSnapshot {
        CampaignProgressionSnapshot(
            mode: mode,
            completedRecords: catalog.compactMap { completionRecords[$0.id] },
            availableScenarioIDs: availableScenarios(in: mode, catalog: catalog).map(\.id),
            nextScenarioID: nextScenario(in: catalog)?.id
        )
    }

    public func completionSummary(
        catalog: [GuderianScenario] = GuderianCampaignCatalog.all
    ) -> CampaignCompletionSummary {
        let ordered = catalog.sorted { $0.order < $1.order }
        let remaining = ordered
            .filter { !completedScenarioIDs.contains($0.id) }
            .map(\.id)
        let records = ordered.compactMap { completionRecords[$0.id] }
        let bands = Dictionary(grouping: records, by: \.victoryBand)
            .mapValues(\.count)

        return CampaignCompletionSummary(
            totalScenarios: ordered.count,
            completedScenarios: ordered.filter { completedScenarioIDs.contains($0.id) }.count,
            remainingScenarioIDs: remaining,
            nextScenarioID: remaining.first,
            totalScore: records.reduce(0) { $0 + $1.score },
            victoryBands: bands
        )
    }

    private var nextLockedOrder: Int {
        let completedOrders = GuderianCampaignCatalog.all
            .filter { completedScenarioIDs.contains($0.id) }
            .map(\.order)

        return (completedOrders.max() ?? 0) + 1
    }
}
