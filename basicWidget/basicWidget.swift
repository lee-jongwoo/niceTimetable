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
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        NEISAPIClient.shared.fetchWeeklyTable() { result in
            switch result {
            case .success(let days):
                let entry = SimpleEntry(date: Date(), data: days)
                completion(entry)
            case .failure(let error):
                let entry = SimpleEntry(date: Date(), data: [])
                completion(entry)
                print("Error fetching timetable: \(error.localizedDescription)")
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let calendar = Calendar.current
        
        if let cached = CacheManager.shared.get(for: now.weekIdentifier(), maxAge: 24 * 60 * 60) {
            // Cache exists, use it
            let midnight = calendar.startOfDay(for: now.addingTimeInterval(86400))
            let currentEntry = SimpleEntry(date: now, data: cached)
            let midnightEntry = SimpleEntry(date: midnight, data: cached)
            let timeline = Timeline(entries: [currentEntry, midnightEntry], policy: .atEnd)
            completion(timeline)
        } else {
            // uh-oh no cache
            // request fetch
            NEISAPIClient.shared.fetchWeeklyTable{ result in
                switch result {
                case .success(let days):
                    CacheManager.shared.set(days, for: now.weekIdentifier())
                    let midnight = calendar.startOfDay(for: now.addingTimeInterval(86400))
                    let entries = [
                        SimpleEntry(date: now, data: days),
                        SimpleEntry(date: midnight, data: days)
                    ]
                    completion(Timeline(entries: entries, policy: .atEnd))
                case .failure(let error):
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

struct WeeklyWidgetEntryView : View {
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
            WidgetGridView(entry: entry, itemAspectRatio: CGFloat(longestDayCount) / 2)
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
    
    var columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 1, alignment: .top), count: 5)
    
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(entry.data) { day in
                VStack(spacing: 1) {
                    ForEach(day.columns) { column in
                        WidgetDailyItemView(column: column, itemAspectRatio: itemAspectRatio, isToday: Calendar.current.isDateInToday(day.date))
                    }
                }
            }
        }
        .mask {
            ContainerRelativeShape()
        }
#if DEBUG
        .overlay {
            Text(entry.date, style: .time)
                .font(.caption2)
                .background {
                    Color.yellow
                }
        }
#endif
    }
}

// MARK: - Items for System view
struct WidgetDailyItemView: View {
    let column: TimetableColumn
    let itemAspectRatio: CGFloat
    let isToday: Bool
    
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode
    
    
    var body: some View {
        if isToday {
            switch renderingMode {
            case .fullColor:
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("AccentColor"))
                    .aspectRatio(itemAspectRatio, contentMode: .fit)
                    .overlay {
                        Text(family == .systemMedium ? column.displayName : column.compactDisplayName)
                            .foregroundStyle(.white)
                            .bold()
                            .minimumScaleFactor(0.5)
                    }
            case .vibrant:
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("AccentColor"))
                    .aspectRatio(itemAspectRatio, contentMode: .fit)
                    .overlay {
                        Text(family == .systemMedium ? column.displayName : column.compactDisplayName)
                            .foregroundStyle(.white)
                            .bold()
                            .minimumScaleFactor(0.5)
                    }
            default:
                RoundedRectangle(cornerRadius: 3)
                    .opacity(0)
                    .aspectRatio(itemAspectRatio, contentMode: .fit)
                    .overlay {
                        Text(family == .systemMedium ? column.displayName : column.compactDisplayName)
                            .foregroundStyle(.white)
                            .fontWeight(.heavy)
                            .minimumScaleFactor(0.5)
                    }
            }
        } else {
            switch renderingMode {
            case .fullColor:
                RoundedRectangle(cornerRadius: 3)
                    .fill(.gray.opacity(0.2))
                    .aspectRatio(itemAspectRatio, contentMode: .fit)
                    .overlay {
                        Text(family == .systemMedium ? column.displayName : column.compactDisplayName)
                            .foregroundStyle(Color(UIColor.label))
                            .minimumScaleFactor(0.5)
                    }
            case .vibrant:
                RoundedRectangle(cornerRadius: 3)
                    .fill(.gray.opacity(0.2))
                    .aspectRatio(itemAspectRatio, contentMode: .fit)
                    .overlay {
                        Text(family == .systemMedium ? column.displayName : column.compactDisplayName)
                            .foregroundStyle(Color(UIColor.label))
                            .bold()
                            .minimumScaleFactor(0.5)
                    }
            default:
                RoundedRectangle(cornerRadius: 3)
                    .opacity(0)
                    .aspectRatio(itemAspectRatio, contentMode: .fit)
                    .overlay {
                        Text(family == .systemMedium ? column.displayName : column.compactDisplayName)
                            .foregroundStyle(Color(UIColor.label))
                            .minimumScaleFactor(0.5)
                    }
            }
        }
    }
}

// MARK: - Accessory Inline
struct WidgetAccessoryInlineView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack {
            if let today = entry.data.first(where: { Calendar.current.isDateInToday($0.date) }) {
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
            if let today = entry.data.first(where: { Calendar.current.isDateInToday($0.date) }) {
                Text(dateFormatter.string(from: today.date))
                    .font(.caption)
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
            WeeklyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            DailyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
            DailyWidgetEntryView(entry: SimpleEntry(date: Date(), data: TimetableDay.sampleWeek))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
        .containerBackground(for: .widget) {}
        
        
    }
}
