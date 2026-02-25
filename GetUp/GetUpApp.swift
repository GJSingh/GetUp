import SwiftUI
import SwiftData

@main
struct GetUpApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [WorkoutSession.self, ExerciseSet.self])
    }
}
