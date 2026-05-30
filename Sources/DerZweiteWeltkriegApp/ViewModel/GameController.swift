import Foundation
import CoreGraphics
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

struct GameControllerLoadedForceState: Equatable, Sendable {
    var playerOneArmy: army_list_t
    var playerOneForceIndex: Int
    var playerTwoArmy: army_list_t
    var playerTwoForceIndex: Int

    init(
        playerOneArmy: army_list_t = DZW_ARMY_BRITISH,
        playerOneForceIndex: Int = 0,
        playerTwoArmy: army_list_t = DZW_ARMY_GERMAN,
        playerTwoForceIndex: Int = 0
    ) {
        self.playerOneArmy = playerOneArmy
        self.playerOneForceIndex = playerOneForceIndex
        self.playerTwoArmy = playerTwoArmy
        self.playerTwoForceIndex = playerTwoForceIndex
    }
}

struct GameControllerSetupSelectionState: Equatable, Sendable {
    var playerOneArmyID: String
    var playerOneForceIndex: Int
    var playerTwoArmyID: String
    var playerTwoForceIndex: Int

    init(
        playerOneArmyID: String = "",
        playerOneForceIndex: Int = 0,
        playerTwoArmyID: String = "",
        playerTwoForceIndex: Int = 0
    ) {
        self.playerOneArmyID = playerOneArmyID
        self.playerOneForceIndex = playerOneForceIndex
        self.playerTwoArmyID = playerTwoArmyID
        self.playerTwoForceIndex = playerTwoForceIndex
    }
}

struct GameControllerBoardSelectionState: Equatable, Sendable {
    var selectedUnitID: Int?
    var selectedTargetID: Int?

    init(selectedUnitID: Int? = nil, selectedTargetID: Int? = nil) {
        self.selectedUnitID = selectedUnitID
        self.selectedTargetID = selectedTargetID
    }
}

@MainActor
final class GameController: ObservableObject, @unchecked Sendable {
    static let boardWidth = CGFloat(game_board_width())
    static let boardHeight = CGFloat(game_board_height())

    @Published var appMode: AppMode = .setup
    @Published private(set) var armyReferences: [ArmyReference] = ArmyReferenceCatalog.load()
    @Published private(set) var game = GameSnapshot(turnNumber: 0, activePlayer: DZW_PLAYER_ONE, phase: DZW_PHASE_MOVEMENT, ruleset: DZW_RULESET_FIXED_PHASES)
    @Published private(set) var mission = MissionSnapshot()
    @Published private(set) var units: [UnitSnapshot] = []
    @Published private(set) var zones: [ZoneSnapshot] = []
    @Published private(set) var objectiveStates: [ObjectiveSnapshot] = []
    @Published private(set) var logs: [String] = []
    @Published private(set) var lastError: String = ""
    @Published private(set) var pendingWeaponDestroyChoice: PendingWeaponDestroyChoiceSnapshot?
    @Published private(set) var pendingHitAllocationChoice: PendingHitAllocationChoiceSnapshot?
    @Published private(set) var loadedForces = GameControllerLoadedForceState()
    @Published private(set) var setupSelection = GameControllerSetupSelectionState()
    @Published private(set) var boardSelection = GameControllerBoardSelectionState()
    @Published var resumableAppMode: AppMode = .deployment
    @Published var currentBattleConfiguration: SkirmishConfiguration?
    @Published var currentOpponentPlan: GeneratedOpponentPlan?
    @Published var isAITurnInProgress: Bool = false
    @Published var setupMessage: String = ""
    @Published var playerUnitCounts: [Int: Int] = [:]
    @Published var pointsLimit: Int = 750
    @Published var seedText: String = "1944"

    nonisolated(unsafe) let handle: OpaquePointer
    var recordedActions: [RecordedBattleAction] = []
    var aiTask: Task<Void, Never>?
    var isReplayingBattle: Bool = false

    var loadedPlayerOneArmy: army_list_t { loadedForces.playerOneArmy }
    var loadedPlayerOneForceIndex: Int { loadedForces.playerOneForceIndex }
    var loadedPlayerTwoArmy: army_list_t { loadedForces.playerTwoArmy }
    var loadedPlayerTwoForceIndex: Int { loadedForces.playerTwoForceIndex }

    var selectedUnitID: Int? {
        get { boardSelection.selectedUnitID }
        set { boardSelection.selectedUnitID = newValue }
    }

    var selectedTargetID: Int? {
        get { boardSelection.selectedTargetID }
        set { boardSelection.selectedTargetID = newValue }
    }

    var playerOneArmyID: String {
        get { setupSelection.playerOneArmyID }
        set { setupSelection.playerOneArmyID = newValue }
    }

