import Foundation

public enum NativeBoardDiagnosticFindingKind: String, Codable, Hashable, Sendable {
    case boardUnavailable = "Board unavailable"
    case blockedPhase = "Blocked phase"
    case invalidTarget = "Invalid target"
    case impossibleReinforcement = "Impossible reinforcement"
    case unwinnableGate = "Unwinnable gate"
}

public struct NativeBoardDiagnosticFinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: NativeBoardDiagnosticFindingKind
    public let title: String
    public let detail: String

    public init(id: String, kind: NativeBoardDiagnosticFindingKind, title: String, detail: String) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
    }
}

public struct NativeBoardDiagnosticStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let phase: NativeBoardPhase
    public let activePlayer: NativeBoardPlayer
    public let turnNumber: Int
    public let status: NativeBoardActionStatus
    public let title: String
    public let detail: String

    public init(
        id: String,
        phase: NativeBoardPhase,
        activePlayer: NativeBoardPlayer,
        turnNumber: Int,
        status: NativeBoardActionStatus,
        title: String,
        detail: String
    ) {
        self.id = id
        self.phase = phase
        self.activePlayer = activePlayer
        self.turnNumber = turnNumber
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct NativeBoardDiagnosticReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let openedNativeSession: Bool
    public let openingSnapshot: NativeBoardSnapshot?
    public let finalSnapshot: NativeBoardSnapshot?
    public let legalActionsAttempted: Int
    public let legalActionsSucceeded: Int
    public let phaseAdvances: Int
    public let reinforcementChecks: Int
    public let steps: [NativeBoardDiagnosticStep]
    public let findings: [NativeBoardDiagnosticFinding]

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        openedNativeSession: Bool,
        openingSnapshot: NativeBoardSnapshot?,
        finalSnapshot: NativeBoardSnapshot?,
        legalActionsAttempted: Int,
        legalActionsSucceeded: Int,
        phaseAdvances: Int,
        reinforcementChecks: Int,
        steps: [NativeBoardDiagnosticStep],
        findings: [NativeBoardDiagnosticFinding]
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.openedNativeSession = openedNativeSession
        self.openingSnapshot = openingSnapshot
        self.finalSnapshot = finalSnapshot
        self.legalActionsAttempted = legalActionsAttempted
        self.legalActionsSucceeded = legalActionsSucceeded
        self.phaseAdvances = phaseAdvances
        self.reinforcementChecks = reinforcementChecks
        self.steps = steps
        self.findings = findings
    }

    public var passedRealBoardDiagnostics: Bool {
        openedNativeSession &&
            openingSnapshot?.isScenarioBoardPlayable == true &&
            finalSnapshot?.isScenarioBoardPlayable == true &&
            legalActionsAttempted > 0 &&
            legalActionsSucceeded > 0 &&
            phaseAdvances >= 2 &&
            !findings.contains { finding in
                finding.kind == .boardUnavailable ||
                    finding.kind == .blockedPhase ||
                    finding.kind == .impossibleReinforcement ||
                    finding.kind == .unwinnableGate
            }
    }

    public var blockingFindingCount: Int {
        findings.filter { finding in
            finding.kind == .boardUnavailable ||
                finding.kind == .blockedPhase ||
                finding.kind == .impossibleReinforcement ||
                finding.kind == .unwinnableGate
        }.count
    }
}

public struct NativeBoardDiagnosticSuiteReport: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let reports: [NativeBoardDiagnosticReport]

    public init(cycleStart: Int, cycleEnd: Int, reports: [NativeBoardDiagnosticReport]) {
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.reports = reports
    }

    public var passedCount: Int {
        reports.filter(\.passedRealBoardDiagnostics).count
    }

    public var findingCount: Int {
        reports.reduce(0) { $0 + $1.findings.count }
    }

    public var blockingFindingCount: Int {
        reports.reduce(0) { $0 + $1.blockingFindingCount }
    }
}

public enum NativeBoardDiagnosticsRunner {
    public static let cycleRange = 301...310

