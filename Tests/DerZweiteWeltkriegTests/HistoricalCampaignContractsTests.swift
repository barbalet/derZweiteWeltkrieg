import DerZweiteWeltkriegCore
@testable import DerZweiteWeltkriegHistorical
import SwiftUI
import XCTest

private enum DemoHistoricalBattleID: String, Codable, Hashable, Sendable, HistoricalBattleID {
    case alamElHalfa
}

final class HistoricalCampaignContractsTests: XCTestCase {
    func testHistoricalScenarioRequiresTwoSelectableSides() throws {
        let scenario = Self.makeDemoScenario()

        XCTAssertEqual(scenario.sideOptions.count, 2)
        XCTAssertTrue(scenario.hasTwoPlayableSides)
        XCTAssertEqual(Set(scenario.sideOptions.map(\.role)), Set([.protagonist, .opponent]))
        XCTAssertEqual(scenario.sideOptions[0].title, "Montgomery's Eighth Army")
        XCTAssertEqual(scenario.sideOptions[1].title, "Panzerarmee Afrika")
    }

    func testSideSelectionBindsHumanToPlayerOneByDefault() throws {
        let scenario = Self.makeDemoScenario()
        let launch = try HistoricalBattleLaunchResolver.makeLaunch(
            scenario: scenario,
            chosenHumanSideID: "montgomery",
            seed: 42
        )

        XCTAssertEqual(launch.battleID, .alamElHalfa)
        XCTAssertEqual(launch.seed, 42)
        XCTAssertEqual(launch.humanBinding?.sideID, "montgomery")
        XCTAssertEqual(launch.humanBinding?.enginePlayerSlot, .playerOne)
        XCTAssertEqual(launch.humanBinding?.enginePlayerSlot.enginePlayer, DZW_PLAYER_ONE)
        XCTAssertEqual(launch.aiBinding?.sideID, "axis")
        XCTAssertEqual(launch.aiBinding?.enginePlayerSlot, .playerTwo)
        XCTAssertEqual(launch.aiBinding?.enginePlayerSlot.enginePlayer, DZW_PLAYER_TWO)
    }

    func testSideSelectionCanPutOpposingArmyUnderHumanControl() throws {
        let scenario = Self.makeDemoScenario()
        let launch = try HistoricalBattleLaunchResolver.makeLaunch(
            scenario: scenario,
            chosenHumanSideID: "axis",
            seed: 99
        )

        XCTAssertEqual(launch.chosenHumanSideID, "axis")
        XCTAssertEqual(launch.humanBinding?.sideID, "axis")
        XCTAssertEqual(launch.humanBinding?.enginePlayerSlot, .playerOne)
        XCTAssertEqual(launch.aiBinding?.sideID, "montgomery")
        XCTAssertEqual(launch.aiBinding?.enginePlayerSlot, .playerTwo)
    }

    func testResolvedSideSelectionExposesSharedSelectedAndOpposingSides() throws {
        let scenario = Self.makeDemoScenario()
        let launch = try HistoricalBattleLaunchResolver.makeLaunch(
            scenario: scenario,
            chosenHumanSideID: "axis",
            seed: 99,
            humanSlot: .playerTwo
        )
        let selection = scenario.resolvedSideSelection(for: launch)

        XCTAssertEqual(selection.selectedSide?.id, "axis")
        XCTAssertEqual(selection.opposingSide?.id, "montgomery")
        XCTAssertEqual(selection.selectedSideTitle, "Panzerarmee Afrika")
        XCTAssertEqual(selection.opposingSideTitle, "Montgomery's Eighth Army")
        XCTAssertEqual(selection.humanEnginePlayerSlot, .playerTwo)
        XCTAssertEqual(selection.aiEnginePlayerSlot, .playerOne)
        XCTAssertEqual(launch.humanSideID, "axis")
        XCTAssertEqual(launch.aiSideID, "montgomery")
        XCTAssertEqual(launch.enginePlayerSlot(for: "axis"), .playerTwo)
        XCTAssertEqual(launch.controller(for: "montgomery"), .ai)
    }

