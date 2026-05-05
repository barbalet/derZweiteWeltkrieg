import Foundation

public enum ScenarioMapReferenceKind: String, CaseIterable, Codable, Hashable, Sendable {
    case modernMapVisualGuide = "Modern map visual guide"
    case scenarioSource = "Scenario source"
    case featureVisualGuide = "Feature visual guide"
}

public struct ScenarioMapReference: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let kind: ScenarioMapReferenceKind
    public let url: URL
    public let note: String

    public init(
        id: String,
        title: String,
        kind: ScenarioMapReferenceKind,
        url: URL,
        note: String
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.url = url
        self.note = note
    }

    public var sourceNote: ScenarioMapSourceNote {
        ScenarioMapSourceNote(title: title, url: url, note: note)
    }
}

public enum ScenarioMapGeographyCrossCheckStep: String, CaseIterable, Codable, Hashable, Sendable {
    case collectScenarioSources = "Collect scenario sources"
    case openModernMapVisualGuide = "Open modern map visual guide"
    case traceWaterAndTerrain = "Trace water and terrain"
    case traceTransportAndCrossings = "Trace transport and crossings"
    case placeSettlementsAndDistricts = "Place settlements and districts"
    case handAuthorAbstractCoordinates = "Hand-author abstract coordinates"
    case attachSourceNotes = "Attach source notes"
    case rerunMapDetailAudit = "Rerun map-detail audit"

    public var instruction: String {
        switch self {
        case .collectScenarioSources:
            return "Review the existing scenario sources before adding or moving map features."
        case .openModernMapVisualGuide:
            return "Use a modern map only as a visual geography guide, not as sole historical proof."
        case .traceWaterAndTerrain:
            return "Mark rivers, canals, lakes, marshes, ridges, forests, and other maneuver-shaping ground."
        case .traceTransportAndCrossings:
            return "Cross-check roads, railways, bridges, fords, ferries, causeways, and retreat lanes."
        case .placeSettlementsAndDistricts:
            return "Add named towns, villages, ports, suburbs, fortress districts, and urban sectors that affect play."
        case .handAuthorAbstractCoordinates:
            return "Translate the checked geography into hand-authored abstract ScenarioMapPoint coordinates."
        case .attachSourceNotes:
            return "Attach source notes to layouts or features so each detail has a review trail."
        case .rerunMapDetailAudit:
            return "Run the map-detail audit to confirm category coverage and the 400% target gap."
        }
    }
}

public struct ScenarioMapGeographyAnchor: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let expectedKind: ScenarioMapElementKind
    public let targetCategories: [ScenarioMapDetailCategory]
    public let searchQuery: String
    public let role: String
    public let sourceNotes: [ScenarioMapSourceNote]

    public init(
        id: String,
        name: String,
        expectedKind: ScenarioMapElementKind,
        targetCategories: [ScenarioMapDetailCategory],
        searchQuery: String,
        role: String,
        sourceNotes: [ScenarioMapSourceNote]
    ) {
        self.id = id
        self.name = name
        self.expectedKind = expectedKind
        self.targetCategories = targetCategories
        self.searchQuery = searchQuery
        self.role = role
        self.sourceNotes = sourceNotes
    }
}

public struct ScenarioMapGeographyCrossCheck: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let theater: CampaignTheater
    public let references: [ScenarioMapReference]
    public let anchors: [ScenarioMapGeographyAnchor]
    public let requiredDetailCategories: [ScenarioMapDetailCategory]
    public let workflowSteps: [ScenarioMapGeographyCrossCheckStep]
    public let coordinatePolicy: String

    public init(
        id: GuderianBattleID,
        title: String,
        theater: CampaignTheater,
        references: [ScenarioMapReference],
        anchors: [ScenarioMapGeographyAnchor],
        requiredDetailCategories: [ScenarioMapDetailCategory],
        workflowSteps: [ScenarioMapGeographyCrossCheckStep],
        coordinatePolicy: String
    ) {
        self.id = id
        self.title = title
        self.theater = theater
        self.references = references
        self.anchors = anchors
        self.requiredDetailCategories = requiredDetailCategories
        self.workflowSteps = workflowSteps
        self.coordinatePolicy = coordinatePolicy
    }

    public var visualGuideReferences: [ScenarioMapReference] {
        references.filter { $0.kind == .modernMapVisualGuide || $0.kind == .featureVisualGuide }
    }

    public var historicalReferences: [ScenarioMapReference] {
        references.filter { $0.kind == .scenarioSource }
    }

    public var sourceNotes: [ScenarioMapSourceNote] {
        references.map(\.sourceNote)
    }

    public var isReadyForHandAuthoredEnrichment: Bool {
        !visualGuideReferences.isEmpty &&
            !historicalReferences.isEmpty &&
            !anchors.isEmpty &&
            workflowSteps.contains(.handAuthorAbstractCoordinates) &&
            workflowSteps.contains(.attachSourceNotes) &&
            workflowSteps.contains(.rerunMapDetailAudit)
    }
}

