# Chapter 2: The C Contract

The public header [`../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h`](../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h) is the most important design document in the codebase. It is not long compared with the C implementation, but it decides what the rest of the repository is allowed to know. Everything above the engine sees `game_t` as an opaque pointer. That is the core bargain: callers can create, reset, query, and command a game, but they cannot reach into its private storage.

That opacity matters because the private state is rich. `struct dzw_game` in [`../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`](../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c) carries turn data, armies, fixed unit arrays, mission state, objectives, zones, pending weapon-destroy choices, pending mixed-profile hit allocation, pending melee continuations, pending vehicle shot sequencing, logs, and last error text. If Swift code could mutate those fields directly, invariants would leak. A unit could be marked embarked without its transport pointing back. A pending hit allocation could be skipped while a combat still expected it. A destroyed transport could still appear to carry passengers.

The header prevents that by offering a command API instead of public fields.

## Enums As Shared Language

The engine defines small enums for the concepts every layer must share:

- `player_t` gives the game `DZW_PLAYER_ONE`, `DZW_PLAYER_TWO`, and `DZW_PLAYER_NONE`.
- `phase_t` defines Movement, Shooting, and Assault.
- `unit_kind_t` separates infantry, vehicles, and assault guns.
- `terrain_kind_t` separates open, difficult, and impassable terrain.
- `follow_up_t` captures post-assault advance or consolidate decisions.
- `army_list_t` names the playable armies: British, American, Australian, Soviet, German, and Italian, plus a demo value.

The names are plain C constants because they must survive both Swift import and C tests. Swift snapshots and UI code can switch on these values directly. That keeps labels and controls simple without making Swift responsible for interpreting engine internals.

## View Structs Instead Of Raw State

Most public data leaves the engine through view structs. `unit_view_t` is a good example. It carries identity, owner, kind, position, facing, footprint, model count, wound state, profile values, armor, special vehicle flags, cover state, action availability, assault locks, morale state, transport relationships, and destruction state. That looks like a lot, but it is still a read-only projection. The caller gets the information needed to draw, inspect, and enable controls. It does not get enough authority to corrupt the simulation.

The same idea appears in `mission_view_t`, `objective_view_t`, `zone_view_t`, `army_roster_unit_view_t`, `army_catalog_unit_view_t`, `weapon_profile_view_t`, `pending_weapon_destroy_view_t`, `pending_hit_allocation_view_t`, and `profile_group_view_t`. The app can build rich panels from these views. Tests can assert detailed behavior. Historical adapters can inspect scenario fit. None of them need to know the memory layout of `unit_t` or `game_t`.

This also makes the Swift bridge almost mechanical. [`../Sources/DerZweiteWeltkriegApp/Bridge/GameSnapshots.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/GameSnapshots.swift) converts C strings and numbers into Swift structs such as `UnitSnapshot`, `MissionSnapshot`, `ObjectiveSnapshot`, `ZoneSnapshot`, `PendingWeaponDestroyChoiceSnapshot`, and `ProfileGroupSnapshot`. The Swift layer adds display helpers, but the raw facts come from the C view.

## Commands Are Explicit

The action API is direct:

- `game_move_unit`
- `game_deploy_unit`
- `game_tank_shock_unit`
- `game_embark_unit`
- `game_disembark_unit`
- `game_fire_passenger`
- `game_rotate_unit`
- `game_deploy_rotate_unit`
- `game_shoot_unit`
- `game_assault_unit`
- `game_choose_pending_weapon_destroy`
- `game_choose_pending_hit_allocation`
- `game_set_preferred_casualty_group`
- `game_toggle_cover`
- `game_toggle_hull_down`
- `game_use_smoke`
- `game_advance_phase`

This list is a useful description of the playable demo. It tells us what the engine considers a player action. It also tells us what a save file can record, because [`../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift) mirrors those commands in `RecordedBattleAction.Kind`.

