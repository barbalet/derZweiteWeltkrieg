import Foundation

public enum NativeBattleSide: String, Codable, Hashable, Sendable {
    case player = "Player"
    case guderianAI = "Guderian AI"
    case neutral = "Neutral"
}

public enum NativeBattleUnitMobility: String, Codable, Hashable, Sendable {
    case infantry = "Infantry"
    case armor = "Armor"
    case gun = "Gun"
    case artillery = "Artillery"
    case engineer = "Engineer"
    case command = "Command"
    case cavalry = "Cavalry"
    case armoredTrain = "Armored train"
    case airPressure = "Air pressure"
    case navalSupport = "Naval support"
}

public enum NativeBattleWeaponRole: String, Codable, Hashable, Sendable {
    case smallArms = "Small arms"
    case machineGun = "Machine gun"
    case antiTank = "Anti-tank"
    case armorGun = "Armor gun"
    case artillery = "Artillery"
    case demolition = "Demolition"
    case command = "Command"
    case reconnaissance = "Reconnaissance"
    case airSupport = "Air support"
    case navalSupport = "Naval support"
}

public enum NativeBattleTerrainKind: String, Codable, Hashable, Sendable {
    case road = "Road"
    case river = "River"
    case town = "Town"
    case forest = "Forest"
    case ridge = "Ridge"
    case bunker = "Bunker"
    case fortifiedLine = "Fortified line"
    case bridge = "Bridge"
    case objective = "Objective"
    case artilleryPark = "Artillery park"
    case airPressure = "Air pressure"
}

public enum NativeBattleObjectiveKind: String, Codable, Hashable, Sendable {
    case hold = "Hold"
    case delay = "Delay"
    case withdraw = "Withdraw"
    case disrupt = "Disrupt"
    case preserve = "Preserve"
    case evacuate = "Evacuate"
    case counterattack = "Counterattack"
    case breakout = "Breakout"
    case deny = "Deny"
    case score = "Score"
}

public enum NativeBattleEventKind: String, Codable, Hashable, Sendable {
    case trigger = "Trigger"
    case reinforcement = "Reinforcement"
    case pacing = "Pacing"
    case tutorial = "Tutorial"
}

public struct NativeBattleCoordinate: Codable, Hashable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct NativeBattleFrame: Codable, Hashable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct NativeBattleWeaponProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let role: NativeBattleWeaponRole
    public let rangeBand: String
    public let effect: String

    public init(id: String, name: String, role: NativeBattleWeaponRole, rangeBand: String, effect: String) {
        self.id = id
        self.name = name
        self.role = role
        self.rangeBand = rangeBand
        self.effect = effect
    }
}

public struct NativeBattleUnit: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: NativeBattleSide
    public let mobility: NativeBattleUnitMobility
    public let role: String
    public let historicalNote: String
    public let deploymentZoneID: String
    public let startingPosition: NativeBattleCoordinate
    public let weapons: [NativeBattleWeaponProfile]

    public init(
        id: String,
        name: String,
        side: NativeBattleSide,
        mobility: NativeBattleUnitMobility,
        role: String,
        historicalNote: String,
        deploymentZoneID: String,
        startingPosition: NativeBattleCoordinate,
        weapons: [NativeBattleWeaponProfile]
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.mobility = mobility
        self.role = role
        self.historicalNote = historicalNote
        self.deploymentZoneID = deploymentZoneID
        self.startingPosition = startingPosition
        self.weapons = weapons
    }
}

public struct NativeBattleTerrainFeature: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: NativeBattleTerrainKind
    public let side: NativeBattleSide
    public let points: [NativeBattleCoordinate]
    public let radius: Double
    public let movementCostHint: Double
    public let blocksLineOfSightHint: Bool
    public let note: String

    public init(
        id: String,
        name: String,
        kind: NativeBattleTerrainKind,
        side: NativeBattleSide,
        points: [NativeBattleCoordinate],
        radius: Double,
        movementCostHint: Double,
        blocksLineOfSightHint: Bool,
        note: String
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.side = side
        self.points = points
        self.radius = radius
        self.movementCostHint = movementCostHint
        self.blocksLineOfSightHint = blocksLineOfSightHint
        self.note = note
    }
}

