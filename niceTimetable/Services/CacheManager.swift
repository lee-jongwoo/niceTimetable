//
//  CacheManager.swift
//  niceTimetable
//
//  Created by 이종우 on 10/2/25.
//

import Foundation
import WidgetKit

struct CachedSchedule: Codable {
    let timestamp: Date
    let currentWeek: [TimetableDay]
}

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.dev.jongwoo.niceTimetable") ?? .standard
}

final class CacheManager {
    static let shared = CacheManager()
    private let defaults: UserDefaults
    
    private init() {
        guard let userDefaults = UserDefaults(suiteName: "group.dev.jongwoo.niceTimetable") else {
            fatalError("Failed to initialize UserDefaults with app group.")
        }
        self.defaults = userDefaults
    }
    
    var cacheSize: String {
        var totalSize = 0
        for key in defaults.dictionaryRepresentation().keys {
            if let data = defaults.data(forKey: key) {
                totalSize += data.count
            }
        }
        return ByteCountFormatter().string(fromByteCount: Int64(totalSize))
    }
    
    private func cacheKey(for identifier: String) -> String {
        return "cachedSchedule_\(identifier)"
    }
    
    func get(for identifier: String, maxAge: TimeInterval) -> [TimetableDay]? {
        guard let data = defaults.data(forKey: cacheKey(for: identifier)),
              let cached = try? JSONDecoder().decode(CachedSchedule.self, from: data) else { return nil }
        
        if Date().timeIntervalSince(cached.timestamp) < maxAge {
            return cached.currentWeek
        } else {
            return nil
        }
    }
    
    func set(_ days: [TimetableDay], for identifier: String) {
        let cached = CachedSchedule(timestamp: Date(), currentWeek: days)
        if let data = try? JSONEncoder().encode(cached) {
            defaults.set(data, forKey: cacheKey(for: identifier))
        }
    }
    
    func pruneOldWeeks(keeping offsets: ClosedRange<Int>) {
        let allKeys = defaults.dictionaryRepresentation().keys
        // Determine valid week identifiers to keep
        // Find all Mondays for the offsets
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        var validIdentifiers: Set<String> = []
        for offset in offsets {
            if let targetDate = calendar.date(byAdding: .weekOfYear, value: offset, to: today) {
                let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: targetDate))!
                let identifier = monday.weekIdentifier()
                validIdentifiers.insert(identifier)
            }
        }
        
        for key in allKeys {
            if key.hasPrefix("cachedSchedule_") {
                let identifier = String(key.dropFirst("cachedSchedule_".count))
                if !validIdentifiers.contains(identifier) {
                    defaults.removeObject(forKey: key)
                }
            }
        }
    }
    
    func purge(for identifier: String) {
        defaults.removeObject(forKey: cacheKey(for: identifier))
    }
    
    func clearAll() {
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("cachedSchedule_") {
                defaults.removeObject(forKey: key)
            }
        }
        reloadWidgets()
    }
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Extensions
extension Date {
    func weekIdentifier() -> String {
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: monday) // e.g. "2025-06-09"
    }
}
