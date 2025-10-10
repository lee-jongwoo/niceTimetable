//
//  TimetableViewModel.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class TimetableViewModel: ObservableObject {
    @Published var days: [TimetableDay] = []
    // Adding pagination: now user can swipe through weeks
    @Published var weeks: [Int: TimetableWeek] = [:]
    @Published var errorMessage: String?
    @Published var currentWeekIndex: Int = 0    // Track which week is currently displayed
    @Published var loadedWeekIndices: [Int] = [] // Track which weeks have been loaded
    
    func loadThreeWeeks() {
        // Load previous, current, and next week
        let group = DispatchGroup()
        var tempWeeks: [TimetableWeek] = []
        var tempLoadedIndices: [Int] = []
        for offset in -1...1 {
            group.enter()
            NEISAPIClient.shared.fetchWeeklyTable(weekInterval: offset) { result in
                switch result {
                case .success(let days):
                    let week = TimetableWeek(days: days, weekInterval: offset)
                    tempWeeks.append(week)
                    tempLoadedIndices.append(offset)
                    self.errorMessage = nil
                case .failure(let error):
                    print("Error while fetching timetable \(offset): \(error.localizedDescription)")
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            // Sort weeks by their weekInterval to ensure correct order
            let sortedWeeks = tempWeeks.sorted { $0.weekInterval < $1.weekInterval }
            self.weeks = Dictionary(uniqueKeysWithValues: sortedWeeks.map { ($0.weekInterval, $0) })
            self.loadedWeekIndices = tempLoadedIndices.sorted()
        }
    }
    
    func checkForUpdates(weekInterval: Int = 0) {
        NEISAPIClient.shared.fetchWeeklyTable(weekInterval: weekInterval, disableCache: true) { result in
            switch result {
            case .success(let days):
                // Check if there's any difference
                print("Fetched week \(weekInterval) for update check.")
                self.errorMessage = nil
                if let existingWeek = self.weeks[weekInterval] {
                    if existingWeek.days != days {
                        // Update the week
                        print("Week \(weekInterval) has updates. Updating...")
                        let updatedWeek = TimetableWeek(days: days, weekInterval: weekInterval)
                        self.weeks[weekInterval] = updatedWeek
                        CacheManager.shared.set(days, for: updatedWeek.days[0].date.weekIdentifier())
                        // Update the widget!
                        // only if current week is updated
                        if weekInterval == 0 {
                            CacheManager.shared.reloadWidgets()
                        }
                    }
                } else {
                    // Week not loaded yet, just add it
                    self.errorMessage = nil
                    let newWeek = TimetableWeek(days: days, weekInterval: weekInterval)
                    self.weeks[weekInterval] = newWeek
                    CacheManager.shared.set(days, for: newWeek.days[0].date.weekIdentifier())
                }
            case .failure(let error):
                self.errorMessage = "Error checking updates: \(error.localizedDescription)"
            }
        }
    }
    
    func clearOldCache() {
        CacheManager.shared.pruneOldWeeks(keeping: -1...1)
    }
    
    func handleWeekChange(to newIndex: Int) {
        // If newIndex is at start or end of loadedWeekIndices, load more weeks
        print("Current loaded weeks: \(loadedWeekIndices), requested week: \(newIndex)")
        if newIndex == (loadedWeekIndices.min() ?? 0) {
            // Load previous week
            let newWeekOffset = (loadedWeekIndices.min() ?? 0) - 1
            NEISAPIClient.shared.fetchWeeklyTable(weekInterval: newWeekOffset) { result in
                switch result {
                case .success(let days):
                    let newWeek = TimetableWeek(days: days, weekInterval: newWeekOffset)
                    self.weeks[newWeekOffset] = newWeek
                    self.loadedWeekIndices.insert(newWeekOffset, at: 0)
                    self.errorMessage = nil
                case .failure(let error):
                    print("Error loading previous week: \(error.localizedDescription)")
                }
            }
        } else if newIndex == (loadedWeekIndices.max() ?? 0) {
            // Load next week
            let newWeekOffset = (loadedWeekIndices.max() ?? 0) + 1
            NEISAPIClient.shared.fetchWeeklyTable(weekInterval: newWeekOffset) { result in
                switch result {
                case .success(let days):
                    let newWeek = TimetableWeek(days: days, weekInterval: newWeekOffset)
                    self.weeks[newWeekOffset] = newWeek
                    self.loadedWeekIndices.append(newWeekOffset)
                    self.errorMessage = nil
                case .failure(let error):
                    print("Error loading next week: \(error.localizedDescription)")
                }
            }
        }
    }
}
