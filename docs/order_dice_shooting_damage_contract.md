# Order Dice Shooting and Damage Contract

Status: cycles 101-120 complete.

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

## Damage Values

Order-dice damage resolution now uses damage values rather than the legacy
strength-versus-toughness wound table:

- inexperienced infantry: DV 3
- regular infantry: DV 4
- veteran infantry: DV 5
- open-topped soft-skin/light vehicle: DV 6
- light armour through heavier armour maps upward from DV 7 to DV 11

Weapon penetration is derived from weapon strength as `strength - 4`, clamped
at zero. This keeps current weapon profiles usable until the weapon chart model
cycle normalizes every weapon directly into range, shots, and penetration.

The engine exposes:

- `last_shooting_damage_value`
- `last_shooting_penetration_modifier`
- `last_shooting_damage_roll`
- `last_shooting_damage_success`

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
and vehicle damage-value/penetration arithmetic.
