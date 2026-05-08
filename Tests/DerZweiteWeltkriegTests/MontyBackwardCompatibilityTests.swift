import SwiftUI
@testable import DerZweiteWeltkriegHistorical
import XCTest

private enum MontyBackwardCompatibilityBattleID: String, Codable, Hashable, Sendable, HistoricalBattleID {
    case alamElHalfa
}

final class MontyBackwardCompatibilityTests: XCTestCase {
    func testMontyBackwardcompatibilityPublishesConcreteSharedBattleSurface() {
        let contract = HistoricalPlayableSurfaceCatalog.dzwStyleBattleSurface
        let requiredIdentifiers: Set<String> = [
            "battle-screen",
            "battle-board",
            "battle-sidebar",
            "battle-side-selector",
            "battle-action-feedback",
            "battle-forces",
            "battle-objectives",
            "battle-terrain-summary",
            "battle-log",
            "battle-next-phase-button",
            "battle-ai-turn-button",
            "battle-debrief-panel",
            "battle-persisted-result",
        ]

        XCTAssertEqual(HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName, "HistoricalPlayableBattleView")
        XCTAssertEqual(HistoricalPlayableSurfaceCatalog.publicSwiftUISurfaceName, "HistoricalPlayableBattleView")
        XCTAssertTrue(HistoricalPlayableSurfaceCatalog.hasPublicSwiftUIBattleSurface)
        XCTAssertEqual(contract.hostSurfaceName, HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName)
        XCTAssertTrue(contract.coversFullBattleFlow)
        XCTAssertTrue(contract.hasBoardAndSidebarComponents)
        XCTAssertTrue(Set(contract.requiredAccessibilityIdentifiers).isSuperset(of: requiredIdentifiers))
        XCTAssertTrue(contract.retiredGameSpecificSurfaceNames.contains("DZWPlayableBattleView"))
        XCTAssertTrue(contract.retiredGameSpecificSurfaceNames.contains("NativeBattleBoardView"))
    }

    func testMontyBackwardcompatibilityKeepsGuderianBoardInteractionAndReadabilityProfiles() throws {
        let snapshot = MontyBackwardCompatibilityFixtures.snapshot()
        let activeUnit = try XCTUnwrap(snapshot.units.first { $0.sideID == snapshot.activeSideID && !$0.destroyed })
        let opposingUnit = try XCTUnwrap(snapshot.units.first { $0.sideID != snapshot.activeSideID && !$0.destroyed })
        let destroyedUnit = try XCTUnwrap(snapshot.units.first { $0.destroyed })
        let interaction = HistoricalPlayableSurfaceCatalog.boardInteractionProfile
        let readability = HistoricalPlayableSurfaceCatalog.boardReadabilityProfile
        let viewport = HistoricalPlayableSurfaceCatalog.boardViewportProfile
        let audit = HistoricalBoardLayoutResolver.readabilityAudit(for: snapshot)

        XCTAssertTrue(interaction.supportsGuderianStyleBoardCommands)
        XCTAssertEqual(interaction.resolverName, "HistoricalBoardInteractionResolver")
        XCTAssertEqual(
            HistoricalBoardInteractionResolver.unitTapIntent(for: activeUnit, in: snapshot),
            .selectUnit(activeUnit.id)
        )
        XCTAssertEqual(
            HistoricalBoardInteractionResolver.unitTapIntent(for: opposingUnit, in: snapshot),
            .selectTarget(opposingUnit.id)
        )
        XCTAssertEqual(
            HistoricalBoardInteractionResolver.unitTapIntent(for: destroyedUnit, in: snapshot),
            .ignored
        )
        XCTAssertEqual(HistoricalBoardSelectionIntent.selectUnit(activeUnit.id).unitID, activeUnit.id)
        XCTAssertEqual(HistoricalBoardSelectionIntent.selectTarget(opposingUnit.id).unitID, opposingUnit.id)
        XCTAssertNil(HistoricalBoardSelectionIntent.clearSelection.unitID)
        XCTAssertTrue(readability.preventsDenseAlwaysOnBoardText)
        XCTAssertEqual(readability.directBoardNameLabelCount, 0)
        XCTAssertFalse(readability.terrainNamesDrawnDirectlyOnBoard)
        XCTAssertFalse(readability.objectiveNamesDrawnDirectlyOnBoard)
        XCTAssertFalse(readability.unitNamesDrawnDirectlyOnBoard)
        XCTAssertTrue(readability.usesIDOnlyUnitTokens)
        XCTAssertTrue(readability.hasSidebarDetailDisclosure)
        XCTAssertTrue(viewport.isCriticalViewportReady)
        XCTAssertLessThanOrEqual(viewport.desktopMaxBoardHeight, 420)
        XCTAssertLessThanOrEqual(viewport.compactMaxBoardHeight, 380)
        XCTAssertTrue(audit.passesCriticalReadabilityGate)
        XCTAssertEqual(audit.directBoardNameLabelCount, 0)
        XCTAssertEqual(audit.estimatedOverlappingTokenPairs, 0)
    }

