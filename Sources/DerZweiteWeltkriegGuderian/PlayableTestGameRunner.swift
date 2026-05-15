import Foundation

public enum PlayableTestAIController: String, Codable, Hashable, Sendable {
    case antiGuderian = "Default-side automation"
    case guderian = "Guderian-command automation"

    init(activePlayer: NativeBoardPlayer) {
        switch activePlayer {
        case .guderianAI:
            self = .guderian
        default:
            self = .antiGuderian
        }
    }
}

public enum OpposingForceAIArmyFamily: String, Codable, Hashable, Sendable {
    case polish = "Polish"
    case french = "French"
    case alliedPortDefense = "Allied port defense"
    case soviet1941 = "Soviet 1941"
    case sovietWinter = "Soviet winter"
    case lateWarSovietAllied = "Late-war Soviet/Allied"
    case generic = "Generic opposing force"
}

public enum OpposingForceAIBehaviorProfile: String, Codable, Hashable, Sendable {
    case fortifiedDelay = "Fortified delay"
    case mobileDelay = "Mobile delay"
    case evacuationDefense = "Evacuation defense"
    case breakout = "Breakout"
    case counterattack = "Counterattack"
    case urbanDefense = "Urban defense"
}

public struct OpposingForceAIOrder: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let turnWindow: String
    public let kind: GermanAIActionKind
    public let target: String
    public let instruction: String

    public init(id: String, turnWindow: String, kind: GermanAIActionKind, target: String, instruction: String) {
        self.id = id
        self.turnWindow = turnWindow
        self.kind = kind
        self.target = target
        self.instruction = instruction
    }
}

public typealias AntiGuderianAIOrder = OpposingForceAIOrder

public struct OpposingForceAIPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let postureName: String
    public let strategicGoal: String
    public let targetPriorities: [String]
    public let orders: [OpposingForceAIOrder]
    public let armyFamily: OpposingForceAIArmyFamily
    public let behaviorProfile: OpposingForceAIBehaviorProfile

    public init(
        id: GuderianBattleID,
        postureName: String,
        strategicGoal: String,
        targetPriorities: [String],
        orders: [OpposingForceAIOrder],
        armyFamily: OpposingForceAIArmyFamily = .generic,
        behaviorProfile: OpposingForceAIBehaviorProfile = .mobileDelay
    ) {
        self.id = id
        self.postureName = postureName
        self.strategicGoal = strategicGoal
        self.targetPriorities = targetPriorities
        self.orders = orders
        self.armyFamily = armyFamily
        self.behaviorProfile = behaviorProfile
    }

    public var isExecutableByNativeAutoplay: Bool {
        !targetPriorities(for: .movement).isEmpty &&
            !targetPriorities(for: .shooting).isEmpty &&
            !targetPriorities(for: .assault).isEmpty
    }

    public func targetPriorities(for phase: NativeBoardPhase) -> [String] {
        uniqueNonEmpty(orders.filter { $0.kind.nativeBoardPhase == phase }.map(\.target) + targetPriorities)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case postureName
        case strategicGoal
        case targetPriorities
        case orders
        case armyFamily
        case behaviorProfile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(GuderianBattleID.self, forKey: .id)
        postureName = try container.decode(String.self, forKey: .postureName)
        strategicGoal = try container.decode(String.self, forKey: .strategicGoal)
        targetPriorities = try container.decode([String].self, forKey: .targetPriorities)
        orders = try container.decode([OpposingForceAIOrder].self, forKey: .orders)
        armyFamily = try container.decodeIfPresent(OpposingForceAIArmyFamily.self, forKey: .armyFamily) ?? .generic
        behaviorProfile = try container.decodeIfPresent(OpposingForceAIBehaviorProfile.self, forKey: .behaviorProfile) ?? .mobileDelay
    }
}

public typealias AntiGuderianAIPlan = OpposingForceAIPlan