    @MainActor
    func testSharedSidePickerBuildsDropdownFromHistoricalScenarioOptions() {
        let scenario = Self.makeDemoScenario()
        let picker = HistoricalBattleSidePicker(
            scenario: scenario,
            selectedSideID: .constant("montgomery")
        )

        XCTAssertEqual(HistoricalBattleSidePickerDefaults.title, "Play as")
        XCTAssertEqual(HistoricalBattleSidePickerDefaults.accessibilityIdentifier, "battle-side-selector")
        XCTAssertEqual(HistoricalBattleSidePickerDefaults.optionAccessibilityIDPrefix, "battle-side-option")
        XCTAssertEqual(scenario.sideOptions.map(\.id), ["montgomery", "axis"])
        XCTAssertTrue(String(describing: type(of: picker)).contains("HistoricalBattleSidePicker"))
    }

    func testSideSelectionRejectsUnknownSideIDs() throws {
        let scenario = Self.makeDemoScenario()

        XCTAssertThrowsError(
            try HistoricalBattleLaunchResolver.makeLaunch(
                scenario: scenario,
                chosenHumanSideID: "unknown",
                seed: 12
            )
        ) { error in
            XCTAssertEqual(error as? HistoricalSideSelectionError, .unknownSide("unknown"))
        }
    }

    func testSharedPlayableSurfaceContractCoversDZWStyleBattleFlow() {
        let contract = HistoricalPlayableSurfaceCatalog.dzwStyleBattleSurface

        XCTAssertEqual(contract.hostSurfaceName, "HistoricalPlayableBattleView")
        XCTAssertTrue(contract.coversFullBattleFlow)
        XCTAssertTrue(contract.hasBoardAndSidebarComponents)
        XCTAssertTrue(contract.requiredStages.contains(.sideSelection))
        XCTAssertTrue(contract.requiredStages.contains(.aiTurn))
        XCTAssertTrue(contract.requiredStages.contains(.debrief))
        XCTAssertTrue(contract.requiredAccessibilityIdentifiers.contains("battle-side-selector"))
        XCTAssertTrue(contract.requiredAccessibilityIdentifiers.contains("battle-board"))
        XCTAssertTrue(contract.retiredGameSpecificSurfaceNames.contains("DZWPlayableBattleView"))
        XCTAssertTrue(contract.retiredGameSpecificSurfaceNames.contains("NativeBattleBoardView"))
    }

    func testSharedPlayableSurfaceProfilesRequireDirectBoardInteractionAndReadableLabels() throws {
        let interaction = HistoricalPlayableSurfaceCatalog.boardInteractionProfile
        let readability = HistoricalPlayableSurfaceCatalog.boardReadabilityProfile
        let viewport = HistoricalPlayableSurfaceCatalog.boardViewportProfile
        let session = try DemoHistoricalBoardSession()
        let snapshot = session.snapshot()
        let activeUnit = try XCTUnwrap(snapshot.units.first { $0.sideID == snapshot.activeSideID })
        let opposingUnit = try XCTUnwrap(snapshot.units.first { $0.sideID != snapshot.activeSideID })
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
        XCTAssertTrue(readability.preventsDenseAlwaysOnBoardText)
        XCTAssertFalse(readability.terrainNamesDrawnDirectlyOnBoard)
        XCTAssertFalse(readability.objectiveNamesDrawnDirectlyOnBoard)
        XCTAssertFalse(readability.unitNamesDrawnDirectlyOnBoard)
        XCTAssertTrue(readability.usesIDOnlyUnitTokens)
        XCTAssertTrue(readability.hasSidebarDetailDisclosure)
        XCTAssertTrue(viewport.isCriticalViewportReady)
        XCTAssertTrue(audit.passesCriticalReadabilityGate)
        XCTAssertEqual(audit.directBoardNameLabelCount, 0)
        XCTAssertEqual(audit.estimatedOverlappingTokenPairs, 0)
    }

    func testHistoricalAutoplayContractCapturesMontyTestShape() {
        let contract = HistoricalAutoplayContract(
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
        )

        XCTAssertEqual(contract.embeddedBattleSurfaceName, "HistoricalPlayableBattleView")
        XCTAssertEqual(contract.retiredEmbeddedSurfaceNames, ["MontyPrototypeBattleView"])
        XCTAssertEqual(contract.speedModes, ["Inspect", "Standard", "Fast"])
        XCTAssertTrue(contract.isFirstBattleAutoplayContract)
    }

