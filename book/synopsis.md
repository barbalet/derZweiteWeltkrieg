# Synopsis

`derZweiteWeltkrieg` is built as a playable World War 2 tabletop battle, not as a loose visual prototype. The code treats the battle as a rules simulation first and a SwiftUI experience second. The C target owns the board, units, weapons, phases, dice, logs, error messages, and resolution state. The Swift target owns presentation, setup, selection, saving, loading, AI scheduling, and interaction ergonomics.

That division is the central design choice of the project. It lets the same combat model be reached from unit tests, command-line reports, historical scenario adapters, campaign modules, and the app UI. A change to how infantry, vehicles, objectives, or pending combat choices behave should usually begin in the C engine. A change to how the player sees or triggers an action should usually begin in the SwiftUI layer.

## Reader Path

The first two chapters define the architecture. Chapter 1 explains why the repository is split into a small number of targets and why the app does not directly own combat truth. Chapter 2 explains the public C header as the contract between the engine and everything else.

The next three chapters describe the data model. Chapter 3 covers the Allied and Axis army catalogues, force presets, and point selections. Chapter 4 follows individual units through profiles, weapons, armor values, transports, and mixed-profile casualty groups. Chapter 5 explains why the board is small, fixed, measurable, and objective driven.

Chapters 6 and 7 are the rules chapters. They cover turn sequencing, movement, shooting, assault, pending decisions, morale, vehicle damage, fire arcs, and the cost of carrying tabletop-like logic in a deterministic C engine.

Chapters 8 and 9 move up the stack. Chapter 8 covers setup, AI opponent drafting, battle recording, save/load, and why replayable actions matter. Chapter 9 describes the SwiftUI battlefield surface, the board coordinate mapping, panel windows, accessibility identifiers, and how the UI stays connected to snapshots instead of private engine memory.

Chapter 10 closes with the historical/campaign modules, tests, and the extension discipline used by this codebase. It is the chapter to read before adding a new nation, campaign scenario, weapon class, or UI workflow.

## Evidence Source Map

The most important source files are:

- [`../Package.swift`](../Package.swift), which defines the reusable C engine, Swift app UI, historical module, Guderian module, app host, test app, and test target.
- [`../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h`](../Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h), which is the public engine boundary.
- [`../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c`](../Sources/DerZweiteWeltkriegCore/der_Zweite_Weltkrieg.c), which implements weapons, army catalogues, units, terrain, movement, shooting, assault, scoring, logging, and engine state.
- [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift), which owns the engine handle and publishes Swift snapshots.
- [`../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift`](../Sources/DerZweiteWeltkriegApp/ViewModel/GameController+Skirmish.swift), which starts battles, saves and loads JSON, records actions, builds AI plans, and runs the AI turn.
- [`../Sources/DerZweiteWeltkriegApp/Bridge/GameSnapshots.swift`](../Sources/DerZweiteWeltkriegApp/Bridge/GameSnapshots.swift), which converts C views into Swift value types.
- [`../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift`](../Sources/DerZweiteWeltkriegApp/Board/BattleBoardView.swift), which maps the rules board into an interactive SwiftUI board.
- [`../Sources/DerZweiteWeltkriegHistorical/HistoricalBattleContracts.swift`](../Sources/DerZweiteWeltkriegHistorical/HistoricalBattleContracts.swift), which defines historical scenario contracts.
- [`../Sources/DerZweiteWeltkriegGuderian/GuderianModuleBoundary.swift`](../Sources/DerZweiteWeltkriegGuderian/GuderianModuleBoundary.swift), which documents the local scenario integration boundary.

## How To Use This Book

Read the chapters linearly if you are new to the project. If you are making a specific change, use the chapters as entry points:

- Adding a unit or army list: start with Chapter 3, then Chapter 4.
- Changing movement, shooting, assault, or victory scoring: start with Chapter 6 or Chapter 7.
- Changing setup, saving, loading, or AI: start with Chapter 8.
- Changing the board or UI affordances: start with Chapter 9.
- Adding a historical scenario or campaign layer: start with Chapter 10.

The book deliberately describes the game as its own World War 2 codebase. It does not depend on a prior identity or earlier theme to explain why the present code exists.

