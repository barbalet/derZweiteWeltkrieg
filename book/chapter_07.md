# Chapter 7: Combat And Damage Resolution

Combat is where the project most clearly chooses simulation over animation. Shooting and assault are not just button effects. They can produce wounds, morale checks, pinning, vehicle damage, destroyed weapons, stunned crews, emergency disembarkation, fall back, combat locks, follow-up movement, and pending player decisions.

The combat code lives mostly in [`../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`](../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c). The public surface is compact: `game_shoot_unit`, `game_fire_passenger`, `game_assault_unit`, `game_choose_pending_weapon_destroy`, `game_choose_pending_hit_allocation`, and `game_set_preferred_casualty_group`. The private implementation is extensive because combat has many branches.

## Shooting

`game_shoot_unit` begins with familiar guards: no pending resolution, valid attacker, legal target, shooting phase, enemy target, not already shot, can shoot now, and no firing into close combat. It then calculates edge-to-edge range and splits behavior by whether the attacker uses vehicle rules.

Infantry shooting normally uses the first weapon slot. The engine checks range, line of sight unless barrage applies, total shots, movement effects, rapid-fire/heavy behavior, and whether the target uses infantry or vehicle rules. If the target is infantry, the engine resolves wounds, possible barrage pinning, and morale. If the target is a vehicle, it resolves armor penetration and damage.

Vehicle shooting is more involved. Vehicles may have several weapons, mounted arcs, ordnance behavior, movement-limited fire, and possible follow-on sequencing. The engine records fire angles and can pause for weapon-destroyed choices. This is why vehicle weapon slots remember destroyed state and last fire angle.

## Vehicle Damage

Vehicle damage is not modeled as hit points. It is modeled through damage results: crew shaken, crew stunned, immobilized, weapon destroyed, and destroyed outcomes. Those states affect later actions. A stunned vehicle may be unable to move or fight. An immobilized vehicle may still shoot but cannot relocate. A weapon-destroyed result can ask the player or AI which weapon is lost.

The engine exposes pending weapon destruction through `pending_weapon_destroy_view_t` and option views. Swift converts this to `PendingWeaponDestroyChoiceSnapshot`. If the AI owns the choice, the AI chooses automatically. If the human owns it, the UI presents a pending section. Resolution continues through `game_choose_pending_weapon_destroy`.

This pattern matters. A damage result that needs a choice is still part of the same combat. The game does not fake it as a later independent action.

## Mixed-Profile Damage

Mixed-profile units create a similar pause. When hits must be assigned among profile groups, the engine records a pending hit allocation. The app shows the attacker, source weapon, target, total hits, hits remaining, and available groups. The player assigns each hit with `game_choose_pending_hit_allocation`. When all hits are assigned, the engine finalizes damage and resumes any paused vehicle fire or melee sequence.

The code also supports preferred casualty groups through `game_set_preferred_casualty_group`. That allows the player to bias automatic allocation when possible, but the engine still enforces eligibility and round-robin constraints.

## Morale, Pinning, And Fall Back

Combat results can affect unit behavior beyond casualties. Barrage or ordnance can pin infantry. Shooting casualties can trigger morale checks. Failed morale can mark a unit as falling back. Falling back affects movement and can eventually remove a unit if it leaves the table. These state changes are engine-owned because they influence later action legality.

The public `unit_view_t` includes `pinned` and `falling_back`, allowing the UI and inspector to show them. But the rules that create and clear those states remain in C.

## Assault

`game_assault_unit` is the densest single public action. It checks phase, attacker kind, previous assault, firing restrictions, friendly target, assault-gun restrictions, difficult terrain charge distance, legal contact, and whether the combat is continuing. It then separates ordinary vehicle targets, assault-gun combat, cover strikes, initiative order, simultaneous combat, mixed-profile pauses, and outcome resolution.

The follow-up choice matters after combat. `DZW_FOLLOW_UP_ADVANCE` and `DZW_FOLLOW_UP_CONSOLIDATE` become `FollowUpChoice` in Swift. The UI exposes the choice, but the engine resolves whether it matters and where the units end up.

Pending melee resolution exists because mixed-profile allocation may interrupt close combat at a particular initiative band. The engine stores enough pending state to continue banded, one-sided, or simultaneous melee after the player assigns hits. This is a sophisticated choice: it keeps the action model synchronous where possible but allows true tabletop pauses where necessary.

## The Rationale

Combat is complicated because it preserves consequences. A destroyed transport affects passengers. A heavy weapon fired after standing still affects later assault eligibility. A vehicle's movement affects how many weapons it can fire. Smoke affects shooting. Cover affects saves and assault order. Mixed profiles can stop resolution until the defender assigns hits.

