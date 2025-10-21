//
//  DateFormatters.swift
//  niceTimetable
//
//  Created by 이종우 on 10/11/25.
//

import Foundation

struct DateFormatters {
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let timeStamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Date {
    func weekIdentifier() -> String {
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: monday) // e.g. "2025-06-09"
    }
}

extension Date {
    func next(_ weekday: Weekday,
                     direction: Calendar.SearchDirection = .forward,
                     considerToday: Bool = true) -> Date
    {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(weekday: weekday.rawValue)

        if considerToday &&
            calendar.component(.weekday, from: self) == weekday.rawValue
        {
            return self
        }

        return calendar.nextDate(after: self,
                                 matching: components,
                                 matchingPolicy: .nextTime,
                                 direction: direction)!
    }

    enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
}
