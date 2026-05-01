# World War II Unit Profile Ledger

This ledger records the public unit families used by `derZweiteWeltkrieg` rosters, presets, previews, and starting transport relationships.

## Wikipedia Research Anchors

- British force naming and common equipment: [British Army during the Second World War](https://en.wikipedia.org/wiki/British_Army_during_the_Second_World_War), [Lee-Enfield](https://en.wikipedia.org/wiki/Lee%E2%80%93Enfield), [Universal Carrier](https://en.wikipedia.org/wiki/Universal_Carrier), and [Ordnance QF 17-pounder](https://en.wikipedia.org/wiki/Ordnance_QF_17-pounder)
- American force naming and motorized equipment: [United States Army in World War II](https://en.wikipedia.org/wiki/United_States_Army_in_World_War_II) and [M3 half-track](https://en.wikipedia.org/wiki/M3_half-track)
- Australian force naming and armor: [Australian Army during World War II](https://en.wikipedia.org/wiki/Australian_Army_during_World_War_II) and [Matilda II](https://en.wikipedia.org/wiki/Matilda_II)
- Soviet force naming and assault troops: [Red Army](https://en.wikipedia.org/wiki/Red_Army) and [T-34](https://en.wikipedia.org/wiki/T-34)
- German force naming and assault-gun support: [Wehrmacht](https://en.wikipedia.org/wiki/Wehrmacht), [MG 42](https://en.wikipedia.org/wiki/MG_42), [Sd.Kfz. 251](https://en.wikipedia.org/wiki/Sd.Kfz._251), and [Sturmgeschutz III](https://en.wikipedia.org/wiki/Sturmgesch%C3%BCtz_III)
- Italian force naming and assault-gun support: [Royal Italian Army during World War II](https://en.wikipedia.org/wiki/Royal_Italian_Army_during_World_War_II), [Bersaglieri](https://en.wikipedia.org/wiki/Bersaglieri), [Autoblindo Fiat-Ansaldo](https://en.wikipedia.org/wiki/Autoblindo_Fiat-Ansaldo), and [Semovente da 75/18](https://en.wikipedia.org/wiki/Semovente_da_75/18)

## Public Roster Families

| Nation | Unit Families |
| --- | --- |
| British | Rifle sections, commando sections, platoon HQ, Royal Engineers flamethrower teams, PIAT teams, forward observers, Universal Carriers, Sherman Fireflies, 3-inch mortar batteries, 15-cwt trucks, Daimler Dingo scout cars |
| American | US rifle squads, Ranger squads, platoon HQ, engineer flamethrower teams, Jeep recon patrols, M3 half-tracks, M10 tank destroyers, 81mm mortar batteries |
| Australian | Rifle sections, platoon HQ, PIAT teams, Vickers MG teams, Australian carriers, Dingo scout cars, Matilda II tanks |
| Soviet | Rifle squads, SMG squads, Guards SMG squads, sapper assault groups, sapper squads, scout sections |
| German | Grenadier squads, Volksgrenadier squads, recon sections, MG42 teams, pioneer squads, Sd.Kfz. 251 half-tracks, StuG III assault guns |
| Italian | Rifle squads, Bersaglieri assault squads, Bersaglieri mixed-profile squads, AB41 armored cars, Semovente 75/18 assault guns, trucks |

## Gameplay Contract

- Catalog entries carry a `unit_name` override so custom skirmish lists and roster previews surface nation-specific World War II names while sharing compact rules factories where appropriate.
- Allied rifle-section units expose Riflemen and Bren Team casualty groups.
- Axis Bersaglieri units expose Bersaglieri Riflemen and Bersaglieri NCO casualty groups.
- Starting transport posture uses roster names, such as British Platoon HQ in a Universal Carrier Transport, Australian Rifle Section in an Australian Carrier, German Pioneer Squad in an Sd.Kfz. 251 Half-track, and US Platoon HQ in an M3 Half-track.
- Vehicle-facing behavior uses `recon` for grounded scout vehicles and assault-gun or tank-destroyer terminology for casemate fighting vehicles; the armor and artillery table is tracked in `docs/wwii_armor_profiles.md`.