The engine's job is to keep those consequences coherent. The UI's job is to make the current choice visible. When adding combat rules, the safest approach is to ask four questions:

- Does this rule change future legality?
- Does it require a player or AI choice during resolution?
- Does it need to be visible in a snapshot?
- Does it need to be recorded for replay?

If the answer to any of those is yes, the change belongs in the engine contract, not only in the UI.

## Combat As A Pausable State Machine

The most important idea in the combat code is that resolution can pause. Many simple games treat an attack as one function call: roll, apply damage, return. `derZweiteWeltkrieg` cannot always do that because some results require choices. A weapon-destroyed vehicle result may require selecting which weapon is lost. A mixed-profile target may require assigning hits among groups. A melee can pause at a specific initiative band, wait for allocation, and then continue.

The private game state includes several pending structures for this reason: pending weapon destruction, pending hit allocation, pending vehicle shot sequencing, pending banded melee, pending one-sided melee, and pending simultaneous melee. The public API exposes only the choices the caller must resolve. This is a good balance. The UI sees a clean pending prompt. The engine remembers the deeper continuation.

This makes combat a state machine rather than a pile of immediate effects. A command may succeed and still leave the game waiting. The next legal command may be a pending-choice resolution. Once resolved, the engine continues the suspended combat or returns to normal play.

## Shooting Entry Conditions

`game_shoot_unit` begins with validation:

```c
if (!assert_no_pending_resolution_choice(game)) {
    return false;
}
unit_t *attacker = find_unit(game, attacker_id);
unit_t *target = find_unit(game, target_id);

if (!assert_valid_unit_action(game, attacker)) {
    return false;
}
if (target == NULL || target->destroyed) {
    return fail(game, "Target is not available.");
}
if (unit_is_embarked(target)) {
    return fail(game, "Embarked units cannot be targeted directly.");
}
if (game->phase != DZW_PHASE_SHOOTING) {
    return fail(game, "Units can only shoot in the shooting phase.");
}
if (target->owner == attacker->owner) {
    return fail(game, "Units cannot target their own side.");
}
if (attacker->shot_this_turn) {
    return fail(game, "%s has already shot this turn.", attacker->name);
}
if (!unit_can_shoot_now(game, attacker)) {
    return fail(game, "%s cannot shoot right now.", attacker->name);
}
if (target->locked_in_assault) {
    return fail(game, "You cannot fire into close combat.");
}
```

These checks express the shooting rules in human language. They also protect the engine from invalid states. The order is useful: pending choices first, then unit lookup, then target availability, phase, ownership, action use, capability, and close-combat restrictions. A failed shot gives the player a specific reason.

The same validation shape appears in other actions. Combat commands should fail early and explain why. Damage resolution should only start after legality is clear.

## Infantry Fire

For infantry, shooting is mostly weapon profile plus model count plus movement state. The engine selects the primary weapon slot, checks whether it is destroyed, checks line of sight unless barrage applies, computes total shots, and resolves against infantry or vehicle target rules.

Infantry fire must care about whether the unit moved because rapid-fire or heavy behavior can change. It must care about range because weapons are scaled to the board. It must care about barrage because indirect weapons can behave differently from direct fire. It must care about target kind because infantry damage and vehicle damage are different systems.

This is a good example of a rule function combining data from many chapters: weapon profiles from Chapter 4, board geometry from Chapter 5, phase timing from Chapter 6, and public views from Chapter 2. Combat is where the architecture converges.

## Vehicle Fire And Follow-On Weapons

Vehicle fire is more complicated because a vehicle can have multiple weapons and movement-limited firing. The engine may prefer ordnance when stationary, then resolve follow-on weapons. It tracks whether weapons are destroyed, whether arcs can bear, whether line of sight is blocked, whether range is valid, and whether a pending vehicle shot sequence must continue.

The engine records fire angles for vehicle weapons. This supports mounted arcs and jammed or constrained fire behavior. The result is a more physical vehicle model than "tank attacks once." A vehicle is a platform with weapons, arcs, movement history, and damage states.

This complexity is why vehicle firing belongs in C. The Swift UI should not decide which vehicle weapon can bear. It can show buttons and target selection, but the engine must evaluate arcs and sequence.

## Damage Against Infantry

Infantry damage uses wound logic, saves, cover, and model removal. The engine tracks casualties during a shooting phase because morale and pinning may depend on how much damage occurred. Mixed-profile units can interrupt damage application with allocation choices.

