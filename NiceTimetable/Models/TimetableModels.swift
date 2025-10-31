//
//  TimetableModels.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import Foundation

// A single period (교시)
struct TimetableColumn: Identifiable, Codable, Equatable {
    var id = UUID()
    let period: Int
    let subject: String
    let room: String?
    let lastUpdated: String?

    private let aliases = PreferencesManager.shared.aliases

    // Use the normal alias if not blank, otherwise original subject
    var displayName: String {
        if aliases[subject]?.normal.isEmpty == false {
            return aliases[subject]?.normal ?? ""
        } else {
            return subject
        }
    }

    // Use the compact alias if not blank, otherwise fallback to the first character of the subject
    var compactDisplayName: String {
        if aliases[subject]?.compact.isEmpty == false {
            return aliases[subject]?.compact ?? ""
        } else if let ini = aliases[subject]?.normal.firstMeaningfulCharacter.map({ String($0) }) {
            return ini
        } else {
            return subject.firstMeaningfulCharacter.map { String($0) } ?? "-"
        }
    }

    static func == (lhs: TimetableColumn, rhs: TimetableColumn) -> Bool {
        return lhs.period == rhs.period &&
        lhs.subject == rhs.subject &&
        lhs.room == rhs.room &&
        lhs.lastUpdated == rhs.lastUpdated
    }
}

extension String {
    var nonEmpty: String? {
        self.isEmpty == false ? self : nil
    }
}

// A whole day’s timetable
struct TimetableDay: Identifiable, Codable, Equatable {
    var id = UUID()
    let date: Date
    var columns: [TimetableColumn]

    static func == (lhs: TimetableDay, rhs: TimetableDay) -> Bool {
        return lhs.date == rhs.date && lhs.columns == rhs.columns
    }

    // dummy data for testing
    static let startOfWeek = PreferencesManager.shared.startOfWeek(for: Date())
    static let sampleWeek: [TimetableDay] = [
        TimetableDay(
            date: startOfWeek.next(.monday),
            columns: [
                TimetableColumn(period: 1, subject: "수학", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "과학", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "역사", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "역사", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 7, subject: "체육", room: "505", lastUpdated: "20231001")
            ]),
        TimetableDay(
            date: startOfWeek.next(.tuesday),
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "음악", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "미술", room: "404", lastUpdated: "20231001")
            ]),
        TimetableDay(
            date: startOfWeek.next(.wednesday),
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "한국사", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "과학탐구", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "윤리와 사상", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "지구과학1", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "정보와 디지털 문해력", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 7, subject: "수능 예비소집일", room: "505", lastUpdated: "20231001")
            ]),
        TimetableDay(
            date: startOfWeek.next(.thursday),
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "음악", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "미술", room: "404", lastUpdated: "20231001")
            ]),
        TimetableDay(
            date: startOfWeek.next(.friday),
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "음악", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 7, subject: "체육", room: "505", lastUpdated: "20231001")
            ])
    ]
}

// A week of timetable; used for pagination
struct TimetableWeek: Identifiable {
    let id = UUID()
    var days: [TimetableDay]
    var weekInterval: Int // 0 for this week, -1 for last week, 1 for next week
}

// A collection of multiple days
struct TimetableResponse: Codable {
    var days: [TimetableDay]
}

// Convert between data models
extension Array where Element == NEISRow {
    func toTimetableDays() -> [TimetableDay] {
        // Group rows by date
        let grouped = Dictionary(grouping: self, by: { $0.date })

        return grouped.compactMap { (dateString, rows) in
            // Parse date
            guard let date = DateFormatters.timeStamp.date(from: dateString) else { return nil }

            // Convert rows → TimetableColumn while removing duplicates by period
            var dayRowsDict: [Int: TimetableColumn] = [:]
            for row in rows {
                guard let period = Int(row.period) else { continue }
                if dayRowsDict[period] == nil {
                    dayRowsDict[period] = TimetableColumn(
                        period: period,
                        subject: row.subject,
                        room: row.room,
                        lastUpdated: row.lastUpdated
                    )
                }
            }

            // Determine the max period present that day
            guard let maxPeriod = dayRowsDict.keys.max(), maxPeriod > 0 else {
                // No valid periods for this date
                return TimetableDay(date: date, columns: [])
            }

            // Build an ordered array 1...maxPeriod, padding missing periods with empty placeholders
            let paddedColumns: [TimetableColumn] = (1...maxPeriod).map { period in
                if let existing = dayRowsDict[period] { return existing }
                return TimetableColumn(period: period, subject: "", room: nil, lastUpdated: nil)
            }

            return TimetableDay(date: date, columns: paddedColumns)
        }
        .sorted(by: { $0.date < $1.date })
    }
}