public struct NativeBattleDeploymentZone: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: NativeBattleSide
    public let origin: NativeBattleCoordinate
    public let width: Double
    public let height: Double
    public let capacityHint: Int
    public let note: String

    public init(
        id: String,
        name: String,
        side: NativeBattleSide,
        origin: NativeBattleCoordinate,
        width: Double,
        height: Double,
        capacityHint: Int,
        note: String
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.origin = origin
        self.width = width
        self.height = height
        self.capacityHint = capacityHint
        self.note = note
    }
}

public struct NativeBattleObjective: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: NativeBattleSide
    public let kind: NativeBattleObjectiveKind
    public let victoryPoints: Int
    public let timing: String
    public let description: String
    public let anchorTerrainID: String?
    public let position: NativeBattleCoordinate

    public init(
        id: String,
        name: String,
        side: NativeBattleSide,
        kind: NativeBattleObjectiveKind,
        victoryPoints: Int,
        timing: String,
        description: String,
        anchorTerrainID: String?,
        position: NativeBattleCoordinate
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.kind = kind
        self.victoryPoints = victoryPoints
        self.timing = timing
        self.description = description
        self.anchorTerrainID = anchorTerrainID
        self.position = position
    }
}

public struct NativeBattleReinforcement: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let side: NativeBattleSide
    public let turnWindow: String
    public let unitName: String
    public let entryCondition: String
    public let role: String
    public let entryZoneID: String

    public init(
        id: String,
        side: NativeBattleSide,
        turnWindow: String,
        unitName: String,
        entryCondition: String,
        role: String,
        entryZoneID: String
    ) {
        self.id = id
        self.side = side
        self.turnWindow = turnWindow
        self.unitName = unitName
        self.entryCondition = entryCondition
        self.role = role
        self.entryZoneID = entryZoneID
    }
}

public struct NativeBattleEventTrigger: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: NativeBattleEventKind
    public let title: String
    public let timing: String
    public let condition: String
    public let effect: String
    public let sourceID: String

    public init(
        id: String,
        kind: NativeBattleEventKind,
        title: String,
        timing: String,
        condition: String,
        effect: String,
        sourceID: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.timing = timing
        self.condition = condition
        self.effect = effect
        self.sourceID = sourceID
    }
}

public struct NativeBattleAIOrder: Identifiable, Codable, Hashable, Sendable {
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

public struct NativeBattleAIProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let postureName: String
    public let strategicGoal: String
    public let targetPriorities: [String]
    public let orders: [NativeBattleAIOrder]

    public init(
        id: GuderianBattleID,
        postureName: String,
        strategicGoal: String,
        targetPriorities: [String],
        orders: [NativeBattleAIOrder]
    ) {
        self.id = id
        self.postureName = postureName
        self.strategicGoal = strategicGoal
        self.targetPriorities = targetPriorities
        self.orders = orders
    }
}

public struct NativeBattleScoreRule: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: NativeBattleSide
    public let victoryPoints: Int
    public let timing: String
    public let description: String

    public init(
        id: String,
        name: String,
        side: NativeBattleSide,
        victoryPoints: Int,
        timing: String,
        description: String
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.victoryPoints = victoryPoints
        self.timing = timing
        self.description = description
    }
}

public struct NativeBattleVictoryProfile: Codable, Hashable, Sendable {
    public let targetTurns: ClosedRange<Int>
    public let missionTargetScore: Int
    public let playerWinCondition: String
    public let pressureLimit: String
    public let scoreRules: [NativeBattleScoreRule]
    public let outcomeBands: [ScenarioOutcomeBand]

    public init(
        targetTurns: ClosedRange<Int>,
        missionTargetScore: Int,
        playerWinCondition: String,
        pressureLimit: String,
        scoreRules: [NativeBattleScoreRule],
        outcomeBands: [ScenarioOutcomeBand]
    ) {
        self.targetTurns = targetTurns
        self.missionTargetScore = missionTargetScore
        self.playerWinCondition = playerWinCondition
        self.pressureLimit = pressureLimit
        self.scoreRules = scoreRules
        self.outcomeBands = outcomeBands
    }
}

public struct NativeEngineUnitSpawn: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: NativeBattleSide
    public let mobility: NativeBattleUnitMobility
    public let x: Double
    public let y: Double
    public let deploymentZoneID: String
    public let weaponRoleIDs: [String]
}

public struct NativeEngineObjectiveSpawn: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: NativeBattleSide
    public let x: Double
    public let y: Double
    public let victoryPoints: Int
}

public struct NativeEngineTerrainSpawn: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: NativeBattleTerrainKind
    public let points: [NativeBattleCoordinate]
    public let radius: Double
    public let movementCostHint: Double
    public let blocksLineOfSightHint: Bool
}