A single-profile unit can usually take wounds directly. A mixed-profile unit needs more care. The owning player may decide whether hits land on ordinary riflemen, a leader, a gunner, or another group, subject to allocation constraints. The engine stores allocated hits until all hits are assigned, then finalizes wounds. This preserves player agency without letting the UI edit model counts directly.

The public profile group view exposes enough for the UI:

```c
typedef struct {
    int index;
    const char *name;
    int models;
    int wounds_per_model;
    int lead_model_wounds;
    int weapon_skill;
    int ballistic_skill;
    int strength;
    int toughness;
    int initiative;
    int attacks;
    int leadership;
    int save;
    bool preferred_casualty_group;
    int pending_allocated_hits;
} profile_group_view_t;
```

The UI can display the group name, model count, stats, current preference, and pending assigned hits. It still cannot apply damage itself. That remains in the engine.

## Damage Against Vehicles

Vehicle damage is not simply wounds. A hit can glance or penetrate, then produce effects. Crew shaken and crew stunned restrict future activity. Immobilized changes movement. Weapon destroyed changes offensive capacity. Destroyed removes the vehicle and may affect passengers.

This produces richer tactical consequences. A vehicle can survive but become less useful. A transport can be destroyed and force emergency disembarkation. An assault gun can be stunned and skip close combat. A weapon-destroyed result can alter future target choices.

The engine uses helper functions to apply these effects because they touch many fields. Destroying a unit clears locks, transport capacity, embarked relationships, model count, and morale state. Destroying a transport invokes passenger outcome. These effects must happen together. Splitting them across UI actions would be dangerous.

## Transport Destruction

Transport destruction is a miniature rules story. If a transport has passengers, the engine clears the transport link, may inflict passenger wounds, searches for legal emergency disembarkation, pins the passengers, and removes them if no legal position exists. It then destroys the transport.

The passenger result depends on dice, saves, board placement, and unit state. That is far beyond a visual effect. The engine must own it.

This also makes transport tests important. A transport feature is not finished when embark and disembark work. Destruction must be coherent too. Otherwise a common combat result can strand hidden passengers or create impossible board states.

## Pinning And Morale

Pinning and morale give shooting consequences short of destruction. Barrage and ordnance can pin units. Casualties can trigger morale checks. Falling back affects later movement and can remove a unit if it leaves the board. These states create pressure and uncertainty.

The engine uses turn-aware flags such as `pinned_until_turn`, `crew_shaken_until_turn`, and `crew_stunned_until_turn`. This ties morale and damage to the turn engine. A unit is not just "pinned" forever; it is pinned according to timing rules.

The UI sees `pinned` and `falling_back` in snapshots. It does not need to know the internal turn number calculation. Again, the engine exposes the state the player needs, not every private detail.

## Assault Entry Conditions

`game_assault_unit` validates phase, target, attacker kind, previous assault, firing restrictions, ownership, assault-gun state, distance, terrain, and contact placement. The beginning of the function is strict because close combat can produce many consequences:

```c
if (game->phase != DZW_PHASE_ASSAULT) {
    return fail(game, "Assaults can only be resolved in the assault phase.");
}
if (attacker->kind == DZW_UNIT_VEHICLE) {
    return fail(game, "Only assault guns and tank destroyers can launch vehicle assaults.");
}
if (attacker->assaulted_this_turn) {
    return fail(game, "%s has already fought an assault this turn.", attacker->name);
}
if (attacker->fired_stationary_rapid_or_heavy) {
    return fail(game, "%s cannot assault after standing still to fire rapid-fire or heavy weapons.", attacker->name);
}
if (target->owner == attacker->owner) {
    return fail(game, "Units cannot assault their own side.");
}
```

The stationary fire restriction links Shooting to Assault. The assault-gun check links unit kind to close combat. The phase check protects timing. Combat functions are full of these cross-system joins.

## Charge Distance And Contact

Assault range uses edge distance: center-to-center distance minus both footprint radii. Difficult terrain can change assault distance. The engine moves the attacker toward contact legally and rolls back if no legal contact can be found. This prevents units from charging through impossible positions or overlapping unrelated combats.

This is a board-geometry rule inside combat. It depends on Chapter 5's placement logic. The UI only selects attacker and target. The engine decides whether contact can happen.

## Initiative And Cover

Close combat resolution can depend on initiative and cover. A defender in cover may strike first. Otherwise higher initiative can strike first, equal initiative can be simultaneous, and mixed-profile groups can create banded resolution. Assault guns and vehicle targets create additional branches.

