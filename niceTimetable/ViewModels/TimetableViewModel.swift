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
    // Adding pagination: now user can swipe through weeks
    @Published var weeks: [Int: TimetableWeek] = [:]
    @Published var errorMessage: String?
    @Published var currentWeekIndex: Int = 0    // Track which week is currently displayed
    @Published var loadedWeekIndices: [Int] = [] // Track which weeks have been loaded
    
    func loadThreeWeeks() async {
        // Load previous, current, and next week
        async let lastWeek = try? await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: -1)
        async let thisWeek = try? await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: 0)
        async let nextWeek = try? await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: 1)
        
        let results = await [lastWeek, thisWeek, nextWeek]
        var tempWeeks: [TimetableWeek] = []
        var tempLoadedIndices: [Int] = []
        
        for (index, days) in results.enumerated() {
            let offset = index - 1 // -1, 0, 1
            if let days {
                let week = TimetableWeek(days: days, weekInterval: offset)
                tempWeeks.append(week)
                tempLoadedIndices.append(offset)
            } else {
                print("Error fetching week \(offset)")
            }
        }
        
        self.weeks = Dictionary(uniqueKeysWithValues: tempWeeks.map { ($0.weekInterval, $0) })
        self.loadedWeekIndices = tempLoadedIndices.sorted()
    }
    
    func checkForUpdates(weekInterval: Int = 0) async {
        do {
            let days = try await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: weekInterval, disableCache: true)
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
        } catch {
            self.errorMessage = "Error checking updates: \(error.localizedDescription)"
        }
    }
    
    func clearOldCache() {
        CacheManager.shared.pruneOldWeeks(keeping: -1...1)
    }
    
    func handleWeekChange(to newIndex: Int) async {
        // If newIndex is at start or end of loadedWeekIndices, load more weeks
        print("Current loaded weeks: \(loadedWeekIndices), requested week: \(newIndex)")
        
        if newIndex == (loadedWeekIndices.min() ?? 0) {
            // Load previous week
            let newWeekOffset = (loadedWeekIndices.min() ?? 0) - 1
            do {
                let days = try await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: newWeekOffset)
                let newWeek = TimetableWeek(days: days, weekInterval: newWeekOffset)
                self.weeks[newWeekOffset] = newWeek
                self.loadedWeekIndices.insert(newWeekOffset, at: 0)
                self.errorMessage = nil
            } catch {
                print("Error loading previous week: \(error.localizedDescription)")
            }
        } else if newIndex == (loadedWeekIndices.max() ?? 0) {
            // Load next week
            let newWeekOffset = (loadedWeekIndices.max() ?? 0) + 1
            do {
                let days = try await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: newWeekOffset)
                let newWeek = TimetableWeek(days: days, weekInterval: newWeekOffset)
                self.weeks[newWeekOffset] = newWeek
                self.loadedWeekIndices.append(newWeekOffset)
                self.errorMessage = nil
            } catch {
                print("Error loading next week: \(error.localizedDescription)")
            }
        }
    }
}
