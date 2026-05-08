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
    public static let publicSwiftUISurfaceName = "HistoricalPlayableBattleView"
    public static let boardInteractionProfile = HistoricalPlayableBoardInteractionProfile(
        interactions: HistoricalPlayableBoardInteraction.allCases,
        resolverName: "HistoricalBoardInteractionResolver",
        mirrorsGuderianSelectionSemantics: true
    )
    public static let boardReadabilityProfile = HistoricalPlayableBoardReadabilityProfile(
        terrainNamesDrawnDirectlyOnBoard: false,
        objectiveNamesDrawnDirectlyOnBoard: false,
        unitNamesDrawnDirectlyOnBoard: false,
        unitLabelMode: "id-only-token-with-full-sidebar-and-help",
        detailDisclosureSurfaces: [
            "battle-sidebar",
            "battle-forces",
            "battle-objectives",
            "battle-log",
            "accessibility-help",
        ]
    )
    public static let boardViewportProfile = HistoricalPlayableBoardViewportProfile(
        aspectRatio: 1.55,
        desktopMaxBoardHeight: 420,
        compactMaxBoardHeight: 380,
        keepsCommandButtonsInPrimaryViewport: true
    )

    public static let dzwStyleBattleSurface = HistoricalPlayableSurfaceContract(
        hostSurfaceName: sharedHostSurfaceName,
        sharedComponentNames: [
            "HistoricalPlayableBattleView",
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
            "battle-forces",
            "battle-objectives",
            "battle-terrain-summary",
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

    public static var hasPublicSwiftUIBattleSurface: Bool {
        publicSwiftUISurfaceName == sharedHostSurfaceName &&
            dzwStyleBattleSurface.sharedComponentNames.contains(publicSwiftUISurfaceName)
    }
}

public enum HistoricalPlayableBoardInteraction: String, CaseIterable, Codable, Hashable, Sendable {
    case directUnitSelection = "Direct unit selection"
    case directTargetSelection = "Direct target selection"
    case boardClearSelection = "Board clear selection"
    case commandButtons = "Command buttons"
    case actionFeedback = "Action feedback"
    case phaseControls = "Phase controls"
    case aiTurn = "AI turn"
    case debrief = "Debrief"
}

public struct HistoricalPlayableBoardInteractionProfile: Codable, Hashable, Sendable {
    public let interactions: [HistoricalPlayableBoardInteraction]
    public let resolverName: String
    public let mirrorsGuderianSelectionSemantics: Bool

    public init(
        interactions: [HistoricalPlayableBoardInteraction],
        resolverName: String,
        mirrorsGuderianSelectionSemantics: Bool
    ) {
        self.interactions = interactions
        self.resolverName = resolverName
        self.mirrorsGuderianSelectionSemantics = mirrorsGuderianSelectionSemantics
    }

    public var supportsGuderianStyleBoardCommands: Bool {
        mirrorsGuderianSelectionSemantics &&
            resolverName == "HistoricalBoardInteractionResolver" &&
            Set(interactions) == Set(HistoricalPlayableBoardInteraction.allCases)
    }
}

public struct HistoricalPlayableBoardReadabilityProfile: Codable, Hashable, Sendable {
    public let terrainNamesDrawnDirectlyOnBoard: Bool
    public let objectiveNamesDrawnDirectlyOnBoard: Bool
    public let unitNamesDrawnDirectlyOnBoard: Bool
    public let unitLabelMode: String
    public let detailDisclosureSurfaces: [String]

    public init(
        terrainNamesDrawnDirectlyOnBoard: Bool,
        objectiveNamesDrawnDirectlyOnBoard: Bool,
        unitNamesDrawnDirectlyOnBoard: Bool,
        unitLabelMode: String,
        detailDisclosureSurfaces: [String]
    ) {
        self.terrainNamesDrawnDirectlyOnBoard = terrainNamesDrawnDirectlyOnBoard
        self.objectiveNamesDrawnDirectlyOnBoard = objectiveNamesDrawnDirectlyOnBoard
        self.unitNamesDrawnDirectlyOnBoard = unitNamesDrawnDirectlyOnBoard
        self.unitLabelMode = unitLabelMode
        self.detailDisclosureSurfaces = detailDisclosureSurfaces
    }

    public var directBoardNameLabelCount: Int {
        [
            terrainNamesDrawnDirectlyOnBoard,
            objectiveNamesDrawnDirectlyOnBoard,
            unitNamesDrawnDirectlyOnBoard,
        ].filter { $0 }.count
    }

    public var usesIDOnlyUnitTokens: Bool {
        unitLabelMode.contains("id-only")
    }

    public var hasSidebarDetailDisclosure: Bool {
        detailDisclosureSurfaces.contains("battle-sidebar") &&
            detailDisclosureSurfaces.contains("battle-forces")
    }

    public var preventsDenseAlwaysOnBoardText: Bool {
        !terrainNamesDrawnDirectlyOnBoard &&
            !objectiveNamesDrawnDirectlyOnBoard &&
            !unitNamesDrawnDirectlyOnBoard &&
            usesIDOnlyUnitTokens &&
            hasSidebarDetailDisclosure
    }
}

public struct HistoricalPlayableBoardViewportProfile: Codable, Hashable, Sendable {
    public let aspectRatio: Double
    public let desktopMaxBoardHeight: Int
    public let compactMaxBoardHeight: Int
    public let keepsCommandButtonsInPrimaryViewport: Bool

    public init(
        aspectRatio: Double,
        desktopMaxBoardHeight: Int,
        compactMaxBoardHeight: Int,
        keepsCommandButtonsInPrimaryViewport: Bool
    ) {
        self.aspectRatio = aspectRatio
        self.desktopMaxBoardHeight = desktopMaxBoardHeight
        self.compactMaxBoardHeight = compactMaxBoardHeight
        self.keepsCommandButtonsInPrimaryViewport = keepsCommandButtonsInPrimaryViewport
    }

    public var isCriticalViewportReady: Bool {
        aspectRatio > 1.4 &&
            aspectRatio < 1.7 &&
            desktopMaxBoardHeight <= 420 &&
            compactMaxBoardHeight <= 380 &&
            keepsCommandButtonsInPrimaryViewport
    }
}

public struct HistoricalAutoplayContract: Codable, Hashable, Sendable {
    public let primarySurfaceName: String
    public let embeddedBattleSurfaceName: String
    public let retiredEmbeddedSurfaceNames: [String]
    public let requiredAccessibilityIdentifiers: [String]
    public let speedModes: [String]
    public let supportsDeterministicSeed: Bool
    public let requiresBothSidesActed: Bool
    public let requiresRealDebriefPersistence: Bool

    public init(
        primarySurfaceName: String,
        embeddedBattleSurfaceName: String = HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName,
        retiredEmbeddedSurfaceNames: [String] = [],
        requiredAccessibilityIdentifiers: [String],
        speedModes: [String] = ["Inspect", "Standard", "Fast"],
        supportsDeterministicSeed: Bool = true,
        requiresBothSidesActed: Bool = true,
        requiresRealDebriefPersistence: Bool = true
    ) {
        self.primarySurfaceName = primarySurfaceName
        self.embeddedBattleSurfaceName = embeddedBattleSurfaceName
        self.retiredEmbeddedSurfaceNames = retiredEmbeddedSurfaceNames
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