    func testHistoricalAutoplayRunControllerStepsSharedBoardActions() throws {
        let session = try AutoplayDemoHistoricalBoardSession()
        let controller = try HistoricalAutoplayRunController(
            session: session,
            configuration: Self.makeDemoAutoplayConfiguration()
        )
        let opening = controller.latestSnapshot

        XCTAssertEqual(controller.runState, .ready)
        XCTAssertTrue(controller.canStep)

        let firstStep = try controller.stepOnce()

        XCTAssertEqual(firstStep?.battleID, .alamElHalfa)
        XCTAssertEqual(firstStep?.activeSideID, opening.activeSideID)
        XCTAssertEqual(firstStep?.phase, .movement)
        XCTAssertEqual(firstStep?.status, .succeeded)
        XCTAssertEqual(controller.runState, .paused)
        XCTAssertEqual(controller.phaseAdvances, 1)
        XCTAssertLessThanOrEqual(controller.phaseProgressFraction, 1)
        XCTAssertGreaterThan(controller.phaseBudgetRemaining, 0)
    }

    func testHistoricalAutoplayRunControllerCompletesToDebriefWithBothSidesActing() throws {
        let session = try AutoplayDemoHistoricalBoardSession()
        let controller = try HistoricalAutoplayRunController(
            session: session,
            configuration: Self.makeDemoAutoplayConfiguration()
        )

        let report = try controller.runToDebrief()

        XCTAssertEqual(controller.runState, .completed)
        XCTAssertTrue(report.completedToDebrief, report.debriefRecord.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.bothSidesActed)
        XCTAssertTrue(report.debriefRecord.automatedSideIDs.isSuperset(of: ["montgomery", "axis"]))
        XCTAssertEqual(report.debriefRecord.winningSideID, "montgomery")
        XCTAssertEqual(report.surfaceName, "MontyTestFirstBattleAutoplayView")
        XCTAssertEqual(report.embeddedBattleSurfaceName, HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName)
        XCTAssertTrue(report.finalResultSummary.contains("Battle of Alam el Halfa"))
        XCTAssertLessThanOrEqual(report.debriefRecord.phaseAdvances, controller.maxPhaseAdvances)
    }

    func testHistoricalBoardSessionProtocolSupportsGenericSnapshotAndActions() throws {
        let session = try DemoHistoricalBoardSession()
        let opening = session.snapshot()

        XCTAssertEqual(opening.battleID, .alamElHalfa)
        XCTAssertEqual(opening.activeSideID, "montgomery")
        XCTAssertEqual(opening.phase, .movement)
        XCTAssertEqual(opening.units.count, 2)

        session.selectUnit(1)
        XCTAssertTrue(session.moveSelectedUnitTowardPriorityObjective(named: ["Alam el Halfa ridge"], maxDistance: 4))
        XCTAssertTrue(session.shootSelectedTarget())
        session.advancePhase()

        let latest = session.snapshot()
        XCTAssertEqual(latest.lastAction.status, .succeeded)
        XCTAssertEqual(latest.phase, .shooting)
        XCTAssertTrue(latest.log.contains { $0.contains("advanced") })
    }

    func testHistoricalScenarioBoardHookMigrationKeepsGuderianCompatibility() {
        let migration = HistoricalScenarioBoardHookCatalog.currentGuderianToHistoricalMigration

        XCTAssertTrue(migration.isGenericMigrationReady)
        XCTAssertEqual(migration.legacyGuardMacroName, "HEINZ_GUDERIAN_GAME")
        XCTAssertEqual(migration.legacyFunctionName, "game_apply_guderian_scenario_board")
        XCTAssertEqual(migration.genericFunctionName, "game_apply_historical_scenario_board")
        XCTAssertTrue(migration.keepsLegacyCompatibilityWrapper)
    }

