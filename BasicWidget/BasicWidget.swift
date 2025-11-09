//
//  basicWidget.swift
//  basicWidget
//
//  Created by 이종우 on 9/30/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: TimetableDay.sampleWeek)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        if let cached = NEISAPIClient.shared.fetchCachedWeeklyTable(weekInterval: 0) {
            let entry = SimpleEntry(date: Date(), data: cached)
            completion(entry)
        } else {
            let entry = SimpleEntry(date: Date(), data: [])
            completion(entry)
            print("No cache available for snapshot.")
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now.addingTimeInterval(86400))
        var daySwitchTime: Date?
        if PreferencesManager.shared.daySwitchTime != (0, 0) {
            daySwitchTime = PreferencesManager.shared.daySwitchTimeDate
        }

        if let cached = CacheManager.shared.get(for: now.weekIdentifier(), maxAge: 24 * 60 * 60) {
            // Cache exists, use it
            var entries: [SimpleEntry] = []
            entries.append(SimpleEntry(date: now, data: cached))
            if let switchTime = daySwitchTime, now < switchTime {
                entries.append(SimpleEntry(date: switchTime, data: cached))
            }
            let timeline = Timeline(entries: entries, policy: .after(midnight))
            completion(timeline)
        } else {
            // No cache, fetch new data
            Task {
                do {
                    let days = try await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: 0, disableCache: true)
                    CacheManager.shared.set(days, for: now.weekIdentifier())
                    var entries: [SimpleEntry] = []
                    entries.append(SimpleEntry(date: now, data: days))
                    if let switchTime = daySwitchTime, now < switchTime {
                        entries.append(SimpleEntry(date: switchTime, data: days))
                    }
                    let timeline = Timeline(entries: entries, policy: .after(midnight))
                    completion(timeline)
                } catch {
                    print("Error from widget timeline fetch: \(error.localizedDescription)")
                    let fallback = SimpleEntry(date: now, data: [])
                    let retry = now.addingTimeInterval(15 * 60)
                    completion(Timeline(entries: [fallback], policy: .after(retry)))
                }
            }
        }
    }

    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: [TimetableDay]
}

struct WeeklyWidgetEntryView: View {
    var entry: Provider.Entry
    var longestDayCount: Int {
        entry.data.map { $0.columns.count }.max() ?? 0
    }

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            WidgetGridView(entry: entry, itemAspectRatio: CGFloat(longestDayCount) / 5.0)
        case .systemMedium:
            WidgetGridView(entry: entry, itemAspectRatio: CGFloat(longestDayCount) / 2.1)
        default:
            Text("Not supported")
        }
    }
}

struct DailyWidgetEntryView: View {
    var entry: Provider.Entry
    var longestDayCount: Int {
        entry.data.map { $0.columns.count }.max() ?? 0
    }

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            WidgetDailyView(entry: entry)
        case .accessoryInline:
            WidgetAccessoryInlineView(entry: entry)
        case .accessoryRectangular:
            WidgetAccessoryRectangularView(entry: entry)
        default:
            Text("Not supported")
        }
    }
}

// MARK: - System Small & Medium
struct WidgetGridView: View {
    let entry: Provider.Entry
    let itemAspectRatio: CGFloat

    var columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0, alignment: .top), count: 5)

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(entry.data) { day in
                VStack(spacing: 0) {
                    ForEach(day.columns) { column in
                        ColumnTile(
                            column: column,
                            itemAspectRatio: itemAspectRatio,
                            isToday: PreferencesManager.shared.isToday(day.date, referenceDate: entry.date)
                        )
                    }
                }
                .mask {
                    RoundedRectangle(cornerRadius: 5)
                        .padding(.horizontal, 1)
                }
            }
        }
        .padding(.horizontal, -1)
        .mask {
            ContainerRelativeShape()
        }
#if DEBUG
        //        .overlay {
        //            Text(entry.date.formatted(date: .numeric, time: .standard))
        //                .background {
        //                    Color.yellow
        //                }
        //        }
#endif
    }
}

