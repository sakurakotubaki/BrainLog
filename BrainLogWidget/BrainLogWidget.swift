//
//  BrainLogWidget.swift
//  BrainLogWidget
//
//  Created by 橋本純一 on 2026/01/29.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry
struct CommitEntry: TimelineEntry {
    let date: Date
    let commits: [CommitData]
    let totalCount: Int
}

struct CommitData: Identifiable {
    let id: UUID
    let content: String
    let createdAt: Date
    let hash: String
    let hasBranch: Bool
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> CommitEntry {
        CommitEntry(
            date: Date(),
            commits: [
                CommitData(id: UUID(), content: "Sample commit message", createdAt: Date(), hash: "abc1234", hasBranch: false)
            ],
            totalCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CommitEntry) -> ()) {
        let entry = fetchLatestCommits()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CommitEntry>) -> ()) {
        let entry = fetchLatestCommits()

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchLatestCommits() -> CommitEntry {
        do {
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(for: Item.self, configurations: configuration)
            let context = ModelContext(container)

            var descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.parentID == nil },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = 5

            let items = try context.fetch(descriptor)
            let allItems = try context.fetch(FetchDescriptor<Item>())

            let commits = items.map { item in
                let hasBranch = allItems.contains { $0.parentID == item.id }
                return CommitData(
                    id: item.id,
                    content: item.content,
                    createdAt: item.createdAt,
                    hash: String(item.id.uuidString.prefix(7)).lowercased(),
                    hasBranch: hasBranch
                )
            }

            return CommitEntry(date: Date(), commits: commits, totalCount: allItems.count)
        } catch {
            return CommitEntry(date: Date(), commits: [], totalCount: 0)
        }
    }
}

// MARK: - Widget Views
struct BrainLogWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: CommitEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundStyle(nodeColor)
                Text("BrainLog")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
            }

            if let latestCommit = entry.commits.first {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(nodeColor)
                            .frame(width: 8, height: 8)
                        Text(latestCommit.hash)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(hashColor)
                    }

                    Text(latestCommit.content)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .foregroundStyle(primaryTextColor)

                    Text(relativeDate(latestCommit.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No commits yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.totalCount) commits")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nodeColor: Color {
        colorScheme == .dark ? Color(hex: "238636") : Color(hex: "1a7f37")
    }

    private var hashColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: CommitEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundStyle(nodeColor)
                Text("BrainLog")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                Spacer()
                Text("\(entry.totalCount) commits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.commits.isEmpty {
                Spacer()
                Text("No commits yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.commits.prefix(3)) { commit in
                    HStack(spacing: 8) {
                        VStack {
                            Circle()
                                .fill(commit.hasBranch ? branchColor : nodeColor)
                                .frame(width: 8, height: 8)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(commit.content)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .foregroundStyle(primaryTextColor)

                            HStack(spacing: 6) {
                                Text(commit.hash)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(hashColor)
                                Text(relativeDate(commit.createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nodeColor: Color {
        colorScheme == .dark ? Color(hex: "238636") : Color(hex: "1a7f37")
    }

    private var branchColor: Color {
        colorScheme == .dark ? Color(hex: "a371f7") : Color(hex: "8250df")
    }

    private var hashColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: CommitEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundStyle(nodeColor)
                Text("BrainLog")
                    .font(.system(.headline, design: .monospaced))
                    .fontWeight(.semibold)
                Spacer()
                Text("\(entry.totalCount) commits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if entry.commits.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No commits yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(Array(entry.commits.prefix(5).enumerated()), id: \.element.id) { index, commit in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(commit.hasBranch ? branchColor : nodeColor)
                                .frame(width: 10, height: 10)
                            if index < min(entry.commits.count - 1, 4) {
                                Rectangle()
                                    .fill(lineColor)
                                    .frame(width: 2)
                            }
                        }
                        .frame(width: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(commit.content)
                                .font(.system(.subheadline, design: .monospaced))
                                .lineLimit(2)
                                .foregroundStyle(primaryTextColor)

                            HStack(spacing: 8) {
                                Text(commit.hash)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(hashColor)
                                Text(relativeDate(commit.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nodeColor: Color {
        colorScheme == .dark ? Color(hex: "238636") : Color(hex: "1a7f37")
    }

    private var branchColor: Color {
        colorScheme == .dark ? Color(hex: "a371f7") : Color(hex: "8250df")
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color(hex: "30363d") : Color(hex: "d0d7de")
    }

    private var hashColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Lock Screen Widgets
struct CircularWidgetView: View {
    let entry: CommitEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.caption)
                Text("\(entry.totalCount)")
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
            }
        }
    }
}

struct RectangularWidgetView: View {
    let entry: CommitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                Text("BrainLog")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
            }

            if let latest = entry.commits.first {
                Text(latest.content)
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(2)
            } else {
                Text("No commits")
                    .font(.caption2)
            }
        }
    }
}

struct InlineWidgetView: View {
    let entry: CommitEntry

    var body: some View {
        if let latest = entry.commits.first {
            Text("\(latest.hash): \(latest.content)")
        } else {
            Text("BrainLog: No commits")
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Configuration
struct BrainLogWidget: Widget {
    let kind: String = "BrainLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                BrainLogWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                BrainLogWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("BrainLog")
        .description("View your latest commits")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline
            ]
        } else {
            return [
                .systemSmall,
                .systemMedium,
                .systemLarge
            ]
        }
    }
}

#Preview(as: .systemSmall) {
    BrainLogWidget()
} timeline: {
    CommitEntry(date: .now, commits: [
        CommitData(id: UUID(), content: "Added new feature", createdAt: Date(), hash: "abc1234", hasBranch: true),
        CommitData(id: UUID(), content: "Fixed bug", createdAt: Date().addingTimeInterval(-3600), hash: "def5678", hasBranch: false)
    ], totalCount: 5)
}

#Preview(as: .systemMedium) {
    BrainLogWidget()
} timeline: {
    CommitEntry(date: .now, commits: [
        CommitData(id: UUID(), content: "Added new feature", createdAt: Date(), hash: "abc1234", hasBranch: true),
        CommitData(id: UUID(), content: "Fixed bug", createdAt: Date().addingTimeInterval(-3600), hash: "def5678", hasBranch: false),
        CommitData(id: UUID(), content: "Updated UI", createdAt: Date().addingTimeInterval(-7200), hash: "ghi9012", hasBranch: false)
    ], totalCount: 10)
}

#Preview(as: .systemLarge) {
    BrainLogWidget()
} timeline: {
    CommitEntry(date: .now, commits: [
        CommitData(id: UUID(), content: "Added new feature with a longer description", createdAt: Date(), hash: "abc1234", hasBranch: true),
        CommitData(id: UUID(), content: "Fixed bug", createdAt: Date().addingTimeInterval(-3600), hash: "def5678", hasBranch: false),
        CommitData(id: UUID(), content: "Updated UI", createdAt: Date().addingTimeInterval(-7200), hash: "ghi9012", hasBranch: false),
        CommitData(id: UUID(), content: "Refactored code", createdAt: Date().addingTimeInterval(-10800), hash: "jkl3456", hasBranch: true),
        CommitData(id: UUID(), content: "Added tests", createdAt: Date().addingTimeInterval(-14400), hash: "mno7890", hasBranch: false)
    ], totalCount: 25)
}
