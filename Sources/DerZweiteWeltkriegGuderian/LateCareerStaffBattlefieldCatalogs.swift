import Foundation

public enum LateCareerStaffBattlefieldSetBCatalog {
    public static let cycleRange = 631...635
    public static let battlefieldIDs = GuderianCareerScopeCatalog.lateCareerSetBCandidateIDs

    public static let allBattlefields: [LateCareerStaffBattlefield] = [
        lateContextBattlefield(
            "operation-bagration-withdrawal",
            germanContext: "Army Group Centre collapse and withdrawal-route crisis around the later General Staff transition.",
            map: lateContextMap(
                prefix: "bagration",
                title: "Operation Bagration Withdrawal Crisis Staff Map",
                sourceTitle: "Operation Bagration source",
                sourceURL: "https://en.wikipedia.org/wiki/Operation_Bagration",
                water: ["Berezina River", "Pripet wetland edge"],
                roads: ["Minsk withdrawal highway", "Borisov road", "Pripet flank road"],
                railway: "Minsk rail escape corridor",
                crossings: ["Berezina bridge", "Borisov ford", "Pripet ferry reach"],
                settlements: ["Minsk rail district", "Borisov", "Bobruisk", "Mogilev"],
                terrain: ["Pripet marsh belt", "Berezina forest screen", "Minsk ridge line"],
                fortified: "Army Group Centre rear line",
                bunker: "Borisov strongpoint",
                playerObjective: "Minsk encirclement gate",
                playerSupportObjective: "Rail escape cut marker",
                germanObjective: "German withdrawal exit",
                pressure: "Soviet pincer pressure",
                phaseLines: ["Berezina collapse phase line", "Minsk isolation phase line"],
                playerZone: "Soviet breakthrough fronts",
                germanZone: "German withdrawal columns"
            ),
            playerForceName: "Soviet Front breakthrough groups",
            germanForceName: "Army Group Centre withdrawal groups",
            playerObjectiveName: "Destroy withdrawal routes",
            playerSupportObjectiveName: "Cut Minsk rail exits",
            denialObjectiveName: "Seal Berezina crossings",
            germanObjectiveName: "Preserve German escape corridors"
        ),
        lateContextBattlefield(
            "lvov-sandomierz",
            germanContext: "General Staff context around Soviet breakthrough, Lvov road pressure, and Sandomierz bridgehead creation.",
            map: lateContextMap(
                prefix: "lvov-sandomierz",
                title: "Lvov-Sandomierz Breakthrough Staff Map",
                sourceTitle: "Lvov-Sandomierz source",
                sourceURL: "https://en.wikipedia.org/wiki/Lvov%E2%80%93Sandomierz_Offensive",
                water: ["Vistula River", "San River approach"],
                roads: ["Lvov road net", "Sandomierz road", "Carpathian approach road"],
                railway: "Lvov-Przemysl rail corridor",
                crossings: ["Sandomierz bridgehead bridge", "San ford", "Vistula ferry reach"],
                settlements: ["Lvov urban district", "Sandomierz", "Przemysl", "Rava-Ruska"],
                terrain: ["Carpathian foothill marsh", "Lvov forest belt", "Sandomierz ridge"],
                fortified: "German Galicia defensive line",
                bunker: "Bridgehead bunker belt",
                playerObjective: "Sandomierz bridgehead",
                playerSupportObjective: "Lvov pursuit lane",
                germanObjective: "German bridgehead containment",
                pressure: "Soviet operational pursuit pressure",
                phaseLines: ["Lvov breakout phase line", "Vistula bridgehead phase line"],
                playerZone: "Soviet assault and pursuit groups",
                germanZone: "German containment reserves"
            ),
            playerForceName: "Soviet breakthrough and bridgehead forces",
            germanForceName: "German Galicia containment groups",
            playerObjectiveName: "Open the Sandomierz bridgehead",
            playerSupportObjectiveName: "Exploit Lvov pursuit lanes",
            denialObjectiveName: "Cut German containment rail",
            germanObjectiveName: "Contain the bridgehead"
        ),
        lateContextBattlefield(
            "narew-vistula-bridgeheads",
            germanContext: "General Staff context for the bridgeheads that set up the winter 1945 offensive.",
            map: lateContextMap(
                prefix: "narew-vistula",
                title: "Narew and Vistula Bridgeheads Staff Map",
                sourceTitle: "Vistula-Oder setup source",
                sourceURL: "https://en.wikipedia.org/wiki/Vistula%E2%80%93Oder_Offensive",
                water: ["Vistula River", "Narew River"],
                roads: ["Magnuszew lodgment road", "Pulawy bridgehead road", "Warsaw approach road"],
                railway: "Warsaw-Lublin rail corridor",
                crossings: ["Magnuszew bridge", "Pulawy ford", "Narew ferry reach"],
                settlements: ["Magnuszew bridgehead district", "Pulawy", "Rozan", "Serock"],
                terrain: ["Vistula marsh islands", "Narew forest belt", "Warsaw approach ridge"],
                fortified: "German river containment line",
                bunker: "Bridgehead artillery bunker",
                playerObjective: "Expand Magnuszew lodgment",
                playerSupportObjective: "Hold Pulawy road exit",
                germanObjective: "German bridgehead reduction",
                pressure: "Soviet bridgehead expansion pressure",
                phaseLines: ["Bridgehead expansion phase line", "Winter offensive start line"],
                playerZone: "Soviet bridgehead defenders",
                germanZone: "German containment arcs"
            ),
            playerForceName: "Soviet bridgehead defenders and engineers",
            germanForceName: "German river-containment groups",
            playerObjectiveName: "Expand bridgehead lodgments",
            playerSupportObjectiveName: "Protect winter offensive exits",
            denialObjectiveName: "Deny German bridgehead reduction",
            germanObjectiveName: "Compress the bridgeheads"
        ),
        lateContextBattlefield(
            "warsaw-defensive-arcs",
            germanContext: "General Staff context for Warsaw-area defensive belts, Vistula crossings, and road-rail arcs before January 1945.",
            map: lateContextMap(
                prefix: "warsaw-arcs",
                title: "Warsaw-Area Defensive Arcs Staff Map",
                sourceTitle: "Warsaw and Vistula source",
                sourceURL: "https://en.wikipedia.org/wiki/Warsaw_Uprising",
                water: ["Vistula River Warsaw reach", "Bug-Narew confluence"],
                roads: ["Praga road arc", "Modlin road", "Warsaw western approach road"],
                railway: "Warsaw rail ring",
                crossings: ["Praga bridge", "Modlin ford", "Vistula ferry sector"],
                settlements: ["Warsaw urban district", "Praga", "Modlin", "Radzymin"],
                terrain: ["Vistula island marsh", "Kampinos forest belt", "Warsaw ridge arc"],
                fortified: "German Warsaw defensive arc",
                bunker: "Modlin fortress sector",
                playerObjective: "Break Praga defensive arc",
                playerSupportObjective: "Cut Warsaw rail ring",
                germanObjective: "German Warsaw hold line",
                pressure: "Soviet Warsaw approach pressure",
                phaseLines: ["Praga entry phase line", "Warsaw isolation phase line"],
                playerZone: "Soviet and Polish-aligned pressure groups",
                germanZone: "German Warsaw defense arcs"
            ),
            playerForceName: "Soviet and Polish-aligned Warsaw approach groups",
            germanForceName: "German Warsaw-area defense groups",
            playerObjectiveName: "Break Warsaw defensive arcs",
            playerSupportObjectiveName: "Open Vistula crossings",
            denialObjectiveName: "Cut road and rail belts",
            germanObjectiveName: "Hold Warsaw-area arcs"
        ),
    ]

