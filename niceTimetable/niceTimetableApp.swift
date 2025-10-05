//
//  niceTimetableApp.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI

@main
struct niceTimetableApp: App {
    @StateObject private var aliasStore = AliasStore()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(aliasStore)
        }
    }
}

struct RootView: View {
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    
    var body: some View {
        if isOnboarding {
            OnboardingView()
        } else {
            TimetableView()
        }
    }
}
