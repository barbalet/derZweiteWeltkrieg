import Foundation

public struct LateCareerStaffBattlefieldObjective: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioSide
    public let victoryPoints: Int
    public let description: String

    public init(id: String, name: String, side: ScenarioSide, victoryPoints: Int, description: String) {
        self.id = id
        self.name = name
        self.side = side
        self.victoryPoints = victoryPoints
        self.description = description
    }
}

public struct LateCareerStaffBattlefieldForce: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let side: ScenarioSide
    public let name: String
    public let role: String
    public let caveat: String

    public init(id: String, side: ScenarioSide, name: String, role: String, caveat: String) {
        self.id = id
        self.side = side
        self.name = name
        self.role = role
        self.caveat = caveat
    }
}

public struct LateCareerStaffBattlefieldRule: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let trigger: String
    public let effect: String

    public init(id: String, name: String, trigger: String, effect: String) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.effect = effect
    }
}

public struct LateCareerStaffBattlefieldMap: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let width: Double
    public let height: Double
    public let elements: [ScenarioMapElement]
    public let deploymentZones: [ScenarioDeploymentZone]
    public let sourceNotes: [ScenarioMapSourceNote]

    public init(
        id: String,
        title: String,
        width: Double = 100,
        height: Double = 64,
        elements: [ScenarioMapElement],
        deploymentZones: [ScenarioDeploymentZone],
        sourceNotes: [ScenarioMapSourceNote]
    ) {
        self.id = id
        self.title = title
        self.width = width
        self.height = height
        self.elements = elements
        self.deploymentZones = deploymentZones
        self.sourceNotes = sourceNotes
    }

    public var featureCount: Int {
        elements.count + deploymentZones.count
    }

    public var sourceNoteCount: Int {
        sourceNotes.count +
            elements.reduce(0) { $0 + $1.sourceNotes.count } +
            deploymentZones.reduce(0) { $0 + $1.sourceNotes.count }
    }

    public var waterFeatureCount: Int {
        elements.filter { $0.kind.isWaterFeature }.count
    }

    public var roadFeatureCount: Int {
        elements.filter { $0.kind.isRoadFeature }.count
    }

    public var railwayFeatureCount: Int {
        elements.filter { $0.kind.isRailwayFeature }.count
    }

    public var crossingFeatureCount: Int {
        elements.filter { $0.kind.isCrossingFeature }.count
    }

    public var settlementFeatureCount: Int {
        elements.filter { $0.kind.isSettlementFeature }.count
    }

    public var groundTerrainFeatureCount: Int {
        elements.filter { $0.kind.isGroundTerrainFeature }.count
    }

    public var hasRequiredStaffContextDetail: Bool {
        featureCount >= 24 &&
            waterFeatureCount >= 2 &&
            roadFeatureCount >= 3 &&
            railwayFeatureCount >= 1 &&
            crossingFeatureCount >= 2 &&
            settlementFeatureCount >= 3 &&
            groundTerrainFeatureCount >= 3 &&
            sourceNoteCount >= 1 &&
            elements.contains { $0.kind == .phaseLine } &&
            elements.allSatisfy { !$0.note.isEmpty } &&
            deploymentZones.allSatisfy { !$0.note.isEmpty }
    }
}

public struct LateCareerStaffBattlefield: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let order: Int
    public let title: String
    public let dateRange: GuderianCareerDateRange
    public let scope: GuderianCommandScope
    public let playerRole: String
    public let germanContext: String
    public let commandCaveat: String
    public let playableFraming: String
    public let map: LateCareerStaffBattlefieldMap
    public let objectives: [LateCareerStaffBattlefieldObjective]
    public let forces: [LateCareerStaffBattlefieldForce]
    public let rules: [LateCareerStaffBattlefieldRule]
    public let sourceLinks: [ScenarioSource]

    public init(
        id: String,
        order: Int,
        title: String,
        dateRange: GuderianCareerDateRange,
        scope: GuderianCommandScope,
        playerRole: String,
        germanContext: String,
        commandCaveat: String,
        playableFraming: String,
        map: LateCareerStaffBattlefieldMap,
        objectives: [LateCareerStaffBattlefieldObjective],
        forces: [LateCareerStaffBattlefieldForce],
        rules: [LateCareerStaffBattlefieldRule],
        sourceLinks: [ScenarioSource]
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.dateRange = dateRange
        self.scope = scope
        self.playerRole = playerRole
        self.germanContext = germanContext
        self.commandCaveat = commandCaveat
        self.playableFraming = playableFraming
        self.map = map
        self.objectives = objectives
        self.forces = forces
        self.rules = rules
        self.sourceLinks = sourceLinks
    }

    public var requiresCommandCaveat: Bool {
        scope.requiresCommandCaveat
    }

    public var linkedExpansionCandidate: GuderianCareerExpansionCandidate? {
        GuderianCareerScopeCatalog.expansionCandidate(for: id)
    }

    public var visibleCommandCaveatLabel: String {
        "\(scope.rawValue): \(commandCaveat)"
    }

    public var isLateCareerReady: Bool {
        linkedExpansionCandidate?.id == id &&
            !scope.allowsDirectBattlefieldScenario &&
            requiresCommandCaveat &&
            visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command") &&
            map.hasRequiredStaffContextDetail &&
            objectives.count >= 4 &&
            objectives.contains { $0.side == .player } &&
            objectives.contains { $0.side == .guderianAI } &&
            forces.count >= 2 &&
            forces.contains { $0.side == .player } &&
            forces.contains { $0.side == .guderianAI } &&
            forces.allSatisfy { !$0.caveat.isEmpty } &&
            rules.count >= 4 &&
            rules.allSatisfy { !$0.trigger.isEmpty && !$0.effect.isEmpty } &&
            !sourceLinks.isEmpty
    }

    public var isSetAReady: Bool {
        isLateCareerReady &&
            scope == .inspectorGeneralInfluence &&
            visibleCommandCaveatLabel.localizedCaseInsensitiveContains("Inspector General")
    }
}

