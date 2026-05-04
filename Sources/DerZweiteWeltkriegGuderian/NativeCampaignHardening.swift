import Foundation

public enum NativeAIEventBoardTargetKind: String, Codable, Hashable, Sendable {
    case objective = "Objective"
    case unit = "Unit"
    case deploymentZone = "Deployment zone"
    case mission = "Mission"
    case scenario = "Scenario"
}

public struct NativeAIEventBoardResolution: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let bindingID: String
    public let kind: NativeAIEventBindingKind
    public let title: String
    public let turnWindow: String
    public let boardTargetKind: NativeAIEventBoardTargetKind
    public let boardTargetName: String
    public let boardTurnNumber: Int
    public let resolvedAgainstBoardState: Bool
    public let effect: String

    public init(
        id: String,
        bindingID: String,
        kind: NativeAIEventBindingKind,
        title: String,
        turnWindow: String,
        boardTargetKind: NativeAIEventBoardTargetKind,
        boardTargetName: String,
        boardTurnNumber: Int,
        resolvedAgainstBoardState: Bool,
        effect: String
    ) {
        self.id = id
        self.bindingID = bindingID
        self.kind = kind
        self.title = title
        self.turnWindow = turnWindow
        self.boardTargetKind = boardTargetKind
        self.boardTargetName = boardTargetName
        self.boardTurnNumber = boardTurnNumber
        self.resolvedAgainstBoardState = resolvedAgainstBoardState
        self.effect = effect
    }
}

public struct NativeAIEventExecutionReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let passCycleStart: Int
    public let passCycleEnd: Int
    public let openedBoardSession: Bool
    public let scenarioBoardPlayable: Bool
    public let deterministicSeedHint: UInt32
    public let aiControlResolutionCount: Int
    public let fallbackResolutionCount: Int
    public let eventResolutionCount: Int
    public let reinforcementResolutionCount: Int
    public let scenarioRuleResolutionCount: Int
    public let victoryGateResolutionCount: Int
    public let boardStateResolutionCount: Int
    public let preferredObjectiveNames: [String]
    public let resolutions: [NativeAIEventBoardResolution]

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        passCycleStart: Int,
        passCycleEnd: Int,
        openedBoardSession: Bool,
        scenarioBoardPlayable: Bool,
        deterministicSeedHint: UInt32,
        aiControlResolutionCount: Int,
        fallbackResolutionCount: Int,
        eventResolutionCount: Int,
        reinforcementResolutionCount: Int,
        scenarioRuleResolutionCount: Int,
        victoryGateResolutionCount: Int,
        boardStateResolutionCount: Int,
        preferredObjectiveNames: [String],
        resolutions: [NativeAIEventBoardResolution]
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.passCycleStart = passCycleStart
        self.passCycleEnd = passCycleEnd
        self.openedBoardSession = openedBoardSession
        self.scenarioBoardPlayable = scenarioBoardPlayable
        self.deterministicSeedHint = deterministicSeedHint
        self.aiControlResolutionCount = aiControlResolutionCount
        self.fallbackResolutionCount = fallbackResolutionCount
        self.eventResolutionCount = eventResolutionCount
        self.reinforcementResolutionCount = reinforcementResolutionCount
        self.scenarioRuleResolutionCount = scenarioRuleResolutionCount
        self.victoryGateResolutionCount = victoryGateResolutionCount
        self.boardStateResolutionCount = boardStateResolutionCount
        self.preferredObjectiveNames = preferredObjectiveNames
        self.resolutions = resolutions
    }

    public var isNativeAIEventExecutionReady: Bool {
        openedBoardSession &&
            scenarioBoardPlayable &&
            deterministicSeedHint > 0 &&
            aiControlResolutionCount > 0 &&
            fallbackResolutionCount > 0 &&
            eventResolutionCount > 0 &&
            victoryGateResolutionCount > 0 &&
            boardStateResolutionCount == resolutions.count &&
            !preferredObjectiveNames.isEmpty &&
            resolutions.allSatisfy(\.resolvedAgainstBoardState)
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) AI/event execution: \(boardStateResolutionCount)/\(resolutions.count) bindings resolved against board state, \(reinforcementResolutionCount) reinforcement timings, \(scenarioRuleResolutionCount) scenario rules."
    }
}

public enum NativeAIEventExecutionCatalog {
    public static let cycleRange = 376...380