    public static var allBattlefieldsReady: Bool {
        allBattlefields.count == battlefieldIDs.count &&
            allBattlefields.map(\.id) == battlefieldIDs &&
            allBattlefields.allSatisfy(\.isLateCareerReady) &&
            allBattlefields.allSatisfy { $0.scope == .armyGeneralStaffInfluence }
    }

    public static func battlefield(for id: String) -> LateCareerStaffBattlefield? {
        allBattlefields.first { $0.id == id }
    }
}

public enum LateCareerStaffBattlefieldSetCCatalog {
    public static let cycleRange = 636...640
    public static let battlefieldIDs = GuderianCareerScopeCatalog.lateCareerSetCCandidateIDs

    public static let allBattlefields: [LateCareerStaffBattlefield] = [
        lateContextBattlefield(
            "vistula-oder-breakthrough",
            germanContext: "General Staff context for the January 1945 front collapse from Vistula bridgeheads toward the Oder.",
            map: lateContextMap(
                prefix: "vistula-oder",
                title: "Vistula-Oder Breakthrough Staff Map",
                sourceTitle: "Vistula-Oder source",
                sourceURL: "https://en.wikipedia.org/wiki/Vistula%E2%80%93Oder_Offensive",
                water: ["Vistula River bridgehead line", "Warta River"],
                roads: ["Lodz road net", "Poznan-Berlin road", "Oder approach road"],
                railway: "Lodz-Poznan rail corridor",
                crossings: ["Vistula bridgehead bridge", "Warta ford", "Oder ferry approach"],
                settlements: ["Lodz urban district", "Kalisz", "Kutno", "Poznan eastern suburb"],
                terrain: ["Vistula winter marsh", "Warta forest belt", "Oder approach ridge"],
                fortified: "German A-line defense belt",
                bunker: "Lodz roadblock bunker",
                playerObjective: "Exploit Lodz breakthrough",
                playerSupportObjective: "Seize Warta crossings",
                germanObjective: "German Oder delay exit",
                pressure: "Soviet deep-pursuit pressure",
                phaseLines: ["Lodz breakthrough phase line", "Oder pursuit phase line"],
                playerZone: "Soviet breakthrough armies",
                germanZone: "German delay and withdrawal groups"
            ),
            playerForceName: "Soviet breakthrough and pursuit forces",
            germanForceName: "German General Staff withdrawal groups",
            playerObjectiveName: "Race from the Vistula to the Oder",
            playerSupportObjectiveName: "Seize Warta and rail exits",
            denialObjectiveName: "Collapse German delay belts",
            germanObjectiveName: "Preserve Oder delay space"
        ),
        lateContextBattlefield(
            "poznan-corridor",
            germanContext: "General Staff context for fortress-city isolation and bypass pressure between the Warta and Berlin road.",
            map: lateContextMap(
                prefix: "poznan",
                title: "Poznan Corridor and Encirclement Staff Map",
                sourceTitle: "Poznan source",
                sourceURL: "https://en.wikipedia.org/wiki/Battle_of_Pozna%C5%84_(1945)",
                water: ["Warta River", "Cybina stream line"],
                roads: ["Poznan bypass road", "Berlin corridor road", "Fortress ring road"],
                railway: "Poznan rail junction",
                crossings: ["Warta bridge", "Cybina ford", "Fortress ferry reach"],
                settlements: ["Poznan fortress district", "Cytadela", "Swarzedz", "Lubon"],
                terrain: ["Warta marsh bank", "Fortress park woods", "Berlin road ridge"],
                fortified: "Poznan fortress perimeter",
                bunker: "Cytadela bunker sector",
                playerObjective: "Isolate Poznan fortress",
                playerSupportObjective: "Open Berlin road corridor",
                germanObjective: "German fortress holdout",
                pressure: "Soviet bypass pressure",
                phaseLines: ["Fortress isolation phase line", "Berlin corridor phase line"],
                playerZone: "Soviet assault and bypass groups",
                germanZone: "German fortress and corridor defense"
            ),
            playerForceName: "Soviet assault and bypass groups",
            germanForceName: "German fortress-city defenders",
            playerObjectiveName: "Isolate the fortress city",
            playerSupportObjectiveName: "Open the Berlin corridor",
            denialObjectiveName: "Cut rail junction traffic",
            germanObjectiveName: "Hold fortress districts"
        ),
        lateContextBattlefield(
            "east-prussia-elbing",
            germanContext: "General Staff context for the northern collapse, lagoon exits, and Elbing coastal cutoff.",
            map: lateContextMap(
                prefix: "east-prussia",
                title: "East Prussia and Elbing Cutoff Staff Map",
                sourceTitle: "East Prussian Offensive source",
                sourceURL: "https://en.wikipedia.org/wiki/East_Prussian_Offensive",
                water: ["Vistula Lagoon", "Pregel River"],
                roads: ["Elbing coastal road", "Konigsberg approach road", "Lagoon evacuation road"],
                railway: "Elbing-Konigsberg rail corridor",
                crossings: ["Pregel bridge", "Lagoon causeway ford", "Elbing ferry reach"],
                settlements: ["Konigsberg fortress district", "Elbing", "Braunsberg", "Heiligenbeil"],
                terrain: ["Lagoon marsh shore", "East Prussian forest belt", "Konigsberg ridge"],
                fortified: "Konigsberg outer defense line",
                bunker: "Elbing roadblock bunker",
                playerObjective: "Cut Elbing corridor",
                playerSupportObjective: "Seal lagoon evacuation routes",
                germanObjective: "German coastal evacuation exit",
                pressure: "Soviet coastal cutoff pressure",
                phaseLines: ["Elbing cutoff phase line", "Lagoon pocket phase line"],
                playerZone: "Soviet northern-front groups",
                germanZone: "German coastal pocket groups"
            ),
            playerForceName: "Soviet northern-front and coastal cutoff forces",
            germanForceName: "German East Prussia pocket groups",
            playerObjectiveName: "Cut the Elbing corridor",
            playerSupportObjectiveName: "Seal lagoon exits",
            denialObjectiveName: "Isolate fortress pockets",
            germanObjectiveName: "Keep coastal evacuation routes open"
        ),
        lateContextBattlefield(
            "kustrin-oder-bridgeheads",
            germanContext: "General Staff context ending near Guderian's dismissal, centered on Oder bridgeheads and Kustrin fortress pressure.",
            map: lateContextMap(
                prefix: "kustrin",
                title: "Kustrin and Oder Bridgeheads Staff Map",
                sourceTitle: "Kustrin source",
                sourceURL: "https://en.wikipedia.org/wiki/Battle_of_K%C3%BCstrin",
                water: ["Oder River", "Warthe confluence"],
                roads: ["Kustrin-Seelow road", "Berlin approach road", "Reitwein spur road"],
                railway: "Kustrin rail junction",
                crossings: ["Oder bridgehead bridge", "Warthe ford", "Kustrin ferry reach"],
                settlements: ["Kustrin fortress district", "Reitwein", "Letschin", "Seelow approach village"],
                terrain: ["Oderbruch marsh", "Reitwein woods", "Seelow approach ridge"],
                fortified: "Kustrin fortress perimeter",
                bunker: "Oder bridgehead bunker belt",
                playerObjective: "Expand Oder bridgehead",
                playerSupportObjective: "Isolate Kustrin fortress",
                germanObjective: "German bridgehead counterattack",
                pressure: "Soviet Berlin-approach pressure",
                phaseLines: ["Oder expansion phase line", "Seelow approach phase line"],
                playerZone: "Soviet Oder bridgehead forces",
                germanZone: "German Kustrin and Oder defense"
            ),
            playerForceName: "Soviet Oder bridgehead forces",
            germanForceName: "German Kustrin and Oder defense groups",
            playerObjectiveName: "Expand the Oder bridgeheads",
            playerSupportObjectiveName: "Isolate Kustrin",
            denialObjectiveName: "Break counterattack routes",
            germanObjectiveName: "Contain the west-bank lodgment"
        ),
    ]