    fileprivate static func makeDemoScenario() -> HistoricalBattleScenario<DemoHistoricalBattleID> {
        HistoricalBattleScenario(
            id: .alamElHalfa,
            order: 1,
            title: "Battle of Alam el Halfa",
            dateLabel: "30 Aug-5 Sep 1942",
            theater: "North Africa",
            status: .demoPlayable,
            historicalResult: "British victory",
            designIntent: "Prepared ridge defense against an Axis outflanking attack.",
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
                    playerBriefing: "Hold the ridge and absorb the Axis attack.",
                    aiBriefing: "Defend ridge objectives and preserve anti-tank lanes."
                ),
                HistoricalSideOption(
                    id: "axis",
                    role: .opponent,
                    title: "Panzerarmee Afrika",
                    historicalForce: "German and Italian Panzer Army Africa",
                    commander: "Erwin Rommel",
                    armyListName: "German",
                    playerBriefing: "Find a flank route before fuel and time expire.",
                    aiBriefing: "Probe minefields and pressure the ridge."
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
                        id: "axis-start",
                        sideID: "axis",
                        name: "Axis approach",
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
                    victoryPoints: 5,
                    location: HistoricalBattleCoordinate(x: 52, y: 24),
                    radius: 5,
                    description: "Keep Axis armour off the ridge."
                ),
            ],
            victory: HistoricalVictoryProfile(
                targetScore: 8,
                targetTurnUpperBound: 8,
                bands: [
                    HistoricalVictoryBand(
                        id: "historical",
                        label: "Historical pressure",
                        scoreRange: 0...3,
                        summary: "The battle follows a near historical shape."
                    ),
                    HistoricalVictoryBand(
                        id: "decisive",
                        label: "Decisive result",
                        scoreRange: 8...12,
                        summary: "The selected side changes the operational tempo."
                    ),
                ]
            )
        )
    }

    fileprivate static func makeDemoAutoplayConfiguration() -> HistoricalAutoplayConfiguration<DemoHistoricalBattleID> {
        HistoricalAutoplayConfiguration(
            battleID: .alamElHalfa,
            battleTitle: "Battle of Alam el Halfa",
            seed: 77,
            contract: HistoricalAutoplayContract(
                primarySurfaceName: "MontyTestFirstBattleAutoplayView",
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
            targetTurnUpperBound: 8,
            maxPhaseAdvances: 24,
            sidePlans: [
                HistoricalAutoplaySidePlan(
                    sideID: "montgomery",
                    controllerLabel: "Montgomery AI",
                    movementPriorityNames: ["Alam el Halfa ridge"],
                    movementDistance: 4
                ),
                HistoricalAutoplaySidePlan(
                    sideID: "axis",
                    controllerLabel: "Axis AI",
                    movementPriorityNames: ["Southern approach"],
                    movementDistance: 6
                ),
            ]
        )
    }
}

private final class DemoHistoricalBoardSession: HistoricalBoardSession {
    let battleID = DemoHistoricalBattleID.alamElHalfa
    let launch: HistoricalBattleLaunch<DemoHistoricalBattleID>

    private var phase = HistoricalBoardPhase.movement
    private var lastAction = HistoricalBoardActionMessage(status: .idle, title: "Ready", detail: "Demo session ready.")
    private var log = ["Demo session opened."]

    init() throws {
        launch = try HistoricalBattleLaunchResolver.makeLaunch(
            scenario: HistoricalCampaignContractsTests.makeDemoScenario(),
            chosenHumanSideID: "montgomery",
            seed: 77
        )
    }

    func snapshot() -> HistoricalBoardSnapshot<DemoHistoricalBattleID> {
        HistoricalBoardSnapshot(
            battleID: battleID,
            turnNumber: 1,
            activeSideID: "montgomery",
            phase: phase,
            mission: HistoricalBoardMissionSnapshot(
                name: "Alam el Halfa ridge",
                targetScore: 8,
                humanScore: 0,
                aiScore: 0
            ),
            units: [
                HistoricalBoardUnitSnapshot(
                    id: 1,
                    sideID: "montgomery",
                    name: "6-pounder anti-tank screen",
                    kind: "Gun",
                    role: "Anti-tank lane",
                    position: HistoricalBattleCoordinate(x: 42, y: 22),
                    facingDegrees: 180,
                    canMoveNow: true,
                    canShootNow: true,
                    selected: true
                ),
                HistoricalBoardUnitSnapshot(
                    id: 2,
                    sideID: "axis",
                    name: "Panzer probe",
                    kind: "Vehicle",
                    role: "Flank probe",
                    position: HistoricalBattleCoordinate(x: 28, y: 34),
                    facingDegrees: 0,
                    targeted: true
                ),
            ],
            zones: [],
            objectives: [
                HistoricalBoardObjectiveSnapshot(
                    id: 1,
                    name: "Alam el Halfa ridge",
                    location: HistoricalBattleCoordinate(x: 52, y: 24),
                    radius: 5,
                    controllingSideID: "montgomery"
                ),
            ],
            lastAction: lastAction,
            log: log
        )
    }

