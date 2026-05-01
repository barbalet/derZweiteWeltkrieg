# Army Integration Notes

The active army selection model is World War II allegiance plus nation:

- Allies: British, American, Australian, Soviet
- Axis: German, Italian

## Current State

- The SwiftUI app lists the six supported nations from `ArmyReferenceCatalog`.
- Each nation carries an `Allies` or `Axis` allegiance label.
- The skirmish setup lets the human player choose any nation.
- The computer opponent drafts from the opposing allegiance by default.
- The C engine owns roster creation, force presets, roster previews, point totals, and starting transport posture.
- Catalog entries and generated rosters expose national troop, support, transport, and armor labels.
- Vehicle rules use World War II armor, transport, scout-car, assault-gun, tank-destroyer, and artillery language.
- The active scenario is `Bocage Breakout`, with World War II objective, terrain, setup, sidebar, and operation-log language.
- Catalog rows carry source notes linked to the Wikipedia-backed research docs.
- The setup screen opens with a ready British draft and a live Axis opponent plan.

## Playable Nation Presets

- British Rifle Platoon
- British Armoured Troop
- US Armored Infantry
- US Ranger Assault
- Australian Jungle Patrol
- Australian Matilda Column
- Soviet Rifle Company
- Soviet Guards Tank Riders
- German Grenadier Platoon
- German Panzergrenadier Kampfgruppe
- Italian Bersaglieri Column
- Italian Alpini Detachment

## Engine Boundary

Swift owns selection state and presentation. The C engine owns valid roster composition, force previews, point totals, source notes, starting transport deployment, battle state, and pending rules decisions such as mixed-profile hit allocation or vehicle weapon-destroyed choices.

The current playable slice uses compact hand-authored roster factories. The next useful growth step is moving those factories into dedicated data tables such as `weapon_profiles.c`, `unit_profiles.c`, and `army_lists/*.c`.
