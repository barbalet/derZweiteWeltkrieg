# World War II Battlefield Profiles

This ledger records the active demo battlefield identity and the Wikipedia source shelf used for scenario names, terrain language, and objective assets.

## Bocage Breakout

The playable demo mission is `Bocage Breakout`, a compact Allies-vs-Axis action inspired by the Normandy breakout fighting after the Allied landings. The scenario is not a simulation of a named historical engagement; it uses historically grounded battlefield features and the game's movement, shooting, vehicle, transport, artillery, objective-control, and victory systems.

### Source Anchors

- [Operation Overlord](https://en.wikipedia.org/wiki/Battle_of_Normandy): Normandy campaign frame, Allied-vs-Axis context, and breakout operations after the beachhead.
- [Bocage](https://en.wikipedia.org/wiki/Bocage): Normandy hedgerow terrain, restricted visibility, and slow progress through enclosed fields.
- [Operation Cobra](https://en.wikipedia.org/wiki/Operation_Cobra): breakout framing and supply pressure while Allied reinforcement and supply depended heavily on the beachhead.
- [Military logistics](https://en.wikipedia.org/wiki/Military_logistics): modern armies' dependence on ammunition depots, fuel, spare parts, and regular replenishment.
- [Land mine](https://en.wikipedia.org/wiki/Minefield): World War II mine and minefield use as defensive obstacles against infantry and vehicles.
- [Artillery observer](https://en.wikipedia.org/wiki/Artillery_observer): observation posts and forward observers directing artillery and mortar fire support.

### Battlefield Mapping

| Demo Element | Engine Role | WWII Rationale |
| --- | --- | --- |
| `Bocage Breakout` | Mission name, 8 VP target | A small breakout action over road access and supplies after the Normandy beachhead phase. |
| `Ruined Farmhouse` | Difficult terrain, blocks line of sight, cover 5+ | Farm and village ruins give infantry cover and break fire lanes. |
| `Bocage Ridge` | Open terrain with hull-down protection, cover 5+ | Hedgerow banks and low ridges create protected firing positions for vehicles and guns. |
| `Shell-Hole Field` | Difficult terrain, cover 6+ | Artillery-scarred ground slows troops and offers partial cover. |
| `Marked Minefield` | Impassable terrain | A defensive obstacle that denies movement through a dangerous approach. |
| `Ammunition Cache` | Objective 1 | Replenishment point tied to ammunition-heavy modern operations. |
| `Observation Post` | Objective 2 | Forward observation asset for directing artillery and mortar fire. |
| `Road Junction` | Objective 3 | Mobility and supply-control point for a breakout scenario. |
| `Fuel Dump` | Objective 4 | Fuel objective supporting mechanized forces and armored movement. |

### Active Demo Contract

- The mission remains score-based: 1 VP per controlled objective at the end of each player's turn.
- The terrain defines movement, cover, line of sight, hull-down, and impassable checks for the active scenario.
- The scenario names must appear consistently in the C engine, SwiftUI board, command-line output, saved-operation replay path, and tests.