public enum OpposingForceAIPlanCatalog {
    public static func plan(for scenario: GuderianScenario) -> OpposingForceAIPlan {
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let playerObjectiveNames = scenario.objectives.map(\.name)
        let playerScoreNames = bundle.balance.scoreChannels
            .filter { $0.side == .player || $0.side == .contested }
            .map(\.name)
        let denialTargets = bundle.aiPlan.targetPriorities.reversed()
        let candidates = uniqueNonEmpty(playerObjectiveNames + playerScoreNames + denialTargets)
        let armyFamily = armyFamily(for: scenario)
        let behaviorProfile = behaviorProfile(for: scenario.playerPosture)
        let movementTargets = priorities(
            for: .movement,
            scenario: scenario,
            family: armyFamily,
            profile: behaviorProfile,
            candidates: candidates
        )
        let shootingTargets = priorities(
            for: .shooting,
            scenario: scenario,
            family: armyFamily,
            profile: behaviorProfile,
            candidates: candidates
        )
        let assaultTargets = priorities(
            for: .assault,
            scenario: scenario,
            family: armyFamily,
            profile: behaviorProfile,
            candidates: candidates
        )
        let priorities = uniqueNonEmpty(movementTargets + shootingTargets + assaultTargets + candidates)
        let movementTarget = movementTargets.first ?? priorities.first ?? scenario.title
        let shootingTarget = shootingTargets.first ?? priorities.dropFirst().first ?? movementTarget
        let assaultTarget = assaultTargets.first ?? priorities.first ?? movementTarget

        return OpposingForceAIPlan(
            id: scenario.id,
            postureName: "\(armyFamily.rawValue) \(behaviorProfile.rawValue)",
            strategicGoal: scenario.designIntent,
            targetPriorities: priorities,
            orders: [
                order(
                    "\(scenario.id.rawValue)-opposing-force-screen",
                    "Opening turns",
                    .movement,
                    movementTarget,
                    instruction(for: .movement, family: armyFamily, profile: behaviorProfile)
                ),
                order(
                    "\(scenario.id.rawValue)-opposing-force-fire",
                    "Contact turns",
                    .shooting,
                    shootingTarget,
                    instruction(for: .shooting, family: armyFamily, profile: behaviorProfile)
                ),
                order(
                    "\(scenario.id.rawValue)-opposing-force-deny",
                    "Endgame",
                    .assault,
                    assaultTarget,
                    instruction(for: .assault, family: armyFamily, profile: behaviorProfile)
                ),
            ],
            armyFamily: armyFamily,
            behaviorProfile: behaviorProfile
        )
    }

    public static var allPlans: [OpposingForceAIPlan] {
        GuderianCampaignCatalog.all.map(plan)
    }

    private static func behaviorProfile(for posture: PlayerPosture) -> OpposingForceAIBehaviorProfile {
        switch posture {
        case .breakout:
            return .breakout
        case .counterattack:
            return .counterattack
        case .evacuationDefense:
            return .evacuationDefense
        case .fortifiedDelay:
            return .fortifiedDelay
        case .mobileDelay:
            return .mobileDelay
        case .urbanDefense:
            return .urbanDefense
        }
    }

    private static func armyFamily(for scenario: GuderianScenario) -> OpposingForceAIArmyFamily {
        switch scenario.id {
        case .tucholaForest, .wizna, .brzescLitewski, .kobryn:
            return .polish
        case .boulogne, .calais, .dunkirk:
            return .alliedPortDefense
        case .sedan, .stonne, .montcornet, .amiensAbbeville, .fallRot:
            return .french
        case .moscowTulaKashira:
            return .sovietWinter
        case .bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk:
            return .soviet1941
        }
    }

    private static func priorities(
        for phase: NativeBoardPhase,
        scenario: GuderianScenario,
        family: OpposingForceAIArmyFamily,
        profile: OpposingForceAIBehaviorProfile,
        candidates: [String]
    ) -> [String] {
        uniqueNonEmpty(
            exactTargets(for: phase, scenario: scenario) +
            matchedTargets(in: candidates, keywords: familyKeywords(for: family, phase: phase)) +
            matchedTargets(in: candidates, keywords: profileKeywords(for: profile, phase: phase)) +
            candidates
        )
    }