public enum LateCareerStaffBattlefieldSetACatalog {
    public static let cycleRange = 626...630
    public static let battlefieldIDs = GuderianCareerScopeCatalog.lateCareerSetACandidateIDs

    public static let allBattlefields: [LateCareerStaffBattlefield] = [
        battlefield(
            "kursk-armored-force-pressure",
            germanContext: "German armored force, equipment, and doctrine pressure informed by the Inspector General role.",
            map: kurskMap,
            objectives: [
                objective("kursk-mine-belts", "Hold mine and anti-tank belts", .player, 5, "Keep the layered defensive belts active through the German pressure window."),
                objective("kursk-reserve-lanes", "Commit armored reserves", .player, 4, "Move Soviet reserves through marked lanes without losing the counterstroke option."),
                objective("kursk-rail-disruption", "Disrupt German rail supply", .player, 3, "Threaten rail and road supply points behind the armored spearhead."),
                objective("kursk-panzer-breakthrough", "German breakthrough pressure", .guderianAI, 5, "German pressure scores for crossing both fortified phase lines."),
            ],
            forces: [
                force("kursk-soviet-defenders", .player, "Soviet Central and Voronezh Front defenders", "Mine belts, anti-tank zones, artillery, and armored reserves.", "Player opposes German armored doctrine pressure."),
                force("kursk-german-pressure", .guderianAI, "German panzer and assault formations", "Armored breakthrough attempt through prepared defenses.", "Guderian is staff context as Inspector General, not field commander."),
            ],
            rules: [
                rule("kursk-mine-attrition", "Mine belt attrition", "German armor enters a mine-belt marker.", "Apply a movement stop and add a repair or morale pressure marker."),
                rule("kursk-at-depth", "Anti-tank depth", "Player holds two ridge or fortified markers at turn end.", "Increase Soviet defensive score and delay German breakthrough phase."),
                rule("kursk-reserve-counterstroke", "Reserve counterstroke", "A Soviet reserve objective is still linked to a road lane after the first phase line falls.", "Unlock a counterattack marker against the German spearhead."),
                rule("kursk-rail-strain", "Rail strain", "Soviet forces contest the rail spur or supply objective.", "Add German logistics friction before the next pressure move."),
            ]
        ),
        battlefield(
            "dnieper-withdrawal",
            germanContext: "German withdrawal, bridgehead, and armored-readiness pressure after the summer 1943 reverses.",
            map: dnieperMap,
            objectives: [
                objective("dnieper-force-crossings", "Force Dnieper crossings", .player, 5, "Secure crossing markers and prevent a clean German river defense."),
                objective("dnieper-isolate-bridgeheads", "Isolate bridgeheads", .player, 4, "Cut road and rail exits behind German bridgehead markers."),
                objective("dnieper-kiev-exit", "Open Kiev approach exits", .player, 3, "Keep east-west routes open for Soviet exploitation."),
                objective("dnieper-german-withdrawal", "German withdrawal corridors", .guderianAI, 5, "German pressure scores for preserving road and ferry exits."),
            ],
            forces: [
                force("dnieper-soviet-fronts", .player, "Soviet Front crossing detachments", "Engineers, rifle formations, artillery, and mobile groups forcing the river.", "Player drives the east-to-west crossing pressure."),
                force("dnieper-german-withdrawal", .guderianAI, "German retreat and bridgehead groups", "River defense, demolition teams, rear guards, and armored reserves.", "Guderian is inspector-level readiness context, not battlefield command."),
            ],
            rules: [
                rule("dnieper-assault-crossing", "Assault crossing", "Player controls a ferry, ford, or bridge marker.", "Create a temporary bridgehead objective on the west bank."),
                rule("dnieper-demolition-risk", "Demolition risk", "German pressure controls a crossing at phase end.", "Mark the crossing denied until engineers restore it."),
                rule("dnieper-wetland-friction", "Wetland friction", "Any force leaves a road inside marsh terrain.", "Reduce movement and expose the unit to artillery pressure."),
                rule("dnieper-bridgehead-isolation", "Bridgehead isolation", "Player controls both road and rail exits behind a bridgehead.", "Score isolation points and remove one German withdrawal option."),
            ]
        ),
        battlefield(
            "korsun-cherkassy-pocket",
            germanContext: "German relief and breakout pressure around a winter pocket in Ukraine.",
            map: korsunMap,
            objectives: [
                objective("korsun-seal-pocket", "Seal pocket roads", .player, 5, "Keep Shenderovka and Korsun road markers blocked against breakout attempts."),
                objective("korsun-hold-crossings", "Hold Gniloy Tikich crossings", .player, 4, "Control river crossings and thaw lanes around the breakout path."),
                objective("korsun-stop-relief", "Stop relief spearheads", .player, 4, "Deny German relief objectives before they touch the pocket phase line."),
                objective("korsun-breakout-route", "German breakout route", .guderianAI, 5, "German pressure scores by opening a continuous road to the western exit."),
            ],
            forces: [
                force("korsun-soviet-blocking", .player, "Soviet blocking and cavalry-mechanized groups", "Seal roads, crossings, and thaw lanes around the pocket.", "Player closes the pocket against German relief pressure."),
                force("korsun-german-pocket", .guderianAI, "German pocket and relief groups", "Breakout columns, relief armor, and rear guards.", "Guderian remains staff-context only."),
            ],
            rules: [
                rule("korsun-thaw-lanes", "Snow and thaw lanes", "A force moves through marsh or thaw terrain.", "Apply movement friction unless connected to a road marker."),
                rule("korsun-relief-contact", "Relief contact", "German pressure controls a relief objective and a pocket road in the same turn.", "Open a temporary breakout corridor."),
                rule("korsun-crossing-block", "Crossing block", "Player controls two Gniloy Tikich crossings.", "Prevent German breakout scoring this round."),
                rule("korsun-pocket-shrink", "Pocket shrink", "Both phase lines are under player control.", "Reduce German deployment depth and increase Soviet score."),
            ]
        ),
        battlefield(
            "kamenets-podolsky-pocket",
            germanContext: "Large spring 1944 armored escape corridor and mud-season withdrawal pressure.",
            map: kamenetsMap,
            objectives: [
                objective("kamenets-close-river-exits", "Close river exits", .player, 5, "Control Dniester and Southern Bug crossings around the pocket corridor."),
                objective("kamenets-cut-tarnopol-road", "Cut Tarnopol road", .player, 4, "Block road and rail movement through the western escape gate."),
                objective("kamenets-mud-pressure", "Exploit mud pressure", .player, 3, "Use mud and marsh markers to slow German columns before they consolidate."),
                objective("kamenets-german-escape", "German armored escape", .guderianAI, 5, "German pressure scores for opening a continuous westward corridor."),
            ],
            forces: [
                force("kamenets-soviet-mobile", .player, "Soviet mobile groups", "Tank, cavalry-mechanized, engineer, and rifle forces closing the pocket exits.", "Player tries to close the corridor before German armor slips away."),
                force("kamenets-german-pocket", .guderianAI, "German First Panzer Army escape groups", "Armored columns, rear guards, and bridge-control detachments.", "Guderian is inspector-level context before his General Staff role."),
            ],
            rules: [
                rule("kamenets-mud-corridor", "Mud corridor", "German pressure leaves a road while mud markers are active.", "Add friction and delay the escape corridor by one phase."),
                rule("kamenets-river-gate", "River gate", "Player controls a bridge and ferry pair.", "Close one escape option until German pressure retakes either marker."),
                rule("kamenets-road-net-cut", "Road net cut", "Player controls Tarnopol road and rail objectives together.", "Break German corridor continuity for scoring."),
                rule("kamenets-armored-slip", "Armored slip", "German pressure controls two consecutive road markers after the phase line.", "Open a temporary westward escape lane."),
            ]
        ),
    ]

