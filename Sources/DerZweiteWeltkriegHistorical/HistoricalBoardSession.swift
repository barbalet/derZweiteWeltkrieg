import Foundation

public enum HistoricalBoardPhase: String, Codable, Hashable, Sendable {
    case movement = "Movement"
    case shooting = "Shooting"
    case assault = "Assault"
}

public enum HistoricalBoardOrder: String, CaseIterable, Codable, Hashable, Sendable {
    case fire = "Fire"
    case advance = "Advance"
    case run = "Run"
    case ambush = "Ambush"
    case rally = "Rally"
    case down = "Down"
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
    public let currentOrder: HistoricalBoardOrder?
    public let availableOrders: [HistoricalBoardOrder]
    public let orderDiceSummary: String
    public let pinCount: Int
    public let moraleQuality: String
    public let retainedOrder: Bool
    public let downOrderActive: Bool
    public let ambushOrderActive: Bool

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
        targeted: Bool = false,
        currentOrder: HistoricalBoardOrder? = nil,
        availableOrders: [HistoricalBoardOrder] = [],
        orderDiceSummary: String = "",
        pinCount: Int = 0,
        moraleQuality: String = "Regular",
        retainedOrder: Bool = false,
        downOrderActive: Bool = false,
        ambushOrderActive: Bool = false
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
        self.currentOrder = currentOrder
        self.availableOrders = availableOrders
        self.orderDiceSummary = orderDiceSummary
        self.pinCount = pinCount
        self.moraleQuality = moraleQuality
        self.retainedOrder = retainedOrder
        self.downOrderActive = downOrderActive
        self.ambushOrderActive = ambushOrderActive
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

public enum HistoricalBoardSelectionIntent: Hashable, Sendable {
    case selectUnit(Int)
    case selectTarget(Int)
    case clearSelection
    case ignored

    public var unitID: Int? {
        switch self {
        case .selectUnit(let id), .selectTarget(let id):
            return id
        case .clearSelection, .ignored:
            return nil
        }
    }
}

public enum HistoricalBoardInteractionResolver {
    public static func unitTapIntent<ID: HistoricalBattleID>(
        for unit: HistoricalBoardUnitSnapshot,
        in snapshot: HistoricalBoardSnapshot<ID>
    ) -> HistoricalBoardSelectionIntent {
        guard !unit.destroyed else {
            return .ignored
        }

        if unit.sideID == snapshot.activeSideID {
            return .selectUnit(unit.id)
        }

        return .selectTarget(unit.id)
    }
}

public struct HistoricalBoardUnitLayoutSlot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let coordinate: HistoricalBattleCoordinate
    public let offsetIndex: Int

    public init(id: Int, coordinate: HistoricalBattleCoordinate, offsetIndex: Int) {
        self.id = id
        self.coordinate = coordinate
        self.offsetIndex = offsetIndex
    }
}

public struct HistoricalBoardReadabilityAudit: Codable, Hashable, Sendable {
    public let unitCount: Int
    public let objectiveCount: Int
    public let zoneCount: Int
    public let directBoardNameLabelCount: Int
    public let estimatedOverlappingTokenPairs: Int
    public let usesIDOnlyUnitTokens: Bool
    public let hasSidebarDetailDisclosure: Bool

    public init(
        unitCount: Int,
        objectiveCount: Int,
        zoneCount: Int,
        directBoardNameLabelCount: Int,
        estimatedOverlappingTokenPairs: Int,
        usesIDOnlyUnitTokens: Bool,
        hasSidebarDetailDisclosure: Bool
    ) {
        self.unitCount = unitCount
        self.objectiveCount = objectiveCount
        self.zoneCount = zoneCount
        self.directBoardNameLabelCount = directBoardNameLabelCount
        self.estimatedOverlappingTokenPairs = estimatedOverlappingTokenPairs
        self.usesIDOnlyUnitTokens = usesIDOnlyUnitTokens
        self.hasSidebarDetailDisclosure = hasSidebarDetailDisclosure
    }

    public var passesCriticalReadabilityGate: Bool {
        unitCount > 0 &&
            objectiveCount > 0 &&
            directBoardNameLabelCount == 0 &&
            estimatedOverlappingTokenPairs == 0 &&
            usesIDOnlyUnitTokens &&
            hasSidebarDetailDisclosure
    }
}

public enum HistoricalBoardLayoutResolver {
    private static let boardWidth = 100.0
    private static let boardHeight = 64.0
    private static let clusterDistance = 10.0
    private static let tokenWidth = 7.8
    private static let tokenHeight = 6.8
    private static let tokenOffsets = [
        HistoricalBattleCoordinate(x: 0, y: 0),
        HistoricalBattleCoordinate(x: 9, y: 0),
        HistoricalBattleCoordinate(x: -9, y: 0),
        HistoricalBattleCoordinate(x: 0, y: 7),
        HistoricalBattleCoordinate(x: 0, y: -7),
        HistoricalBattleCoordinate(x: 9, y: 7),
        HistoricalBattleCoordinate(x: -9, y: 7),
        HistoricalBattleCoordinate(x: 9, y: -7),
        HistoricalBattleCoordinate(x: -9, y: -7),
        HistoricalBattleCoordinate(x: 18, y: 0),
        HistoricalBattleCoordinate(x: -18, y: 0),
        HistoricalBattleCoordinate(x: 0, y: 14),
        HistoricalBattleCoordinate(x: 0, y: -14),
    ]

