# Chapter 1: The Shape Of The Game

The first thing to understand about `derZweiteWeltkrieg` is that the game is not arranged around screens. It is arranged around a rules core. The screens are important because they make the game playable, but the state of the battle lives in C. That is why the package begins with `DerZweiteWeltkriegCore` in [`../Package.swift`](../Package.swift), then layers `DerZweiteWeltkriegAppUI`, `DerZweiteWeltkriegHistorical`, `DerZweiteWeltkriegGuderian`, and executable hosts above it.

This is a deliberate shape. World War 2 tabletop combat has many pieces of state that must agree: a transport may carry a passenger, a passenger may be pinned after emergency disembarkation, a tank may be immobilized by rough ground, a vehicle weapon may be destroyed while the rest of the vehicle survives, and a mixed-profile squad may need the owning player to assign hits before resolution can continue. Those are not just display facts. They are rules facts. Keeping them in a single engine prevents the UI, tests, and campaign modules from inventing slightly different versions of the same battle.

The package boundary also keeps content pressure away from the engine. `DerZweiteWeltkriegCore` exposes generic World War 2 game concepts: armies, phases, units, weapons, terrain, objectives, actions, and views. `DerZweiteWeltkriegHistorical` defines scenario contracts. `DerZweiteWeltkriegGuderian` holds local scenario and campaign integration. The app UI imports the engine and scenario module, but the engine does not import SwiftUI, AppKit, or campaign code. That direction of dependency is the architecture in miniature.

## The Engine As The Source Of Truth

The public engine API is in [`../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h`](../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h). It defines an opaque `game_t`, enums for players, phases, unit kinds, terrain kinds, follow-up choices, and army lists, plus read-only view structs such as `unit_view_t`, `mission_view_t`, `objective_view_t`, `zone_view_t`, and `weapon_profile_view_t`.

The implementation in [`../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`](../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c) stores the real mutable state in fixed-size arrays inside `struct dzw_game`. That structure contains turn state, the active player, the current phase, selected army identities, units, terrain zones, objectives, mission scores, pending combat choices, a log buffer, and a last-error buffer. In other words, the engine owns both the simulation and the player-facing explanations that fall out of it.

This choice has a practical payoff. The Swift app does not need to know why an action failed. It calls a C function and reloads snapshots. If the player tries to move through impassable terrain, shoot while in the wrong phase, embark too far from a transport, or assault beyond legal range, the engine records the reason. The UI can display that reason without duplicating the rule.

## The App As A Command Surface

The Swift app is centered on [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift). `GameController` is marked `@MainActor` because it publishes state to SwiftUI. It owns the opaque engine handle, publishes `GameSnapshot`, `MissionSnapshot`, units, terrain zones, objective states, logs, pending choices, setup state, battle configuration, and AI status.

The controller does not mutate battle fields directly. It calls engine functions such as `game_move_unit`, `game_shoot_unit`, `game_assault_unit`, `game_use_smoke`, and `game_advance_phase`. After each command it calls `reload()`, converting the latest C state into Swift value snapshots. This gives the UI an ordinary Swift data model while preserving the C engine as the authority.

The command surface pattern appears throughout [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Actions.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Actions.swift). Methods such as `selectUnit`, `moveUnit`, `shootSelected`, `assaultSelected`, `toggleCover`, and `resolvePendingHitAllocation` are small and guarded. They ask whether the app is in setup, deployment, or battle mode; whether it is the human turn; whether the AI is in progress; and whether the needed unit or target exists. Once those app-level checks pass, rule legality belongs to the engine.

## Why The Board Is Measured

The board is not an arbitrary canvas. The C engine exposes `game_board_width()` and `game_board_height()`, and `GameController` publishes them as static CGFloat values. [`../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift`](../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift) maps those measurements into the visible board. Dragging a token converts screen coordinates back into game coordinates. Terrain, objective radii, unit footprints, weapon ranges, and movement distances all share that same coordinate space.

This is important because the rules depend on measured relationships. A move allowance is measured in inches. An enemy separation is measured from footprint edge to footprint edge. Assault range subtracts both units' footprint radii. Objective control depends on presence inside an objective radius. A UI that only moved sprites visually would be easy to build but hard to trust. This code chooses the harder, stronger path: every visual movement is a rules request.

## The Book's Working Assumption

The rest of this book treats the project as a layered promise:

