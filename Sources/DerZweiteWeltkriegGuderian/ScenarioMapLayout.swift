import Foundation

public enum ScenarioMapElementKind: String, Codable, Hashable, Sendable {
    case road = "Road"
    case river = "River"
    case town = "Town"
    case forest = "Forest"
    case ridge = "Ridge"
    case bunker = "Bunker"
    case fortifiedLine = "Fortified line"
    case bridge = "Bridge"
    case objective = "Objective"
    case artillery = "Artillery"
    case airPressure = "Air pressure"
    case deployment = "Deployment"
}

public enum ScenarioSide: String, Codable, Hashable, Sendable {
    case player = "Player"
    case guderianAI = "Guderian AI"
    case neutral = "Neutral"
}

public struct ScenarioMapPoint: Codable, Hashable, Sendable {
    public let x: Double
    public let y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

public struct ScenarioMapElement: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: ScenarioMapElementKind
    public let side: ScenarioSide
    public let points: [ScenarioMapPoint]
    public let radius: Double
    public let strokeWidth: Double
    public let note: String

    public init(
        id: String,
        name: String,
        kind: ScenarioMapElementKind,
        side: ScenarioSide = .neutral,
        points: [ScenarioMapPoint],
        radius: Double = 0,
        strokeWidth: Double = 3,
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.side = side
        self.points = points
        self.radius = radius
        self.strokeWidth = strokeWidth
        self.note = note
    }
}

public struct ScenarioDeploymentZone: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioSide
    public let origin: ScenarioMapPoint
    public let width: Double
    public let height: Double
    public let note: String

    public init(
        id: String,
        name: String,
        side: ScenarioSide,
        origin: ScenarioMapPoint,
        width: Double,
        height: Double,
        note: String
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.origin = origin
        self.width = width
        self.height = height
        self.note = note
    }
}

public struct ScenarioMapLayout: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let width: Double
    public let height: Double
    public let elements: [ScenarioMapElement]
    public let deploymentZones: [ScenarioDeploymentZone]

    public init(
        id: GuderianBattleID,
        title: String,
        width: Double = 100,
        height: Double = 64,
        elements: [ScenarioMapElement],
        deploymentZones: [ScenarioDeploymentZone]
    ) {
        self.id = id
        self.title = title
        self.width = width
        self.height = height
        self.elements = elements
        self.deploymentZones = deploymentZones
    }

    public var objectiveElements: [ScenarioMapElement] {
        elements.filter { $0.kind == .objective }
    }
}

public enum ScenarioMapCatalog {
    public static func layout(for scenario: GuderianScenario) -> ScenarioMapLayout {
        switch scenario.id {
        case .tucholaForest:
            return tucholaForest
        case .wizna:
            return wizna
        case .brzescLitewski:
            return brzescLitewski
        case .kobryn:
            return kobryn
        case .sedan:
            return sedan
        case .stonne:
            return stonne
        case .montcornet:
            return montcornet
        case .amiensAbbeville:
            return amiensAbbeville
        case .boulogne:
            return boulogne
        case .calais:
            return calais
        case .dunkirk:
            return dunkirk
        case .fallRot:
            return fallRot
        case .bialystokMinsk:
            return bialystokMinsk
        case .smolensk:
            return smolensk
        case .roslavlNovozybkov:
            return roslavlNovozybkov
        case .kiev:
            return kiev
        case .bryansk:
            return bryansk
        case .mtsensk:
            return mtsensk
        case .moscowTulaKashira:
            return moscowTulaKashira
        }
    }

    private static let tucholaForest = ScenarioMapLayout(
        id: .tucholaForest,
        title: "Tuchola Forest Corridor",
        elements: [
            line("tuchola-corridor-road", "Chojnice-Tuchola-Bydgoszcz road", .road, [p(6, 28), p(21, 31), p(39, 34), p(61, 42), p(93, 54)], note: "Main withdrawal and pursuit route through the corridor."),
            line("tuchola-rail", "Chojnice rail line", .road, [p(2, 18), p(19, 24), p(42, 29), p(72, 31), p(99, 36)], width: 2, note: "Rail corridor and early Chojnice pressure axis."),
            line("tuchola-brda", "Brda River", .river, [p(8, 43), p(27, 39), p(47, 37), p(72, 45), p(99, 49)], width: 5, note: "Bridge obstacle and demolition line."),
            line("tuchola-forest-belt", "Tuchola forest belt", .forest, [p(13, 14), p(32, 20), p(55, 18), p(80, 25), p(94, 33)], width: 9, note: "Dense forest funnels armor onto the road net."),
            marker("tuchola-chojnice", "Chojnice", .town, .player, p(18, 25), radius: 5, note: "Rail and road hub where German motorized pressure opens."),
            marker("tuchola-town", "Tuchola", .town, .player, p(43, 33), radius: 5, note: "Infantry strongpoint and midgame delay objective."),
            marker("tuchola-pruszcz-bridge", "Pruszcz bridge", .bridge, .neutral, p(32, 38), radius: 3, note: "Early bridge fight over the Brda."),
            marker("tuchola-pila-mlyn", "Pila-Mlyn bridge", .bridge, .neutral, p(49, 37), radius: 3, note: "Demolition site and secondary crossing."),
            marker("tuchola-krojanty", "Krojanty screen", .objective, .player, p(24, 18), radius: 4, note: "Cavalry screen disrupts pursuit, then must withdraw."),
            marker("tuchola-bydgoszcz", "Bydgoszcz withdrawal", .objective, .player, p(88, 54), radius: 5, note: "Exit lane for coherent Polish formations."),
            marker("tuchola-german-pincer", "East Prussia pincer", .airPressure, .guderianAI, p(73, 18), radius: 5, note: "Operational pressure that converts the battle from delay to withdrawal."),
            marker("tuchola-panzer-entry", "XIX Corps spearhead", .objective, .guderianAI, p(7, 35), radius: 4, note: "German armored entry pressure from Western Pomerania."),
        ],
        deploymentZones: [
            zone("tuchola-polish-corridor", "Pomeranian Army corridor defense", .player, p(16, 20), 44, 29, "Polish infantry, anti-tank guns, demolition teams, and cavalry screens start around the forest road net."),
            zone("tuchola-german-assembly", "German pincer assembly", .guderianAI, p(0, 11), 30, 36, "XIX Panzer Corps pushes from the west while pincer pressure appears from the north and east."),
        ]
    )