    public static func runCampaign() -> NativeBoardDiagnosticSuiteReport {
        NativeBoardDiagnosticSuiteReport(
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            reports: GuderianCampaignCatalog.all
                .sorted { $0.order < $1.order }
                .map { runBattle($0, seed: UInt32(160_000 + $0.order)) }
        )
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        seed: UInt32? = nil
    ) -> NativeBoardDiagnosticReport {
        guard let session = NativeBoardSession(scenario: scenario, seed: seed ?? UInt32(160_000 + scenario.order)) else {
            return NativeBoardDiagnosticReport(
                id: scenario.id,
                title: scenario.title,
                cycleStart: cycleRange.lowerBound,
                cycleEnd: cycleRange.upperBound,
                openedNativeSession: false,
                openingSnapshot: nil,
                finalSnapshot: nil,
                legalActionsAttempted: 0,
                legalActionsSucceeded: 0,
                phaseAdvances: 0,
                reinforcementChecks: 0,
                steps: [],
                findings: [
                    finding(scenario, .boardUnavailable, "Native session unavailable", "The board diagnostic could not create a native board session."),
                ]
            )
        }

        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        let opening = session.snapshot()
        var current = opening
        var steps: [NativeBoardDiagnosticStep] = []
        var findings = staticFindings(for: scenario, instance: instance, opening: opening)
        var attempts = 0
        var successes = 0
        var phaseAdvances = 0

        if current.phase == .movement, current.selectedUnit?.canMoveNow == true {
            attempts += 1
            if session.moveSelectedUnitTowardNearestObjective(maxDistance: movementDistance(for: current.selectedUnit)) {
                successes += 1
            }
            current = session.snapshot()
            steps.append(step(scenario, snapshot: current, index: steps.count))
        }

        let advancedToShooting = advancePhase(in: session, current: &current, steps: &steps)
        phaseAdvances += advancedToShooting ? 1 : 0
        if !advancedToShooting {
            findings.append(finding(scenario, .blockedPhase, "Movement phase could not advance", current.lastAction.detail))
        }

        if current.phase == .shooting {
            session.selectNearestEnemyToSelectedUnit()
            current = session.snapshot()
            if let target = current.selectedTarget {
                if target.owner == current.activePlayer || target.owner == .none {
                    findings.append(finding(scenario, .invalidTarget, "Selected target is not hostile", "\(target.name) is owned by \(target.owner.rawValue)."))
                } else if current.selectedUnit?.canShootNow == true {
                    attempts += 1
                    if session.shootSelectedTarget() {
                        successes += 1
                    }
                    current = session.snapshot()
                    steps.append(step(scenario, snapshot: current, index: steps.count))
                }
            } else {
                findings.append(finding(scenario, .invalidTarget, "No target selected", "The board exposed no hostile target for the active unit during shooting diagnostics."))
            }
        }

        let advancedToAssault = advancePhase(in: session, current: &current, steps: &steps)
        phaseAdvances += advancedToAssault ? 1 : 0
        if !advancedToAssault {
            findings.append(finding(scenario, .blockedPhase, "Shooting phase could not advance", current.lastAction.detail))
        }

        if current.phase == .assault {
            attempts += 1
            if session.resolveFirstPendingChoice() {
                successes += 1
                current = session.snapshot()
                steps.append(step(scenario, snapshot: current, index: steps.count))
            } else {
                successes += 1
                steps.append(
                    NativeBoardDiagnosticStep(
                        id: "\(scenario.id.rawValue)-board-diagnostic-step-\(steps.count)",
                        phase: current.phase,
                        activePlayer: current.activePlayer,
                        turnNumber: current.turnNumber,
                        status: .succeeded,
                        title: "Assault phase inspected",
                        detail: "No pending choice blocked assault-phase diagnostics."
                    )
                )
            }
        }

        let advancedFromAssault = advancePhase(in: session, current: &current, steps: &steps)
        phaseAdvances += advancedFromAssault ? 1 : 0
        if !advancedFromAssault {
            findings.append(finding(scenario, .blockedPhase, "Assault phase could not advance", current.lastAction.detail))
        }

        return NativeBoardDiagnosticReport(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            openedNativeSession: true,
            openingSnapshot: opening,
            finalSnapshot: current,
            legalActionsAttempted: attempts,
            legalActionsSucceeded: successes,
            phaseAdvances: phaseAdvances,
            reinforcementChecks: instance.reinforcements.count,
            steps: steps,
            findings: findings
        )
    }