    public static func report(for id: GuderianBattleID) -> NativeAIEventExecutionReport? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return report(for: scenario)
    }

    public static func report(for scenario: GuderianScenario) -> NativeAIEventExecutionReport {
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        let pass = NativeAIEventPassCatalog.report(for: scenario)
        guard let session = NativeBoardSession(scenario: scenario, seed: pass.deterministicSeedHint) else {
            return NativeAIEventExecutionReport(
                id: scenario.id,
                title: scenario.title,
                cycleStart: cycleRange.lowerBound,
                cycleEnd: cycleRange.upperBound,
                passCycleStart: pass.cycleStart,
                passCycleEnd: pass.cycleEnd,
                openedBoardSession: false,
                scenarioBoardPlayable: false,
                deterministicSeedHint: pass.deterministicSeedHint,
                aiControlResolutionCount: 0,
                fallbackResolutionCount: 0,
                eventResolutionCount: 0,
                reinforcementResolutionCount: 0,
                scenarioRuleResolutionCount: 0,
                victoryGateResolutionCount: 0,
                boardStateResolutionCount: 0,
                preferredObjectiveNames: [],
                resolutions: []
            )
        }

        let snapshot = session.snapshot()
        let preferred = preferredObjectiveName(
            for: instance,
            objectiveNames: snapshot.objectives.map(\.name)
        ).map { [$0] } ?? []
        let resolutions = pass.bindings.enumerated().map { index, binding in
            resolution(
                for: binding,
                index: index,
                scenario: scenario,
                instance: instance,
                snapshot: snapshot
            )
        }

        return NativeAIEventExecutionReport(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            passCycleStart: pass.cycleStart,
            passCycleEnd: pass.cycleEnd,
            openedBoardSession: true,
            scenarioBoardPlayable: snapshot.isScenarioBoardPlayable,
            deterministicSeedHint: pass.deterministicSeedHint,
            aiControlResolutionCount: resolutions.filter { $0.kind == .germanPriority }.count,
            fallbackResolutionCount: resolutions.filter { $0.kind == .fallbackBehavior }.count,
            eventResolutionCount: resolutions.filter { bindingIsEvent($0.kind) }.count,
            reinforcementResolutionCount: resolutions.filter { $0.kind == .reinforcementTiming }.count,
            scenarioRuleResolutionCount: resolutions.filter { $0.kind == .scenarioRule }.count,
            victoryGateResolutionCount: resolutions.filter { $0.kind == .victoryGate }.count,
            boardStateResolutionCount: resolutions.filter(\.resolvedAgainstBoardState).count,
            preferredObjectiveNames: preferred,
            resolutions: resolutions
        )
    }

    public static var allReports: [NativeAIEventExecutionReport] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(report)
    }

    public static func isExecutionReady(_ scenario: GuderianScenario) -> Bool {
        report(for: scenario).isNativeAIEventExecutionReady
    }

    public static func preferredObjectiveName(
        for scenario: GuderianScenario,
        objectiveNames: [String]
    ) -> String? {
        preferredObjectiveName(
            for: NativeBattleInstanceCatalog.instance(for: scenario),
            objectiveNames: objectiveNames
        )
    }

    public static func preferredObjectiveName(
        for instance: NativeBattleInstance,
        objectiveNames: [String]
    ) -> String? {
        guard !objectiveNames.isEmpty else {
            return nil
        }

        let hints = instance.aiProfile.targetPriorities + instance.aiProfile.orders.map(\.target)
        let scored = objectiveNames.map { name in
            (name: name, score: score(candidate: name, against: hints))
        }
        return scored.max { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.name > rhs.name
            }
            return lhs.score < rhs.score
        }?.name ?? objectiveNames.first
    }

    private static func resolution(
        for binding: NativeAIEventBinding,
        index: Int,
        scenario: GuderianScenario,
        instance: NativeBattleInstance,
        snapshot: NativeBoardSnapshot
    ) -> NativeAIEventBoardResolution {
        let target = boardTarget(for: binding, scenario: scenario, instance: instance, snapshot: snapshot)
        return NativeAIEventBoardResolution(
            id: "\(scenario.id.rawValue)-native-ai-event-execution-\(index)",
            bindingID: binding.id,
            kind: binding.kind,
            title: binding.title,
            turnWindow: binding.timing,
            boardTargetKind: target.kind,
            boardTargetName: target.name,
            boardTurnNumber: snapshot.turnNumber,
            resolvedAgainstBoardState: snapshot.isScenarioBoardPlayable && !target.name.isEmpty,
            effect: binding.effect
        )
    }

    private static func boardTarget(
        for binding: NativeAIEventBinding,
        scenario: GuderianScenario,
        instance: NativeBattleInstance,
        snapshot: NativeBoardSnapshot
    ) -> NativeAIEventBoardTarget {
        switch binding.kind {
        case .germanPriority:
            if let name = preferredObjectiveName(for: instance, objectiveNames: snapshot.objectives.map(\.name)) {
                return NativeAIEventBoardTarget(kind: .objective, name: name)
            }
        case .fallbackBehavior:
            if let objective = snapshot.objectives.first(where: { $0.controller != .guderianAI }) ?? snapshot.objectives.first {
                return NativeAIEventBoardTarget(kind: .objective, name: objective.name)
            }
        case .reinforcementTiming:
            if let reinforcement = instance.reinforcements.first(where: { reinforcement in
                binding.sourceID == reinforcement.id ||
                    textMatches(binding.title, reinforcement.unitName) ||
                    textMatches(binding.effect, reinforcement.role)
            }),
                let zone = instance.deploymentZones.first(where: { $0.id == reinforcement.entryZoneID }) {
                return NativeAIEventBoardTarget(kind: .deploymentZone, name: zone.name)
            }
        case .victoryGate:
            if let objective = matchingObjective(for: "\(binding.title) \(binding.effect)", snapshot: snapshot) {
                return NativeAIEventBoardTarget(kind: .objective, name: objective.name)
            }
            return NativeAIEventBoardTarget(kind: .mission, name: snapshot.mission.name)
        case .scenarioRule, .scriptedTrigger, .pacingRule, .tutorialCue:
            if let objective = matchingObjective(for: "\(binding.title) \(binding.target) \(binding.effect)", snapshot: snapshot) {
                return NativeAIEventBoardTarget(kind: .objective, name: objective.name)
            }
            if let unit = matchingUnit(for: "\(binding.title) \(binding.target) \(binding.effect)", snapshot: snapshot) {
                return NativeAIEventBoardTarget(kind: .unit, name: unit.name)
            }
        }

        if let objective = snapshot.objectives.first {
            return NativeAIEventBoardTarget(kind: .objective, name: objective.name)
        }
        if let unit = snapshot.units.first {
            return NativeAIEventBoardTarget(kind: .unit, name: unit.name)
        }
        return NativeAIEventBoardTarget(kind: .scenario, name: scenario.title)
    }

    private static func matchingObjective(
        for text: String,
        snapshot: NativeBoardSnapshot
    ) -> NativeBoardObjectiveSnapshot? {
        snapshot.objectives.max { lhs, rhs in
            score(candidate: lhs.name, against: [text]) < score(candidate: rhs.name, against: [text])
        }
    }

    private static func matchingUnit(
        for text: String,
        snapshot: NativeBoardSnapshot
    ) -> NativeBoardUnitSnapshot? {
        snapshot.units.max { lhs, rhs in
            score(candidate: lhs.name, against: [text]) < score(candidate: rhs.name, against: [text])
        }
    }

    private static func bindingIsEvent(_ kind: NativeAIEventBindingKind) -> Bool {
        switch kind {
        case .reinforcementTiming, .scriptedTrigger, .scenarioRule, .pacingRule, .tutorialCue:
            return true
        case .germanPriority, .fallbackBehavior, .victoryGate:
            return false
        }
    }
}

