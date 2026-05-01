import SwiftUI

struct BattleInspectorSection: View {
    @ObservedObject var controller: GameController

    var body: some View {
        BattleSidebarSection("Selection") {
            if let unit = controller.selectedUnit {
                Text(unit.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("\(unit.ownerName) • \(unit.shortStatus)")
                    .foregroundStyle(BattlePalette.sidebarSecondaryText)
                Text(unit.detailSummary)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(BattlePalette.sidebarSecondaryText)
                if controller.isDeploymentMode {
                    Text("Facing: \(Int(unit.facingDegrees.rounded()))° • Drag on the board to change this unit’s starting position.")
                        .font(.system(size: 13, design: .monospaced))
                }
                Text("Models: \(unit.models)/\(unit.startingModels)")
                    .font(.system(size: 13, design: .monospaced))
                if unit.mixedProfiles {
                    Text("Wounds: \(unit.totalWoundsRemaining) total across mixed profiles")
                        .font(.system(size: 13, design: .monospaced))
                } else if unit.isMultiWound {
                    Text("Wounds: \(unit.totalWoundsRemaining) total • Lead \(unit.leadModelWounds)/\(unit.woundsPerModel)")
                        .font(.system(size: 13, design: .monospaced))
                }
                if unit.embarked, let transport = controller.units.first(where: { $0.id == unit.embarkedInTransportID }) {
                    Text("Embarked in \(transport.name)")
                        .font(.system(size: 13, design: .monospaced))
                }
                if unit.transportCapacity > 0, let passenger = controller.embarkedPassenger(for: unit) {
                    Text("Passenger: \(passenger.name) (\(passenger.models))")
                        .font(.system(size: 13, design: .monospaced))
                }
                if let range = controller.rangeBetweenSelection(), controller.selectedTarget != nil {
                    Text("Range to target: \(range, specifier: "%.1f")\"")
                        .font(.system(size: 13, design: .monospaced))
                }
            } else {
                Text(controller.isDeploymentMode ? "Select one of your units, then drag it on the board to set its starting position." : "Select one of the active player’s units to move or act.")
                    .foregroundStyle(BattlePalette.sidebarSecondaryText)
            }

            HStack {
                Button("Prev Ready") {
                    controller.cycleActiveUnit(forward: false)
                }
                .battleSecondaryButton()
                .keyboardShortcut("[", modifiers: [.command])

                Button("Next Ready") {
                    controller.cycleActiveUnit(forward: true)
                }
                .battleSecondaryButton()
                .keyboardShortcut("]", modifiers: [.command])
            }

            if controller.isDeploymentMode {
                Button("Clear") {
                    controller.clearSelection()
                }
                .battleSecondaryButton()
                .keyboardShortcut(.escape, modifiers: [])
            } else {
                HStack {
                    Button("Nearest Enemy") {
                        controller.selectNearestEnemy()
                    }
                    .battleSecondaryButton()
                    .disabled(controller.selectedUnit == nil)
                    .keyboardShortcut("e", modifiers: [.command])

                    Button("Clear") {
                        controller.clearSelection()
                    }
                    .battleSecondaryButton()
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }

            if let target = controller.selectedTarget, !controller.isDeploymentMode {
                Divider()
                Text("Target: \(target.name)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(target.detailSummary)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(BattlePalette.sidebarSecondaryText)
            }
        }
    }
}
