import Foundation

public enum HistoricalAutoplayRunState: String, Codable, Hashable, Sendable {
    case ready = "Ready"
    case running = "Running"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"

    public var isTerminal: Bool {
        self == .completed || self == .failed
    }
}

public enum HistoricalAutoplaySpeed: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case inspect = "Inspect"
    case standard = "Standard"
    case fast = "Fast"

    public var id: String {
        rawValue
    }

    public var stepDelayNanoseconds: UInt64 {
        switch self {
        case .inspect:
            return 220_000_000
        case .standard:
            return 45_000_000
        case .fast:
            return 8_000_000
        }
    }
}

public enum HistoricalAutoplayError: Error, CustomStringConvertible, Hashable, Sendable {
    case battleMismatch(expected: String, actual: String)
    case runFailed(String)

    public var description: String {
        switch self {
        case .battleMismatch(let expected, let actual):
            return "Historical autoplay expected battle \(expected), but session opened \(actual)."
        case .runFailed(let message):
            return message
        }
    }
}

public struct HistoricalAutoplayTacticalOrder: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let turnWindow: String
    public let phase: HistoricalBoardPhase
    public let order: HistoricalBoardOrder?
    public let target: String
    public let instruction: String

    public init(
        id: String,
        turnWindow: String,
        phase: HistoricalBoardPhase,
        order: HistoricalBoardOrder? = nil,
        target: String,
        instruction: String
    ) {
        self.id = id
        self.turnWindow = turnWindow
        self.phase = phase
        self.order = order
        self.target = target
        self.instruction = instruction
    }
}

public struct HistoricalAutoplayTacticalPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let armyFamilyName: String
    public let behaviorProfileName: String
    public let strategicGoal: String
    public let targetPriorities: [String]
    public let orders: [HistoricalAutoplayTacticalOrder]

    public init(
        id: String,
        armyFamilyName: String,
        behaviorProfileName: String,
        strategicGoal: String,
        targetPriorities: [String],
        orders: [HistoricalAutoplayTacticalOrder]
    ) {
        self.id = id
        self.armyFamilyName = armyFamilyName
        self.behaviorProfileName = behaviorProfileName
        self.strategicGoal = strategicGoal
        self.targetPriorities = targetPriorities
        self.orders = orders
    }

    public var isPhaseAware: Bool {
        !targetPriorities(for: .movement).isEmpty &&
            !targetPriorities(for: .shooting).isEmpty &&
            !targetPriorities(for: .assault).isEmpty
    }

    public var visibleReasoning: [String] {
        orders.map { "\($0.target): \($0.instruction)" }
    }

    public func targetPriorities(for phase: HistoricalBoardPhase) -> [String] {
        uniqueHistoricalAutoplayNames(
            orders.filter { $0.phase == phase }.map(\.target) + targetPriorities
        )
    }

    public func instruction(for phase: HistoricalBoardPhase) -> String {
        orders.first { $0.phase == phase }?.instruction ?? strategicGoal
    }

    public func preferredOrder(for phase: HistoricalBoardPhase) -> HistoricalBoardOrder? {
        orders.first { $0.phase == phase && $0.order != nil }?.order
    }
}

public struct HistoricalAutoplaySidePlan: Codable, Hashable, Sendable {
    public let sideID: String
    public let controllerLabel: String
    public let movementPriorityNames: [String]
    public let movementDistance: Double
    public let tacticalPlan: HistoricalAutoplayTacticalPlan?

    public init(
        sideID: String,
        controllerLabel: String,
        movementPriorityNames: [String],
        movementDistance: Double = 6,
        tacticalPlan: HistoricalAutoplayTacticalPlan? = nil
    ) {
        self.sideID = sideID
        self.controllerLabel = controllerLabel
        self.movementPriorityNames = movementPriorityNames
        self.movementDistance = movementDistance
        self.tacticalPlan = tacticalPlan
    }

    public func priorityNames(for phase: HistoricalBoardPhase) -> [String] {
        let legacyPriorities = phase == .movement ? movementPriorityNames : []
        guard let tacticalPlan else {
            return legacyPriorities
        }
        return uniqueHistoricalAutoplayNames(tacticalPlan.targetPriorities(for: phase) + legacyPriorities)
    }

    public func priorityTarget(for phase: HistoricalBoardPhase) -> String {
        priorityNames(for: phase).first ?? "nearest legal objective"
    }