public struct ScenarioMapGeographyPipelineReport: Codable, Hashable, Sendable {
    public let records: [ScenarioMapGeographyCrossCheck]

    public init(records: [ScenarioMapGeographyCrossCheck]) {
        self.records = records
    }

    public var scenarioCount: Int {
        records.count
    }

    public var readyScenarioIDs: [GuderianBattleID] {
        records.filter(\.isReadyForHandAuthoredEnrichment).map(\.id)
    }

    public var totalAnchorCount: Int {
        records.reduce(0) { $0 + $1.anchors.count }
    }

    public var modernVisualReferenceCount: Int {
        records.reduce(0) { total, record in
            total + record.references.filter { $0.kind == .modernMapVisualGuide }.count
        }
    }

    public var featureVisualReferenceCount: Int {
        records.reduce(0) { total, record in
            total + record.references.filter { $0.kind == .featureVisualGuide }.count
        }
    }

    public var historicalReferenceCount: Int {
        records.reduce(0) { total, record in
            total + record.historicalReferences.count
        }
    }
}

public enum ScenarioMapGeographyPipelineCatalog {
    public static func record(for scenario: GuderianScenario) -> ScenarioMapGeographyCrossCheck {
        let anchors = scenario.mapFeatures.enumerated().map { index, feature in
            anchor(for: feature, index: index, scenario: scenario)
        }
        let audit = ScenarioMapDetailAuditCatalog.audit(for: scenario)

        return ScenarioMapGeographyCrossCheck(
            id: scenario.id,
            title: scenario.title,
            theater: scenario.theater,
            references: references(for: scenario, anchors: anchors),
            anchors: anchors,
            requiredDetailCategories: detailCategories(from: audit),
            workflowSteps: ScenarioMapGeographyCrossCheckStep.allCases,
            coordinatePolicy: "Modern maps are visual guides; scenario maps store hand-authored abstract coordinates in the 0-100 layout space."
        )
    }