public struct NativeEngineBattleBlueprint: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let seed: UInt32
    public let sourceInstanceID: String
    public let engineBoardFrame: NativeBattleFrame
    public let missionTargetScore: Int
    public let units: [NativeEngineUnitSpawn]
    public let objectives: [NativeEngineObjectiveSpawn]
    public let terrain: [NativeEngineTerrainSpawn]
    public let eventTriggerIDs: [String]

    public var isCompleteForScenarioLoader: Bool {
        missionTargetScore > 0 &&
            !units.isEmpty &&
            units.allSatisfy { !$0.weaponRoleIDs.isEmpty } &&
            !objectives.isEmpty &&
            !terrain.isEmpty
    }
}

public struct NativeBattleInstance: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let instanceID: String
    public let title: String
    public let order: Int
    public let theater: CampaignTheater
    public let playerPosture: PlayerPosture
    public let frame: NativeBattleFrame
    public let terrain: [NativeBattleTerrainFeature]
    public let deploymentZones: [NativeBattleDeploymentZone]
    public let objectives: [NativeBattleObjective]
    public let units: [NativeBattleUnit]
    public let reinforcements: [NativeBattleReinforcement]
    public let events: [NativeBattleEventTrigger]
    public let aiProfile: NativeBattleAIProfile
    public let victory: NativeBattleVictoryProfile

    public var requiresNativeScenarioLoader: Bool {
        true
    }

    public var isModeledForNativeGameplay: Bool {
        !units.isEmpty &&
            units.allSatisfy { !$0.weapons.isEmpty } &&
            !terrain.isEmpty &&
            deploymentZones.filter { $0.side != .neutral }.count >= 2 &&
            !objectives.isEmpty &&
            !aiProfile.orders.isEmpty &&
            victory.missionTargetScore > 0
    }

    public func engineBlueprint(seed: UInt32) -> NativeEngineBattleBlueprint {
        let engineFrame = NativeBattleFrame(width: 72, height: 48)
        let unitSpawns = units.map { unit in
            let point = engineCoordinate(unit.startingPosition, from: frame, to: engineFrame)
            return NativeEngineUnitSpawn(
                id: unit.id,
                name: unit.name,
                side: unit.side,
                mobility: unit.mobility,
                x: point.x,
                y: point.y,
                deploymentZoneID: unit.deploymentZoneID,
                weaponRoleIDs: unit.weapons.map(\.role.rawValue)
            )
        }
        let objectiveSpawns = objectives.map { objective in
            let point = engineCoordinate(objective.position, from: frame, to: engineFrame)
            return NativeEngineObjectiveSpawn(
                id: objective.id,
                name: objective.name,
                side: objective.side,
                x: point.x,
                y: point.y,
                victoryPoints: max(1, objective.victoryPoints)
            )
        }
        let terrainSpawns = terrain.map { feature in
            NativeEngineTerrainSpawn(
                id: feature.id,
                name: feature.name,
                kind: feature.kind,
                points: feature.points.map { engineCoordinate($0, from: frame, to: engineFrame) },
                radius: scaledRadius(feature.radius, from: frame, to: engineFrame),
                movementCostHint: feature.movementCostHint,
                blocksLineOfSightHint: feature.blocksLineOfSightHint
            )
        }

        return NativeEngineBattleBlueprint(
            id: id,
            seed: seed,
            sourceInstanceID: instanceID,
            engineBoardFrame: engineFrame,
            missionTargetScore: victory.missionTargetScore,
            units: unitSpawns,
            objectives: objectiveSpawns,
            terrain: terrainSpawns,
            eventTriggerIDs: events.map(\.id)
        )
    }

    private func engineCoordinate(
        _ coordinate: NativeBattleCoordinate,
        from source: NativeBattleFrame,
        to destination: NativeBattleFrame
    ) -> NativeBattleCoordinate {
        NativeBattleCoordinate(
            x: clamp((coordinate.x / source.width) * destination.width, min: 0, max: destination.width),
            y: clamp((coordinate.y / source.height) * destination.height, min: 0, max: destination.height)
        )
    }

    private func scaledRadius(_ radius: Double, from source: NativeBattleFrame, to destination: NativeBattleFrame) -> Double {
        let scale = min(destination.width / source.width, destination.height / source.height)
        return max(0, radius * scale)
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}

public enum NativeBattleInstanceCatalog {
    public static let modelCycleRange = 261...270

