import DerZweiteWeltkriegCore
import DerZweiteWeltkriegHistorical
import Foundation

public enum NativeBoardPlayer: String, Codable, Hashable, Sendable {
    case none = "None"
    case player = "Player"
    case guderianAI = "Guderian AI"

    public init(_ player: player_t) {
        switch player {
        case DZW_PLAYER_ONE:
            self = .player
        case DZW_PLAYER_TWO:
            self = .guderianAI
        default:
            self = .none
        }
    }
}

private extension NativeBoardPlayer {
    var cValue: player_t {
        switch self {
        case .player:
            return DZW_PLAYER_ONE
        case .guderianAI:
            return DZW_PLAYER_TWO
        case .none:
            return DZW_PLAYER_NONE
        }
    }
}

public enum NativeBoardPhase: String, Codable, Hashable, Sendable {
    case movement = "Movement"
    case shooting = "Shooting"
    case assault = "Assault"

    init(_ phase: phase_t) {
        switch phase {
        case DZW_PHASE_SHOOTING:
            self = .shooting
        case DZW_PHASE_ASSAULT:
            self = .assault
        default:
            self = .movement
        }
    }
}

public enum NativeBoardActionStatus: String, Codable, Hashable, Sendable {
    case idle = "Idle"
    case succeeded = "Succeeded"
    case blocked = "Blocked"
}

public struct NativeBoardActionMessage: Codable, Hashable, Sendable {
    public let status: NativeBoardActionStatus
    public let title: String
    public let detail: String

