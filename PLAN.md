# DZW 200-Cycle Order-Dice Rules Migration Plan

## Purpose

This plan tracks the `derZweiteWeltkrieg` rules-engine migration from the current fixed turn/phase model to a Bolt Action-style order-dice activation game. DZW is the rules authority for this change. Guderian and Monty must consume the resulting public contracts rather than reimplementing their own variants.

The external rules reference is Warlord Games' Bolt Action reference sheet: `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`. Use it as the rules target, but write original engine/API documentation and tests in this repository.

## Migration Principle

The new fundamental loop is:

1. Build an order-dice cup from eligible units.
2. Draw one side's order die.
3. That side assigns one order to one eligible unit.
4. Resolve any required order test, including failure and FUBAR outcomes.
5. Execute that unit's action immediately.
6. Continue drawing dice until all eligible units have acted or retained eligible standing orders.
7. End the turn, clean up destroyed-unit dice, return dice to the cup, and preserve retained Ambush/Down orders where rules allow.

The old all-units movement -> shooting -> assault phase flow becomes compatibility infrastructure only until the new loop is complete.

## Cycle Range Summary

- **Cycles 1-20:** baseline audit, public rules model, and compatibility gates.
- **Cycles 21-45:** order dice, order assignment, activation state, and turn-end cleanup.
- **Cycles 46-70:** order tests, morale, pins, Rally, Down, Ambush, and FUBAR.
- **Cycles 71-95:** order-specific movement and terrain/vehicle manoeuvre.
- **Cycles 96-125:** shooting procedure, hit modifiers, damage values, and pin effects.
- **Cycles 126-150:** weapons, HE, vehicle damage, and destruction/wreck state.
- **Cycles 151-170:** close quarters and infantry-vs-vehicle assault.
- **Cycles 171-185:** Swift snapshots, public historical adapters, UI-facing command contracts, and autoplay hooks.
- **Cycles 186-195:** book/docs/reference updates and migration notes.
- **Cycles 196-200:** full acceptance, deprecated phase-flow quarantine, and downstream release handoff.

## Cycles 1-200

