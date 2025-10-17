//
//  niceTimetableApp.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI
import TipKit

@main
struct NiceTimetableApp: App {
    static let timetableAppDidOpen = Tips.Event(id: "timetableAppDidOpen")
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear { Self.timetableAppDidOpen.sendDonation() }
        }
    }

    init() {
        do {
            #if DEBUG
            try Tips.resetDatastore()
            #endif

            try Tips.configure([
                .displayFrequency(.hourly)
            ])
        } catch {
            print("Failed to configure TipKit: \(error)")
        }
    }
}

struct RootView: View {
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if isOnboarding {
            OnboardingView()
        } else {
            TimetableView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        CacheManager.shared.reloadWidgetsIfNeeded()
                    }
                }
        }
    }
}
