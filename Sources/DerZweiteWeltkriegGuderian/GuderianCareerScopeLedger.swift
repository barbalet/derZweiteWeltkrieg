import Foundation

public enum GuderianCommandScope: String, CaseIterable, Codable, Hashable, Sendable {
    case directFieldCommand = "Direct field command"
    case adjacentCampaignPressure = "Adjacent campaign pressure"
    case inspectorGeneralInfluence = "Inspector General influence"
    case armyGeneralStaffInfluence = "Army General Staff influence"
    case postDismissalContext = "Post-dismissal context"

    public var allowsDirectBattlefieldScenario: Bool {
        self == .directFieldCommand
    }

    public var requiresCommandCaveat: Bool {
        !allowsDirectBattlefieldScenario
    }
}

public struct GuderianCareerDateRange: Codable, Comparable, Hashable, Sendable {
    public let start: ScenarioDateKey
    public let end: ScenarioDateKey
    public let label: String

    public init(start: ScenarioDateKey, end: ScenarioDateKey, label: String) {
        precondition(start <= end, "Career date range must not end before it starts.")
        self.start = start
        self.end = end
        self.label = label
    }

    public static func < (lhs: GuderianCareerDateRange, rhs: GuderianCareerDateRange) -> Bool {
        if lhs.start != rhs.start { return lhs.start < rhs.start }
        return lhs.end < rhs.end
    }

    public func contains(_ date: ScenarioDateKey) -> Bool {
        start <= date && date <= end
    }
}

public struct GuderianCareerScopeRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let dateRange: GuderianCareerDateRange
    public let scope: GuderianCommandScope
    public let commandRole: String
    public let playableFraming: String
    public let scenarioIDs: [GuderianBattleID]
    public let sourceLinks: [ScenarioSource]

    public init(
        id: String,
        title: String,
        dateRange: GuderianCareerDateRange,
        scope: GuderianCommandScope,
        commandRole: String,
        playableFraming: String,
        scenarioIDs: [GuderianBattleID],
        sourceLinks: [ScenarioSource]
    ) {
        self.id = id
        self.title = title
        self.dateRange = dateRange
        self.scope = scope
        self.commandRole = commandRole
        self.playableFraming = playableFraming
        self.scenarioIDs = scenarioIDs
        self.sourceLinks = sourceLinks
    }

    public var requiresCommandCaveat: Bool {
        scope.requiresCommandCaveat
    }
}

public struct GuderianCareerExpansionCandidate: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let order: Int
    public let title: String
    public let dateRange: GuderianCareerDateRange
    public let scope: GuderianCommandScope
    public let playerRole: String
    public let geographyFocus: [String]
    public let playableFraming: String
    public let inclusionReason: String
    public let sourceLinks: [ScenarioSource]

    public init(
        id: String,
        order: Int,
        title: String,
        dateRange: GuderianCareerDateRange,
        scope: GuderianCommandScope,
        playerRole: String,
        geographyFocus: [String],
        playableFraming: String,
        inclusionReason: String,
        sourceLinks: [ScenarioSource]
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.dateRange = dateRange
        self.scope = scope
        self.playerRole = playerRole
        self.geographyFocus = geographyFocus
        self.playableFraming = playableFraming
        self.inclusionReason = inclusionReason
        self.sourceLinks = sourceLinks
    }

    public var requiresCommandCaveat: Bool {
        scope.requiresCommandCaveat
    }
}

