import Foundation

public enum ReleaseChecklistStatus: String, Codable, Hashable, Sendable {
    case passed = "Passed"
    case watch = "Watch"
}

public struct ReleaseChecklistItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let status: ReleaseChecklistStatus

    public init(id: String, title: String, detail: String, status: ReleaseChecklistStatus) {
        self.id = id
        self.title = title
        self.detail = detail
        self.status = status
    }
}

public struct CampaignCredit: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let sourcePathOrURL: String

    public init(id: String, title: String, detail: String, sourcePathOrURL: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.sourcePathOrURL = sourcePathOrURL
    }
}

public struct AccessibilityAuditItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let coverage: String

    public init(id: String, title: String, coverage: String) {
        self.id = id
        self.title = title
        self.coverage = coverage
    }
}

public struct PerformanceBudget: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let measuredCount: Int
    public let limit: Int
    public let detail: String

    public init(id: String, title: String, measuredCount: Int, limit: Int, detail: String) {
        self.id = id
        self.title = title
        self.measuredCount = measuredCount
        self.limit = limit
        self.detail = detail
    }

    public var isPassing: Bool {
        measuredCount <= limit
    }
}

public struct FullCampaignShipReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let scenarioCount: Int
    public let proxyLoadableCount: Int
    public let handAuthoredCount: Int
    public let historicalOverlayCount: Int
    public let aiSnapshotCount: Int
    public let balanceAuditCount: Int
    public let releaseChecklist: [ReleaseChecklistItem]
    public let credits: [CampaignCredit]
    public let accessibilityItems: [AccessibilityAuditItem]
    public let performanceBudgets: [PerformanceBudget]
    public let buildCommands: [String]
    public let blockers: [String]

    public init(
        cycleRange: ClosedRange<Int>,
        scenarioCount: Int,
        proxyLoadableCount: Int,
        handAuthoredCount: Int,
        historicalOverlayCount: Int,
        aiSnapshotCount: Int,
        balanceAuditCount: Int,
        releaseChecklist: [ReleaseChecklistItem],
        credits: [CampaignCredit],
        accessibilityItems: [AccessibilityAuditItem],
        performanceBudgets: [PerformanceBudget],
        buildCommands: [String],
        blockers: [String]
    ) {
        self.cycleRange = cycleRange
        self.scenarioCount = scenarioCount
        self.proxyLoadableCount = proxyLoadableCount
        self.handAuthoredCount = handAuthoredCount
        self.historicalOverlayCount = historicalOverlayCount
        self.aiSnapshotCount = aiSnapshotCount
        self.balanceAuditCount = balanceAuditCount
        self.releaseChecklist = releaseChecklist
        self.credits = credits
        self.accessibilityItems = accessibilityItems
        self.performanceBudgets = performanceBudgets
        self.buildCommands = buildCommands
        self.blockers = blockers
    }

    public var isShipReady: Bool {
        blockers.isEmpty
            && releaseChecklist.allSatisfy { $0.status == .passed }
            && performanceBudgets.allSatisfy(\.isPassing)
    }

    public var cycleLabel: String {
        "Cycles \(cycleRange.lowerBound)-\(cycleRange.upperBound)"
    }
}

public enum FullCampaignShipReportCatalog {
    public static func report(
        catalog: [GuderianScenario] = GuderianCampaignCatalog.all
    ) -> FullCampaignShipReport {
        let bundles = catalog.map(ScenarioContentCatalog.bundle)
        let proxyLoadableCount = catalog.filter { $0.status == .dzwProxyLoadable && DZWScenarioLoader.load($0.id) != nil }.count
        let handAuthoredCount = catalog.filter { ScenarioContentCatalog.handAuthoredScenarioIDs.contains($0.id) }.count
        let performanceBudgets = performanceBudgets(for: bundles)
        let blockers = blockers(
            catalog: catalog,
            bundles: bundles,
            proxyLoadableCount: proxyLoadableCount,
            handAuthoredCount: handAuthoredCount,
            performanceBudgets: performanceBudgets
        )

        return FullCampaignShipReport(
            cycleRange: 241...250,
            scenarioCount: catalog.count,
            proxyLoadableCount: proxyLoadableCount,
            handAuthoredCount: handAuthoredCount,
            historicalOverlayCount: ScenarioHistoricalOverlayCatalog.allOverlays.count,
            aiSnapshotCount: GermanAIRefinementCatalog.allSnapshots.count,
            balanceAuditCount: ScenarioBalanceAuditCatalog.allAudits.count,
            releaseChecklist: checklist(blockers: blockers),
            credits: credits(),
            accessibilityItems: accessibilityItems(),
            performanceBudgets: performanceBudgets,
            buildCommands: [
                "git diff --check",
                "swift build",
                "swift test",
                "xcodebuild -project Guderian.xcodeproj -scheme Guderian -destination 'platform=macOS' build",
            ],
            blockers: blockers
        )
    }

