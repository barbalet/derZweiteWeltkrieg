import Foundation

public enum PolishCampaignAssetKind: String, Codable, Hashable, Sendable {
    case infantryDivision = "Infantry division"
    case cavalryBrigade = "Cavalry brigade"
    case antiTankGun = "Anti-tank gun"
    case bunker = "Bunker"
    case fortress = "Fortress"
    case armoredTrain = "Armored train"
    case obsoleteTank = "Obsolete tank"
    case demolitionTeam = "Demolition team"
    case withdrawalRoute = "Withdrawal route"
    case commandFriction = "Command friction"
}

public struct PolishCampaignAsset: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: PolishCampaignAssetKind
    public let battlefieldRole: String
    public let limitation: String

    public init(
        id: String,
        name: String,
        kind: PolishCampaignAssetKind,
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

public struct PolishCampaignRule: Identifiable, Codable, Hashable, Sendable {
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

public struct PolishScenarioSystemProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let operationalProblem: String
    public let playerDoctrine: String
    public let assets: [PolishCampaignAsset]
    public let specialRules: [PolishCampaignRule]

    public init(
        id: GuderianBattleID,
        operationalProblem: String,
        playerDoctrine: String,
        assets: [PolishCampaignAsset],
        specialRules: [PolishCampaignRule]
    ) {
        self.id = id
        self.operationalProblem = operationalProblem
        self.playerDoctrine = playerDoctrine
        self.assets = assets
        self.specialRules = specialRules
    }
}

public enum PolishCampaignSystemCatalog {
    public static func profile(for scenario: GuderianScenario) -> PolishScenarioSystemProfile? {
        profile(for: scenario.id)
    }

    public static func profile(for id: GuderianBattleID) -> PolishScenarioSystemProfile? {
        switch id {
        case .tucholaForest:
            return tucholaForest
        case .wizna:
            return wizna
        case .brzescLitewski:
            return brzescLitewski
        case .kobryn:
            return kobryn
        default:
            return nil
        }
    }

    public static let polishScenarioIDs: [GuderianBattleID] = [
        .tucholaForest,
        .wizna,
        .brzescLitewski,
        .kobryn,
    ]

    private static let tucholaForest = PolishScenarioSystemProfile(
        id: .tucholaForest,
        operationalProblem: "The Pomeranian Army is defending exposed corridor positions while German motorized and panzer columns try to link mainland Germany with East Prussia.",
        playerDoctrine: "Trade road junctions and bridges for time, then withdraw coherent infantry, cavalry screens, and anti-tank guns before the pincer closes.",
        assets: [
            asset("tuchola-9th-division", "9th Infantry Division bridge guards", .infantryDivision, "Hold Brda crossings and village strongpoints long enough for demolitions.", "Coordination breaks down if adjacent withdrawal lanes are already cut."),
            asset("tuchola-27th-division", "27th Infantry Division counterattack", .infantryDivision, "Launch a limited counterstroke against the Brda bridgehead.", "Arrives piecemeal unless command-friction rules are satisfied."),
            asset("tuchola-czersk-group", "Czersk Operational Group screen", .infantryDivision, "Cover the Chojnice-Tuchola road net and delay motorized infantry.", "Cannot survive a prolonged stand against armor without a withdrawal route."),
            asset("tuchola-pomeranian-cavalry", "Pomeranian Cavalry Brigade screen", .cavalryBrigade, "Disrupt reconnaissance and cover withdrawals around Krojanty.", "High losses if it remains exposed to armored cars after its screening attack."),
            asset("tuchola-anti-tank", "37 mm anti-tank gun detachments", .antiTankGun, "Punish panzers that enter forest road chokepoints.", "Few guns; each loss removes a whole fire lane from the defense."),
            asset("tuchola-demolitions", "Brda bridge demolition parties", .demolitionTeam, "Partially destroy or block crossings at Pruszcz and Pila-Mlyn.", "Must be protected through the first German contact window."),
            asset("tuchola-bydgoszcz-route", "Bydgoszcz withdrawal route", .withdrawalRoute, "Convert delay into campaign success by exiting intact units.", "The route degrades once German pincer markers reach the south edge."),
            asset("tuchola-command-friction", "Pomeranian Army command friction", .commandFriction, "Models the historical difficulty of coordinating 9th and 27th Division actions.", "Counterattack and withdrawal orders cannot both be optimized in the same turn."),
        ],
        specialRules: [
            rule("tuchola-brda-demolition", "Brda demolitions", "A Polish demolition asset is adjacent to an uncontrolled bridge at turn end.", "Block the crossing and score delay points; German engineers must spend a later action to reopen it."),
            rule("tuchola-forest-choke", "Forest road choke", "German armor leaves a road or enters a marked forest choke.", "Polish anti-tank units may fire before German assault orders resolve."),
            rule("tuchola-krojanty-screen", "Krojanty screen", "Pomeranian Cavalry Brigade attacks or screens on turns 2-3.", "Cancel one German reconnaissance or pursuit order, then force the cavalry to withdraw or risk losses."),
            rule("tuchola-pincer-alarm", "Pincer alarm", "German AI controls both the Brda bridgehead and a northern/eastern pressure marker.", "Switch Polish scoring from position defense to withdrawal preservation."),
        ]
    )

    private static let wizna = PolishScenarioSystemProfile(
        id: .wizna,
        operationalProblem: "Small Polish fortified detachments face overwhelming German armor, artillery, and assault pioneers.",
        playerDoctrine: "Use bunkers, anti-tank guns, and command-post morale to buy time rather than chasing a battlefield victory.",
        assets: [
            asset("wizna-bunkers", "Wizna bunker line", .bunker, "Anchor defensive fire and delay scoring.", "Static positions become vulnerable when isolated."),
            asset("wizna-at-guns", "Scarce anti-tank guns", .antiTankGun, "Threaten armor on the Narew approaches.", "Limited ammunition and narrow fire arcs."),
            asset("wizna-command", "Raginis command post", .commandFriction, "Keeps the defense coherent under artillery pressure.", "Morale drops sharply if the post is lost."),
        ],
        specialRules: [
            rule("wizna-isolated-bunker", "Isolated bunker", "A bunker has no adjacent friendly support.", "German assault pioneers may attack it after a suppression marker."),
            rule("wizna-last-stand", "Last stand scoring", "The final bunker or command post remains contested.", "Award delay points even if the wider position is collapsing."),
        ]
    )

    private static let brzescLitewski = PolishScenarioSystemProfile(
        id: .brzescLitewski,
        operationalProblem: "Polish defenders must turn an old fortress and rail hub into a delaying battle against mechanized assault columns.",
        playerDoctrine: "Use fortress depth, armored-train fire, obsolete tanks, and fallback gates to slow encirclement.",
        assets: [
            asset("brzesc-fortress", "Brzesc fortress sectors", .fortress, "Create layered urban and citadel defense positions.", "Strong locally, but vulnerable to isolation."),
            asset("brzesc-armored-train", "Armored train support", .armoredTrain, "Provides rail-line fire support and evacuation cover.", "Bound to rail control and can be cut off."),
            asset("brzesc-ft17", "FT-17 tank detachment", .obsoleteTank, "Represents old armor used as mobile strongpoints.", "Cannot duel modern panzers without terrain support."),
        ],
        specialRules: [
            rule("brzesc-rail-control", "Rail control", "The player controls a rail objective.", "Armored train support can fire or cover a fallback."),
            rule("brzesc-inner-fallback", "Inner fallback", "Outer fortress sectors are lost.", "Move surviving defenders into citadel positions and score preservation points."),
        ]
    )

    private static let kobryn = PolishScenarioSystemProfile(
        id: .kobryn,
        operationalProblem: "Operational Group Polesie must preserve cohesion while German motorized infantry tries to fix and envelop the rearguard.",
        playerDoctrine: "Hold Kobryn long enough to open eastern exits, then withdraw before motorized pressure becomes encirclement.",
        assets: [
            asset("kobryn-reserve-infantry", "60th Reserve Infantry Division", .infantryDivision, "Defend the town and cover retreat lanes.", "Lower mobility makes late withdrawal difficult."),
            asset("kobryn-field-guns", "Field and anti-tank guns", .antiTankGun, "Cover road approaches and town exits.", "Must limber before withdrawal scoring."),
            asset("kobryn-withdrawal", "Eastern withdrawal lanes", .withdrawalRoute, "Score force preservation and cohesion.", "Close if German pressure reaches both road exits."),
        ],
        specialRules: [
            rule("kobryn-roadblock", "Western roadblock", "Polish guns or reserve infantry contest the western road.", "Delay the German fixing attack and preserve one eastern exit from immediate pressure."),
            rule("kobryn-rearguard", "Rearguard timing", "The player holds a town objective through the midgame.", "Unlock withdrawal scoring for infantry groups."),
            rule("kobryn-cohesion", "Cohesion preservation", "Three or more units exit through the same lane.", "Award operational success for preserving the rearguard."),
        ]
    )
}

private func asset(
    _ id: String,
    _ name: String,
    _ kind: PolishCampaignAssetKind,
    _ role: String,
    _ limitation: String
) -> PolishCampaignAsset {
    PolishCampaignAsset(id: id, name: name, kind: kind, battlefieldRole: role, limitation: limitation)
}

private func rule(_ id: String, _ name: String, _ trigger: String, _ effect: String) -> PolishCampaignRule {
    PolishCampaignRule(id: id, name: name, trigger: trigger, effect: effect)
}
