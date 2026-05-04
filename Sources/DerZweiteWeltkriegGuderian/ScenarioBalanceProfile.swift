import Foundation

public enum ScenarioScoringSide: String, Codable, Hashable, Sendable {
    case player = "Player"
    case guderianAI = "Guderian AI"
    case contested = "Contested"
}

public enum VictoryBand: String, Codable, Hashable, Sendable {
    case decisive = "Decisive"
    case operational = "Operational"
    case tactical = "Tactical"
    case marginal = "Marginal"
    case historicalPressure = "Historical pressure"
}

public struct ScenarioScoreChannel: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioScoringSide
    public let victoryPoints: Int
    public let timing: String
    public let description: String

    public init(
        id: String,
        name: String,
        side: ScenarioScoringSide,
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

public struct ScenarioPacingRule: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let turnWindow: String
    public let effect: String

    public init(id: String, name: String, turnWindow: String, effect: String) {
        self.id = id
        self.name = name
        self.turnWindow = turnWindow
        self.effect = effect
    }
}

public struct ScenarioReinforcement: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let side: ScenarioUnitSide
    public let turnWindow: String
    public let unitName: String
    public let entryCondition: String
    public let role: String

    public init(
        id: String,
        side: ScenarioUnitSide,
        turnWindow: String,
        unitName: String,
        entryCondition: String,
        role: String
    ) {
        self.id = id
        self.side = side
        self.turnWindow = turnWindow
        self.unitName = unitName
        self.entryCondition = entryCondition
        self.role = role
    }
}

public struct ScenarioOutcomeBand: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let grade: VictoryBand
    public let scoreRange: ClosedRange<Int>
    public let summary: String

    public init(id: String, grade: VictoryBand, scoreRange: ClosedRange<Int>, summary: String) {
        self.id = id
        self.grade = grade
        self.scoreRange = scoreRange
        self.summary = summary
    }
}

public struct ScenarioBalanceProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let targetTurns: ClosedRange<Int>
    public let balanceIntent: String
    public let playerWinCondition: String
    public let germanPressureLimit: String
    public let scoreChannels: [ScenarioScoreChannel]
    public let pacingRules: [ScenarioPacingRule]
    public let reinforcements: [ScenarioReinforcement]
    public let outcomeBands: [ScenarioOutcomeBand]

    public init(
        id: GuderianBattleID,
        targetTurns: ClosedRange<Int>,
        balanceIntent: String,
        playerWinCondition: String,
        germanPressureLimit: String,
        scoreChannels: [ScenarioScoreChannel],
        pacingRules: [ScenarioPacingRule],
        reinforcements: [ScenarioReinforcement],
        outcomeBands: [ScenarioOutcomeBand]
    ) {
        self.id = id
        self.targetTurns = targetTurns
        self.balanceIntent = balanceIntent
        self.playerWinCondition = playerWinCondition
        self.germanPressureLimit = germanPressureLimit
        self.scoreChannels = scoreChannels
        self.pacingRules = pacingRules
        self.reinforcements = reinforcements
        self.outcomeBands = outcomeBands
    }

    public var maxPlayerScore: Int {
        scoreChannels
            .filter { $0.side == .player || $0.side == .contested }
            .map(\.victoryPoints)
            .reduce(0, +)
    }
}

