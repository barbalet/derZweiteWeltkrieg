# Chapter 5: Battlefield, Terrain, And Objectives

The battlefield in `derZweiteWeltkrieg` is a measured rectangle. The C engine exposes `game_board_width()` and `game_board_height()`, while the Swift controller publishes those values as `GameController.boardWidth` and `GameController.boardHeight`. The default board is used by the engine for legality and by the UI for drawing, dragging, zooming, terrain, objectives, and unit positions.

The point of the fixed board is trust. A player drag on the screen becomes a point in the same coordinate system used by movement distance, range, terrain intersection, objective control, and enemy separation. If the board were just visual, the UI would have to approximate legality. Here the UI asks for a move; the engine says yes or explains why not.

## Terrain Zones

Terrain zones are represented by rectangles with a kind, cover save, line-of-sight flag, and hull-down flag. `zone_view_t` exposes those fields publicly, and `ZoneSnapshot` converts them into Swift data. The default scenario includes named terrain such as ruined farmhouses, ridges, shell-hole fields, and minefields. Tests verify those names and kinds in the mission scenario.

The engine uses terrain in several ways:

- Impassable terrain blocks movement and deployment.
- Difficult terrain can reduce movement or force vehicle/recon bog checks.
- Line-of-sight blocking terrain prevents most direct fire.
- Cover saves and hull-down state affect survivability.

The code keeps these effects mechanical. `path_touches_terrain` checks whether a movement segment intersects a zone of a given kind. `can_place_unit_at` checks board bounds, impassable terrain, and overlap rules. `find_disembark_position` searches legal positions around a transport. These helpers keep terrain behavior out of the UI.

## Objectives And Mission Scoring

Objectives are circular areas with identity, name, position, radius, controller, and presence counts. `objective_view_t` gives the app enough to draw markers, labels, contested state, and score text. `MissionSnapshot` turns the engine's mission view into title, target score, current score, leader line, and winner name.

The board view draws objective control with color and a dashed radius. That display is not just decoration. It mirrors engine-calculated control. The app can show contested, player-controlled, opponent-controlled, or unclaimed objectives because the engine has already counted presence.

Objective scoring happens when phases advance past the assault phase and the engine finishes a turn. `game_advance_phase` moves Movement to Shooting, Shooting to Assault, then completes the turn, scores objectives, switches active player, starts a new Movement phase, and increments the turn number. This makes objectives part of the turn economy. A unit may move or assault to change control before scoring, but the score is not an arbitrary UI event.

## Deployment

Deployment is a distinct app mode, but it still uses engine actions. `game_deploy_unit` and `game_deploy_rotate_unit` reposition and face units without consuming movement. That distinction is tested by `testDeploymentMoveRepositionsUnitWithoutConsumingMovement` and `testDeploymentRotateUpdatesFacingWithoutSpendingAction`.

This is a practical compromise. A playable demo needs the player to arrange units before the battle begins. But deployment should not be a loophole that bypasses board bounds, impassable terrain, or overlap. The engine therefore has deployment-specific commands: more permissive than movement in action cost, but still rule-checked.

The Swift board uses the same drag gesture for deployment and battle movement. [`../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift`](../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift) asks the controller to move the unit. [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Actions.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Actions.swift) chooses `deployUnit` or `moveUnit` based on `appMode`. The UI interaction is consistent; the command semantics change at the controller boundary.

## Drawing The Board

The board view renders in layers: ground, grid, terrain, objectives, then units. It maps every game coordinate into the current view size. Terrain rectangles are scaled from board coordinates. Objective radii use the board scale. Unit tokens use position, footprint, owner, kind, selection state, smoke, transport badges, assault gun badges, and wound badges.

The visual decisions are tuned for repeated play. Infantry are circles. Vehicles are rounded rectangles. Assault guns get an `AG` badge. Transports with passengers get a `TR` badge. Smoke creates an outer dashed ring. Vehicle facing is shown by a barrel-like marker. These are not separate game states. They are presentations of `UnitSnapshot`.

## Scenario Hooks

The engine also exposes `game_apply_guderian_scenario_board`, which allows a scenario module to replace mission name, target score, terrain zones, and objectives. The historical and Guderian modules use typed scenario contracts above the core. This keeps the board model reusable: a custom battle may have different named terrain and objectives, but it still feeds the same engine structures.

The extension rule is simple: if the new battlefield element affects rules, put it in the engine and expose it as a view. If it is only a label, briefing, or historical annotation, keep it in the scenario module. That separation lets scenario detail grow without turning the core into a campaign database.