    func testMontyBackwardcompatibilityOffsetsClusteredBoardTokens() {
        let snapshot = MontyBackwardCompatibilityFixtures.snapshot(clustered: true)
        let slots = HistoricalBoardLayoutResolver.resolvedUnitSlots(for: snapshot)
        let coordinates = Set(slots.map(\.coordinate))
        let offsetIndexes = Set(slots.map(\.offsetIndex))
        let audit = HistoricalBoardLayoutResolver.readabilityAudit(for: snapshot)

        XCTAssertEqual(slots.count, 4)
        XCTAssertEqual(Set(slots.map(\.id)), Set([1, 2, 3, 4]))
        XCTAssertEqual(coordinates.count, slots.count)
        XCTAssertEqual(offsetIndexes.count, slots.count)
        XCTAssertEqual(audit.unitCount, 4)
        XCTAssertEqual(audit.estimatedOverlappingTokenPairs, 0)
        XCTAssertTrue(audit.passesCriticalReadabilityGate)
    }

    func testMontyBackwardcompatibilityScenarioLaunchAndSnapshotsStayCodable() throws {
        let scenario = MontyBackwardCompatibilityFixtures.scenario()
        let launch = try MontyBackwardCompatibilityFixtures.launch()
        let snapshot = MontyBackwardCompatibilityFixtures.snapshot()

        XCTAssertTrue(scenario.hasTwoPlayableSides)
        XCTAssertEqual(scenario.sideOptions.map(\.id), ["montgomery", "opposition"])
        XCTAssertEqual(launch.battleID, .alamElHalfa)
        XCTAssertEqual(launch.humanBinding?.sideID, "montgomery")
        XCTAssertEqual(launch.humanBinding?.enginePlayerSlot, .playerOne)
        XCTAssertEqual(launch.aiBinding?.sideID, "opposition")
        XCTAssertEqual(launch.aiBinding?.enginePlayerSlot, .playerTwo)

        let encodedScenario = try JSONEncoder().encode(scenario)
        let decodedScenario = try JSONDecoder().decode(
            HistoricalBattleScenario<MontyBackwardCompatibilityBattleID>.self,
            from: encodedScenario
        )
        let encodedLaunch = try JSONEncoder().encode(launch)
        let decodedLaunch = try JSONDecoder().decode(
            HistoricalBattleLaunch<MontyBackwardCompatibilityBattleID>.self,
            from: encodedLaunch
        )
        let encodedSnapshot = try JSONEncoder().encode(snapshot)
        let decodedSnapshot = try JSONDecoder().decode(
            HistoricalBoardSnapshot<MontyBackwardCompatibilityBattleID>.self,
            from: encodedSnapshot
        )

        XCTAssertEqual(decodedScenario, scenario)
        XCTAssertEqual(decodedLaunch, launch)
        XCTAssertEqual(decodedSnapshot, snapshot)
    }

    func testMontyBackwardcompatibilitySessionProtocolSupportsMontyCommandSet() throws {
        let session = try MontyBackwardCompatibilityBoardSession()

        try Self.driveMontyCommandSet(session)

        let latest = session.snapshot()
        XCTAssertEqual(latest.lastAction.status, .succeeded)
        XCTAssertTrue(latest.log.contains { $0.contains("Resolved") })
    }

