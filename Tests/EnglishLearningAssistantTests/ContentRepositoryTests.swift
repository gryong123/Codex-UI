import Testing
import SwiftData
@testable import EnglishLearningAssistant

struct ContentRepositoryTests {
    @Test
    func repositoryContainsPlannedContent() {
        let repository = ContentRepository.shared

        #expect(repository.vocabulary.count == 300)
        #expect(repository.grammar.count == 60)
    }

    @Test
    func everyVocabularyEntryHasMemoryAids() {
        for entry in ContentRepository.shared.vocabulary {
            #expect(!entry.word.isEmpty)
            #expect(!entry.meaning.isEmpty)
            #expect(entry.phrases.count >= 2)
            #expect(!entry.usageNotes.isEmpty)
            #expect(!entry.example.isEmpty)
        }
    }

    @Test
    func vocabularyUsesCuratedDailyLifeContent() {
        let vocabulary = ContentRepository.shared.vocabulary
        let mainEntries = vocabulary.filter { !$0.id.contains("-phrase-") }
        let bannedTemplateFragments = [
            "in daily life",
            "with confidence",
            "talk about",
            "learn to"
        ]

        #expect(mainEntries.count == 100)
        #expect(Set(mainEntries.map(\.example)).count == 100)

        for entry in vocabulary {
            let content = ([entry.example] + entry.phrases.map(\.example))
                .joined(separator: " ")
                .lowercased()
            for fragment in bannedTemplateFragments {
                #expect(!content.contains(fragment))
            }
        }
    }

    @Test
    func defaultSettingsMatchProductRequirements() {
        let settings = UserSettings()

        #expect(settings.notificationHour == 9)
        #expect(settings.notificationMinute == 30)
        #expect(settings.dailyVocabularyCount == 5)
        #expect(settings.dailyGrammarCount == 1)
    }

    @Test
    @MainActor
    func plannerCreatesOneStableDailySet() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        try StudyPlanner.ensureToday(in: context)
        let firstCount = try context.fetch(FetchDescriptor<DailyStudyItem>()).count
        try StudyPlanner.ensureToday(in: context)
        let secondCount = try context.fetch(FetchDescriptor<DailyStudyItem>()).count

        #expect(firstCount == 6)
        #expect(secondCount == firstCount)
    }

    @Test
    @MainActor
    func statusChangesUpdateProgressAndAppendHistory() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        try StudyPlanner.setStatus(
            .saved,
            contentID: "v-hello",
            kind: .vocabulary,
            in: context
        )
        try StudyPlanner.setStatus(
            .learned,
            contentID: "v-hello",
            kind: .vocabulary,
            in: context
        )

        let progress = try context.fetch(FetchDescriptor<LearningProgress>())
        let events = try context.fetch(FetchDescriptor<LearningActionEvent>())
        #expect(progress.count == 1)
        #expect(progress.first?.status == .learned)
        #expect(events.count == 2)
    }

    @Test
    @MainActor
    func clearingStatusRemovesCurrentProgress() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        try StudyPlanner.setStatus(
            .learned,
            contentID: "v-hello",
            kind: .vocabulary,
            in: context
        )
        try StudyPlanner.clearStatus(contentID: "v-hello", in: context)

        let progress = try context.fetch(FetchDescriptor<LearningProgress>())
        #expect(progress.isEmpty)
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            DailyStudyItem.self,
            LearningProgress.self,
            LearningActionEvent.self,
            UserSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