    private static func exactTargets(for phase: NativeBoardPhase, scenario: GuderianScenario) -> [String] {
        switch (scenario.id, phase) {
        case (.tucholaForest, .movement):
            return ["Bydgoszcz withdrawal", "Tuchola", "Chojnice", "Pila-Mlyn bridge", "Pruszcz bridge"]
        case (.tucholaForest, .shooting):
            return ["Chojnice-Tuchola road net", "Brda crossings", "Tuchola"]
        case (.tucholaForest, .assault):
            return ["Bydgoszcz withdrawal", "Pruszcz bridge", "Pila-Mlyn bridge"]
        case (.wizna, .movement):
            return ["Wizna bunkers", "Narew crossings", "Fortified line"]
        case (.sedan, .movement):
            return ["Meuse crossings", "Artillery control", "Bridgehead containment"]
        case (.stonne, .movement):
            return ["Contest the heights", "Stonne village", "Break German support"]
        case (.montcornet, .movement):
            return ["Raid the column", "Montcornet village", "Disengage armor"]
        case (.boulogne, .movement):
            return ["Evacuate troops", "Harbor", "Haute Ville"]
        case (.calais, .movement):
            return ["Protect Dunkirk time", "Hold the perimeter", "Preserve supply"]
        case (.dunkirk, .movement):
            return ["Evacuate formations", "Beach perimeter", "Canal lines"]
        case (.moscowTulaKashira, .movement):
            return ["Guard Tula axis", "Kashira counterstroke", "German exhaustion"]
        case (.bialystokMinsk, .movement):
            return ["Open breakout lanes", "Save command units", "Minsk road and rail junction"]
        case (.bialystokMinsk, .shooting):
            return ["Mechanized counterattack", "Bug and Neman crossings", "Delay pincer closure"]
        case (.bialystokMinsk, .assault):
            return ["Bialystok salient", "Novogrudok pocket", "Open breakout lanes"]
        case (.smolensk, .movement):
            return ["Yartsevo escape lane", "Release trapped armies", "Dnieper and Dvina crossings"]
        case (.smolensk, .shooting):
            return ["Yelnya and reserve counterstrokes", "Force logistics strain", "Dnieper crossing line"]
        case (.smolensk, .assault):
            return ["Smolensk pocket", "Yartsevo escape lane", "Keep crossings contested"]
        case (.roslavlNovozybkov, .movement):
            return ["Strike panzer flank", "Preserve reserves", "Roslavl-Novozybkov road axis"]
        case (.roslavlNovozybkov, .shooting):
            return ["Soviet tank raid point", "2nd Panzer supply columns", "Reveal German intent"]
        case (.roslavlNovozybkov, .assault):
            return ["Bryansk Front assembly", "Southward-turn screen", "Preserve reserves"]
        case (.kiev, .movement):
            return ["Eastern closure corridor", "Evacuate command assets", "Open breakout corridors"]
        case (.kiev, .shooting):
            return ["Kiev rail junctions", "Southwestern Front command", "Delay pincer closure"]
        case (.kiev, .assault):
            return ["Kiev pocket", "Eastern closure corridor", "Open breakout corridors"]
        case (.bryansk, .movement):
            return ["Guard Tula axis", "Preserve rail command", "Delay pocket collapse"]
        case (.bryansk, .shooting):
            return ["Autumn road friction", "Bryansk-Orel road", "Orel-Tula road"]
        case (.bryansk, .assault):
            return ["Bryansk pocket", "Orel-Tula road", "Delay pocket collapse"]
        case (.mtsensk, .movement):
            return ["Ambush panzer lead", "Preserve Guards tanks", "Tula withdrawal route"]
        case (.mtsensk, .shooting):
            return ["Katukov tank ambush", "T-34/KV kill lanes", "Anti-tank screen"]
        case (.mtsensk, .assault):
            return ["Orel-Mtsensk road", "Tula road exit", "Preserve Guards tanks"]
        default:
            return []
        }
    }