This complexity is why pending melee state exists. If a mixed-profile unit is involved, the engine may need to pause after resolving a particular initiative band. It must remember accumulated wounds, which side is acting, what follow-up choice was selected, and what step comes next.

The UI does not need to understand all those branches. It only needs to present hit allocation when asked. The engine continues afterward.

## Combat Outcome And Follow-Up

After wounds are resolved, close combat outcome can destroy units, cause fall back, lock units in combat, or allow follow-up. `follow_up_t` lets the attacker choose advance or consolidate intent. The engine decides how that intent applies to the actual outcome.

This keeps player agency bounded by rules. The player can choose a posture, but cannot force an illegal result. If a unit is destroyed, locked, or unable to move, the engine resolves accordingly.

## Logs As Combat Explanation

Combat logs are especially valuable. They report shots, wounds, saves, pinning, morale, vehicle damage, charges, and combat outcomes. In a visual game with dice, players need a record. The log makes invisible dice and rule branches visible.

Logs also help tests and debugging. A failed test can inspect state, but a human debugging the failure will often read the log to understand the sequence. Keeping log text in the engine means explanations evolve with rules.

## UI Pending Sections

The Swift UI displays pending weapon-destroy and hit-allocation sections in the command panel. Those sections appear only when snapshots exist. This is the ideal relationship: the engine says "a choice is pending"; Swift shows controls; the chosen option calls back into the engine.

The AI uses the same snapshots. If Player 2 owns a pending weapon choice, it picks an option automatically. If Player 2 owns a hit allocation choice, it chooses a group based on toughness and save. The human and AI therefore resolve the same engine prompts through different decision makers.

## Testing Combat

Combat tests should cover representative branches rather than every dice permutation. Useful tests include:

- shooting fails in wrong phase,
- shooting respects line of sight,
- barrage or ordnance causes pinning,
- mixed-profile shooting creates pending allocation,
- pending allocation finalizes damage,
- vehicle damage can create weapon-destroy choice,
- transport destruction handles passengers,
- assault fails out of range,
- assault respects previous heavy fire,
- assault creates or resolves locks,
- objective scoring works after combat changes board control.

The aim is coverage of rule shape. Dice-heavy systems cannot be tested by hope. Seeded games and public commands make representative tests possible.

## Adding New Combat Rules

A new combat rule should be traced through the same path:

1. What state does it need?
2. Which phase owns it?
3. Does it modify shooting, assault, movement, or morale?
4. Can it pause for a choice?
5. Does the UI need a snapshot?
6. Can the AI resolve or use it?
7. Does replay record it?
8. What tests prove it?

For example, adding defensive fire would touch phase timing, command API, target selection, possibly pending state, AI behavior, and replay. Adding a new weapon flag might touch only weapon profiles, shooting resolution, snapshots, and tests. The checklist helps scope the change.

## The Chapter's Rule Of Thumb

Combat is allowed to be complex, but it should not be mysterious. Every branch should have a state reason, a rule reason, and where possible a log reason. The player can accept a harsh result if the game explains it. The maintainer can extend a harsh result if the state machine is explicit. That is the discipline behind this combat engine.

## Penetration, Saves, And Abstraction

The game abstracts many real-world details into a compact sequence of hit, wound or penetrate, save or damage, and morale consequence. That abstraction is necessary. World War 2 ballistics could become a separate simulation involving range bands, armor slope, ammunition type, crew training, visibility, suppression, and mechanical reliability. The demo instead uses strength, AP, armor, cover, hull-down state, and damage results.

The abstraction is successful when it creates the right tactical questions. Should the player expose a tank's side armor for a better shot? Should infantry leave cover to contest an objective? Should a mortar try to pin a squad instead of killing it outright? Should an anti-tank team fire now or wait for a closer shot? Those questions matter more to the current game than literal technical precision.

This does not mean values are arbitrary. They should remain historically inspired and internally consistent. A 17-pounder should feel more dangerous to armor than a rifle. A flamethrower should threaten cover. A heavy machine gun should project volume. But all values must be judged inside the board scale, turn rhythm, and unit model of this engine.

## Blast, Barrage, And Area Pressure

Blast and barrage flags give indirect or explosive weapons a role beyond ordinary shots. A blast diameter can affect multiple models or represent area danger. Barrage can bypass some line-of-sight requirements and interact with pinning. Ordnance can add weight to pinning or vehicle damage.

These flags are important because otherwise artillery-like weapons would become rifles with different names. The game needs mortars and tank guns to create different behavior. A mortar battery's ability to pressure units behind terrain changes how players read the board. A tank gun's ordnance behavior changes how vehicles and infantry respond.

