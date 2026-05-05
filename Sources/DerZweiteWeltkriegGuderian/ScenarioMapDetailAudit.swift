import Foundation

public enum ScenarioMapDetailCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case totalMapFeatures = "Total map features"
    case water = "Water geography"
    case roads = "Roads"
    case railways = "Railways"
    case crossings = "Crossings"
    case settlements = "Settlements"
    case groundTerrain = "Ground terrain"
    case fortifications = "Fortifications"
    case objectives = "Objectives"
    case deploymentZones = "Deployment zones"
    case pressureMarkers = "Pressure markers"
    case annotatedFeatures = "Annotated features"
    case sourceNotes = "Source notes"
}

public struct ScenarioMapDetailMetrics: Codable, Hashable, Sendable {
    public let elementCount: Int
    public let deploymentZoneCount: Int
    public let lineElementCount: Int
    public let markerElementCount: Int
    public let coordinatePointCount: Int
    public let categoryCounts: [ScenarioMapDetailCategory: Int]

    public init(layout: ScenarioMapLayout) {
        elementCount = layout.elements.count
        deploymentZoneCount = layout.deploymentZones.count
        lineElementCount = layout.elements.filter { $0.points.count > 1 }.count
        markerElementCount = layout.elements.filter { $0.points.count <= 1 }.count
        coordinatePointCount = layout.elements.reduce(0) { $0 + $1.points.count } + layout.deploymentZones.count * 4

        let annotatedElementCount = layout.elements.filter { !$0.note.isEmpty }.count
        let annotatedZoneCount = layout.deploymentZones.filter { !$0.note.isEmpty }.count
        let sourceNoteCount = layout.sourceNotes.count +
            layout.elements.reduce(0) { $0 + $1.sourceNotes.count } +
            layout.deploymentZones.reduce(0) { $0 + $1.sourceNotes.count }

        categoryCounts = [
            .totalMapFeatures: layout.elements.count + layout.deploymentZones.count,
            .water: layout.elements.filter(Self.isWater).count,
            .roads: layout.elements.filter(Self.isRoad).count,
            .railways: layout.elements.filter(Self.isRailway).count,
            .crossings: layout.elements.filter(Self.isCrossing).count,
            .settlements: layout.elements.filter(Self.isSettlement).count,
            .groundTerrain: layout.elements.filter(Self.isGroundTerrain).count,
            .fortifications: layout.elements.filter(Self.isFortification).count,
            .objectives: layout.elements.filter { $0.kind == .objective }.count,
            .deploymentZones: layout.deploymentZones.count,
            .pressureMarkers: layout.elements.filter(Self.isPressureMarker).count,
            .annotatedFeatures: annotatedElementCount + annotatedZoneCount,
            .sourceNotes: sourceNoteCount,
        ]
    }

    public func count(for category: ScenarioMapDetailCategory) -> Int {
        categoryCounts[category, default: 0]
    }

    public var mapFeatureCount: Int {
        count(for: .totalMapFeatures)
    }

    private static func isWater(_ element: ScenarioMapElement) -> Bool {
        element.kind.isWaterFeature || matches(element, tokens: ["river", "canal", "lake", "marsh", "lagoon"])
    }

    private static func isRoad(_ element: ScenarioMapElement) -> Bool {
        element.kind.isRoadFeature && !isRailway(element)
    }

    private static func isRailway(_ element: ScenarioMapElement) -> Bool {
        element.kind.isRailwayFeature || (element.kind == .road && matches(element, tokens: ["rail", "train"]))
    }

    private static func isCrossing(_ element: ScenarioMapElement) -> Bool {
        element.kind.isCrossingFeature || matches(element, tokens: ["bridge", "crossing", "ford", "ferry"])
    }

    private static func isSettlement(_ element: ScenarioMapElement) -> Bool {
        element.kind.isSettlementFeature || matches(element, tokens: ["town", "city", "village", "harbor", "port", "docks", "citadel"])
    }

    private static func isGroundTerrain(_ element: ScenarioMapElement) -> Bool {
        element.kind.isGroundTerrainFeature || matches(element, tokens: ["forest", "woods", "ridge", "heights", "belt", "ravine", "marsh"])
    }

    private static func isFortification(_ element: ScenarioMapElement) -> Bool {
        element.kind.isFortificationFeature || matches(element, tokens: ["bunker", "fortress", "citadel", "perimeter", "defensive line"])
    }

    private static func isPressureMarker(_ element: ScenarioMapElement) -> Bool {
        element.kind.isPressureMarker
    }

    private static func matches(_ element: ScenarioMapElement, tokens: [String]) -> Bool {
        let text = "\(element.name) \(element.note)".lowercased()
        return tokens.contains { text.contains($0) }
    }
}

public struct ScenarioMapDetailTarget: Codable, Hashable, Sendable {
    public let minimumFeatureCount: Int
    public let requiredAdditionalFeatureCount: Int
    public let minimumCategoryCounts: [ScenarioMapDetailCategory: Int]

    public init(metrics: ScenarioMapDetailMetrics) {
        minimumFeatureCount = metrics.mapFeatureCount * 4
        requiredAdditionalFeatureCount = max(0, minimumFeatureCount - metrics.mapFeatureCount)

        minimumCategoryCounts = [
            .totalMapFeatures: minimumFeatureCount,
            .water: max(2, metrics.count(for: .water) * 2),
            .roads: max(3, metrics.count(for: .roads) * 2),
            .railways: max(1, metrics.count(for: .railways) * 2),
            .crossings: max(2, metrics.count(for: .crossings) * 2),
            .settlements: max(4, metrics.count(for: .settlements) * 2),
            .groundTerrain: max(3, metrics.count(for: .groundTerrain) * 2),
            .fortifications: max(1, metrics.count(for: .fortifications)),
            .objectives: max(6, metrics.count(for: .objectives)),
            .deploymentZones: max(2, metrics.count(for: .deploymentZones)),
            .pressureMarkers: max(1, metrics.count(for: .pressureMarkers)),
            .annotatedFeatures: minimumFeatureCount,
            .sourceNotes: max(1, metrics.count(for: .sourceNotes) * 2),
        ]
    }
}