    private static let brzescLitewski = ScenarioMapLayout(
        id: .brzescLitewski,
        title: "Brzesc Fortress Defense",
        elements: [
            line("brzesc-bug", "Bug River", .river, [p(8, 18), p(31, 24), p(55, 25), p(87, 18)], width: 5, note: "River edge and fortress approach."),
            line("brzesc-muchawiec", "Muchawiec River", .river, [p(23, 56), p(41, 45), p(58, 35), p(73, 26)], width: 4, note: "Secondary obstacle dividing the town and fortress approaches."),
            line("brzesc-rail", "Rail line", .road, [p(4, 46), p(29, 42), p(49, 38), p(78, 34), p(97, 29)], width: 2, note: "Armored-train support and German approach lane."),
            marker("brzesc-citadel", "Brzesc Citadel", .fortifiedLine, .player, p(52, 32), radius: 7, note: "Central fortress objective."),
            marker("brzesc-town", "Brzesc town", .town, .player, p(43, 43), radius: 6, note: "Urban delay zone before the citadel."),
            marker("brzesc-armored-train", "Armored train track", .artillery, .player, p(35, 40), radius: 4, note: "Rail-bound fire support and evacuation cover."),
            marker("brzesc-ft17", "FT-17 tank park", .objective, .player, p(59, 45), radius: 4, note: "Obsolete tanks used as mobile strongpoints."),
            marker("brzesc-panzer-entry", "XIX Corps west entry", .objective, .guderianAI, p(7, 44), radius: 4, note: "German panzer and motorized assault approach."),
            marker("brzesc-south-exit", "South fallback gate", .objective, .player, p(78, 55), radius: 4, note: "Withdrawal route after citadel delay."),
        ],
        deploymentZones: [
            zone("brzesc-polish-fortress", "Polish fortress defense", .player, p(34, 24), 43, 28, "Improvised infantry battalions, engineers, artillery, armored trains, and FT-17 tanks defend the town and citadel."),
            zone("brzesc-german-assault", "XIX Corps assault columns", .guderianAI, p(0, 35), 29, 22, "German panzer, motorized infantry, and artillery pressure the west and rail approaches."),
        ]
    )

    private static let kobryn = ScenarioMapLayout(
        id: .kobryn,
        title: "Kobryn Rearguard",
        elements: [
            line("kobryn-road-west", "Brzesc-Kobryn road", .road, [p(3, 37), p(25, 35), p(47, 34), p(70, 31), p(96, 28)], note: "German motorized infantry approach and Polish withdrawal route."),
            line("kobryn-eastern-road", "Eastern withdrawal road", .road, [p(46, 39), p(63, 48), p(82, 54), p(99, 58)], width: 2, note: "Exit path for Operational Group Polesie."),
            line("kobryn-canal", "Mukhavets marsh/canal line", .river, [p(4, 51), p(27, 48), p(53, 51), p(79, 46), p(100, 42)], width: 4, note: "Wet terrain and partial obstacle around Kobryn."),
            marker("kobryn-town", "Kobryn", .town, .player, p(47, 35), radius: 7, note: "Road hub and rearguard anchor."),
            marker("kobryn-reserve-line", "60th Reserve Infantry line", .fortifiedLine, .player, p(57, 42), radius: 5, note: "Improvised defensive line covering eastern exits."),
            marker("kobryn-west-roadblock", "Western roadblock", .objective, .player, p(29, 35), radius: 4, note: "Delay motorized pressure before the town fight."),
            marker("kobryn-east-exit", "Eastern exit", .objective, .player, p(87, 55), radius: 5, note: "Force-preservation scoring route."),
            marker("kobryn-german-fix", "2nd Motorized pressure", .objective, .guderianAI, p(12, 38), radius: 4, note: "German effort to fix and envelop the rearguard."),
        ],
        deploymentZones: [
            zone("kobryn-polish-rearguard", "Operational Group Polesie", .player, p(34, 28), 42, 25, "Polish reserve infantry, guns, and rearguard detachments start around Kobryn and the eastern road."),
            zone("kobryn-german-entry", "German motorized entry", .guderianAI, p(0, 27), 28, 25, "German 2nd Motorized Infantry Division attacks from the west."),
        ]
    )

    private static let wizna = ScenarioMapLayout(
        id: .wizna,
        title: "Wizna Fortified Line",
        elements: [
            line("narew-road", "Narew approach road", .road, [p(4, 52), p(30, 42), p(58, 33), p(94, 22)], note: "Main armored approach toward the bunker line."),
            line("narew-river", "Narew river line", .river, [p(0, 29), p(24, 25), p(47, 27), p(72, 20), p(100, 18)], width: 6, note: "River obstacle shaping the German attack lanes."),
            line("wizna-line", "Polish bunker belt", .fortifiedLine, [p(32, 19), p(43, 24), p(52, 30), p(61, 38)], width: 4, note: "Forward fortified positions."),
            marker("kurpiki-bunker", "Kurpiki bunker", .bunker, .player, p(39, 24), radius: 3, note: "Tutorial strongpoint for cover and anti-tank fire."),
            marker("gelczyn-bunker", "Gelczyn bunker", .bunker, .player, p(52, 31), radius: 3, note: "Central defense objective."),
            marker("gora-strekowa", "Gora Strekowa HQ", .objective, .player, p(61, 39), radius: 4, note: "Command position and final hold objective."),
            marker("german-artillery", "German artillery park", .artillery, .guderianAI, p(15, 47), radius: 4, note: "Pressure source for tutorial bombardment events."),
        ],
        deploymentZones: [
            zone("polish-line", "Polish fortified line", .player, p(30, 16), 38, 30, "Player deploys bunkers, machine guns, and anti-tank guns along the line."),
            zone("german-approach", "German assembly area", .guderianAI, p(0, 39), 24, 21, "German armor and infantry enter from the western approach."),
        ]
    )

