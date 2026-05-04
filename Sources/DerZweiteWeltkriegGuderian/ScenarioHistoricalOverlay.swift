import Foundation

public struct ScenarioSourceNote: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let note: String

    public init(id: String, title: String, note: String) {
        self.id = id
        self.title = title
        self.note = note
    }
}

public struct ScenarioHistoricalOverlay: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let commanderContext: String
    public let mapNote: String
    public let outcomeSummary: String
    public let caveats: [String]
    public let sourceNotes: [ScenarioSourceNote]

    public init(
        id: GuderianBattleID,
        commanderContext: String,
        mapNote: String,
        outcomeSummary: String,
        caveats: [String],
        sourceNotes: [ScenarioSourceNote]
    ) {
        self.id = id
        self.commanderContext = commanderContext
        self.mapNote = mapNote
        self.outcomeSummary = outcomeSummary
        self.caveats = caveats
        self.sourceNotes = sourceNotes
    }
}

public enum ScenarioHistoricalOverlayCatalog {
    public static func overlay(for scenario: GuderianScenario) -> ScenarioHistoricalOverlay {
        let layout = ScenarioMapCatalog.layout(for: scenario)
        return ScenarioHistoricalOverlay(
            id: scenario.id,
            commanderContext: commanderContext(for: scenario),
            mapNote: mapNote(for: scenario, layout: layout),
            outcomeSummary: outcomeSummary(for: scenario),
            caveats: caveats(for: scenario),
            sourceNotes: sourceNotes(for: scenario)
        )
    }

    public static func overlay(for id: GuderianBattleID) -> ScenarioHistoricalOverlay? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return overlay(for: scenario)
    }

    public static var allOverlays: [ScenarioHistoricalOverlay] {
        GuderianCampaignCatalog.all.map(overlay)
    }

    private static func commanderContext(for scenario: GuderianScenario) -> String {
        switch scenario.id {
        case .dunkirk:
            return "The scenario models pressure from the Channel-port campaign after Guderian's coast drive rather than a clean single-battle command by Guderian."
        case .mtsensk:
            return "Guderian's sector pressure is represented through German panzer formations opposed by Katukov's 4th Tank Brigade and 1st Guards Rifle Corps around Mtsensk."
        case .moscowTulaKashira:
            return "The scenario follows Guderian's 2nd Panzer Army on the southern Moscow approach, where Tula, Venev, Kashira, and winter supply all shape the final offensive failure."
        default:
            return "\(scenario.guderianCommand) is the command frame for this battle; the player controls \(scenario.playerForceSummary) to resist, delay, escape, or counterattack."
        }
    }

    private static func mapNote(for scenario: GuderianScenario, layout: ScenarioMapLayout) -> String {
        let objectiveNames = layout.objectiveElements.map(\.name).prefix(3).joined(separator: ", ")
        if objectiveNames.isEmpty {
            return "\(layout.title) abstracts the main roads, defensive terrain, and command-relevant objectives used by the scenario."
        }
        return "\(layout.title) emphasizes \(objectiveNames) as the player-facing operational map anchors."
    }

    private static func outcomeSummary(for scenario: GuderianScenario) -> String {
        switch scenario.id {
        case .mtsensk:
            return "Historically, the Mtsensk fighting checked German armor locally and became a showcase for Soviet armored ambush tactics, even though the wider Moscow campaign remained under severe pressure."
        case .moscowTulaKashira:
            return "Historically, Tula held, the Kashira thrust was repelled, and the southern approach became one of the routes where German exhaustion turned into Soviet counteroffensive pressure."
        case .dunkirk:
            return "Historically, Allied evacuation succeeded under severe German pressure while the broader campaign in France remained a German operational victory."
        default:
            return scenario.historicalResult
        }
    }

    private static func caveats(for scenario: GuderianScenario) -> [String] {
        var values = [
            "This is a compact operational scenario, not a literal one-to-one recreation of every formation and movement.",
            "The player-facing role remains opposition to Guderian's formations; the presentation avoids celebratory framing.",
        ]

        if scenario.id == .dunkirk {
            values.append("Guderian's role is indirect here; the scenario is kept because it follows from the Channel-port campaign pressure.")
        }
        if scenario.id == .mtsensk {
            values.append("Tank-loss claims around Mtsensk are contested in detail, so scoring emphasizes delay, shock, and preservation rather than exact loss totals.")
        }
        if scenario.id == .moscowTulaKashira {
            values.append("The full Moscow battle is much larger than this scenario; this module focuses on Guderian's southern pincer around Tula and Kashira.")
        }
        return values
    }

    private static func sourceNotes(for scenario: GuderianScenario) -> [ScenarioSourceNote] {
        scenario.sourceLinks.map { source in
            ScenarioSourceNote(
                id: "\(scenario.id.rawValue)-\(source.title.lowercased().replacingOccurrences(of: " ", with: "-"))",
                title: source.title,
                note: "Used for date range, command scope, terrain anchors, result framing, and scenario inclusion boundaries."
            )
        }
    }
}
