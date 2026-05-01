# World War II Weapon Taxonomy

The game centralizes weapon identity in `wwii_weapon_profiles` inside `Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`.

The table uses World War II equipment from the roadmap source anchors while keeping rules behavior readable and testable:

| Rules Role | World War II Examples In The Profile Table |
| --- | --- |
| Rifle and semi-auto fire | Lee-Enfield No.4 Mk I, M1 Garand, Karabiner 98k, Mosin-Nagant M91/30, Carcano M91 Rifle |
| Pistols and close-range fire | M1911A1 Pistol, Webley Revolver, Tokarev TT-33, Nagant M1895 Revolver, M3 Grease Gun |
| SMG and assault fire | Thompson SMG, MP 40 SMG, PPSh-41 SMG, Beretta M38 SMG |
| Light, medium, and heavy machine guns | Bren LMG, Browning M1919A4, DP-27 LMG, Breda M1930 LMG, Vickers HMG, MG42 |
| Heavy machine guns and autocannon | M2 Browning HMG, 20mm Autocannon |
| Portable anti-tank weapons | PIAT, M1 Bazooka, Panzerfaust |
| Anti-tank and tank guns | 17-pounder Anti-Tank Gun, 75mm Tank Gun |
| Flame weapons | Flamethrower |
| Mortars and indirect fire | 81mm Mortar Battery, 120mm Mortar |

Weapon names are visible in shooting logs, roster primary weapons, pending hit allocation sources, and vehicle weapon-destroyed choices. Representative profiles are exposed through a read-only C snapshot API so tests can verify range, strength, AP, shots, and special flags deterministically.
