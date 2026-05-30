# Order-Dice Activation Contract

Status: cycles 21-40 complete.

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This contract records the staged DZW API surface for order-dice activation. It follows the reference turn sequence at the engine-control level: build a dice cup, draw one side's die, assign one order to one eligible unit, and track whether the die is spent or retained.

## Ruleset Toggle

The fixed-phase game remains the default playable path while the migration is in progress. Order dice are enabled explicitly:

- `game_set_ruleset(game, DZW_RULESET_ORDER_DICE)`
- `game_set_ruleset(game, DZW_RULESET_FIXED_PHASES)`

Switching to order dice rebuilds the cup from currently eligible units. Switching back clears the order-dice lifecycle state.

## Dice Cup

The cup is exposed through deterministic views:

- `game_rebuild_order_dice_cup`
- `game_order_dice_remaining_count`
- `game_order_dice_remaining_view`
- `game_order_dice_replay_signature`

Each die records a sequence number and owner. The sequence is for deterministic replay diagnostics; the die still represents side activation, not a forced unit binding.

## Draw Lifecycle

The draw path is:

1. `game_draw_order_die`
2. `game_current_order_die_view`
3. `game_assign_order`

A new die cannot be drawn while the current die is waiting for assignment. Assignment fails when no die has been drawn. After assignment, the current die moves to either the spent pool or retained pool.

Current lifecycle views:

- `game_order_dice_spent_count`
- `game_order_dice_spent_view`
- `game_order_dice_retained_count`
- `game_order_dice_retained_view`

Cycles 41-45 will add full turn-end return of spent dice, retained Ambush/Down handling across turns, and destroyed-unit cleanup at the turn boundary.

## Eligibility

`game_unit_order_eligibility_view(game, unitID, order)` reports whether a unit can receive a specific order from the current die.

The view includes:

- `eligible`
- `requires_order_test`
- `reason`

Explicit reasons are returned for missing dice, wrong side, destroyed units, embarked units, falling-back units, locked units, retained orders, already ordered units, immobilized vehicles receiving movement orders, and crew-stunned vehicle restrictions. Pinned units remain eligible at this stage, but report that an order test is required.

## Assign Order

`game_assign_order(game, unitID, order)` is now the central order assignment command for the order-dice ruleset. It supports:

- Fire
- Advance
- Run
- Ambush
- Rally
- Down

The command marks the unit as having received an order this turn. Ambush and Down currently move the die into the retained pool. Fire, Advance, Run, and Rally move the die into the spent pool.

## Compatibility Execution Helpers

The old public movement, shooting, and assault commands remain available for the fixed-phase ruleset. In the order-dice ruleset they now operate as execution helpers behind assigned orders:

- Advance or Run enables `game_move_unit`
- Fire or Advance enables `game_shoot_unit`
- Run enables `game_assault_unit`

Later cycles will add the full order-specific action payloads and turn-end cleanup. For now this creates a compileable, tested bridge from fixed phases to order assignment without removing the playable fixed-phase demo.
