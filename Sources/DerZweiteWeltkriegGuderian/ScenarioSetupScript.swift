import Foundation

public enum ScenarioUnitSide: String, Codable, Hashable, Sendable {
    case player = "Player"
    case guderianAI = "Guderian AI"
}

public struct ScenarioUnitCard: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioUnitSide
    public let role: String
    public let historicalNote: String

    public init(id: String, name: String, side: ScenarioUnitSide, role: String, historicalNote: String) {
        self.id = id
        self.name = name
        self.side = side
        self.role = role
        self.historicalNote = historicalNote
    }
}

public struct ScenarioTrigger: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let condition: String
    public let effect: String

    public init(id: String, name: String, condition: String, effect: String) {
        self.id = id
        self.name = name
        self.condition = condition
        self.effect = effect
    }
}

public struct TutorialStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let instruction: String

    public init(id: String, title: String, instruction: String) {
        self.id = id
        self.title = title
        self.instruction = instruction
    }
}

public struct ScenarioSetupScript: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let playerBriefing: String
    public let guderianBriefing: String
    public let units: [ScenarioUnitCard]
    public let triggers: [ScenarioTrigger]
    public let tutorialSteps: [TutorialStep]

    public init(
        id: GuderianBattleID,
        playerBriefing: String,
        guderianBriefing: String,
        units: [ScenarioUnitCard],
        triggers: [ScenarioTrigger],
        tutorialSteps: [TutorialStep] = []
    ) {
        self.id = id
        self.playerBriefing = playerBriefing
        self.guderianBriefing = guderianBriefing
        self.units = units
        self.triggers = triggers
        self.tutorialSteps = tutorialSteps
    }

    public var playerUnits: [ScenarioUnitCard] {
        units.filter { $0.side == .player }
    }

    public var guderianUnits: [ScenarioUnitCard] {
        units.filter { $0.side == .guderianAI }
    }
}

