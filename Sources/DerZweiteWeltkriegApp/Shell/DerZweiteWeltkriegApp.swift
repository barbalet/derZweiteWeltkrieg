import SwiftUI

@main
struct DerZweiteWeltkriegApp: App {
    var body: some Scene {
        WindowGroup("derZweiteWeltkrieg") {
            ContentView()
                .frame(minWidth: 1320, minHeight: 820)
        }
        .windowResizability(.contentSize)
    }
}