    public static var allBattlefieldsReady: Bool {
        allBattlefields.count == battlefieldIDs.count &&
            allBattlefields.map(\.id) == battlefieldIDs &&
            allBattlefields.allSatisfy(\.isSetAReady)
    }

    public static func battlefield(for id: String) -> LateCareerStaffBattlefield? {
        allBattlefields.first { $0.id == id }
    }
}

private extension LateCareerStaffBattlefieldSetACatalog {
    static var kurskMap: LateCareerStaffBattlefieldMap {
        LateCareerStaffBattlefieldMap(
            id: "kursk-armored-force-pressure-map",
            title: "Kursk Armored Force Pressure Staff Map",
            elements: [
            lateLine("kursk-psel", "Psel River", .river, [lp(15, 26), lp(32, 25), lp(50, 28), lp(69, 25), lp(91, 23)], width: 4, "River line behind the defensive belts."),
            lateLine("kursk-seim", "Seim River rear line", .river, [lp(4, 43), lp(23, 39), lp(45, 37), lp(68, 34)], width: 3, "Rear water line behind the salient."),
            lateMarker("kursk-marsh-ground", "Low marsh ground", .marsh, .neutral, lp(42, 35), radius: 4, "Wet ground where armor leaves prepared lanes."),
            lateLine("kursk-oboyan-road", "Oboyan road", .road, [lp(5, 54), lp(24, 47), lp(43, 39), lp(62, 31), lp(88, 20)], width: 2, "Main armored pressure road."),
            lateLine("kursk-prokhorovka-road", "Prokhorovka reserve road", .road, [lp(43, 39), lp(56, 35), lp(73, 32), lp(94, 29)], width: 2, "Road for Soviet armored reserves."),
            lateLine("kursk-ponyri-road", "Ponyri road", .road, [lp(28, 20), lp(43, 28), lp(57, 36)], width: 2, "Northern approach into layered defenses."),
            lateLine("kursk-rail-spur", "Kursk rail spur", .railway, [lp(8, 48), lp(31, 42), lp(54, 36), lp(78, 30), lp(98, 27)], width: 2, "Rail supply and reserve corridor."),
            lateMarker("kursk-psel-bridge", "Psel bridge", .bridge, .neutral, lp(58, 27), radius: 3, "Bridge anchoring the reserve road."),
            lateMarker("kursk-seim-ford", "Seim ford", .ford, .neutral, lp(43, 37), radius: 3, "Minor crossing on the rear line."),
            lateMarker("kursk-oboyan", "Oboyan", .village, .player, lp(61, 31), radius: 3, "Road town on the breakthrough axis."),
            lateMarker("kursk-prokhorovka", "Prokhorovka", .village, .player, lp(82, 30), radius: 3, "Reserve assembly settlement."),
            lateMarker("kursk-ponyri", "Ponyri", .village, .player, lp(37, 26), radius: 3, "Northern defensive town."),
            lateMarker("kursk-rail-district", "Kursk rail district", .urbanDistrict, .player, lp(24, 45), radius: 4, "Rail district feeding the defense."),
            lateLine("kursk-mine-belt-one", "First mine belt", .fortifiedLine, [lp(29, 43), lp(45, 38), lp(63, 32)], width: 4, "Forward mine and anti-tank belt."),
            lateLine("kursk-mine-belt-two", "Second anti-tank belt", .fortifiedLine, [lp(43, 48), lp(59, 41), lp(79, 35)], width: 4, "Deeper anti-tank line for elastic defense."),
            lateLine("kursk-wooded-ridge", "Wooded ridge belt", .forest, [lp(37, 18), lp(56, 20), lp(76, 22)], width: 5, "Concealment for guns and reserves."),
            lateMarker("kursk-artillery-ridge", "Artillery ridge", .ridge, .player, lp(54, 33), radius: 4, "Observation ridge behind the mine belts."),
            lateMarker("kursk-tank-ditch", "Tank ditch line", .bunker, .player, lp(48, 37), radius: 3, "Anti-armor earthwork behind the first belt."),
            lateMarker("kursk-reserve-park", "Armored reserve park", .objective, .player, lp(76, 35), radius: 4, "Reserve objective for Soviet counterstroke timing."),
            lateMarker("kursk-panzer-spearhead", "Panzer spearhead pressure", .objective, .guderianAI, lp(18, 49), radius: 4, "German armored pressure entry."),
            lateLine("kursk-phase-forward", "Forward belt phase line", .phaseLine, [lp(30, 43), lp(48, 38), lp(66, 33)], width: 2, "Phase line for the first defensive belt."),
            lateLine("kursk-phase-reserve", "Reserve counterstroke phase line", .phaseLine, [lp(58, 39), lp(75, 34), lp(93, 29)], width: 2, "Phase line for Soviet reserve commitment."),
            ],
            deploymentZones: [
                lateZone("kursk-soviet-depth", "Soviet defense in depth", .player, lp(38, 20), 48, 28, "Player starts in layered belts, rail districts, and reserve lanes."),
                lateZone("kursk-german-entry", "German armored pressure", .guderianAI, lp(0, 42), 30, 18, "German pressure enters from the west and south-west."),
            ],
            sourceNotes: [lateSource("Kursk staff-context source", "https://en.wikipedia.org/wiki/Battle_of_Kursk", "Used as the source shelf for a staff-influence armored pressure battlefield.")]
        )
    }

