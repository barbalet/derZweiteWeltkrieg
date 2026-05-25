import DerZweiteWeltkriegCore
import Foundation

public protocol HistoricalBattleID: RawRepresentable, Codable, Hashable, Sendable where RawValue == String {}

public enum HistoricalBattleStatus: String, Codable, Hashable, Sendable {
    case planned = "Planned"
    case catalogReady = "Catalog ready"
    case dataLocked = "Data locked"
    case playable = "Playable"
    case demoPlayable = "Demo playable"
}

public enum HistoricalSideRole: String, CaseIterable, Codable, Hashable, Sendable {
    case protagonist
    case opponent
}

public struct HistoricalSourceLink: Codable, Hashable, Sendable {
    public let title: String
    public let url: String

    public init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

public struct HistoricalBattleCoordinate: Codable, Hashable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public enum HistoricalMapElementKind: String, Codable, Hashable, Sendable {
    case road = "Road"
    case river = "River"
    case ridge = "Ridge"
    case town = "Town"
    case forest = "Forest"
    case minefield = "Minefield"
    case bridge = "Bridge"
    case objective = "Objective"
    case phaseLine = "Phase line"
    case deployment = "Deployment"
    case other = "Other"
}

public struct HistoricalMapElement: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: HistoricalMapElementKind
    public let points: [HistoricalBattleCoordinate]
    public let note: String

    public init(
        id: String,
        name: String,
        kind: HistoricalMapElementKind,
        points: [HistoricalBattleCoordinate],
        note: String
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.points = points
        self.note = note
    }
}

public struct HistoricalDeploymentZone: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let sideID: String
    public let name: String
    public let origin: HistoricalBattleCoordinate
    public let width: Double
    public let height: Double
    public let note: String

    public init(
        id: String,
        sideID: String,
        name: String,
        origin: HistoricalBattleCoordinate,
        width: Double,
        height: Double,
        note: String
    ) {
        self.id = id
        self.sideID = sideID
        self.name = name
        self.origin = origin
        self.width = width
        self.height = height
        self.note = note
    }
}

public struct HistoricalBattleMap: Codable, Hashable, Sendable {
    public let title: String
    public let width: Double
    public let height: Double
    public let elements: [HistoricalMapElement]
    public let deploymentZones: [HistoricalDeploymentZone]

    public init(
        title: String,
        width: Double = Double(game_board_width()),
        height: Double = Double(game_board_height()),
        elements: [HistoricalMapElement],
        deploymentZones: [HistoricalDeploymentZone]
    ) {
        self.title = title
        self.width = width
        self.height = height
        self.elements = elements
        self.deploymentZones = deploymentZones
    }
}

public struct HistoricalObjective: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let sideID: String?
    public let victoryPoints: Int
    public let location: HistoricalBattleCoordinate?
    public let radius: Double
    public let description: String

    public init(
        id: String,
        name: String,
        sideID: String? = nil,
        victoryPoints: Int,
        location: HistoricalBattleCoordinate? = nil,
        radius: Double = 0,
        description: String
    ) {
        self.id = id
        self.name = name
        self.sideID = sideID
        self.victoryPoints = victoryPoints
        self.location = location
        self.radius = radius
        self.description = description
    }
}

public struct HistoricalVictoryBand: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let scoreRange: ClosedRange<Int>
    public let summary: String

    public init(id: String, label: String, scoreRange: ClosedRange<Int>, summary: String) {
        self.id = id
        self.label = label
        self.scoreRange = scoreRange
        self.summary = summary
    }
}

public struct HistoricalVictoryProfile: Codable, Hashable, Sendable {
    public let targetScore: Int
    public let targetTurnUpperBound: Int
    public let bands: [HistoricalVictoryBand]

    public init(targetScore: Int, targetTurnUpperBound: Int, bands: [HistoricalVictoryBand]) {
        self.targetScore = targetScore
        self.targetTurnUpperBound = targetTurnUpperBound
        self.bands = bands
    }
}

public struct HistoricalSideOption: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let role: HistoricalSideRole
    public let title: String
    public let historicalForce: String
    public let commander: String?
    public let armyListName: String
    public let playerBriefing: String
    public let aiBriefing: String

    public init(
        id: String,
        role: HistoricalSideRole,
        title: String,
        historicalForce: String,
        commander: String? = nil,
        armyListName: String,
        playerBriefing: String,
        aiBriefing: String
    ) {
        self.id = id
        self.role = role
        self.title = title
        self.historicalForce = historicalForce
        self.commander = commander
        self.armyListName = armyListName
        self.playerBriefing = playerBriefing
        self.aiBriefing = aiBriefing
    }
}

public struct HistoricalBattleScenario<ID: HistoricalBattleID>: Identifiable, Codable, Hashable, Sendable {
    public let id: ID
    public let order: Int
    public let title: String
    public let dateLabel: String
    public let theater: String
    public let status: HistoricalBattleStatus
    public let historicalResult: String
    public let designIntent: String
    public let sourceLinks: [HistoricalSourceLink]
    public let sideOptions: [HistoricalSideOption]
    public let map: HistoricalBattleMap
    public let objectives: [HistoricalObjective]
    public let victory: HistoricalVictoryProfile
    public let tags: [String]

    public init(
        id: ID,
        order: Int,
        title: String,
        dateLabel: String,
        theater: String,
        status: HistoricalBattleStatus,
        historicalResult: String,
        designIntent: String,
        sourceLinks: [HistoricalSourceLink],
        sideOptions: [HistoricalSideOption],
        map: HistoricalBattleMap,
        objectives: [HistoricalObjective],
        victory: HistoricalVictoryProfile,
        tags: [String] = []
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.dateLabel = dateLabel
        self.theater = theater
        self.status = status
        self.historicalResult = historicalResult
        self.designIntent = designIntent
        self.sourceLinks = sourceLinks
        self.sideOptions = sideOptions
        self.map = map
        self.objectives = objectives
        self.victory = victory
        self.tags = tags
    }

    public var hasTwoPlayableSides: Bool {
        Set(sideOptions.map(\.role)) == Set(HistoricalSideRole.allCases) &&
            sideOptions.count == 2
    }
}
