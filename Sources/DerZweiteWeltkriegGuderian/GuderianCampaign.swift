import Foundation

public enum GuderianBattleID: String, CaseIterable, Codable, Hashable, Sendable {
    case tucholaForest
    case wizna
    case brzescLitewski
    case kobryn
    case sedan
    case stonne
    case montcornet
    case amiensAbbeville
    case boulogne
    case calais
    case dunkirk
    case fallRot
    case bialystokMinsk
    case smolensk
    case roslavlNovozybkov
    case kiev
    case bryansk
    case mtsensk
    case moscowTulaKashira
}

public enum CampaignTheater: String, Codable, Hashable, Sendable {
    case poland1939 = "Poland 1939"
    case france1940 = "France 1940"
    case easternFront1941 = "Eastern Front 1941"
}

public enum ScenarioStatus: String, Codable, Hashable, Sendable {
    case dataLocked = "Data locked"
    case dzwProxyLoadable = "dzw proxy loadable"
    case planned = "Planned"
}

public enum PlayerPosture: String, Codable, Hashable, Sendable {
    case fortifiedDelay = "Fortified delay"
    case mobileDelay = "Mobile delay"
    case urbanDefense = "Urban defense"
    case counterattack = "Counterattack"
    case breakout = "Breakout"
    case evacuationDefense = "Evacuation defense"
}

public struct ScenarioDateKey: Codable, Comparable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: ScenarioDateKey, rhs: ScenarioDateKey) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}

public struct ScenarioSource: Codable, Hashable, Sendable {
    public let title: String
    public let url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}

public struct ScenarioMapFeature: Codable, Hashable, Sendable {
    public let name: String
    public let role: String

    public init(name: String, role: String) {
        self.name = name
        self.role = role
    }
}

public struct ScenarioObjective: Codable, Hashable, Sendable {
    public let name: String
    public let victoryPoints: Int
    public let description: String

    public init(name: String, victoryPoints: Int, description: String) {
        self.name = name
        self.victoryPoints = victoryPoints
        self.description = description
    }
}

public struct ScenarioForceSlot: Codable, Hashable, Sendable {
    public let side: String
    public let historicalForce: String
    public let role: String

    public init(side: String, historicalForce: String, role: String) {
        self.side = side
        self.historicalForce = historicalForce
        self.role = role
    }
}

public struct GuderianScenario: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let order: Int
    public let title: String
    public let dateLabel: String
    public let startDate: ScenarioDateKey
    public let theater: CampaignTheater
    public let status: ScenarioStatus
    public let playerPosture: PlayerPosture
    public let guderianCommand: String
    public let playerForceSummary: String
    public let historicalResult: String
    public let designIntent: String
    public let sourceLinks: [ScenarioSource]
    public let mapFeatures: [ScenarioMapFeature]
    public let objectives: [ScenarioObjective]
    public let forces: [ScenarioForceSlot]
    public let tags: [String]

    public var sourceSummary: String {
        sourceLinks.map(\.title).joined(separator: ", ")
    }

    public var isDemoScenario: Bool {
        id == .wizna || id == .sedan || id == .moscowTulaKashira
    }
}