    public static var allBattlefieldsReady: Bool {
        allBattlefields.count == battlefieldIDs.count &&
            allBattlefields.map(\.id) == battlefieldIDs &&
            allBattlefields.allSatisfy(\.isLateCareerReady) &&
            allBattlefields.allSatisfy { $0.scope == .armyGeneralStaffInfluence }
    }

    public static func battlefield(for id: String) -> LateCareerStaffBattlefield? {
        allBattlefields.first { $0.id == id }
    }
}

public enum LateCareerStaffBattlefieldSetDCatalog {
    public static let cycleRange = 641...645
    public static let battlefieldIDs = GuderianCareerScopeCatalog.lateCareerSetDCandidateIDs

    public static let allBattlefields: [LateCareerStaffBattlefield] = [
        lateContextBattlefield(
            "operation-solstice",
            germanContext: "General Staff and Army Group Vistula context for the failed Stargard counterstroke.",
            map: lateContextMap(
                prefix: "solstice",
                title: "Operation Solstice at Stargard Staff Map",
                sourceTitle: "Operation Solstice source",
                sourceURL: "https://en.wikipedia.org/wiki/Operation_Solstice",
                water: ["Ina River", "Madusee lake line"],
                roads: ["Stargard road", "Arnswalde relief road", "Pomeranian flank road"],
                railway: "Stargard rail corridor",
                crossings: ["Ina bridge", "Madusee causeway ford", "Arnswalde ferry reach"],
                settlements: ["Stargard urban district", "Arnswalde", "Pyritz", "Reetz"],
                terrain: ["Pomeranian lake marsh", "Stargard forest belt", "Arnswalde ridge"],
                fortified: "Soviet blocking line",
                bunker: "German relief assembly bunker",
                playerObjective: "Contain Solstice counterstroke",
                playerSupportObjective: "Hold Arnswalde roadblock",
                germanObjective: "German relief attack exit",
                pressure: "German counterstroke pressure",
                phaseLines: ["Stargard containment phase line", "Arnswalde relief phase line"],
                playerZone: "Soviet blocking and counterattack groups",
                germanZone: "German relief attack groups"
            ),
            playerForceName: "Soviet blocking and counterattack groups",
            germanForceName: "German Operation Solstice attack groups",
            playerObjectiveName: "Contain the counterstroke",
            playerSupportObjectiveName: "Hold Arnswalde roadblocks",
            denialObjectiveName: "Deny relief contact",
            germanObjectiveName: "Break out from Stargard"
        ),
        lateContextBattlefield(
            "east-pomeranian-offensive",
            germanContext: "General Staff context for clearing the Baltic flank before the Berlin operation.",
            map: lateContextMap(
                prefix: "east-pomeranian",
                title: "East Pomeranian Offensive Staff Map",
                sourceTitle: "East Pomeranian source",
                sourceURL: "https://en.wikipedia.org/wiki/East_Pomeranian_Offensive",
                water: ["Baltic coast line", "Pomeranian lake chain"],
                roads: ["Kolberg coastal road", "Danzig approach road", "Oder flank road"],
                railway: "Danzig-Kolberg rail corridor",
                crossings: ["Lake causeway bridge", "Oder flank ford", "Coastal ferry reach"],
                settlements: ["Danzig urban district", "Kolberg", "Stolp", "Koeslin"],
                terrain: ["Coastal marsh belt", "Pomeranian forest belt", "Danzig ridge"],
                fortified: "Baltic port defense line",
                bunker: "Kolberg fortress bunker",
                playerObjective: "Clear Baltic flank",
                playerSupportObjective: "Cut Danzig rail approach",
                germanObjective: "German coastal pocket exit",
                pressure: "Soviet and Polish coastal pressure",
                phaseLines: ["Pomeranian lake phase line", "Baltic pocket phase line"],
                playerZone: "Soviet and Polish coastal clearing groups",
                germanZone: "German Baltic flank defense"
            ),
            playerForceName: "Soviet and Polish coastal clearing forces",
            germanForceName: "German Baltic flank and port defense groups",
            playerObjectiveName: "Clear the Baltic flank",
            playerSupportObjectiveName: "Cut port rail approaches",
            denialObjectiveName: "Seal coastal pockets",
            germanObjectiveName: "Preserve evacuation pockets"
        ),
        lateContextBattlefield(
            "seelow-heights-epilogue",
            germanContext: "Post-dismissal epilogue context for the Oder-Seelow defensive belt after Guderian leaves office.",
            map: lateContextMap(
                prefix: "seelow",
                title: "Seelow Heights Epilogue Staff Map",
                sourceTitle: "Seelow Heights source",
                sourceURL: "https://en.wikipedia.org/wiki/Battle_of_the_Seelow_Heights",
                water: ["Oder River", "Oderbruch flood plain"],
                roads: ["Seelow-Berlin road", "Reitwein spur road", "Kustrin approach road"],
                railway: "Seelow rail approach",
                crossings: ["Oder bridgehead bridge", "Oderbruch ford", "Reitwein ferry reach"],
                settlements: ["Seelow heights district", "Reitwein", "Manschnow", "Kustrin approach village"],
                terrain: ["Oderbruch marsh", "Seelow forest belt", "Seelow ridge heights"],
                fortified: "Seelow defensive belt",
                bunker: "Heights bunker line",
                playerObjective: "Break Seelow heights",
                playerSupportObjective: "Open Berlin road",
                germanObjective: "German heights defense",
                pressure: "Soviet artillery and assault pressure",
                phaseLines: ["Oderbruch assault phase line", "Berlin road phase line"],
                playerZone: "Soviet assault armies",
                germanZone: "German post-dismissal defense context"
            ),
            playerForceName: "Soviet assault armies",
            germanForceName: "German Seelow defense groups",
            playerObjectiveName: "Break the heights",
            playerSupportObjectiveName: "Open the Berlin road",
            denialObjectiveName: "Collapse the defensive belt",
            germanObjectiveName: "Hold the heights"
        ),
        lateContextBattlefield(
            "berlin-halbe-epilogue",
            germanContext: "Post-dismissal closing context for Berlin urban reduction and Halbe escape attempts.",
            map: lateContextMap(
                prefix: "berlin-halbe",
                title: "Berlin and Halbe Epilogue Staff Map",
                sourceTitle: "Berlin and Halbe source",
                sourceURL: "https://en.wikipedia.org/wiki/Battle_of_Berlin",
                water: ["Spree River", "Teltow Canal"],
                roads: ["Berlin inner ring road", "Halbe forest escape road", "Potsdam approach road"],
                railway: "Berlin rail ring",
                crossings: ["Spree bridge", "Teltow canal ford", "Halbe ferry reach"],
                settlements: ["Berlin urban district", "Potsdam", "Halbe", "Zossen"],
                terrain: ["Spree marsh bank", "Halbe forest belt", "Tempelhof ridge"],
                fortified: "Berlin inner defense ring",
                bunker: "Urban bunker sector",
                playerObjective: "Reduce Berlin districts",
                playerSupportObjective: "Block Halbe escape road",
                germanObjective: "German breakout pocket",
                pressure: "Soviet and Allied-aligned final assault pressure",
                phaseLines: ["Berlin ring phase line", "Halbe pocket phase line"],
                playerZone: "Soviet and Polish-aligned final assault groups",
                germanZone: "German Berlin and Halbe pocket groups"
            ),
            playerForceName: "Soviet, Polish, and Allied-aligned final assault groups",
            germanForceName: "German Berlin and Halbe pocket groups",
            playerObjectiveName: "Reduce final urban pockets",
            playerSupportObjectiveName: "Block Halbe escape roads",
            denialObjectiveName: "Seal canal and forest routes",
            germanObjectiveName: "Open a breakout pocket"
        ),
    ]

