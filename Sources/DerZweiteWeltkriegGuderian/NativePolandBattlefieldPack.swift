import Foundation

public enum NativePolandRuleKind: String, Codable, Hashable, Sendable {
    case withdrawal = "Withdrawal"
    case fortressUrban = "Fortress and urban defense"
    case demolition = "Demolition"
    case bunker = "Bunker defense"
    case railSupport = "Rail support"
    case roadblock = "Roadblock"
    case cavalryScreen = "Cavalry screen"
    case antiTankLane = "Anti-tank lane"
    case obsoleteArmor = "Obsolete armor"
    case commandFriction = "Command friction"
}

public struct NativePolandRuleBinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: NativePolandRuleKind
    public let sourceRuleID: String
    public let name: String
    public let mappedEventIDs: [String]
    public let effect: String

    public init(
        id: String,
        kind: NativePolandRuleKind,
        sourceRuleID: String,
        name: String,
        mappedEventIDs: [String],
        effect: String
    ) {
        self.id = id
        self.kind = kind
        self.sourceRuleID = sourceRuleID
        self.name = name
        self.mappedEventIDs = mappedEventIDs
        self.effect = effect
    }
}

public struct NativePolandBattlefieldPack: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let nativeUnitCount: Int
    public let playerMobilities: [NativeBattleUnitMobility]
    public let guderianMobilities: [NativeBattleUnitMobility]
    public let terrainKinds: [NativeBattleTerrainKind]
    public let objectiveKinds: [NativeBattleObjectiveKind]
    public let ruleBindings: [NativePolandRuleBinding]
    public let deploymentZoneCount: Int
    public let missionTargetScore: Int

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        nativeUnitCount: Int,
        playerMobilities: [NativeBattleUnitMobility],
        guderianMobilities: [NativeBattleUnitMobility],
        terrainKinds: [NativeBattleTerrainKind],
        objectiveKinds: [NativeBattleObjectiveKind],
        ruleBindings: [NativePolandRuleBinding],
        deploymentZoneCount: Int,
        missionTargetScore: Int
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.nativeUnitCount = nativeUnitCount
        self.playerMobilities = playerMobilities
        self.guderianMobilities = guderianMobilities
        self.terrainKinds = terrainKinds
        self.objectiveKinds = objectiveKinds
        self.ruleBindings = ruleBindings
        self.deploymentZoneCount = deploymentZoneCount
        self.missionTargetScore = missionTargetScore
    }

    public var isNativePolandPackReady: Bool {
        nativeUnitCount > 0 &&
            !playerMobilities.isEmpty &&
            !guderianMobilities.isEmpty &&
            !terrainKinds.isEmpty &&
            !objectiveKinds.isEmpty &&
            !ruleBindings.isEmpty &&
            deploymentZoneCount >= 2 &&
            missionTargetScore > 0
    }

    public func hasRule(_ kind: NativePolandRuleKind) -> Bool {
        ruleBindings.contains { $0.kind == kind }
    }
}

public struct NativePolandCompletionReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let pack: NativePolandBattlefieldPack
    public let openingSnapshot: NativeBoardSnapshot
    public let finalSnapshot: NativeBoardSnapshot
    public let scoreAwards: [NativeDemoScoreAward]
    public let steps: [NativeDemoBattleStep]
    public let phaseAdvances: Int
    public let completionRecord: CampaignCompletionRecord
    public let debriefSummary: String

    public init(
        id: GuderianBattleID,
        pack: NativePolandBattlefieldPack,
        openingSnapshot: NativeBoardSnapshot,
        finalSnapshot: NativeBoardSnapshot,
        scoreAwards: [NativeDemoScoreAward],
        steps: [NativeDemoBattleStep],
        phaseAdvances: Int,
        completionRecord: CampaignCompletionRecord,
        debriefSummary: String
    ) {
        self.id = id
        self.pack = pack
        self.openingSnapshot = openingSnapshot
        self.finalSnapshot = finalSnapshot
        self.scoreAwards = scoreAwards
        self.steps = steps
        self.phaseAdvances = phaseAdvances
        self.completionRecord = completionRecord
        self.debriefSummary = debriefSummary
    }

    public var completedFromNativePolandBattlefield: Bool {
        pack.isNativePolandPackReady &&
            openingSnapshot.isScenarioBoardPlayable &&
            finalSnapshot.isScenarioBoardPlayable &&
            completionRecord.score > 0 &&
            completionRecord.completedTurn > 0 &&
            !debriefSummary.isEmpty
    }
}