The explicit API keeps action replay possible. A saved battle does not serialize every private field in the engine. It stores a `SkirmishConfiguration` plus a sequence of recorded actions. Loading a battle means creating the same initial game, then replaying the actions through the same public API. That is only viable because each player command is named and parameterized.

## Error And Log As Part Of The Contract

The header exposes `game_log_count`, `game_log_line`, and `game_last_error`. These are not afterthoughts. Tabletop-style rules are dense enough that the game must explain itself. A failed command needs a rule reason: outside the battlefield, wrong phase, blocked line of sight, already moved, no legal disembarkation position, no pending choice, and so on. A successful command also needs a record: a unit moves, a tank shocks, passengers fire, a unit takes wounds, a combat continues, objectives score.

The app uses those strings as player feedback, while tests can use them as a diagnostic trail. This design keeps explanation close to the rule that produced it. If a future rule changes, the same edit can update the behavior and its explanation.

## The Boundary Rule

The safest way to extend this project is to respect the header. Add new private state in C if the rule needs it. Add a new view field if the app must display it. Add a new command if the player or AI must trigger it. Add a new recorded action if it must survive save/load replay. Avoid making Swift infer engine state from labels, unit names, or UI positions. The C contract exists so the rest of the program can stay honest.

## The Header As A Promise

The header is intentionally written in ordinary C. It avoids Swift-specific concepts, Objective-C bridging types, and heap-owned collection handles. That restraint is what allows the same API to serve SwiftUI, unit tests, command-line code, and scenario adapters. A caller receives primitive values, pointers to static strings, and plain structs. The ownership model is simple: the engine owns the game; callers ask for views.

At the top of the file, the most important line is the least detailed one:

```c
typedef struct dzw_game game_t;
```

That line says every external caller can hold a pointer to a game but cannot know how a game is stored. The implementation may add fields for new pending choices, scenario labels, or damage state without requiring the Swift app to rebuild its mental model of the engine. The public functions become the only legal access path. That gives the engine freedom to change internally while giving callers a stable contract.

The same philosophy appears in the view structs. They are wide enough to support a rich UI, but they are copies. `unit_view_t` does not expose a pointer to `unit_t`. `zone_view_t` does not expose the engine's terrain array. `profile_group_view_t` does not let Swift mutate profile group counts. This is the line between presentation and authority.

## Anatomy Of `unit_view_t`

`unit_view_t` is the most useful public structure for understanding the game because it compresses a complete battlefield unit into a displayable contract:

```c
typedef struct {
    int id;
    const char *name;
    player_t owner;
    unit_kind_t kind;
    float x;
    float y;
    float facing_degrees;
    float footprint_radius;
    int models;
    int wounds_per_model;
    int lead_model_wounds;
    int total_wounds_remaining;
    bool mixed_profiles;
    int starting_models;
    int weapon_skill;
    int ballistic_skill;
    int strength;
    int toughness;
    int initiative;
    int attacks;
    int leadership;
    int save;
    int front_armour;
    int side_armour;
    int rear_armour;
    bool fast;
    bool recon;
    bool open_topped;
    bool in_cover;
    bool hull_down;
    bool smoke_available;
    bool smoke_active;
    bool moved_this_turn;
    bool can_move_now;
    bool shot_this_turn;
    bool can_shoot_now;
    bool can_assault_now;
    bool locked_in_assault;
    bool pinned;
    bool falling_back;
    bool embarked;
    int embarked_unit_id;
    int embarked_in_transport_id;
    int transport_capacity;
    bool destroyed;
} unit_view_t;
```

This structure is long because the UI must answer many questions without cheating. What icon shape should the token use? Does the unit belong to the active side? Is it a vehicle? Does it have armor values? Is it selected? Can it move? Can it shoot? Is it pinned, embarked, destroyed, or locked in combat? Does it carry passengers? Should smoke be drawn? Should the inspector show partial wounds?

The field list is a useful design checklist. If a future feature needs to be visible, it likely needs a field here or in a related view. For example, if minefields someday mark a unit as suppressed rather than pinned, the engine should not make Swift infer suppression from the last log line. It should expose a stable field. If a vehicle gets a new state such as "buttoned up" that changes shooting or assault, that state probably belongs in `unit_t` and then in `unit_view_t` if the player needs to see it.

