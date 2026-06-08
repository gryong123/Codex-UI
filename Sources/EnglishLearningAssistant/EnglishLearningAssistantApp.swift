import AppKit
import SwiftData
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct EnglishLearningAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container: ModelContainer = {
        let schema = Schema([
            DailyStudyItem.self,
            LearningProgress.self,
            LearningActionEvent.self,
            UserSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create the learning database: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .frame(width: 900, height: 620)
                .modelContainer(container)
                .preferredColorScheme(.light)
        } label: {
            Label("英语学习助手", systemImage: "character.book.closed")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .modelContainer(container)
                .frame(width: 520, height: 480)
                .preferredColorScheme(.light)
        }
    }
}