- The C engine promises consistent tabletop rules.
- The Swift bridge promises safe, readable snapshots.
- The controller promises commands, replay, and AI scheduling.
- The UI promises useful player affordances without becoming the rules engine.
- The tests promise that representative scenarios keep working as the game grows.

That promise is what lets the project absorb more World War 2 detail. New weapons, nations, scenarios, and UI panels should strengthen this shape, not bypass it.

## Package Topology As Design

The package layout is a map of the design argument. `Package.swift` declares `DerZweiteWeltkriegCore` first, then the content and app targets that depend on it. The most important part is not the exact list of products, but the dependency direction:

```swift
.target(
    name: "DerZweiteWeltkriegCore",
    path: "Sources/DerZweiteWeltkriegCore",
    publicHeadersPath: "include",
    cSettings: [
        .define("HEINZ_GUDERIAN_GAME"),
    ]
),
.target(
    name: "DerZweiteWeltkriegGuderian",
    dependencies: [
        "DerZweiteWeltkriegCore",
        "DerZweiteWeltkriegHistorical",
    ],
    path: "Sources/DerZweiteWeltkriegGuderian"
),
.target(
    name: "DerZweiteWeltkriegAppUI",
    dependencies: [
        "DerZweiteWeltkriegCore",
        "DerZweiteWeltkriegGuderian",
    ],
    path: "Sources/DerZweiteWeltkriegApp"
)
```

This target graph tells maintainers where a new idea should enter. A rule goes in the core. A historical scenario contract goes in the historical target. A Guderian-specific scenario catalogue or campaign adapter goes in the Guderian target. A button, picker, panel, board label, or gesture goes in the app UI target. The graph also tells maintainers what not to do: the core should not need to know that a SwiftUI view exists, and it should not import scenario-specific Swift modules to answer a combat question.

The `HEINZ_GUDERIAN_GAME` define may look like an exception because it appears in the core target settings. In practice it enables bounded integration hooks in the C implementation, such as storage for Guderian scenario labels and a board-application function. The important thing is that the core still receives scenario data through plain C structures and arrays. It does not become a campaign module. The scenario layer is allowed to provide terrain and objectives; the core still decides how terrain and objectives behave.

The app executable is also deliberately thin. The product `DerZweiteWeltkriegApp` depends on `DerZweiteWeltkriegAppUI`, which already owns the SwiftUI screens. This keeps the host as a launch point rather than a gameplay container. That matters for testing and future reuse. A different host can import the same UI module, and command-line or test targets can import the core without dragging in AppKit.

## Why C Is The Engine Language

The core being C is not incidental. C gives the engine a small, predictable ABI that Swift can import directly. It also encourages explicit state. The battle is stored in fixed-size arrays and plain structs rather than object graphs with hidden ownership. In a rules engine, explicit state is a virtue because it makes invariants inspectable.

The private `game_t` implementation has a shape like this:

```c
struct dzw_game {
    uint32_t rng_state;
    int turn_number;
    player_t active_player;
    phase_t phase;
    army_list_t player_one_army;
    int player_one_force;
    army_list_t player_two_army;
    int player_two_force;
    int unit_count;
    unit_t units[DZW_MAX_UNITS];
    int zone_count;
    zone_t zones[DZW_MAX_ZONES];
    const char *mission_name;
    int mission_target_score;
    int player_one_score;
    int player_two_score;
    int objective_count;
    objective_t objectives[DZW_MAX_OBJECTIVES];
    bool pending_weapon_destroy_active;
    bool pending_hit_allocation_active;
    int log_count;
    char logs[DZW_MAX_LOG_LINES][DZW_LOG_LINE_LENGTH];
    char last_error[DZW_LOG_LINE_LENGTH];
};
```

That excerpt leaves out many fields, but even the shortened version shows the design. A battle has no external database and no UI-controlled cache. It has a random state, turn state, selected armies, arrays of units and board features, mission score, pending choices, logs, and error state. When a command runs, it updates this one structure. When a view reloads, it projects from this one structure.

Fixed-size arrays are a tradeoff. They place an upper bound on units, zones, objectives, weapons, profile groups, logs, and pending options. The benefit is that the engine can avoid allocation during normal play and can expose stable C view functions without asking Swift to manage ownership of internal collections. For a demo-scale tabletop battle, that is a sensible bargain. The game wants predictable behavior more than unbounded scale.

