import SwiftUI

public struct HistoricalPlayableDebriefSummary: Hashable, Sendable {
    public let title: String
    public let summary: String
    public let scoreLine: String
    public let persistedResultIdentifier: String

    public init(
        title: String,
        summary: String,
        scoreLine: String,
        persistedResultIdentifier: String = "battle-persisted-result"
    ) {
        self.title = title
        self.summary = summary
        self.scoreLine = scoreLine
        self.persistedResultIdentifier = persistedResultIdentifier
    }
}

public struct HistoricalPlayableBattleView<ID: HistoricalBattleID>: View {
    private let battleTitle: String
    private let selectedSideTitle: String
    private let opposingSideTitle: String
    private let snapshot: HistoricalBoardSnapshot<ID>
    private let debrief: HistoricalPlayableDebriefSummary?
    private let onSelectReadyUnit: () -> Void
    private let onSelectNearestEnemy: () -> Void
    private let onSelectUnit: (Int) -> Void
    private let onSelectTarget: (Int) -> Void
    private let onClearSelection: () -> Void
    private let onMove: () -> Void
    private let onShoot: () -> Void
    private let onAssault: () -> Void
    private let onIssueOrder: (HistoricalBoardOrder) -> Void
    private let onResolvePending: () -> Void
    private let onNextPhase: () -> Void
    private let onAITurn: () -> Void
    private let onRestart: () -> Void
    private let onRunToDebrief: () -> Void

    public init(
        battleTitle: String,
        selectedSideTitle: String,
        opposingSideTitle: String,
        snapshot: HistoricalBoardSnapshot<ID>,
        debrief: HistoricalPlayableDebriefSummary? = nil,
        onSelectReadyUnit: @escaping () -> Void = {},
        onSelectNearestEnemy: @escaping () -> Void = {},
        onSelectUnit: @escaping (Int) -> Void = { _ in },
        onSelectTarget: @escaping (Int) -> Void = { _ in },
        onClearSelection: @escaping () -> Void = {},
        onMove: @escaping () -> Void = {},
        onShoot: @escaping () -> Void = {},
        onAssault: @escaping () -> Void = {},
        onIssueOrder: @escaping (HistoricalBoardOrder) -> Void = { _ in },
        onResolvePending: @escaping () -> Void = {},
        onNextPhase: @escaping () -> Void = {},
        onAITurn: @escaping () -> Void = {},
        onRestart: @escaping () -> Void = {},
        onRunToDebrief: @escaping () -> Void = {}
    ) {
        self.battleTitle = battleTitle
        self.selectedSideTitle = selectedSideTitle
        self.opposingSideTitle = opposingSideTitle
        self.snapshot = snapshot
        self.debrief = debrief
        self.onSelectReadyUnit = onSelectReadyUnit
        self.onSelectNearestEnemy = onSelectNearestEnemy
        self.onSelectUnit = onSelectUnit
        self.onSelectTarget = onSelectTarget
        self.onClearSelection = onClearSelection
        self.onMove = onMove
        self.onShoot = onShoot
        self.onAssault = onAssault
        self.onIssueOrder = onIssueOrder
        self.onResolvePending = onResolvePending
        self.onNextPhase = onNextPhase
        self.onAITurn = onAITurn
        self.onRestart = onRestart
        self.onRunToDebrief = onRunToDebrief
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            battleLayout
            controls
        }
        .padding(12)
        .background(Color.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(red: 0.30, green: 0.38, blue: 0.24).opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("battle-screen")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(battleTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(selectedSideTitle) vs \(opposingSideTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 12)

            Text("Turn \(snapshot.turnNumber) | \(snapshot.activeSideID) | \(snapshot.phase.rawValue)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(activeColor, in: RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private var battleLayout: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                board
                    .frame(minWidth: 500, minHeight: 300, maxHeight: 420)
                    .layoutPriority(2)

                sidebar
                    .frame(width: 280)
            }

            VStack(alignment: .leading, spacing: 10) {
                board
                    .frame(minHeight: 260, maxHeight: 380)
                sidebar
            }
        }
    }

