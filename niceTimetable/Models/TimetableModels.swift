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
    
    // Use the normal alias if not blank, otherwise original subject
    var displayName: String {
        PreferencesManager.shared.aliases[subject]?.normal.isEmpty == false ? PreferencesManager.shared.aliases[subject]!.normal : subject
    }
    
    // Use the compact alias if not blank, otherwise fallback to the first character of the subject
    var compactDisplayName: String {
        PreferencesManager.shared.aliases[subject]?.compact.isEmpty == false ? PreferencesManager.shared.aliases[subject]!.compact : subject.firstMeaningfulCharacter.map { String($0) } ?? subject
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
    static let sampleWeek: [TimetableDay] = [
        TimetableDay(
            date: Date(),
            columns: [
                TimetableColumn(period: 1, subject: "수학", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "과학", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "역사", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "역사", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 7, subject: "체육", room: "505", lastUpdated: "20231001"),
            ]),
        TimetableDay(
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "음악", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "미술", room: "404", lastUpdated: "20231001"),
            ]),
        TimetableDay(
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "음악", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 7, subject: "체육", room: "505", lastUpdated: "20231001"),
            ]),
        TimetableDay(
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "음악", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "미술", room: "404", lastUpdated: "20231001"),
            ]),
        TimetableDay(
            date: Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
            columns: [
                TimetableColumn(period: 1, subject: "국어", room: "101", lastUpdated: "20231001"),
                TimetableColumn(period: 2, subject: "영어", room: "202", lastUpdated: "20231001"),
                TimetableColumn(period: 3, subject: "음악", room: "303", lastUpdated: "20231001"),
                TimetableColumn(period: 4, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 5, subject: "체육", room: "505", lastUpdated: "20231001"),
                TimetableColumn(period: 6, subject: "미술", room: "404", lastUpdated: "20231001"),
                TimetableColumn(period: 7, subject: "체육", room: "505", lastUpdated: "20231001"),
            ]),
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
        let grouped = Dictionary(grouping: self, by: { $0.ALL_TI_YMD })
        
        return grouped.compactMap { (dateString, rows) in
            // Parse date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            guard let date = formatter.date(from: dateString) else { return nil }
            
            // Convert rows → TimetableColumn while removing duplicates by period
            var dayRowsDict: [Int: TimetableColumn] = [:]
            for row in rows {
                guard let period = Int(row.PERIO) else { continue }
                if dayRowsDict[period] == nil {
                    dayRowsDict[period] = TimetableColumn(
                        period: period,
                        subject: row.ITRT_CNTNT,
                        room: row.CLRM_NM,
                        lastUpdated: row.LOAD_DTM
                    )
                }
            }
            
            // Determine the max period present that day
            guard let maxPeriod = dayRowsDict.keys.max(), maxPeriod > 0 else {
                // No valid periods for this date
                return TimetableDay(date: date, columns: [])
            }
            
            // Build an ordered array 1...maxPeriod, padding missing periods with empty placeholders
            let paddedColumns: [TimetableColumn] = (1...maxPeriod).map { p in
                if let existing = dayRowsDict[p] { return existing }
                return TimetableColumn(period: p, subject: "", room: nil, lastUpdated: nil)
            }
            
            return TimetableDay(date: date, columns: paddedColumns)
        }
        .sorted(by: { $0.date < $1.date })
    }
}
