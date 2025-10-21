//
//  DaySwitchNotifier.swift
//  NiceTimetable
//
//  Created by 이종우 on 10/21/25.
//

import Foundation

final class DaySwitchNotifier {
    static let shared = DaySwitchNotifier()

    private var nextSwitchTask: DispatchWorkItem?

    private init() {
        scheduleNextSwitch()
    }

    func refresh() {
        // Cancel any pending scheduled switch
        nextSwitchTask?.cancel()
        // Fire immediately
        NotificationCenter.default.post(name: .dayDidSwitch, object: nil)
        scheduleNextSwitch()
    }

    private func scheduleNextSwitch() {
        let now = Date()
        let calendar = Calendar.current

        let switchTimeToday = PreferencesManager.shared.daySwitchTimeDate

        let nextSwitchDate: Date
        if now < switchTimeToday {
            nextSwitchDate = switchTimeToday
        } else {
            nextSwitchDate = calendar.date(byAdding: .day, value: 1, to: switchTimeToday)!
        }

        let interval = nextSwitchDate.timeIntervalSince(now)

        let task = DispatchWorkItem { [weak self] in
            NotificationCenter.default.post(name: .dayDidSwitch, object: nil)
            self?.scheduleNextSwitch()
        }

        nextSwitchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: task)
    }
}

extension Notification.Name {
    static let dayDidSwitch = Notification.Name("dayDidSwitch")
}