The view also separates ability flags from raw status. `moved_this_turn` and `can_move_now` are not redundant. A unit may be unable to move because of phase, pinning, falling back, immobilization, or prior action. The UI can show "already moved" or "not available" when useful, but the engine supplies the current boolean. The same applies to shooting and assault.

## Why The Contract Uses Functions For Counts

The engine exposes collections through count-and-view functions:

```c
int game_unit_count(const game_t *game);
unit_view_t game_unit_view(const game_t *game, int index);
int game_zone_count(const game_t *game);
zone_view_t game_zone_view(const game_t *game, int index);
int game_objective_count(const game_t *game);
objective_view_t game_objective_view(const game_t *game, int index);
```

This is old-fashioned but robust. It avoids returning heap arrays to Swift, avoids ownership ambiguity, and lets the implementation keep fixed-size internal arrays. It also makes invalid indexes harmless: view functions can return zeroed or empty views rather than expose memory. The Swift bridge wraps this in a familiar map:

```swift
units = (0..<Int(game_unit_count(handle))).map { index in
    UnitSnapshot(raw: game_unit_view(handle, Int32(index)))
}
```

The count-and-view pattern does create one responsibility: callers should treat each reload as a coherent snapshot pass. If a caller requests unit count, then mutates the game, then continues reading old indexes, it may observe a different collection. `GameController.reload()` avoids that by reading all views immediately after a command on the main actor.

## Creation And Reset Functions

The header offers several creation and reset paths:

```c
game_t *game_create_demo(uint32_t seed);
game_t *game_create_demo_with_armies(
    uint32_t seed,
    army_list_t player_one_army,
    army_list_t player_two_army
);
game_t *game_create_demo_with_forces(
    uint32_t seed,
    army_list_t player_one_army,
    int player_one_force,
    army_list_t player_two_army,
    int player_two_force
);
game_t *game_create_skirmish(
    uint32_t seed,
    army_list_t player_one_army,
    const army_list_entry_t *player_one_entries,
    int player_one_entry_count,
    army_list_t player_two_army,
    const army_list_entry_t *player_two_entries,
    int player_two_entry_count
);
```

The progression matters. A demo can be created with defaults. A demo can select armies. A demo can select force presets. A skirmish can use explicit army-list entries. This gives tests and UI different levels of control. A quick smoke test can call `game_create_demo`. A force preset test can call `game_create_demo_with_forces`. The setup screen can build exact list entries and call `game_create_skirmish`.

Reset functions mirror creation functions. This is useful because the Swift controller owns a long-lived engine handle. It can reset the existing game for a new configuration rather than requiring the app to rebuild all controller state around a new object. The public `game_destroy` closes the ownership loop. The lifecycle is clear: create, use through commands and views, reset when needed, destroy in `deinit`.

## Army And Catalogue Functions

The army API extends the same contract to force building:

```c
const char *army_name(army_list_t army);
int army_force_count(army_list_t army);
army_force_view_t army_force_view(army_list_t army, int index);
int army_catalog_unit_count(army_list_t army);
army_catalog_unit_view_t army_catalog_unit_view(army_list_t army, int index);
int army_list_total_points(
    army_list_t army,
    const army_list_entry_t *entries,
    int entry_count
);
```

These functions let the UI build setup screens from engine data. The Swift app does not hard-code the point value of a US Rifle Squad or the maximum number of Italian trucks. It asks the engine. That is important because the same catalogue entries instantiate real units. If point values lived only in Swift, the setup screen could drift away from the game.

The API also lets tests verify catalogue completeness without knowing private arrays. Tests can iterate every playable army, ask for catalogue counts, inspect each view, and create skirmishes from selected entries. That gives the C implementation freedom to rearrange internal arrays while preserving public behavior.

## Pending Choice Views

