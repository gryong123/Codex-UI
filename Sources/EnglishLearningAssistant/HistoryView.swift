import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LearningProgress.updatedAt, order: .reverse)
    private var allProgress: [LearningProgress]
    @State private var searchText = ""

    let status: LearningStatus

    private var filteredProgress: [LearningProgress] {
        allProgress.filter { item in
            guard item.status == status else { return false }
            guard !searchText.isEmpty else { return true }
            let query = searchText.localizedLowercase
            if let word = ContentRepository.shared.vocabulary(id: item.contentID) {
                return word.word.localizedLowercase.contains(query)
                    || word.meaning.localizedLowercase.contains(query)
            }
            if let grammar = ContentRepository.shared.grammar(id: item.contentID) {
                return grammar.title.localizedLowercase.contains(query)
                    || grammar.explanation.localizedLowercase.contains(query)
            }
            return false
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(status.title)
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                    Spacer()
                    Text("\(filteredProgress.count) 条")
                        .foregroundStyle(.secondary)
                }

                if filteredProgress.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 100)
                } else {
                    ForEach(filteredProgress) { item in
                        historyCard(item)
                    }
                }
            }
            .frame(maxWidth: 760)
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(status.title)
        .searchable(text: $searchText, prompt: "搜索英文或中文")
    }

    @ViewBuilder
    private func historyCard(_ item: LearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                if let word = ContentRepository.shared.vocabulary(id: item.contentID) {
                    Text(word.word)
                        .font(.title2.weight(.semibold))
                    Text(word.meaning)
                        .foregroundStyle(.secondary)
                    Spacer()
                    SpeakButton(text: word.word, compact: true)
                } else if let grammar = ContentRepository.shared.grammar(id: item.contentID) {
                    Text(grammar.title)
                        .font(.title2.weight(.semibold))
                    Spacer()
                    SpeakButton(text: grammar.example, compact: true)
                }
            }

            if let word = ContentRepository.shared.vocabulary(id: item.contentID) {
                Text(word.example)
                Text(word.translation)
                    .foregroundStyle(.secondary)
            } else if let grammar = ContentRepository.shared.grammar(id: item.contentID) {
                Text(grammar.explanation)
                Text(grammar.example)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(
                    item.updatedAt.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Button {
                    performAction(item)
                } label: {
                    Label(
                        status == .learned ? "取消已学会" : "标记为学会",
                        systemImage: status == .learned
                            ? "arrow.uturn.backward.circle"
                            : "checkmark.circle"
                    )
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 1)
        }
    }

    private func performAction(_ item: LearningProgress) {
        if status == .learned {
            try? StudyPlanner.clearStatus(
                contentID: item.contentID,
                in: modelContext
            )
        } else {
            try? StudyPlanner.setStatus(
                .learned,
                contentID: item.contentID,
                kind: item.contentKind,
                in: modelContext
            )
        }
    }
}