    public init(status: NativeBoardActionStatus, title: String, detail: String) {
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct NativeBoardOrderDieSnapshot: Codable, Hashable, Sendable {
    public let sequence: Int
    public let owner: NativeBoardPlayer

    public init(sequence: Int, owner: NativeBoardPlayer) {
        self.sequence = sequence
        self.owner = owner
    }
}

public struct NativeBoardOrderDiceSnapshot: Codable, Hashable, Sendable {
    public let rulesetActive: Bool
    public let current: NativeBoardOrderDieSnapshot?
    public let remaining: [NativeBoardOrderDieSnapshot]
    public let spent: [NativeBoardOrderDieSnapshot]
    public let retained: [NativeBoardOrderDieSnapshot]

    public init(
        rulesetActive: Bool,
        current: NativeBoardOrderDieSnapshot?,
        remaining: [NativeBoardOrderDieSnapshot],
        spent: [NativeBoardOrderDieSnapshot],
        retained: [NativeBoardOrderDieSnapshot]
    ) {
        self.rulesetActive = rulesetActive
        self.current = current
        self.remaining = remaining
        self.spent = spent
        self.retained = retained
    }

    public var hasCurrentDie: Bool {
        current != nil
    }

    public var totalDice: Int {
        remaining.count + spent.count + retained.count + (current == nil ? 0 : 1)
    }

    public func remainingCount(for owner: NativeBoardPlayer) -> Int {
        remaining.filter { $0.owner == owner }.count
    }

    public func spentCount(for owner: NativeBoardPlayer) -> Int {
        spent.filter { $0.owner == owner }.count
    }

    public func retainedCount(for owner: NativeBoardPlayer) -> Int {
        retained.filter { $0.owner == owner }.count
    }

    public func currentCount(for owner: NativeBoardPlayer) -> Int {
        current?.owner == owner ? 1 : 0
    }
}

public struct NativeBoardMissionSnapshot: Codable, Hashable, Sendable {
    public let name: String
    public let targetScore: Int
    public let playerScore: Int
    public let opponentScore: Int
    public let winner: NativeBoardPlayer

    public init(
        name: String,
        targetScore: Int,
        playerScore: Int,
        opponentScore: Int,
        winner: NativeBoardPlayer
    ) {
        self.name = name
        self.targetScore = targetScore
        self.playerScore = playerScore
        self.opponentScore = opponentScore
        self.winner = winner
    }
}

public struct NativeBoardUnitSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let engineName: String
    public let nativeUnitID: String?
    public let owner: NativeBoardPlayer
    public let kind: String
    public let mobility: String
    public let role: String
    public let historicalNote: String
    public let x: Double
    public let y: Double
    public let facingDegrees: Double
    public let totalWoundsRemaining: Int
    public let destroyed: Bool
    public let inCover: Bool
    public let hullDown: Bool
    public let pinned: Bool
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
    public let lastOrderTestResult: String
    public let lastOrderTestRoll: Int
    public let lastOrderTestTarget: Int
    public let lastOrderTestPinModifier: Int
    public let lastOrderTestOfficerModifier: Int
    public let lastFubarResult: String
    public let lastFubarTargetID: Int?
    public let retainedOrder: Bool
    public let downOrderActive: Bool
    public let ambushOrderActive: Bool
    public let advanceMoveAllowance: Double
    public let runMoveAllowance: Double
    public let currentOrderMoveAllowance: Double
    public let reverseMoveAllowance: Double
    public let canReverseNow: Bool
    public let pivotBudget: Int
    public let pivotCountUsed: Int
    public let movementRejectionReason: String
    public let assaultMoveAllowance: Double
    public let frontArmour: Int
    public let sideArmour: Int
    public let rearArmour: Int
    public let defensiveToHitModifier: Int
    public let fastVehicle: Bool
    public let reconVehicle: Bool
    public let openToppedVehicle: Bool
    public let smokeAvailable: Bool
    public let smokeActive: Bool
    public let crewShaken: Bool
    public let crewStunned: Bool
    public let immobilized: Bool
    public let wrecked: Bool
    public let wreckBlocksMovement: Bool
    public let lastShootingTargetID: Int?
    public let lastShootingRange: Double
    public let lastShootingTargetReaction: String
    public let lastShootingBaseToHit: Int
    public let lastShootingPointBlankModifier: Int
    public let lastShootingPinModifier: Int
    public let lastShootingLongRangeModifier: Int
    public let lastShootingInexperiencedModifier: Int
    public let lastShootingMoveModifier: Int
    public let lastShootingDownModifier: Int
    public let lastShootingSmallUnitModifier: Int
    public let lastShootingCoverModifier: Int
    public let lastShootingToHitModifier: Int
    public let lastShootingNeededToHit: Int
    public let lastShootingDamageValue: Int
    public let lastShootingPenetrationModifier: Int
    public let lastShootingDamageRoll: Int
    public let lastShootingDamageSuccess: Bool
    public let lastShootingVehicleArmourModifier: Int
    public let lastShootingVehicleLongRangePenalty: Int
    public let lastShootingVehicleOpenToppedIndirectModifier: Int
    public let lastShootingVehicleDamageClass: String
    public let lastVehicleDamageTableRoll: Int
    public let lastVehicleDamageResult: String
    public let lastVehicleDamageMoraleRoll: Int
    public let lastVehicleDamageMoraleTarget: Int
    public let lastVehicleDamageMoraleFailed: Bool
    public let lastShootingModelsRemoved: Int
    public let lastShootingPinsAdded: Int
    public let lastShootingMoraleChecked: Bool
    public let lastShootingMoraleRoll: Int
    public let lastShootingMoraleTarget: Int
    public let lastShootingMoralePinModifier: Int
    public let lastShootingMoraleOfficerModifier: Int
    public let lastShootingMoraleFailed: Bool
    public let lastAssaultTargetID: Int?
    public let lastAssaultRange: Double
    public let lastAssaultTargetReaction: String
    public let lastAssaultAttackerWounds: Int
    public let lastAssaultDefenderWounds: Int
    public let lastAssaultDrawRounds: Int
    public let lastAssaultWinnerID: Int?
    public let lastAssaultLoserID: Int?
    public let lastAssaultLoserDestroyed: Bool
    public let lastAssaultRegroupDistance: Double
    public let lastAssaultVehicleTarget: Bool
    public let lastAssaultAntitankEquipped: Bool
    public let lastAssaultEnclosedArmourOrderTestRequired: Bool
    public let lastAssaultEnclosedArmourOrderTestRoll: Int
    public let lastAssaultEnclosedArmourOrderTestTarget: Int
    public let lastAssaultEnclosedArmourOrderTestFailed: Bool
    public let lastAssaultVehicleDefensiveFireResolved: Bool
    public let lastAssaultVehicleHits: Int
    public let lastAssaultVehicleDamageValue: Int
    public let lastAssaultVehiclePenetrationModifier: Int
    public let lastAssaultVehicleDamageRoll: Int
    public let lastAssaultVehicleDamageClass: String

    public init(
        id: Int,
        name: String,
        engineName: String,
        nativeUnitID: String?,
        owner: NativeBoardPlayer,
        kind: String,
        mobility: String,
        role: String,
        historicalNote: String,
        x: Double,
        y: Double,
        facingDegrees: Double,
        totalWoundsRemaining: Int,
        destroyed: Bool,
        inCover: Bool,
        hullDown: Bool,
        pinned: Bool,
        canMoveNow: Bool,
        canShootNow: Bool,
        canAssaultNow: Bool,
        selected: Bool,
        targeted: Bool,
        currentOrder: HistoricalBoardOrder? = nil,
        availableOrders: [HistoricalBoardOrder] = [],
        orderDiceSummary: String = "",
        pinCount: Int = 0,
        moraleQuality: String = "Regular",
        lastOrderTestResult: String = "Not Required",
        lastOrderTestRoll: Int = 0,
        lastOrderTestTarget: Int = 0,
        lastOrderTestPinModifier: Int = 0,
        lastOrderTestOfficerModifier: Int = 0,
        lastFubarResult: String = "None",
        lastFubarTargetID: Int? = nil,
        retainedOrder: Bool = false,
        downOrderActive: Bool = false,
        ambushOrderActive: Bool = false,
        advanceMoveAllowance: Double = 0,
        runMoveAllowance: Double = 0,
        currentOrderMoveAllowance: Double = 0,
        reverseMoveAllowance: Double = 0,
        canReverseNow: Bool = false,
        pivotBudget: Int = 0,
        pivotCountUsed: Int = 0,
        movementRejectionReason: String = "",
        assaultMoveAllowance: Double = 0,
        frontArmour: Int = 0,
        sideArmour: Int = 0,
        rearArmour: Int = 0,
        defensiveToHitModifier: Int = 0,
        fastVehicle: Bool = false,
        reconVehicle: Bool = false,
        openToppedVehicle: Bool = false,
        smokeAvailable: Bool = false,
        smokeActive: Bool = false,
        crewShaken: Bool = false,
        crewStunned: Bool = false,
        immobilized: Bool = false,
        wrecked: Bool = false,
        wreckBlocksMovement: Bool = false,
        lastShootingTargetID: Int? = nil,
        lastShootingRange: Double = 0,
        lastShootingTargetReaction: String = "None",
        lastShootingBaseToHit: Int = 0,
        lastShootingPointBlankModifier: Int = 0,
        lastShootingPinModifier: Int = 0,
        lastShootingLongRangeModifier: Int = 0,
        lastShootingInexperiencedModifier: Int = 0,
        lastShootingMoveModifier: Int = 0,
        lastShootingDownModifier: Int = 0,
        lastShootingSmallUnitModifier: Int = 0,
        lastShootingCoverModifier: Int = 0,
        lastShootingToHitModifier: Int = 0,
        lastShootingNeededToHit: Int = 0,
        lastShootingDamageValue: Int = 0,
        lastShootingPenetrationModifier: Int = 0,
        lastShootingDamageRoll: Int = 0,
        lastShootingDamageSuccess: Bool = false,
        lastShootingVehicleArmourModifier: Int = 0,
        lastShootingVehicleLongRangePenalty: Int = 0,
        lastShootingVehicleOpenToppedIndirectModifier: Int = 0,
        lastShootingVehicleDamageClass: String = "None",
        lastVehicleDamageTableRoll: Int = 0,
        lastVehicleDamageResult: String = "None",
        lastVehicleDamageMoraleRoll: Int = 0,
        lastVehicleDamageMoraleTarget: Int = 0,
        lastVehicleDamageMoraleFailed: Bool = false,
        lastShootingModelsRemoved: Int = 0,
        lastShootingPinsAdded: Int = 0,
        lastShootingMoraleChecked: Bool = false,
        lastShootingMoraleRoll: Int = 0,
        lastShootingMoraleTarget: Int = 0,
        lastShootingMoralePinModifier: Int = 0,
        lastShootingMoraleOfficerModifier: Int = 0,
        lastShootingMoraleFailed: Bool = false,
        lastAssaultTargetID: Int? = nil,
        lastAssaultRange: Double = 0,
        lastAssaultTargetReaction: String = "None",
        lastAssaultAttackerWounds: Int = 0,
        lastAssaultDefenderWounds: Int = 0,
        lastAssaultDrawRounds: Int = 0,
        lastAssaultWinnerID: Int? = nil,
        lastAssaultLoserID: Int? = nil,
        lastAssaultLoserDestroyed: Bool = false,
        lastAssaultRegroupDistance: Double = 0,
        lastAssaultVehicleTarget: Bool = false,
        lastAssaultAntitankEquipped: Bool = false,
        lastAssaultEnclosedArmourOrderTestRequired: Bool = false,
        lastAssaultEnclosedArmourOrderTestRoll: Int = 0,
        lastAssaultEnclosedArmourOrderTestTarget: Int = 0,
        lastAssaultEnclosedArmourOrderTestFailed: Bool = false,
        lastAssaultVehicleDefensiveFireResolved: Bool = false,
        lastAssaultVehicleHits: Int = 0,
        lastAssaultVehicleDamageValue: Int = 0,
        lastAssaultVehiclePenetrationModifier: Int = 0,
        lastAssaultVehicleDamageRoll: Int = 0,
        lastAssaultVehicleDamageClass: String = "None"
    ) {
        self.id = id
        self.name = name
        self.engineName = engineName
        self.nativeUnitID = nativeUnitID
        self.owner = owner
        self.kind = kind
        self.mobility = mobility
        self.role = role
        self.historicalNote = historicalNote
        self.x = x
        self.y = y
        self.facingDegrees = facingDegrees
        self.totalWoundsRemaining = totalWoundsRemaining
        self.destroyed = destroyed
        self.inCover = inCover
        self.hullDown = hullDown
        self.pinned = pinned
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
        self.lastOrderTestResult = lastOrderTestResult
        self.lastOrderTestRoll = lastOrderTestRoll
        self.lastOrderTestTarget = lastOrderTestTarget
        self.lastOrderTestPinModifier = lastOrderTestPinModifier
        self.lastOrderTestOfficerModifier = lastOrderTestOfficerModifier
        self.lastFubarResult = lastFubarResult
        self.lastFubarTargetID = lastFubarTargetID
        self.retainedOrder = retainedOrder
        self.downOrderActive = downOrderActive
        self.ambushOrderActive = ambushOrderActive
        self.advanceMoveAllowance = advanceMoveAllowance
        self.runMoveAllowance = runMoveAllowance
        self.currentOrderMoveAllowance = currentOrderMoveAllowance
        self.reverseMoveAllowance = reverseMoveAllowance
        self.canReverseNow = canReverseNow
        self.pivotBudget = pivotBudget
        self.pivotCountUsed = pivotCountUsed
        self.movementRejectionReason = movementRejectionReason
        self.assaultMoveAllowance = assaultMoveAllowance
        self.frontArmour = frontArmour
        self.sideArmour = sideArmour
        self.rearArmour = rearArmour
        self.defensiveToHitModifier = defensiveToHitModifier
        self.fastVehicle = fastVehicle
        self.reconVehicle = reconVehicle
        self.openToppedVehicle = openToppedVehicle
        self.smokeAvailable = smokeAvailable
        self.smokeActive = smokeActive
        self.crewShaken = crewShaken
        self.crewStunned = crewStunned
        self.immobilized = immobilized
        self.wrecked = wrecked
        self.wreckBlocksMovement = wreckBlocksMovement
        self.lastShootingTargetID = lastShootingTargetID
        self.lastShootingRange = lastShootingRange
        self.lastShootingTargetReaction = lastShootingTargetReaction
        self.lastShootingBaseToHit = lastShootingBaseToHit
        self.lastShootingPointBlankModifier = lastShootingPointBlankModifier
        self.lastShootingPinModifier = lastShootingPinModifier
        self.lastShootingLongRangeModifier = lastShootingLongRangeModifier
        self.lastShootingInexperiencedModifier = lastShootingInexperiencedModifier
        self.lastShootingMoveModifier = lastShootingMoveModifier
        self.lastShootingDownModifier = lastShootingDownModifier
        self.lastShootingSmallUnitModifier = lastShootingSmallUnitModifier
        self.lastShootingCoverModifier = lastShootingCoverModifier
        self.lastShootingToHitModifier = lastShootingToHitModifier
        self.lastShootingNeededToHit = lastShootingNeededToHit
        self.lastShootingDamageValue = lastShootingDamageValue
        self.lastShootingPenetrationModifier = lastShootingPenetrationModifier
        self.lastShootingDamageRoll = lastShootingDamageRoll
        self.lastShootingDamageSuccess = lastShootingDamageSuccess
        self.lastShootingVehicleArmourModifier = lastShootingVehicleArmourModifier
        self.lastShootingVehicleLongRangePenalty = lastShootingVehicleLongRangePenalty
        self.lastShootingVehicleOpenToppedIndirectModifier = lastShootingVehicleOpenToppedIndirectModifier
        self.lastShootingVehicleDamageClass = lastShootingVehicleDamageClass
        self.lastVehicleDamageTableRoll = lastVehicleDamageTableRoll
        self.lastVehicleDamageResult = lastVehicleDamageResult
        self.lastVehicleDamageMoraleRoll = lastVehicleDamageMoraleRoll
        self.lastVehicleDamageMoraleTarget = lastVehicleDamageMoraleTarget
        self.lastVehicleDamageMoraleFailed = lastVehicleDamageMoraleFailed
        self.lastShootingModelsRemoved = lastShootingModelsRemoved
        self.lastShootingPinsAdded = lastShootingPinsAdded
        self.lastShootingMoraleChecked = lastShootingMoraleChecked
        self.lastShootingMoraleRoll = lastShootingMoraleRoll
        self.lastShootingMoraleTarget = lastShootingMoraleTarget
        self.lastShootingMoralePinModifier = lastShootingMoralePinModifier
        self.lastShootingMoraleOfficerModifier = lastShootingMoraleOfficerModifier
        self.lastShootingMoraleFailed = lastShootingMoraleFailed
        self.lastAssaultTargetID = lastAssaultTargetID
        self.lastAssaultRange = lastAssaultRange
        self.lastAssaultTargetReaction = lastAssaultTargetReaction
        self.lastAssaultAttackerWounds = lastAssaultAttackerWounds
        self.lastAssaultDefenderWounds = lastAssaultDefenderWounds
        self.lastAssaultDrawRounds = lastAssaultDrawRounds
        self.lastAssaultWinnerID = lastAssaultWinnerID
        self.lastAssaultLoserID = lastAssaultLoserID
        self.lastAssaultLoserDestroyed = lastAssaultLoserDestroyed
        self.lastAssaultRegroupDistance = lastAssaultRegroupDistance
        self.lastAssaultVehicleTarget = lastAssaultVehicleTarget
        self.lastAssaultAntitankEquipped = lastAssaultAntitankEquipped
        self.lastAssaultEnclosedArmourOrderTestRequired = lastAssaultEnclosedArmourOrderTestRequired
        self.lastAssaultEnclosedArmourOrderTestRoll = lastAssaultEnclosedArmourOrderTestRoll
        self.lastAssaultEnclosedArmourOrderTestTarget = lastAssaultEnclosedArmourOrderTestTarget
        self.lastAssaultEnclosedArmourOrderTestFailed = lastAssaultEnclosedArmourOrderTestFailed
        self.lastAssaultVehicleDefensiveFireResolved = lastAssaultVehicleDefensiveFireResolved
        self.lastAssaultVehicleHits = lastAssaultVehicleHits
        self.lastAssaultVehicleDamageValue = lastAssaultVehicleDamageValue
        self.lastAssaultVehiclePenetrationModifier = lastAssaultVehiclePenetrationModifier
        self.lastAssaultVehicleDamageRoll = lastAssaultVehicleDamageRoll
        self.lastAssaultVehicleDamageClass = lastAssaultVehicleDamageClass
    }

    public var roleLine: String {
        mobility == role ? role : "\(mobility) | \(role)"
    }
}

public struct NativeBoardZoneSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let kind: String
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let coverSave: Int
    public let blocksLineOfSight: Bool
    public let hullDown: Bool

