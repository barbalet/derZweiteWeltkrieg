# Chapter 6: The Turn Engine

The turn engine is small in vocabulary and large in consequence. A battle has a turn number, a dice cup, a current drawn die, a side that owns that die, and units that can receive exactly one order while eligible. The current rules model follows the World War 2 order-dice structure used throughout the repository documentation: draw a die, choose a unit, assign Fire, Advance, Run, Ambush, Rally, or Down, resolve any required order test, execute that unit, then continue drawing until all eligible units have acted or retained a legal standing order.

This order-dice structure is the spine of play. Movement is no longer a side-wide phase that all units share; it is a consequence of Advance or Run. Shooting is no longer opened for a whole side at once; it is tied to Fire or Advance, with target reactions and hit modifiers resolved immediately. Assault is no longer a separate global phase; it is normally the close-quarters branch of a Run order. The older Movement, Shooting, and Assault labels still exist in compatibility adapters where old callers have not yet been fully retired, but new rules, AI, snapshots, documentation, and downstream contracts are written around unit orders.

## Drawing And Assigning Orders

The order-dice lifecycle is the authoritative transition. The engine builds a deterministic cup from eligible units, draws one side-owned die, asks that side to choose one unit, and records the assigned order next to that unit. Once a unit has an order, it cannot receive a second normal order during the same turn. Destroyed units remove their dice. Normal spent dice return to the cup at turn end, while retained Ambush or Down orders remain attached where the rules allow.

The command surface centers on `game_assign_order` in C and `HistoricalBoardSession.issueOrder(_:to:)` in Swift. Older movement, shooting, assault, and phase-advance functions remain as compatibility infrastructure, but the future-facing path is order first, action second. That order-first shape is important because it gives pins, morale, FUBAR, Ambush, and Down a single place to interrupt activation before any movement or fire is performed.

There is also an important guard: time cannot advance while a pending resolution choice exists. If a vehicle damage result, hit allocation, order-test branch, FUBAR result, or close-quarters continuation is waiting, the engine keeps the battle paused. That prevents a player or AI from skipping half-finished combat.

## Movement

`game_move_unit` shows the pattern used by most commands. It clears previous error state, checks for pending resolutions, finds the unit, verifies action ownership and basic validity, then applies phase and unit-specific rules. It checks pinning, falling back, combat locks, crew stun, immobilization, already-used movement, board bounds, impassable terrain, difficult terrain, movement allowance, enemy separation, and transport synchronization.

Movement is therefore not just changing coordinates. It is spending a phase action under current battlefield conditions. Vehicles may be fast, recon, immobilized, or crew stunned. Infantry may be pinned or falling back. Terrain may block the path. Enemy models may force separation. A transport must carry its passenger along.

The engine logs the move or explains the failure. The UI does not need to re-create these checks to gray out every impossible destination. It can optimistically send the action and show the rule result.

## Deployment As A Parallel Path

Deployment uses `game_deploy_unit`, not `game_move_unit`. It shares board and overlap legality but does not mark the unit as having moved. This is why the setup-to-deployment-to-battle flow can be interactive without consuming turn actions. The UI can let the player drag tokens into reasonable starting positions, and the engine still rejects impossible placement.

`game_deploy_rotate_unit` follows the same principle for facing. Deployment facing matters for vehicle fire arcs, but changing it before the battle starts should not count as a movement action.

## Transport Actions

Embark, disembark, and passenger fire are separate commands because transport behavior is a knot of dependencies. `game_embark_unit` checks that the transport is friendly, has capacity, is active, is a real transport, is close enough, and that the passenger is eligible. `game_disembark_unit` checks phase, crew stun, passenger presence, recent embarkation, transport movement distance, and legal placement. `game_fire_passenger` belongs to shooting and checks target legality, passenger status, range, fire arcs, line of sight, transport movement, open-topped firing capacity, and pinning.

Keeping these actions explicit lets the UI present them as distinct buttons and lets replay store them accurately. It also gives tests and future AI code clear hooks.

## Tank Shock And Smoke

