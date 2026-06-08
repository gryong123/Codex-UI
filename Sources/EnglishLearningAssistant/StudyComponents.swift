import SwiftData
import SwiftUI

enum AppTheme {
    static let accent = Color.orange
}

struct SpeakButton: View {
    @Environment(SpeechService.self) private var speech
    let text: String
    var compact = false

    var isSpeaking: Bool {
        speech.currentText == text
    }

    var body: some View {
        Button {
            speech.toggle(text)
        } label: {
            if compact {
                Image(systemName: isSpeaking ? "stop.fill" : "speaker.wave.2")
            } else {
                Label(
                    isSpeaking ? "停止" : "发音",
                    systemImage: isSpeaking ? "stop.fill" : "speaker.wave.2"
                )
            }
        }
        .buttonStyle(.borderless)
        .help(isSpeaking ? "停止朗读" : "朗读英文")
        .accessibilityLabel(isSpeaking ? "停止朗读 \(text)" : "朗读 \(text)")
    }
}

struct StatusButtons: View {
    @Environment(\.modelContext) private var modelContext
    let contentID: String
    let kind: ContentKind
    let currentStatus: LearningStatus?

    var body: some View {
        HStack(spacing: 10) {
            Button {
                setStatus(.learned)
            } label: {
                Label(
                    currentStatus == .learned ? "已学会" : "学会了",
                    systemImage: currentStatus == .learned
                        ? "checkmark.circle.fill"
                        : "checkmark.circle"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button {
                setStatus(.saved)
            } label: {
                Label("加入生词本", systemImage: currentStatus == .saved ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.accent)
        }
    }

    private func setStatus(_ status: LearningStatus) {
        try? StudyPlanner.setStatus(
            status,
            contentID: contentID,
            kind: kind,
            in: modelContext
        )
    }
}

struct VocabularyCard: View {
    let entry: VocabularyEntry
    let status: LearningStatus?
    var showActions = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.word)
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .textSelection(.enabled)
                    HStack(spacing: 8) {
                        Text(entry.phonetic)
                            .foregroundStyle(.secondary)
                        Text(entry.partOfSpeech)
                            .font(.caption)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                Spacer()
                SpeakButton(text: entry.word)
            }

            Text(entry.meaning)
                .font(.title3.weight(.medium))

            ExampleBlock(
                english: entry.example,
                translation: entry.translation
            )

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("常用短语")
                    .font(.headline)
                ForEach(entry.phrases, id: \.text) { phrase in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(phrase.text)
                                .font(.body.weight(.semibold))
                            SpeakButton(text: phrase.text, compact: true)
                            Spacer()
                            Text(phrase.meaning)
                                .foregroundStyle(.secondary)
                        }
                        Text(phrase.example)
                            .font(.callout)
                        HStack(alignment: .firstTextBaseline) {
                            Text(phrase.translation)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            SpeakButton(text: phrase.example, compact: true)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("用法与语法")
                    .font(.headline)
                ForEach(entry.usageNotes, id: \.self) { note in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(note.category)
                            .font(.subheadline.weight(.semibold))
                        Text(note.explanation)
                            .foregroundStyle(.secondary)
                        Text(note.pattern)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                    }
                }
            }

            if showActions {
                Divider()
                StatusButtons(
                    contentID: entry.id,
                    kind: .vocabulary,
                    currentStatus: status
                )
            }
        }
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 1)
        }
    }
}

struct GrammarCard: View {
    let entry: GrammarEntry
    let status: LearningStatus?
    var showActions = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("语法", systemImage: "text.book.closed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
            }

            Text(entry.title)
                .font(.system(size: 28, weight: .semibold, design: .serif))
            Text(entry.explanation)
                .font(.title3)

            Text(entry.pattern)
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

            ExampleBlock(english: entry.example, translation: entry.translation)

            if showActions {
                Divider()
                StatusButtons(
                    contentID: entry.id,
                    kind: .grammar,
                    currentStatus: status
                )
            }
        }
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 1)
        }
    }
}

struct ExampleBlock: View {
    let english: String
    let translation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(english)
                    .font(.body.weight(.medium))
                    .textSelection(.enabled)
                Spacer(minLength: 12)
                SpeakButton(text: english, compact: true)
            }
            Text(translation)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 12)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(AppTheme.accent)
                .frame(width: 3)
        }
    }
}