private struct NativeAIEventBoardTarget {
    let kind: NativeAIEventBoardTargetKind
    let name: String
}

public enum NativeBalanceUXSignalKind: String, Codable, Hashable, Sendable {
    case pacing = "Pacing"
    case agency = "Agency"
    case density = "Density"
    case readability = "Readability"
    case accessibility = "Accessibility"
    case saveLoad = "Save/load"
    case failureDebrief = "Failure and debrief"
}

public struct NativeBalanceUXSignal: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: NativeBalanceUXSignalKind
    public let title: String
    public let detail: String
    public let ready: Bool

    public init(id: String, kind: NativeBalanceUXSignalKind, title: String, detail: String, ready: Bool) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.ready = ready
    }
}

public struct NativeBalanceUXAuditReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let targetTurns: ClosedRange<Int>
    public let nativeUnitCount: Int
    public let nativeObjectiveCount: Int
    public let nativeTerrainCount: Int
    public let missionTargetScore: Int
    public let maxPlayerScore: Int
    public let victoryBandCount: Int
    public let readableUnitDensity: Bool
    public let playablePacingReady: Bool
    public let playerAgencyReady: Bool
    public let debriefReady: Bool
    public let accessibilityReady: Bool
    public let saveLoadReady: Bool
    public let failureReportingReady: Bool
    public let signals: [NativeBalanceUXSignal]
    public let blockers: [String]

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        targetTurns: ClosedRange<Int>,
        nativeUnitCount: Int,
        nativeObjectiveCount: Int,
        nativeTerrainCount: Int,
        missionTargetScore: Int,
        maxPlayerScore: Int,
        victoryBandCount: Int,
        readableUnitDensity: Bool,
        playablePacingReady: Bool,
        playerAgencyReady: Bool,
        debriefReady: Bool,
        accessibilityReady: Bool,
        saveLoadReady: Bool,
        failureReportingReady: Bool,
        signals: [NativeBalanceUXSignal],
        blockers: [String]
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.targetTurns = targetTurns
        self.nativeUnitCount = nativeUnitCount
        self.nativeObjectiveCount = nativeObjectiveCount
        self.nativeTerrainCount = nativeTerrainCount
        self.missionTargetScore = missionTargetScore
        self.maxPlayerScore = maxPlayerScore
        self.victoryBandCount = victoryBandCount
        self.readableUnitDensity = readableUnitDensity
        self.playablePacingReady = playablePacingReady
        self.playerAgencyReady = playerAgencyReady
        self.debriefReady = debriefReady
        self.accessibilityReady = accessibilityReady
        self.saveLoadReady = saveLoadReady
        self.failureReportingReady = failureReportingReady
        self.signals = signals
        self.blockers = blockers
    }

    public var isNativeBalanceUXReady: Bool {
        blockers.isEmpty &&
            readableUnitDensity &&
            playablePacingReady &&
            playerAgencyReady &&
            debriefReady &&
            accessibilityReady &&
            saveLoadReady &&
            failureReportingReady &&
            signals.allSatisfy(\.ready)
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) balance/UX audit: \(nativeUnitCount) units, \(nativeObjectiveCount) objectives, \(victoryBandCount) victory bands, \(blockers.count) blockers."
    }
}

