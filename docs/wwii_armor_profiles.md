# World War II Armor, Transport, And Artillery Ledger

This ledger records how `derZweiteWeltkrieg` models World War II armor, transports, scout cars, assault guns, tank destroyers, and artillery batteries. The C engine owns movement bands, transport capacity, mounted fire arcs, smoke, hull-down state, weapon-destroyed choices, damage tables, barrage fire, and assault resolution.

## Wikipedia Research Anchors

- Cross-faction tank doctrine and vehicle classes: [Tanks in World War II](https://en.wikipedia.org/wiki/Tanks_in_World_War_II)
- Allied carriers and transports: [Universal Carrier](https://en.wikipedia.org/wiki/Universal_Carrier), [M3 half-track](https://en.wikipedia.org/wiki/M3_half-track), and [Daimler Dingo](https://en.wikipedia.org/wiki/Daimler_Dingo)
- Allied armor and tank destroyers: [Sherman Firefly](https://en.wikipedia.org/wiki/Sherman_Firefly), [M10 tank destroyer](https://en.wikipedia.org/wiki/M10_tank_destroyer), [Matilda II](https://en.wikipedia.org/wiki/Matilda_II), and [Ordnance QF 17-pounder](https://en.wikipedia.org/wiki/Ordnance_QF_17-pounder)
- Axis transports, armored cars, and assault guns: [Sd.Kfz. 251](https://en.wikipedia.org/wiki/Sd.Kfz._251), [Autoblindo Fiat-Ansaldo](https://en.wikipedia.org/wiki/Autoblindo_Fiat-Ansaldo), [Sturmgeschutz III](https://en.wikipedia.org/wiki/Sturmgesch%C3%BCtz_III), and [Semovente da 75/18](https://en.wikipedia.org/wiki/Semovente_da_75/18)
- Artillery and mortar profiles: [Ordnance QF 25-pounder](https://en.wikipedia.org/wiki/Ordnance_QF_25-pounder), [Ordnance ML 3-inch mortar](https://en.wikipedia.org/wiki/ML_3-inch_mortar), [M1 mortar](https://en.wikipedia.org/wiki/M1_mortar), [8 cm Granatwerfer 34](https://en.wikipedia.org/wiki/8_cm_Granatwerfer_34), [Obice da 75/18 modello 34](https://en.wikipedia.org/wiki/Obice_da_75/18_modello_34), and [Bofors 40 mm L/60 gun](https://en.wikipedia.org/wiki/Bofors_40_mm_L/60_gun)

## Engine Roles

| Rules Role | World War II Implementation |
| --- | --- |
| Grounded recon and carrier movement | Universal Carrier, Jeep Recon Patrol, Daimler Dingo Scout Car, and AB41 Armored Car use fast or recon behavior where appropriate |
| Heavy transport | M3 Half-track, Sd.Kfz. 251 Half-track, 15-cwt truck, Australian Carrier, and Italian Truck support embarkation, disembarkation, passenger damage, and embarked firing |
| Turreted battle tank | Sherman Firefly and Matilda II style profiles use turret or hull-mounted weapons with period armament names |
| Assault gun or tank destroyer | `TE_UNIT_ASSAULT_GUN` represents casemate assault guns and tank destroyers such as StuG III, Semovente 75/18, and M10 Tank Destroyer |
| Scout car | Daimler Dingo Scout Car and AB41 Armored Car use ground vehicle movement, recon tagging, and period light weapons |
| Artillery battery | Mortar Battery and field-gun style weapons use barrage, ordnance, blast, and pinning behavior with World War II weapon names |

## Vehicle And Weapon Notes

| Nation | Demo Vehicles Or Batteries | Notes |
| --- | --- | --- |
| British | Universal Carrier, Sherman Firefly, 3-inch Mortar Battery, Daimler Dingo Scout Car, British 15-cwt Truck | Carrier and truck weapons use Bren light machine-gun language. Firefly carries a 17-pounder anti-tank gun with a hull Browning M1919A4. Dingo is a wheeled recon vehicle. |
| American | Jeep Recon Patrol, M3 Half-track, M10 Tank Destroyer, 81mm Mortar Battery | Jeep and half-track profiles support mobile fire and transport behavior. The M10 uses tank-destroyer close-combat rules and a heavy anti-tank gun profile. |
| Australian | Australian Carrier, Matilda II, Dingo Scout Car | Australian Carrier uses Vickers/Bren armament. Matilda labels keep the roster's armor hooks while matching Commonwealth equipment language. |
| Soviet | Rifle, SMG, Guards, sapper, and scout support formations | The active presets expose Soviet infantry and support weapons; heavier SU/T-34 family expansion is a data-growth task. |
| German | Sd.Kfz. 251 Half-track, StuG III Assault Gun, MG42 support | The Sd.Kfz. 251 supports armored-personnel-carrier flow. StuG III uses fixed casemate gun arcs and machine-gun support. |
| Italian | AB41 Armored Car, Semovente 75/18 Assault Gun, Italian Truck | AB41 uses a 20mm autocannon profile. Semovente 75/18 uses a fixed 75mm gun and Breda machine-gun support. |

## Behavior Coverage

- Vehicle damage supports crew shaken, crew stunned, immobilized, weapon destroyed, wrecked, detonation, passenger damage, and wreck displacement.
- Mounted weapons distinguish turret, hull, pintle, fixed casemate, and artillery-style mounts through arc handling.
- `recon` is the public state flag for grounded fast/scout vehicles in Swift snapshots.
- `assault gun` is the public vehicle class shown in tests, board badges, and logs.
- Transport destruction, emergency disembarkation, embarked firing, smoke, hull-down state, and barrage tests are covered by World War II fixtures.