    public static func instance(for scenario: GuderianScenario) -> NativeBattleInstance {
        NativeBattleInstanceBuilder(bundle: ScenarioContentCatalog.bundle(for: scenario)).build()
    }

    public static func instance(for id: GuderianBattleID) -> NativeBattleInstance? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return instance(for: scenario)
    }

    public static var allInstances: [NativeBattleInstance] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(instance)
    }
}

private struct NativeBattleInstanceBuilder {
    let bundle: ScenarioContentBundle

    func build() -> NativeBattleInstance {
        let scenario = bundle.scenario
        let frame = NativeBattleFrame(width: bundle.mapLayout.width, height: bundle.mapLayout.height)
        let deploymentZones = makeDeploymentZones()

        return NativeBattleInstance(
            id: scenario.id,
            instanceID: "\(scenario.id.rawValue)-native-v1",
            title: scenario.title,
            order: scenario.order,
            theater: scenario.theater,
            playerPosture: scenario.playerPosture,
            frame: frame,
            terrain: makeTerrain(),
            deploymentZones: deploymentZones,
            objectives: makeObjectives(),
            units: makeUnits(deploymentZones: deploymentZones),
            reinforcements: makeReinforcements(deploymentZones: deploymentZones),
            events: makeEvents(),
            aiProfile: makeAIProfile(),
            victory: makeVictory()
        )
    }

    private func makeTerrain() -> [NativeBattleTerrainFeature] {
        bundle.mapLayout.elements.map { element in
            NativeBattleTerrainFeature(
                id: element.id,
                name: element.name,
                kind: nativeTerrainKind(element.kind),
                side: nativeSide(element.side),
                points: element.points.map(nativeCoordinate),
                radius: element.radius,
                movementCostHint: movementCostHint(for: element.kind),
                blocksLineOfSightHint: blocksLineOfSightHint(for: element.kind),
                note: element.note
            )
        }
    }

    private func makeDeploymentZones() -> [NativeBattleDeploymentZone] {
        bundle.mapLayout.deploymentZones.map { zone in
            let side = nativeSide(zone.side)
            let capacity = bundle.setup.units.filter { nativeSide($0.side) == side }.count
            return NativeBattleDeploymentZone(
                id: zone.id,
                name: zone.name,
                side: side,
                origin: nativeCoordinate(zone.origin),
                width: zone.width,
                height: zone.height,
                capacityHint: capacity,
                note: zone.note
            )
        }
    }

    private func makeObjectives() -> [NativeBattleObjective] {
        if bundle.scenario.id == .tucholaForest {
            return makeTucholaForestObjectives()
        }

        let anchors = objectiveAnchors()
        return bundle.scenario.objectives.enumerated().map { index, objective in
            let anchor = anchors.isEmpty ? nil : anchors[index % anchors.count]
            let position = anchor.flatMap(center) ?? NativeBattleCoordinate(x: bundle.mapLayout.width / 2, y: bundle.mapLayout.height / 2)
            return NativeBattleObjective(
                id: "\(bundle.scenario.id.rawValue)-objective-\(index)-\(slug(objective.name))",
                name: objective.name,
                side: anchor.map { nativeSide($0.side) } ?? .player,
                kind: objectiveKind(name: objective.name, description: objective.description),
                victoryPoints: objective.victoryPoints,
                timing: "Scenario objective",
                description: objective.description,
                anchorTerrainID: anchor?.id,
                position: position
            )
        }
    }

    private func makeUnits(deploymentZones: [NativeBattleDeploymentZone]) -> [NativeBattleUnit] {
        var sideOffsets: [NativeBattleSide: Int] = [:]
        return bundle.setup.units.map { unit in
            let side = nativeSide(unit.side)
            let zone = zone(for: side, in: deploymentZones)
            let offset = sideOffsets[side, default: 0]
            sideOffsets[side] = offset + 1
            let count = max(1, bundle.setup.units.filter { nativeSide($0.side) == side }.count)
            return NativeBattleUnit(
                id: unit.id,
                name: unit.name,
                side: side,
                mobility: mobility(for: unit),
                role: unit.role,
                historicalNote: unit.historicalNote,
                deploymentZoneID: zone.id,
                startingPosition: tucholaForestStartingPosition(for: unit.id) ?? position(in: zone, index: offset, count: count),
                weapons: weaponProfiles(for: unit)
            )
        }
    }