    func testMontyBackwardcompatibilityAutoplayContractAndControllerReachDebrief() throws {
        let configuration = MontyBackwardCompatibilityFixtures.autoplayConfiguration()
        let session = try MontyBackwardCompatibilityBoardSession()
        let controller = try HistoricalAutoplayRunController(
            session: session,
            configuration: configuration
        )

        XCTAssertEqual(configuration.contract.embeddedBattleSurfaceName, HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName)
        XCTAssertEqual(configuration.contract.speedModes, ["Inspect", "Standard", "Fast"])
        XCTAssertTrue(configuration.contract.supportsDeterministicSeed)
        XCTAssertTrue(configuration.contract.isFirstBattleAutoplayContract)
        XCTAssertEqual(configuration.plan(for: "montgomery").controllerLabel, "Montgomery AI")
        XCTAssertEqual(HistoricalAutoplaySpeed.allCases.map(\.rawValue), configuration.contract.speedModes)
        XCTAssertTrue(HistoricalAutoplayRunState.completed.isTerminal)
        XCTAssertFalse(HistoricalAutoplayRunState.paused.isTerminal)

        let report = try controller.runToDebrief()

        XCTAssertEqual(controller.runState, .completed)
        XCTAssertTrue(report.completedToDebrief, report.debriefRecord.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.bothSidesActed)
        XCTAssertTrue(report.debriefRecord.automatedSideIDs.isSuperset(of: ["montgomery", "opposition"]))
        XCTAssertEqual(report.surfaceName, "MontyTestFirstBattleAutoplayView")
        XCTAssertEqual(report.embeddedBattleSurfaceName, HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName)
        XCTAssertEqual(report.finalSnapshot.mission.winningSideID, "montgomery")
        XCTAssertTrue(report.finalResultSummary.contains("Battle of Alam el Halfa"))
        XCTAssertLessThanOrEqual(report.debriefRecord.phaseAdvances, controller.maxPhaseAdvances)
    }

    @MainActor
    func testMontyBackwardcompatibilityCanInstantiateSharedSwiftUIViewWithMontyCallbacks() {
        let snapshot = MontyBackwardCompatibilityFixtures.snapshot()
        let debrief = HistoricalPlayableDebriefSummary(
            title: "Historical pressure",
            summary: "Monty persisted the shared battle result.",
            scoreLine: "8 VP | Turn 2"
        )

        let view = HistoricalPlayableBattleView(
            battleTitle: "Battle of Alam el Halfa",
            selectedSideTitle: "Montgomery command",
            opposingSideTitle: "Opposing command",
            snapshot: snapshot,
            debrief: debrief,
            onSelectReadyUnit: {},
            onSelectNearestEnemy: {},
            onSelectUnit: { _ in },
            onSelectTarget: { _ in },
            onClearSelection: {},
            onMove: {},
            onShoot: {},
            onAssault: {},
            onResolvePending: {},
            onNextPhase: {},
            onAITurn: {},
            onRestart: {},
            onRunToDebrief: {}
        )

        XCTAssertTrue(String(describing: type(of: view)).contains("HistoricalPlayableBattleView"))
        XCTAssertEqual(debrief.persistedResultIdentifier, "battle-persisted-result")
    }

    private static func driveMontyCommandSet<Session: HistoricalBoardSession>(_ session: Session) throws {
        let opening = session.snapshot()
        let activeUnit = try XCTUnwrap(opening.units.first { $0.sideID == opening.activeSideID && !$0.destroyed })
        let opposingUnit = try XCTUnwrap(opening.units.first { $0.sideID != opening.activeSideID && !$0.destroyed })

        session.selectUnit(activeUnit.id)
        session.selectTarget(opposingUnit.id)
        session.selectFirstActiveUnit()
        session.selectNearestEnemyToSelectedUnit()
        XCTAssertTrue(session.moveSelectedUnitTowardPriorityObjective(named: ["Alam el Halfa ridge"], maxDistance: 4))
        XCTAssertTrue(session.moveSelectedUnitTowardNearestObjective(maxDistance: 3))
        XCTAssertTrue(session.moveUnit(activeUnit.id, to: HistoricalBattleCoordinate(x: 44, y: 24)))
        XCTAssertTrue(session.rotateUnit(activeUnit.id, to: 135))
        XCTAssertTrue(session.toggleCover(for: activeUnit.id, enabled: true))
        XCTAssertTrue(session.toggleHullDown(for: activeUnit.id, enabled: true))

        session.advancePhase()
        session.selectUnit(activeUnit.id)
        session.selectTarget(opposingUnit.id)
        XCTAssertTrue(session.shootSelectedTarget())
        XCTAssertTrue(session.shootUnit(activeUnit.id, targetID: opposingUnit.id))

        session.advancePhase()
        XCTAssertTrue(session.assaultUnit(activeUnit.id, targetID: opposingUnit.id, advance: true))
        XCTAssertTrue(session.resolveFirstPendingChoice())
    }
}