| Cycles | Focus | Technical Output |
| --- | --- | --- |
| 1-5 | Rules baseline audit | Inventory the current DZW turn, phase, movement, shooting, morale, assault, vehicle, transport, and UI snapshot APIs. Identify every API that assumes side-wide phases or one full side acting at a time. |
| 6-10 | Rules target model | Add an internal rules-design note for order dice, orders, pins, order tests, FUBAR, movement, shooting, HE, vehicles, and close quarters. Keep it paraphrased and repository-owned. |
| 11-15 | Compatibility gates | Add failing tests or diagnostics proving that the old fixed phase loop is still active and must be retired. Add a feature flag or ruleset enum so migration work can be staged. |
| 16-20 | Public data primitives | Introduce typed order values: Fire, Advance, Run, Ambush, Rally, Down. Add unit order state, acted-this-turn state, retained-order state, pin count, morale quality, and order-test result types. |
| 21-25 | Order dice cup | Build deterministic order-dice cup generation from alive eligible units by side. Support seeded draw order for tests and replay signatures. |
| 26-30 | Draw lifecycle | Add draw-one-die, current-die-owner, remaining dice, spent dice, retained dice, and destroyed-unit dice cleanup. Reject activation when no die is available. |
| 31-35 | Unit eligibility | Enforce one order per unit per turn. Destroyed, embarked, routed, pinned, retained, immobilized, and special-case units must expose explicit eligibility reasons. |
| 36-40 | Assign order command | Replace phase-specific command entry points with `assignOrder(unitID:order:)` as the central engine command. Existing movement/shooting APIs become execution helpers behind assigned orders. |
| 41-45 | Turn end | Implement order-dice return at turn end, destroyed-unit die removal, retained Ambush/Down handling, pin/order cleanup hooks, replay logging, and tests for multi-turn state. |
| 46-50 | Morale quality | Add Inexperienced, Regular, and Veteran morale baselines. Map existing units to quality through army list entries and scenario overrides. |
| 51-55 | Order tests | Implement order-test rolls with pin penalties, officer modifiers, double-one success, double-six failure, and structured result reporting for UI/history. |
| 56-60 | FUBAR | Implement FUBAR resolution with friendly-fire and panic branches. Make target selection explicit and testable; where no legal FUBAR target/path exists, resolve to Down. |
| 61-65 | Rally and pins | Implement Rally as a no-move/no-fire order that removes a die-roll amount of pins, applies officer modifiers where legal, and records exact pin deltas. |
| 66-70 | Down and Ambush | Implement Down as a defensive order with hit modifier effects. Implement Ambush as a retained opportunity-fire state with clear trigger/cancel semantics and UI-readable pending state. |
| 71-75 | Movement rates | Replace old generic movement allowances with order-specific Advance and Run rates for infantry, tracked vehicles, half-tracks, and wheeled vehicles. |
| 76-80 | Terrain table | Add terrain movement rules for open, rough, obstacle, building, and road categories, including no-run, no-entry, artillery exceptions, road doubling, and tests for each mobility class. |
| 81-85 | Vehicle manoeuvre | Implement reverse moves, pivot budgets, tracked/half-track/wheeled pivot differences, immobilized movement rejection, and recce reverse exceptions where represented. |
| 86-90 | Assault movement | Treat Run as the assault movement order. Enforce target declaration, distance measurement, legal contact, and no-fire after Run. |
| 91-95 | Movement UI contract | Expose legal movement ranges and rejection reasons by order type in Swift snapshots. Remove UI assumptions that movement is always the current global phase. |
| 96-100 | Shooting procedure | Rebuild shooting around declared target, target reaction, range check, roll to hit, roll to damage, casualties/damage, and morale/pin consequences. |
| 101-105 | Hit modifiers | Implement point blank, pins on firer, long range, inexperienced firer, fire on the move, Down target, small unit, soft cover, and hard cover modifiers. |
| 106-110 | Damage values | Implement troop/soft-skin damage thresholds and armoured target damage thresholds. Keep penetration arithmetic inspectable in tests. |
| 111-115 | Pins from fire | Apply pins consistently from incoming fire, HE, vehicle damage, and FUBAR. Expose pin changes in action logs and snapshots. |
| 116-120 | Morale checks after casualties | Add morale checks after relevant casualties/damage, routing/removal outcomes, and commander/officer modifier hooks. |
| 121-125 | Shooting compatibility | Retire or wrap old `shoot now in shooting phase` APIs so Fire and Advance orders are the only normal shooting paths. Add regression tests that fail if side-wide shooting phase remains the default. |
| 126-130 | Weapons chart model | Normalize small arms, heavy weapons, anti-tank weapons, flamethrowers, mortars, howitzers, and vehicle weapons into range, shots, penetration, and special-rule fields. |
| 131-135 | HE | Implement HE dice size, pin dice, fixed penetration modifier, blast/casualty grouping hooks, and indirect-fire minimum/maximum range where represented. |
| 136-140 | Vehicle penetration | Add side/top/rear armour modifiers, long-range heavy-weapon modifier, superficial/full/massive damage classifications, and open-topped indirect-fire modifier. |
| 141-145 | Vehicle damage table | Implement crew stunned, immobilized, on fire, knocked out, wreck creation, duplicate immobilized destruction, and order-to-Down transitions. |
| 146-150 | Wreck and terrain effects | Treat wrecked armoured vehicles as impassable terrain where configured. Add cleanup/display state for removed-vs-wrecked vehicle policies. |
| 151-155 | Close quarters procedure | Implement infantry-vs-infantry assault declaration, target reaction, assault movement, simultaneous/sequenced damage rounds, loser destruction, draw continuation, and winner regroup. |
| 156-160 | Defender reactions | Add target reactions needed by shooting and assaults, including Down and opportunity fire from Ambush where legal. |
| 161-165 | Infantry vs vehicles | Implement infantry assaulting vehicles: Run restriction, anti-tank equipment requirement/order-test penalty for enclosed armour, vehicle defensive fire, hit/damage calculation, and regroup. |
| 166-170 | Assault compatibility | Quarantine old close-combat frontage and consolidation rules that conflict with the order-dice ruleset, or explicitly map them as DZW optional rules behind the old ruleset. |
| 171-175 | Swift snapshots | Add order-dice cup, current die, available orders, selected order, pin count, morale quality, retained order, Down/Ambush state, and order-test/FUBAR details to snapshots. |
| 176-180 | Historical board adapter | Update `HistoricalBoardSession` and `HistoricalPlayableBattleView` contracts so callers issue orders rather than global phase commands. Preserve temporary compatibility only with explicit deprecation names. |
| 181-185 | Autoplay and AI hooks | Add order-dice-aware AI runner interfaces: choose unit, choose order, choose target/path, resolve order test, and respond to Ambush/Down opportunities. |
| 186-190 | Book rules docs | Update the DZW book/rules documentation to describe the order-dice turn, order list, pins/morale, movement, shooting, vehicle damage, and close quarters. Remove obsolete phase-flow explanations. |
| 191-195 | Migration docs | Add migration notes for Guderian and Monty, listing renamed APIs, deprecated phase commands, new snapshot fields, and minimum downstream acceptance tests. |
| 196-200 | Acceptance closeout | Require full DZW test pass, deterministic replay signatures, rules-reference conformance tests, docs build/readability pass, and explicit downstream handoff notes. Mark old fixed phase loop as legacy-only. |

## Acceptance Gates

- The default ruleset uses order-dice activation, not side-wide movement/shooting/assault phases.
- Every unit can receive at most one order per turn unless explicitly retained by Ambush/Down rules.
- Pins affect order tests and shooting.
- Morale quality, officer modifiers, FUBAR, Rally, Down, Ambush, and retained orders are represented in engine state and UI snapshots.
- Advance, Run, Fire, Rally, Down, and Ambush have distinct legal-action behavior.
- Vehicle damage and close quarters no longer depend on the old global assault phase.
- DZW book documentation describes the new rules in repository-owned language.
- Guderian and Monty can compile against the new public contracts.

## Downstream Dependency Order

1. DZW cycles 1-200 define and test the rules engine.
2. Guderian consumes DZW's new order-dice contracts for scenario, AI, UI, save, and campaign changes.
3. Monty consumes the same shared contracts through its Guderian/DZW dependency path.