    public static var allBattlefieldsReady: Bool {
        allBattlefields.count == battlefieldIDs.count &&
            allBattlefields.map(\.id) == battlefieldIDs &&
            allBattlefields.allSatisfy(\.isLateCareerReady) &&
            allBattlefields.filter { $0.scope == .postDismissalContext }.count == 2 &&
            allBattlefields.allSatisfy { $0.visibleCommandCaveatLabel.contains($0.scope.rawValue) }
    }

    public static func battlefield(for id: String) -> LateCareerStaffBattlefield? {
        allBattlefields.first { $0.id == id }
    }
}

public struct LateCareerStaffBattlefieldAcceptanceReport: Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let currentPlayableBattleCount: Int
    public let routedPlayableBattleCount: Int
    public let lateCareerBattlefieldCount: Int
    public let commandCaveatCount: Int
    public let postDismissalBattlefieldCount: Int
    public let currentCampaignMapDetailReady: Bool
    public let allLateCareerBattlefieldsReady: Bool
    public let allBattlefieldIDsMatchLedger: Bool
    public let visibleCommandCaveatLabels: [String]

    public var isReadyForAcceptance: Bool {
        cycleStart == 646 &&
            cycleEnd == 650 &&
            currentPlayableBattleCount == 19 &&
            routedPlayableBattleCount == currentPlayableBattleCount &&
            lateCareerBattlefieldCount == commandCaveatCount &&
            postDismissalBattlefieldCount >= 2 &&
            currentCampaignMapDetailReady &&
            allLateCareerBattlefieldsReady &&
            allBattlefieldIDsMatchLedger &&
            visibleCommandCaveatLabels.allSatisfy { $0.localizedCaseInsensitiveContains("not a Guderian field command") }
    }
}