public enum GuderianCareerScopeCatalog {
    public static let currentScenarioRecords: [GuderianCareerScopeRecord] = [
        currentRecord(
            "poland-1939-xix-corps",
            "Poland 1939 XIX Corps battles",
            start: date(1939, 9, 1),
            end: date(1939, 9, 18),
            label: "1-18 Sep 1939",
            scope: .directFieldCommand,
            commandRole: "XIX Panzer Corps in the invasion of Poland.",
            playableFraming: "Default play resists XIX Corps as Polish forces trying to delay, preserve forces, or hold fortress positions; the side selector can also launch German command study mode.",
            scenarioIDs: [.tucholaForest, .wizna, .brzescLitewski, .kobryn],
            sources: [
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
                careerSource("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps"),
            ]
        ),
        currentRecord(
            "france-1940-xix-corps",
            "France 1940 XIX Corps and Channel drive",
            start: date(1940, 5, 12),
            end: date(1940, 5, 26),
            label: "12-26 May 1940",
            scope: .directFieldCommand,
            commandRole: "XIX Army Corps during the Meuse crossing and Channel coast drive.",
            playableFraming: "Default play commands French, British, and Belgian defenders delaying the Meuse breakthrough and port battles; the side selector can also launch German command study mode.",
            scenarioIDs: [.sedan, .stonne, .montcornet, .amiensAbbeville, .boulogne, .calais],
            sources: [
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
                careerSource("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps"),
            ]
        ),
        currentRecord(
            "dunkirk-command-caveat",
            "Dunkirk campaign-pressure caveat",
            start: date(1940, 5, 26),
            end: date(1940, 6, 4),
            label: "26 May-4 Jun 1940",
            scope: .adjacentCampaignPressure,
            commandRole: "Adjacent pressure after the Channel port drive, not a clean direct Guderian field-command battle.",
            playableFraming: "Default play defends the evacuation perimeter while the scenario explicitly labels the Guderian connection as contextual; side-selected command study remains non-celebratory.",
            scenarioIDs: [.dunkirk],
            sources: [
                careerSource("Battle of Dunkirk", "https://en.wikipedia.org/wiki/Battle_of_Dunkirk"),
                careerSource("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps"),
            ]
        ),
        currentRecord(
            "fall-rot-panzergruppe",
            "Fall Rot Panzergruppe Guderian drive",
            start: date(1940, 6, 10),
            end: date(1940, 6, 22),
            label: "10-22 Jun 1940",
            scope: .directFieldCommand,
            commandRole: "Panzergruppe Guderian during the late-France drive to the Swiss border.",
            playableFraming: "Default play uses French bridge, fortress, and retreat-corridor defenses against Guderian's exploitation; the side selector can also launch German command study mode.",
            scenarioIDs: [.fallRot],
            sources: [
                careerSource("Fall Rot", "https://en.wikipedia.org/wiki/Fall_Rot"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        currentRecord(
            "eastern-front-1941-panzer-group",
            "Eastern Front 1941 panzer group and panzer army battles",
            start: date(1941, 6, 22),
            end: date(1942, 1, 7),
            label: "22 Jun 1941-7 Jan 1942",
            scope: .directFieldCommand,
            commandRole: "2nd Panzer Group, later 2nd Panzer Army, until Guderian's dismissal during the Moscow crisis.",
            playableFraming: "Default play commands Soviet defenders, breakout forces, and counterattack groups against Guderian's 1941 panzer command; the side selector can also launch German command study mode, and Moscow carries an end-date caveat because the battle outlasts his command.",
            scenarioIDs: [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira],
            sources: [
                careerSource("2nd Panzer Army", "https://en.wikipedia.org/wiki/2nd_Panzer_Army"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
    ]

    public static let lateCareerExpansionCandidates: [GuderianCareerExpansionCandidate] = [
        candidate(
            "kursk-armored-force-pressure",
            order: 1,
            title: "Kursk Armored Force Pressure",
            start: date(1943, 7, 5),
            end: date(1943, 7, 16),
            label: "5-16 Jul 1943",
            scope: .inspectorGeneralInfluence,
            playerRole: "Soviet mine, anti-tank, artillery, and armored reserve defenders.",
            geography: ["Orel and Belgorod salients", "mine belts", "anti-tank zones", "armored reserve lanes"],
            framing: "A staff-influence scenario about German armored doctrine and equipment pressure, not a Guderian field command.",
            reason: "Captures the 1943 armored-force debate and the player experience of deep Soviet defense against German panzer doctrine.",
            sources: [
                careerSource("Battle of Kursk", "https://en.wikipedia.org/wiki/Battle_of_Kursk"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "dnieper-withdrawal",
            order: 2,
            title: "Dnieper Withdrawal and Bridgeheads",
            start: date(1943, 8, 24),
            end: date(1943, 12, 23),
            label: "24 Aug-23 Dec 1943",
            scope: .inspectorGeneralInfluence,
            playerRole: "Soviet Front detachments forcing crossings and isolating German bridgeheads.",
            geography: ["Dnieper River", "Kiev bridgeheads", "wetland crossings", "east-west road exits"],
            framing: "A late-war armor-readiness scenario using Guderian's inspector role as context.",
            reason: "Begins the withdrawal-from-the-east arc with major river geography and retreat-route pressure.",
            sources: [
                careerSource("Battle of the Dnieper", "https://en.wikipedia.org/wiki/Battle_of_the_Dnieper"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "korsun-cherkassy-pocket",
            order: 3,
            title: "Korsun-Cherkassy Pocket",
            start: date(1944, 1, 24),
            end: date(1944, 2, 16),
            label: "24 Jan-16 Feb 1944",
            scope: .inspectorGeneralInfluence,
            playerRole: "Soviet blocking, armored, and cavalry-mechanized groups sealing breakout roads.",
            geography: ["Korsun pocket", "Gniloy Tikich crossings", "Shenderovka road net", "snow and thaw lanes"],
            framing: "A command-context scenario for German armored relief and breakout pressure rather than a Guderian command battle.",
            reason: "Adds a major pocket-withdrawal battlefield with water obstacles and late-winter movement detail.",
            sources: [
                careerSource("Korsun-Cherkassy Pocket", "https://en.wikipedia.org/wiki/Korsun%E2%80%93Cherkassy_pocket"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "kamenets-podolsky-pocket",
            order: 4,
            title: "Kamenets-Podolsky Pocket",
            start: date(1944, 3, 4),
            end: date(1944, 4, 15),
            label: "4 Mar-15 Apr 1944",
            scope: .inspectorGeneralInfluence,
            playerRole: "Soviet mobile groups trying to close river exits and road junctions.",
            geography: ["Dniester and Southern Bug approaches", "Tarnopol roads", "mud-season exits", "pocket corridors"],
            framing: "A staff-influence withdrawal scenario centered on German armored escape corridors.",
            reason: "Adds a large retreat-and-breakout problem before Guderian's General Staff appointment.",
            sources: [
                careerSource("Kamenets-Podolsky Pocket", "https://en.wikipedia.org/wiki/Kamenets-Podolsky_pocket"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "operation-bagration-withdrawal",
            order: 5,
            title: "Operation Bagration Withdrawal Crisis",
            start: date(1944, 6, 22),
            end: date(1944, 8, 19),
            label: "22 Jun-19 Aug 1944",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet Front spearheads destroying Army Group Centre withdrawal routes.",
            geography: ["Berezina crossings", "Minsk road net", "Pripet flank", "rail escape corridors"],
            framing: "A transition scenario for the Eastern Front crisis around Guderian's later General Staff role.",
            reason: "Connects the 1944 collapse in the east to the later staff-influence campaign arc.",
            sources: [
                careerSource("Operation Bagration", "https://en.wikipedia.org/wiki/Operation_Bagration"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "lvov-sandomierz",
            order: 6,
            title: "Lvov-Sandomierz Breakthrough",
            start: date(1944, 7, 13),
            end: date(1944, 8, 29),
            label: "13 Jul-29 Aug 1944",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet attackers forcing bridgeheads and operational pursuit lanes.",
            geography: ["Lvov road net", "Vistula crossings", "Sandomierz bridgehead", "Carpathian approaches"],
            framing: "A General Staff context scenario about the German response to Soviet breakthrough and bridgehead creation.",
            reason: "Adds a key 1944 Vistula bridgehead precursor for the final defensive line.",
            sources: [
                careerSource("Lvov-Sandomierz Offensive", "https://en.wikipedia.org/wiki/Lvov%E2%80%93Sandomierz_Offensive"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "narew-vistula-bridgeheads",
            order: 7,
            title: "Narew and Vistula Bridgeheads",
            start: date(1944, 8, 1),
            end: date(1945, 1, 11),
            label: "1 Aug 1944-11 Jan 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet bridgehead defenders expanding lodgments before the winter offensive.",
            geography: ["Magnuszew bridgehead", "Pulawy bridgehead", "Narew crossings", "Warsaw approaches"],
            framing: "A staff-influence defensive-preparation scenario where the player grows Soviet bridgeheads.",
            reason: "Creates the setup battlefield for the Vistula-Oder offensive.",
            sources: [
                careerSource("Vistula-Oder Offensive", "https://en.wikipedia.org/wiki/Vistula%E2%80%93Oder_Offensive"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "warsaw-defensive-arcs",
            order: 8,
            title: "Warsaw-Area Defensive Arcs",
            start: date(1944, 8, 1),
            end: date(1945, 1, 17),
            label: "1 Aug 1944-17 Jan 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet and Polish-aligned forces pressuring Warsaw approaches, Vistula crossings, and German defensive belts.",
            geography: ["Warsaw approaches", "Vistula crossings", "Modlin and Praga arcs", "road and rail defensive belts"],
            framing: "A General Staff context scenario where the player breaks Warsaw-area defensive arcs without treating Guderian as a field commander.",
            reason: "Fills the 1944 Warsaw-area defensive arc named in the late-career plan between bridgehead preparation and the Vistula-Oder breakthrough.",
            sources: [
                careerSource("Warsaw Uprising", "https://en.wikipedia.org/wiki/Warsaw_Uprising"),
                careerSource("Vistula-Oder Offensive", "https://en.wikipedia.org/wiki/Vistula%E2%80%93Oder_Offensive"),
            ]
        ),
        candidate(
            "vistula-oder-breakthrough",
            order: 9,
            title: "Vistula-Oder Breakthrough",
            start: date(1945, 1, 12),
            end: date(1945, 2, 2),
            label: "12 Jan-2 Feb 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet breakthrough and pursuit forces racing from Vistula bridgeheads toward the Oder.",
            geography: ["Vistula bridgeheads", "Lodz road net", "Warta crossings", "Oder approaches"],
            framing: "A General Staff context scenario about German front collapse under Soviet operational pressure.",
            reason: "Core final-campaign battlefield for the withdrawal from the east.",
            sources: [
                careerSource("Vistula-Oder Offensive", "https://en.wikipedia.org/wiki/Vistula%E2%80%93Oder_Offensive"),
                careerSource("The Soviet advance to the Oder, January-February 1945", "https://www.britannica.com/event/World-War-II/The-Soviet-advance-to-the-Oder-January-February-1945"),
            ]
        ),
        candidate(
            "poznan-corridor",
            order: 10,
            title: "Poznan Corridor and Encirclement",
            start: date(1945, 1, 24),
            end: date(1945, 2, 23),
            label: "24 Jan-23 Feb 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet assault and bypass groups isolating fortress-city defenses.",
            geography: ["Poznan fortress", "Warta River", "Berlin road corridor", "rail junctions"],
            framing: "A staff-level collapse scenario focused on bypass, isolation, and fortress reduction.",
            reason: "Adds urban and river geography between the Vistula-Oder dash and the Oder line.",
            sources: [
                careerSource("Battle of Poznan (1945)", "https://en.wikipedia.org/wiki/Battle_of_Pozna%C5%84_(1945)"),
                careerSource("Vistula-Oder Offensive", "https://en.wikipedia.org/wiki/Vistula%E2%80%93Oder_Offensive"),
            ]
        ),
        candidate(
            "east-prussia-elbing",
            order: 11,
            title: "East Prussia and Elbing Cutoff",
            start: date(1945, 1, 13),
            end: date(1945, 4, 25),
            label: "13 Jan-25 Apr 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet forces cutting coastal roads, lagoon exits, and fortress pockets.",
            geography: ["Vistula Lagoon", "Elbing corridor", "Konigsberg approaches", "coastal evacuation routes"],
            framing: "A General Staff context scenario about the northern collapse and evacuation geography.",
            reason: "Broadens the final battles beyond the Berlin axis with water-heavy map detail.",
            sources: [
                careerSource("East Prussian Offensive", "https://en.wikipedia.org/wiki/East_Prussian_Offensive"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "operation-solstice",
            order: 12,
            title: "Operation Solstice at Stargard",
            start: date(1945, 2, 15),
            end: date(1945, 2, 18),
            label: "15-18 Feb 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet defenders and counterattack groups containing German relief attacks.",
            geography: ["Stargard", "Arnswalde", "Pomeranian road net", "Oder flank approaches"],
            framing: "A General Staff/Army Group Vistula context scenario about the failed German counterstroke.",
            reason: "Connects Guderian's late staff conflict to a concrete, playable final-war battlefield.",
            sources: [
                careerSource("Operation Solstice", "https://en.wikipedia.org/wiki/Operation_Solstice"),
                careerSource("Army Group Vistula", "https://en.wikipedia.org/wiki/Army_Group_Vistula"),
            ]
        ),
        candidate(
            "east-pomeranian-offensive",
            order: 13,
            title: "East Pomeranian Offensive",
            start: date(1945, 2, 24),
            end: date(1945, 4, 4),
            label: "24 Feb-4 Apr 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet and Polish forces clearing the Baltic flank before Berlin.",
            geography: ["Kolberg coast", "Danzig approaches", "Oder flank", "Pomeranian lakes"],
            framing: "A late General Staff context scenario that clears the northern flank of the Berlin approach.",
            reason: "Adds Baltic-coast water geography and flank-security gameplay to the final arc.",
            sources: [
                careerSource("East Pomeranian Offensive", "https://en.wikipedia.org/wiki/East_Pomeranian_Offensive"),
                careerSource("Army Group Vistula", "https://en.wikipedia.org/wiki/Army_Group_Vistula"),
            ]
        ),
        candidate(
            "kustrin-oder-bridgeheads",
            order: 14,
            title: "Kustrin and Oder Bridgeheads",
            start: date(1945, 2, 1),
            end: date(1945, 3, 30),
            label: "1 Feb-30 Mar 1945",
            scope: .armyGeneralStaffInfluence,
            playerRole: "Soviet bridgehead forces expanding west-bank positions toward Berlin.",
            geography: ["Oder River", "Kustrin fortress", "Seelow approaches", "Reitwein spur"],
            framing: "A final General Staff context scenario ending around Guderian's dismissal from staff command.",
            reason: "Builds the river-crossing and bridgehead map needed before the Berlin offensive.",
            sources: [
                careerSource("Battle of Kustrin", "https://en.wikipedia.org/wiki/Battle_of_K%C3%BCstrin"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "seelow-heights-epilogue",
            order: 15,
            title: "Seelow Heights Epilogue",
            start: date(1945, 4, 16),
            end: date(1945, 4, 19),
            label: "16-19 Apr 1945",
            scope: .postDismissalContext,
            playerRole: "Soviet assault armies breaking the Oder-Seelow defensive belt.",
            geography: ["Oderbruch", "Seelow Heights", "Reitwein spur", "Berlin road"],
            framing: "A post-dismissal epilogue scenario: playable only as final-war context after Guderian leaves office.",
            reason: "Lets the campaign show the last Berlin approach while clearly removing Guderian from command.",
            sources: [
                careerSource("Battle of the Seelow Heights", "https://en.wikipedia.org/wiki/Battle_of_the_Seelow_Heights"),
                careerSource("Heinz Guderian", "https://en.wikipedia.org/wiki/Heinz_Guderian"),
            ]
        ),
        candidate(
            "berlin-halbe-epilogue",
            order: 16,
            title: "Berlin and Halbe Epilogue",
            start: date(1945, 4, 20),
            end: date(1945, 5, 2),
            label: "20 Apr-2 May 1945",
            scope: .postDismissalContext,
            playerRole: "Soviet, Polish, and Allied-aligned forces reducing the final pockets and escape attempts.",
            geography: ["Berlin urban districts", "Spree crossings", "Teltow Canal", "Halbe forest roads"],
            framing: "A post-dismissal closing context scenario, not a Guderian battle.",
            reason: "Provides final-war closure only if the UI keeps the command-caveat label visible.",
            sources: [
                careerSource("Battle of Berlin", "https://en.wikipedia.org/wiki/Battle_of_Berlin"),
                careerSource("Battle of Halbe", "https://en.wikipedia.org/wiki/Battle_of_Halbe"),
            ]
        ),
    ]

    public static let lateCareerSetACandidateIDs: [String] = [
        "kursk-armored-force-pressure",
        "dnieper-withdrawal",
        "korsun-cherkassy-pocket",
        "kamenets-podolsky-pocket",
    ]

    public static var lateCareerSetAExpansionCandidates: [GuderianCareerExpansionCandidate] {
        lateCareerSetACandidateIDs.compactMap(expansionCandidate)
    }

    public static let lateCareerSetBCandidateIDs: [String] = [
        "operation-bagration-withdrawal",
        "lvov-sandomierz",
        "narew-vistula-bridgeheads",
        "warsaw-defensive-arcs",
    ]

    public static var lateCareerSetBExpansionCandidates: [GuderianCareerExpansionCandidate] {
        lateCareerSetBCandidateIDs.compactMap(expansionCandidate)
    }

    public static let lateCareerSetCCandidateIDs: [String] = [
        "vistula-oder-breakthrough",
        "poznan-corridor",
        "east-prussia-elbing",
        "kustrin-oder-bridgeheads",
    ]

    public static var lateCareerSetCExpansionCandidates: [GuderianCareerExpansionCandidate] {
        lateCareerSetCCandidateIDs.compactMap(expansionCandidate)
    }

    public static let lateCareerSetDCandidateIDs: [String] = [
        "operation-solstice",
        "east-pomeranian-offensive",
        "seelow-heights-epilogue",
        "berlin-halbe-epilogue",
    ]

    public static var lateCareerSetDExpansionCandidates: [GuderianCareerExpansionCandidate] {
        lateCareerSetDCandidateIDs.compactMap(expansionCandidate)
    }

    public static var lateCareerBattlefieldCandidateIDs: [String] {
        lateCareerExpansionCandidates.map(\.id)
    }

    public static let allCurrentScenarioIDs: Set<GuderianBattleID> = Set(
        currentScenarioRecords.flatMap(\.scenarioIDs)
    )

    public static var directCommandScenarioIDs: [GuderianBattleID] {
        currentScenarioRecords
            .filter { $0.scope.allowsDirectBattlefieldScenario }
            .flatMap(\.scenarioIDs)
    }

    public static var caveatedCurrentScenarioIDs: [GuderianBattleID] {
        currentScenarioRecords
            .filter(\.requiresCommandCaveat)
            .flatMap(\.scenarioIDs)
    }

    public static func record(for id: GuderianBattleID) -> GuderianCareerScopeRecord? {
        currentScenarioRecords.first { $0.scenarioIDs.contains(id) }
    }

    public static func expansionCandidate(for id: String) -> GuderianCareerExpansionCandidate? {
        lateCareerExpansionCandidates.first { $0.id == id }
    }
}

private func currentRecord(
    _ id: String,
    _ title: String,
    start: ScenarioDateKey,
    end: ScenarioDateKey,
    label: String,
    scope: GuderianCommandScope,
    commandRole: String,
    playableFraming: String,
    scenarioIDs: [GuderianBattleID],
    sources: [ScenarioSource]
) -> GuderianCareerScopeRecord {
    GuderianCareerScopeRecord(
        id: id,
        title: title,
        dateRange: range(start, end, label),
        scope: scope,
        commandRole: commandRole,
        playableFraming: playableFraming,
        scenarioIDs: scenarioIDs,
        sourceLinks: sources
    )
}

private func candidate(
    _ id: String,
    order: Int,
    title: String,
    start: ScenarioDateKey,
    end: ScenarioDateKey,
    label: String,
    scope: GuderianCommandScope,
    playerRole: String,
    geography: [String],
    framing: String,
    reason: String,
    sources: [ScenarioSource]
) -> GuderianCareerExpansionCandidate {
    GuderianCareerExpansionCandidate(
        id: id,
        order: order,
        title: title,
        dateRange: range(start, end, label),
        scope: scope,
        playerRole: playerRole,
        geographyFocus: geography,
        playableFraming: framing,
        inclusionReason: reason,
        sourceLinks: sources
    )
}

private func range(
    _ start: ScenarioDateKey,
    _ end: ScenarioDateKey,
    _ label: String
) -> GuderianCareerDateRange {
    GuderianCareerDateRange(start: start, end: end, label: label)
}

private func date(_ year: Int, _ month: Int, _ day: Int) -> ScenarioDateKey {
    ScenarioDateKey(year: year, month: month, day: day)
}

private func careerSource(_ title: String, _ urlString: String) -> ScenarioSource {
    guard let url = URL(string: urlString) else {
        preconditionFailure("Invalid source URL: \(urlString)")
    }
    return ScenarioSource(title: title, url: url)
}