Pending choices are one of the strongest reasons to keep the contract explicit. Combat can pause for a weapon-destroyed selection or mixed-profile hit allocation. The engine exposes those pauses as views:

```c
pending_weapon_destroy_view_t game_pending_weapon_destroy_view(const game_t *game);
int game_pending_weapon_destroy_option_count(const game_t *game);
vehicle_weapon_view_t game_pending_weapon_destroy_option_view(const game_t *game, int index);

pending_hit_allocation_view_t game_pending_hit_allocation_view(const game_t *game);
int game_unit_profile_group_count(const game_t *game, int unit_id);
profile_group_view_t game_unit_profile_group_view(const game_t *game, int unit_id, int index);
```

The app does not need to know what private melee or vehicle sequence was interrupted. It only needs enough information to present the choice: who chooses, what target is involved, what options exist, and how many hits remain. When the player chooses, the app calls `game_choose_pending_weapon_destroy` or `game_choose_pending_hit_allocation`. The engine then continues the suspended resolution.

This design scales. A future rule might introduce a pending morale decision, artillery deviation choice, reaction fire choice, or reserve entry choice. The pattern is already established: private pending state in `game_t`, public pending view, public resolution command, Swift snapshot, UI section, AI resolution path, and replay action.

## Swift Snapshot Conversion

The Swift bridge performs translation, not interpretation. For example, `UnitSnapshot` copies raw fields and then adds display helpers:

```swift
struct UnitSnapshot: Identifiable {
    let id: Int
    let name: String
    let owner: player_t
    let kind: unit_kind_t
    let x: CGFloat
    let y: CGFloat
    let facingDegrees: CGFloat
    let models: Int
    let frontArmour: Int
    let sideArmour: Int
    let rearArmour: Int
    let canMoveNow: Bool
    let canShootNow: Bool
    let canAssaultNow: Bool
    let pinned: Bool
    let fallingBack: Bool
    let embarked: Bool
    let destroyed: Bool

    init(raw: unit_view_t) {
        id = Int(raw.id)
        name = raw.name.map { String(cString: $0) } ?? "Unit"
        owner = raw.owner
        kind = raw.kind
        x = CGFloat(raw.x)
        y = CGFloat(raw.y)
        facingDegrees = CGFloat(raw.facing_degrees)
        models = Int(raw.models)
        frontArmour = Int(raw.front_armour)
        sideArmour = Int(raw.side_armour)
        rearArmour = Int(raw.rear_armour)
        canMoveNow = raw.can_move_now
        canShootNow = raw.can_shoot_now
        canAssaultNow = raw.can_assault_now
        pinned = raw.pinned
        fallingBack = raw.falling_back
        embarked = raw.embarked
        destroyed = raw.destroyed
    }
}
```

The real file contains more fields, but the pattern is the same. Swift does not compute `canMoveNow` by duplicating engine logic. It receives it. Swift does compute display strings such as `shortStatus` or `detailSummary`, because those are presentation concerns. That is the correct boundary.

## C Strings And Lifetime

The C API returns `const char *` for names, summaries, source notes, and log lines. In the current engine, those strings are static literals or buffers owned by the game. Swift snapshots convert them immediately into `String`. This immediate conversion is important. It avoids retaining pointers across reloads or resets, especially for log and error buffers that live inside `game_t`.

When adding new string fields, follow the same discipline. If the string is a static catalogue label, returning a literal is fine. If it is scenario-provided and stored in the game, keep storage in `game_t` and expose `const char *` that remains valid until the next reset or destroy. Swift should copy it into a value snapshot.

## Last Error As A Command Result Companion

Most command functions return `bool`, but that boolean is intentionally minimal. `true` means the command succeeded or completed its immediate part. `false` means the command was rejected. The reason lives in `game_last_error`. This avoids expanding every command into a custom result type while still giving useful feedback.

