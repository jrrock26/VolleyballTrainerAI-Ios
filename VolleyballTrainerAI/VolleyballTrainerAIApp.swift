import SwiftUI
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

@main
struct VolleyballTrainerAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var targetScreen: String? = nil

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VolleyballHit.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .navigationDestination(isPresented: Binding(
                        get: { targetScreen == "SavedAnalytics" },
                        set: { isPresented in if !isPresented { targetScreen = nil } }
                    )) {
                        SessionSummaryView()
                    }
                    .onAppear {
                        NotificationCenter.default.addObserver(
                            forName: NSNotification.Name("NavigateToScreen"),
                            object: nil,
                            queue: .main
                        ) { notification in
                            if let screen = notification.object as? String {
                                targetScreen = screen
                            }
                        }
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}