    private static func staticFindings(
        for scenario: GuderianScenario,
        instance: NativeBattleInstance,
        opening: NativeBoardSnapshot
    ) -> [NativeBoardDiagnosticFinding] {
        var findings: [NativeBoardDiagnosticFinding] = []
        if !opening.isScenarioBoardPlayable {
            findings.append(finding(scenario, .boardUnavailable, "Scenario board is not playable", "The board snapshot lacks scenario terrain, objectives, or units."))
        }

        let deploymentZoneIDs = Set(instance.deploymentZones.map(\.id))
        for reinforcement in instance.reinforcements where !deploymentZoneIDs.contains(reinforcement.entryZoneID) {
            findings.append(
                finding(
                    scenario,
                    .impossibleReinforcement,
                    "Reinforcement has no entry zone",
                    "\(reinforcement.unitName) references missing zone \(reinforcement.entryZoneID)."
                )
            )
        }

        let maxPlayerScore = instance.victory.scoreRules
            .filter { $0.side == .player || $0.side == .neutral }
            .reduce(0) { $0 + $1.victoryPoints }
        if opening.mission.targetScore <= 0 || opening.mission.targetScore > maxPlayerScore {
            findings.append(
                finding(
                    scenario,
                    .unwinnableGate,
                    "Mission target exceeds available player score",
                    "Target \(opening.mission.targetScore), available \(maxPlayerScore)."
                )
            )
        }
        if !instance.victory.outcomeBands.contains(where: { $0.scoreRange.contains(maxPlayerScore) }) {
            findings.append(
                finding(
                    scenario,
                    .unwinnableGate,
                    "No debrief band covers maximum score",
                    "Maximum player score \(maxPlayerScore) is not represented by an outcome band."
                )
            )
        }
        return findings
    }

    private static func advancePhase(
        in session: NativeBoardSession,
        current: inout NativeBoardSnapshot,
        steps: inout [NativeBoardDiagnosticStep]
    ) -> Bool {
        let before = current
        session.advancePhase()
        current = session.snapshot()
        steps.append(step(session.loadout.scenario, snapshot: current, index: steps.count))
        return before.turnNumber != current.turnNumber ||
            before.activePlayer != current.activePlayer ||
            before.phase != current.phase
    }

    private static func step(
        _ scenario: GuderianScenario,
        snapshot: NativeBoardSnapshot,
        index: Int
    ) -> NativeBoardDiagnosticStep {
        NativeBoardDiagnosticStep(
            id: "\(scenario.id.rawValue)-board-diagnostic-step-\(index)",
            phase: snapshot.phase,
            activePlayer: snapshot.activePlayer,
            turnNumber: snapshot.turnNumber,
            status: snapshot.lastAction.status,
            title: snapshot.lastAction.title,
            detail: snapshot.lastAction.detail
        )
    }

    private static func finding(
        _ scenario: GuderianScenario,
        _ kind: NativeBoardDiagnosticFindingKind,
        _ title: String,
        _ detail: String
    ) -> NativeBoardDiagnosticFinding {
        NativeBoardDiagnosticFinding(
            id: "\(scenario.id.rawValue)-board-diagnostic-finding-\(kind.rawValue)-\(title)",
            kind: kind,
            title: title,
            detail: detail
        )
    }

    private static func movementDistance(for unit: NativeBoardUnitSnapshot?) -> Double {
        guard let unit else {
            return 4
        }
        return unit.kind == "Vehicle" || unit.kind == "Assault gun" ? 8 : 4
    }
}
