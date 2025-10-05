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
    
    private let defaults = UserDefaults(suiteName: "group.dev.jongwoo.niceTimetable") ?? .standard
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
}
