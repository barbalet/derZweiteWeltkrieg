import SwiftUI

struct BattleShellView: View {
    @ObservedObject var controller: GameController
    @Binding var followUpChoice: FollowUpChoice
    @Binding var dragPreview: [Int: CGPoint]

    var body: some View {
        HStack(spacing: 18) {
            VStack(spacing: 14) {
                BattleHeaderView(controller: controller)
                BattleBoardView(controller: controller, dragPreview: $dragPreview)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BattleSidebarView(controller: controller, followUpChoice: $followUpChoice)
                .frame(width: 340)
        }
        .padding(18)
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
}
