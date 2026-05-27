# Chapter 8: Setup, AI, And Replay

The playable demo begins before the first move. The player chooses a nation, drafts a force to a points cap, lets the computer draft an opposing force, deploys units, and then begins battle. This whole flow is coordinated by Swift, but it depends on engine catalogues for legality and engine actions for the actual battle.

The setup surface is [`../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift`](../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift). It displays the operation title, nation picker, points cap, unit steppers, current draft total, AI opponent plan, action buttons, and status messages. The controller behind it is [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift), with setup and AI logic in [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift).

## Setup State

`GameController` stores setup state as stable Swift values: selected player army ID, force index, opponent army ID, points limit, seed text, current unit counts, setup message, current battle configuration, and current opponent plan. This state is app-level. It is not part of `game_t` until the player starts a battle.

When the player taps Deploy Force, `startBattleFromSetup()` validates the selected nation, selected points, points cap, and AI plan. It then creates a `SkirmishConfiguration` with seed, points limit, player army ID, player selections, AI army ID, and AI selections. The controller loads that configuration through `loadConfiguration`, which calls the C engine's skirmish creation/reset path.

This separation is useful because setup may change many times before a battle exists. The engine does not need to model half-built lists. It only receives a legal selected list.

## Opponent Drafting

The AI opponent plan uses the same catalogues as the player. `suggestedOpponentPlan()` filters army references to opposing allegiance, then asks `bestOpponentPlan` to build a point-matched selection. `bestOpponentPlan` flattens each catalogue entry by its max count, then uses a small dynamic programming table to find a combination close to the target points.

This is intentionally a draft assistant, not a strategic doctrine. It solves setup pacing: when the player changes a unit count or points cap, the opponent updates. It also keeps the AI honest by using the same point values and max counts. A future smarter opponent could prefer anti-tank answers, infantry density, or scenario-specific profiles, but it should still build from the catalogue contract.

## Recorded Actions

