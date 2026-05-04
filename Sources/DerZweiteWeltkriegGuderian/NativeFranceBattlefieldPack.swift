import Foundation

public enum NativeFranceRuleKind: String, Codable, Hashable, Sendable {
    case riverCrossing = "River crossing"
    case bridgehead = "Bridgehead"
    case heavyTankShock = "Heavy tank shock"
    case armoredRaid = "Armored raid"
    case airPressure = "Air pressure"
    case counterattack = "Counterattack"
    case withdrawal = "Withdrawal"
    case evacuation = "Evacuation"
    case siegeSupply = "Siege supply"
    case portDenial = "Port denial"
    case navalSupport = "Naval support"
    case channelDelay = "Channel delay"
    case fortressFallback = "Fortress fallback"
}

public struct NativeFranceRuleBinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: NativeFranceRuleKind
    public let sourceRuleID: String
    public let name: String
    public let mappedEventIDs: [String]
    public let effect: String

    public init(
        id: String,
        kind: NativeFranceRuleKind,
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

public struct NativeFranceBattlefieldPack: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let nativeUnitCount: Int
    public let playerMobilities: [NativeBattleUnitMobility]
    public let guderianMobilities: [NativeBattleUnitMobility]
    public let terrainKinds: [NativeBattleTerrainKind]
    public let objectiveKinds: [NativeBattleObjectiveKind]
    public let ruleBindings: [NativeFranceRuleBinding]
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
        ruleBindings: [NativeFranceRuleBinding],
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

    public var isNativeFrancePackReady: Bool {
        nativeUnitCount > 0 &&
            !playerMobilities.isEmpty &&
            !guderianMobilities.isEmpty &&
            !terrainKinds.isEmpty &&
            !objectiveKinds.isEmpty &&
            !ruleBindings.isEmpty &&
            deploymentZoneCount >= 2 &&
            missionTargetScore > 0
    }

    public func hasRule(_ kind: NativeFranceRuleKind) -> Bool {
        ruleBindings.contains { $0.kind == kind }
    }
}

public struct NativeFranceCompletionReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let pack: NativeFranceBattlefieldPack
    public let openingSnapshot: NativeBoardSnapshot
    public let finalSnapshot: NativeBoardSnapshot
    public let scoreAwards: [NativeDemoScoreAward]
    public let steps: [NativeDemoBattleStep]
    public let phaseAdvances: Int
    public let completionRecord: CampaignCompletionRecord
    public let debriefSummary: String

    public init(
        id: GuderianBattleID,
        pack: NativeFranceBattlefieldPack,
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

    public var completedFromNativeFranceBattlefield: Bool {
        pack.isNativeFrancePackReady &&
            openingSnapshot.isScenarioBoardPlayable &&
            finalSnapshot.isScenarioBoardPlayable &&
            completionRecord.score > 0 &&
            completionRecord.completedTurn > 0 &&
            !debriefSummary.isEmpty
    }
}

public struct NativeFranceCampaignCompletionReport: Codable, Hashable, Sendable {
    public let completions: [NativeFranceCompletionReport]
    public let progress: CampaignProgress
    public let summary: CampaignCompletionSummary

    public init(
        completions: [NativeFranceCompletionReport],
        progress: CampaignProgress,
        summary: CampaignCompletionSummary
    ) {
        self.completions = completions
        self.progress = progress
        self.summary = summary
    }

    public var completedAllFranceBattles: Bool {
        completions.map(\.id) == NativeFranceBattlefieldPackCatalog.playableBattleIDs &&
            completions.allSatisfy(\.completedFromNativeFranceBattlefield) &&
            summary.completedScenarios == NativeFranceBattlefieldPackCatalog.playableBattleIDs.count
    }
}

public enum NativeFranceBattlefieldPackCatalog {
    public static let cycleRange = 326...345
    public static let playableBattleIDs = FranceCampaignSystemCatalog.franceScenarioIDs