public enum NativeBalanceUXAuditCatalog {
    public static let cycleRange = 381...390

    public static func report(for id: GuderianBattleID) -> NativeBalanceUXAuditReport? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return report(for: scenario)
    }

    public static func report(for scenario: GuderianScenario) -> NativeBalanceUXAuditReport {
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let audit = ScenarioBalanceAuditCatalog.audit(for: scenario)
        let flowPlan = try? BattleUIFlowRunner.plan(for: scenario.id)
        let readableDensity = instance.units.count <= 24 && instance.objectives.count <= 6 && instance.terrain.count <= 52
        let pacingReady = balance.targetTurns.lowerBound >= 4 && balance.targetTurns.upperBound <= 12 && !balance.pacingRules.isEmpty
        let agencyReady = !audit.agencyNote.isEmpty && balance.maxPlayerScore >= instance.victory.missionTargetScore
        let debriefReady = balance.outcomeBands.count >= 3 &&
            balance.outcomeBands.contains { $0.scoreRange.contains(instance.victory.missionTargetScore) }
        let accessibilityReady = flowPlan?.visitedStages == BattleUIFlowStage.allCases &&
            flowPlan?.accessibilityIdentifiers.allSatisfy { !$0.isEmpty } == true
        let saveLoadReady = saveRoundTripReady(for: scenario, balance: balance)
        let failureReady = !audit.pressureNote.isEmpty && !balance.germanPressureLimit.isEmpty && !balance.playerWinCondition.isEmpty
        let blockers = blockers(
            readableDensity: readableDensity,
            pacingReady: pacingReady,
            agencyReady: agencyReady,
            debriefReady: debriefReady,
            accessibilityReady: accessibilityReady,
            saveLoadReady: saveLoadReady,
            failureReady: failureReady
        )

        return NativeBalanceUXAuditReport(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            targetTurns: balance.targetTurns,
            nativeUnitCount: instance.units.count,
            nativeObjectiveCount: instance.objectives.count,
            nativeTerrainCount: instance.terrain.count,
            missionTargetScore: instance.victory.missionTargetScore,
            maxPlayerScore: balance.maxPlayerScore,
            victoryBandCount: Set(balance.outcomeBands.map(\.grade)).count,
            readableUnitDensity: readableDensity,
            playablePacingReady: pacingReady,
            playerAgencyReady: agencyReady,
            debriefReady: debriefReady,
            accessibilityReady: accessibilityReady,
            saveLoadReady: saveLoadReady,
            failureReportingReady: failureReady,
            signals: signals(
                scenario: scenario,
                balance: balance,
                readableDensity: readableDensity,
                pacingReady: pacingReady,
                agencyReady: agencyReady,
                debriefReady: debriefReady,
                accessibilityReady: accessibilityReady,
                saveLoadReady: saveLoadReady,
                failureReady: failureReady
            ),
            blockers: blockers
        )
    }

    public static var allReports: [NativeBalanceUXAuditReport] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(report)
    }

    public static func isAuditReady(_ scenario: GuderianScenario) -> Bool {
        report(for: scenario).isNativeBalanceUXReady
    }

    private static func saveRoundTripReady(
        for scenario: GuderianScenario,
        balance: ScenarioBalanceProfile
    ) -> Bool {
        var progress = CampaignProgress()
        progress.recordCompletion(
            CampaignCompletionRecord(
                scenarioID: scenario.id,
                score: balance.maxPlayerScore,
                victoryBand: .operational,
                completedTurn: balance.targetTurns.upperBound,
                note: "Cycle 390 save/load continuity audit."
            )
        )
        let state = CampaignSaveState(
            selectedScenarioID: scenario.id,
            playMode: .standalone,
            progress: progress,
            savedAt: Date(timeIntervalSince1970: 1_941_000 + Double(scenario.order))
        )
        guard let data = try? CampaignSaveCodec.encode(state) else {
            return false
        }
        return CampaignSaveCodec.decodeIfCurrent(data) == state
    }

    private static func blockers(
        readableDensity: Bool,
        pacingReady: Bool,
        agencyReady: Bool,
        debriefReady: Bool,
        accessibilityReady: Bool,
        saveLoadReady: Bool,
        failureReady: Bool
    ) -> [String] {
        [
            readableDensity ? nil : "Native unit/objective/terrain density exceeds readable board limits.",
            pacingReady ? nil : "Target turns or pacing rules do not support playable pacing.",
            agencyReady ? nil : "Player agency score does not cover the native mission target.",
            debriefReady ? nil : "Victory bands do not cover maximum player score.",
            accessibilityReady ? nil : "UI flow accessibility identifiers do not cover the full battle flow.",
            saveLoadReady ? nil : "Campaign save/load continuity did not round-trip.",
            failureReady ? nil : "Failure and debrief notes are incomplete.",
        ].compactMap { $0 }
    }

    private static func signals(
        scenario: GuderianScenario,
        balance: ScenarioBalanceProfile,
        readableDensity: Bool,
        pacingReady: Bool,
        agencyReady: Bool,
        debriefReady: Bool,
        accessibilityReady: Bool,
        saveLoadReady: Bool,
        failureReady: Bool
    ) -> [NativeBalanceUXSignal] {
        [
            signal(scenario, "pacing", .pacing, "Playable pacing", "Target turn window \(balance.targetTurns.lowerBound)-\(balance.targetTurns.upperBound) with \(balance.pacingRules.count) pacing rules.", pacingReady),
            signal(scenario, "agency", .agency, "Player agency", balance.playerWinCondition, agencyReady),
            signal(scenario, "density", .density, "Readable board density", "Native unit, objective, and terrain counts stay inside cycle 390 limits.", readableDensity),
            signal(scenario, "readability", .readability, "Victory readability", "\(balance.outcomeBands.count) debrief bands cover the native mission target.", debriefReady),
            signal(scenario, "accessibility", .accessibility, "UI flow labels", "Campaign row through completion exposes stable accessibility identifiers.", accessibilityReady),
            signal(scenario, "save-load", .saveLoad, "Save/load continuity", "Scenario progress round-trips through the current save schema.", saveLoadReady),
            signal(scenario, "failure-debrief", .failureDebrief, "Failure/debrief reporting", balance.germanPressureLimit, failureReady),
        ]
    }

    private static func signal(
        _ scenario: GuderianScenario,
        _ suffix: String,
        _ kind: NativeBalanceUXSignalKind,
        _ title: String,
        _ detail: String,
        _ ready: Bool
    ) -> NativeBalanceUXSignal {
        NativeBalanceUXSignal(
            id: "\(scenario.id.rawValue)-cycle-390-\(suffix)",
            kind: kind,
            title: title,
            detail: detail,
            ready: ready
        )
    }
}

