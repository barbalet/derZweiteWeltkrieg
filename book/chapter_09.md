# Chapter 9: The SwiftUI Battlefield

The SwiftUI app is the player's command post. It does not own the rules, but it owns the feeling of play: setup, deployment, board interaction, inspection, commands, pending choices, log review, zoom, and window panels. The UI is built around snapshots from `GameController`, so it can react to engine changes without mutating private C state.

The main app entry for user experience is split across setup and battlefield surfaces. Setup is in [`../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift`](../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift). The battle shell is in [`../Sources/DerZweiteWeltkriegApp/Shell/BattleShellView.swift`](../Sources/DerZweiteWeltkriegApp/Shell/BattleShellView.swift). The board itself is in [`../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift`](../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift). The sidebar sections live in `Sources/DerZweiteWeltkriegApp/Sidebar`.

## Modes

The app has three modes: setup, deployment, and battle. `AppMode` lives in [`../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift). Mode is an app concept, not a C phase. Deployment mode still has an engine game underneath, but it uses deployment commands rather than normal movement. Battle mode exposes the phase sequence and human-vs-AI turn flow. Setup mode is mostly list building and configuration.

The mode distinction keeps UI affordances honest. In setup, the board is absent. In deployment, player-owned units can be selected, dragged, and rotated before battle begins. In battle, selection respects human turn and active player. The controller enforces those app-level boundaries before commands reach the engine.

## The Board As Projection

`BattleBoardView` renders the board as a projection of snapshots. It draws terrain zones from `ZoneSnapshot`, objective markers from `ObjectiveSnapshot`, and unit tokens from `UnitSnapshot`. It does not cache rules data. A token's color, shape, badges, smoke ring, opacity, facing marker, and accessibility label all come from snapshot fields.

Dragging is the main board interaction. The view converts the drag location from screen space to board coordinates and asks the controller to move the unit. While dragging, `dragPreview` allows the token to visually follow the cursor. On release, the controller calls either deployment or movement action depending on mode. If the engine rejects the move, reload returns the token to its legal position and the error message explains why.

This is the right compromise between responsiveness and correctness. The UI can feel direct without becoming authoritative.

## Panels And Commands

`BattleShellView` places the battlefield in a viewport and controls floating panel windows through `BattleShellWindowCoordinator`. The default visible panels are Command and Inspector, with Forces and Log available from toolbar buttons. Each panel is a SwiftUI view hosted in an AppKit window.

This panel design gives the game room. The battlefield can stay large while command, inspection, force summary, and log detail remain accessible. It also maps well to tabletop play: board in the center, reference sheets and command panels around it.

The Command panel includes battle header and controls. It also displays pending weapon destruction and pending hit allocation sections when snapshots say they exist, plus error messages from the engine. The Inspector panel shows selected unit detail and objectives. The Forces panel shows armies and legend. The Log panel shows guide and battle log.

## Accessibility As Test Contract

The UI has accessibility identifiers such as `setup-screen`, `deployment-screen`, `battle-screen`, `battle-board`, `unit-token-<id>`, `deploy-force-button`, `begin-battle-button`, `next-ready-button`, `nearest-enemy-button`, `shoot-target-button`, `assault-target-button`, `manual-cover-toggle`, `hull-down-toggle`, `battle-phase-label`, and `battlefield-zoom-slider`.

These identifiers are not only for assistive technology. They are the UI test contract. [`../Tests/DerZweiteWeltkriegUITests/DerZweiteWeltkriegUITests.swift`](../Tests/DerZweiteWeltkriegUITests/DerZweiteWeltkriegUITests.swift) launches the app, deploys forces, drags units, begins battles, advances phases, selects enemies, shoots, checks assault controls, toggles cover, toggles hull down, restarts, and verifies the visible phase. That suite depends on stable identifiers rather than fragile text matching or screen coordinates alone.

When changing UI, keep identifiers stable if the behavior remains the same. Add new identifiers for new controls. This makes UI tests a practical development tool rather than a constant maintenance tax.

## Presentation Layer

Visual styling is isolated in files such as [`../Sources/DerZweiteWeltkriegApp/Presentation/BattlePalette.swift`](../Sources/DerZweiteWeltkriegApp/Presentation/BattlePalette.swift), [`../Sources/DerZweiteWeltkriegApp/Presentation/BattleButtonStyles.swift`](../Sources/DerZweiteWeltkriegApp/Presentation/BattleButtonStyles.swift), and [`../Sources/DerZweiteWeltkriegApp/Presentation/PanelChrome.swift`](../Sources/DerZweiteWeltkriegApp/Presentation/PanelChrome.swift). Labels are handled through display helpers such as [`../Sources/DerZweiteWeltkriegApp/Presentation/DisplayLabels.swift`](../Sources/DerZweiteWeltkriegApp/Presentation/DisplayLabels.swift).

That keeps rule snapshots from being cluttered with color and typography. It also gives the app a consistent war-room surface without requiring each sidebar section to invent its own chrome.

## The Rationale

The UI is powerful because it is modest about authority. It lets the player see the board, select units, drag, click, and inspect. It schedules AI and saves battles. But it treats the engine as the arbiter. That gives the game a durable interactive shell around a single rules truth.

When extending the UI, ask what snapshot data already exists. If the data does not exist, add an engine view field rather than deriving it from labels. If a control triggers a rule, route it through a recorded action. If a UI behavior becomes important to play, give it an accessibility identifier and a UI test.

## The UI Starts With App Mode

The SwiftUI app is organized around `AppMode`: setup, deployment, and battle. These modes decide which surface the player sees and which commands are appropriate. Setup shows force building. Deployment shows the board with pre-battle manipulation. Battle shows the board with turn, phase, AI, and combat actions.

This app mode layer is separate from engine phase. That separation lets the app offer deployment without pretending deployment is an engine phase. It also lets setup exist as a full interface before a skirmish is committed. The UI should continue to respect this distinction.

The setup screen marks itself for UI tests:

```swift
.accessibilityElement(children: .contain)
.accessibilityIdentifier("setup-screen")
```

The battle shell does the same, selecting deployment or battle identifier from mode:

```swift
.accessibilityElement(children: .contain)
.accessibilityIdentifier(controller.isDeploymentMode ? "deployment-screen" : "battle-screen")
```

These identifiers are small but powerful. They let tests verify that the app crossed the correct mode boundary after a button click.

## Setup UI As Force Builder

`SkirmishSetupView` is a real tool surface. It includes a nation picker, point cap stepper, current draft total, catalogue unit steppers, opponent plan preview, deploy button, load button, resume button when applicable, and status text. It is dense because setup is not marketing; it is force construction.

The player-facing draft list is generated from engine catalogue data. Each unit row shows name, points, max count, current count, and summary. The UI does not know how to instantiate those units. It only lets the player select counts. The controller converts those counts to `ArmyListSelection`, asks the engine for points, and later starts a skirmish.

This keeps setup honest. If a catalogue entry changes points, setup changes. If a unit preview changes, setup changes. The UI is a lens over game data, not a parallel list.

## Board Rendering Layers

`BattleBoardView` renders in predictable layers:

```swift
ZStack {
    RoundedRectangle(cornerRadius: 24)
        .fill(...)

    grid(in: geometry.size)
        .stroke(Color.black.opacity(0.18), lineWidth: 1)

    ForEach(controller.zones) { zone in
        terrainShape(for: zone, in: geometry.size)
    }

    ForEach(controller.objectiveStates) { objective in
        objectiveMarker(objective, in: geometry.size)
    }

    ForEach(controller.renderableUnits) { unit in
        unitToken(unit, in: geometry.size)
    }
}
```

This order is practical. Ground and grid establish scale. Terrain comes before objectives and units. Objectives remain visible. Units sit on top because they are interactive. The view is clipped and overlaid to create a board boundary.

The board is not a decorative card in the app's logic. It is the primary play surface. It owns gestures, token taps, drag previews, coordinate conversion, and accessibility identifiers for units.

## Coordinate Conversion

The board's conversion helpers are central:

```swift
private func boardPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(
        x: point.x / GameController.boardWidth * size.width,
        y: point.y / GameController.boardHeight * size.height
    )
}