public enum LateCareerStaffBattlefieldAcceptanceCatalog {
    public static let cycleRange = 646...650

    public static var allLateCareerBattlefields: [LateCareerStaffBattlefield] {
        (
            LateCareerStaffBattlefieldSetACatalog.allBattlefields +
                LateCareerStaffBattlefieldSetBCatalog.allBattlefields +
                LateCareerStaffBattlefieldSetCCatalog.allBattlefields +
                LateCareerStaffBattlefieldSetDCatalog.allBattlefields
        )
        .sorted { $0.order < $1.order }
    }

    public static var allLateCareerBattlefieldIDs: [String] {
        allLateCareerBattlefields.map(\.id)
    }

    public static var allBattlefieldIDsMatchLedger: Bool {
        allLateCareerBattlefieldIDs == GuderianCareerScopeCatalog.lateCareerBattlefieldCandidateIDs
    }

    public static var currentCampaignMapDetailReady: Bool {
        GuderianCampaignCatalog.all.allSatisfy { scenario in
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let metrics = ScenarioMapDetailMetrics(layout: layout)

            return metrics.mapFeatureCount >= 24 &&
                metrics.count(for: .water) >= 2 &&
                metrics.count(for: .roads) >= 3 &&
                metrics.count(for: .railways) >= 1 &&
                metrics.count(for: .crossings) >= 2 &&
                metrics.count(for: .settlements) >= 3 &&
                metrics.count(for: .groundTerrain) >= 3 &&
                metrics.count(for: .sourceNotes) >= 1 &&
                layout.elements.allSatisfy { !$0.note.isEmpty }
        }
    }

