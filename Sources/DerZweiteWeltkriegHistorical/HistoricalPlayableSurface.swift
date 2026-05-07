import Foundation

public enum HistoricalPlayableSurfaceStage: String, CaseIterable, Codable, Hashable, Sendable {
    case campaignRow = "Campaign row"
    case briefing = "Briefing"
    case sideSelection = "Side selection"
    case launch = "Launch"
    case board = "Board"
    case unitSelection = "Unit selection"
    case movement = "Movement"
    case combat = "Combat"
    case pendingChoice = "Pending choice"
    case phaseFlow = "Phase flow"
    case aiTurn = "AI turn"
    case blockedActionFeedback = "Blocked action feedback"
    case debrief = "Debrief"
    case persistence = "Persistence"
}

public struct HistoricalPlayableSurfaceContract: Codable, Hashable, Sendable {
    public let hostSurfaceName: String
    public let sharedComponentNames: [String]
    public let requiredStages: [HistoricalPlayableSurfaceStage]
    public let requiredAccessibilityIdentifiers: [String]
    public let retiredGameSpecificSurfaceNames: [String]

    public init(
        hostSurfaceName: String,
        sharedComponentNames: [String],
        requiredStages: [HistoricalPlayableSurfaceStage],
        requiredAccessibilityIdentifiers: [String],
        retiredGameSpecificSurfaceNames: [String]
    ) {
        self.hostSurfaceName = hostSurfaceName
        self.sharedComponentNames = sharedComponentNames
        self.requiredStages = requiredStages
        self.requiredAccessibilityIdentifiers = requiredAccessibilityIdentifiers
        self.retiredGameSpecificSurfaceNames = retiredGameSpecificSurfaceNames
    }

    public var coversFullBattleFlow: Bool {
        Set(requiredStages) == Set(HistoricalPlayableSurfaceStage.allCases)
    }

    public var hasBoardAndSidebarComponents: Bool {
        sharedComponentNames.contains("BattleBoardView") &&
            sharedComponentNames.contains("BattleSidebarView") &&
            sharedComponentNames.contains("BattlefieldViewport")
    }
}

public enum HistoricalPlayableSurfaceCatalog {
    public static let sharedHostSurfaceName = "HistoricalPlayableBattleView"

    public static let dzwStyleBattleSurface = HistoricalPlayableSurfaceContract(
        hostSurfaceName: sharedHostSurfaceName,
        sharedComponentNames: [
            "BattleShellView",
            "BattleBoardView",
            "BattleSidebarView",
            "BattlefieldViewport",
            "BattleControlsSection",
            "BattleObjectivesSection",
            "BattleLogSection",
        ],
        requiredStages: HistoricalPlayableSurfaceStage.allCases,
        requiredAccessibilityIdentifiers: [
            "battle-screen",
            "battle-board",
            "battle-sidebar",
            "battle-side-selector",
            "battle-action-feedback",
            "battle-objectives",
            "battle-log",
            "battle-next-phase-button",
            "battle-ai-turn-button",
            "battle-debrief-panel",
            "battle-persisted-result",
        ],
        retiredGameSpecificSurfaceNames: [
            "DZWPlayableBattleView",
            "LateCareerUnifiedPlayableBoardView",
            "LateCareerMapSurface",
            "NativeBattleBoardView",
        ]
    )
}

public struct HistoricalAutoplayContract: Codable, Hashable, Sendable {
    public let primarySurfaceName: String
    public let embeddedBattleSurfaceName: String
    public let requiredAccessibilityIdentifiers: [String]
    public let speedModes: [String]
    public let supportsDeterministicSeed: Bool
    public let requiresBothSidesActed: Bool
    public let requiresRealDebriefPersistence: Bool

    public init(
        primarySurfaceName: String,
        embeddedBattleSurfaceName: String = HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName,
        requiredAccessibilityIdentifiers: [String],
        speedModes: [String] = ["Inspect", "Standard", "Fast"],
        supportsDeterministicSeed: Bool = true,
        requiresBothSidesActed: Bool = true,
        requiresRealDebriefPersistence: Bool = true
    ) {
        self.primarySurfaceName = primarySurfaceName
        self.embeddedBattleSurfaceName = embeddedBattleSurfaceName
        self.requiredAccessibilityIdentifiers = requiredAccessibilityIdentifiers
        self.speedModes = speedModes
        self.supportsDeterministicSeed = supportsDeterministicSeed
        self.requiresBothSidesActed = requiresBothSidesActed
        self.requiresRealDebriefPersistence = requiresRealDebriefPersistence
    }

    public var isFirstBattleAutoplayContract: Bool {
        supportsDeterministicSeed &&
            requiresBothSidesActed &&
            requiresRealDebriefPersistence &&
            embeddedBattleSurfaceName == HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName &&
            requiredAccessibilityIdentifiers.contains { $0.contains("run-to-debrief") } &&
            requiredAccessibilityIdentifiers.contains { $0.contains("result-summary") }
    }
}