private enum MontyBackwardCompatibilityFixtures {
    static func scenario() -> HistoricalBattleScenario<MontyBackwardCompatibilityBattleID> {
        HistoricalBattleScenario(
            id: .alamElHalfa,
            order: 1,
            title: "Battle of Alam el Halfa",
            dateLabel: "30 Aug-5 Sep 1942",
            theater: "North Africa",
            status: .demoPlayable,
            historicalResult: "British victory",
            designIntent: "Pin the public historical contracts Monty uses for its demo battle host.",
            sourceLinks: [
                HistoricalSourceLink(
                    title: "Battle of Alam el Halfa",
                    url: "https://en.wikipedia.org/wiki/Battle_of_Alam_el_Halfa"
                ),
            ],
            sideOptions: [
                HistoricalSideOption(
                    id: "montgomery",
                    role: .protagonist,
                    title: "Montgomery's Eighth Army",
                    historicalForce: "British Eighth Army",
                    commander: "Bernard Montgomery",
                    armyListName: "British",
                    playerBriefing: "Hold the ridge and break the Axis attack.",
                    aiBriefing: "Defend ridge objectives and preserve anti-tank lanes."
                ),
                HistoricalSideOption(
                    id: "opposition",
                    role: .opponent,
                    title: "Opposing command",
                    historicalForce: "Axis desert force",
                    commander: "Erwin Rommel",
                    armyListName: "German",
                    playerBriefing: "Probe the ridge before fuel and time expire.",
                    aiBriefing: "Pressure minefields and ridge approaches."
                ),
            ],
            map: HistoricalBattleMap(
                title: "Alam el Halfa Ridge",
                elements: [
                    HistoricalMapElement(
                        id: "ridge",
                        name: "Alam el Halfa ridge",
                        kind: .ridge,
                        points: [
                            HistoricalBattleCoordinate(x: 18, y: 24),
                            HistoricalBattleCoordinate(x: 78, y: 22),
                        ],
                        note: "Primary defensive line."
                    ),
                ],
                deploymentZones: [
                    HistoricalDeploymentZone(
                        id: "montgomery-start",
                        sideID: "montgomery",
                        name: "Eighth Army boxes",
                        origin: HistoricalBattleCoordinate(x: 18, y: 18),
                        width: 28,
                        height: 18,
                        note: "Prepared defensive boxes."
                    ),
                    HistoricalDeploymentZone(
                        id: "opposition-start",
                        sideID: "opposition",
                        name: "Opposing approach",
                        origin: HistoricalBattleCoordinate(x: 2, y: 34),
                        width: 24,
                        height: 16,
                        note: "Southern approach lanes."
                    ),
                ]
            ),
            objectives: [
                HistoricalObjective(
                    id: "ridge-control",
                    name: "Hold Alam el Halfa ridge",
                    sideID: "montgomery",
                    victoryPoints: 8,
                    location: HistoricalBattleCoordinate(x: 52, y: 24),
                    radius: 5,
                    description: "Keep opposing armour off the ridge."
                ),
            ],
            victory: HistoricalVictoryProfile(
                targetScore: 8,
                targetTurnUpperBound: 1,
                bands: [
                    HistoricalVictoryBand(
                        id: "historical-pressure",
                        label: "Historical pressure",
                        scoreRange: 0...7,
                        summary: "The ridge defense stays contested."
                    ),
                    HistoricalVictoryBand(
                        id: "monty-success",
                        label: "Monty success",
                        scoreRange: 8...12,
                        summary: "Montgomery holds the ridge."
                    ),
                ]
            ),
            tags: ["montyBackwardcompatibility"]
        )
    }

    static func launch() throws -> HistoricalBattleLaunch<MontyBackwardCompatibilityBattleID> {
        try HistoricalBattleLaunchResolver.makeLaunch(
            scenario: scenario(),
            chosenHumanSideID: "montgomery",
            seed: 1942
        )
    }

