//
//  niceTimetableApp.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI

@main
struct niceTimetableApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
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