    private func makeReinforcements(deploymentZones: [NativeBattleDeploymentZone]) -> [NativeBattleReinforcement] {
        bundle.balance.reinforcements.map { reinforcement in
            let side = nativeSide(reinforcement.side)
            return NativeBattleReinforcement(
                id: reinforcement.id,
                side: side,
                turnWindow: reinforcement.turnWindow,
                unitName: reinforcement.unitName,
                entryCondition: reinforcement.entryCondition,
                role: reinforcement.role,
                entryZoneID: zone(for: side, in: deploymentZones).id
            )
        }
    }

    private func makeEvents() -> [NativeBattleEventTrigger] {
        let setupTriggers = bundle.setup.triggers.map { trigger in
            NativeBattleEventTrigger(
                id: trigger.id,
                kind: .trigger,
                title: trigger.name,
                timing: "Scenario trigger",
                condition: trigger.condition,
                effect: trigger.effect,
                sourceID: trigger.id
            )
        }
        let reinforcements = bundle.balance.reinforcements.map { reinforcement in
            NativeBattleEventTrigger(
                id: "\(reinforcement.id)-event",
                kind: .reinforcement,
                title: reinforcement.unitName,
                timing: reinforcement.turnWindow,
                condition: reinforcement.entryCondition,
                effect: reinforcement.role,
                sourceID: reinforcement.id
            )
        }
        let pacingRules = bundle.balance.pacingRules.map { rule in
            NativeBattleEventTrigger(
                id: "\(rule.id)-event",
                kind: .pacing,
                title: rule.name,
                timing: rule.turnWindow,
                condition: rule.turnWindow,
                effect: rule.effect,
                sourceID: rule.id
            )
        }
        let tutorials = bundle.setup.tutorialSteps.map { step in
            NativeBattleEventTrigger(
                id: "\(step.id)-event",
                kind: .tutorial,
                title: step.title,
                timing: "Tutorial",
                condition: "Player reaches tutorial step",
                effect: step.instruction,
                sourceID: step.id
            )
        }
        let polishRules = PolishCampaignSystemCatalog.profile(for: bundle.scenario)?.specialRules.map { rule in
            NativeBattleEventTrigger(
                id: "\(rule.id)-native-polish-rule",
                kind: .trigger,
                title: rule.name,
                timing: "Native Polish rule",
                condition: rule.trigger,
                effect: rule.effect,
                sourceID: rule.id
            )
        } ?? []
        let franceRules = FranceCampaignSystemCatalog.profile(for: bundle.scenario)?.specialRules.map { rule in
            NativeBattleEventTrigger(
                id: "\(rule.id)-native-france-rule",
                kind: .trigger,
                title: rule.name,
                timing: "Native France rule",
                condition: rule.trigger,
                effect: rule.effect,
                sourceID: rule.id
            )
        } ?? []
        let easternRules = EasternFrontCampaignSystemCatalog.profile(for: bundle.scenario)?.specialRules.map { rule in
            NativeBattleEventTrigger(
                id: "\(rule.id)-native-eastern-front-rule",
                kind: .trigger,
                title: rule.name,
                timing: "Native Eastern Front rule",
                condition: rule.trigger,
                effect: rule.effect,
                sourceID: rule.id
            )
        } ?? []
        return setupTriggers + reinforcements + pacingRules + tutorials + polishRules + franceRules + easternRules
    }

    private func makeAIProfile() -> NativeBattleAIProfile {
        NativeBattleAIProfile(
            id: bundle.aiPlan.id,
            postureName: bundle.aiPlan.postureName,
            strategicGoal: bundle.aiPlan.strategicGoal,
            targetPriorities: bundle.aiPlan.targetPriorities,
            orders: bundle.aiPlan.orders.map { order in
                NativeBattleAIOrder(
                    id: order.id,
                    turnWindow: order.turnWindow,
                    kind: order.kind,
                    target: order.target,
                    instruction: order.instruction
                )
            }
        )
    }

    private func makeVictory() -> NativeBattleVictoryProfile {
        NativeBattleVictoryProfile(
            targetTurns: bundle.balance.targetTurns,
            missionTargetScore: max(1, bundle.balance.maxPlayerScore),
            playerWinCondition: bundle.balance.playerWinCondition,
            pressureLimit: bundle.balance.germanPressureLimit,
            scoreRules: bundle.balance.scoreChannels.map { channel in
                NativeBattleScoreRule(
                    id: channel.id,
                    name: channel.name,
                    side: nativeSide(channel.side),
                    victoryPoints: channel.victoryPoints,
                    timing: channel.timing,
                    description: channel.description
                )
            },
            outcomeBands: bundle.balance.outcomeBands
        )
    }

