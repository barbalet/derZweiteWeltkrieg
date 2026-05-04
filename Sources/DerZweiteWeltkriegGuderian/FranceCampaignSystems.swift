import Foundation

public enum FranceCampaignAssetKind: String, Codable, Hashable, Sendable {
    case heavyTank = "Heavy tank"
    case armoredDivision = "Armored division"
    case infantryStrongpoint = "Infantry strongpoint"
    case riverCrossing = "River crossing"
    case airPressure = "Air pressure"
    case portOrChannelRoute = "Port or Channel route"
    case evacuationPoint = "Evacuation point"
    case navalSupport = "Naval support"
    case demolition = "Demolition"
    case portPerimeter = "Port perimeter"
    case roadJunction = "Road junction"
    case withdrawalRoute = "Withdrawal route"
}

public struct FranceCampaignAsset: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: FranceCampaignAssetKind
    public let battlefieldRole: String
    public let limitation: String

    public init(
        id: String,
        name: String,
        kind: FranceCampaignAssetKind,
        battlefieldRole: String,
        limitation: String
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.battlefieldRole = battlefieldRole
        self.limitation = limitation
    }
}

public struct FranceCampaignRule: Identifiable, Codable, Hashable, Sendable {
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

public struct FranceScenarioSystemProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let operationalProblem: String
    public let playerDoctrine: String
    public let assets: [FranceCampaignAsset]
    public let specialRules: [FranceCampaignRule]

    public init(
        id: GuderianBattleID,
        operationalProblem: String,
        playerDoctrine: String,
        assets: [FranceCampaignAsset],
        specialRules: [FranceCampaignRule]
    ) {
        self.id = id
        self.operationalProblem = operationalProblem
        self.playerDoctrine = playerDoctrine
        self.assets = assets
        self.specialRules = specialRules
    }
}

public enum FranceCampaignSystemCatalog {
    public static func profile(for scenario: GuderianScenario) -> FranceScenarioSystemProfile? {
        profile(for: scenario.id)
    }

    public static func profile(for id: GuderianBattleID) -> FranceScenarioSystemProfile? {
        switch id {
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
        default:
            return nil
        }
    }

    public static let franceScenarioIDs: [GuderianBattleID] = [
        .sedan,
        .stonne,
        .montcornet,
        .amiensAbbeville,
        .boulogne,
        .calais,
        .dunkirk,
        .fallRot,
    ]

    private static let sedan = FranceScenarioSystemProfile(
        id: .sedan,
        operationalProblem: "The French player must defend a river line under severe air and artillery pressure while German engineers try to create a bridgehead.",
        playerDoctrine: "Keep artillery control alive, contest bridge sites, and counterattack before panzer follow-up turns a foothold into breakout tempo.",
        assets: [
            franceAsset("sedan-meuse-crossing", "Meuse crossing defense", .riverCrossing, "Anchor the player around bridge denial and artillery observation.", "Once engineers hold a bridge site, the pressure curve accelerates."),
            franceAsset("sedan-french-artillery", "French artillery control", .infantryStrongpoint, "Punish crossings and preserve command cohesion.", "Air-pressure events can pin but should not erase all agency."),
            franceAsset("sedan-air-pressure", "German air-pressure lane", .airPressure, "Represents the suppression that opens the crossing.", "Capped in early turns so the defense still gets a response window."),
        ],
        specialRules: [
            franceRule("sedan-observer-control", "Observer control", "A French observer or artillery unit remains unpinned.", "Bridge sites cannot score stable German control without surviving a player response."),
            franceRule("sedan-counterattack-window", "Counterattack window", "A bridgehead is established or artillery control is lost.", "French reserves enter before the German road-exit score can be locked."),
        ]
    )

    private static let stonne = FranceScenarioSystemProfile(
        id: .stonne,
        operationalProblem: "French forces try to threaten the Sedan bridgehead from the Stonne heights while German infantry and panzers fight for a village that changes hands repeatedly.",
        playerDoctrine: "Use Char B1 heavy tanks and village cover to contest heights, damage German support, and force bridgehead risk without overextending.",
        assets: [
            franceAsset("stonne-char-b1", "Char B1 bis shock group", .heavyTank, "Break German assault tempo at short range and punish weak anti-tank fire.", "Fuel, coordination, and flank exposure limit repeated attacks."),
            franceAsset("stonne-heights", "Stonne heights", .infantryStrongpoint, "Observation and terrain control over the Sedan bridgehead flank.", "Holding the heights attracts concentrated German artillery and infantry pressure."),
            franceAsset("stonne-grossdeutschland", "Grossdeutschland pressure", .roadJunction, "German infantry pressure that can fix French tanks in the village.", "Cannot safely assault heavy tanks without support markers."),
        ],
        specialRules: [
            franceRule("stonne-heavy-tank-shock", "Heavy-tank shock", "A Char B1 attacks from village or ridge cover.", "Cancel one German anti-tank result unless the French unit is flanked or isolated."),
            franceRule("stonne-change-hands", "Village changes hands", "Stonne control flips during a turn.", "Award contested-control points and escalate German reinforcement pressure."),
        ]
    )