    public static func record(for id: GuderianBattleID) -> ScenarioMapGeographyCrossCheck? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }

        return record(for: scenario)
    }

    public static var allRecords: [ScenarioMapGeographyCrossCheck] {
        GuderianCampaignCatalog.all.map(record)
    }

    public static func report() -> ScenarioMapGeographyPipelineReport {
        ScenarioMapGeographyPipelineReport(records: allRecords)
    }

    public static func sourceNotes(for scenario: GuderianScenario) -> [ScenarioMapSourceNote] {
        sourceReferences(for: scenario).map(\.sourceNote)
    }

    private static func references(
        for scenario: GuderianScenario,
        anchors: [ScenarioMapGeographyAnchor]
    ) -> [ScenarioMapReference] {
        sourceReferences(for: scenario) + anchors.flatMap { anchor in
            anchor.sourceNotes.enumerated().map { index, sourceNote in
                ScenarioMapReference(
                    id: "\(anchor.id)-visual-\(index)",
                    title: sourceNote.title,
                    kind: .featureVisualGuide,
                    url: sourceNote.url ?? modernMapURL(query: anchor.searchQuery),
                    note: sourceNote.note
                )
            }
        }
    }

    private static func sourceReferences(for scenario: GuderianScenario) -> [ScenarioMapReference] {
        let modernReference = ScenarioMapReference(
            id: "\(scenario.id.rawValue)-modern-map",
            title: "\(scenario.title) modern map visual guide",
            kind: .modernMapVisualGuide,
            url: modernMapURL(query: "\(scenario.title) battlefield geography"),
            note: "Visual geography guide only; keep historical interpretation tied to scenario sources and hand-authored abstract coordinates."
        )

        return [modernReference] + scenario.sourceLinks.enumerated().map { index, source in
            ScenarioMapReference(
                id: "\(scenario.id.rawValue)-source-\(index)",
                title: source.title,
                kind: .scenarioSource,
                url: source.url,
                note: "Scenario source used to cross-check whether modern geography belongs on the historical battlefield map."
            )
        }
    }

    private static func anchor(
        for feature: ScenarioMapFeature,
        index: Int,
        scenario: GuderianScenario
    ) -> ScenarioMapGeographyAnchor {
        let query = "\(feature.name) \(scenario.title)"
        let kind = inferredKind(for: feature)

        return ScenarioMapGeographyAnchor(
            id: "\(scenario.id.rawValue)-anchor-\(index)",
            name: feature.name,
            expectedKind: kind,
            targetCategories: inferredCategories(for: feature, expectedKind: kind),
            searchQuery: query,
            role: feature.role,
            sourceNotes: [
                ScenarioMapSourceNote(
                    title: "\(feature.name) visual guide",
                    url: modernMapURL(query: query),
                    note: "Use as a visual cross-check before placing this feature in abstract scenario coordinates."
                ),
            ]
        )
    }

    private static func detailCategories(from audit: ScenarioMapDetailAudit) -> [ScenarioMapDetailCategory] {
        let excluded: Set<ScenarioMapDetailCategory> = [
            .totalMapFeatures,
            .annotatedFeatures,
            .sourceNotes,
            .deploymentZones,
        ]

        return audit.gaps.map(\.category).filter { !excluded.contains($0) }
    }

    private static func inferredKind(for feature: ScenarioMapFeature) -> ScenarioMapElementKind {
        let text = "\(feature.name) \(feature.role)".lowercased()

        if contains(text, ["rail", "train", "station"]) {
            return .railway
        }
        if contains(text, ["bridge", "crossing", "ford", "ferry", "causeway"]) {
            return .bridge
        }
        if contains(text, ["river", "canal", "lake", "lagoon", "coast", "beach", "harbor", "port"]) {
            return .river
        }
        if contains(text, ["road", "route", "lane", "corridor", "axis", "junction", "hub"]) {
            return .road
        }
        if contains(text, ["forest", "woods", "wooded"]) {
            return .forest
        }
        if contains(text, ["ridge", "heights", "hill", "ravine"]) {
            return .ridge
        }
        if contains(text, ["bunker", "fortress", "citadel", "perimeter", "defense", "defensive"]) {
            return .fortifiedLine
        }
        if contains(text, ["town", "city", "village", "suburb", "docks"]) {
            return .town
        }
        if contains(text, ["marsh", "swamp", "wetland"]) {
            return .marsh
        }

        return .objective
    }

    private static func inferredCategories(
        for feature: ScenarioMapFeature,
        expectedKind: ScenarioMapElementKind
    ) -> [ScenarioMapDetailCategory] {
        var categories: [ScenarioMapDetailCategory] = [.totalMapFeatures, .annotatedFeatures, .sourceNotes]
        let text = "\(feature.name) \(feature.role)".lowercased()

        appendCategory(for: expectedKind, to: &categories)

        if contains(text, ["river", "canal", "lake", "lagoon", "coast", "beach", "harbor", "port", "marsh", "wetland"]) {
            appendUnique(.water, to: &categories)
        }
        if contains(text, ["road", "route", "lane", "corridor", "axis", "junction", "hub"]) {
            appendUnique(.roads, to: &categories)
        }
        if contains(text, ["rail", "train", "station"]) {
            appendUnique(.railways, to: &categories)
        }
        if contains(text, ["bridge", "crossing", "ford", "ferry", "causeway"]) {
            appendUnique(.crossings, to: &categories)
        }
        if contains(text, ["town", "city", "village", "suburb", "harbor", "port", "docks", "citadel"]) {
            appendUnique(.settlements, to: &categories)
        }
        if contains(text, ["forest", "woods", "ridge", "heights", "hill", "ravine", "marsh", "swamp", "wetland"]) {
            appendUnique(.groundTerrain, to: &categories)
        }
        if contains(text, ["bunker", "fortress", "citadel", "perimeter", "defense", "defensive"]) {
            appendUnique(.fortifications, to: &categories)
        }

        return categories
    }

    private static func appendCategory(
        for kind: ScenarioMapElementKind,
        to categories: inout [ScenarioMapDetailCategory]
    ) {
        if kind.isWaterFeature {
            appendUnique(.water, to: &categories)
        }
        if kind.isRoadFeature {
            appendUnique(.roads, to: &categories)
        }
        if kind.isRailwayFeature {
            appendUnique(.railways, to: &categories)
        }
        if kind.isCrossingFeature {
            appendUnique(.crossings, to: &categories)
        }
        if kind.isSettlementFeature {
            appendUnique(.settlements, to: &categories)
        }
        if kind.isGroundTerrainFeature {
            appendUnique(.groundTerrain, to: &categories)
        }
        if kind.isFortificationFeature {
            appendUnique(.fortifications, to: &categories)
        }
    }

    private static func appendUnique(
        _ category: ScenarioMapDetailCategory,
        to categories: inout [ScenarioMapDetailCategory]
    ) {
        if !categories.contains(category) {
            categories.append(category)
        }
    }

    private static func contains(_ text: String, _ tokens: [String]) -> Bool {
        tokens.contains { text.contains($0) }
    }

    private static func modernMapURL(query: String) -> URL {
        guard var components = URLComponents(string: "https://www.google.com/maps/search/") else {
            preconditionFailure("Invalid Google Maps base URL")
        }

        components.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: query),
        ]

        guard let url = components.url else {
            preconditionFailure("Invalid Google Maps query: \(query)")
        }

        return url
    }
}