    private func objectiveAnchors() -> [ScenarioMapElement] {
        let preferredKinds: Set<ScenarioMapElementKind> = [.objective, .bridge, .bunker, .town, .fortifiedLine, .artillery]
        return bundle.mapLayout.elements.filter { preferredKinds.contains($0.kind) }
    }

    private func makeTucholaForestObjectives() -> [NativeBattleObjective] {
        [
            tucholaObjective(
                id: "tuchola-pruszcz-bridge",
                name: "Pruszcz bridge / Pila-Mlyn bridge",
                side: .player,
                kind: .deny,
                victoryPoints: 4,
                timing: "Turns 1-3",
                description: "Block, demolish, or keep the Brda crossings at Pruszcz and Pila-Mlyn contested before German engineers can reopen the road."
            ),
            tucholaObjective(
                id: "tuchola-chojnice",
                name: "Chojnice road hub / Tuchola road hub",
                side: .player,
                kind: .hold,
                victoryPoints: 3,
                timing: "Turns 2-5",
                description: "Keep at least one Chojnice-Tuchola forest road hub contested so German motorized infantry cannot freely fix the corridor defense."
            ),
            tucholaObjective(
                id: "tuchola-krojanty",
                name: "Krojanty cavalry screen",
                side: .player,
                kind: .disrupt,
                victoryPoints: 2,
                timing: "Turns 2-3",
                description: "Use the Pomeranian Cavalry Brigade screen to disrupt reconnaissance, then pull it back before armor closes."
            ),
            tucholaObjective(
                id: "tuchola-bydgoszcz",
                name: "Bydgoszcz withdrawal",
                side: .player,
                kind: .withdraw,
                victoryPoints: 5,
                timing: "Turns 4-8",
                description: "Exit coherent Polish infantry, cavalry, command, and anti-tank assets toward Bydgoszcz before the pincer seals the corridor."
            ),
        ]
    }

    private func tucholaObjective(
        id: String,
        name: String,
        side: NativeBattleSide,
        kind: NativeBattleObjectiveKind,
        victoryPoints: Int,
        timing: String,
        description: String
    ) -> NativeBattleObjective {
        let anchor = bundle.mapLayout.elements.first { $0.id == id }
        return NativeBattleObjective(
            id: "\(id)-objective",
            name: name,
            side: side,
            kind: kind,
            victoryPoints: victoryPoints,
            timing: timing,
            description: description,
            anchorTerrainID: anchor?.id,
            position: anchor.flatMap(center) ?? NativeBattleCoordinate(x: bundle.mapLayout.width / 2, y: bundle.mapLayout.height / 2)
        )
    }

    private func center(of element: ScenarioMapElement) -> NativeBattleCoordinate? {
        if element.points.isEmpty {
            return nil
        }
        let sum = element.points.reduce((x: 0.0, y: 0.0)) { partial, point in
            (partial.x + point.x, partial.y + point.y)
        }
        return NativeBattleCoordinate(x: sum.x / Double(element.points.count), y: sum.y / Double(element.points.count))
    }

    private func zone(for side: NativeBattleSide, in zones: [NativeBattleDeploymentZone]) -> NativeBattleDeploymentZone {
        if let zone = zones.first(where: { $0.side == side }) {
            return zone
        }
        if let zone = zones.first(where: { $0.side != .neutral }) {
            return zone
        }
        return NativeBattleDeploymentZone(
            id: "\(bundle.scenario.id.rawValue)-fallback-zone",
            name: "Fallback deployment",
            side: side,
            origin: NativeBattleCoordinate(x: 0, y: 0),
            width: bundle.mapLayout.width,
            height: bundle.mapLayout.height,
            capacityHint: bundle.setup.units.count,
            note: "Generated fallback only used when authored deployment zones are missing."
        )
    }

    private func position(in zone: NativeBattleDeploymentZone, index: Int, count: Int) -> NativeBattleCoordinate {
        let columns = max(1, Int(ceil(sqrt(Double(count)))))
        let rows = max(1, Int(ceil(Double(count) / Double(columns))))
        let column = index % columns
        let row = index / columns
        let x = zone.origin.x + zone.width * (Double(column + 1) / Double(columns + 1))
        let y = zone.origin.y + zone.height * (Double(min(row, rows - 1) + 1) / Double(rows + 1))
        return NativeBattleCoordinate(
            x: clamp(x, min: 0, max: bundle.mapLayout.width),
            y: clamp(y, min: 0, max: bundle.mapLayout.height)
        )
    }