public enum ScenarioSetupCatalog {
    public static func setup(for scenario: GuderianScenario) -> ScenarioSetupScript {
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

    private static let tucholaForest = ScenarioSetupScript(
        id: .tucholaForest,
        playerBriefing: "Delay XIX Panzer Corps at the Brda crossings and forest roads, then turn the defense into a disciplined withdrawal toward Bydgoszcz before the German pincer seals the corridor.",
        guderianBriefing: "The German plan drives armor through the forest road net, repairs blocked bridges, uses motorized infantry to fix Polish strongpoints, and converts delay into encirclement once the pincer pressure appears.",
        units: [
            unit("tuchola-9th-infantry", "Polish 9th Infantry Division bridge guards", .player, "Brda crossing defense", "Holds Pruszcz and Pila-Mlyn long enough for demolition teams to work."),
            unit("tuchola-27th-infantry", "Polish 27th Infantry Division counterattack group", .player, "Piecemeal counterattack", "Can hit the Brda bridgehead but suffers command friction if committed too late."),
            unit("tuchola-czersk-group", "Czersk Operational Group detachments", .player, "Forest road defense", "Defends Chojnice and Tuchola road hubs before withdrawal."),
            unit("tuchola-cavalry", "Pomeranian Cavalry Brigade screen", .player, "Reconnaissance disruption", "Covers withdrawal around Krojanty and can cancel a German pursuit order."),
            unit("tuchola-at-guns", "Polish anti-tank gun sections", .player, "Forest choke fire lanes", "Scarce guns that threaten panzers moving through marked road chokepoints."),
            unit("tuchola-demolition-parties", "Brda bridge demolition parties", .player, "Crossing denial", "Convert early bridge defense into German engineer delay."),
            unit("tuchola-3rd-panzer", "German 3rd Panzer Division spearhead", .guderianAI, "Armored breakthrough", "Primary armored pressure along forest roads and bridge approaches."),
            unit("tuchola-motorized-divisions", "German 2nd and 20th Motorized Divisions", .guderianAI, "Infantry pursuit", "Fixes Polish road hubs and supports panzer bridgehead expansion."),
            unit("tuchola-engineers", "German bridge engineers", .guderianAI, "Bridge repair", "Reopens blocked Brda crossings after demolition or artillery pressure."),
            unit("tuchola-pincer", "German pincer pressure from East Prussia", .guderianAI, "Encirclement clock", "Operational pressure marker that forces Polish withdrawal decisions."),
        ],
        triggers: [
            trigger("tuchola-first-contact", "Border contact", "German turn 1 reaches a Brda or Chojnice approach", "Reveal bridge demolition and forest choke objectives."),
            trigger("tuchola-brda-demolition", "Brda bridge demolition", "Polish demolition parties hold Pruszcz or Pila-Mlyn at turn end", "Block that crossing and delay German panzer movement until engineers act."),
            trigger("tuchola-krojanty-screen", "Krojanty cavalry screen", "Pomeranian Cavalry Brigade is committed on turns 2-3", "Cancel one German reconnaissance or pursuit order, then require cavalry withdrawal."),
            trigger("tuchola-pincer-arrival", "Pincer arrival", "German AI controls a bridgehead and the East Prussia marker is active", "Shift scoring emphasis from road defense to Bydgoszcz withdrawal."),
            trigger("tuchola-withdrawal-window", "Bydgoszcz withdrawal window", "Turns 4-7", "Score surviving infantry, cavalry screen, command, and anti-tank units that exit east."),
        ]
    )

    private static let brzescLitewski = ScenarioSetupScript(
        id: .brzescLitewski,
        playerBriefing: "Turn the old fortress, rail line, and improvised garrison into a three-day delay. Hold Brzesc long enough to protect fallback routes, then extract mobile assets before the citadel is isolated.",
        guderianBriefing: "The German plan fixes the town with motorized infantry, drives armor along road and rail approaches, and uses artillery/engineers to isolate the citadel.",
        units: [
            unit("brzesc-plisowski-hq", "Plisowski defense headquarters", .player, "Fortress command", "Improvised command group coordinating three infantry battalions and engineers."),
            unit("brzesc-infantry", "Brzesc infantry battalions", .player, "Urban defense", "Reservists and march battalions holding town and fortress sectors."),
            unit("brzesc-engineers", "Polish engineer battalion", .player, "Fortress works", "Maintains gates, demolitions, and fallback routes inside the fortress."),
            unit("brzesc-armored-trains", "Armored trains PP55 and PP53", .player, "Rail fire support", "Rail-bound support that can cover town defense or withdrawal."),
            unit("brzesc-ft17", "FT-17 training tank companies", .player, "Obsolete armor", "Old tanks used as mobile pillboxes rather than panzer duelists."),
            unit("brzesc-10th-panzer", "German 10th Panzer Division", .guderianAI, "Armored assault", "Panzer force attacking road and fortress approaches."),
            unit("brzesc-3rd-panzer", "German 3rd Panzer Division", .guderianAI, "Encirclement pressure", "Armored pressure that can cut fallback gates."),
            unit("brzesc-20th-motorized", "German 20th Motorized Division", .guderianAI, "Infantry reduction", "Motorized infantry and artillery used to reduce town sectors."),
        ],
        triggers: [
            trigger("brzesc-rail-support", "Rail support", "A Polish armored train controls a rail objective", "Fire support can pin one German approach or cover a fallback."),
            trigger("brzesc-ft17-strongpoint", "FT-17 strongpoint", "Old tanks defend from town or fortress cover", "Ignore one German light-armor breakthrough result before checking isolation."),
            trigger("brzesc-citadel-isolation", "Citadel isolation", "German forces control town and rail approaches", "Shift scoring from town defense to inner-fortress survival and fallback."),
            trigger("brzesc-fallback-gate", "Fallback gate", "Turns 4-7", "Score surviving command, train, and infantry assets that exit through the south gate."),
        ]
    )

    private static let kobryn = ScenarioSetupScript(
        id: .kobryn,
        playerBriefing: "Hold Kobryn as a rearguard, keep Operational Group Polesie coherent, and withdraw the 60th Reserve Infantry before German motorized pressure closes both exits.",
        guderianBriefing: "The German plan uses the 2nd Motorized Infantry Division to fix Kobryn, threaten both eastern exits, and turn an inconclusive fight into encirclement.",
        units: [
            unit("kobryn-epler-hq", "Adam Epler command group", .player, "Rearguard command", "Keeps reserve infantry and guns coordinated during withdrawal."),
            unit("kobryn-60th-reserve", "60th Reserve Infantry Division", .player, "Town defense", "Main Polish force holding Kobryn and covering exits."),
            unit("kobryn-field-guns", "Polish field and anti-tank guns", .player, "Road denial", "Covers western roadblocks and must limber to score preservation."),
            unit("kobryn-rearguard", "Polish rearguard companies", .player, "Withdrawal cover", "Detachments that trade ground for time around Kobryn."),
            unit("kobryn-2nd-motorized", "German 2nd Motorized Infantry Division", .guderianAI, "Fixing attack", "Motorized infantry pressure from XIX Corps."),
            unit("kobryn-flank-patrols", "German flank patrols", .guderianAI, "Exit threat", "Markers that can close eastern withdrawal lanes."),
        ],
        triggers: [
            trigger("kobryn-roadblock", "Western roadblock", "Polish guns or infantry contest the western road", "Delay the German fixing attack by one order."),
            trigger("kobryn-rearguard-window", "Rearguard window", "Kobryn remains contested through turn 3", "Unlock eastern withdrawal scoring."),
            trigger("kobryn-exit-threat", "Exit threat", "German flank patrols control one eastern road", "Force the player to choose between town defense and cohesion scoring."),
            trigger("kobryn-cohesion-exit", "Cohesion exit", "Three or more Polish units exit through the same lane", "Award operational success despite the town being lost or contested."),
        ]
    )

    private static let wizna = ScenarioSetupScript(
        id: .wizna,
        playerBriefing: "Hold the fortified line long enough for the wider Polish defense to gain time. Survival and delay matter more than destroying every attacker.",
        guderianBriefing: "The German plan pressures the bunkers with artillery, probes for weak strongpoints, then assaults once defenders are pinned.",
        units: [
            unit("wizna-raginis-hq", "Raginis command post", .player, "Command objective", "Represents the fortified command position around Gora Strekowa."),
            unit("wizna-bunker-line", "Bunker machine-gun sections", .player, "Fortified infantry", "Static defense groups occupying the bunker belt."),
            unit("wizna-at-guns", "Polish anti-tank guns", .player, "Anti-armor screen", "Scarce weapons that teach fire lanes and target priority."),
            unit("wizna-artillery", "German artillery batteries", .guderianAI, "Suppression", "Scheduled fire used to introduce pinning and bunker pressure."),
            unit("wizna-panzer-column", "Panzer assault column", .guderianAI, "Armored pressure", "Temporary dzw German armor proxy until Polish/German 1939 rosters are added."),
            unit("wizna-assault-pioneers", "German assault pioneers", .guderianAI, "Bunker assault", "Infantry tasked with reducing isolated fortifications."),
        ],
        triggers: [
            trigger("wizna-turn-pressure", "Bombardment pressure", "Start of German turns 1 and 2", "Apply artillery/pinning pressure to bunker objectives."),
            trigger("wizna-last-stand", "Last bunker stand", "Player controls one or fewer bunker objectives", "Award delay points and surface withdrawal/hold guidance."),
        ],
        tutorialSteps: [
            tutorial("wizna-cover", "Use the bunkers", "Select a fortified unit and keep it inside the bunker belt to preserve cover saves."),
            tutorial("wizna-fire-lanes", "Prioritize armor lanes", "Use anti-tank fire against vehicles on the Narew approach road before they reach assault range."),
            tutorial("wizna-delay", "Score by delaying", "End turns with bunkers contested or controlled; the tutorial rewards time bought, not total destruction."),
            tutorial("wizna-assault", "Survive close assault", "When a bunker is isolated, prepare for assault and preserve nearby support fire."),
        ]
    )

    private static let sedan = ScenarioSetupScript(
        id: .sedan,
        playerBriefing: "Defend the Meuse line, keep artillery control intact, and prevent German engineers from expanding the bridgehead.",
        guderianBriefing: "The German plan suppresses the defenders, pushes engineers to two bridge sites, then releases panzer follow-up into the Sedan road net.",
        units: [
            unit("sedan-french-infantry", "French Meuse infantry", .player, "River defense", "Defenders holding the east bank and town approaches."),
            unit("sedan-french-artillery", "French artillery group", .player, "Defensive fire support", "Key morale and fire-support objective behind the river line."),
            unit("sedan-french-observers", "French forward observers", .player, "Artillery control", "Observation assets that protect the fire plan."),
            unit("sedan-counterattack", "French reserve counterattack group", .player, "Timed counterattack", "Arrives after the bridgehead forms or artillery control is lost."),
            unit("sedan-engineers", "German assault engineers", .guderianAI, "Bridgehead creation", "Crossing troops that unlock the panzer follow-up trigger."),
            unit("sedan-motorized-infantry", "German motorized infantry", .guderianAI, "Crossing support", "Infantry that clears near-bank positions."),
            unit("sedan-panzer-followup", "German panzer follow-up", .guderianAI, "Breakout force", "Armor released after bridgehead conditions are met."),
            unit("sedan-air-support", "German air-pressure event", .guderianAI, "Suppression", "Represents the disruption that opens the river-crossing sequence."),
        ],
        triggers: [
            trigger("sedan-air-pressure", "Air-pressure opening", "Start of turn 1", "Suppress or pin selected French artillery/observer positions."),
            trigger("sedan-engineer-crossing", "Engineer crossing", "German engineers control a bridge site", "Unlock bridgehead objective scoring and panzer follow-up."),
            trigger("sedan-french-counterattack", "French counterattack", "Bridgehead perimeter is German-controlled or artillery control is lost", "Release French reserve counterattack group."),
            trigger("sedan-panzer-release", "Panzer release", "German bridgehead survives a full player turn", "Allow German armor to move east along the Sedan-Gaulier road."),
        ]
    )

    private static let stonne = ScenarioSetupScript(
        id: .stonne,
        playerBriefing: "Use French heavy tanks and infantry to contest Stonne and the heights. The goal is to threaten the Sedan bridgehead flank, not to hold every street forever.",
        guderianBriefing: "German forces must keep the bridgehead flank secure by pinning French infantry, flanking heavy tanks, and retaking Stonne after each French thrust.",
        units: [
            unit("stonne-char-b1", "Char B1 bis shock group", .player, "Heavy-tank counterattack", "French heavy tanks can dominate frontal fights when supported."),
            unit("stonne-french-infantry", "French infantry around Stonne", .player, "Village control", "Infantry needed to convert tank shock into objective control."),
            unit("stonne-artillery", "French artillery observers", .player, "Bridgehead threat", "Observation from the heights pressures German support lines."),
            unit("stonne-grossdeutschland", "Grossdeutschland assault group", .guderianAI, "Village assault", "German infantry pressure in the repeated fight for Stonne."),
            unit("stonne-panzer-support", "10th Panzer support elements", .guderianAI, "Bridgehead guard", "Armor and anti-tank support trying to contain Char B1 attacks."),
            unit("stonne-artillery-support", "German artillery support", .guderianAI, "Suppression", "Pressure source that makes repeated village control costly."),
        ],
        triggers: [
            trigger("stonne-heavy-tank-shock", "Heavy-tank shock", "A Char B1 attacks from village or ridge cover", "Cancel one unsupported German anti-tank result."),
            trigger("stonne-village-flip", "Village changes hands", "Control of Stonne changes during a turn", "Score contested objective points and escalate reinforcement pressure."),
            trigger("stonne-flank-risk", "Flank risk", "French tanks advance without adjacent infantry", "German support can mark heavy tanks as isolated."),
        ]
    )

    private static let montcornet = ScenarioSetupScript(
        id: .montcornet,
        playerBriefing: "Strike German columns around Montcornet with 4e Division cuirassee, destroy or disorder road assets, then withdraw armor before German reserve and air pressure peaks.",
        guderianBriefing: "German forces absorb the raid, hold road junctions, call air pressure, and try to trap French armor after the first attacks lose momentum.",
        units: [
            unit("montcornet-4dcr-tanks", "4e Division cuirassee tank groups", .player, "Armored raid", "Strong tank groups that can smash road columns during the early raid window."),
            unit("montcornet-french-support", "French limited support detachments", .player, "Raid support", "Sparse infantry and artillery support that cannot hold ground alone."),
            unit("montcornet-withdrawal-group", "French withdrawal control", .player, "Disengagement", "Preserves armored force after disruption objectives are met."),
            unit("montcornet-column-guards", "German road column guards", .guderianAI, "Column security", "Protect command, supply, and transport assets."),
            unit("montcornet-reserves", "German reserve reaction", .guderianAI, "Counterattack", "Arrives after the French raid window opens."),
            unit("montcornet-air-pressure", "Luftwaffe reaction", .guderianAI, "Air pressure", "Late pressure that punishes French armor that remains too long."),
        ],
        triggers: [
            trigger("montcornet-raid-window", "Raid window", "Turns 1-3", "French tanks score disruption before German reserves fully react."),
            trigger("montcornet-column-disruption", "Column disruption", "French armor controls a German road objective", "Reduce German pursuit or reinforcement tempo."),
            trigger("montcornet-air-peak", "Air-pressure peak", "Turns 4-6", "French armor still on road objectives risks loss unless withdrawing."),
        ]
    )

    private static let amiensAbbeville = ScenarioSetupScript(
        id: .amiensAbbeville,
        playerBriefing: "Hold Somme bridges and road hubs long enough to buy evacuation time. The Germans will likely reach the Channel; your success is measured in delays and preserved blocking forces.",
        guderianBriefing: "XIX Corps races through Amiens toward Abbeville, then spreads along the Somme to secure the Channel cut and guard against counterattacks.",
        units: [
            unit("amiens-french-blocking", "French blocking detachments", .player, "Road defense", "Holds Amiens and Somme crossings against German armored movement."),
            unit("amiens-british-elements", "British blocking elements", .player, "Evacuation time", "Detachments whose survival represents time bought for northern Allied forces."),
            unit("amiens-demolition-teams", "Bridge demolition teams", .player, "Crossing delay", "Can deny a Somme crossing for one German order window."),
            unit("amiens-1st-panzer", "German 1st Panzer Division", .guderianAI, "Amiens thrust", "Central armored drive through Amiens."),
            unit("amiens-2nd-panzer", "German 2nd Panzer Division", .guderianAI, "Abbeville thrust", "Northern armored drive toward Abbeville and the Channel."),
            unit("amiens-10th-panzer", "German 10th Panzer Division flank", .guderianAI, "Somme guard", "Southern flank security along the river line."),
        ],
        triggers: [
            trigger("amiens-bridge-delay", "Bridge delay", "A bridge is contested or demolished at turn end", "Prevent German exit scoring through that crossing next turn."),
            trigger("amiens-abbeville-race", "Abbeville race", "German armor controls Amiens road hub", "Advance 2nd Panzer pressure toward the Channel exit."),
            trigger("amiens-channel-cut", "Channel cut", "German armor controls Abbeville and the Channel exit", "Switch player scoring to evacuation time and force preservation."),
        ]
    )

    private static let boulogne = ScenarioSetupScript(
        id: .boulogne,
        playerBriefing: "Hold Boulogne's harbor and old town long enough for destroyers to embark troops and land demolition parties. The port may fall; the player wins by evacuation, naval support timing, and denial.",
        guderianBriefing: "2nd Panzer Division presses from the coast road and ridge approaches, tries to split the old town from the harbor, and calls air/artillery pressure once destroyers enter.",
        units: [
            unit("boulogne-french-garrison", "French naval and fortress garrison", .player, "Old-town defense", "Defenders in the Haute Ville and port forts."),
            unit("boulogne-guards", "20th Guards Brigade detachments", .player, "Harbor perimeter", "British defenders holding Irish and Welsh Guards sectors around the port."),
            unit("boulogne-destroyers", "Royal Navy destroyer support", .player, "Naval fire and embarkation", "Ships enter under tank, artillery, and air pressure to extract troops."),
            unit("boulogne-demolitions", "Navy demolition party", .player, "Port denial", "Can deny harbor facilities after evacuation scoring."),
            unit("boulogne-2nd-panzer", "German 2nd Panzer Division", .guderianAI, "Urban assault", "Primary German assault force against the port."),
            unit("boulogne-air-pressure", "German air and artillery pressure", .guderianAI, "Harbor disruption", "Pressure that reduces embarkation capacity."),
        ],
        triggers: [
            trigger("boulogne-destroyer-fire", "Destroyer fire support", "A destroyer support marker reaches the harbor", "Pin one German assault order and unlock embarkation scoring."),
            trigger("boulogne-embarkation", "Harbor embarkation", "The harbor objective is player-controlled or contested at turn end", "Evacuate one Allied formation or wounded/non-combatant marker."),
            trigger("boulogne-port-denial", "Port denial", "Demolition parties survive after an evacuation score", "Deny one German harbor-control point even if the port falls."),
        ]
    )

    private static let calais = ScenarioSetupScript(
        id: .calais,
        playerBriefing: "Hold Calais in layers. The garrison is not expected to keep the port indefinitely; every turn that 10th Panzer remains fixed here supports the wider Dunkirk evacuation.",
        guderianBriefing: "10th Panzer Division reduces outer defenses, cuts supply, then drives on the citadel and docks to end the strategic delay.",
        units: [
            unit("calais-british-garrison", "British Calais garrison", .player, "Layered defense", "Core garrison under siege pressure."),
            unit("calais-french-belgian", "French and Belgian defenders", .player, "Perimeter support", "Local defenders holding town and dock sectors."),
            unit("calais-supply", "Garrison supply and command points", .player, "Siege endurance", "Keeps fire support and command active under bombardment."),
            unit("calais-10th-panzer", "German 10th Panzer Division", .guderianAI, "Siege assault", "German armor and infantry assigned to reduce Calais."),
            unit("calais-artillery-air", "German artillery and air pressure", .guderianAI, "Supply reduction", "Suppresses perimeter layers and garrison supply."),
        ],
        triggers: [
            trigger("calais-strategic-delay", "Strategic delay", "Any inner perimeter objective is held at turn end", "Score Dunkirk-time points regardless of eventual port control."),
            trigger("calais-supply-pressure", "Supply pressure", "Air and assault pressure target the same layer", "Reduce garrison fire support unless supply remains held."),
            trigger("calais-citadel-fight", "Citadel fight", "Outer perimeter falls", "Move scoring focus to citadel/docks and costly German attacks."),
        ]
    )

    private static let dunkirk = ScenarioSetupScript(
        id: .dunkirk,
        playerBriefing: "Keep the evacuation perimeter open. This scenario is marked as Guderian-adjacent campaign pressure rather than direct Guderian command; score by moving formations off the beaches while rear guards hold canals.",
        guderianBriefing: "German pressure compresses canal lines and roads, reducing beach capacity each time a perimeter gate or air-pressure marker breaks through.",
        units: [
            unit("dunkirk-bef-rearguard", "BEF rear-guard detachments", .player, "Canal defense", "Hold crossings long enough to keep evacuation lanes open."),
            unit("dunkirk-french-perimeter", "French perimeter forces", .player, "Beachhead defense", "Defenders around harbor and canal sectors."),
            unit("dunkirk-evacuation-control", "Evacuation control parties", .player, "Embarkation", "Convert open beach sectors into evacuated formations."),
            unit("dunkirk-german-pressure", "German perimeter pressure", .guderianAI, "Compression", "Campaign-pressure force attacking canal and road exits."),
            unit("dunkirk-air-pressure", "German air pressure", .guderianAI, "Evacuation disruption", "Reduces beach capacity and damages exposed sectors."),
        ],
        triggers: [
            trigger("dunkirk-command-caveat", "Command-scope caveat", "Scenario briefing opens", "Display that this is a Guderian-adjacent pressure scenario."),
            trigger("dunkirk-evacuation", "Evacuation capacity", "A beach sector remains open at turn end", "Evacuate one formation, reduced by air-pressure and canal-breach markers."),
            trigger("dunkirk-rearguard-sacrifice", "Rear-guard sacrifice", "A rear-guard unit holds a canal gate while isolated", "Score time bought even if the unit cannot withdraw."),
        ]
    )

    private static let fallRot = ScenarioSetupScript(
        id: .fallRot,
        playerBriefing: "Slow Panzergruppe Guderian's late drive with bridge demolitions, fortress-town stands, fuel denial, and retreat corridors. Once Belfort and Epinal are threatened, preservation matters more than holding every crossing.",
        guderianBriefing: "Panzergruppe Guderian forces crossings, exploits road gaps, captures fortress towns, and connects with Army Group C to trap French forces near the Vosges and Maginot rear.",
        units: [
            unit("fallrot-bridge-guards", "French bridge and canal guards", .player, "Crossing denial", "Defenders around Aisne and Marne-Rhine crossing points."),
            unit("fallrot-fortress-garrisons", "Belfort and Epinal fortress garrisons", .player, "Fortress-town delay", "Late-campaign strongpoints that can force urban fights."),
            unit("fallrot-retreat-columns", "French retreat columns", .player, "Preservation", "Forces trying to escape through Vosges corridors."),
            unit("fallrot-demolitions", "Fuel and bridge demolition teams", .player, "Tempo denial", "Can create congestion and fuel friction for panzers."),
            unit("fallrot-panzergruppe", "Panzergruppe Guderian columns", .guderianAI, "Deep exploitation", "German armored columns driving toward the Swiss border."),
            unit("fallrot-engineers", "German bridge engineers", .guderianAI, "Crossing repair", "Reopen demolished or contested crossings."),
            unit("fallrot-army-group-c", "Army Group C link-up marker", .guderianAI, "Encirclement", "Represents the eastern link closing behind French forces."),
        ],
        triggers: [
            trigger("fallrot-bridge-denial", "Bridge denial", "A demolition team holds a crossing at turn end", "Force German engineers or congestion before panzer exit scoring."),
            trigger("fallrot-fortress-stand", "Fortress-town stand", "Belfort or Epinal remains contested", "Score delay and slow Army Group C link-up pressure."),
            trigger("fallrot-vosges-trap", "Vosges trap", "German forces control Belfort and an eastern road marker", "Switch scoring from position defense to retreat-corridor preservation."),
        ]
    )

    private static let bialystokMinsk = ScenarioSetupScript(
        id: .bialystokMinsk,
        playerBriefing: "Western Front is in danger of double envelopment. Use mechanized counterattacks to delay one pincer, keep Minsk road/rail communications open, and evacuate command posts before the pockets close.",
        guderianBriefing: "2nd Panzer Group drives across the Bug as the southern pincer while 3rd Panzer Group closes from the north; the German plan is to seal Bialystok and Minsk pockets before Soviet formations can withdraw.",
        units: [
            unit("bialystok-3rd-army", "Soviet 3rd Army detachments", .player, "Northern pocket defense", "Forward army elements threatened by the northern pincer."),
            unit("bialystok-10th-army", "Soviet 10th Army salient force", .player, "Breakout force", "Large forward force that must choose between counterattack and withdrawal."),
            unit("bialystok-4th-army", "Soviet 4th Army remnants", .player, "Southern screen", "Screen against Guderian's Bug River penetration."),
            unit("bialystok-mechanized", "Soviet mechanized counterattack groups", .player, "Pincer delay", "Fuel-limited counterattack force for reopening escape lanes."),
            unit("bialystok-command", "Western Front command posts", .player, "Command preservation", "High-value headquarters and artillery control assets."),
            unit("bialystok-2nd-panzer", "German 2nd Panzer Group", .guderianAI, "Southern pincer", "Guderian's force driving toward Minsk."),
            unit("bialystok-3rd-panzer", "German 3rd Panzer Group", .guderianAI, "Northern pincer", "Hoth's force closing the double envelopment."),
            unit("bialystok-infantry-armies", "German 4th and 9th Army pressure", .guderianAI, "Pocket reduction", "Infantry pressure that destroys pockets after panzer closure."),
        ],
        triggers: [
            trigger("bialystok-double-envelopment", "Double envelopment", "Northern and southern pincer markers both advance east", "Close one breakout route and add pocket attrition."),
            trigger("bialystok-boldin-counterattack", "Mechanized counterattack", "Mechanized assets attack a pincer marker on turns 2-4", "Delay one pincer order and open a temporary escape lane, then mark fuel-low."),
            trigger("bialystok-command-preservation", "Command preservation", "A command post reaches Minsk road or rail control", "Score command-survival points and reduce attrition for one turn."),
            trigger("bialystok-breakout-lane", "Breakout lane", "A road or rail objective remains Soviet-controlled at turn end", "Exit one trapped formation or remove one isolation marker."),
        ]
    )

    private static let smolensk = ScenarioSetupScript(
        id: .smolensk,
        playerBriefing: "Smolensk is not a static city defense. Hold the Dnieper and Dvina crossings long enough to strain German supply, then counterattack pincer shoulders and move trapped armies through the Yartsevo escape lane.",
        guderianBriefing: "2nd Panzer Group crosses the Dnieper from the south while Hoth's northern pincer presses through Vitebsk. The German plan is to close the pocket quickly, then survive Soviet reserve counterstrokes.",
        units: [
            unit("smolensk-16th-army", "Soviet 16th Army Smolensk defense", .player, "Urban pocket anchor", "Holds the city and Moscow road while escape operations organize."),
            unit("smolensk-19th-army", "Soviet 19th Army escape group", .player, "Breakout force", "Pocketed force that scores by exiting rather than standing in place."),
            unit("smolensk-20th-army", "Soviet 20th Army escape group", .player, "Breakout force", "Trapped army elements that can move through Yartsevo if the corridor opens."),
            unit("smolensk-reserve-armies", "Stavka reserve counterattack armies", .player, "Pincer shoulder pressure", "Fresh but uneven forces committed to blunt the German drive."),
            unit("smolensk-engineers", "Dnieper and Dvina crossing guards", .player, "River delay", "Engineers and infantry contest bridgeheads and force German supply checks."),
            unit("smolensk-2nd-panzer", "German 2nd Panzer Group", .guderianAI, "Southern pincer", "Guderian's force crossing the Dnieper and pushing toward Smolensk."),
            unit("smolensk-3rd-panzer", "German 3rd Panzer Group", .guderianAI, "Northern pincer", "Hoth's pincer closing through Vitebsk and the Dvina line."),
            unit("smolensk-infantry-followup", "German infantry follow-up armies", .guderianAI, "Pocket reduction", "Slower infantry needed to reduce trapped Soviet formations."),
            unit("smolensk-supply-columns", "German extended supply columns", .guderianAI, "Logistics strain", "Long supply lines vulnerable to delay and counterattack pressure."),
        ],
        triggers: [
            trigger("smolensk-dnieper-delay", "Dnieper crossing delay", "A Soviet crossing guard contests a Dnieper bridgehead at turn end", "Add one German supply-strain marker and delay southern pincer movement."),
            trigger("smolensk-reserve-counterstroke", "Reserve counterstroke", "Reserve armies attack a pincer shoulder on turns 2-5", "Reopen one escape lane or cancel one pocket-closure order, then mark the reserve disrupted."),
            trigger("smolensk-yartsevo-escape", "Yartsevo escape lane", "The Yartsevo objective is Soviet-controlled or contested at turn end", "Exit one trapped army element and reduce pocket attrition."),
            trigger("smolensk-logistics-crisis", "Logistics crisis", "Two German supply-strain markers are active", "German AI must choose between pincer closure and bridgehead reinforcement."),
        ]
    )

    private static let roslavlNovozybkov = ScenarioSetupScript(
        id: .roslavlNovozybkov,
        playerBriefing: "Bryansk Front is attacking to spoil Guderian's southward turn. Hit columns and crossing points, reveal the German intent screen, then withdraw tanks before the counterpressure turns the raid into another pocket.",
        guderianBriefing: "2nd Panzer Group screens Roslavl, protects supply columns, and keeps the southward turn moving despite Soviet attacks from the Bryansk Front.",
        units: [
            unit("roslavl-bryansk-front", "Bryansk Front rifle attack groups", .player, "Spoiling offensive", "Rifle formations pressing the Roslavl-Novozybkov axis."),
            unit("roslavl-tank-groups", "Soviet tank groups", .player, "Column raid", "Limited tank assets used to damage German road and supply columns."),
            unit("roslavl-recon", "Soviet reconnaissance detachments", .player, "Intent reveal", "Can expose whether German forces are screening, counterattacking, or turning south."),
            unit("roslavl-reserve-control", "Bryansk Front reserve control", .player, "Withdrawal coordination", "Preserves attack groups after disruption objectives are complete."),
            unit("roslavl-2nd-panzer", "German 2nd Panzer Group road columns", .guderianAI, "Southward movement", "Mobile elements turning away from Smolensk toward Kiev."),
            unit("roslavl-2nd-army", "German 2nd Army screen", .guderianAI, "Infantry screen", "Infantry pressure protecting roads and pinning Soviet attacks."),
            unit("roslavl-supply-columns", "German supply and traffic columns", .guderianAI, "Raid target", "Operational targets whose disruption slows the southward turn."),
            unit("roslavl-counterattack", "German counterpressure group", .guderianAI, "Trap response", "Arrives after Soviet tanks overstay on road objectives."),
        ],
        triggers: [
            trigger("roslavl-intel-reveal", "Intent screen revealed", "Soviet reconnaissance controls the southward-turn screen", "Reveal German route priorities and unlock full raid scoring."),
            trigger("roslavl-column-raid", "Column raid", "Soviet tanks control or contest a supply-column objective", "Score panzer attrition and slow German southward-turn tempo."),
            trigger("roslavl-withdrawal-order", "Tank withdrawal order", "A tank group scores a raid objective", "Allow that unit to exit before German counterpressure if a reserve-control marker is open."),
            trigger("roslavl-counterpressure", "German counterpressure", "German screen and panzer markers both control the road axis", "Close one Soviet withdrawal lane and threaten reserve cohesion."),
        ]
    )

    private static let kiev = ScenarioSetupScript(
        id: .kiev,
        playerBriefing: "The Kiev battle is a command-evacuation and breakout problem. Delay Guderian's northern pincer, keep the eastern corridor open, and move headquarters and artillery out before the link-up closes.",
        guderianBriefing: "2nd Panzer Group drives south as the northern pincer while 1st Panzer Group rises from the south. The German plan is to close the eastern corridor, then reduce the Kiev pocket.",
        units: [
            unit("kiev-5th-army", "Soviet 5th Army detachments", .player, "Northern delay", "Defends against Guderian's southward pincer."),
            unit("kiev-37th-army", "Kiev fortified-area defenders", .player, "Urban defense", "Holds Kiev and nearby Dnieper positions while evacuation begins."),
            unit("kiev-26th-army", "Soviet 26th Army breakout group", .player, "Breakout force", "Attempts to keep the eastern road corridor open."),
            unit("kiev-command-hq", "Southwestern Front command posts", .player, "Command evacuation", "High-value headquarters and artillery-control assets."),
            unit("kiev-rail-control", "Kiev rail and road control teams", .player, "Communications", "Keep routes active for evacuation and breakout operations."),
            unit("kiev-2nd-panzer", "German 2nd Panzer Group", .guderianAI, "Northern pincer", "Guderian's force driving south into the encirclement."),
            unit("kiev-1st-panzer", "German 1st Panzer Group link-up marker", .guderianAI, "Southern pincer", "Kleist's force rising to meet the northern pincer."),
            unit("kiev-infantry-reduction", "German infantry pocket-reduction armies", .guderianAI, "Pocket reduction", "Follow-up forces that collapse the pocket after closure."),
        ],
        triggers: [
            trigger("kiev-northern-pincer", "Northern pincer pressure", "2nd Panzer Group reaches the eastern closure corridor", "Narrow one breakout route and escalate command-evacuation scoring."),
            trigger("kiev-command-evacuation", "Command evacuation", "A command post exits through the eastern corridor", "Score command points and preserve one future breakout order."),
            trigger("kiev-pincer-linkup", "Pincer link-up", "Northern and southern pincer markers both control closure objectives", "Close the pocket and shift scoring to breakout survival."),
            trigger("kiev-breakout-operation", "Breakout operation", "Rifle army assets attack a closure marker while the corridor is contested", "Exit one trapped formation or delay pocket attrition."),
        ]
    )

    private static let bryansk = ScenarioSetupScript(
        id: .bryansk,
        playerBriefing: "Guderian's Typhoon attack arrives from an unexpected direction. Keep Bryansk and the rail junction useful, delay the 13th and 3rd Army pockets from collapsing, and protect the Orel-Tula road as long as possible.",
        guderianBriefing: "2nd Panzer Group attacks through Bryansk and Orel with speed, trying to encircle Soviet armies and open the southern approach to Tula before autumn friction and Soviet resistance slow the advance.",
        units: [
            unit("bryansk-50th-army", "Soviet 50th Army Tula screen", .player, "Road protection", "Defends the route toward Tula and the southern Moscow approach."),
            unit("bryansk-13th-army", "Soviet 13th Army pocket group", .player, "Pocket survival", "Encircled force that can keep German infantry tied down."),
            unit("bryansk-3rd-army", "Soviet 3rd Army pocket group", .player, "Pocket survival", "Trapped formation trying to contest exits and delay reduction."),
            unit("bryansk-rail-command", "Bryansk rail and command teams", .player, "Evacuation control", "Preserves command and supply through the rail junction."),
            unit("bryansk-roadblocks", "Orel-Tula roadblock detachments", .player, "Tula road guard", "Improvised defenders protecting the road north."),
            unit("bryansk-2nd-panzer", "German 2nd Panzer Group/Army", .guderianAI, "Typhoon breakthrough", "Guderian's armored force attacking Bryansk and Orel."),
            unit("bryansk-infantry", "German infantry reduction columns", .guderianAI, "Pocket reduction", "Follow-up infantry used to destroy encircled armies."),
            unit("bryansk-supply", "German autumn supply columns", .guderianAI, "Logistics strain", "Columns vulnerable when armor outruns rail and infantry support."),
        ],
        triggers: [
            trigger("bryansk-unexpected-axis", "Unexpected axis", "German armor reaches Orel before turn 4", "Reveal the Tula-road danger and reduce Soviet command flexibility."),
            trigger("bryansk-pocket-delay", "Pocket delay", "A pocket group contests Bryansk or a road exit at turn end", "Delay German infantry reduction and score time bought."),
            trigger("bryansk-tula-road-guard", "Tula road guard", "The Orel-Tula road remains Soviet-contested", "Prevent German exit scoring and preserve Moscow campaign readiness."),
            trigger("bryansk-autumn-friction", "Autumn friction", "German armor advances beyond rail or infantry support", "Add a supply-strain marker before further assault orders."),
        ]
    )

    private static let mtsensk = ScenarioSetupScript(
        id: .mtsensk,
        playerBriefing: "Do not meet the panzers in the open. Let 4th Panzer Division enter the Orel-Mtsensk road kill zone, reveal T-34/KV groups from wooded ridges, use rifle and anti-tank screens to pin the lead, then withdraw surviving tanks toward Tula.",
        guderianBriefing: "The German plan forces the road quickly at first, then switches to reconnaissance, artillery, and flanking pressure after the first T-34/KV ambush exposes the danger.",
        units: [
            unit("mtsensk-katukov-hq", "Mikhail Katukov command group", .player, "Ambush coordination", "Coordinates 4th Tank Brigade ambushes and staged withdrawals."),
            unit("mtsensk-4th-tank", "4th Tank Brigade T-34/KV groups", .player, "Armor ambush", "Shock armor that can blunt German panzer attacks when revealed from cover."),
            unit("mtsensk-lavrinenko-platoon", "Lavrinenko-style tank platoon", .player, "Mobile kill team", "Represents elite tank crews used for short, violent ambushes."),
            unit("mtsensk-guards-rifle", "1st Guards Rifle Corps screen", .player, "Road and ridge screen", "Infantry, airborne, artillery, and border-guard elements covering the ambush area."),
            unit("mtsensk-at-artillery", "Anti-tank and artillery screen", .player, "Track kill support", "Pins or immobilizes German armor in road chokepoints."),
            unit("mtsensk-4th-panzer", "German 4th Panzer Division spearhead", .guderianAI, "Road thrust", "Panzer force trying to recover speed after Bryansk and Orel."),
            unit("mtsensk-german-recon", "German reconnaissance and flank patrols", .guderianAI, "Ambush detection", "Attempts to clear wooded ridge lanes before armor commits."),
            unit("mtsensk-german-artillery", "German artillery and air pressure", .guderianAI, "Ambush suppression", "Late pressure against revealed Soviet tanks and anti-tank guns."),
        ],
        triggers: [
            trigger("mtsensk-ambush-reveal", "Ambush reveal", "A concealed tank group attacks from wooded ridge or road-choke cover", "Score German tank-loss points, cancel one movement order, and mark the ambush lane revealed."),
            trigger("mtsensk-t34-shock", "T-34/KV shock", "German armor attacks without artillery or flank support", "Ignore one unsupported German armor result and add a German caution marker."),
            trigger("mtsensk-track-kill", "Track-kill screen", "Anti-tank guns or rifle screens fire into a road choke", "Pin or immobilize the panzer lead before the assault step."),
            trigger("mtsensk-withdrawal", "Staged withdrawal", "A tank group has scored an ambush or is marked revealed", "Allow withdrawal toward Tula for preservation scoring."),
        ]
    )

    private static let moscowTulaKashira = ScenarioSetupScript(
        id: .moscowTulaKashira,
        playerBriefing: "Hold Tula, deny the Kashira bypass, and force German armor to outrun infantry and supply. The full scenario links Bryansk, Mtsensk, Tula, Venev, Kashira, and Mordves into one southern-pincer chain.",
        guderianBriefing: "The German plan drives along the Orel-Tula road, probes the Venev-Kashira bypass when Tula resists, and risks exhaustion if armor keeps pushing without infantry, fuel, or winter support.",
        units: [
            unit("moscow-tula-rifle", "Tula rifle defense group", .player, "City defense", "Infantry and guns holding the Tula belt and prepared urban positions."),
            unit("moscow-worker-militia", "Tula worker militia detachments", .player, "Morale anchor", "Local defense units that help keep city objectives contested under pressure."),
            unit("moscow-at-guns", "Soviet anti-tank gun line", .player, "Road denial", "Guns deployed to punish German armor that remains on the Orel-Tula road."),
            unit("moscow-reserve-armor", "Soviet reserve armor counterattack", .player, "Timed counterattack", "T-34/KV-style counterattack placeholder that enters after German exhaustion or road overextension."),
            unit("moscow-mobile-winter-reserve", "Mobile winter reserve", .player, "Flank pressure", "Ski, cavalry, or mobile detachments represented as a late-game pressure force."),
            unit("moscow-belov-getman", "Belov/Getman mobile reserve", .player, "Kashira counterstroke", "Cavalry and mechanized reserve abstraction that can drive back overextended panzers near Kashira."),
            unit("moscow-mordves-group", "Mordves counteroffensive group", .player, "Drive-back route", "Late reserve pressure that turns German exhaustion into retreat scoring."),
            unit("moscow-panzer-spearhead", "German panzer spearhead", .guderianAI, "Road thrust", "Armor racing the winter road net toward Tula and Kashira."),
            unit("moscow-motorized-infantry", "German motorized infantry follow-up", .guderianAI, "Assault support", "Infantry needed to convert panzer reach into objective control."),
            unit("moscow-venev-column", "German Venev bypass column", .guderianAI, "Bypass pressure", "Armor trying to skirt Tula and threaten Kashira."),
            unit("moscow-supply-columns", "German supply columns", .guderianAI, "Exhaustion clock", "Represents the logistical strain limiting repeated German attacks."),
            unit("moscow-artillery-support", "German artillery support", .guderianAI, "City suppression", "Fire support that helps attacks but cannot fully offset winter and supply penalties."),
        ],
        triggers: [
            trigger("moscow-first-exhaustion", "First exhaustion marker", "German armor ends a turn beyond infantry support", "Mark supply strain and expose the spearhead to Soviet counterattack scoring."),
            trigger("moscow-road-ambush", "Road ambush", "German armor moves through a marked winter road choke", "Allow Soviet anti-tank guns to score counterattack or exhaustion points."),
            trigger("moscow-venev-bypass", "Venev bypass", "German armor controls Venev while Tula remains contested", "Threaten the Kashira road and force a mobile reserve response."),
            trigger("moscow-reserve-release", "Soviet reserve release", "German spearhead controls a road objective or has two exhaustion markers", "Release Soviet reserve armor counterattack."),
            trigger("moscow-kashira-counterstroke", "Kashira counterstroke", "Belov/Getman reserve attacks an exhausted German spearhead near Kashira", "Drive back one panzer marker and score counteroffensive points."),
            trigger("moscow-city-morale", "Tula morale check", "Tula is contested at the end of a German assault turn", "Worker militia and city defenders may preserve contested control."),
            trigger("moscow-final-counteroffensive", "Final counteroffensive window", "Turns 6-9 and German exhaustion is active", "Soviet mobile winter reserve can enter on a flank objective and open the Mordves drive-back route."),
        ]
    )

    private static func generic(for scenario: GuderianScenario) -> ScenarioSetupScript {
        ScenarioSetupScript(
            id: scenario.id,
            playerBriefing: scenario.designIntent,
            guderianBriefing: GermanAIPlanCatalog.plan(for: scenario).strategicGoal,
            units: [
                unit("\(scenario.id.rawValue)-player-main", scenario.playerForceSummary, .player, scenario.playerPosture.rawValue, "Placeholder force card until the scenario receives a hand-authored order of battle."),
                unit("\(scenario.id.rawValue)-german-main", scenario.guderianCommand, .guderianAI, "German pressure force", "Placeholder force card until the scenario receives a hand-authored order of battle."),
            ],
            triggers: [
                trigger("\(scenario.id.rawValue)-objective-pressure", "Objective pressure", "German AI reaches a primary objective", "Escalate from movement pressure to shooting or assault orders."),
            ]
        )
    }
}

private func unit(_ id: String, _ name: String, _ side: ScenarioUnitSide, _ role: String, _ note: String) -> ScenarioUnitCard {
    ScenarioUnitCard(id: id, name: name, side: side, role: role, historicalNote: note)
}

private func trigger(_ id: String, _ name: String, _ condition: String, _ effect: String) -> ScenarioTrigger {
    ScenarioTrigger(id: id, name: name, condition: condition, effect: effect)
}

private func tutorial(_ id: String, _ title: String, _ instruction: String) -> TutorialStep {
    TutorialStep(id: id, title: title, instruction: instruction)
}