    public init(
        id: Int,
        name: String,
        kind: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        coverSave: Int,
        blocksLineOfSight: Bool,
        hullDown: Bool
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.coverSave = coverSave
        self.blocksLineOfSight = blocksLineOfSight
        self.hullDown = hullDown
    }
}

public struct NativeBoardObjectiveSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let x: Double
    public let y: Double
    public let radius: Double
    public let controller: NativeBoardPlayer
    public let playerPresence: Int
    public let opponentPresence: Int

    public init(
        id: Int,
        name: String,
        x: Double,
        y: Double,
        radius: Double,
        controller: NativeBoardPlayer,
        playerPresence: Int,
        opponentPresence: Int
    ) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.radius = radius
        self.controller = controller
        self.playerPresence = playerPresence
        self.opponentPresence = opponentPresence
    }
}

public struct NativeBoardSnapshot: Codable, Hashable, Sendable {
    public let scenarioID: GuderianBattleID
    public let scenarioTitle: String
    public let turnNumber: Int
    public let activePlayer: NativeBoardPlayer
    public let phase: NativeBoardPhase
    public let mission: NativeBoardMissionSnapshot
    public let units: [NativeBoardUnitSnapshot]
    public let zones: [NativeBoardZoneSnapshot]
    public let objectives: [NativeBoardObjectiveSnapshot]
    public let logLines: [String]
    public let lastAction: NativeBoardActionMessage
    public let orderDice: NativeBoardOrderDiceSnapshot
    public let boardReport: NativeScenarioBoardReport
    public let deploymentReport: NativeScenarioDeploymentReport