private func gameCoordinates(for location: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(
        x: min(max(0, location.x / size.width * GameController.boardWidth), GameController.boardWidth),
        y: min(max(0, location.y / size.height * GameController.boardHeight), GameController.boardHeight)
    )
}
```

These helpers keep screen and rules coordinates aligned. A future line-of-sight preview, movement ruler, range ring, or deployment overlay should use the same model. If coordinate conversion drifts, the player will see one thing while the engine receives another. That is one of the worst UI failures a tactics game can have.

## Unit Tokens

Unit tokens are compact visual summaries. Infantry are circles. Vehicles are rounded rectangles. Owner color distinguishes sides. Selection adds a stronger stroke. Destroyed units fade. Smoke creates a ring. Assault guns get an `AG` badge. Transports with passengers get a `TR` badge. Partial wounds can display a wound badge.

The token body uses `UnitSnapshot`, not private engine state. For example:

```swift
let ownerColor = unit.owner == DZW_PLAYER_ONE ? BattlePalette.playerOneAccent : Color(red: 0.63, green: 0.23, blue: 0.16)
let isSelected = controller.selectedUnitID == unit.id || controller.selectedTargetID == unit.id

if unit.usesVehicleRules {
    RoundedRectangle(cornerRadius: 10)
        .fill(ownerColor)
} else {
    Circle()
        .fill(ownerColor)
}
```

The shape conveys rules category. The badges convey special state. This is exactly what a board token should do: be readable at a glance and inspectable when selected.

## Gestures And Commands

Tokens support tap and drag. Tap calls `controller.selectUnit(unit)`. Drag checks `controller.canManipulate(unit)`, updates `dragPreview`, and on release calls `controller.moveUnit(id:to:)`.

The drag preview is temporary UI state. It lets the token follow the cursor while the player drags. On release, the engine command determines the real position. If the engine rejects the move, reload restores the legal position. This is the right relationship between responsiveness and correctness.

The UI test `dragFirstUnitToken` relies on this behavior. It finds a token by accessibility identifier, finds the board, and drags from token center to a normalized board coordinate. That test does not know engine movement rules. It verifies that the interaction path exists.

## Selection Model

Selection belongs to the controller. `selectedUnitID` and `selectedTargetID` are Swift state derived from user interaction. They are not stored in the engine. This lets the UI offer features like next-ready cycling and nearest-enemy selection without changing C rules.

`selectUnit(_:)` behaves differently by mode. In deployment, it only selects player-owned non-destroyed, non-embarked units. In battle, it requires human turn; selecting an active friendly unit sets selected unit, while selecting an enemy sets selected target. That creates a simple interaction grammar: choose your piece, choose their piece, press a command.

The controller clears invalid selections on reload if the unit no longer exists. This protects the UI after destruction or reset.

## Panels And Window Coordination

`BattleShellView` uses a full battlefield viewport plus floating panel windows. `BattleShellPanel` defines command, inspector, forces, and log panels. `BattleShellWindowCoordinator` creates AppKit windows hosting SwiftUI content.

This hybrid approach is practical for a macOS tactics game. The board remains large. Panels can be moved, closed, or toggled. The command panel can stay open while the player inspects units. The log can become its own window rather than stealing board width.

The coordinator also owns window identifiers and default frames. That makes panels testable and predictable. When the shell appears, command and inspector panels open by default. When it disappears, windows close. This avoids orphaned panels after returning to setup or loading a different battle.

## Command Panel Responsibilities

The command panel contains header, controls, pending choice sections, and errors. It should answer "what can I do now?" The inspector panel answers "what am I looking at?" The forces panel answers "what armies are present?" The log panel answers "what happened?"

This separation keeps panel content from becoming a giant miscellaneous sidebar. A new control should be placed according to the question it answers. A pending combat choice belongs in Command. A unit stat belongs in Inspector. A roster summary belongs in Forces. A battle explanation belongs in Log.

## Accessibility Identifiers As Public UI API

The UI tests depend on stable identifiers:

```swift
private func expectElement(_ identifier: String) {
    XCTAssertTrue(element(identifier).waitForExistence(timeout: 2), "Expected element '\(identifier)' to exist.")
}
```

Identifiers such as `deploy-force-button`, `begin-battle-button`, `next-phase-button`, `nearest-enemy-button`, `shoot-target-button`, and `unit-token-<id>` form a public UI API for tests. Changing visible labels should not break tests if behavior remains the same. Changing identifiers should be treated like changing a public function name.

This does not mean identifiers can never change. It means changes should be intentional and tests should be updated with the behavior. A missing identifier can make a playable feature untestable.

## UI Tests That Play

The UI test suite includes tests that play through real interactions:

```swift
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
```

This test does not assert that the shot killed a unit. It asserts that the player can reach Shooting phase, select a ready unit, select a target, press Shoot, and remain in a stable UI. That is valuable at this stage. Playability tests should often check interaction paths before checking perfect tactical outcomes.

Other tests cover deployment, rotation, dragging, movement, target selection, assault controls, cover toggles, phase advancement, and restart. Together they form a smoke test for the player's path through a battle.

## Presentation Files

The presentation layer separates palette, button styles, panel chrome, and display labels from game logic. This is not only aesthetic organization. It keeps views readable. A control section should not need to define every color. A board token should not need to decide global palette. A display label helper can abbreviate token names without changing unit data.

This separation also supports future visual work. The game can become more polished without editing engine or controller logic. Conversely, engine changes should not force style churn unless new states need visual representation.

## UI Failure Modes

Common UI failure modes in this project include stale snapshots, missing accessibility identifiers, controls enabled in wrong modes, text overflowing compact panels, board coordinate drift, panel windows left open after mode changes, and UI commands that bypass recorded actions. The current architecture addresses these, but future edits should be careful.

If a control triggers an engine command directly instead of going through `executeRecordedAction`, save/load may break. If a view calculates legality instead of reading snapshot flags and engine errors, it may drift. If a token lacks an accessibility identifier, UI tests cannot play through it. If a panel owns important state instead of the controller, closing the panel may lose the state.

These are not theoretical. They are typical ways game UIs become brittle.

## Adding A New UI Command

A new UI command should follow a standard path:

1. Confirm the engine command exists or add it.
2. Add a controller method that creates a recorded action.
3. Add a button, toggle, menu, or gesture in the appropriate panel.
4. Use snapshot fields for enabled/disabled and display state.
5. Add an accessibility identifier.
6. Add a UI test if the command is part of normal play.
7. Verify save/load replay if the command changes battle state.

This path keeps the UI as a command surface. It also makes the command discoverable to tests and future maintainers.

## The Chapter's Rule Of Thumb

The UI should make rules playable, not redefine them. It should be direct, readable, and testable. It should show enough state for decisions and route every consequential action through the controller and engine. If the player can do it, the test suite should eventually be able to do it too.

## Inspector As Translation Layer

The inspector is where dense engine state becomes player-readable. A unit snapshot can contain dozens of fields. The player usually needs a meaningful subset: name, owner, kind, model count, wounds, armor, weapon, status, transport relationship, cover state, and action availability. The inspector's job is to organize that information without hiding the important parts.

This is especially important for World War 2 units because categories behave differently. Infantry stats such as WS, BS, S, T, W, I, A, Ld, and save matter. Vehicle armor values matter. Assault guns mix ideas. Transports need passenger information. Mixed-profile units need group summaries. The inspector should respect those distinctions rather than forcing every unit into one generic line.

The snapshot helpers such as `detailSummary`, `shortStatus`, and profile group summaries are part of this translation. They keep the view from repeating formatting logic. If a new unit state becomes important, consider whether it belongs in a snapshot helper before scattering display code across panels.

## Log Panel As Player Memory

The log panel is not just debug output. It is player memory. A battle can contain many dice rolls and state changes. The player may need to know why a unit is pinned, why a tank cannot move, or when an objective changed control. The log makes the sequence visible.

Because log lines come from the engine, they reflect rule decisions. The UI should not rewrite them into a different story. It can style, scroll, or filter logs in the future, but the source should remain the engine. A future log filter could group movement, shooting, assault, and scoring entries. It should still preserve the original lines for traceability.

UI tests currently use phase labels and identifiers more than logs, but logs are useful for manual verification. When a UI interaction test fails, a screenshot plus log panel can often explain what happened.

## Zoom And Viewport

The battlefield shell includes zoom controls. Zoom is a view concern. It changes how the board is displayed, not the underlying coordinates. The slider, zoom buttons, and reset button all manipulate `battlefieldZoom`. The board continues to use `GameController.boardWidth` and `boardHeight` for coordinate conversion.

This distinction should remain. Zoom should never affect game coordinates. A unit at x 12, y 20 is still there at every zoom level. Drag conversion should account for view size, not treat zoom as a rule modifier. UI tests may not deeply cover zoom yet, but the accessibility identifier `battlefield-zoom-slider` makes it available.

Future pan, minimap, or camera features should follow the same rule. They can change view transform. They should not change engine position.

## Control Density And Wargame Expectations

The app is a wargame tool, not a landing page. It needs controls. It needs compact information. It needs visible lists and logs. The design uses panels, sections, monospaced stat lines, badges, and toolbar buttons because players are making repeated tactical decisions.

This affects future UI work. Avoid hiding core commands behind overly decorative screens. Avoid replacing dense force summaries with vague cards. Avoid making the board smaller to show explanatory marketing text. The first screen is setup because setup is a playable activity. The battle screen is the board because the board is the game.

Polish should improve legibility and speed. It should not dilute the command surface.

## UI And Engine Error Relationship

When an engine command fails, `GameController.reload()` updates `lastError`. The command panel can display that error through `BattleErrorSection`. This gives the player immediate feedback. The UI should not swallow failed commands unless there is a clear user-experience reason.

There is a balance here. Some controls can be disabled when snapshots clearly say they are unavailable. But because the engine has the final word, errors remain necessary. A button may be enabled because a unit looks broadly eligible, but the exact target may be out of range or blocked. The engine error explains the finer rule.

If future UI work adds previews, such as showing why a shot is blocked before clicking, keep the error path anyway. Previews can be wrong or incomplete. Engine errors are the final explanation.

## Main Actor And Threading

`GameController` is `@MainActor` because it publishes to SwiftUI. UI tests and helper methods are also marked `@MainActor` where they interact with `XCUIApplication`. This matters with Swift concurrency. The earlier UI test cleanup fixed main-actor isolation errors by keeping app interactions on the main actor. The same principle applies to app code.

Engine commands are called through the controller. AI is scheduled as a task but interacts with controller state safely. If future work introduces background computation, it must not mutate published UI state off the main actor or call the C engine concurrently through the same handle.

The current architecture is simple: one controller, one engine handle, main-actor orchestration. Keep it simple unless there is a strong reason to change.

## Screenshots And Documentation

The README includes screenshots of operation setup and deployment board. Those images are useful because they show the real game, not a concept mockup. The book chapters describe logic; screenshots show the play surface. If the UI changes significantly, documentation images should be updated so new contributors see the current app.

Screenshots also help catch visual drift. A board that still passes tests may look cramped or unclear. Documentation images are not formal tests, but they are a shared reference for the intended experience.

## Accessibility Beyond Tests

Accessibility identifiers are used heavily for tests, but accessibility labels and values also matter for real users. Unit tokens combine labels and values so assistive technology can identify units and owners. Buttons use labels. Panels have identifiers. As the UI grows, accessibility should remain part of feature completion.

A wargame board is visually dense, so accessibility is challenging. Stable identifiers and labels are a start. Future work might expose selected unit details more clearly, provide keyboard navigation, or add list-based unit selection. Those features would also help power users and tests.

## Practical UI Review Checklist

When reviewing UI changes, ask:

- Does this view read from snapshots rather than private engine state?
- Does every consequential command route through the controller?
- Is the control visible in the right app mode?
- Is the disabled state based on reliable snapshot data?
- Is there an engine error path for rejected commands?
- Does the control have an accessibility identifier if tests need it?
- Does text fit in compact panels?
- Does the board remain the primary battle surface?
- Does the change preserve save/replay behavior?

These questions catch many UI bugs before runtime.

## Future UI Opportunities

The current UI can support many improvements without architecture changes: range rulers, legal move previews, target lines, objective control overlays, casualty allocation improvements, richer log filters, keyboard shortcuts, scenario briefing panels, deployment zone highlights, and AI activity indicators. Each should remain a visualization or command surface over engine truth.

For example, a range ruler can use board coordinate conversion and weapon profile ranges. It does not need to alter rules. A legal move preview might ask the engine for candidate legality in a future API, rather than duplicating movement checks. A scenario briefing panel can read historical metadata without changing combat. The architecture leaves room for all of this.

## Final UI Note

The UI's success is measured by whether a player can understand and command the battle. It should feel immediate, but it should never fake success. It should look like World War 2 tactical play, but it should not hide the measured rules beneath the board. The strongest UI in this project is the one that makes the engine's truth feel natural.

## Relationship Between UI Tests And Design

The UI tests are not only regression tools. They describe the minimum playable surface. A test that deploys a force says setup must produce a deployment-ready game. A test that drags a unit says board tokens must be interactive. A test that advances phases says the phase button and phase label must remain discoverable. A test that shoots says target selection and command execution must remain connected. A test that restarts says the app must recover after real play.

This gives design work a practical boundary. A redesigned setup screen is acceptable if the player can still select a force and deploy. A redesigned board is acceptable if tokens remain identifiable and draggable. A redesigned command panel is acceptable if phase advancement, target selection, shooting, and pending choices remain accessible. The tests do not freeze the look. They freeze the playable promises.

When UI tests fail after a design change, read the failure as a conversation. Sometimes the test is stale because the interaction genuinely improved. Sometimes the design removed a needed affordance. Sometimes an accessibility identifier was lost. The fix should preserve both playability and testability.

## UI State That Should Stay Local

Not every state belongs in the engine. Window visibility, zoom level, current panel selection, drag preview, picker focus, and temporary status text belong in Swift. They shape experience but not battle legality. Keeping them local prevents the engine from becoming a UI storage system.

The distinction is useful during review. If a value affects dice, movement, scoring, combat, save replay, or AI, it likely belongs in the engine or recorded configuration. If it affects only how the player views or manipulates existing state, it likely belongs in Swift. Zoom is Swift. Smoke is engine. Selected unit is Swift. Embarked passenger is engine. This mental sorting keeps both layers healthy.

## A Note On Polish

Polish should make the game easier to play repeatedly. Better spacing, clearer buttons, more readable tokens, improved contrast, and smoother panel behavior all matter. But polish should not turn core controls into hidden gestures or vague decorative elements. A wargame UI earns trust by being clear under pressure. The player should know what they selected, what phase it is, what target is chosen, what action is available, and what happened after the action.

That is the standard for future UI work.
