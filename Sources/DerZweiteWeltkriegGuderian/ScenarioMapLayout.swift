import Foundation

public enum ScenarioMapElementKind: String, CaseIterable, Codable, Hashable, Sendable {
    case road = "Road"
    case river = "River"
    case canal = "Canal"
    case lake = "Lake"
    case marsh = "Marsh"
    case railway = "Railway"
    case town = "Town"
    case village = "Village"
    case urbanDistrict = "Urban district"
    case forest = "Forest"
    case ridge = "Ridge"
    case bunker = "Bunker"
    case fortifiedLine = "Fortified line"
    case bridge = "Bridge"
    case ford = "Ford"
    case ferry = "Ferry"
    case objective = "Objective"
    case artillery = "Artillery"
    case airPressure = "Air pressure"
    case deployment = "Deployment"
    case phaseLine = "Phase line"

    // Marsh is modeled as difficult ground here, not as a waterway.
    private static let waterFeatures: Set<ScenarioMapElementKind> = [.river, .canal, .lake]
    private static let crossingFeatures: Set<ScenarioMapElementKind> = [.bridge, .ford, .ferry]
    private static let settlementFeatures: Set<ScenarioMapElementKind> = [.town, .village, .urbanDistrict]
    private static let groundTerrainFeatures: Set<ScenarioMapElementKind> = [.forest, .ridge, .bunker, .fortifiedLine, .marsh, .urbanDistrict]
    private static let fortificationFeatures: Set<ScenarioMapElementKind> = [.bunker, .fortifiedLine]
    private static let pressureMarkers: Set<ScenarioMapElementKind> = [.artillery, .airPressure]
    private static let nonPlayableTerrainFeatures: Set<ScenarioMapElementKind> = [.objective, .deployment, .phaseLine]

    public var isWaterFeature: Bool { Self.waterFeatures.contains(self) }

    public var isRoadFeature: Bool {
        self == .road
    }

    public var isRailwayFeature: Bool {
        self == .railway
    }

    public var isCrossingFeature: Bool { Self.crossingFeatures.contains(self) }

    public var isSettlementFeature: Bool { Self.settlementFeatures.contains(self) }

    public var isGroundTerrainFeature: Bool { Self.groundTerrainFeatures.contains(self) }

    public var isFortificationFeature: Bool { Self.fortificationFeatures.contains(self) }

    public var isPressureMarker: Bool { Self.pressureMarkers.contains(self) }

    public var isPlayableTerrainFeature: Bool { !Self.nonPlayableTerrainFeatures.contains(self) }
}

public struct ScenarioMapSourceNote: Codable, Hashable, Sendable {
    public let title: String
    public let url: URL?
    public let note: String

    public init(title: String, url: URL? = nil, note: String) {
        self.title = title
        self.url = url
        self.note = note
    }
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
    public let sourceNotes: [ScenarioMapSourceNote]

    public init(
        id: String,
        name: String,
        kind: ScenarioMapElementKind,
        side: ScenarioSide = .neutral,
        points: [ScenarioMapPoint],
        radius: Double = 0,
        strokeWidth: Double = 3,
        note: String = "",
        sourceNotes: [ScenarioMapSourceNote] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.side = side
        self.points = points
        self.radius = radius
        self.strokeWidth = strokeWidth
        self.note = note
        self.sourceNotes = sourceNotes
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
    public let sourceNotes: [ScenarioMapSourceNote]

    public init(
        id: String,
        name: String,
        side: ScenarioSide,
        origin: ScenarioMapPoint,
        width: Double,
        height: Double,
        note: String,
        sourceNotes: [ScenarioMapSourceNote] = []
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.origin = origin
        self.width = width
        self.height = height
        self.note = note
        self.sourceNotes = sourceNotes
    }
}

public struct ScenarioMapLayout: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let width: Double
    public let height: Double
    public let elements: [ScenarioMapElement]
    public let deploymentZones: [ScenarioDeploymentZone]
    public let sourceNotes: [ScenarioMapSourceNote]

    public init(
        id: GuderianBattleID,
        title: String,
        width: Double = 100,
        height: Double = 64,
        elements: [ScenarioMapElement],
        deploymentZones: [ScenarioDeploymentZone],
        sourceNotes: [ScenarioMapSourceNote] = []
    ) {
        self.id = id
        self.title = title
        self.width = width
        self.height = height
        self.elements = elements
        self.deploymentZones = deploymentZones
        self.sourceNotes = sourceNotes
    }

    public var objectiveElements: [ScenarioMapElement] {
        elements.filter { $0.kind == .objective }
    }

    public func appendingSourceNotes(_ additionalSourceNotes: [ScenarioMapSourceNote]) -> ScenarioMapLayout {
        guard !additionalSourceNotes.isEmpty else {
            return self
        }

        return ScenarioMapLayout(
            id: id,
            title: title,
            width: width,
            height: height,
            elements: elements,
            deploymentZones: deploymentZones,
            sourceNotes: sourceNotes + additionalSourceNotes
        )
    }
}

public enum ScenarioMapCatalog {
    public static func layout(for scenario: GuderianScenario) -> ScenarioMapLayout {
        let layout: ScenarioMapLayout

        switch scenario.id {
        case .tucholaForest:
            layout = tucholaForest
        case .wizna:
            layout = wizna
        case .brzescLitewski:
            layout = brzescLitewski
        case .kobryn:
            layout = kobryn
        case .sedan:
            layout = sedan
        case .stonne:
            layout = stonne
        case .montcornet:
            layout = montcornet
        case .amiensAbbeville:
            layout = amiensAbbeville
        case .boulogne:
            layout = boulogne
        case .calais:
            layout = calais
        case .dunkirk:
            layout = dunkirk
        case .fallRot:
            layout = fallRot
        case .bialystokMinsk:
            layout = bialystokMinsk
        case .smolensk:
            layout = smolensk
        case .roslavlNovozybkov:
            layout = roslavlNovozybkov
        case .kiev:
            layout = kiev
        case .bryansk:
            layout = bryansk
        case .mtsensk:
            layout = mtsensk
        case .moscowTulaKashira:
            layout = moscowTulaKashira
        }

        return layout.appendingSourceNotes(
            ScenarioMapGeographyPipelineCatalog.sourceNotes(for: scenario)
        )
    }