    public static var report: LateCareerStaffBattlefieldAcceptanceReport {
        let lateCareer = allLateCareerBattlefields

        return LateCareerStaffBattlefieldAcceptanceReport(
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            currentPlayableBattleCount: GuderianCampaignCatalog.all.count,
            routedPlayableBattleCount: PlayableBattleSurfaceCatalog.routedBattleIDs.count,
            lateCareerBattlefieldCount: lateCareer.count,
            commandCaveatCount: lateCareer.filter(\.requiresCommandCaveat).count,
            postDismissalBattlefieldCount: lateCareer.filter { $0.scope == .postDismissalContext }.count,
            currentCampaignMapDetailReady: currentCampaignMapDetailReady,
            allLateCareerBattlefieldsReady: lateCareer.allSatisfy(\.isLateCareerReady),
            allBattlefieldIDsMatchLedger: allBattlefieldIDsMatchLedger,
            visibleCommandCaveatLabels: lateCareer.map(\.visibleCommandCaveatLabel)
        )
    }
}

private func lateContextBattlefield(
    _ candidateID: String,
    germanContext: String,
    map: LateCareerStaffBattlefieldMap,
    playerForceName: String,
    germanForceName: String,
    playerObjectiveName: String,
    playerSupportObjectiveName: String,
    denialObjectiveName: String,
    germanObjectiveName: String
) -> LateCareerStaffBattlefield {
    guard let candidate = GuderianCareerScopeCatalog.expansionCandidate(for: candidateID) else {
        preconditionFailure("Missing late-career candidate: \(candidateID)")
    }

    let commandCaveatPrefix = candidate.scope == .postDismissalContext ? "Post-dismissal context" : "Staff-context only"

    return LateCareerStaffBattlefield(
        id: candidate.id,
        order: candidate.order,
        title: candidate.title,
        dateRange: candidate.dateRange,
        scope: candidate.scope,
        playerRole: candidate.playerRole,
        germanContext: germanContext,
        commandCaveat: "\(commandCaveatPrefix): not a Guderian field command battle.",
        playableFraming: candidate.playableFraming,
        map: map,
        objectives: [
            lateContextObjective("\(candidate.id)-primary", playerObjectiveName, .player, 5, "Primary player objective for \(candidate.title)."),
            lateContextObjective("\(candidate.id)-support", playerSupportObjectiveName, .player, 4, "Support objective that keeps the staff-context map tactically playable."),
            lateContextObjective("\(candidate.id)-denial", denialObjectiveName, .player, 3, "Denial objective tied to crossings, roads, rail, or defensive belts."),
            lateContextObjective("\(candidate.id)-german", germanObjectiveName, .guderianAI, 5, "Opposition pressure objective; Guderian is context rather than field commander."),
        ],
        forces: [
            lateContextForce("\(candidate.id)-player-force", .player, playerForceName, candidate.playerRole, "Player controls the anti-Guderian side in a command-caveated late-war context."),
            lateContextForce("\(candidate.id)-german-force", .guderianAI, germanForceName, germanContext, "German side reflects \(candidate.scope.rawValue), not direct Guderian field command."),
        ],
        rules: [
            lateContextRule("\(candidate.id)-crossing-rule", "Crossing pressure", "Player controls two crossing markers.", "Score crossing pressure and constrain the German operational response."),
            lateContextRule("\(candidate.id)-rail-rule", "Rail and road disruption", "Player controls a rail or road objective at phase end.", "Add logistics friction before the next German pressure step."),
            lateContextRule("\(candidate.id)-caveat-rule", "Command caveat visible", "The battlefield opens in any late-career UI surface.", "Show the command caveat label before objectives are scored."),
            lateContextRule("\(candidate.id)-phase-rule", "Phase-line escalation", "Either side crosses a phase line.", "Advance the crisis state and refresh German AI priority pressure."),
        ],
        sourceLinks: candidate.sourceLinks
    )
}

