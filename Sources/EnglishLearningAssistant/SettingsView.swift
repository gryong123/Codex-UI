import AppKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsItems: [UserSettings]
    @State private var showClearConfirmation = false

    var body: some View {
        Group {
            if let settings = settingsItems.first {
                SettingsForm(
                    settings: settings,
                    showClearConfirmation: $showClearConfirmation
                )
            } else {
                ProgressView()
                    .task {
                        _ = try? StudyPlanner.ensureSettings(in: modelContext)
                    }
            }
        }
        .navigationTitle("设置")
        .confirmationDialog(
            "清空全部学习记录？",
            isPresented: $showClearConfirmation
        ) {
            Button("清空记录", role: .destructive) {
                clearLearningData()
            }
        } message: {
            Text("此操作会删除今日内容、已学会、生词本和历史记录，无法撤销。")
        }
    }

    private func clearLearningData() {
        try? modelContext.delete(model: DailyStudyItem.self)
        try? modelContext.delete(model: LearningProgress.self)
        try? modelContext.delete(model: LearningActionEvent.self)
        try? modelContext.save()
        try? StudyPlanner.ensureToday(in: modelContext)
    }
}

private struct SettingsForm: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: UserSettings
    @Binding var showClearConfirmation: Bool

    var body: some View {
        Form {
            Section("每日学习") {
                Stepper(
                    "单词数量：\(settings.dailyVocabularyCount)",
                    value: $settings.dailyVocabularyCount,
                    in: 1...20
                )
                Stepper(
                    "语法数量：\(settings.dailyGrammarCount)",
                    value: $settings.dailyGrammarCount,
                    in: 1...5
                )
                Text("数量调整会从下一次生成每日内容时生效。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("每日提醒") {
                DatePicker(
                    "提醒时间",
                    selection: Binding(
                        get: { settings.notificationDate },
                        set: { settings.notificationDate = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )

                Toggle("启用系统通知", isOn: $settings.notificationsEnabled)

                HStack {
                    Text(notificationStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("打开系统通知设置") {
                        openNotificationSettings()
                    }
                }
            }

            Section("语音") {
                LabeledContent("发音语言", value: "美式英语")
                LabeledContent("语音来源", value: "macOS 离线语音")
            }

            Section("数据") {
                Button("清空全部学习记录", role: .destructive) {
                    showClearConfirmation = true
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .onChange(of: settings.notificationHour) { _, _ in saveAndReschedule() }
        .onChange(of: settings.notificationMinute) { _, _ in saveAndReschedule() }
        .onChange(of: settings.dailyVocabularyCount) { _, _ in saveAndReschedule() }
        .onChange(of: settings.dailyGrammarCount) { _, _ in saveAndReschedule() }
        .onChange(of: settings.notificationsEnabled) { _, enabled in
            Task {
                if enabled {
                    let granted = await NotificationService.requestAuthorization()
                    settings.notificationsEnabled = granted
                    if granted {
                        await schedule()
                    }
                } else {
                    NotificationService.cancel()
                }
                try? modelContext.save()
            }
        }
    }

    private var notificationStatusText: String {
        settings.notificationsEnabled
            ? "每天 \(String(format: "%02d:%02d", settings.notificationHour, settings.notificationMinute)) 提醒"
            : "通知已关闭"
    }

    private func saveAndReschedule() {
        try? modelContext.save()
        guard settings.notificationsEnabled else { return }
        Task { await schedule() }
    }

    private func schedule() async {
        await NotificationService.schedule(
            hour: settings.notificationHour,
            minute: settings.notificationMinute,
            vocabularyCount: settings.dailyVocabularyCount,
            grammarCount: settings.dailyGrammarCount
        )
    }

    private func openNotificationSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.notifications"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
