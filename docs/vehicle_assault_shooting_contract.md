# Vehicle Manoeuvre, Assault Movement, And Shooting Contract

Status: cycles 81-100 complete.

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This document records the DZW implementation contract for vehicle manoeuvre, Run-order assault movement, UI-facing movement legality, and the first structured shooting-procedure state. It is repository-owned API documentation; the reference sheet remains the external rules target.

## Vehicle Manoeuvre

Vehicles now expose reverse and pivot behavior in the order-dice ruleset.

`game_reverse_unit(game, unitID, distance)` resolves a straight reverse move for a vehicle on an Advance order. Non-recce vehicles reverse up to half their standard Advance rate. Recce vehicles reverse up to their full standard Advance rate. Artillery batteries do not use the vehicle reverse move.

Pivot budgets are tracked during order-dice movement:

| Mobility | Advance pivots | Run pivots |
| --- | ---: | ---: |
| Tracked vehicle | 1 | 0 |
| Half-track | 2 | 1 |
| Wheeled vehicle | 2 | 1 |

The public state is exposed through:

- `unit_view_t.reverse_move_allowance`
- `unit_view_t.can_reverse_now`
- `unit_view_t.last_reverse_distance`
- `unit_view_t.pivot_budget`
- `unit_view_t.pivot_count_used`
- matching `UnitSnapshot` fields

## Movement UI Contract

Movement legality now has a UI-readable blocker string. Callers can read the selected unit's current blocker from `unit_view_t.movement_rejection_reason` or ask about a specific order through:

- `game_unit_order_movement_rejection_reason(game, unitID, order)`

The movement, shooting, and assault execution helpers all reject unresolved required order tests. This keeps the UI from showing an executable move for a pinned unit that has not yet passed its order test.

## Assault Movement

In the order-dice ruleset, close assault is entered through `DZW_ORDER_RUN`. `game_assault_unit` uses the unit's Run movement allowance to measure legal contact rather than the legacy fixed-phase 6-inch charge distance. Successful non-continuing assaults mark the attacker as moved and record `moved_distance`; Run already prevents normal shooting from the same order.

## Shooting Procedure

`game_shoot_unit` now records structured procedure state on the firing unit:

- declared target id
- measured range
- target reaction state
- range-check completion
- hit-roll completion
- damage-resolution completion
- models removed
- pin markers added
- morale-check step reached

The target reaction enum is:

- `DZW_TARGET_REACTION_NONE`
- `DZW_TARGET_REACTION_DOWN`
- `DZW_TARGET_REACTION_AMBUSH_READY`

`game_target_reaction_name` provides stable display text for these values. This cycle records the reaction state and keeps the existing shooting resolution machinery; later cycles expand the full modifier and damage-value model.

## Test Coverage

The cycle 81-100 tests cover:

- non-recce and recce reverse movement limits
- tracked and wheeled pivot budgets
- UI movement blocker text for unresolved order tests
- Run-order assault movement beyond the old fixed 6-inch charge distance
- Advance-order assault rejection
- shooting procedure state for declared target, range, target reaction, hit/damage steps, casualties, pins, and morale
