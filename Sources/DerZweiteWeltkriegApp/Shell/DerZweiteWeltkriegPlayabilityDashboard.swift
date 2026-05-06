import SwiftUI
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
import DerZweiteWeltkriegGuderian
#endif

@MainActor
private final class DerZweiteWeltkriegPlayabilityViewModel: ObservableObject {
    @Published private(set) var steps: [DerZweiteWeltkriegPlayabilityStep] = []
    @Published private(set) var isRunning = false

    var passedCount: Int {
        steps.filter(\.passed).count
    }

    var isPassing: Bool {
        !steps.isEmpty && steps.allSatisfy(\.passed)
    }

    func run() {
        guard !isRunning else {
            return
        }

        isRunning = true
        steps = []

        let controller = GameController(seed: 1_944)
        record("Setup UI", controller.appMode == .setup, "Production setup controller loaded \(controller.armyReferences.count) army references.")

        controller.startBattleFromSetup()
        record("Deployment UI", controller.appMode == .deployment, "The same setup flow opened deployment with \(controller.units.count) units.")
        record("Board Content", !controller.units.isEmpty && !controller.objectiveStates.isEmpty, "\(controller.units.count) units and \(controller.objectiveStates.count) objectives are available to the production board.")

        controller.cycleActiveUnit(forward: true)
        let selectedForDeployment = controller.selectedUnit
        if selectedForDeployment != nil {
            controller.rotateSelected(by: 45)
        }
        record("Deployment Command", selectedForDeployment != nil, selectedForDeployment.map { "\($0.name) selected and rotated through the production command path." } ?? "No deployment unit could be selected.")

        controller.beginBattle()
        record("Battle UI", controller.appMode == .battle, "The shared battle shell opened on \(controller.game.phaseName).")

        controller.cycleActiveUnit(forward: true)
        controller.selectNearestEnemy()
        record("Selection And Targeting", controller.selectedUnit != nil && controller.selectedTarget != nil, targetDetail(from: controller))

        controller.advancePhase()
        record("Phase Flow", controller.game.phase == DZW_PHASE_SHOOTING, "Next Phase advanced to \(controller.game.phaseName).")

        controller.selectNearestEnemy()
        controller.shootSelected()
        record("Combat Command", !controller.lastError.isEmpty || !controller.logs.isEmpty, controller.lastError.isEmpty ? "Combat command emitted \(controller.logs.count) log lines." : controller.lastError)

#if SWIFT_PACKAGE
        runGuderianScenarioProbe()
#endif

        isRunning = false
    }

    private func targetDetail(from controller: GameController) -> String {
        guard let unit = controller.selectedUnit else {
            return "No active unit selected."
        }
        guard let target = controller.selectedTarget else {
            return "\(unit.name) selected without a target."
        }
        return "\(unit.name) selected \(target.name) as target."
    }

    private func record(_ title: String, _ passed: Bool, _ detail: String) {
        steps.append(
            DerZweiteWeltkriegPlayabilityStep(
                title: title,
                passed: passed,
                detail: detail
            )
        )
    }

#if SWIFT_PACKAGE
    private func runGuderianScenarioProbe() {
        do {
            let result = try DZWPlayableScreenHarness.runBattleFlow(for: .tucholaForest, seed: 1_939_0901)
            record(
                "Guderian Campaign Bridge",
                result.completedAllStages,
                result.completedAllStages
                    ? "\(result.title) completed through the dzw-hosted native scenario session."
                    : "\(result.title) reported blockers: \(result.blockers.joined(separator: "; "))"
            )
        } catch {
            record("Guderian Campaign Bridge", false, "\(error)")
        }
    }
#endif
}

private struct DerZweiteWeltkriegPlayabilityStep: Identifiable {
    let id = UUID()
    let title: String
    let passed: Bool
    let detail: String
}

public struct DerZweiteWeltkriegPlayabilityDashboard: View {
    @StateObject private var viewModel = DerZweiteWeltkriegPlayabilityViewModel()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Playability")
                        .font(.title2.weight(.semibold))
                    Text("\(viewModel.passedCount)/\(viewModel.steps.count) checks passed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    viewModel.run()
                } label: {
                    Label(viewModel.isRunning ? "Running" : "Run", systemImage: viewModel.isRunning ? "play.circle.fill" : "play.fill")
                }
                .disabled(viewModel.isRunning)
                .accessibilityIdentifier("dzw-test-playability-run-button")
            }

            Label(
                viewModel.isPassing ? "Production UI playability path is green." : "Run the shared UI playability path.",
                systemImage: viewModel.isPassing ? "checkmark.seal.fill" : "checkerboard.rectangle"
            )
            .font(.headline)
            .foregroundStyle(viewModel.isPassing ? .green : .secondary)

            List(viewModel.steps) { step in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: step.passed ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundStyle(step.passed ? .green : .red)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(.callout.weight(.medium))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
            .accessibilityIdentifier("dzw-test-playability-list")
        }
        .padding(18)
        .onAppear {
            if viewModel.steps.isEmpty {
                viewModel.run()
            }
        }
    }
}