    private var board: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.66, green: 0.61, blue: 0.45))
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onClearSelection)

                grid(in: proxy.size)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)

                ForEach(snapshot.zones) { zone in
                    zoneView(zone, proxy: proxy)
                }

                ForEach(snapshot.objectives) { objective in
                    objectiveView(objective, proxy: proxy)
                }

                ForEach(snapshot.units) { unit in
                    unitView(unit, proxy: proxy)
                        .zIndex(unitZIndex(unit))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.24), lineWidth: 1)
            )
        }
        .aspectRatio(1.55, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("battle-board")
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                actionFeedback
                inspector
                forces
                objectives
                terrainSummary
                eventLog
                debriefSection
            }
            .padding(10)
        }
        .background(Color(red: 0.91, green: 0.88, blue: 0.77).opacity(0.78), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityIdentifier("battle-sidebar")
    }

    private var actionFeedback: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snapshot.lastAction.title)
                .font(.caption.weight(.bold))
            Text(snapshot.lastAction.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(actionColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityIdentifier("battle-action-feedback")
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Inspector")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(selectedUnit?.name ?? "No unit selected")
                .font(.callout.weight(.semibold))
                .lineLimit(2)
            Text(targetedUnit.map { "Target: \($0.name)" } ?? "No target")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var forces: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Forces")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(snapshot.units) { unit in
                HStack(alignment: .top, spacing: 7) {
                    Text("\(unit.id)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 20)
                        .background(unitColor(unit.sideID), in: RoundedRectangle(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(unit.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(unitStateSummary(unit))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(unit.selected || unit.targeted ? Color.white.opacity(0.45) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
            }
        }
        .accessibilityIdentifier("battle-forces")
    }

    private var objectives: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Objectives")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(snapshot.objectives) { objective in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Circle()
                        .fill(objective.controllingSideID == snapshot.activeSideID ? activeColor : inactiveColor)
                        .frame(width: 7, height: 7)
                    Text(objective.name)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
        }
        .accessibilityIdentifier("battle-objectives")
    }

    private var terrainSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Terrain")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(snapshot.zones.prefix(10)) { zone in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(zoneColor(zone.kind).opacity(0.7))
                                .frame(width: 9, height: 9)
                            Text(zone.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            .frame(maxHeight: 74)
        }
        .accessibilityIdentifier("battle-terrain-summary")
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Log")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(snapshot.log.suffix(8).enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.caption2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 110)
        }
        .accessibilityIdentifier("battle-log")
    }

    @ViewBuilder
    private var debriefSection: some View {
        if let debrief {
            VStack(alignment: .leading, spacing: 5) {
                Text(debrief.title)
                    .font(.headline)
                Text(debrief.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(debrief.scoreLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(activeColor)
                    .accessibilityIdentifier(debrief.persistedResultIdentifier)
            }
            .padding(8)
            .background(Color(red: 0.84, green: 0.77, blue: 0.55).opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
            .accessibilityIdentifier("battle-debrief-panel")
        }
    }

    private var controls: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118, maximum: 170), spacing: 8)], alignment: .leading, spacing: 8) {
            commandButton("Select", systemImage: "scope", identifier: "battle-select-ready-unit-button", action: onSelectReadyUnit)
            commandButton("Target", systemImage: "target", identifier: "battle-nearest-enemy-button", disabled: selectedUnit == nil, action: onSelectNearestEnemy)
            orderButton(.fire, systemImage: "scope")
            orderButton(.advance, systemImage: "arrow.up.right")
            orderButton(.run, systemImage: "figure.run")
            orderButton(.ambush, systemImage: "eye")
            orderButton(.rally, systemImage: "flag.2.crossed")
            orderButton(.down, systemImage: "arrow.down.circle")
            commandButton("Move", systemImage: "arrow.up.right", identifier: "battle-move-button", disabled: selectedUnit?.canMoveNow != true, action: onMove)
            commandButton("Shoot", systemImage: "scope", identifier: "battle-shoot-button", disabled: selectedUnit?.canShootNow != true || targetedUnit == nil, action: onShoot)
            commandButton("Assault", systemImage: "figure.run", identifier: "battle-assault-button", disabled: selectedUnit?.canAssaultNow != true || targetedUnit == nil, action: onAssault)
            commandButton("Resolve", systemImage: "checkmark.circle", identifier: "battle-resolve-pending-button", action: onResolvePending)
            commandButton("Phase", systemImage: "forward.end", identifier: "battle-next-phase-button", action: onNextPhase)
            commandButton("AI Phase", systemImage: "cpu", identifier: "battle-ai-turn-button", disabled: debrief != nil, action: onAITurn)
            commandButton("Restart", systemImage: "arrow.clockwise", identifier: "battle-restart-button", action: onRestart)
            commandButton("Debrief", systemImage: "checkmark.seal", identifier: "battle-run-to-debrief-button", prominent: true, disabled: debrief != nil, action: onRunToDebrief)
        }
    }

    private func orderButton(_ order: HistoricalBoardOrder, systemImage: String) -> some View {
        let disabled = selectedUnit.map { !$0.availableOrders.contains(order) } ?? true
        return commandButton(
            order.rawValue,
            systemImage: systemImage,
            identifier: "battle-order-\(order.rawValue.lowercased())-button",
            disabled: disabled
        ) {
            onIssueOrder(order)
        }
    }

    private func commandButton(
        _ title: String,
        systemImage: String,
        identifier: String,
        prominent: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Group {
            if prominent {
                Button(action: action) {
                    commandLabel(title, systemImage: systemImage)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.30, green: 0.38, blue: 0.24))
            } else {
                Button(action: action) {
                    commandLabel(title, systemImage: systemImage)
                }
                .buttonStyle(.bordered)
                .tint(activeColor)
            }
        }
        .disabled(disabled)
        .accessibilityIdentifier(identifier)
        .accessibilityHint(helpText(title: title, disabled: disabled))
        .help(helpText(title: title, disabled: disabled))
    }

    private func commandLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 30)
    }

    private func zoneView(_ zone: HistoricalBoardZoneSnapshot, proxy: GeometryProxy) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(zoneColor(zone.kind).opacity(0.44))
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: zone.blocksLineOfSight ? [5, 3] : []))
        }
        .frame(
            width: max(42, scaledWidth(zone.width, proxy: proxy)),
            height: max(22, scaledHeight(zone.height, proxy: proxy))
        )
        .position(position(zone.origin, proxy: proxy))
        .help(zone.name)
        .accessibilityLabel(zone.name)
        .accessibilityIdentifier("battle-zone-\(zone.id)")
    }

    private func objectiveView(_ objective: HistoricalBoardObjectiveSnapshot, proxy: GeometryProxy) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
            Circle()
                .fill(objective.controllingSideID == snapshot.activeSideID ? activeColor : inactiveColor)
                .padding(3)
            Text("\(objective.id)")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(width: 22, height: 22)
        .position(position(objective.location, proxy: proxy))
        .help(objective.name)
        .accessibilityLabel(objective.name)
        .accessibilityIdentifier("battle-objective-token-\(objective.id)")
    }

    private func unitView(_ unit: HistoricalBoardUnitSnapshot, proxy: GeometryProxy) -> some View {
        let isSelected = unit.selected || unit.targeted
        let isActiveSide = unit.sideID == snapshot.activeSideID

        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: unit.kind == "Armour" ? 10 : 22)
                .fill(unitColor(unit.sideID))
                .overlay {
                    RoundedRectangle(cornerRadius: unit.kind == "Armour" ? 10 : 22)
                        .stroke(selectionStroke(unit: unit, isActiveSide: isActiveSide), lineWidth: isSelected ? 3 : 1)
                }

            VStack(spacing: 1) {
                Image(systemName: iconName(for: unit))
                    .font(.system(size: 13, weight: .bold))
                Text("\(unit.id)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if unit.selected || unit.targeted {
                Text(unit.selected ? "S" : "T")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(unit.selected ? Color.black : Color.white)
                    .frame(width: 13, height: 13)
                    .background(unit.selected ? Color.yellow : Color.orange, in: Circle())
                    .offset(x: 4, y: -4)
            }
        }
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .opacity(unit.destroyed ? 0.42 : 1)
        .position(position(HistoricalBoardLayoutResolver.resolvedUnitCoordinate(for: unit, in: snapshot), proxy: proxy))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            handleUnitTap(unit)
        }
        .help("Unit \(unit.id): \(unit.name), \(unit.role)")
        .accessibilityLabel("Unit \(unit.id), \(unit.name), \(unit.sideID), \(unit.kind)")
        .accessibilityHint(unitTapHint(unit))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("battle-unit-token-\(unit.id)")
    }

    private var selectedUnit: HistoricalBoardUnitSnapshot? {
        snapshot.units.first(where: \.selected)
    }

    private var targetedUnit: HistoricalBoardUnitSnapshot? {
        snapshot.units.first(where: \.targeted)
    }

    private var activeColor: Color {
        Color(red: 0.13, green: 0.24, blue: 0.34)
    }

    private var inactiveColor: Color {
        Color(red: 0.62, green: 0.24, blue: 0.17)
    }

    private var actionColor: Color {
        switch snapshot.lastAction.status {
        case .idle:
            return activeColor
        case .succeeded:
            return Color(red: 0.30, green: 0.38, blue: 0.24)
        case .blocked:
            return inactiveColor
        }
    }

    private func zoneColor(_ kind: HistoricalMapElementKind) -> Color {
        switch kind {
        case .ridge, .forest:
            return Color(red: 0.23, green: 0.42, blue: 0.28)
        case .minefield:
            return inactiveColor
        case .road, .bridge, .phaseLine:
            return activeColor
        case .river:
            return Color(red: 0.18, green: 0.39, blue: 0.52)
        case .town, .objective:
            return Color(red: 0.44, green: 0.29, blue: 0.18)
        default:
            return Color.gray
        }
    }

    private func unitColor(_ sideID: String) -> Color {
        sideID == snapshot.activeSideID ? activeColor : inactiveColor
    }

    private func iconName(for unit: HistoricalBoardUnitSnapshot) -> String {
        switch unit.kind {
        case "Armour":
            return "shield.lefthalf.filled"
        case "Gun":
            return "scope"
        case "Command":
            return "flag.2.crossed.fill"
        default:
            return "flag.fill"
        }
    }

    private func position(_ point: HistoricalBattleCoordinate, proxy: GeometryProxy) -> CGPoint {
        CGPoint(
            x: min(max(18, point.x / 100 * proxy.size.width), proxy.size.width - 18),
            y: min(max(18, point.y / 64 * proxy.size.height), proxy.size.height - 18)
        )
    }

    private func scaledWidth(_ width: Double, proxy: GeometryProxy) -> Double {
        width / 100 * proxy.size.width
    }

    private func scaledHeight(_ height: Double, proxy: GeometryProxy) -> Double {
        height / 64 * proxy.size.height
    }

    private func grid(in size: CGSize) -> Path {
        var path = Path()
        let columns = 10
        let rows = 8

        for column in 0...columns {
            let x = size.width * CGFloat(column) / CGFloat(columns)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for row in 0...rows {
            let y = size.height * CGFloat(row) / CGFloat(rows)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        return path
    }

    private func unitZIndex(_ unit: HistoricalBoardUnitSnapshot) -> Double {
        if unit.selected {
            return 3
        }
        if unit.targeted {
            return 2
        }
        return unit.destroyed ? 0 : 1
    }

    private func selectionStroke(unit: HistoricalBoardUnitSnapshot, isActiveSide: Bool) -> Color {
        if unit.selected {
            return Color.yellow
        }
        if unit.targeted {
            return Color.orange
        }
        return isActiveSide ? Color.white.opacity(0.38) : Color.white.opacity(0.18)
    }

    private func unitStateSummary(_ unit: HistoricalBoardUnitSnapshot) -> String {
        let status: String
        if unit.destroyed {
            status = "destroyed"
        } else if let currentOrder = unit.currentOrder {
            status = "order \(currentOrder.rawValue.lowercased())"
        } else if unit.selected {
            status = "selected"
        } else if unit.targeted {
            status = "targeted"
        } else if unit.sideID == snapshot.activeSideID {
            status = "active"
        } else {
            status = "opposing"
        }
        let pins = unit.pinCount > 0 ? " | pins \(unit.pinCount)" : ""
        return "\(unit.sideID) | \(unit.role) | \(status)\(pins)"
    }

    private func handleUnitTap(_ unit: HistoricalBoardUnitSnapshot) {
        switch HistoricalBoardInteractionResolver.unitTapIntent(for: unit, in: snapshot) {
        case .selectUnit(let id):
            onSelectUnit(id)
        case .selectTarget(let id):
            onSelectTarget(id)
        case .clearSelection:
            onClearSelection()
        case .ignored:
            break
        }
    }

    private func unitTapHint(_ unit: HistoricalBoardUnitSnapshot) -> String {
        switch HistoricalBoardInteractionResolver.unitTapIntent(for: unit, in: snapshot) {
        case .selectUnit:
            return "Selects this active unit."
        case .selectTarget:
            return "Targets this opposing unit."
        case .clearSelection:
            return "Clears the current selection."
        case .ignored:
            return "This unit cannot be selected."
        }
    }

    private func helpText(title: String, disabled: Bool) -> String {
        if disabled {
            return "\(title) is waiting for a legal unit, phase, target, or unresolved debrief state."
        }
        return "\(title) command"
    }
}
