import AVFoundation
import Foundation
import Observation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var currentText: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func toggle(_ text: String) {
        if currentText == text, synthesizer.isSpeaking {
            stop()
            return
        }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.44
        currentText = text
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        currentText = nil
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            currentText = nil
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            currentText = nil
        }
    }
}

enum NotificationService {
    static let requestIdentifier = "daily-learning-reminder"

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func schedule(hour: Int, minute: Int, vocabularyCount: Int, grammarCount: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "今天的英语准备好了"
        content.body = "\(vocabularyCount) 个单词和 \(grammarCount) 条语法，花几分钟轻松学完。"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
    }
}

@MainActor
enum StudyPlanner {
    static func ensureSettings(in context: ModelContext) throws -> UserSettings {
        var descriptor = FetchDescriptor<UserSettings>(
            predicate: #Predicate { $0.key == "primary" }
        )
        descriptor.fetchLimit = 1
        if let settings = try context.fetch(descriptor).first {
            return settings
        }

        let settings = UserSettings()
        context.insert(settings)
        try context.save()
        return settings
    }

    static func ensureToday(
        in context: ModelContext,
        repository: ContentRepository = .shared,
        calendar: Calendar = .current
    ) throws {
        let start = calendar.startOfDay(for: .now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        let dailyDescriptor = FetchDescriptor<DailyStudyItem>(
            predicate: #Predicate { $0.studyDate >= start && $0.studyDate < end }
        )
        guard try context.fetch(dailyDescriptor).isEmpty else { return }

        let settings = try ensureSettings(in: context)
        let progress = try context.fetch(FetchDescriptor<LearningProgress>())
        let excluded = Set(progress.map(\.contentID))

        let vocabulary = repository.vocabulary
            .filter { !excluded.contains($0.id) }
            .shuffled()
            .prefix(settings.dailyVocabularyCount)
        let grammar = repository.grammar
            .filter { !excluded.contains($0.id) }
            .shuffled()
            .prefix(settings.dailyGrammarCount)

        var order = 0
        for entry in vocabulary {
            context.insert(
                DailyStudyItem(
                    studyDate: start,
                    contentID: entry.id,
                    contentKind: .vocabulary,
                    displayOrder: order
                )
            )
            order += 1
        }
        for entry in grammar {
            context.insert(
                DailyStudyItem(
                    studyDate: start,
                    contentID: entry.id,
                    contentKind: .grammar,
                    displayOrder: order
                )
            )
            order += 1
        }
        try context.save()
    }

    static func setStatus(
        _ status: LearningStatus,
        contentID: String,
        kind: ContentKind,
        in context: ModelContext
    ) throws {
        let id = contentID
        var descriptor = FetchDescriptor<LearningProgress>(
            predicate: #Predicate { $0.contentID == id }
        )
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor).first
        let previous = existing?.status

        if let existing {
            existing.status = status
        } else {
            context.insert(
                LearningProgress(contentID: contentID, contentKind: kind, status: status)
            )
        }
        context.insert(
            LearningActionEvent(
                contentID: contentID,
                contentKind: kind,
                previousStatus: previous,
                newStatus: status
            )
        )
        try context.save()
    }

    static func clearStatus(
        contentID: String,
        in context: ModelContext
    ) throws {
        let id = contentID
        var descriptor = FetchDescriptor<LearningProgress>(
            predicate: #Predicate { $0.contentID == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }
}