    public func priorityInstruction(for phase: HistoricalBoardPhase) -> String {
        guard let tacticalPlan else {
            if phase == .movement && !movementPriorityNames.isEmpty {
                return "Move toward configured scenario objectives before falling back to the nearest legal objective."
            }
            return "Use the nearest legal action while preserving the side's scenario goal."
        }
        return tacticalPlan.instruction(for: phase)
    }

    public func preferredOrder(for phase: HistoricalBoardPhase) -> HistoricalBoardOrder? {
        tacticalPlan?.preferredOrder(for: phase)
    }
}

public struct HistoricalAutoplayOrderDecision: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let order: HistoricalBoardOrder
    public let targetID: Int?
    public let targetName: String?
    public let pathTarget: HistoricalBattleCoordinate?
    public let requiresOrderTest: Bool
    public let respondsToAmbushOrDown: Bool
    public let reason: String

    public init(
        unitID: Int,
        unitName: String,
        order: HistoricalBoardOrder,
        targetID: Int?,
        targetName: String?,
        pathTarget: HistoricalBattleCoordinate?,
        requiresOrderTest: Bool,
        respondsToAmbushOrDown: Bool,
        reason: String
    ) {
        self.unitID = unitID
        self.unitName = unitName
        self.order = order
        self.targetID = targetID
        self.targetName = targetName
        self.pathTarget = pathTarget
        self.requiresOrderTest = requiresOrderTest
        self.respondsToAmbushOrDown = respondsToAmbushOrDown
        self.reason = reason
    }

    public var summary: String {
        let targetText = targetName.map { " toward \($0)" } ?? ""
        let testText = requiresOrderTest ? " after order test" : ""
        let reactionText = respondsToAmbushOrDown ? "; checking Ambush/Down reaction state" : ""
        return "\(order.rawValue) order to \(unitName)\(targetText)\(testText). \(reason)\(reactionText)"
    }
}

public enum HistoricalAutoplayOrderAdvisor {
    public static func decision<ID: HistoricalBattleID>(
        in snapshot: HistoricalBoardSnapshot<ID>,
        sidePlan: HistoricalAutoplaySidePlan
    ) -> HistoricalAutoplayOrderDecision? {
        guard let unit = chooseUnit(in: snapshot) else {
            return nil
        }

        let target = chooseTarget(for: unit, in: snapshot, sidePlan: sidePlan)
        let pathTarget = choosePathTarget(for: unit, in: snapshot, sidePlan: sidePlan)
        let order = chooseOrder(
            for: unit,
            target: target,
            pathTarget: pathTarget,
            in: snapshot,
            sidePlan: sidePlan
        )

        guard let order else {
            return nil
        }

        return HistoricalAutoplayOrderDecision(
            unitID: unit.id,
            unitName: unit.name,
            order: order,
            targetID: target?.id,
            targetName: target?.name,
            pathTarget: pathTarget,
            requiresOrderTest: requiresOrderTest(for: unit, order: order),
            respondsToAmbushOrDown: respondsToAmbushOrDown(for: unit, target: target),
            reason: reason(for: order, unit: unit, target: target, pathTarget: pathTarget, sidePlan: sidePlan, phase: snapshot.phase)
        )
    }

    public static func chooseUnit<ID: HistoricalBattleID>(
        in snapshot: HistoricalBoardSnapshot<ID>
    ) -> HistoricalBoardUnitSnapshot? {
        let candidates = snapshot.units
            .filter { $0.sideID == snapshot.activeSideID && !$0.destroyed && $0.currentOrder == nil && !$0.availableOrders.isEmpty }
            .sorted { lhs, rhs in
                if lhs.pinCount != rhs.pinCount {
                    return lhs.pinCount > rhs.pinCount
                }
                if lhs.selected != rhs.selected {
                    return lhs.selected
                }
                return lhs.id < rhs.id
            }
        return candidates.first
    }

