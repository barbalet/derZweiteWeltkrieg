# Order-Dice Rules Model

Status: cycles 6-10 complete.

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This document is DZW's internal, repository-owned model for the order-dice migration. It uses the Warlord reference sheet as the target rules vocabulary, but the engine contracts and descriptions here are written for this codebase.

## Turn Lifecycle

The new ruleset is centered on a dice cup rather than side-wide phases.

1. Build a cup from every eligible unit's side-owned order die.
2. Draw one die.
3. The owning side chooses one eligible unit.
4. That unit receives one order.
5. If pins or special conditions require an order test, resolve it before action execution.
6. Execute the resulting action immediately.
7. Continue drawing until all eligible units have acted or legally retained standing orders.
8. At turn end, remove dice for destroyed units, return normal dice to the cup, and preserve allowed retained Ambush or Down states.

The fixed Movement, Shooting, and Assault phases remain only as compatibility infrastructure until their public callers have migrated to unit orders.

## Public Orders

DZW exposes these typed orders:

- `DZW_ORDER_FIRE`: the unit remains in place and fires at full effect.
- `DZW_ORDER_ADVANCE`: the unit moves at its normal advance rate and may fire with movement penalties where applicable.
- `DZW_ORDER_RUN`: the unit moves at its run rate and normally cannot fire; this is also the assault movement order.
- `DZW_ORDER_AMBUSH`: the unit holds fire for an opportunity trigger.
- `DZW_ORDER_RALLY`: the unit gives up movement and fire to shed pin pressure.
- `DZW_ORDER_DOWN`: the unit takes a defensive posture and becomes harder to hit.

`DZW_ORDER_NONE` is a staging value for units that have not yet received an order this turn.

## Unit Activation State

Each unit needs order-dice state independent of the old phase flags:

- `current_order` records the assigned order or `None`.
- `acted_this_turn` prevents assigning a second normal order during the same turn.
- `retained_order` records Ambush or Down persistence where later rules allow it.
- `pin_count` records accumulated pin markers.
- `morale_quality` records Inexperienced, Regular, or Veteran quality.
- `last_order_test_result` gives UI and replay systems a stable result value.

These primitives are public before the full order lifecycle exists so Guderian, Monty, tests, and Swift UI code can compile against the future-facing contract early.

## Morale, Pins, And Order Tests

Morale quality establishes a unit's baseline nerve. Regular is the DZW default for existing units until army-list mapping cycles assign more precise quality. Pins are numeric pressure markers. A pinned unit may need to test before following an order, and the pin count will later feed both order-test and shooting penalties.

Order-test results are represented as:

- `DZW_ORDER_TEST_NOT_REQUIRED`
- `DZW_ORDER_TEST_PASSED`
- `DZW_ORDER_TEST_FAILED`
- `DZW_ORDER_TEST_FUBAR`

The FUBAR result is reserved for the reference-style catastrophic order failure branch. Later cycles will model friendly-fire and panic outcomes as structured results, including fallbacks to Down when no legal target or path exists.

## Movement Model

Movement becomes order-specific:

- Infantry Advance and Run are separate rates.
- Tracked and half-tracked vehicles use different manoeuvre limits from wheeled vehicles.
- Roads, rough ground, obstacles, and buildings affect unit classes differently.
- Run is forbidden in some terrain where Advance remains legal.
- Vehicle reverse movement and pivot budgets become explicit in the movement validator.

The existing DZW movement code remains a useful geometry, collision, terrain, transport, and displacement substrate. Later cycles should replace its public phase checks with order-specific legality checks.

## Shooting Model

Shooting should resolve through a declared target and a visible procedure:

- Declare target.
- Resolve any target reaction.
- Check range and line of sight.
- Roll to hit with modifiers.
- Roll damage or penetration.
- Apply casualties, vehicle damage, pins, and morale consequences.

Fire and Advance become the normal shooting orders. Down, Ambush, Rally, and Run either block normal shooting or route through special-case reaction logic. Later cycles must replace the old "shoot now because it is the Shooting phase" contract.

## HE, Weapons, And Vehicles

The weapons chart migration will normalize small arms, machine guns, anti-tank weapons, flamethrowers, mortars, howitzers, and vehicle weapons into public weapon-chart data. HE needs blast size, penetration modifier, pin dice, and indirect-fire constraints. Vehicles need armour-facing modifiers, long-range penetration adjustments, superficial/full/massive damage classifications, Down transitions, immobilized state, fire checks, knockout, and wreck terrain behavior.

The existing weapon slots, vehicle arcs, transport state, crew damage, smoke, hull-down, and pending choice flows should be reused where they still match the new rules.

## Close Quarters Model

Close quarters begins from an order, not from a global Assault phase. The usual path is a Run order into legal contact. The engine should expose target reaction, movement distance, damage rounds, loser destruction, draw handling, and winner regroup as inspectable steps. Infantry-vs-vehicle assaults need their own legality checks, including anti-tank equipment and enclosed-armour pressure where represented.

## Cycle 20 Boundary

After cycle 20 the game is expected to still play through the old fixed phase loop. The completed work is the migration foundation: audit notes, target model notes, diagnostics identifying legacy phase dependencies, a staged ruleset enum, typed order values, and public unit state for order, pins, morale quality, retained order, acted state, and order-test result.