The C layer also centralizes dice. `rng_state` belongs to the game, so a seed can produce repeatable outcomes. That is essential for tests and replay. If Swift views rolled dice independently, a saved action sequence could drift when loaded. If AI rolled outside the engine, the same setup might diverge depending on UI scheduling. Keeping random resolution in the engine lets the seed, rules, and action log define the battle.

## Snapshot Flow

The app receives state by reload. The pattern in `GameController.reload()` is direct:

```swift
func reload() {
    let gameView = game_view(handle)
    game = GameSnapshot(
        turnNumber: Int(gameView.turn_number),
        activePlayer: gameView.active_player,
        phase: gameView.phase
    )
    mission = MissionSnapshot(raw: game_mission_view(handle))

    units = (0..<Int(game_unit_count(handle))).map { index in
        UnitSnapshot(raw: game_unit_view(handle, Int32(index)))
    }
    zones = (0..<Int(game_zone_count(handle))).map { index in
        ZoneSnapshot(raw: game_zone_view(handle, Int32(index)))
    }
    objectiveStates = (0..<Int(game_objective_count(handle))).map { index in
        ObjectiveSnapshot(raw: game_objective_view(handle, Int32(index)))
    }
}
```

The value of this reload style is that Swift does not retain C pointers into mutable engine arrays. It copies the current public view into Swift structs. A SwiftUI view can read those structs without worrying that a C command will mutate them mid-render. After the next command, `reload()` publishes a new set of values and SwiftUI refreshes.

This is especially important for asynchronous AI. The controller may schedule an AI task when the active player becomes Player 2. That task repeatedly calls engine commands and reloads. If SwiftUI were holding direct pointers to units, the UI would be exposed to mutation while rendering. Snapshot values keep the model simple: the controller is the one bridge point, and it runs on the main actor.

The snapshot flow is also what makes UI tests feasible. A test can tap a button, wait for an accessibility element, and inspect visible labels. It does not need to reach into private engine memory. The visible UI is derived from the same snapshots a player sees.

## State Ownership And Failure Modes

The architecture prevents several common failure modes in game code.

The first is split truth. If the app stored a selected unit position separately from the engine and forgot to reconcile it after a rejected move, the visible token and rule state would disagree. In this code, `dragPreview` is temporary. It is cleared on drag end, then the engine result determines the token's actual position.

The second is partial rule enforcement. If the UI disabled a button based on its own approximation of legality, but the engine allowed something different, tests and players would eventually find inconsistent behavior. This project accepts that the UI may show some controls optimistically, but the engine remains final. The user-facing error log is part of that design. A failed action is not silent; it teaches the current rule boundary.

The third is persistence drift. If saves were snapshots of Swift UI state, then engine changes could make old saves meaningless. Instead, a saved battle is a configuration plus recorded engine commands. Loading replays through the same public API used by live play. That is slower than raw serialization but more explainable.

The fourth is content leakage. Historical modules can describe battles and provide board data, but they do not own combat rules. This keeps the game from developing one set of rules for skirmish setup and another for campaign scenarios.

## A Walk Through A Player Action

Consider a simple player action: selecting a unit and dragging it on the board during Movement. The board view converts the pointer location into board coordinates. It does not move the engine unit directly. Instead it calls `controller.moveUnit(id:to:)`. The controller checks app mode. If the app is in deployment, it records a deploy action. If the app is in battle, it requires a human turn and records a move action. That action passes through `executeRecordedAction`, which calls `game_move_unit` in C.

The engine then checks pending choices, ownership, phase, pinning, falling back, assault locks, vehicle stun, immobilization, board limits, terrain, movement allowance, and enemy separation. If the action is valid, it updates the unit, syncs any embarked passenger, logs the move, and returns true. If not, it records `last_error` and returns false. The controller reloads either way. The UI shows the updated board or the previous legal position plus an error message.

That sequence crosses many files:

- `BattleBoardView` handles the gesture and coordinate conversion.
- `GameController+Actions` chooses the action kind.
- `GameController+Skirmish` executes and records the action.
- `der_Zweite_Weltkrieg.c` applies rules.
- `GameController.reload()` republishes snapshots.
- Sidebar and board views redraw.

The key is that each layer has one job. The board is physical input. The controller is command routing. The engine is rule resolution. The snapshots are presentation data. The UI is feedback.

## Why This Helps Future Development

