# Order-Dice Cycle 200 Acceptance Closeout

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This closeout defines the acceptance gate for the 200-cycle order-dice conversion. It is not a claim that every future army list, scenario, AI tactic, or UI polish item is finished. It is the point where the original fixed-phase conversion plan has a playable, testable order-first rules contract across engine, Swift snapshots, historical adapters, autoplay, and downstream handoff docs.

## Required Test Pass

The full local gate is:

```sh
swift test
```

Targeted development gates may use filters while working, but cycle-200 closeout requires the whole suite before release handoff. Failures should be classified by surface:

- engine rules failure,
- Swift snapshot or adapter failure,
- Guderian downstream contract failure,
- Monty downstream contract failure,
- documentation or migration mismatch,
- UI automation instability.

## Rules-Reference Conformance

The rules conformance suite should continue to assert these reference-shaped behaviors:

- order dice are drawn from a deterministic seeded cup,
- the drawn die constrains the acting side,
- the public order list is Fire, Advance, Run, Ambush, Rally, and Down,
- pins can require order tests,
- FUBAR, panic, and friendly-fire outcomes are visible,
- Down and Ambush can become retained states,
- Advance and Run use different movement allowances,
- Fire and Advance are shooting-capable orders,
- Run is the close-quarters entry order,
- vehicle damage uses inspectable penetration and damage-table results,
- knocked-out armoured vehicles can remain as movement-blocking wrecks,
- close quarters destroy the loser or continue on a draw,
- infantry assaults against vehicles expose defensive fire, nerve checks, and damage traces.

## Deterministic Replay Signatures

Replay signatures must include order-dice state, not only old action names. A stable signature should be sensitive to:

- cup seed and draw order,
- current die owner,
- assigned order,
- acting unit id,
- retained Ambush or Down orders,
- pin count and order-test result,
- FUBAR branch,
- vehicle damage result,
- pending-choice resolution,
- turn-end cleanup.

Equivalent seeded activation sequences should replay to the same signature. Different order choices should produce different signatures even when the same units eventually move or shoot.

## Documentation Acceptance

Documentation is considered closeout-ready when:

- `book/chapter_06.md` describes the order-dice turn engine as the rules authority,
- `book/chapter_07.md` describes combat timing through orders,
- `docs/order_dice_rules_model.md` records the cycle-200 boundary,
- `docs/order_dice_migration_guderian_monty.md` lists downstream API migration expectations,
- this closeout file lists the test, replay, rules-reference, and handoff gates,
- old phase-loop language is framed as legacy compatibility only.

## Downstream Handoff Notes

Guderian and Monty should treat DZW as the shared rules provider. Their next implementation work should start from these checks:

- compile against `HistoricalBoardOrder`,
- assign orders with `HistoricalBoardSession.issueOrder(_:to:)`,
- preserve order fields in snapshots,
- route AI and autoplay through order decisions,
- assert replay signatures with order state included,
- keep old phase advancement only behind legacy compatibility names.

Any downstream blocker should be filed against the missing DZW command, snapshot field, or documented rule branch rather than solved through an isolated local fork.