## Board Dimensions As A Rules Primitive

The board size is a rules primitive, not merely a drawing choice. The C functions `game_board_width()` and `game_board_height()` are used by the engine, the Swift controller, the historical map defaults, and the board rendering code. This makes the board a shared contract across layers.

The engine uses board dimensions to reject illegal placement, clamp fall-back movement, calculate legal disembarkation, and keep units inside the table. Swift uses the same dimensions for aspect ratio and coordinate conversion. Historical scenario structures default to the same dimensions so their map data can align with playable battles.

This shared size gives every feature a common language. A deployment zone can be a rectangle on the same coordinate system as an objective. A drag gesture can become a legal move request. A line-of-sight helper can test terrain rectangles in the same space the player sees. The board becomes a rule surface, not a painted background.

## Terrain Data Shape

Terrain zones are stored as named rectangles with kind and rule flags:

```c
typedef struct {
    int id;
    const char *name;
    terrain_kind_t kind;
    rect_t rect;
    int cover_save;
    bool blocks_line_of_sight;
    bool hull_down;
} zone_t;
```

The public `zone_view_t` mirrors that shape. Swift converts it into `ZoneSnapshot` with a `CGRect` and booleans. The board view then renders terrain based on kind and labels it by name. The same object therefore serves rules, inspection, and visual orientation.

The terrain kind enum is deliberately small:

```c
typedef enum {
    DZW_TERRAIN_OPEN = 0,
    DZW_TERRAIN_DIFFICULT = 1,
    DZW_TERRAIN_IMPASSABLE = 2
} terrain_kind_t;
```

This gives the demo enough variety without building a full terrain taxonomy. Difficult terrain affects movement and vehicle bogging. Impassable terrain blocks placement and movement. Open terrain can still carry cover or hull-down flags if a scenario needs it. More terrain kinds can be added later, but each new kind should earn its place by changing rules.

## Terrain As Movement Constraint

The engine checks terrain with helpers such as `path_touches_terrain`:

```c
static bool path_touches_terrain(const game_t *game, float x1, float y1, float x2, float y2, terrain_kind_t kind) {
    for (int index = 0; index < game->zone_count; index += 1) {
        const zone_t *zone = &game->zones[index];
        if (zone->kind != kind) {
            continue;
        }
        if (segment_intersects_rect(x1, y1, x2, y2, zone->rect)) {
            return true;
        }
    }
    return false;
}
```

This helper lets movement rules ask whether a line from origin to destination crosses a zone. `game_move_unit` uses it to reject impassable crossings and to trigger difficult-terrain behavior. Deployment uses a degenerate path from a point to itself to check whether the placement point is inside impassable terrain.

The choice of rectangular terrain is pragmatic. It is easy to render, easy to test, and easy to intersect with movement segments. More complex terrain polygons may be desirable later, but rectangles are enough for bocage, minefields, ridges, ruins, and shell-hole fields in the current demo. If polygons are added, they should replace or extend the engine helper rather than making the UI decide terrain interactions.

## Legal Placement

Placement is more than board bounds. The helper `can_place_unit_at` checks boundaries, impassable terrain, enemy separation, and friendly overlap:

```c
static bool can_place_unit_at(const game_t *game, const unit_t *unit, float x, float y, int ignore_unit_id) {
    if (x < unit->footprint_radius || y < unit->footprint_radius || x > DZW_BOARD_WIDTH - unit->footprint_radius || y > DZW_BOARD_HEIGHT - unit->footprint_radius) {
        return false;
    }

    if (path_touches_terrain(game, x, y, x, y, DZW_TERRAIN_IMPASSABLE)) {
        return false;
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        const unit_t *other = &game->units[index];
        if (other->destroyed || other->id == unit->id || other->id == ignore_unit_id || unit_is_embarked(other)) {
            continue;
        }

        float separation = dzw_distance(x, y, other->x, other->y) - unit->footprint_radius - other->footprint_radius;
        if (other->owner != unit->owner && separation < 1.0f) {
            return false;
        }
        if (other->owner == unit->owner && separation < 0.25f) {
            return false;
        }
    }

    return true;
}
```

This function is used by disembarkation and legal movement helpers. It encodes a physical model of the table: units have footprints, enemies require spacing, friendly units cannot overlap, and impassable terrain is truly impassable. That model is what makes the board feel like a tactical surface.

