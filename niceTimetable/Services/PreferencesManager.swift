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
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
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
    }
    
    func removeAlias(for subject: String) {
        var current = aliasData
        current.removeValue(forKey: subject)
        aliasData = current
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
}