    static func autoplayConfiguration() -> HistoricalAutoplayConfiguration<MontyBackwardCompatibilityBattleID> {
        HistoricalAutoplayConfiguration(
            battleID: .alamElHalfa,
            battleTitle: "Battle of Alam el Halfa",
            seed: 1942,
            contract: HistoricalAutoplayContract(
                primarySurfaceName: "MontyTestFirstBattleAutoplayView",
                retiredEmbeddedSurfaceNames: ["MontyPrototypeBattleView"],
                requiredAccessibilityIdentifiers: [
                    "monty-test-first-battle-autoplay",
                    "monty-test-run-to-debrief-button",
                    "monty-test-step-button",
                    "monty-test-pause-button",
                    "monty-test-speed-picker",
                    "monty-test-safety-cap",
                    "monty-test-event-log",
                    "monty-test-result-summary",
                ]
            ),
            targetTurnUpperBound: 1,
            maxPhaseAdvances: 12,
            sidePlans: [
                HistoricalAutoplaySidePlan(
                    sideID: "montgomery",
                    controllerLabel: "Montgomery AI",
                    movementPriorityNames: ["Alam el Halfa ridge"],
                    movementDistance: 4
                ),
                HistoricalAutoplaySidePlan(
                    sideID: "opposition",
                    controllerLabel: "Opposition AI",
                    movementPriorityNames: ["Alam el Halfa ridge"],
                    movementDistance: 4
                ),
            ]
        )
    }

    static func snapshot(
        clustered: Bool = false,
        turnNumber: Int = 1,
        activeSideID: String = "montgomery",
        phase: HistoricalBoardPhase = .movement,
        winningSideID: String? = nil,
        selectedUnitID: Int? = 1,
        targetedUnitID: Int? = 2
    ) -> HistoricalBoardSnapshot<MontyBackwardCompatibilityBattleID> {
        HistoricalBoardSnapshot(
            battleID: .alamElHalfa,
            turnNumber: turnNumber,
            activeSideID: activeSideID,
            phase: phase,
            mission: HistoricalBoardMissionSnapshot(
                name: "Alam el Halfa ridge",
                targetScore: 8,
                humanScore: winningSideID == "montgomery" ? 8 : 3,
                aiScore: 2,
                winningSideID: winningSideID
            ),
            units: clustered ? clusteredUnits(activeSideID: activeSideID) : standardUnits(
                activeSideID: activeSideID,
                phase: phase,
                selectedUnitID: selectedUnitID,
                targetedUnitID: targetedUnitID
            ),
            zones: [
                HistoricalBoardZoneSnapshot(
                    id: 1,
                    name: "Alam el Halfa ridge",
                    kind: .ridge,
                    origin: HistoricalBattleCoordinate(x: 18, y: 22),
                    width: 60,
                    height: 6,
                    blocksLineOfSight: true
                ),
            ],
            objectives: [
                HistoricalBoardObjectiveSnapshot(
                    id: 1,
                    name: "Hold Alam el Halfa ridge",
                    location: HistoricalBattleCoordinate(x: 52, y: 24),
                    radius: 5,
                    controllingSideID: "montgomery"
                ),
            ],
            lastAction: HistoricalBoardActionMessage(
                status: .idle,
                title: "Ready",
                detail: "Monty compatibility board session is ready."
            ),
            log: ["Monty compatibility snapshot opened."]
        )
    }

    private static func standardUnits(
        activeSideID: String,
        phase: HistoricalBoardPhase,
        selectedUnitID: Int?,
        targetedUnitID: Int?
    ) -> [HistoricalBoardUnitSnapshot] {
        [
            unit(
                id: 1,
                sideID: "montgomery",
                name: "6-pounder anti-tank screen",
                kind: "Gun",
                role: "Anti-tank lane",
                position: HistoricalBattleCoordinate(x: 42, y: 22),
                facingDegrees: 180,
                activeSideID: activeSideID,
                phase: phase,
                selectedUnitID: selectedUnitID,
                targetedUnitID: targetedUnitID
            ),
            unit(
                id: 2,
                sideID: "opposition",
                name: "Panzer probe",
                kind: "Armour",
                role: "Flank probe",
                position: HistoricalBattleCoordinate(x: 28, y: 34),
                facingDegrees: 0,
                activeSideID: activeSideID,
                phase: phase,
                selectedUnitID: selectedUnitID,
                targetedUnitID: targetedUnitID
            ),
            unit(
                id: 3,
                sideID: "opposition",
                name: "Disabled scout car",
                kind: "Armour",
                role: "Destroyed screen",
                position: HistoricalBattleCoordinate(x: 12, y: 52),
                facingDegrees: 0,
                destroyed: true,
                activeSideID: activeSideID,
                phase: phase,
                selectedUnitID: selectedUnitID,
                targetedUnitID: targetedUnitID
            ),
        ]
    }