    private static let sedan = ScenarioMapLayout(
        id: .sedan,
        title: "Sedan Meuse Crossing",
        elements: [
            line("meuse", "Meuse river", .river, [p(0, 29), p(19, 25), p(41, 28), p(62, 35), p(100, 38)], width: 7, note: "Major crossing obstacle."),
            line("sedan-road", "Sedan-Gaulier road", .road, [p(18, 57), p(35, 43), p(49, 34), p(67, 22), p(91, 9)], note: "Axis of German bridgehead expansion."),
            marker("sedan-town", "Sedan", .town, .player, p(40, 38), radius: 8, note: "Urban anchor for French defense."),
            marker("gaulier-bridge", "Gaulier bridge site", .bridge, .neutral, p(48, 31), radius: 3, note: "Primary German crossing objective."),
            marker("wadelincourt-bridge", "Wadelincourt bridge site", .bridge, .neutral, p(58, 34), radius: 3, note: "Secondary engineer crossing."),
            marker("french-artillery", "French artillery positions", .artillery, .player, p(73, 48), radius: 6, note: "Defensive fire support and morale objective."),
            marker("air-pressure", "Stuka pressure lane", .airPressure, .guderianAI, p(30, 15), radius: 7, note: "Timed disruption event against defenders."),
            marker("bridgehead", "Bridgehead perimeter", .objective, .neutral, p(61, 27), radius: 7, note: "German expansion goal; player scores by denying it."),
        ],
        deploymentZones: [
            zone("french-bank", "French near-bank defense", .player, p(34, 30), 52, 27, "French infantry, guns, and observers defend the east bank and artillery parks."),
            zone("german-west-bank", "German west-bank assembly", .guderianAI, p(0, 7), 32, 35, "German engineers, infantry, and panzers prepare the forced crossing."),
        ]
    )

    private static let stonne = ScenarioMapLayout(
        id: .stonne,
        title: "Stonne Heights Counterattack",
        elements: [
            line("stonne-sedan-road", "Sedan-Stonne road", .road, [p(6, 54), p(25, 44), p(45, 34), p(70, 22), p(93, 14)], note: "German bridgehead flank route."),
            line("stonne-mont-dieu-woods", "Mont-Dieu woods", .forest, [p(18, 21), p(38, 20), p(58, 18), p(82, 24)], width: 8, note: "Concealment and approach cover."),
            marker("stonne-village", "Stonne village", .town, .neutral, p(52, 33), radius: 7, note: "Repeatedly contested village objective."),
            marker("stonne-heights", "Stonne heights", .ridge, .player, p(58, 25), radius: 6, note: "Observation and bridgehead threat."),
            marker("stonne-char-b1", "Char B1 shock point", .objective, .player, p(44, 39), radius: 4, note: "French heavy-tank counterattack start."),
            marker("stonne-bridgehead-risk", "Bridgehead risk line", .objective, .player, p(69, 25), radius: 4, note: "Player scores by threatening the Sedan bridgehead flank."),
            marker("stonne-german-support", "German support line", .artillery, .guderianAI, p(31, 48), radius: 5, note: "Motorized infantry, anti-tank, and artillery support."),
        ],
        deploymentZones: [
            zone("stonne-french-counterattack", "French armor and infantry", .player, p(37, 23), 32, 24, "French heavy tanks and infantry stage to contest Stonne and the heights."),
            zone("stonne-german-bridgehead", "German bridgehead flank", .guderianAI, p(8, 40), 32, 18, "German Grossdeutschland and panzer support protect the bridgehead flank."),
        ]
    )

    private static let montcornet = ScenarioMapLayout(
        id: .montcornet,
        title: "Montcornet Armored Raid",
        elements: [
            line("montcornet-road-net", "Montcornet road net", .road, [p(4, 40), p(27, 37), p(48, 32), p(72, 30), p(96, 23)], note: "German rear-area movement and French raid path."),
            line("montcornet-withdrawal", "French withdrawal lane", .road, [p(43, 53), p(33, 44), p(21, 35), p(8, 28)], width: 2, note: "Armor exit route after raid objectives are hit."),
            marker("montcornet-town", "Montcornet", .town, .neutral, p(52, 32), radius: 6, note: "Raid center and German road hub."),
            marker("montcornet-column", "German column park", .objective, .guderianAI, p(66, 28), radius: 5, note: "Transport, command, and supply disruption target."),
            marker("montcornet-4dcr", "4e DCR attack group", .objective, .player, p(34, 43), radius: 4, note: "French armored raid start."),
            marker("montcornet-air", "Luftwaffe reaction lane", .airPressure, .guderianAI, p(62, 15), radius: 6, note: "Late air-pressure source."),
            marker("montcornet-exit", "Armor disengagement", .objective, .player, p(12, 29), radius: 4, note: "Exit point for surviving French tanks."),
        ],
        deploymentZones: [
            zone("montcornet-french-armor", "4e Division cuirassee", .player, p(22, 35), 30, 22, "French armor enters for a time-limited raid."),
            zone("montcornet-german-column", "German column security", .guderianAI, p(55, 18), 34, 22, "German road guards, reserves, and air-pressure markers defend the road net."),
        ]
    )