    static var dnieperMap: LateCareerStaffBattlefieldMap {
        LateCareerStaffBattlefieldMap(
            id: "dnieper-withdrawal-map",
            title: "Dnieper Withdrawal and Bridgeheads Staff Map",
            elements: [
            lateLine("dnieper-main", "Dnieper River", .river, [lp(7, 44), lp(27, 39), lp(50, 34), lp(73, 29), lp(97, 25)], width: 6, "Major river obstacle and bridgehead line."),
            lateLine("dnieper-pripyat", "Pripyat wetland edge", .river, [lp(12, 22), lp(31, 25), lp(50, 29)], width: 3, "Northern wetland river edge."),
            lateMarker("dnieper-island-marsh", "Dnieper island marsh", .marsh, .neutral, lp(54, 33), radius: 5, "Marsh islands inside the crossing zone."),
            lateLine("dnieper-kiev-road", "Kiev west road", .road, [lp(18, 49), lp(35, 42), lp(54, 36), lp(78, 30)], width: 2, "Road from crossing sites toward Kiev."),
            lateLine("dnieper-cherkasy-road", "Cherkasy road", .road, [lp(37, 52), lp(51, 44), lp(66, 36), lp(84, 31)], width: 2, "Southern bridgehead road."),
            lateLine("dnieper-withdrawal-road", "German withdrawal road", .road, [lp(59, 31), lp(72, 27), lp(88, 22), lp(100, 18)], width: 2, "Road exit for German rear guards."),
            lateLine("dnieper-rail", "Kiev rail corridor", .railway, [lp(9, 47), lp(31, 42), lp(54, 36), lp(78, 30), lp(98, 24)], width: 2, "Rail corridor paralleling the river exits."),
            lateMarker("dnieper-kiev-bridge", "Kiev bridgehead bridge", .bridge, .neutral, lp(54, 35), radius: 3, "Bridgehead crossing near Kiev."),
            lateMarker("dnieper-cherkasy-bridge", "Cherkasy bridge", .bridge, .neutral, lp(67, 34), radius: 3, "Southern crossing point."),
            lateMarker("dnieper-ferry", "Dnieper ferry reach", .ferry, .neutral, lp(43, 37), radius: 3, "Improvised ferry reach for assault crossing."),
            lateMarker("dnieper-kiev-district", "Kiev approach district", .urbanDistrict, .player, lp(75, 29), radius: 4, "Urban approach tied to the bridgehead fight."),
            lateMarker("dnieper-cherkasy", "Cherkasy", .village, .player, lp(69, 35), radius: 3, "Southern crossing settlement."),
            lateMarker("dnieper-kaniv", "Kaniv", .village, .player, lp(56, 35), radius: 3, "Named river crossing town."),
            lateMarker("dnieper-pereyaslav", "Pereyaslav", .village, .player, lp(63, 27), radius: 3, "Road town behind bridgehead exits."),
            lateLine("dnieper-woods", "Riverbank woods", .forest, [lp(44, 23), lp(62, 22), lp(80, 20)], width: 5, "Wooded riverbank cover."),
            lateMarker("dnieper-bluff", "Dnieper bluff", .ridge, .neutral, lp(57, 31), radius: 4, "High ground overlooking crossings."),
            lateLine("dnieper-german-river-line", "German river defense line", .fortifiedLine, [lp(45, 36), lp(61, 31), lp(79, 26)], width: 3, "German rear guard line along the west bank."),
            lateMarker("dnieper-rail-yard", "Kiev rail yard", .urbanDistrict, .player, lp(70, 30), radius: 4, "Rail-yard control point behind the crossing exits."),
            lateMarker("dnieper-engineer-park", "Soviet engineer park", .objective, .player, lp(38, 41), radius: 4, "Engineer objective for creating bridgeheads."),
            lateMarker("dnieper-withdrawal-exit", "German withdrawal exit", .objective, .guderianAI, lp(94, 20), radius: 4, "German road exit objective."),
            lateLine("dnieper-phase-crossing", "Crossing phase line", .phaseLine, [lp(40, 39), lp(57, 34), lp(75, 29)], width: 2, "Phase line for establishing bridgeheads."),
            lateLine("dnieper-phase-isolation", "Bridgehead isolation phase line", .phaseLine, [lp(61, 31), lp(78, 26), lp(96, 21)], width: 2, "Phase line for cutting German exits."),
            ],
            deploymentZones: [
                lateZone("dnieper-soviet-east-bank", "Soviet east-bank assault groups", .player, lp(20, 34), 38, 24, "Soviet crossing detachments start east of the river."),
                lateZone("dnieper-german-west-bank", "German west-bank withdrawal", .guderianAI, lp(58, 18), 38, 24, "German rear guards hold crossings and exits."),
            ],
            sourceNotes: [lateSource("Dnieper withdrawal source", "https://en.wikipedia.org/wiki/Battle_of_the_Dnieper", "Used as the source shelf for river-crossing and bridgehead staff-context geography.")]
        )
    }

