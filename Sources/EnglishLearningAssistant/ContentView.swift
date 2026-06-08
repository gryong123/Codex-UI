import AppKit
import SwiftData
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case today
    case learned
    case saved
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "今日学习"
        case .learned: "已学会"
        case .saved: "生词本"
        case .settings: "设置"
        }
    }

    var icon: String {
        switch self {
        case .today: "book.pages"
        case .learned: "checkmark.circle"
        case .saved: "bookmark"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progress: [LearningProgress]
    @State private var selection: AppSection? = .today
    @State private var speech = SpeechService()

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(AppSection.allCases, selection: $selection) { section in
                    HStack {
                        Label(section.title, systemImage: section.icon)
                        Spacer()
                        if let count = count(for: section) {
                            Text("\(count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(section)
                }

                Divider()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("退出英语学习助手", systemImage: "power")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(12)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 210)
        } detail: {
            switch selection ?? .today {
            case .today:
                TodayView()
            case .learned:
                HistoryView(status: .learned)
            case .saved:
                HistoryView(status: .saved)
            case .settings:
                SettingsView()
            }
        }
        .environment(speech)
        .task {
            try? StudyPlanner.ensureToday(in: modelContext)
            await requestNotificationsOnFirstLaunch()
        }
    }

    private func count(for section: AppSection) -> Int? {
        switch section {
        case .learned:
            progress.count { $0.status == .learned }
        case .saved:
            progress.count { $0.status == .saved }
        case .today, .settings:
            nil
        }
    }

    private func requestNotificationsOnFirstLaunch() async {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        let key = "hasRequestedNotificationAuthorization"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let granted = await NotificationService.requestAuthorization()
        guard let settings = try? StudyPlanner.ensureSettings(in: modelContext) else { return }
        settings.notificationsEnabled = granted
        try? modelContext.save()
        if granted {
            await NotificationService.schedule(
                hour: settings.notificationHour,
                minute: settings.notificationMinute,
                vocabularyCount: settings.dailyVocabularyCount,
                grammarCount: settings.dailyGrammarCount
            )
        }
    }
}
