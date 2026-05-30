# derZweiteWeltkrieg Book

This directory is a source-oriented book for `derZweiteWeltkrieg`, modeled after the narrative developer documentation style in the [APESDK book](https://github.com/barbalet/apesdk/tree/master/book). It explains the rationale and logic of the game as it exists in this repository: a World War 2 tabletop wargame with an order-dice C rules engine, a SwiftUI command surface, playable setup flow, AI opponent, scenario extensions, and tests.

The book is written for maintainers who need to change the game without losing the design intent. Each chapter points to the files that embody the idea being described.

## Contents

- [Synopsis](synopsis.md)
- [Chapter 1: The Shape Of The Game](chapter_01.md)
- [Chapter 2: The C Contract](chapter_02.md)
- [Chapter 3: Armies And Catalogues](chapter_03.md)
- [Chapter 4: Units, Profiles, Weapons, And Vehicles](chapter_04.md)
- [Chapter 5: Battlefield, Terrain, And Objectives](chapter_05.md)
- [Chapter 6: The Turn Engine](chapter_06.md)
- [Chapter 7: Combat And Damage Resolution](chapter_07.md)
- [Chapter 8: Setup, AI, And Replay](chapter_08.md)
- [Chapter 9: The SwiftUI Battlefield](chapter_09.md)
- [Chapter 10: Historical Modules, Tests, And Extension Discipline](chapter_10.md)

## Fast Source Map

- Package boundary: [`../Package.swift`](../Package.swift)
- C public API: [`../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h`](../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h)
- C rules engine: [`../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`](../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c)
- Swift snapshots: [`../Sources/DerZweiteWeltkriegApp/Bridge/GameSnapshots.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/GameSnapshots.swift)
- Skirmish persistence models: [`../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/SkirmishModels.swift)
- App controller: [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift)
- Controller actions and AI: [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift)
- Board view: [`../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift`](../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift)
- Setup screen: [`../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift`](../Sources/DerZweiteWeltkriegApp/Shell/SkirmishSetupView.swift)
- Order-dice rules model: [`../docs/order_dice_rules_model.md`](../docs/order_dice_rules_model.md)
- Downstream migration notes: [`../docs/order_dice_migration_guderian_monty.md`](../docs/order_dice_migration_guderian_monty.md)
- Cycle-200 acceptance closeout: [`../docs/order_dice_acceptance_closeout.md`](../docs/order_dice_acceptance_closeout.md)
- Unit and integration tests: [`../Tests/DerZweiteWeltkriegTests/DerZweiteWeltkriegTests.swift`](../Tests/DerZweiteWeltkriegTests/DerZweiteWeltkriegTests.swift)
- UI tests: [`../Tests/DerZweiteWeltkriegUITests/DerZweiteWeltkriegUITests.swift`](../Tests/DerZweiteWeltkriegUITests/DerZweiteWeltkriegUITests.swift)
