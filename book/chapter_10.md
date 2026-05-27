# Chapter 10: Historical Modules, Tests, And Extension Discipline

The repository is larger than the default skirmish demo. It includes reusable historical contracts and a Guderian integration module. These targets make it possible to grow from a single playable battle into scenario catalogues and campaign flows without stuffing everything into the core engine.

The target graph in [`../Package.swift`](../Package.swift) is the starting point. `DerZweiteWeltkriegHistorical` depends on `DerZweiteWeltkriegCore`. `DerZweiteWeltkriegGuderian` depends on both the core and historical targets. `DerZweiteWeltkriegAppUI` depends on the core and Guderian module. The core remains at the bottom. That is the rule to preserve.

## Historical Contracts

[`../Sources/DerZweiteWeltkriegHistorical/HistoricalBattleContracts.swift`](../Sources/DerZweiteWeltkriegHistorical/HistoricalBattleContracts.swift) defines types for historical scenarios: IDs, status, side roles, source links, map coordinates, map elements, deployment zones, objectives, victory bands, side options, and full scenario records. These are content contracts, not combat rules.

The historical layer can describe a battle's title, date, theater, result, sources, sides, map, objectives, victory profile, and tags. It can say what a scenario intends. It does not decide how a rifle shoots or how a transport disembarks. That distinction keeps historical content expressive while preserving one combat engine.

The map contract uses `game_board_width()` and `game_board_height()` as defaults, which is a quiet but useful connection. Historical scenarios can share the same board scale as skirmishes while adding more structured metadata.

## Guderian Boundary

[`../Sources/DerZweiteWeltkriegGuderian/GuderianModuleBoundary.swift`](../Sources/DerZweiteWeltkriegGuderian/GuderianModuleBoundary.swift) states the local integration rule plainly: Guderian-specific scenario data, campaign automation, and playable-board adapters live in the Guderian target so the reusable C engine can stay content-agnostic. It also names allowed local dependency edges and forbidden reusable target imports.

This kind of boundary file is useful because it turns architecture into testable, reviewable text. When a future change is tempted to import scenario content into the engine, the answer is already written down.

## Tests As Design Memory

The unit tests in [`../Tests/DerZweiteWeltkriegTests`](../Tests/DerZweiteWeltkriegTests) cover core state, army presets, catalogues, weapon balance, skirmish creation, deployment, roster previews, objectives, transports, mission scoring, combat, historical contracts, and compatibility. They act as design memory. They do not merely catch crashes. They encode what the project considers playable and stable.

The UI tests in [`../Tests/DerZweiteWeltkriegUITests/DerZweiteWeltkriegUITests.swift`](../Tests/DerZweiteWeltkriegUITests/DerZweiteWeltkriegUITests.swift) cover a different surface: launching, setup, deployment, dragging, beginning battle, movement, target selection, shooting, assault controls, cover toggles, phase advancement, and restart. These tests matter because a game can have correct engine logic and still fail at playability if the player cannot trigger it.

Together, the test layers create a healthy split:

- Core tests prove rules and data contracts.
- Historical tests prove scenario records are coherent.
- UI tests prove the app can drive the game.

## Extension Discipline

Adding a new feature should follow the architecture rather than shortcut it.

For a new weapon:

- Add or extend a `weapon_profile_t`.
- Expose any new public display fields through `weapon_profile_view_t` if needed.
- Use the profile in unit factories or catalogues.
- Add tests for representative values and behavior.

For a new unit:

- Create a unit factory in the C engine.
- Assign weapons, model stats, footprint, armor, and special flags.
- Add a catalogue or preset entry with points and source note.
- Verify roster previews and skirmish creation.

For a new action:

- Add a C command if it changes rules state.
- Add view fields for any state the UI must show.
- Add a `RecordedBattleAction.Kind`.
- Route the controller through `executeRecordedAction`.
- Decide whether AI can perform or resolve it.
- Add unit and UI tests.

For a new scenario:

- Model historical metadata in `DerZweiteWeltkriegHistorical`.
- Put scenario-specific catalogs, campaign automation, and adapters in the scenario module.
- Apply board zones and objectives through the engine scenario board API.
- Keep combat resolution in the core.

## What To Avoid

Avoid deriving rules from display text. Avoid adding UI-only state for things that affect action legality. Avoid serializing private engine memory when a configuration plus recorded actions can replay the battle. Avoid importing campaign content into the C engine. Avoid adding catalogue entries that cannot instantiate playable units.

