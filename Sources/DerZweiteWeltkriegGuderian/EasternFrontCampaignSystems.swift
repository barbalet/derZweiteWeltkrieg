import Foundation

public enum EasternFrontAssetKind: String, Codable, Hashable, Sendable {
    case rifleArmy = "Rifle army"
    case mechanizedCorps = "Mechanized corps"
    case tankReserve = "Tank reserve"
    case commandPost = "Command post"
    case breakoutRoute = "Breakout route"
    case riverCrossing = "River crossing"
    case railJunction = "Rail junction"
    case pocket = "Pocket"
    case logisticsFriction = "Logistics friction"
    case winterFriction = "Winter friction"
    case armorAmbush = "Armor ambush"
    case antiTankScreen = "Anti-tank screen"
    case counteroffensiveAxis = "Counteroffensive axis"
    case cityDefense = "City defense"
}

public struct EasternFrontAsset: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: EasternFrontAssetKind
    public let battlefieldRole: String
    public let limitation: String

    public init(
        id: String,
        name: String,
        kind: EasternFrontAssetKind,
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

public struct EasternFrontRule: Identifiable, Codable, Hashable, Sendable {
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

public struct EasternFrontScenarioSystemProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let operationalProblem: String
    public let playerDoctrine: String
    public let assets: [EasternFrontAsset]
    public let specialRules: [EasternFrontRule]

    public init(
        id: GuderianBattleID,
        operationalProblem: String,
        playerDoctrine: String,
        assets: [EasternFrontAsset],
        specialRules: [EasternFrontRule]
    ) {
        self.id = id
        self.operationalProblem = operationalProblem
        self.playerDoctrine = playerDoctrine
        self.assets = assets
        self.specialRules = specialRules
    }
}

public enum EasternFrontCampaignSystemCatalog {
    public static func profile(for scenario: GuderianScenario) -> EasternFrontScenarioSystemProfile? {
        profile(for: scenario.id)
    }

    public static func profile(for id: GuderianBattleID) -> EasternFrontScenarioSystemProfile? {
        switch id {
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
        default:
            return nil
        }
    }

    public static let easternFrontScenarioIDs: [GuderianBattleID] = [
        .bialystokMinsk,
        .smolensk,
        .roslavlNovozybkov,
        .kiev,
        .bryansk,
        .mtsensk,
        .moscowTulaKashira,
    ]

    private static let bialystokMinsk = EasternFrontScenarioSystemProfile(
        id: .bialystokMinsk,
        operationalProblem: "Soviet Western Front formations are forward-deployed in a vulnerable salient while Guderian's 2nd Panzer Group and Hoth's 3rd Panzer Group attempt a double envelopment toward Minsk.",
        playerDoctrine: "Preserve command posts, open at least one breakout route, counterattack only to unpin trapped armies, and keep rail/road communications alive long enough for units to escape the pockets.",
        assets: [
            easternAsset("bialystok-3rd-army", "Soviet 3rd Army detachments", .rifleArmy, "Northern pocket and breakout pressure around Bialystok.", "Can be cut off from Minsk roads by northern pincer markers."),
            easternAsset("bialystok-10th-army", "Soviet 10th Army salient force", .rifleArmy, "Largest forward salient force whose survival depends on timely withdrawal.", "Suffers command friction if ordered to counterattack and withdraw in the same window."),
            easternAsset("bialystok-4th-army", "Soviet 4th Army remnants", .rifleArmy, "Southern screen against 2nd Panzer Group.", "Starts vulnerable to Bug River penetration and air disruption."),
            easternAsset("bialystok-mechanized", "Mechanized corps counterattack groups", .mechanizedCorps, "Limited counterattacks to reopen lanes or delay panzers.", "Fuel and coordination losses make repeated attacks costly."),
            easternAsset("bialystok-minsk-rail", "Minsk road and rail junction", .railJunction, "Main command-and-escape objective east of the pockets.", "If cut, breakout scoring becomes much harder."),
            easternAsset("bialystok-bug-neman", "Bug and Neman crossings", .riverCrossing, "Initial German penetration points and Soviet delay opportunities.", "Crossings cannot stop panzers alone once bridgeheads exist."),
            easternAsset("bialystok-pocket", "Bialystok-Novogrudok pockets", .pocket, "Encirclement zones whose pressure rises each turn.", "Units trapped inside score only through breakout or command preservation."),
        ],
        specialRules: [
            easternRule("bialystok-double-envelopment", "Double envelopment", "German northern and southern pincer markers both advance east of the pocket line.", "Close one breakout route and increase pocket attrition."),
            easternRule("bialystok-boldin-counterattack", "Boldin counterattack", "Mechanized or cavalry assets attack a pincer marker on turns 2-4.", "Delay one pincer order and open a temporary escape lane, then mark the counterattack group fuel-low."),
            easternRule("bialystok-command-preservation", "Command preservation", "A Soviet command post reaches Minsk road or rail control.", "Award command-survival points and reduce pocket attrition for one turn."),
            easternRule("bialystok-breakout-lane", "Breakout lane", "A road/rail objective remains Soviet-controlled at turn end.", "Exit one trapped formation or remove one isolation marker."),
        ]
    )

    private static let smolensk = EasternFrontScenarioSystemProfile(
        id: .smolensk,
        operationalProblem: "The Smolensk battle stretches the German panzer groups across the Dnieper and Dvina while Soviet reserve armies counterattack and try to open exits from the developing pocket.",
        playerDoctrine: "Hold crossing lines just long enough to force supply strain, counterattack the pincer shoulders, and move 16th, 19th, and 20th Army elements through Yartsevo and Moscow-road escape lanes.",
        assets: [
            easternAsset("smolensk-16th-army", "Soviet 16th Army around Smolensk", .rifleArmy, "Urban and road-defense anchor inside the pocket.", "Risks isolation if the Moscow road is cut."),
            easternAsset("smolensk-19th-20th", "19th and 20th Army escape groups", .rifleArmy, "Pocket breakout formations east of Smolensk.", "Lose scoring value if held too long for static defense."),
            easternAsset("smolensk-reserve-armies", "Stavka reserve armies", .tankReserve, "Counteroffensive pressure against German pincer shoulders.", "Arrive piecemeal and cannot hold every river crossing."),
            easternAsset("smolensk-dnieper-dvina", "Dnieper and Dvina crossing lines", .riverCrossing, "Primary German crossing targets and Soviet delay positions.", "Once both lines are forced, pocket attrition accelerates."),
            easternAsset("smolensk-yartsevo", "Yartsevo escape lane", .breakoutRoute, "Eastern exit for trapped armies toward the Moscow road.", "Can be closed by coordinated northern and southern pincer pressure."),
            easternAsset("smolensk-pocket", "Smolensk pocket", .pocket, "Encirclement zone for trapped Soviet armies.", "Units inside score through breakout, not final map control."),
            easternAsset("smolensk-logistics", "German extended supply columns", .logisticsFriction, "Represents stretched German lines after the rapid Barbarossa advance.", "Only matters if the player forces repeated counterattacks or crossing delays."),
        ],
        specialRules: [
            easternRule("smolensk-river-crossing-delay", "River crossing delay", "Soviet units contest Dnieper or Dvina crossings at turn end.", "Add a German supply-strain marker and delay one pincer order."),
            easternRule("smolensk-reserve-counterstroke", "Reserve counterstroke", "A reserve army attacks a pincer shoulder on turns 2-5.", "Reopen or protect one escape lane, then mark the reserve as disrupted."),
            easternRule("smolensk-yartsevo-corridor", "Yartsevo corridor", "The Moscow-road exit remains Soviet-controlled.", "Exit one trapped army asset and reduce pocket attrition."),
            easternRule("smolensk-logistics-crisis", "Logistics crisis", "Two supply-strain markers are active.", "German AI must choose between pincer closure and reinforcing bridgeheads."),
        ]
    )

    private static let roslavlNovozybkov = EasternFrontScenarioSystemProfile(
        id: .roslavlNovozybkov,
        operationalProblem: "Bryansk Front launches a spoiling offensive against 2nd Panzer Group and 2nd Army as Guderian's force turns south from the Smolensk battle toward Kiev.",
        playerDoctrine: "Strike flank and road-column objectives, preserve scarce tanks after each raid, and use uncertainty about the southward turn to buy time before Operation Typhoon.",
        assets: [
            easternAsset("roslavl-bryansk-front", "Bryansk Front attack groups", .rifleArmy, "Main Soviet attacking force along Roslavl and Novozybkov axes.", "Offensive strength drops quickly if unsupported attacks stall."),
            easternAsset("roslavl-tank-groups", "Soviet tank attrition groups", .tankReserve, "Limited armor for spoiling attacks against German columns.", "Must withdraw after disruption to avoid being pocketed."),
            easternAsset("roslavl-desna-crossings", "Desna and Sozh crossing net", .riverCrossing, "Operational hinge for German southward movement and Soviet attack lanes.", "Crossings can delay movement but do not stop concentrated panzers."),
            easternAsset("roslavl-intel-screen", "German southward-turn screen", .commandPost, "Fog-of-war marker hiding whether Guderian is continuing south or preparing Moscow operations.", "If revealed too late, Soviet attacks lose tempo."),
            easternAsset("roslavl-supply-column", "2nd Panzer Group supply columns", .logisticsFriction, "Soft operational targets for the spoiling offensive.", "Protected by German infantry if attacks are delayed."),
            easternAsset("roslavl-novozybkov-road", "Roslavl-Novozybkov road axis", .breakoutRoute, "Soviet attack-and-withdrawal route.", "Can become a trap if German counterpressure reaches both ends."),
        ],
        specialRules: [
            easternRule("roslavl-spoiling-raid", "Spoiling raid", "Soviet tank or rifle groups control a German column objective.", "Reduce German southward-turn tempo and score panzer-attrition points."),
            easternRule("roslavl-intelligence-limit", "Intelligence limit", "The German southward-turn screen remains unrevealed.", "Limit Soviet target priority until a recon or combat trigger reveals the true axis."),
            easternRule("roslavl-tank-preservation", "Tank preservation", "A tank group exits after scoring a raid objective.", "Award preservation points and prevent German counterencirclement scoring against that group."),
            easternRule("roslavl-counterpressure", "Counterpressure", "German infantry and panzer markers both control the road axis.", "Close one Soviet withdrawal lane and force reserves to test cohesion."),
        ]
    )

    private static let kiev = EasternFrontScenarioSystemProfile(
        id: .kiev,
        operationalProblem: "Guderian's 2nd Panzer Group turns south as the northern pincer of the Kiev encirclement while Kleist's 1st Panzer Group rises from the south against the Soviet Southwestern Front.",
        playerDoctrine: "Keep command evacuation moving, delay pincer link-up near the eastern escape routes, and open breakout corridors before the Kiev pocket collapses.",
        assets: [
            easternAsset("kiev-southwestern-front", "Soviet Southwestern Front armies", .rifleArmy, "Large defending force around Kiev and the Dnieper bend.", "Static defense becomes disastrous once both pincers are active."),
            easternAsset("kiev-command-hq", "Southwestern Front command posts", .commandPost, "High-value evacuation and coordination assets.", "If trapped, breakout and artillery rules degrade."),
            easternAsset("kiev-dnieper-desna", "Dnieper and Desna river lines", .riverCrossing, "Delay terrain and pincer approach obstacles.", "German pincer markers can bypass if river guards are overcommitted."),
            easternAsset("kiev-lokhvytsia-corridor", "Eastern pincer closure corridor", .breakoutRoute, "Road net for command evacuation and late breakout.", "Narrows every turn after both panzer groups are committed."),
            easternAsset("kiev-pocket", "Kiev encirclement pocket", .pocket, "Main pocket pressure zone.", "Once closed, only command evacuation and breakout operations score well."),
            easternAsset("kiev-rail-junctions", "Kiev rail and road junctions", .railJunction, "Operational communications and evacuation routes.", "Loss increases command friction and reinforcement delays."),
        ],
        specialRules: [
            easternRule("kiev-northern-pincer", "Northern pincer pressure", "2nd Panzer Group marker reaches an eastern road objective.", "Narrow one breakout corridor and trigger command-evacuation urgency."),
            easternRule("kiev-pincer-linkup", "Pincer link-up", "Northern and southern pincer markers both control closure objectives.", "Close the Kiev pocket and convert remaining objectives to breakout scoring."),
            easternRule("kiev-command-evacuation", "Command evacuation", "A command post exits through an eastern corridor.", "Award command points and preserve one future breakout order."),
            easternRule("kiev-breakout-operation", "Breakout operation", "Rifle armies attack a closure marker while a corridor is contested.", "Exit one trapped formation or delay pocket attrition for a turn."),
        ]
    )

    private static let bryansk = EasternFrontScenarioSystemProfile(
        id: .bryansk,
        operationalProblem: "During Operation Typhoon, Guderian attacks in an unexpected direction, captures Bryansk and Orel, and threatens to encircle the 13th and 3rd Armies while opening the road toward Tula.",
        playerDoctrine: "Trade space for time, keep pocketed armies active, protect the Orel-Tula road, and use autumn road and logistics friction to slow the southern Moscow approach.",
        assets: [
            easternAsset("bryansk-50th-army", "Soviet 50th Army defense", .rifleArmy, "Northern Bryansk defense and Tula-axis screen.", "Can be bypassed if Orel falls too quickly."),
            easternAsset("bryansk-13th-3rd-armies", "13th and 3rd Army pocket groups", .rifleArmy, "Encirclement survival and breakout forces.", "Lose effectiveness under pocket attrition."),
            easternAsset("bryansk-pocket", "Bryansk encirclement pockets", .pocket, "Pocket pressure around Bryansk and eastward roads.", "German infantry reduction increases after Orel road control."),
            easternAsset("bryansk-orel-road", "Bryansk-Orel-Tula road axis", .breakoutRoute, "Axis connecting Operation Typhoon to the southern Moscow approach.", "German control unlocks Tula-road pressure."),
            easternAsset("bryansk-rail-junction", "Bryansk rail junction", .railJunction, "Command, evacuation, and supply node.", "If lost, Soviet reinforcement timing becomes unreliable."),
            easternAsset("bryansk-autumn-friction", "Autumn road friction", .logisticsFriction, "Mud, distance, and logistics friction slowing repeated German exploitation.", "Does not help if the player leaves roads uncontested."),
        ],
        specialRules: [
            easternRule("bryansk-unexpected-axis", "Unexpected axis", "German armor reaches Orel before turn 4.", "Reveal Tula-road danger and reduce Soviet command flexibility."),
            easternRule("bryansk-pocket-delay", "Pocket delay", "A pocket group contests Bryansk or a road exit at turn end.", "Delay German infantry reduction and score time bought."),
            easternRule("bryansk-tula-road-guard", "Tula road guard", "The Orel-Tula road remains Soviet-contested.", "Prevent German exit scoring and preserve Moscow campaign readiness."),
            easternRule("bryansk-autumn-friction", "Autumn friction", "German armor advances beyond rail or infantry support.", "Add a supply-strain marker before further assault orders."),
        ]
    )

    private static let mtsensk = EasternFrontScenarioSystemProfile(
        id: .mtsensk,
        operationalProblem: "Katukov's 4th Tank Brigade and 1st Guards Rifle Corps cover the Orel-Mtsensk-Tula road while Guderian's panzer formations attempt to recover momentum after the Bryansk encirclement.",
        playerDoctrine: "Use concealed T-34/KV ambushes, rifle screens, and anti-tank guns to force German tank losses, then withdraw armor before air, artillery, and flank probes convert the ambush into a trap.",
        assets: [
            easternAsset("mtsensk-4th-tank", "Katukov 4th Tank Brigade", .armorAmbush, "Main T-34/KV ambush and counterattack force.", "Must reveal from cover; exposed tanks become high-priority German targets."),
            easternAsset("mtsensk-1st-guards-rifle", "1st Guards Rifle Corps screen", .rifleArmy, "Infantry, airborne, artillery, and border-guard screen around Mtsensk.", "Can slow roads but cannot duel panzer divisions in open ground."),
            easternAsset("mtsensk-t34-kv", "T-34 and KV shock platoons", .tankReserve, "Armored shock assets that outclass many early German tank engagements.", "Scarce; preservation scoring matters after each ambush."),
            easternAsset("mtsensk-at-screen", "Anti-tank and artillery screen", .antiTankScreen, "Track-breaking and close-range kill lanes against German armor.", "Needs terrain cover or a rifle screen to survive."),
            easternAsset("mtsensk-wooded-ridges", "Wooded ridge ambush lanes", .armorAmbush, "Cover and line-of-sight breaks along the Orel-Mtsensk road.", "Lose surprise if German reconnaissance clears them."),
            easternAsset("mtsensk-orel-road", "Orel-Mtsensk-Tula road", .breakoutRoute, "German advance route and Soviet withdrawal path.", "If the road is lost end-to-end, armor preservation becomes harder."),
        ],
        specialRules: [
            easternRule("mtsensk-ambush-reveal", "Ambush reveal", "A concealed tank group attacks German armor from a wooded ridge or road choke.", "Score tank-loss points and cancel one German movement order, then mark the ambush lane revealed."),
            easternRule("mtsensk-t34-shock", "T-34/KV shock", "German panzer units attack without artillery or flanking support.", "Ignore one unsupported German armor result and add a German caution marker."),
            easternRule("mtsensk-track-kill", "Track kill screen", "Anti-tank guns or rifle screens fire at armor in a road choke.", "Immobilize or pin a panzer spearhead before it can assault."),
            easternRule("mtsensk-preserve-guards", "Guards preservation", "A tank or rifle group withdraws after scoring an ambush.", "Award preservation points and keep the Tula road delay chain active."),
        ]
    )

    private static let moscowTulaKashira = EasternFrontScenarioSystemProfile(
        id: .moscowTulaKashira,
        operationalProblem: "The full southern Moscow pincer links the Bryansk/Orel approach, Mtsensk armor delay, Tula city defense, Venev breakthrough threat, Kashira counterstroke, and winter counteroffensive into one exhaustion chain.",
        playerDoctrine: "Hold Tula, deny Orel-Tula and Kashira exits, use Belov/Getman-style mobile reserves after German overextension, and convert winter logistics into a counteroffensive rather than a static last stand.",
        assets: [
            easternAsset("moscow-rifle-belt", "Tula rifle defensive belt", .cityDefense, "Prepared city defense and morale anchor.", "Can be worn down if reserves arrive too late."),
            easternAsset("moscow-50th-army", "50th Army and Tula militia", .rifleArmy, "City, factory, and roadblock defense.", "Cannot cover every bypass route without mobile reserves."),
            easternAsset("moscow-kashira-reserve", "Kashira mobile reserve", .tankReserve, "Belov/Getman-style counterattack force against overextended armor.", "Scores best after German exhaustion markers appear."),
            easternAsset("moscow-venev-axis", "Venev-Kashira threat axis", .counteroffensiveAxis, "German bypass route and Soviet counterstroke trigger.", "If ignored, German exit pressure bypasses Tula."),
            easternAsset("moscow-winter", "Winter logistics friction", .winterFriction, "Limits repeated German armored assaults.", "Should slow pressure without freezing the battle."),
            easternAsset("moscow-orel-tula-road", "Orel-Tula road chain", .breakoutRoute, "Connects Bryansk and Mtsensk delays to the final Moscow approach.", "Early German control increases Tula pressure."),
        ],
        specialRules: [
            easternRule("moscow-exhaustion", "German exhaustion", "German armor outruns infantry or supply.", "Add exhaustion and unlock Soviet reserve timing."),
            easternRule("moscow-venev-bypass", "Venev bypass", "German armor controls Venev and the Kashira road is open.", "Threaten a southern exit unless Soviet mobile reserves counterattack."),
            easternRule("moscow-kashira-counterstroke", "Kashira counterstroke", "Soviet mobile reserves attack an exhausted German spearhead.", "Drive back one panzer marker and score counteroffensive points."),
            easternRule("moscow-counteroffensive", "Counteroffensive window", "Late turns with German exhaustion active.", "Soviet mobile reserves may enter and score flank pressure."),
        ]
    )
}

private func easternAsset(
    _ id: String,
    _ name: String,
    _ kind: EasternFrontAssetKind,
    _ role: String,
    _ limitation: String
) -> EasternFrontAsset {
    EasternFrontAsset(id: id, name: name, kind: kind, battlefieldRole: role, limitation: limitation)
}

private func easternRule(_ id: String, _ name: String, _ trigger: String, _ effect: String) -> EasternFrontRule {
    EasternFrontRule(id: id, name: name, trigger: trigger, effect: effect)
}