    public init(
        scenarioID: GuderianBattleID,
        scenarioTitle: String,
        turnNumber: Int,
        activePlayer: NativeBoardPlayer,
        phase: NativeBoardPhase,
        mission: NativeBoardMissionSnapshot,
        units: [NativeBoardUnitSnapshot],
        zones: [NativeBoardZoneSnapshot],
        objectives: [NativeBoardObjectiveSnapshot],
        logLines: [String],
        lastAction: NativeBoardActionMessage,
        orderDice: NativeBoardOrderDiceSnapshot,
        boardReport: NativeScenarioBoardReport,
        deploymentReport: NativeScenarioDeploymentReport
    ) {
        self.scenarioID = scenarioID
        self.scenarioTitle = scenarioTitle
        self.turnNumber = turnNumber
        self.activePlayer = activePlayer
        self.phase = phase
        self.mission = mission
        self.units = units
        self.zones = zones
        self.objectives = objectives
        self.logLines = logLines
        self.lastAction = lastAction
        self.orderDice = orderDice
        self.boardReport = boardReport
        self.deploymentReport = deploymentReport
    }

    public var isScenarioBoardPlayable: Bool {
        boardReport.isScenarioSpecific && !units.isEmpty && !objectives.isEmpty
    }

    public var selectedUnit: NativeBoardUnitSnapshot? {
        units.first(where: \.selected)
    }

    public var selectedTarget: NativeBoardUnitSnapshot? {
        units.first(where: \.targeted)
    }
}

public final class NativeBoardSession {
    public static let cycleRange = 281...290

    public let loadout: NativeScenarioLoadout
    public let launch: HistoricalBattleLaunch<GuderianBattleID>
    private let loadedGame: NativeScenarioLoadedGame
    private let nativeUnitByEngineID: [Int: NativeBattleUnit]
    private var selectedUnitID: Int?
    private var selectedTargetID: Int?
    private var lastAction = NativeBoardActionMessage(status: .idle, title: "Ready", detail: "Board session is ready.")

    public var handle: OpaquePointer {
        loadedGame.handle
    }

    public var humanPlayer: NativeBoardPlayer {
        launch.humanSideID
            .flatMap(GuderianHistoricalSideSelectionResolver.nativePlayer(for:)) ?? .player
    }

    public var aiPlayer: NativeBoardPlayer {
        launch.aiSideID
            .flatMap(GuderianHistoricalSideSelectionResolver.nativePlayer(for:)) ?? .guderianAI
    }

    public init?(
        scenario: GuderianScenario,
        seed: UInt32 = 1941,
        launch: HistoricalBattleLaunch<GuderianBattleID>? = nil
    ) {
        let resolvedLaunch: HistoricalBattleLaunch<GuderianBattleID>
        if let launch {
            resolvedLaunch = launch
        } else if let defaultLaunch = try? GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: GuderianHistoricalSideSelectionResolver.defaultHumanSideID,
            seed: seed
        ) {
            resolvedLaunch = defaultLaunch
        } else {
            return nil
        }