public enum NativeCampaignShipGateStatus: String, Codable, Hashable, Sendable {
    case passed = "Passed"
    case blocked = "Blocked"
}

public struct NativeCampaignShipGate: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let status: NativeCampaignShipGateStatus
    public let detail: String

    public init(id: String, title: String, status: NativeCampaignShipGateStatus, detail: String) {
        self.id = id
        self.title = title
        self.status = status
        self.detail = detail
    }
}

public struct NativeCampaignShipReport: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let scenarioCount: Int
    public let nativePlayableCount: Int
    public let automationNonTerminalCount: Int
    public let completedScenarioCount: Int
    public let aiEventExecutionReadyCount: Int
    public let balanceUXReadyCount: Int
    public let metadataShipReady: Bool
    public let gates: [NativeCampaignShipGate]
    public let buildCommands: [String]
    public let blockers: [String]

    public init(
        cycleStart: Int,
        cycleEnd: Int,
        scenarioCount: Int,
        nativePlayableCount: Int,
        automationNonTerminalCount: Int,
        completedScenarioCount: Int,
        aiEventExecutionReadyCount: Int,
        balanceUXReadyCount: Int,
        metadataShipReady: Bool,
        gates: [NativeCampaignShipGate],
        buildCommands: [String],
        blockers: [String]
    ) {
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.scenarioCount = scenarioCount
        self.nativePlayableCount = nativePlayableCount
        self.automationNonTerminalCount = automationNonTerminalCount
        self.completedScenarioCount = completedScenarioCount
        self.aiEventExecutionReadyCount = aiEventExecutionReadyCount
        self.balanceUXReadyCount = balanceUXReadyCount
        self.metadataShipReady = metadataShipReady
        self.gates = gates
        self.buildCommands = buildCommands
        self.blockers = blockers
    }

    public var isNativeCampaignShipReady: Bool {
        blockers.isEmpty && gates.allSatisfy { $0.status == .passed }
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) native ship gate: \(nativePlayableCount)/\(scenarioCount) native playable, \(completedScenarioCount)/\(scenarioCount) automated completions, \(blockers.count) blockers."
    }
}

public enum NativeCampaignShipReportCatalog {
    public static let cycleRange = 391...400