    static var korsunMap: LateCareerStaffBattlefieldMap {
        LateCareerStaffBattlefieldMap(
            id: "korsun-cherkassy-pocket-map",
            title: "Korsun-Cherkassy Pocket Staff Map",
            elements: [
            lateLine("korsun-gniloy-tikich", "Gniloy Tikich River", .river, [lp(19, 46), lp(37, 43), lp(56, 39), lp(76, 36)], width: 4, "River crossing on the breakout route."),
            lateLine("korsun-ros", "Ros River", .river, [lp(12, 27), lp(32, 29), lp(53, 31), lp(74, 30)], width: 3, "Northern river edge around Korsun."),
            lateMarker("korsun-thaw-marsh", "Thaw marsh lane", .marsh, .neutral, lp(58, 43), radius: 5, "Snow and thaw ground around the breakout road."),
            lateLine("korsun-shenderovka-road", "Shenderovka road", .road, [lp(15, 50), lp(32, 47), lp(50, 43), lp(68, 38), lp(87, 34)], width: 2, "Main breakout road."),
            lateLine("korsun-lysyanka-road", "Lysyanka relief road", .road, [lp(43, 57), lp(55, 48), lp(69, 39), lp(83, 30)], width: 2, "German relief approach road."),
            lateLine("korsun-cherkassy-road", "Cherkassy road", .road, [lp(54, 32), lp(68, 29), lp(86, 26), lp(100, 24)], width: 2, "Road toward the eastern pocket edge."),
            lateLine("korsun-rail", "Korsun rail spur", .railway, [lp(7, 41), lp(30, 39), lp(54, 34), lp(78, 29)], width: 2, "Rail spur through the pocket."),
            lateMarker("korsun-tikich-bridge", "Tikich bridge", .bridge, .neutral, lp(55, 40), radius: 3, "Bridge on the breakout route."),
            lateMarker("korsun-ros-ford", "Ros ford", .ford, .neutral, lp(47, 31), radius: 3, "Minor northern crossing."),
            lateMarker("korsun-winter-ferry", "Winter ferry reach", .ferry, .neutral, lp(66, 37), radius: 3, "Improvised river crossing in the thaw."),
            lateMarker("korsun-town", "Korsun", .urbanDistrict, .guderianAI, lp(39, 37), radius: 4, "Pocket town and road junction."),
            lateMarker("korsun-cherkassy", "Cherkassy", .village, .player, lp(88, 26), radius: 3, "Eastern road settlement."),
            lateMarker("korsun-shenderovka", "Shenderovka", .village, .guderianAI, lp(50, 43), radius: 3, "Breakout road village."),
            lateMarker("korsun-lysyanka", "Lysyanka", .village, .neutral, lp(74, 36), radius: 3, "Relief road settlement."),
            lateLine("korsun-woods", "Pocket wood belt", .forest, [lp(25, 22), lp(44, 24), lp(64, 25)], width: 5, "Wood cover around the northern pocket edge."),
            lateMarker("korsun-snow-ridge", "Snow ridge", .ridge, .neutral, lp(61, 36), radius: 4, "High ground beside the breakout crossing."),
            lateLine("korsun-blocking-line", "Soviet blocking line", .fortifiedLine, [lp(51, 42), lp(66, 38), lp(82, 34)], width: 3, "Blocking line across breakout lanes."),
            lateMarker("korsun-pocket-core", "Pocket core", .objective, .guderianAI, lp(38, 38), radius: 5, "German pocket survival objective."),
            lateMarker("korsun-relief-spearhead", "Relief spearhead", .objective, .guderianAI, lp(70, 43), radius: 4, "German relief objective."),
            lateMarker("korsun-soviet-seal", "Pocket seal marker", .objective, .player, lp(63, 38), radius: 4, "Soviet objective for sealing the breakout."),
            lateLine("korsun-phase-pocket", "Pocket shrink phase line", .phaseLine, [lp(34, 39), lp(52, 39), lp(70, 36)], width: 2, "Phase line as the pocket contracts."),
            lateLine("korsun-phase-breakout", "Breakout phase line", .phaseLine, [lp(50, 43), lp(67, 38), lp(86, 34)], width: 2, "Phase line for the breakout road."),
            ],
            deploymentZones: [
                lateZone("korsun-soviet-ring", "Soviet blocking ring", .player, lp(50, 25), 42, 24, "Soviet blocking forces surround the crossing and road net."),
                lateZone("korsun-german-pocket", "German pocket and relief pressure", .guderianAI, lp(22, 36), 50, 22, "German pocket and relief forces contest a breakout route."),
            ],
            sourceNotes: [lateSource("Korsun-Cherkassy source", "https://en.wikipedia.org/wiki/Korsun%E2%80%93Cherkassy_pocket", "Used as the source shelf for a winter pocket and breakout battlefield.")]
        )
    }

