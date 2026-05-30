# Order Tests And FUBAR Contract

Status: cycles 41-60 complete.

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This contract records the DZW rules-engine layer for order-dice turn end, morale quality, pinned-unit order tests, and FUBAR outcomes. It is repository-owned API documentation; the reference sheet remains the external rules target.

## Turn End

`game_order_dice_turn_complete(game)` reports whether the current order-dice turn has no current die waiting for assignment and no dice left in the cup.

`game_end_order_dice_turn(game)` ends an order-dice turn only when every drawn die has been assigned. It:

- rejects turn end while a current die is waiting for assignment
- rejects turn end while dice remain in the cup
- removes destroyed-unit dice from future activation
- clears spent dice
- preserves retained Ambush and Down orders
- rebuilds the next turn's remaining cup from units that are alive, unembarked, not falling back, not locked, and not retaining an order
- increments the game turn and logs the retained/returned dice counts

Retained Ambush and Down units keep their order marker, keep a retained die out of the cup, and become unacted for the new turn so later retained-order cancellation rules can be layered on cleanly.

## Morale Quality

The public morale values are:

- `DZW_MORALE_INEXPERIENCED`
- `DZW_MORALE_REGULAR`
- `DZW_MORALE_VETERAN`

The engine maps existing rosters to morale baselines from unit leadership and unit type:

- infantry with leadership 7 or below maps to Inexperienced
- infantry with leadership 8 maps to Regular
- infantry with leadership 9 or above maps to Veteran
- vehicles and assault guns map to Regular until vehicle morale receives a deeper dedicated model

`game_morale_quality_name` provides stable UI text for these values.

## Order Tests

Pinned units remain eligible for orders, but `game_unit_order_eligibility_view` sets `requires_order_test` and reports why. After `game_assign_order`, callers resolve the check with:

- `game_resolve_order_test(game, unitID)`

The result is recorded on `unit_view_t`:

- `last_order_test_result`
- `last_order_test_roll`
- `last_order_test_target`
- `last_order_test_pin_modifier`
- `last_order_test_officer_modifier`

The target uses the unit's morale baseline, subtracts one point per pin, adds the best nearby officer-style modifier currently represented by HQ/command units, and clamps the resulting target to the useful 2D6 range. Double-one always passes and removes one pin. A normal pass removes one pin except for Rally, where pin removal is resolved by the Rally action itself. A normal failure changes the unit's resulting order to Down and retains its die.

## FUBAR

Double-six on an order test records `DZW_ORDER_TEST_FUBAR` and immediately resolves one of the first two FUBAR branches:

- `DZW_FUBAR_FRIENDLY_FIRE`
- `DZW_FUBAR_PANIC`
- `DZW_FUBAR_DOWN`

The resulting details are exposed on `unit_view_t`:

- `last_fubar_result`
- `last_fubar_target_id`

Friendly Fire chooses an explicit friendly target from units that are near enemy pressure. The target list is inspectable through:

- `game_fubar_friendly_fire_target_count`
- `game_fubar_friendly_fire_target_view`

The current implementation records the friendly-fire target and changes the FUBAR unit to a Fire result so the upcoming shooting cycles can resolve the attack through the new shooting procedure.

Panic finds the nearest enemy unit and moves the FUBAR unit away on a Run result using the current legal-placement model. If no enemy or legal path exists, the unit goes Down instead.

## Swift Snapshot Fields

`UnitSnapshot` mirrors the new C fields so the UI can show order-test and FUBAR outcomes without reimplementing rules:

- `lastOrderTestRoll`
- `lastOrderTestTarget`
- `lastOrderTestPinModifier`
- `lastOrderTestOfficerModifier`
- `lastFubarResult`
- `lastFubarTargetID`
- `lastFubarResultName`

These fields are intentionally descriptive rather than prescriptive: downstream callers should display them, not recompute them.