    private func tucholaForestStartingPosition(for unitID: String) -> NativeBattleCoordinate? {
        guard bundle.scenario.id == .tucholaForest else {
            return nil
        }

        switch unitID {
        case "tuchola-9th-infantry":
            return NativeBattleCoordinate(x: 31, y: 39)
        case "tuchola-27th-infantry":
            return NativeBattleCoordinate(x: 43, y: 34)
        case "tuchola-czersk-group":
            return NativeBattleCoordinate(x: 22, y: 28)
        case "tuchola-cavalry":
            return NativeBattleCoordinate(x: 24, y: 18)
        case "tuchola-at-guns":
            return NativeBattleCoordinate(x: 36, y: 31)
        case "tuchola-demolition-parties":
            return NativeBattleCoordinate(x: 49, y: 37)
        case "tuchola-3rd-panzer":
            return NativeBattleCoordinate(x: 7, y: 35)
        case "tuchola-motorized-divisions":
            return NativeBattleCoordinate(x: 15, y: 27)
        case "tuchola-engineers":
            return NativeBattleCoordinate(x: 10, y: 40)
        case "tuchola-pincer":
            return NativeBattleCoordinate(x: 73, y: 18)
        default:
            return nil
        }
    }

    private func weaponProfiles(for unit: ScenarioUnitCard) -> [NativeBattleWeaponProfile] {
        let text = "\(unit.name) \(unit.role) \(unit.historicalNote)".lowercased()
        var roles: [NativeBattleWeaponRole] = []
        if containsAny(text, ["anti-tank", "at gun", "t-34", "kv", "char b1", "tank", "panzer", "armor", "armored", "ft-17"]) {
            roles.append(.antiTank)
        }
        if containsAny(text, ["tank", "panzer", "armor", "armored", "char b1", "t-34", "kv", "ft-17"]) {
            roles.append(.armorGun)
        }
        if containsAny(text, ["artillery", "gun", "howitzer", "train"]) {
            roles.append(.artillery)
        }
        if containsAny(text, ["engineer", "pioneer", "demolition", "bridge"]) {
            roles.append(.demolition)
        }
        if containsAny(text, ["cavalry", "recon", "screen", "patrol"]) {
            roles.append(.reconnaissance)
        }
        if containsAny(text, ["air", "stuka", "luftwaffe"]) {
            roles.append(.airSupport)
        }
        if containsAny(text, ["naval", "destroyer", "harbor"]) {
            roles.append(.navalSupport)
        }
        if containsAny(text, ["command", "hq", "headquarters"]) {
            roles.append(.command)
        }
        if containsAny(text, ["machine-gun", "machine gun", "mg", "bunker"]) {
            roles.append(.machineGun)
        }
        roles.append(.smallArms)

        var uniqueRoles: [NativeBattleWeaponRole] = []
        for role in roles where !uniqueRoles.contains(role) {
            uniqueRoles.append(role)
        }

        return uniqueRoles
            .enumerated()
            .map { index, role in
                NativeBattleWeaponProfile(
                    id: "\(unit.id)-weapon-\(index)-\(slug(role.rawValue))",
                    name: role.rawValue,
                    role: role,
                    rangeBand: rangeBand(for: role),
                    effect: effect(for: role)
                )
            }
    }

    private func mobility(for unit: ScenarioUnitCard) -> NativeBattleUnitMobility {
        let text = "\(unit.name) \(unit.role) \(unit.historicalNote)".lowercased()
        if containsAny(text, ["air", "stuka", "luftwaffe"]) { return .airPressure }
        if containsAny(text, ["naval", "destroyer"]) { return .navalSupport }
        if containsAny(text, ["armored train", "train"]) { return .armoredTrain }
        if containsAny(text, ["pincer pressure", "pressure marker"]) { return .command }
        if containsAny(text, ["command", "hq", "headquarters"]) { return .command }
        if containsAny(text, ["engineer", "pioneer", "demolition"]) { return .engineer }
        if containsAny(text, ["artillery"]) { return .artillery }
        if containsAny(text, ["anti-tank", "field gun", "gun section", "guns"]) { return .gun }
        if containsAny(text, ["tank", "panzer", "armor", "armored", "char b1", "t-34", "kv", "ft-17"]) { return .armor }
        if containsAny(text, ["cavalry"]) { return .cavalry }
        return .infantry
    }