    private static func familyKeywords(
        for family: OpposingForceAIArmyFamily,
        phase: NativeBoardPhase
    ) -> [String] {
        switch (family, phase) {
        case (.polish, .movement):
            return ["withdraw", "delay", "bridge", "bunker", "fortress", "rail", "roadblock"]
        case (.polish, .shooting):
            return ["road", "bridge", "bunker", "anti-tank", "fortress"]
        case (.polish, .assault):
            return ["withdraw", "bridge", "bunker", "fortress"]
        case (.french, .movement):
            return ["counterattack", "armor", "bridgehead", "heights", "crossing", "road"]
        case (.french, .shooting):
            return ["support", "column", "bridgehead", "engineer", "armor"]
        case (.french, .assault):
            return ["heights", "village", "crossing", "column"]
        case (.alliedPortDefense, .movement):
            return ["evacuat", "harbor", "port", "perimeter", "beach", "canal"]
        case (.alliedPortDefense, .shooting):
            return ["naval", "support", "perimeter", "supply", "air"]
        case (.alliedPortDefense, .assault):
            return ["harbor", "perimeter", "canal", "demolition", "supply"]
        case (.soviet1941, .movement):
            return ["breakout", "corridor", "command", "counterattack", "crossing", "road", "rail"]
        case (.soviet1941, .shooting):
            return ["pincer", "column", "supply", "armor", "bridgehead"]
        case (.soviet1941, .assault):
            return ["corridor", "pocket", "road", "crossing", "pincer"]
        case (.sovietWinter, .movement):
            return ["tula", "kashira", "venev", "winter", "counterattack", "road"]
        case (.sovietWinter, .shooting):
            return ["exhaustion", "spearhead", "armor", "road", "infantry"]
        case (.sovietWinter, .assault):
            return ["tula", "kashira", "counteroffensive", "road"]
        case (.lateWarSovietAllied, .movement):
            return ["crossing", "rail", "road", "pocket", "bridgehead", "corridor"]
        case (.lateWarSovietAllied, .shooting):
            return ["withdraw", "supply", "rail", "road", "fortress"]
        case (.lateWarSovietAllied, .assault):
            return ["pocket", "bridgehead", "fortress", "corridor"]
        case (.generic, _):
            return []
        }
    }

    private static func profileKeywords(
        for profile: OpposingForceAIBehaviorProfile,
        phase: NativeBoardPhase
    ) -> [String] {
        switch (profile, phase) {
        case (.fortifiedDelay, .movement):
            return ["hold", "line", "bunker", "fortress", "crossing"]
        case (.fortifiedDelay, .shooting):
            return ["support", "artillery", "anti-tank", "approach"]
        case (.fortifiedDelay, .assault):
            return ["line", "bunker", "fortress", "crossing"]
        case (.mobileDelay, .movement):
            return ["withdraw", "delay", "road", "exit", "bridge"]
        case (.mobileDelay, .shooting):
            return ["column", "road", "spearhead", "bridge"]
        case (.mobileDelay, .assault):
            return ["exit", "road", "bridge", "withdraw"]
        case (.evacuationDefense, .movement):
            return ["evacuat", "harbor", "beach", "perimeter", "canal"]
        case (.evacuationDefense, .shooting):
            return ["support", "naval", "supply", "perimeter"]
        case (.evacuationDefense, .assault):
            return ["harbor", "beach", "perimeter", "canal"]
        case (.breakout, .movement):
            return ["breakout", "corridor", "exit", "road", "rail"]
        case (.breakout, .shooting):
            return ["pincer", "block", "supply", "crossing"]
        case (.breakout, .assault):
            return ["corridor", "exit", "pocket", "road"]
        case (.counterattack, .movement):
            return ["counterattack", "raid", "column", "flank", "heights"]
        case (.counterattack, .shooting):
            return ["column", "support", "armor", "flank"]
        case (.counterattack, .assault):
            return ["heights", "village", "column", "flank"]
        case (.urbanDefense, .movement):
            return ["town", "city", "perimeter", "rail", "supply"]
        case (.urbanDefense, .shooting):
            return ["street", "support", "supply", "perimeter"]
        case (.urbanDefense, .assault):
            return ["town", "city", "perimeter", "rail"]
        }
    }

    private static func matchedTargets(in candidates: [String], keywords: [String]) -> [String] {
        candidates.filter { candidate in
            let lowered = candidate.lowercased()
            return keywords.contains { lowered.contains($0.lowercased()) }
        }
    }

    private static func instruction(
        for phase: NativeBoardPhase,
        family: OpposingForceAIArmyFamily,
        profile: OpposingForceAIBehaviorProfile
    ) -> String {
        switch phase {
        case .movement:
            return "Use \(family.rawValue.lowercased()) \(profile.rawValue.lowercased()) movement priorities before generic objective pursuit."
        case .shooting:
            return "Fire to protect the \(profile.rawValue.lowercased()) plan and punish exposed German-command pressure."
        case .assault:
            return "Assault only when it preserves the \(family.rawValue.lowercased()) scenario goal or denies a decisive German-command target."
        }
    }

    private static func order(
        _ id: String,
        _ turnWindow: String,
        _ kind: GermanAIActionKind,
        _ target: String,
        _ instruction: String
    ) -> OpposingForceAIOrder {
        OpposingForceAIOrder(
            id: id,
            turnWindow: turnWindow,
            kind: kind,
            target: target,
            instruction: instruction
        )
    }

}

