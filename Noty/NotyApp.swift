import SwiftUI

@main
struct NotyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .defaultLaunchBehavior(.suppressed)
        .commandsRemoved()
    }
}