public enum ScenarioBalanceCatalog {
    public static func profile(for scenario: GuderianScenario) -> ScenarioBalanceProfile {
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

    private static let tucholaForest = ScenarioBalanceProfile(
        id: .tucholaForest,
        targetTurns: 6...8,
        balanceIntent: "Make the first full-campaign battle a mobile-delay puzzle: the player should feel the German breakthrough forming, but still score by demolishing bridges, disrupting pursuit, and withdrawing coherent forces.",
        playerWinCondition: "Delay the Brda crossing through the early game and exit at least three Polish assets through the Bydgoszcz withdrawal route before the pincer closes.",
        germanPressureLimit: "German pincer pressure should not close both the bridgehead and withdrawal lane before the player has had at least three turns to choose between counterattack and withdrawal.",
        scoreChannels: [
            score("tuchola-brda-delay", "Brda crossing delay", .player, 4, "Turns 1-3", "Award points for blocked, demolished, or contested Pruszcz and Pila-Mlyn crossings."),
            score("tuchola-road-net", "Chojnice-Tuchola road net", .player, 3, "Turns 2-5", "Award if at least one forest road hub remains contested through the midgame."),
            score("tuchola-withdrawal", "Withdraw Pomeranian Army elements", .player, 5, "Turns 4-8", "Award for exiting infantry, cavalry screen, command, and anti-tank assets toward Bydgoszcz."),
            score("tuchola-krojanty-screen", "Krojanty screen disruption", .player, 2, "Turns 2-3", "Award if cavalry cancels or delays a German reconnaissance or pursuit order."),
            score("tuchola-german-corridor", "German corridor breakthrough", .guderianAI, 7, "Scenario end", "German score for clearing the Brda line and blocking the Bydgoszcz withdrawal route."),
        ],
        pacingRules: [
            pacing("tuchola-opening-contact", "Opening contact cap", "Turn 1", "German armor may reach bridge approaches but cannot both repair a crossing and score exit pressure in the same turn."),
            pacing("tuchola-demolition-window", "Demolition window", "Turns 1-2", "Polish demolition parties must get a meaningful chance to block at least one Brda crossing."),
            pacing("tuchola-counterattack-choice", "Counterattack choice", "Turns 2-4", "The 27th Infantry Division can counterattack the bridgehead, but committing it delays withdrawal scoring."),
            pacing("tuchola-pincer-pressure", "Pincer pressure", "Turns 3-6", "East Prussia pressure grows only after a bridgehead is open or a road hub falls."),
            pacing("tuchola-exit-race", "Exit race", "Turns 4-8", "German pursuit focuses on withdrawal lanes while Polish scoring shifts to preservation."),
        ],
        reinforcements: [
            reinforcement("tuchola-polish-27th", .player, "Turns 2-3", "27th Infantry Division counterattack group", "Enter if a Brda bridgehead is German-controlled or contested.", "Limited counterattack"),
            reinforcement("tuchola-german-engineers", .guderianAI, "Turns 2-3", "German bridge engineers", "Enter when a Brda crossing is blocked or demolished.", "Bridge repair"),
            reinforcement("tuchola-german-pincer", .guderianAI, "Turns 3-5", "East Prussia pincer pressure", "Enter once German forces hold a Brda bridgehead or Chojnice road hub.", "Encirclement clock"),
        ],
        outcomeBands: [
            outcome("tuchola-decisive", .decisive, 12...14, "The Polish defense turns the corridor fight into a disciplined escape with bridges blocked and key assets withdrawn."),
            outcome("tuchola-operational", .operational, 8...11, "The Brda line and cavalry screen buy time, though German pressure still breaks the corridor."),
            outcome("tuchola-tactical", .tactical, 4...7, "Some local delay is achieved, but too many formations are caught before Bydgoszcz."),
            outcome("tuchola-historical", .historicalPressure, 0...3, "German tempo tracks the historical corridor breakthrough and Polish formations are badly disorganized."),
        ]
    )

    private static let brzescLitewski = ScenarioBalanceProfile(
        id: .brzescLitewski,
        targetTurns: 6...8,
        balanceIntent: "Make Brzesc a fortress delay where the player can lose the town yet succeed by preserving command, armored-train, and fallback assets.",
        playerWinCondition: "Hold the citadel or keep it contested through turn 5, then withdraw at least two mobile or command assets through the south fallback gate.",
        germanPressureLimit: "German forces cannot isolate the citadel and interdict the fallback gate before armored trains have one meaningful support window.",
        scoreChannels: [
            score("brzesc-town-delay", "Town delay", .player, 3, "Turns 1-4", "Award for keeping Brzesc town contested."),
            score("brzesc-citadel-stand", "Citadel stand", .player, 5, "Turns 3-6", "Award for controlling or contesting fortress sectors."),
            score("brzesc-rail-support", "Armored-train support", .player, 3, "Any player turn", "Award if armored-train fire pins or covers a fallback."),
            score("brzesc-fallback", "Fallback gate preservation", .player, 4, "Turns 5-8", "Award for extracting command, train, infantry, or FT-17 assets."),
            score("brzesc-german-isolation", "Fortress isolation", .guderianAI, 7, "Scenario end", "German score for controlling town, rail, and fallback approaches."),
        ],
        pacingRules: [
            pacing("brzesc-rail-window", "Rail support window", "Turns 1-2", "Armored trains can act before German rail-cut pressure fully applies."),
            pacing("brzesc-isolation-clock", "Isolation clock", "Turns 3-5", "German isolation pressure grows only after town or rail control changes."),
            pacing("brzesc-fallback-choice", "Fallback choice", "Turns 5-8", "Player must choose whether to keep the citadel contested or preserve mobile assets."),
        ],
        reinforcements: [
            reinforcement("brzesc-german-engineers", .guderianAI, "Turns 3-4", "German engineer assault group", "Enter after town or rail approach is German-controlled.", "Fortress reduction"),
        ],
        outcomeBands: [
            outcome("brzesc-decisive", .decisive, 12...15, "The fortress delays XIX Corps and key assets escape."),
            outcome("brzesc-operational", .operational, 8...11, "The town falls, but the citadel and rail assets buy useful time."),
            outcome("brzesc-tactical", .tactical, 4...7, "Some delay is achieved before isolation."),
            outcome("brzesc-historical", .historicalPressure, 0...3, "The fortress falls near historical German tempo."),
        ]
    )

    private static let kobryn = ScenarioBalanceProfile(
        id: .kobryn,
        targetTurns: 5...7,
        balanceIntent: "Model Kobryn as an inconclusive rearguard where preservation and cohesion matter more than final town possession.",
        playerWinCondition: "Keep Kobryn contested through the midgame and withdraw at least three Polish units through one eastern lane.",
        germanPressureLimit: "German flank patrols can threaten one exit early, but both exits should not close before rearguard scoring unlocks.",
        scoreChannels: [
            score("kobryn-town-contest", "Kobryn contested", .player, 3, "Turns 1-4", "Award if the town remains contested or Polish-controlled."),
            score("kobryn-roadblock-delay", "Western roadblock delay", .player, 2, "Turns 1-3", "Award for delaying German motorized entry."),
            score("kobryn-cohesion-exit", "Cohesion withdrawal", .player, 5, "Turns 4-7", "Award for withdrawing three or more units through the same eastern lane."),
            score("kobryn-gun-preservation", "Gun preservation", .player, 2, "Scenario end", "Award if at least one field or anti-tank gun exits or remains unbroken."),
            score("kobryn-german-envelopment", "German envelopment", .guderianAI, 6, "Scenario end", "German score for controlling Kobryn and both eastern exits."),
        ],
        pacingRules: [
            pacing("kobryn-no-early-collapse", "No early collapse", "Turns 1-2", "German pressure starts by fixing roadblocks before exit closure."),
            pacing("kobryn-rearguard-unlock", "Rearguard unlock", "Turn 3", "If Kobryn is contested, withdrawal scoring becomes available."),
            pacing("kobryn-exit-race", "Exit race", "Turns 4-7", "German patrols target exits while the player scores cohesion."),
        ],
        reinforcements: [
            reinforcement("kobryn-german-flank", .guderianAI, "Turns 3-4", "German flank patrols", "Enter once the western roadblock is cleared or Kobryn is contested.", "Exit threat"),
        ],
        outcomeBands: [
            outcome("kobryn-decisive", .decisive, 10...12, "The rearguard preserves cohesion and denies a clean envelopment."),
            outcome("kobryn-operational", .operational, 7...9, "Kobryn is traded for an organized withdrawal."),
            outcome("kobryn-marginal", .marginal, 4...6, "The town delays German pressure but withdrawals are costly."),
            outcome("kobryn-historical", .historicalPressure, 0...3, "German pressure fixes the rearguard with little preserved cohesion."),
        ]
    )

    private static let wizna = ScenarioBalanceProfile(
        id: .wizna,
        targetTurns: 5...7,
        balanceIntent: "Teach fortified delay by letting the player score meaningful success even as the line is eventually overwhelmed.",
        playerWinCondition: "Hold at least two bunker objectives through turn 5 or preserve the command post after the final German assault.",
        germanPressureLimit: "German artillery can pin but should not remove a full bunker before the player has acted twice.",
        scoreChannels: [
            score("wizna-bunker-turns", "Bunker turns held", .player, 5, "End of each player turn", "One point per turn with two or more bunker objectives still controlled."),
            score("wizna-at-survival", "Anti-tank gun survival", .player, 2, "Scenario end", "Award if at least one anti-tank asset remains operational."),
            score("wizna-command-post", "Command post stand", .player, 3, "Scenario end", "Award if Gora Strekowa HQ is controlled or contested."),
            score("wizna-german-breakthrough", "German breakthrough", .guderianAI, 5, "Scenario end", "German pressure score for clearing the road and reducing the bunker belt."),
        ],
        pacingRules: [
            pacing("wizna-no-alpha", "No opening wipeout", "Turn 1", "Limit German fire to suppression/pinning before armor has moved."),
            pacing("wizna-escalation", "Escalating pressure", "Turns 3-5", "Allow assaults only after artillery or machine-gun pressure has marked the bunker as isolated."),
        ],
        reinforcements: [
            reinforcement("wizna-pioneers", .guderianAI, "Turn 3", "German assault pioneers", "Enter if at least one bunker is pinned.", "Bunker assault"),
        ],
        outcomeBands: [
            outcome("wizna-decisive", .decisive, 8...10, "The fortified line delays the assault far beyond expectations."),
            outcome("wizna-operational", .operational, 5...7, "The defenders buy useful time despite heavy losses."),
            outcome("wizna-historical", .historicalPressure, 0...4, "The line falls quickly under overwhelming pressure."),
        ]
    )

    private static let sedan = ScenarioBalanceProfile(
        id: .sedan,
        targetTurns: 6...8,
        balanceIntent: "Make Sedan a tense delay scenario: the German crossing should feel dangerous, but French artillery and counterattack timing must give the player agency.",
        playerWinCondition: "Deny a stable bridgehead through turn 6 or destroy enough follow-up armor that the German breakout stalls.",
        germanPressureLimit: "German air pressure suppresses artillery but cannot both neutralize all observers and release panzer follow-up before turn 3.",
        scoreChannels: [
            score("sedan-delay", "Bridgehead delay", .player, 6, "Turns 1-6", "One point for each turn the bridgehead perimeter is uncontrolled by German forces."),
            score("sedan-artillery", "Artillery control", .player, 3, "Scenario end", "Award if French observers or artillery remain active."),
            score("sedan-counterattack-damage", "Counterattack damage", .player, 4, "After reserve release", "Award for damaging engineer or panzer follow-up units."),
            score("sedan-bridge-denial", "Bridge denial", .contested, 3, "Scenario end", "Award if at least one bridge site is contested or blocked."),
            score("sedan-german-bridgehead", "Stable bridgehead", .guderianAI, 6, "Scenario end", "German score for holding bridgehead and road-exit objectives."),
        ],
        pacingRules: [
            pacing("sedan-air-cap", "Air-pressure cap", "Turn 1", "Air pressure may pin artillery or observers, not both across the whole line."),
            pacing("sedan-engineer-window", "Engineer crossing window", "Turns 2-3", "Engineers can establish a crossing only if an adjacent French defender is pinned or displaced."),
            pacing("sedan-counterattack-window", "Counterattack agency", "Turns 3-5", "French reserve counterattack enters before German armor can score the road-exit objective."),
            pacing("sedan-breakout-check", "Breakout check", "Turns 6-8", "German panzer follow-up must hold the bridgehead for one full player turn before exit scoring."),
        ],
        reinforcements: [
            reinforcement("sedan-french-reserve", .player, "Turns 3-4", "French reserve counterattack group", "Enter when the bridgehead is German-controlled or artillery control is lost.", "Counterattack damage"),
            reinforcement("sedan-panzer-followup", .guderianAI, "Turns 3-5", "German panzer follow-up", "Enter after German engineers establish and hold a crossing.", "Bridgehead exploitation"),
        ],
        outcomeBands: [
            outcome("sedan-decisive", .decisive, 12...16, "The Meuse crossing is disrupted and German breakout tempo collapses."),
            outcome("sedan-operational", .operational, 8...11, "The bridgehead forms, but the French delay and counterattack damage meaningfully slow exploitation."),
            outcome("sedan-tactical", .tactical, 4...7, "The defense inflicts losses but cannot prevent a working bridgehead."),
            outcome("sedan-historical", .historicalPressure, 0...3, "The German crossing runs close to the historical tempo."),
        ]
    )

    private static let stonne = ScenarioBalanceProfile(
        id: .stonne,
        targetTurns: 5...7,
        balanceIntent: "Stonne should feel like a violent bridgehead-flank contest: heavy tanks are powerful, but village control is unstable and overextended armor can be isolated.",
        playerWinCondition: "Contest Stonne and the heights while damaging German support, then preserve at least one heavy-tank group.",
        germanPressureLimit: "German anti-tank fire should need flank, isolation, or support markers before reliably stopping Char B1 attacks.",
        scoreChannels: [
            score("stonne-heights", "Contest Stonne heights", .player, 4, "Turns 1-5", "Award for controlling or contesting heights near the bridgehead flank."),
            score("stonne-heavy-tank-shock", "Heavy-tank shock", .player, 3, "Any player attack", "Award if Char B1 assets cancel or break a German support order."),
            score("stonne-support-losses", "German support losses", .player, 3, "Scenario end", "Award for damaging infantry, anti-tank, or artillery support."),
            score("stonne-tank-preservation", "Preserve heavy tanks", .player, 2, "Scenario end", "Award if a heavy-tank unit is not isolated or destroyed."),
            score("stonne-german-secure", "Bridgehead flank secured", .guderianAI, 6, "Scenario end", "German score for holding Stonne and the heights."),
        ],
        pacingRules: [
            pacing("stonne-shock-window", "Shock window", "Turns 1-2", "French heavy tanks get an early shock opportunity before German flank markers build."),
            pacing("stonne-control-flips", "Control flips", "Turns 2-5", "Village control can change repeatedly without ending the scenario."),
            pacing("stonne-isolation-risk", "Isolation risk", "Turns 4-7", "Unsupported heavy tanks become vulnerable to German containment."),
        ],
        reinforcements: [
            reinforcement("stonne-german-support", .guderianAI, "Turns 3-4", "German bridgehead support group", "Enter after Stonne changes hands or a Char B1 shock score is earned.", "Flank containment"),
        ],
        outcomeBands: [
            outcome("stonne-decisive", .decisive, 10...12, "French armor threatens the bridgehead flank and escapes with heavy tanks intact."),
            outcome("stonne-operational", .operational, 7...9, "The heights are contested and German support takes meaningful losses."),
            outcome("stonne-tactical", .tactical, 4...6, "Stonne is bloodily contested but German control stabilizes late."),
            outcome("stonne-historical", .historicalPressure, 0...3, "German bridgehead security is restored with limited disruption."),
        ]
    )

    private static let montcornet = ScenarioBalanceProfile(
        id: .montcornet,
        targetTurns: 5...6,
        balanceIntent: "Montcornet is a raid, not a hold-ground battle: the player scores by disrupting German road assets and then escaping before air and reserve pressure peaks.",
        playerWinCondition: "Score at least two road-column disruption objectives and withdraw armor before the air-pressure peak.",
        germanPressureLimit: "German reserves and air pressure should react after the player has an initial raid window.",
        scoreChannels: [
            score("montcornet-column-raid", "Column raid", .player, 5, "Turns 1-3", "Award for destroying or disordering German transport, command, or road assets."),
            score("montcornet-armor-mobile", "Armor remains mobile", .player, 2, "Turns 3-5", "Award if a French tank group remains unpinned after the raid."),
            score("montcornet-withdrawal", "Timed withdrawal", .player, 3, "Turns 4-6", "Award for exiting armor before air pressure peaks."),
            score("montcornet-german-trap", "German trap", .guderianAI, 6, "Scenario end", "German score for isolating or pinning French armor after the raid."),
        ],
        pacingRules: [
            pacing("montcornet-raid-window", "Raid window", "Turns 1-3", "French armor has priority access to road-column objectives."),
            pacing("montcornet-reaction", "Reserve reaction", "Turns 3-4", "German reserves begin to close exits after disruption scoring opens."),
            pacing("montcornet-air-peak", "Air-pressure peak", "Turns 4-6", "Lingering French armor becomes exposed to air-pressure penalties."),
        ],
        reinforcements: [
            reinforcement("montcornet-german-reserves", .guderianAI, "Turns 3-4", "German reserve reaction", "Enter after first French disruption score.", "Counterattack"),
            reinforcement("montcornet-air-pressure", .guderianAI, "Turns 4-5", "Luftwaffe reaction", "Enter if French armor still holds a road objective.", "Air pressure"),
        ],
        outcomeBands: [
            outcome("montcornet-decisive", .decisive, 9...10, "The raid badly disrupts German columns and French armor withdraws intact."),
            outcome("montcornet-operational", .operational, 6...8, "German road assets are damaged before the French force disengages under pressure."),
            outcome("montcornet-marginal", .marginal, 3...5, "Some disruption is achieved, but armor losses limit the effect."),
            outcome("montcornet-historical", .historicalPressure, 0...2, "German reaction blunts the raid before it changes tempo."),
        ]
    )

    private static let amiensAbbeville = ScenarioBalanceProfile(
        id: .amiensAbbeville,
        targetTurns: 5...7,
        balanceIntent: "The Channel race should be tense and mostly unwinnable positionally, with player success measured by bridge delay and evacuation time.",
        playerWinCondition: "Hold or demolish enough Somme crossings to buy at least three turns before the Channel cut completes.",
        germanPressureLimit: "German armor can move fast, but each contested bridge or roadblock must cost an order window before exit scoring.",
        scoreChannels: [
            score("amiens-bridge-delay", "Somme bridge delay", .player, 4, "Turns 1-4", "Award for contested or demolished crossings."),
            score("amiens-roadblocks", "Roadblock time", .player, 2, "Turns 2-5", "Award for keeping Allied blocking detachments on road hubs."),
            score("amiens-evacuation-time", "Evacuation time bought", .player, 4, "Each turn before Channel cut", "Award for each turn the German Channel exit remains incomplete."),
            score("amiens-force-preservation", "Blocking force preservation", .player, 2, "Scenario end", "Award if a British or French blocking element withdraws."),
            score("amiens-channel-cut", "Channel cut", .guderianAI, 7, "Scenario end", "German score for controlling Amiens, Abbeville, and the Channel exit."),
        ],
        pacingRules: [
            pacing("amiens-opening-race", "Opening race", "Turn 1", "German armor pressures Amiens but must spend orders into contested bridges."),
            pacing("amiens-bridge-cost", "Bridge cost", "Turns 2-4", "Each contested crossing cancels one German exit-scoring attempt."),
            pacing("amiens-evacuation-shift", "Evacuation shift", "Turns 4-7", "After Abbeville is threatened, player scoring shifts to time bought and force preservation."),
        ],
        reinforcements: [
            reinforcement("amiens-2nd-panzer-pressure", .guderianAI, "Turns 3-4", "2nd Panzer Abbeville thrust", "Enter after Amiens road hub is German-controlled.", "Channel exit"),
        ],
        outcomeBands: [
            outcome("amiens-decisive", .decisive, 10...12, "The Channel cut is delayed long enough to materially aid northern Allied evacuation."),
            outcome("amiens-operational", .operational, 7...9, "German armor reaches the Channel, but bridge delays cost valuable time."),
            outcome("amiens-marginal", .marginal, 4...6, "Roadblocks buy local time before the cut is complete."),
            outcome("amiens-historical", .historicalPressure, 0...3, "XIX Corps completes the Channel dash near historical tempo."),
        ]
    )

    private static let boulogne = ScenarioBalanceProfile(
        id: .boulogne,
        targetTurns: 5...7,
        balanceIntent: "Boulogne is a short evacuation-defense battle: the player should feel the port collapsing while still having meaningful windows for embarkation, naval fire, and demolition.",
        playerWinCondition: "Embark at least two formations or evacuation markers, use naval support once, and deny the harbor before German final assault scoring.",
        germanPressureLimit: "German armor cannot both isolate the old town and close the harbor before destroyer support has one entry window.",
        scoreChannels: [
            score("boulogne-evacuation", "Harbor evacuation", .player, 5, "Turns 2-5", "Award for embarked formations while the harbor remains open."),
            score("boulogne-naval-support", "Naval support", .player, 2, "Any player turn", "Award if destroyer fire pins a German assault order."),
            score("boulogne-port-denial", "Port denial", .player, 3, "Scenario end", "Award if demolition teams deny port facilities after evacuation."),
            score("boulogne-old-town-delay", "Old-town delay", .player, 2, "Turns 1-4", "Award for keeping Haute Ville contested."),
            score("boulogne-german-harbor", "German harbor capture", .guderianAI, 6, "Scenario end", "German score for controlling harbor and old-town objectives."),
        ],
        pacingRules: [
            pacing("boulogne-destroyer-window", "Destroyer entry window", "Turns 2-3", "Naval support can enter before air pressure reaches maximum."),
            pacing("boulogne-harbor-capacity", "Harbor capacity", "Turns 2-5", "Each air-pressure marker reduces but does not erase embarkation capacity."),
            pacing("boulogne-final-collapse", "Final collapse", "Turns 5-7", "German final assault targets demolition and harbor control."),
        ],
        reinforcements: [
            reinforcement("boulogne-destroyers", .player, "Turns 2-3", "Royal Navy destroyer support", "Enter while harbor is open or contested.", "Naval support"),
            reinforcement("boulogne-air-pressure", .guderianAI, "Turns 3-4", "Luftwaffe harbor pressure", "Enter after destroyer support or first evacuation score.", "Evacuation disruption"),
        ],
        outcomeBands: [
            outcome("boulogne-decisive", .decisive, 10...12, "Troops are evacuated, destroyers affect the battle, and the port is denied before collapse."),
            outcome("boulogne-operational", .operational, 7...9, "The harbor evacuation succeeds under heavy pressure."),
            outcome("boulogne-marginal", .marginal, 4...6, "Some evacuation or denial succeeds before German control."),
            outcome("boulogne-historical", .historicalPressure, 0...3, "The port falls with little time bought."),
        ]
    )

    private static let calais = ScenarioBalanceProfile(
        id: .calais,
        targetTurns: 6...8,
        balanceIntent: "Calais rewards strategic delay over survival: every held layer should matter because it fixes German armor away from Dunkirk.",
        playerWinCondition: "Hold an inner perimeter or supply point long enough to score at least four Dunkirk-time points before the citadel/docks fall.",
        germanPressureLimit: "German attacks can be costly and strong, but supply pressure should not remove all defensive fire before turn 3.",
        scoreChannels: [
            score("calais-strategic-delay", "Dunkirk time bought", .player, 5, "Each turn before inner dock collapse", "Award for fixing German forces at Calais."),
            score("calais-layered-defense", "Layered defense", .player, 3, "Turns 1-5", "Award for each perimeter layer held or contested."),
            score("calais-supply-preserved", "Supply preserved", .player, 2, "Scenario end", "Award if at least one supply or command point remains active."),
            score("calais-costly-attacks", "Costly German attacks", .player, 2, "Any assault turn", "Award for damaging or pinning German assault support."),
            score("calais-german-reduction", "Port reduced", .guderianAI, 7, "Scenario end", "German score for citadel and docks control."),
        ],
        pacingRules: [
            pacing("calais-opening-investment", "Opening investment", "Turns 1-2", "German movement and suppression invest the perimeter before all-out assault."),
            pacing("calais-supply-degrades", "Supply degrades", "Turns 3-6", "Each lost layer worsens supply but does not erase all defense."),
            pacing("calais-final-siege", "Final siege", "Turns 6-8", "German attacks focus citadel and docks to end delay scoring."),
        ],
        reinforcements: [
            reinforcement("calais-german-assault", .guderianAI, "Turns 4-5", "German concentrated assault group", "Enter after supply pressure or an outer perimeter break.", "Siege reduction"),
        ],
        outcomeBands: [
            outcome("calais-decisive", .decisive, 10...12, "The garrison fixes German armor long enough to materially support Dunkirk."),
            outcome("calais-operational", .operational, 7...9, "Layered defenses buy meaningful strategic time."),
            outcome("calais-marginal", .marginal, 4...6, "The siege costs German time but supply collapse limits resistance."),
            outcome("calais-historical", .historicalPressure, 0...3, "Calais falls with little strategic delay beyond historical pressure."),
        ]
    )

    private static let dunkirk = ScenarioBalanceProfile(
        id: .dunkirk,
        targetTurns: 7...9,
        balanceIntent: "Dunkirk is an evacuation-management scenario with command-scope caveats: success is measured by formations embarked and rear-guard time bought.",
        playerWinCondition: "Evacuate at least four formations while keeping one canal or harbor gate contested through the midgame.",
        germanPressureLimit: "Air pressure can reduce capacity but should leave at least one player-controlled evacuation action each early turn.",
        scoreChannels: [
            score("dunkirk-evacuated-formations", "Evacuated formations", .player, 7, "Each open beach turn", "Award for formations embarked from beach or harbor sectors."),
            score("dunkirk-canal-line", "Canal line held", .player, 3, "Turns 1-5", "Award for keeping canal gates contested."),
            score("dunkirk-rearguard-time", "Rear-guard time bought", .player, 3, "Turns 3-8", "Award for isolated rear guards holding pressure away from beaches."),
            score("dunkirk-command-caveat", "Command caveat honored", .player, 1, "Scenario briefing", "Award for keeping the scenario framed as Guderian-adjacent campaign pressure."),
            score("dunkirk-german-compression", "Perimeter compressed", .guderianAI, 7, "Scenario end", "German score for reducing evacuation capacity and controlling harbor/canal objectives."),
        ],
        pacingRules: [
            pacing("dunkirk-evacuation-floor", "Evacuation floor", "Turns 1-3", "Air pressure cannot reduce evacuation capacity below one action."),
            pacing("dunkirk-canal-breach", "Canal breach", "Turns 3-6", "Each breached canal gate lowers future capacity."),
            pacing("dunkirk-final-shrink", "Final shrink", "Turns 6-9", "German pressure compresses harbor and beach sectors."),
        ],
        reinforcements: [
            reinforcement("dunkirk-air-pressure", .guderianAI, "Turns 2-5", "German air pressure", "Enter against open beach sectors.", "Evacuation disruption"),
            reinforcement("dunkirk-rearguard", .player, "Turns 3-4", "Rear-guard detachments", "Enter if a canal gate is threatened.", "Delay"),
        ],
        outcomeBands: [
            outcome("dunkirk-decisive", .decisive, 12...14, "Large evacuation succeeds and rear guards keep the perimeter coherent."),
            outcome("dunkirk-operational", .operational, 8...11, "Most evacuation goals are met under heavy pressure."),
            outcome("dunkirk-marginal", .marginal, 4...7, "Some formations escape but perimeter collapse reduces capacity."),
            outcome("dunkirk-historical", .historicalPressure, 0...3, "German pressure overwhelms the perimeter faster than expected."),
        ]
    )

    private static let fallRot = ScenarioBalanceProfile(
        id: .fallRot,
        targetTurns: 6...8,
        balanceIntent: "Fall Rot is an operational retreat-and-delay chain: the player should score by forcing crossings, congestion, fortress stands, and withdrawals before encirclement closes.",
        playerWinCondition: "Deny at least two crossings or congestion points and extract at least three French assets before the Vosges trap closes.",
        germanPressureLimit: "Panzergruppe Guderian should be fast, but each demolition or fortress stand must consume a real order window.",
        scoreChannels: [
            score("fallrot-bridge-denial", "Bridge and canal denial", .player, 4, "Turns 1-4", "Award for destroyed or contested crossings."),
            score("fallrot-fortress-stand", "Fortress-town stand", .player, 3, "Turns 4-7", "Award for holding Belfort or Epinal contested."),
            score("fallrot-retreat-corridor", "Retreat corridor preservation", .player, 4, "Turns 5-8", "Award for extracting units through the Vosges route."),
            score("fallrot-congestion", "Panzer congestion", .player, 2, "Any German turn", "Award when demolition or fuel denial forces German congestion."),
            score("fallrot-german-linkup", "German Swiss-border linkup", .guderianAI, 8, "Scenario end", "German score for border cut and Army Group C link-up."),
        ],
        pacingRules: [
            pacing("fallrot-crossing-window", "Crossing window", "Turns 1-3", "French demolition can meaningfully delay crossings before engineers arrive."),
            pacing("fallrot-exploitation", "Exploitation pressure", "Turns 3-6", "German speed grows if crossings are clear."),
            pacing("fallrot-preservation-shift", "Preservation shift", "Turns 5-8", "Once Belfort or Epinal is threatened, player scoring shifts to exits."),
        ],
        reinforcements: [
            reinforcement("fallrot-german-engineers", .guderianAI, "Turns 2-3", "German bridge engineers", "Enter after a crossing is denied.", "Bridge repair"),
            reinforcement("fallrot-army-group-c", .guderianAI, "Turns 5-6", "Army Group C link-up pressure", "Enter once Belfort or the Swiss-border marker is German-controlled.", "Encirclement"),
        ],
        outcomeBands: [
            outcome("fallrot-decisive", .decisive, 11...13, "French defenders force major crossing delays and escape before the trap closes."),
            outcome("fallrot-operational", .operational, 8...10, "Fortress stands and demolitions slow the drive while some forces withdraw."),
            outcome("fallrot-marginal", .marginal, 4...7, "Local delays occur but the retreat corridor narrows quickly."),
            outcome("fallrot-historical", .historicalPressure, 0...3, "Panzergruppe Guderian reaches the encirclement line near historical tempo."),
        ]
    )

    private static let bialystokMinsk = ScenarioBalanceProfile(
        id: .bialystokMinsk,
        targetTurns: 7...9,
        balanceIntent: "Bialystok-Minsk should be an encirclement-survival scenario where the player cannot stop Barbarossa outright but can save command assets, open lanes, and delay pincer closure.",
        playerWinCondition: "Open one breakout route, preserve at least two command or army assets, and delay one German pincer marker before pocket attrition peaks.",
        germanPressureLimit: "The double envelopment should close if ignored, but mechanized counterattacks must be able to delay one pincer without being immediately erased.",
        scoreChannels: [
            score("bialystok-breakout-lanes", "Breakout lanes opened", .player, 5, "Turns 2-7", "Award for road or rail routes kept open long enough to exit trapped units."),
            score("bialystok-command-preserved", "Command preserved", .player, 3, "Scenario end", "Award for command posts reaching Minsk communications."),
            score("bialystok-pincer-delay", "Pincer delayed", .player, 3, "Turns 2-5", "Award for mechanized counterattack or crossing defense delaying a pincer marker."),
            score("bialystok-army-assets", "Army assets extracted", .player, 3, "Turns 5-9", "Award for rifle army or artillery groups leaving pocket zones."),
            score("bialystok-german-pocket", "Pockets closed", .guderianAI, 8, "Scenario end", "German score for closing Bialystok and Novogrudok/Minsk pockets."),
        ],
        pacingRules: [
            pacing("bialystok-opening-shock", "Opening shock", "Turn 1", "German pincer movement is strong, but Soviet command still acts before full pocket attrition."),
            pacing("bialystok-counterattack-window", "Counterattack window", "Turns 2-4", "Mechanized groups can delay one pincer but gain fuel-low markers."),
            pacing("bialystok-pocket-attrition", "Pocket attrition", "Turns 4-8", "Each closed route increases attrition and reduces future exits."),
            pacing("bialystok-minsk-race", "Minsk race", "Turns 5-9", "Command assets must reach road/rail objectives before link-up closes."),
        ],
        reinforcements: [
            reinforcement("bialystok-boldin-group", .player, "Turns 2-3", "Mechanized counterattack group", "Enter when either pincer marker reaches a pocket road.", "Pincer delay"),
            reinforcement("bialystok-german-infantry", .guderianAI, "Turns 5-6", "German infantry army pocket-reduction pressure", "Enter after pincer markers close or two routes are cut.", "Pocket reduction"),
        ],
        outcomeBands: [
            outcome("bialystok-decisive", .decisive, 12...14, "A meaningful breakout preserves command and several formations before the pockets collapse."),
            outcome("bialystok-operational", .operational, 8...11, "Some command and army assets escape despite German encirclement."),
            outcome("bialystok-marginal", .marginal, 4...7, "One escape lane opens briefly, but pocket attrition is severe."),
            outcome("bialystok-historical", .historicalPressure, 0...3, "German pincer closure destroys most Western Front formations."),
        ]
    )

    private static let smolensk = ScenarioBalanceProfile(
        id: .smolensk,
        targetTurns: 8...10,
        balanceIntent: "Smolensk should feel like an operational delay and breakout fight: the player can lose the city and still succeed by forcing German logistics strain, counterattacking pincer shoulders, and extracting trapped armies.",
        playerWinCondition: "Keep at least one river crossing contested through the early game, open the Yartsevo corridor, and exit two army assets before pocket attrition peaks.",
        germanPressureLimit: "German pincer closure should be dangerous, but reserve counterstrokes and crossing defense must each delay one German tempo step if executed on time.",
        scoreChannels: [
            score("smolensk-crossing-delay", "Dnieper and Dvina delay", .player, 4, "Turns 1-4", "Award for contested or blocked river crossings."),
            score("smolensk-yartsevo-escape", "Yartsevo escape lane", .player, 5, "Turns 3-9", "Award for exiting trapped army assets through the Moscow-road corridor."),
            score("smolensk-reserve-counterstroke", "Reserve counterstrokes", .player, 3, "Turns 2-6", "Award if reserve armies delay a pincer shoulder."),
            score("smolensk-supply-strain", "German supply strain", .player, 3, "Any German turn", "Award when crossing delay or counterattacks create supply-strain markers."),
            score("smolensk-german-pocket", "Pocket closed", .guderianAI, 8, "Scenario end", "German score for cutting Yartsevo and reducing the Smolensk pocket."),
        ],
        pacingRules: [
            pacing("smolensk-river-window", "River-defense window", "Turns 1-2", "German armor can force bridgeheads but cannot both close the pocket and clear all crossing defenders."),
            pacing("smolensk-counterstroke-window", "Counterstroke window", "Turns 2-5", "Reserve armies can delay a pincer shoulder once before disruption penalties apply."),
            pacing("smolensk-pocket-attrition", "Pocket attrition", "Turns 4-8", "Each closed route raises attrition but Yartsevo can still exit one asset if contested."),
            pacing("smolensk-logistics-choice", "Logistics choice", "Turns 5+", "German AI with two strain markers must slow either pincer closure or bridgehead reinforcement."),
        ],
        reinforcements: [
            reinforcement("smolensk-reserve-armies", .player, "Turns 2-3", "Stavka reserve counterattack armies", "Enter after a German pincer marker controls a crossing approach.", "Counterstroke"),
            reinforcement("smolensk-german-infantry", .guderianAI, "Turns 5-6", "German infantry pocket-reduction armies", "Enter after a pocket marker is closed or Yartsevo is threatened.", "Pocket reduction"),
        ],
        outcomeBands: [
            outcome("smolensk-decisive", .decisive, 12...15, "The Soviet defense forces serious delay and extracts several armies before the pocket collapses."),
            outcome("smolensk-operational", .operational, 8...11, "Crossing delays and counterstrokes slow the German advance while some trapped forces escape."),
            outcome("smolensk-marginal", .marginal, 4...7, "The pocket narrows, but one escape or logistics success buys time."),
            outcome("smolensk-historical", .historicalPressure, 0...3, "German pincer closure proceeds near historical pressure with limited Soviet extraction."),
        ]
    )

    private static let roslavlNovozybkov = ScenarioBalanceProfile(
        id: .roslavlNovozybkov,
        targetTurns: 6...8,
        balanceIntent: "Roslavl-Novozybkov is a spoiling-offensive puzzle: Soviet attacks should be able to damage tempo and columns, but overcommitted tanks can be trapped by German counterpressure.",
        playerWinCondition: "Reveal the German southward-turn screen, disrupt at least two road or supply objectives, and withdraw one tank group intact.",
        germanPressureLimit: "German counterpressure should punish lingering attacks, but not before the player has a real raid-and-withdrawal window.",
        scoreChannels: [
            score("roslavl-intel-reveal", "Southward turn revealed", .player, 2, "Turns 1-3", "Award for revealing German operational intent."),
            score("roslavl-column-disruption", "Column disruption", .player, 5, "Turns 2-5", "Award for damaging or contesting supply-column objectives."),
            score("roslavl-tank-preservation", "Tank preservation", .player, 3, "Turns 3-8", "Award if a tank group exits after a raid."),
            score("roslavl-delay-south-turn", "Southward turn delayed", .player, 3, "Scenario end", "Award if German southward-turn tempo is reduced by raid or crossing results."),
            score("roslavl-german-counterpressure", "Counterpressure trap", .guderianAI, 6, "Scenario end", "German score for closing withdrawal lanes and preserving columns."),
        ],
        pacingRules: [
            pacing("roslavl-recon-window", "Recon window", "Turn 1", "Soviet reconnaissance can reveal one German screen before main attacks commit."),
            pacing("roslavl-raid-window", "Raid window", "Turns 2-4", "Soviet tanks can score against columns before German counterpressure peaks."),
            pacing("roslavl-withdrawal-choice", "Withdrawal choice", "Turns 4-7", "Attack groups must choose between a second disruption and preservation scoring."),
            pacing("roslavl-counterpressure-escalation", "Counterpressure escalation", "Turns 5+", "German counterattacks close roads only after a Soviet raid or delayed withdrawal."),
        ],
        reinforcements: [
            reinforcement("roslavl-soviet-tanks", .player, "Turns 2-3", "Soviet tank raid groups", "Enter after intent is revealed or a road-column objective is exposed.", "Spoiling raid"),
            reinforcement("roslavl-german-counterpressure", .guderianAI, "Turns 4-5", "German counterpressure group", "Enter after a Soviet tank group scores or remains on a road objective.", "Trap response"),
        ],
        outcomeBands: [
            outcome("roslavl-decisive", .decisive, 10...13, "The spoiling offensive disrupts the southward turn and preserves mobile reserves."),
            outcome("roslavl-operational", .operational, 7...9, "German tempo is slowed, though Soviet attack groups take losses."),
            outcome("roslavl-marginal", .marginal, 4...6, "A local raid succeeds before German counterpressure closes in."),
            outcome("roslavl-historical", .historicalPressure, 0...3, "German columns absorb the offensive and continue the operational turn."),
        ]
    )

    private static let kiev = ScenarioBalanceProfile(
        id: .kiev,
        targetTurns: 8...10,
        balanceIntent: "Kiev is a large pocket scenario where the player is rewarded for command evacuation, corridor defense, and breakout operations rather than an ahistorical full halt of the pincers.",
        playerWinCondition: "Evacuate at least two command or artillery-control assets, keep one eastern corridor contested, and delay pincer link-up for two turns.",
        germanPressureLimit: "The pincer link-up should close if ignored, but command evacuation must be possible before the pocket fully seals.",
        scoreChannels: [
            score("kiev-command-evacuation", "Command evacuation", .player, 5, "Turns 2-8", "Award for headquarters and artillery-control assets exiting through the eastern corridor."),
            score("kiev-corridor-held", "Eastern corridor held", .player, 4, "Turns 2-7", "Award for keeping the closure corridor controlled or contested."),
            score("kiev-pincer-delay", "Pincer link-up delayed", .player, 3, "Turns 3-6", "Award for delaying northern or southern pincer markers."),
            score("kiev-breakout-operations", "Breakout operations", .player, 4, "Turns 5-10", "Award for exiting trapped rifle army assets after closure pressure begins."),
            score("kiev-german-encirclement", "Kiev pocket closed", .guderianAI, 9, "Scenario end", "German score for pincer link-up and pocket reduction."),
        ],
        pacingRules: [
            pacing("kiev-evacuation-window", "Evacuation window", "Turns 1-3", "Command posts can move before both pincer markers threaten closure."),
            pacing("kiev-northern-pressure", "Northern pressure", "Turns 2-5", "2nd Panzer Group narrows one corridor after reaching the eastern closure line."),
            pacing("kiev-linkup-clock", "Link-up clock", "Turns 4-7", "Once both pincer markers are active, closure advances every turn unless delayed."),
            pacing("kiev-breakout-shift", "Breakout shift", "Turns 6-10", "After link-up pressure, scoring shifts from position defense to breakout and command preservation."),
        ],
        reinforcements: [
            reinforcement("kiev-soviet-breakout", .player, "Turns 5-6", "Soviet breakout groups", "Enter if an eastern corridor remains contested.", "Breakout operation"),
            reinforcement("kiev-german-infantry", .guderianAI, "Turns 6-7", "German infantry pocket-reduction armies", "Enter after pincer link-up or two closure objectives are German-controlled.", "Pocket reduction"),
        ],
        outcomeBands: [
            outcome("kiev-decisive", .decisive, 13...16, "Command assets escape and multiple formations break out before the pocket is reduced."),
            outcome("kiev-operational", .operational, 9...12, "The pocket closes, but command evacuation and corridor defense save meaningful combat power."),
            outcome("kiev-marginal", .marginal, 5...8, "Some assets escape while the encirclement develops."),
            outcome("kiev-historical", .historicalPressure, 0...4, "The encirclement traps most assets and command evacuation fails."),
        ]
    )

    private static let bryansk = ScenarioBalanceProfile(
        id: .bryansk,
        targetTurns: 7...9,
        balanceIntent: "Bryansk should bridge Kiev and Moscow: German tempo is strong, but Soviet success comes from delaying pockets, preserving the Tula road, and forcing autumn logistics strain.",
        playerWinCondition: "Keep Bryansk or a pocket exit contested through the midgame, deny German exit scoring on the Orel-Tula road, and trigger at least one autumn-friction check.",
        germanPressureLimit: "German armor can seize road depth quickly, but must not both close all pockets and exit toward Tula before Soviet roadblocks and friction act.",
        scoreChannels: [
            score("bryansk-pocket-delay", "Pocket delay", .player, 4, "Turns 2-7", "Award for keeping 13th or 3rd Army pocket groups active."),
            score("bryansk-rail-command", "Rail and command preservation", .player, 3, "Turns 1-6", "Award if Bryansk rail or command assets remain active long enough to support exits."),
            score("bryansk-tula-road", "Tula road protected", .player, 5, "Turns 4-9", "Award if the Orel-Tula road remains Soviet-contested or blocked."),
            score("bryansk-autumn-friction", "Autumn friction forced", .player, 3, "Any German turn", "Award when German armor outruns rail or infantry support."),
            score("bryansk-german-typhoon", "Typhoon breakthrough", .guderianAI, 8, "Scenario end", "German score for controlling Bryansk, Orel, and a Tula-road exit."),
        ],
        pacingRules: [
            pacing("bryansk-surprise-axis", "Surprise axis", "Turn 1", "German armor can advance fast but cannot reduce a pocket in the same opening move."),
            pacing("bryansk-pocket-clock", "Pocket clock", "Turns 3-7", "Pocket attrition increases after Bryansk or Orel falls."),
            pacing("bryansk-roadblock-window", "Roadblock window", "Turns 3-5", "Soviet roadblocks can deny one Orel-Tula exit before German infantry arrives."),
            pacing("bryansk-friction-window", "Friction window", "Turns 5+", "German exploitation beyond support triggers autumn supply checks."),
        ],
        reinforcements: [
            reinforcement("bryansk-soviet-roadblocks", .player, "Turns 3-4", "Orel-Tula roadblock detachments", "Enter after Orel is threatened or the unexpected axis is revealed.", "Tula road guard"),
            reinforcement("bryansk-german-infantry", .guderianAI, "Turns 4-5", "German infantry pocket-reduction columns", "Enter after Bryansk is German-controlled or a pocket route is cut.", "Pocket reduction"),
        ],
        outcomeBands: [
            outcome("bryansk-decisive", .decisive, 12...15, "Soviet forces preserve the Tula road and keep pockets fighting long enough to damage Typhoon tempo."),
            outcome("bryansk-operational", .operational, 8...11, "Bryansk is pressured, but roadblocks and friction slow the southern approach."),
            outcome("bryansk-marginal", .marginal, 4...7, "Some pocket delay occurs before Orel and Tula-road pressure build."),
            outcome("bryansk-historical", .historicalPressure, 0...3, "German forces seize Bryansk and Orel with little delay to the Tula axis."),
        ]
    )

    private static let mtsensk = ScenarioBalanceProfile(
        id: .mtsensk,
        targetTurns: 5...7,
        balanceIntent: "Mtsensk is a compact armored showcase: Soviet T-34/KV ambushes should feel sharp and surprising, but the player still has to preserve scarce tanks after the first German shock fades.",
        playerWinCondition: "Score at least two German tank-loss or immobilization results, keep the Tula road delayed, and withdraw one elite tank group before final German artillery pressure.",
        germanPressureLimit: "German armor can recover after the first ambush, but unsupported panzer assaults should be punished and early player armor should not be wiped before revealing from cover.",
        scoreChannels: [
            score("mtsensk-panzer-losses", "German tank losses", .player, 5, "Ambush turns", "Award for destroying, immobilizing, or pinning German spearhead vehicles."),
            score("mtsensk-t34-shock", "T-34/KV shock", .player, 3, "First reveal", "Award when Soviet armor cancels unsupported German armor pressure."),
            score("mtsensk-tula-road-delay", "Tula road delayed", .player, 3, "Scenario end", "Award if the German force fails to make a clean road exit toward Tula."),
            score("mtsensk-guards-preserved", "Guards tanks preserved", .player, 3, "Turns 4-7", "Award for withdrawing one tank group after it scores an ambush."),
            score("mtsensk-german-road", "Road reopened", .guderianAI, 6, "Scenario end", "German score for clearing the road, ridge cover, and Tula exit."),
        ],
        pacingRules: [
            pacing("mtsensk-hidden-start", "Hidden start", "Turn 1", "Soviet tank groups begin concealed; German opening pressure is movement and recon, not full assault."),
            pacing("mtsensk-ambush-window", "Ambush window", "Turns 2-3", "T-34/KV groups can score high-value ambush results before German caution markers stack."),
            pacing("mtsensk-withdrawal-choice", "Withdrawal choice", "Turns 4-6", "Revealed Soviet tanks must choose between a second attack and preservation scoring."),
            pacing("mtsensk-german-adaptation", "German adaptation", "Turns 4+", "German artillery, flank probes, and cautious movement reduce repeated ambush certainty."),
        ],
        reinforcements: [
            reinforcement("mtsensk-lavrinenko-platoon", .player, "Turns 2-3", "Lavrinenko-style tank platoon", "Enter from a concealed ridge after German armor reaches the kill zone.", "Mobile kill team"),
            reinforcement("mtsensk-german-artillery", .guderianAI, "Turns 4-5", "German artillery and air pressure", "Enter after an ambush lane is revealed.", "Ambush suppression"),
        ],
        outcomeBands: [
            outcome("mtsensk-decisive", .decisive, 12...14, "Katukov's force wrecks the panzer lead and preserves tanks for the Tula defense."),
            outcome("mtsensk-operational", .operational, 8...11, "The ambush delays the road and inflicts real panzer losses, though German pressure recovers."),
            outcome("mtsensk-marginal", .marginal, 4...7, "Some German armor is blunted before Soviet tanks are forced back."),
            outcome("mtsensk-historical", .historicalPressure, 0...3, "German forces absorb the ambush and reopen the road with limited delay."),
        ]
    )

    private static let moscowTulaKashira = ScenarioBalanceProfile(
        id: .moscowTulaKashira,
        targetTurns: 8...10,
        balanceIntent: "Turn the full southern Moscow approach into an exhaustion chain where Bryansk/Mtsensk delay, Tula city defense, Venev/Kashira bypass denial, and late counteroffensive timing all matter.",
        playerWinCondition: "Hold or contest Tula, deny the Kashira bypass, trigger at least two German exhaustion checks, and launch a mobile counterstroke before the final turn.",
        germanPressureLimit: "German armor must choose between road speed, Tula assault, and Kashira bypass; winter attrition should punish overextension without stopping all attacks.",
        scoreChannels: [
            score("moscow-hold-tula", "Hold Tula", .player, 6, "Scenario end", "Award if Tula remains controlled or contested."),
            score("moscow-kashira-road", "Deny Kashira road", .player, 4, "Turns 4-10", "Award if German spearheads do not exit through Venev and Kashira."),
            score("moscow-exhaustion", "German exhaustion checks", .player, 4, "Any German turn", "Award up to four points when German units suffer supply strain or winter movement penalties."),
            score("moscow-counterattack", "Counterattack timing", .player, 4, "Turns 5-10", "Award if Soviet mobile reserves damage, pin, or drive back a German spearhead after it outruns infantry support."),
            score("moscow-mordves-driveback", "Mordves drive-back", .player, 2, "Final counteroffensive", "Award if late reserves force a German fallback from the Kashira axis."),
            score("moscow-german-breakthrough", "Southern breakthrough", .guderianAI, 7, "Scenario end", "German score for controlling Tula or exiting toward Kashira."),
        ],
        pacingRules: [
            pacing("moscow-road-speed", "Road speed temptation", "Turns 1-3", "German armor moves best on road elements but becomes vulnerable to planned ambush points."),
            pacing("moscow-supply-friction", "Supply friction", "Turns 3+", "Each German turn with spearheads beyond infantry support adds an exhaustion marker."),
            pacing("moscow-venev-branch", "Venev branch", "Turns 4-6", "German AI can shift toward Kashira only if Tula remains contested and exhaustion remains manageable."),
            pacing("moscow-winter-attrition", "Winter attrition", "Turns 5+", "German assaults after repeated exhaustion checks suffer morale or movement pressure."),
            pacing("moscow-counteroffensive-window", "Counteroffensive window", "Turns 6-10", "Soviet reserves should arrive while German pressure is still dangerous, not after it has already collapsed."),
        ],
        reinforcements: [
            reinforcement("moscow-soviet-armor", .player, "Turns 5-6", "Soviet reserve armor counterattack", "Enter when a German spearhead controls a road objective or has two exhaustion markers.", "Counterattack"),
            reinforcement("moscow-belov-getman", .player, "Turns 5-7", "Belov/Getman mobile reserve", "Enter if the Venev-Kashira axis is threatened or a German spearhead has two exhaustion markers.", "Kashira counterstroke"),
            reinforcement("moscow-ski-cavalry", .player, "Turns 6-7", "Mobile winter reserve", "Enter if Tula remains contested.", "Flank pressure"),
            reinforcement("moscow-german-infantry", .guderianAI, "Turns 3-4", "German infantry follow-up", "Enter if panzer units hold the Orel-Tula road.", "Assault support"),
            reinforcement("moscow-german-venev-column", .guderianAI, "Turns 4-5", "German Venev bypass column", "Enter if Tula remains contested and the Orel-Tula road is open.", "Bypass pressure"),
        ],
        outcomeBands: [
            outcome("moscow-decisive", .decisive, 16...20, "Tula holds, Kashira is denied, and German armor is driven back by a timed counteroffensive."),
            outcome("moscow-operational", .operational, 11...15, "The Soviet defense holds the city while German pressure slows under winter, supply strain, and reserve counterattacks."),
            outcome("moscow-marginal", .marginal, 5...10, "The city or bypass route is contested and both sides are badly worn down."),
            outcome("moscow-historical", .historicalPressure, 0...4, "German pressure reaches dangerous depth before the Soviet defense stabilizes."),
        ]
    )

    private static func generic(for scenario: GuderianScenario) -> ScenarioBalanceProfile {
        ScenarioBalanceProfile(
            id: scenario.id,
            targetTurns: 5...7,
            balanceIntent: "Placeholder balance profile until this battle receives detailed scenario tuning.",
            playerWinCondition: scenario.objectives.first?.description ?? scenario.designIntent,
            germanPressureLimit: "Prevent early no-agency collapses by keeping the first German turn focused on movement pressure.",
            scoreChannels: scenario.objectives.map {
                score("\(scenario.id.rawValue)-\($0.name)", $0.name, .player, $0.victoryPoints, "Scenario end", $0.description)
            },
            pacingRules: [
                pacing("\(scenario.id.rawValue)-opening", "Opening pressure cap", "Turn 1", "German AI starts with movement or suppression before assault resolution."),
            ],
            reinforcements: [],
            outcomeBands: [
                outcome("\(scenario.id.rawValue)-tactical", .tactical, 4...8, "The player achieves the main local scenario goal."),
                outcome("\(scenario.id.rawValue)-historical", .historicalPressure, 0...3, "The battle follows historical German pressure."),
            ]
        )
    }
}

private func score(
    _ id: String,
    _ name: String,
    _ side: ScenarioScoringSide,
    _ victoryPoints: Int,
    _ timing: String,
    _ description: String
) -> ScenarioScoreChannel {
    ScenarioScoreChannel(id: id, name: name, side: side, victoryPoints: victoryPoints, timing: timing, description: description)
}

private func pacing(_ id: String, _ name: String, _ turnWindow: String, _ effect: String) -> ScenarioPacingRule {
    ScenarioPacingRule(id: id, name: name, turnWindow: turnWindow, effect: effect)
}

private func reinforcement(
    _ id: String,
    _ side: ScenarioUnitSide,
    _ turnWindow: String,
    _ unitName: String,
    _ entryCondition: String,
    _ role: String
) -> ScenarioReinforcement {
    ScenarioReinforcement(id: id, side: side, turnWindow: turnWindow, unitName: unitName, entryCondition: entryCondition, role: role)
}

private func outcome(_ id: String, _ grade: VictoryBand, _ scoreRange: ClosedRange<Int>, _ summary: String) -> ScenarioOutcomeBand {
    ScenarioOutcomeBand(id: id, grade: grade, scoreRange: scoreRange, summary: summary)
}