The `ignore_unit_id` parameter is an important detail. Some moves or placements must consider a unit's current transport or target as a special case. Rather than duplicate placement logic with exceptions, the helper accepts one unit to ignore. This keeps collision logic centralized.

## Disembarkation And The Board

Transport disembarkation is one of the clearest places where board geometry and unit rules meet. The engine must place a passenger near the transport, avoid illegal overlap, avoid impassable terrain, and keep the passenger within the board. The helper `find_disembark_position` searches around the transport using facing-relative offsets and increasing clearance.

This is a good example of engine-owned physical reasoning. The UI cannot simply place the passenger next to the token visually. It does not know enough about legal positions, enemy spacing, or terrain. The engine searches, chooses, and logs the outcome. The UI reloads.

If future rules add deployment zones, reserve entry, towing, or objective pickup, they should follow the same pattern. Let the engine decide legal placement. Let the board show the result.

## Objective Data Shape

Objectives are smaller than terrain zones but more important to victory:

```c
typedef struct {
    int id;
    const char *name;
    float x;
    float y;
    float radius;
} objective_t;
```

The public objective view adds control and presence:

```c
typedef struct {
    int id;
    const char *name;
    float x;
    float y;
    float radius;
    player_t controller;
    int player_one_presence;
    int player_two_presence;
} objective_view_t;
```

The split is useful. The underlying objective has position and radius. The view includes calculated control state. The app should display who controls an objective, but it should not calculate control independently. The engine owns the scoring logic.

`ObjectiveSnapshot.statusText` turns those fields into readable display. It can say contested, controlled by Player 1, controlled by Player 2, or unclaimed. The UI can then draw color and text from engine-calculated state.

## Mission State

Mission state includes name, target score, player scores, and winner. The default mission is `Bocage Breakout`. The view is compact:

```c
typedef struct {
    const char *name;
    int target_score;
    int player_one_score;
    int player_two_score;
    player_t winner;
} mission_view_t;
```

This is enough for the app header to show current score, leader, and winner. It is also enough for tests to assert score changes. The mission system is intentionally simple for the playable demo: objectives generate points, a target score decides victory, and the engine reports a winner.

Future scenarios may want more victory conditions. They might add turn limits, asymmetric objectives, exit points, preservation bonuses, or historical victory bands. Those should enter through engine mission state if they affect scoring, or historical scenario metadata if they are briefing-only. The distinction matters. A victory condition that changes who wins is engine truth. A paragraph explaining historical context is scenario content.

## Drawing Terrain And Objectives

The board view renders terrain and objectives from snapshots:

```swift
ForEach(controller.zones) { zone in
    terrainShape(for: zone, in: geometry.size)
}

ForEach(controller.objectiveStates) { objective in
    objectiveMarker(objective, in: geometry.size)
}
```

The terrain shape chooses fill color by terrain kind and draws a dashed outline if line of sight is blocked. The objective marker chooses color based on contested or controlled state, draws a dashed radius, and labels the objective. The visual language is tightly coupled to snapshots, not to hard-coded scenario assumptions.

This lets scenario modules change board data without rewriting the board renderer. A new scenario can provide different terrain names and objective positions. The app will draw them because the renderer cares about generic zones and objectives.

## Grid And Scale

`BattleBoardView` draws a full grid based on board width and height. This is not only visual texture. It gives the player a rough measure of distance. Movement allowances, weapon ranges, and assault reach are all measured, so a visible grid helps players plan.

The grid is generated from board dimensions:

```swift
let columns = Int(GameController.boardWidth)
let rows = Int(GameController.boardHeight)

for column in 0...columns {
    let x = size.width * CGFloat(column) / GameController.boardWidth
    path.move(to: CGPoint(x: x, y: 0))
    path.addLine(to: CGPoint(x: x, y: size.height))
}
```

This keeps grid spacing aligned with rules inches. If board size changes, the grid adapts. If zoom changes, the grid scales with the board. A future measurement overlay should use the same coordinate basis.

## Deployment Flow

Deployment mode deserves emphasis because it is a separate relationship between UI and engine. The player can drag units and rotate them before battle. The engine allows this through deployment commands. It still rejects illegal placement.

The result is a playable pre-battle ritual. The player sees the same board that will be used for combat, arranges units with the same coordinates that rules will use, and begins battle when ready. This is more satisfying than spawning units in fixed positions and more honest than allowing arbitrary visual placement.

Tests cover deployment movement and rotation precisely because this mode is easy to break. If a deployment move accidentally consumes normal movement, the first turn becomes wrong. If deployment bypasses impassable terrain, the battle can start in an illegal state. The tests protect both freedom and legality.