        let loadout = NativeScenarioLoader.load(scenario, seed: resolvedLaunch.seed)
        guard let loadedGame = loadout.makeGame() else {
            return nil
        }
        self.loadout = loadout
        self.launch = resolvedLaunch
        self.loadedGame = loadedGame
        nativeUnitByEngineID = Self.nativeUnitMap(handle: loadedGame.handle, instance: loadout.instance)
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
    }

    public convenience init?(
        scenario: GuderianScenario,
        launch: HistoricalBattleLaunch<GuderianBattleID>
    ) {
        self.init(scenario: scenario, seed: launch.seed, launch: launch)
    }

    public convenience init?(battleID: GuderianBattleID, seed: UInt32 = 1941) {
        guard let scenario = GuderianCampaignCatalog.scenario(id: battleID) else {
            return nil
        }
        self.init(scenario: scenario, seed: seed)
    }

    public func snapshot() -> NativeBoardSnapshot {
        let view = game_view(handle)
        let mission = game_mission_view(handle)
        return NativeBoardSnapshot(
            scenarioID: loadout.scenario.id,
            scenarioTitle: loadout.scenario.title,
            turnNumber: Int(view.turn_number),
            activePlayer: NativeBoardPlayer(view.active_player),
            phase: NativeBoardPhase(view.phase),
            mission: NativeBoardMissionSnapshot(
                name: nativeBoardCString(mission.name),
                targetScore: Int(mission.target_score),
                playerScore: Int(mission.player_one_score),
                opponentScore: Int(mission.player_two_score),
                winner: NativeBoardPlayer(mission.winner)
            ),
            units: unitSnapshots(),
            zones: zoneSnapshots(),
            objectives: objectiveSnapshots(),
            logLines: logLines(),
            lastAction: lastAction,
            orderDice: orderDiceSnapshot(),
            boardReport: loadedGame.boardReport,
            deploymentReport: loadedGame.deploymentReport
        )
    }

    public func selectUnit(_ id: Int) {
        selectedUnitID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Unit selected", detail: unitName(id: id))
        if selectedTargetID == id {
            selectedTargetID = nil
        }
    }

    public func selectTarget(_ id: Int) {
        selectedTargetID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Target selected", detail: unitName(id: id))
    }

    public func selectFirstActiveUnit() {
        selectedUnitID = (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { $0.owner == game_view(self.handle).active_player && !$0.destroyed && !$0.embarked }
            .map { Int($0.id) }
    }

    public func selectNearestEnemyToSelectedUnit() {
        guard let selected = selectedUnitView() else {
            selectedTargetID = nil
            return
        }
        selectedTargetID = (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .filter { $0.owner != selected.owner && $0.owner != DZW_PLAYER_NONE && !$0.destroyed && !$0.embarked }
            .min { lhs, rhs in
                distance(from: selected, to: lhs) < distance(from: selected, to: rhs)
            }
            .map { Int($0.id) }
    }

    @discardableResult
    public func moveSelectedUnitTowardNearestObjective(maxDistance: Double = 4) -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before issuing movement.")
        }
        guard orderDiceRulesetActive || NativeBoardPhase(game_view(handle).phase) == .movement,
              unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move with the current phase or order.")
        }
        guard let objective = nearestObjective(to: unit) else {
            return failAction("No objective", "The board has no scenario objective to move toward.")
        }

        return move(unit, toward: objective, maxDistance: maxDistance)
    }

    @discardableResult
    public func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double = 6) -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before issuing movement.")
        }
        guard orderDiceRulesetActive || NativeBoardPhase(game_view(handle).phase) == .movement,
              unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move with the current phase or order.")
        }
        let priorityObjectives = priorityObjectives(named: priorityNames)
        var candidateObjectives = priorityObjectives
        if let nearest = nearestObjective(to: unit), !candidateObjectives.contains(where: { $0.id == nearest.id }) {
            candidateObjectives.append(nearest)
        }
        guard !candidateObjectives.isEmpty else {
            return failAction("No objective", "The board has no scenario objective to move toward.")
        }

        for objective in candidateObjectives {
            if move(unit, toward: objective, maxDistance: maxDistance) {
                return true
            }
        }

        return failFromEngine("Priority move blocked")
    }

    @discardableResult
    public func moveUnit(_ id: Int, to point: NativeBattleCoordinate) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        guard orderDiceRulesetActive || NativeBoardPhase(game_view(handle).phase) == .movement,
              unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move with the current phase or order.")
        }

        let x = clamp(point.x, min: 1, max: loadout.blueprint.engineBoardFrame.width - 1)
        let y = clamp(point.y, min: 1, max: loadout.blueprint.engineBoardFrame.height - 1)
        if game_move_unit(handle, Int32(id), Float(x), Float(y)) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unitDisplayName(unit)) moved to \(Int(x)), \(Int(y)).")
            return true
        }
        return failFromEngine("Move blocked")
    }

    @discardableResult
    public func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_rotate_unit(handle, Int32(id), Float(facingDegrees)) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Rotated", detail: "\(unitDisplayName(unit)) rotated to \(Int(facingDegrees)) degrees.")
            return true
        }
        return failFromEngine("Rotate blocked")
    }

    @discardableResult
    public func toggleCover(for id: Int, enabled: Bool) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_toggle_cover(handle, Int32(id), enabled) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Cover updated", detail: "\(unitDisplayName(unit)) \(enabled ? "entered" : "left") cover.")
            return true
        }
        return failFromEngine("Cover toggle blocked")
    }

    @discardableResult
    public func toggleHullDown(for id: Int, enabled: Bool) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_toggle_hull_down(handle, Int32(id), enabled) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Hull-down updated", detail: "\(unitDisplayName(unit)) \(enabled ? "took" : "left") hull-down position.")
            return true
        }
        return failFromEngine("Hull-down toggle blocked")
    }

    @discardableResult
    public func shootUnit(_ attackerID: Int, targetID: Int) -> Bool {
        guard let unit = unitView(id: attackerID) else {
            return failAction("Unit unavailable", "Unit \(attackerID) is not present on the board.")
        }
        guard orderDiceRulesetActive || NativeBoardPhase(game_view(handle).phase) == .shooting,
              unit.can_shoot_now else {
            return failAction("Shooting blocked", "\(unitDisplayName(unit)) cannot shoot with the current phase or order.")
        }
        if game_shoot_unit(handle, Int32(attackerID), Int32(targetID)) {
            selectedUnitID = attackerID
            selectedTargetID = targetID
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Fired", detail: "\(unitDisplayName(unit)) fired at \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Shot blocked")
    }

    @discardableResult
    public func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool = true) -> Bool {
        guard let unit = unitView(id: attackerID) else {
            return failAction("Unit unavailable", "Unit \(attackerID) is not present on the board.")
        }
        guard orderDiceRulesetActive || NativeBoardPhase(game_view(handle).phase) == .assault,
              unit.can_assault_now else {
            return failAction("Assault blocked", "\(unitDisplayName(unit)) cannot assault with the current phase or order.")
        }
        let followUp = advance ? DZW_FOLLOW_UP_ADVANCE : DZW_FOLLOW_UP_CONSOLIDATE
        if game_assault_unit(handle, Int32(attackerID), Int32(targetID), followUp) {
            selectedUnitID = attackerID
            selectedTargetID = targetID
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Assaulted", detail: "\(unitDisplayName(unit)) assaulted \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Assault blocked")
    }

    @discardableResult
    public func issueOrder(_ order: HistoricalBoardOrder, to unitID: Int) -> Bool {
        if game_ruleset(handle) != DZW_RULESET_ORDER_DICE {
            guard game_set_ruleset(handle, DZW_RULESET_ORDER_DICE) else {
                return failFromEngine("Order mode blocked")
            }
        }
        guard let unit = unitView(id: unitID) else {
            return failAction("Unit unavailable", "Unit \(unitID) is not present on the board.")
        }
        guard currentOrderDieBelongs(to: unit.owner) || drawOrderDie(for: unit.owner) else {
            return failFromEngine("Order die blocked")
        }
        guard game_assign_order(handle, Int32(unitID), order.cValue) else {
            return failFromEngine("Order blocked")
        }

        selectedUnitID = unitID
        lastAction = NativeBoardActionMessage(
            status: .succeeded,
            title: "\(order.rawValue) order",
            detail: "\(unitDisplayName(unit)) received \(order.rawValue)."
        )
        return true
    }

    @discardableResult
    public func prepareNextOrderDiceActivation(
        preferredOwner: NativeBoardPlayer? = nil,
        selectsUnit: Bool = true
    ) -> Bool {
        if !orderDiceRulesetActive {
            guard game_set_ruleset(handle, DZW_RULESET_ORDER_DICE) else {
                return failFromEngine("Order mode blocked")
            }
        }

        if game_order_dice_turn_complete(handle) {
            guard game_end_order_dice_turn(handle) else {
                return failFromEngine("Order-dice turn end blocked")
            }
        }

        if let preferredOwner,
           preferredOwner != .none,
           !currentOrderDieBelongs(to: preferredOwner.cValue) {
            guard drawOrderDie(for: preferredOwner.cValue) else {
                return failFromEngine("Order die draw blocked")
            }
        } else if !game_current_order_die_view(handle).available {
            if game_order_dice_remaining_count(handle) == 0 {
                guard game_end_order_dice_turn(handle) else {
                    return failFromEngine("Order-dice turn end blocked")
                }
            }
            guard game_draw_order_die(handle) else {
                return failFromEngine("Order die draw blocked")
            }
        }

        if selectsUnit {
            selectFirstActiveUnit()
            selectNearestEnemyToSelectedUnit()
        } else {
            selectedUnitID = nil
            selectedTargetID = nil
        }
        let current = game_current_order_die_view(handle)
        lastAction = NativeBoardActionMessage(
            status: current.available ? .succeeded : .blocked,
            title: current.available ? "Order die drawn" : "Order die blocked",
            detail: current.available ? "Order die drawn for \(NativeBoardPlayer(current.owner).rawValue)." : lastEngineError()
        )
        return current.available
    }

    @discardableResult
    public func resolveOrderTestIfNeeded(for unitID: Int) -> Bool {
        guard orderDiceRulesetActive else {
            return true
        }
        guard let unit = unitView(id: unitID), unit.current_order != DZW_ORDER_NONE else {
            return true
        }
        let result = game_resolve_order_test(handle, Int32(unitID))
        let refreshed = unitView(id: unitID) ?? unit
        lastAction = NativeBoardActionMessage(
            status: result ? .succeeded : .blocked,
            title: result ? "Order test resolved" : "Order test blocked",
            detail: result ? orderDiceSummary(for: refreshed) : lastEngineError()
        )
        return result
    }

    @discardableResult
    public func resolveRallyOrder(for unitID: Int) -> Bool {
        guard orderDiceRulesetActive else {
            return false
        }
        let result = game_resolve_rally_order(handle, Int32(unitID))
        let detail = unitView(id: unitID).map(orderDiceSummary(for:)) ?? lastEngineError()
        lastAction = NativeBoardActionMessage(
            status: result ? .succeeded : .blocked,
            title: result ? "Rally resolved" : "Rally blocked",
            detail: detail
        )
        return result
    }

    @discardableResult
    public func issueOrderToSelectedUnit(_ order: HistoricalBoardOrder) -> Bool {
        guard let selectedUnitID else {
            return failAction("No unit selected", "Select a unit before issuing an order.")
        }
        return issueOrder(order, to: selectedUnitID)
    }

    @discardableResult
    public func shootSelectedTarget() -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before shooting.")
        }
        guard let targetID = selectedTargetID else {
            return failAction("No target selected", "Select an enemy unit before shooting.")
        }
        guard orderDiceRulesetActive || NativeBoardPhase(game_view(handle).phase) == .shooting,
              unit.can_shoot_now else {
            return failAction("Shooting blocked", "\(unitDisplayName(unit)) cannot shoot with the current phase or order.")
        }

        if game_shoot_unit(handle, Int32(unit.id), Int32(targetID)) {
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Fired", detail: "\(unitDisplayName(unit)) fired at \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Shot blocked")
    }

    public func advancePhase() {
        game_advance_phase(handle)
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
        let view = game_view(handle)
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Phase advanced", detail: "\(NativeBoardPlayer(view.active_player).rawValue) \(NativeBoardPhase(view.phase).rawValue), turn \(Int(view.turn_number)).")
    }

    @discardableResult
    public func resolveFirstPendingChoice() -> Bool {
        let hitAllocation = game_pending_hit_allocation_view(handle)
        if hitAllocation.active {
            let result = game_choose_pending_hit_allocation(handle, 0)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Hit allocation resolved" : "Hit allocation blocked",
                detail: result ? "Applied the first legal damage allocation." : lastEngineError()
            )
            return result
        }

        let weaponChoice = game_pending_weapon_destroy_view(handle)
        if weaponChoice.active, game_pending_weapon_destroy_option_count(handle) > 0 {
            let option = game_pending_weapon_destroy_option_view(handle, 0)
            let result = game_choose_pending_weapon_destroy(handle, option.weapon_index)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Weapon damage resolved" : "Weapon damage blocked",
                detail: result ? "Applied the first legal weapon-damage option." : lastEngineError()
            )
            return result
        }

        return false
    }

    private func unitSnapshots() -> [NativeBoardUnitSnapshot] {
        (0..<Int(game_unit_count(handle))).map { index in
            let unit = game_unit_view(handle, Int32(index))
            let engineName = nativeBoardCString(unit.name)
            let nativeUnit = nativeUnitByEngineID[Int(unit.id)]
            let engineKind = unitKindName(unit.kind)
            return NativeBoardUnitSnapshot(
                id: Int(unit.id),
                name: nativeUnit?.name ?? engineName,
                engineName: engineName,
                nativeUnitID: nativeUnit?.id,
                owner: NativeBoardPlayer(unit.owner),
                kind: engineKind,
                mobility: nativeUnit?.mobility.rawValue ?? engineKind,
                role: nativeUnit?.role ?? engineKind,
                historicalNote: nativeUnit?.historicalNote ?? "",
                x: Double(unit.x),
                y: Double(unit.y),
                facingDegrees: Double(unit.facing_degrees),
                totalWoundsRemaining: Int(unit.total_wounds_remaining),
                destroyed: unit.destroyed,
                inCover: unit.in_cover,
                hullDown: unit.hull_down,
                pinned: unit.pinned,
                canMoveNow: unit.can_move_now,
                canShootNow: unit.can_shoot_now,
                canAssaultNow: unit.can_assault_now,
                selected: Int(unit.id) == selectedUnitID,
                targeted: Int(unit.id) == selectedTargetID,
                currentOrder: HistoricalBoardOrder(unit.current_order),
                availableOrders: availableOrders(for: unit),
                orderDiceSummary: orderDiceSummary(for: unit),
                pinCount: Int(unit.pin_count),
                moraleQuality: nativeBoardCString(game_morale_quality_name(unit.morale_quality)),
                lastOrderTestResult: nativeBoardCString(game_order_test_result_name(unit.last_order_test_result)),
                lastOrderTestRoll: Int(unit.last_order_test_roll),
                lastOrderTestTarget: Int(unit.last_order_test_target),
                lastOrderTestPinModifier: Int(unit.last_order_test_pin_modifier),
                lastOrderTestOfficerModifier: Int(unit.last_order_test_officer_modifier),
                lastFubarResult: nativeBoardCString(game_fubar_result_name(unit.last_fubar_result)),
                lastFubarTargetID: optionalNativeBoardID(unit.last_fubar_target_id),
                retainedOrder: unit.retained_order,
                downOrderActive: unit.down_order_active,
                ambushOrderActive: unit.ambush_order_active,
                advanceMoveAllowance: Double(unit.advance_move_allowance),
                runMoveAllowance: Double(unit.run_move_allowance),
                currentOrderMoveAllowance: Double(unit.current_order_move_allowance),
                reverseMoveAllowance: Double(unit.reverse_move_allowance),
                canReverseNow: unit.can_reverse_now,
                pivotBudget: Int(unit.pivot_budget),
                pivotCountUsed: Int(unit.pivot_count_used),
                movementRejectionReason: nativeBoardCString(unit.movement_rejection_reason),
                assaultMoveAllowance: Double(unit.assault_move_allowance),
                frontArmour: Int(unit.front_armour),
                sideArmour: Int(unit.side_armour),
                rearArmour: Int(unit.rear_armour),
                defensiveToHitModifier: Int(unit.defensive_to_hit_modifier),
                fastVehicle: unit.fast,
                reconVehicle: unit.recon,
                openToppedVehicle: unit.open_topped,
                smokeAvailable: unit.smoke_available,
                smokeActive: unit.smoke_active,
                crewShaken: unit.crew_shaken,
                crewStunned: unit.crew_stunned,
                immobilized: unit.immobilized,
                wrecked: unit.wrecked,
                wreckBlocksMovement: unit.wreck_blocks_movement,
                lastShootingTargetID: optionalNativeBoardID(unit.last_shooting_target_id),
                lastShootingRange: Double(unit.last_shooting_range),
                lastShootingTargetReaction: nativeBoardCString(game_target_reaction_name(unit.last_shooting_target_reaction)),
                lastShootingBaseToHit: Int(unit.last_shooting_base_to_hit),
                lastShootingPointBlankModifier: Int(unit.last_shooting_point_blank_modifier),
                lastShootingPinModifier: Int(unit.last_shooting_pin_modifier),
                lastShootingLongRangeModifier: Int(unit.last_shooting_long_range_modifier),
                lastShootingInexperiencedModifier: Int(unit.last_shooting_inexperienced_modifier),
                lastShootingMoveModifier: Int(unit.last_shooting_move_modifier),
                lastShootingDownModifier: Int(unit.last_shooting_down_modifier),
                lastShootingSmallUnitModifier: Int(unit.last_shooting_small_unit_modifier),
                lastShootingCoverModifier: Int(unit.last_shooting_cover_modifier),
                lastShootingToHitModifier: Int(unit.last_shooting_to_hit_modifier),
                lastShootingNeededToHit: Int(unit.last_shooting_needed_to_hit),
                lastShootingDamageValue: Int(unit.last_shooting_damage_value),
                lastShootingPenetrationModifier: Int(unit.last_shooting_penetration_modifier),
                lastShootingDamageRoll: Int(unit.last_shooting_damage_roll),
                lastShootingDamageSuccess: unit.last_shooting_damage_success,
                lastShootingVehicleArmourModifier: Int(unit.last_shooting_vehicle_armour_modifier),
                lastShootingVehicleLongRangePenalty: Int(unit.last_shooting_vehicle_long_range_penalty),
                lastShootingVehicleOpenToppedIndirectModifier: Int(unit.last_shooting_vehicle_open_topped_indirect_modifier),
                lastShootingVehicleDamageClass: vehicleDamageClassName(unit.last_shooting_vehicle_damage_class),
                lastVehicleDamageTableRoll: Int(unit.last_vehicle_damage_table_roll),
                lastVehicleDamageResult: nativeBoardCString(game_vehicle_damage_result_name(unit.last_vehicle_damage_result)),
                lastVehicleDamageMoraleRoll: Int(unit.last_vehicle_damage_morale_roll),
                lastVehicleDamageMoraleTarget: Int(unit.last_vehicle_damage_morale_target),
                lastVehicleDamageMoraleFailed: unit.last_vehicle_damage_morale_failed,
                lastShootingModelsRemoved: Int(unit.last_shooting_models_removed),
                lastShootingPinsAdded: Int(unit.last_shooting_pins_added),
                lastShootingMoraleChecked: unit.last_shooting_morale_checked,
                lastShootingMoraleRoll: Int(unit.last_shooting_morale_roll),
                lastShootingMoraleTarget: Int(unit.last_shooting_morale_target),
                lastShootingMoralePinModifier: Int(unit.last_shooting_morale_pin_modifier),
                lastShootingMoraleOfficerModifier: Int(unit.last_shooting_morale_officer_modifier),
                lastShootingMoraleFailed: unit.last_shooting_morale_failed,
                lastAssaultTargetID: optionalNativeBoardID(unit.last_assault_target_id),
                lastAssaultRange: Double(unit.last_assault_range),
                lastAssaultTargetReaction: nativeBoardCString(game_target_reaction_name(unit.last_assault_target_reaction)),
                lastAssaultAttackerWounds: Int(unit.last_assault_attacker_wounds),
                lastAssaultDefenderWounds: Int(unit.last_assault_defender_wounds),
                lastAssaultDrawRounds: Int(unit.last_assault_draw_rounds),
                lastAssaultWinnerID: optionalNativeBoardID(unit.last_assault_winner_id),
                lastAssaultLoserID: optionalNativeBoardID(unit.last_assault_loser_id),
                lastAssaultLoserDestroyed: unit.last_assault_loser_destroyed,
                lastAssaultRegroupDistance: Double(unit.last_assault_regroup_distance),
                lastAssaultVehicleTarget: unit.last_assault_vehicle_target,
                lastAssaultAntitankEquipped: unit.last_assault_antitank_equipped,
                lastAssaultEnclosedArmourOrderTestRequired: unit.last_assault_enclosed_armour_order_test_required,
                lastAssaultEnclosedArmourOrderTestRoll: Int(unit.last_assault_enclosed_armour_order_test_roll),
                lastAssaultEnclosedArmourOrderTestTarget: Int(unit.last_assault_enclosed_armour_order_test_target),
                lastAssaultEnclosedArmourOrderTestFailed: unit.last_assault_enclosed_armour_order_test_failed,
                lastAssaultVehicleDefensiveFireResolved: unit.last_assault_vehicle_defensive_fire_resolved,
                lastAssaultVehicleHits: Int(unit.last_assault_vehicle_hits),
                lastAssaultVehicleDamageValue: Int(unit.last_assault_vehicle_damage_value),
                lastAssaultVehiclePenetrationModifier: Int(unit.last_assault_vehicle_penetration_modifier),
                lastAssaultVehicleDamageRoll: Int(unit.last_assault_vehicle_damage_roll),
                lastAssaultVehicleDamageClass: vehicleDamageClassName(unit.last_assault_vehicle_damage_class)
            )
        }
    }

    private func zoneSnapshots() -> [NativeBoardZoneSnapshot] {
        (0..<Int(game_zone_count(handle))).map { index in
            let zone = game_zone_view(handle, Int32(index))
            return NativeBoardZoneSnapshot(
                id: Int(zone.id),
                name: nativeBoardCString(zone.name),
                kind: terrainKindName(zone.kind),
                x: Double(zone.rect.x),
                y: Double(zone.rect.y),
                width: Double(zone.rect.width),
                height: Double(zone.rect.height),
                coverSave: Int(zone.cover_save),
                blocksLineOfSight: zone.blocks_line_of_sight,
                hullDown: zone.hull_down
            )
        }
    }

    private func objectiveSnapshots() -> [NativeBoardObjectiveSnapshot] {
        (0..<Int(game_objective_count(handle))).map { index in
            let objective = game_objective_view(handle, Int32(index))
            return NativeBoardObjectiveSnapshot(
                id: Int(objective.id),
                name: nativeBoardCString(objective.name),
                x: Double(objective.x),
                y: Double(objective.y),
                radius: Double(objective.radius),
                controller: NativeBoardPlayer(objective.controller),
                playerPresence: Int(objective.player_one_presence),
                opponentPresence: Int(objective.player_two_presence)
            )
        }
    }

    private func logLines() -> [String] {
        (0..<Int(game_log_count(handle))).map { index in
            nativeBoardCString(game_log_line(handle, Int32(index)))
        }
    }

    private func selectedUnitView() -> unit_view_t? {
        guard let selectedUnitID else {
            return nil
        }
        return unitView(id: selectedUnitID)
    }

    private var orderDiceRulesetActive: Bool {
        game_ruleset(handle) == DZW_RULESET_ORDER_DICE
    }

    private func currentOrderDieBelongs(to owner: player_t) -> Bool {
        let current = game_current_order_die_view(handle)
        return current.available && current.owner == owner
    }

    private func drawOrderDie(for owner: player_t) -> Bool {
        var attemptsRemaining = Int(game_order_dice_remaining_count(handle)) + 1
        while attemptsRemaining > 0 {
            attemptsRemaining -= 1
            let current = game_current_order_die_view(handle)
            if current.available {
                if current.owner == owner {
                    return true
                }
                if let filler = firstOrderAssignableUnit(owner: current.owner, excluding: [selectedUnitID].compactMap { $0 }) {
                    guard game_assign_order(handle, Int32(filler.id), DZW_ORDER_DOWN) else {
                        return false
                    }
                    continue
                }
                return false
            }
            guard game_draw_order_die(handle) else {
                return false
            }
        }
        return false
    }

    private func orderDiceSnapshot() -> NativeBoardOrderDiceSnapshot {
        NativeBoardOrderDiceSnapshot(
            rulesetActive: game_ruleset(handle) == DZW_RULESET_ORDER_DICE,
            current: Self.orderDieSnapshot(game_current_order_die_view(handle)),
            remaining: orderDiceList(
                count: Int(game_order_dice_remaining_count(handle)),
                view: { game_order_dice_remaining_view(self.handle, Int32($0)) }
            ),
            spent: orderDiceList(
                count: Int(game_order_dice_spent_count(handle)),
                view: { game_order_dice_spent_view(self.handle, Int32($0)) }
            ),
            retained: orderDiceList(
                count: Int(game_order_dice_retained_count(handle)),
                view: { game_order_dice_retained_view(self.handle, Int32($0)) }
            )
        )
    }

    private func orderDiceList(
        count: Int,
        view: (Int) -> order_die_view_t
    ) -> [NativeBoardOrderDieSnapshot] {
        (0..<count).compactMap { Self.orderDieSnapshot(view($0)) }
    }

    private static func orderDieSnapshot(_ view: order_die_view_t) -> NativeBoardOrderDieSnapshot? {
        guard view.available else {
            return nil
        }
        return NativeBoardOrderDieSnapshot(
            sequence: Int(view.sequence),
            owner: NativeBoardPlayer(view.owner)
        )
    }

    private func firstOrderAssignableUnit(owner: player_t, excluding excludedIDs: [Int]) -> unit_view_t? {
        (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { unit in
                unit.owner == owner &&
                    !excludedIDs.contains(Int(unit.id)) &&
                    game_unit_order_eligibility_view(self.handle, unit.id, DZW_ORDER_DOWN).eligible
            }
    }

    private func availableOrders(for unit: unit_view_t) -> [HistoricalBoardOrder] {
        HistoricalBoardOrder.allCases.filter { order in
            game_unit_order_eligibility_view(handle, unit.id, order.cValue).eligible
        }
    }

    private func orderDiceSummary(for unit: unit_view_t) -> String {
        var parts = ["Order \(nativeBoardCString(game_order_name(unit.current_order)))", "\(nativeBoardCString(game_morale_quality_name(unit.morale_quality)))", "Pins \(Int(unit.pin_count))"]
        if unit.retained_order {
            parts.append("Retained")
        }
        if unit.down_order_active {
            parts.append("Down")
        }
        if unit.ambush_order_active {
            parts.append("Ambush")
        }
        if unit.last_order_test_result != DZW_ORDER_TEST_NOT_REQUIRED {
            parts.append(nativeBoardCString(game_order_test_result_name(unit.last_order_test_result)))
        }
        if unit.last_fubar_result != DZW_FUBAR_NONE {
            parts.append(nativeBoardCString(game_fubar_result_name(unit.last_fubar_result)))
        }
        return parts.joined(separator: " | ")
    }

    private func unitView(id: Int) -> unit_view_t? {
        return (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == id }
    }

    private func nearestObjective(to unit: unit_view_t) -> objective_view_t? {
        (0..<Int(game_objective_count(handle))).lazy
            .map { game_objective_view(self.handle, Int32($0)) }
            .min { lhs, rhs in
                distance(from: unit, to: lhs) < distance(from: unit, to: rhs)
            }
    }

    private func priorityObjectives(named priorityNames: [String]) -> [objective_view_t] {
        let objectives = (0..<Int(game_objective_count(handle))).map { game_objective_view(self.handle, Int32($0)) }
        var matches: [objective_view_t] = []
        for priorityName in priorityNames {
            let priority = normalized(priorityName)
            if let objective = objectives.first(where: { objective in
                let name = normalized(nativeBoardCString(objective.name))
                return name.contains(priority) || priority.contains(name)
            }), !matches.contains(where: { $0.id == objective.id }) {
                matches.append(objective)
            }
        }
        return matches
    }

    private func move(_ unit: unit_view_t, toward objective: objective_view_t, maxDistance: Double) -> Bool {
        let dx = Double(objective.x) - Double(unit.x)
        let dy = Double(objective.y) - Double(unit.y)
        let length = max(0.01, sqrt(dx * dx + dy * dy))
        let baseStep = min(maxDistance, length)
        let candidateDistances = [baseStep, baseStep / 2, min(1.5, length), min(0.75, length)]
            .filter { $0 > 0.05 }
        let xDirection = dx == 0 ? 0 : dx / abs(dx)
        let yDirection = dy == 0 ? 0 : dy / abs(dy)

        for distance in candidateDistances {
            let candidates = [
                (
                    Double(unit.x) + (dx / length) * distance,
                    Double(unit.y) + (dy / length) * distance
                ),
                (
                    Double(unit.x) + xDirection * distance,
                    Double(unit.y)
                ),
                (
                    Double(unit.x),
                    Double(unit.y) + yDirection * distance
                ),
            ]

            for candidate in candidates {
                let x = clamp(candidate.0, min: 1, max: loadout.blueprint.engineBoardFrame.width - 1)
                let y = clamp(candidate.1, min: 1, max: loadout.blueprint.engineBoardFrame.height - 1)
                if game_move_unit(handle, Int32(unit.id), Float(x), Float(y)) {
                    lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unitDisplayName(unit)) advanced toward \(nativeBoardCString(objective.name)).")
                    return true
                }
            }
        }
        return failFromEngine("Move blocked")
    }

    private func unitName(id: Int) -> String {
        (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == id }
            .map(unitDisplayName) ?? "Unit \(id)"
    }

    private func unitDisplayName(_ unit: unit_view_t) -> String {
        nativeUnitByEngineID[Int(unit.id)]?.name ?? nativeBoardCString(unit.name)
    }

    private static func nativeUnitMap(handle: OpaquePointer, instance: NativeBattleInstance) -> [Int: NativeBattleUnit] {
        let nativeBySide: [NativeBoardPlayer: [NativeBattleUnit]] = [
            .player: instance.units.filter { $0.side == .player },
            .guderianAI: instance.units.filter { $0.side == .guderianAI },
        ]
        var sideOffsets: [NativeBoardPlayer: Int] = [:]
        var result: [Int: NativeBattleUnit] = [:]

        for index in 0..<Int(game_unit_count(handle)) {
            let unit = game_unit_view(handle, Int32(index))
            let owner = NativeBoardPlayer(unit.owner)
            guard owner == .player || owner == .guderianAI, !unit.destroyed, !unit.embarked else {
                continue
            }
            let offset = sideOffsets[owner, default: 0]
            sideOffsets[owner] = offset + 1
            if let nativeUnit = nativeBySide[owner]?[safe: offset] {
                result[Int(unit.id)] = nativeUnit
            }
        }
        return result
    }

    private func failFromEngine(_ title: String) -> Bool {
        failAction(title, lastEngineError())
    }

    private func failAction(_ title: String, _ detail: String) -> Bool {
        lastAction = NativeBoardActionMessage(status: .blocked, title: title, detail: detail)
        return false
    }

    private func lastEngineError() -> String {
        let error = nativeBoardCString(game_last_error(handle))
        return error.isEmpty ? "The engine rejected the action." : error
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    private func normalized(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension HistoricalBoardOrder {
    init?(_ order: dzw_order_t) {
        switch order {
        case DZW_ORDER_FIRE:
            self = .fire
        case DZW_ORDER_ADVANCE:
            self = .advance
        case DZW_ORDER_RUN:
            self = .run
        case DZW_ORDER_AMBUSH:
            self = .ambush
        case DZW_ORDER_RALLY:
            self = .rally
        case DZW_ORDER_DOWN:
            self = .down
        default:
            return nil
        }
    }

    var cValue: dzw_order_t {
        switch self {
        case .fire:
            return DZW_ORDER_FIRE
        case .advance:
            return DZW_ORDER_ADVANCE
        case .run:
            return DZW_ORDER_RUN
        case .ambush:
            return DZW_ORDER_AMBUSH
        case .rally:
            return DZW_ORDER_RALLY
        case .down:
            return DZW_ORDER_DOWN
        }
    }
}

private func distance(from unit: unit_view_t, to objective: objective_view_t) -> Double {
    let dx = Double(unit.x) - Double(objective.x)
    let dy = Double(unit.y) - Double(objective.y)
    return sqrt(dx * dx + dy * dy)
}

private func distance(from lhs: unit_view_t, to rhs: unit_view_t) -> Double {
    let dx = Double(lhs.x) - Double(rhs.x)
    let dy = Double(lhs.y) - Double(rhs.y)
    return sqrt(dx * dx + dy * dy)
}

private func nativeBoardCString(_ pointer: UnsafePointer<CChar>?) -> String {
    guard let pointer else {
        return ""
    }
    return String(cString: pointer)
}

private func optionalNativeBoardID(_ id: Int32) -> Int? {
    id > 0 ? Int(id) : nil
}

private func vehicleDamageClassName(_ damageClass: dzw_vehicle_damage_class_t) -> String {
    switch damageClass {
    case DZW_VEHICLE_DAMAGE_SUPERFICIAL:
        return "Superficial"
    case DZW_VEHICLE_DAMAGE_FULL:
        return "Full"
    case DZW_VEHICLE_DAMAGE_MASSIVE:
        return "Massive"
    default:
        return "None"
    }
}

private func unitKindName(_ kind: unit_kind_t) -> String {
    switch kind {
    case DZW_UNIT_VEHICLE:
        return "Vehicle"
    case DZW_UNIT_ASSAULT_GUN:
        return "Assault gun"
    default:
        return "Infantry"
    }
}

private func terrainKindName(_ kind: terrain_kind_t) -> String {
    switch kind {
    case DZW_TERRAIN_DIFFICULT:
        return "Difficult"
    case DZW_TERRAIN_IMPASSABLE:
        return "Impassable"
    default:
        return "Open"
    }
}
