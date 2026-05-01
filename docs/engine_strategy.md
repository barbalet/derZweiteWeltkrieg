# derZweiteWeltkrieg Engine Strategy

This project splits the rulebook into two layers:

- `Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`: the authoritative rules engine in C.
- `Sources/DerZweiteWeltkriegApp/*.swift`: a macOS SwiftUI shell that renders the board, collects player intent, and forwards every state change into the C engine.

That split matters because the rulebook is broad. The C layer should own every measurable rule, while the SwiftUI layer should stay limited to:

- board presentation
- selection and drag interactions
- turn/phase controls
- combat commands
- action log display

## Current Playable Scope

The current implementation covers the rules-book spine needed for a tabletop demo:

- turn sequence
- infantry movement with coherency-scale abstraction at the unit token level
- difficult and impassable terrain handling
- vehicle movement, fast vehicles, recon vehicles, smoke, hull-down checks, damage tables, wreck displacement on relevant destroy results, and tank shock
- slewed wrecks now automatically displace overlapping nearby units in the current token model, matching the rulebook note that models in the way leap aside
- multi-weapon vehicle `Weapon Destroyed` results now pause for an explicit attacker choice that the SwiftUI sidebar resolves against engine-owned state
- immobilized vehicles can no longer pivot in place after damage results
- second immobilized results can jam turret and sponson weapons into their last-fired direction within the current arc approximation
- crew-stunned assault guns now skip new close-combat launches on their following turn
- crew-stunned recon vehicles now auto-coast on their following movement phase while keeping facing fixed, using a random-heading approximation of the scatter-die direction
- crew-shaken and crew-stunned damage results now stay live through the affected vehicle's next turn instead of clearing at the end of the current one
- vehicle line of fire with token-level mounted fire arcs and blocking by other vehicles
- transport embark/disembark, passenger damage on destroyed vehicles, and embarked firing with automatic placement across the full 2" disembark band in the current token model
- shooting with ballistic skill, rapid fire, pistols, heavy weapons, AP, armour saves, instant death, morale from 25% shooting casualties, pinning, and mixed-profile hit allocation
- uniform multi-wound infantry casualty tracking plus mixed-profile casualty pools in the shooting path, including a player-directed preferred casualty group control and a pending manual hit-allocation flow for infantry, passenger, and vehicle fire
- flame templates, blast, ordnance, and barrage shooting at the unit-token level
- assaults with charge distance, cover-first strikes, initiative ordering, infantry attacks on vehicles, assault-gun close combat, combat result, morale, fall back, advance, and consolidation, including pending manual mixed-profile allocation for non-simultaneous infantry initiative steps and cover-first infantry assaults
- regrouping for falling-back units

## How To Reach Broader Rulebook Coverage

The PDF contents split naturally into implementation tiers.

### Tier 1: Core Rules Completion

Extend `der_Zweite_Weltkrieg.c` with:

- fully manual casualty allocation beyond the current mixed-profile shooting and infantry melee pause flows, especially for finer engagement matching and any remaining non-infantry edge cases beyond the current token-level frontage/support cap, legal charge-lane checks, and stop-short follow-up handling
- transport damage outcomes beyond the current 4+ passenger-hit, armour-save, pinned-emergency-disembark abstraction
- assault-gun edge cases such as refined damage/morale interactions and more exact facing/contact behavior beyond the current crew-stunned assault lockout and continuing-combat skip handling
- model-level template placement and casualty selection beyond the current token-level flame and blast approximations
- model-specific weapon mount geometry beyond the current profile-level fire arc approximation
- close-combat edge cases for independent characters, challenge-style casualty assignment, and attacker-vs-defender matching that goes beyond the current unit-token engagement abstraction

These belong in the existing engine file first, then can be refactored into `combat.c`, `vehicles.c`, and `movement.c` once the rules stabilize.

### Tier 2: Army Data Separation

Move unit and weapon definitions out of hard-coded setup into data tables:

- `unit_profiles.c` for shared statlines
- `weapon_profiles.c` for rules-table weapons
- `army_lists/*.c` or generated headers for WWII nation rosters

The rulebook’s army lists and wargear should be data-driven, not encoded as UI logic.

### Tier 3: Scenario And Campaign Systems

Add separate modules for:

- deployment maps
- mission objectives
- victory conditions
- experience and campaign progression

These are orchestration systems layered on top of the same combat engine. They should mutate scenario state, not rewrite basic movement or damage rules.

The current demo now follows that direction for a first scenario slice: `Bocage Breakout` objectives, terrain features, control checks, VP scoring, and win detection live in the C engine and are exposed to the SwiftUI layer as read-only snapshots. The battlefield source notes live in `docs/wwii_battlefield_profiles.md`.

The macOS app exposes the supported World War II nation catalog as player-selectable matchup choices, and those choices feed curated force presets in the C engine. The sidebar reads per-nation force options plus roster previews back from the engine, including starting transport deployment notes and pending `Weapon Destroyed` decisions, so Swift does not duplicate unit composition or vehicle-damage state. The current rosters are hand-authored sample presets; source notes on catalog rows and a read-only weapon profile snapshot API give tests and future data files stable table boundaries before the factories are split into separate modules.

### Tier 4: Physical Fidelity

If the goal shifts from unit-token play to true model-level simulation, change the engine state model before adding more rules:

- store per-model positions inside units
- represent base sizes explicitly
- resolve coherency, casualty removal, and engagement from actual model locations
- promote templates and line-of-sight checks from approximations to model geometry

The SwiftUI board is already compatible with that direction because it consumes snapshots instead of owning the rule state.

## Practical Development Order

1. Finish all core rules in C.
2. Keep SwiftUI as a thin client.
3. Add deterministic tests for every table and phase transition.
4. Move army data into tables.
5. Add scenarios and campaign logic after the core is stable.

That order keeps rules authority in the C engine and prevents duplicated rules logic in the UI.