public enum AntiGuderianAIPlanCatalog {
    public static func plan(for scenario: GuderianScenario) -> AntiGuderianAIPlan {
        OpposingForceAIPlanCatalog.plan(for: scenario)
    }

    public static var allPlans: [AntiGuderianAIPlan] {
        OpposingForceAIPlanCatalog.allPlans
    }
}

private func uniqueNonEmpty(_ values: [String]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for value in values {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trimmed.lowercased()
        guard !trimmed.isEmpty, !seen.contains(key) else {
            continue
        }
        seen.insert(key)
        result.append(trimmed)
    }
    return result
}

public struct PlayableTestGameStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let turnNumber: Int
    public let activePlayer: NativeBoardPlayer
    public let controller: PlayableTestAIController
    public let phase: NativeBoardPhase
    public let status: NativeBoardActionStatus
    public let title: String
    public let detail: String
    public let movementDistance: Double

    public init(
        id: String,
        turnNumber: Int,
        activePlayer: NativeBoardPlayer,
        controller: PlayableTestAIController,
        phase: NativeBoardPhase,
        status: NativeBoardActionStatus,
        title: String,
        detail: String,
        movementDistance: Double = 0
    ) {
        self.id = id
        self.turnNumber = turnNumber
        self.activePlayer = activePlayer
        self.controller = controller
        self.phase = phase
        self.status = status
        self.title = title
        self.detail = detail
        self.movementDistance = movementDistance
    }
}

public struct PlayableTestGameBattleResult: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let openingSnapshot: NativeBoardSnapshot
    public let finalSnapshot: NativeBoardSnapshot
    public let antiGuderianPlan: AntiGuderianAIPlan
    public let germanPlan: GermanAIPlan
    public let completion: PlayableBattleCompletionSummary
    public let steps: [PlayableTestGameStep]
    public let phaseAdvances: Int
    public let blockers: [String]

    public init(
        id: GuderianBattleID,
        title: String,
        openingSnapshot: NativeBoardSnapshot,
        finalSnapshot: NativeBoardSnapshot,
        antiGuderianPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan,
        completion: PlayableBattleCompletionSummary,
        steps: [PlayableTestGameStep],
        phaseAdvances: Int,
        blockers: [String]
    ) {
        self.id = id
        self.title = title
        self.openingSnapshot = openingSnapshot
        self.finalSnapshot = finalSnapshot
        self.antiGuderianPlan = antiGuderianPlan
        self.germanPlan = germanPlan
        self.completion = completion
        self.steps = steps
        self.phaseAdvances = phaseAdvances
        self.blockers = blockers
    }

    public var automatedSides: Set<NativeBoardPlayer> {
        Set(steps.map(\.activePlayer).filter { $0 == .player || $0 == .guderianAI })
    }

    public var opposingForcePlan: OpposingForceAIPlan {
        antiGuderianPlan
    }

    public var antiGuderianStepCount: Int {
        steps.filter { $0.controller == .antiGuderian }.count
    }

    public var germanStepCount: Int {
        steps.filter { $0.controller == .guderian }.count
    }

    public var totalMovementDistance: Double {
        steps.map(\.movementDistance).reduce(0, +)
    }

    public var blockedMovementPhases: Int {
        steps.filter { $0.phase == .movement && $0.status == .blocked }.count
    }

    public var completedToEnd: Bool {
        blockers.isEmpty &&
            completion.completionRecord.scenarioID == id &&
            completion.completionRecord.completedTurn > 0 &&
            automatedSides.isSuperset(of: [.player, .guderianAI])
    }

    public var summary: String {
        "\(title) played to debrief with \(antiGuderianStepCount) default-side automation steps, \(germanStepCount) Guderian-command automation steps, and \(phaseAdvances) phase advances."
    }
}

public struct PlayableTestGameCampaignResult: Codable, Hashable, Sendable {
    public let battleIDs: [GuderianBattleID]
    public let results: [PlayableTestGameBattleResult]
    public let progress: CampaignProgress
    public let summary: CampaignCompletionSummary

    public init(
        battleIDs: [GuderianBattleID],
        results: [PlayableTestGameBattleResult],
        progress: CampaignProgress,
        summary: CampaignCompletionSummary
    ) {
        self.battleIDs = battleIDs
        self.results = results
        self.progress = progress
        self.summary = summary
    }

    public var completedAllBattlesToEnd: Bool {
        results.map(\.id) == battleIDs &&
            results.allSatisfy(\.completedToEnd) &&
            summary.isComplete
    }
}