    public static func resolvedUnitSlots<ID: HistoricalBattleID>(
        for snapshot: HistoricalBoardSnapshot<ID>
    ) -> [HistoricalBoardUnitLayoutSlot] {
        snapshot.units
            .sorted { $0.id < $1.id }
            .map { unit in
                let offsetIndex = clusterOffsetIndex(for: unit, in: snapshot)
                let offset = tokenOffsets[offsetIndex % tokenOffsets.count]
                return HistoricalBoardUnitLayoutSlot(
                    id: unit.id,
                    coordinate: clamped(
                        HistoricalBattleCoordinate(
                            x: unit.position.x + offset.x,
                            y: unit.position.y + offset.y
                        )
                    ),
                    offsetIndex: offsetIndex
                )
            }
    }

    public static func resolvedUnitCoordinate<ID: HistoricalBattleID>(
        for unit: HistoricalBoardUnitSnapshot,
        in snapshot: HistoricalBoardSnapshot<ID>
    ) -> HistoricalBattleCoordinate {
        resolvedUnitSlots(for: snapshot).first { $0.id == unit.id }?.coordinate ?? unit.position
    }

    public static func readabilityAudit<ID: HistoricalBattleID>(
        for snapshot: HistoricalBoardSnapshot<ID>
    ) -> HistoricalBoardReadabilityAudit {
        let readability = HistoricalPlayableSurfaceCatalog.boardReadabilityProfile
        return HistoricalBoardReadabilityAudit(
            unitCount: snapshot.units.filter { !$0.destroyed }.count,
            objectiveCount: snapshot.objectives.count,
            zoneCount: snapshot.zones.count,
            directBoardNameLabelCount: readability.directBoardNameLabelCount,
            estimatedOverlappingTokenPairs: estimatedOverlappingTokenPairs(for: snapshot),
            usesIDOnlyUnitTokens: readability.usesIDOnlyUnitTokens,
            hasSidebarDetailDisclosure: readability.hasSidebarDetailDisclosure
        )
    }

    private static func clusterOffsetIndex<ID: HistoricalBattleID>(
        for unit: HistoricalBoardUnitSnapshot,
        in snapshot: HistoricalBoardSnapshot<ID>
    ) -> Int {
        let nearby = snapshot.units
            .filter { !$0.destroyed && boardDistance($0.position, unit.position) <= clusterDistance }
            .sorted { $0.id < $1.id }

        return nearby.firstIndex { $0.id == unit.id } ?? 0
    }

    private static func estimatedOverlappingTokenPairs<ID: HistoricalBattleID>(
        for snapshot: HistoricalBoardSnapshot<ID>
    ) -> Int {
        let slots = resolvedUnitSlots(for: snapshot)
        var overlappingPairs = 0

        for lhsIndex in slots.indices {
            let rhsStart = slots.index(after: lhsIndex)
            guard rhsStart < slots.endIndex else {
                continue
            }

            for rhsIndex in rhsStart..<slots.endIndex {
                let lhs = slots[lhsIndex].coordinate
                let rhs = slots[rhsIndex].coordinate
                if abs(lhs.x - rhs.x) < tokenWidth && abs(lhs.y - rhs.y) < tokenHeight {
                    overlappingPairs += 1
                }
            }
        }

        return overlappingPairs
    }

    private static func boardDistance(
        _ lhs: HistoricalBattleCoordinate,
        _ rhs: HistoricalBattleCoordinate
    ) -> Double {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt(dx * dx + dy * dy)
    }

    private static func clamped(_ point: HistoricalBattleCoordinate) -> HistoricalBattleCoordinate {
        HistoricalBattleCoordinate(
            x: min(max(3, point.x), boardWidth - 3),
            y: min(max(3, point.y), boardHeight - 3)
        )
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
    func issueOrder(_ order: HistoricalBoardOrder, to unitID: Int) -> Bool
    func issueOrderToSelectedUnit(_ order: HistoricalBoardOrder) -> Bool
    func shootSelectedTarget() -> Bool
    func resolveFirstPendingChoice() -> Bool
    func advancePhase()
}

public extension HistoricalBoardSession {
    func issueOrder(_ order: HistoricalBoardOrder, to unitID: Int) -> Bool {
        _ = order
        _ = unitID
        return false
    }

    func issueOrderToSelectedUnit(_ order: HistoricalBoardOrder) -> Bool {
        _ = order
        return false
    }

    @available(*, deprecated, message: "Use issueOrder(_:to:) and order-dice actions instead of global phase advancement.")
    func advanceLegacyPhase() {
        advancePhase()
    }
}