These cautions are not bureaucracy. They keep the game understandable. The project can grow because each layer has a job.

## The End State

The present code already contains the essentials of a World War 2 tabletop demo: Allied and Axis forces, measured board play, terrain, objectives, infantry, vehicles, artillery-style weapons, transports, smoke, armor damage, mixed-profile allocation, assault, scoring, setup, AI, save/load, historical scenario contracts, and tests.

The next expansions should deepen that foundation. More nations, vehicles, weapons, scenarios, and campaigns are welcome when they enter through the same path: engine truth, public views, Swift snapshots, recorded commands, playable UI, and tests that describe why the behavior should stay.

## Why Historical Contracts Are Separate

Historical content has different needs from combat resolution. It needs titles, dates, theaters, source links, side descriptions, commanders, map annotations, deployment zones, objectives, victory bands, tags, and design intent. Combat resolution needs units, weapons, movement, shooting, assault, morale, damage, and scoring. Mixing those concerns would make both worse.

`DerZweiteWeltkriegHistorical` therefore defines scenario contracts without owning the C battle engine. The central type is `HistoricalBattleScenario`, which includes metadata and playable-facing structure:

```swift
public struct HistoricalBattleScenario<ID: HistoricalBattleID>: Identifiable, Codable, Hashable, Sendable {
    public let id: ID
    public let order: Int
    public let title: String
    public let dateLabel: String
    public let theater: String
    public let status: HistoricalBattleStatus
    public let historicalResult: String
    public let designIntent: String
    public let sourceLinks: [HistoricalSourceLink]
    public let sideOptions: [HistoricalSideOption]
    public let map: HistoricalBattleMap
    public let objectives: [HistoricalObjective]
    public let victory: HistoricalVictoryProfile
    public let tags: [String]
}
```

This type can describe a battle as history and as playable design. It can say what sources were used, what each side represents, where objectives sit, and what victory means. It does not roll dice or apply vehicle damage. That is the correct separation.

## Scenario Status As Development Signal

`HistoricalBattleStatus` includes values such as planned, catalog ready, data locked, playable, and demo playable. These statuses are useful because historical scenario development is staged. A battle can have research and metadata before it has a playable board. It can have a map before balance is locked. It can be demo playable before campaign integration is complete.

Status fields prevent binary thinking. A scenario is not only "done" or "not done." It can advertise its current maturity. Tests can assert that playable scenarios have required structures. Documentation can explain which battles are ready for users.

As more scenarios are added, status discipline becomes important. A planned scenario should not appear as a fully playable operation. A demo playable scenario should meet the app's playability expectations. A data locked scenario should have stable source links and map data.

## Historical Map Elements

Historical map contracts include roads, rivers, ridges, towns, forests, minefields, bridges, objectives, phase lines, deployments, and other elements. This is richer than the core engine's terrain rectangles. That is intentional. Historical maps can store more detail than the current battle engine uses.

The adaptation path is then explicit. A historical map element may become:

- an engine terrain zone,
- an objective,
- a deployment zone,
- a UI overlay,
- briefing text,
- or a scenario note.

Not every historical element needs a rule effect. But if it does affect play, it must be translated into engine data. A bridge that controls movement cannot remain only a note. A minefield that damages units cannot remain only a map label. A town that is flavor may remain metadata.

## Guderian Module Boundary

The Guderian boundary file is short but important:

```swift
public enum GuderianModuleBoundaryContract {
    public static let reusableEngineTarget = "DerZweiteWeltkriegCore"
    public static let guderianContentTarget = "DerZweiteWeltkriegGuderian"
    public static let reusableAppTarget = "DerZweiteWeltkriegAppUI"

    public static let forbiddenReusableTargetImports = [
        "DerZweiteWeltkriegCore -> DerZweiteWeltkriegGuderian",
        "DerZweiteWeltkriegCore -> GuderianCore",
        "DerZweiteWeltkriegCore -> GuderianAppUI",
    ]
}
```

This codifies dependency direction. The core engine is reusable. Guderian content depends on it. The app can consume Guderian integration. The core must not import Guderian content. This prevents scenario-specific needs from hardening into engine dependencies.

Boundary files are useful because they make architecture visible. A future contributor can read the contract and understand why a proposed import is wrong. Tests can also enforce these boundaries if needed.

## Native Scenario Integration