public enum PlayableTestGameRunner {
    public static func runCampaign(
        ids: [GuderianBattleID] = GuderianCampaignCatalog.all.sorted { $0.order < $1.order }.map(\.id),
        chosenHumanSideID: String? = nil
    ) throws -> PlayableTestGameCampaignResult {
        var progress = CampaignProgress()
        var results: [PlayableTestGameBattleResult] = []

        for id in ids {
            let result: PlayableTestGameBattleResult
            if let chosenHumanSideID {
                result = try runBattle(for: id, chosenHumanSideID: chosenHumanSideID)
            } else {
                result = try runBattle(for: id)
            }
            results.append(result)
            progress.recordCompletion(result.completion.completionRecord)
        }

        let scenarios = ids.compactMap(GuderianCampaignCatalog.scenario)
        return PlayableTestGameCampaignResult(
            battleIDs: ids,
            results: results,
            progress: progress,
            summary: progress.completionSummary(catalog: scenarios)
        )
    }

    public static func runGuderianCommandCampaign(
        ids: [GuderianBattleID] = GuderianCampaignCatalog.all.sorted { $0.order < $1.order }.map(\.id)
    ) throws -> PlayableTestGameCampaignResult {
        try runCampaign(
            ids: ids,
            chosenHumanSideID: GuderianHistoricalSideID.guderianCommand
        )
    }

