# derZweiteWeltkrieg World War II Development Roadmap

This roadmap defines the playable `derZweiteWeltkrieg` demo: an Allies-vs-Axis World War II tabletop skirmish where the player can build or load forces, deploy, move, shoot, resolve vehicle damage, use artillery and transports, fight over objectives, and finish a complete match.

The demo is built around these game systems: turn phases, movement, shooting, blast/flame/barrage handling, vehicles, transports, objectives, morale, assault resolution, rosters, force presets, AI draft flow, and a SwiftUI interface backed by a C rules engine.

## Source Anchors

Wikipedia is the initial open reference shelf for naming, equipment coverage, and demo-era roster choices:

- Infantry weapons and national small-arms lists: [List of World War II infantry weapons](https://en.wikipedia.org/wiki/List_of_World_War_II_infantry_weapons)
- British army organization, armor doctrine, artillery, and equipment comparison: [British Army during the Second World War](https://en.wikipedia.org/wiki/British_Army_during_the_Second_World_War)
- British equipment index: [List of British military equipment of World War II](https://en.wikipedia.org/wiki/List_of_British_military_equipment_of_World_War_II)
- U.S. equipment, armor, artillery, and small arms: [List of equipment of the United States Army during World War II](https://en.wikipedia.org/wiki/List_of_equipment_of_the_United_States_Army_during_World_War_II)
- Australian equipment, weapons, vehicles, and artillery: [List of Australian military equipment of World War II](https://en.wikipedia.org/wiki/List_of_Australian_military_equipment_of_World_War_II)
- Soviet equipment, weapons, armor, artillery, and production context: [List of Soviet Union military equipment of World War II](https://en.wikipedia.org/wiki/List_of_Soviet_Union_military_equipment_of_World_War_II)
- German equipment, tanks, self-propelled guns, artillery, and support weapons: [List of German military equipment of World War II](https://en.wikipedia.org/wiki/List_of_German_military_equipment_of_World_War_II)
- Italian army structure and troop types: [Royal Italian Army during World War II](https://en.wikipedia.org/wiki/Royal_Italian_Army_during_World_War_II)
- Italian equipment, small arms, tanks, and self-propelled guns: [List of Italian Army equipment in World War II](https://en.wikipedia.org/wiki/List_of_Italian_Army_equipment_in_World_War_II)
- Cross-faction armor context: [Tanks in World War II](https://en.wikipedia.org/wiki/Tanks_in_World_War_II)
- Battlefield and objective context for the active demo: [Operation Overlord](https://en.wikipedia.org/wiki/Battle_of_Normandy), [Bocage](https://en.wikipedia.org/wiki/Bocage), [Operation Cobra](https://en.wikipedia.org/wiki/Operation_Cobra), [Military logistics](https://en.wikipedia.org/wiki/Military_logistics), [Land mine](https://en.wikipedia.org/wiki/Minefield), and [Artillery observer](https://en.wikipedia.org/wiki/Artillery_observer)

## Faction Research Baseline

| Side | Nation | Troop Families | Infantry Weapons | Armor And Vehicles | Artillery And Support |
| --- | --- | --- | --- | --- | --- |
| Allies | British | Rifle sections, Commandos, airborne troops, Royal Engineers, Royal Artillery crews, armored regiments | Lee-Enfield rifles, Sten SMG, Bren LMG, Vickers HMG, PIAT, Boys anti-tank rifle, Mills bombs | Universal Carrier, Matilda II, Valentine, Churchill, Cromwell, Sherman, Sherman Firefly | 2-inch and 3-inch mortars, QF 25-pounder, 6-pounder and 17-pounder anti-tank guns, Bofors 40mm, 4.5-inch and 5.5-inch guns |
| Allies | American | Rifle squads, Rangers, airborne, combat engineers, armored infantry, tank destroyer crews | M1 Garand, M1 Carbine, Thompson, M3 SMG, BAR, Browning M1919, M2 Browning, bazooka | Jeep, M3 half-track, M3/M5 Stuart, M3 Lee/Grant, M4 Sherman, M10/M18/M36 tank destroyers, M7 Priest, M26 Pershing late-war | 60mm and 81mm mortars, M101 105mm howitzer, M114 155mm howitzer, M2 Long Tom, T34 Calliope |
| Allies | Australian | AIF rifle sections, militia, commandos, jungle warfare troops, armored and carrier crews | Lee-Enfield rifles, Owen gun, Austen, Bren, Vickers, Boys anti-tank rifle, PIAT | Universal Carrier, Dingo scout car, Matilda II, M3 Stuart, M3 Grant, AC1 cruiser tank as domestic production reference | 2-inch, 3-inch, and 4.2-inch mortars, QF 25-pounder, Short 25-pounder, 2-pounder, 6-pounder, 17-pounder, Bofors 40mm |
| Allies | Soviet | Rifle squads, SMG squads, Guards units, sappers, tank riders, anti-tank rifle teams | Mosin-Nagant, SVT-40, PPSh-41, PPS-43, DP-27, Maxim M1910, DShK, PTRD-41, PTRS-41, RGD/F1 grenades | T-26, T-70, T-34/76, T-34/85, KV-1, IS-2, SU-76, SU-85, SU-100, ISU-152 | 50/82/120mm mortars, 45mm anti-tank gun, ZiS-3 76mm, M-30 122mm, ML-20 152mm, BM-13 Katyusha |
| Axis | German | Grenadiers, Panzergrenadiers, pioneers, recon troops, armor crews, artillery crews | Karabiner 98k, MP 40, MG 34, MG 42, Gewehr 43, StG 44 late-war, Panzerfaust, Panzerschreck, Stielhandgranate | Sd.Kfz. 251 half-track, Panzer III, Panzer IV, Panther, Tiger I, Tiger II, StuG III, Marder, Hetzer, Jagdpanzer IV | 5cm/8cm/12cm mortars, 7.5cm PaK 40, 8.8cm FlaK, 10.5cm leFH 18, 15cm sFH 18, Nebelwerfer |
| Axis | Italian | Rifle infantry, Bersaglieri, Alpini, Blackshirt-attached infantry, colonial troops, tankette and armored units | Carcano rifles and carbines, Beretta Model 38, Breda M1930, Breda M1937, Brixia 45mm mortar, Solothurn anti-tank rifle | L3/35, L6/40, M11/39, M13/40, M14/41, M15/42, P40 late-war, Semovente 47/32, Semovente 75/18, Semovente 75/34, Semovente 90/53 | 47/32 anti-tank gun, 65/17 infantry gun, 75/27, 75/18, 100/17, 149/40, 90/53 AA/AT gun |

## Development Cycle 0: Research Lock And Demo Scope

Goal: freeze the first playable World War II scope before broad implementation work.

Deliverables:

- Record the research baseline above near the army data tables and source ledgers.
- Choose the first demo matchup: `British Rifle Platoon` versus `German Grenadier Platoon`.
- Define secondary demo presets for British, American, Australian, Soviet, German, and Italian forces.
- Document the equipment and battlefield source anchors in `docs/wwii_demo_scope.md`.

Acceptance:

- The demo slice has infantry, support weapons, anti-tank weapons, a transport or carrier, armor, indirect fire, template weapons, mixed-profile allocation, objectives, morale, assault, and victory scoring.
- Every supported nation has two named presets.

Status: Completed. The scoped demo uses Allied and Axis forces with historically grounded troop, weapon, armor, artillery, and battlefield references.

## Development Cycle 1: Product Identity

Goal: the repository launches and presents as `derZweiteWeltkrieg`.

Deliverables:

- Use `DerZweiteWeltkrieg*` naming for Swift package, targets, Xcode projects, schemes, bundle identifiers, app title, command-line banner, README, and tests.
- Keep the C interop prefix stable where Swift bindings rely on it.
- Ensure the app and command-line targets both expose World War II naming.

Acceptance:

- `swift build` succeeds.
- App and CLI launch with `derZweiteWeltkrieg` branding.

Status: Completed. The package, app, command-line target, tests, and documentation use `derZweiteWeltkrieg` naming.

## Development Cycle 2: Allegiance Model And Army Catalog

Goal: support Allies and Axis nation selection.

Deliverables:

- Model the two sides as `Allies` and `Axis`.
- Support British, American, Australian, Soviet, German, and Italian armies.
- Keep active C army values available to Swift as `DZW_ARMY_BRITISH`, `DZW_ARMY_AMERICAN`, `DZW_ARMY_AUSTRALIAN`, `DZW_ARMY_SOVIET`, `DZW_ARMY_GERMAN`, and `DZW_ARMY_ITALIAN`.
- Let the setup flow draft an opposing-side computer opponent by default.
- Add force presets such as `British Rifle Platoon`, `US Armored Infantry`, `Soviet Guards Tank Riders`, `German Panzergrenadier Kampfgruppe`, and `Italian Bersaglieri Column`.

Acceptance:

- Players can choose any Allied nation against any Axis nation.
- The AI drafts an opposing-side force unless a debug path explicitly creates a mirror match.

Status: Completed. Public setup exposes all six nations grouped by side, with opposing-side drafting enabled by default.

## Development Cycle 3: Weapon Taxonomy

Goal: create a World War II weapon table for the firing, AP, blast, flame, barrage, heavy, pistol, rapid-fire, and assault mechanics.

Deliverables:

- Centralize weapon profiles in `wwii_weapon_profiles`.
- Cover rifles, SMGs, pistols, LMG/MMG/HMG weapons, portable anti-tank weapons, tank guns, mortars, artillery, and flamethrowers.
- Use representative national weapons from the research baseline.
- Add deterministic tests for representative profile values.

Acceptance:

- Every weapon shown in the app exists in the source baseline or a documented Wikipedia-linked equipment page.
- Tests for range, AP, blast, flame, barrage, vehicle penetration, mixed-profile allocation, and weapon-destroyed choices pass with World War II fixtures.

Status: Completed. Visible weapon strings flow through a centralized table and are covered by deterministic snapshot tests.

## Development Cycle 4: Unit Profiles And Force Presets

Goal: provide playable World War II armies for each supported nation.

Deliverables:

- Add national infantry profile factories:
  - British Rifle Section, Bren Team, PIAT Team, Commando Section.
  - US Rifle Squad, Ranger Squad, engineer teams, and support weapons.
  - Australian Rifle Section, PIAT Team, Vickers MG Team, and jungle patrol support.
  - Soviet Rifle Squad, SMG Squad, Guards SMG Squad, Sapper Squad, and scout troops.
  - German Grenadier Squad, Volksgrenadier Squad, MG42 Team, Pioneer Squad, and recon troops.
  - Italian Rifle Squad, Bersaglieri Squad, AB41 armored-car support, and Semovente support.
- Keep mixed-profile groups for squads with leaders, attached machine guns, or support teams.
- Surface historical formation language in force summaries and roster previews.

Acceptance:

- All six nations have at least two force presets.
- At least one preset per side exercises mixed-profile casualty allocation.

Status: Completed. Public roster entries, force previews, presets, custom army lists, and transport embarkation hooks expose national World War II unit names.

## Development Cycle 5: Armor, Transports, And Artillery

Goal: support World War II armor, transports, scout cars, assault guns, tank destroyers, and artillery batteries.

Deliverables:

- Add vehicle families by nation:
  - British: Universal Carrier, Sherman Firefly, Daimler Dingo, 15-cwt truck.
  - American: Jeep recon patrol, M3 half-track, M10 tank destroyer.
  - Australian: Australian Carrier, Matilda II, Dingo scout car.
  - Soviet: infantry support teams now, with SU/T-34 family expansion as future data growth.
  - German: Sd.Kfz. 251, StuG III, MG42 support.
  - Italian: AB41 Armored Car, Semovente 75/18, Italian Truck.
- Use grounded recon and assault-gun terminology in public state.
- Keep mounted fire arcs for hull, turret, pintle, casemate, and fixed weapons.
- Cover transport flow with M3 half-track, Universal Carrier, Sd.Kfz. 251, trucks, and carrier-style vehicles.

Acceptance:

- Vehicle damage, weapon-destroyed choices, smoke, hull-down, fire arcs, transport destruction, disembarkation, and embarked firing all have World War II tests.

Status: Completed. Vehicle fixtures, mounted weapons, board badges, CLI output, snapshots, and tests read as World War II armor, transports, scout cars, assault guns, tank destroyers, and mortar batteries.

## Development Cycle 6: Battlefield, Mission, And UI Language

Goal: make the board, objectives, logs, setup screens, guides, and inspector language read as a World War II battle.

Deliverables:

- Use the mission `Bocage Breakout`.
- Use period battlefield features: ruined farmhouse, bocage ridge, shell-hole field, minefield, ammunition cache, observation post, road junction, and fuel dump.
- Keep setup, guide, sidebar, error, and log strings focused on nations, platoons, squads, tanks, guns, crews, and objectives.

Acceptance:

- A complete playthrough log contains World War II terms.
- Mission scoring and victory detection work.

Status: Completed. The active scenario is `Bocage Breakout`, with terrain and objectives documented in `docs/wwii_battlefield_profiles.md`.

## Development Cycle 7: Tests, Balancing, And Data Boundaries

Goal: keep the playable demo stable and easier to expand.

Deliverables:

- Add smoke tests for every nation and force preset.
- Add balance tests around representative weapons: rifle fire, SMG assault, MG fire, flamethrowers, mortar blast, bazooka/PIAT/Panzerfaust, tank gun, and artillery barrage.
- Expose read-only weapon profile snapshots for deterministic tests.
- Add source notes to catalog rows so tuning can trace back to the research ledgers.
- Prepare future `weapon_profiles.c`, `unit_profiles.c`, and `army_lists/*.c` data splits.

Acceptance:

- `swift test` passes.
- Coverage includes roster creation, preset reset, skirmish draft, objective scoring, transport flow, vehicle damage, mixed allocation, and artillery.
- Data boundaries are ready for adding more World War II units without editing UI code.

Status: Completed. Tests smoke every nation and force preset, catalog previews require source notes, and representative weapon profiles are available through a C snapshot API.

## Development Cycle 8: Playable Demo Polish

Goal: ship a self-contained World War II demo.

Deliverables:

- Default demo: British force versus German force on a World War II objective map.
- Secondary presets: American, Australian, Soviet, and Italian forces playable through setup.
- Command-line demo drafts one Allied and one Axis force and prints a World War II battle report.
- README becomes a concise `derZweiteWeltkrieg` run guide.
- Add a final demo checklist.

Acceptance:

- A new user can run `swift run` or open the Xcode scheme and immediately play a World War II battle.
- App setup supports all six nations and shows Allies/Axis classification.
- Demo battle can be completed from deployment to victory.

Status: Completed. The app opens with a deployable British force, drafts an Axis opponent immediately, keeps all six nations playable from setup, uses a 1944 seed baseline, and the command-line target prints a World War II battle report with Allies/Axis labels.

## Playable Demo Definition Of Done

The demo is complete when:

- The game name, package, app title, CLI title, docs, and tests all say `derZweiteWeltkrieg`.
- The playable sides are Allies and Axis nations: British, American, Australian, Soviet, German, and Italian.
- Every army has historically grounded troops, armor, artillery, support weapons, force summaries, roster previews, and at least two presets.
- The player can build or load a force, deploy, move, shoot, use artillery, damage vehicles, embark/disembark, fight for objectives, and finish a match.
- `swift build` and `swift test` pass.