    public static func report() -> NativeCampaignShipReport {
        let catalog = GuderianCampaignCatalog.all.sorted { $0.order < $1.order }
        let readinessReports = NativePlayabilityArchitectureCatalog.allReadinessReports
        let automation = CampaignAutomationRunner.runCampaign()
        let aiExecutionReports = NativeAIEventExecutionCatalog.allReports
        let balanceReports = NativeBalanceUXAuditCatalog.allReports
        let metadataReport = FullCampaignShipReportCatalog.report()
        let scenarioCount = catalog.count
        let nativePlayableCount = readinessReports.filter { $0.status == .nativePlayable }.count
        let automationNonTerminalCount = automation.reports.filter { !$0.status.isTerminalProblem }.count
        let completedScenarioCount = automation.completionSummary.completedScenarios
        let aiReadyCount = aiExecutionReports.filter(\.isNativeAIEventExecutionReady).count
        let balanceReadyCount = balanceReports.filter(\.isNativeBalanceUXReady).count
        let blockers = blockers(
            scenarioCount: scenarioCount,
            nativePlayableCount: nativePlayableCount,
            automationNonTerminalCount: automationNonTerminalCount,
            completedScenarioCount: completedScenarioCount,
            aiReadyCount: aiReadyCount,
            balanceReadyCount: balanceReadyCount,
            metadataShipReady: metadataReport.isShipReady
        )

        return NativeCampaignShipReport(
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            scenarioCount: scenarioCount,
            nativePlayableCount: nativePlayableCount,
            automationNonTerminalCount: automationNonTerminalCount,
            completedScenarioCount: completedScenarioCount,
            aiEventExecutionReadyCount: aiReadyCount,
            balanceUXReadyCount: balanceReadyCount,
            metadataShipReady: metadataReport.isShipReady,
            gates: gates(
                scenarioCount: scenarioCount,
                nativePlayableCount: nativePlayableCount,
                automationNonTerminalCount: automationNonTerminalCount,
                completedScenarioCount: completedScenarioCount,
                aiReadyCount: aiReadyCount,
                balanceReadyCount: balanceReadyCount,
                metadataShipReady: metadataReport.isShipReady
            ),
            buildCommands: [
                "git diff --check",
                "git -C dzw diff --check",
                "swift build",
                "swift test",
                "xcodebuild -project Guderian.xcodeproj -scheme Guderian -destination 'platform=macOS' test",
                "xcodebuild -project Guderian.xcodeproj -scheme GuderianTest -destination 'platform=macOS' build",
            ],
            blockers: blockers
        )
    }

    private static func blockers(
        scenarioCount: Int,
        nativePlayableCount: Int,
        automationNonTerminalCount: Int,
        completedScenarioCount: Int,
        aiReadyCount: Int,
        balanceReadyCount: Int,
        metadataShipReady: Bool
    ) -> [String] {
        [
            scenarioCount == 19 ? nil : "Campaign catalog must contain 19 scenarios.",
            nativePlayableCount == scenarioCount ? nil : "Every scenario must be native playable.",
            automationNonTerminalCount == scenarioCount ? nil : "GuderianTest automation must avoid failed or blocked battles.",
            completedScenarioCount == scenarioCount ? nil : "Automation must produce full-campaign completion records.",
            aiReadyCount == scenarioCount ? nil : "Every scenario must pass native AI/event execution readiness.",
            balanceReadyCount == scenarioCount ? nil : "Every scenario must pass native balance/UX readiness.",
            metadataShipReady ? nil : "Cycle 250 metadata ship report must remain green.",
        ].compactMap { $0 }
    }

    private static func gates(
        scenarioCount: Int,
        nativePlayableCount: Int,
        automationNonTerminalCount: Int,
        completedScenarioCount: Int,
        aiReadyCount: Int,
        balanceReadyCount: Int,
        metadataShipReady: Bool
    ) -> [NativeCampaignShipGate] {
        [
            gate("catalog", "Campaign catalog", scenarioCount == 19, "\(scenarioCount) command-scope battles."),
            gate("native-playable", "Native playability", nativePlayableCount == scenarioCount, "\(nativePlayableCount)/\(scenarioCount) battles are native playable."),
            gate("automation", "GuderianTest automation", automationNonTerminalCount == scenarioCount, "\(automationNonTerminalCount)/\(scenarioCount) battles avoid failed or blocked status."),
            gate("completion", "Campaign completion", completedScenarioCount == scenarioCount, "\(completedScenarioCount)/\(scenarioCount) completion records."),
            gate("ai-events", "AI/event execution", aiReadyCount == scenarioCount, "\(aiReadyCount)/\(scenarioCount) board-state AI/event reports ready."),
            gate("balance-ux", "Balance and UX", balanceReadyCount == scenarioCount, "\(balanceReadyCount)/\(scenarioCount) balance/UX reports ready."),
            gate("metadata-ship", "Metadata ship baseline", metadataShipReady, "Cycle 250 metadata release gate remains green."),
        ]
    }

