# Order Dice Shooting and Damage Contract

Status: cycles 101-140 complete.

This contract describes the current Bolt Action-inspired shooting layer used by
the order-dice ruleset. It is intentionally inspectable from `unit_view_t` and
Swift `UnitSnapshot` so the UI can explain why a shot needed a given target
number and what happened after hits were scored.

Reference anchor: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

## Hit Modifiers

Order-dice shooting now records a base ballistic target and the individual
modifiers that changed it:

- point blank: `-1` when the target is within 6 inches
- pins on firer: `+1` per active pin marker on the attacking unit
- long range: `+1` beyond half weapon range
- inexperienced firer: `+1`
- fire on the move: `+1` after movement
- Down target: `+1` for retained Down infantry/artillery
- small unit: `+1` for small infantry targets
- cover: `+1` soft cover or `+2` hard cover

The engine exposes:

- `last_shooting_base_to_hit`
- `last_shooting_*_modifier`
- `last_shooting_to_hit_modifier`
- `last_shooting_needed_to_hit`

Fixed-phase shooting keeps its legacy behavior, while the order-dice ruleset
uses these modifiers for infantry, vehicle, and non-indirect blast hit rolls.

## Damage Values And Penetration

Order-dice damage resolution now uses damage values rather than the legacy
strength-versus-toughness wound table:

- inexperienced infantry: DV 3
- regular infantry: DV 4
- veteran infantry: DV 5
- open-topped soft-skin/light vehicle: DV 6
- light armour through heavier armour maps upward from DV 7 to DV 11

Weapon penetration now comes from the normalized weapon chart fields for
weapons that have been converted to the order-dice profile model. Legacy
strength-derived penetration remains only as a compatibility fallback for
profiles that have not yet been charted. This keeps the public arithmetic
inspectable while allowing small arms, anti-tank weapons, heavy weapons,
flamethrowers, mortars, and vehicle weapons to express their own penetration
values directly.

The engine exposes:

- `last_shooting_damage_value`
- `last_shooting_penetration_modifier`
- `last_shooting_damage_roll`
- `last_shooting_damage_success`

## Weapon Chart Fields

`weapon_profile_view_t` now exposes the order-dice chart data needed by UI,
AI, and test tooling:

- `min_range`
- `penetration`
- `he_hits_dice_count`
- `he_hits_die_sides`
- `he_pins_dice_count`
- `he_pins_die_sides`
- `he_penetration`
- `indirect_fire`
- `team`
- `fixed`
- `shaped_charge`
- `one_shot`

The initial charted profiles cover the demo's small arms, light/heavy machine
guns, anti-tank gun, tank guns, mortars, flamethrower, bazooka, PIAT,
panzerfaust, and autocannon profiles.

## HE And Indirect Fire

Converted HE weapons use explicit hit dice, pin dice, and fixed HE penetration
instead of reusing the old blast strength. Indirect weapons can also define a
minimum range. A target inside that range is rejected in the order-dice ruleset
with a minimum-range error before the shot is resolved.

The current converted demo profiles include:

- 81mm mortar: 18-60 inch range, D6 HE hits, D2 pins, +2 HE penetration
- 120mm mortar: 18-72 inch range, 2D6 HE hits, D3 pins, +3 HE penetration
- 17-pounder and tank-gun HE: small HE hit dice with fixed low HE penetration

## Vehicle Penetration Detail

Order-dice vehicle shooting now records the extra vehicle arithmetic needed to
explain anti-armour attacks:

- side armour attacks add `+1` penetration
- rear armour attacks add `+2` penetration
- long-range anti-armour fire applies `-1` beyond half range
- indirect HE against open-topped vehicles applies the open-topped modifier
- penetration outcomes are classified as none, superficial, full, or massive

The engine exposes:

- `last_shooting_vehicle_armour_modifier`
- `last_shooting_vehicle_long_range_penalty`
- `last_shooting_vehicle_open_topped_indirect_modifier`
- `last_shooting_vehicle_damage_class`

## Pins From Fire

Incoming order-dice fire now adds pin markers consistently:

- small-arms hits add one pin marker to infantry targets
- template and HE hits add pins before damage is resolved
- vehicle damage that reaches the vehicle damage value adds pins
- FUBAR outcomes add a pin marker to the affected unit

The shooting procedure still records `last_shooting_pins_added`, and the action
log records the source that caused the pin marker.

## Morale After Casualties

Order-dice infantry morale checks now trigger after shooting casualties. The
check uses the unit morale quality baseline, active pin penalty, and nearby
officer modifier. Failed checks route through the existing fallback/removal
path, including table-edge removal if the fallback leaves the board.

The engine exposes:

- `last_shooting_morale_checked`
- `last_shooting_morale_roll`
- `last_shooting_morale_target`
- `last_shooting_morale_pin_modifier`
- `last_shooting_morale_officer_modifier`
- `last_shooting_morale_failed`

## Tests

The cycle tests cover point blank fire, stacked defensive modifiers, moving
inexperienced fire, pins from small-arms hits, casualty morale detail recording,
Fire/Advance shooting compatibility, weapon chart exposure, indirect HE minimum
range and pins, and vehicle armour-arc/long-range penetration arithmetic.