    static var kamenetsMap: LateCareerStaffBattlefieldMap {
        LateCareerStaffBattlefieldMap(
            id: "kamenets-podolsky-pocket-map",
            title: "Kamenets-Podolsky Pocket Staff Map",
            elements: [
            lateLine("kamenets-dniester", "Dniester River", .river, [lp(12, 51), lp(32, 47), lp(54, 43), lp(76, 38), lp(98, 34)], width: 5, "Southern river exit line."),
            lateLine("kamenets-southern-bug", "Southern Bug approach", .river, [lp(18, 25), lp(38, 28), lp(58, 31), lp(80, 34)], width: 3, "Northern river approach around the pocket."),
            lateMarker("kamenets-mud-marsh", "Mud-season marsh", .marsh, .neutral, lp(55, 45), radius: 5, "Mud terrain constraining the escape corridor."),
            lateLine("kamenets-tarnopol-road", "Tarnopol road", .road, [lp(8, 40), lp(28, 40), lp(50, 41), lp(73, 39), lp(96, 36)], width: 2, "Westward escape road."),
            lateLine("kamenets-proskurov-road", "Proskurov road", .road, [lp(43, 30), lp(55, 36), lp(70, 41)], width: 2, "Northern road into the pocket."),
            lateLine("kamenets-chortkov-road", "Chortkov road", .road, [lp(50, 44), lp(62, 51), lp(77, 58)], width: 2, "Southern road around river exits."),
            lateLine("kamenets-rail", "Tarnopol rail corridor", .railway, [lp(6, 43), lp(29, 41), lp(52, 40), lp(76, 37), lp(99, 35)], width: 2, "Rail corridor through the escape gate."),
            lateMarker("kamenets-dniester-bridge", "Dniester bridge", .bridge, .neutral, lp(58, 42), radius: 3, "Bridge on the southern river exit."),
            lateMarker("kamenets-bug-bridge", "Southern Bug bridge", .bridge, .neutral, lp(58, 31), radius: 3, "Northern bridge on the pocket edge."),
            lateMarker("kamenets-dniester-ferry", "Dniester ferry reach", .ferry, .neutral, lp(72, 39), radius: 3, "Fallback crossing for escape columns."),
            lateMarker("kamenets-rail-bridge", "Rail bridge", .bridge, .neutral, lp(50, 40), radius: 3, "Rail bridge controlling corridor continuity."),
            lateMarker("kamenets-town", "Kamenets-Podolsky", .urbanDistrict, .guderianAI, lp(55, 43), radius: 4, "Urban pocket hub."),
            lateMarker("kamenets-tarnopol", "Tarnopol", .village, .neutral, lp(86, 36), radius: 3, "Western road exit settlement."),
            lateMarker("kamenets-proskurov", "Proskurov", .village, .player, lp(44, 30), radius: 3, "Northern approach settlement."),
            lateMarker("kamenets-chortkov", "Chortkov", .village, .player, lp(72, 55), radius: 3, "Southern road settlement."),
            lateLine("kamenets-wooded-hills", "Wooded hill belt", .forest, [lp(36, 20), lp(56, 23), lp(77, 26)], width: 5, "Wooded hills on the northern flank."),
            lateMarker("kamenets-corridor-ridge", "Corridor ridge", .ridge, .neutral, lp(66, 39), radius: 4, "High ground overlooking the escape road."),
            lateLine("kamenets-soviet-block-line", "Soviet blocking line", .fortifiedLine, [lp(49, 41), lp(66, 39), lp(83, 36)], width: 3, "Blocking line across the westward corridor."),
            lateMarker("kamenets-river-exit", "River exit control", .objective, .player, lp(61, 42), radius: 4, "Player objective for closing river exits."),
            lateMarker("kamenets-west-corridor", "West corridor gate", .objective, .guderianAI, lp(94, 36), radius: 4, "German escape corridor objective."),
            lateMarker("kamenets-road-net-cut", "Road net cut marker", .objective, .player, lp(73, 39), radius: 4, "Player objective for cutting Tarnopol road traffic."),
            lateLine("kamenets-phase-pocket", "Pocket corridor phase line", .phaseLine, [lp(48, 42), lp(66, 40), lp(85, 37)], width: 2, "Phase line for corridor continuity."),
            lateLine("kamenets-phase-river", "River exit phase line", .phaseLine, [lp(53, 43), lp(70, 39), lp(94, 35)], width: 2, "Phase line for river exit control."),
            ],
            deploymentZones: [
                lateZone("kamenets-soviet-mobile", "Soviet mobile closing groups", .player, lp(40, 24), 48, 35, "Soviet mobile groups pressure river exits and road junctions."),
                lateZone("kamenets-german-corridor", "German escape corridor", .guderianAI, lp(46, 34), 50, 23, "German armored columns try to preserve a westward road corridor."),
            ],
            sourceNotes: [lateSource("Kamenets-Podolsky source", "https://en.wikipedia.org/wiki/Kamenets-Podolsky_pocket", "Used as the source shelf for spring pocket and escape-corridor geography.")]
        )
    }