private func lateContextObjective(_ id: String, _ name: String, _ side: ScenarioSide, _ points: Int, _ description: String) -> LateCareerStaffBattlefieldObjective {
    LateCareerStaffBattlefieldObjective(id: id, name: name, side: side, victoryPoints: points, description: description)
}

private func lateContextForce(_ id: String, _ side: ScenarioSide, _ name: String, _ role: String, _ caveat: String) -> LateCareerStaffBattlefieldForce {
    LateCareerStaffBattlefieldForce(id: id, side: side, name: name, role: role, caveat: caveat)
}

private func lateContextRule(_ id: String, _ name: String, _ trigger: String, _ effect: String) -> LateCareerStaffBattlefieldRule {
    LateCareerStaffBattlefieldRule(id: id, name: name, trigger: trigger, effect: effect)
}

private func lateContextMap(
    prefix: String,
    title: String,
    sourceTitle: String,
    sourceURL: String,
    water: [String],
    roads: [String],
    railway: String,
    crossings: [String],
    settlements: [String],
    terrain: [String],
    fortified: String,
    bunker: String,
    playerObjective: String,
    playerSupportObjective: String,
    germanObjective: String,
    pressure: String,
    phaseLines: [String],
    playerZone: String,
    germanZone: String
) -> LateCareerStaffBattlefieldMap {
    precondition(water.count >= 2)
    precondition(roads.count >= 3)
    precondition(crossings.count >= 3)
    precondition(settlements.count >= 4)
    precondition(terrain.count >= 3)
    precondition(phaseLines.count >= 2)

    return LateCareerStaffBattlefieldMap(
        id: "\(prefix)-map",
        title: title,
        elements: [
            lateContextLine("\(prefix)-water-primary", water[0], .river, [lateContextPoint(7, 45), lateContextPoint(27, 40), lateContextPoint(50, 35), lateContextPoint(74, 30), lateContextPoint(97, 25)], width: 5, "\(water[0]) anchors the main operational water obstacle."),
            lateContextLine("\(prefix)-water-secondary", water[1], .river, [lateContextPoint(11, 24), lateContextPoint(31, 27), lateContextPoint(52, 30), lateContextPoint(74, 32)], width: 3, "\(water[1]) shapes the flank and secondary crossings."),
            lateContextMarker("\(prefix)-marsh", terrain[0], .marsh, .neutral, lateContextPoint(54, 39), radius: 5, "\(terrain[0]) slows movement away from prepared routes."),
            lateContextLine("\(prefix)-road-primary", roads[0], .road, [lateContextPoint(9, 52), lateContextPoint(30, 47), lateContextPoint(51, 40), lateContextPoint(76, 31), lateContextPoint(98, 24)], width: 2, "\(roads[0]) carries the principal operational movement."),
            lateContextLine("\(prefix)-road-secondary", roads[1], .road, [lateContextPoint(20, 31), lateContextPoint(42, 35), lateContextPoint(65, 34), lateContextPoint(89, 28)], width: 2, "\(roads[1]) links reserves and counterpressure."),
            lateContextLine("\(prefix)-road-withdrawal", roads[2], .road, [lateContextPoint(47, 55), lateContextPoint(59, 47), lateContextPoint(73, 38), lateContextPoint(96, 29)], width: 2, "\(roads[2]) is the withdrawal or pursuit lane."),
            lateContextLine("\(prefix)-rail", railway, .railway, [lateContextPoint(8, 48), lateContextPoint(31, 43), lateContextPoint(55, 37), lateContextPoint(79, 31), lateContextPoint(99, 26)], width: 2, "\(railway) creates the rail-control objective spine."),
            lateContextMarker("\(prefix)-bridge", crossings[0], .bridge, .neutral, lateContextPoint(55, 36), radius: 3, "\(crossings[0]) is the primary crossing gate."),
            lateContextMarker("\(prefix)-ford", crossings[1], .ford, .neutral, lateContextPoint(43, 39), radius: 3, "\(crossings[1]) is the secondary ford or shallow crossing."),
            lateContextMarker("\(prefix)-ferry", crossings[2], .ferry, .neutral, lateContextPoint(68, 33), radius: 3, "\(crossings[2]) provides a fragile fallback crossing."),
            lateContextMarker("\(prefix)-urban", settlements[0], .urbanDistrict, .player, lateContextPoint(73, 30), radius: 4, "\(settlements[0]) is the major urban or fortress district."),
            lateContextMarker("\(prefix)-settlement-a", settlements[1], .village, .player, lateContextPoint(58, 36), radius: 3, "\(settlements[1]) anchors a road and crossing junction."),
            lateContextMarker("\(prefix)-settlement-b", settlements[2], .village, .neutral, lateContextPoint(40, 42), radius: 3, "\(settlements[2]) marks the contested middle ground."),
            lateContextMarker("\(prefix)-settlement-c", settlements[3], .village, .guderianAI, lateContextPoint(86, 27), radius: 3, "\(settlements[3]) screens the German pressure side."),
            lateContextLine("\(prefix)-forest", terrain[1], .forest, [lateContextPoint(24, 19), lateContextPoint(45, 21), lateContextPoint(68, 24), lateContextPoint(86, 23)], width: 5, "\(terrain[1]) masks reserves and blocking forces."),
            lateContextMarker("\(prefix)-ridge", terrain[2], .ridge, .neutral, lateContextPoint(63, 32), radius: 4, "\(terrain[2]) overlooks roads, crossings, or bridgeheads."),
            lateContextLine("\(prefix)-fortified-line", fortified, .fortifiedLine, [lateContextPoint(43, 42), lateContextPoint(61, 36), lateContextPoint(82, 30)], width: 3, "\(fortified) is the principal defensive belt."),
            lateContextMarker("\(prefix)-bunker", bunker, .bunker, .guderianAI, lateContextPoint(66, 35), radius: 3, "\(bunker) hardens the defensive arc."),
            lateContextMarker("\(prefix)-player-objective", playerObjective, .objective, .player, lateContextPoint(55, 37), radius: 4, "\(playerObjective) is the main player scoring location."),
            lateContextMarker("\(prefix)-player-support-objective", playerSupportObjective, .objective, .player, lateContextPoint(77, 31), radius: 4, "\(playerSupportObjective) keeps road and rail play meaningful."),
            lateContextMarker("\(prefix)-german-objective", germanObjective, .objective, .guderianAI, lateContextPoint(94, 27), radius: 4, "\(germanObjective) is the German pressure scoring exit."),
            lateContextMarker("\(prefix)-pressure", pressure, .artillery, .guderianAI, lateContextPoint(28, 47), radius: 4, "\(pressure) gives the opposition a visible crisis lever."),
            lateContextLine("\(prefix)-phase-primary", phaseLines[0], .phaseLine, [lateContextPoint(39, 43), lateContextPoint(58, 37), lateContextPoint(77, 31)], width: 2, "\(phaseLines[0]) gates the first escalation state."),
            lateContextLine("\(prefix)-phase-secondary", phaseLines[1], .phaseLine, [lateContextPoint(58, 42), lateContextPoint(76, 35), lateContextPoint(96, 28)], width: 2, "\(phaseLines[1]) gates the final crisis state."),
        ],
        deploymentZones: [
            lateContextZone("\(prefix)-player-zone", playerZone, .player, lateContextPoint(16, 26), 42, 28, "\(playerZone) begin from the pressure or bridgehead side."),
            lateContextZone("\(prefix)-german-zone", germanZone, .guderianAI, lateContextPoint(55, 21), 40, 26, "\(germanZone) hold exits, belts, or counterattack routes."),
        ],
        sourceNotes: [
            ScenarioMapSourceNote(title: sourceTitle, url: URL(string: sourceURL), note: "Source shelf for \(title) hand-authored staff-context geography.")
        ]
    )
}

private func lateContextLine(
    _ id: String,
    _ name: String,
    _ kind: ScenarioMapElementKind,
    _ points: [ScenarioMapPoint],
    width: Double,
    _ note: String
) -> ScenarioMapElement {
    ScenarioMapElement(id: id, name: name, kind: kind, points: points, strokeWidth: width, note: note)
}

private func lateContextMarker(
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

private func lateContextZone(
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

private func lateContextPoint(_ x: Double, _ y: Double) -> ScenarioMapPoint {
    ScenarioMapPoint(x, y)
}