Tank shock and smoke make movement more than relocation. `game_tank_shock_unit` lets vehicles force infantry morale decisions, death-or-glory style responses, possible vehicle damage, and forced fall back. `game_use_smoke` lets vehicles create a defensive state in Movement at the cost of shooting. Both actions belong in the engine because they alter future legality and survivability.

The Swift controller exposes these as `tankShockSelected()` and `useSmoke()`, guarded by app mode and turn. The engine decides whether the selected unit is a legal tank shock attacker or smoke user.

## The Rationale

The turn engine has two jobs: give the player a clear rhythm and ensure rules happen in the right order. The rhythm is visible in the phase label, controls, and logs. The order is enforced in C. That is why phase state is public, but phase transitions and actions are commands. The UI may guide, but it should not become an alternate path around the engine.

## The Phase State In Public View

The public view of turn state is intentionally tiny:

```c
typedef struct {
    int turn_number;
    player_t active_player;
    phase_t phase;
} game_view_t;
```

Swift turns that into `GameSnapshot`, adding display labels:

```swift
struct GameSnapshot {
    let turnNumber: Int
    let activePlayer: player_t
    let phase: phase_t

    var phaseName: String {
        switch phase {
        case DZW_PHASE_MOVEMENT:
            return "Movement"
        case DZW_PHASE_SHOOTING:
            return "Shooting"
        case DZW_PHASE_ASSAULT:
            return "Assault"
        default:
            return "Unknown"
        }
    }
}
```

That is enough for the UI to label the current moment without controlling it. The player sees the phase, active player, and turn number. The engine still decides what the phase means.

The small public view also makes tests direct. A test can create a game, inspect that it starts on turn 1, active Player 1, Movement phase, issue `game_advance_phase`, and assert the next phase. Turn state is easy to reason about because it is not spread across multiple systems.

## The Authoritative Transition

`game_advance_phase` is one of the most important functions in the engine because it is the only public way to move the turn forward:

```c
void game_advance_phase(game_t *game) {
    if (game == NULL) {
        return;
    }

    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return;
    }

    if (game->phase == DZW_PHASE_MOVEMENT) {
        game->phase = DZW_PHASE_SHOOTING;
        init_shooting_phase(game);
        dzw_log(game, "%s advances to the %s phase.", player_name(game->active_player), phase_name(game->phase));
        return;
    }

    if (game->phase == DZW_PHASE_SHOOTING) {
        game->phase = DZW_PHASE_ASSAULT;
        dzw_log(game, "%s advances to the %s phase.", player_name(game->active_player), phase_name(game->phase));
        return;
    }

    finish_turn(game, game->active_player);
    score_objectives(game);
    game->active_player = other_player(game->active_player);
    game->phase = DZW_PHASE_MOVEMENT;
    game->turn_number += 1;
    begin_turn(game);
}
```

The function shows several design principles. It clears errors at the start. It refuses to advance over pending combat decisions. It initializes shooting when entering Shooting. It scores objectives only after Assault. It switches active player and increments turn in one place. It logs transitions.

This means UI code does not need to know how objectives are scored or when turn counters increment. The UI button can say "Next Phase." The engine turns that click into rules.

## Pending Choices Block Time

The pending-choice guard is easy to overlook, but it is essential. A combat action can create a half-resolved state. For example, a vehicle may suffer a weapon-destroyed result and require the owning side to choose which weapon is lost. A mixed-profile unit may need hit allocation. A melee sequence may pause at an initiative band until allocation is complete.

If the player could advance phase during that pause, the battle would become incoherent. The engine might have pending damage from the previous phase while the next phase begins. The guard turns pending choices into true modal rules state. The app can display the pending UI, the AI can resolve AI-owned pending choices, and no other time transition happens until the choice is complete.

This is a good pattern for future rules. If a reaction, morale choice, reserve entry, artillery correction, or command decision interrupts play, it should block time the same way. Pending state should be explicit, visible, resolvable, and protected by phase advancement.

## Movement Phase Responsibilities

Movement phase is the broadest phase because it includes ordinary movement, deployment-like positioning during setup, facing, transports, tank shock, smoke, and some posture decisions. In live battle, `game_move_unit` carries the main burden.

The function begins with guard logic:

