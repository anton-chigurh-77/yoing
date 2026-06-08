import SwiftUI
import YoingCore

struct UsageStatsSection: View {
    var snapshot: UsageStatsSnapshot

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Usage")
                    .font(.headline)

                Spacer()

                Text("Last \(snapshot.days.count / 7) weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                UsageMetricTile(value: formattedNumber(snapshot.today.wordCount), label: "words today")
                UsageMetricTile(value: formattedNumber(snapshot.today.sessionCount), label: "sessions today")
                UsageMetricTile(value: formattedMinutes(snapshot.today.dictatedSeconds), label: "minutes today")
                UsageMetricTile(value: formattedWPM(snapshot.today.wordsPerMinute), label: "estimated wpm")
            }

            DailyWordsBarChart(days: Array(snapshot.days.suffix(30)))

            ContributionGrid(days: snapshot.days)

            Text(activitySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var activitySummary: String {
        guard snapshot.totalSessions > 0 else {
            return "No dictations yet"
        }

        let wordNoun = snapshot.totalWords == 1 ? "word" : "words"
        let sessionNoun = snapshot.totalSessions == 1 ? "session" : "sessions"
        return "\(formattedNumber(snapshot.totalWords)) \(wordNoun) across \(formattedNumber(snapshot.totalSessions)) \(sessionNoun)"
    }

    private func formattedNumber(_ value: Int) -> String {
        value.formatted(.number)
    }

    private func formattedMinutes(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else {
            return "0m"
        }

        if seconds < 60 {
            return "<1m"
        }

        return "\(Int((seconds / 60).rounded()))m"
    }

    private func formattedWPM(_ value: Int?) -> String {
        guard let value else {
            return "--"
        }

        return formattedNumber(value)
    }
}

private struct DailyWordsBarChart: View {
    var days: [DailyUsageStats]

    private var maxWords: Int {
        max(days.map(\.wordCount).max() ?? 0, 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let maxBarHeight = max(1, proxy.size.height - 14)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(barColor(for: day))
                        .frame(height: barHeight(for: day, maxHeight: maxBarHeight))
                        .frame(maxWidth: .infinity, alignment: .bottom)
                        .help(helpText(for: day))
                        .accessibilityLabel(helpText(for: day))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
        }
        .frame(height: 72)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily dictated words bar chart")
    }

    private func barHeight(for day: DailyUsageStats, maxHeight: CGFloat) -> CGFloat {
        guard day.wordCount > 0 else {
            return 3
        }

        let height = CGFloat(day.wordCount) / CGFloat(maxWords) * maxHeight
        return max(5, height)
    }

    private func barColor(for day: DailyUsageStats) -> Color {
        day.wordCount > 0 ? Color(nsColor: .controlAccentColor) : Color.secondary.opacity(0.16)
    }

    private func helpText(for day: DailyUsageStats) -> String {
        let date = day.day.formatted(date: .abbreviated, time: .omitted)
        let wordNoun = day.wordCount == 1 ? "word" : "words"
        return "\(date): \(day.wordCount) \(wordNoun)"
    }
}

private struct UsageMetricTile: View {
    var value: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ContributionGrid: View {
    var days: [DailyUsageStats]

    private let spacing: CGFloat = 3

    private var weeks: [[DailyUsageStats]] {
        stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    private var maxWords: Int {
        max(days.map(\.wordCount).max() ?? 0, 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let columnCount = max(weeks.count, 1)
            let rawCellSide = (proxy.size.width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            let cellSide = max(8, min(14, rawCellSide))

            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: spacing) {
                        ForEach(week) { day in
                            ContributionCell(day: day, maxWords: maxWords, cellSide: cellSide)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 116)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Dictation activity grid")
    }
}

private struct ContributionCell: View {
    var day: DailyUsageStats
    var maxWords: Int
    var cellSide: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(cellColor)
            .frame(width: cellSide, height: cellSide)
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(.separator.opacity(0.35), lineWidth: 0.5)
            }
            .help(helpText)
            .accessibilityLabel(helpText)
    }

    private var cellColor: Color {
        guard day.wordCount > 0 else {
            return Color.secondary.opacity(0.14)
        }

        let opacity: Double
        switch Double(day.wordCount) / Double(maxWords) {
        case 0..<0.25:
            opacity = 0.35
        case 0.25..<0.5:
            opacity = 0.5
        case 0.5..<0.75:
            opacity = 0.7
        default:
            opacity = 0.95
        }

        return Color(nsColor: .controlAccentColor).opacity(opacity)
    }

    private var helpText: String {
        let date = day.day.formatted(date: .abbreviated, time: .omitted)
        let wordNoun = day.wordCount == 1 ? "word" : "words"
        let sessionNoun = day.sessionCount == 1 ? "session" : "sessions"
        return "\(date): \(day.wordCount) \(wordNoun), \(day.sessionCount) \(sessionNoun)"
    }
}
