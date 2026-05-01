# World War II Demo Scope

This document freezes the first playable `derZweiteWeltkrieg` demo scope.

## Research Baseline

The playable demo uses representative equipment from Wikipedia's World War II equipment and infantry weapon lists:

- British, U.S., Australian, Soviet, German, and Italian small arms from [List of World War II infantry weapons](https://en.wikipedia.org/wiki/List_of_World_War_II_infantry_weapons)
- British organization, artillery, and armor context from [British Army during the Second World War](https://en.wikipedia.org/wiki/British_Army_during_the_Second_World_War)
- U.S. weapons, tanks, and artillery from [List of equipment of the United States Army during World War II](https://en.wikipedia.org/wiki/List_of_equipment_of_the_United_States_Army_during_World_War_II)
- Australian weapons, tanks, and artillery from [List of Australian military equipment of World War II](https://en.wikipedia.org/wiki/List_of_Australian_military_equipment_of_World_War_II)
- Soviet weapons, armor, artillery, and production context from [List of Soviet Union military equipment of World War II](https://en.wikipedia.org/wiki/List_of_Soviet_Union_military_equipment_of_World_War_II)
- German weapons, armor, self-propelled guns, and artillery from [List of German military equipment of World War II](https://en.wikipedia.org/wiki/List_of_German_military_equipment_of_World_War_II)
- Italian organization and equipment from [Royal Italian Army during World War II](https://en.wikipedia.org/wiki/Royal_Italian_Army_during_World_War_II) and [List of Italian Army equipment in World War II](https://en.wikipedia.org/wiki/List_of_Italian_Army_equipment_in_World_War_II)

## First Playable Demo Slice

Default matchup:

- Allies: `British Rifle Platoon`
- Axis: `German Grenadier Platoon`

| Gameplay Need | Allied Demo Unit | Axis Demo Unit |
| --- | --- | --- |
| Rifle infantry | British Rifle Section with Lee-Enfield rifles | German Grenadier Squad with Karabiner 98k rifles |
| Automatic fire | Bren Team or Vickers Team | MG42 Team |
| Portable anti-tank | PIAT Team | Panzerfaust or Panzerschreck Team |
| Transport/carrier | Universal Carrier | Sd.Kfz. 251 half-track |
| Tank or assault gun | Sherman or Churchill | Panzer IV or StuG III |
| Indirect/blast fire | 3-inch mortar or QF 25-pounder | 8cm mortar or 10.5cm leFH 18 |
| Flame/template coverage | Royal Engineer Flamethrower Team | German Pioneer Flamethrower Team |
| Mixed-profile allocation | Rifle Section with section leader and Bren gunner | Grenadier Squad with NCO and MG42 gunner |

This slice covers movement, shooting, AP, blast, barrage, flame, vehicle damage, transport flow, mounted fire arcs, mixed-profile allocation, objectives, morale, assault, and victory scoring.

## Nation Preset Plan

Each nation gets two initial force presets. These are demo-sized formations, not full historical orders of battle.

| Side | Nation | Preset 0 | Preset 1 |
| --- | --- | --- | --- |
| Allies | British | British Rifle Platoon | British Armoured Troop |
| Allies | American | US Armored Infantry | US Ranger Assault |
| Allies | Australian | Australian Jungle Patrol | Australian Matilda Column |
| Allies | Soviet | Soviet Rifle Company | Soviet Guards Tank Riders |
| Axis | German | German Grenadier Platoon | German Panzergrenadier Kampfgruppe |
| Axis | Italian | Italian Bersaglieri Column | Italian Alpini Detachment |

## Preset Content Targets

- `British Rifle Platoon`: Rifle Section, Bren Team, PIAT Team, Universal Carrier, Sherman or Churchill, 3-inch mortar.
- `British Armoured Troop`: Sherman Firefly, Cromwell or Churchill, Rifle Section, Royal Engineer Flamethrower Team, QF 25-pounder.
- `US Armored Infantry`: Rifle Squad, BAR Team, Bazooka Team, M3 half-track, M4 Sherman, M7 Priest.
- `US Ranger Assault`: Ranger Squad, Thompson/M3 SMG Team, Bazooka Team, M10 tank destroyer, 81mm mortar.
- `Australian Jungle Patrol`: Rifle Section, Owen SMG Section, Bren Team, PIAT Team, Universal Carrier, Short 25-pounder.
- `Australian Matilda Column`: Matilda II, M3 Grant, Rifle Section, Vickers Team, 3-inch mortar.
- `Soviet Rifle Company`: Rifle Squad, PPSh SMG Squad, DP-27 Team, PTRD/PTRS Team, T-34/76, 82mm mortar.
- `Soviet Guards Tank Riders`: Guards SMG Squad, Sapper Team, T-34/85, SU-76 or SU-85, BM-13 Katyusha.
- `German Grenadier Platoon`: Grenadier Squad, MG42 Team, Panzerfaust Team, Sd.Kfz. 251, Panzer IV, 8cm mortar.
- `German Panzergrenadier Kampfgruppe`: Panzergrenadier Squad, Pioneer Flamethrower Team, Panzerschreck Team, StuG III, Panther, Nebelwerfer.
- `Italian Bersaglieri Column`: Bersaglieri Squad, Breda MG Team, Solothurn Team, M13/40 or M14/41, Semovente 75/18, 81mm mortar.
- `Italian Alpini Detachment`: Alpini Squad, Rifle Squad, Brixia mortar, 47/32 anti-tank gun, Semovente 90/53 or 75/34.

## Acceptance Check

- Research source anchors are recorded.
- The first demo slice has infantry, support weapons, anti-tank weapons, a transport, armor, indirect fire, template coverage, mixed-profile allocation, and objective play.
- Every nation has two named initial presets.
