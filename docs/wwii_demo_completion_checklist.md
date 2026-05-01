# derZweiteWeltkrieg Demo Completion Checklist

The World War II demo is playable.

## Playable Entry Points

- The SwiftUI app opens on operation setup with British forces selected and a ready Axis opponent draft.
- The setup screen supports British, American, Australian, Soviet, German, and Italian force building.
- Every setup nation shows its Allies or Axis classification.
- The player can deploy, begin battle, move, shoot, use transports, resolve vehicle damage, fight assaults, score objectives, and reach victory.
- The command-line target drafts one Allied force and one Axis force, then prints a World War II battle report.

## Active Content

- Product name, package name, app title, command-line title, tests, and README use `derZweiteWeltkrieg`.
- The active mission is `Bocage Breakout`.
- Terrain and objectives use World War II battlefield language.
- Army catalogs contain the six supported World War II nations.
- Catalog entries carry source notes that point back to the Wikipedia-backed research ledgers.
- Roster factories use nation-appropriate small arms and transport weapons for the playable demo armies.
- Weapon balance values are covered by deterministic profile tests.

## Verification

- `swift test` passes.
- `swift build` passes.
- The command-line Xcode scheme builds.
- The macOS app Xcode scheme builds.
- Documentation describes `derZweiteWeltkrieg` as a World War II game.
