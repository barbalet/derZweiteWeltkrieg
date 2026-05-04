import SwiftUI
#if SWIFT_PACKAGE
import DerZweiteWeltkriegAppUI
#endif

@main
struct DerZweiteWeltkriegApp: App {
    var body: some Scene {
        WindowGroup("derZweiteWeltkrieg") {
            DerZweiteWeltkriegRootView()
                .frame(minWidth: 1320, minHeight: 820)
        }
        .windowResizability(.contentSize)
    }
}
