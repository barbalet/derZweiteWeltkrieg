# Chapter 3: Armies And Catalogues

The game presents World War 2 armies as Allied or Axis nations. The Swift side exposes that classification in [`../Sources/DerZweiteWeltkriegApp/Bridge/ArmyReferenceCatalog.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/ArmyReferenceCatalog.swift), where British, American, Australian, and Soviet armies are `.allies`, while German and Italian armies are `.axis`. The core side exposes the same playable nations through `army_list_t` in the public header.

This duplication is small and intentional. The C engine needs compact enum values for rules, catalogues, and tests. The Swift app needs user-facing references with stable IDs, display names, and allegiance labels. `ArmyReference` bridges those needs without forcing UI strings into the engine.

## Why Catalogues Exist

The engine contains static army catalogues in [`../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`](../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c). Each catalogue entry has a catalog ID, points value, maximum count, unit factory, display name, and source note. British entries include rifle sections, commandos, carriers, Fireflies, mortars, platoon HQ, flamethrowers, transports, PIAT teams, trucks, and scout cars. German entries include grenadiers, Volksgrenadiers, recon, MG42 teams, pioneers, Sd.Kfz. 251 half-tracks, and StuG III assault guns. Other catalogues cover Australian, Italian, American, and Soviet formations.

The catalogue model is more flexible than hard-coded rosters. It supports the setup screen, AI list building, tests, force previews, and future scenario composition. A user can draft a list from available units. The AI can assemble an opposing force from the same rules. Tests can verify every catalogue entry has points, a source note, a playable unit preview, and armor where appropriate.

The catalogue also lets the game be historically suggestive without pretending to be a full order-of-battle database. Entries are representative World War 2 game units, anchored by the research ledgers in [`../docs/wwii_demo_scope.md`](../docs/wwii_demo_scope.md), [`../docs/wwii_weapon_taxonomy.md`](../docs/wwii_weapon_taxonomy.md), [`../docs/wwii_unit_profiles.md`](../docs/wwii_unit_profiles.md), and [`../docs/wwii_armor_profiles.md`](../docs/wwii_armor_profiles.md). The source note string exists so the data layer remembers where the historical abstraction came from.

## Presets And Drafting

The engine still supports curated force presets through functions such as `army_force_count`, `army_force_view`, and `army_force_roster_unit_view`. Presets matter for demo readiness. A new player can start with a plausible British vs German operation without building from scratch. Tests such as `testEveryNationForcePresetLoadsPlayableRoster` verify that each playable nation has force variants that can load into a real game.

The setup screen uses catalogues differently. [`../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift`](../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift) shows the player a nation picker, a points cap, and steppers for each unit in the selected nation's catalogue. Those steppers populate `playerUnitCounts` in `GameController`. The current draft becomes `[ArmyListSelection]`, then the controller asks the C engine for total points through `army_list_total_points`.

The AI opponent plan is generated in [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift). It filters opponent nations by allegiance, then uses catalogue entries and a small dynamic programming pass to find a list close to the player's point total. That method is intentionally local and transparent. The AI is not trying to be a grand strategist at setup time. It is trying to produce a legal, point-matched opposing force quickly enough that setup feels alive.

## Source Notes And Tests

The tests in [`../Tests/DerZweiteWeltkriegTests/DerZweiteWeltkriegTests.swift`](../Tests/DerZweiteWeltkriegTests/DerZweiteWeltkriegTests.swift) are blunt about catalogue quality. They assert that every catalogue entry has a name, points, max count, source note, preview unit, models, wounds, and armor where appropriate. They also assert stable representative weapon profiles and that every nation preset exposes playable rosters.

That is a good pattern for historical game data. The tests do not prove that every value is historically perfect. They prove that the gameplay contract is not broken: the unit can be selected, previewed, costed, instantiated, and played. Historical refinement can proceed inside that tested frame.

## The Rationale

The catalogue system solves three problems at once:

- It gives the player meaningful force-building choices.
- It gives the AI a shared legal pool.
- It gives the engine a uniform way to create units from historical abstractions.

The important constraint is that catalogues should continue to produce real units, not loose descriptors. A new catalogue entry should have a unit factory, point value, max count, source note, preview, and tests. If it represents armor, it should expose armor values. If it carries passengers, both the transport and passenger relationship should be coherent. If it introduces a new weapon behavior, Chapter 4 and Chapter 7 describe where that behavior belongs.

## Allegiance In Swift, Army Identity In C

The game has two related but distinct ideas: army identity and allegiance. Army identity belongs to the engine because it affects catalogue lookup, roster creation, preset generation, and tests. Allegiance belongs mostly to setup and opponent selection because it describes which armies should oppose one another.

The C enum is compact:

```c
typedef enum {
    DZW_ARMY_DEMO = 0,
    DZW_ARMY_BRITISH = 1,
    DZW_ARMY_AMERICAN = 2,
    DZW_ARMY_AUSTRALIAN = 3,
    DZW_ARMY_SOVIET = 4,
    DZW_ARMY_GERMAN = 5,
    DZW_ARMY_ITALIAN = 6
} army_list_t;
```

The Swift catalogue adds user-facing identity:

```swift
private static let supportedArmies: [KnownArmy] = [
    KnownArmy(id: "british", displayName: "British", allegiance: .allies, preset: DZW_ARMY_BRITISH),
    KnownArmy(id: "american", displayName: "American", allegiance: .allies, preset: DZW_ARMY_AMERICAN),
    KnownArmy(id: "australian", displayName: "Australian", allegiance: .allies, preset: DZW_ARMY_AUSTRALIAN),
    KnownArmy(id: "soviet", displayName: "Soviet", allegiance: .allies, preset: DZW_ARMY_SOVIET),
    KnownArmy(id: "german", displayName: "German", allegiance: .axis, preset: DZW_ARMY_GERMAN),
    KnownArmy(id: "italian", displayName: "Italian", allegiance: .axis, preset: DZW_ARMY_ITALIAN),
]
```

This split lets the setup UI speak in ordinary names while the engine remains enum-driven. It also keeps allegiance logic outside the core. The core does not need to know that British and German are enemies in the setup screen. It only needs to instantiate the army it is given. The app can decide that the AI should choose from the opposing allegiance.

That decision has design value. It leaves room for historical or custom scenarios where unusual pairings might be valid. The core can create any two legal army lists. The setup screen chooses conventional Allies-vs-Axis opposition for the default flow.

## Catalogue Entry Shape

In the C implementation, each catalogue entry binds design data to a factory function. The macro name is less important than the pattern: ID, point cost, max count, unit creation function, display name, source note.

```c
static const army_catalog_entry_t american_catalog[] = {
    DZWK_CATALOG_ENTRY(0, 150, 2, make_catalog_american_rifle_squad, "US Rifle Squad", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(1, 140, 1, make_catalog_commando_or_ranger, "US Ranger Squad", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(2, 65, 1, make_catalog_jeep_recon_patrol, "Jeep Recon Patrol", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(3, 115, 1, make_catalog_m10_tank_destroyer, "M10 Tank Destroyer", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(4, 95, 1, make_catalog_mortar_battery, "81mm Mortar Battery", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(5, 100, 1, make_catalog_us_command_squad, "US Platoon HQ", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(6, 25, 2, make_catalog_flamethrower_team, "US Engineer Flamethrower Team", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(7, 50, 1, make_catalog_m3_half_track, "M3 Half-track", DZWK_AMERICAN_SOURCE_NOTE),
};
```

This is not just a menu. It is a compact playable force grammar. A catalogue entry can be previewed, costed, selected, counted against a maximum, instantiated into a `unit_t`, and included in a saved configuration. The source note keeps the historical abstraction accountable. The display name keeps the player-facing draft readable. The factory keeps the entry grounded in actual rules.

The same shape applies to each nation, even though the entries differ. British catalogues emphasize rifle sections, carriers, PIAT teams, Fireflies, mortars, and support elements. German catalogues include grenadiers, MG42 teams, pioneers, half-tracks, and StuG assault guns. Soviet catalogues emphasize rifle, SMG, guards, sapper, and scout formations. Italian catalogues include rifle squads, Bersaglieri, armored cars, Semovente assault guns, and trucks. The entries are not a complete simulation of every World War 2 formation. They are a demo-scale vocabulary chosen to exercise infantry, armor, artillery-like weapons, transports, mixed profiles, and objective play.

## Point Values As Gameplay Translation

Point values are not historical facts. They are balance tools. A real army's production cost, battlefield rarity, training burden, and doctrinal role cannot be translated directly into a single number for a small demo. The catalogue points instead express expected gameplay impact inside this ruleset.

A unit with many models, better weapons, armor, transport capacity, or special behavior should cost more because it gives the player more tools. A cheap flamethrower team may be fragile but tactically important. A tank destroyer may have fewer models but can threaten armor. A transport may not destroy much by itself but changes movement, passenger protection, and scenario reach. The point value is where those tradeoffs become draftable.

The setup screen asks the engine for total points:

```swift
func points(for army: army_list_t, selections: [ArmyListSelection]) -> Int {
    let entries: [army_list_entry_t] = selections.map { selection in
        army_list_entry_t(catalog_id: Int32(selection.catalogID), count: Int32(selection.count))
    }
    let total: Int32 = entries.withUnsafeBufferPointer { buffer in
        army_list_total_points(army, buffer.baseAddress, Int32(buffer.count))
    }
    return Int(total)
}
```

This is a small but important choice. Swift does not recalculate points from its own copy of catalogue data. It converts selected IDs and counts into C entries and asks the engine. That means a point change in the C catalogue immediately affects player setup, AI drafting, tests, and skirmish creation.

## Maximum Counts And Demo Scale

Each catalogue entry has `max_count`. This keeps a demo force from becoming lopsided. Without maximums, the best mathematical draft might spam the cheapest or most efficient unit. Maximums are also historically suggestive: a small operation is unlikely to contain endless identical specialist teams.

The setup UI uses the maximum to bound steppers. The AI uses it by flattening catalogue entries into repeated items up to their max count. Tests assert that max counts are positive. This turns one catalogue field into three forms of guardrail: player interface, AI list generation, and data integrity.

If future development adds larger battles, max counts can grow or scenario-specific list rules can be added. The current pattern still works. A bigger catalogue might include role categories such as platoon, support, armor, artillery, and transport. But the base principle should remain: force construction rules belong in data the engine can expose and tests can inspect.

## Presets Versus Player Drafts

The game supports both curated presets and custom drafted skirmishes. Presets are useful for immediate play, examples, tests, and scenario defaults. Drafts are useful for replayability and player agency. The engine keeps both because they answer different needs.

Presets are exposed through functions such as `army_force_count`, `army_force_view`, and `army_force_roster_unit_view`. They allow the app or tests to preview a named force without selecting catalogue entries one by one. A preset can tell a story: British Rifle Platoon, US Ranger Assault, Australian Matilda Column, German Panzergrenadier Kampfgruppe, Italian Alpini Detachment. It can include starting transport relationships or a curated mix of infantry and vehicles.

Drafts use `army_list_entry_t` arrays and `game_create_skirmish`. They are more mechanical: choose catalogue ID and count. The engine expands those choices into units. This is what the setup screen uses for the default playable loop.

The coexistence is healthy. Presets give designers and scenario modules a ready-made vocabulary. Drafts give players a builder. Tests cover both so neither path becomes stale.

## Source Notes As Design Anchors

Earlier project work gathered Wikipedia-backed information into documentation ledgers. The catalogue source notes point back to that research basis, usually through strings that mention the research-backed demo scope. This is not intended to make the engine a citation database. It is intended to prevent anonymous data.

Anonymous historical game data decays quickly. A future maintainer sees "Matilda II" with certain armor values or a "Breda M1930 LMG" with certain shots and does not know whether the value is a placeholder, a deliberate abstraction, or an old mistake. Source notes and docs do not remove judgment, but they preserve the path of judgment.

The tests enforce that catalogue entries carry source notes. That may seem unusual for game tests, but it is appropriate here. The project is not just testing that values compile. It is testing that historical abstractions remain traceable.

## The AI Uses The Same Catalogue

The opponent plan is generated from the same army references and catalogue units shown to the player. This matters because the AI should not receive hidden units or special prices in the default setup flow. `suggestedOpponentPlan()` first finds armies whose allegiance opposes the player. It then asks `bestOpponentPlan` to build a list near the player's point value.

The plan builder is a bounded dynamic programming search:

```swift
let items = catalog.flatMap { unit in
    Array(repeating: Item(catalogID: unit.id, points: unit.points), count: unit.maxCount)
}

var dp: [Choice?] = Array(repeating: nil, count: cappedTarget + 1)
dp[0] = Choice(counts: [:], unitCount: 0)

for item in items {
    guard item.points <= cappedTarget else { continue }
    for total in stride(from: cappedTarget, through: item.points, by: -1) {
        guard let previous = dp[total - item.points] else { continue }
        var nextCounts = previous.counts
        nextCounts[item.catalogID, default: 0] += 1
        let nextChoice = Choice(counts: nextCounts, unitCount: previous.unitCount + 1)
        if let existing = dp[total] {
            if nextChoice.unitCount > existing.unitCount {
                dp[total] = nextChoice
            }
        } else {
            dp[total] = nextChoice
        }
    }
}
```

The tie-breaker prefers more units at the same point total. That is a gameplay-friendly choice because it tends to produce an AI force with enough pieces to participate in objectives, movement, and shooting rather than a single expensive unit. It is not perfect strategy, but it gives the demo a responsive opponent quickly.

Future AI drafting could add more heuristics: prefer anti-tank if the player buys armor, prefer transports on wide maps, prefer infantry on objective-dense maps, or prefer historical pairings in scenario mode. Those improvements should still begin from catalogue entries. The shared catalogue keeps both sides honest.

## Creating Skirmish Units

When `game_create_skirmish` receives army list entries, the engine must expand them into actual units. That expansion is where catalogue factories earn their keep. The function does not merely record that the player bought "catalog ID 0." It creates a unit with name, owner, model count, weapons, stats, armor if any, transport links if applicable, and a deployment slot.

This is why catalogue previews matter. The setup UI can show `ArmyCatalogUnitSnapshot`, which wraps `army_catalog_unit_view_t` and `ArmyRosterUnitSnapshot`. The preview should resemble the unit that will appear on the board. If the preview says a unit has transport capacity, the actual unit should have transport capacity. If the preview says the primary weapon is PIAT, the created unit should use that weapon.

The tests are deliberately suspicious about this. They inspect catalogue previews, create skirmishes, and check resulting unit names. This reduces the risk that a catalogue entry looks correct in setup but creates the wrong unit in battle.

## Adding A New Nation

Adding a new nation is larger than adding a name. The path should look like this:

1. Add a new `army_list_t` value.
2. Add a Swift `ArmyReference` with allegiance and stable ID.
3. Add `army_name` support and sanitization.
4. Create unit factories for representative infantry, support weapons, vehicles, and any special units.
5. Add catalogue entries with points, max counts, names, and source notes.
6. Add at least two force presets if the nation should match the existing playable standard.
7. Add roster preview support.
8. Add tests that every preset loads and every catalogue entry is playable.
9. Check setup AI behavior so the new nation appears as an opponent only when appropriate.
10. Update research docs and book chapters if the nation changes the game's design vocabulary.

This is a lot of work because a playable army is a cross-layer feature. It appears in C data, Swift setup, UI labels, AI opponent selection, tests, and documentation. Cutting corners makes the nation visible but not reliable.

## Adding A New Catalogue Entry

A single new unit entry follows a smaller version of the same path. The entry needs a factory. The factory should set meaningful model stats, weapons, and flags. The point cost should be reviewed against comparable units. The max count should support demo-scale force building. The source note should identify the research basis. The preview should expose the same kind of unit the factory creates.

Then tests should answer practical questions:

- Does the catalogue count include the new entry?
- Does the entry have a nonempty name and source note?
- Is its point value positive?
- Does its max count make sense?
- Does its preview expose models and wounds?
- If it is a vehicle or assault gun, does it expose armor?
- Can a skirmish containing the entry be created?

The goal is not to freeze every balance value forever. The goal is to make data changes intentional and playable.

## Why The Catalogue Is In C

It might seem natural to store catalogues in JSON or Swift data. The current C placement has benefits. Unit factories are already C because they create engine units. Weapon profiles are C because combat resolution consumes them directly. Keeping catalogues beside factories makes it easy to ensure entries and units stay aligned.

There is a tradeoff. C arrays are less friendly to content editing than external data files. If the game grows into hundreds of units, a data-driven layer may become attractive. Even then, the engine will still need a validation and instantiation boundary. The current C catalogue is the simplest honest implementation for the current scale.

If external data is introduced later, it should not bypass the principles here. External entries must still have point values, max counts, source notes, factories or templates, previews, tests, and a path into `game_create_skirmish`. Data-driven does not mean unvalidated.

## Balance As Iteration

The point system is deliberately simple. That is acceptable for a playable demo, but it should be treated as iterative. Tests assert representative values so accidental changes are visible, not because the first number is sacred. If playtesting shows a unit is underpriced, update the points and update tests with a clear reason. If a weapon profile changes, review the units and catalogue entries that rely on it.

Balance also interacts with AI drafting. A point change can alter opponent plans. A max count change can change force composition. A new cheap unit can make the AI prefer many small units. These are not reasons to avoid changes. They are reasons to run tests and play through setup after data edits.

The catalogue is where historical flavor becomes playable economics. It deserves the same care as combat code.

## The Chapter's Rule Of Thumb

An army list is healthy when the same data supports five things: player choice, AI choice, unit creation, preview display, and tests. If any one of those breaks, the catalogue entry is not finished. That rule of thumb keeps armies from becoming decorative data. In `derZweiteWeltkrieg`, every army should be something the player can draft, the AI can oppose, the engine can instantiate, the UI can explain, and the test suite can defend.

## Reading The Current Army Set

The current army set is intentionally asymmetric in flavor but symmetric in capability. The Allies include British, American, Australian, and Soviet forces. The Axis include German and Italian forces. Each nation has distinctive labels and weapons, but the demo tries to give every side access to the core gameplay needs: ordinary infantry, automatic weapons, some form of anti-armor threat, at least one unit that stresses movement or transport rules where appropriate, and units that can participate in objective play.

British forces provide a baseline Allied feel: rifle sections, Bren or Vickers-style support, PIAT teams, carriers, trucks, and Firefly or Matilda-style armored presence through current factories. The American catalogue leans into larger rifle squads, Rangers, half-tracks, bazookas, mortars, and tank destroyer flavor. Australian entries emphasize rifle sections, carriers, PIAT support, scout cars, Vickers teams, and Matilda naming. Soviet entries emphasize rifle and SMG formations, guards, sappers, and scouts. German entries bring grenadiers, Volksgrenadiers, recon, MG42 teams, pioneers, half-tracks, and StuG assault guns. Italian entries bring rifle squads, Bersaglieri, AB41 armored cars, Semovente assault guns, and trucks.

The exact historical representation is intentionally compressed. A tabletop demo cannot model every wartime table of organization. Instead, it chooses representative formations that create different tactical textures. German MG42 teams make heavy fire visible. Soviet SMG squads make short-range assault pressure visible. American half-tracks make passenger and transport logic visible. Italian Semovente units make assault-gun logic visible. British and Australian carrier/truck entries make mounted movement and support choices visible.

This is how the game turns historical research into playable systems. The catalogue is not only saying "this equipment existed." It is saying "this equipment helps exercise a rule the demo needs."

## Relationship To The Research Ledgers

The documentation under `docs/` gives the catalogue historical context. `wwii_demo_scope.md` defines the first playable slice and nation preset plan. `wwii_weapon_taxonomy.md` records how weapons are grouped for play. `wwii_unit_profiles.md` and `wwii_armor_profiles.md` describe unit and armor abstractions. `wwii_battlefield_profiles.md` records terrain and battlefield assumptions.

Those ledgers are important because the engine values are intentionally game-scaled. A weapon range in the engine is a tabletop range, not a literal battlefield range. An armor value is a comparative rules value, not a millimeter thickness table. A unit's model count is a playable representation, not a full platoon roster. The docs explain the translation layer. The catalogue stores the translated result.

When changing catalogue values, update the appropriate ledger if the rationale changes. For example, changing a unit name from a generic truck to a specific vehicle may require research documentation. Changing a point cost after playtesting may not require historical documentation, but it should be reflected in tests if tests lock the value. Changing a weapon profile may require both weapon taxonomy and combat tests.

## Force Preview As Player Education

The setup screen does more than collect choices. It teaches the player what a unit is. `ArmyRosterUnitSnapshot.summaryLine` condenses important data into readable tags: model count, wounds, mixed profiles, armor values, transport capacity, fast/recon/open-topped flags, primary weapon, and starting embarked relationships. That summary is the player-facing version of the catalogue contract.

The preview matters because `derZweiteWeltkrieg` has several unit categories that behave differently. A player choosing between a rifle section, a mortar battery, an armored car, and a transport needs to see more than names. They need enough signal to understand what the choice will do on the board. The summary line should therefore stay honest and dense.

If a new unit has a special behavior that is not visible in the summary, consider whether it should be. Some behaviors are implied by kind, such as vehicle armor. Others may need text, such as open-topped transport or recon. The summary should not become a rulebook paragraph, but it should reveal the attributes that change play.

## Scenario Use Of Army Data

Historical scenario modules can use the same army concepts in a more directed way. A scenario may choose fixed sides and forces rather than letting the setup screen draft freely. Even then, the best path is to reuse catalogues, presets, or unit factories where possible. Reuse keeps scenario units aligned with core tests and app previews.

If a scenario needs a special one-off unit, that unit should still be represented as a real engine unit. It may not need to appear in the generic setup catalogue, but it still needs weapons, stats, flags, views, and tests if its behavior is new. Scenario content should narrow player choice, not invent a parallel kind of unit.

This is especially important for campaigns. A campaign layer may track losses, reinforcements, named commanders, or historical objectives. But when a battle begins, the units on the board should still be engine units. That is how scenario storytelling and rules simulation stay connected.

## Practical Review Questions

When reviewing an army or catalogue change, ask:

- Does this entry represent a playable battlefield role?
- Does the unit factory create what the preview says?
- Is the point cost plausible relative to similar units?
- Does max count prevent obvious spam in demo-scale games?
- Does the source note point to the correct research context?
- Can the setup screen display it without special cases?
- Can the AI draft it without creating broken forces?
- Do tests cover the entry, preview, and skirmish creation?

These questions keep the catalogue from becoming a pile of names. The names are the flavor. The role, factory, cost, preview, and tests are what make the flavor playable.

That distinction should stay visible whenever the armies grow. A nation is complete only when its historical identity has become reliable gameplay data that players, AI, scenarios, documentation, future maintainers, balance reviews, saved games, and tests can all use.

Anything less is only a label, however evocative the name may be on screen during setup, battle, and deployment.