    public static func chooseTarget<ID: HistoricalBattleID>(
        for unit: HistoricalBoardUnitSnapshot,
        in snapshot: HistoricalBoardSnapshot<ID>,
        sidePlan: HistoricalAutoplaySidePlan
    ) -> HistoricalBoardUnitSnapshot? {
        let priorityTokens = sidePlan.priorityNames(for: snapshot.phase).map { $0.lowercased() }
        let enemies = snapshot.units
            .filter { $0.sideID != unit.sideID && !$0.destroyed }
            .sorted { lhs, rhs in
                let lhsPriority = priorityTokens.contains { token in
                    lhs.name.lowercased().contains(token) || lhs.role.lowercased().contains(token)
                }
                let rhsPriority = priorityTokens.contains { token in
                    rhs.name.lowercased().contains(token) || rhs.role.lowercased().contains(token)
                }
                if lhsPriority != rhsPriority {
                    return lhsPriority
                }
                return distance(from: unit.position, to: lhs.position) < distance(from: unit.position, to: rhs.position)
            }
        return enemies.first
    }

    public static func choosePathTarget<ID: HistoricalBattleID>(
        for unit: HistoricalBoardUnitSnapshot,
        in snapshot: HistoricalBoardSnapshot<ID>,
        sidePlan: HistoricalAutoplaySidePlan
    ) -> HistoricalBattleCoordinate? {
        let priorityNames = sidePlan.priorityNames(for: .movement).map { $0.lowercased() }
        if let objective = snapshot.objectives.first(where: { objective in
            priorityNames.contains { objective.name.lowercased().contains($0) }
        }) {
            return objective.location
        }

        return snapshot.objectives
            .sorted { distance(from: unit.position, to: $0.location) < distance(from: unit.position, to: $1.location) }
            .first?
            .location
    }

    public static func chooseOrder<ID: HistoricalBattleID>(
        for unit: HistoricalBoardUnitSnapshot,
        target: HistoricalBoardUnitSnapshot?,
        pathTarget: HistoricalBattleCoordinate?,
        in snapshot: HistoricalBoardSnapshot<ID>,
        sidePlan: HistoricalAutoplaySidePlan
    ) -> HistoricalBoardOrder? {
        let available = Set(unit.availableOrders)

        if unit.pinCount > 0, available.contains(.rally) {
            return .rally
        }

        if let target, target.ambushOrderActive, available.contains(.down) {
            return .down
        }

        if let preferred = sidePlan.preferredOrder(for: snapshot.phase), available.contains(preferred) {
            return preferred
        }

        switch snapshot.phase {
        case .movement:
            if pathTarget != nil, available.contains(.advance) {
                return .advance
            }
            if available.contains(.run) {
                return .run
            }
        case .shooting:
            if target != nil, available.contains(.fire) {
                return .fire
            }
            if target != nil, available.contains(.advance) {
                return .advance
            }
        case .assault:
            if target != nil, available.contains(.run) {
                return .run
            }
        }

        if target == nil, available.contains(.ambush) {
            return .ambush
        }
        if available.contains(.down) {
            return .down
        }

        return unit.availableOrders.first
    }

    public static func requiresOrderTest(
        for unit: HistoricalBoardUnitSnapshot,
        order: HistoricalBoardOrder
    ) -> Bool {
        unit.pinCount > 0 && order != .down
    }

    public static func respondsToAmbushOrDown(
        for unit: HistoricalBoardUnitSnapshot,
        target: HistoricalBoardUnitSnapshot?
    ) -> Bool {
        unit.downOrderActive || unit.ambushOrderActive || target?.downOrderActive == true || target?.ambushOrderActive == true
    }

    private static func reason(
        for order: HistoricalBoardOrder,
        unit: HistoricalBoardUnitSnapshot,
        target: HistoricalBoardUnitSnapshot?,
        pathTarget: HistoricalBattleCoordinate?,
        sidePlan: HistoricalAutoplaySidePlan,
        phase: HistoricalBoardPhase
    ) -> String {
        if unit.pinCount > 0 && order == .rally {
            return "Pinned unit takes Rally before attempting a normal action."
        }
        if order == .down {
            return "Down response protects against the current Ambush or defensive-fire threat."
        }
        if target != nil && (order == .fire || order == .run || order == .advance) {
            return sidePlan.priorityInstruction(for: phase)
        }
        if pathTarget != nil && order == .advance {
            return sidePlan.priorityInstruction(for: phase)
        }
        if order == .ambush {
            return "No immediate target is better than preserving an opportunity-fire posture."
        }
        return sidePlan.priorityInstruction(for: phase)
    }

    private static func distance(
        from lhs: HistoricalBattleCoordinate,
        to rhs: HistoricalBattleCoordinate
    ) -> Double {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt(dx * dx + dy * dy)
    }
}

