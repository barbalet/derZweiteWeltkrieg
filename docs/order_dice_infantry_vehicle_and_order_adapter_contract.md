# Order-Dice Infantry Assaults and Order Adapter Contract

Status: cycles 161-180 complete.

This contract records the next playable slice of the order-dice conversion. It follows the Bolt Action reference shape used by the project: orders are issued from a drawn die, assaults require a Run order, pinned or unnerved troops may need tests, vehicles use armour and damage-table resolution, and Down/Ambush states remain visible to the caller.

## Infantry Assaulting Vehicles

Infantry can assault a vehicle only from a legal Run order. A vehicle that has already made a Run move this turn rejects the assault, because the infantry cannot catch a vehicle that has gone flat out across the board.

Enclosed armour now applies a separate nerve check when the assaulting infantry does not carry anti-tank assault equipment. The engine records:

- whether the assault target used vehicle rules;
- whether the attacker had anti-tank assault equipment;
- whether the enclosed-armour order test was required;
- the 2D6 roll, target number, and fail/pass outcome;
- whether the assault was consumed before contact.

Anti-tank assault equipment is detected from live weapon profiles. Shaped-charge, one-shot, flamethrower, or penetration 2+ weapons qualify. PIAT, bazooka, Panzerfaust, and flamethrower teams therefore skip the enclosed-armour penalty, while rifle-only sections must test before attacking a closed tank.

## Defensive Fire and Damage

Vehicles may fire one suitable direct-fire weapon defensively before infantry resolve close-assault damage. The defensive fire path records that it was resolved, applies a simple 4+ hit roll per shot, tests damage against the attacker's order-dice infantry damage value, and adds pins when hits are scored.

Infantry-vs-vehicle close assault no longer uses the old strength-versus-armour shortcut in the order-dice ruleset. It now records and applies:

- assault hit count;
- vehicle damage value;
- penetration modifier from the best anti-tank assault weapon or close-combat strength fallback;
- side/rear armour modifier from the attack arc;
- damage roll;
- superficial/full/massive vehicle damage class;
- vehicle damage table result and wreck/regroup outcome.

When the vehicle is knocked out, the winner may regroup up to 3 inches using the same legal movement guard already used by close quarters.

## Assault Compatibility

Fixed-phase close combat keeps the old frontage cap as a legacy rule. Order-dice infantry close quarters bypasses that cap so all eligible models in the initiative band can fight. Order-dice loser destruction, draw continuation, and regroup remain the authoritative close-quarters outcome. The legacy locked-combat, fall-back, and consolidation outcomes are now retained only behind the fixed-phase path.

## Swift Snapshot Fields

`unit_view_t` and Swift `UnitSnapshot` now expose the vehicle-assault trace alongside the existing order-dice fields:

- current order, retained order, Down/Ambush state, pins, morale quality, order-test/FUBAR details;
- vehicle-assault target and anti-tank equipment booleans;
- enclosed-armour test roll, target, and failure;
- defensive-fire resolution flag;
- vehicle hits, damage value, penetration modifier, damage roll, and damage class.

The app summary includes these details in the existing order-dice summary string so the UI can explain why an assault stopped, survived defensive fire, or damaged a vehicle.

## Historical Board Orders

`HistoricalBoardSession` now defines `HistoricalBoardOrder` with Fire, Advance, Run, Ambush, Rally, and Down. Shared historical unit snapshots carry current order, available orders, order-dice summary, pin count, morale quality, retained order, Down, and Ambush state.

`HistoricalPlayableBattleView` exposes order buttons for selected units and routes them through `onIssueOrder`. The old phase-advance entry point remains available through the explicitly named deprecated `advanceLegacyPhase()` wrapper, while newer callers can issue orders directly and then execute movement, shooting, or assault actions under the selected order.