## Scenario Board Application

The engine includes `game_apply_guderian_scenario_board`, which lets scenario modules provide mission name, target score, terrain zones, and objectives. The public scenario structs use C-friendly data:

```c
typedef struct {
    int id;
    const char *name;
    terrain_kind_t kind;
    rect_t rect;
    int cover_save;
    bool blocks_line_of_sight;
    bool hull_down;
} guderian_scenario_zone_t;

typedef struct {
    int id;
    const char *name;
    float x;
    float y;
    float radius;
} guderian_scenario_objective_t;
```

This is a narrow hook. A scenario can reshape the battlefield, but it still feeds the same engine zone and objective concepts. The core does not need to understand the campaign's narrative to make terrain block line of sight. The scenario layer does not need to reimplement movement to place a minefield.

That narrowness is healthy. It allows scenario growth without rules duplication.

## Adding New Battlefield Features

New battlefield features should be sorted by whether they affect rules.

A named town, historical road label, briefing arrow, or phase line may belong in historical metadata or UI overlay. It can enrich the player's understanding without changing legality. A minefield that damages units, a river that blocks vehicles, a bridge that controls movement, or a smoke screen that blocks line of sight belongs in engine state and view structs.

If a feature affects rules, define:

- its data shape,
- how it is loaded or generated,
- how it affects movement, shooting, assault, or scoring,
- how the UI displays it,
- how tests prove it.

Do not add rule terrain as an image-only overlay. The player will trust the board. If it looks like terrain, its mechanical meaning should be clear.

## The Chapter's Rule Of Thumb

The battlefield is a measured argument. Every unit, zone, objective, radius, and drag point should mean the same thing to the engine and the player. When the board lies, the game becomes frustrating. When the board and rules agree, the player can think tactically. That agreement is the goal of the terrain, objective, deployment, and scenario board code.

## Line Of Sight And Fire Planning

Terrain also participates in shooting. A zone can block line of sight, and most direct-fire weapons must respect that. Barrage weapons are the major exception. This distinction lets mortars and artillery-style weapons feel different from rifles, machine guns, or tank guns. It also gives terrain a tactical role beyond movement friction.

The important design point is that line of sight is an engine question. The UI may eventually draw a firing line or highlight blockers, but the engine must decide whether a shot is legal. `game_shoot_unit` checks line of sight after it has selected weapon behavior and before it resolves damage. If a weapon is not barrage and terrain blocks the line, the command fails with an explanation.

This keeps visual assistance optional. A future overlay can help the player understand why a shot will fail, but the shot cannot succeed merely because a line looked clear on screen. The board renderer and engine should continue to converge, but legality remains in C.

## Cover And Hull-Down State

Terrain zones carry `cover_save` and `hull_down`, but the game also allows manual cover and hull-down toggles. This is a practical concession to tabletop play. A rectangular zone can represent a farmhouse, ridge, or shell-hole field, but players may need to mark a unit's local posture or scenario-specific protection. The engine stores manual flags and exposes `in_cover` and `hull_down` through `unit_view_t`.

The UI controls for manual cover and hull down are not rule engines. They call `game_toggle_cover` and `game_toggle_hull_down`. The engine logs the change and updates snapshots. This keeps even manual state inside the authoritative model.

When adding more terrain-derived defensive effects, be careful not to make manual toggles contradict terrain. A good rule is that automatic terrain and manual posture should combine through engine functions such as `cover_save_for_unit`, not through UI assumptions. The player should not have to know whether a bonus came from a zone, a toggle, a scenario rule, or smoke. The engine should expose the resulting state.

## Objective Presence And Unit Footprints

Objectives use radii, and units use footprints. Control should be understood in terms of physical presence, not just unit center points. The engine can count which units are close enough to matter and expose presence counts. The UI can then show contested or controlled state.

This is another reason footprint radius matters. A vehicle token and an infantry token are not identical points. Their physical size affects movement separation, assault contact, and potentially objective presence. Even if some current calculations use center distance in simplified ways, the data model is ready for footprint-aware rules.

Future objective rules might distinguish infantry scoring from vehicle contesting, require non-embarked units, ignore falling-back units, or give extra value to specific unit kinds. Those rules should be centralized in the scoring logic. The objective view can grow if the UI needs more detail, but the controller should not calculate victory independently.

## Battle Pacing Through Objectives