    private static let montcornet = FranceScenarioSystemProfile(
        id: .montcornet,
        operationalProblem: "De Gaulle's 4e Division cuirassee attacks German rear-area and column positions but lacks enough infantry, air cover, and time to exploit success.",
        playerDoctrine: "Raid the road net, destroy or disorder transport and command assets, then withdraw armor before Luftwaffe and German reserves isolate it.",
        assets: [
            franceAsset("montcornet-4dcr", "4e Division cuirassee", .armoredDivision, "High-value armored raid force with strong tanks and weak support.", "Must disengage before air and reserve pressure peak."),
            franceAsset("montcornet-column", "German column targets", .roadJunction, "Soft targets whose loss slows Guderian's operational tempo.", "Protected by roadblocks and timed German reaction orders."),
            franceAsset("montcornet-air", "Luftwaffe reaction", .airPressure, "Late pressure that forces withdrawal decisions.", "Arrives after the player has a raid window."),
        ],
        specialRules: [
            franceRule("montcornet-raid-window", "Raid window", "French armor reaches a road objective before German reserves enter.", "Score disruption and reduce German pursuit orders."),
            franceRule("montcornet-withdrawal", "Timed withdrawal", "Turns 4-6 or after two raid objectives are scored.", "French armor can exit for preservation points before air pressure peaks."),
        ]
    )

    private static let amiensAbbeville = FranceScenarioSystemProfile(
        id: .amiensAbbeville,
        operationalProblem: "Allied blocking forces face the XIX Corps race to Amiens and Abbeville, where the German objective is to cut through to the Channel and turn the Allied north flank.",
        playerDoctrine: "Hold Somme bridges, guard road junctions, and trade positions for evacuation time as German armored divisions spread along the river line.",
        assets: [
            franceAsset("amiens-somme-bridges", "Somme bridge detachments", .riverCrossing, "Delay German armored crossings and force defensive deployments along the river.", "Cannot hold every crossing once multiple panzer divisions fan out."),
            franceAsset("amiens-roadblocks", "Amiens-Abbeville roadblocks", .roadJunction, "Buy time at town and road chokepoints.", "Bypassed roadblocks stop scoring if no withdrawal lane remains."),
            franceAsset("amiens-channel-route", "Channel evacuation time", .portOrChannelRoute, "Converts local delay into strategic time for northern Allied forces.", "German exit markers reduce the evacuation clock each turn."),
        ],
        specialRules: [
            franceRule("amiens-bridge-delay", "Bridge delay", "A Somme crossing is contested at turn end.", "Prevent German exit scoring through that road band for one turn."),
            franceRule("amiens-channel-cut", "Channel cut", "German armor controls both Amiens and Abbeville exit markers.", "End positional scoring and shift to evacuation-time scoring."),
        ]
    )

    private static let boulogne = FranceScenarioSystemProfile(
        id: .boulogne,
        operationalProblem: "Boulogne is a port-defense and evacuation battle where Allied defenders use the old town, harbor, naval gunfire, and demolition parties to buy time under 2nd Panzer Division pressure.",
        playerDoctrine: "Hold the harbor and Haute Ville long enough to embark troops, use destroyer fire and RAF support to slow assaults, then deny the port as the perimeter collapses.",
        assets: [
            franceAsset("boulogne-harbor", "Boulogne harbor evacuation points", .evacuationPoint, "Converts port defense into embarked formations and wounded/non-combatant evacuation.", "Harbor scoring collapses if German armor controls the quay."),
            franceAsset("boulogne-haute-ville", "Haute Ville old-town perimeter", .portPerimeter, "Defensive anchor on high ground and medieval walls.", "Can be isolated once the harbor road and lower town fall."),
            franceAsset("boulogne-naval-gunfire", "Royal Navy destroyer support", .navalSupport, "Bombards German positions and covers re-embarkation windows.", "Exposed to artillery and air pressure while entering the harbor."),
            franceAsset("boulogne-demolitions", "Port demolition party", .demolition, "Denies port facilities after evacuation scoring.", "Needs a held or contested harbor approach to act."),
        ],
        specialRules: [
            franceRule("boulogne-destroyer-window", "Destroyer window", "A destroyer support marker reaches the harbor while the quay is contested.", "Pin one German assault order and unlock embarkation scoring."),
            franceRule("boulogne-port-denial", "Port denial", "Demolition teams survive after an evacuation score.", "Deny one German harbor-control point even if the perimeter falls."),
        ]
    )

