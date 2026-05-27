# Chapter 4: Units, Profiles, Weapons, And Vehicles

The combat personality of `derZweiteWeltkrieg` lives in `unit_t` and `weapon_profile_t` inside [`../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`](../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c). A unit is not only a name and a position. It has owner, kind, footprint, facing, model count, wounds, weapon skill, ballistic skill, strength, toughness, initiative, attacks, leadership, save, armor values, movement and action flags, transport relationships, morale state, vehicle damage state, and optional profile groups.

That breadth is what lets the game model infantry squads, machine-gun teams, mortar batteries, scout cars, half-tracks, assault guns, tank destroyers, and command groups with one rules engine. The unit type is large because the simulation is stateful. The alternative would be many narrowly specialized unit structs with conversion code between them. This code chooses one complete battle unit representation.

## Weapon Profiles

World War 2 weapons are stored in `wwii_weapon_profiles`. Representative entries include Lee-Enfield rifles, M1 Garands, PPSh-41 SMGs, MG42s, Vickers HMGs, PIATs, bazookas, panzerfausts, 17-pounder anti-tank guns, 75mm tank guns, flamethrowers, mortars, and autocannons. Each profile has range, strength, armor penetration, shots, mode, mount, fire arc, blast diameter, and flags such as flame, ignores cover, ordnance, barrage, and linked.

The profile values are not raw historical statistics. They are gameplay translations. A rifle's range and strength need to work with the engine's movement scale and wound model. A mortar's blast and barrage flags need to produce pinning and line-of-sight behavior. A tank gun's ordnance flag needs to interact with vehicle follow-on fire and damage. Tests in `testRepresentativeWeaponBalanceProfilesAreStable` lock down key values so future edits are deliberate.

The public `weapon_profile_view_t` strips the internal profile into flags that the app and tests can read. The app does not need to know the internal enum for rapid fire or heavy. It needs booleans such as `rapid_fire`, `assault`, `heavy`, `flame`, `ordnance`, and `barrage`. This is another example of the engine making private representations convenient at the boundary.

## Infantry And Mixed Profiles

Basic infantry can use a single profile across all models. Mixed-profile units use `profile_group_t` arrays. A profile group has a name, model count, starting model count, combat values, save, wounds per model, and lead model wound state. This supports squads where leaders, special weapons, or elite troops differ from the rest of the formation.

Mixed-profile allocation is one of the reasons the engine includes pending choices. When hits land on a mixed unit, the defender may need to assign them across eligible groups. The engine records a pending hit allocation with attacker name, source name, target, total hits, remaining hits, and allocation counts. The app displays that pending state and calls `game_choose_pending_hit_allocation` until the engine can finish resolution.

This is a good example of tabletop logic refusing to be a single synchronous function call. Some resolutions need player input partway through. Rather than make Swift own half-resolved damage, the engine pauses with explicit pending state.

## Vehicles And Assault Guns

Vehicles use armor values and special flags. `front_armour`, `side_armour`, and `rear_armour` are visible in snapshots and roster previews. `fast`, `recon`, and `open_topped` affect movement, rough-ground risk, and embarked fire. `smoke_available`, `smoke_active`, `crew_shaken`, `crew_stunned`, and `immobilized` model ongoing vehicle state.

Weapons on vehicles are stored in slots. A slot has a profile plus destroyed and jammed state, fire-angle memory, and mount data. This supports weapon-destroyed results and fire arcs. A vehicle can lose a specific weapon while remaining on the board. When the damage table produces a weapon-destroyed choice, the engine exposes `pending_weapon_destroy_view_t`, and the app asks the player or AI to select which weapon is lost.

Assault guns are represented as `DZW_UNIT_ASSAULT_GUN`, a special kind between infantry and ordinary vehicles. They use vehicle-like armor but can participate in assault behavior that ordinary vehicles cannot. This is a compact way to model close-support armored fighting vehicles without creating a separate combat engine.

## Transports