```c
clear_error(game);
if (!assert_no_pending_resolution_choice(game)) {
    return false;
}
unit_t *unit = find_unit(game, unit_id);
if (!assert_valid_unit_action(game, unit)) {
    return false;
}
if (!unit_can_move_now(game, unit)) {
    if (game->phase != DZW_PHASE_MOVEMENT) {
        return fail(game, "Units can only move in the movement phase.");
    }
    if (unit->falling_back) {
        return fail(game, "%s is falling back and cannot be given a normal move.", unit->name);
    }
    if (unit->locked_in_assault) {
        return fail(game, "%s is locked in close combat.", unit->name);
    }
    return fail(game, "%s cannot move right now.", unit->name);
}
```

This style is repeated across commands: clear error, check pending state, find unit, verify ownership and availability, give specific failure reasons. The specificity matters. "Cannot move" is less useful than "is falling back" or "is locked in close combat." The player learns the rule through the failed action.

Movement then checks board bounds, impassable terrain, difficult terrain, vehicle immobilization tests, movement allowance, enemy spacing, and transport synchronization. It is not a coordinate setter. It is a phase action with consequences.

## Movement Allowance And Unit Kind

`best_movement_allowance` encodes simple but important distinctions:

```c
static int best_movement_allowance(game_t *game, const unit_t *unit, bool difficult_terrain) {
    if (unit->kind == DZW_UNIT_ASSAULT_GUN) {
        return difficult_terrain ? roll_highest_of_2d6(game) : 6;
    }

    if (unit->kind == DZW_UNIT_VEHICLE) {
        return unit->fast ? 24 : 12;
    }

    return difficult_terrain ? roll_highest_of_2d6(game) : 6;
}
```

Infantry and assault guns move 6 inches normally, with difficult terrain rolling. Vehicles move 12 or 24 if fast. These numbers create battlefield rhythm. Infantry advances steadily. Fast vehicles can reposition. Difficult terrain introduces uncertainty. Assault guns sit between infantry and armor behavior.

The numbers are game scale values, not literal speeds. Their job is to make the board interesting. If infantry moved too far, objectives would collapse into immediate contact. If vehicles moved too little, transports and recon would feel pointless. If difficult terrain had no cost, board features would lose meaning.

## Shooting Phase Initialization

When Movement advances to Shooting, the engine calls `init_shooting_phase`. This is where shooting-phase state can be prepared. The game tracks things such as casualties during shooting, morale checks, stationary fire, smoke consequences, and weapon availability. Entering Shooting is not merely a label change. It is a rules boundary.

This boundary matters for actions such as smoke. A vehicle that pops smoke in Movement cannot fire that turn. A unit that moved may have different rapid-fire or heavy-weapon behavior. A transport's movement affects passenger fire. The shooting phase reads the history of Movement.

That is one reason the engine records movement details like `moved_this_turn`, `movement_action_used_this_turn`, and `moved_distance`. The turn engine is not stateless between phases. Earlier choices modify later options.

## Shooting Phase Responsibilities

The Shooting phase owns direct fire, barrage fire, passenger fire, vehicle weapon sequencing, pinning, shooting morale, and vehicle damage. The controller exposes commands such as `shootSelected()` and `firePassengerSelected()`, but the engine decides legality.

A unit cannot shoot in the wrong phase, target friendly units, fire into close combat, shoot twice, shoot while pinned or falling back, or shoot without a valid weapon. Vehicles may be limited by movement distance and weapon arcs. Barrage weapons may ignore line-of-sight restrictions that direct weapons obey. Infantry shots may trigger mixed-profile allocation. Vehicle shots may trigger weapon-destroyed choices.

Shooting therefore consumes much of the game's tactical detail. It is also a major reason the phase system must be strict. If a player could move after shooting, heavy-weapon and rapid-fire tradeoffs would collapse. If a player could shoot during Movement, smoke and transport movement restrictions would become ambiguous.

## Assault Phase Responsibilities

Assault phase resolves charges and close combat. It checks distance, difficult terrain, previous shooting behavior, target ownership, combat locks, assault-gun behavior, vehicle targets, cover, initiative, simultaneous strikes, morale outcomes, fall back, advance, and consolidation. It is the most stateful phase because combat can continue across turns through locks and pending melee resolution.