public enum GuderianCampaignCatalog {
    public static let all: [GuderianScenario] = [
        makeScenario(
            .tucholaForest,
            order: 1,
            title: "Battle of Tuchola Forest",
            dateLabel: "1-5 Sep 1939",
            start: .init(year: 1939, month: 9, day: 1),
            theater: .poland1939,
            status: .dzwProxyLoadable,
            posture: .mobileDelay,
            command: "XIX Panzer Corps under 4th Army",
            playerForce: "Polish Pomeranian Army elements in the Polish Corridor",
            result: "German victory",
            intent: "Delay the armored corridor breakout across the Brda crossings, disrupt the Chojnice-Tuchola road net, and withdraw coherent Polish forces before the pincer closes.",
            sources: [
                source("Battle of Tuchola Forest", "https://en.wikipedia.org/wiki/Battle_of_Tuchola_Forest"),
                source("Pomeranian Army", "https://en.wikipedia.org/wiki/Pomeranian_Army"),
                source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps"),
            ],
            features: [
                feature("Brda River crossings", "bridge demolition and early roadblock objectives"),
                feature("Tuchola forest roads", "restricted armored movement and anti-tank ambush lanes"),
                feature("Chojnice rail and road hub", "motorized pressure point and withdrawal hinge"),
                feature("Krojanty cavalry screen", "mounted delay action covering withdrawal"),
                feature("Bydgoszcz route", "operational escape lane before encirclement"),
            ],
            objectives: [
                objective("Block Brda crossings", 4, "Destroy, contest, or delay bridge sites at Pruszcz and Pila-Mlyn."),
                objective("Hold Chojnice-Tuchola road net", 3, "Keep at least one forest road hub contested through the midgame."),
                objective("Withdraw Pomeranian Army elements", 5, "Exit infantry, cavalry screen, command, and anti-tank assets toward Bydgoszcz."),
                objective("Disrupt German reconnaissance", 2, "Use cavalry and forest screens to cancel or slow German pursuit orders."),
            ],
            forces: [force("Player", "Polish corridor defenders", "delay and withdraw"), force("Guderian AI", "XIX Panzer Corps spearheads", "break through")]
        ),
        makeScenario(
            .wizna,
            order: 2,
            title: "Battle of Wizna",
            dateLabel: "7-10 Sep 1939",
            start: .init(year: 1939, month: 9, day: 7),
            theater: .poland1939,
            status: .dzwProxyLoadable,
            posture: .fortifiedDelay,
            command: "XIX Panzer Corps; Guderian listed with Ferdinand Schaal",
            playerForce: "Polish fortified line under Wladyslaw Raginis and Stanislaw Brykalski",
            result: "German victory",
            intent: "Use bunkers, anti-tank guns, and machine-gun nests to hold against overwhelming armor and artillery.",
            sources: [source("Battle of Wizna", "https://en.wikipedia.org/wiki/Battle_of_Wizna")],
            features: [feature("Bunker line", "fortified strongpoints"), feature("Narew approaches", "armored assault lane")],
            objectives: [objective("Hold the bunkers", 4, "Earn points for each fortification still resisting at turn end."), objective("Preserve the anti-tank guns", 2, "Keep scarce anti-armor weapons firing as long as possible.")],
            forces: [force("Player", "Polish Wizna defenders", "fortified delay"), force("Guderian AI", "German panzer and artillery assault group", "reduce bunkers")]
        ),
        makeScenario(
            .brzescLitewski,
            order: 3,
            title: "Battle of Brzesc Litewski",
            dateLabel: "14-17 Sep 1939",
            start: .init(year: 1939, month: 9, day: 14),
            theater: .poland1939,
            status: .dzwProxyLoadable,
            posture: .urbanDefense,
            command: "XIX Panzer Corps with 10th Panzer, 3rd Panzer, and 20th Infantry Division",
            playerForce: "Polish Brzesc defense group under Konstanty Plisowski",
            result: "German victory",
            intent: "Stage a fortress and urban delay with armored trains, old tanks, artillery, and fallback routes.",
            sources: [source("Battle of Brzesc Litewski", "https://en.wikipedia.org/wiki/Battle_of_Brze%C5%9B%C4%87_Litewski")],
            features: [feature("Citadel approaches", "urban strongpoint"), feature("Rail line", "armored train route")],
            objectives: [objective("Delay the citadel assault", 4, "Hold inner positions through multiple German assaults."), objective("Evacuate mobile reserves", 2, "Withdraw surviving armor and train assets.")],
            forces: [force("Player", "Brzesc defense group", "fortress defense"), force("Guderian AI", "XIX Panzer Corps assault columns", "capture fortress")]
        ),
        makeScenario(
            .kobryn,
            order: 4,
            title: "Battle of Kobryn",
            dateLabel: "14-18 Sep 1939",
            start: .init(year: 1939, month: 9, day: 14),
            theater: .poland1939,
            status: .dzwProxyLoadable,
            posture: .mobileDelay,
            command: "XIX Panzer Corps, primarily 2nd Motorized Infantry Division",
            playerForce: "Operational Group Polesie and 60th Reserve Infantry Division",
            result: "Inconclusive",
            intent: "Protect a rearguard, block routes, and escape before encirclement closes.",
            sources: [source("Battle of Kobryn", "https://en.wikipedia.org/wiki/Battle_of_Kobry%C5%84")],
            features: [feature("Kobryn town", "contested road hub"), feature("Eastern exits", "withdrawal lanes")],
            objectives: [objective("Keep the road hub contested", 3, "Prevent an early German route capture."), objective("Exit reserve infantry", 3, "Score for units leaving by the eastern edge.")],
            forces: [force("Player", "Operational Group Polesie", "rearguard withdrawal"), force("Guderian AI", "German motorized infantry", "fix and encircle")]
        ),
        makeScenario(
            .sedan,
            order: 5,
            title: "Battle of Sedan",
            dateLabel: "12-17 May 1940",
            start: .init(year: 1940, month: 5, day: 12),
            theater: .france1940,
            status: .dzwProxyLoadable,
            posture: .fortifiedDelay,
            command: "XIX Army Corps under Panzergruppe Kleist",
            playerForce: "French 2nd Army sector with British air support",
            result: "German victory",
            intent: "Defend the Meuse crossing, bridge approaches, artillery positions, and counterattack routes under air pressure.",
            sources: [source("Battle of Sedan", "https://en.wikipedia.org/wiki/Battle_of_Sedan_%281940%29"), source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")],
            features: [feature("Meuse river", "crossing obstacle"), feature("Sedan bridge sites", "German bridgehead objectives"), feature("Artillery parks", "defensive fire support")],
            objectives: [objective("Deny bridgehead expansion", 5, "Keep German units away from the far-bank objectives."), objective("Save artillery control", 2, "Keep observer and artillery assets unbroken.")],
            forces: [force("Player", "French Sedan sector defenders", "river defense"), force("Guderian AI", "XIX Army Corps assault echelons", "force crossing")]
        ),
        makeScenario(.stonne, order: 6, title: "Stonne Heights", dateLabel: "15-17 May 1940", start: .init(year: 1940, month: 5, day: 15), theater: .france1940, status: .dzwProxyLoadable, posture: .counterattack, command: "XIX Army Corps bridgehead flank", playerForce: "French armor and infantry around Stonne", result: "German bridgehead secured", intent: "Threaten the bridgehead with heavy tanks, village cover, and hill control.", sources: [source("Stonne", "https://en.wikipedia.org/wiki/Stonne"), source("Battle of Sedan", "https://en.wikipedia.org/wiki/Battle_of_Sedan_%281940%29"), source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")], features: [feature("Stonne village", "close-range armor fight"), feature("Heights", "bridgehead observation"), feature("Mont-Dieu woods", "flank cover and approach terrain")], objectives: [objective("Contest the heights", 4, "Control high ground overlooking the bridgehead."), objective("Break German support", 3, "Damage infantry, anti-tank, or assault-gun support before withdrawing."), objective("Preserve heavy tanks", 2, "Keep Char B1 shock assets from being isolated after the village changes hands.")], forces: [force("Player", "French Char B1 bis counterattack force", "counterattack"), force("Guderian AI", "German bridgehead flank guard", "hold bridgehead")]),
        makeScenario(.montcornet, order: 7, title: "Battle of Montcornet", dateLabel: "17-19 May 1940", start: .init(year: 1940, month: 5, day: 17), theater: .france1940, status: .dzwProxyLoadable, posture: .counterattack, command: "Guderian sector with German 1st Panzer Division", playerForce: "French 4e Division cuirassee under Charles de Gaulle", result: "French victory followed by withdrawal pressure", intent: "Raid German columns with strong tanks but limited support, then disengage before air and reserve pressure peak.", sources: [source("Battle of Montcornet", "https://en.wikipedia.org/wiki/Battle_of_Montcornet")], features: [feature("Montcornet village", "raid target"), feature("German road columns", "operational disruption targets"), feature("Luftwaffe lanes", "air pressure timing")], objectives: [objective("Raid the column", 4, "Destroy or disrupt German transport, command, and road units."), objective("Disengage armor", 3, "Exit tanks before air attacks and German reserves peak."), objective("Hold raid tempo", 2, "Keep at least one armored group mobile after the first strike.")], forces: [force("Player", "4e Division cuirassee", "armored raid"), force("Guderian AI", "German column guards", "absorb and counterattack")]),
        makeScenario(.amiensAbbeville, order: 8, title: "Amiens-Abbeville Channel Race", dateLabel: "20 May 1940", start: .init(year: 1940, month: 5, day: 20), theater: .france1940, status: .dzwProxyLoadable, posture: .mobileDelay, command: "XIX Army Corps", playerForce: "French and British blocking forces on Somme approaches", result: "German breakthrough to Channel", intent: "Buy evacuation time by holding Somme bridges, towns, and road junctions as XIX Corps drives from Amiens to Abbeville.", sources: [source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps"), source("Battle of Abbeville", "https://en.wikipedia.org/wiki/Battle_of_Abbeville")], features: [feature("Somme bridges", "crossing control"), feature("Amiens road hub", "central blocking point"), feature("Abbeville road", "Channel exit axis")], objectives: [objective("Hold Somme crossings", 4, "Delay German exit movement across the river line."), objective("Demolish road links", 2, "Deny clean armored routes."), objective("Buy evacuation time", 3, "Score each turn before the Channel cut is complete.")], forces: [force("Player", "Allied blocking detachments", "mobile delay"), force("Guderian AI", "Panzer spearheads", "reach Channel")]),
        makeScenario(.boulogne, order: 9, title: "Battle of Boulogne", dateLabel: "22-25 May 1940", start: .init(year: 1940, month: 5, day: 22), theater: .france1940, status: .dzwProxyLoadable, posture: .evacuationDefense, command: "XIX Corps; 2nd Panzer Division attack", playerForce: "French, British, and Belgian port defenders", result: "German victory", intent: "Protect evacuation points, old-town perimeter positions, demolitions, and naval-fire support while German armor closes in.", sources: [source("Battle of Boulogne", "https://en.wikipedia.org/wiki/Battle_of_Boulogne")], features: [feature("Harbor", "evacuation and destroyer docking objective"), feature("Haute Ville", "old-town defensive perimeter"), feature("River Liane", "harbor approach and urban crossing obstacle"), feature("Mont St. Lambert ridge", "German observation and assault approach")], objectives: [objective("Evacuate troops", 5, "Score for units embarked from the harbor while destroyers can still dock."), objective("Hold demolition teams", 2, "Keep port denial teams alive after evacuation scoring."), objective("Use naval support", 2, "Pin or delay German assaults with destroyer fire.")], forces: [force("Player", "Boulogne garrison", "port defense"), force("Guderian AI", "2nd Panzer Division", "capture port")]),
        makeScenario(.calais, order: 10, title: "Siege of Calais", dateLabel: "22-26 May 1940", start: .init(year: 1940, month: 5, day: 22), theater: .france1940, status: .dzwProxyLoadable, posture: .evacuationDefense, command: "XIX Corps sector; 10th Panzer Division under Ferdinand Schaal", playerForce: "British, French, and Belgian defenders", result: "German victory", intent: "Win strategically by holding layered defenses long enough to fix German armor and support Dunkirk, not by keeping the port forever.", sources: [source("Siege of Calais", "https://en.wikipedia.org/wiki/Siege_of_Calais_%281940%29"), source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")], features: [feature("Calais walls", "defensive perimeter"), feature("Citadel and docks", "inner siege objectives"), feature("Dunkirk road", "strategic delay axis"), feature("Supply points", "garrison endurance under siege")], objectives: [objective("Hold the perimeter", 4, "Delay German entry into the port."), objective("Protect Dunkirk time", 4, "Score each turn the German force is fixed at Calais."), objective("Preserve supply", 2, "Keep ammunition or command points active during the siege.")], forces: [force("Player", "Calais garrison", "siege defense"), force("Guderian AI", "10th Panzer Division", "reduce port")]),
        makeScenario(.dunkirk, order: 11, title: "Dunkirk Perimeter Pressure", dateLabel: "26 May-4 Jun 1940", start: .init(year: 1940, month: 5, day: 26), theater: .france1940, status: .dzwProxyLoadable, posture: .evacuationDefense, command: "Guderian-adjacent Channel port campaign pressure", playerForce: "British, French, Belgian, and Dutch evacuation perimeter", result: "Allied evacuation under German pressure", intent: "Conduct perimeter defense and evacuation management with explicit caveats about Guderian's indirect command scope.", sources: [source("Battle of Dunkirk", "https://en.wikipedia.org/wiki/Battle_of_Dunkirk"), source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")], features: [feature("Beach perimeter", "evacuation zone"), feature("Canal lines", "defensive obstacles"), feature("Rear-guard exits", "sacrifice and force-preservation tradeoff"), feature("Air attack lanes", "evacuation-capacity pressure")], objectives: [objective("Evacuate formations", 6, "Score for units withdrawn by sea."), objective("Hold perimeter exits", 2, "Keep German units out of evacuation lanes."), objective("Preserve command caveat", 1, "Keep scenario notes clear that this is campaign-pressure rather than direct command.")], forces: [force("Player", "Dunkirk perimeter forces", "evacuation defense"), force("Guderian AI", "German pressure forces", "compress perimeter")]),
        makeScenario(.fallRot, order: 12, title: "Fall Rot Swiss-Border Drive", dateLabel: "10-22 Jun 1940", start: .init(year: 1940, month: 6, day: 10), theater: .france1940, status: .dzwProxyLoadable, posture: .mobileDelay, command: "Panzergruppe Guderian", playerForce: "French defenders around Aisne, Marne-Rhine Canal, Langres, Belfort, and Epinal", result: "German victory", intent: "Stage bridge demolitions, fortress-town stands, fuel denial, road congestion, and retreat corridors before the drive reaches the Swiss border and rear of the Maginot Line.", sources: [source("Fall Rot", "https://en.wikipedia.org/wiki/Fall_Rot"), source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")], features: [feature("Aisne and Marne-Rhine crossings", "bridge denial and engineer delay"), feature("Belfort and Epinal", "fortress-town delay objectives"), feature("Vosges retreat corridor", "French withdrawal route"), feature("Swiss-border cut line", "encirclement pressure")], objectives: [objective("Deny bridges", 3, "Destroy or hold canal and river crossings."), objective("Extract defenders", 4, "Move French forces toward retreat corridors."), objective("Force congestion", 2, "Use demolition and fuel-denial points to slow panzer tempo.")], forces: [force("Player", "French late-campaign defenders", "mobile delay"), force("Guderian AI", "Panzergruppe Guderian", "deep exploitation")]),
        makeScenario(.bialystokMinsk, order: 13, title: "Battle of Bialystok-Minsk", dateLabel: "22 Jun-9 Jul 1941", start: .init(year: 1941, month: 6, day: 22), theater: .easternFront1941, status: .dzwProxyLoadable, posture: .breakout, command: "2nd Panzer Group as Army Group Centre southern pincer", playerForce: "Soviet Western Front formations", result: "German victory", intent: "Fight breakout and delaying actions while preserving command assets, mechanized counterattack options, and Minsk road/rail supply routes before double envelopment closes.", sources: [source("Battle of Bialystok-Minsk", "https://en.wikipedia.org/wiki/Battle_of_Bia%C5%82ystok%E2%80%93Minsk"), source("Operation Barbarossa", "https://en.wikipedia.org/wiki/Operation_Barbarossa")], features: [feature("Bialystok salient", "forward-deployed pocket risk"), feature("Minsk road and rail junction", "escape and command objective"), feature("Bug and Neman crossings", "panzer penetration lines"), feature("Novogrudok pocket", "encirclement pressure")], objectives: [objective("Open breakout lanes", 4, "Keep at least one road or rail route free."), objective("Save command units", 3, "Withdraw headquarters and artillery toward Minsk."), objective("Delay pincer closure", 3, "Use mechanized counterattacks to slow one German pincer marker.")], forces: [force("Player", "Soviet Western Front detachments", "breakout"), force("Guderian AI", "2nd Panzer Group", "encircle")]),
        makeScenario(.smolensk, order: 14, title: "Battle of Smolensk", dateLabel: "10 Jul-10 Sep 1941", start: .init(year: 1941, month: 7, day: 10), theater: .easternFront1941, status: .dzwProxyLoadable, posture: .breakout, command: "2nd Panzer Group with Hoth's northern pincer", playerForce: "Soviet 16th, 19th, 20th, and reserve armies around Smolensk", result: "German victory with major delay to German advance", intent: "Hold Dnieper and Dvina crossings, counterattack pincer shoulders, force German supply strain, and open Yartsevo escape lanes from the Smolensk pocket.", sources: [source("Battle of Smolensk", "https://en.wikipedia.org/wiki/Battle_of_Smolensk_%281941%29"), source("2nd Panzer Army", "https://en.wikipedia.org/wiki/2nd_Panzer_Army")], features: [feature("Dnieper and Dvina crossings", "river-defense and supply-strain triggers"), feature("Smolensk pocket", "encirclement zone"), feature("Yartsevo escape lane", "Moscow-road breakout objective"), feature("Yelnya and reserve counterstrokes", "Soviet counteroffensive pressure")], objectives: [objective("Keep crossings contested", 4, "Prevent clean pincer closure by forcing crossing delays."), objective("Release trapped armies", 5, "Exit pocketed 16th, 19th, or 20th Army assets eastward."), objective("Force logistics strain", 3, "Make German armor choose between pincer closure and bridgehead reinforcement.")], forces: [force("Player", "Soviet Smolensk defenders and reserve armies", "counterattack and breakout"), force("Guderian AI", "2nd Panzer Group with northern pincer coordination", "close pocket")]),
        makeScenario(.roslavlNovozybkov, order: 15, title: "Roslavl-Novozybkov Offensive", dateLabel: "30 Aug-12 Sep 1941", start: .init(year: 1941, month: 8, day: 30), theater: .easternFront1941, status: .dzwProxyLoadable, posture: .counterattack, command: "2nd Panzer Group turned south toward Kiev with German 2nd Army support", playerForce: "Soviet Bryansk Front under Andrey Yeryomenko", result: "German victory after Soviet spoiling attacks", intent: "Disrupt the southward turn from Smolensk toward Kiev, raid German supply columns, preserve tank groups, and fight through intelligence limits before Operation Typhoon.", sources: [source("Roslavl-Novozybkov offensive", "https://en.wikipedia.org/wiki/Roslavl%E2%80%93Novozybkov_offensive"), source("Battle of Smolensk", "https://en.wikipedia.org/wiki/Battle_of_Smolensk_%281941%29")], features: [feature("Desna and Sozh crossings", "operational hinge and raid route"), feature("Bryansk Front assembly areas", "Soviet attack start"), feature("Roslavl-Novozybkov road axis", "attack-and-withdrawal route"), feature("Southward-turn screen", "German intent and intelligence limit")], objectives: [objective("Strike panzer flank", 4, "Damage German spearhead or supply-column assets."), objective("Preserve reserves", 3, "Withdraw tank and rifle groups after disruption."), objective("Reveal German intent", 2, "Use reconnaissance to expose the southward-turn screen.")], forces: [force("Player", "Bryansk Front counterattack force", "spoiling offensive"), force("Guderian AI", "2nd Panzer Group and 2nd Army screen", "protect southward turn")]),
        makeScenario(.kiev, order: 16, title: "Battle of Kiev", dateLabel: "7 Jul-26 Sep 1941", start: .init(year: 1941, month: 9, day: 1), theater: .easternFront1941, status: .dzwProxyLoadable, posture: .breakout, command: "2nd Panzer Group northern pincer with Kleist's 1st Panzer Group", playerForce: "Soviet Southwestern Front", result: "German victory and major encirclement", intent: "Delay the northern pincer, keep eastern breakout corridors contested, and evacuate command posts and artillery control before the Kiev pocket closes.", sources: [source("Battle of Kiev", "https://en.wikipedia.org/wiki/Battle_of_Kiev_%281941%29"), source("2nd Panzer Army", "https://en.wikipedia.org/wiki/2nd_Panzer_Army")], features: [feature("Northern pincer route", "Guderian approach"), feature("Dnieper and Desna lines", "river delay and evacuation terrain"), feature("Kiev pocket", "encirclement zone"), feature("Eastern closure corridor", "command evacuation and breakout route")], objectives: [objective("Delay pincer closure", 5, "Hold or contest eastern junctions against panzer pressure."), objective("Evacuate command assets", 5, "Move headquarters and artillery-control assets out of the pocket."), objective("Open breakout corridors", 4, "Exit trapped rifle army groups after closure pressure begins.")], forces: [force("Player", "Soviet Southwestern Front", "breakout defense"), force("Guderian AI", "2nd Panzer Group and link-up pressure", "close northern pincer")]),
        makeScenario(.bryansk, order: 17, title: "Battle of Bryansk", dateLabel: "30 Sep-21 Oct 1941", start: .init(year: 1941, month: 9, day: 30), theater: .easternFront1941, status: .dzwProxyLoadable, posture: .breakout, command: "2nd Panzer Group / 2nd Panzer Army during Operation Typhoon", playerForce: "Soviet Bryansk Front, including 50th, 13th, and 3rd Armies", result: "German victory", intent: "Trade ground for time, fight pocket liquidation, protect the Orel-Tula road, and force autumn logistics checks before the southern Moscow approach opens.", sources: [source("Battle of Bryansk", "https://en.wikipedia.org/wiki/Battle_of_Bryansk_%281941%29"), source("Battle of Moscow / Operation Typhoon", "https://en.wikipedia.org/wiki/Battle_of_Moscow"), source("2nd Panzer Army", "https://en.wikipedia.org/wiki/2nd_Panzer_Army")], features: [feature("Bryansk pocket", "encirclement fight"), feature("Bryansk-Orel road", "unexpected German attack axis"), feature("Orel-Tula road", "southern Moscow approach"), feature("Autumn road friction", "logistics and supply-strain trigger")], objectives: [objective("Delay pocket collapse", 4, "Keep encircled 13th and 3rd Army formations fighting."), objective("Guard Tula axis", 5, "Prevent a clean German breakthrough on the Orel-Tula road."), objective("Preserve rail command", 3, "Keep Bryansk rail and command nodes active long enough to support exits.")], forces: [force("Player", "Bryansk Front detachments", "delay and breakout"), force("Guderian AI", "2nd Panzer Group / 2nd Panzer Army", "encircle and advance")]),
        makeScenario(.mtsensk, order: 18, title: "Mtsensk Armored Ambush", dateLabel: "4-11 Oct 1941", start: .init(year: 1941, month: 10, day: 4), theater: .easternFront1941, status: .dzwProxyLoadable, posture: .counterattack, command: "Guderian's Panzergruppe 2 sector, including 4th Panzer Division pressure", playerForce: "Soviet 4th Tank Brigade, 1st Guards Rifle Corps, and supporting anti-tank/artillery detachments", result: "Soviet delaying success", intent: "Use T-34/KV surprise, wooded ridge cover, anti-tank screens, and staged withdrawals to blunt German panzer divisions on the Orel-Mtsensk-Tula road.", sources: [source("Mikhail Katukov", "https://en.wikipedia.org/wiki/Mikhail_Katukov"), source("German encounter of Soviet T-34 and KV tanks", "https://en.wikipedia.org/wiki/German_encounter_of_Soviet_T-34_and_KV_tanks"), source("4th Panzer Division", "https://en.wikipedia.org/wiki/4th_Panzer_Division"), source("1st Guards Special Rifle Corps", "https://en.wikipedia.org/wiki/1st_Guards_Special_Rifle_Corps"), source("Battle of Moscow", "https://en.wikipedia.org/wiki/Battle_of_Moscow")], features: [feature("Orel-Mtsensk road", "ambush and German movement axis"), feature("Wooded ridges", "concealed armor positions"), feature("T-34/KV kill lanes", "surprise and shock scoring"), feature("Tula withdrawal route", "post-ambush force-preservation lane")], objectives: [objective("Ambush panzer lead", 5, "Destroy, immobilize, or pin German spearhead vehicles from cover."), objective("Preserve Guards tanks", 4, "Withdraw T-34/KV assets after scoring ambush results."), objective("Keep Tula road delayed", 3, "Prevent a clean German exit from Mtsensk toward Tula.")], forces: [force("Player", "Katukov's 4th Tank Brigade and 1st Guards Rifle Corps screen", "armored ambush"), force("Guderian AI", "4th Panzer Division and German motorized pressure", "force road")]),
        makeScenario(
            .moscowTulaKashira,
            order: 19,
            title: "Moscow Southern Approach",
            dateLabel: "2 Oct 1941-7 Jan 1942",
            start: .init(year: 1941, month: 10, day: 24),
            theater: .easternFront1941,
            status: .dzwProxyLoadable,
            posture: .fortifiedDelay,
            command: "2nd Panzer Army under Guderian",
            playerForce: "Soviet forces defending Tula, Kashira, and southern approaches to Moscow",
            result: "Soviet victory",
            intent: "Extend the demo into the full southern-pincer chain: preserve the Tula defensive belt, react to the Venev/Kashira bypass, time Belov/Getman-style mobile reserves, and turn winter logistics into the opening of the Soviet counteroffensive.",
            sources: [source("Battle of Moscow", "https://en.wikipedia.org/wiki/Battle_of_Moscow"), source("2nd Panzer Army", "https://en.wikipedia.org/wiki/2nd_Panzer_Army"), source("Mikhail Katukov", "https://en.wikipedia.org/wiki/Mikhail_Katukov")],
            features: [feature("Orel-Tula road", "Bryansk/Mtsensk approach chain"), feature("Tula defensive belt", "city strongpoint"), feature("Venev-Kashira axis", "southern bypass and counterstroke route"), feature("Winter roads", "logistics friction"), feature("Mordves counteroffensive route", "late Soviet drive-back axis")],
            objectives: [objective("Hold Tula", 5, "Keep Soviet control or contested control of the city objective."), objective("Deny Kashira bypass", 4, "Prevent German armor from exiting through Venev and Kashira."), objective("Exhaust panzer supply", 4, "Force German units to spend turns in poor supply or winter terrain."), objective("Launch counteroffensive", 3, "Use mobile reserves after German exhaustion to drive back a spearhead.")],
            forces: [force("Player", "Soviet Tula, Kashira, Belov/Getman reserve, and winter counteroffensive defenders", "winter defense"), force("Guderian AI", "2nd Panzer Army southern pincer", "break southern approach")]
        ),
    ]

    public static let demoIDs: [GuderianBattleID] = [.wizna, .sedan, .moscowTulaKashira]

    public static func scenario(id: GuderianBattleID) -> GuderianScenario? {
        all.first { $0.id == id }
    }
}

private func makeScenario(
    _ id: GuderianBattleID,
    order: Int,
    title: String,
    dateLabel: String,
    start: ScenarioDateKey,
    theater: CampaignTheater,
    status: ScenarioStatus,
    posture: PlayerPosture,
    command: String,
    playerForce: String,
    result: String,
    intent: String,
    sources: [ScenarioSource],
    features: [ScenarioMapFeature],
    objectives: [ScenarioObjective],
    forces: [ScenarioForceSlot],
    tags: [String] = []
) -> GuderianScenario {
    GuderianScenario(
        id: id,
        order: order,
        title: title,
        dateLabel: dateLabel,
        startDate: start,
        theater: theater,
        status: status,
        playerPosture: posture,
        guderianCommand: command,
        playerForceSummary: playerForce,
        historicalResult: result,
        designIntent: intent,
        sourceLinks: sources,
        mapFeatures: features,
        objectives: objectives,
        forces: forces,
        tags: tags
    )
}

private func source(_ title: String, _ urlString: String) -> ScenarioSource {
    guard let url = URL(string: urlString) else {
        preconditionFailure("Invalid source URL: \(urlString)")
    }
    return ScenarioSource(title: title, url: url)
}

private func feature(_ name: String, _ role: String) -> ScenarioMapFeature {
    ScenarioMapFeature(name: name, role: role)
}

private func objective(_ name: String, _ victoryPoints: Int, _ description: String) -> ScenarioObjective {
    ScenarioObjective(name: name, victoryPoints: victoryPoints, description: description)
}

private func force(_ side: String, _ historicalForce: String, _ role: String) -> ScenarioForceSlot {
    ScenarioForceSlot(side: side, historicalForce: historicalForce, role: role)
}