Transports are ordinary units with `transport_capacity`, `embarked_unit_id`, and passenger back-links through `embarked_in_transport_id`. The engine keeps those relationships synchronized. `game_embark_unit` checks friendly ownership, capacity, phase, range, pinning, falling back, and whether the transport already has passengers. `game_disembark_unit` checks movement distance, crew stun, whether the passenger just embarked, and legal placement around the transport.

Transport destruction is handled in the engine because it has consequences. Passengers may take wounds, attempt emergency disembarkation, become pinned, or be destroyed if no legal position exists. The UI should never guess at those results. It only reloads after the engine decides.

## The Extension Rule

A new unit should begin as a rules unit, not as a display token. Give it weapons, combat values, footprint, movement traits, transport data if needed, and a catalogue entry. Then expose enough through the existing view structs for the app to preview and command it. If the new unit requires a new interrupting decision, model that as pending engine state first. The UI can then become a clean prompt instead of a second rules system.

## The Unit As A Battlefield Contract

The private `unit_t` is one of the densest structures in the project. That density is not accidental. A battlefield unit must remember identity, ownership, physical position, movement state, combat state, morale state, vehicle damage, transport relationships, weapons, and sometimes multiple profile groups. A unit in this engine is not just a counter. It is a contract that says what the rules may ask of this battlefield element.

The core shape includes fields like these:

```c
typedef struct {
    int id;
    const char *name;
    player_t owner;
    unit_kind_t kind;
    float x;
    float y;
    float facing_degrees;
    float footprint_radius;
    int starting_models;
    int models;
    int wounds_per_model;
    int lead_model_wounds;
    int weapon_skill;
    int ballistic_skill;
    int strength;
    int toughness;
    int initiative;
    int attacks;
    int leadership;
    int save;
    int front_armour;
    int side_armour;
    int rear_armour;
    bool fast;
    bool recon;
    bool open_topped;
    bool smoke_available;
    bool smoke_active;
    bool moved_this_turn;
    bool shot_this_turn;
    bool assaulted_this_turn;
    int weapon_count;
    weapon_slot_t weapons[DZW_MAX_WEAPONS];
    bool locked_in_assault;
    bool pinned;
    bool falling_back;
    bool crew_shaken;
    bool crew_stunned;
    bool immobilized;
    int transport_capacity;
    int embarked_unit_id;
    int embarked_in_transport_id;
    int profile_group_count;
    profile_group_t profile_groups[DZW_MAX_PROFILE_GROUPS];
} unit_t;
```

The actual structure has additional fields, but this excerpt shows the intent. A unit stores both profile data and transient state. That lets the engine answer questions locally. Can this unit move? Does it have a weapon left? Is it pinned until its next turn? Is it an open-topped transport? Is it carrying passengers? Is it locked in an assault? Does it use armor facing? The rules do not need to query separate systems for those facts.

This also explains why adding a unit should not start in Swift. A Swift token cannot answer these questions. A catalogue name cannot answer them. Only a real engine unit can.

## Weapon Profiles As Rules Translation

`weapon_profile_t` is the other half of unit behavior. It translates historical equipment into a rules language:

```c
typedef struct {
    const char *name;
    int range;
    int strength;
    int ap;
    int shots;
    weapon_mode_internal_t mode;
    weapon_mount_internal_t mount;
    int fire_arc_degrees;
    int blast_diameter;
    bool flame;
    bool ignores_cover;
    bool ordnance;
    bool barrage;
    bool linked;
} weapon_profile_t;
```

The fields are not arbitrary. `range` decides whether a target can be reached. `strength` and `ap` feed wound and armor saves. `shots` determines volume. `mode` affects movement and assault interactions. `mount` and `fire_arc_degrees` matter for vehicles and passenger fire. `blast_diameter`, `ordnance`, and `barrage` allow mortars and tank guns to behave differently from rifles. `flame` and `ignores_cover` let flamethrowers create a distinct tactical role.

The weapon table shows how historical flavor becomes rules data:

```c
[DZWK_WEAPON_MG42] = {
    .name = "MG42",
    .range = 36,
    .strength = 5,
    .ap = 4,
    .shots = 3,
    .mode = DZW_WEAPON_HEAVY_INTERNAL,
    .mount = DZW_WEAPON_MOUNT_FIXED_INTERNAL,
    .fire_arc_degrees = 360,
},
[DZWK_WEAPON_81MM_MORTAR_BATTERY] = {
    .name = "81mm Mortar Battery",
    .range = 48,
    .strength = 5,
    .ap = 4,
    .shots = 1,
    .mode = DZW_WEAPON_HEAVY_INTERNAL,
    .mount = DZW_WEAPON_MOUNT_FIXED_INTERNAL,
    .fire_arc_degrees = 360,
    .blast_diameter = 5,
    .ordnance = true,
    .barrage = true,
},
[DZWK_WEAPON_FLAMETHROWER] = {
    .name = "Flamethrower",
    .range = 8,
    .strength = 4,
    .ap = 5,
    .shots = 1,
    .mode = DZW_WEAPON_ASSAULT_INTERNAL,
    .mount = DZW_WEAPON_MOUNT_FIXED_INTERNAL,
    .fire_arc_degrees = 360,
    .flame = true,
    .ignores_cover = true,
},
```

The MG42 is long-ranged and high-volume. The mortar has barrage and blast behavior. The flamethrower is short-ranged but ignores cover. These differences are small in data but large in play. They also show why the weapon table is a good place for balance review. Changing `shots` on a heavy weapon affects shooting output. Changing `mode` can affect whether a unit can assault after firing. Changing `barrage` can bypass line-of-sight checks and trigger pinning.

## Modes, Movement, And Assault Eligibility

Weapon mode matters because the game cares how a unit fought earlier in the turn. A unit that stood still to produce rapid-fire or heavy volume can become ineligible for assault. That is why units carry `fired_stationary_rapid_or_heavy` in private state and why `game_assault_unit` checks it. The weapon profile is not just a damage package; it influences phase-to-phase consequences.

This kind of rule gives the game a tabletop rhythm. The player can choose to remain stationary and fire more effectively, or preserve mobility and assault potential. A weapon profile therefore participates in decision-making before dice are rolled.

Future weapons should be reviewed for these cross-phase effects. A new machine gun should probably use heavy behavior. A new SMG should probably support assault behavior. A new anti-tank weapon may need high strength and AP but limited shots. A new mortar should likely use barrage or ordnance flags if it is meant to fire indirectly. The table should describe tactical identity, not merely names.

## Weapon Slots And Vehicle Damage

Vehicles do not only have one abstract attack. They have weapon slots:

```c
typedef struct {
    weapon_profile_t profile;
    bool destroyed;
    bool jammed_in_place;
    bool has_last_fire_angle;
    float last_fire_angle_degrees;
    float jammed_fire_angle_degrees;
} weapon_slot_t;
```

This structure exists because vehicle weapons can be lost or constrained independently. A weapon-destroyed result should not necessarily remove the whole tank. A mounted weapon may have an arc. A vehicle may fire one weapon and then follow on with others. The slot remembers enough to make those outcomes persistent.

The UI exposes pending weapon destruction as a choice rather than assuming which weapon is lost. That is important for multi-weapon vehicles. If a half-track or tank destroyer has several weapons, the choice may matter. The engine owns the valid options, the UI displays them, and the chosen slot is marked destroyed.

This is a pattern to reuse. If a future rule damages radios, tracks, optics, or turrets, it should be represented as persistent engine state if it affects later play. A temporary log line is not enough.

## Infantry Profiles And Specialist Models

Single-profile infantry is simple: every model uses the same combat values. Mixed-profile infantry is more interesting. A squad may contain a leader, gunner, assistant, riflemen, or elite members. The engine represents this with profile groups:

```c
typedef struct {
    const char *name;
    int models;
    int starting_models;
    int weapon_skill;
    int ballistic_skill;
    int strength;
    int toughness;
    int initiative;
    int attacks;
    int leadership;
    int save;
    int wounds_per_model;
    int lead_model_wounds;
} profile_group_t;
```

