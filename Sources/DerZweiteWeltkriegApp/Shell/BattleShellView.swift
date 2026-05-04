import AppKit
import SwiftUI

enum BattleShellPanel: String, CaseIterable, Identifiable {
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

@MainActor
private final class BattleShellWindowCoordinator: NSObject, ObservableObject, NSWindowDelegate {
    @Published private(set) var visiblePanels: Set<BattleShellPanel> = []

    private var windows: [BattleShellPanel: NSWindow] = [:]
    private var panelsByWindowID: [ObjectIdentifier: BattleShellPanel] = [:]

    func showDefaults(controller: GameController, followUpChoice: Binding<FollowUpChoice>) {
        for panel in [BattleShellPanel.command, .inspector] {
            show(panel, controller: controller, followUpChoice: followUpChoice)
        }
    }

    func toggle(
        _ panel: BattleShellPanel,
        controller: GameController,
        followUpChoice: Binding<FollowUpChoice>
    ) {
        if visiblePanels.contains(panel) {
            hide(panel)
        } else {
            show(panel, controller: controller, followUpChoice: followUpChoice)
        }
    }

    func show(
        _ panel: BattleShellPanel,
        controller: GameController,
        followUpChoice: Binding<FollowUpChoice>
    ) {
        let window = windows[panel] ?? makeWindow(for: panel)
        window.contentViewController = NSHostingController(
            rootView: BattleShellPanelWindow(
                panel: panel,
                controller: controller,
                followUpChoice: followUpChoice
            )
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        visiblePanels.insert(panel)
    }

    func hide(_ panel: BattleShellPanel) {
        windows[panel]?.orderOut(nil)
        visiblePanels.remove(panel)
    }

    func closeAll() {
        for window in windows.values {
            window.delegate = nil
            window.close()
        }
        windows.removeAll()
        panelsByWindowID.removeAll()
        visiblePanels.removeAll()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let panel = panelsByWindowID[ObjectIdentifier(window)] else {
            return
        }
        visiblePanels.remove(panel)
    }

    private func makeWindow(for panel: BattleShellPanel) -> NSWindow {
        let frame = defaultFrame(for: panel)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "derZweiteWeltkrieg \(panel.title)"
        window.minSize = panel.minimumSize
        window.isReleasedWhenClosed = false
        window.delegate = self
        windows[panel] = window
        panelsByWindowID[ObjectIdentifier(window)] = panel
        return window
    }

    private func defaultFrame(for panel: BattleShellPanel) -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 80, y: 80, width: 1440, height: 900)
        let size = panel.defaultSize
        let origin: CGPoint
        switch panel {
        case .command:
            origin = CGPoint(x: screen.minX + 36, y: screen.maxY - size.height - 72)
        case .inspector:
            origin = CGPoint(x: screen.maxX - size.width - 44, y: screen.maxY - size.height - 88)
        case .forces:
            origin = CGPoint(x: screen.maxX - size.width - 72, y: screen.minY + 68)
        case .log:
            origin = CGPoint(x: screen.minX + 64, y: screen.minY + 74)
        }
        return CGRect(origin: origin, size: size)
    }
}

private extension BattleShellPanel {
    var defaultSize: CGSize {
        switch self {
        case .command:
            return CGSize(width: 860, height: 700)
        case .inspector:
            return CGSize(width: 340, height: 520)
        case .forces:
            return CGSize(width: 360, height: 560)
        case .log:
            return CGSize(width: 380, height: 460)
        }
    }

    var minimumSize: CGSize {
        switch self {
        case .command:
            return CGSize(width: 620, height: 420)
        case .inspector:
            return CGSize(width: 300, height: 360)
        case .forces:
            return CGSize(width: 320, height: 360)
        case .log:
            return CGSize(width: 320, height: 300)
        }
    }

    var scrollIdentifier: String {
        switch self {
        case .command:
            return "battle-sidebar-scroll"
        case .inspector:
            return "battle-inspector-scroll"
        case .forces:
            return "battle-forces-scroll"
        case .log:
            return "battle-log-scroll"
        }
    }
}

private struct BattleShellPanelWindow: View {
    let panel: BattleShellPanel
    @ObservedObject var controller: GameController
    @Binding var followUpChoice: FollowUpChoice

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 14) {
                content
            }
            .foregroundStyle(BattlePalette.sidebarPrimaryText)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(panel.scrollIdentifier)
        .frame(minWidth: panel.minimumSize.width, minHeight: panel.minimumSize.height)
        .background(BattlePalette.sidebarBackground)
    }

    @ViewBuilder
    private var content: some View {
        switch panel {
        case .command:
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
        case .inspector:
            BattleInspectorSection(controller: controller)
            BattleObjectivesSection(controller: controller)
        case .forces:
            BattleArmiesSection(controller: controller)
            BattleLegendStripView()
        case .log:
            BattleGuideSection()
            BattleLogSection(lines: controller.logs)
        }
    }
}

struct BattleShellView: View {
    @ObservedObject var controller: GameController
    @Binding var followUpChoice: FollowUpChoice
    @Binding var dragPreview: [Int: CGPoint]
    @StateObject private var panelWindows = BattleShellWindowCoordinator()
    @State private var battlefieldZoom: CGFloat = 1

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
        }
        .background(BattlePalette.shellBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(controller.isDeploymentMode ? "deployment-screen" : "battle-screen")
        .onAppear {
            panelWindows.showDefaults(controller: controller, followUpChoice: $followUpChoice)
        }
        .onDisappear {
            panelWindows.closeAll()
        }
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
                .tint(panelWindows.visiblePanels.contains(panel) ? BattlePalette.playerOneAccent : Color.black.opacity(0.32))
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

    private var zoomBinding: Binding<CGFloat> {
        Binding(
            get: { battlefieldZoom },
            set: { battlefieldZoom = clampedZoom($0) }
        )
    }

    private func toggle(_ panel: BattleShellPanel) {
        panelWindows.toggle(panel, controller: controller, followUpChoice: $followUpChoice)
    }

    private func adjustZoom(by delta: CGFloat) {
        battlefieldZoom = clampedZoom(battlefieldZoom + delta)
    }

    private func clampedZoom(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, 0.6), 2.2)
    }
}