The Guderian module contains many files for scenario catalogs, campaign automation, board sessions, AI plans, balance audits, map layout, and playable battle screens. These files are allowed to be scenario-rich. They can know about historical campaigns, Guderian-specific flows, and scenario packs.

The key is that they use the core as an engine, not as a dumping ground. Scenario modules can generate board data, select forces, run automation, and adapt results. They should not reimplement movement, shooting, or assault. If they need a rule the core does not support, the rule should be added to the core in a reusable way.

This keeps historical development from fragmenting the rules. A German campaign scenario and a generic skirmish should agree on how a half-track disembarks troops.

## Tests As Layered Contracts

The test suite is layered like the code. Core tests exercise the C engine through public APIs. Historical tests exercise scenario contracts. Guderian tests exercise campaign and gameplay integration. UI tests exercise player interaction. Each layer has a different purpose.

Core tests are best for deterministic rules. They should create games, issue commands, inspect views, and assert outcomes. They are fast and precise.

Historical tests are best for data completeness. They should assert that scenarios have titles, dates, source links, two playable sides where required, maps, objectives, deployment zones, and victory profiles.

Integration tests are best for boundary behavior. They can assert that scenario modules depend on core correctly, load playable boards, and preserve expected architecture.

UI tests are best for playability. They launch the app, click, drag, and verify visible state.

The suite is strongest when each test type stays in its lane.

## What The Current Tests Protect

The existing tests already protect many design promises:

- demo games load core state,
- army presets load selected matchups,
- every nation exposes force presets,
- catalogue entries have source notes and playable previews,
- representative weapon profiles remain stable,
- army list points are calculated in the engine,
- skirmish creation loads selected entries,
- deployment movement and rotation do not spend battle movement,
- roster previews expose transport relationships,
- mission objectives and terrain load correctly,
- passengers begin embarked where intended,
- historical campaign contracts exist,
- UI tests can deploy and play interactions.

This list is effectively a design ledger. It tells future maintainers what the project cares about. When a test fails, ask whether the design changed or the code regressed. Do not blindly update tests just to make them green.

## Test Gaps To Watch

No test suite is complete. Areas that may need more coverage as the game grows include:

- save/load replay fixtures,
- AI full-turn stability across more force compositions,
- vehicle weapon-destroy choices,
- mixed-profile allocation across melee continuation,
- transport destruction edge cases,
- scenario board application from historical maps,
- campaign persistence,
- accessibility and keyboard navigation,
- visual board regression through screenshots,
- balance-focused simulations.

These are not criticisms of the current suite. They are signposts. As features mature, tests should move from broad smoke coverage to specific regression coverage.

## Extension Discipline For Historical Scenarios

Adding a historical scenario should follow a path:

1. Create or extend a scenario ID enum.
2. Add source links.
3. Define side options with historical force names and army list names.
4. Define map elements and deployment zones.
5. Define objectives and victory profile.
6. Mark status honestly.
7. Translate playable terrain and objectives into engine board data.
8. Choose or generate forces through existing army data where possible.
9. Add tests for scenario completeness.
10. Add playable tests once the scenario enters demo playable or playable status.

This keeps historical work traceable. A scenario should not become playable by hiding rules in a view. It should become playable by translating historical intent into engine-supported battle data.

## Extension Discipline For Campaign Systems

Campaign systems add continuity. They may track progress, losses, commanders, scenario order, historical branches, and automation. That data belongs above the core. The core can report battle results and provide a playable board. The campaign decides what those results mean next.

This separation makes it possible to run standalone skirmishes and campaign battles through the same combat engine. It also keeps campaign persistence from bloating `game_t` with strategic data. If the core starts storing campaign progress, reuse suffers.

When a campaign needs new tactical behavior, add it to the core as a general rule. When it needs strategic memory, keep it in the campaign module.

## Extension Discipline For Tests

Every feature should come with the right kind of test. A new C command needs core tests. A new scenario data type needs historical tests. A new UI control needs UI tests. A new save feature needs replay tests. A new AI behavior needs deterministic or bounded simulation tests.

Tests should avoid depending on implementation details where public contracts suffice. For example, a test should prefer `game_unit_view` over private unit arrays. A UI test should prefer accessibility identifiers over fragile coordinates unless the point of the test is dragging on the board.

Good tests make refactoring safer. Bad tests freeze incidental structure. The difference is whether the test describes a promise users or maintainers rely on.