    private static let amiensAbbeville = ScenarioMapLayout(
        id: .amiensAbbeville,
        title: "Amiens-Abbeville Channel Race",
        elements: [
            line("amiens-somme", "Somme River", .river, [p(4, 42), p(25, 39), p(49, 41), p(73, 36), p(98, 34)], width: 6, note: "River line for blocking and bridge denial."),
            line("amiens-channel-road", "Amiens-Abbeville road", .road, [p(11, 50), p(32, 43), p(54, 38), p(77, 31), p(96, 24)], note: "German race to the Channel."),
            marker("amiens", "Amiens", .town, .player, p(33, 43), radius: 7, note: "Central road hub captured in the Channel dash."),
            marker("abbeville", "Abbeville", .town, .player, p(78, 31), radius: 7, note: "Channel cut objective."),
            marker("somme-bridges", "Somme bridges", .bridge, .neutral, p(55, 40), radius: 4, note: "Crossing contest for Allied delay."),
            marker("allied-roadblocks", "Allied roadblocks", .objective, .player, p(51, 33), radius: 4, note: "Blocking detachments buy evacuation time."),
            marker("channel-exit", "Channel exit", .objective, .guderianAI, p(94, 24), radius: 5, note: "German operational finish line."),
            marker("panzer-race", "Panzer race column", .objective, .guderianAI, p(14, 50), radius: 4, note: "XIX Corps armored entry."),
        ],
        deploymentZones: [
            zone("amiens-allied-block", "Allied blocking line", .player, p(30, 28), 52, 24, "French and British blocking detachments defend Somme bridges and road hubs."),
            zone("amiens-german-race", "XIX Corps road columns", .guderianAI, p(2, 42), 28, 18, "German panzer divisions race from the west toward Amiens and Abbeville."),
        ]
    )

    private static let boulogne = ScenarioMapLayout(
        id: .boulogne,
        title: "Boulogne Port Defense",
        elements: [
            line("boulogne-liane", "River Liane harbor channel", .river, [p(15, 54), p(31, 44), p(47, 34), p(67, 27), p(90, 22)], width: 5, note: "Harbor channel and urban crossing obstacle."),
            line("boulogne-coast-road", "Channel coast road", .road, [p(4, 48), p(24, 42), p(45, 36), p(68, 29), p(96, 18)], note: "2nd Panzer approach toward the port."),
            marker("boulogne-harbor", "Harbor evacuation", .objective, .player, p(70, 28), radius: 7, note: "Embarkation and destroyer docking objective."),
            marker("boulogne-haute-ville", "Haute Ville perimeter", .fortifiedLine, .player, p(55, 36), radius: 6, note: "Old-town defensive anchor above the port."),
            marker("boulogne-destroyers", "Destroyer fire lane", .artillery, .player, p(82, 17), radius: 5, note: "Naval support window for re-embarkation."),
            marker("boulogne-demolition", "Port demolition party", .objective, .player, p(73, 37), radius: 4, note: "Port denial after evacuation scoring."),
            marker("boulogne-mont-lambert", "Mont St. Lambert ridge", .ridge, .guderianAI, p(37, 23), radius: 5, note: "German observation and assault approach."),
            marker("boulogne-panzer-entry", "2nd Panzer entry", .objective, .guderianAI, p(9, 48), radius: 4, note: "German armor closes on the port."),
        ],
        deploymentZones: [
            zone("boulogne-allied-port", "Allied port perimeter", .player, p(48, 23), 38, 25, "French, British, and Belgian defenders hold harbor and old-town positions."),
            zone("boulogne-german-coast", "2nd Panzer assault area", .guderianAI, p(0, 34), 34, 22, "German armor and infantry enter along the coast road and ridge approaches."),
        ]
    )

    private static let calais = ScenarioMapLayout(
        id: .calais,
        title: "Calais Siege Perimeter",
        elements: [
            line("calais-coast-road", "Boulogne-Calais road", .road, [p(5, 45), p(25, 40), p(46, 36), p(70, 31), p(95, 26)], note: "German 10th Panzer approach."),
            line("calais-dunkirk-road", "Dunkirk road", .road, [p(66, 18), p(79, 14), p(94, 10)], width: 2, note: "Strategic delay axis toward Dunkirk."),
            marker("calais-outer-perimeter", "Outer perimeter", .fortifiedLine, .player, p(50, 35), radius: 8, note: "Layered town defenses."),
            marker("calais-citadel", "Citadel", .fortifiedLine, .player, p(61, 29), radius: 6, note: "Inner siege objective."),
            marker("calais-docks", "Docks and harbor", .objective, .player, p(72, 24), radius: 5, note: "Final port objective and supply route."),
            marker("calais-supply", "Garrison supply point", .artillery, .player, p(56, 43), radius: 4, note: "Ammunition and command endurance."),
            marker("calais-10th-panzer", "10th Panzer pressure", .objective, .guderianAI, p(14, 43), radius: 4, note: "German siege assault force."),
            marker("calais-air-pressure", "Air and artillery pressure", .airPressure, .guderianAI, p(37, 24), radius: 5, note: "Supply and perimeter suppression."),
        ],
        deploymentZones: [
            zone("calais-garrison", "Calais garrison", .player, p(47, 22), 36, 27, "British, French, and Belgian defenders hold layered port defenses."),
            zone("calais-german-siege", "10th Panzer siege line", .guderianAI, p(0, 31), 34, 22, "German armor, infantry, artillery, and air pressure reduce the port."),
        ]
    )