The pattern in the implementation is consistent: clear the old error, validate, call `fail(game, "...")` on rejection, log on success, and return. This makes C commands easy to call from Swift and easy to test. If a future action needs a richer result, first ask whether a view plus log/error can express it. Many tabletop actions have complex consequences, but the caller usually only needs success, updated snapshots, and explanatory text.

## Maintaining ABI Sanity

Because Swift imports the C header, public structs should be treated carefully. Reordering fields can affect callers that are compiled against the header. Adding fields is usually straightforward inside the same package because everything rebuilds together, but it still deserves care. Avoid exposing private implementation details just because a view currently wants to show them. Expose stable concepts.

For example, `smoke_active` is a stable gameplay concept. `smoke_used_this_turn` may be private unless a UI control needs to distinguish unavailable smoke from active smoke. `pending_hit_allocation_hits_remaining` is a stable display concept. The exact private arrays used to store allocated hits are not.

The boundary rule is not "hide everything." It is "expose the concepts that other layers can safely depend on." That is why the header is broad but still disciplined.

## Testing The Contract

The tests are strongest when they use the public contract the way real callers do. The core tests create games through public functions, inspect views, issue commands, and assert results. That style is preferable to reaching into private C state. It means the tests protect the API that Swift and future modules actually rely on.

When adding a public function, add a test that proves why it exists. When adding a view field, add a test that makes the field meaningful. When adding a command, test both a successful case and at least one rejected case if the rule has interesting legality. The header is the contract; tests are the contract's memory.

## Command Pairs And Semantic Completeness

Many commands appear in pairs because the engine distinguishes live battle actions from preparation actions or initiating actions from continuation actions. `game_move_unit` and `game_deploy_unit` both change a unit's position, but they mean different things. One spends a movement opportunity in a phase. The other arranges starting position. `game_rotate_unit` and `game_deploy_rotate_unit` follow the same pattern. This is better than a single function with a vague mode flag because the public API names the intent.

Other pairs separate starting a resolution from completing a pending choice. `game_shoot_unit` may eventually require `game_choose_pending_weapon_destroy` or `game_choose_pending_hit_allocation`. `game_assault_unit` may eventually require `game_choose_pending_hit_allocation` before it can finish a melee sequence. The public API therefore describes not only actions but also pauses. A caller can treat the engine as a state machine: issue a command, reload, check pending views, resolve any pending view, then continue.

The semantic completeness of commands is worth protecting. A command should leave the game in a valid state even if it pauses. If a shot creates pending hit allocation, the game should not also allow phase advancement or an unrelated action. If a transport is destroyed and passengers must be placed, the engine should handle the passenger outcome before returning to normal play. Callers should not be asked to remember hidden follow-up obligations.

## Why The Header Does Not Expose Selection

The engine does not store the UI's selected unit or selected target. Selection is a command-surface concern, not a rules concern. Swift stores `selectedUnitID` and `selectedTargetID` in `GameControllerBoardSelectionState`. The engine only receives IDs when a command is issued.

This avoids a subtle coupling problem. A historical scenario runner, command-line test, or AI routine should not need to manipulate UI selection before moving or shooting. It should call the command with IDs. The app can have whatever selection model feels good for humans: tapping, cycling, nearest enemy, inspector selection, keyboard shortcuts, or future marquee selection. The engine remains indifferent.

The header does expose enough state for selection to be safe. Unit IDs are stable during a game. Destroyed or embarked units can be detected. Owner and action availability are visible. The controller can clear stale selections after reload:

```swift
if let selectedUnitID, !units.contains(where: { $0.id == selectedUnitID }) {
    self.selectedUnitID = nil
}
if let selectedTargetID, !units.contains(where: { $0.id == selectedTargetID }) {
    self.selectedTargetID = nil
}
```

That code belongs in Swift because it is about UI focus, not battle legality.

## Boundary Friction Is Useful

The C contract creates some friction. Adding a new visible concept may require editing a private C struct, a public C view struct, a view function, a Swift snapshot, a controller query, a UI view, and tests. That can feel heavy for a small feature. The heaviness is intentional. It makes the maintainer decide whether the concept is truly public.