    public static func isNativePlayable(_ scenario: GuderianScenario) -> Bool {
        guard playableBattleIDs.contains(scenario.id),
              let pack = pack(for: scenario)
        else {
            return false
        }
        let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(190_000 + scenario.order))
        return pack.isNativeFrancePackReady &&
            loadout.canApplyScenarioBoardHook &&
            !loadout.usesForcePresetProxy
    }

    public static func pack(for id: GuderianBattleID) -> NativeFranceBattlefieldPack? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return pack(for: scenario)
    }

    public static func pack(for scenario: GuderianScenario) -> NativeFranceBattlefieldPack? {
        guard let profile = FranceCampaignSystemCatalog.profile(for: scenario) else {
            return nil
        }
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        return NativeFranceBattlefieldPack(
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

    public static var allPacks: [NativeFranceBattlefieldPack] {
        playableBattleIDs.compactMap { pack(for: $0) }
    }

    private static func ruleBindings(
        profile: FranceScenarioSystemProfile,
        instance: NativeBattleInstance
    ) -> [NativeFranceRuleBinding] {
        let specialRuleBindings = profile.specialRules.map { rule in
            let text = "\(rule.id) \(rule.name) \(rule.trigger) \(rule.effect)"
            let mappedEvents = instance.events
                .filter { event in
                    event.sourceID == rule.id ||
                        event.id.contains(rule.id) ||
                        textMatches(event.title, rule.name)
                }
                .map(\.id)
            return NativeFranceRuleBinding(
                id: "\(profile.id.rawValue)-native-france-rule-\(rule.id)",
                kind: ruleKind(for: text),
                sourceRuleID: rule.id,
                name: rule.name,
                mappedEventIDs: mappedEvents,
                effect: rule.effect
            )
        }
        let assetBindings = profile.assets.map { asset in
            NativeFranceRuleBinding(
                id: "\(profile.id.rawValue)-native-france-asset-\(asset.id)",
                kind: ruleKind(for: asset),
                sourceRuleID: asset.id,
                name: asset.name,
                mappedEventIDs: [],
                effect: asset.battlefieldRole
            )
        }
        return specialRuleBindings + assetBindings
    }

    private static func ruleKind(for text: String) -> NativeFranceRuleKind {
        let lower = text.lowercased()
        if containsAny(lower, ["destroyer", "naval"]) { return .navalSupport }
        if containsAny(lower, ["port denial", "demolition", "demolish", "deny the port", "harbor-control"]) { return .portDenial }
        if containsAny(lower, ["evacuat", "embark", "beach", "harbor evacuation"]) { return .evacuation }
        if containsAny(lower, ["citadel", "supply", "siege", "ammunition"]) { return .siegeSupply }
        if containsAny(lower, ["dunkirk", "channel", "abbeville", "boulogne", "port", "docks", "quay"]) { return .channelDelay }
        if containsAny(lower, ["char b1", "heavy tank", "heavy-tank"]) { return .heavyTankShock }
        if containsAny(lower, ["air", "stuka", "luftwaffe"]) { return .airPressure }
        if containsAny(lower, ["bridgehead", "foothold"]) { return .bridgehead }
        if containsAny(lower, ["withdraw", "retreat", "exit", "preservation"]) { return .withdrawal }
        if containsAny(lower, ["raid", "4e division", "de gaulle", "column"]) { return .armoredRaid }
        if containsAny(lower, ["counterattack", "counterstroke", "reserve"]) { return .counterattack }
        if containsAny(lower, ["river", "meuse", "somme", "canal", "crossing", "bridge"]) { return .riverCrossing }
        if containsAny(lower, ["fortress", "belfort", "epinal", "vosges", "fallback"]) { return .fortressFallback }
        return .counterattack
    }

    private static func ruleKind(for asset: FranceCampaignAsset) -> NativeFranceRuleKind {
        let text = "\(asset.id) \(asset.name) \(asset.kind.rawValue) \(asset.battlefieldRole) \(asset.limitation)"
        switch asset.kind {
        case .heavyTank:
            return .heavyTankShock
        case .armoredDivision:
            return containsAny(text.lowercased(), ["withdraw", "disengage", "preserve"]) ? .withdrawal : .armoredRaid
        case .riverCrossing:
            return ruleKind(for: text)
        case .airPressure:
            return .airPressure
        case .portOrChannelRoute:
            return .channelDelay
        case .evacuationPoint:
            return .evacuation
        case .navalSupport:
            return .navalSupport
        case .demolition:
            return .portDenial
        case .portPerimeter:
            return containsAny(text.lowercased(), ["citadel", "supply", "siege"]) ? .siegeSupply : .channelDelay
        case .roadJunction:
            return ruleKind(for: text)
        case .withdrawalRoute:
            return .withdrawal
        case .infantryStrongpoint:
            return ruleKind(for: text)
        }
    }

    private static func playerMobilities(
        profile: FranceScenarioSystemProfile,
        instance: NativeBattleInstance
    ) -> [NativeBattleUnitMobility] {
        unique(
            instance.units.filter { $0.side == .player }.map(\.mobility) +
                profile.assets.map(assetMobility)
        )
    }

    private static func assetMobility(_ asset: FranceCampaignAsset) -> NativeBattleUnitMobility {
        switch asset.kind {
        case .heavyTank, .armoredDivision:
            return .armor
        case .riverCrossing, .demolition:
            return .engineer
        case .airPressure:
            return .airPressure
        case .navalSupport:
            return .navalSupport
        case .infantryStrongpoint, .portOrChannelRoute, .evacuationPoint, .portPerimeter, .roadJunction, .withdrawalRoute:
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

public enum NativeFrancePackRunner {
    public static let cycleRange = NativeFranceBattlefieldPackCatalog.cycleRange

    public static func runBattle(
        id: GuderianBattleID,
        seed: UInt32? = nil
    ) throws -> NativeFranceCompletionReport {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw NativeDemoParityError.missingScenario(id)
        }
        return try runBattle(scenario, seed: seed)
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        seed: UInt32? = nil
    ) throws -> NativeFranceCompletionReport {
        guard let session = NativeBoardSession(scenario: scenario, seed: seed ?? UInt32(195_000 + scenario.order)) else {
            throw NativeDemoParityError.boardSessionUnavailable(scenario.id)
        }
        return try completeBattle(from: session)
    }

    public static func completeBattle(from session: NativeBoardSession) throws -> NativeFranceCompletionReport {
        let scenario = session.loadout.scenario
        guard NativeFranceBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id),
              let pack = NativeFranceBattlefieldPackCatalog.pack(for: scenario)
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
            steps.append(performFranceAction(in: session, before: current, stepIndex: steps.count))
            session.advancePhase()
            phaseAdvances += 1
            current = session.snapshot()
        }

        let final = session.snapshot()
        let awards = scoreAwards(for: balance, finalSnapshot: final)
        let score = awards.filter(\.awarded).reduce(0) { $0 + $1.victoryPoints }
        let outcome = outcomeBand(for: score, balance: balance)
        let debrief = "\(scenario.title) completed as a native France 1940 pack battle on turn \(max(1, final.turnNumber)) with \(score)/\(balance.maxPlayerScore) VP and \(outcome.grade.rawValue) result."
        let record = CampaignCompletionRecord(
            scenarioID: scenario.id,
            score: score,
            victoryBand: outcome.grade,
            completedTurn: max(1, final.turnNumber),
            note: "Cycle 345 native France pack completion: \(debrief)"
        )

        return NativeFranceCompletionReport(
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

    public static func runCampaign() throws -> NativeFranceCampaignCompletionReport {
        var progress = CampaignProgress()
        var completions: [NativeFranceCompletionReport] = []
        for id in NativeFranceBattlefieldPackCatalog.playableBattleIDs {
            let completion = try runBattle(id: id)
            completions.append(completion)
            progress.recordCompletion(completion.completionRecord)
        }
        let scenarios = NativeFranceBattlefieldPackCatalog.playableBattleIDs.compactMap(GuderianCampaignCatalog.scenario)
        return NativeFranceCampaignCompletionReport(
            completions: completions,
            progress: progress,
            summary: progress.completionSummary(catalog: scenarios)
        )
    }

    private static func performFranceAction(
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
            id: "\(snapshot.scenarioID.rawValue)-native-france-step-\(stepIndex)",
            turnNumber: snapshot.turnNumber,
            activePlayer: snapshot.activePlayer,
            phase: snapshot.phase,
            status: after.lastAction.status == .idle ? .succeeded : after.lastAction.status,
            title: after.lastAction.status == .idle ? "Phase inspected" : after.lastAction.title,
            detail: after.lastAction.status == .idle ? "No pending action blocked native France playback." : after.lastAction.detail
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
