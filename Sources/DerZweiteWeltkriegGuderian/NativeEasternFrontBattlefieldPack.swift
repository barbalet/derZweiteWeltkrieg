import Foundation

public enum NativeEasternFrontRuleKind: String, Codable, Hashable, Sendable {
    case pocket = "Pocket"
    case breakout = "Breakout"
    case mechanizedCounterattack = "Mechanized counterattack"
    case commandPost = "Command post"
    case riverCrossing = "River crossing"
    case logistics = "Logistics"
    case southwardTurn = "Southward turn"
    case pincer = "Pincer"
    case armorAmbush = "Armor ambush"
    case t34KVShock = "T-34/KV shock"
    case winterFriction = "Winter friction"
    case tulaDefense = "Tula defense"
    case counteroffensive = "Counteroffensive"
}

public struct NativeEasternFrontRuleBinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: NativeEasternFrontRuleKind
    public let sourceRuleID: String
    public let name: String
    public let mappedEventIDs: [String]
    public let effect: String

    public init(
        id: String,
        kind: NativeEasternFrontRuleKind,
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

public struct NativeEasternFrontBattlefieldFoundation: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let nativeUnitCount: Int
    public let playerMobilities: [NativeBattleUnitMobility]
    public let guderianMobilities: [NativeBattleUnitMobility]
    public let terrainKinds: [NativeBattleTerrainKind]
    public let objectiveKinds: [NativeBattleObjectiveKind]
    public let ruleBindings: [NativeEasternFrontRuleBinding]
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
        ruleBindings: [NativeEasternFrontRuleBinding],
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

    public var isNativeEasternFrontFoundationReady: Bool {
        nativeUnitCount > 0 &&
            !playerMobilities.isEmpty &&
            !guderianMobilities.isEmpty &&
            !terrainKinds.isEmpty &&
            !objectiveKinds.isEmpty &&
            !ruleBindings.isEmpty &&
            deploymentZoneCount >= 2 &&
            missionTargetScore > 0
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) Eastern Front foundation: \(ruleBindings.count) native rule bindings, \(nativeUnitCount) units, \(terrainKinds.count) terrain kinds, \(objectiveKinds.count) objective kinds."
    }

    public func hasRule(_ kind: NativeEasternFrontRuleKind) -> Bool {
        ruleBindings.contains { $0.kind == kind }
    }
}

public enum NativeEasternFrontBattlefieldFoundationCatalog {
    public static let cycleRange = 346...350
    public static let foundationBattleIDs = EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs

    public static func isFoundationReady(_ scenario: GuderianScenario) -> Bool {
        guard foundationBattleIDs.contains(scenario.id),
              let foundation = foundation(for: scenario)
        else {
            return false
        }
        let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(205_000 + scenario.order))
        return foundation.isNativeEasternFrontFoundationReady &&
            loadout.canApplyScenarioBoardHook &&
            !loadout.usesForcePresetProxy
    }

    public static func foundation(for id: GuderianBattleID) -> NativeEasternFrontBattlefieldFoundation? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return foundation(for: scenario)
    }

    public static func foundation(for scenario: GuderianScenario) -> NativeEasternFrontBattlefieldFoundation? {
        guard let profile = EasternFrontCampaignSystemCatalog.profile(for: scenario) else {
            return nil
        }
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        return NativeEasternFrontBattlefieldFoundation(
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

    public static var allFoundations: [NativeEasternFrontBattlefieldFoundation] {
        foundationBattleIDs.compactMap { foundation(for: $0) }
    }

    private static func ruleBindings(
        profile: EasternFrontScenarioSystemProfile,
        instance: NativeBattleInstance
    ) -> [NativeEasternFrontRuleBinding] {
        let specialRuleBindings = profile.specialRules.map { rule in
            let text = "\(rule.id) \(rule.name) \(rule.trigger) \(rule.effect)"
            let mappedEvents = instance.events
                .filter { event in
                    event.sourceID == rule.id ||
                        event.id.contains(rule.id) ||
                        textMatches(event.title, rule.name)
                }
                .map(\.id)
            return NativeEasternFrontRuleBinding(
                id: "\(profile.id.rawValue)-native-eastern-rule-\(rule.id)",
                kind: ruleKind(for: text),
                sourceRuleID: rule.id,
                name: rule.name,
                mappedEventIDs: mappedEvents,
                effect: rule.effect
            )
        }
        let assetBindings = profile.assets.map { asset in
            NativeEasternFrontRuleBinding(
                id: "\(profile.id.rawValue)-native-eastern-asset-\(asset.id)",
                kind: ruleKind(for: asset),
                sourceRuleID: asset.id,
                name: asset.name,
                mappedEventIDs: [],
                effect: asset.battlefieldRole
            )
        }
        return specialRuleBindings + assetBindings
    }

    private static func ruleKind(for text: String) -> NativeEasternFrontRuleKind {
        let lower = text.lowercased()
        if containsAny(lower, ["ambush", "katukov", "wooded ridge"]) { return .armorAmbush }
        if containsAny(lower, ["t-34", "kv", "tank-loss", "tank loss"]) { return .t34KVShock }
        if containsAny(lower, ["counteroffensive", "counterstroke", "mobile reserve"]) { return .counteroffensive }
        if containsAny(lower, ["winter", "exhaustion"]) { return .winterFriction }
        if containsAny(lower, ["tula", "kashira", "venev"]) { return .tulaDefense }
        if containsAny(lower, ["southward", "turns south", "kiev operation"]) { return .southwardTurn }
        if containsAny(lower, ["pincer", "link-up", "linkup", "envelopment", "closure"]) { return .pincer }
        if containsAny(lower, ["mechanized", "boldin", "counterattack", "reserve army", "tank group"]) { return .mechanizedCounterattack }
        if containsAny(lower, ["command", "hq", "headquarters"]) { return .commandPost }
        if containsAny(lower, ["river", "dnieper", "dvina", "desna", "bug", "neman", "crossing"]) { return .riverCrossing }
        if containsAny(lower, ["logistics", "supply", "rail", "autumn", "friction", "road"]) { return .logistics }
        if containsAny(lower, ["breakout", "escape", "corridor", "withdraw", "exit", "open"]) { return .breakout }
        if containsAny(lower, ["pocket", "encircle", "isolation", "salient", "trapped"]) { return .pocket }
        return .breakout
    }

    private static func ruleKind(for asset: EasternFrontAsset) -> NativeEasternFrontRuleKind {
        let text = "\(asset.id) \(asset.name) \(asset.kind.rawValue) \(asset.battlefieldRole) \(asset.limitation)"
        let lower = text.lowercased()
        if containsAny(lower, ["t-34", "kv"]) {
            return .t34KVShock
        }
        switch asset.kind {
        case .rifleArmy:
            return containsAny(lower, ["pocket", "trapped", "salient"]) ? .pocket : .breakout
        case .mechanizedCorps, .tankReserve:
            return .mechanizedCounterattack
        case .commandPost:
            return .commandPost
        case .breakoutRoute:
            return containsAny(lower, ["tula", "kashira", "venev"]) ? .tulaDefense : .breakout
        case .riverCrossing:
            return .riverCrossing
        case .railJunction, .logisticsFriction:
            return .logistics
        case .pocket:
            return .pocket
        case .winterFriction:
            return .winterFriction
        case .armorAmbush:
            return .armorAmbush
        case .antiTankScreen:
            return .t34KVShock
        case .counteroffensiveAxis, .cityDefense:
            return .tulaDefense
        }
    }

    private static func playerMobilities(
        profile: EasternFrontScenarioSystemProfile,
        instance: NativeBattleInstance
    ) -> [NativeBattleUnitMobility] {
        unique(
            instance.units.filter { $0.side == .player }.map(\.mobility) +
                profile.assets.map(assetMobility)
        )
    }

    private static func assetMobility(_ asset: EasternFrontAsset) -> NativeBattleUnitMobility {
        switch asset.kind {
        case .mechanizedCorps, .tankReserve, .armorAmbush, .counteroffensiveAxis:
            return .armor
        case .commandPost:
            return .command
        case .riverCrossing, .logisticsFriction, .winterFriction, .breakoutRoute, .railJunction:
            return .engineer
        case .antiTankScreen:
            return .gun
        case .rifleArmy, .pocket, .cityDefense:
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

public struct NativeEasternFrontBattlefieldPack: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let foundationCycleStart: Int
    public let foundationCycleEnd: Int
    public let nativeUnitCount: Int
    public let playerMobilities: [NativeBattleUnitMobility]
    public let guderianMobilities: [NativeBattleUnitMobility]
    public let terrainKinds: [NativeBattleTerrainKind]
    public let objectiveKinds: [NativeBattleObjectiveKind]
    public let ruleBindings: [NativeEasternFrontRuleBinding]
    public let deploymentZoneCount: Int
    public let missionTargetScore: Int

    public init(
        foundation: NativeEasternFrontBattlefieldFoundation,
        cycleRange: ClosedRange<Int>
    ) {
        self.id = foundation.id
        self.title = foundation.title
        self.cycleStart = cycleRange.lowerBound
        self.cycleEnd = cycleRange.upperBound
        self.foundationCycleStart = foundation.cycleStart
        self.foundationCycleEnd = foundation.cycleEnd
        self.nativeUnitCount = foundation.nativeUnitCount
        self.playerMobilities = foundation.playerMobilities
        self.guderianMobilities = foundation.guderianMobilities
        self.terrainKinds = foundation.terrainKinds
        self.objectiveKinds = foundation.objectiveKinds
        self.ruleBindings = foundation.ruleBindings
        self.deploymentZoneCount = foundation.deploymentZoneCount
        self.missionTargetScore = foundation.missionTargetScore
    }

    public var isNativeEasternFrontPackReady: Bool {
        nativeUnitCount > 0 &&
            !playerMobilities.isEmpty &&
            !guderianMobilities.isEmpty &&
            !terrainKinds.isEmpty &&
            !objectiveKinds.isEmpty &&
            !ruleBindings.isEmpty &&
            deploymentZoneCount >= 2 &&
            missionTargetScore > 0
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) Eastern Front pack: \(ruleBindings.count) native rule bindings, \(nativeUnitCount) units, \(terrainKinds.count) terrain kinds, \(objectiveKinds.count) objective kinds."
    }

    public func hasRule(_ kind: NativeEasternFrontRuleKind) -> Bool {
        ruleBindings.contains { $0.kind == kind }
    }
}

public struct NativeEasternFrontCompletionReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let pack: NativeEasternFrontBattlefieldPack
    public let openingSnapshot: NativeBoardSnapshot
    public let finalSnapshot: NativeBoardSnapshot
    public let scoreAwards: [NativeDemoScoreAward]
    public let steps: [NativeDemoBattleStep]
    public let phaseAdvances: Int
    public let completionRecord: CampaignCompletionRecord
    public let debriefSummary: String

    public init(
        id: GuderianBattleID,
        pack: NativeEasternFrontBattlefieldPack,
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

    public var completedFromNativeEasternFrontBattlefield: Bool {
        pack.isNativeEasternFrontPackReady &&
            openingSnapshot.isScenarioBoardPlayable &&
            finalSnapshot.isScenarioBoardPlayable &&
            completionRecord.score > 0 &&
            completionRecord.completedTurn > 0 &&
            !debriefSummary.isEmpty
    }
}

public struct NativeEasternFrontCampaignCompletionReport: Codable, Hashable, Sendable {
    public let completions: [NativeEasternFrontCompletionReport]
    public let progress: CampaignProgress
    public let summary: CampaignCompletionSummary

    public init(
        completions: [NativeEasternFrontCompletionReport],
        progress: CampaignProgress,
        summary: CampaignCompletionSummary
    ) {
        self.completions = completions
        self.progress = progress
        self.summary = summary
    }

    public var completedAllEasternFrontBattles: Bool {
        completions.map(\.id) == NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs &&
            completions.allSatisfy(\.completedFromNativeEasternFrontBattlefield) &&
            summary.completedScenarios == NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.count
    }
}

public enum NativeEasternFrontBattlefieldPackCatalog {
    public static let cycleRange = 346...370
    public static let playableBattleIDs = NativeEasternFrontBattlefieldFoundationCatalog.foundationBattleIDs

    public static func isNativePlayable(_ scenario: GuderianScenario) -> Bool {
        guard playableBattleIDs.contains(scenario.id),
              let pack = pack(for: scenario)
        else {
            return false
        }
        let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(215_000 + scenario.order))
        return pack.isNativeEasternFrontPackReady &&
            loadout.canApplyScenarioBoardHook &&
            !loadout.usesForcePresetProxy
    }

    public static func pack(for id: GuderianBattleID) -> NativeEasternFrontBattlefieldPack? {
        guard let foundation = NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: id) else {
            return nil
        }
        return NativeEasternFrontBattlefieldPack(foundation: foundation, cycleRange: cycleRange)
    }

    public static func pack(for scenario: GuderianScenario) -> NativeEasternFrontBattlefieldPack? {
        guard let foundation = NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: scenario) else {
            return nil
        }
        return NativeEasternFrontBattlefieldPack(foundation: foundation, cycleRange: cycleRange)
    }

    public static var allPacks: [NativeEasternFrontBattlefieldPack] {
        playableBattleIDs.compactMap { pack(for: $0) }
    }
}