public struct HistoricalAutoplayConfiguration<ID: HistoricalBattleID>: Codable, Hashable, Sendable {
    public let battleID: ID
    public let battleTitle: String
    public let seed: UInt32
    public let contract: HistoricalAutoplayContract
    public let targetTurnUpperBound: Int
    public let maxPhaseAdvances: Int
    public let sidePlans: [HistoricalAutoplaySidePlan]
    public let persistsDebriefResult: Bool

    public init(
        battleID: ID,
        battleTitle: String,
        seed: UInt32,
        contract: HistoricalAutoplayContract,
        targetTurnUpperBound: Int,
        maxPhaseAdvances: Int? = nil,
        sidePlans: [HistoricalAutoplaySidePlan],
        persistsDebriefResult: Bool = true
    ) {
        self.battleID = battleID
        self.battleTitle = battleTitle
        self.seed = seed
        self.contract = contract
        self.targetTurnUpperBound = targetTurnUpperBound
        self.maxPhaseAdvances = maxPhaseAdvances ?? max(24, targetTurnUpperBound * 8)
        self.sidePlans = sidePlans
        self.persistsDebriefResult = persistsDebriefResult
    }

    public func plan(for sideID: String) -> HistoricalAutoplaySidePlan {
        sidePlans.first { $0.sideID == sideID } ??
            HistoricalAutoplaySidePlan(
                sideID: sideID,
                controllerLabel: "\(sideID) AI",
                movementPriorityNames: []
            )
    }
}

