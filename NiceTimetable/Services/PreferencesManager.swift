//
//  PreferencesManager.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import Foundation

/// A simple wrapper around UserDefaults for storing user preferences
final class PreferencesManager {
    static let shared = PreferencesManager()
    private init() {}

    private let defaults = UserDefaults.appGroup
    private let aliasesKey = "subjectAliases"

    private enum Keys {
        static let schoolType = "schoolType"
        static let officeCode = "officeCode"
        static let schoolName = "schoolName"
        static let schoolCode = "schoolCode"
        static let grade = "grade"
        static let className = "className"
        static let aliases = "subjectAliases"
        static let daySwitchTime = "daySwitchTime"
        static let shouldUpdateWidget = "shouldUpdateWidget"
    }

    // MARK: - Date Control Functions
    // Not currenly customizable, but might be in the future
    func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    func weekdayTimeFrame(for date: Date) -> (start: Date, end: Date) {
        let startOfWeek = self.startOfWeek(for: date)
        // Find Monday after startOfWeek (which may be Sunday)
        let start = startOfWeek.next(.monday, considerToday: true)
        let end = startOfWeek.next(.friday, considerToday: true)
        return (start, end)
    }

    // May change start time of day in the future
    func isToday(_ date: Date, referenceDate: Date = Date()) -> Bool {
        let calendar = Calendar.current

        guard daySwitchTime != (0, 0) else {
            return calendar.isDate(date, inSameDayAs: referenceDate)
        }

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: referenceDate)
        components.hour = daySwitchTime.hour
        components.minute = daySwitchTime.minute
        components.second = 0

        guard let switchTimeToday = calendar.date(from: components),
              let nextDay = calendar.date(byAdding: .day, value: 1, to: referenceDate)
        else {
            return false
        }

        let effectiveDay = referenceDate >= switchTimeToday ? nextDay : referenceDate
        return calendar.isDate(effectiveDay, inSameDayAs: date)
    }

    // MARK: - Subject Aliases

    private var aliasData: [String: AliasPair] {
        get {
            guard let data = defaults.data(forKey: aliasesKey),
                  let dict = try? JSONDecoder().decode([String: AliasPair].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: aliasesKey)
            }
        }
    }

    var aliases: [String: AliasPair] {
        get { aliasData }
        set { aliasData = newValue }
    }

    func setAlias(for subject: String, normal: String, compact: String) {
        if normal.isEmpty && compact.isEmpty {
            removeAlias(for: subject)
            return
        }
        var current = aliasData
        current[subject] = AliasPair(normal: normal, compact: compact)
        aliasData = current
        shouldUpdateWidget = true
    }

    func removeAlias(for subject: String) {
        var current = aliasData
        current.removeValue(forKey: subject)
        aliasData = current
        shouldUpdateWidget = true
    }

    // MARK: - School Info
    var schoolType: String? {
        get { defaults.string(forKey: Keys.schoolType) }
        set { defaults.set(newValue, forKey: Keys.schoolType) }
    }

    var officeCode: String? {
        get { defaults.string(forKey: Keys.officeCode) }
        set { defaults.set(newValue, forKey: Keys.officeCode) }
    }

    var schoolName: String? {
        get { defaults.string(forKey: Keys.schoolName) }
        set { defaults.set(newValue, forKey: Keys.schoolName) }
    }

    var schoolCode: String? {
        get { defaults.string(forKey: Keys.schoolCode) }
        set { defaults.set(newValue, forKey: Keys.schoolCode) }
    }

    var grade: String? {
        get { defaults.string(forKey: Keys.grade) }
        set { defaults.set(newValue, forKey: Keys.grade) }
    }

    var className: String? {
        get { defaults.string(forKey: Keys.className) }
        set { defaults.set(newValue, forKey: Keys.className) }
    }

    func setSchoolInfo(school: School, newClass: SchoolClass) {
        self.schoolType = school.schoolType
        self.officeCode = school.officeCode
        self.schoolName = school.schoolName
        self.schoolCode = school.schoolCode
        self.grade = newClass.grade
        self.className = newClass.className
    }

    // MARK: - Day Switch Time
    var daySwitchTime: (hour: Int, minute: Int) {
        get {
            if let timeString = defaults.string(forKey: Keys.daySwitchTime) {
                let components = timeString.split(separator: ":").compactMap { Int($0) }
                if components.count == 2 {
                    return (components[0], components[1])
                }
            }
            // Default to midnight
            return (0, 0)
        }

        set {
            let timeString = String(format: "%02d:%02d", newValue.hour, newValue.minute)
            defaults.set(timeString, forKey: Keys.daySwitchTime)
        }
    }

    var daySwitchTimeDate: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = daySwitchTime.hour
        components.minute = daySwitchTime.minute
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }

    var daySwitchTimeLabel: String {
        return defaults.string(forKey: Keys.daySwitchTime) ?? "끔"
    }

    var isDaySwitchTimeOn: Bool {
        return daySwitchTime != (0, 0)
    }

    // MARK: - Widget Update Control
    var shouldUpdateWidget: Bool {
        get { defaults.bool(forKey: Keys.shouldUpdateWidget) }
        set { defaults.set(newValue, forKey: Keys.shouldUpdateWidget) }
    }
}