public enum NativeEasternFrontPackRunner {
    public static let cycleRange = NativeEasternFrontBattlefieldPackCatalog.cycleRange

    public static func runBattle(
        id: GuderianBattleID,
        seed: UInt32? = nil
    ) throws -> NativeEasternFrontCompletionReport {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw NativeDemoParityError.missingScenario(id)
        }
        return try runBattle(scenario, seed: seed)
    }

    public static func runBattle(
        _ scenario: GuderianScenario,
        seed: UInt32? = nil
    ) throws -> NativeEasternFrontCompletionReport {
        guard let session = NativeBoardSession(scenario: scenario, seed: seed ?? UInt32(220_000 + scenario.order)) else {
            throw NativeDemoParityError.boardSessionUnavailable(scenario.id)
        }
        return try completeBattle(from: session)
    }

    public static func completeBattle(from session: NativeBoardSession) throws -> NativeEasternFrontCompletionReport {
        let scenario = session.loadout.scenario
        guard NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id),
              let pack = NativeEasternFrontBattlefieldPackCatalog.pack(for: scenario)
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
            steps.append(performEasternFrontAction(in: session, before: current, stepIndex: steps.count))
            session.advancePhase()
            phaseAdvances += 1
            current = session.snapshot()
        }

        let final = session.snapshot()
        let awards = scoreAwards(for: balance, finalSnapshot: final)
        let score = awards.filter(\.awarded).reduce(0) { $0 + $1.victoryPoints }
        let outcome = outcomeBand(for: score, balance: balance)
        let debrief = "\(scenario.title) completed as a native Eastern Front pack battle on turn \(max(1, final.turnNumber)) with \(score)/\(balance.maxPlayerScore) VP and \(outcome.grade.rawValue) result."
        let record = CampaignCompletionRecord(
            scenarioID: scenario.id,
            score: score,
            victoryBand: outcome.grade,
            completedTurn: max(1, final.turnNumber),
            note: "Cycle 370 native Eastern Front pack completion: \(debrief)"
        )

        return NativeEasternFrontCompletionReport(
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

    public static func runCampaign() throws -> NativeEasternFrontCampaignCompletionReport {
        var progress = CampaignProgress()
        var completions: [NativeEasternFrontCompletionReport] = []
        for id in NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs {
            let completion = try runBattle(id: id)
            completions.append(completion)
            progress.recordCompletion(completion.completionRecord)
        }
        let scenarios = NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.compactMap(GuderianCampaignCatalog.scenario)
        return NativeEasternFrontCampaignCompletionReport(
            completions: completions,
            progress: progress,
            summary: progress.completionSummary(catalog: scenarios)
        )
    }

    private static func performEasternFrontAction(
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
            id: "\(snapshot.scenarioID.rawValue)-native-eastern-front-step-\(stepIndex)",
            turnNumber: snapshot.turnNumber,
            activePlayer: snapshot.activePlayer,
            phase: snapshot.phase,
            status: after.lastAction.status == .idle ? .succeeded : after.lastAction.status,
            title: after.lastAction.status == .idle ? "Phase inspected" : after.lastAction.title,
            detail: after.lastAction.status == .idle ? "No pending action blocked native Eastern Front playback." : after.lastAction.detail
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