    private func objectiveKind(name: String, description: String) -> NativeBattleObjectiveKind {
        let text = "\(name) \(description)".lowercased()
        if containsAny(text, ["withdraw", "exit", "escape"]) { return .withdraw }
        if containsAny(text, ["evacuat", "embark"]) { return .evacuate }
        if containsAny(text, ["preserve", "save", "survival"]) { return .preserve }
        if containsAny(text, ["counterattack", "raid", "strike", "ambush"]) { return .counterattack }
        if containsAny(text, ["breakout", "open"]) { return .breakout }
        if containsAny(text, ["deny", "block", "destroy", "demolish"]) { return .deny }
        if containsAny(text, ["delay", "buy time", "hold through"]) { return .delay }
        if containsAny(text, ["disrupt", "slow"]) { return .disrupt }
        if containsAny(text, ["hold", "control", "contest"]) { return .hold }
        return .score
    }

    private func nativeTerrainKind(_ kind: ScenarioMapElementKind) -> NativeBattleTerrainKind {
        switch kind {
        case .road:
            return .road
        case .river:
            return .river
        case .town:
            return .town
        case .forest:
            return .forest
        case .ridge:
            return .ridge
        case .bunker:
            return .bunker
        case .fortifiedLine:
            return .fortifiedLine
        case .bridge:
            return .bridge
        case .objective, .deployment:
            return .objective
        case .artillery:
            return .artilleryPark
        case .airPressure:
            return .airPressure
        }
    }

    private func nativeSide(_ side: ScenarioSide) -> NativeBattleSide {
        switch side {
        case .player:
            return .player
        case .guderianAI:
            return .guderianAI
        case .neutral:
            return .neutral
        }
    }

    private func nativeSide(_ side: ScenarioUnitSide) -> NativeBattleSide {
        switch side {
        case .player:
            return .player
        case .guderianAI:
            return .guderianAI
        }
    }

    private func nativeSide(_ side: ScenarioScoringSide) -> NativeBattleSide {
        switch side {
        case .player:
            return .player
        case .guderianAI:
            return .guderianAI
        case .contested:
            return .neutral
        }
    }

    private func nativeCoordinate(_ point: ScenarioMapPoint) -> NativeBattleCoordinate {
        NativeBattleCoordinate(x: point.x, y: point.y)
    }

    private func movementCostHint(for kind: ScenarioMapElementKind) -> Double {
        switch kind {
        case .road, .bridge:
            return 0.75
        case .river:
            return 4
        case .forest, .ridge, .bunker, .fortifiedLine, .town:
            return 1.5
        case .objective, .artillery, .airPressure, .deployment:
            return 1
        }
    }

    private func blocksLineOfSightHint(for kind: ScenarioMapElementKind) -> Bool {
        switch kind {
        case .forest, .ridge, .town, .bunker, .fortifiedLine:
            return true
        case .road, .river, .bridge, .objective, .artillery, .airPressure, .deployment:
            return false
        }
    }

    private func rangeBand(for role: NativeBattleWeaponRole) -> String {
        switch role {
        case .smallArms, .machineGun, .demolition, .command:
            return "close"
        case .antiTank, .armorGun, .reconnaissance:
            return "medium"
        case .artillery, .airSupport, .navalSupport:
            return "long"
        }
    }

    private func effect(for role: NativeBattleWeaponRole) -> String {
        switch role {
        case .smallArms:
            return "baseline infantry fire"
        case .machineGun:
            return "suppression and bunker fire lane"
        case .antiTank:
            return "vehicle threat and road denial"
        case .armorGun:
            return "armored direct fire"
        case .artillery:
            return "indirect suppression"
        case .demolition:
            return "bridge, bunker, or obstacle action"
        case .command:
            return "command, scoring, or cohesion support"
        case .reconnaissance:
            return "screening and pursuit disruption"
        case .airSupport:
            return "timed air-pressure event"
        case .navalSupport:
            return "off-board naval fire or evacuation support"
        }
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    private func slug(_ value: String) -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        var output = ""
        var lastWasDash = false
        for character in value.lowercased() {
            if allowed.contains(character) {
                output.append(character)
                lastWasDash = false
            } else if !lastWasDash {
                output.append("-")
                lastWasDash = true
            }
        }
        while output.first == "-" {
            output.removeFirst()
        }
        while output.last == "-" {
            output.removeLast()
        }
        return output.isEmpty ? "item" : output
    }
}