// MARK: - Items for System view
struct ColumnTile: View {
    let column: TimetableColumn
    let itemAspectRatio: CGFloat
    let isToday: Bool

    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        Rectangle()
            .fill(fillColor)
            .aspectRatio(itemAspectRatio, contentMode: .fit)
            .overlay {
                Text(family == .systemMedium ? column.displayName : column.compactDisplayName)
                    .foregroundStyle(textColor)
                    .fontWeight(fontWeight)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 2)
            }
    }

    // MARK: - Style helpers
    private var fillColor: Color {
        switch (isToday, renderingMode) {
        case (true, .fullColor), (true, .vibrant):
            return Color("AccentColor")
        case (true, _):
            return .gray.opacity(0.2)
        case (false, .fullColor):
            return .gray.opacity(0.1)
        case (false, .vibrant):
            return .gray.opacity(0.2)
        default:
            return .gray.opacity(0.05)
        }
    }

    private var textColor: Color {
        isToday && (renderingMode == .fullColor || renderingMode == .vibrant) ? .white : .primary
    }

    private var fontWeight: Font.Weight {
        isToday ? .bold : .regular
    }
}

// MARK: - Home Screen Daily
struct WidgetDailyView: View {
    let entry: Provider.Entry
    let rows: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0, alignment: .leading), count: 2)

    var body: some View {
        GeometryReader { geo in
            VStack {
                if let today = entry.data.first(where: { PreferencesManager.shared.isToday($0.date, referenceDate: entry.date) }) {
                    TwoColumnFillingLayout(spacing: 3, columnSpacing: 10) {
                        CurrentDateView(date: today.date, showTomorrowLabel: !Calendar.current.isDateInToday(today.date))

                        ForEach(today.columns) { column in
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color("AccentColor"))
                                    .frame(width: 3)
                                Text(column.displayName)
                                    .font(.callout)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(3)
                            .background {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.gray.opacity(0.05))
                            }
                        }
                    }
                } else {
                    CurrentDateView(date: entry.date, showTomorrowLabel: false)
                    Spacer()
                    Text("오늘은 수업이 없습니다.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct CurrentDateView: View {
    let date: Date
    let showTomorrowLabel: Bool

    var body: some View {
        HStack(alignment: .bottom) {
            Text(date, format: .dateTime.day(.defaultDigits).weekday(.narrow))
                .font(.title2)

            if showTomorrowLabel {
                Text("내일")
                    .font(.caption)
                    .padding(2)
                    .widgetAccentable()
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.2))
                    }
            }

            Spacer()
        }
    }
}

// MARK: - Accessory Inline
struct WidgetAccessoryInlineView: View {
    let entry: Provider.Entry

    var body: some View {
        HStack {
            if let today = entry.data.first(where: {
                PreferencesManager.shared.isToday($0.date, referenceDate: entry.date)
            }) {
                if !Calendar.current.isDateInToday(today.date) {
                    Image(systemName: "arrow.right.circle.dotted")
                }
                Text(today.columns.map({ $0.compactDisplayName }).joined(separator: "·"))
            } else {
                Text("수업 없음")
            }
        }
    }
}

// MARK: - Accessory Rectangular
struct WidgetAccessoryRectangularView: View {
    let entry: Provider.Entry
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading) {
            if let today = entry.data.first(where: {
                PreferencesManager.shared.isToday($0.date, referenceDate: entry.date)
            }) {
                HStack {
                    Text(dateFormatter.string(from: today.date))
                        .font(.caption)
                    if !Calendar.current.isDateInToday(today.date) {
                        Text("내일")
                            .font(.caption)
                            .padding(2)
                            .widgetAccentable()
                            .background {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.gray.opacity(0.2))
                            }
                    }
                    Spacer()
                }
                HStack(spacing: 2) {
                    ForEach(today.columns) { column in
                        Circle()
                            .fill(.gray.opacity(0.15))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Text(column.compactDisplayName)
                                    .font(.headline)
                                    .widgetAccentable()
                                    .padding(1)
                                    .minimumScaleFactor(0.5)
                            }
                    }
                }
            } else {
                Text(dateFormatter.string(from: Date()))
                    .font(.caption)
                ViewThatFits {
                    Text("오늘은 수업이 없습니다.")
                        .foregroundStyle(.secondary)
                    Text("수업이 없습니다.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct WeeklyWidget: Widget {
    let kind: String = "WeeklyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeeklyWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { }
        }
        .configurationDisplayName("주간 시간표")
        .description("한 주 동안의 시간표를 확인합니다.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}

struct DailyWidget: Widget {
    let kind: String = "DailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { }
        }
        .configurationDisplayName("일간 시간표")
        .description("오늘의 시간표를 확인합니다.")
        .supportedFamilies([
            .systemMedium,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeeklyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")
            WeeklyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")
            DailyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Daily Medium")
            DailyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
            DailyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Small")
        }
        .containerBackground(for: .widget) {}
    }
}