The game is intended to grow: more nations, more armor, more artillery, more scenario detail, and more campaign structure. Growth is only safe if the base shape stays understandable. This architecture gives maintainers a decision procedure.

If a new feature affects dice, casualties, legal movement, scoring, phase order, transport state, morale, weapon destruction, or AI replay, it should begin in the C engine. If it affects how a player chooses from existing legal actions, it belongs in Swift. If it affects historical description, source links, map annotations, or scenario metadata, it belongs in the historical or Guderian layer. If it affects how a battle can be saved and reloaded, it must pass through `RecordedBattleAction`.

This is why the book starts with shape rather than details. The shape is what makes the details maintainable. World War 2 tabletop systems are full of exceptions, special cases, and equipment distinctions. Without a strong architecture, those details become scattered conditionals in the UI. With this architecture, details can be added to the rules engine and exposed deliberately.

## Reading The Repository With The Shape In Mind

When navigating the source, read from the bottom upward. Start with the public C header to understand available nouns and verbs. Then read the C implementation for private state and rule behavior. Then read Swift snapshots to see what is exposed. Then read the controller to see how the app issues commands. Finally, read views to see how the player interacts with those commands.

This bottom-up reading order mirrors runtime truth. The visible app is lively, but it is a surface. The battle is the engine. The more changes respect that direction, the easier the project remains to reason about.

## Determinism, Debugging, And The Log

The architecture also makes debugging humane. A battle can be described by a seed, a starting configuration, and a sequence of actions. The engine owns dice, so the same seed and the same commands should produce the same broad outcome unless the rules have intentionally changed. The app records commands, so a strange event can be reconstructed. The engine logs, so the reconstruction has a narrative trail.

This matters more in a wargame than in many other applications. A player may report that a tank was immobilized while crossing rough ground, that a mortar pinned a squad unexpectedly, or that an assault did not proceed because the unit had fired a heavy weapon. Without engine logs, every report becomes a forensic exercise. With engine logs, the game can say what it thought happened.

The log is not a substitute for tests, but it is the human-facing half of the same discipline. Tests assert the state. Logs explain the state. The engine produces both from the same rule code. That is better than writing separate explanatory text in Swift because the explanation stays near the branch that caused it.

The last-error buffer has a similar role. Failed commands are expected during play. A player may drag too far, attempt to fire out of range, select a friendly target, or ask a pinned unit to move. Those attempts should not crash and should not silently do nothing. The engine clears the old error at the start of an action, then records a specific reason if the action fails. Swift reloads and displays the result. This transforms failed input from a bug-shaped experience into rules feedback.

## Why The UI Does Not Precompute Everything

It can be tempting to make the UI smart enough to avoid every invalid action. For example, the app could calculate movement range overlays, firing arcs, and legal assault bands. Some of that may eventually be useful. But the present architecture keeps a crucial distinction: UI predictions are assistance, not authority.

The reason is that complete legality can be surprisingly expensive to duplicate. A move depends on terrain intersections, difficult terrain tests, unit kind, immobilization, pinning, falling back, locks, board bounds, and enemy spacing. Shooting depends on phase, range, line of sight, barrage exceptions, mounted arcs, movement distance, weapon destruction, smoke, and target status. Assault depends on range, difficult terrain, previous firing, initiative, cover, vehicle kind, and pending mixed-profile choices.

Duplicating all of that in Swift would produce two rule engines. Even if both were correct today, they would drift. The chosen architecture lets the UI be selective. It can disable obvious impossible controls, such as battle-only commands during setup. It can show action buttons based on snapshot flags like `canMoveNow`, `canShootNow`, and `canAssaultNow`. But when a real command is attempted, the C engine still decides. This gives the player a guided interface without making UI state sacred.

## The Board As A Shared Coordinate Contract

The board coordinate contract is one of the cleanest examples of layered design. The C engine defines the board dimensions. The Swift controller reads them. The board view scales them. The gesture recognizer maps pointer movement back to them. Terrain zones and objectives are drawn with them. Unit footprints, weapon ranges, movement allowances, and separation rules use them.

That shared coordinate contract is why the UI can be visual without becoming decorative. A token's screen location corresponds to a rules location. A terrain rectangle corresponds to a rules zone. An objective ring corresponds to the radius used for control. The player can develop spatial intuition because the visual and mechanical spaces are the same.

The code below from the board view is small, but it is central:

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

