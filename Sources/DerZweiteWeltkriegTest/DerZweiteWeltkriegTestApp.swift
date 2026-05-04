import SwiftUI
#if SWIFT_PACKAGE
import DerZweiteWeltkriegAppUI
#endif

@main
struct DerZweiteWeltkriegTestApp: App {
    var body: some Scene {
        WindowGroup("derZweiteWeltkriegTest") {
            DerZweiteWeltkriegRootView()
                .frame(minWidth: 1320, minHeight: 820)
        }
        .windowResizability(.contentSize)

        WindowGroup("derZweiteWeltkriegTest Playability") {
            DerZweiteWeltkriegPlayabilityDashboard()
                .frame(minWidth: 760, minHeight: 540)
        }
        .windowResizability(.contentMinSize)
    }
}