    func selectUnit(_ id: Int) {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Selected", detail: "Selected unit \(id).")
    }

    func selectTarget(_ id: Int) {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Targeted", detail: "Targeted unit \(id).")
    }

    func selectFirstActiveUnit() {
        selectUnit(1)
    }

    func selectNearestEnemyToSelectedUnit() {
        selectTarget(2)
    }

    func moveSelectedUnitTowardNearestObjective(maxDistance: Double) -> Bool {
        moveSelectedUnitTowardPriorityObjective(named: ["Alam el Halfa ridge"], maxDistance: maxDistance)
    }

    func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double) -> Bool {
        lastAction = HistoricalBoardActionMessage(
            status: .succeeded,
            title: "Moved",
            detail: "Moved toward \(priorityNames.first ?? "objective") up to \(maxDistance)."
        )
        log.append(lastAction.detail)
        return true
    }

    func moveUnit(_ id: Int, to point: HistoricalBattleCoordinate) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Moved", detail: "Moved unit \(id).")
        return true
    }

    func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Rotated", detail: "Rotated unit \(id).")
        return true
    }

    func toggleCover(for id: Int, enabled: Bool) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Cover", detail: "Updated cover for \(id).")
        return true
    }

    func toggleHullDown(for id: Int, enabled: Bool) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Hull down", detail: "Updated hull-down for \(id).")
        return true
    }

    func shootUnit(_ attackerID: Int, targetID: Int) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Shot", detail: "Unit \(attackerID) fired at \(targetID).")
        log.append(lastAction.detail)
        return true
    }

    func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .blocked, title: "Assault blocked", detail: "No assault range.")
        return false
    }

    func shootSelectedTarget() -> Bool {
        shootUnit(1, targetID: 2)
    }

    func resolveFirstPendingChoice() -> Bool {
        false
    }

    func advancePhase() {
        phase = .shooting
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Phase advanced", detail: "Battle advanced to shooting.")
        log.append(lastAction.detail)
    }
}

private final class AutoplayDemoHistoricalBoardSession: HistoricalBoardSession {
    let battleID = DemoHistoricalBattleID.alamElHalfa
    let launch: HistoricalBattleLaunch<DemoHistoricalBattleID>

    private var turnNumber = 1
    private var activeSideID = "montgomery"
    private var phase = HistoricalBoardPhase.movement
    private var winningSideID: String?
    private var selectedUnitID: Int?
    private var selectedTargetID: Int?
    private var lastAction = HistoricalBoardActionMessage(status: .idle, title: "Ready", detail: "Autoplay demo ready.")
    private var log = ["Autoplay demo opened."]

    init() throws {
        launch = try HistoricalBattleLaunchResolver.makeLaunch(
            scenario: HistoricalCampaignContractsTests.makeDemoScenario(),
            chosenHumanSideID: "montgomery",
            seed: 77
        )
    }