    private static let dunkirk = ScenarioMapLayout(
        id: .dunkirk,
        title: "Dunkirk Evacuation Perimeter",
        elements: [
            line("dunkirk-beach", "Beach evacuation line", .road, [p(58, 13), p(70, 11), p(84, 12), p(98, 15)], width: 4, note: "Embarkation sectors along the beach."),
            line("dunkirk-canal", "Canal defensive line", .river, [p(8, 43), p(28, 38), p(51, 35), p(75, 30), p(100, 28)], width: 5, note: "Perimeter obstacle and breach line."),
            line("dunkirk-road", "Dunkirk perimeter road", .road, [p(12, 53), p(35, 46), p(58, 36), p(82, 22)], note: "Rear-guard withdrawal route."),
            marker("dunkirk-beach-sector", "Beach sector", .objective, .player, p(78, 13), radius: 7, note: "Evacuation capacity objective."),
            marker("dunkirk-harbor", "Dunkirk harbor", .town, .player, p(72, 24), radius: 6, note: "Harbor evacuation and perimeter anchor."),
            marker("dunkirk-canal-gate", "Canal gate", .bridge, .player, p(55, 35), radius: 4, note: "Key perimeter crossing."),
            marker("dunkirk-rearguard", "Rear-guard line", .fortifiedLine, .player, p(45, 42), radius: 5, note: "Force left behind to protect evacuation lanes."),
            marker("dunkirk-air", "Air attack lane", .airPressure, .guderianAI, p(68, 8), radius: 6, note: "Evacuation-capacity pressure."),
            marker("dunkirk-german-pressure", "German pressure front", .objective, .guderianAI, p(17, 47), radius: 5, note: "Campaign-pressure marker compressing the perimeter."),
        ],
        deploymentZones: [
            zone("dunkirk-allied-perimeter", "Allied evacuation perimeter", .player, p(43, 16), 45, 31, "Allied rear guards defend canals, harbor, and beach sectors."),
            zone("dunkirk-german-front", "German perimeter pressure", .guderianAI, p(0, 35), 34, 23, "German pressure forces advance against canal and road exits."),
        ]
    )

    private static let fallRot = ScenarioMapLayout(
        id: .fallRot,
        title: "Fall Rot Swiss-Border Drive",
        elements: [
            line("fallrot-drive-road", "Panzergruppe Guderian drive", .road, [p(5, 48), p(23, 43), p(42, 36), p(63, 29), p(86, 18)], note: "Deep exploitation route toward the Swiss border."),
            line("fallrot-canal", "Aisne and Marne-Rhine crossings", .river, [p(9, 36), p(31, 34), p(55, 31), p(77, 27), p(98, 25)], width: 5, note: "Crossing and demolition line."),
            line("fallrot-vosges", "Vosges retreat corridor", .ridge, [p(55, 54), p(68, 48), p(82, 39), p(95, 32)], width: 5, note: "French withdrawal corridor and trap line."),
            marker("fallrot-langres", "Langres road hub", .town, .player, p(41, 36), radius: 5, note: "Mid-route delay point."),
            marker("fallrot-belfort", "Belfort fortress town", .fortifiedLine, .player, p(78, 30), radius: 6, note: "Late fortress-town stand."),
            marker("fallrot-epinal", "Epinal fortress town", .fortifiedLine, .player, p(72, 46), radius: 5, note: "Northern fortress and retreat hinge."),
            marker("fallrot-fuel", "Fuel denial point", .objective, .player, p(50, 33), radius: 4, note: "Road congestion and fuel friction scoring."),
            marker("fallrot-swiss-border", "Swiss-border cut line", .objective, .guderianAI, p(89, 19), radius: 5, note: "German encirclement finish line."),
        ],
        deploymentZones: [
            zone("fallrot-french-delay", "French late-campaign defense", .player, p(36, 27), 46, 28, "French bridge, fortress, and retreat-corridor defenders."),
            zone("fallrot-panzergruppe", "Panzergruppe Guderian columns", .guderianAI, p(0, 38), 30, 19, "German deep exploitation columns enter from the west."),
        ]
    )

    private static let bialystokMinsk = ScenarioMapLayout(
        id: .bialystokMinsk,
        title: "Bialystok-Minsk Pocket",
        elements: [
            line("bialystok-minsk-road", "Bialystok-Minsk road and rail", .road, [p(7, 44), p(28, 39), p(51, 34), p(76, 28), p(96, 23)], note: "Main communications and breakout route."),
            line("bialystok-bug", "Bug River crossing line", .river, [p(4, 54), p(24, 48), p(44, 44), p(66, 41)], width: 5, note: "Southern penetration line for 2nd Panzer Group."),
            line("bialystok-neman", "Neman crossing line", .river, [p(17, 20), p(38, 24), p(61, 27), p(83, 24)], width: 4, note: "Northern pincer crossing pressure."),
            marker("bialystok-salient", "Bialystok salient", .objective, .player, p(31, 38), radius: 7, note: "Forward Soviet pocket risk."),
            marker("bialystok-novogrudok", "Novogrudok pocket", .objective, .neutral, p(55, 35), radius: 6, note: "Larger encirclement zone."),
            marker("bialystok-minsk", "Minsk rail junction", .town, .player, p(83, 25), radius: 7, note: "Command and breakout objective."),
            marker("bialystok-boldin", "Mechanized counterattack", .objective, .player, p(43, 30), radius: 4, note: "Counterattack marker to reopen escape lanes."),
            marker("bialystok-guderian", "2nd Panzer Group pincer", .objective, .guderianAI, p(23, 50), radius: 5, note: "Southern German pincer."),
            marker("bialystok-hoth", "3rd Panzer Group pincer", .objective, .guderianAI, p(43, 23), radius: 5, note: "Northern German pincer."),
        ],
        deploymentZones: [
            zone("bialystok-soviet-front", "Soviet Western Front", .player, p(23, 27), 52, 25, "Soviet rifle armies, command posts, and mechanized counterattack groups start in the salient."),
            zone("bialystok-german-pincers", "German pincer approaches", .guderianAI, p(4, 18), 36, 39, "2nd and 3rd Panzer Group pressure closes from south and north."),
        ]
    )