    private static func gate(_ id: String, _ title: String, _ passed: Bool, _ detail: String) -> NativeCampaignShipGate {
        NativeCampaignShipGate(
            id: id,
            title: title,
            status: passed ? .passed : .blocked,
            detail: detail
        )
    }
}

public enum NativePostShipAnalysisTheme: String, Codable, Hashable, Sendable {
    case playerAgency = "Player agency"
    case aiPressure = "AI pressure"
    case eventTiming = "Event timing"
    case historicalContext = "Historical context"
    case automationCoverage = "Automation coverage"
}

public struct NativePostShipAnalysisNote: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let theme: NativePostShipAnalysisTheme
    public let title: String
    public let detail: String

    public init(id: String, theme: NativePostShipAnalysisTheme, title: String, detail: String) {
        self.id = id
        self.theme = theme
        self.title = title
        self.detail = detail
    }
}

public struct NativePostShipAnalysisReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let readinessStatus: NativePlayabilityStatus
    public let aiEventExecutionReady: Bool
    public let balanceUXReady: Bool
    public let notes: [NativePostShipAnalysisNote]
    public let tuningBacklog: [String]

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        readinessStatus: NativePlayabilityStatus,
        aiEventExecutionReady: Bool,
        balanceUXReady: Bool,
        notes: [NativePostShipAnalysisNote],
        tuningBacklog: [String]
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.readinessStatus = readinessStatus
        self.aiEventExecutionReady = aiEventExecutionReady
        self.balanceUXReady = balanceUXReady
        self.notes = notes
        self.tuningBacklog = tuningBacklog
    }

    public var isPostShipAnalysisReady: Bool {
        readinessStatus == .nativePlayable &&
            aiEventExecutionReady &&
            balanceUXReady &&
            notes.count >= 5 &&
            tuningBacklog.allSatisfy { !$0.isEmpty }
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) post-ship analysis: \(notes.count) notes, \(tuningBacklog.count) tuning follow-ups."
    }
}

public enum NativePostShipAnalysisCatalog {
    public static let cycleRange = 401...425

    public static func report(for id: GuderianBattleID) -> NativePostShipAnalysisReport? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return report(for: scenario)
    }

    public static func report(for scenario: GuderianScenario) -> NativePostShipAnalysisReport {
        let readiness = NativePlayabilityArchitectureCatalog.readiness(for: scenario)
        let aiExecution = NativeAIEventExecutionCatalog.report(for: scenario)
        let balanceUX = NativeBalanceUXAuditCatalog.report(for: scenario)
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)

        return NativePostShipAnalysisReport(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            readinessStatus: readiness.status,
            aiEventExecutionReady: aiExecution.isNativeAIEventExecutionReady,
            balanceUXReady: balanceUX.isNativeBalanceUXReady,
            notes: [
                note(scenario, "agency", .playerAgency, "Agency check", balance.playerWinCondition),
                note(scenario, "pressure", .aiPressure, "AI pressure check", instance.aiProfile.strategicGoal),
                note(scenario, "events", .eventTiming, "Event timing check", "\(aiExecution.reinforcementResolutionCount) reinforcement timings and \(aiExecution.scenarioRuleResolutionCount) scenario rules resolve on the board."),
                note(scenario, "history", .historicalContext, "Historical framing", scenario.designIntent),
                note(scenario, "automation", .automationCoverage, "Automation coverage", balanceUX.summary),
            ],
            tuningBacklog: [
                "Keep \(scenario.title) within the \(balance.targetTurns.lowerBound)-\(balance.targetTurns.upperBound) turn pacing band.",
                "Preserve player score ceiling \(balance.maxPlayerScore) against mission target \(instance.victory.missionTargetScore).",
                "Review \(aiExecution.preferredObjectiveNames.joined(separator: ", ")) as the primary AI pressure focus during manual smoke.",
            ]
        )
    }

    public static var allReports: [NativePostShipAnalysisReport] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(report)
    }

    private static func note(
        _ scenario: GuderianScenario,
        _ suffix: String,
        _ theme: NativePostShipAnalysisTheme,
        _ title: String,
        _ detail: String
    ) -> NativePostShipAnalysisNote {
        NativePostShipAnalysisNote(
            id: "\(scenario.id.rawValue)-cycle-425-\(suffix)",
            theme: theme,
            title: title,
            detail: detail
        )
    }
}