    private static func clusteredUnits(activeSideID: String) -> [HistoricalBoardUnitSnapshot] {
        [
            unit(
                id: 1,
                sideID: "montgomery",
                name: "Rifle company",
                kind: "Infantry",
                role: "Ridge defense",
                position: HistoricalBattleCoordinate(x: 40, y: 24),
                facingDegrees: 180,
                activeSideID: activeSideID,
                phase: .movement
            ),
            unit(
                id: 2,
                sideID: "opposition",
                name: "Forward panzer troop",
                kind: "Armour",
                role: "Probe",
                position: HistoricalBattleCoordinate(x: 40, y: 24),
                facingDegrees: 0,
                activeSideID: activeSideID,
                phase: .movement
            ),
            unit(
                id: 3,
                sideID: "montgomery",
                name: "Anti-tank reserve",
                kind: "Gun",
                role: "Reserve",
                position: HistoricalBattleCoordinate(x: 40, y: 24),
                facingDegrees: 180,
                activeSideID: activeSideID,
                phase: .movement
            ),
            unit(
                id: 4,
                sideID: "opposition",
                name: "Armoured cars",
                kind: "Armour",
                role: "Screen",
                position: HistoricalBattleCoordinate(x: 40, y: 24),
                facingDegrees: 0,
                activeSideID: activeSideID,
                phase: .movement
            ),
        ]
    }

    private static func unit(
        id: Int,
        sideID: String,
        name: String,
        kind: String,
        role: String,
        position: HistoricalBattleCoordinate,
        facingDegrees: Double,
        destroyed: Bool = false,
        activeSideID: String,
        phase: HistoricalBoardPhase,
        selectedUnitID: Int? = nil,
        targetedUnitID: Int? = nil
    ) -> HistoricalBoardUnitSnapshot {
        HistoricalBoardUnitSnapshot(
            id: id,
            sideID: sideID,
            name: name,
            kind: kind,
            role: role,
            position: position,
            facingDegrees: facingDegrees,
            destroyed: destroyed,
            canMoveNow: !destroyed && sideID == activeSideID && phase == .movement,
            canShootNow: !destroyed && sideID == activeSideID && phase == .shooting,
            canAssaultNow: !destroyed && sideID == activeSideID && phase == .assault,
            selected: id == selectedUnitID,
            targeted: id == targetedUnitID
        )
    }
}

private final class MontyBackwardCompatibilityBoardSession: HistoricalBoardSession {
    let battleID = MontyBackwardCompatibilityBattleID.alamElHalfa
    let launch: HistoricalBattleLaunch<MontyBackwardCompatibilityBattleID>

    private var turnNumber = 1
    private var activeSideID = "montgomery"
    private var phase = HistoricalBoardPhase.movement
    private var winningSideID: String?
    private var selectedUnitID: Int?
    private var selectedTargetID: Int?
    private var pendingChoices = 0
    private var lastAction = HistoricalBoardActionMessage(
        status: .idle,
        title: "Ready",
        detail: "Monty compatibility session is ready."
    )
    private var log = ["Monty compatibility session opened."]

    init() throws {
        launch = try MontyBackwardCompatibilityFixtures.launch()
    }

    func snapshot() -> HistoricalBoardSnapshot<MontyBackwardCompatibilityBattleID> {
        var snapshot = MontyBackwardCompatibilityFixtures.snapshot(
            turnNumber: turnNumber,
            activeSideID: activeSideID,
            phase: phase,
            winningSideID: winningSideID,
            selectedUnitID: selectedUnitID,
            targetedUnitID: selectedTargetID
        )

        snapshot = HistoricalBoardSnapshot(
            battleID: snapshot.battleID,
            turnNumber: snapshot.turnNumber,
            activeSideID: snapshot.activeSideID,
            phase: snapshot.phase,
            mission: snapshot.mission,
            units: snapshot.units,
            zones: snapshot.zones,
            objectives: snapshot.objectives,
            lastAction: lastAction,
            log: log
        )
        return snapshot
    }