    private static let smolensk = ScenarioMapLayout(
        id: .smolensk,
        title: "Smolensk Dnieper Pocket",
        elements: [
            line("smolensk-dnieper", "Dnieper crossing line", .river, [p(5, 46), p(25, 42), p(47, 39), p(70, 34), p(95, 31)], width: 5, note: "Main southern crossing line for 2nd Panzer Group."),
            line("smolensk-dvina", "Dvina and Vitebsk line", .river, [p(10, 20), p(31, 22), p(55, 24), p(79, 21), p(99, 18)], width: 4, note: "Northern pressure line for Hoth's pincer."),
            line("smolensk-moscow-road", "Smolensk-Moscow road", .road, [p(8, 43), p(30, 39), p(52, 35), p(76, 30), p(98, 26)], note: "Main escape and German pursuit route east."),
            marker("smolensk-city", "Smolensk", .town, .player, p(56, 35), radius: 7, note: "Urban anchor and pocket center."),
            marker("smolensk-yartsevo", "Yartsevo escape lane", .objective, .player, p(78, 29), radius: 5, note: "Eastern exit for trapped armies."),
            marker("smolensk-vitebsk", "Vitebsk reserve entry", .town, .player, p(39, 23), radius: 5, note: "Reserve army and northern counterattack axis."),
            marker("smolensk-yelnya", "Yelnya counteroffensive", .objective, .player, p(65, 47), radius: 5, note: "Counterattack pressure against German overextension."),
            marker("smolensk-pocket", "Smolensk pocket", .objective, .neutral, p(61, 36), radius: 7, note: "Encirclement zone around Soviet armies."),
            marker("smolensk-guderian-pincer", "2nd Panzer Group southern pincer", .objective, .guderianAI, p(35, 44), radius: 5, note: "Guderian's Dnieper crossing pressure."),
            marker("smolensk-hoth-pincer", "3rd Panzer Group northern pincer", .objective, .guderianAI, p(46, 24), radius: 5, note: "Northern pincer coordination pressure."),
            marker("smolensk-supply-strain", "German supply strain", .airPressure, .guderianAI, p(31, 53), radius: 4, note: "Extended supply lines after the rapid advance."),
        ],
        deploymentZones: [
            zone("smolensk-soviet-pocket", "Soviet Smolensk defense", .player, p(43, 22), 45, 29, "Soviet 16th, 19th, 20th, and reserve army elements defend crossings and escape lanes."),
            zone("smolensk-german-pincers", "German panzer pincers", .guderianAI, p(7, 25), 36, 29, "2nd and 3rd Panzer Group markers press from south and north."),
        ]
    )

    private static let roslavlNovozybkov = ScenarioMapLayout(
        id: .roslavlNovozybkov,
        title: "Roslavl-Novozybkov Spoiling Offensive",
        elements: [
            line("roslavl-desna", "Desna and Sozh crossing net", .river, [p(8, 43), p(29, 40), p(52, 37), p(74, 34), p(97, 31)], width: 4, note: "River and bridge net shaping the spoiling attack."),
            line("roslavl-road-axis", "Roslavl-Novozybkov road axis", .road, [p(6, 51), p(28, 45), p(49, 39), p(71, 33), p(96, 26)], note: "Soviet attack and withdrawal route."),
            line("roslavl-south-turn", "German southward turn route", .road, [p(39, 28), p(51, 39), p(64, 50), p(78, 60)], width: 2, note: "Operational hinge toward Kiev."),
            marker("roslavl-town", "Roslavl", .town, .neutral, p(42, 39), radius: 6, note: "Western objective and German traffic node."),
            marker("novozybkov", "Novozybkov", .town, .player, p(78, 30), radius: 6, note: "Eastern anchor for Bryansk Front pressure."),
            marker("roslavl-bryansk-front", "Bryansk Front assembly", .objective, .player, p(66, 46), radius: 5, note: "Soviet attack staging area."),
            marker("roslavl-tank-raid", "Soviet tank raid point", .objective, .player, p(51, 35), radius: 4, note: "Spoiling attack target against German columns."),
            marker("roslavl-supply-column", "2nd Panzer supply columns", .objective, .guderianAI, p(45, 30), radius: 5, note: "Disruption target and German protection point."),
            marker("roslavl-intel-screen", "Southward-turn screen", .airPressure, .guderianAI, p(59, 52), radius: 4, note: "Fog-of-war marker hiding German intent."),
            marker("roslavl-counterpressure", "German counterpressure", .objective, .guderianAI, p(28, 45), radius: 4, note: "Counterattack threat against Soviet withdrawal lanes."),
        ],
        deploymentZones: [
            zone("roslavl-soviet-attack", "Bryansk Front attack groups", .player, p(56, 30), 33, 25, "Soviet rifle, tank, and reconnaissance groups attack from the east and southeast."),
            zone("roslavl-german-turn", "2nd Panzer Group road columns", .guderianAI, p(22, 25), 35, 29, "German columns screen Roslavl and the southward turn."),
        ]
    )