For example, suppose a future rule adds vehicle "bogged" status distinct from immobilized. If it is only an intermediate result that immediately becomes immobilized or clear, it may not need a public field. If it persists and affects movement, it needs private state. If the player should see it, it needs a view field and snapshot. If the player can clear it with an action, it needs a command and recorded action. The boundary friction turns feature design into a set of explicit choices.

This is better than adding a Swift boolean because a panel needs a label. UI-only booleans spread quickly. They create bugs where the interface believes something the rules do not. The contract asks the slower question: should the rules know this?

## Documentation Role Of The Header

The header is also documentation for non-C readers. A Swift developer can read it and learn the playable vocabulary without reading thousands of lines of implementation. The army enum tells them which nations exist. The phase enum tells them the turn rhythm. The command list tells them what players can do. The view structs tell them what the app may display. The pending structs tell them where resolution can pause.

This is why naming matters. `game_fire_passenger` is clearer than `game_special_shoot_unit`. `game_toggle_hull_down` is clearer than `game_set_vehicle_flag`. `game_apply_guderian_scenario_board` is explicit about its integration role. The public API should continue to use names that explain design intent, not only implementation mechanics.

Good names reduce the amount of oral history required to maintain the code. A future contributor should be able to discover the game by reading the contract. This book deepens that reading, but the header should remain the short version.

## Practical Rules For Future Header Changes

When changing the public header, use a small checklist.

First, decide whether the new concept is an engine concept. If it affects legality, dice, damage, scoring, state persistence, or AI decision making, it probably is.

Second, decide whether it must be public. A private helper or flag can stay in the implementation. A visible state, action, catalogue property, or scenario hook must cross the header.

Third, prefer views over mutable access. A caller should ask what the engine currently believes, not edit internals.

Fourth, keep command parameters minimal and explicit. Pass IDs, coordinates, booleans, enum choices, or arrays of simple entry structs. Avoid passing UI objects or large loosely typed dictionaries.

Fifth, mirror the change in Swift snapshots and recorded actions only when needed. Not every view field needs a recorded action. Not every private rule needs a UI label.

Sixth, add tests at the contract level. If the function is public, exercise it as a caller would. If the field is public, assert it in a scenario that proves its meaning.

These rules keep the C boundary boring in the best sense. A boring boundary lets the rest of the game be interesting.

## The Contract As Collaboration Surface

The contract is also the point where different kinds of contributors can collaborate. A rules-focused contributor can improve `game_shoot_unit` or catalogue data and prove the result through C-level tests. A UI-focused contributor can add a panel around existing snapshots without changing the engine. A scenario-focused contributor can provide board zones, objectives, source links, and force choices without editing combat resolution. The header is the meeting place between those efforts.

That collaboration works only if each contributor trusts the boundary. If a UI change starts parsing log text to discover a hidden state, scenario authors cannot rely on it. If a combat change writes state that has no view, UI authors cannot present it. If a scenario module bypasses public creation paths, tests cannot easily reproduce it. The C contract gives everyone a shared language.

The header should therefore be reviewed with more care than its size suggests. A private helper can be changed freely. A public field or command becomes part of how the project thinks. Once Swift snapshots, UI identifiers, save files, and tests depend on a concept, removing or renaming it costs more. That does not mean the API should freeze prematurely. It means public additions should describe durable game ideas.

In `derZweiteWeltkrieg`, the durable ideas are already visible: armies, force lists, units, weapons, board zones, objectives, phases, movement, shooting, assault, transports, smoke, cover, hull-down status, morale states, pending choices, logs, and errors. Future features should join that vocabulary with the same clarity.

That clarity is what lets the rest of the codebase move quickly without becoming casual about rules, tests, persistence, scenario data, player-facing explanations, or future maintenance.

For a rules-heavy game, that is not ceremony. It is survival, especially once more scenarios, weapons, campaign layers, and user workflows arrive in earnest across the app.

The header keeps that arrival orderly, reviewable, repeatable, testable, documented, teachable, and sane.