    public static func runBattle(
        for id: GuderianBattleID,
        seed: UInt32? = nil
    ) throws -> PlayableTestGameBattleResult {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw NativeDemoParityError.missingScenario(id)
        }
        return try runBattle(scenario, seed: seed ?? defaultSeed(for: scenario))
    }

    public static func runBattle(
        for id: GuderianBattleID,
        chosenHumanSideID: String,
        seed: UInt32? = nil
    ) throws -> PlayableTestGameBattleResult {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw NativeDemoParityError.missingScenario(id)
        }
        return try runBattle(
            scenario,
            chosenHumanSideID: chosenHumanSideID,
            seed: seed ?? defaultSeed(for: scenario)
        )
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        seed: UInt32? = nil
    ) throws -> PlayableTestGameBattleResult {
        guard let session = NativeBoardSession(scenario: scenario, seed: seed ?? defaultSeed(for: scenario)) else {
            throw NativeDemoParityError.boardSessionUnavailable(scenario.id)
        }
        return try runBattle(from: session)
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        chosenHumanSideID: String,
        seed: UInt32? = nil
    ) throws -> PlayableTestGameBattleResult {
        let resolvedSeed = seed ?? defaultSeed(for: scenario)
        let launch = try GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: chosenHumanSideID,
            seed: resolvedSeed
        )
        guard let session = NativeBoardSession(
            scenario: scenario,
            seed: resolvedSeed,
            launch: launch
        ) else {
            throw NativeDemoParityError.boardSessionUnavailable(scenario.id)
        }
        return try runBattle(from: session)
    }

    public static func runBattle(from session: NativeBoardSession) throws -> PlayableTestGameBattleResult {
        let scenario = session.loadout.scenario
        let opening = session.snapshot()
        guard opening.isScenarioBoardPlayable else {
            throw NativeDemoParityError.scenarioBoardUnavailable(scenario.id)
        }

        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let antiPlan = OpposingForceAIPlanCatalog.plan(for: scenario)
        let germanPlan = GermanAIPlanCatalog.plan(for: scenario)
        let maxPhaseAdvances = max(24, balance.targetTurns.upperBound * 8)
        var steps: [PlayableTestGameStep] = []
        var phaseAdvances = 0
        var blockers: [String] = []
        var current = opening

        while current.turnNumber <= balance.targetTurns.upperBound &&
            current.mission.winner == .none &&
            phaseAdvances < maxPhaseAdvances {
            steps.append(
                performActiveAIPhase(
                    in: session,
                    before: current,
                    antiPlan: antiPlan,
                    germanPlan: germanPlan,
                    stepIndex: steps.count
                )
            )
            drainPendingChoices(in: session, steps: &steps)
            session.advancePhase()
            phaseAdvances += 1
            current = session.snapshot()
        }

        if phaseAdvances >= maxPhaseAdvances {
            blockers.append("\(scenario.title) hit the \(maxPhaseAdvances)-phase autoplay guard before debrief.")
        }
        let automatedSides = Set(steps.map(\.activePlayer))
        if !automatedSides.contains(.player) {
            blockers.append("Default-side automation did not receive an active phase.")
        }
        if !automatedSides.contains(.guderianAI) {
            blockers.append("Guderian-command automation did not receive an active phase.")
        }

        let completion = try PlayableBattleCompletionResolver.completeBattle(from: session)
        let final = session.snapshot()

        return PlayableTestGameBattleResult(
            id: scenario.id,
            title: scenario.title,
            openingSnapshot: opening,
            finalSnapshot: final,
            antiGuderianPlan: antiPlan,
            germanPlan: germanPlan,
            completion: completion,
            steps: steps,
            phaseAdvances: phaseAdvances,
            blockers: blockers
        )
    }

    private static func performActiveAIPhase(
        in session: NativeBoardSession,
        before snapshot: NativeBoardSnapshot,
        antiPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan,
        stepIndex: Int
    ) -> PlayableTestGameStep {
        let controller = PlayableTestAIController(activePlayer: snapshot.activePlayer)
        let status: NativeBoardActionStatus
        let title: String
        let detail: String
        let movementDistance: Double

        switch snapshot.phase {
        case .movement:
            let movement = moveActiveUnits(in: session, snapshot: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            let target = priorityTarget(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            let reason = priorityInstruction(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            status = movement.moved == 0 ? .blocked : .succeeded
            title = "\(controller.rawValue) movement"
            detail = movement.moved == 0 ?
                "No legal movement was available for priority target \(target); fallback to nearest legal objective also failed. Reason: \(reason)" :
                "\(movement.moved) active units moved \(String(format: "%.1f", movement.distance))\" toward priority target \(target), with nearest legal objective as fallback. Reason: \(reason)"
            movementDistance = movement.distance
        case .shooting:
            let shots = shootActiveUnits(in: session, snapshot: snapshot)
            let target = priorityTarget(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            let reason = priorityInstruction(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            status = shots == 0 ? .blocked : .succeeded
            title = "\(controller.rawValue) shooting"
            detail = shots == 0 ?
                "No legal shots were available while protecting priority target \(target). Reason: \(reason)" :
                "\(shots) active units fired at nearest enemies to protect priority target \(target). Reason: \(reason)"
            movementDistance = 0
        case .assault:
            let assaults = assaultActiveUnits(in: session, snapshot: snapshot)
            let resolved = session.resolveFirstPendingChoice()
            let target = priorityTarget(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            let reason = priorityInstruction(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan)
            title = "\(controller.rawValue) assault"
            movementDistance = 0
            if assaults > 0 {
                status = .succeeded
                detail = "\(assaults) active units assaulted nearest enemies around priority target \(target). Reason: \(reason)"
            } else if resolved {
                status = .succeeded
                detail = "Resolved a pending assault or damage choice around priority target \(target). Reason: \(reason)"
            } else {
                status = .blocked
                detail = "No legal assaults or pending choices were available around priority target \(target). Reason: \(reason)"
            }
        }

        return PlayableTestGameStep(
            id: "\(snapshot.scenarioID.rawValue)-playable-test-step-\(stepIndex)",
            turnNumber: snapshot.turnNumber,
            activePlayer: snapshot.activePlayer,
            controller: controller,
            phase: snapshot.phase,
            status: status,
            title: title,
            detail: detail,
            movementDistance: movementDistance
        )
    }

    private static func moveActiveUnits(
        in session: NativeBoardSession,
        snapshot: NativeBoardSnapshot,
        antiPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan
    ) -> PlayableMovementPhaseResult {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canMoveNow }
            .sorted { $0.id < $1.id }
        var moved = 0
        var distance = 0.0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            let controller = PlayableTestAIController(activePlayer: snapshot.activePlayer)
            let maxDistance = movementDistance(
                for: unit,
                controller: controller,
                scenarioID: snapshot.scenarioID,
                turnNumber: snapshot.turnNumber
            )
            let usedPriority = session.moveSelectedUnitTowardPriorityObjective(
                named: phasePriorities(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan),
                maxDistance: maxDistance
            )
            if usedPriority || session.moveSelectedUnitTowardNearestObjective(maxDistance: maxDistance) {
                moved += 1
                if let after = session.snapshot().units.first(where: { $0.id == unit.id }) {
                    distance += hypot(after.x - unit.x, after.y - unit.y)
                }
            }
        }

        return PlayableMovementPhaseResult(moved: moved, distance: distance)
    }

    private static func phasePriorities(
        for snapshot: NativeBoardSnapshot,
        antiPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan
    ) -> [String] {
        if snapshot.activePlayer == .guderianAI {
            return germanPlan.targetPriorities(for: snapshot.phase)
        }

        return antiPlan.targetPriorities(for: snapshot.phase)
    }

    private static func priorityTarget(
        for snapshot: NativeBoardSnapshot,
        antiPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan
    ) -> String {
        phasePriorities(for: snapshot, antiPlan: antiPlan, germanPlan: germanPlan).first ?? "nearest legal objective"
    }

    private static func priorityInstruction(
        for snapshot: NativeBoardSnapshot,
        antiPlan: AntiGuderianAIPlan,
        germanPlan: GermanAIPlan
    ) -> String {
        if snapshot.activePlayer == .guderianAI {
            return germanPlan.orders.first { $0.kind.nativeBoardPhase == snapshot.phase }?.instruction ??
                germanPlan.strategicGoal
        }

        return antiPlan.orders.first { $0.kind.nativeBoardPhase == snapshot.phase }?.instruction ??
            antiPlan.strategicGoal
    }

    private static func shootActiveUnits(
        in session: NativeBoardSession,
        snapshot: NativeBoardSnapshot
    ) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canShootNow }
            .sorted { $0.id < $1.id }
        var shots = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if session.shootSelectedTarget() {
                shots += 1
                drainPendingChoices(in: session)
            }
        }

        return shots
    }

    private static func assaultActiveUnits(
        in session: NativeBoardSession,
        snapshot: NativeBoardSnapshot
    ) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canAssaultNow }
            .sorted { $0.id < $1.id }
        var assaults = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if let target = session.snapshot().selectedTarget,
               session.assaultUnit(unit.id, targetID: target.id, advance: true) {
                assaults += 1
                drainPendingChoices(in: session)
            }
        }

        return assaults
    }

    private static func drainPendingChoices(
        in session: NativeBoardSession,
        steps: inout [PlayableTestGameStep]
    ) {
        for _ in 0..<16 {
            let before = session.snapshot()
            guard session.resolveFirstPendingChoice() else {
                return
            }
            let after = session.snapshot()
            steps.append(
                PlayableTestGameStep(
                    id: "\(before.scenarioID.rawValue)-playable-test-step-\(steps.count)",
                    turnNumber: before.turnNumber,
                    activePlayer: before.activePlayer,
                    controller: PlayableTestAIController(activePlayer: before.activePlayer),
                    phase: before.phase,
                    status: after.lastAction.status,
                    title: after.lastAction.title,
                    detail: after.lastAction.detail
                )
            )
        }
    }

    private static func drainPendingChoices(in session: NativeBoardSession) {
        for _ in 0..<16 {
            guard session.resolveFirstPendingChoice() else {
                return
            }
        }
    }

    private static func movementDistance(
        for unit: NativeBoardUnitSnapshot,
        controller: PlayableTestAIController,
        scenarioID: GuderianBattleID,
        turnNumber: Int
    ) -> Double {
        let base: Double
        if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
            base = controller == .guderian ? 9 : 7
        } else {
            base = controller == .guderian ? 5 : 4
        }
        return max(3, base - movementFriction(for: scenarioID, controller: controller, turnNumber: turnNumber))
    }

    private static func movementFriction(
        for scenarioID: GuderianBattleID,
        controller: PlayableTestAIController,
        turnNumber: Int
    ) -> Double {
        switch scenarioID {
        case .montcornet:
            return controller == .guderian && turnNumber <= 4 ? 2 : 0
        case .wizna, .kobryn, .stonne, .amiensAbbeville, .boulogne:
            return controller == .guderian && turnNumber <= 4 ? 1 : 0
        case .calais:
            return controller == .guderian && turnNumber <= 5 ? 1 : 0
        case .mtsensk:
            if controller == .guderian && turnNumber <= 3 {
                return 2
            }
            return controller == .guderian ? 1 : 0
        default:
            return 0
        }
    }

    private static func defaultSeed(for scenario: GuderianScenario) -> UInt32 {
        UInt32(620_000 + scenario.order)
    }
}

private struct PlayableMovementPhaseResult: Hashable, Sendable {
    let moved: Int
    let distance: Double
}