The group carries enough stats to fight differently. It also carries wound state for multi-wound or partial-wound models. When damage lands, the engine can ask the owning player to assign hits among groups. This is what allows a squad to preserve or lose important specialists according to rules rather than random UI decisions.

Mixed profiles are costly in complexity. They require pending hit allocation, profile-group views, preferred casualty groups, and continuation of interrupted shooting or melee. The benefit is that they let World War 2 squads feel more like composed teams instead of uniform hit boxes.

The rule of thumb is to use mixed profiles when the distinction changes play. A squad leader with different leadership, a special weapon with different shooting, or an elite subgroup may justify it. Cosmetic differences do not.

## Vehicles, Armor, And Facing

Vehicles carry `front_armour`, `side_armour`, and `rear_armour`. This makes them qualitatively different from infantry. Infantry saves are about personal protection and cover. Vehicle survivability depends on armor facing, weapon strength, penetration, and damage results.

The board supports facing because vehicle weapons and armor can care about direction. `facing_degrees` appears in both engine state and UI rendering. The board draws a facing marker for vehicle tokens. Rotation is an action in movement and a free deployment adjustment before battle. This creates a spatial game: where a vehicle points matters.

Armor values are exposed in roster previews and unit inspectors. A player should be able to distinguish a scout car from a tank destroyer, or an assault gun from a soft transport. The UI summary uses compact text like `AV front/side/rear`, which is dense but appropriate for a wargame.

## Transports As Coupled Units

A transport is not a container in Swift. It is a coupled pair of engine units. The transport stores `embarked_unit_id`, and the passenger stores `embarked_in_transport_id`. The engine synchronizes position and facing while embarked. It handles disembark placement. It handles passenger fire. It handles passengers when a transport is destroyed.

This coupling produces important invariants:

- If a passenger is embarked, it should not be directly targetable.
- If a transport moves, the passenger should move with it.
- If a transport is destroyed, passenger outcome must be resolved.
- If a passenger disembarks, both units must clear their links.
- If a passenger fires from a transport, the transport's movement and fire arcs matter.

Those invariants are too important for UI state. They belong in C. The UI can show a transport badge, display passenger names, and offer embark/disembark buttons, but the engine must own the relationship.

## Smoke, Hull Down, And Manual Cover

Not every unit state is a casualty state. Some states represent tactical posture. `manual_in_cover` and `manual_hull_down` allow the player to mark conditions that the board geometry may not fully infer. `smoke_available` and `smoke_active` let vehicles use smoke launchers in Movement, affecting later shooting.

`game_use_smoke` shows the pattern:

```c
bool game_use_smoke(game_t *game, int unit_id) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (!assert_valid_unit_action(game, unit)) {
        return false;
    }
    if (game->phase != DZW_PHASE_MOVEMENT) {
        return fail(game, "Smoke launchers can only be used in the movement phase.");
    }
    if (unit->kind != DZW_UNIT_VEHICLE) {
        return fail(game, "Only vehicles use smoke launchers.");
    }
    if (!unit->smoke_available) {
        return fail(game, "%s has already used its smoke launchers.", unit->name);
    }

    unit->smoke_available = false;
    unit->smoke_active = true;
    unit->smoke_used_this_turn = true;
    dzw_log(game, "%s pops smoke and cannot fire this turn.", unit->name);
    return true;
}
```

This action is small but expressive. It validates phase and unit kind, consumes availability, changes visible state, and logs the consequence. The board can then draw a smoke ring from `smoke_active`.

## Snapshot Summaries

The Swift snapshot layer turns raw unit fields into concise display. `UnitSnapshot.detailSummary` is a good example. It treats assault guns, vehicles, mixed-profile units, and ordinary infantry differently:

```swift
var detailSummary: String {
    if kind == DZW_UNIT_ASSAULT_GUN {
        return "Assault gun WS \(weaponSkill) S \(strength) I \(initiative) A \(attacks) - AV \(frontArmour)/\(sideArmour)/\(rearArmour)"
    }
    if kind == DZW_UNIT_VEHICLE {
        let transportText = transportCapacity > 0 ? " - Transport \(transportCapacity)" : ""
        return "AV \(frontArmour)/\(sideArmour)/\(rearArmour)\(transportText)"
    }
    if mixedProfiles {
        return "Mixed profile unit - \(models) models - \(totalWoundsRemaining) total wounds"
    }
    return "WS \(weaponSkill) BS \(ballisticSkill) S \(strength) T \(toughness) W \(woundsPerModel) I \(initiative) A \(attacks) Ld \(leadership) Sv \(save)+"
}
```

The source file uses presentation separators appropriate to the app, but the logic is the important part. A unit's kind changes how the player should read it. Vehicles care about armor. Infantry cares about profile stats. Mixed units care about total wounds and groups. The snapshot does not invent these facts; it formats them.

## Designing New Profiles

When adding new unit profiles, start with role. Is the unit meant to hold objectives, screen movement, deliver short-range fire, threaten armor, transport infantry, absorb punishment, or provide indirect pressure? The role should determine stats and weapons. Historical names should guide the role, but the final values must work in the game scale.

Then compare against existing units. A new elite infantry section should be measured against commandos, rangers, sappers, or guards. A new armored car should be measured against AB41, Dingo, or Jeep recon entries. A new assault gun should be measured against StuG or Semovente behavior. This keeps point costs and profiles from drifting.

Finally, consider what the UI needs to explain. If the unit introduces no new rules, existing summaries may be enough. If it introduces a new flag or state, the snapshot and UI may need to grow.

## The Chapter's Rule Of Thumb

Units and weapons should be historically evocative, mechanically honest, and visible enough to play. A name creates atmosphere. A profile creates rules. A snapshot creates understanding. All three are needed. A World War 2 unit that looks right but cannot exercise the engine is unfinished. A unit that has rules but no clear preview is frustrating. A unit that is visible but not tested is fragile.

## How Factories Encode Doctrine

The catalogue entries call factory functions, and those factories are where unit doctrine becomes concrete. A factory chooses the unit kind, combat values, primary weapon, optional secondary weapons, armor, transport capacity, and special flags. Even without a separate doctrine engine, those choices make a unit behave like its intended role.

For example, a recon vehicle should probably have `recon = true`, a smaller footprint than a tank, lighter armor, and a weapon suited to scouting harassment rather than tank killing. A half-track should have transport capacity and may be open-topped. An assault gun should have armor and a serious gun, but its kind should communicate that it participates in assault-gun-specific logic rather than ordinary infantry or ordinary vehicle behavior. A mortar battery should have barrage-like weapon flags and likely poor assault relevance.

This is doctrine through data. The engine does not need a high-level "recon doctrine" object if the unit's movement, weapons, and flags already create recon behavior. The app does not need to label every doctrine because the unit summary can show the important traits. The AI can then make simple decisions from visible facts: move toward objectives, prefer targets, use transport or passenger fire when possible.

When adding factories, keep the playable role obvious in the data. If a unit's intended use is invisible from its stats, the player will not discover it naturally.

## Interdependence Of Weapons And Model Counts

A weapon's value depends on who carries it. A high-volume weapon on a one-model team creates a fragile but dangerous piece. The same profile on a full squad may create too much firepower. An anti-tank weapon in a small team creates a specialist. An anti-tank weapon inside a large squad creates resilience and objective presence. The engine's catalogue system allows these combinations, so designers must consider them together.

Model count also affects morale and scoring. Larger infantry units can absorb casualties, contest objectives, and keep firing after losses. Smaller specialist units are easier to remove but cheaper and more focused. Vehicles use a different durability model through armor and damage states. A point value that looks right for the weapon may be wrong once model count and survivability are included.