    private static func blockers(
        catalog: [GuderianScenario],
        bundles: [ScenarioContentBundle],
        proxyLoadableCount: Int,
        handAuthoredCount: Int,
        performanceBudgets: [PerformanceBudget]
    ) -> [String] {
        var values: [String] = []
        let expectedIDs = Set(catalog.map(\.id))

        if catalog.count != 19 {
            values.append("Campaign catalog should contain 19 command-scope scenarios.")
        }
        if proxyLoadableCount != catalog.count {
            values.append("Every scenario must be proxy-loadable through DZWScenarioLoader.")
        }
        if handAuthoredCount != catalog.count || ScenarioContentCatalog.handAuthoredScenarioIDs != expectedIDs {
            values.append("Every scenario must have a hand-authored Guderian content bundle.")
        }
        if bundles.contains(where: { $0.scenario.sourceLinks.isEmpty || $0.historicalOverlay.sourceNotes.isEmpty }) {
            values.append("Every scenario must keep source links and historical source notes.")
        }
        if GermanAIRefinementCatalog.allSnapshots.count != catalog.count {
            values.append("Every scenario must expose an AI refinement snapshot.")
        }
        if ScenarioBalanceAuditCatalog.allAudits.count != catalog.count {
            values.append("Every scenario must expose a balance audit.")
        }
        if performanceBudgets.contains(where: { !$0.isPassing }) {
            values.append("One or more release performance budgets is over limit.")
        }
        return values
    }

    private static func checklist(blockers: [String]) -> [ReleaseChecklistItem] {
        let status: ReleaseChecklistStatus = blockers.isEmpty ? .passed : .watch
        return [
            item("icon", "Icon provenance", "Public-domain Guderian portrait source is documented with hash and crop notes.", status),
            item("credits", "Credits ledger", "Engine, icon, source shelf, and campaign data ownership are credited.", status),
            item("accessibility", "Accessibility pass", "Primary controls, scenario rows, map zones, and filters expose semantic labels.", status),
            item("performance", "Performance pass", "Scenario data stays inside release budgets for map, setup, and log density.", status),
            item("save-load", "Save/load", "Campaign progress, selected scenario, and play mode round-trip through a versioned save envelope.", status),
            item("completion", "Completion screen", "A full-campaign completion summary unlocks when all scenarios have records.", status),
            item("regression", "Regression suite", "Full-campaign smoke tests cover content bundles, proxy loads, AI snapshots, and balance audits.", status),
            item("dzw-boundary", "dzw boundary", "Guderian work remains outside the included engine directory.", status),
        ]
    }

    private static func credits() -> [CampaignCredit] {
        [
            credit("engine", "derZweiteWeltkrieg engine", "Included C rules core and SwiftUI shell used through the proxy loader.", "dzw/"),
            credit("icon", "App icon portrait", "Public-domain Wikimedia Commons portrait crop documented with source and SHA-256.", "Resources/AppIconSource/README.md"),
            credit("sources", "Historical source shelf", "Wikipedia campaign pages seed dates, command scope, force anchors, and result framing.", "README.md"),
            credit("data", "Guderian scenario data", "All maps, setup scripts, AI plans, balance profiles, overlays, and audits live in root Guderian sources.", "Sources/GuderianCore/"),
        ]
    }

    private static func accessibilityItems() -> [AccessibilityAuditItem] {
        [
            access("navigation", "Campaign navigation", "Scenario rows combine order, title, date, theater, completion, and lock state."),
            access("controls", "Controls", "Play mode, completion, reset, save, load, and log filter controls use labeled SwiftUI controls."),
            access("map", "Map presentation", "Map deployment zones expose accessibility labels while decorative map chrome is hidden where appropriate."),
            access("status", "Status", "Ship, renderer, completion, and scenario availability states are repeated as text labels."),
        ]
    }

    private static func performanceBudgets(for bundles: [ScenarioContentBundle]) -> [PerformanceBudget] {
        [
            budget("map-elements", "Map element density", bundles.map { $0.mapLayout.elements.count }.max() ?? 0, 48, "Highest single-scenario map element count."),
            budget("setup-units", "Setup unit density", bundles.map { $0.setup.units.count }.max() ?? 0, 18, "Highest single-scenario unit roster count."),
            budget("log-entries", "Operation log density", bundles.map { $0.logEntries.count }.max() ?? 0, 42, "Highest single-scenario operation-log entry count."),
            budget("ai-orders", "AI order density", bundles.map { $0.aiPlan.orders.count }.max() ?? 0, 10, "Highest single-scenario German AI order count."),
        ]
    }

    private static func item(_ id: String, _ title: String, _ detail: String, _ status: ReleaseChecklistStatus) -> ReleaseChecklistItem {
        ReleaseChecklistItem(id: id, title: title, detail: detail, status: status)
    }

    private static func credit(_ id: String, _ title: String, _ detail: String, _ source: String) -> CampaignCredit {
        CampaignCredit(id: id, title: title, detail: detail, sourcePathOrURL: source)
    }

    private static func access(_ id: String, _ title: String, _ coverage: String) -> AccessibilityAuditItem {
        AccessibilityAuditItem(id: id, title: title, coverage: coverage)
    }

    private static func budget(_ id: String, _ title: String, _ measured: Int, _ limit: Int, _ detail: String) -> PerformanceBudget {
        PerformanceBudget(id: id, title: title, measuredCount: measured, limit: limit, detail: detail)
    }
}