public struct HistoricalAutoplayStep<ID: HistoricalBattleID>: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: ID
    public let turnNumber: Int
    public let activeSideID: String
    public let controllerLabel: String
    public let phase: HistoricalBoardPhase
    public let status: HistoricalBoardActionStatus
    public let title: String
    public let detail: String

    public init(
        id: String,
        battleID: ID,
        turnNumber: Int,
        activeSideID: String,
        controllerLabel: String,
        phase: HistoricalBoardPhase,
        status: HistoricalBoardActionStatus,
        title: String,
        detail: String
    ) {
        self.id = id
        self.battleID = battleID
        self.turnNumber = turnNumber
        self.activeSideID = activeSideID
        self.controllerLabel = controllerLabel
        self.phase = phase
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct HistoricalAutoplayDebriefRecord<ID: HistoricalBattleID>: Identifiable, Codable, Hashable, Sendable {
    public var id: String {
        "\(battleID.rawValue)-debrief-\(seed)"
    }

    public let battleID: ID
    public let battleTitle: String
    public let seed: UInt32
    public let completedTurn: Int
    public let winningSideID: String?
    public let automatedSideIDs: Set<String>
    public let phaseAdvances: Int
    public let blockers: [String]
    public let persistedResult: Bool

    public init(
        battleID: ID,
        battleTitle: String,
        seed: UInt32,
        completedTurn: Int,
        winningSideID: String?,
        automatedSideIDs: Set<String>,
        phaseAdvances: Int,
        blockers: [String],
        persistedResult: Bool
    ) {
        self.battleID = battleID
        self.battleTitle = battleTitle
        self.seed = seed
        self.completedTurn = completedTurn
        self.winningSideID = winningSideID
        self.automatedSideIDs = automatedSideIDs
        self.phaseAdvances = phaseAdvances
        self.blockers = blockers
        self.persistedResult = persistedResult
    }

    public var completedWithoutBlockers: Bool {
        blockers.isEmpty && completedTurn > 0 && persistedResult
    }

    public var summary: String {
        let outcome = winningSideID.map { "winner \($0)" } ?? "no winner"
        return "\(battleTitle) autoplay reached debrief on turn \(completedTurn) with \(outcome) after \(phaseAdvances) phase advances."
    }
}

public struct HistoricalAutoplayReport<ID: HistoricalBattleID>: Codable, Hashable, Sendable {
    public let surfaceName: String
    public let embeddedBattleSurfaceName: String
    public let openingSnapshot: HistoricalBoardSnapshot<ID>
    public let finalSnapshot: HistoricalBoardSnapshot<ID>
    public let debriefRecord: HistoricalAutoplayDebriefRecord<ID>
    public let steps: [HistoricalAutoplayStep<ID>]

    public init(
        surfaceName: String,
        embeddedBattleSurfaceName: String,
        openingSnapshot: HistoricalBoardSnapshot<ID>,
        finalSnapshot: HistoricalBoardSnapshot<ID>,
        debriefRecord: HistoricalAutoplayDebriefRecord<ID>,
        steps: [HistoricalAutoplayStep<ID>]
    ) {
        self.surfaceName = surfaceName
        self.embeddedBattleSurfaceName = embeddedBattleSurfaceName
        self.openingSnapshot = openingSnapshot
        self.finalSnapshot = finalSnapshot
        self.debriefRecord = debriefRecord
        self.steps = steps
    }

    public var completedToDebrief: Bool {
        debriefRecord.completedWithoutBlockers
    }

    public var bothSidesActed: Bool {
        debriefRecord.automatedSideIDs.count >= 2
    }

    public var finalResultSummary: String {
        debriefRecord.summary
    }
}

public final class HistoricalAutoplayRunController<Session: HistoricalBoardSession> {
    public typealias BattleID = Session.BattleID

    public private(set) var session: Session
    public let configuration: HistoricalAutoplayConfiguration<BattleID>
    public private(set) var openingSnapshot: HistoricalBoardSnapshot<BattleID>
    public private(set) var latestSnapshot: HistoricalBoardSnapshot<BattleID>
    public private(set) var runState: HistoricalAutoplayRunState = .ready
    public private(set) var steps: [HistoricalAutoplayStep<BattleID>] = []
    public private(set) var phaseAdvances = 0
    public private(set) var blockers: [String] = []
    public private(set) var lastReport: HistoricalAutoplayReport<BattleID>?

    public init(
        session: Session,
        configuration: HistoricalAutoplayConfiguration<BattleID>
    ) throws {
        guard session.battleID == configuration.battleID else {
            throw HistoricalAutoplayError.battleMismatch(
                expected: configuration.battleID.rawValue,
                actual: session.battleID.rawValue
            )
        }

        self.session = session
        self.configuration = configuration
        openingSnapshot = session.snapshot()
        latestSnapshot = openingSnapshot
    }

    public var maxPhaseAdvances: Int {
        configuration.maxPhaseAdvances
    }

    public var phaseBudgetRemaining: Int {
        max(0, maxPhaseAdvances - phaseAdvances)
    }

    public var phaseProgressFraction: Double {
        guard maxPhaseAdvances > 0 else {
            return 0
        }
        return min(1, Double(phaseAdvances) / Double(maxPhaseAdvances))
    }

    public var canRun: Bool {
        !runState.isTerminal && lastReport == nil
    }

    public var canStep: Bool {
        canRun && runState != .running
    }

    public var automatedSideIDs: Set<String> {
        Set(steps.map(\.activeSideID))
    }

    public func resume() {
        guard canRun else {
            return
        }
        runState = .running
    }

    public func pause() {
        guard runState == .running else {
            return
        }
        runState = .paused
    }

    @discardableResult
    public func stepOnce() throws -> HistoricalAutoplayStep<BattleID>? {
        guard canRun else {
            return steps.last
        }

        let step = try performNextPhase()
        if !runState.isTerminal {
            runState = .paused
        }
        return step
    }

    @discardableResult
    public func runUntilPauseOrDebrief(maxSteps: Int = Int.max) throws -> HistoricalAutoplayReport<BattleID>? {
        guard canRun else {
            return lastReport
        }

        resume()
        var completedSteps = 0
        while runState == .running,
              lastReport == nil,
              completedSteps < maxSteps {
            _ = try performNextPhase()
            completedSteps += 1
        }
        return lastReport
    }

    @discardableResult
    public func runToDebrief() throws -> HistoricalAutoplayReport<BattleID> {
        while lastReport == nil && canRun {
            _ = try runUntilPauseOrDebrief(maxSteps: 1)
        }

        if let lastReport {
            return lastReport
        }

        runState = .failed
        throw HistoricalAutoplayError.runFailed(
            "\(configuration.battleTitle) historical autoplay ended without a debrief report."
        )
    }

    private func performNextPhase() throws -> HistoricalAutoplayStep<BattleID>? {
        if let report = finishIfDebriefable() {
            return report.steps.last
        }

        let before = latestSnapshot
        let step = performActiveAIPhase(before: before, stepIndex: steps.count)
        steps.append(step)
        drainPendingChoices()
        session.advancePhase()
        phaseAdvances += 1
        latestSnapshot = session.snapshot()
        _ = finishIfDebriefable()
        return step
    }

    private func finishIfDebriefable() -> HistoricalAutoplayReport<BattleID>? {
        guard lastReport == nil else {
            return lastReport
        }

        latestSnapshot = session.snapshot()
        let hitPhaseGuard = phaseAdvances >= maxPhaseAdvances
        let reachedTurnLimit = latestSnapshot.turnNumber > configuration.targetTurnUpperBound
        let hasWinner = latestSnapshot.mission.winningSideID != nil

        guard hitPhaseGuard || reachedTurnLimit || hasWinner else {
            return nil
        }

        if hitPhaseGuard {
            appendBlocker("\(configuration.battleTitle) hit the \(maxPhaseAdvances)-phase autoplay guard before debrief.")
        }

        if configuration.contract.requiresBothSidesActed {
            let expectedSideIDs = Set(session.launch.sideBindings.map(\.sideID))
            if !automatedSideIDs.isSuperset(of: expectedSideIDs) {
                appendBlocker("Historical autoplay did not give every launch side an active phase.")
            }
        }

        let persisted = configuration.contract.requiresRealDebriefPersistence
            ? configuration.persistsDebriefResult && blockers.isEmpty
            : true
        let debriefRecord = HistoricalAutoplayDebriefRecord(
            battleID: configuration.battleID,
            battleTitle: configuration.battleTitle,
            seed: configuration.seed,
            completedTurn: latestSnapshot.turnNumber,
            winningSideID: latestSnapshot.mission.winningSideID,
            automatedSideIDs: automatedSideIDs,
            phaseAdvances: phaseAdvances,
            blockers: blockers,
            persistedResult: persisted
        )
        let report = HistoricalAutoplayReport(
            surfaceName: configuration.contract.primarySurfaceName,
            embeddedBattleSurfaceName: configuration.contract.embeddedBattleSurfaceName,
            openingSnapshot: openingSnapshot,
            finalSnapshot: latestSnapshot,
            debriefRecord: debriefRecord,
            steps: steps
        )

        lastReport = report
        runState = blockers.isEmpty ? .completed : .failed
        return report
    }

    private func performActiveAIPhase(
        before snapshot: HistoricalBoardSnapshot<BattleID>,
        stepIndex: Int
    ) -> HistoricalAutoplayStep<BattleID> {
        let sidePlan = configuration.plan(for: snapshot.activeSideID)
        let orderDecision = issueOrderForActiveUnitIfAvailable(snapshot: snapshot, sidePlan: sidePlan)
        let actionSnapshot = session.snapshot()
        let orderDetailPrefix = orderDecision.map { "\($0.summary) " } ?? "No order-dice assignment was available before the compatibility action. "
        let status: HistoricalBoardActionStatus
        let title: String
        let detail: String

        switch snapshot.phase {
        case .movement:
            let moved = moveActiveUnits(snapshot: actionSnapshot, sidePlan: sidePlan)
            let target = sidePlan.priorityTarget(for: snapshot.phase)
            let reason = sidePlan.priorityInstruction(for: snapshot.phase)
            status = moved == 0 ? .blocked : .succeeded
            title = "\(sidePlan.controllerLabel) movement"
            detail = moved == 0 ?
                "\(orderDetailPrefix)No legal movement was available for priority target \(target); fallback to nearest legal objective also failed. Reason: \(reason)" :
                "\(orderDetailPrefix)\(moved) active units moved toward priority target \(target), with nearest legal objective as fallback. Reason: \(reason)"
        case .shooting:
            let shots = shootActiveUnits(snapshot: actionSnapshot)
            let target = sidePlan.priorityTarget(for: snapshot.phase)
            let reason = sidePlan.priorityInstruction(for: snapshot.phase)
            status = shots == 0 ? .blocked : .succeeded
            title = "\(sidePlan.controllerLabel) shooting"
            detail = shots == 0 ?
                "\(orderDetailPrefix)No legal shots were available while protecting priority target \(target). Reason: \(reason)" :
                "\(orderDetailPrefix)\(shots) active units fired at nearest enemies to protect priority target \(target). Reason: \(reason)"
        case .assault:
            let assaults = assaultActiveUnits(snapshot: actionSnapshot)
            let resolved = session.resolveFirstPendingChoice()
            let target = sidePlan.priorityTarget(for: snapshot.phase)
            let reason = sidePlan.priorityInstruction(for: snapshot.phase)
            title = "\(sidePlan.controllerLabel) assault"
            if assaults > 0 {
                status = .succeeded
                detail = "\(orderDetailPrefix)\(assaults) active units assaulted nearest enemies around priority target \(target). Reason: \(reason)"
            } else if resolved {
                status = .succeeded
                detail = "\(orderDetailPrefix)Resolved a pending assault or damage choice around priority target \(target). Reason: \(reason)"
            } else {
                status = .blocked
                detail = "\(orderDetailPrefix)No legal assaults or pending choices were available around priority target \(target). Reason: \(reason)"
            }
        }

        return HistoricalAutoplayStep(
            id: "\(snapshot.battleID.rawValue)-historical-autoplay-step-\(stepIndex)",
            battleID: snapshot.battleID,
            turnNumber: snapshot.turnNumber,
            activeSideID: snapshot.activeSideID,
            controllerLabel: sidePlan.controllerLabel,
            phase: snapshot.phase,
            status: status,
            title: title,
            detail: detail
        )
    }

    private func issueOrderForActiveUnitIfAvailable(
        snapshot: HistoricalBoardSnapshot<BattleID>,
        sidePlan: HistoricalAutoplaySidePlan
    ) -> HistoricalAutoplayOrderDecision? {
        guard let decision = HistoricalAutoplayOrderAdvisor.decision(in: snapshot, sidePlan: sidePlan) else {
            return nil
        }

        session.selectUnit(decision.unitID)
        if let targetID = decision.targetID {
            session.selectTarget(targetID)
        } else {
            session.selectNearestEnemyToSelectedUnit()
        }

        if session.issueOrder(decision.order, to: decision.unitID) {
            drainPendingChoices()
        }

        return decision
    }

    private func moveActiveUnits(
        snapshot: HistoricalBoardSnapshot<BattleID>,
        sidePlan: HistoricalAutoplaySidePlan
    ) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.sideID == snapshot.activeSideID && !$0.destroyed && $0.canMoveNow }
            .sorted { $0.id < $1.id }
        var moved = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            let usedPriority = session.moveSelectedUnitTowardPriorityObjective(
                named: sidePlan.priorityNames(for: .movement),
                maxDistance: sidePlan.movementDistance
            )
            if usedPriority || session.moveSelectedUnitTowardNearestObjective(maxDistance: sidePlan.movementDistance) {
                moved += 1
            }
        }

        return moved
    }

    private func shootActiveUnits(snapshot: HistoricalBoardSnapshot<BattleID>) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.sideID == snapshot.activeSideID && !$0.destroyed && $0.canShootNow }
            .sorted { $0.id < $1.id }
        var shots = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if session.shootSelectedTarget() {
                shots += 1
                drainPendingChoices()
            }
        }

        return shots
    }

    private func assaultActiveUnits(snapshot: HistoricalBoardSnapshot<BattleID>) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.sideID == snapshot.activeSideID && !$0.destroyed && $0.canAssaultNow }
            .sorted { $0.id < $1.id }
        var assaults = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            guard let target = session.snapshot().units.first(where: { $0.targeted && !$0.destroyed }) else {
                continue
            }
            if session.assaultUnit(unit.id, targetID: target.id, advance: true) {
                assaults += 1
                drainPendingChoices()
            }
        }

        return assaults
    }

    private func drainPendingChoices() {
        for _ in 0..<16 {
            let before = session.snapshot()
            guard session.resolveFirstPendingChoice() else {
                return
            }
            let after = session.snapshot()
            steps.append(
                HistoricalAutoplayStep(
                    id: "\(before.battleID.rawValue)-historical-autoplay-step-\(steps.count)",
                    battleID: before.battleID,
                    turnNumber: before.turnNumber,
                    activeSideID: before.activeSideID,
                    controllerLabel: configuration.plan(for: before.activeSideID).controllerLabel,
                    phase: before.phase,
                    status: after.lastAction.status,
                    title: after.lastAction.title,
                    detail: after.lastAction.detail
                )
            )
        }
    }

    private func appendBlocker(_ blocker: String) {
        if !blockers.contains(blocker) {
            blockers.append(blocker)
        }
    }
}

private func uniqueHistoricalAutoplayNames(_ values: [String]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for value in values {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmed.lowercased()
        guard !trimmed.isEmpty, !seen.contains(key) else {
            continue
        }
        seen.insert(key)
        result.append(trimmed)
    }
    return result
}