One function projects rules coordinates into pixels. The other projects pixels back into rules coordinates. This symmetry is why drag-and-drop can stay simple. It is also why future overlays, measurement tools, firing lines, or deployment zones should use the same mapping helpers or equivalent logic.

## App Modes And Engine Phases

Another design distinction worth preserving is the difference between app modes and engine phases. `setup`, `deployment`, and `battle` are app modes. Movement, Shooting, and Assault are engine phases. They are related, but they are not the same kind of state.

Setup is a pre-game composition mode. The engine may already have a default demo handle allocated so the app can show previews, but the player's draft is still Swift setup state. Deployment is a pre-battle manipulation mode over a real game. Units exist in the engine, but repositioning them uses deployment commands that do not consume movement. Battle mode is the actual turn engine.

This distinction avoids awkward phase hacks. Deployment is not "Movement phase but do not spend movement"; it is an app mode that routes to `game_deploy_unit`. Setup is not "Turn zero"; it is a Swift configuration workflow. Battle is where engine phases become meaningful to player turns.

The controller is the right place for this distinction because it sees both layers. The engine should not know about Swift setup panels. The board view should not decide rule semantics. The controller can translate app mode into command kind:

```swift
switch appMode {
case .deployment:
    kind = .deployUnit
case .battle:
    guard isHumanTurn else { return }
    kind = .moveUnit
case .setup:
    return
}
```

That small switch is a boundary marker. It keeps app workflow flexible while letting the engine stay focused on commands.

## Architectural Tests To Keep In Mind

There are a few mental tests that help protect the architecture during future changes.

First, ask whether a change can be tested without launching the app. If the change is a rule, the answer should be yes. A new weapon effect, vehicle state, or movement restriction should be covered through `DerZweiteWeltkriegTests` using the C API. If it cannot be tested there, the rule may have been placed too high in the stack.

Second, ask whether a saved battle can replay the change. If the player can trigger it, then `RecordedBattleAction` or engine initialization must capture it. A live-only action is a persistence bug waiting to happen.

Third, ask whether the AI needs to understand the choice. If a new pending decision can belong to Player 2, the AI must be able to resolve it. Otherwise the game can hang on the AI turn.

Fourth, ask whether the UI is displaying source truth or inferred truth. Displaying `unit.pinned` from a snapshot is source truth. Guessing pinning by scanning log text is inferred truth. The first is maintainable. The second is brittle.

These tests are simple, but they make the architecture actionable. They turn "keep the engine authoritative" into concrete review questions.

## The Maintainer's Mental Model

A useful way to picture the codebase is as a table with four layers. The bottom layer is the battlefield ledger: the C engine's arrays, counters, flags, and pending state. The next layer is the public contract: C view structs and command functions. The third layer is Swift orchestration: snapshots, selection, setup, recorded actions, AI scheduling, save/load, and app modes. The top layer is presentation: board drawing, panels, buttons, labels, colors, accessibility identifiers, and tests that interact with the UI.

Most bugs can be located by asking which layer owns the failed promise. If a unit is legally wrong, look down in the engine. If the engine is right but Swift is stale, inspect reload and snapshot conversion. If the snapshot is right but the button is missing, inspect the view. If the UI works live but a saved battle diverges, inspect recorded actions and replay. This layered debugging model is one of the strongest reasons to keep the current shape.

It also helps when reading pull requests. A change that adds a weapon profile and a catalogue entry belongs mostly to Chapter 3 and Chapter 4 concerns. A change that adds a new pending choice belongs to Chapter 7 and Chapter 8 concerns. A change that only renames a panel or changes a color should not touch the C engine. When a patch crosses layers, it should do so because the feature truly crosses layers, not because the author reached for whichever file was convenient.

The game will inevitably become more detailed if it continues to grow. More detail does not have to mean more confusion. The architecture already has room for complexity when it enters through the right door.

That is the point of beginning the book here. Before studying army lists, tanks, artillery, AI, or UI panels, the maintainer should know where truth lives. The rest of the code is much easier to change once that question has a stable answer: truth begins in the engine, crosses the public contract, becomes Swift snapshots, and only then becomes visible play.

Everything else in the repository is a variation on that movement from rule to representation.

When in doubt, follow that path slowly and the design usually explains itself.

That patience is a practical engineering tool here, not just a reading preference for future maintainers and contributors.