This is why roster previews include both primary weapon and models. The player needs to see not just "MG42" but also whether it is a team, squad, vehicle weapon, or transport mount. The same name can imply different tactical risk depending on platform.

## Vehicle Platform Questions

When designing or reviewing a vehicle, ask a different set of questions than for infantry:

- Does it use `DZW_UNIT_VEHICLE` or `DZW_UNIT_ASSAULT_GUN`?
- Are front, side, and rear armor values meaningful relative to existing weapons?
- Is it fast, recon, open-topped, or a transport?
- Does it have smoke?
- How many weapons does it mount?
- Do those weapons have appropriate arcs?
- Can it carry passengers, and if so how many?
- Should passenger fire be possible or limited?
- What happens when it is immobilized or crew stunned?

Those questions are gameplay questions. A vehicle name alone does not answer them. The engine values answer them.

The current system is already prepared for several vehicle distinctions. Fast vehicles move farther. Recon vehicles interact differently with rough ground. Open-topped transports allow more passenger fire. Assault guns enter special close-combat logic. Weapon slots can be destroyed. Smoke can be spent. This gives future armor additions room to be distinctive without changing the entire engine.

## Infantry Platform Questions

Infantry design has its own review checklist:

- Is the unit single-profile or mixed-profile?
- How many models does it have?
- Does it have one wound per model or multi-wound specialists?
- What is its primary weapon?
- Does the weapon mode support its intended role?
- Are leadership and save appropriate?
- Should it be able to embark?
- Does it need a preferred casualty group?
- Does it create a new pending allocation situation?

Infantry are the core objective holders. They must remain readable. Too many special cases in ordinary infantry can make the UI feel opaque. Mixed profiles should be used when they add meaningful decisions, such as protecting a gunner or leader. Ordinary rifle squads can remain simpler.

## Code Review Examples

A useful review comment for a new weapon might say: "This SMG uses heavy mode, which will prevent intended assault behavior after firing. Should it be assault mode like the PPSh-41 or MP 40?" That comment connects data to play.

A useful review comment for a new vehicle might say: "This transport has capacity but no open-topped flag and no passenger-fire test. Is passenger fire intentionally limited?" That comment connects platform data to UI and test behavior.

A useful review comment for a mixed squad might say: "This profile group has different stats, but no test exercises hit allocation against it. Add a shooting or melee case that forces group choice." That comment connects unit data to pending resolution.

These examples are mundane, but they are the way a rules codebase stays coherent. Review should not only ask whether code compiles. It should ask whether the data tells the truth about play.

## Tests For Unit And Weapon Changes

The existing tests already lock representative weapon profiles. That pattern should continue. A new weapon category should have at least one test that verifies its important flags. A new vehicle should have tests around armor preview and any special behavior. A new transport should have embark/disembark or passenger-fire coverage if its behavior differs from existing transports. A new mixed-profile unit should have allocation coverage.

Tests do not need to exhaust every dice branch. They should establish that the rule is connected. For example, a smoke test can verify smoke availability becomes active and the unit cannot use smoke twice. A transport test can verify passenger links before and after disembarkation. A weapon-destroyed test can verify a pending choice appears for a multi-weapon vehicle.

The key is to test from the public API. Create a game or skirmish, inspect views, issue commands, and inspect views again. That proves the unit or weapon works through the same path the app uses.

## Final Maintainer Note

Units and weapons are the part of the game most likely to attract enthusiastic additions. That is good. The World War 2 setting is rich with equipment and formations. But every addition should pay rent in gameplay. It should create a distinct role, exercise existing rules, or support a scenario. If it only adds a name, it belongs in research notes until it has a playable reason to exist.

That standard protects both history and play. Historical equipment deserves better than being reduced to decorative labels, and players deserve units whose differences matter on the board. The engine already has enough hooks for many distinct battlefield roles. Use those hooks first, extend them when a role truly needs more, and keep the UI honest about what the unit can actually do during a battle turn, setup draft, saved replay, AI activation, or deployment step.

That is how equipment becomes game design instead of background flavor or empty inventory text in actual play sessions together.
