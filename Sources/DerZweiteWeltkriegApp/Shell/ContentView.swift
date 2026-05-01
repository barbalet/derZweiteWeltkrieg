import SwiftUI

struct ContentView: View {
    @StateObject private var controller = GameController()
    @State private var followUpChoice: FollowUpChoice = .advance
    @State private var dragPreview: [Int: CGPoint] = [:]

    var body: some View {
        Group {
            if controller.appMode == .setup {
                SkirmishSetupView(controller: controller)
            } else {
                BattleShellView(
                    controller: controller,
                    followUpChoice: $followUpChoice,
                    dragPreview: $dragPreview
                )
            }
        }
    }
}
