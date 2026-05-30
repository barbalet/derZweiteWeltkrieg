# Order-Dice Migration Notes for Guderian and Monty

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This note records the downstream API expectations for Guderian and Monty after the DZW order-dice conversion. DZW is the rules authority. Downstream modules should consume these contracts rather than recreating a parallel turn loop, morale model, or order list.

## Required Order Surface

Use the shared order vocabulary:

- `HistoricalBoardOrder.fire`
- `HistoricalBoardOrder.advance`
- `HistoricalBoardOrder.run`
- `HistoricalBoardOrder.ambush`
- `HistoricalBoardOrder.rally`
- `HistoricalBoardOrder.down`

Use `HistoricalBoardSession.issueOrder(_:to:)` to assign a specific order to a specific unit. Use `issueOrderToSelectedUnit(_:)` only when the UI selection is already authoritative. The compatibility method `advanceLegacyPhase()` exists only to keep old callers building during migration. New Guderian and Monty work should assign orders directly, then execute movement, shooting, assault, pending-choice, or reaction commands under that order.

## Snapshot Fields Downstream Callers Must Preserve

Every Guderian or Monty board adapter should preserve these unit fields when converting from native engine state to historical board snapshots:

- `currentOrder`
- `availableOrders`
- `orderDiceSummary`
- `pinCount`
- `moraleQuality`
- `retainedOrder`
- `downOrderActive`
- `ambushOrderActive`

Vehicle and close-quarters adapters should also preserve the newer order-dice summary details exposed by native unit snapshots: movement allowance, pivot allowance, shooting modifiers, penetration trace, vehicle damage class, vehicle damage-table result, vehicle-assault trace, and close-quarters reaction state where available. If a downstream screen cannot display all of those fields, it should still keep them in logs, accessibility summaries, or debug panels so tests can inspect them.

## Deprecated Phase Commands

These patterns are legacy-only:

- side-wide Movement, Shooting, and Assault loops that activate every unit in a side before the opponent receives a die,
- UI buttons that advance global phase as the main battle clock,
- AI runners that call movement, shooting, and assault phases without first assigning an order,
- save or replay formats that reconstruct battle time only from phase transitions,
- tests that assert "Shooting phase" as the authority for whether a unit may fire.

Compatibility wrappers can keep old demos playable while Guderian and Monty migrate, but new acceptance should be phrased in order-dice terms: drawn die, selected unit, assigned order, order test, action resolution, retained or spent die, and turn cleanup.

## Guderian Acceptance Tests

Minimum Guderian acceptance should include:

- a native battle can expose `availableOrders` for the active side,
- issuing Fire to a legal unit enables a shooting command,
- issuing Advance to a legal unit enables movement plus later firing context,
- issuing Run to a legal unit enables movement and close-quarters entry but blocks normal fire,
- a pinned unit records order-test details before acting,
- Down and Ambush remain visible after turn cleanup when retained,
- vehicle damage summaries include penetration class and damage-table result,
- infantry-vs-vehicle assault summaries include defensive fire, nerve test, and damage trace where relevant,
- deterministic replay signatures remain stable for a seeded order-dice battle,
- the old fixed phase loop is exercised only through explicitly named legacy compatibility tests.

## Monty Acceptance Tests

Minimum Monty acceptance should include:

- `MontyTestFirstBattleAutoplayView` uses the shared historical board contract,
- autoplay issues an order before executing its movement, shooting, or assault helper,
- autoplay chooses Rally for pinned units when Rally is available,
- autoplay can choose Down when reacting to an Ambush threat,
- debrief completion still requires both sides to act,
- event logs show the selected order and unit before action details,
- the side picker and playable host remain generic historical surfaces rather than game-specific forks,
- Monty fixtures compile without old phase-only tactical assumptions,
- saved and replayed Monty demo runs preserve order summaries,
- downstream UI tests interact with the order buttons instead of only pressing a next-phase control.

## Handoff Rule

When a downstream feature is ambiguous, prefer the DZW order-dice command and snapshot contract over local convenience state. If a caller needs new data, add it to the shared DZW snapshot or command result first, then consume it from Guderian or Monty.