The phase order gives assault a dramatic role. Movement sets up charges. Shooting may weaken or pin targets but can also prevent some assault behavior. Assault then decides close contact and objective contests before scoring at the end of the active player's turn.

The follow-up choice appears here. Swift exposes `FollowUpChoice.advance` and `FollowUpChoice.consolidate`, mapped to C `follow_up_t`. The player chooses intent, but the engine resolves what actually happens.

## App Guards Versus Engine Guards

The Swift controller adds user-experience guards before calling the engine:

```swift
func advancePhase() {
    guard appMode == .battle, isHumanTurn, !isAITurnInProgress else { return }
    _ = executeRecordedAction(RecordedBattleAction(kind: .advancePhase))
}
```

This guard prevents the human from advancing during setup, during deployment, during the AI turn, or while AI is already acting. It is a UI and app-flow rule. The engine still has its own guards against pending choices and invalid state.

Both levels are needed. The app guard keeps the interface calm. The engine guard keeps the simulation valid. If the app accidentally exposes a button at the wrong time, the engine should still protect the battle. If the engine rejects an action, the app should still present the reason.

## Active Units And Cycling

The controller supports cycling active units. This is not an engine concept, but it helps players navigate the turn. `activeUnits` are derived from snapshots and phase state. The controller can select the next candidate, clear invalid targets, and let the UI focus on ready pieces.

This shows how the app can add ergonomic behavior without taking ownership of rules. Cycling does not decide whether a unit can move or shoot. It chooses a useful selection from units the engine describes. The distinction is subtle but important. Convenience features should be derived from engine state, not separate from it.

## AI And The Order Loop

The AI uses the same order structure as the human. It chooses a unit, chooses an order, chooses a target or path, resolves any order test or FUBAR result it owns, then executes the command that belongs to the selected order. The historical autoplay layer now exposes this as `HistoricalAutoplayOrderAdvisor`, which returns a `HistoricalAutoplayOrderDecision` containing the chosen unit, order, target, movement objective, order-test need, Ambush/Down reaction context, and visible reason string.

The AI loop is intentionally modest:

```swift
let decision = HistoricalAutoplayOrderAdvisor.decision(
    in: snapshot,
    sidePlan: sidePlan
)
session.selectUnit(decision.unitID)
session.issueOrder(decision.order, to: decision.unitID)
```

The important thing is not AI brilliance. It is integration. The AI observes the same snapshot fields as the UI: `availableOrders`, `currentOrder`, `pinCount`, `moraleQuality`, `retainedOrder`, `downOrderActive`, `ambushOrderActive`, and `orderDiceSummary`. It issues the same order command as the human. It resolves its own pending choices and pauses when a human-owned choice blocks the game. That makes AI behavior replayable and testable.

The advisor follows a practical priority order. Pinned units Rally before normal work when Rally is available. A unit facing an Ambush threat can choose Down. Movement-oriented plans prefer Advance or Run toward configured objectives. Shooting-oriented plans prefer Fire against a legal target. Close-quarters plans prefer Run because contact is an order result rather than a separate global phase. When no immediate action is better, Ambush preserves an opportunity-fire posture.

## Restart And Replay

The phase engine also benefits replay. A saved battle records `advancePhase` actions alongside moves, shots, and assaults. Loading a battle replays the sequence. Phase state is not edited directly. It is reconstructed. If a battle reached Turn 3 Shooting, it did so by passing through the same transitions it used live.

This is a powerful debugging property. If replay stops early, a command failed. If a phase differs, the action sequence or rule changed. The phase engine becomes a timeline that can be reconstructed, not a field that can be arbitrarily restored.

## Testing Order-Dice Behavior

Order-dice tests should cover more than simple assignment. Useful tests include:

- the cup is deterministic for a seed,
- the drawn die constrains which side can activate,
- assigning an order consumes the current die,
- pinned units produce an order-test result before executing,
- double-one and double-six order-test paths are visible,
- FUBAR outcomes expose friendly-fire or panic details,
- Down and Ambush can be retained where legal,
- Advance and Run expose different movement allowances,
- Fire and Advance are the normal shooting orders,
- Run is the normal close-quarters entry order,
- pending choices block turn completion,
- destroyed units remove their order dice,
- replay signatures remain stable across equivalent activation sequences.

These tests protect the turn rhythm. Many bugs in tabletop games are timing bugs: something happens in the wrong order, twice in a turn, after a die is already spent, or while a pending choice is unresolved. The order-dice tests are the guardrail.

## The Chapter's Rule Of Thumb

Every action should know where it belongs in time. If an action changes position or posture before fire, it probably belongs to Movement. If it projects force at range, it probably belongs to Shooting. If it resolves contact, it probably belongs to Assault. If it interrupts resolution, it should create explicit pending state and block time until resolved. If it is only setup arrangement, it should use deployment mode and deployment commands.

The turn engine is simple enough for the player to understand and strict enough for the rules to trust. That combination is the heart of the playable demo.

## Turn State And Unit State

The phase system only works because units remember what they have done. A turn is not just global state. It is also distributed through unit flags: moved this turn, movement action used, moved distance, shot this turn, assaulted this turn, smoke used, stationary fire, pinned until a turn number, crew shaken until a turn number, crew stunned until a turn number, locked in assault, falling back, and embarked this turn.

These fields allow the engine to answer contextual questions. Can the unit move now? Can it shoot now? Can it assault now? Can passengers fire after their transport moved? Can a unit disembark after embarking this turn? Does a stunned vehicle recover at the right point? Does a pinned infantry unit become available on its next turn?

The public view exposes the parts the UI needs:

```c
bool moved_this_turn;
bool can_move_now;
bool shot_this_turn;
bool assaulted_this_turn;
bool can_shoot_now;
bool can_assault_now;
bool locked_in_assault;
bool pinned;
bool falling_back;
bool embarked;
```

This is why `unit_view_t` includes both history and current capability. A player may want to know that a unit has already shot. A button may only need `can_shoot_now`. Tests may want to assert both. The engine computes the truth; the view exposes the useful pieces.

## Beginning And Finishing Turns

The implementation has private helpers such as `begin_turn`, `finish_turn`, and `score_objectives`. Those helpers are where per-turn cleanup and scoring live. Keeping them private is correct because callers should not be able to start or finish partial turns. The public caller advances phase; the engine decides which private transition is needed.

This matters for recovery states. Pinning, shaken crew, stunned crew, smoke, and falling back all need timing. If the app could manually set phase or active player, it might skip recovery. By funneling through `game_advance_phase`, the engine can keep turn timing coherent.

When adding a new duration-based state, decide when it begins and when it clears. If a state lasts until the unit's next turn, use turn-number logic similar to pinning and crew state. If it lasts through the current shooting phase, initialize or clear it in phase helpers. If it lasts until a pending choice resolves, store it with pending state. Time rules should be explicit.

## Player Experience Of Time

The user experiences the turn engine through labels and controls. `BattleHeaderView` and control sections show the active phase, score, and action buttons. UI tests look for `battle-phase-label` to verify phase transitions. This visible phase label is a promise: if it says Shooting, shooting actions should be available where legal and movement actions should not.

The game also uses logs to narrate time. Advancing phase logs which player advanced. Movement logs movement distance. Shooting logs fire and damage. Assault logs charges and outcomes. Scoring logs mission state. The log turns the phase engine into an after-action report.

This is important for player trust. In a rules-dense game, players need to understand not just what changed but when it changed. A phase label and log together create that understanding.

## Deployment, Battle, And Resumable Mode

`GameController` tracks `appMode` and `resumableAppMode`. This lets the app move between setup, deployment, and battle without losing the current battle configuration. A player can return to setup, resume a current operation, restart, or load a saved operation.

The distinction matters for phase state. Deployment is outside the normal phase rhythm, but it prepares the game state that battle mode will use. Resuming battle should re-enter the correct app mode and schedule AI if the active player is the AI. Restarting should reload the current configuration and reset recorded actions.