    var playerOneForceIndex: Int {
        get { setupSelection.playerOneForceIndex }
        set { setupSelection.playerOneForceIndex = newValue }
    }

    var playerTwoArmyID: String {
        get { setupSelection.playerTwoArmyID }
        set { setupSelection.playerTwoArmyID = newValue }
    }

    var playerTwoForceIndex: Int {
        get { setupSelection.playerTwoForceIndex }
        set { setupSelection.playerTwoForceIndex = newValue }
    }

    init(seed: UInt32 = 1_944) {
        guard let handle = game_create_demo_with_forces(seed, DZW_ARMY_BRITISH, 0, DZW_ARMY_GERMAN, 0) else {
            fatalError("Failed to allocate derZweiteWeltkrieg demo game.")
        }
        self.handle = handle
        initializeSetupSelections()
        reload()
    }

    deinit {
        aiTask?.cancel()
        game_destroy(handle)
    }

    func reload() {
        let gameView = game_view(handle)
        game = GameSnapshot(
            turnNumber: Int(gameView.turn_number),
            activePlayer: gameView.active_player,
            phase: gameView.phase,
            ruleset: gameView.ruleset
        )
        mission = MissionSnapshot(raw: game_mission_view(handle))
        loadedForces = GameControllerLoadedForceState(
            playerOneArmy: game_player_army(handle, DZW_PLAYER_ONE),
            playerOneForceIndex: Int(game_player_force(handle, DZW_PLAYER_ONE)),
            playerTwoArmy: game_player_army(handle, DZW_PLAYER_TWO),
            playerTwoForceIndex: Int(game_player_force(handle, DZW_PLAYER_TWO))
        )

        units = (0..<Int(game_unit_count(handle))).map { index in
            UnitSnapshot(raw: game_unit_view(handle, Int32(index)))
        }
        zones = (0..<Int(game_zone_count(handle))).map { index in
            ZoneSnapshot(raw: game_zone_view(handle, Int32(index)))
        }
        objectiveStates = (0..<Int(game_objective_count(handle))).map { index in
            ObjectiveSnapshot(raw: game_objective_view(handle, Int32(index)))
        }
        logs = (0..<Int(game_log_count(handle))).map { index in
            String(cString: game_log_line(handle, Int32(index)))
        }
        pendingWeaponDestroyChoice = PendingWeaponDestroyChoiceSnapshot(handle: handle)
        pendingHitAllocationChoice = PendingHitAllocationChoiceSnapshot(handle: handle)

        let error = String(cString: game_last_error(handle))
        lastError = error

        if let selectedUnitID, !units.contains(where: { $0.id == selectedUnitID }) {
            self.selectedUnitID = nil
        }
        if let selectedTargetID, !units.contains(where: { $0.id == selectedTargetID }) {
            self.selectedTargetID = nil
        }
    }

    func reconcileForceSelections() {
        playerOneForceIndex = sanitizedForceIndex(playerOneForceIndex, for: playerOneArmy?.preset ?? DZW_ARMY_DEMO)
        playerTwoForceIndex = sanitizedForceIndex(playerTwoForceIndex, for: playerTwoArmy?.preset ?? DZW_ARMY_DEMO)
    }

    private func initializeSetupSelections() {
        armyReferences = ArmyReferenceCatalog.load()
        setupSelection = GameControllerSetupSelectionState(
            playerOneArmyID: preferredArmyID(named: "British") ?? armyReferences.first(where: { $0.allegiance == .allies })?.id ?? "",
            playerOneForceIndex: 0,
            playerTwoArmyID: preferredArmyID(named: "German") ?? armyReferences.first(where: { $0.allegiance == .axis })?.id ?? "",
            playerTwoForceIndex: 0
        )
        playerUnitCounts = defaultUnitCounts(for: playerOneArmy?.preset ?? DZW_ARMY_BRITISH)
        reconcileForceSelections()
        refreshOpponentPlan()
    }

    private func preferredArmyID(named name: String) -> String? {
        armyReferences.first(where: { $0.displayName == name })?.id
    }

    func armyReference(id: String) -> ArmyReference? {
        armyReferences.first(where: { $0.id == id })
    }

    func updatePlayerArmy(id: String) {
        guard playerOneArmyID != id else { return }
        playerOneArmyID = id
        playerUnitCounts = defaultUnitCounts(for: playerOneArmy?.preset ?? DZW_ARMY_BRITISH)
        setupMessage = ""
        refreshOpponentPlan()
    }

    func updatePointsLimit(_ value: Int) {
        pointsLimit = min(max(value, 250), 1500)
        setupMessage = ""
        refreshOpponentPlan()
    }

