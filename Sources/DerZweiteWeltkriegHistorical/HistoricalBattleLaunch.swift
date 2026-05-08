import DerZweiteWeltkriegCore
import Foundation

public enum HistoricalController: String, Codable, Hashable, Sendable {
    case human = "Human"
    case ai = "AI"
}

public enum HistoricalEnginePlayerSlot: String, Codable, Hashable, Sendable {
    case playerOne = "Player one"
    case playerTwo = "Player two"

    public var enginePlayer: player_t {
        switch self {
        case .playerOne:
            return DZW_PLAYER_ONE
        case .playerTwo:
            return DZW_PLAYER_TWO
        }
    }
}

public struct HistoricalEngineSideBinding: Identifiable, Codable, Hashable, Sendable {
    public var id: String { sideID }

    public let sideID: String
    public let enginePlayerSlot: HistoricalEnginePlayerSlot
    public let controller: HistoricalController

    public init(
        sideID: String,
        enginePlayerSlot: HistoricalEnginePlayerSlot,
        controller: HistoricalController
    ) {
        self.sideID = sideID
        self.enginePlayerSlot = enginePlayerSlot
        self.controller = controller
    }
}

public struct HistoricalBattleLaunch<ID: HistoricalBattleID>: Codable, Hashable, Sendable {
    public let battleID: ID
    public let chosenHumanSideID: String
    public let seed: UInt32
    public let sideBindings: [HistoricalEngineSideBinding]

    public init(
        battleID: ID,
        chosenHumanSideID: String,
        seed: UInt32,
        sideBindings: [HistoricalEngineSideBinding]
    ) {
        self.battleID = battleID
        self.chosenHumanSideID = chosenHumanSideID
        self.seed = seed
        self.sideBindings = sideBindings
    }

    public var humanBinding: HistoricalEngineSideBinding? {
        sideBindings.first { $0.controller == .human }
    }

    public var aiBinding: HistoricalEngineSideBinding? {
        sideBindings.first { $0.controller == .ai }
    }

    public var humanSideID: String? {
        humanBinding?.sideID
    }

    public var aiSideID: String? {
        aiBinding?.sideID
    }

    public func binding(for sideID: String) -> HistoricalEngineSideBinding? {
        sideBindings.first { $0.sideID == sideID }
    }

    public func controller(for sideID: String) -> HistoricalController? {
        binding(for: sideID)?.controller
    }

    public func enginePlayerSlot(for sideID: String) -> HistoricalEnginePlayerSlot? {
        binding(for: sideID)?.enginePlayerSlot
    }
}

public struct HistoricalBattleSideSelection<ID: HistoricalBattleID>: Codable, Hashable, Sendable {
    public let scenario: HistoricalBattleScenario<ID>
    public let launch: HistoricalBattleLaunch<ID>

    public init(
        scenario: HistoricalBattleScenario<ID>,
        launch: HistoricalBattleLaunch<ID>
    ) {
        self.scenario = scenario
        self.launch = launch
    }

    public var selectedSide: HistoricalSideOption? {
        scenario.sideOption(id: launch.chosenHumanSideID)
    }

    public var opposingSide: HistoricalSideOption? {
        launch.aiSideID.flatMap { scenario.sideOption(id: $0) } ??
            scenario.opposingSideOption(to: launch.chosenHumanSideID)
    }

    public var selectedSideTitle: String {
        selectedSide?.title ?? launch.chosenHumanSideID
    }

    public var opposingSideTitle: String {
        opposingSide?.title ?? launch.aiSideID ?? ""
    }

    public var humanEnginePlayerSlot: HistoricalEnginePlayerSlot? {
        launch.humanBinding?.enginePlayerSlot
    }

    public var aiEnginePlayerSlot: HistoricalEnginePlayerSlot? {
        launch.aiBinding?.enginePlayerSlot
    }
}

public extension HistoricalBattleScenario {
    func sideOption(id sideID: String) -> HistoricalSideOption? {
        sideOptions.first { $0.id == sideID }
    }

    func opposingSideOption(to sideID: String) -> HistoricalSideOption? {
        sideOptions.first { $0.id != sideID }
    }

    func resolvedSideSelection(
        for launch: HistoricalBattleLaunch<ID>
    ) -> HistoricalBattleSideSelection<ID> {
        HistoricalBattleSideSelection(scenario: self, launch: launch)
    }
}

public enum HistoricalSideSelectionError: Error, Equatable, CustomStringConvertible {
    case scenarioNeedsExactlyTwoSides(String, actualCount: Int)
    case unknownSide(String)
    case duplicateSideIDs(String)

    public var description: String {
        switch self {
        case .scenarioNeedsExactlyTwoSides(let battleID, let actualCount):
            return "Historical battle \(battleID) needs exactly two side options; found \(actualCount)."
        case .unknownSide(let sideID):
            return "Unknown historical side option: \(sideID)."
        case .duplicateSideIDs(let battleID):
            return "Historical battle \(battleID) has duplicate side IDs."
        }
    }
}

public enum HistoricalBattleLaunchResolver {
    public static func makeLaunch<ID: HistoricalBattleID>(
        scenario: HistoricalBattleScenario<ID>,
        chosenHumanSideID: String,
        seed: UInt32,
        humanSlot: HistoricalEnginePlayerSlot = .playerOne
    ) throws -> HistoricalBattleLaunch<ID> {
        guard scenario.sideOptions.count == 2 else {
            throw HistoricalSideSelectionError.scenarioNeedsExactlyTwoSides(
                scenario.id.rawValue,
                actualCount: scenario.sideOptions.count
            )
        }

        let sideIDs = scenario.sideOptions.map(\.id)
        guard Set(sideIDs).count == sideIDs.count else {
            throw HistoricalSideSelectionError.duplicateSideIDs(scenario.id.rawValue)
        }

        guard sideIDs.contains(chosenHumanSideID) else {
            throw HistoricalSideSelectionError.unknownSide(chosenHumanSideID)
        }

        let aiSlot: HistoricalEnginePlayerSlot = humanSlot == .playerOne ? .playerTwo : .playerOne
        let bindings = scenario.sideOptions.map { side in
            HistoricalEngineSideBinding(
                sideID: side.id,
                enginePlayerSlot: side.id == chosenHumanSideID ? humanSlot : aiSlot,
                controller: side.id == chosenHumanSideID ? .human : .ai
            )
        }

        return HistoricalBattleLaunch(
            battleID: scenario.id,
            chosenHumanSideID: chosenHumanSideID,
            seed: seed,
            sideBindings: bindings
        )
    }
}
