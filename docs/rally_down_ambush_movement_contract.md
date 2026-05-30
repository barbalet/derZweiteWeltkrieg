# Rally, Down, Ambush, And Movement Contract

Status: cycles 61-80 complete.

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This document records the DZW implementation contract for Rally, Down, Ambush, order-specific movement rates, and terrain movement categories. It is repository-owned API documentation; the reference sheet remains the external rules target.

## Rally

Rally is represented by `DZW_ORDER_RALLY` and is resolved in two explicit steps:

- assign Rally through `game_assign_order`
- resolve the Rally action through `game_resolve_rally_order`

Pinned units still make any required order test before Rally takes effect. Unlike normal successful order tests, Rally does not remove a pin during the test pass; the Rally action rolls its own D6 and removes that many pins. The exact roll and delta are exposed through:

- `unit_view_t.last_rally_roll`
- `unit_view_t.last_rally_pins_removed`
- `UnitSnapshot.lastRallyRoll`
- `UnitSnapshot.lastRallyPinsRemoved`

An unresolved Rally order blocks `game_order_dice_turn_complete` and `game_end_order_dice_turn`, keeping turn-end state honest until the no-move/no-fire Rally action is resolved.

## Down

Down remains a retained order state and now carries an explicit defensive modifier for infantry and artillery targets. The public state is exposed through:

- `unit_view_t.down_order_active`
- `unit_view_t.defensive_to_hit_modifier`
- `UnitSnapshot.downOrderActive`
- `UnitSnapshot.defensiveToHitModifier`

The shooting engine applies the modifier to non-template infantry hit rolls against a Down infantry or artillery target. Swift snapshots include the state in `orderDiceSummary` so the UI can present the retained defensive order without recalculating it.

## Ambush

Ambush remains a retained order state with explicit opportunity-fire transitions:

- `game_trigger_ambush_order(game, unitID)` converts retained Ambush to Fire, moves the retained die to the spent pool, and makes the owning player active so the existing shooting command can resolve the opportunity shot.
- `game_cancel_ambush_order(game, unitID)` converts retained Ambush to retained Down, preserving the retained die while ending the Ambush posture.

The pending state is exposed through `unit_view_t.ambush_order_active` and `UnitSnapshot.ambushOrderActive`.

## Movement Rates

Order-dice movement now uses order-specific Advance and Run allowances instead of the legacy global phase allowance:

| Mobility | Advance | Run |
| --- | ---: | ---: |
| Infantry | 6" | 12" |
| Artillery | 6" | 12" |
| Tracked vehicle | 9" | 18" |
| Half-track | 9" | 18" |
| Wheeled vehicle | 12" | 24" |

Artillery uses the infantry movement rate in the current engine because crew-moved guns do not yet have towing or limbering state. Its terrain permissions are separate from infantry and vehicles.

The engine exposes these values through:

- `game_unit_order_movement_allowance`
- `unit_view_t.advance_move_allowance`
- `unit_view_t.run_move_allowance`
- `unit_view_t.current_order_move_allowance`
- `UnitSnapshot.advanceMoveAllowance`
- `UnitSnapshot.runMoveAllowance`
- `UnitSnapshot.currentOrderMoveAllowance`

`unit_view_t.moved_distance` and `UnitSnapshot.movedDistance` also publish actual distance moved for UI diagnostics, shooting modifiers, and road movement tests.

## Terrain Categories

The public terrain categories now include open, difficult/rough, impassable, obstacle, building, and road. Order-dice movement checks the path category before applying the distance allowance.

The current movement table is:

- infantry cannot Run through rough or difficult ground
- artillery cannot enter rough ground, obstacles, or buildings once play has started
- vehicles cannot enter buildings
- wheeled vehicles cannot enter rough or difficult ground
- tracked vehicles can Advance through rough or difficult ground but cannot Run through it
- only tracked vehicles can cross obstacles
- vehicle movement is doubled when the full path starts and ends inside the same road zone

Fixed-phase compatibility movement keeps the older difficult-terrain immobilization behavior. The new terrain table only applies while `DZW_RULESET_ORDER_DICE` is enabled.

## Test Coverage

The cycle 61-80 tests cover:

- Rally pin removal and turn-end gating
- Down retained state and defensive modifier exposure
- Ambush trigger and cancel transitions
- infantry, artillery, tracked, and wheeled Advance/Run allowances
- rough-ground restrictions for infantry, tracked vehicles, and wheeled vehicles
- artillery rough/obstacle restrictions, road non-doubling, vehicle road doubling, and actual moved-distance reporting