The current mission target score gives the battle a pacing mechanism. Objectives create reasons to move. Without objectives, a small demo can devolve into static shooting. With objectives, movement, transports, smoke, terrain, and assault all become meaningful. A player may need to leave cover to contest a point. A transport may matter because it can move infantry toward the road junction. A mortar may matter because it can pin objective holders.

This is why objectives are not just score counters. They connect all other systems. Board geometry matters because objectives have positions. Army catalogues matter because force composition affects objective ability. Turn sequencing matters because scoring happens at a predictable point. AI matters because it prioritizes objectives when moving. UI matters because objective markers give the player goals at a glance.

When designing new scenarios, objectives should be placed to create decisions. If all objectives are safe in deployment zones, movement is unnecessary. If all objectives are in one cluster, the board shrinks tactically. If objectives are too far apart for available movement, the game may feel sluggish. Scenario board design is therefore rules design.

## Map Readability

The board view uses color, labels, dashed outlines, objective rings, and unit badges to keep the battlefield readable. Readability is part of mechanics. If the player cannot distinguish impassable terrain from difficult terrain, or controlled objectives from contested ones, the rules may be correct but the experience will fail.

The current board uses a restrained set of visual signals:

- terrain fill changes by kind,
- line-of-sight blockers use dashed strokes,
- objectives use color and numbered markers,
- selected units get a stronger stroke,
- vehicles and infantry have different shapes,
- smoke is a visible ring,
- transports and assault guns get compact badges.

These choices should stay connected to rules. A new visual badge should mean something. A new terrain color should correspond to a rule or clear scenario distinction. Decorative complexity can make tactical reading harder.

## Historical Map Adaptation

Historical battles rarely fit a rectangular skirmish board perfectly. The historical module solves this by representing map elements, deployment zones, objectives, and notes as structured scenario data. The playable board then becomes an adaptation, not a literal reproduction. Roads, rivers, ridges, towns, forests, bridges, minefields, objectives, and phase lines can be represented at the level needed for play.

The adaptation process should preserve the tactical question of the historical situation. If a battle was about crossing a river, the playable board needs a river or bridge mechanic. If it was about a ridge, the board needs hull-down or line-of-sight meaning. If it was about a road junction, objectives and movement lanes should make that junction matter. Historical labels alone are not enough.

This is where the scenario module and core engine meet. The scenario module can say "this is the important ridge." The engine needs terrain concepts that make the ridge matter. If the existing terrain vocabulary cannot represent the important feature, extend the engine rather than hiding the feature in text.

## Testing Battlefield Changes

Battlefield changes should be tested at several levels. Core tests can assert terrain counts, objective names, mission target score, initial control, movement rejection through impassable terrain, difficult terrain behavior, deployment legality, and scoring. UI tests can assert that deployment shows the board, tokens can be dragged, phases advance, and objective or phase labels remain visible. Scenario tests can assert that historical maps have required elements and deployment zones.

Good terrain tests do not need a full game. A small skirmish with one unit and one terrain zone can prove a rule. Good objective tests should move or create units in positions that change control and then advance phases to score. Good UI tests should not rely on exact pixel colors, but they can rely on accessibility identifiers and visible controls.

Tests are especially important for board code because visual regressions can feel like rule bugs. If a drag no longer maps to the correct coordinate, the engine may reject moves that seem legal. If the board aspect ratio changes, terrain and objectives may appear misplaced. If an accessibility identifier disappears, UI tests lose the ability to play the game.

## Future Board Features

Several future features would fit naturally into the current model:

- deployment zone overlays,
- range and movement rulers,
- line-of-sight previews,
- objective control heat markers,
- scenario phase lines,
- bridge or road movement modifiers,
- minefield triggers,
- smoke clouds as temporary zones,
- wrecks as new terrain after vehicle destruction.

Each feature should be classified before implementation. A ruler can be UI-only because it helps the player measure. A minefield trigger must be engine-owned because it changes casualties and movement. A wreck that blocks line of sight or movement must become engine terrain or obstacle state. A phase line that only appears in a briefing may stay scenario metadata.

The current board architecture can absorb these features if the distinction is kept clear.

## Final Battlefield Note

The board is where the player most directly meets the rules. A click, drag, target selection, or objective marker is tactile in a way that catalogue data is not. That makes board truth emotionally important. When a player drags a unit, the result should feel explainable. When a shot is blocked, the board should help them understand. When an objective changes control, the marker should make it obvious. The engine and UI share responsibility for that feeling, but the engine owns the facts.
