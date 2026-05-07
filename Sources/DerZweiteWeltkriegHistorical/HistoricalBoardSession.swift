import Foundation

public enum HistoricalBoardPhase: String, Codable, Hashable, Sendable {
    case movement = "Movement"
    case shooting = "Shooting"
    case assault = "Assault"
}

public enum HistoricalBoardActionStatus: String, Codable, Hashable, Sendable {
    case idle = "Idle"
    case succeeded = "Succeeded"
    case blocked = "Blocked"
}

public struct HistoricalBoardActionMessage: Codable, Hashable, Sendable {
    public let status: HistoricalBoardActionStatus
    public let title: String
    public let detail: String

    public init(status: HistoricalBoardActionStatus, title: String, detail: String) {
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct HistoricalBoardMissionSnapshot: Codable, Hashable, Sendable {
    public let name: String
    public let targetScore: Int
    public let humanScore: Int
    public let aiScore: Int
    public let winningSideID: String?

    public init(
        name: String,
        targetScore: Int,
        humanScore: Int,
        aiScore: Int,
        winningSideID: String? = nil
    ) {
        self.name = name
        self.targetScore = targetScore
        self.humanScore = humanScore
        self.aiScore = aiScore
        self.winningSideID = winningSideID
    }
}

public struct HistoricalBoardUnitSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let sideID: String
    public let name: String
    public let kind: String
    public let role: String
    public let position: HistoricalBattleCoordinate
    public let facingDegrees: Double
    public let destroyed: Bool
    public let canMoveNow: Bool
    public let canShootNow: Bool
    public let canAssaultNow: Bool
    public let selected: Bool
    public let targeted: Bool

    public init(
        id: Int,
        sideID: String,
        name: String,
        kind: String,
        role: String,
        position: HistoricalBattleCoordinate,
        facingDegrees: Double,
        destroyed: Bool = false,
        canMoveNow: Bool = false,
        canShootNow: Bool = false,
        canAssaultNow: Bool = false,
        selected: Bool = false,
        targeted: Bool = false
    ) {
        self.id = id
        self.sideID = sideID
        self.name = name
        self.kind = kind
        self.role = role
        self.position = position
        self.facingDegrees = facingDegrees
        self.destroyed = destroyed
        self.canMoveNow = canMoveNow
        self.canShootNow = canShootNow
        self.canAssaultNow = canAssaultNow
        self.selected = selected
        self.targeted = targeted
    }
}

public struct HistoricalBoardZoneSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let kind: HistoricalMapElementKind
    public let origin: HistoricalBattleCoordinate
    public let width: Double
    public let height: Double
    public let blocksLineOfSight: Bool

    public init(
        id: Int,
        name: String,
        kind: HistoricalMapElementKind,
        origin: HistoricalBattleCoordinate,
        width: Double,
        height: Double,
        blocksLineOfSight: Bool
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.origin = origin
        self.width = width
        self.height = height
        self.blocksLineOfSight = blocksLineOfSight
    }
}

public struct HistoricalBoardObjectiveSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let location: HistoricalBattleCoordinate
    public let radius: Double
    public let controllingSideID: String?

    public init(
        id: Int,
        name: String,
        location: HistoricalBattleCoordinate,
        radius: Double,
        controllingSideID: String?
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.radius = radius
        self.controllingSideID = controllingSideID
    }
}

public struct HistoricalBoardSnapshot<ID: HistoricalBattleID>: Codable, Hashable, Sendable {
    public let battleID: ID
    public let turnNumber: Int
    public let activeSideID: String
    public let phase: HistoricalBoardPhase
    public let mission: HistoricalBoardMissionSnapshot
    public let units: [HistoricalBoardUnitSnapshot]
    public let zones: [HistoricalBoardZoneSnapshot]
    public let objectives: [HistoricalBoardObjectiveSnapshot]
    public let lastAction: HistoricalBoardActionMessage
    public let log: [String]

    public init(
        battleID: ID,
        turnNumber: Int,
        activeSideID: String,
        phase: HistoricalBoardPhase,
        mission: HistoricalBoardMissionSnapshot,
        units: [HistoricalBoardUnitSnapshot],
        zones: [HistoricalBoardZoneSnapshot],
        objectives: [HistoricalBoardObjectiveSnapshot],
        lastAction: HistoricalBoardActionMessage = .init(status: .idle, title: "Ready", detail: "Battle session is ready."),
        log: [String] = []
    ) {
        self.battleID = battleID
        self.turnNumber = turnNumber
        self.activeSideID = activeSideID
        self.phase = phase
        self.mission = mission
        self.units = units
        self.zones = zones
        self.objectives = objectives
        self.lastAction = lastAction
        self.log = log
    }
}

public protocol HistoricalBoardSession: AnyObject {
    associatedtype BattleID: HistoricalBattleID

    var battleID: BattleID { get }
    var launch: HistoricalBattleLaunch<BattleID> { get }

    func snapshot() -> HistoricalBoardSnapshot<BattleID>
    func selectUnit(_ id: Int)
    func selectTarget(_ id: Int)
    func selectFirstActiveUnit()
    func selectNearestEnemyToSelectedUnit()
    func moveSelectedUnitTowardNearestObjective(maxDistance: Double) -> Bool
    func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double) -> Bool
    func moveUnit(_ id: Int, to point: HistoricalBattleCoordinate) -> Bool
    func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool
    func toggleCover(for id: Int, enabled: Bool) -> Bool
    func toggleHullDown(for id: Int, enabled: Bool) -> Bool
    func shootUnit(_ attackerID: Int, targetID: Int) -> Bool
    func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool) -> Bool
    func shootSelectedTarget() -> Bool
    func resolveFirstPendingChoice() -> Bool
    func advancePhase()
}