The phase engine remains C-owned, while app mode remains Swift-owned. `resumableAppMode` is a UI workflow detail. `phase` is a rules detail. Their interaction is managed by the controller.

## Action Recording And Temporal Meaning

Recorded actions are temporal. A `moveUnit` action means something only at the point it occurred. A `shoot` action assumes the engine is in Shooting and the attacker has not already fired. An `advancePhase` action moves the battle clock. Replaying actions therefore reconstructs time, not just state.

This is why the order of recorded actions matters. Moving then shooting differs from shooting then moving. Choosing hit allocation before phase advancement matters. Restarting a battle clears recorded actions because the timeline begins again. Saving a battle stores both configuration and action sequence because neither alone is enough.

If a new action is added, its temporal constraints should be clear. Is it allowed only in Movement? Does it consume shooting? Does it happen during pending resolution? Can it happen in deployment? Does it trigger AI scheduling? The answers determine where it appears in `RecordedBattleAction.Kind`, `executeRecordedAction`, and UI controls.

## AI Blocking And Human Decisions

The AI loop contains a subtle timing rule: it stops if a human-owned pending decision blocks resolution. That matters because some actions by the AI can create choices for the human. For example, the AI may shoot a human mixed-profile unit and require the human to assign hits. The AI should not continue advancing through its turn while waiting for that human decision.

The controller checks:

```swift
private var humanDecisionIsBlockingAI: Bool {
    pendingWeaponDestroyChoice?.chooserOwner == DZW_PLAYER_ONE || pendingHitAllocationChoice?.chooserOwner == DZW_PLAYER_ONE
}
```

This is an app-level reflection of engine pending state. The engine blocks unrelated commands; the controller also stops the AI task so the UI can present the decision. Once the human resolves it, the AI can continue if appropriate.

This pattern should be reused for future pending decisions. A pending decision should identify the chooser owner. The AI should auto-resolve its own decisions and pause for human decisions. The phase engine should not advance until the pending decision is gone.

## Why Compatibility Phases Still Exist

World War 2 combat could be modeled with many visible time slices: command, orders, movement, defensive fire, indirect fire, morale, assault, recovery, reserves, and logistics. The game now treats those as consequences of unit orders, but the codebase still contains older Movement, Shooting, and Assault names because downstream modules used them as UI and replay boundaries. Those names are legacy-only compatibility buckets. They are useful for migration and tests, but they are not the rules authority for new behavior.

The order-dice engine still has room for nuance through actions and pending choices. Smoke can belong to an Advance or other movement posture. Passenger fire belongs to a shooting-capable order. Close combat and follow-up belong to Run. Morale can be triggered by fire or assault. Recovery can happen at order assignment, order-test resolution, or turn-end cleanup. The visible order list stays small while rules stay expressive.

If future development adds more order types, it should be because a repeated rule cannot be expressed cleanly through Fire, Advance, Run, Ambush, Rally, or Down. Adding a new order affects UI labels, controls, AI loops, replay, tests, and player expectations. That is a major design change.

## Final Timing Note

Time is the hidden structure of the whole game. Units, weapons, transports, objectives, and AI all depend on when actions happen. The engine's phase model gives the code a shared clock. Respect that clock, and new rules will usually find a natural home. Ignore it, and even correct-looking features will create strange edge cases.

The maintainer's practical question should always be: which die was drawn, which unit can receive it, which order was assigned, what has already happened this turn, and what must wait until later? The current code answers that through order-dice state, active side, per-unit flags, pending choices, and recorded action order. That combination is stronger than any one field alone. A unit may be active but unable to execute because it failed an order test. A game may have a spent die but be unable to finish the turn because hit allocation is pending. A battle may be in the AI turn but paused because the human must choose casualties. These cases are not exceptions to the turn engine; they are the turn engine doing its job carefully.

That carefulness is what keeps a dense ruleset playable instead of merely busy, especially as more weapons, vehicles, scenarios, saved battles, AI routines, historical hooks, campaign systems, tutorials, and UI commands are added.

The clock must remain legible to code, tests, UI, AI, saved replays, logs, scenarios, campaign systems, tutorials, documentation, designers, maintainers, reviewers, contributors, debuggers, and players.