    func snapshot() -> HistoricalBoardSnapshot<DemoHistoricalBattleID> {
        HistoricalBoardSnapshot(
            battleID: battleID,
            turnNumber: turnNumber,
            activeSideID: activeSideID,
            phase: phase,
            mission: HistoricalBoardMissionSnapshot(
                name: "Alam el Halfa ridge",
                targetScore: 8,
                humanScore: activeSideID == "montgomery" ? 4 : 3,
                aiScore: activeSideID == "axis" ? 4 : 2,
                winningSideID: winningSideID
            ),
            units: [
                unit(
                    id: 1,
                    sideID: "montgomery",
                    name: "6-pounder anti-tank screen",
                    position: HistoricalBattleCoordinate(x: 42, y: 22)
                ),
                unit(
                    id: 2,
                    sideID: "axis",
                    name: "Panzer probe",
                    position: HistoricalBattleCoordinate(x: 28, y: 34)
                ),
            ],
            zones: [],
            objectives: [
                HistoricalBoardObjectiveSnapshot(
                    id: 1,
                    name: activeSideID == "axis" ? "Southern approach" : "Alam el Halfa ridge",
                    location: HistoricalBattleCoordinate(x: 52, y: 24),
                    radius: 5,
                    controllingSideID: winningSideID ?? "montgomery"
                ),
            ],
            lastAction: lastAction,
            log: log
        )
    }

    func selectUnit(_ id: Int) {
        selectedUnitID = id
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Selected", detail: "Selected unit \(id).")
    }

    func selectTarget(_ id: Int) {
        selectedTargetID = id
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Targeted", detail: "Targeted unit \(id).")
    }

    func selectFirstActiveUnit() {
        selectUnit(activeSideID == "montgomery" ? 1 : 2)
    }

    func selectNearestEnemyToSelectedUnit() {
        selectTarget(activeSideID == "montgomery" ? 2 : 1)
    }

    func moveSelectedUnitTowardNearestObjective(maxDistance: Double) -> Bool {
        moveSelectedUnitTowardPriorityObjective(named: ["nearest objective"], maxDistance: maxDistance)
    }

    func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double) -> Bool {
        guard selectedUnitID != nil else {
            return false
        }
        lastAction = HistoricalBoardActionMessage(
            status: .succeeded,
            title: "Moved",
            detail: "\(activeSideID) moved toward \(priorityNames.first ?? "objective")."
        )
        log.append(lastAction.detail)
        return true
    }

    func moveUnit(_ id: Int, to point: HistoricalBattleCoordinate) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Moved", detail: "Moved unit \(id).")
        return true
    }

    func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Rotated", detail: "Rotated unit \(id).")
        return true
    }

    func toggleCover(for id: Int, enabled: Bool) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Cover", detail: "Updated cover for \(id).")
        return true
    }

    func toggleHullDown(for id: Int, enabled: Bool) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Hull down", detail: "Updated hull-down for \(id).")
        return true
    }

    func shootUnit(_ attackerID: Int, targetID: Int) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Shot", detail: "Unit \(attackerID) fired at \(targetID).")
        log.append(lastAction.detail)
        return true
    }

    func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool) -> Bool {
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Assault", detail: "Unit \(attackerID) assaulted \(targetID).")
        log.append(lastAction.detail)
        return true
    }

    func shootSelectedTarget() -> Bool {
        guard let selectedUnitID, let selectedTargetID else {
            return false
        }
        return shootUnit(selectedUnitID, targetID: selectedTargetID)
    }

    func resolveFirstPendingChoice() -> Bool {
        false
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
                activeSideID = "axis"
            } else {
                activeSideID = "montgomery"
                turnNumber += 1
                winningSideID = "montgomery"
            }
        }
        selectedUnitID = nil
        selectedTargetID = nil
        lastAction = HistoricalBoardActionMessage(status: .succeeded, title: "Phase advanced", detail: "Battle advanced to \(phase.rawValue).")
        log.append(lastAction.detail)
    }

    private func unit(
        id: Int,
        sideID: String,
        name: String,
        position: HistoricalBattleCoordinate
    ) -> HistoricalBoardUnitSnapshot {
        HistoricalBoardUnitSnapshot(
            id: id,
            sideID: sideID,
            name: name,
            kind: sideID == "axis" ? "Vehicle" : "Gun",
            role: sideID == "axis" ? "Flank probe" : "Anti-tank lane",
            position: position,
            facingDegrees: sideID == "axis" ? 0 : 180,
            canMoveNow: phase == .movement && activeSideID == sideID,
            canShootNow: phase == .shooting && activeSideID == sideID,
            canAssaultNow: phase == .assault && activeSideID == sideID,
            selected: selectedUnitID == id,
            targeted: selectedTargetID == id
        )
    }
}