public struct NativeCampaignSoakProbe: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let seed: UInt32
    public let openedNativeSession: Bool
    public let legalActionsAttempted: Int
    public let legalActionsSucceeded: Int
    public let phaseAdvances: Int
    public let blockingFindingCount: Int
    public let replaySignature: String

    public init(
        id: String,
        seed: UInt32,
        openedNativeSession: Bool,
        legalActionsAttempted: Int,
        legalActionsSucceeded: Int,
        phaseAdvances: Int,
        blockingFindingCount: Int,
        replaySignature: String
    ) {
        self.id = id
        self.seed = seed
        self.openedNativeSession = openedNativeSession
        self.legalActionsAttempted = legalActionsAttempted
        self.legalActionsSucceeded = legalActionsSucceeded
        self.phaseAdvances = phaseAdvances
        self.blockingFindingCount = blockingFindingCount
        self.replaySignature = replaySignature
    }

    public var isStable: Bool {
        openedNativeSession &&
            legalActionsAttempted > 0 &&
            legalActionsSucceeded > 0 &&
            phaseAdvances >= 2 &&
            blockingFindingCount == 0 &&
            !replaySignature.isEmpty
    }
}

public struct NativeCampaignSoakBattleReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let cycleStart: Int
    public let cycleEnd: Int
    public let probes: [NativeCampaignSoakProbe]

    public init(
        id: GuderianBattleID,
        title: String,
        cycleStart: Int,
        cycleEnd: Int,
        probes: [NativeCampaignSoakProbe]
    ) {
        self.id = id
        self.title = title
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.probes = probes
    }

    public var isSoakStable: Bool {
        probes.count == NativeCampaignSoakRunner.seedsPerBattle &&
            probes.allSatisfy(\.isStable) &&
            Set(probes.map(\.replaySignature)).count == probes.count
    }

    public var summary: String {
        "Cycle \(cycleStart)-\(cycleEnd) soak: \(probes.filter(\.isStable).count)/\(probes.count) deterministic probes stable."
    }
}

public struct NativeCampaignSoakSuiteReport: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let reports: [NativeCampaignSoakBattleReport]

    public init(cycleStart: Int, cycleEnd: Int, reports: [NativeCampaignSoakBattleReport]) {
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.reports = reports
    }

    public var stableBattleCount: Int {
        reports.filter(\.isSoakStable).count
    }

    public var isCampaignSoakReady: Bool {
        reports.count == GuderianCampaignCatalog.all.count &&
            reports.allSatisfy(\.isSoakStable)
    }
}

public enum NativeCampaignSoakRunner {
    public static let cycleRange = 426...450
    public static let seedsPerBattle = 3

    public static func runCampaign() -> NativeCampaignSoakSuiteReport {
        NativeCampaignSoakSuiteReport(
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            reports: GuderianCampaignCatalog.all
                .sorted { $0.order < $1.order }
                .map(runBattle)
        )
    }

    public static func runBattle(for id: GuderianBattleID) -> NativeCampaignSoakBattleReport? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return runBattle(scenario)
    }

    public static func runBattle(_ scenario: GuderianScenario) -> NativeCampaignSoakBattleReport {
        let probes = (0..<seedsPerBattle).map { offset in
            let seed = UInt32(450_000 + scenario.order * 10 + offset)
            let diagnostic = NativeBoardDiagnosticsRunner.runBattle(scenario, seed: seed)
            return NativeCampaignSoakProbe(
                id: "\(scenario.id.rawValue)-cycle-450-soak-\(offset)",
                seed: seed,
                openedNativeSession: diagnostic.openedNativeSession,
                legalActionsAttempted: diagnostic.legalActionsAttempted,
                legalActionsSucceeded: diagnostic.legalActionsSucceeded,
                phaseAdvances: diagnostic.phaseAdvances,
                blockingFindingCount: diagnostic.blockingFindingCount,
                replaySignature: signature(for: diagnostic, seed: seed)
            )
        }
        return NativeCampaignSoakBattleReport(
            id: scenario.id,
            title: scenario.title,
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            probes: probes
        )
    }

    private static func signature(
        for diagnostic: NativeBoardDiagnosticReport,
        seed: UInt32
    ) -> String {
        let final = diagnostic.finalSnapshot
        return [
            "\(diagnostic.id.rawValue)",
            "seed:\(seed)",
            "turn:\(final?.turnNumber ?? 0)",
            "phase:\(final?.phase.rawValue ?? "None")",
            "actions:\(diagnostic.legalActionsSucceeded)-\(diagnostic.legalActionsAttempted)",
            "findings:\(diagnostic.blockingFindingCount)",
        ].joined(separator: "|")
    }
}

private func textMatches(_ lhs: String, _ rhs: String) -> Bool {
    let lhsTokens = Set(textTokens(lhs))
    let rhsTokens = Set(textTokens(rhs))
    return !lhsTokens.isDisjoint(with: rhsTokens)
}

private func score(candidate: String, against hints: [String]) -> Int {
    let candidateTokens = Set(textTokens(candidate))
    guard !candidateTokens.isEmpty else {
        return 0
    }
    return hints.reduce(0) { partial, hint in
        partial + candidateTokens.intersection(Set(textTokens(hint))).count
    }
}

private func textTokens(_ text: String) -> [String] {
    text.lowercased()
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { $0.count > 2 }
}