    private static let kiev = ScenarioMapLayout(
        id: .kiev,
        title: "Kiev Northern Pincer",
        elements: [
            line("kiev-dnieper", "Dnieper defensive arc", .river, [p(9, 48), p(29, 43), p(51, 36), p(73, 31), p(96, 28)], width: 6, note: "Main river and Kiev defensive line."),
            line("kiev-desna", "Desna approach line", .river, [p(6, 28), p(27, 30), p(48, 32), p(71, 35), p(93, 39)], width: 4, note: "Northern pincer crossing and delay terrain."),
            line("kiev-escape-road", "Kiev eastern escape corridor", .road, [p(34, 39), p(54, 36), p(74, 35), p(94, 37)], note: "Command evacuation and breakout corridor."),
            marker("kiev-city", "Kiev", .town, .player, p(34, 40), radius: 7, note: "Southwestern Front urban and command anchor."),
            marker("kiev-command", "Southwestern Front command", .objective, .player, p(43, 33), radius: 5, note: "High-value evacuation objective."),
            marker("kiev-lokhvytsia", "Eastern closure corridor", .objective, .neutral, p(78, 35), radius: 6, note: "Pincer closure and breakout route."),
            marker("kiev-pocket", "Kiev pocket", .objective, .neutral, p(58, 39), radius: 8, note: "Encirclement pressure zone."),
            marker("kiev-rail", "Kiev rail junctions", .artillery, .player, p(48, 44), radius: 4, note: "Command and evacuation communications."),
            marker("kiev-guderian", "2nd Panzer Group northern pincer", .objective, .guderianAI, p(46, 25), radius: 5, note: "Guderian's southward pincer."),
            marker("kiev-kleist", "1st Panzer Group southern pincer", .objective, .guderianAI, p(63, 51), radius: 5, note: "Southern closure pressure."),
        ],
        deploymentZones: [
            zone("kiev-southwestern-front", "Soviet Southwestern Front", .player, p(30, 31), 48, 22, "Soviet armies, headquarters, artillery, and breakout groups start inside the developing pocket."),
            zone("kiev-panzer-pincers", "German pincer approaches", .guderianAI, p(39, 19), 35, 39, "2nd Panzer Group presses from the north while 1st Panzer Group closes from the south."),
        ]
    )

    private static let bryansk = ScenarioMapLayout(
        id: .bryansk,
        title: "Bryansk-Orel Typhoon Approach",
        elements: [
            line("bryansk-orel-road", "Bryansk-Orel road", .road, [p(7, 43), p(29, 40), p(51, 36), p(74, 30), p(96, 24)], note: "Unexpected German axis and Operation Typhoon route."),
            line("bryansk-tula-road", "Orel-Tula road", .road, [p(73, 30), p(82, 22), p(92, 14)], width: 2, note: "Southern Moscow approach that must be protected."),
            line("bryansk-desna", "Desna and forest river line", .river, [p(6, 29), p(27, 32), p(49, 34), p(72, 33), p(96, 36)], width: 4, note: "Wet defensive terrain around Bryansk."),
            line("bryansk-forest", "Bryansk forest belt", .forest, [p(18, 19), p(39, 22), p(60, 20), p(82, 25)], width: 8, note: "Cover for delaying detachments and pocket breakouts."),
            marker("bryansk-city", "Bryansk", .town, .player, p(43, 37), radius: 7, note: "Rail and road hub under encirclement pressure."),
            marker("orel", "Orel", .town, .neutral, p(74, 30), radius: 6, note: "Gateway toward Tula."),
            marker("bryansk-pocket", "13th and 3rd Army pockets", .objective, .player, p(50, 34), radius: 7, note: "Encircled Soviet formations trying to remain active."),
            marker("bryansk-50th-army", "50th Army Tula screen", .fortifiedLine, .player, p(70, 22), radius: 5, note: "Defense protecting the road north toward Tula."),
            marker("bryansk-rail", "Bryansk rail junction", .artillery, .player, p(46, 42), radius: 4, note: "Command and evacuation node."),
            marker("bryansk-guderian-axis", "Guderian unexpected axis", .objective, .guderianAI, p(23, 41), radius: 5, note: "German armored entry and surprise direction."),
            marker("bryansk-autumn-friction", "Autumn road friction", .airPressure, .guderianAI, p(62, 47), radius: 4, note: "Supply and road-friction marker for overextended armor."),
        ],
        deploymentZones: [
            zone("bryansk-front-defense", "Soviet Bryansk Front", .player, p(38, 23), 45, 25, "50th, 13th, and 3rd Army detachments defend pockets, roads, and rail exits."),
            zone("bryansk-panzer-army", "2nd Panzer Group/Army approach", .guderianAI, p(4, 34), 31, 20, "German armor enters from the west and drives toward Bryansk, Orel, and Tula."),
        ]
    )

    private static let mtsensk = ScenarioMapLayout(
        id: .mtsensk,
        title: "Mtsensk Armor Ambush",
        elements: [
            line("mtsensk-orel-road", "Orel-Mtsensk-Tula road", .road, [p(4, 48), p(25, 43), p(47, 37), p(70, 30), p(96, 22)], note: "German panzer movement axis and Soviet delay objective."),
            line("mtsensk-zusha", "Zusha river and ravines", .river, [p(8, 34), p(30, 36), p(54, 34), p(78, 31), p(99, 32)], width: 4, note: "Partial obstacle and ambush terrain around Mtsensk."),
            line("mtsensk-wooded-ridges", "Wooded ridge ambush belt", .forest, [p(18, 24), p(38, 25), p(58, 22), p(80, 25)], width: 9, note: "Concealed firing lanes for T-34/KV groups."),
            marker("mtsensk-town", "Mtsensk", .town, .player, p(63, 33), radius: 7, note: "Road hub and ambush center."),
            marker("mtsensk-orel", "Orel road entry", .objective, .guderianAI, p(17, 45), radius: 5, note: "German armored entry from Orel."),
            marker("mtsensk-tula-exit", "Tula road exit", .objective, .player, p(90, 24), radius: 5, note: "Delay route toward Tula."),
            marker("mtsensk-katukov", "Katukov tank ambush", .objective, .player, p(47, 28), radius: 5, note: "T-34/KV reveal point."),
            marker("mtsensk-at-screen", "Anti-tank screen", .artillery, .player, p(57, 39), radius: 4, note: "Track-kill and artillery support position."),
            marker("mtsensk-guards-rifle", "1st Guards Rifle screen", .fortifiedLine, .player, p(71, 29), radius: 5, note: "Infantry screen covering withdrawal and ambush resets."),
            marker("mtsensk-4th-panzer", "4th Panzer pressure", .objective, .guderianAI, p(30, 42), radius: 5, note: "German spearhead trying to force the road."),
            marker("mtsensk-german-caution", "German caution marker", .airPressure, .guderianAI, p(42, 48), radius: 4, note: "AI fallback pressure after T-34/KV shock."),
        ],
        deploymentZones: [
            zone("mtsensk-soviet-ambush", "Katukov ambush screen", .player, p(43, 21), 43, 23, "4th Tank Brigade, rifle screens, anti-tank guns, and artillery hide along the road and ridges."),
            zone("mtsensk-german-spearhead", "German panzer spearhead", .guderianAI, p(2, 36), 34, 18, "4th Panzer Division and motorized support enter from the Orel road."),
        ]
    )

