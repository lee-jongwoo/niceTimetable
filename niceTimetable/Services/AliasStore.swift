//
//  AliasStore.swift
//  niceTimetable
//
//  Created by 이종우 on 10/4/25.
//

import Foundation
import Combine

struct AliasPair: Codable {
    var normal: String
    var compact: String
}

class AliasStore: ObservableObject {
    @Published var aliases: [String: AliasPair] = [:]
    
    private let manager = PreferencesManager.shared
    
    init() {
        // Load aliases from UserDefaults initially
        self.aliases = manager.aliases
    }
    
    func setAlias(for subject: String, normal: String, compact: String) {
        aliases[subject] = AliasPair(normal: normal, compact: compact)
        // Persist to UserDefaults
        manager.setAlias(for: subject, normal: normal, compact: compact)
    }
    
    func reloadFromDefaults() {
        aliases = manager.aliases
    }
}