When adding artillery, do not only set range and strength. Decide whether the weapon should be barrage, ordnance, blast, heavy, fixed, or mounted. Decide whether it should pin. Decide how it interacts with line of sight. Then test that behavior.

## Cover And Ignoring Cover

Cover is one of the main ways the board affects casualties. Terrain, manual cover, and hull-down state can all improve survivability. Flamethrowers and some special weapons can ignore cover. This creates a tactical triangle: terrain protects, certain weapons punish terrain reliance, movement changes exposure.

The `ignores_cover` flag is therefore a strong statement. It should be used sparingly. A weapon that ignores cover changes the value of terrain and can force movement. That is appropriate for flamethrowers. It may be inappropriate for ordinary automatic fire. The flag is small in code but large in play.

The UI should make cover-related states visible enough for the player to understand. Manual cover toggles and hull-down toggles are already exposed. Future overlays could show cover zones or unit cover status. But saves and cover interactions should continue to resolve in the engine.

## Preferred Casualty Groups

`game_set_preferred_casualty_group` gives players some control over mixed-profile casualty behavior before hits arrive. This is a subtle but useful feature. It reduces repetitive decisions when the player has a preferred allocation pattern, while still allowing explicit pending allocation when rules require it.

The command validates that the unit exists, uses mixed profile groups, and that the chosen group is valid and has models. It can also clear the preference. The log records the preference change.

This is a good example of a command that does not directly cause damage but shapes future resolution. It belongs in the engine because it affects future casualty assignment. It belongs in recorded actions because a saved battle must replay the same preference if later damage depends on it.

## Combat And Objective Play

Combat does not exist only to remove units. It changes objective control. Pinning an enemy squad may keep it from moving to a point. Destroying a transport may strand infantry away from a road junction. Assaulting a unit off an objective may swing scoring at end of turn. Smoke may keep a vehicle alive long enough to contest.

This means combat balance should be reviewed through objective play, not only kill probability. A weapon that rarely kills may still be powerful if it pins. A transport that never fires may be decisive if it delivers infantry. An assault unit may be valuable because it moves enemies, not because it destroys them efficiently.

When testing or playtesting combat, watch the mission state. Does shooting create decisions about objectives? Does assault matter before scoring? Do vehicles influence space? If combat only produces attrition without movement consequences, the battlefield will feel flat.

## AI Combat Choices

The AI's combat choices are simple but meaningful. It sorts targets by distance, objective relevance, and vehicle bias. It attempts shots with units that can shoot. It resolves its own pending choices. It attempts assaults against close targets in Assault phase.

The key point is that AI combat uses the same commands as human combat. It does not directly apply wounds or skip pending state. This makes AI a stress test for the engine. If pending choices are mishandled, the AI turn can expose that. If a command lacks clear failure behavior, AI loops become harder to reason about.

Future AI improvements should keep this command discipline. Smarter target scoring is welcome. Hidden damage shortcuts are not.

## Combat UI Responsibilities

The UI has three combat responsibilities: selection, command presentation, and explanation. Selection lets the player choose attacker and target. Command presentation enables shooting, assault, passenger fire, smoke, cover, hull-down, and pending choices. Explanation comes from snapshots, button state, inspector fields, and logs.

The UI should avoid a fourth responsibility: resolving combat. It should not calculate wounds, damage, morale, or vehicle results. If the player needs to choose during combat, the UI should display options from pending snapshots and send the selected option back.

This division keeps combat maintainable. Designers can tune rules in C. UI work can improve visibility. Tests can cover both layers separately.

## Edge Cases Worth Respecting

Combat code tends to collect edge cases because battle state is messy. A target may be embarked. A unit may be destroyed halfway through vehicle follow-on fire. A transport may lose passengers. A mixed-profile target may be destroyed before all pending state continues. A close combat may involve cover and simultaneous initiatives. A stunned assault gun may skip attacks but remain locked.

The current code has many guards for these situations. Future edits should preserve that caution. When adding a branch, ask what happens if the attacker dies, the target dies, a pending choice appears, or the unit is embarked. Combat bugs often come from assuming the battlefield stays unchanged during resolution.

## Final Combat Note

The combat system is the part of the game that most benefits from the C engine's authority. It has dice, state, interrupts, logs, and consequences across phases. Keeping it centralized is what lets the Swift UI remain playable and what lets tests reproduce complicated outcomes. The more detailed combat becomes, the more valuable that centralization is.
