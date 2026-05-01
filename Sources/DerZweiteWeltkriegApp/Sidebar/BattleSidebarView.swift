import SwiftUI

struct BattleSidebarView: View {
    @ObservedObject var controller: GameController
    @Binding var followUpChoice: FollowUpChoice

    var body: some View {
        BattleSidebarPanel {
            VStack(alignment: .leading, spacing: 14) {
                BattleInspectorSection(controller: controller)
                BattleControlsSection(controller: controller, followUpChoice: $followUpChoice)
                BattleArmiesSection(controller: controller)
                BattleObjectivesSection(controller: controller)

                if let pendingChoice = controller.pendingWeaponDestroyChoice {
                    BattlePendingWeaponDestroySection(controller: controller, pendingChoice: pendingChoice)
                }

                if let pendingAllocation = controller.pendingHitAllocationChoice {
                    BattlePendingAllocationSection(controller: controller, pendingAllocation: pendingAllocation)
                }

                if !controller.lastError.isEmpty {
                    BattleErrorSection(message: controller.lastError)
                }

                BattleGuideSection()
                BattleLegendStripView()
                BattleLogSection(lines: controller.logs)
            }
        }
    }
}