    private static let moscowTulaKashira = ScenarioMapLayout(
        id: .moscowTulaKashira,
        title: "Tula-Kashira Winter Defense",
        elements: [
            line("tula-road", "Orel-Tula road", .road, [p(6, 56), p(30, 43), p(57, 31), p(86, 12)], note: "Main panzer advance route."),
            line("venev-kashira-axis", "Venev-Kashira bypass", .road, [p(52, 46), p(69, 36), p(83, 24), p(95, 14)], width: 2, note: "Southern bypass route that can open the road to Moscow."),
            line("winter-track", "Frozen side track", .road, [p(18, 61), p(34, 52), p(52, 46), p(76, 39)], width: 2, note: "Secondary movement route with winter friction."),
            line("upa-river", "Upa river", .river, [p(12, 33), p(39, 30), p(65, 24), p(100, 28)], width: 5, note: "Frozen river and defensive obstacle."),
            line("tula-belt", "Tula defensive belt", .fortifiedLine, [p(58, 18), p(66, 23), p(76, 23), p(86, 18)], width: 4, note: "Prepared city defenses and anti-tank positions."),
            marker("road-choke", "Winter road choke", .ridge, .neutral, p(47, 37), radius: 4, note: "Movement friction and ambush point."),
            marker("tula", "Tula", .town, .player, p(69, 23), radius: 8, note: "City hold objective."),
            marker("venev", "Venev bypass gate", .town, .neutral, p(78, 27), radius: 5, note: "German bypass pressure before Kashira."),
            marker("kashira-road", "Kashira road", .objective, .player, p(83, 12), radius: 5, note: "Southern approach to Moscow."),
            marker("soviet-reserve", "Soviet reserve staging", .objective, .player, p(73, 49), radius: 5, note: "Reserve armor and mobile winter forces enter from this area."),
            marker("belov-counterstroke", "Belov/Getman counterstroke", .objective, .player, p(82, 38), radius: 5, note: "Mobile reserve attack against overextended armor."),
            marker("mordves-driveback", "Mordves drive-back line", .objective, .player, p(58, 48), radius: 4, note: "Late counteroffensive route after German exhaustion."),
            marker("winter-supply", "German supply strain", .airPressure, .guderianAI, p(26, 48), radius: 5, note: "Attrition and movement friction event source."),
            marker("panzer-overreach", "Panzer overreach line", .objective, .guderianAI, p(55, 32), radius: 4, note: "German armor beyond this line starts checking supply and morale pressure."),
        ],
        deploymentZones: [
            zone("soviet-city-belt", "Soviet Tula belt", .player, p(58, 12), 35, 24, "Soviet infantry, guns, and reserves defend Tula and Kashira approaches."),
            zone("german-road-column", "German road columns", .guderianAI, p(0, 40), 30, 20, "2nd Panzer Army enters along strained winter roads."),
        ]
    )

    private static func fallback(for scenario: GuderianScenario) -> ScenarioMapLayout {
        let featureElements = scenario.mapFeatures.enumerated().map { index, feature in
            marker(
                "\(scenario.id.rawValue)-feature-\(index)",
                feature.name,
                index.isMultiple(of: 2) ? .objective : .town,
                .neutral,
                p(22 + Double(index * 18 % 58), 20 + Double(index * 11 % 28)),
                radius: 4,
                note: feature.role
            )
        }

        return ScenarioMapLayout(
            id: scenario.id,
            title: "\(scenario.title) planning map",
            elements: [
                line("\(scenario.id.rawValue)-main-road", "Operational road", .road, [p(4, 51), p(35, 38), p(63, 26), p(96, 13)], note: "Generic campaign route until a hand-authored map is added."),
            ] + featureElements,
            deploymentZones: [
                zone("\(scenario.id.rawValue)-player", "Player deployment", .player, p(58, 11), 34, 28, "Opposing force deployment area."),
                zone("\(scenario.id.rawValue)-german", "Guderian approach", .guderianAI, p(2, 36), 30, 22, "German attack or pursuit start area."),
            ]
        )
    }
}

private func line(
    _ id: String,
    _ name: String,
    _ kind: ScenarioMapElementKind,
    _ points: [ScenarioMapPoint],
    width: Double = 3,
    note: String
) -> ScenarioMapElement {
    ScenarioMapElement(id: id, name: name, kind: kind, points: points, strokeWidth: width, note: note)
}

private func marker(
    _ id: String,
    _ name: String,
    _ kind: ScenarioMapElementKind,
    _ side: ScenarioSide,
    _ point: ScenarioMapPoint,
    radius: Double,
    note: String
) -> ScenarioMapElement {
    ScenarioMapElement(id: id, name: name, kind: kind, side: side, points: [point], radius: radius, note: note)
}

private func zone(
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

private func p(_ x: Double, _ y: Double) -> ScenarioMapPoint {
    ScenarioMapPoint(x, y)
}