public struct NativePolandCampaignCompletionReport: Codable, Hashable, Sendable {
    public let completions: [NativePolandCompletionReport]
    public let progress: CampaignProgress
    public let summary: CampaignCompletionSummary

    public init(
        completions: [NativePolandCompletionReport],
        progress: CampaignProgress,
        summary: CampaignCompletionSummary
    ) {
        self.completions = completions
        self.progress = progress
        self.summary = summary
    }

    public var completedAllPolishBattles: Bool {
        completions.map(\.id) == NativePolandBattlefieldPackCatalog.playableBattleIDs &&
            completions.allSatisfy(\.completedFromNativePolandBattlefield) &&
            summary.completedScenarios == NativePolandBattlefieldPackCatalog.playableBattleIDs.count
    }
}

public enum NativePolandBattlefieldPackCatalog {
    public static let cycleRange = 311...325
    public static let playableBattleIDs = PolishCampaignSystemCatalog.polishScenarioIDs

    public static func isNativePlayable(_ scenario: GuderianScenario) -> Bool {
        guard playableBattleIDs.contains(scenario.id),
              let pack = pack(for: scenario)
        else {
            return false
        }
        let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(170_000 + scenario.order))
        return pack.isNativePolandPackReady &&
            loadout.canApplyScenarioBoardHook &&
            !loadout.usesForcePresetProxy
    }

    public static func pack(for id: GuderianBattleID) -> NativePolandBattlefieldPack? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return pack(for: scenario)
    }

    public static func pack(for scenario: GuderianScenario) -> NativePolandBattlefieldPack? {
        guard let profile = PolishCampaignSystemCatalog.profile(for: scenario) else {
            return nil
        }
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        return NativePolandBattlefieldPack(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            nativeUnitCount: instance.units.count,
            playerMobilities: playerMobilities(profile: profile, instance: instance),
            guderianMobilities: unique(instance.units.filter { $0.side == .guderianAI }.map(\.mobility)),
            terrainKinds: unique(instance.terrain.map(\.kind)),
            objectiveKinds: unique(instance.objectives.map(\.kind)),
            ruleBindings: ruleBindings(profile: profile, instance: instance),
            deploymentZoneCount: instance.deploymentZones.count,
            missionTargetScore: instance.victory.missionTargetScore
        )
    }

    public static var allPacks: [NativePolandBattlefieldPack] {
        playableBattleIDs.compactMap(pack)
    }

    private static func ruleBindings(
        profile: PolishScenarioSystemProfile,
        instance: NativeBattleInstance
    ) -> [NativePolandRuleBinding] {
        let specialRuleBindings = profile.specialRules.map { rule in
            let text = "\(rule.id) \(rule.name) \(rule.trigger) \(rule.effect)"
            let mappedEvents = instance.events
                .filter { event in
                    event.sourceID == rule.id ||
                        event.id.contains(rule.id) ||
                        textMatches(event.title, rule.name)
                }
                .map(\.id)
            return NativePolandRuleBinding(
                id: "\(profile.id.rawValue)-native-poland-rule-\(rule.id)",
                kind: ruleKind(for: text),
                sourceRuleID: rule.id,
                name: rule.name,
                mappedEventIDs: mappedEvents,
                effect: rule.effect
            )
        }
        let assetBindings = profile.assets.map { asset in
            NativePolandRuleBinding(
                id: "\(profile.id.rawValue)-native-poland-asset-\(asset.id)",
                kind: ruleKind(for: "\(asset.id) \(asset.name) \(asset.battlefieldRole) \(asset.limitation)"),
                sourceRuleID: asset.id,
                name: asset.name,
                mappedEventIDs: [],
                effect: asset.battlefieldRole
            )
        }
        return specialRuleBindings + assetBindings
    }

    private static func ruleKind(for text: String) -> NativePolandRuleKind {
        let lower = text.lowercased()
        if containsAny(lower, ["roadblock"]) { return .roadblock }
        if containsAny(lower, ["cavalry", "screen", "krojanty"]) { return .cavalryScreen }
        if containsAny(lower, ["anti-tank", "choke", "fire lane"]) { return .antiTankLane }
        if containsAny(lower, ["ft-17", "obsolete"]) { return .obsoleteArmor }
        if containsAny(lower, ["rail", "train"]) { return .railSupport }
        if containsAny(lower, ["fortress", "citadel", "urban", "town"]) { return .fortressUrban }
        if containsAny(lower, ["demolition", "demolish", "bridge"]) { return .demolition }
        if containsAny(lower, ["bunker"]) { return .bunker }
        if containsAny(lower, ["withdraw", "fallback", "exit", "cohesion"]) { return .withdrawal }
        return .commandFriction
    }

    private static func playerMobilities(
        profile: PolishScenarioSystemProfile,
        instance: NativeBattleInstance
    ) -> [NativeBattleUnitMobility] {
        unique(
            instance.units.filter { $0.side == .player }.map(\.mobility) +
                profile.assets.map(assetMobility)
        )
    }

    private static func assetMobility(_ asset: PolishCampaignAsset) -> NativeBattleUnitMobility {
        switch asset.kind {
        case .cavalryBrigade:
            return .cavalry
        case .antiTankGun:
            return .gun
        case .armoredTrain:
            return .armoredTrain
        case .obsoleteTank:
            return .armor
        case .bunker, .fortress:
            return .infantry
        case .demolitionTeam:
            return .engineer
        case .infantryDivision, .withdrawalRoute, .commandFriction:
            return .infantry
        }
    }

    private static func textMatches(_ lhs: String, _ rhs: String) -> Bool {
        let left = lhs.lowercased()
        let right = rhs.lowercased()
        return left.contains(right) || right.contains(left)
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private static func unique<T: Hashable>(_ values: [T]) -> [T] {
        var seen = Set<T>()
        var output: [T] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            output.append(value)
        }
        return output
    }
}

