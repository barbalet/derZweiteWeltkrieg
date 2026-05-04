import DerZweiteWeltkriegCore
@testable import DerZweiteWeltkriegGuderian
import XCTest

final class DerZweiteWeltkriegGuderianGameplayTests: XCTestCase {
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
}
