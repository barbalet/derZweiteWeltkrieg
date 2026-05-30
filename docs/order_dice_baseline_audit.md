# Order-Dice Baseline Audit

Status: cycles 1-5 complete.

Rules reference: Warlord Games Bolt Action reference sheet, `https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This audit records the current DZW rules engine shape before the order-dice migration. The reference sheet establishes the target turn shape: draw an order die, assign one order to one eligible unit, resolve any required order test, execute that unit, and continue until eligible units have acted or retained allowed orders. DZW currently uses a side-wide phase model, so these notes identify the places where the old model is still structurally active.

## Current Turn Model

- `game_view_t` exposes `turn_number`, `active_player`, and one global `phase`.
- `game_advance_phase` advances the entire active side through Movement, Shooting, and Assault, then scores objectives and passes play to the other side.
- `begin_turn` resets movement, shooting, assault, smoke, and fallback state for every unit owned by the active player.
- `finish_turn` clears short-lived crew and pin states for the side that just completed its phase sequence.

This is the main incompatibility with order dice. Under the target model, the game should not ask "which phase is this side in?" before every command. It should ask which side's order die was drawn, which unit is eligible, which order was assigned, and whether that order succeeds.

## Phase-Gated Commands

- `game_move_unit` depends on `unit_can_move_now`, which requires `DZW_PHASE_MOVEMENT`.
- `game_shoot_unit` depends on `unit_can_shoot_now`, which requires `DZW_PHASE_SHOOTING`.
- `game_assault_unit` depends on `unit_can_assault_now`, which requires `DZW_PHASE_ASSAULT`.
- `game_use_smoke` is movement-phase only.
- `game_fire_passenger` is shooting-phase only.
- `game_tank_shock_unit`, embark, disembark, rotate, and deploy functions currently inherit the same turn assumptions through movement and active-player checks.

These APIs will become compatibility wrappers once the central command changes to assigning an order to one unit. They remain useful as execution helpers, but not as public turn-flow authority.

## Movement

The current engine has a general movement allowance model for infantry, vehicles, fast vehicles, difficult terrain, impassable terrain, tank shock, transport sync, and emergency disembarkation. The order-dice migration must split movement into order-specific behavior: Advance permits movement plus later fire, Run permits longer movement and assaults, and Fire/Rally/Down/Ambush normally do not move.

Current movement assumptions to retire or wrap:

- Movement is available because the whole side is in Movement.
- Each unit tracks `moved_this_turn` and `movement_action_used_this_turn`, but not an assigned order.
- Terrain restrictions are not yet represented as the reference-style open, rough, obstacle, building, and road table.
- Vehicle movement is not yet represented through order-specific pivot and reverse budgets.

## Shooting

The shooting system already has useful lower-level machinery: line of sight, range, cover, hull-down checks, vehicle fire arcs, weapon sequences, mixed-profile allocation, ordnance, barrage, flame, pending weapon-destroy choices, and morale checks after shooting casualties.

Current shooting assumptions to retire or wrap:

- Shooting is available because the whole side is in Shooting.
- `init_shooting_phase` prepares every unit's phase strength and casualty counters at once.
- Hit modifiers are represented through the older DZW profile model, not a full order-dice shooting modifier stack.
- Pins are represented as short-lived legacy pinning, not accumulated pin markers.

## Morale And Pins

The current engine has `leadership`, fallback/regroup behavior, `pinned_until_turn`, crew shaken, and crew stunned. It does not yet expose morale quality as Inexperienced, Regular, or Veteran, and it does not yet keep a numeric pin-marker count. The first 20-cycle migration therefore adds public state for morale quality, pin count, order-test result, and retained order state without replacing the old morale implementation yet.

## Assault And Close Quarters

The current close-combat implementation supports assaults, follow-up advance/consolidate, initiative-banded or simultaneous resolution, pending hit allocation, locked assault state, infantry-vs-vehicle interactions, and fallback. It is still entered from the global Assault phase.

Target work for later cycles:

- Treat Run as the normal assault movement order.
- Model target reaction before assault resolution.
- Replace the global assault phase with unit activation and order execution.
- Keep useful casualty allocation and vehicle interaction code as internal resolution helpers.

## Vehicles, Transports, And Wrecks

DZW already models front/side/rear armour, recon, fast vehicles, open-topped vehicles, smoke, immobilization, crew shaken/stunned, weapon destruction, mounted weapon arcs, transport capacity, embarked firing, emergency disembarkation, and wreck displacement. Later cycles should connect this to order-dice vehicle manoeuvre, vehicle damage categories, Down order transitions, accumulated pins, and wreck terrain policies.

## Swift And UI Snapshot Surface

Current Swift snapshots expose phase-shaped booleans:

- `canMoveNow`
- `canShootNow`
- `canAssaultNow`
- `movedThisTurn`
- `shotThisTurn`
- `assaultedThisTurn`

These are useful compatibility fields, but callers also need order-dice state. Cycles 16-20 add `currentOrder`, `actedThisTurn`, `retainedOrder`, `pinCount`, `moraleQuality`, and `lastOrderTestResult` to the public unit snapshot surface.

## Compatibility Gate

The old model remains active after this audit. That is intentional for cycles 1-20. The new diagnostics report each major fixed-phase dependency so later cycles can burn them down deliberately instead of making the legacy flow disappear silently.