    func selectUnit(_ id: Int) {
        selectedUnitID = id
        record(status: .succeeded, title: "Selected", detail: "Selected unit \(id).")
    }

    func selectTarget(_ id: Int) {
        selectedTargetID = id
        record(status: .succeeded, title: "Targeted", detail: "Targeted unit \(id).")
    }

    func selectFirstActiveUnit() {
        selectUnit(activeSideID == "montgomery" ? 1 : 2)
    }

    func selectNearestEnemyToSelectedUnit() {
        let selectedSide = selectedUnitID == 2 ? "opposition" : "montgomery"
        selectTarget(selectedSide == "montgomery" ? 2 : 1)
    }

    func moveSelectedUnitTowardNearestObjective(maxDistance: Double) -> Bool {
        moveSelectedUnitTowardPriorityObjective(named: ["Alam el Halfa ridge"], maxDistance: maxDistance)
    }

    func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double) -> Bool {
        guard selectedUnitID != nil, !priorityNames.isEmpty, maxDistance > 0 else {
            record(status: .blocked, title: "Move", detail: "No Monty-compatible movement target was available.")
            return false
        }

        record(status: .succeeded, title: "Moved", detail: "Moved toward \(priorityNames[0]).")
        return true
    }

    func moveUnit(_ id: Int, to point: HistoricalBattleCoordinate) -> Bool {
        selectedUnitID = id
        record(status: .succeeded, title: "Moved", detail: "Moved unit \(id) to \(point.x),\(point.y).")
        return true
    }

    func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool {
        selectedUnitID = id
        record(status: .succeeded, title: "Rotated", detail: "Rotated unit \(id) to \(facingDegrees).")
        return true
    }

    func toggleCover(for id: Int, enabled: Bool) -> Bool {
        record(status: .succeeded, title: "Cover", detail: "Updated cover for unit \(id).")
        return true
    }

    func toggleHullDown(for id: Int, enabled: Bool) -> Bool {
        record(status: .succeeded, title: "Hull down", detail: "Updated hull-down for unit \(id).")
        return true
    }

    func shootUnit(_ attackerID: Int, targetID: Int) -> Bool {
        selectedUnitID = attackerID
        selectedTargetID = targetID
        pendingChoices += 1
        record(status: .succeeded, title: "Shot", detail: "Unit \(attackerID) fired at unit \(targetID).")
        return true
    }

    func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool) -> Bool {
        selectedUnitID = attackerID
        selectedTargetID = targetID
        pendingChoices += 1
        record(status: .succeeded, title: "Assaulted", detail: "Unit \(attackerID) assaulted unit \(targetID).")
        return true
    }

    func shootSelectedTarget() -> Bool {
        guard let selectedUnitID, let selectedTargetID else {
            record(status: .blocked, title: "Shot", detail: "Select an attacker and target before shooting.")
            return false
        }

        return shootUnit(selectedUnitID, targetID: selectedTargetID)
    }

    func resolveFirstPendingChoice() -> Bool {
        guard pendingChoices > 0 else {
            return false
        }

        pendingChoices -= 1
        record(status: .succeeded, title: "Resolved", detail: "Resolved the first pending choice.")
        return true
    }

    func advancePhase() {
        switch phase {
        case .movement:
            phase = .shooting
        case .shooting:
            phase = .assault
        case .assault:
            phase = .movement
            if activeSideID == "montgomery" {
                activeSideID = "opposition"
            } else {
                activeSideID = "montgomery"
                turnNumber += 1
                winningSideID = "montgomery"
            }
        }

        selectedUnitID = nil
        selectedTargetID = nil
        record(status: .succeeded, title: "Advanced", detail: "Advanced to \(activeSideID) \(phase.rawValue).")
    }

    private func record(status: HistoricalBoardActionStatus, title: String, detail: String) {
        lastAction = HistoricalBoardActionMessage(status: status, title: title, detail: detail)
        log.append("\(title): \(detail)")
    }
}