## Documentation As A Parallel Contract

Documentation is part of extension discipline. The README explains how to run the game and shows screenshots. The docs directory records research scope, weapon taxonomy, unit profiles, armor profiles, battlefield profiles, roadmap, and checklists. This book explains rationale and logic.

When code changes the game's design vocabulary, documentation should change too. Adding a new nation should update research and book context. Adding a new major rule should update the relevant chapter. Adding a new workflow should update README or UI docs if users need to know.

Outdated documentation is dangerous in a historical game because it can preserve false assumptions. Treat docs as living design memory.

## What Not To Centralize

Not every shared-looking thing belongs in the core. Historical source links do not. Campaign progress does not. App window layout does not. UI zoom does not. Test helper workflows do not. Scenario briefing prose does not.

The core should centralize reusable tactical rules. Other layers should centralize their own concerns. This is how the project avoids a "god engine" that knows everything and a "god UI" that decides everything.

## The Chapter's Rule Of Thumb

A feature is healthy when it lives at the lowest layer that truly needs it and no lower. Combat rules live in core. Historical description lives in historical modules. Campaign continuity lives in campaign modules. Presentation lives in SwiftUI. Tests cross layers only to prove public promises.

That rule keeps the game expandable. It lets `derZweiteWeltkrieg` become richer without becoming tangled.

## Boundary Enforcement By Habit

Not every architectural boundary needs a compiler error to be real. Some are enforced by package dependencies. Others are enforced by review habits, tests, and documentation. The Guderian boundary contract is a good example because it names forbidden imports even if a developer could technically try to work around them. It creates a shared expectation.

Good boundary habits include:

- read `Package.swift` before adding dependencies,
- avoid importing app targets into reusable targets,
- keep scenario-specific names out of generic engine APIs unless they are behind optional integration hooks,
- prefer plain data transfer structs across module boundaries,
- add tests when a boundary exists to protect reuse,
- document why a dependency direction matters.

These habits prevent slow architectural erosion. A single convenient import can feel harmless. Ten convenient imports can make the engine impossible to reuse. The book's role is to keep that long-term cost visible.

## Historical Accuracy And Playability

Historical games must balance accuracy and playability. `derZweiteWeltkrieg` is not a database of every squad, tank, gun, and battle. It is a playable tabletop wargame using historically grounded abstractions. That means the code should be honest about its level of detail.

Source links and research ledgers support historical grounding. Unit factories and weapon profiles support playability. Scenario contracts support historical context. Tests support reliability. None of these alone is enough.

A historically accurate equipment name with poor gameplay integration is not complete. A fun rule with no source rationale may drift away from the World War 2 setting. A well-researched scenario with no playable map is not demo ready. A playable map with no tests may regress. The project needs all four forms of discipline.

## Versioning Future Data

As scenarios, campaigns, and save files grow, versioning will matter more. The current saved skirmish document already has a version. Historical scenario records are Codable. Campaign save state files exist in the Guderian module. These are early signs of a data lifecycle.

Future versioning questions include:

- What happens if a catalogue ID changes?
- What happens if a scenario objective is renamed?
- What happens if a campaign branch is removed?
- What happens if a weapon profile changes and old saves replay differently?
- What happens if a historical source link changes?

Not every change needs migration. Some balance changes are allowed to affect replays if the project accepts that saves replay under current rules. But important format changes should be explicit. Data versioning is another reason to keep configuration and actions readable.

## Automation And Playability Reports

The Guderian module includes automation and reporting files such as campaign automation runners, playability architecture, balance audits, board diagnostics, and full campaign ship reports. These are signs that the project treats playability as something that can be inspected, not just felt.

Automation can answer questions human playtesting may miss: do scenarios load, do AI turns complete, do maps have objectives, do forces fit points, do scenarios expose required metadata, do campaign paths remain reachable? Automated answers do not replace human judgment, but they catch structural failures early.

As the game grows, automation should become more important. A suite that can load every scenario, run several turns, and report crashes or stalls would be extremely valuable. It does not need to prove balance. It needs to prove that content is alive.

## UI Tests In The Long-Term Test Pyramid

The current UI tests are intentionally interaction-focused rather than exhaustive. That is right. UI tests are slower and more fragile than core tests. They should cover critical player paths: launching, setup, deployment, movement, phase advancement, shooting, assault controls, toggles, restart, save/load when practical.