    static func battlefield(
        _ candidateID: String,
        germanContext: String,
        map: LateCareerStaffBattlefieldMap,
        objectives: [LateCareerStaffBattlefieldObjective],
        forces: [LateCareerStaffBattlefieldForce],
        rules: [LateCareerStaffBattlefieldRule]
    ) -> LateCareerStaffBattlefield {
        guard let candidate = GuderianCareerScopeCatalog.expansionCandidate(for: candidateID) else {
            preconditionFailure("Missing late-career candidate: \(candidateID)")
        }

        return LateCareerStaffBattlefield(
            id: candidate.id,
            order: candidate.order,
            title: candidate.title,
            dateRange: candidate.dateRange,
            scope: candidate.scope,
            playerRole: candidate.playerRole,
            germanContext: germanContext,
            commandCaveat: "Staff-context only: not a Guderian field command battle.",
            playableFraming: candidate.playableFraming,
            map: map,
            objectives: objectives,
            forces: forces,
            rules: rules,
            sourceLinks: candidate.sourceLinks
        )
    }

    static func objective(_ id: String, _ name: String, _ side: ScenarioSide, _ points: Int, _ description: String) -> LateCareerStaffBattlefieldObjective {
        LateCareerStaffBattlefieldObjective(id: id, name: name, side: side, victoryPoints: points, description: description)
    }

