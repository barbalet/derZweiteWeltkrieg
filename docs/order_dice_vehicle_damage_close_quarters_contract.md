# Order Dice Vehicle Damage And Close Quarters Contract

Status: cycles 141-160 complete.

Reference anchor: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This contract records the DZW implementation for vehicle damage results,
wrecked armoured vehicles, infantry close quarters, and defender reactions in
the order-dice ruleset. The language here is repository-owned API
documentation; the reference sheet remains the external rules target.

## Vehicle Damage Table

Order-dice vehicle penetration now resolves through a damage table after a
penetrating result has been classified as superficial, full, or massive.
Superficial damage applies a `-3` table modifier, full damage rolls normally,
and massive damage rolls twice unless the first result destroys the vehicle.

The table outcomes are exposed through `dzw_vehicle_damage_result_t`:

- `DZW_VEHICLE_DAMAGE_RESULT_NONE`
- `DZW_VEHICLE_DAMAGE_RESULT_CREW_STUNNED`
- `DZW_VEHICLE_DAMAGE_RESULT_IMMOBILIZED`
- `DZW_VEHICLE_DAMAGE_RESULT_ON_FIRE`
- `DZW_VEHICLE_DAMAGE_RESULT_KNOCKED_OUT`

Crew Stunned, Immobilized, and a passed On Fire morale check place or convert
the vehicle to Down for the rest of that order-dice turn. On Fire records the
morale roll and target; a failed check destroys the vehicle. A second
Immobilized result is recorded as Knocked Out and destroys the vehicle.

The public state is exposed through:

- `unit_view_t.last_vehicle_damage_table_roll`
- `unit_view_t.last_vehicle_damage_result`
- `unit_view_t.last_vehicle_damage_morale_roll`
- `unit_view_t.last_vehicle_damage_morale_target`
- `unit_view_t.last_vehicle_damage_morale_failed`
- `game_vehicle_damage_result_name`
- matching Swift `UnitSnapshot` fields and summary text

## Wrecks

Knocked-out armoured vehicles remain as wrecks. The engine marks them with
`unit_view_t.wrecked` and reports whether they block movement through
`unit_view_t.wreck_blocks_movement`.

Order-dice movement and reverse movement reject paths that cross a wrecked
armoured vehicle. Final placement also rejects ending on top of an armoured
wreck. The legacy fixed-phase movement flow keeps its existing permissive
placement behavior so older compatibility tests and campaign adapters are not
silently migrated before the later acceptance cycles.

## Close Quarters

Order-dice infantry close quarters enters through a Run order and records the
declared target, measured assault range, and target reaction before movement to
contact. Infantry-vs-infantry close quarters now follows the order-dice result
shape: both sides resolve damage, ties trigger additional rounds, and the loser
is destroyed rather than falling back through the legacy morale path.

The winner regroups by using the existing consolidation helper, which returns
the actual regroup distance for UI and tests. Draws are capped by a deterministic
roll-off guard after repeated tied rounds so pathological seed combinations do
not leave a combat unresolved forever.

The public state is exposed through:

- `unit_view_t.last_assault_target_id`
- `unit_view_t.last_assault_range`
- `unit_view_t.last_assault_target_reaction`
- `unit_view_t.last_assault_attacker_wounds`
- `unit_view_t.last_assault_defender_wounds`
- `unit_view_t.last_assault_draw_rounds`
- `unit_view_t.last_assault_winner_id`
- `unit_view_t.last_assault_loser_id`
- `unit_view_t.last_assault_loser_destroyed`
- `unit_view_t.last_assault_regroup_distance`
- matching Swift `UnitSnapshot` fields and summary text

## Defender Reactions

Assault declaration now uses the same public target-reaction enum as shooting:

- `DZW_TARGET_REACTION_NONE`
- `DZW_TARGET_REACTION_DOWN`
- `DZW_TARGET_REACTION_AMBUSH_READY`

Down is recorded as a defender reaction for UI/history purposes. A retained
Ambush order can become opportunity fire before contact: the retained die is
moved to spent, the defender changes to Fire, and `game_shoot_unit` resolves
against the assaulting unit before movement. If that opportunity fire creates a
pending choice or destroys the attacker, the assault command returns after the
fire is resolved so the caller can handle the pending state normally.

## Tests

The cycle tests cover vehicle damage table outcomes, Down transitions, On Fire
morale detail, wreck creation and movement blocking, close-quarters loser
destruction, Down reaction recording, and Ambush opportunity fire before
contact.
