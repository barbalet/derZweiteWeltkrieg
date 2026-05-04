import SwiftUI

private enum BattleShellPanel: String, CaseIterable, Identifiable {
    case command
    case inspector
    case forces
    case log

    var id: Self { self }

    var title: String {
        switch self {
        case .command:
            return "Command"
        case .inspector:
            return "Inspector"
        case .forces:
            return "Forces"
        case .log:
            return "Log"
        }
    }

    var systemImage: String {
        switch self {
        case .command:
            return "slider.horizontal.3"
        case .inspector:
            return "scope"
        case .forces:
            return "person.3"
        case .log:
            return "list.bullet.rectangle"
        }
    }
}

struct BattleShellView: View {
    @ObservedObject var controller: GameController
    @Binding var followUpChoice: FollowUpChoice
    @Binding var dragPreview: [Int: CGPoint]
    @State private var battlefieldZoom: CGFloat = 1
    @State private var visiblePanels: Set<BattleShellPanel> = [.command, .inspector]

    var body: some View {
        ZStack(alignment: .topLeading) {
            BattlefieldViewport(
                zoom: $battlefieldZoom,
                boardWidth: GameController.boardWidth,
                boardHeight: GameController.boardHeight
            ) {
                BattleBoardView(controller: controller, dragPreview: $dragPreview)
            }

            VStack {
                battlefieldToolbar
                Spacer()
            }
            .padding(18)
            .zIndex(10)

            floatingPanels
        }
        .background(BattlePalette.shellBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(controller.isDeploymentMode ? "deployment-screen" : "battle-screen")
        .onChange(of: controller.playerOneArmyID) { _, _ in
            controller.reconcileForceSelections()
        }
        .onChange(of: controller.playerTwoArmyID) { _, _ in
            controller.reconcileForceSelections()
        }
    }

    private var battlefieldToolbar: some View {
        HStack(spacing: 10) {
            Label("Battlefield", systemImage: "map")
                .font(.system(size: 13, weight: .bold, design: .rounded))

            Button {
                adjustZoom(by: -0.15)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("Zoom out")

            Slider(value: zoomBinding, in: 0.6...2.2)
                .frame(width: 160)
                .accessibilityIdentifier("battlefield-zoom-slider")

            Text("\(Int((battlefieldZoom * 100).rounded()))%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .frame(width: 44, alignment: .trailing)

            Button {
                battlefieldZoom = 1
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("Reset zoom")

            Divider()
                .frame(height: 24)

            ForEach(BattleShellPanel.allCases) { panel in
                Button {
                    toggle(panel)
                } label: {
                    Label(panel.title, systemImage: panel.systemImage)
                }
                .tint(visiblePanels.contains(panel) ? BattlePalette.playerOneAccent : Color.black.opacity(0.32))
                .accessibilityIdentifier("toggle-\(panel.rawValue)-window")
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(10)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.68))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
    }

    @ViewBuilder
    private var floatingPanels: some View {
        if visiblePanels.contains(.command) {
            BattleFloatingWindow(
                title: BattleShellPanel.command.title,
                systemImage: BattleShellPanel.command.systemImage,
                width: 860,
                maxHeight: 700,
                scrollIdentifier: "battle-sidebar-scroll",
                onClose: { toggle(.command) }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    BattleHeaderView(controller: controller)
                    BattleControlsSection(controller: controller, followUpChoice: $followUpChoice)

                    if let pendingChoice = controller.pendingWeaponDestroyChoice {
                        BattlePendingWeaponDestroySection(controller: controller, pendingChoice: pendingChoice)
                    }

                    if let pendingAllocation = controller.pendingHitAllocationChoice {
                        BattlePendingAllocationSection(controller: controller, pendingAllocation: pendingAllocation)
                    }

                    if !controller.lastError.isEmpty {
                        BattleErrorSection(message: controller.lastError)
                    }
                }
            }
            .padding(.top, 82)
            .padding(.leading, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .zIndex(4)
        }

        if visiblePanels.contains(.inspector) {
            BattleFloatingWindow(
                title: BattleShellPanel.inspector.title,
                systemImage: BattleShellPanel.inspector.systemImage,
                width: 340,
                maxHeight: 520,
                scrollIdentifier: "battle-inspector-scroll",
                onClose: { toggle(.inspector) }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    BattleInspectorSection(controller: controller)
                    BattleObjectivesSection(controller: controller)
                }
            }
            .padding(.top, 82)
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .zIndex(5)
        }

        if visiblePanels.contains(.forces) {
            BattleFloatingWindow(
                title: BattleShellPanel.forces.title,
                systemImage: BattleShellPanel.forces.systemImage,
                width: 360,
                maxHeight: 560,
                scrollIdentifier: "battle-forces-scroll",
                onClose: { toggle(.forces) }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    BattleArmiesSection(controller: controller)
                    BattleLegendStripView()
                }
            }
            .padding(.trailing, 18)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .zIndex(3)
        }

        if visiblePanels.contains(.log) {
            BattleFloatingWindow(
                title: BattleShellPanel.log.title,
                systemImage: BattleShellPanel.log.systemImage,
                width: 380,
                maxHeight: 460,
                scrollIdentifier: "battle-log-scroll",
                onClose: { toggle(.log) }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    BattleGuideSection()
                    BattleLogSection(lines: controller.logs)
                }
            }
            .padding(.leading, 18)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(3)
        }
    }

    private var zoomBinding: Binding<CGFloat> {
        Binding(
            get: { battlefieldZoom },
            set: { battlefieldZoom = clampedZoom($0) }
        )
    }

    private func toggle(_ panel: BattleShellPanel) {
        if visiblePanels.contains(panel) {
            visiblePanels.remove(panel)
        } else {
            visiblePanels.insert(panel)
        }
    }

    private func adjustZoom(by delta: CGFloat) {
        battlefieldZoom = clampedZoom(battlefieldZoom + delta)
    }

    private func clampedZoom(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, 0.6), 2.2)
    }
}
