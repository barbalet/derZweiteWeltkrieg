import DerZweiteWeltkriegCore
import DerZweiteWeltkriegHistorical
@testable import DerZweiteWeltkriegGuderian
import XCTest

final class DerZweiteWeltkriegGuderianGameplayTests: XCTestCase {
    func testGuderianScenarioAdaptsToSharedHistoricalScenarioContract() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let historical = GuderianHistoricalScenarioAdapter.scenario(for: scenario)

        XCTAssertEqual(historical.id, .tucholaForest)
        XCTAssertEqual(historical.title, scenario.title)
        XCTAssertEqual(historical.status, .playable)
        XCTAssertTrue(historical.hasTwoPlayableSides)
        XCTAssertEqual(
            historical.sideOptions.map(\.id),
            [
                GuderianHistoricalSideID.guderianCommand,
                GuderianHistoricalSideID.opposingForce,
            ]
        )
        XCTAssertEqual(historical.sideOptions.first?.role, .protagonist)
        XCTAssertEqual(historical.sideOptions.last?.role, .opponent)
        XCTAssertEqual(historical.objectives.count, scenario.objectives.count)
        XCTAssertGreaterThanOrEqual(historical.victory.targetScore, scenario.objectives.map(\.victoryPoints).max() ?? 0)
    }

    func testGuderianAutoplayAdapterExposesSharedHistoricalHarnessContract() throws {
        let report = GuderianHistoricalAutoplayCatalog.rewriteReport
        let scenario = try XCTUnwrap(GuderianHistoricalAutoplayCatalog.firstBattleScenario())
        let nativeScenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let configuration = GuderianHistoricalAutoplayCatalog.configuration(for: nativeScenario)

        XCTAssertTrue(report.isReady)
        XCTAssertEqual(scenario.id, .tucholaForest)
        XCTAssertEqual(configuration.battleID, .tucholaForest)
        XCTAssertEqual(configuration.seed, GuderianHistoricalAutoplayCatalog.defaultSeed)
        XCTAssertEqual(configuration.contract.embeddedBattleSurfaceName, HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName)
        XCTAssertTrue(configuration.contract.retiredEmbeddedSurfaceNames.contains("DZWPlayableBattleView"))
        XCTAssertEqual(configuration.sidePlans.map(\.sideID), [
            GuderianHistoricalSideID.opposingForce,
            GuderianHistoricalSideID.guderianCommand,
        ])
        XCTAssertTrue(configuration.contract.isFirstBattleAutoplayContract)
        XCTAssertGreaterThanOrEqual(configuration.maxPhaseAdvances, 24)
    }

    func testGuderianHistoricalSideSelectionMapsEitherSideToNativeEngineSlots() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let opposingLaunch = try GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: GuderianHistoricalSideID.opposingForce,
            seed: 620_001
        )
        let guderianLaunch = try GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: GuderianHistoricalSideID.guderianCommand,
            seed: 620_002
        )
        let guderianSelection = try GuderianHistoricalSideSelectionResolver.resolvedSelection(
            for: scenario,
            chosenHumanSideID: GuderianHistoricalSideID.guderianCommand,
            seed: 620_002
        )
        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, launch: guderianLaunch))

        XCTAssertEqual(opposingLaunch.humanBinding?.enginePlayerSlot, .playerOne)
        XCTAssertEqual(opposingLaunch.aiBinding?.enginePlayerSlot, .playerTwo)
        XCTAssertEqual(guderianLaunch.humanBinding?.enginePlayerSlot, .playerTwo)
        XCTAssertEqual(guderianLaunch.aiBinding?.enginePlayerSlot, .playerOne)
        XCTAssertEqual(guderianSelection.selectedSide?.id, GuderianHistoricalSideID.guderianCommand)
        XCTAssertEqual(guderianSelection.opposingSide?.id, GuderianHistoricalSideID.opposingForce)
        XCTAssertEqual(session.launch.chosenHumanSideID, GuderianHistoricalSideID.guderianCommand)
        XCTAssertEqual(session.humanPlayer, .guderianAI)
        XCTAssertEqual(session.aiPlayer, .player)
    }

    func testGuderianScenarioBoardSessionIsHostedByDZWPackage() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, seed: 1_939_0901))
        let opening = session.snapshot()

        XCTAssertEqual(opening.scenarioID, .tucholaForest)
        XCTAssertTrue(opening.isScenarioBoardPlayable)
        XCTAssertGreaterThan(opening.units.count, 0)
        XCTAssertGreaterThan(opening.objectives.count, 0)

        session.selectFirstActiveUnit()
        session.selectNearestEnemyToSelectedUnit()
        let selected = session.snapshot()

        XCTAssertNotNil(selected.selectedUnit)
        XCTAssertNotNil(selected.selectedTarget)

        let aiPlan = ScenarioContentCatalog.bundle(for: scenario).aiPlan
        let moved = session.moveSelectedUnitTowardPriorityObjective(
            named: aiPlan.targetPriorities,
            maxDistance: 6
        ) || session.moveSelectedUnitTowardNearestObjective(maxDistance: 4)
        let afterMove = session.snapshot()

        XCTAssertTrue(moved, afterMove.lastAction.detail)
        XCTAssertEqual(afterMove.lastAction.status, .succeeded)
    }

    func testPlayableTestGameRunnerCoversBothSidesFromDZWPackage() throws {
        let result = try PlayableTestGameRunner.runBattle(for: .tucholaForest, seed: 620_001)

        XCTAssertTrue(result.completedToEnd, result.blockers.joined(separator: "\n"))
        XCTAssertTrue(result.automatedSides.contains(.player))
        XCTAssertTrue(result.automatedSides.contains(.guderianAI))
        XCTAssertGreaterThan(result.antiGuderianStepCount, 0)
        XCTAssertGreaterThan(result.germanStepCount, 0)
        XCTAssertEqual(result.completion.completionRecord.scenarioID, .tucholaForest)
        XCTAssertFalse(result.antiGuderianPlan.targetPriorities.isEmpty)
    }

    func testCareerScopeLedgerCoversCurrentCampaignAndFlagsCaveats() {
        XCTAssertEqual(GuderianCareerScopeCatalog.allCurrentScenarioIDs, Set(GuderianBattleID.allCases))
        XCTAssertEqual(
            Set(GuderianCareerScopeCatalog.directCommandScenarioIDs),
            Set(GuderianBattleID.allCases).subtracting([.dunkirk])
        )
        XCTAssertEqual(GuderianCareerScopeCatalog.caveatedCurrentScenarioIDs, [.dunkirk])

        let dunkirk = GuderianCareerScopeCatalog.record(for: .dunkirk)
        XCTAssertEqual(dunkirk?.scope, .adjacentCampaignPressure)
        XCTAssertEqual(dunkirk?.requiresCommandCaveat, true)
        XCTAssertTrue(dunkirk?.playableFraming.contains("explicitly labels") == true)

        let moscow = GuderianCareerScopeCatalog.record(for: .moscowTulaKashira)
        XCTAssertEqual(moscow?.scope, .directFieldCommand)
        XCTAssertTrue(moscow?.playableFraming.contains("end-date caveat") == true)
    }

    func testLateCareerExpansionCandidatesAreStaffOrEpilogueContext() {
        let candidates = GuderianCareerScopeCatalog.lateCareerExpansionCandidates

        XCTAssertGreaterThanOrEqual(candidates.count, 15)
        XCTAssertEqual(candidates.map(\.order), Array(1...candidates.count))
        XCTAssertTrue(candidates.allSatisfy(\.requiresCommandCaveat))
        XCTAssertFalse(candidates.contains { $0.scope.allowsDirectBattlefieldScenario })
        XCTAssertTrue(candidates.contains { $0.scope == .inspectorGeneralInfluence })
        XCTAssertTrue(candidates.contains { $0.scope == .armyGeneralStaffInfluence })
        XCTAssertTrue(candidates.contains { $0.scope == .postDismissalContext })
        XCTAssertTrue(candidates.allSatisfy { !$0.sourceLinks.isEmpty })
        XCTAssertTrue(candidates.allSatisfy { !$0.geographyFocus.isEmpty })
        XCTAssertTrue(candidates.allSatisfy { !$0.playerRole.isEmpty })
    }

    func testScenarioMapDetailAuditSetsFourXTargetsForEveryCurrentBattle() {
        let audits = ScenarioMapDetailAuditCatalog.allAudits

        XCTAssertEqual(audits.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(audits.map(\.id), GuderianCampaignCatalog.all.map(\.id))

        for audit in audits {
            XCTAssertGreaterThan(audit.metrics.mapFeatureCount, 0, audit.title)
            XCTAssertEqual(audit.target.minimumFeatureCount, audit.metrics.mapFeatureCount * 4, audit.title)
            XCTAssertEqual(audit.target.requiredAdditionalFeatureCount, audit.metrics.mapFeatureCount * 3, audit.title)
            XCTAssertTrue(audit.needsFourXEnrichment, audit.title)
            XCTAssertTrue(audit.gaps.contains { $0.category == .totalMapFeatures }, audit.title)
            XCTAssertGreaterThanOrEqual(audit.metrics.deploymentZoneCount, 2, audit.title)
        }
    }

    func testScenarioMapDetailAuditMeasuresRequestedGeographyCategories() {
        let report = ScenarioMapDetailAuditCatalog.report()

        XCTAssertEqual(report.scenarioCount, 19)
        XCTAssertEqual(report.minimumFeatureCount, report.currentFeatureCount * 4)
        XCTAssertEqual(report.requiredAdditionalFeatureCount, report.currentFeatureCount * 3)
        XCTAssertEqual(report.battleIDsNeedingEnrichment.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(report.categoryGaps.contains(.water))
        XCTAssertTrue(report.categoryGaps.contains(.roads))
        XCTAssertTrue(report.categoryGaps.contains(.railways))
        XCTAssertTrue(report.categoryGaps.contains(.crossings))
        XCTAssertTrue(report.categoryGaps.contains(.settlements))
        XCTAssertTrue(report.categoryGaps.contains(.groundTerrain))
        XCTAssertTrue(report.categoryGaps.contains(.annotatedFeatures))
    }

    func testScenarioMapSchemaSupportsCycle605GeographyAndSourceNotes() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://example.com/map-source"))
        let source = ScenarioMapSourceNote(
            title: "Synthetic map source",
            url: sourceURL,
            note: "Used only to verify source-note metadata in the schema."
        )
        let layout = ScenarioMapLayout(
            id: .tucholaForest,
            title: "Cycle 605 schema probe",
            elements: [
                ScenarioMapElement(id: "canal", name: "Canal", kind: .canal, points: [ScenarioMapPoint(1, 1), ScenarioMapPoint(10, 1)], note: "Water obstacle.", sourceNotes: [source]),
                ScenarioMapElement(id: "lake", name: "Lake", kind: .lake, points: [ScenarioMapPoint(12, 2)], radius: 3, note: "Standing water."),
                ScenarioMapElement(id: "marsh", name: "Marsh", kind: .marsh, points: [ScenarioMapPoint(16, 2)], radius: 4, note: "Wet ground."),
                ScenarioMapElement(id: "rail", name: "Railway", kind: .railway, points: [ScenarioMapPoint(1, 8), ScenarioMapPoint(20, 8)], note: "Rail axis."),
                ScenarioMapElement(id: "ford", name: "Ford", kind: .ford, points: [ScenarioMapPoint(8, 1)], radius: 2, note: "Minor crossing."),
                ScenarioMapElement(id: "ferry", name: "Ferry", kind: .ferry, points: [ScenarioMapPoint(14, 1)], radius: 2, note: "River crossing."),
                ScenarioMapElement(id: "village", name: "Village", kind: .village, points: [ScenarioMapPoint(18, 8)], radius: 3, note: "Named settlement."),
                ScenarioMapElement(id: "district", name: "Urban district", kind: .urbanDistrict, points: [ScenarioMapPoint(22, 8)], radius: 4, note: "Urban neighborhood."),
                ScenarioMapElement(id: "phase", name: "Phase line", kind: .phaseLine, points: [ScenarioMapPoint(1, 12), ScenarioMapPoint(24, 12)], note: "Operational line."),
            ],
            deploymentZones: [
                ScenarioDeploymentZone(id: "player", name: "Player", side: .player, origin: ScenarioMapPoint(0, 0), width: 10, height: 10, note: "Player start.", sourceNotes: [source]),
                ScenarioDeploymentZone(id: "ai", name: "AI", side: .guderianAI, origin: ScenarioMapPoint(20, 0), width: 10, height: 10, note: "AI start."),
            ],
            sourceNotes: [source]
        )
        let metrics = ScenarioMapDetailMetrics(layout: layout)

        XCTAssertTrue(ScenarioMapElementKind.allCases.contains(.canal))
        XCTAssertTrue(ScenarioMapElementKind.allCases.contains(.railway))
        XCTAssertEqual(metrics.count(for: .water), 4)
        XCTAssertEqual(metrics.count(for: .railways), 1)
        XCTAssertEqual(metrics.count(for: .crossings), 2)
        XCTAssertEqual(metrics.count(for: .settlements), 2)
        XCTAssertEqual(metrics.count(for: .groundTerrain), 2)
        XCTAssertEqual(metrics.count(for: .sourceNotes), 3)
        XCTAssertFalse(ScenarioMapElementKind.phaseLine.isPlayableTerrainFeature)
    }

    func testScenarioMapGeographyPipelinePreparesEveryBattleForEnrichment() throws {
        let report = ScenarioMapGeographyPipelineCatalog.report()

        XCTAssertEqual(report.scenarioCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.readyScenarioIDs, GuderianCampaignCatalog.all.map(\.id))
        XCTAssertEqual(report.modernVisualReferenceCount, GuderianCampaignCatalog.all.count)
        XCTAssertGreaterThanOrEqual(report.historicalReferenceCount, GuderianCampaignCatalog.all.count)
        XCTAssertGreaterThanOrEqual(
            report.totalAnchorCount,
            GuderianCampaignCatalog.all.reduce(0) { $0 + $1.mapFeatures.count }
        )

        let sedan = try XCTUnwrap(ScenarioMapGeographyPipelineCatalog.record(for: .sedan))

        XCTAssertTrue(sedan.workflowSteps.contains(.openModernMapVisualGuide))
        XCTAssertTrue(sedan.workflowSteps.contains(.handAuthorAbstractCoordinates))
        XCTAssertTrue(sedan.workflowSteps.contains(.attachSourceNotes))
        XCTAssertTrue(sedan.workflowSteps.contains(.rerunMapDetailAudit))
        XCTAssertTrue(sedan.coordinatePolicy.contains("abstract coordinates"))
        XCTAssertTrue(sedan.visualGuideReferences.contains { $0.url.absoluteString.contains("google.com/maps/search") })
        XCTAssertTrue(sedan.anchors.contains { $0.targetCategories.contains(.crossings) })
        XCTAssertTrue(sedan.requiredDetailCategories.contains(.water))

        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .sedan))
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let metrics = ScenarioMapDetailMetrics(layout: layout)

        XCTAssertTrue(layout.sourceNotes.contains { $0.title.contains("modern map visual guide") })
        XCTAssertGreaterThanOrEqual(metrics.count(for: .sourceNotes), scenario.sourceLinks.count + 1)
    }

    func testCycle615PolandMapsReachFourXBaselineWithDetailedGeography() throws {
        let cycle600BaselineFeatureCounts: [GuderianBattleID: Int] = [
            .tucholaForest: 14,
            .wizna: 9,
            .brzescLitewski: 11,
            .kobryn: 10,
        ]
        let polandIDs: [GuderianBattleID] = [.tucholaForest, .wizna, .brzescLitewski, .kobryn]

        for id in polandIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let metrics = ScenarioMapDetailMetrics(layout: layout)
            let baseline = try XCTUnwrap(cycle600BaselineFeatureCounts[id])

            XCTAssertGreaterThanOrEqual(metrics.mapFeatureCount, baseline * 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .water), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .roads), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .railways), 1, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .crossings), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .settlements), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .groundTerrain), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .sourceNotes), scenario.sourceLinks.count + 1, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .marsh }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .railway }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .phaseLine }, scenario.title)
            XCTAssertTrue(layout.elements.allSatisfy { !$0.note.isEmpty }, scenario.title)
        }
    }

    func testCycle620FranceMapsReachFourXBaselineWithDetailedGeography() throws {
        let cycle600BaselineFeatureCounts: [GuderianBattleID: Int] = [
            .sedan: 10,
            .stonne: 9,
            .montcornet: 9,
            .amiensAbbeville: 10,
            .boulogne: 10,
            .calais: 10,
            .dunkirk: 11,
            .fallRot: 10,
        ]
        let franceIDs: [GuderianBattleID] = [
            .sedan,
            .stonne,
            .montcornet,
            .amiensAbbeville,
            .boulogne,
            .calais,
            .dunkirk,
            .fallRot,
        ]
        let channelIDs: Set<GuderianBattleID> = [.amiensAbbeville, .boulogne, .calais, .dunkirk]
        let canalIDs: Set<GuderianBattleID> = [.calais, .dunkirk, .fallRot]
        let fortressIDs: Set<GuderianBattleID> = [.boulogne, .calais, .fallRot]

        for id in franceIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let metrics = ScenarioMapDetailMetrics(layout: layout)
            let baseline = try XCTUnwrap(cycle600BaselineFeatureCounts[id])

            XCTAssertGreaterThanOrEqual(metrics.mapFeatureCount, baseline * 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .water), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .roads), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .railways), 1, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .crossings), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .settlements), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .groundTerrain), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .sourceNotes), scenario.sourceLinks.count + 1, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .railway }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .urbanDistrict }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .phaseLine }, scenario.title)
            XCTAssertTrue(layout.elements.allSatisfy { !$0.note.isEmpty }, scenario.title)

            if channelIDs.contains(id) {
                XCTAssertTrue(
                    layout.elements.contains { $0.name.localizedCaseInsensitiveContains("coast") || $0.name.localizedCaseInsensitiveContains("beach") || $0.name.localizedCaseInsensitiveContains("harbor") },
                    scenario.title
                )
            }
            if canalIDs.contains(id) {
                XCTAssertTrue(layout.elements.contains { $0.kind == .canal }, scenario.title)
            }
            if fortressIDs.contains(id) {
                XCTAssertTrue(layout.elements.contains { $0.kind == .fortifiedLine || $0.kind == .bunker }, scenario.title)
            }
        }
    }

    func testCycle625EasternFrontMapsReachFourXBaselineWithDetailedGeography() throws {
        let cycle600BaselineFeatureCounts: [GuderianBattleID: Int] = [
            .bialystokMinsk: 11,
            .smolensk: 13,
            .roslavlNovozybkov: 12,
            .kiev: 12,
            .bryansk: 13,
            .mtsensk: 13,
            .moscowTulaKashira: 16,
        ]
        let easternFrontIDs: [GuderianBattleID] = [
            .bialystokMinsk,
            .smolensk,
            .roslavlNovozybkov,
            .kiev,
            .bryansk,
            .mtsensk,
            .moscowTulaKashira,
        ]
        let pocketIDs: Set<GuderianBattleID> = [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk]

        for id in easternFrontIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let metrics = ScenarioMapDetailMetrics(layout: layout)
            let baseline = try XCTUnwrap(cycle600BaselineFeatureCounts[id])

            XCTAssertGreaterThanOrEqual(metrics.mapFeatureCount, baseline * 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .water), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .roads), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .railways), 1, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .crossings), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .settlements), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .groundTerrain), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .sourceNotes), scenario.sourceLinks.count + 1, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .railway }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .forest }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .urbanDistrict }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .phaseLine }, scenario.title)
            XCTAssertTrue(layout.elements.allSatisfy { !$0.note.isEmpty }, scenario.title)

            if pocketIDs.contains(id) {
                XCTAssertTrue(
                    layout.elements.contains { $0.name.localizedCaseInsensitiveContains("escape") || $0.name.localizedCaseInsensitiveContains("breakout") || $0.name.localizedCaseInsensitiveContains("exit") },
                    scenario.title
                )
            }
        }

        let mtsensk = ScenarioMapCatalog.layout(for: try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .mtsensk)))
        XCTAssertTrue(mtsensk.elements.contains { $0.name.localizedCaseInsensitiveContains("ambush") })

        let moscow = ScenarioMapCatalog.layout(for: try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .moscowTulaKashira)))
        XCTAssertTrue(moscow.elements.contains { $0.name.localizedCaseInsensitiveContains("winter") || $0.name.localizedCaseInsensitiveContains("frozen") || $0.name.localizedCaseInsensitiveContains("snow") })
    }

    func testCycle630LateCareerSetAAddsStaffContextBattlefields() throws {
        let catalog = LateCareerStaffBattlefieldSetACatalog.self
        let currentBattleRawIDs = Set(GuderianBattleID.allCases.map(\.rawValue))

        XCTAssertEqual(catalog.cycleRange, 626...630)
        XCTAssertEqual(
            catalog.battlefieldIDs,
            [
                "kursk-armored-force-pressure",
                "dnieper-withdrawal",
                "korsun-cherkassy-pocket",
                "kamenets-podolsky-pocket",
            ]
        )
        XCTAssertEqual(catalog.allBattlefields.count, 4)
        XCTAssertTrue(catalog.allBattlefieldsReady)
        XCTAssertEqual(GuderianCampaignCatalog.all.count, 19)

        for battlefield in catalog.allBattlefields {
            let candidate = try XCTUnwrap(GuderianCareerScopeCatalog.expansionCandidate(for: battlefield.id))

            XCTAssertFalse(currentBattleRawIDs.contains(battlefield.id), battlefield.title)
            XCTAssertEqual(candidate.title, battlefield.title)
            XCTAssertEqual(candidate.scope, .inspectorGeneralInfluence, battlefield.title)
            XCTAssertEqual(candidate.dateRange, battlefield.dateRange, battlefield.title)
            XCTAssertEqual(battlefield.scope, .inspectorGeneralInfluence, battlefield.title)
            XCTAssertTrue(battlefield.requiresCommandCaveat, battlefield.title)
            XCTAssertTrue(battlefield.commandCaveat.localizedCaseInsensitiveContains("not a Guderian field command"), battlefield.title)
            XCTAssertTrue(battlefield.playableFraming.localizedCaseInsensitiveContains("scenario"), battlefield.title)
            XCTAssertTrue(battlefield.map.hasRequiredStaffContextDetail, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.featureCount, 24, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.waterFeatureCount, 2, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.roadFeatureCount, 3, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.railwayFeatureCount, 1, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.crossingFeatureCount, 2, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.settlementFeatureCount, 3, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.groundTerrainFeatureCount, 3, battlefield.title)
            XCTAssertTrue(battlefield.map.elements.contains { $0.kind == .phaseLine }, battlefield.title)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .player }, battlefield.title)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .guderianAI }, battlefield.title)
            XCTAssertTrue(battlefield.forces.allSatisfy { !$0.caveat.isEmpty }, battlefield.title)
            XCTAssertTrue(battlefield.rules.allSatisfy { !$0.trigger.isEmpty && !$0.effect.isEmpty }, battlefield.title)
            XCTAssertEqual(catalog.battlefield(for: battlefield.id)?.id, battlefield.id)
        }
    }

    func testCycle635LateCareerSetBAddsWithdrawalCrisisBattlefields() throws {
        try assertLateCareerBattlefieldSet(
            cycleRange: LateCareerStaffBattlefieldSetBCatalog.cycleRange,
            expectedRange: 631...635,
            ids: LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs,
            expectedIDs: [
                "operation-bagration-withdrawal",
                "lvov-sandomierz",
                "narew-vistula-bridgeheads",
                "warsaw-defensive-arcs",
            ],
            battlefields: LateCareerStaffBattlefieldSetBCatalog.allBattlefields,
            ready: LateCareerStaffBattlefieldSetBCatalog.allBattlefieldsReady,
            expectedScopes: [.armyGeneralStaffInfluence]
        )

        XCTAssertEqual(LateCareerStaffBattlefieldSetBCatalog.battlefield(for: "warsaw-defensive-arcs")?.title, "Warsaw-Area Defensive Arcs")
    }

    func testCycle640LateCareerSetCAddsCollapseAndOderBattlefields() throws {
        try assertLateCareerBattlefieldSet(
            cycleRange: LateCareerStaffBattlefieldSetCCatalog.cycleRange,
            expectedRange: 636...640,
            ids: LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs,
            expectedIDs: [
                "vistula-oder-breakthrough",
                "poznan-corridor",
                "east-prussia-elbing",
                "kustrin-oder-bridgeheads",
            ],
            battlefields: LateCareerStaffBattlefieldSetCCatalog.allBattlefields,
            ready: LateCareerStaffBattlefieldSetCCatalog.allBattlefieldsReady,
            expectedScopes: [.armyGeneralStaffInfluence]
        )

        XCTAssertTrue(LateCareerStaffBattlefieldSetCCatalog.allBattlefields.contains { $0.map.title.localizedCaseInsensitiveContains("Oder") })
    }

    func testCycle645LateCareerSetDAddsFinalWarAndPostDismissalCaveats() throws {
        try assertLateCareerBattlefieldSet(
            cycleRange: LateCareerStaffBattlefieldSetDCatalog.cycleRange,
            expectedRange: 641...645,
            ids: LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs,
            expectedIDs: [
                "operation-solstice",
                "east-pomeranian-offensive",
                "seelow-heights-epilogue",
                "berlin-halbe-epilogue",
            ],
            battlefields: LateCareerStaffBattlefieldSetDCatalog.allBattlefields,
            ready: LateCareerStaffBattlefieldSetDCatalog.allBattlefieldsReady,
            expectedScopes: [.armyGeneralStaffInfluence, .postDismissalContext]
        )

        let epilogues = LateCareerStaffBattlefieldSetDCatalog.allBattlefields.filter { $0.scope == .postDismissalContext }
        XCTAssertEqual(epilogues.map(\.id), ["seelow-heights-epilogue", "berlin-halbe-epilogue"])
        XCTAssertTrue(epilogues.allSatisfy { $0.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("Post-dismissal") })
    }

    func testCycle650LateCareerAcceptanceCoversCurrentAndNewBattlefields() throws {
        let report = LateCareerStaffBattlefieldAcceptanceCatalog.report

        XCTAssertEqual(LateCareerStaffBattlefieldAcceptanceCatalog.cycleRange, 646...650)
        XCTAssertTrue(report.isReadyForAcceptance)
        XCTAssertEqual(report.currentPlayableBattleCount, 19)
        XCTAssertEqual(report.routedPlayableBattleCount, 19)
        XCTAssertTrue(report.currentCampaignMapDetailReady)
        XCTAssertEqual(report.lateCareerBattlefieldCount, 16)
        XCTAssertEqual(report.commandCaveatCount, 16)
        XCTAssertEqual(report.postDismissalBattlefieldCount, 2)
        XCTAssertTrue(report.allLateCareerBattlefieldsReady)
        XCTAssertTrue(report.allBattlefieldIDsMatchLedger)
        XCTAssertEqual(
            LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefieldIDs,
            GuderianCareerScopeCatalog.lateCareerBattlefieldCandidateIDs
        )
        XCTAssertEqual(
            LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.map(\.order),
            Array(1...16)
        )
        XCTAssertEqual(report.visibleCommandCaveatLabels.count, 16)
        XCTAssertTrue(report.visibleCommandCaveatLabels.contains { $0.contains(GuderianCommandScope.inspectorGeneralInfluence.rawValue) })
        XCTAssertTrue(report.visibleCommandCaveatLabels.contains { $0.contains(GuderianCommandScope.armyGeneralStaffInfluence.rawValue) })
        XCTAssertTrue(report.visibleCommandCaveatLabels.contains { $0.contains(GuderianCommandScope.postDismissalContext.rawValue) })
    }

    private func assertLateCareerBattlefieldSet(
        cycleRange: ClosedRange<Int>,
        expectedRange: ClosedRange<Int>,
        ids: [String],
        expectedIDs: [String],
        battlefields: [LateCareerStaffBattlefield],
        ready: Bool,
        expectedScopes: Set<GuderianCommandScope>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let currentBattleRawIDs = Set(GuderianBattleID.allCases.map(\.rawValue))

        XCTAssertEqual(cycleRange, expectedRange, file: file, line: line)
        XCTAssertEqual(ids, expectedIDs, file: file, line: line)
        XCTAssertEqual(battlefields.map(\.id), expectedIDs, file: file, line: line)
        XCTAssertEqual(battlefields.count, expectedIDs.count, file: file, line: line)
        XCTAssertTrue(ready, file: file, line: line)
        XCTAssertEqual(GuderianCampaignCatalog.all.count, 19, file: file, line: line)

        for battlefield in battlefields {
            let candidate = try XCTUnwrap(GuderianCareerScopeCatalog.expansionCandidate(for: battlefield.id), file: file, line: line)

            XCTAssertFalse(currentBattleRawIDs.contains(battlefield.id), battlefield.title, file: file, line: line)
            XCTAssertEqual(candidate.title, battlefield.title, file: file, line: line)
            XCTAssertEqual(candidate.dateRange, battlefield.dateRange, battlefield.title, file: file, line: line)
            XCTAssertEqual(candidate.scope, battlefield.scope, battlefield.title, file: file, line: line)
            XCTAssertTrue(expectedScopes.contains(battlefield.scope), battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.isLateCareerReady, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.requiresCommandCaveat, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.visibleCommandCaveatLabel.contains(battlefield.scope.rawValue), battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command"), battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.map.hasRequiredStaffContextDetail, battlefield.title, file: file, line: line)
            XCTAssertGreaterThanOrEqual(battlefield.map.featureCount, 24, battlefield.title, file: file, line: line)
            XCTAssertGreaterThanOrEqual(battlefield.map.waterFeatureCount, 2, battlefield.title, file: file, line: line)
            XCTAssertGreaterThanOrEqual(battlefield.map.roadFeatureCount, 3, battlefield.title, file: file, line: line)
            XCTAssertGreaterThanOrEqual(battlefield.map.railwayFeatureCount, 1, battlefield.title, file: file, line: line)
            XCTAssertGreaterThanOrEqual(battlefield.map.crossingFeatureCount, 2, battlefield.title, file: file, line: line)
            XCTAssertGreaterThanOrEqual(battlefield.map.settlementFeatureCount, 3, battlefield.title, file: file, line: line)
            XCTAssertGreaterThanOrEqual(battlefield.map.groundTerrainFeatureCount, 3, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.map.elements.contains { $0.kind == .phaseLine }, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .player }, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .guderianAI }, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.forces.contains { $0.side == .player }, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.forces.contains { $0.side == .guderianAI }, battlefield.title, file: file, line: line)
            XCTAssertTrue(battlefield.rules.allSatisfy { !$0.trigger.isEmpty && !$0.effect.isEmpty }, battlefield.title, file: file, line: line)
        }
    }
}