    static func force(_ id: String, _ side: ScenarioSide, _ name: String, _ role: String, _ caveat: String) -> LateCareerStaffBattlefieldForce {
        LateCareerStaffBattlefieldForce(id: id, side: side, name: name, role: role, caveat: caveat)
    }

    static func rule(_ id: String, _ name: String, _ trigger: String, _ effect: String) -> LateCareerStaffBattlefieldRule {
        LateCareerStaffBattlefieldRule(id: id, name: name, trigger: trigger, effect: effect)
    }
}

private func lateLine(
    _ id: String,
    _ name: String,
    _ kind: ScenarioMapElementKind,
    _ points: [ScenarioMapPoint],
    width: Double = 3,
    _ note: String
) -> ScenarioMapElement {
    ScenarioMapElement(id: id, name: name, kind: kind, points: points, strokeWidth: width, note: note)
}

private func lateMarker(
    _ id: String,
    _ name: String,
    _ kind: ScenarioMapElementKind,
    _ side: ScenarioSide,
    _ point: ScenarioMapPoint,
    radius: Double,
    _ note: String
) -> ScenarioMapElement {
    ScenarioMapElement(id: id, name: name, kind: kind, side: side, points: [point], radius: radius, note: note)
}

private func lateZone(
    _ id: String,
    _ name: String,
    _ side: ScenarioSide,
    _ origin: ScenarioMapPoint,
    _ width: Double,
    _ height: Double,
    _ note: String
) -> ScenarioDeploymentZone {
    ScenarioDeploymentZone(id: id, name: name, side: side, origin: origin, width: width, height: height, note: note)
}

private func lateSource(_ title: String, _ urlString: String, _ note: String) -> ScenarioMapSourceNote {
    ScenarioMapSourceNote(title: title, url: URL(string: urlString), note: note)
}

private func lp(_ x: Double, _ y: Double) -> ScenarioMapPoint {
    ScenarioMapPoint(x, y)
}