    func updatePlayerUnitCount(catalogID: Int, count: Int) {
        if count <= 0 {
            playerUnitCounts.removeValue(forKey: catalogID)
        } else {
            playerUnitCounts[catalogID] = count
        }
        setupMessage = ""
        refreshOpponentPlan()
    }

    func catalogUnits(for army: army_list_t) -> [ArmyCatalogUnitSnapshot] {
        (0..<Int(army_catalog_unit_count(army))).map { index in
            ArmyCatalogUnitSnapshot(raw: army_catalog_unit_view(army, Int32(index)))
        }
    }

    func points(for army: army_list_t, selections: [ArmyListSelection]) -> Int {
        let entries: [army_list_entry_t] = selections.map { selection in
            army_list_entry_t(catalog_id: Int32(selection.catalogID), count: Int32(selection.count))
        }
        let total: Int32 = entries.withUnsafeBufferPointer { buffer in
            army_list_total_points(army, buffer.baseAddress, Int32(buffer.count))
        }
        return Int(total)
    }

    func currentPlayerSelections() -> [ArmyListSelection] {
        playerUnitCounts
            .filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
            .map { ArmyListSelection(catalogID: $0.key, count: $0.value) }
    }

    func refreshOpponentPlan() {
        currentOpponentPlan = suggestedOpponentPlan()
        playerTwoArmyID = currentOpponentPlan?.army.id ?? ""
    }

    func selectedPlayerOneArmyPreset() -> army_list_t {
        playerOneArmy?.preset ?? DZW_ARMY_DEMO
    }

    func selectedPlayerTwoArmyPreset() -> army_list_t {
        playerTwoArmy?.preset ?? DZW_ARMY_DEMO
    }

    func selectedPlayerOneForceIndex() -> Int {
        sanitizedForceIndex(playerOneForceIndex, for: selectedPlayerOneArmyPreset())
    }

    func selectedPlayerTwoForceIndex() -> Int {
        sanitizedForceIndex(playerTwoForceIndex, for: selectedPlayerTwoArmyPreset())
    }

    func forceOptions(for army: army_list_t) -> [ArmyForceOptionSnapshot] {
        let count = Int(army_force_count(army))
        return (0..<count).map { index in
            ArmyForceOptionSnapshot(raw: army_force_view(army, Int32(index)))
        }
    }

    func rosterPreview(for army: army_list_t, forceIndex: Int) -> ArmyRosterPreviewSnapshot {
        let sanitizedForce = sanitizedForceIndex(forceIndex, for: army)
        let selectedForce = ArmyForceOptionSnapshot(raw: army_force_view(army, Int32(sanitizedForce)))
        let count = Int(army_force_roster_unit_count(army, Int32(sanitizedForce)))
        let units = (0..<count).map { index in
            ArmyRosterUnitSnapshot(index: index, raw: army_force_roster_unit_view(army, Int32(sanitizedForce), Int32(index)))
        }
        return ArmyRosterPreviewSnapshot(
            army: army,
            forceIndex: sanitizedForce,
            forceName: selectedForce.name,
            forceSummary: selectedForce.summary,
            units: units
        )
    }

    func sanitizedForceIndex(_ forceIndex: Int, for army: army_list_t) -> Int {
        let count = Int(army_force_count(army))
        guard count > 0 else { return 0 }
        return min(max(forceIndex, 0), count - 1)
    }

    func armyName(for army: army_list_t) -> String {
        String(cString: army_name(army))
    }

    func forceName(for army: army_list_t, index: Int) -> String {
        let sanitizedForce = sanitizedForceIndex(index, for: army)
        let view = army_force_view(army, Int32(sanitizedForce))
        return view.name.map { String(cString: $0) } ?? "Preset"
    }

    func selectedPlayerOneForceName() -> String {
        forceName(for: selectedPlayerOneArmyPreset(), index: playerOneForceIndex)
    }

    func selectedPlayerTwoForceName() -> String {
        forceName(for: selectedPlayerTwoArmyPreset(), index: playerTwoForceIndex)
    }

    private func defaultUnitCounts(for army: army_list_t) -> [Int: Int] {
        switch army {
        case DZW_ARMY_BRITISH:
            return [0: 2, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1]
        case DZW_ARMY_AMERICAN:
            return [0: 2, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1]
        case DZW_ARMY_AUSTRALIAN:
            return [0: 2, 1: 1, 2: 1, 3: 1, 4: 1, 6: 1]
        case DZW_ARMY_SOVIET:
            return [0: 2, 1: 1, 2: 1, 3: 1, 4: 1]
        case DZW_ARMY_GERMAN:
            return [0: 2, 3: 1, 4: 1, 5: 1, 6: 1]
        case DZW_ARMY_ITALIAN:
            return [0: 2, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1]
        default:
            return [:]
        }
    }
}