public struct ScenarioMapDetailGap: Identifiable, Codable, Hashable, Sendable {
    public let category: ScenarioMapDetailCategory
    public let currentCount: Int
    public let targetCount: Int
    public let note: String

    public init(
        category: ScenarioMapDetailCategory,
        currentCount: Int,
        targetCount: Int,
        note: String
    ) {
        self.category = category
        self.currentCount = currentCount
        self.targetCount = targetCount
        self.note = note
    }

    public var id: String {
        category.rawValue
    }

    public var missingCount: Int {
        max(0, targetCount - currentCount)
    }
}

public struct ScenarioMapDetailAudit: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let theater: CampaignTheater
    public let mapTitle: String
    public let metrics: ScenarioMapDetailMetrics
    public let target: ScenarioMapDetailTarget
    public let gaps: [ScenarioMapDetailGap]

    public init(scenario: GuderianScenario, layout: ScenarioMapLayout) {
        let computedMetrics = ScenarioMapDetailMetrics(layout: layout)
        let computedTarget = ScenarioMapDetailTarget(metrics: computedMetrics)
        let computedGaps: [ScenarioMapDetailGap] = ScenarioMapDetailCategory.allCases.compactMap { category in
            guard let targetCount = computedTarget.minimumCategoryCounts[category] else {
                return nil
            }

            let currentCount = computedMetrics.count(for: category)
            guard currentCount < targetCount else {
                return nil
            }

            return ScenarioMapDetailGap(
                category: category,
                currentCount: currentCount,
                targetCount: targetCount,
                note: Self.gapNote(for: category, current: currentCount, target: targetCount)
            )
        }

        id = scenario.id
        title = scenario.title
        theater = scenario.theater
        mapTitle = layout.title
        metrics = computedMetrics
        target = computedTarget
        gaps = computedGaps
    }

    public var needsFourXEnrichment: Bool {
        metrics.mapFeatureCount < target.minimumFeatureCount
    }

    private static func gapNote(
        for category: ScenarioMapDetailCategory,
        current: Int,
        target: Int
    ) -> String {
        switch category {
        case .totalMapFeatures:
            return "Add at least \(target - current) sourceable map features to reach the 400% detail target."
        case .annotatedFeatures:
            return "Every new geography feature needs a playable note or source-facing rationale."
        case .sourceNotes:
            return "Attach source notes to maps or features before detailed geography is treated as sourceable."
        case .water:
            return "Add named rivers, canals, lakes, marshes, beaches, lagoons, or wet obstacles where historically relevant."
        case .roads:
            return "Add secondary roads, tracks, road junctions, causeways, and retreat or pursuit lanes."
        case .railways:
            return "Add rail lines, stations, armored-train corridors, or rail junctions where the battle geography supports them."
        case .crossings:
            return "Add bridges, ferries, fords, bridgeheads, crossing sites, and demolition points."
        case .settlements:
            return "Add named towns, villages, urban districts, docks, ports, fortress districts, or suburbs."
        case .groundTerrain:
            return "Add forests, ridges, ravines, marsh belts, hills, chokepoints, and other maneuver-shaping terrain."
        case .fortifications:
            return "Add bunkers, strongpoints, city perimeters, prepared lines, or fortress sectors when applicable."
        case .objectives:
            return "Add enough player-readable objectives to make the larger battlefield tactically legible."
        case .deploymentZones:
            return "Keep both sides' deployment spaces explicit as the map grows."
        case .pressureMarkers:
            return "Add artillery, air, supply, pincer, evacuation, or command-pressure markers where they affect play."
        }
    }
}

public struct ScenarioMapDetailAuditReport: Codable, Hashable, Sendable {
    public let audits: [ScenarioMapDetailAudit]

    public init(audits: [ScenarioMapDetailAudit]) {
        self.audits = audits
    }

    public var scenarioCount: Int {
        audits.count
    }

    public var currentFeatureCount: Int {
        audits.reduce(0) { $0 + $1.metrics.mapFeatureCount }
    }

    public var minimumFeatureCount: Int {
        audits.reduce(0) { $0 + $1.target.minimumFeatureCount }
    }

    public var requiredAdditionalFeatureCount: Int {
        audits.reduce(0) { $0 + $1.target.requiredAdditionalFeatureCount }
    }

    public var battleIDsNeedingEnrichment: [GuderianBattleID] {
        audits.filter(\.needsFourXEnrichment).map(\.id)
    }

    public var categoryGaps: [ScenarioMapDetailCategory] {
        ScenarioMapDetailCategory.allCases.filter { category in
            audits.contains { audit in
                audit.gaps.contains { $0.category == category }
            }
        }
    }
}

public enum ScenarioMapDetailAuditCatalog {
    public static func audit(for scenario: GuderianScenario) -> ScenarioMapDetailAudit {
        ScenarioMapDetailAudit(
            scenario: scenario,
            layout: ScenarioMapCatalog.layout(for: scenario)
        )
    }

    public static func audit(for id: GuderianBattleID) -> ScenarioMapDetailAudit? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }

        return audit(for: scenario)
    }

    public static var allAudits: [ScenarioMapDetailAudit] {
        GuderianCampaignCatalog.all.map(audit)
    }

    public static func report() -> ScenarioMapDetailAuditReport {
        ScenarioMapDetailAuditReport(audits: allAudits)
    }
}
