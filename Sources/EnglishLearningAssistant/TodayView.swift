import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyStudyItem.displayOrder) private var allItems: [DailyStudyItem]
    @Query private var progress: [LearningProgress]

    private var allTodayItems: [DailyStudyItem] {
        allItems.filter { Calendar.current.isDateInToday($0.studyDate) }
    }

    private var progressByID: [String: LearningStatus] {
        Dictionary(uniqueKeysWithValues: progress.map { ($0.contentID, $0.status) })
    }

    private var visibleTodayItems: [DailyStudyItem] {
        allTodayItems.filter { progressByID[$0.contentID] == nil }
    }

    private var completedCount: Int {
        allTodayItems.filter { progressByID[$0.contentID] != nil }.count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header

                if visibleTodayItems.isEmpty {
                    ContentUnavailableView(
                        "今天的新内容已经学完",
                        systemImage: "checkmark.seal",
                        description: Text("明天会为你准备新的单词和语法。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(visibleTodayItems) { item in
                        card(for: item)
                    }
                }
            }
            .frame(maxWidth: 760)
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("今日学习")
        .task {
            try? StudyPlanner.ensureToday(in: modelContext)
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("今天，学一点就很好")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.accent)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(completedCount) / \(allTodayItems.count)")
                    .font(.headline.monospacedDigit())
                ProgressView(
                    value: Double(completedCount),
                    total: Double(max(allTodayItems.count, 1))
                )
                .tint(AppTheme.accent)
                .frame(width: 130)
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func card(for item: DailyStudyItem) -> some View {
        switch item.contentKind {
        case .vocabulary:
            if let entry = ContentRepository.shared.vocabulary(id: item.contentID) {
                VocabularyCard(entry: entry, status: progressByID[item.contentID])
            }
        case .grammar:
            if let entry = ContentRepository.shared.grammar(id: item.contentID) {
                GrammarCard(entry: entry, status: progressByID[item.contentID])
            }
        }
    }
}