`RecordedBattleAction` in [`../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift) is the bridge between UI commands and persistence. Its `Kind` enum mirrors public engine commands: deploy, rotate, advance phase, move, tank shock, embark, disembark, cover, hull down, smoke, shoot, passenger fire, assault, weapon-destroy choice, hit-allocation choice, and casualty preference.

The controller funnels most battle commands through `executeRecordedAction`. That function switches on action kind, calls the corresponding C API, reloads snapshots, appends the action if it succeeded, and optionally schedules the AI. This gives the game a single command log that can represent human actions and AI actions.

The consequence is important: save files do not need to know every engine field. They store the initial configuration plus the action list. Loading can recreate the battle by replaying actions. This keeps persistence aligned with the public engine contract and makes save format more durable than dumping private memory.

## Save And Load

`SavedSkirmishDocument` contains version, configuration, actions, and mode. Versioning starts simply but gives room for migration. The load initializer defaults missing version and mode for older files. Save and load use JSON through AppKit panels in the macOS app.

This design has a clear philosophical stance: a saved battle is a story of choices, not a memory image. That makes bugs easier to investigate. If a loaded battle behaves differently, the action sequence can be inspected. If a command changes behavior, tests can reveal whether replay expectations need to move.

## AI Turn Execution

The AI turn is scheduled when the battle is active, replay is not in progress, no AI turn is already running, no winner exists, and the active player is `DZW_PLAYER_TWO`. The AI also refuses to proceed if a human-owned pending choice is blocking resolution.

The AI loop handles phases:

- In Movement, it moves active units toward objectives or enemies, then advances phase.
- In Shooting, it tries target candidates for each unit, resolves AI-owned pending choices, handles passenger fire, and advances phase.
- In Assault, it looks for close targets, assaults when legal, resolves AI-owned pending choices, and advances phase.

Target priority favors distance, objective relevance, and vehicle targets. Movement candidates step toward a target with several angle offsets, clamped to the board. This is simple and readable by design. It creates an opponent that plays enough of the game to exercise systems without hiding behavior behind a black box.

## The Rationale

Setup, AI, and replay share one idea: treat actions as the durable interface. The player builds a configuration, the engine creates a game, the controller records commands, the AI produces the same kind of commands, and save/load replays them. This makes the playable demo easier to debug and easier to extend.

When adding a new player action, remember the full chain. Add the C command, add the Swift recorded action kind, execute it through `executeRecordedAction`, expose it in the UI, decide whether the AI can use it, and test it. Skipping replay support means the feature may work live but fail as soon as a battle is saved.

## Setup As A Separate Product Surface

The setup screen is not a menu before the game. It is part of the game. It teaches the available nations, shows the point cap, previews units, builds the player's force, and generates an opposing plan. It is the first place where army catalogues become player choice.

The code keeps setup state in `GameController` rather than in the C engine until the player starts an operation. That is the right boundary. During setup, the player may change nations, step unit counts up and down, adjust the points cap, or change the seed. Those are draft edits, not battle events. The engine should only receive a legal configuration once the player commits.

The relevant state is visible in the controller:

```swift
@Published var currentBattleConfiguration: SkirmishConfiguration?
@Published var currentOpponentPlan: GeneratedOpponentPlan?
@Published var isAITurnInProgress: Bool = false
@Published var setupMessage: String = ""
@Published var playerUnitCounts: [Int: Int] = [:]
@Published var pointsLimit: Int = 750
@Published var seedText: String = "1944"
```

This state is UI workflow data. It describes what the player is drafting and what the app is ready to load. It does not replace engine battle state.

## Starting A Battle

`startBattleFromSetup()` is the gate between draft and battle. It validates that the player has chosen a nation, has selected at least one unit, is within the points cap, and has an opponent plan. Then it creates `SkirmishConfiguration`:

```swift
let configuration = SkirmishConfiguration(
    seed: UInt32(seedText) ?? 1_944,
    pointsLimit: pointsLimit,
    playerArmyID: playerArmy.id,
    playerSelections: playerSelections,
    aiArmyID: opponentPlan.army.id,
    aiSelections: opponentPlan.selections
)
loadConfiguration(configuration, replaying: [], mode: .deployment)
```

The battle begins in deployment mode, not immediately in battle mode. That gives the player a pre-battle placement step. The configuration contains only stable, saveable data: seed, point cap, army IDs, and selected catalogue entries. It does not contain Swift views or transient selections.

This is a strong persistence design. If the setup state can be converted into `SkirmishConfiguration`, it can be saved, loaded, tested, and replayed.

## Configuration Loading

`loadConfiguration` is the controller's bridge from setup or save file into engine state. It cancels AI, clears selection, updates setup fields, stores the current configuration, converts Swift army IDs into C army enums, creates C `army_list_entry_t` arrays, resets or creates the engine skirmish, replays actions if any, reloads snapshots, and enters the requested mode.

This function is where several book chapters meet:

- Chapter 2's C contract receives `game_create_skirmish` or reset calls.
- Chapter 3's catalogues interpret army list entries.
- Chapter 6's app modes decide deployment or battle.
- Chapter 8's recorded actions replay the timeline.
- Chapter 9's UI redraws from the new snapshots.

Because `loadConfiguration` is a crossing point, it should remain careful. It should not silently ignore invalid armies. It should not partially replay actions while AI is active. It should not leave stale selections. It should not create a battle without reloading snapshots.

## The Opponent Plan As Draft AI

The opponent plan is not the same as battlefield AI. It is draft AI. Its job is to choose a legal opposing force that roughly matches the player's points. It uses allegiance to choose candidates and dynamic programming to find a list.

The plan is represented by:

```swift
struct GeneratedOpponentPlan: Hashable {
    let army: ArmyReference
    let selections: [ArmyListSelection]
    let points: Int
}
```

This is intentionally small. It does not include a battle plan, scripted behavior, or hidden advantage. It is just the force the AI will bring. The battlefield AI then plays that force using phase routines.

Keeping draft AI and battlefield AI separate is useful. A smarter draft system can be built later without changing movement and shooting AI. A smarter battlefield AI can be built without changing setup. Both use the same catalogues and engine commands.

## Dynamic Programming Details

The opponent plan builder flattens catalogue entries by `maxCount`, then performs a bounded knapsack-like search up to the target points. The stored choice includes counts and unit count. At each total, the algorithm keeps the choice with more units if point total ties. At the end it chooses the highest reachable total within cap.

This is not complicated AI, but it is deterministic and explainable. It avoids random bad drafts. It respects max counts. It produces a force near the player's size. It is fast enough for setup updates when steppers change.

The algorithm's limitations are also clear. It does not currently reason about role coverage. It may choose a force with weak anti-armor if the points fit. It does not read scenario objectives. It does not consider player composition beyond total points. Those are opportunities for future development, not hidden surprises.

If role-aware drafting is added, it should probably classify catalogue entries by role and score candidate plans. But it should still respect points and max counts. It should still produce `GeneratedOpponentPlan`.

## Recorded Actions As The Save Backbone

`RecordedBattleAction` is the backbone of save/load:

```swift
struct RecordedBattleAction: Codable, Hashable {
    enum Kind: String, Codable {
        case deployUnit
        case deployRotate
        case advancePhase
        case moveUnit
        case tankShock
        case embark
        case disembark
        case rotate
        case toggleCover
        case toggleHullDown
        case useSmoke
        case shoot
        case firePassenger
        case assault
        case chooseWeaponDestroy
        case chooseHitAllocation
        case setPreferredCasualtyGroup
    }

    let kind: Kind
    var unitID: Int?
    var targetID: Int?
    var transportID: Int?
    var optionID: Int?
    var groupIndex: Int?
    var pointX: Double?
    var pointY: Double?
    var degrees: Double?
    var enabled: Bool?
    var followUp: FollowUpChoice?
}
```

The action type is intentionally sparse. Each kind uses only the fields it needs. This keeps JSON readable and avoids creating many small structs. It also makes versioning manageable. Future actions can add optional fields without breaking older documents, as long as decoding remains tolerant.

The design cost is that `executeRecordedAction` must validate fields for each kind. That cost is acceptable because it centralizes command execution.

## Executing Recorded Actions

`executeRecordedAction` translates a recorded action into a C command, reloads, records success, and schedules AI:

```swift
@discardableResult
func executeRecordedAction(_ action: RecordedBattleAction, record: Bool = true, triggerAI: Bool = true) -> Bool {
    let succeeded: Bool

    switch action.kind {
    case .moveUnit:
        guard let unitID = action.unitID,
              let pointX = action.pointX,
              let pointY = action.pointY else {
            return false
        }
        succeeded = game_move_unit(handle, Int32(unitID), Float(pointX), Float(pointY))
    case .shoot:
        guard let unitID = action.unitID, let targetID = action.targetID else {
            return false
        }
        succeeded = game_shoot_unit(handle, Int32(unitID), Int32(targetID))
    case .advancePhase:
        game_advance_phase(handle)
        succeeded = true
    default:
        ...
    }

    reload()
    if succeeded && record {
        recordedActions.append(action)
    }
    if succeeded && triggerAI && !isReplayingBattle {
        scheduleAITurnIfNeeded()
    }
    return succeeded
}
```

The real function covers every action. The important pattern is that all roads go through it. Human clicks, AI choices, and replayed save actions use the same translation. That means a bug in action execution is visible across live play and replay, which is easier to diagnose than separate code paths.

## Save Documents

The save document stores version, configuration, actions, and mode:

```swift
struct SavedSkirmishDocument: Codable {
    let version: Int
    let configuration: SkirmishConfiguration
    let actions: [RecordedBattleAction]
    let mode: AppMode
}
```

This document is readable JSON. That is useful during development. A saved operation can be inspected, diffed, and sometimes edited by hand. More importantly, it describes intent rather than memory. The game is recreated by performing the same actions.

The decoder defaults missing version and mode for older documents. This is a small but wise versioning step. Save formats live longer than code assumptions. Future migrations may need to translate army IDs, action names, or configuration fields. Starting with a version field gives that work a place to happen.

## Replay Mode

The controller tracks `isReplayingBattle` to prevent replay from scheduling AI or duplicating action records. During load, actions should be applied as history, not as new live decisions. If replay triggered AI after every loaded action, the loaded battle would diverge. If replay appended actions again, the save would grow incorrectly.

This is a subtle but essential distinction. Live command execution and replay command execution use the same C commands, but their side effects in the controller differ. `record` and `triggerAI` parameters make that distinction explicit.

When adding new side effects to command execution, consider replay. Does the side effect need to happen when loading? Logs and state changes should happen because the C command runs. UI notifications, AI scheduling, or panel focus changes may not.

## Battlefield AI Movement

The battlefield AI moves toward objectives first, then enemies. It generates candidate points by stepping toward a target with angle offsets and decreasing distances. It clamps candidates inside the board and tries them through `game_move_unit`. The engine decides legality.

This is simple but robust. The AI does not need its own pathfinding legality. It proposes moves. The engine accepts or rejects. If the direct route is blocked, angle offsets may find an alternate. If all candidates fail, the unit simply does not move.

The movement AI also respects phase and active unit availability because it derives candidates from snapshots. This means an immobilized vehicle, pinned infantry unit, or embarked passenger should not be moved by AI unless snapshots and engine commands allow it.

## Battlefield AI Shooting And Assault

Shooting AI sorts target candidates by edge distance, objective bias, and vehicle bias. It tries to shoot until a command succeeds. It resolves AI-owned pending choices, including weapon destruction and hit allocation. It also tries passenger fire when applicable.

Assault AI filters target candidates by distance and attempts assault with advance follow-up. It is conservative and simple. That is acceptable for the demo. The goal is to exercise assault controls and create pressure, not to outperform a human.

Because AI actions are recorded, AI turns become part of save history. That is valuable. A loaded battle should include what the AI did, not recalculate a different AI response from the same position unless deliberately restarted.

## Human Blocking Decisions

The AI stops when the human must resolve a pending choice. This prevents the computer from racing through its turn while the player owes a casualty or weapon decision. Pending choices include chooser ownership, so the controller can distinguish AI-owned decisions from human-owned decisions.

This pattern is necessary for fairness and clarity. If the AI shoots a human mixed-profile squad, the human should assign hits before the AI continues. If the AI damages its own vehicle and must choose a weapon loss, the AI can resolve that automatically. Ownership of pending decisions is therefore part of playability.

## Error Handling In Setup

Setup errors use `setupMessage`. Examples include missing nation, empty force, over-cap force, or missing opponent plan. These are not engine errors because they happen before a skirmish is loaded. They are app workflow messages.

Once battle starts, engine errors come from `game_last_error`. Keeping setup messages and engine errors distinct helps maintainers locate problems. If the player cannot start, inspect setup validation. If a command fails during battle, inspect engine rules.

## Adding A New Action To Replay

Adding a new action requires a full path:

1. Add the C command or identify the existing command.
2. Add a `RecordedBattleAction.Kind`.
3. Add associated optional fields if needed.
4. Add execution logic in `executeRecordedAction`.
5. Route UI controls through a controller method that creates the action.
6. Decide whether AI can use it.
7. Decide whether replay should trigger AI afterward.
8. Add tests for live behavior and save/load if the action is significant.

This path may feel repetitive, but it is what makes the game reliable. A command that cannot be replayed is not truly part of the saved battle.

## The Chapter's Rule Of Thumb

Setup creates a configuration. Battle play creates an action history. Save files store both. AI uses the same actions. Replay uses the same engine commands. That loop is the reason `derZweiteWeltkrieg` can be a playable demo rather than a one-session prototype. Preserve the loop and features will remain debuggable.

## Seeds And Repeatability

The setup seed is more than a decorative field. It is the starting point for deterministic dice. The default value, `1944`, is thematic, but the important behavior is that a seed becomes part of `SkirmishConfiguration`. When a battle is saved, the seed is saved. When it is loaded, the same seed initializes the engine before actions replay.

This means a saved battle is not merely a list of actions. It is a list of actions against a seeded rules engine. If the same configuration and action list are replayed under the same rules, the result should be stable. If the result changes, maintainers can look for an intentional rules change or a replay bug.

Seeded repeatability is especially valuable for combat. Dice-heavy systems can be difficult to debug if outcomes shift every run. A failing test or strange save can be replayed with the same seed. That does not make every game predictable to the player, but it makes development tractable.

## JSON As A Development-Friendly Format

The save system uses JSON through `JSONEncoder` and `JSONDecoder`. This is not the most compact format, but compactness is not the priority. Readability is. During active development, a JSON save can be opened and inspected. The configuration, mode, and actions are visible. If a saved game fails to load, the document can be understood without a binary parser.

The encoder uses pretty printing and sorted keys. That makes saved operations easier to diff and review. A future automated test could store fixture saves and compare behavior across versions. Human-readable saves make that practical.

There is a tradeoff. JSON documents can refer to catalogue IDs that change meaning if catalogues are reordered. That means catalogue IDs should be treated as stable within an army once saves exist. If IDs must change, migration code should translate old documents. The presence of a `version` field makes that possible.

## UI Tests As Replay's Cousin

The UI tests that play a game are conceptually related to action replay. They launch the app and perform visible actions: deploy, drag, begin battle, advance phase, select nearest enemy, shoot, check assault controls, toggle cover, toggle hull down, and restart. These tests do not serialize `RecordedBattleAction`, but they exercise the same command path.

This is valuable because replay can prove the command model, while UI tests prove the command surface. A move action may replay correctly but the drag gesture could be broken. A shoot action may work in C but the Shoot button could lose its accessibility identifier. Both layers need coverage.

When adding a new major action, consider adding both a core/replay-style test and a UI interaction test. The core test proves rules. The UI test proves playability.

## Restart Semantics

Restarting a battle is different from loading a save and different from returning to setup. `restartCurrentBattle()` keeps the current configuration, uses the seed text, clears replay actions, reloads the battle, and returns to the resumable mode. This gives the player a way to try again without redrafting.

The restart behavior should stay clear. If restart preserved recorded actions, it would not be a restart. If restart discarded the current configuration, it would be return-to-setup. If restart allowed AI tasks to keep running, it could corrupt the new battle. That is why `cancelAI`, `clearSelection`, and reload logic matter.

The UI test `testPlaysSeveralInteractionsThenRestartsBattle` is important because restart crosses several systems. It starts a battle, performs actions, shoots, restarts, and expects battle state to be usable again.

## Load Mode And Resuming

Save documents include `mode` because loading into setup, deployment, or battle changes user experience. A battle saved during deployment should return to deployment. A battle saved during battle should resume battle and schedule AI if needed. A setup-only draft may be represented differently in future versions.

The current `SavedSkirmishDocument` defaults missing mode to `.battle`, which protects older saves. Future formats may need more nuanced migration, but the pattern is present.

Mode is also why `resumableAppMode` exists. Returning to setup does not necessarily destroy the current battle. The player may adjust view or setup state and resume. This app-level workflow would be awkward if encoded as engine phase. Keeping it in Swift is cleaner.

## AI Safety And Cancellation

AI is asynchronous through a `Task`. That creates lifecycle responsibility. Starting or loading a new battle must cancel any old AI task. Returning to setup must cancel AI. Deinitializing the controller must cancel AI before destroying the engine handle.

This matters because the engine handle is not thread-safe application state for arbitrary concurrent mutation. The controller is `@MainActor`, and AI commands flow through controller methods. If an old task kept running after a reset, it could issue commands against the wrong battle. The cancellation calls are therefore part of correctness, not cleanup decoration.

When adding longer AI thinking, animations, or delays, preserve cancellation points. A responsive app should stop old AI work when the battle changes.

## What Future Campaign Saves May Need

The current save file stores one skirmish operation. Campaign systems may need more: roster persistence, casualties between battles, named commanders, scenario progress, unlocked forces, historical branches, or accumulated scores. Those should probably live in a campaign document that references or contains skirmish documents.

The skirmish save design is still useful. Each battle can remain configuration plus actions. The campaign layer can decide which configuration to create next. This keeps tactical replay separate from strategic progress.

If campaign saves are added, avoid putting campaign-only fields into the C engine. The core engine should finish a battle and report results. Campaign modules can interpret those results.

## Practical Debugging Workflow

When a save/load bug appears, follow the loop:

1. Inspect the JSON configuration.
2. Check the seed.
3. Check the mode.
4. Read the action sequence.
5. Replay mentally or with tests until the first failing action.
6. Determine whether the C command failed, the action lacked fields, or the controller side effect was wrong.

This is much easier than debugging a binary snapshot. The action log makes the battle narrative explicit.

## Final Replay Note

The setup and replay system is modest, but it gives the project a durable spine. Players can start, save, load, restart, and fight an AI that uses the same public commands. That is a major threshold for a playable game. Future work should deepen it, not replace it with hidden state shortcuts.

The practical promise is simple: if something happened in a battle, it should be possible to describe how it happened. The configuration says what forces and seed began the operation. The action list says what players and AI did. The engine logs say what the rules produced. Those three records together make the game understandable after the fact, during development, during bug reports, during regression testing, during scenario tuning, during balance review, during documentation, during AI refinement, during UI testing, during save migration, during campaign integration, during code review, during demos, during tutorials, during release checks, during support, during maintenance, during refactoring, during onboarding, during investigation, during design review, and during playtesting.
