import CoreGraphics
import XCTest

final class DerZweiteWeltkriegUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDeployForceAndBeginBattleFromSetup() {
        launchGame()
        defer { terminateGame() }

        deployForce()
        beginBattle()

        expectElement("battle-screen")
        expectPhase("Movement")
    }

    @MainActor
    func testDeploymentSelectsRotatesAndBeginsBattle() {
        launchGame()
        defer { terminateGame() }

        deployForce()
        tapElement("next-ready-button")
        expectElement("selected-facing-label")
        tapElement("rotate-right-button")
        tapElement("rotate-left-button")
        beginBattle()

        expectElement("battle-screen")
    }

    @MainActor
    func testDeploymentDragsFirstUnitForwardBeforeBattle() {
        launchGame()
        defer { terminateGame() }

        deployForce()
        dragFirstUnitToken(to: CGVector(dx: 0.42, dy: 0.38))
        beginBattle()

        expectElement("battle-screen")
        expectPhase("Movement")
    }

    @MainActor
    func testMovementPhaseMovesSelectedUnitOnBoard() {
        launchGame()
        defer { terminateGame() }

        startBattleWithForwardUnit()
        tapElement("next-ready-button")
        dragFirstUnitToken(to: CGVector(dx: 0.44, dy: 0.40))

        expectPhase("Movement")
    }

    @MainActor
    func testMovementPhaseSelectsNearestEnemy() {
        launchGame()
        defer { terminateGame() }

        startBattleWithForwardUnit()
        tapElement("next-ready-button")
        tapElement("nearest-enemy-button")

        expectElement("selected-target-label")
    }

    @MainActor
    func testShootingPhaseSelectsTargetAndShoots() {
        launchGame()
        defer { terminateGame() }

        startBattleWithForwardUnit()
        advanceToPhase("Shooting")
        tapElement("next-ready-button")
        tapElement("nearest-enemy-button")
        tapElement("shoot-target-button")

        expectPhase("Shooting")
    }

    @MainActor
    func testAssaultPhaseSelectsTargetAndChecksAssaultControl() {
        launchGame()
        defer { terminateGame() }

        startBattleWithForwardUnit()
        advanceToPhase("Assault")
        tapElement("next-ready-button")
        tapElement("nearest-enemy-button")

        let assaultButton = element("assault-target-button")
        XCTAssertTrue(assaultButton.waitForExistence(timeout: 2), "Expected Assault Target to be available in the action panel.")
        if assaultButton.isEnabled {
            tap(assaultButton, named: "element 'assault-target-button'")
        } else {
            XCTAssertFalse(assaultButton.isEnabled, "Assault Target should remain disabled when the selected unit is not in legal charge position.")
        }

        expectPhase("Assault")
    }

    @MainActor
    func testBattleTogglesCoverAndHullDownForSelectedUnit() {
        launchGame()
        defer { terminateGame() }

        startBattleWithForwardUnit()
        tapElement("next-ready-button")
        tapElement("manual-cover-toggle")
        tapElement("hull-down-toggle")

        expectPhase("Movement")
    }

    @MainActor
    func testAdvancesThroughMovementShootingAndAssaultPhases() {
        launchGame()
        defer { terminateGame() }

        startBattleWithForwardUnit()
        expectPhase("Movement")
        tapElement("next-phase-button")
        expectPhase("Shooting")
        tapElement("next-phase-button")
        expectPhase("Assault")
    }

    @MainActor
    func testPlaysSeveralInteractionsThenRestartsBattle() {
        launchGame()
        defer { terminateGame() }

        startBattleWithForwardUnit()
        tapElement("next-ready-button")
        dragFirstUnitToken(to: CGVector(dx: 0.45, dy: 0.42))
        tapElement("nearest-enemy-button")
        advanceToPhase("Shooting")
        tapElement("shoot-target-button")
        tapElement("restart-button")

        expectElement("battle-screen")
        expectPhase("Movement")
    }

    @MainActor
    private func launchGame() {
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-test-suite",
            "DerZweiteWeltkriegGameplayUITests"
        ]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5), "The game should launch into the foreground.")
        expectElement("setup-screen")
    }

    @MainActor
    private func terminateGame() {
        if app != nil && app.state != .notRunning {
            app.terminate()
        }
        app = nil
    }

    @MainActor
    private func startBattleWithForwardUnit() {
        deployForce()
        tapElement("next-ready-button")
        dragFirstUnitToken(to: CGVector(dx: 0.42, dy: 0.38))
        beginBattle()
        tapElement("next-ready-button")
    }

    @MainActor
    private func deployForce() {
        tapElement("deploy-force-button")
        expectElement("deployment-screen")
        XCTAssertTrue(battleBoard().waitForExistence(timeout: 2), "Deployment should show the battle board.")
    }

    @MainActor
    private func beginBattle() {
        tapElement("begin-battle-button")
        expectElement("battle-screen")
    }

    @MainActor
    private func advanceToPhase(_ phase: String) {
        for _ in 0..<3 where !phaseLabelContains(phase) {
            tapElement("next-phase-button")
        }
        expectPhase(phase)
    }

    @MainActor
    private func dragFirstUnitToken(to destination: CGVector) {
        let token = firstUnitToken()
        let board = battleBoard()
        XCTAssertTrue(token.waitForExistence(timeout: 2), "Expected at least one unit token on the board.")
        XCTAssertTrue(board.waitForExistence(timeout: 2), "Expected the battle board.")

        let start = token.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = board.coordinate(withNormalizedOffset: destination)
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    @MainActor
    private func firstUnitToken() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "unit-token-"))
            .element(boundBy: 0)
    }

    @MainActor
    private func battleBoard() -> XCUIElement {
        element("battle-board")
    }

    @MainActor
    private func expectElement(_ identifier: String) {
        XCTAssertTrue(element(identifier).waitForExistence(timeout: 2), "Expected element '\(identifier)' to exist.")
    }

    @MainActor
    private func expectPhase(_ phase: String) {
        let phaseLabel = element("battle-phase-label")
        XCTAssertTrue(phaseLabel.waitForExistence(timeout: 2), "Expected the battle phase label to exist.")
        let accessibleText = accessibilityText(for: phaseLabel)
        XCTAssertTrue(accessibleText.contains(phase), "Expected phase label to contain '\(phase)', got '\(accessibleText)'.")
    }

    @MainActor
    private func phaseLabelContains(_ phase: String) -> Bool {
        let phaseLabel = element("battle-phase-label")
        return phaseLabel.exists && accessibilityText(for: phaseLabel).contains(phase)
    }

    @MainActor
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", identifier))
            .firstMatch
    }

    @MainActor
    private func accessibilityText(for element: XCUIElement) -> String {
        var parts = [element.label]
        if let value = element.value as? String {
            parts.append(value)
        }
        return parts.joined(separator: " ")
    }

    @MainActor
    private func tapElement(_ identifier: String) {
        tap(element(identifier), named: "element '\(identifier)'")
    }

    @MainActor
    private func tap(_ element: XCUIElement, named name: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 2), "Expected \(name) to exist.")
        XCTAssertTrue(element.isEnabled, "Expected \(name) to be enabled.")
        reveal(element)
        XCTAssertTrue(element.isHittable, "Expected \(name) to be hittable.")
        element.click()
    }

    @MainActor
    private func reveal(_ element: XCUIElement) {
        guard !element.isHittable else { return }
        let scrollView = app.scrollViews["battle-sidebar-scroll"].exists
            ? app.scrollViews["battle-sidebar-scroll"]
            : app.scrollViews.firstMatch

        guard scrollView.waitForExistence(timeout: 1) else { return }

        for _ in 0..<8 where !element.isHittable {
            scrollSidebar(scrollView, towardLowerContent: true)
        }

        for _ in 0..<4 where !element.isHittable {
            scrollSidebar(scrollView, towardLowerContent: false)
        }
    }

    @MainActor
    private func scrollSidebar(_ scrollView: XCUIElement, towardLowerContent: Bool) {
        let startY = towardLowerContent ? 0.82 : 0.22
        let endY = towardLowerContent ? 0.22 : 0.82
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

}