Core rules should not be tested only through UI. If a damage table changes, write core tests. If a button disappears, write UI tests. If a scenario contract breaks, write scenario tests. A healthy test pyramid has many fast core tests, a solid layer of integration tests, and focused UI tests.

This pyramid matters because the user's previous request for hundreds of UI tests was explicitly exploratory. Broad UI tests can reveal crashes and failures, but the long-term suite should also contain precise lower-level tests. The book should make that testing philosophy clear.

## Code Comments And Documentation

The codebase generally benefits from clear names more than many comments. But complex blocks, especially pending combat continuations, scenario integration, and AI planning, may deserve short orienting comments. Documentation chapters like this one can carry the larger rationale so source comments do not become essays.

Use the right documentation layer:

- source comments for local complexity,
- tests for executable promises,
- docs ledgers for research and scope,
- README for running and status,
- book chapters for architectural rationale.

This keeps each artifact readable. A source file should not need to explain the entire project. A book chapter should not need to duplicate every line of code.

## Onboarding A New Contributor

A new contributor should be able to follow a path:

1. Read the README to understand what the game is and how to run it.
2. Skim this book's synopsis.
3. Read the chapter relevant to their change.
4. Inspect the source anchors in that chapter.
5. Run existing tests.
6. Make a small change through the proper layer.
7. Add or update tests.

This onboarding path is one reason the book exists. A codebase with C rules, SwiftUI, historical modules, AI, save/load, and UI tests can feel sprawling. The book turns it into a map.

## Examples Of Correct Extension Paths

Consider a new British airborne scenario. Historical metadata belongs in `DerZweiteWeltkriegHistorical` or a scenario module. The force might reuse British catalogue entries or add airborne-specific factories if needed. The board data might use scenario zones and objectives. The playable battle should still call core creation and board application APIs. UI might add a scenario picker. Tests should validate scenario metadata and playable load.

Consider a new artillery smoke barrage rule. The rule belongs in the core because it affects line of sight and board state. It may need a new weapon flag, a temporary smoke zone, a view field, and tests. Swift may display smoke overlays and add a command if player-triggered. Replay needs an action if the player chooses it.

Consider a campaign promotion system. Promotion state belongs in the campaign module. It may influence which units are selected or what briefing text appears. If promotion changes tactical stats, the core needs a general way to receive modified unit profiles or scenario-specific units. The campaign should not patch private engine memory.

These examples show the same rule: start with the layer that owns the concept, then cross boundaries deliberately.

## Examples Of Incorrect Extension Paths

An incorrect path for a new minefield would be drawing a red rectangle in Swift and checking drag coordinates in the view. That would make UI movement differ from engine movement. The correct path is engine terrain or obstacle state, with Swift rendering the view.

An incorrect path for a new campaign loss rule would be adding campaign fields to `game_t` that every skirmish now carries. The correct path is a campaign save state that consumes battle results.

An incorrect path for a new weapon would be adding a button that directly reduces target models in Swift. The correct path is a C weapon profile and combat resolution branch, exposed through normal commands.

Naming wrong paths helps maintainers recognize temptation. Shortcuts are usually attractive because they work for one demo. The architecture exists to make them unnecessary.

## Final Extension Note

The project has already crossed an important line: it is not only a collection of rules and screens, but a playable system with persistence, AI, scenarios, tests, and documentation. That makes extension more rewarding and more risky. New work should add to the system, not tunnel around it. If a feature cannot be explained in terms of engine truth, public views, snapshots, recorded commands, UI affordances, and tests, it probably needs more design before implementation.

The healthiest future for `derZweiteWeltkrieg` is incremental depth. Add one scenario and make it load cleanly. Add one weapon behavior and test it. Add one UI command and replay it. Add one campaign step and keep the tactical battle reusable. This rhythm may feel slower than piling features into the nearest file, but it compounds. Each well-placed feature makes the next one easier because it strengthens the architecture instead of hiding from it.

That is the reason this final chapter returns to discipline. A World War 2 game has almost endless possible content. The only way to make that abundance manageable is to keep the path from history to rules to interface to tests visible.

When that path is visible, contributors can disagree productively. They can debate whether a value is balanced, whether a scenario is ready, whether a UI control is clear, or whether a test captures the right promise. Those debates improve the game because everyone can point to the layer being changed and the contract being protected for future work, release, maintenance, expansion, and playable growth over time together as careful teammates here.