    private static let calais = FranceScenarioSystemProfile(
        id: .calais,
        operationalProblem: "Calais is a strategic delay: the garrison cannot expect relief, but every turn spent tying down 10th Panzer Division supports the wider Dunkirk evacuation.",
        playerDoctrine: "Layer defenses around the town, citadel, docks, and supply points; accept losses while preserving enough command and ammunition to keep the siege costly.",
        assets: [
            franceAsset("calais-citadel", "Calais citadel and town perimeter", .portPerimeter, "Layered defensive shell that keeps German assault forces fixed.", "Each lost layer increases supply pressure."),
            franceAsset("calais-dunkirk-time", "Dunkirk time objective", .portOrChannelRoute, "Strategic scoring for fixing German armor away from Dunkirk.", "Ends once German control reaches the inner docks."),
            franceAsset("calais-supply", "Garrison supply points", .infantryStrongpoint, "Ammunition and command endurance during the siege.", "Degrades under air/artillery pressure."),
        ],
        specialRules: [
            franceRule("calais-strategic-delay", "Strategic delay", "The garrison holds any inner perimeter objective at turn end.", "Score Dunkirk-time points regardless of final port control."),
            franceRule("calais-supply-pressure", "Supply pressure", "German assault and air-pressure markers both target a perimeter layer.", "Reduce garrison fire support unless a supply point remains held."),
        ]
    )

    private static let dunkirk = FranceScenarioSystemProfile(
        id: .dunkirk,
        operationalProblem: "Dunkirk is an evacuation-perimeter scenario with deliberate caveats: it represents Guderian-adjacent Channel pressure rather than a single direct Guderian battlefield command.",
        playerDoctrine: "Hold canal lines and beach exits, keep evacuation corridors open, and use rear-guard sacrifice to move formations off the perimeter.",
        assets: [
            franceAsset("dunkirk-beaches", "Beach evacuation sectors", .evacuationPoint, "Primary scoring locations for embarked formations.", "Air pressure and perimeter breaches reduce capacity."),
            franceAsset("dunkirk-canal-line", "Canal defensive line", .riverCrossing, "Stops German pressure from compressing the beachhead too quickly.", "Multiple breaches force evacuation-capacity losses."),
            franceAsset("dunkirk-rearguard", "Rear-guard perimeter detachments", .infantryStrongpoint, "Trades time and space for evacuation.", "Often scores by staying behind rather than surviving."),
        ],
        specialRules: [
            franceRule("dunkirk-command-caveat", "Command-scope caveat", "Scenario briefing opens.", "Display that this is a Guderian-adjacent campaign-pressure scenario, not a clean direct-command battle."),
            franceRule("dunkirk-evacuation-capacity", "Evacuation capacity", "A beach sector is open at turn end.", "Embark one formation; reduce capacity for each air-pressure or canal-breach marker."),
        ]
    )

    private static let fallRot = FranceScenarioSystemProfile(
        id: .fallRot,
        operationalProblem: "Fall Rot follows Panzergruppe Guderian's late drive toward the Swiss border and the rear of the Maginot Line, where French defenders must trade bridges, canals, fortress towns, and retreat corridors for time.",
        playerDoctrine: "Deny crossings on the Aisne and Marne-Rhine approaches, force fuel and road congestion checks, and extract defenders before Belfort/Epinal pressure cuts the route.",
        assets: [
            franceAsset("fallrot-canal", "Marne-Rhine Canal and river crossings", .riverCrossing, "Bridge demolition and crossing-delay objectives.", "Cannot be held indefinitely once panzer engineers arrive."),
            franceAsset("fallrot-fortress-towns", "Belfort and Epinal fortress towns", .infantryStrongpoint, "Late-campaign strongpoints that create urban delay.", "Can be bypassed or isolated by deep exploitation."),
            franceAsset("fallrot-retreat-corridors", "Retreat corridors toward the Vosges", .withdrawalRoute, "Preservation scoring for French units trying to avoid encirclement.", "Close as German columns connect with Army Group C."),
            franceAsset("fallrot-fuel-denial", "Fuel and road-denial points", .demolition, "Slow panzer tempo by forcing congestion and fuel checks.", "Works best before German bridgeheads are secure."),
        ],
        specialRules: [
            franceRule("fallrot-bridge-denial", "Bridge denial", "A French demolition unit holds a crossing at turn end.", "Force Panzergruppe Guderian to spend an engineer or congestion order next turn."),
            franceRule("fallrot-vosges-trap", "Vosges trap", "German forces control Belfort and an eastern road marker.", "Switch player scoring from position defense to retreat-corridor preservation."),
        ]
    )
}

private func franceAsset(
    _ id: String,
    _ name: String,
    _ kind: FranceCampaignAssetKind,
    _ role: String,
    _ limitation: String
) -> FranceCampaignAsset {
    FranceCampaignAsset(id: id, name: name, kind: kind, battlefieldRole: role, limitation: limitation)
}

private func franceRule(_ id: String, _ name: String, _ trigger: String, _ effect: String) -> FranceCampaignRule {
    FranceCampaignRule(id: id, name: name, trigger: trigger, effect: effect)
}