    private static let tucholaForest = ScenarioMapLayout(
        id: .tucholaForest,
        title: "Tuchola Forest Corridor",
        elements: [
            line("tuchola-corridor-road", "Chojnice-Tuchola-Bydgoszcz road", .road, [p(6, 28), p(21, 31), p(39, 34), p(61, 42), p(93, 54)], note: "Main withdrawal and pursuit route through the corridor."),
            line("tuchola-rail", "Chojnice rail line", .railway, [p(2, 18), p(19, 24), p(42, 29), p(72, 31), p(99, 36)], width: 2, note: "Rail corridor and early Chojnice pressure axis."),
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
        ] + tucholaForestEnrichment,
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
            line("brzesc-rail", "Rail line", .railway, [p(4, 46), p(29, 42), p(49, 38), p(78, 34), p(97, 29)], width: 2, note: "Armored-train support and German approach lane."),
            marker("brzesc-citadel", "Brzesc Citadel", .fortifiedLine, .player, p(52, 32), radius: 7, note: "Central fortress objective."),
            marker("brzesc-town", "Brzesc town", .town, .player, p(43, 43), radius: 6, note: "Urban delay zone before the citadel."),
            marker("brzesc-armored-train", "Armored train track", .artillery, .player, p(35, 40), radius: 4, note: "Rail-bound fire support and evacuation cover."),
            marker("brzesc-ft17", "FT-17 tank park", .objective, .player, p(59, 45), radius: 4, note: "Obsolete tanks used as mobile strongpoints."),
            marker("brzesc-panzer-entry", "XIX Corps west entry", .objective, .guderianAI, p(7, 44), radius: 4, note: "German panzer and motorized assault approach."),
            marker("brzesc-south-exit", "South fallback gate", .objective, .player, p(78, 55), radius: 4, note: "Withdrawal route after citadel delay."),
        ] + brzescLitewskiEnrichment,
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
            line("kobryn-canal", "Mukhavets marsh/canal line", .canal, [p(4, 51), p(27, 48), p(53, 51), p(79, 46), p(100, 42)], width: 4, note: "Wet terrain and partial obstacle around Kobryn."),
            marker("kobryn-town", "Kobryn", .town, .player, p(47, 35), radius: 7, note: "Road hub and rearguard anchor."),
            marker("kobryn-reserve-line", "60th Reserve Infantry line", .fortifiedLine, .player, p(57, 42), radius: 5, note: "Improvised defensive line covering eastern exits."),
            marker("kobryn-west-roadblock", "Western roadblock", .objective, .player, p(29, 35), radius: 4, note: "Delay motorized pressure before the town fight."),
            marker("kobryn-east-exit", "Eastern exit", .objective, .player, p(87, 55), radius: 5, note: "Force-preservation scoring route."),
            marker("kobryn-german-fix", "2nd Motorized pressure", .objective, .guderianAI, p(12, 38), radius: 4, note: "German effort to fix and envelop the rearguard."),
        ] + kobrynEnrichment,
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
        ] + wiznaEnrichment,
        deploymentZones: [
            zone("polish-line", "Polish fortified line", .player, p(30, 16), 38, 30, "Opposing force deploys bunkers, machine guns, and anti-tank guns along the line."),
            zone("german-approach", "German assembly area", .guderianAI, p(0, 39), 24, 21, "German armor and infantry enter from the western approach."),
        ]
    )

    private static let tucholaForestEnrichment: [ScenarioMapElement] = [
        line("tuchola-wda", "Wda River flank", .river, [p(18, 8), p(32, 13), p(50, 15), p(76, 22)], width: 3, note: "Northern water obstacle that narrows the pincer approach."),
        line("tuchola-kamionka", "Kamionka stream", .river, [p(5, 38), p(18, 36), p(29, 34)], width: 2, note: "Local stream line that slows lateral movement near Chojnice."),
        marker("tuchola-brda-marsh-west", "Brda west marsh", .marsh, .neutral, p(22, 41), radius: 4, note: "Wet ground beside the first Brda crossing."),
        marker("tuchola-brda-marsh-east", "Brda east marsh", .marsh, .neutral, p(62, 44), radius: 4, note: "Marshy river bend that makes the eastern crossing slower."),
        line("tuchola-vistula-edge", "Vistula approach edge", .river, [p(82, 60), p(94, 55), p(100, 52)], width: 3, note: "Southern river edge framing the Bydgoszcz withdrawal space."),
        line("tuchola-czersk-road", "Czersk-Chojnice road", .road, [p(9, 12), p(18, 20), p(28, 28), p(42, 33)], width: 2, note: "Secondary road used by Polish screens and German reconnaissance."),
        line("tuchola-swiecie-road", "Tuchola-Swiecie road", .road, [p(43, 34), p(55, 43), p(69, 51), p(82, 58)], width: 2, note: "Fallback route toward the Vistula crossings."),
        line("tuchola-koronowo-road", "Koronowo-Bydgoszcz road", .road, [p(55, 47), p(68, 51), p(81, 53), p(94, 55)], width: 2, note: "Southern exit road for withdrawing Polish groups."),
        line("tuchola-forest-track-north", "Northern forest track", .road, [p(22, 17), p(39, 22), p(58, 23), p(76, 27)], width: 2, note: "Narrow track that lets cavalry screens slip away from armor."),
        line("tuchola-bydgoszcz-spur", "Bydgoszcz spur road", .road, [p(72, 45), p(82, 49), p(91, 54), p(99, 59)], width: 2, note: "Final withdrawal spur to the operational exit."),
        line("tuchola-cavalry-track", "Krojanty cavalry track", .road, [p(16, 16), p(23, 19), p(31, 22), p(39, 27)], width: 2, note: "Screening lane for the Pomeranian Cavalry Brigade."),
        line("tuchola-german-west-road", "German west approach road", .road, [p(0, 34), p(10, 35), p(21, 36), p(32, 38)], width: 2, note: "Western motorized approach before the Brda crossing fight."),
        line("tuchola-east-prussia-road", "East Prussia pressure road", .road, [p(63, 11), p(72, 18), p(82, 25), p(94, 32)], width: 2, note: "Northern pincer road converting the battle into a withdrawal."),
        line("tuchola-bydgoszcz-rail", "Bydgoszcz rail exit", .railway, [p(60, 31), p(72, 35), p(84, 42), p(97, 49)], width: 2, note: "Rail corridor marking the southern evacuation direction."),
        line("tuchola-czersk-rail-spur", "Czersk rail spur", .railway, [p(8, 15), p(22, 21), p(38, 26)], width: 2, note: "Rail spur tying Czersk and Chojnice into the corridor fight."),
        marker("tuchola-chojnice-rail-bridge", "Chojnice rail bridge", .bridge, .neutral, p(19, 24), radius: 2, note: "Rail crossing that can be blocked to slow early German pressure."),
        marker("tuchola-tuchola-ford", "Tuchola ford", .ford, .neutral, p(43, 37), radius: 2, note: "Minor Brda crossing with limited vehicle capacity."),
        marker("tuchola-swiecie-bridge", "Swiecie bridge", .bridge, .neutral, p(79, 55), radius: 3, note: "Withdrawal bridge near the Vistula edge."),
        marker("tuchola-koronowo-ford", "Koronowo ford", .ford, .neutral, p(66, 49), radius: 2, note: "Secondary wet crossing for retreating infantry."),
        marker("tuchola-brda-ferry", "Brda ferry point", .ferry, .neutral, p(58, 43), radius: 2, note: "Improvised river crossing when bridges are threatened."),
        marker("tuchola-czersk-crossing", "Czersk crossing", .bridge, .neutral, p(27, 28), radius: 2, note: "Northern crossing that protects the Chojnice flank."),
        marker("tuchola-czersk", "Czersk", .village, .player, p(27, 23), radius: 3, note: "Northern road and rail settlement anchoring the corridor flank."),
        marker("tuchola-rytel", "Rytel", .village, .player, p(34, 21), radius: 3, note: "Forest village that marks a lateral withdrawal point."),
        marker("tuchola-legbad", "Legbad", .village, .player, p(50, 24), radius: 3, note: "Village on the forest track where pursuit can be screened."),
        marker("tuchola-gostycyn", "Gostycyn", .village, .player, p(52, 38), radius: 3, note: "Road village between Tuchola and the southern exits."),
        marker("tuchola-pruszcz", "Pruszcz", .village, .player, p(32, 39), radius: 3, note: "Bridge village that sharpens the demolition fight."),
        marker("tuchola-pila-mlyn-village", "Pila-Mlyn", .village, .player, p(49, 39), radius: 3, note: "Bridge hamlet and fallback hinge on the Brda."),
        marker("tuchola-swiecie", "Swiecie", .village, .player, p(79, 58), radius: 4, note: "Vistula-side exit settlement for battered formations."),
        marker("tuchola-koronowo", "Koronowo", .village, .player, p(64, 52), radius: 3, note: "Southern road hub protecting the Bydgoszcz approach."),
        marker("tuchola-sepolno", "Sepolno Krajenskie", .village, .player, p(14, 30), radius: 3, note: "Western locality marking the German entry side of the corridor."),
        marker("tuchola-byslaw", "Byslaw", .village, .player, p(57, 31), radius: 3, note: "Intermediate settlement on the road net around Tuchola."),
        line("tuchola-north-forest", "Northern Tuchola woods", .forest, [p(10, 8), p(28, 11), p(48, 12), p(70, 17), p(87, 24)], width: 7, note: "Deep forest mass limiting armored lateral movement."),
        line("tuchola-south-forest", "Southern Tuchola woods", .forest, [p(31, 47), p(48, 49), p(65, 52), p(82, 59)], width: 7, note: "Southern forest belt covering withdrawal routes."),
        marker("tuchola-forest-choke-west", "Western forest choke", .ridge, .player, p(29, 32), radius: 3, note: "Constricted road segment for anti-tank fire."),
        marker("tuchola-forest-choke-east", "Eastern forest choke", .ridge, .player, p(70, 43), radius: 3, note: "Late choke point before the Bydgoszcz exit."),
        marker("tuchola-sand-track-marsh", "Sand track marsh", .marsh, .neutral, p(38, 46), radius: 3, note: "Soft ground off the road where vehicles bog down."),
        marker("tuchola-bory-pocket", "Bory forest pocket", .forest, .player, p(45, 19), radius: 5, note: "Wooded pocket where cut-off defenders can delay pursuit."),
        line("tuchola-polish-fallback-route", "Polish fallback route", .road, [p(39, 34), p(52, 41), p(68, 49), p(88, 56)], width: 2, note: "Fallback route joining Tuchola to the Bydgoszcz withdrawal."),
        marker("tuchola-osie-fallback", "Osie fallback marker", .objective, .player, p(75, 48), radius: 3, note: "Intermediate rally point before the final withdrawal gate."),
        marker("tuchola-bydgoszcz-gate", "Bydgoszcz gate", .objective, .player, p(96, 57), radius: 4, note: "End-of-map gate for coherent Polish formations."),
        line("tuchola-phase-brda", "Brda delay phase line", .phaseLine, [p(9, 43), p(31, 40), p(55, 42), p(79, 48)], width: 2, note: "First line where demolition and bridge control decide tempo."),
        line("tuchola-phase-withdrawal", "Withdrawal phase line", .phaseLine, [p(55, 49), p(70, 52), p(88, 57), p(100, 61)], width: 2, note: "Later line where scoring shifts to force preservation."),
    ]

    private static let wiznaEnrichment: [ScenarioMapElement] = [
        line("wizna-lomza-road", "Lomza-Wizna road", .road, [p(8, 35), p(24, 32), p(43, 30), p(62, 27)], width: 2, note: "Rear road from Lomza into the fortified sector."),
        line("wizna-jedwabne-road", "Jedwabne approach road", .road, [p(14, 50), p(28, 44), p(43, 37), p(58, 33)], width: 2, note: "German approach lane that can bypass isolated bunkers."),
        line("wizna-gora-track", "Gora Strekowa fallback track", .road, [p(56, 39), p(65, 45), p(76, 51), p(90, 56)], width: 2, note: "Command-post fallback track across high ground."),
        line("wizna-german-armored-road", "German armored approach road", .road, [p(0, 57), p(16, 50), p(30, 42), p(46, 34)], width: 2, note: "Armored movement lane toward the bunker belt."),
        line("wizna-lomza-rail", "Lomza rear rail line", .railway, [p(13, 14), p(34, 18), p(56, 21), p(83, 20)], width: 2, note: "Rear communications rail line behind the Narew defensive sector."),
        line("wizna-biebrza", "Biebrza River flank", .river, [p(4, 9), p(23, 12), p(46, 15), p(68, 17)], width: 4, note: "Northern water line and marsh source for the defensive position."),
        marker("wizna-narew-marsh-west", "Narew west marsh", .marsh, .neutral, p(20, 28), radius: 4, note: "Wet ground beside the western river bend."),
        marker("wizna-narew-marsh-east", "Narew east marsh", .marsh, .neutral, p(70, 20), radius: 4, note: "Marshland near the eastern crossing approaches."),
        marker("wizna-biebrza-marsh", "Biebrza marsh", .marsh, .neutral, p(35, 13), radius: 5, note: "Marsh belt that restricts northern envelopment."),
        marker("wizna-backwater-lake", "Narew backwater", .lake, .neutral, p(53, 24), radius: 3, note: "Backwater pool breaking up direct approach routes."),
        line("wizna-mala-struga", "Mala Struga stream", .river, [p(41, 41), p(51, 36), p(62, 33)], width: 2, note: "Small stream that protects the command-post slope."),
        marker("wizna-bridge", "Wizna bridge", .bridge, .neutral, p(42, 27), radius: 2, note: "Main Narew crossing near the fortified village."),
        marker("wizna-strekowa-ford", "Strekowa Gora ford", .ford, .neutral, p(63, 22), radius: 2, note: "Minor ford that can open a flank if left uncovered."),
        marker("wizna-burzyn-ferry", "Burzyn ferry", .ferry, .neutral, p(76, 19), radius: 2, note: "Small ferry point along the Narew bend."),
        marker("wizna-causeway", "Marsh causeway", .bridge, .neutral, p(30, 29), radius: 2, note: "Raised crossing through wet ground."),
        marker("wizna-village", "Wizna village", .village, .player, p(43, 28), radius: 4, note: "Settlement anchoring the river crossing."),
        marker("wizna-strekowa-gora", "Strekowa Gora", .village, .player, p(61, 40), radius: 3, note: "High-ground settlement around the command position."),
        marker("wizna-kurpiki-village", "Kurpiki village", .village, .player, p(37, 22), radius: 3, note: "Village tied to the western bunker sector."),
        marker("wizna-gielczyn-village", "Gielczyn village", .village, .player, p(52, 33), radius: 3, note: "Central village near the bunker line."),
        marker("wizna-burzyn", "Burzyn", .village, .player, p(79, 22), radius: 3, note: "Eastern riverside settlement and ferry reference."),
        marker("wizna-rutki", "Rutki", .village, .player, p(28, 45), radius: 3, note: "Road village on a German approach lane."),
        marker("wizna-perlejewo", "Perlejewo", .village, .neutral, p(73, 49), radius: 3, note: "Rear settlement framing the fallback side of the map."),
        marker("wizna-perlejewo-woods", "Perlejewo woods", .forest, .neutral, p(70, 44), radius: 5, note: "Wooded cover near the rear fallback track."),
        marker("wizna-river-bluff", "Narew river bluff", .ridge, .player, p(57, 25), radius: 4, note: "Observation ridge above the crossing sites."),
        marker("wizna-forward-trench", "Forward trench spur", .fortifiedLine, .player, p(46, 29), radius: 3, note: "Trench spur linking bunker positions."),
        marker("wizna-at-ditch", "Anti-tank ditch", .ridge, .player, p(48, 36), radius: 3, note: "Ditch and slope obstacle covering the road."),
        line("wizna-phase-last-stand", "Last-stand phase line", .phaseLine, [p(38, 26), p(49, 31), p(62, 38)], width: 2, note: "Line used to mark the shrinking fortified stand."),
    ]

    private static let brzescLitewskiEnrichment: [ScenarioMapElement] = [
        line("brzesc-terespol-road", "Terespol-Brzesc road", .road, [p(0, 39), p(18, 40), p(35, 42), p(50, 43)], width: 2, note: "Western road approach from Terespol into Brzesc."),
        line("brzesc-kobryn-road", "Brzesc-Kobryn road", .road, [p(52, 43), p(67, 45), p(83, 49), p(100, 54)], width: 2, note: "Eastern road that becomes a fallback and pursuit route."),
        line("brzesc-south-road", "Southern fortress road", .road, [p(25, 57), p(42, 52), p(61, 48), p(82, 45)], width: 2, note: "Southern route around the fortress and town."),
        line("brzesc-inner-ring-road", "Citadel ring road", .road, [p(41, 30), p(49, 26), p(60, 28), p(65, 36), p(57, 42), p(45, 39), p(41, 30)], width: 2, note: "Inner road around the fortress sectors."),
        line("brzesc-eastern-fallback-road", "Eastern fallback road", .road, [p(61, 45), p(73, 50), p(86, 56), p(98, 61)], width: 2, note: "Fallback road for surviving defenders after the citadel is pressured."),
        line("brzesc-yard-rail", "Brzesc rail yards", .railway, [p(26, 43), p(38, 41), p(51, 39), p(66, 37)], width: 2, note: "Rail-yard trackage used by armored-train support."),
        line("brzesc-kobryn-rail", "Kobryn rail exit", .railway, [p(63, 37), p(78, 38), p(94, 41)], width: 2, note: "Eastern rail exit that can be cut by German pressure."),
        line("brzesc-bug-west-channel", "Bug west channel", .river, [p(4, 24), p(20, 28), p(38, 29)], width: 3, note: "Western river channel shaping the assault approach."),
        marker("brzesc-muchawiec-marsh", "Muchawiec marsh bend", .marsh, .neutral, p(61, 34), radius: 4, note: "Wet ground where the Muchawiec bends around the fortress."),
        marker("brzesc-bug-floodplain", "Bug floodplain", .marsh, .neutral, p(30, 20), radius: 5, note: "Floodplain beside the Bug River crossing line."),
        marker("brzesc-south-lake", "Southern wet hollow", .lake, .neutral, p(70, 53), radius: 3, note: "Low wet ground on the southern fallback route."),
        marker("brzesc-terespol-bridge", "Terespol bridge", .bridge, .neutral, p(23, 23), radius: 3, note: "Western Bug crossing under German approach pressure."),
        marker("brzesc-rail-bridge", "Rail bridge", .bridge, .neutral, p(37, 28), radius: 3, note: "Rail crossing tied to armored-train movement."),
        marker("brzesc-muchawiec-bridge", "Muchawiec bridge", .bridge, .neutral, p(58, 35), radius: 3, note: "Bridge between town and citadel sectors."),
        marker("brzesc-south-ford", "Southern ford", .ford, .neutral, p(69, 47), radius: 2, note: "Minor crossing on the southern defensive edge."),
        marker("brzesc-bug-ferry", "Bug ferry point", .ferry, .neutral, p(18, 21), radius: 2, note: "Small ferry route that can be interdicted."),
        marker("brzesc-terespol", "Terespol", .village, .neutral, p(16, 39), radius: 4, note: "Western settlement and German approach reference."),
        marker("brzesc-kobylany", "Kobylany", .village, .neutral, p(28, 35), radius: 3, note: "Village on the western road to Brzesc."),
        marker("brzesc-znamenka", "Znamenka", .village, .player, p(76, 51), radius: 3, note: "Eastern locality near fallback routes."),
        marker("brzesc-wola-district", "Wola district", .urbanDistrict, .player, p(37, 46), radius: 4, note: "Urban district screening the town approaches."),
        marker("brzesc-rail-yard-district", "Rail-yard district", .urbanDistrict, .player, p(49, 39), radius: 4, note: "Rail-yard blocks where armored-train support is contested."),
        marker("brzesc-north-suburb", "Northern suburb", .urbanDistrict, .player, p(50, 24), radius: 4, note: "Suburban sector between the Bug and the citadel."),
        marker("brzesc-east-gate", "East gate settlement", .village, .player, p(69, 42), radius: 3, note: "Settlement marking the eastern gate from the fortress area."),
        marker("brzesc-south-suburb", "Southern suburb", .village, .player, p(62, 50), radius: 3, note: "Southern edge of the urban defense."),
        marker("brzesc-kobryn-gate", "Kobryn gate", .objective, .player, p(88, 54), radius: 4, note: "Exit gate for an organized withdrawal toward Kobryn."),
        marker("brzesc-north-fort", "Northern fort sector", .fortifiedLine, .player, p(49, 25), radius: 4, note: "Outer fort sector guarding the Bug side."),
        marker("brzesc-east-fort", "Eastern fort sector", .fortifiedLine, .player, p(65, 35), radius: 4, note: "Fort sector guarding the road and rail exits."),
        marker("brzesc-west-redoubt", "Western redoubt", .bunker, .player, p(41, 34), radius: 3, note: "Strongpoint absorbing the first assault wave."),
        marker("brzesc-island-citadel", "Citadel island sector", .fortifiedLine, .player, p(55, 30), radius: 5, note: "Inner fortress sector bounded by water and urban blocks."),
        marker("brzesc-outer-rampart", "Outer rampart", .fortifiedLine, .player, p(53, 37), radius: 5, note: "Rampart belt that slows the final assault."),
        marker("brzesc-smoke-artillery", "Smoke and artillery point", .artillery, .player, p(44, 48), radius: 3, note: "Fire-support point covering rail and road withdrawal."),
        line("brzesc-phase-citadel-ring", "Citadel ring phase line", .phaseLine, [p(38, 30), p(50, 24), p(65, 28), p(70, 39), p(60, 47), p(43, 43)], width: 2, note: "Operational ring line used when German assault columns isolate the citadel."),
        marker("brzesc-command-fallback", "Command fallback cellar", .objective, .player, p(58, 41), radius: 3, note: "Fallback command point if the town perimeter collapses."),
    ]

    private static let kobrynEnrichment: [ScenarioMapElement] = [
        line("kobryn-brest-rail", "Brzesc-Kobryn rail line", .railway, [p(3, 31), p(25, 33), p(48, 34), p(73, 34), p(98, 36)], width: 2, note: "Rail communications line parallel to the main road."),
        line("kobryn-pinsk-road", "Kobryn-Pinsk road", .road, [p(50, 36), p(64, 44), p(79, 51), p(96, 57)], width: 2, note: "Southeastern withdrawal route toward Polesie."),
        line("kobryn-pruzhany-road", "Pruzhany road", .road, [p(46, 33), p(59, 24), p(74, 16), p(92, 10)], width: 2, note: "Northern route that can be threatened by German patrols."),
        line("kobryn-divin-road", "Divin road", .road, [p(44, 38), p(56, 47), p(68, 57), p(82, 63)], width: 2, note: "Southern road for rearguard withdrawal."),
        line("kobryn-forest-track", "Polesie forest track", .road, [p(36, 46), p(50, 51), p(66, 56), p(82, 59)], width: 2, note: "Low-capacity track through wooded and wet ground."),
        line("kobryn-north-rail-spur", "Northern rail spur", .railway, [p(44, 29), p(59, 24), p(76, 21)], width: 2, note: "Rail spur toward the northern road net."),
        line("kobryn-mukhavets-branch", "Mukhavets branch stream", .river, [p(32, 55), p(44, 50), p(58, 46)], width: 3, note: "Branch watercourse feeding the marsh/canal line."),
        marker("kobryn-marsh-west", "Western Polesie marsh", .marsh, .neutral, p(25, 48), radius: 5, note: "Wet ground that channels German motorized movement onto the road."),
        marker("kobryn-marsh-east", "Eastern Polesie marsh", .marsh, .neutral, p(72, 47), radius: 5, note: "Marsh belt beside the eastern exits."),
        marker("kobryn-drainage-lake", "Drainage pool", .lake, .neutral, p(60, 54), radius: 3, note: "Standing water beside the withdrawal track."),
        marker("kobryn-canal-ford", "Canal ford", .ford, .neutral, p(51, 50), radius: 2, note: "Minor crossing through the canal line."),
        marker("kobryn-road-bridge", "Kobryn road bridge", .bridge, .neutral, p(47, 35), radius: 3, note: "Road bridge at the town center."),
        marker("kobryn-rail-bridge", "Kobryn rail bridge", .bridge, .neutral, p(48, 34), radius: 2, note: "Rail bridge that controls armored-train and supply movement."),
        marker("kobryn-divin-ferry", "Divin ferry", .ferry, .neutral, p(68, 57), radius: 2, note: "Small ferry point on the southern withdrawal road."),
        marker("kobryn-berezno", "Berezno", .village, .player, p(31, 36), radius: 3, note: "Western village screening the first German contact."),
        marker("kobryn-ostromichy", "Ostromichy", .village, .player, p(61, 30), radius: 3, note: "Northern village on the Pruzhany road."),
        marker("kobryn-gorodec", "Gorodec", .village, .player, p(75, 38), radius: 3, note: "Eastern village near the rail and road exits."),
        marker("kobryn-divin", "Divin", .village, .player, p(74, 59), radius: 3, note: "Southern withdrawal village on the Polesie road."),
        marker("kobryn-izyabelin", "Izyabelin", .village, .neutral, p(84, 50), radius: 3, note: "Eastern locality that can become an exit screen."),
        marker("kobryn-rail-yard", "Kobryn rail yard", .urbanDistrict, .player, p(50, 34), radius: 4, note: "Rail-yard blocks where field guns can delay German entry."),
        marker("kobryn-town-east-district", "Kobryn east district", .urbanDistrict, .player, p(56, 37), radius: 4, note: "Urban edge where the rearguard transitions to withdrawal."),
        line("kobryn-polesie-woods", "Polesie woods", .forest, [p(42, 49), p(58, 53), p(77, 58), p(95, 60)], width: 7, note: "Wooded wetland belt masking the withdrawal lanes."),
        marker("kobryn-marsh-choke", "Marsh road choke", .marsh, .neutral, p(64, 45), radius: 4, note: "Wet choke point between town and exits."),
        marker("kobryn-south-wood", "Southern wood", .forest, .player, p(55, 58), radius: 5, note: "Cover for retreating infantry on the southern road."),
        marker("kobryn-gun-line", "Field-gun line", .ridge, .player, p(39, 38), radius: 3, note: "Low rise where field and anti-tank guns cover the western road."),
        marker("kobryn-north-exit", "Northern exit", .objective, .player, p(88, 12), radius: 4, note: "Alternative withdrawal gate toward Pruzhany."),
        marker("kobryn-south-exit", "Southern exit", .objective, .player, p(86, 61), radius: 4, note: "Southern withdrawal gate through Divin."),
        line("kobryn-phase-rearguard", "Rearguard phase line", .phaseLine, [p(30, 33), p(48, 36), p(66, 41)], width: 2, note: "Line where the town defense becomes a delaying action."),
        line("kobryn-phase-withdrawal", "Withdrawal phase line", .phaseLine, [p(61, 45), p(78, 53), p(97, 60)], width: 2, note: "Line that marks the transition to force preservation scoring."),
        marker("kobryn-flank-pressure", "German flank patrol pressure", .airPressure, .guderianAI, p(72, 24), radius: 4, note: "Pressure marker for patrols closing the northern exit."),
    ]

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
        ] + sedanEnrichment,
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
            marker("stonne-bridgehead-risk", "Bridgehead risk line", .objective, .player, p(69, 25), radius: 4, note: "Default side scores by threatening the Sedan bridgehead flank."),
            marker("stonne-german-support", "German support line", .artillery, .guderianAI, p(31, 48), radius: 5, note: "Motorized infantry, anti-tank, and artillery support."),
        ] + stonneEnrichment,
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
        ] + montcornetEnrichment,
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
        ] + amiensAbbevilleEnrichment,
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
        ] + boulogneEnrichment,
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
        ] + calaisEnrichment,
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
            line("dunkirk-canal", "Canal defensive line", .canal, [p(8, 43), p(28, 38), p(51, 35), p(75, 30), p(100, 28)], width: 5, note: "Perimeter obstacle and breach line."),
            line("dunkirk-road", "Dunkirk perimeter road", .road, [p(12, 53), p(35, 46), p(58, 36), p(82, 22)], note: "Rear-guard withdrawal route."),
            marker("dunkirk-beach-sector", "Beach sector", .objective, .player, p(78, 13), radius: 7, note: "Evacuation capacity objective."),
            marker("dunkirk-harbor", "Dunkirk harbor", .town, .player, p(72, 24), radius: 6, note: "Harbor evacuation and perimeter anchor."),
            marker("dunkirk-canal-gate", "Canal gate", .bridge, .player, p(55, 35), radius: 4, note: "Key perimeter crossing."),
            marker("dunkirk-rearguard", "Rear-guard line", .fortifiedLine, .player, p(45, 42), radius: 5, note: "Force left behind to protect evacuation lanes."),
            marker("dunkirk-air", "Air attack lane", .airPressure, .guderianAI, p(68, 8), radius: 6, note: "Evacuation-capacity pressure."),
            marker("dunkirk-german-pressure", "German pressure front", .objective, .guderianAI, p(17, 47), radius: 5, note: "Campaign-pressure marker compressing the perimeter."),
        ] + dunkirkEnrichment,
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
            line("fallrot-canal", "Aisne and Marne-Rhine crossings", .canal, [p(9, 36), p(31, 34), p(55, 31), p(77, 27), p(98, 25)], width: 5, note: "Crossing and demolition line."),
            line("fallrot-vosges", "Vosges retreat corridor", .ridge, [p(55, 54), p(68, 48), p(82, 39), p(95, 32)], width: 5, note: "French withdrawal corridor and trap line."),
            marker("fallrot-langres", "Langres road hub", .town, .player, p(41, 36), radius: 5, note: "Mid-route delay point."),
            marker("fallrot-belfort", "Belfort fortress town", .fortifiedLine, .player, p(78, 30), radius: 6, note: "Late fortress-town stand."),
            marker("fallrot-epinal", "Epinal fortress town", .fortifiedLine, .player, p(72, 46), radius: 5, note: "Northern fortress and retreat hinge."),
            marker("fallrot-fuel", "Fuel denial point", .objective, .player, p(50, 33), radius: 4, note: "Road congestion and fuel friction scoring."),
            marker("fallrot-swiss-border", "Swiss-border cut line", .objective, .guderianAI, p(89, 19), radius: 5, note: "German encirclement finish line."),
        ] + fallRotEnrichment,
        deploymentZones: [
            zone("fallrot-french-delay", "French late-campaign defense", .player, p(36, 27), 46, 28, "French bridge, fortress, and retreat-corridor defenders."),
            zone("fallrot-panzergruppe", "Panzergruppe Guderian columns", .guderianAI, p(0, 38), 30, 19, "German deep exploitation columns enter from the west."),
        ]
    )

    private static let sedanEnrichment: [ScenarioMapElement] = [
        line("sedan-meuse-loop", "Meuse loop backwater", .river, [p(5, 36), p(25, 33), p(45, 36), p(68, 43), p(96, 45)], width: 4, note: "Secondary Meuse bend that frames the bridgehead depth."),
        line("sedan-bar-stream", "Bar stream approach", .river, [p(16, 61), p(31, 52), p(44, 42), p(55, 33)], width: 3, note: "Tributary drainage that channels road movement toward Sedan."),
        marker("sedan-meuse-floodplain", "Meuse floodplain", .marsh, .neutral, p(37, 31), radius: 5, note: "Wet ground beside the river limits off-road deployment."),
        marker("sedan-bar-marsh", "Bar marsh pocket", .marsh, .neutral, p(26, 52), radius: 4, note: "Low ground where traffic bunches before the crossing."),
        line("sedan-donchery-road", "Donchery-Sedan road", .road, [p(5, 38), p(20, 36), p(34, 37), p(44, 39)], width: 2, note: "West-bank road feeding assault engineers."),
        line("sedan-floing-road", "Floing approach road", .road, [p(11, 26), p(26, 29), p(40, 34), p(52, 39)], width: 2, note: "Northern approach into the Sedan bridge zone."),
        line("sedan-chehery-road", "Chehery expansion road", .road, [p(56, 37), p(66, 43), p(80, 47), p(96, 48)], width: 2, note: "Bridgehead expansion route toward the French rear."),
        line("sedan-artillery-track", "French artillery service track", .road, [p(58, 48), p(70, 51), p(85, 53), p(100, 55)], width: 2, note: "Rear track linking batteries and ammunition positions."),
        line("sedan-charleville-rail", "Charleville-Sedan rail line", .railway, [p(0, 22), p(22, 25), p(45, 29), p(69, 31), p(97, 33)], width: 2, note: "Rail embankment parallels the Meuse and constrains crossings."),
        line("sedan-meuse-rail-spur", "Meuse rail spur", .railway, [p(36, 28), p(45, 36), p(53, 43)], width: 2, note: "Industrial spur through Sedan's riverfront district."),
        marker("sedan-donchery-bridge", "Donchery bridge site", .bridge, .neutral, p(24, 34), radius: 3, note: "Alternate crossing point west of Sedan."),
        marker("sedan-floing-bridge", "Floing bridge site", .bridge, .neutral, p(37, 30), radius: 3, note: "Northern bridge point under observation from the heights."),
        marker("sedan-rail-bridge", "Sedan rail bridge", .bridge, .player, p(43, 32), radius: 3, note: "Rail bridge demolition and repair contest."),
        marker("sedan-meuse-ferry", "Meuse ferry reach", .ferry, .neutral, p(53, 36), radius: 3, note: "Fallback ferry reach for emergency river movement."),
        marker("sedan-torcy-ford", "Torcy shallow reach", .ford, .neutral, p(34, 35), radius: 3, note: "Shallow river reach that scouts can probe but armor cannot exploit quickly."),
        marker("sedan-floing", "Floing village", .village, .player, p(34, 27), radius: 3, note: "Village north of Sedan anchoring the approach road."),
        marker("sedan-donchery", "Donchery village", .village, .player, p(20, 36), radius: 4, note: "West-bank settlement used as an assembly and bridge-control point."),
        marker("sedan-wadelincourt", "Wadelincourt village", .village, .player, p(59, 37), radius: 3, note: "East-bank village behind the secondary bridge site."),
        marker("sedan-gaulier", "Gaulier village", .village, .player, p(50, 28), radius: 3, note: "Village beside the primary crossing zone."),
        marker("sedan-torcy-district", "Torcy river district", .urbanDistrict, .player, p(38, 34), radius: 4, note: "Riverfront streets turn the crossing into close terrain."),
        marker("sedan-balcon-ridge", "Balcon ridge", .ridge, .player, p(57, 24), radius: 5, note: "Observation ground over the Meuse crossings."),
        marker("sedan-marfee-heights", "Marfee heights", .ridge, .player, p(62, 50), radius: 5, note: "Southern heights that cover the artillery parks."),
        line("sedan-bois-marfee", "Bois de la Marfee", .forest, [p(48, 52), p(63, 55), p(79, 57), p(94, 57)], width: 6, note: "Wood belt screening French reserves."),
        marker("sedan-forward-trench", "Forward trench line", .fortifiedLine, .player, p(48, 40), radius: 5, note: "Forward prepared line behind the Meuse bank."),
        marker("sedan-east-artillery-park", "Eastern artillery park", .artillery, .player, p(82, 51), radius: 4, note: "Additional battery group supporting the near-bank defense."),
        marker("sedan-pont-maas", "Pont Maugis crossing watch", .objective, .player, p(63, 39), radius: 3, note: "French scoring point for denying bridgehead widening."),
        line("sedan-bridgehead-phase", "Bridgehead phase line", .phaseLine, [p(50, 31), p(61, 36), p(75, 41)], width: 2, note: "Line marking the first German consolidation limit."),
        line("sedan-counterattack-phase", "French counterattack phase line", .phaseLine, [p(58, 45), p(72, 48), p(91, 50)], width: 2, note: "Counterattack trigger line for reserve armor and infantry."),
        marker("sedan-meuse-backwater", "Meuse backwater pool", .lake, .neutral, p(47, 30), radius: 3, note: "River backwater complicating direct movement through the bank."),
        line("sedan-german-assembly-track", "German assembly track", .road, [p(2, 16), p(17, 20), p(32, 26), p(43, 31)], width: 2, note: "West-bank track where assault units stack before crossing."),
    ]

    private static let stonneEnrichment: [ScenarioMapElement] = [
        line("stonne-bar-stream", "Bar valley stream", .river, [p(8, 58), p(25, 50), p(44, 43), p(63, 35), p(86, 27)], width: 3, note: "Valley drainage below Stonne that funnels the flank route."),
        line("stonne-meuse-rear-line", "Meuse rear crossing line", .river, [p(2, 35), p(20, 33), p(38, 34), p(56, 32)], width: 3, note: "Rear Meuse reference line tying Stonne to Sedan."),
        marker("stonne-low-marsh", "Low valley marsh", .marsh, .neutral, p(31, 49), radius: 4, note: "Wet valley floor below the counterattack route."),
        line("stonne-bulson-road", "Bulson road", .road, [p(20, 51), p(34, 44), p(48, 36), p(62, 29)], width: 2, note: "Road connecting the Sedan bridgehead to Stonne."),
        line("stonne-beaumont-road", "Beaumont approach road", .road, [p(42, 58), p(50, 48), p(58, 37), p(68, 27)], width: 2, note: "Southern approach for French counterattacks."),
        line("stonne-les-grandes-road", "Les Grandes-Armoises road", .road, [p(55, 32), p(70, 34), p(86, 37), p(99, 41)], width: 2, note: "Eastern ridge road used for reinforcement and withdrawal."),
        line("stonne-reserve-track", "Reserve tank track", .road, [p(35, 25), p(45, 30), p(55, 35)], width: 2, note: "Short armor track into the contested village."),
        line("stonne-sedan-vouziers-rail", "Sedan-Vouziers rail trace", .railway, [p(0, 47), p(19, 45), p(39, 43), p(60, 40), p(82, 36)], width: 2, note: "Rail trace below the heights and behind the road fight."),
        marker("stonne-bulson-bridge", "Bulson bridge", .bridge, .neutral, p(38, 42), radius: 3, note: "Stream bridge feeding the German flank."),
        marker("stonne-beaumont-ford", "Beaumont ford", .ford, .neutral, p(48, 47), radius: 3, note: "Minor crossing for infantry probes below the heights."),
        marker("stonne-valley-ferry", "Valley ferry track", .ferry, .neutral, p(23, 51), radius: 3, note: "Improvised local crossing point in the valley."),
        marker("stonne-bulson", "Bulson village", .village, .guderianAI, p(34, 44), radius: 3, note: "German bridgehead village at the base of the Stonne road."),
        marker("stonne-beaumont", "Beaumont-en-Argonne", .village, .player, p(46, 55), radius: 4, note: "Southern staging village for French armor."),
        marker("stonne-les-grandes", "Les Grandes-Armoises", .village, .player, p(79, 36), radius: 3, note: "Eastern village on the reinforcement road."),
        marker("stonne-la-berliere", "La Berliere village", .village, .player, p(65, 21), radius: 3, note: "Northern village beyond the Mont-Dieu woods."),
        marker("stonne-town-district", "Stonne stone lanes", .urbanDistrict, .neutral, p(53, 34), radius: 4, note: "Built-up lanes that make the village fight attritional."),
        marker("stonne-mont-damion", "Mont Damion ridge", .ridge, .player, p(61, 23), radius: 4, note: "Observation spur overlooking the village."),
        marker("stonne-sugarloaf", "Sugarloaf height", .ridge, .neutral, p(50, 27), radius: 4, note: "Local high ground repeatedly contested by armor and infantry."),
        line("stonne-bois-chesne", "Bois du Chesne", .forest, [p(61, 16), p(75, 20), p(91, 25)], width: 5, note: "Wooded cover north-east of the heights."),
        line("stonne-argonne-woodline", "Argonne woodline", .forest, [p(7, 18), p(24, 21), p(43, 21)], width: 6, note: "Wooded approach masking French reserves."),
        marker("stonne-at-belt", "Anti-tank belt", .fortifiedLine, .guderianAI, p(39, 41), radius: 4, note: "German gun belt covering the road into Stonne."),
        marker("stonne-french-gun-ridge", "French gun ridge", .artillery, .player, p(67, 26), radius: 4, note: "French artillery observers over the bridgehead flank."),
        marker("stonne-german-flak", "German flak roadblock", .artillery, .guderianAI, p(42, 39), radius: 3, note: "Flak and anti-tank guns harden the counterattack route."),
        marker("stonne-tank-counterstroke", "Tank counterstroke gate", .objective, .player, p(47, 37), radius: 4, note: "Scoring marker for French armor breaking into Stonne."),
        line("stonne-phase-village", "Village fight phase line", .phaseLine, [p(41, 37), p(53, 34), p(66, 30)], width: 2, note: "Phase line for control of Stonne and the heights."),
        line("stonne-phase-bridgehead", "Bridgehead-threat phase line", .phaseLine, [p(58, 28), p(72, 25), p(88, 22)], width: 2, note: "Line where French pressure threatens the Sedan bridgehead."),
        marker("stonne-raid-pressure", "German dive-bomber pressure", .airPressure, .guderianAI, p(55, 17), radius: 4, note: "Air pressure marker against the Char B1 counterattack route."),
    ]

    private static let montcornetEnrichment: [ScenarioMapElement] = [
        line("montcornet-serre", "Serre River line", .river, [p(7, 45), p(26, 42), p(48, 38), p(70, 35), p(95, 31)], width: 4, note: "River line crossing the road hub and limiting the raid."),
        line("montcornet-souche", "Souche tributary", .river, [p(26, 56), p(37, 47), p(49, 39), p(62, 31)], width: 3, note: "Small tributary that channels withdrawal traffic."),
        marker("montcornet-serre-marsh", "Serre wet meadows", .marsh, .neutral, p(48, 39), radius: 4, note: "Wet meadows around the river crossings."),
        line("montcornet-laon-road", "Laon road", .road, [p(14, 58), p(27, 48), p(40, 39), p(53, 32)], width: 2, note: "French approach road from the south-west."),
        line("montcornet-guise-road", "Guise road", .road, [p(51, 32), p(63, 25), p(76, 17), p(90, 10)], width: 2, note: "Northern German traffic route through Montcornet."),
        line("montcornet-la-ferte-road", "La Ferte road", .road, [p(55, 34), p(69, 40), p(84, 45), p(99, 49)], width: 2, note: "Eastern route for German column dispersal."),
        line("montcornet-rozoy-road", "Rozoy road", .road, [p(50, 35), p(41, 29), p(31, 23), p(18, 18)], width: 2, note: "Northern flank road used by column guards."),
        line("montcornet-service-track", "Column service track", .road, [p(61, 41), p(73, 37), p(86, 32)], width: 2, note: "Rear-area service route around the column park."),
        line("montcornet-laon-rail", "Laon-Montcornet rail line", .railway, [p(0, 50), p(22, 46), p(45, 40), p(68, 34), p(96, 28)], width: 2, note: "Rail line paralleling the main road and station area."),
        line("montcornet-yard-spur", "Montcornet yard spur", .railway, [p(47, 37), p(55, 32), p(66, 28)], width: 2, note: "Station spur through the town's supply area."),
        marker("montcornet-serre-bridge", "Serre road bridge", .bridge, .neutral, p(51, 36), radius: 3, note: "Primary bridge in the raid center."),
        marker("montcornet-souche-ford", "Souche ford", .ford, .neutral, p(39, 46), radius: 3, note: "Minor ford used for flank movement."),
        marker("montcornet-rail-bridge", "Rail bridge", .bridge, .neutral, p(58, 35), radius: 3, note: "Rail crossing and demolition point."),
        marker("montcornet-lislet", "Lislet village", .village, .player, p(31, 52), radius: 3, note: "French approach village before the raid objective."),
        marker("montcornet-sissonne", "Sissonne assembly", .village, .player, p(21, 60), radius: 4, note: "Rear armor assembly village."),
        marker("montcornet-rozoy", "Rozoy-sur-Serre", .village, .guderianAI, p(23, 20), radius: 3, note: "Northern road node for German security."),
        marker("montcornet-la-ville", "La Ville-aux-Bois", .village, .guderianAI, p(71, 43), radius: 3, note: "Eastern screen village behind the column park."),
        marker("montcornet-station-district", "Station district", .urbanDistrict, .neutral, p(56, 34), radius: 4, note: "Rail and road district where traffic congestion becomes tactical terrain."),
        marker("montcornet-serre-bank", "Serre bank ridge", .ridge, .neutral, p(62, 29), radius: 4, note: "Low ridge overlooking the river crossing."),
        line("montcornet-bois-clermont", "Bois de Clermont", .forest, [p(62, 49), p(78, 52), p(94, 53)], width: 5, note: "Wooded cover south-east of the column routes."),
        line("montcornet-bois-north", "Northern wood belt", .forest, [p(24, 16), p(42, 16), p(60, 18)], width: 5, note: "Wood belt screening German road security."),
        marker("montcornet-roadblock-belt", "German roadblock belt", .fortifiedLine, .guderianAI, p(64, 31), radius: 4, note: "Improvised defenses around the column park."),
        marker("montcornet-french-gun-stop", "French gun stop", .artillery, .player, p(42, 43), radius: 3, note: "Forward gun position for covering tank withdrawal."),
        marker("montcornet-fuel-column", "Fuel column target", .objective, .guderianAI, p(70, 29), radius: 4, note: "German fuel traffic gives the raid an additional disruption target."),
        line("montcornet-phase-raid", "Raid penetration phase line", .phaseLine, [p(36, 44), p(51, 36), p(68, 30)], width: 2, note: "Phase line for French armor entering the road hub."),
        line("montcornet-phase-disengage", "Disengagement phase line", .phaseLine, [p(41, 49), p(27, 42), p(12, 32)], width: 2, note: "Phase line for surviving tanks exiting the battlefield."),
        marker("montcornet-air-reaction-point", "Air reaction point", .airPressure, .guderianAI, p(72, 19), radius: 4, note: "Luftwaffe reaction point against exposed French armor."),
    ]

    private static let amiensAbbevilleEnrichment: [ScenarioMapElement] = [
        line("amiens-somme-north-branch", "Somme north branch", .river, [p(7, 34), p(28, 33), p(51, 35), p(73, 31), p(99, 28)], width: 4, note: "Northern branch of the Somme crossing belt."),
        line("amiens-somme-marsh-channel", "Somme marsh channel", .canal, [p(18, 47), p(40, 45), p(63, 40), p(88, 36)], width: 3, note: "Canalized wetland channel between Amiens and Abbeville."),
        marker("amiens-somme-marshes", "Somme marshes", .marsh, .neutral, p(61, 39), radius: 5, note: "Marsh belt that slows the Channel dash off the paved road."),
        marker("amiens-abbeville-backwater", "Abbeville backwater", .lake, .neutral, p(82, 33), radius: 3, note: "Backwater beside the Abbeville crossing."),
        line("amiens-poix-road", "Poix-Amiens road", .road, [p(4, 56), p(18, 51), p(32, 44)], width: 2, note: "Western approach road into Amiens."),
        line("amiens-doullens-road", "Doullens road", .road, [p(32, 43), p(46, 32), p(59, 21)], width: 2, note: "Northern route for blocking detachments."),
        line("amiens-hesdin-road", "Hesdin-Abbeville road", .road, [p(67, 35), p(78, 28), p(92, 21)], width: 2, note: "Road from Abbeville toward the coast."),
        line("amiens-rue-road", "Rue coast road", .road, [p(79, 31), p(89, 25), p(100, 18)], width: 2, note: "Coastal exit road after the Somme crossing."),
        line("amiens-rail-main", "Amiens-Abbeville rail line", .railway, [p(9, 45), p(32, 42), p(55, 39), p(78, 32), p(98, 27)], width: 2, note: "Rail line that follows the Somme valley."),
        line("amiens-rail-doullens", "Doullens rail branch", .railway, [p(32, 42), p(43, 35), p(55, 25)], width: 2, note: "Rail branch toward the northern blocking route."),
        marker("amiens-longpre-bridge", "Longpre bridge", .bridge, .neutral, p(63, 38), radius: 3, note: "Somme bridge where rearguards can delay the drive."),
        marker("amiens-picquigny-bridge", "Picquigny bridge", .bridge, .neutral, p(47, 40), radius: 3, note: "Central crossing between Amiens and Abbeville."),
        marker("amiens-rail-bridge", "Somme rail bridge", .bridge, .neutral, p(55, 38), radius: 3, note: "Rail crossing that can be denied or repaired."),
        marker("amiens-marsh-ford", "Marsh ford", .ford, .neutral, p(70, 37), radius: 3, note: "Minor marsh crossing for infantry screens."),
        marker("amiens-picquigny", "Picquigny village", .village, .player, p(46, 41), radius: 3, note: "Village guarding a Somme crossing."),
        marker("amiens-longpre", "Longpre-les-Corps-Saints", .village, .player, p(63, 37), radius: 3, note: "Village in the Somme marsh belt."),
        marker("amiens-airaines", "Airaines village", .village, .player, p(69, 48), radius: 3, note: "Southern road village where roadblocks can re-form."),
        marker("amiens-rue", "Rue coast village", .village, .player, p(92, 20), radius: 3, note: "Coastal exit village beyond Abbeville."),
        marker("amiens-station-district", "Amiens station district", .urbanDistrict, .player, p(35, 42), radius: 4, note: "Rail and road district that makes Amiens more than a single town marker."),
        marker("abbeville-port-district", "Abbeville river district", .urbanDistrict, .player, p(80, 31), radius: 4, note: "Built-up Somme district at the Channel cut objective."),
        marker("amiens-somme-bluff", "Somme bluff", .ridge, .player, p(58, 31), radius: 4, note: "Low bluff overlooking the Somme valley road."),
        line("amiens-villers-wood", "Villers wood belt", .forest, [p(38, 23), p(55, 22), p(72, 25)], width: 5, note: "Wood belt north of the main route."),
        line("amiens-marsh-reed-beds", "Somme reed beds", .marsh, [p(51, 43), p(67, 40), p(84, 35)], width: 4, note: "Reed-bed line that makes the valley a crossing puzzle."),
        marker("amiens-blockhouse-line", "Somme blockhouse line", .fortifiedLine, .player, p(55, 36), radius: 4, note: "Improvised Allied blockhouse and roadblock belt."),
        marker("amiens-german-forward-guns", "Forward gun column", .artillery, .guderianAI, p(19, 48), radius: 3, note: "German guns supporting the road race."),
        marker("amiens-bridge-demolition", "Bridge demolition teams", .objective, .player, p(58, 39), radius: 4, note: "Allied objective for slowing the Channel cut."),
        line("amiens-phase-amiens", "Amiens phase line", .phaseLine, [p(22, 46), p(34, 42), p(47, 39)], width: 2, note: "Line where the race enters the Amiens road hub."),
        line("amiens-phase-abbeville", "Abbeville phase line", .phaseLine, [p(62, 37), p(78, 31), p(95, 25)], width: 2, note: "Line where the battle shifts to Channel exit control."),
        marker("amiens-air-pressure", "Air pressure over Somme bridges", .airPressure, .guderianAI, p(66, 24), radius: 4, note: "Air pressure marker against blocking detachments."),
        marker("amiens-coast-cut", "Coast cut marker", .objective, .guderianAI, p(99, 19), radius: 3, note: "Operational marker for reaching the Channel coast."),
    ]

    private static let boulogneEnrichment: [ScenarioMapElement] = [
        line("boulogne-coastline", "Channel coastline", .canal, [p(50, 12), p(64, 10), p(80, 12), p(98, 16)], width: 4, note: "Coastal edge of the evacuation port."),
        line("boulogne-liane-inner", "Inner Liane branch", .river, [p(35, 50), p(47, 42), p(61, 33), p(78, 27)], width: 3, note: "Inner harbor branch through the town."),
        marker("boulogne-harbor-basin", "Harbor basin", .lake, .player, p(76, 24), radius: 5, note: "Basin where evacuation craft and destroyers operate."),
        marker("boulogne-mudflats", "Liane mudflats", .marsh, .neutral, p(61, 31), radius: 4, note: "Tidal mud flats restrict movement around the harbor."),
        line("boulogne-saint-omer-road", "Saint-Omer road", .road, [p(11, 58), p(25, 49), p(39, 40), p(55, 33)], width: 2, note: "Inland approach toward Boulogne."),
        line("boulogne-wimille-road", "Wimille coast road", .road, [p(55, 25), p(67, 19), p(81, 16), p(98, 16)], width: 2, note: "Northern coast road around the port."),
        line("boulogne-outreau-road", "Outreau road", .road, [p(56, 37), p(66, 45), p(78, 53), p(92, 59)], width: 2, note: "Southern urban approach and fallback route."),
        line("boulogne-port-service-road", "Port service road", .road, [p(64, 29), p(73, 27), p(84, 25)], width: 2, note: "Service road between harbor works and demolition teams."),
        line("boulogne-rail-main", "Boulogne rail approach", .railway, [p(8, 52), p(28, 46), p(50, 38), p(71, 29)], width: 2, note: "Rail approach entering the port district."),
        line("boulogne-harbor-rail", "Harbor rail spur", .railway, [p(66, 31), p(75, 25), p(85, 22)], width: 2, note: "Harbor spur used for supply and evacuation handling."),
        marker("boulogne-liane-road-bridge", "Liane road bridge", .bridge, .player, p(58, 33), radius: 3, note: "Road bridge linking the old town to the harbor."),
        marker("boulogne-rail-bridge", "Liane rail bridge", .bridge, .player, p(64, 29), radius: 3, note: "Rail bridge across the inner harbor branch."),
        marker("boulogne-harbor-ferry", "Harbor ferry slip", .ferry, .player, p(80, 24), radius: 3, note: "Small-craft evacuation slip in the harbor."),
        marker("boulogne-wimille", "Wimille village", .village, .player, p(71, 17), radius: 3, note: "Northern village on the coast road."),
        marker("boulogne-outreau", "Outreau district", .urbanDistrict, .player, p(75, 51), radius: 4, note: "Southern built-up district guarding a road approach."),
        marker("boulogne-saint-martin", "Saint-Martin district", .urbanDistrict, .player, p(52, 34), radius: 4, note: "Urban district beside the Haute Ville defense."),
        marker("boulogne-le-portel", "Le Portel village", .village, .player, p(87, 47), radius: 3, note: "Coastal settlement south of the port."),
        marker("boulogne-station-quarter", "Station quarter", .urbanDistrict, .player, p(63, 32), radius: 4, note: "Rail-yard district that splits the port defense."),
        marker("boulogne-mont-couple", "Mont Couple ridge", .ridge, .guderianAI, p(30, 29), radius: 4, note: "Approach ridge for German observation."),
        marker("boulogne-brecquerecque-ridge", "Brecquerecque ridge", .ridge, .player, p(53, 47), radius: 4, note: "High ground behind the southern urban district."),
        line("boulogne-wimereux-woods", "Wimereux wood belt", .forest, [p(50, 19), p(63, 18), p(77, 20)], width: 4, note: "Wood belt north of the port road."),
        marker("boulogne-citadel-wall", "Citadel wall", .fortifiedLine, .player, p(56, 35), radius: 4, note: "Old-town wall segment within the perimeter."),
        marker("boulogne-harbor-bunkers", "Harbor bunkers", .bunker, .player, p(72, 27), radius: 3, note: "Port-defense strongpoints covering the docks."),
        marker("boulogne-naval-gun-line", "Naval gun line", .artillery, .player, p(88, 18), radius: 4, note: "Destroyer support lanes covering the harbor mouth."),
        marker("boulogne-demolition-cache", "Demolition cache", .objective, .player, p(75, 32), radius: 3, note: "Additional port-denial target after evacuation."),
        marker("boulogne-panzer-flank", "Panzer flank pressure", .objective, .guderianAI, p(32, 37), radius: 4, note: "German objective for enveloping the port perimeter."),
        line("boulogne-phase-harbor", "Harbor perimeter phase line", .phaseLine, [p(50, 36), p(64, 31), p(79, 27)], width: 2, note: "Phase line where the fight compresses to the harbor."),
        line("boulogne-phase-evacuation", "Evacuation phase line", .phaseLine, [p(67, 24), p(80, 22), p(93, 20)], width: 2, note: "Phase line controlling the final embarkation window."),
        marker("boulogne-air-pressure", "Air pressure over harbor", .airPressure, .guderianAI, p(69, 14), radius: 4, note: "Air attack pressure against evacuation capacity."),
        marker("boulogne-breakwater", "Breakwater objective", .objective, .player, p(86, 22), radius: 3, note: "Breakwater control affects harbor evacuation capacity."),
    ]

    private static let calaisEnrichment: [ScenarioMapElement] = [
        line("calais-coastline", "Calais coastline", .canal, [p(54, 15), p(70, 12), p(87, 12), p(100, 15)], width: 4, note: "Channel edge that frames the port defense."),
        line("calais-harbor-channel", "Harbor channel", .canal, [p(63, 28), p(72, 23), p(83, 19), p(96, 17)], width: 4, note: "Canalized harbor channel through the port."),
        line("calais-aa-canal", "Aa Canal line", .canal, [p(12, 50), p(31, 46), p(51, 41), p(73, 34)], width: 4, note: "Canal approach that helps form the siege perimeter."),
        marker("calais-harbor-basin", "Calais harbor basin", .lake, .player, p(76, 22), radius: 5, note: "Harbor basin and final supply pocket."),
        marker("calais-marsh-approach", "Coastal marsh approach", .marsh, .neutral, p(43, 39), radius: 4, note: "Wet low ground on the approach to the outer perimeter."),
        line("calais-saint-omer-road", "Saint-Omer road", .road, [p(8, 55), p(24, 48), p(42, 40), p(59, 33)], width: 2, note: "Inland road into the Calais siege line."),
        line("calais-gravelines-road", "Gravelines road", .road, [p(56, 34), p(70, 35), p(86, 34), p(99, 31)], width: 2, note: "Coastal road toward Dunkirk and Gravelines."),
        line("calais-sangatte-road", "Sangatte road", .road, [p(59, 33), p(69, 27), p(82, 21), p(95, 17)], width: 2, note: "Coastal road south-west of the port."),
        line("calais-ring-road", "Inner ring road", .road, [p(46, 36), p(57, 31), p(68, 29), p(75, 24)], width: 2, note: "Urban ring route between perimeter and harbor."),
        line("calais-rail-main", "Calais rail approach", .railway, [p(4, 49), p(24, 45), p(45, 39), p(66, 31), p(88, 24)], width: 2, note: "Rail approach through the siege zone."),
        line("calais-harbor-rail-spur", "Harbor rail spur", .railway, [p(66, 30), p(74, 24), p(84, 20)], width: 2, note: "Rail spur feeding the docks and citadel district."),
        marker("calais-aa-bridge", "Aa Canal bridge", .bridge, .neutral, p(38, 43), radius: 3, note: "Canal crossing on the main siege approach."),
        marker("calais-harbor-bridge", "Harbor bridge", .bridge, .player, p(72, 24), radius: 3, note: "Bridge within the docks and harbor defense."),
        marker("calais-rail-bridge", "Calais rail bridge", .bridge, .player, p(63, 32), radius: 3, note: "Rail crossing into the urban perimeter."),
        marker("calais-canal-ford", "Canal service ford", .ford, .neutral, p(52, 39), radius: 3, note: "Service crossing for infantry probes at the outer line."),
        marker("calais-gravelines", "Gravelines road village", .village, .player, p(89, 33), radius: 3, note: "Village on the Dunkirk road axis."),
        marker("calais-coquelles", "Coquelles village", .village, .player, p(45, 31), radius: 3, note: "Village anchoring the south-west perimeter."),
        marker("calais-sangatte", "Sangatte village", .village, .player, p(82, 20), radius: 3, note: "Coastal village near the western approaches."),
        marker("calais-station-district", "Station district", .urbanDistrict, .player, p(61, 31), radius: 4, note: "Built-up rail district inside the outer perimeter."),
        marker("calais-dock-district", "Dock district", .urbanDistrict, .player, p(74, 24), radius: 4, note: "Docks become close terrain around the final objective."),
        marker("calais-hotel-de-ville", "Town hall district", .urbanDistrict, .player, p(63, 28), radius: 4, note: "Central city district between citadel and perimeter."),
        marker("calais-dune-ridge", "Dune ridge", .ridge, .neutral, p(72, 17), radius: 4, note: "Coastal high ground overlooking the harbor."),
        line("calais-northern-dunes", "Northern dune belt", .ridge, [p(62, 15), p(78, 14), p(94, 16)], width: 4, note: "Dune belt along the Channel coast."),
        marker("calais-bastion-line", "Bastion line", .fortifiedLine, .player, p(58, 34), radius: 5, note: "Intermediate bastion line before the citadel."),
        marker("calais-dock-bunkers", "Dock bunkers", .bunker, .player, p(76, 25), radius: 3, note: "Strongpoints defending the harbor district."),
        marker("calais-german-gun-park", "German gun park", .artillery, .guderianAI, p(32, 38), radius: 4, note: "Siege artillery supporting the 10th Panzer attack."),
        marker("calais-delay-objective", "Dunkirk delay objective", .objective, .player, p(91, 31), radius: 4, note: "Strategic delay marker for holding German pressure away from Dunkirk."),
        line("calais-phase-outer", "Outer perimeter phase line", .phaseLine, [p(38, 42), p(51, 37), p(66, 32)], width: 2, note: "Phase line for the first reduction of the perimeter."),
        line("calais-phase-citadel", "Citadel phase line", .phaseLine, [p(58, 31), p(67, 27), p(77, 23)], width: 2, note: "Phase line for the final citadel and docks fight."),
        marker("calais-air-artillery-spot", "Air artillery spotter lane", .airPressure, .guderianAI, p(49, 21), radius: 4, note: "Air and artillery pressure marker against supply endurance."),
    ]

    private static let dunkirkEnrichment: [ScenarioMapElement] = [
        line("dunkirk-bray-dunes", "Bray-Dunes beach sector", .road, [p(76, 9), p(86, 8), p(98, 10)], width: 3, note: "Eastern beach evacuation sector."),
        line("dunkirk-malo-beach", "Malo-les-Bains beach sector", .road, [p(58, 12), p(68, 10), p(78, 10)], width: 3, note: "Central beach sector serving embarkation columns."),
        line("dunkirk-gravelines-canal", "Gravelines canal", .canal, [p(2, 49), p(22, 45), p(43, 40), p(64, 36)], width: 4, note: "Western canal line defending the perimeter."),
        line("dunkirk-bergues-canal", "Bergues canal", .canal, [p(21, 54), p(35, 47), p(52, 38), p(70, 29)], width: 4, note: "Canal route from Bergues into Dunkirk."),
        line("dunkirk-furnes-canal", "Furnes canal", .canal, [p(50, 36), p(66, 30), p(84, 24), p(100, 22)], width: 4, note: "Eastern canal protecting the Belgian side of the perimeter."),
        marker("dunkirk-polder-marsh", "Polder marsh", .marsh, .neutral, p(52, 34), radius: 5, note: "Low polder ground between canals and beach roads."),
        marker("dunkirk-inner-harbor-basin", "Inner harbor basin", .lake, .player, p(72, 22), radius: 4, note: "Harbor basin for evacuation and supply handling."),
        line("dunkirk-cassel-road", "Cassel road", .road, [p(6, 58), p(22, 52), p(39, 46), p(55, 38)], width: 2, note: "South-west road used by rear guards falling back."),
        line("dunkirk-bergues-road", "Bergues road", .road, [p(20, 55), p(36, 47), p(53, 37), p(69, 27)], width: 2, note: "Road beside the Bergues canal."),
        line("dunkirk-furnes-road", "Furnes road", .road, [p(63, 30), p(76, 26), p(90, 23), p(100, 21)], width: 2, note: "Eastern road toward the Belgian perimeter."),
        line("dunkirk-harbor-service-road", "Harbor service road", .road, [p(66, 24), p(75, 22), p(86, 20)], width: 2, note: "Service road linking harbor and beach sectors."),
        line("dunkirk-rail-main", "Dunkirk rail approach", .railway, [p(5, 50), p(28, 45), p(50, 38), p(72, 25)], width: 2, note: "Rail approach into the port city."),
        line("dunkirk-mole-rail-spur", "Mole rail spur", .railway, [p(69, 24), p(79, 19), p(91, 16)], width: 2, note: "Harbor rail spur toward the evacuation mole."),
        marker("dunkirk-gravelines-bridge", "Gravelines bridge", .bridge, .player, p(34, 42), radius: 3, note: "Western canal crossing held by rear guards."),
        marker("dunkirk-bergues-bridge", "Bergues bridge", .bridge, .player, p(50, 38), radius: 3, note: "Central bridge on the withdrawal road."),
        marker("dunkirk-furnes-bridge", "Furnes bridge", .bridge, .player, p(76, 26), radius: 3, note: "Eastern canal bridge toward the Belgian flank."),
        marker("dunkirk-beach-ferry", "Small-craft ferry lane", .ferry, .player, p(84, 13), radius: 3, note: "Small-craft pickup lane on the beach."),
        marker("dunkirk-gravelines", "Gravelines", .village, .player, p(29, 44), radius: 3, note: "Western perimeter settlement on the canal line."),
        marker("dunkirk-bergues", "Bergues", .village, .player, p(46, 39), radius: 3, note: "Canal town anchoring the central perimeter."),
        marker("dunkirk-malo", "Malo-les-Bains", .urbanDistrict, .player, p(67, 13), radius: 4, note: "Beach district handling evacuation traffic."),
        marker("dunkirk-rosendael", "Rosendael district", .urbanDistrict, .player, p(73, 19), radius: 4, note: "Urban district between harbor and beaches."),
        marker("dunkirk-bray-dunes-town", "Bray-Dunes", .village, .player, p(91, 11), radius: 3, note: "Eastern beach village."),
        marker("dunkirk-dune-belt", "Dune belt", .ridge, .neutral, p(79, 10), radius: 4, note: "Coastal dunes controlling beach movement."),
        line("dunkirk-polder-ditches", "Polder ditch belt", .marsh, [p(41, 35), p(58, 32), p(76, 28)], width: 4, note: "Waterlogged ditch line behind the canals."),
        line("dunkirk-nieuwpoort-dunes", "Nieuwpoort dune ridge", .ridge, [p(81, 8), p(92, 9), p(100, 11)], width: 3, note: "Eastern coastal ridge beyond the beach sector."),
        marker("dunkirk-canal-bunkers", "Canal bunker belt", .bunker, .player, p(47, 40), radius: 4, note: "Strongpoints covering the bridge and canal gates."),
        marker("dunkirk-mole-guns", "Mole gun line", .artillery, .player, p(77, 18), radius: 4, note: "Harbor gun and naval support point."),
        marker("dunkirk-beach-capacity", "Beach capacity marker", .objective, .player, p(87, 12), radius: 4, note: "Additional objective for tracking evacuation throughput."),
        marker("dunkirk-canal-demolition", "Canal demolition charges", .objective, .player, p(53, 36), radius: 4, note: "Demolition objective to delay German pressure."),
        marker("dunkirk-german-artillery-park", "German artillery park", .artillery, .guderianAI, p(24, 49), radius: 4, note: "Pressure source against canal defenders."),
        line("dunkirk-phase-canal", "Canal defense phase line", .phaseLine, [p(29, 44), p(48, 39), p(69, 31)], width: 2, note: "Phase line for holding the canal perimeter."),
        line("dunkirk-phase-beach", "Beach evacuation phase line", .phaseLine, [p(62, 16), p(78, 13), p(95, 13)], width: 2, note: "Phase line for the final withdrawal to beaches."),
        marker("dunkirk-stuka-raid", "Stuka raid corridor", .airPressure, .guderianAI, p(80, 7), radius: 4, note: "Air pressure corridor over the beach sectors."),
        marker("dunkirk-eastern-exit", "Eastern evacuation gate", .objective, .player, p(98, 13), radius: 3, note: "Evacuation gate at the far beach sector."),
    ]

    private static let fallRotEnrichment: [ScenarioMapElement] = [
        line("fallrot-aisne-line", "Aisne River line", .river, [p(2, 39), p(22, 36), p(43, 33), p(64, 30)], width: 4, note: "Aisne crossing line at the start of the drive."),
        line("fallrot-marne-rhine-canal", "Marne-Rhine Canal", .canal, [p(30, 41), p(50, 36), p(71, 31), p(96, 27)], width: 4, note: "Canalized crossing belt on the way to the east."),
        line("fallrot-moselle", "Moselle bend", .river, [p(55, 52), p(69, 47), p(84, 39), p(99, 33)], width: 4, note: "Eastern river bend along the retreat corridor."),
        marker("fallrot-canal-marsh", "Canal marsh pocket", .marsh, .neutral, p(53, 34), radius: 4, note: "Wet canal-side ground around demolition points."),
        line("fallrot-chaumont-road", "Chaumont road", .road, [p(17, 53), p(30, 45), p(42, 37)], width: 2, note: "Road into the Langres and Chaumont delay zone."),
        line("fallrot-vesoul-road", "Vesoul road", .road, [p(49, 34), p(62, 29), p(76, 24), p(91, 18)], width: 2, note: "Eastern exploitation road toward the Swiss-border cut."),
        line("fallrot-epinal-road", "Epinal road", .road, [p(58, 38), p(66, 45), p(74, 52), p(84, 60)], width: 2, note: "Northern fortress road into the Vosges hinge."),
        line("fallrot-belfort-road", "Belfort road", .road, [p(69, 31), p(79, 30), p(91, 28), p(100, 26)], width: 2, note: "Final road toward Belfort and the border."),
        line("fallrot-supply-track", "Panzer supply track", .road, [p(28, 51), p(43, 45), p(58, 37), p(72, 30)], width: 2, note: "Congested supply route behind the exploitation spearhead."),
        line("fallrot-paris-basel-rail", "Paris-Basel rail line", .railway, [p(5, 44), p(29, 40), p(52, 35), p(76, 29), p(99, 24)], width: 2, note: "Rail corridor shadowing the late-France drive."),
        line("fallrot-vosges-rail-spur", "Vosges rail spur", .railway, [p(61, 48), p(72, 45), p(85, 40)], width: 2, note: "Rail spur toward Epinal and the Vosges routes."),
        marker("fallrot-aisne-bridge", "Aisne bridge", .bridge, .neutral, p(34, 34), radius: 3, note: "Early bridge repair and demolition point."),
        marker("fallrot-canal-bridge", "Canal bridge", .bridge, .neutral, p(55, 32), radius: 3, note: "Central crossing on the Marne-Rhine Canal."),
        marker("fallrot-moselle-bridge", "Moselle bridge", .bridge, .player, p(78, 42), radius: 3, note: "Retreat-corridor bridge near the Vosges route."),
        marker("fallrot-canal-ford", "Canal service crossing", .ford, .neutral, p(62, 31), radius: 3, note: "Minor service crossing that infantry can contest."),
        marker("fallrot-chaumont", "Chaumont", .village, .player, p(31, 45), radius: 3, note: "Delay village before Langres."),
        marker("fallrot-vesoul", "Vesoul", .village, .player, p(73, 28), radius: 3, note: "Road hub on the drive toward Belfort."),
        marker("fallrot-luxeuil", "Luxeuil-les-Bains", .village, .player, p(80, 36), radius: 3, note: "Northern village on the Vosges approach."),
        marker("fallrot-langres-district", "Langres fortress district", .urbanDistrict, .player, p(42, 36), radius: 4, note: "Built-up fortress road hub rather than a single town point."),
        marker("fallrot-belfort-district", "Belfort urban fortress", .urbanDistrict, .player, p(79, 30), radius: 4, note: "Urban district around the Belfort defense."),
        marker("fallrot-epinal-district", "Epinal urban district", .urbanDistrict, .player, p(73, 46), radius: 4, note: "Built-up northern fortress hinge."),
        marker("fallrot-vosges-pass", "Vosges pass", .ridge, .player, p(83, 46), radius: 4, note: "Mountain pass governing the retreat corridor."),
        marker("fallrot-plateau-ridge", "Langres plateau ridge", .ridge, .player, p(45, 29), radius: 4, note: "High plateau commanding the road hub."),
        line("fallrot-vosges-forest", "Vosges forest belt", .forest, [p(67, 50), p(80, 48), p(95, 42)], width: 6, note: "Forested retreat belt below the Vosges ridge."),
        marker("fallrot-maginot-work", "Detached fortress work", .bunker, .player, p(69, 34), radius: 3, note: "Fortress work delaying the exploitation road."),
        marker("fallrot-canal-gun-line", "Canal gun line", .artillery, .player, p(57, 35), radius: 4, note: "French guns covering canal demolitions."),
        marker("fallrot-supply-dump", "Supply dump denial", .objective, .player, p(61, 37), radius: 4, note: "Fuel and supply denial objective on the exploitation route."),
        line("fallrot-phase-crossings", "Crossing phase line", .phaseLine, [p(29, 37), p(49, 34), p(69, 30)], width: 2, note: "Phase line for the Aisne and canal crossings."),
        line("fallrot-phase-border", "Border cut phase line", .phaseLine, [p(71, 31), p(84, 25), p(98, 20)], width: 2, note: "Phase line for the Swiss-border cut."),
        marker("fallrot-air-recce", "Air reconnaissance pressure", .airPressure, .guderianAI, p(66, 22), radius: 4, note: "Air reconnaissance pressure over French retreat columns."),
    ]

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
        ] + bialystokMinskEnrichment,
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
        ] + smolenskEnrichment,
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
        ] + roslavlNovozybkovEnrichment,
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
        ] + kievEnrichment,
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
        ] + bryanskEnrichment,
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
        ] + mtsenskEnrichment,
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
        ] + moscowTulaKashiraEnrichment,
        deploymentZones: [
            zone("soviet-city-belt", "Soviet Tula belt", .player, p(58, 12), 35, 24, "Soviet infantry, guns, and reserves defend Tula and Kashira approaches."),
            zone("german-road-column", "German road columns", .guderianAI, p(0, 40), 30, 20, "2nd Panzer Army enters along strained winter roads."),
        ]
    )

    private static let bialystokMinskEnrichment: [ScenarioMapElement] = [
        line("bialystok-berezina", "Berezina river screen", .river, [p(61, 29), p(75, 28), p(90, 25), p(100, 22)], width: 4, note: "Eastern river screen behind the Minsk road."),
        line("bialystok-shchara", "Shchara river line", .river, [p(29, 52), p(42, 46), p(58, 39), p(75, 33)], width: 3, note: "Central water obstacle between the two pincer routes."),
        marker("bialystok-pripyat-marsh-edge", "Pripyat marsh edge", .marsh, .neutral, p(66, 52), radius: 5, note: "Southern wet edge that blocks easy breakout away from the road net."),
        line("bialystok-grodno-road", "Grodno road", .road, [p(15, 20), p(29, 25), p(43, 30)], width: 2, note: "Northern road toward the Hoth pincer."),
        line("bialystok-volkovysk-road", "Volkovysk road", .road, [p(20, 41), p(36, 39), p(52, 36)], width: 2, note: "Central road through the salient."),
        line("bialystok-slonim-road", "Slonim-Baranovichi road", .road, [p(48, 38), p(60, 34), p(73, 30), p(86, 26)], width: 2, note: "Escape road toward Minsk."),
        line("bialystok-german-lateral-road", "German lateral road", .road, [p(17, 51), p(30, 45), p(44, 38), p(58, 32)], width: 2, note: "Road that lets southern German columns tighten the pocket."),
        line("bialystok-baranovichi-road", "Baranovichi bypass road", .road, [p(55, 43), p(69, 38), p(84, 31)], width: 2, note: "Bypass route for Soviet retreat and German pursuit."),
        line("bialystok-minsk-rail-main", "Minsk rail corridor", .railway, [p(4, 42), p(27, 38), p(50, 34), p(75, 28), p(97, 23)], width: 2, note: "Rail corridor shadowing the Bialystok-Minsk road."),
        line("bialystok-grodno-rail-spur", "Grodno rail spur", .railway, [p(15, 21), p(30, 24), p(47, 28)], width: 2, note: "Northern rail spur into the salient."),
        marker("bialystok-bug-bridge", "Bug bridge", .bridge, .neutral, p(31, 47), radius: 3, note: "Southern river crossing under pincer pressure."),
        marker("bialystok-neman-bridge", "Neman bridge", .bridge, .neutral, p(39, 24), radius: 3, note: "Northern crossing that can delay Hoth's pressure."),
        marker("bialystok-shchara-bridge", "Shchara bridge", .bridge, .neutral, p(58, 38), radius: 3, note: "Central bridge on the escape road."),
        marker("bialystok-berezina-ford", "Berezina ford", .ford, .neutral, p(82, 27), radius: 3, note: "Minor eastern crossing for breakout screens."),
        marker("bialystok-city-district", "Bialystok city district", .urbanDistrict, .player, p(30, 39), radius: 4, note: "Urban district anchoring the forward salient."),
        marker("bialystok-grodno", "Grodno", .village, .player, p(27, 23), radius: 3, note: "Northern settlement on the Neman route."),
        marker("bialystok-volkovysk", "Volkovysk", .village, .player, p(41, 39), radius: 3, note: "Road and rail town inside the pocket neck."),
        marker("bialystok-slonim", "Slonim", .village, .player, p(61, 35), radius: 3, note: "Eastern road junction on the breakout path."),
        marker("bialystok-baranovichi", "Baranovichi", .village, .player, p(73, 30), radius: 3, note: "Rail and road node before Minsk."),
        marker("bialystok-minsk-station", "Minsk station district", .urbanDistrict, .player, p(84, 25), radius: 4, note: "Urban rail district around the command objective."),
        line("bialystok-augustow-forest", "Augustow forest belt", .forest, [p(7, 15), p(24, 18), p(41, 22)], width: 6, note: "Northern forest belt masking pincer movement."),
        line("bialystok-naliboki-forest", "Naliboki forest belt", .forest, [p(56, 16), p(72, 19), p(90, 22)], width: 6, note: "Eastern forest belt beside the Minsk route."),
        marker("bialystok-novogrudok-ridge", "Novogrudok ridge", .ridge, .neutral, p(55, 34), radius: 4, note: "High ground in the larger pocket zone."),
        marker("bialystok-pocket-marsh", "Pocket marsh choke", .marsh, .neutral, p(51, 43), radius: 4, note: "Wet choke between the salient and eastern roads."),
        marker("bialystok-border-bunker-line", "Border bunker line", .fortifiedLine, .player, p(22, 34), radius: 4, note: "Forward fortifications bypassed by the armored pincers."),
        marker("bialystok-front-command", "Western Front command post", .objective, .player, p(45, 32), radius: 4, note: "Command-preservation objective inside the pocket."),
        marker("bialystok-eastern-breakout", "Eastern breakout gate", .objective, .player, p(90, 24), radius: 4, note: "Breakout gate for surviving Soviet columns."),
        marker("bialystok-minsk-rail-yard", "Minsk rail-yard control", .objective, .player, p(80, 27), radius: 4, note: "Rail-yard objective for keeping evacuation capacity alive."),
        line("bialystok-phase-salient", "Salient compression phase line", .phaseLine, [p(27, 41), p(45, 37), p(62, 32)], width: 2, note: "Line where the forward salient begins to collapse."),
        line("bialystok-phase-minsk", "Minsk escape phase line", .phaseLine, [p(57, 35), p(73, 30), p(92, 24)], width: 2, note: "Line marking the transition from pocket defense to Minsk escape."),
        marker("bialystok-luftwaffe-road-pressure", "Luftwaffe road pressure", .airPressure, .guderianAI, p(66, 22), radius: 4, note: "Air pressure against road and rail escape traffic."),
        marker("bialystok-south-pincer-fuel", "South pincer fuel point", .objective, .guderianAI, p(37, 50), radius: 4, note: "German protection objective for the southern pincer's fuel column."),
        line("bialystok-command-track", "Command withdrawal track", .road, [p(43, 31), p(58, 32), p(73, 28), p(88, 23)], width: 2, note: "Narrow command track used when the main road is blocked."),
    ]

    private static let smolenskEnrichment: [ScenarioMapElement] = [
        line("smolensk-dnieper-south-branch", "Dnieper south branch", .river, [p(18, 53), p(38, 48), p(59, 43), p(82, 38)], width: 4, note: "Southern Dnieper branch around the pocket."),
        line("smolensk-kasplya", "Kasplya river", .river, [p(37, 18), p(49, 25), p(61, 33)], width: 3, note: "Local river line feeding the northern approaches to Smolensk."),
        line("smolensk-vop", "Vop river screen", .river, [p(70, 27), p(82, 24), p(96, 22)], width: 3, note: "Eastern river screen beyond Yartsevo."),
        marker("smolensk-dnieper-marsh", "Dnieper marsh bend", .marsh, .neutral, p(52, 41), radius: 4, note: "Wet bend around the main Dnieper crossing."),
        line("smolensk-orsha-road", "Orsha-Smolensk road", .road, [p(5, 47), p(23, 43), p(42, 39), p(57, 35)], width: 2, note: "Western approach road along the Dnieper."),
        line("smolensk-vitebsk-road", "Vitebsk-Smolensk road", .road, [p(34, 23), p(45, 28), p(56, 35)], width: 2, note: "Northern road from Vitebsk into Smolensk."),
        line("smolensk-yartsevo-road", "Yartsevo road", .road, [p(57, 35), p(70, 31), p(84, 28), p(99, 25)], width: 2, note: "Eastern escape road toward Yartsevo."),
        line("smolensk-yelnya-road", "Yelnya road", .road, [p(56, 37), p(65, 45), p(75, 53)], width: 2, note: "Southern road toward the Yelnya salient."),
        line("smolensk-reserve-road", "Reserve army road", .road, [p(44, 20), p(56, 25), p(70, 29)], width: 2, note: "Road for reserve armies entering the pocket fight."),
        line("smolensk-bypass-road", "Moscow highway bypass", .road, [p(62, 32), p(77, 29), p(94, 26)], width: 2, note: "Bypass road for German pursuit after the pocket tightens."),
        line("smolensk-moscow-rail", "Smolensk-Moscow rail line", .railway, [p(8, 45), p(31, 41), p(55, 36), p(79, 30), p(99, 27)], width: 2, note: "Main rail escape and supply corridor."),
        line("smolensk-vitebsk-rail", "Vitebsk rail branch", .railway, [p(36, 22), p(47, 27), p(58, 34)], width: 2, note: "Northern rail branch into the city."),
        marker("smolensk-dnieper-east-bridge", "Dnieper east bridge", .bridge, .neutral, p(62, 36), radius: 3, note: "Main bridge east of Smolensk."),
        marker("smolensk-orsha-bridge", "Orsha bridge", .bridge, .neutral, p(31, 41), radius: 3, note: "Western Dnieper crossing on the approach road."),
        marker("smolensk-kasplya-ford", "Kasplya ford", .ford, .neutral, p(50, 26), radius: 3, note: "Minor northern crossing for probes."),
        marker("smolensk-rail-bridge", "Smolensk rail bridge", .bridge, .player, p(55, 36), radius: 3, note: "Rail bridge critical to evacuation capacity."),
        marker("smolensk-vop-ferry", "Vop ferry point", .ferry, .neutral, p(82, 24), radius: 3, note: "Fallback ferry point beyond Yartsevo."),
        marker("smolensk-orsha", "Orsha", .village, .player, p(24, 43), radius: 3, note: "Western road and rail settlement."),
        marker("smolensk-krasny", "Krasny", .village, .player, p(42, 48), radius: 3, note: "Southern Dnieper settlement on the pocket edge."),
        marker("smolensk-rudnya", "Rudnya", .village, .player, p(42, 24), radius: 3, note: "Northern settlement between Vitebsk and Smolensk."),
        marker("smolensk-yartsevo-town", "Yartsevo", .village, .player, p(81, 28), radius: 3, note: "Eastern escape town and rail node."),
        marker("smolensk-dorogobuzh", "Dorogobuzh", .village, .player, p(72, 45), radius: 3, note: "Southern Dnieper town on the withdrawal route."),
        marker("smolensk-station-district", "Smolensk station district", .urbanDistrict, .player, p(57, 35), radius: 4, note: "Rail station district inside the pocket city."),
        line("smolensk-north-forest", "Northern forest belt", .forest, [p(26, 15), p(45, 17), p(65, 20), p(83, 20)], width: 6, note: "Forest belt masking the northern pincer."),
        line("smolensk-yelnya-woods", "Yelnya woods", .forest, [p(57, 48), p(72, 53), p(90, 57)], width: 5, note: "Wooded terrain around the southern counteroffensive."),
        marker("smolensk-dnieper-bluff", "Dnieper bluff", .ridge, .player, p(60, 32), radius: 4, note: "Bluff overlooking river crossings near the city."),
        marker("smolensk-yelnya-ridge", "Yelnya ridge", .ridge, .player, p(68, 47), radius: 4, note: "High ground around the counteroffensive marker."),
        marker("smolensk-pocket-marsh", "Pocket marsh choke", .marsh, .neutral, p(66, 39), radius: 4, note: "Wet choke between Smolensk and Yartsevo."),
        marker("smolensk-city-defensive-line", "City defensive line", .fortifiedLine, .player, p(55, 38), radius: 4, note: "Improvised defensive line around the city approaches."),
        marker("smolensk-command-post", "Soviet command post", .objective, .player, p(52, 33), radius: 4, note: "Command objective for coordinating breakout lanes."),
        marker("smolensk-yartsevo-breakout", "Yartsevo breakout gate", .objective, .player, p(88, 27), radius: 4, note: "Eastern breakout gate for trapped armies."),
        marker("smolensk-yelnya-salient", "Yelnya salient pressure", .objective, .player, p(70, 49), radius: 4, note: "Counteroffensive pressure against the southern pincer."),
        marker("smolensk-german-supply-dump", "German supply dump", .objective, .guderianAI, p(29, 51), radius: 4, note: "German logistics point vulnerable to Soviet raids."),
        marker("smolensk-soviet-artillery-bank", "Soviet artillery bank", .artillery, .player, p(64, 41), radius: 4, note: "Artillery covering Dnieper crossings and pocket exits."),
        line("smolensk-phase-pocket", "Pocket compression phase line", .phaseLine, [p(44, 39), p(59, 36), p(74, 31)], width: 2, note: "Line where pincer pressure closes around Smolensk."),
        line("smolensk-phase-escape", "Yartsevo escape phase line", .phaseLine, [p(63, 34), p(79, 29), p(96, 25)], width: 2, note: "Line where the battle shifts to escape-lane control."),
        marker("smolensk-air-interdiction", "Air interdiction lane", .airPressure, .guderianAI, p(73, 20), radius: 4, note: "Air pressure against road and rail breakout traffic."),
        line("smolensk-reserve-rail-spur", "Reserve rail spur", .railway, [p(40, 23), p(52, 28), p(66, 31)], width: 2, note: "Rail spur used by reserve armies near the northern flank."),
        marker("smolensk-reserve-entry", "Reserve army entry", .objective, .player, p(44, 22), radius: 4, note: "Reserve entry marker for reopening the pocket shoulder."),
    ]

    private static let roslavlNovozybkovEnrichment: [ScenarioMapElement] = [
        line("roslavl-ostyor", "Ostyor river", .river, [p(20, 47), p(36, 43), p(53, 38)], width: 3, note: "Local river line shaping the Roslavl approach."),
        line("roslavl-sudost", "Sudost river screen", .river, [p(55, 53), p(68, 45), p(82, 37), p(98, 31)], width: 3, note: "Eastern water screen near Novozybkov routes."),
        line("roslavl-iput", "Iput river branch", .river, [p(68, 27), p(82, 26), p(99, 25)], width: 3, note: "Northern branch that protects the Bryansk Front flank."),
        marker("roslavl-pripyat-marsh-edge", "Pripyat marsh edge", .marsh, .neutral, p(83, 45), radius: 5, note: "Wet southern edge that narrows the spoiling attack routes."),
        line("roslavl-yelnya-road", "Yelnya-Roslavl road", .road, [p(17, 39), p(31, 38), p(43, 39)], width: 2, note: "Western road into Roslavl."),
        line("roslavl-krichev-road", "Krichev road", .road, [p(43, 39), p(58, 35), p(73, 32)], width: 2, note: "Eastern road toward Krichev and Novozybkov."),
        line("roslavl-unecha-road", "Unecha road", .road, [p(69, 34), p(78, 31), p(90, 28), p(100, 25)], width: 2, note: "Road toward the Bryansk Front rear."),
        line("roslavl-starodub-road", "Starodub road", .road, [p(72, 34), p(81, 42), p(93, 51)], width: 2, note: "Southern road toward Starodub and the marsh edge."),
        line("roslavl-supply-track", "German supply track", .road, [p(34, 28), p(45, 30), p(58, 33)], width: 2, note: "Supply track protecting the southward turn."),
        line("roslavl-rail-main", "Roslavl-Novozybkov rail line", .railway, [p(9, 46), p(32, 41), p(55, 36), p(78, 31), p(98, 27)], width: 2, note: "Rail line tying the spoiling offensive targets together."),
        line("roslavl-gomel-rail-spur", "Gomel rail spur", .railway, [p(74, 31), p(85, 27), p(98, 24)], width: 2, note: "Rail spur toward Gomel and the eastern rear."),
        marker("roslavl-desna-bridge", "Desna bridge", .bridge, .neutral, p(39, 39), radius: 3, note: "Bridge at the western target zone."),
        marker("roslavl-sozh-bridge", "Sozh bridge", .bridge, .neutral, p(74, 34), radius: 3, note: "Bridge on the eastern pressure route."),
        marker("roslavl-sudost-ford", "Sudost ford", .ford, .neutral, p(82, 38), radius: 3, note: "Minor crossing for reconnaissance and withdrawal."),
        marker("roslavl-desna-ferry", "Desna ferry point", .ferry, .neutral, p(51, 37), radius: 3, note: "Improvised ferry for separated detachments."),
        marker("roslavl-rail-bridge", "Rail bridge", .bridge, .neutral, p(56, 36), radius: 3, note: "Rail crossing that can be raided by Soviet tanks."),
        marker("roslavl-yelnya", "Yelnya", .village, .player, p(17, 39), radius: 3, note: "Western staging village for Soviet spoiling groups."),
        marker("roslavl-krichev", "Krichev", .village, .player, p(70, 32), radius: 3, note: "Eastern road and rail settlement."),
        marker("roslavl-unecha", "Unecha", .village, .player, p(88, 29), radius: 3, note: "Rail node behind the Bryansk Front pressure."),
        marker("roslavl-starodub", "Starodub", .village, .player, p(89, 50), radius: 3, note: "Southern settlement on the marsh-edge road."),
        marker("roslavl-station-district", "Roslavl station district", .urbanDistrict, .neutral, p(43, 39), radius: 4, note: "Rail district and German traffic node."),
        marker("novozybkov-rail-district", "Novozybkov rail district", .urbanDistrict, .player, p(79, 30), radius: 4, note: "Eastern rail district anchoring the Soviet pressure."),
        line("roslavl-bryansk-forest", "Bryansk forest belt", .forest, [p(53, 18), p(70, 21), p(88, 25)], width: 6, note: "Forest cover for Soviet attack groups."),
        line("roslavl-south-woods", "Southern wood belt", .forest, [p(57, 52), p(73, 55), p(91, 57)], width: 5, note: "Woods and marsh-edge cover near Starodub."),
        marker("roslavl-desna-bluff", "Desna bluff", .ridge, .neutral, p(48, 35), radius: 4, note: "Observation ground above the western river crossing."),
        marker("roslavl-roadblock-line", "German roadblock line", .fortifiedLine, .guderianAI, p(51, 34), radius: 4, note: "Improvised German line protecting columns and supply."),
        marker("roslavl-artillery-park", "Soviet artillery park", .artillery, .player, p(63, 43), radius: 4, note: "Fire support for the spoiling offensive."),
        marker("roslavl-tank-raid-second", "Second tank raid marker", .objective, .player, p(59, 33), radius: 4, note: "Additional raid target against German road traffic."),
        marker("roslavl-eastern-breakout", "Eastern breakout gate", .objective, .player, p(96, 26), radius: 4, note: "Exit marker for Soviet groups after the spoiling strike."),
        marker("roslavl-german-supply-dump", "German supply dump", .objective, .guderianAI, p(49, 29), radius: 4, note: "Supply target protecting the southward turn."),
        line("roslavl-phase-spoiling", "Spoiling attack phase line", .phaseLine, [p(42, 39), p(58, 35), p(75, 31)], width: 2, note: "Phase line for the Soviet raid reaching the road net."),
        line("roslavl-phase-south-turn", "Southward turn phase line", .phaseLine, [p(52, 39), p(64, 49), p(78, 60)], width: 2, note: "Phase line for German columns turning toward Kiev."),
        marker("roslavl-air-screen", "Air reconnaissance screen", .airPressure, .guderianAI, p(61, 25), radius: 4, note: "Air pressure marker masking the German turn."),
        marker("roslavl-rail-yard-target", "Rail-yard raid target", .objective, .player, p(76, 30), radius: 4, note: "Rail-yard disruption objective at Novozybkov."),
        line("roslavl-withdrawal-track", "Soviet withdrawal track", .road, [p(64, 45), p(78, 40), p(94, 34)], width: 2, note: "Withdrawal track after spoiling objectives are hit."),
        marker("roslavl-marsh-choke", "Marsh road choke", .marsh, .neutral, p(82, 48), radius: 4, note: "Wet choke where roads skirt the Pripyat edge."),
    ]

    private static let kievEnrichment: [ScenarioMapElement] = [
        line("kiev-dnieper-back-channel", "Dnieper back channel", .river, [p(25, 49), p(43, 44), p(62, 38), p(82, 34)], width: 4, note: "Secondary Dnieper channel behind Kiev."),
        line("kiev-trubizh", "Trubizh river", .river, [p(55, 24), p(67, 31), p(80, 37)], width: 3, note: "Eastern river crossing line on the closure route."),
        line("kiev-supii", "Supii river screen", .river, [p(59, 52), p(72, 47), p(88, 43)], width: 3, note: "Southern river screen near the breakout corridor."),
        marker("kiev-dnieper-marsh", "Dnieper marsh islands", .marsh, .neutral, p(44, 40), radius: 5, note: "Marshy islands that complicate crossings and evacuation."),
        line("kiev-chernigov-road", "Chernihiv-Kiev road", .road, [p(10, 25), p(26, 29), p(43, 32)], width: 2, note: "Northern road into the pocket."),
        line("kiev-nizhyn-road", "Nizhyn road", .road, [p(45, 32), p(58, 34), p(72, 35)], width: 2, note: "Road toward Nizhyn and the eastern exits."),
        line("kiev-priluki-road", "Priluki road", .road, [p(51, 40), p(63, 43), p(77, 46)], width: 2, note: "South-eastern road for breakout columns."),
        line("kiev-piryatin-road", "Piryatin-Lokhvytsia road", .road, [p(66, 39), p(77, 36), p(91, 34)], width: 2, note: "Road toward the pincer closure point."),
        line("kiev-kleist-road", "Southern pincer road", .road, [p(61, 54), p(68, 47), p(77, 39)], width: 2, note: "Southern German pincer route toward closure."),
        line("kiev-kursk-rail", "Kiev-Kursk rail line", .railway, [p(31, 44), p(49, 40), p(68, 36), p(90, 33)], width: 2, note: "Rail evacuation line through the pocket."),
        line("kiev-poltava-rail", "Kiev-Poltava rail branch", .railway, [p(43, 45), p(58, 47), p(75, 49)], width: 2, note: "Southern rail branch into the pocket."),
        marker("kiev-dnieper-bridge", "Dnieper bridge", .bridge, .player, p(38, 39), radius: 3, note: "Main bridge linking Kiev and east-bank exits."),
        marker("kiev-desna-bridge", "Desna bridge", .bridge, .neutral, p(47, 32), radius: 3, note: "Northern crossing under pincer pressure."),
        marker("kiev-rail-bridge", "Kiev rail bridge", .bridge, .player, p(45, 42), radius: 3, note: "Rail bridge for command evacuation."),
        marker("kiev-dnieper-ferry", "Dnieper ferry reach", .ferry, .player, p(52, 37), radius: 3, note: "Fallback ferry reach when bridges are interdicted."),
        marker("kiev-trubizh-ford", "Trubizh ford", .ford, .neutral, p(69, 33), radius: 3, note: "Minor crossing near the closure corridor."),
        marker("kiev-chernigov", "Chernihiv", .village, .player, p(22, 28), radius: 3, note: "Northern road settlement on the Desna route."),
        marker("kiev-nizhyn", "Nizhyn", .village, .player, p(62, 35), radius: 3, note: "Eastern rail and road town inside the pocket."),
        marker("kiev-priluki", "Priluki", .village, .player, p(70, 45), radius: 3, note: "South-eastern breakout settlement."),
        marker("kiev-piryatin", "Piryatin", .village, .player, p(81, 40), radius: 3, note: "Road town near the closure corridor."),
        marker("kiev-lokhvytsia-town", "Lokhvytsia", .village, .neutral, p(88, 35), radius: 3, note: "Named pincer-closure settlement."),
        marker("kiev-station-district", "Kiev station district", .urbanDistrict, .player, p(41, 42), radius: 4, note: "Rail and command district inside Kiev."),
        marker("kiev-dnieper-bluff", "Dnieper bluff", .ridge, .player, p(36, 36), radius: 4, note: "High east-bank ground above the bridges."),
        line("kiev-north-forest", "Northern forest belt", .forest, [p(18, 20), p(38, 23), p(58, 24)], width: 6, note: "Forest belt on Guderian's southern turn route."),
        line("kiev-pereyaslav-woods", "Pereyaslav wood belt", .forest, [p(63, 50), p(79, 52), p(96, 53)], width: 5, note: "Wooded cover on the southern breakout road."),
        marker("kiev-east-bank-line", "East-bank defense line", .fortifiedLine, .player, p(49, 39), radius: 5, note: "Improvised defense covering bridges and command exits."),
        marker("kiev-dnieper-bunkers", "Dnieper bunker pockets", .bunker, .player, p(34, 42), radius: 3, note: "Strongpoints covering the city river edge."),
        marker("kiev-artillery-bank", "Dnieper artillery bank", .artillery, .player, p(47, 44), radius: 4, note: "Soviet artillery covering evacuation routes."),
        marker("kiev-command-escape", "Command escape gate", .objective, .player, p(65, 36), radius: 4, note: "Command-preservation objective on the eastern corridor."),
        marker("kiev-pocket-east-exit", "Pocket east exit", .objective, .player, p(94, 36), radius: 4, note: "Breakout gate beyond Lokhvytsia."),
        marker("kiev-rail-evacuation", "Rail evacuation yard", .objective, .player, p(51, 43), radius: 4, note: "Rail evacuation objective before the pocket closes."),
        marker("kiev-panzer-closure", "Panzer closure point", .objective, .guderianAI, p(82, 36), radius: 4, note: "German pincer objective east of Kiev."),
        line("kiev-phase-northern-pincer", "Northern pincer phase line", .phaseLine, [p(39, 31), p(55, 33), p(72, 35)], width: 2, note: "Phase line for Guderian's southward pressure."),
        line("kiev-phase-pocket-closure", "Pocket closure phase line", .phaseLine, [p(61, 39), p(76, 37), p(92, 35)], width: 2, note: "Line where the pocket closure becomes decisive."),
        marker("kiev-air-interdiction", "Air interdiction lane", .airPressure, .guderianAI, p(58, 24), radius: 4, note: "Air pressure against bridges and command exits."),
        line("kiev-breakout-track", "Breakout farm track", .road, [p(52, 42), p(67, 40), p(83, 38), p(98, 37)], width: 2, note: "Farm track used by units avoiding main-road interdiction."),
    ]

    private static let bryanskEnrichment: [ScenarioMapElement] = [
        line("bryansk-bolva", "Bolva river", .river, [p(25, 47), p(43, 42), p(62, 36)], width: 3, note: "Local river line south-west of Bryansk."),
        line("bryansk-navlya", "Navlya river", .river, [p(34, 58), p(48, 50), p(63, 42), p(80, 35)], width: 3, note: "Southern river line and pocket edge."),
        line("bryansk-sudost", "Sudost upper stream", .river, [p(61, 25), p(75, 28), p(94, 31)], width: 3, note: "Eastern stream beyond Orel routes."),
        marker("bryansk-autumn-marsh", "Autumn marsh flats", .marsh, .neutral, p(55, 38), radius: 5, note: "Wet flats that make the Typhoon roads fragile."),
        line("bryansk-karachev-road", "Karachev road", .road, [p(31, 40), p(45, 37), p(60, 34)], width: 2, note: "Road between Bryansk and the Orel axis."),
        line("bryansk-sevsk-road", "Sevsk road", .road, [p(25, 50), p(39, 45), p(54, 40)], width: 2, note: "Southern approach road into the pocket."),
        line("bryansk-belev-road", "Belev road", .road, [p(70, 29), p(80, 23), p(93, 17)], width: 2, note: "Northern road protecting the Tula screen."),
        line("bryansk-withdrawal-track", "Forest withdrawal track", .road, [p(45, 35), p(58, 30), p(73, 25)], width: 2, note: "Track used by Soviet pockets to move through forest cover."),
        line("bryansk-mud-road", "Rasputitsa mud road", .road, [p(56, 45), p(69, 40), p(84, 34)], width: 2, note: "Mud road where German supply strain builds."),
        line("bryansk-rail-orel", "Bryansk-Orel rail line", .railway, [p(8, 42), p(30, 39), p(53, 35), p(76, 30), p(98, 25)], width: 2, note: "Rail route toward Orel and Tula."),
        line("bryansk-rail-tula", "Orel-Tula rail branch", .railway, [p(73, 30), p(82, 22), p(93, 14)], width: 2, note: "Rail branch behind the Tula approach."),
        marker("bryansk-desna-bridge", "Desna bridge", .bridge, .neutral, p(43, 34), radius: 3, note: "Main bridge in the Bryansk pocket zone."),
        marker("bryansk-bolva-bridge", "Bolva bridge", .bridge, .neutral, p(47, 41), radius: 3, note: "Bridge on the south-western road."),
        marker("bryansk-rail-bridge", "Bryansk rail bridge", .bridge, .player, p(46, 39), radius: 3, note: "Rail crossing tied to the evacuation node."),
        marker("bryansk-navlya-ford", "Navlya ford", .ford, .neutral, p(59, 45), radius: 3, note: "Minor crossing for pocket movement."),
        marker("bryansk-desna-ferry", "Desna ferry reach", .ferry, .neutral, p(52, 33), radius: 3, note: "Fallback crossing when bridges are lost."),
        marker("bryansk-karachev", "Karachev", .village, .player, p(58, 34), radius: 3, note: "Road town between Bryansk and Orel."),
        marker("bryansk-sevsk", "Sevsk", .village, .player, p(34, 47), radius: 3, note: "Southern road settlement on the pocket flank."),
        marker("bryansk-navlya-town", "Navlya", .village, .player, p(62, 43), radius: 3, note: "Forest and river settlement on the withdrawal route."),
        marker("bryansk-belev", "Belev", .village, .player, p(85, 20), radius: 3, note: "Northern settlement on the Tula screen."),
        marker("bryansk-station-district", "Bryansk station district", .urbanDistrict, .player, p(45, 40), radius: 4, note: "Rail district supporting command and evacuation."),
        marker("orel-station-district", "Orel station district", .urbanDistrict, .neutral, p(75, 30), radius: 4, note: "Orel rail and road district at the Typhoon gateway."),
        line("bryansk-forest-south", "Southern Bryansk forest", .forest, [p(24, 55), p(44, 54), p(65, 52), p(83, 48)], width: 6, note: "Forest cover for southern pocket breakouts."),
        line("bryansk-forest-north", "Northern Bryansk forest", .forest, [p(18, 19), p(39, 22), p(60, 20), p(82, 25)], width: 7, note: "Northern forest belt around the road approach."),
        marker("bryansk-forest-ridge", "Forest ridge", .ridge, .player, p(62, 27), radius: 4, note: "Observation ridge above the Tula approach road."),
        marker("bryansk-marsh-woods", "Marsh wood choke", .marsh, .neutral, p(53, 35), radius: 4, note: "Wet wooded choke near the encircled armies."),
        marker("bryansk-tula-screen-line", "Tula screen line", .fortifiedLine, .player, p(77, 23), radius: 4, note: "Prepared blocking line on the road north."),
        marker("bryansk-forest-bunkers", "Forest bunker pockets", .bunker, .player, p(49, 31), radius: 3, note: "Local strongpoints used by pocket groups."),
        marker("bryansk-artillery-yard", "Bryansk artillery yard", .artillery, .player, p(48, 42), radius: 4, note: "Artillery and rail support point inside Bryansk."),
        marker("bryansk-pocket-exit", "Forest pocket exit", .objective, .player, p(72, 26), radius: 4, note: "Breakout gate through the forest belt."),
        marker("bryansk-tula-screen-objective", "Tula screen objective", .objective, .player, p(88, 17), radius: 4, note: "Objective for preserving the road north to Tula."),
        marker("bryansk-rail-evacuation", "Rail evacuation control", .objective, .player, p(52, 39), radius: 4, note: "Rail objective for moving command and guns out of Bryansk."),
        marker("bryansk-german-supply-train", "German supply train", .objective, .guderianAI, p(31, 43), radius: 4, note: "German supply objective exposed by the rapid advance."),
        line("bryansk-phase-encirclement", "Encirclement phase line", .phaseLine, [p(35, 39), p(52, 36), p(70, 31)], width: 2, note: "Line where Bryansk pockets begin to close."),
        line("bryansk-phase-tula", "Tula approach phase line", .phaseLine, [p(69, 30), p(81, 23), p(95, 16)], width: 2, note: "Line marking the turn from pocket fight to Tula approach."),
        marker("bryansk-mud-pressure", "Mud pressure lane", .airPressure, .guderianAI, p(64, 47), radius: 4, note: "Road friction pressure marker for the German advance."),
        marker("bryansk-forest-roadblock", "Forest roadblock", .fortifiedLine, .player, p(61, 31), radius: 4, note: "Blocking position in the forest belt."),
        marker("bryansk-counterattack-node", "Counterattack node", .objective, .player, p(57, 36), radius: 4, note: "Local counterattack point for reopening pocket movement."),
        line("bryansk-orel-bypass-road", "Orel bypass road", .road, [p(62, 36), p(74, 32), p(90, 26)], width: 2, note: "Bypass lane used if Orel's main road is blocked."),
    ]

    private static let mtsenskEnrichment: [ScenarioMapElement] = [
        line("mtsensk-oka", "Oka river bend", .river, [p(56, 30), p(71, 27), p(89, 23), p(100, 21)], width: 4, note: "Oka bend behind Mtsensk and the Tula road."),
        line("mtsensk-zusha-south-branch", "Zusha south branch", .river, [p(25, 42), p(43, 39), p(62, 34), p(83, 31)], width: 3, note: "Southern branch of the Zusha crossing zone."),
        line("mtsensk-ravine-stream", "Ravine stream", .river, [p(35, 25), p(46, 30), p(58, 37)], width: 2, note: "Small ravine stream through the ambush belt."),
        marker("mtsensk-zusha-marsh", "Zusha marsh pocket", .marsh, .neutral, p(55, 35), radius: 4, note: "Wet ground around the main river crossing."),
        line("mtsensk-chern-road", "Chern road", .road, [p(60, 35), p(72, 43), p(86, 52)], width: 2, note: "Southern road that can bypass the ambush center."),
        line("mtsensk-tula-road-east", "Tula east road", .road, [p(66, 30), p(78, 25), p(92, 20)], width: 2, note: "Eastern continuation of the Tula road."),
        line("mtsensk-withdrawal-track", "Soviet withdrawal track", .road, [p(48, 29), p(63, 26), p(79, 23)], width: 2, note: "Track for resetting ambush groups toward Tula."),
        line("mtsensk-bypass-track", "German bypass track", .road, [p(29, 46), p(43, 45), p(58, 40), p(74, 34)], width: 2, note: "Bypass track used by cautious German armor."),
        line("mtsensk-ambush-trail", "Forest ambush trail", .road, [p(37, 24), p(48, 28), p(59, 32)], width: 2, note: "Hidden trail linking tank ambush positions."),
        line("mtsensk-rail-main", "Orel-Tula rail line", .railway, [p(5, 45), p(28, 41), p(51, 36), p(75, 29), p(98, 22)], width: 2, note: "Rail line shadowing the road to Tula."),
        line("mtsensk-station-spur", "Mtsensk station spur", .railway, [p(55, 36), p(65, 33), p(76, 29)], width: 2, note: "Station spur inside the ambush center."),
        marker("mtsensk-zusha-road-bridge", "Zusha road bridge", .bridge, .neutral, p(58, 34), radius: 3, note: "Road bridge at the main ambush crossing."),
        marker("mtsensk-zusha-rail-bridge", "Zusha rail bridge", .bridge, .neutral, p(62, 33), radius: 3, note: "Rail crossing beside Mtsensk station."),
        marker("mtsensk-ravine-ford", "Ravine ford", .ford, .neutral, p(48, 31), radius: 3, note: "Minor ford inside the ambush ravine."),
        marker("mtsensk-oka-ferry", "Oka ferry reach", .ferry, .neutral, p(81, 25), radius: 3, note: "Fallback crossing toward the Tula road."),
        marker("mtsensk-rail-crossing", "Rail crossing", .bridge, .player, p(68, 31), radius: 3, note: "Rail-road crossing defended by anti-tank guns."),
        marker("mtsensk-first-warrior", "First Warrior village", .village, .player, p(43, 30), radius: 3, note: "Village associated with Katukov's ambush line."),
        marker("mtsensk-chern", "Chern", .village, .player, p(83, 51), radius: 3, note: "Southern road village beyond the ambush zone."),
        marker("mtsensk-naryshkino", "Naryshkino", .village, .guderianAI, p(22, 44), radius: 3, note: "Western approach settlement near Orel."),
        marker("mtsensk-plavsk", "Plavsk road village", .village, .player, p(88, 22), radius: 3, note: "Tula-road settlement beyond Mtsensk."),
        marker("mtsensk-station-district", "Mtsensk station district", .urbanDistrict, .player, p(64, 33), radius: 4, note: "Rail district that creates close terrain inside the road hub."),
        marker("mtsensk-orel-outskirts", "Orel outskirts", .urbanDistrict, .guderianAI, p(18, 45), radius: 4, note: "German road entry district from Orel."),
        line("mtsensk-north-woods", "Northern ambush woods", .forest, [p(20, 23), p(39, 24), p(58, 22), p(78, 24)], width: 6, note: "Primary concealment belt for T-34 and KV groups."),
        line("mtsensk-south-woods", "Southern wood belt", .forest, [p(35, 49), p(54, 50), p(75, 48)], width: 5, note: "Southern cover for infantry and anti-tank guns."),
        marker("mtsensk-zusha-ridge", "Zusha ridge", .ridge, .player, p(54, 28), radius: 4, note: "High ground overlooking the bridge and road."),
        marker("mtsensk-ravine-belt", "Ravine ambush belt", .ridge, .player, p(47, 34), radius: 4, note: "Broken ground where Soviet armor can reset ambushes."),
        marker("mtsensk-gun-line", "Anti-tank gun line", .fortifiedLine, .player, p(59, 38), radius: 4, note: "Gun line covering the river and road."),
        marker("mtsensk-bunker-pocket", "Rifle bunker pocket", .bunker, .player, p(70, 29), radius: 3, note: "Infantry strongpoint protecting the Tula exit."),
        marker("mtsensk-artillery-hill", "Artillery hill", .artillery, .player, p(52, 40), radius: 4, note: "Artillery support point for ambush fire."),
        marker("mtsensk-second-ambush", "Second ambush gate", .objective, .player, p(55, 29), radius: 4, note: "Second T-34/KV reveal point after German caution rises."),
        marker("mtsensk-tula-withdrawal", "Tula withdrawal gate", .objective, .player, p(95, 21), radius: 4, note: "Exit objective for preserving the screen toward Tula."),
        marker("mtsensk-german-bypass-objective", "German bypass objective", .objective, .guderianAI, p(72, 34), radius: 4, note: "German objective for forcing movement around the ambush."),
        marker("mtsensk-supply-column", "Panzer supply column", .objective, .guderianAI, p(36, 43), radius: 4, note: "Supply column vulnerable to ambush and roadblocks."),
        line("mtsensk-phase-ambush", "Ambush phase line", .phaseLine, [p(36, 42), p(50, 36), p(65, 30)], width: 2, note: "Line where Soviet armor springs the main ambush."),
        line("mtsensk-phase-tula", "Tula withdrawal phase line", .phaseLine, [p(65, 30), p(80, 25), p(97, 21)], width: 2, note: "Line where the fight shifts to delay and withdrawal."),
        marker("mtsensk-luftwaffe-caution", "Air caution lane", .airPressure, .guderianAI, p(45, 18), radius: 4, note: "Air and reconnaissance pressure after the German spearhead slows."),
        marker("mtsensk-roadblock", "Forest roadblock", .fortifiedLine, .player, p(50, 32), radius: 3, note: "Roadblock that forces armor into covered fire lanes."),
        marker("mtsensk-repair-point", "German repair point", .objective, .guderianAI, p(28, 44), radius: 4, note: "German repair and recovery objective after tank losses."),
        line("mtsensk-ravine-track", "Ravine lateral track", .road, [p(42, 33), p(55, 35), p(70, 32)], width: 2, note: "Lateral track connecting ambush and withdrawal positions."),
    ]

    private static let moscowTulaKashiraEnrichment: [ScenarioMapElement] = [
        line("tula-oka-river", "Oka river line", .river, [p(66, 18), p(79, 16), p(94, 13)], width: 4, note: "Oka crossing line behind the Kashira approach."),
        line("tula-don-headwaters", "Don headwaters", .river, [p(25, 58), p(39, 51), p(55, 43)], width: 3, note: "Southern water line near the winter road approach."),
        line("tula-shat-stream", "Shat stream", .river, [p(52, 45), p(66, 38), p(82, 31)], width: 3, note: "Stream crossing on the Venev-Kashira bypass."),
        marker("tula-frozen-marsh", "Frozen marsh flats", .marsh, .neutral, p(54, 41), radius: 5, note: "Frozen low ground that still channels heavy movement."),
        marker("tula-shat-reservoir", "Shat reservoir", .lake, .neutral, p(68, 36), radius: 4, note: "Reservoir beside the bypass road."),
        line("tula-moscow-road", "Tula-Moscow road", .road, [p(67, 23), p(75, 17), p(86, 10)], width: 2, note: "Northern continuation of the main road toward Moscow."),
        line("tula-kashira-road", "Kashira road", .road, [p(72, 37), p(83, 27), p(96, 16)], width: 2, note: "Road from reserve areas toward Kashira."),
        line("tula-stalinogorsk-road", "Stalinogorsk road", .road, [p(44, 49), p(57, 42), p(72, 37)], width: 2, note: "Eastern road through industrial and winter terrain."),
        line("tula-mordves-road", "Mordves road", .road, [p(44, 54), p(56, 49), p(70, 43)], width: 2, note: "Counteroffensive route after German exhaustion."),
        line("tula-serpukhov-road", "Serpukhov road", .road, [p(70, 22), p(79, 16), p(91, 8)], width: 2, note: "Northern road tying Tula to the Moscow defense belt."),
        line("tula-snow-track-west", "Western snow track", .road, [p(17, 58), p(30, 52), p(44, 45)], width: 2, note: "Snow-covered side track with high movement friction."),
        line("tula-frozen-lane", "Frozen field lane", .road, [p(51, 46), p(64, 40), p(78, 34)], width: 2, note: "Frozen lane used by mobile reserves and cautious armor."),
        line("tula-rail-main", "Orel-Tula-Moscow rail line", .railway, [p(7, 55), p(31, 43), p(57, 31), p(84, 13)], width: 2, note: "Rail corridor along the main road."),
        line("tula-kashira-rail", "Kashira rail branch", .railway, [p(67, 24), p(79, 18), p(94, 14)], width: 2, note: "Rail branch toward Kashira and Moscow."),
        marker("tula-upa-bridge", "Upa bridge", .bridge, .player, p(62, 25), radius: 3, note: "Bridge on the Tula defensive belt."),
        marker("tula-oka-bridge", "Oka bridge", .bridge, .player, p(84, 15), radius: 3, note: "Kashira crossing point guarding the Moscow approach."),
        marker("tula-rail-bridge", "Tula rail bridge", .bridge, .player, p(66, 24), radius: 3, note: "Rail bridge inside the defensive belt."),
        marker("tula-shat-ford", "Shat frozen ford", .ford, .neutral, p(69, 37), radius: 3, note: "Frozen ford on the bypass axis."),
        marker("tula-winter-ferry", "Oka winter ferry", .ferry, .neutral, p(91, 14), radius: 3, note: "Emergency ferry and ice crossing near Kashira."),
        marker("tula-city-district", "Tula arsenal district", .urbanDistrict, .player, p(69, 23), radius: 5, note: "Arsenal and urban defense district inside Tula."),
        marker("tula-kashira-town", "Kashira", .village, .player, p(88, 14), radius: 3, note: "Named town guarding the Moscow road."),
        marker("tula-mordves", "Mordves", .village, .player, p(56, 49), radius: 3, note: "Village on the drive-back line."),
        marker("tula-stalinogorsk", "Stalinogorsk", .village, .player, p(62, 42), radius: 3, note: "Industrial road hub on the eastern approach."),
        marker("tula-serpukhov", "Serpukhov", .village, .player, p(90, 8), radius: 3, note: "Northern settlement on the Moscow defense road."),
        marker("tula-laptevo", "Laptevo", .village, .player, p(52, 33), radius: 3, note: "Road settlement on the Tula approaches."),
        marker("tula-venev-district", "Venev road district", .urbanDistrict, .neutral, p(78, 27), radius: 4, note: "Built-up bypass district before Kashira."),
        line("tula-yasnaya-woods", "Yasnaya Polyana woods", .forest, [p(44, 25), p(60, 20), p(78, 18)], width: 5, note: "Wooded cover south-west of Tula."),
        line("tula-kashira-woods", "Kashira winter woods", .forest, [p(73, 30), p(86, 25), p(99, 20)], width: 5, note: "Wood belt along the northern bypass."),
        marker("tula-snow-ridge", "Snow ridge choke", .ridge, .neutral, p(49, 38), radius: 4, note: "Snowy high ground creating a road choke."),
        marker("tula-arsenal-bunkers", "Arsenal bunkers", .bunker, .player, p(70, 22), radius: 3, note: "Strongpoints protecting Tula's urban core."),
        marker("tula-outer-at-line", "Outer anti-tank line", .fortifiedLine, .player, p(62, 28), radius: 5, note: "Outer prepared line on the main road."),
        marker("tula-kashira-defense-line", "Kashira defense line", .fortifiedLine, .player, p(86, 16), radius: 4, note: "Reserve line that guards the Moscow approach."),
        marker("tula-artillery-park", "Tula artillery park", .artillery, .player, p(65, 27), radius: 4, note: "Artillery supporting city and road defenses."),
        marker("tula-winter-fuel-dump", "Winter fuel dump", .objective, .guderianAI, p(36, 49), radius: 4, note: "German fuel point strained by cold and road distance."),
        marker("tula-reserve-railhead", "Reserve railhead", .objective, .player, p(77, 39), radius: 4, note: "Soviet reserve railhead feeding counterstrokes."),
        marker("tula-kashira-defense-objective", "Kashira defense objective", .objective, .player, p(91, 15), radius: 4, note: "Objective for holding the southern approach to Moscow."),
        marker("tula-counteroffensive-start", "Counteroffensive start line", .objective, .player, p(73, 42), radius: 4, note: "Start line for Belov and Getman mobile attacks."),
        marker("tula-panzer-roadblock", "Panzer roadblock", .objective, .guderianAI, p(52, 36), radius: 4, note: "German objective for forcing the road choke before exhaustion."),
        marker("tula-moscow-gate", "Moscow gate", .objective, .player, p(96, 12), radius: 4, note: "Final gate on the southern Moscow approach."),
        line("tula-phase-city-belt", "Tula city-belt phase line", .phaseLine, [p(54, 31), p(67, 24), p(83, 17)], width: 2, note: "Phase line for holding the prepared city belt."),
        line("tula-phase-kashira", "Kashira bypass phase line", .phaseLine, [p(69, 37), p(82, 25), p(97, 14)], width: 2, note: "Phase line for the German bypass toward Kashira."),
        line("tula-phase-counteroffensive", "Counteroffensive phase line", .phaseLine, [p(58, 49), p(73, 42), p(88, 35)], width: 2, note: "Phase line for the Soviet winter drive-back."),
        marker("tula-blizzard-pressure", "Blizzard pressure lane", .airPressure, .guderianAI, p(31, 50), radius: 4, note: "Weather and supply pressure against German road columns."),
        marker("tula-frostbite-pressure", "Frostbite pressure marker", .airPressure, .guderianAI, p(47, 55), radius: 4, note: "Cold-weather attrition marker tied to overextended armor."),
        line("tula-ski-track", "Soviet ski track", .road, [p(68, 44), p(78, 38), p(90, 31)], width: 2, note: "Winter lane for mobile Soviet reserve movement."),
        marker("tula-venev-bridge", "Venev bridge", .bridge, .neutral, p(77, 28), radius: 3, note: "Bridge crossing on the bypass gate."),
        marker("tula-snow-drift-belt", "Snow drift belt", .ridge, .neutral, p(60, 45), radius: 4, note: "Drifted high ground that slows road-edge movement."),
        marker("tula-kashira-station", "Kashira station district", .urbanDistrict, .player, p(87, 15), radius: 4, note: "Rail and road district behind the Oka crossing."),
    ]

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
                zone("\(scenario.id.rawValue)-player", "Opposing force deployment", .player, p(58, 11), 34, 28, "Opposing force deployment area."),
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