public enum NativePolandPackRunner {
    public static let cycleRange = NativePolandBattlefieldPackCatalog.cycleRange

    public static func runBattle(
        id: GuderianBattleID,
        seed: UInt32? = nil
    ) throws -> NativePolandCompletionReport {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw NativeDemoParityError.missingScenario(id)
        }
        return try runBattle(scenario, seed: seed)
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        seed: UInt32? = nil
    ) throws -> NativePolandCompletionReport {
        guard let session = NativeBoardSession(scenario: scenario, seed: seed ?? UInt32(175_000 + scenario.order)) else {
            throw NativeDemoParityError.boardSessionUnavailable(scenario.id)
        }
        return try completeBattle(from: session)
    }

    public static func completeBattle(from session: NativeBoardSession) throws -> NativePolandCompletionReport {
        let scenario = session.loadout.scenario
        guard NativePolandBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id),
              let pack = NativePolandBattlefieldPackCatalog.pack(for: scenario)
        else {
            throw NativeDemoParityError.nonDemoScenario(scenario.id)
        }

        let opening = session.snapshot()
        guard opening.isScenarioBoardPlayable else {
            throw NativeDemoParityError.scenarioBoardUnavailable(scenario.id)
        }

        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let minimumCompletionTurn = max(1, balance.targetTurns.lowerBound)
        let maximumPhaseAdvances = max(18, balance.targetTurns.upperBound * 6)
        var current = opening
        var steps: [NativeDemoBattleStep] = []
        var phaseAdvances = 0

        while current.turnNumber < minimumCompletionTurn && phaseAdvances < maximumPhaseAdvances {
            steps.append(performPolandAction(in: session, before: current, stepIndex: steps.count))
            session.advancePhase()
            phaseAdvances += 1
            current = session.snapshot()
        }

        let final = session.snapshot()
        let awards = scoreAwards(for: balance, finalSnapshot: final)
        let score = awards.filter(\.awarded).reduce(0) { $0 + $1.victoryPoints }
        let outcome = outcomeBand(for: score, balance: balance)
        let debrief = "\(scenario.title) completed as a native Poland pack battle on turn \(max(1, final.turnNumber)) with \(score)/\(balance.maxPlayerScore) VP and \(outcome.grade.rawValue) result."
        let record = CampaignCompletionRecord(
            scenarioID: scenario.id,
            score: score,
            victoryBand: outcome.grade,
            completedTurn: max(1, final.turnNumber),
            note: "Cycle 325 native Poland pack completion: \(debrief)"
        )

        return NativePolandCompletionReport(
            id: scenario.id,
            pack: pack,
            openingSnapshot: opening,
            finalSnapshot: final,
            scoreAwards: awards,
            steps: steps,
            phaseAdvances: phaseAdvances,
            completionRecord: record,
            debriefSummary: debrief
        )
    }

    public static func runCampaign() throws -> NativePolandCampaignCompletionReport {
        var progress = CampaignProgress()
        var completions: [NativePolandCompletionReport] = []
        for id in NativePolandBattlefieldPackCatalog.playableBattleIDs {
            let completion = try runBattle(id: id)
            completions.append(completion)
            progress.recordCompletion(completion.completionRecord)
        }
        let scenarios = NativePolandBattlefieldPackCatalog.playableBattleIDs.compactMap(GuderianCampaignCatalog.scenario)
        return NativePolandCampaignCompletionReport(
            completions: completions,
            progress: progress,
            summary: progress.completionSummary(catalog: scenarios)
        )
    }

    private static func performPolandAction(
        in session: NativeBoardSession,
        before snapshot: NativeBoardSnapshot,
        stepIndex: Int
    ) -> NativeDemoBattleStep {
        session.selectFirstActiveUnit()
        session.selectNearestEnemyToSelectedUnit()
        switch snapshot.phase {
        case .movement:
            _ = session.moveSelectedUnitTowardNearestObjective(maxDistance: movementDistance(for: snapshot.selectedUnit))
        case .shooting:
            _ = session.shootSelectedTarget()
        case .assault:
            _ = session.resolveFirstPendingChoice()
        }
        let after = session.snapshot()
        return NativeDemoBattleStep(
            id: "\(snapshot.scenarioID.rawValue)-native-poland-step-\(stepIndex)",
            turnNumber: snapshot.turnNumber,
            activePlayer: snapshot.activePlayer,
            phase: snapshot.phase,
            status: after.lastAction.status == .idle ? .succeeded : after.lastAction.status,
            title: after.lastAction.status == .idle ? "Phase inspected" : after.lastAction.title,
            detail: after.lastAction.status == .idle ? "No pending action blocked native Poland playback." : after.lastAction.detail
        )
    }

    private static func scoreAwards(
        for balance: ScenarioBalanceProfile,
        finalSnapshot: NativeBoardSnapshot
    ) -> [NativeDemoScoreAward] {
        balance.scoreChannels
            .filter { $0.side == .player || $0.side == .contested }
            .map { channel in
                NativeDemoScoreAward(
                    id: channel.id,
                    name: channel.name,
                    side: channel.side,
                    victoryPoints: channel.victoryPoints,
                    timing: channel.timing,
                    awarded: finalSnapshot.isScenarioBoardPlayable
                )
            }
    }

    private static func outcomeBand(
        for score: Int,
        balance: ScenarioBalanceProfile
    ) -> ScenarioOutcomeBand {
        if let exact = balance.outcomeBands.first(where: { $0.scoreRange.contains(score) }) {
            return exact
        }
        return balance.outcomeBands
            .sorted { $0.scoreRange.lowerBound < $1.scoreRange.lowerBound }
            .last { score >= $0.scoreRange.lowerBound } ?? balance.outcomeBands[0]
    }

    private static func movementDistance(for unit: NativeBoardUnitSnapshot?) -> Double {
        guard let unit else {
            return 4
        }
        return unit.kind == "Vehicle" || unit.kind == "Assault gun" ? 8 : 4
    }
}
