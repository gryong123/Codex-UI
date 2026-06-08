import Foundation
import SwiftData

enum ContentKind: String, Codable, CaseIterable {
    case vocabulary
    case grammar
}

enum LearningStatus: String, Codable, CaseIterable {
    case learned
    case saved

    var title: String {
        switch self {
        case .learned: "已学会"
        case .saved: "生词本"
        }
    }
}

struct RelatedPhrase: Codable, Hashable, Sendable {
    let text: String
    let meaning: String
    let example: String
    let translation: String
}

struct UsageNote: Codable, Hashable, Sendable {
    let category: String
    let explanation: String
    let pattern: String
    let example: String
}

struct VocabularyEntry: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let word: String
    let phonetic: String
    let partOfSpeech: String
    let meaning: String
    let example: String
    let translation: String
    let phrases: [RelatedPhrase]
    let usageNotes: [UsageNote]
}

struct GrammarEntry: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let pattern: String
    let example: String
    let translation: String
}

@Model
final class DailyStudyItem {
    @Attribute(.unique) var id: String
    var studyDate: Date
    var contentID: String
    var contentKindRaw: String
    var displayOrder: Int

    init(
        id: String = UUID().uuidString,
        studyDate: Date,
        contentID: String,
        contentKind: ContentKind,
        displayOrder: Int
    ) {
        self.id = id
        self.studyDate = studyDate
        self.contentID = contentID
        self.contentKindRaw = contentKind.rawValue
        self.displayOrder = displayOrder
    }

    var contentKind: ContentKind {
        ContentKind(rawValue: contentKindRaw) ?? .vocabulary
    }
}

@Model
final class LearningProgress {
    @Attribute(.unique) var contentID: String
    var contentKindRaw: String
    var statusRaw: String
    var updatedAt: Date

    init(
        contentID: String,
        contentKind: ContentKind,
        status: LearningStatus,
        updatedAt: Date = .now
    ) {
        self.contentID = contentID
        self.contentKindRaw = contentKind.rawValue
        self.statusRaw = status.rawValue
        self.updatedAt = updatedAt
    }

    var contentKind: ContentKind {
        ContentKind(rawValue: contentKindRaw) ?? .vocabulary
    }

    var status: LearningStatus {
        get { LearningStatus(rawValue: statusRaw) ?? .saved }
        set {
            statusRaw = newValue.rawValue
            updatedAt = .now
        }
    }
}

@Model
final class LearningActionEvent {
    var id: UUID
    var contentID: String
    var contentKindRaw: String
    var previousStatusRaw: String?
    var newStatusRaw: String
    var occurredAt: Date

    init(
        contentID: String,
        contentKind: ContentKind,
        previousStatus: LearningStatus?,
        newStatus: LearningStatus,
        occurredAt: Date = .now
    ) {
        self.id = UUID()
        self.contentID = contentID
        self.contentKindRaw = contentKind.rawValue
        self.previousStatusRaw = previousStatus?.rawValue
        self.newStatusRaw = newStatus.rawValue
        self.occurredAt = occurredAt
    }
}

@Model
final class UserSettings {
    @Attribute(.unique) var key: String
    var notificationHour: Int
    var notificationMinute: Int
    var dailyVocabularyCount: Int
    var dailyGrammarCount: Int
    var notificationsEnabled: Bool

    init(
        key: String = "primary",
        notificationHour: Int = 9,
        notificationMinute: Int = 30,
        dailyVocabularyCount: Int = 5,
        dailyGrammarCount: Int = 1,
        notificationsEnabled: Bool = false
    ) {
        self.key = key
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.dailyVocabularyCount = dailyVocabularyCount
        self.dailyGrammarCount = dailyGrammarCount
        self.notificationsEnabled = notificationsEnabled
    }

    var notificationDate: Date {
        get {
            Calendar.current.date(
                bySettingHour: notificationHour,
                minute: notificationMinute,
                second: 0,
                of: .now
            ) ?? .now
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            notificationHour = components.hour ?? 9
            notificationMinute = components.minute ?? 30
        }
    }
}
